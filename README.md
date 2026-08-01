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

| Secret | 说明 | 生成方式 |
|--------|------|---------|
| `KEYSTORE_BASE64` | keystore 文件 base64 编码（去掉换行） | `base64 -w0 tired-agent.keystore` |
| `KEYSTORE_PASSWORD` | keystore 密码 | `keytool -genkey` 时输入 |
| `KEY_PASSWORD` | 私钥密码（可与 store 同） | `keytool -genkey` 时输入 |
| `KEY_ALIAS` | 私钥别名 | `keytool -genkey -alias tired-agent` |

### 本地生成 keystore

```bash
cd android/app
keytool -genkey -v \
  -keystore tired-agent.keystore \
  -alias tired-agent \
  -keyalg RSA -keysize 2048 -validity 10000
```

生成后 base64 编码上传到 GitHub Secret：

```bash
base64 -w0 android/app/tired-agent.keystore > /tmp/keystore.b64
# 复制 /tmp/keystore.b64 内容到 KEYSTORE_BASE64
```

> **注意**：`android/key.properties` 和 `android/app/*.keystore` 已加入 `.gitignore`，本地调试时按需手动放置。