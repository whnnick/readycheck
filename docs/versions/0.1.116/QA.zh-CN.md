# 0.1.116 验收

[English](QA.md) | [版本索引](../../VERSIONS.md) | [0.1.115 验收](../0.1.115/QA.zh-CN.md)

状态：本地预览；尚未请求 GitHub 发布。[Codex App Server 账号接口](https://learn.chatgpt.com/docs/app-server#auth-endpoints)提供账号与套餐信息，但未记载当前结算日期。[OpenAI 账单说明](https://help.openai.com/en/articles/9039756-managing-billing-for-chatgpt-and-the-api-platform)指引个人订阅用户在 ChatGPT 设置 > 账单查看。

| 需求 | 状态 | 证据与待验收内容 |
| --- | --- | --- |
| 保留以前能显示的日期 | 已实现；有日期的界面场景待验 | 令牌里的未来日期继续显示为“订阅有效至”；已过去的日期显示为“上次记录有效至”，不把旧日期冒充当前结算周期。两种场景仍需受控快照验收。 |
| 解释日期缺失 | 预览版界面已验 | 当前本机 Codex 连接返回 Plus 和实时配额，但不提供订阅日期；主卡片显示“订阅日期 · 请在 ChatGPT 账单查看”，不再显示“未确认”。已在 macOS 检查首屏排版。 |
| 回归检查 | 已通过 | Swift 核心测试 198 项、应用测试 4 项通过；Windows 检查、版本一致性、稳定签名预览版打包和严格签名验证通过。 |
| 公开发布 | 未请求 | 公开 latest 仍为 0.1.114。 |
