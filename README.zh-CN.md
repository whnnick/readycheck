# ReadyCheck

[English](README.md) | 中文

ReadyCheck 是一款 macOS 菜单栏和桌面 widget 应用，用于查看 Codex 订阅额度窗口；刷新不会发送模型推理请求。

<p align="center">
  <img src="docs/assets/readycheck-preview.gif" alt="ReadyCheck 产品预览" width="860">
</p>

> 最新发布版：[`0.1.113`](https://github.com/whnnick/readycheck/releases/tag/v0.1.113)。本版完善额度气泡和显示设置；恢复提醒仅支持 macOS。

## 可以做什么

ReadyCheck **0.1.113** 保留可拖动额度气泡、贴边胶囊、卡片和刘海显示。气泡使用稳定深色表面，并在窗口层按圆球、贴边或展开卡片轮廓裁切，避免外侧出现方形底。主窗口按功能整理显示设置，两组共用配额窗口选择。参见 [0.1.113 验收状态](docs/versions/0.1.113/QA.zh-CN.md)。

气泡在运行时读取已安装 Codex 或 ChatGPT 的应用图标。Codex、ChatGPT 及其标志归 OpenAI 所有；ReadyCheck 是独立项目，并[遵循 OpenAI 品牌规范](https://openai.com/brand/)。

- 根据 Codex 当前实际返回动态展示经过验证的额度窗口，不预设固定为 5 小时或 7 天。
- 当已授权的用量数据提供对应字段时，在主窗口和详细 Widget 中显示 Credits 余额或无限额度状态。
- 本机 Codex 已安装且登录同一账户时，优先使用官方 app-server，并提供 7/30/90 天账户 Token 使用看板。
- 提供主窗口、菜单栏摘要和可选的桌面悬浮 widget。
- 在支持的 Mac 内置刘海屏下方提供可选的紧凑额度状态条。
- 官方本机 Codex app-server 报告额度变化时及时刷新，同时保留手动刷新和每 1、3、5 分钟只读轮询作为兜底；所有刷新均不调用模型推理接口。
- 对仍未使用的主动重置，在到期前 72、48、24、12 小时分别发送系统提醒；额度用尽后再次开始消耗 Codex Credits 时也会提醒。
- 官方 Token 历史不可用时，保留明确标注的本地额度下降看板作为降级方案。
- OAuth 凭据存储在 macOS Keychain 中。
- 支持简体中文和英文。

ReadyCheck 采用保守策略：无法安全读取或验证额度数据时，显示不可用，而不会猜测百分比。

## 额度恢复自动提醒（macOS 0.1.98）

**额度恢复自动提醒** 默认开启，始终显示在主窗口和菜单栏的额度区域下方。任一已观察窗口的剩余额度回升就提醒，无需先耗尽，也无需等待其他窗口恢复。正常消耗和重复刷新不提醒，首次读取只建立基线。请保持 ReadyCheck 运行；未观察到的历史恢复不会补发通知。

恢复后的额度再次开始下降时，ReadyCheck 会自动从通知中心移除对应的持续提醒。新的恢复会替换旧恢复提醒，已完成的提醒不会不断堆积。

关闭开关会停止监听并取消当前等待。开关与等待状态在重启后保留，切换账号会清除旧账号的等待。连接、数据或投递异常会就地说明；系统通知关闭时提供设置入口。“测试通知”按钮在测试后仍可点击，结果单独显示。

本次恢复提醒仅支持 macOS；Windows 同步版本号。参见[功能与黑盒验收清单](docs/QA.zh-CN.md#0193-自动恢复提醒交互)。

## 安装

从[最新发布页](https://github.com/whnnick/readycheck/releases/latest)下载已发布的 macOS DMG，打开 DMG 后将 `ReadyCheck.app` 拖入“应用程序”。

Windows 10/11 预览测试可从同一个发布页下载已发布的 Windows 便携 ZIP，解压后运行 `ReadyCheck.exe`。

当前预览构建使用稳定的 ReadyCheck 自签名身份，但尚未使用 Developer ID 签名或经过 Apple notarization。首次打开时，macOS 可能需要在“系统设置 > 隐私与安全性”中确认。详见[安装说明](docs/INSTALL.zh-CN.md)。

## 连接 Codex

1. 打开 ReadyCheck，保持选择“使用本机 Codex”，直接复用这台 Mac 上 Codex 或 ChatGPT 已登录的账号。
2. 如果本机 app-server 不可用，选择“独立 OAuth”，点击“连接”并在浏览器完成授权。
3. ReadyCheck 只刷新该连接返回的额度与用量数据。

OAuth 回调监听 `localhost:1455`。若本地回调未成功接收，仍可手动粘贴回调 URL 完成授权。

## 从源码构建

要求：macOS 14 或更高版本、Xcode Command Line Tools、Swift 6。

```bash
swift test
scripts/package_app.sh
scripts/package_dmg.sh
```

开发版 DMG 输出到 `dist/ReadyCheck-0.1.113-macos.dmg`；Windows 打包脚本的输出名为 `ReadyCheck-0.1.113-windows-x64-portable.zip`。

## Windows 预览版开发

Windows 客户端已作为 Electron 桌面应用在 [`apps/windows`](apps/windows/README.md) 启动。当前包含托盘、主窗口、桌面 widget、Codex OAuth、安全 token 存储和只读 usage 刷新；已提供便携版 zip 供 Windows 10/11 黑盒测试，但还没有签名安装器。

## 产品动效

README 预览动图从 [`marketing/remotion`](marketing/remotion/README.md) 的 Remotion 产品介绍视频生成。

```bash
cd marketing/remotion
npm install
npm run dev
```

## 准确性与隐私

- 应用优先使用官方本地 Codex app-server，否则读取已授权的 Codex 用量端点；两条路径都不会发送 prompt 或调用模型。
- 本机模式在官方账号 ID 可用时用它隔离提醒状态；独立 OAuth 仅接受与 OAuth 账号匹配的 app-server 补充数据。降级用量响应属于内部服务接口，可能变化，因此 ReadyCheck 只显示可以验证的字段。
- OAuth token 存储在 Keychain 中；提交 GitHub Issue 时不要包含 token、回调 URL、账户 ID 或原始用量数据。
- 本项目与 OpenAI 没有隶属或背书关系。

## 文档

- [0.1.113 悬浮窗遮罩验收](docs/versions/0.1.113/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.113/QA.md) | [版本索引](docs/VERSIONS.md)
- [0.1.112 气泡轮廓验收](docs/versions/0.1.112/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.112/QA.md)
- [0.1.111 气泡圆角验收](docs/versions/0.1.111/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.111/QA.md)
- [0.1.110 气泡可读性验收](docs/versions/0.1.110/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.110/QA.md)
- [0.1.109 Widget 间距验收](docs/versions/0.1.109/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.109/QA.md)
- [0.1.108 共用配额选择验收](docs/versions/0.1.108/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.108/QA.md)
- [0.1.107 显示间距验收](docs/versions/0.1.107/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.107/QA.md)
- [0.1.106 显示控件分组验收](docs/versions/0.1.106/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.106/QA.md)
- [0.1.105 圆球收起验收](docs/versions/0.1.105/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.105/QA.md)
- [0.1.104 形状切换验收](docs/versions/0.1.104/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.104/QA.md)
- [0.1.103 动效与玻璃验收](docs/versions/0.1.103/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.103/QA.md)
- [0.1.102 额度切换验收](docs/versions/0.1.102/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.102/QA.md)
- [0.1.101 贴边标签验收](docs/versions/0.1.101/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.101/QA.md)
- [0.1.100 气泡验收](docs/versions/0.1.100/QA.zh-CN.md) | [English acceptance](docs/versions/0.1.100/QA.md)
- [0.1.99 气泡计划](docs/versions/0.1.99/PLAN.zh-CN.md) | [English plan](docs/versions/0.1.99/PLAN.md)

- [安装说明](docs/INSTALL.zh-CN.md) | [Install guide](docs/INSTALL.md)
- [真实场景验收](docs/QA.zh-CN.md) | [Real-world QA checklist](docs/QA.md)
- [Windows 开发计划](docs/WINDOWS.zh-CN.md) | [Windows development plan](docs/WINDOWS.md)
- [Windows 黑盒测试](docs/WINDOWS_QA.zh-CN.md) | [Windows black-box QA](docs/WINDOWS_QA.md)
- [发布流程](docs/RELEASE.zh-CN.md) | [Release process](docs/RELEASE.md)
- [参与贡献](CONTRIBUTING.md)
- [安全策略](SECURITY.md)
- [更新日志](CHANGELOG.zh-CN.md) | [Changelog](CHANGELOG.md)

## 反馈

请通过 [GitHub Issues](https://github.com/whnnick/readycheck/issues) 报告问题或提出建议。提交前请移除所有账号数据和凭据。

## 许可证

本项目使用 [MIT License](LICENSE)。
