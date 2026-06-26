# ReadyCheck

[English](README.md) | 中文

ReadyCheck 是一款 macOS 菜单栏和桌面 widget 应用，用于查看 Codex 订阅额度窗口；刷新不会发送模型推理请求。

> 当前状态：`0.1.39` 为 macOS 早期预览版。本版本仅支持 Codex OAuth；Windows 和其他模型服务商尚未包含。

## 可以做什么

- 当已授权的用量数据可解析时，显示 Codex 5 小时与 7 天额度窗口。
- 提供主窗口、菜单栏摘要和可选的桌面悬浮 widget。
- 支持手动刷新以及每 1、3、5 分钟自动刷新。刷新只读取用量数据，不调用模型推理接口。
- OAuth 凭据存储在 macOS Keychain 中。
- 支持简体中文和英文。

ReadyCheck 采用保守策略：无法安全读取或验证额度数据时，显示不可用，而不会猜测百分比。

## 安装

从[最新发布页](https://github.com/whnnick/readycheck/releases/latest)下载 `ReadyCheck-0.1.39-macos.dmg`，打开 DMG 后将 `ReadyCheck.app` 拖入“应用程序”。

当前预览构建使用 ad-hoc 签名，尚未经过 Apple notarization。首次打开时，macOS 可能需要在“系统设置 > 隐私与安全性”中确认。详见[安装说明](docs/INSTALL.zh-CN.md)。

## 连接 Codex

1. 打开 ReadyCheck，点击“连接”。
2. 在浏览器完成 OAuth 授权。
3. ReadyCheck 接收本地回调并刷新可用额度窗口。

OAuth 回调监听 `localhost:1455`。若本地回调未成功接收，仍可手动粘贴回调 URL 完成授权。

## 从源码构建

要求：macOS 14 或更高版本、Xcode Command Line Tools、Swift 6。

```bash
swift test
scripts/package_app.sh
scripts/package_dmg.sh
```

DMG 输出到 `dist/ReadyCheck-0.1.39-macos.dmg`。

## 准确性与隐私

- 应用只读取已授权的 Codex 用量端点，不会通过发送 prompt 或调用模型来推测额度。
- 上游用量响应属于内部服务接口，可能变化。ReadyCheck 只有在解析器能够验证两个额度窗口时才显示百分比。
- OAuth token 存储在 Keychain 中；提交 GitHub Issue 时不要包含 token、回调 URL、账户 ID 或原始用量数据。
- 本项目与 OpenAI 没有隶属或背书关系。

## 文档

- [安装说明](docs/INSTALL.zh-CN.md) | [Install guide](docs/INSTALL.md)
- [发布流程](docs/RELEASE.zh-CN.md) | [Release process](docs/RELEASE.md)
- [参与贡献](CONTRIBUTING.md)
- [安全策略](SECURITY.md)
- [更新日志](CHANGELOG.zh-CN.md) | [Changelog](CHANGELOG.md)

## 反馈

请通过 [GitHub Issues](https://github.com/whnnick/readycheck/issues) 报告问题或提出建议。提交前请移除所有账号数据和凭据。

## 许可证

本项目使用 [MIT License](LICENSE)。
