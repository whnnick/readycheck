# 0.1.128 验收

[English](QA.md) | [版本索引](../../VERSIONS.md) | [0.1.127 验收](../0.1.127/QA.zh-CN.md)

状态：0.1.128 预览发布版。macOS DMG 使用稳定预览签名，尚非 Developer ID 签名，也未公证。

| 需求 | 状态 | 证据与待验收内容 |
| --- | --- | --- |
| 独立 OAuth 登录与本机 Codex 为同一账号时恢复每日 Token 记录 | 本地通过 | 0.1.128 预览版显示每日 Token 图和账号汇总，配额卡片仍标明 OAuth API 来源；本机 app-server 只读检查返回 133 个每日记录。 |
| 不把另一个本机账号的 Token 记录算给 OAuth 账号 | 测试通过 | Provider 测试验证即使邮箱相同，也优先要求账号 ID 完全一致；不匹配时不附加 Token 记录，保留百分点图作为后备。 |
| 悬停 Token 柱显示日期和 Token 数 | 已实现，鼠标实测待验 | 原 Token 图的悬停提示代码保留。电脑界面工具确认了柱图数据，但未能产生原生悬停事件；实际鼠标复核仍待完成。 |
| 构建、测试、版本与签名 | 通过 | 公开同步检出中的 205 个 Core 测试和 4 个 App 测试通过；两个发行包通过完整性检查，DMG 中的应用通过严格签名校验。 |
| 公开发布 | 已发布 | [GitHub Release v0.1.128](https://github.com/whnnick/readycheck/releases/tag/v0.1.128) 包含 macOS DMG 与 Windows portable ZIP；latest 和资产下载均已验证。 |
