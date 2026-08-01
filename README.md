# tired_agent_app

Flutter mobile client for tired-agent.

## CI / Release

Tag 触发 GitHub Actions（`.github/workflows/flutter_build.yml`），并行构建 windows / linux / android 三个平台产物，自动从 `CHANGELOG.md` 提取本版本 release notes 写入 GitHub Release。

```bash
git tag v1.0.0            # tag 命名规范：v<version>
git push origin v1.0.0    # push 后 CI 自动起跑
```

### GitHub Secrets 配置（Android 签名）

CI 注入 4 个 Secret 到 `android/key.properties` + `android/app/tired-agent.keystore`：

| Secret | 说明 |
|--------|------|
| `KEYSTORE_BASE64` | keystore 文件 base64 编码（去掉换行）。生成：`base64 -w0 keystore文件` |
| `KEYSTORE_PASSWORD` | keystore 密码（不要写进 README/CLAUDE.md，只放 GitHub Secret） |
| `KEY_PASSWORD` | 私钥密码（可与 store 同） |
| `KEY_ALIAS` | 私钥别名，本项目用 `tired-agent` |

### 复用已有 keystore（推荐）

多个 applicationId 共用同一 keystore 完全合法 —— Android 按「包名 + 签名指纹」识别身份，签名指纹相同即可同源升级。

```bash
# 直接用你已有的 keystore：
cp path/to/your.keystore android/app/tired-agent.keystore
# 或在 CI 里把这份 keystore base64 上传到 KEYSTORE_BASE64，alias 填 tired-agent
```

### 本地生成新 keystore

```bash
cd android/app
keytool -genkey -v \
  -keystore tired-agent.keystore \
  -alias tired-agent \
  -keyalg RSA -keysize 2048 -validity 10000
```

> **注意**：`android/key.properties` 和 `android/app/*.keystore` 已加入 `.gitignore`，本地调试时按需手动放置。**真实密码只放 GitHub Secret 配置面板，不要提交任何代码或文档。**