# 安装 ReadyCheck

## 系统要求

- Apple 芯片（arm64），macOS 14 Sonoma 或更高版本
- 连接 Codex OAuth 和刷新用量时需要网络

## 从发布页安装

1. 从 GitHub Release 下载 `ReadyCheck-<版本>-macos.dmg`。
2. 打开磁盘映像，将 `ReadyCheck.app` 拖入“应用程序”。
3. 从“应用程序”打开 ReadyCheck。

当前预览版使用稳定的 ReadyCheck 自签名身份，但尚未使用 Developer ID 签名或 notarization。更新后，macOS 可能再次要求确认访问已有钥匙串凭据。若 macOS 首次阻止打开，请进入“系统设置 > 隐私与安全性”，为 ReadyCheck 选择“仍要打开”。这是预览发行的分发限制，与 OAuth 无关。

## 连接账号

在“设置 → 连接”中点击“登录 ReadyCheck”，完成浏览器 OAuth 授权。正常情况下会通过 `localhost:1455` 回到应用；未能自动回调时，可在 ReadyCheck 中粘贴最终回调 URL。

点击“断开”会从 Keychain 移除 ReadyCheck 保存的 OAuth 凭据。

## 升级到 0.2.1

替换应用前请退出 ReadyCheck。既有设置、凭据和历史会保留；重建预览包可能仍需 macOS 钥匙串确认，必要时在设置 → 连接中重试读取凭据。总览保留订阅／主动重置／Credits 信息，侧栏底部或菜单栏更多可打开关于查看更新重点。Windows 为独立便携预览，沿用原界面。

旧贴边选项会迁移为自适应悬浮气泡，保留贴边位置；信息卡片仍独立，可拖动标题移动。更新要点集中在关于，不再放在连接设置。
