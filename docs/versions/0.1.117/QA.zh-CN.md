# 0.1.117 验收

[English](QA.md) | [版本索引](../../VERSIONS.md) | [0.1.116 验收](../0.1.116/QA.zh-CN.md)

状态：本地预览；尚未请求 GitHub 发布。[Codex 官方协议](https://github.com/openai/codex/blob/main/codex-rs/app-server-protocol/src/protocol/v2/account.rs)中的 `ordinaryUsageAllowed` 为可选值；未返回时不能据此确认使用许可。[OpenAI 账单指引](https://help.openai.com/en/articles/9039756-managing-billing-for-chatgpt-and-the-api-platform)说明了查看订阅日期的入口。

| 需求 | 状态 | 证据与待验收内容 |
| --- | --- | --- |
| 将普通用量许可与额度百分比分开 | 缺失字段场景预览界面已验；真实 `true`/`false` 待验 | 解析与数据源测试覆盖 `true`、`false`、缺失字段。稳定签名的 0.1.117 预览版面对当前未返回该字段的本机 Codex app-server，显示“可用性未确认”，同时保留有效的 5 小时和 7 天百分比。已验证的额度回升仍独立提醒。 |
| 明确说明已选窗口回退 | 已实现；切换账号界面待验 | 已保存窗口缺失时，设置中保留原选择并提示临时回退目标。单元测试覆盖已选、缺失和旧偏好。实际切换账号与重启待 macOS 验收。 |
| 日期缺失时提供账单操作 | 预览界面已验；外部跳转待验 | 稳定签名预览版在缺失日期的行显示指向 OpenAI 账单指引的可访问链接。令牌里未来与过去日期的界面验收仍待完成，见 [0.1.116](../0.1.116/QA.zh-CN.md)。 |
| 悬浮气泡轮廓和展开动效 | 保留现有实现；真实环境待验 | 在浅色和深色背景复查圆球、贴边胶囊、展开卡片、拖动与展开收起。本版未修改动效代码。 |
| 回归检查 | 已通过 | Swift 核心测试 200 项、应用测试 4 项、Windows 检查、版本一致性、macOS 稳定签名预览版打包和严格签名验证均通过。 |
| 公开发布 | 未请求 | 本任务不创建 tag、不推送 GitHub、不发布 Release。 |
