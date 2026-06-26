# 安装 ReadyCheck

## 系统要求

- macOS 14 Sonoma 或更高版本
- 连接 Codex OAuth 和刷新用量时需要网络

## 从发布页安装

1. 从 GitHub Release 下载 `ReadyCheck-<版本>-macos.dmg`。
2. 打开磁盘映像，将 `ReadyCheck.app` 拖入“应用程序”。
3. 从“应用程序”打开 ReadyCheck。

当前预览版使用 ad-hoc 签名，尚未 notarization。若 macOS 首次阻止打开，请进入“系统设置 > 隐私与安全性”，为 ReadyCheck 选择“仍要打开”。这是预览发行的分发限制，与 OAuth 无关。

## 连接账号

在应用中点击“连接”，完成浏览器 OAuth 授权。正常情况下会通过 `localhost:1455` 回到应用；未能自动回调时，可在 ReadyCheck 中粘贴最终回调 URL。

点击“断开”会从 Keychain 移除 ReadyCheck 保存的 OAuth 凭据。
