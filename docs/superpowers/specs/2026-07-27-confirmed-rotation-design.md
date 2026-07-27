# Confirmed Rotation — 高可靠性双 Token 轮转方案

> 2026-07-27 设计。解决移动端切后台/丢响应导致 refreshToken 永久失效、用户需重复输入 API Token 的问题。

## 问题

当前双 Token 轮转采用**单次使用即删除**策略（`storage.ts:467`）：

```typescript
// 单次删除
handle.prepare('DELETE FROM manager_sessions WHERE refresh_token = ?').run(token);
// 插入新行
handle.prepare('INSERT INTO manager_sessions ...').run(newToken, newRefreshToken);
```

当客户端发出的 refresh 请求已到达服务端（旧 token 被删除），但服务端的响应丢失（网络波动、切后台、App 崩溃）时，客户端仍持有旧的 refreshToken，而服务端已将其作废。客户端下次再试时收到 `invalid_refresh` → 断开连接 → 用户需重新输入 API Token。

**根因**："响应到达客户端"这个信号不可靠，却被用作"轮转确认"。

## 方案：Confirmed Rotation

### 核心思路

将确认信号从"响应到达客户端"改为"新 sessionToken 被实际用于 API 请求并验证通过"。

```
响应到达客户端 → ❌ 不可靠（可能丢）
新 sessionToken 被 auth middleware 验证通过 → ✅ 可靠（服务端确认）
```

### 实现原理

在 `manager_sessions` 表增加 `replaced_by` 列，标记 refreshToken 的替代关系。refresh 时不再删除旧行，而是标记替代。待新 sessionToken 被真实使用后才清理旧行。

### Schema 变更

```sql
ALTER TABLE manager_sessions ADD COLUMN replaced_by TEXT;
-- replaced_by: 本行的 refreshToken 被哪个 sessionToken 替代了
-- NULL = 未被使用的 refreshToken（初始状态）
-- 'abc...' = 已轮转，新 sessionToken 是 abc...
```

### 流程

#### refreshSession（重写）

```
refreshToken_A 请求刷新：
  1. 按 refresh_token 找到行
  2. 检查 refresh_expires_at —— 过期则删除并返回 undefined
  3. IF replaced_by IS NOT NULL（这是重试）：
     a. 按 replaced_by 找到新行
     b. 新行存在且未过期 → 返回已有的 token 对（不再轮转）
     c. 新行不存在（prune 清理了） → 降级为正常刷新（fall through）
  4. 首次刷新：
     a. 生成 sessionToken_B + refreshToken_B
     b. INSERT 新行 (token=B, refresh_token=RB, ...)
     c. UPDATE 旧行 SET replaced_by='B'
     d. 返回新 token 对
```

#### auth middleware（新增清理逻辑）

```
registerAuth 验证 sessionToken 成功后：
  storage.confirmSession(token)
    → DELETE FROM manager_sessions WHERE replaced_by = token
```

#### pruneExpired（增强）

```sql
-- 现有：清理 expiresAt 或 refresh_expires_at 过期的行
DELETE FROM manager_sessions WHERE expiresAt < now OR refresh_expires_at < now;

-- 增强：清理 replaced_by 指向的行已不复存在的旧行
-- （安全兜底，正常情况下由 confirmSession 清理）
```

### 场景验证

| 场景 | 结果 |
|------|------|
| **正常轮转** | 客户端收到新 token → 下次 API 请求用新 sessionToken → auth middleware 验证通过 → confirmSession() 删旧行 → 旧 refreshToken 失效 ✓ |
| **丢响应（切后台/网络断）** | 客户端重试旧 refreshToken → refreshSession 发现 `replaced_by` → 返回同一对新 token → 恢复 ✓ |
| **多次丢响应** | 每次重试都返回同一对 token，不产生新轮转 ✓ |
| **App 崩溃重启** | 旧 refreshToken 保留（仍在 refresh_expires_at 内）→ 重启后 boot() 用它 refresh → 通过 replaced_by 拿到同一对新 token ✓ |
| **token 泄露** | 旧 refreshToken 最终会在合法客户端使用新 sessionToken 时通过 confirmSession 被清除 ✓ |

### 安全性分析

- 旧 refreshToken 的 `refresh_expires_at` 不变，过期后由 `pruneExpired` 清理
- `replaced_by` 只是延长了旧 token 的"可重试窗口"，不是无限制宽限
- `confirmSession` 的触发条件是真实 API 请求的 auth 验证，攻击者无法伪造
- 退化场景（新行被 prune、崩溃后长时间未使用）：replaced_by 行仍会随 refresh_expires_at 过期

## 客户端改动

配套客户端（`tired_agent_app`）改动较小：

1. **`TiredAgentApp` + `WidgetsBindingObserver`**：监听 `AppLifecycleState.resumed`，切前台时触发 session 刷新
2. **`AuthProvider.refreshAllSessions()`**：对所有连接调用 `ensureFreshSession()`
3. **`ManagerConnection.ensureFreshSession()`**：已有逻辑，无需改动

## 文件清单

### 服务端（`tired-agent/packages/manager/src/`）

| 文件 | 改动 |
|------|------|
| `storage.ts` | ALTER TABLE migration；重写 `refreshSession`；新增 `confirmSession`；增强 `pruneExpired` |
| `auth.ts` | `registerAuth` 验证成功后调 `storage.confirmSession(token)` |
| `storage.test.ts` | 更新测试用例对齐新行为 |

### 客户端（`tired_agent_app`）

| 文件 | 改动 |
|------|------|
| `lib/main.dart` | `TiredAgentApp` + `WidgetsBindingObserver`，`didChangeAppLifecycleState` 处理 resume |
| `lib/providers/auth_provider.dart` | 新增 `refreshAllSessions()` |

## 不走的设计

- ❌ **时间窗口宽限**：用 30 秒/60 秒这样的固定窗口不能保证覆盖所有丢响应场景
- ❌ **存储 API Token 做 fallback**：API Token 是静态长期凭证，不应持久化在客户端
- ❌ **多 token 并行有效**：增加攻击面，没有明确的失效信号
- ❌ **客户端确认后回调**：增加一次额外 HTTP 往返，且回调也可能丢
