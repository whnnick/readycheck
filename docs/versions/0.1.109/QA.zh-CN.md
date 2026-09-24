# 0.1.109 验收

[English](QA.md) | [版本索引](../../VERSIONS.md) | [0.1.108 验收](../0.1.108/QA.zh-CN.md)

macOS 预览版已于 2026-09-24 发布。

| 需求 | 状态 | 证据 |
| --- | --- | --- |
| 收紧桌面 Widget 卡片底部空白 | 已完成 | Widget 分组不再设最小高度。安装版的气泡样式在最后一个样式控件后结束，只保留常规的 14 点卡片内边距。 |
| 气泡与卡片样式 | 已完成 | 已在安装的 0.1.109 应用中目视检查两种样式：卡片样式的附加控件完整显示，切回气泡后卡片自动收高；已恢复原来的气泡选择。 |
| 构建及版本一致性 | 已完成 | public-sync 中的 Swift 测试通过（197 项 Core、4 项 App），版本引用检查通过；Windows 打包的 check、smoke、UI smoke 通过。0.1.109 DMG 内的 App 使用 ReadyCheck Preview Signing 签名并通过严格签名校验，Windows ZIP 通过完整性测试。 |
| 公开发布 | 已完成 | [GitHub Release v0.1.109](https://github.com/whnnick/readycheck/releases/tag/v0.1.109) 已发布，非草稿；latest-release 接口返回 v0.1.109；标签指向提交 `02efec5`，该提交位于远端 `main`。两个附件已上传，GitHub 返回的 SHA-256 与下方本地安装包一致。 |

| 发布附件 | SHA-256 |
| --- | --- |
| `ReadyCheck-0.1.109-macos.dmg` | `e0358634dde3dd6ecb31263ccd1492e6dc35e49bf983bc064acaafb451984e40` |
| `ReadyCheck-0.1.109-windows-x64-portable.zip` | `1ceee5786ab97aadfb9e303b51ffe1d07f3699bf6b0d4c21c78a928db64852f0` |
