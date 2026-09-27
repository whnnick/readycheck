# 0.1.118 验收

[English](QA.md) | [版本索引](../../VERSIONS.md) | [0.1.117 验收](../0.1.117/QA.zh-CN.md)

状态：0.1.118 已发布。[Codex 官方后端客户端](https://github.com/openai/codex/blob/main/codex-rs/backend-client/src/client/rate_limit_resets.rs)将用量响应中的 `rate_limit.allowed` 映射为 `ordinaryUsageAllowed`，没有依据额度百分比推断。ReadyCheck 的独立 OAuth 模式读取同一用量接口。

| 需求 | 状态 | 证据与待验收内容 |
| --- | --- | --- |
| 通过独立 OAuth 显示后端许可 | 真实账号通过；未装本机 Codex 的环境待验 | 已签名预览版在“单独登录”模式显示“OAuth API · 已验证”和“Codex 可用”；手动刷新后配额更新，来源和状态保持不变。此模式不会向数据源注入本机 app-server。数据源和解析测试覆盖 true、false、缺失值，且与百分比无关。尚未在没有安装 Codex 的 Mac 上实测。 |
| 区分未知与受限 | 已实现；真实 null 响应待验 | `rate_limit.allowed` 缺失或为空时保持“可用性未确认”；false 表示“使用受限”。百分比和重置时间不会补全许可。 |
| 钥匙串阻止后台读取时恢复已保存的 OAuth 登录 | 真实凭据读取已恢复；系统提示操作未观察 | 已签名的 0.1.118 预览界面在钥匙串阻止读取时出现“重试读取”。再次验收时已可读取保存的登录信息，独立 OAuth 刷新成功。电脑操作工具无法查看或操作系统授权提示，因此无法确认具体授权动作。之后已恢复原先的本机 Codex 模式。 |
| 回归与打包 | 通过 | 201 个核心、4 个应用测试（包含 OAuth 回环）、Windows 检查／冒烟测试／打包及版本一致性检查通过。最终 DMG 挂载后确认 0.1.118 版本和稳定预览签名有效；Windows ZIP 通过 `unzip -t`，Windows 生产依赖审计为零项漏洞。 |
| 公开发布 | 已发布 | [GitHub Release v0.1.118](https://github.com/whnnick/readycheck/releases/tag/v0.1.118) 包含 macOS DMG 与 Windows 便携 ZIP。预览签名身份不是 Developer ID 证书，macOS 包尚未公证。 |
