# 0.7.0 — Reporting sources / 统计数据依据

[English plan](PLAN.md) · [中文计划](PLAN.zh-CN.md)

Scope corrected 2026-10-30: usage monitoring only. Earlier model-invocation research is not evidence that statistics can be read. / 范围已修正为用量监控，先前模型调用调研不能证明统计可读。

Documentation reviewed 2026-10-29; no new provider has been tested with a real account. Revalidate eligibility, permission and fields at implementation. / 官方文档核对日期为2026-10-29；新增服务均未真实接入验收，开发时需复核权限和字段。

| Source / 来源 | Relevance / 统计含义 | Open acceptance / 待验证 |
| --- | --- | --- |
| [OpenAI organization Usage and Costs](https://developers.openai.com/api/reference/cli/resources/admin/subresources/organization/subresources/usage) | Organization reporting / 组织统计 | Eligible role/key, project scope and reporting delay / 账号权限、项目范围及延迟 |
| [ChatGPT and API billing](https://help.openai.com/en/articles/9039756-managing-billing-for-chatgpt-and-the-api-platform) | Separate billing systems / 不同计费系统 | Keep Codex subscription and API reporting distinct / 分开订阅与API统计 |
| [Claude Usage and Cost API](https://platform.claude.com/docs/en/manage-claude/usage-cost-api) | Organization reporting requires eligible management credentials / 组织统计需要相应管理凭据 | Individual/subscription reporting cannot be assumed / 不假定个人订阅可读 |
| [Claude subscription and API](https://support.claude.com/en/articles/9876003-i-have-a-paid-claude-subscription-pro-max-team-or-enterprise-plans-why-is-claude-api-usage-billed-separately-from-my-paid-claude-plan) | Different products / 不同产品 | Distinguish subscription quota from API usage / 区分订阅额度和API用量 |
| [Gemini billing and usage dashboard](https://ai.google.dev/gemini-api/docs/billing) | Official dashboard is documented / 官方控制台可查看 | Supported read API and permissions for ReadyCheck are not established / 本应用可用的读取接口与权限尚未证实 |
| [DeepSeek balance](https://api-docs.deepseek.com/api/get-user-balance/) | Official balance endpoint / 官方余额接口 | Validate account, currency and freshness; usage history is a separate question / 核实账号、币种及更新时间；另行验证用量历史 |
| [Qwen/Model Studio regions](https://help.aliyun.com/zh/model-studio/regions) | Regional access differs / 地域接入有差异 | Statistics source, plan and permissions not verified / 统计来源、套餐及权限待验 |

The retired three chat concepts were generated previews only, not product functionality or implementation targets. / 已撤回的三张对话概念稿仅为预览，不代表产品功能，也不是实现目标。

## CodexBar provider discovery — historical broad research / 初期广泛调研归档

[CodexBar README providers](https://github.com/steipete/CodexBar/blob/main/README.md#providers) and [provider overview](https://github.com/steipete/CodexBar/blob/main/docs/providers.md) currently enumerate 110 provider entries. The prototype catalog records these names and reference URLs as a discovery snapshot, with locally assigned browsing categories and summarized method/metric hints. It is not ReadyCheck support proof. / 当天核对 110 个服务入口；原型保留名称和来源链接，分类及指标/方式是发现线索，不是 ReadyCheck 支持证明。

- [Claude](https://github.com/steipete/CodexBar/blob/main/docs/claude.md): OAuth, browser, CLI and optional Admin reporting are distinct paths. / 订阅、管理统计、本机记录须分别核实，不混用账号。
- [Gemini](https://github.com/steipete/CodexBar/blob/main/docs/gemini.md): CLI OAuth and optional Gemini-app web sources are separate. / CLI、应用、API 平台的身份和额度不互补，适用套餐需实测。
- [OpenAI](https://github.com/steipete/CodexBar/blob/main/docs/openai.md): organization API usage/costs, separate from Codex subscription. / 组织统计不能视为订阅额度。
- [DeepSeek](https://github.com/steipete/CodexBar/blob/main/docs/deepseek.md): API-key balance versus optional private Platform-session detailed usage. / 普通 Key 不能认证其私有网站用量接口；原型仍仅演示余额。

No new provider credentials, browser sessions, CLI credentials or API calls were used. Upstream code is a technical reference; official support, permission and stability still require verification. Codex retains ReadyCheck's current OAuth-only primary connection; this research does not restore the removed local-Codex login. / 未读取新增服务凭据或会话，也未请求真实统计；上游实现只是技术参考，官方适用性和稳定性待验。Codex 保持现有 OAuth 单主入口。

## Approved ten-service scope — 2026-10-30 / 已确认十家范围

The current prototype selects only Codex, Claude, Gemini, DeepSeek, Cursor; GitHub Copilot, Alibaba/Bailian Coding Plan, GLM Coding Plan, Kimi Code and MiniMax Coding Plan. The broader upstream list is a reference, not a current product promise. / 当前目录仅保留已确认十家，其他上游条目不进入本次产品承诺。

Additional per-service upstream documents reviewed today: [Cursor](https://github.com/steipete/CodexBar/blob/main/docs/cursor.md), [Copilot](https://github.com/steipete/CodexBar/blob/main/docs/copilot.md), [Alibaba Coding Plan](https://github.com/steipete/CodexBar/blob/main/docs/alibaba-coding-plan.md), [GLM](https://github.com/steipete/CodexBar/blob/main/docs/zai.md), [Kimi Code](https://github.com/steipete/CodexBar/blob/main/docs/kimi.md), [MiniMax](https://github.com/steipete/CodexBar/blob/main/docs/minimax.md). These expose different source/permission/region constraints and do not establish ReadyCheck eligibility. / 当天复核上述上游接入说明，来源、权限、地域不同，仍不能替代本应用实测。

The [official DeepSeek balance response](https://api-docs.deepseek.com/api/get-user-balance/) was rechecked: per-currency total, granted and topped-up amounts plus the independent availability flag. This documented read path makes it the first new implementation slice; it does not provide Token or cost history. / 已复核官方余额响应：按币种金额及独立可用标记，因此先做这一条新接入；不将其称为 Token/费用历史。 See [technical scope](TECHNICAL.md) / [技术范围](TECHNICAL.zh-CN.md). No real API request or credential access was performed.

## Official source review — 2026-10-31 / 官方来源复核

- [Claude Usage and Cost Analytics API](https://platform.claude.com/docs/en/manage-claude/usage-cost-analytics-api) reports organization usage and costs, with different credentials for Claude Console and eligible Claude Enterprise organizations. This does not establish a personal subscription quota API. / 该接口统计组织用量及费用，Console 与符合条件的 Enterprise 凭据不同；不能据此认定个人订阅额度可读。
- [Gemini Code Assist monitoring](https://docs.cloud.google.com/gemini/docs/codeassist/monitor-gemini-code-assist) describes project-level metrics and Cloud Monitoring permissions; its token counts are not per-user and its recording is limited to IDE interactions. This is not evidence of an individual Gemini CLI subscription quota. / 该文档说明项目级指标及监控权限；Token 数不按个人统计，记录范围限定于 IDE 交互，不能当成个人 Gemini CLI 订阅额度。
- [Cursor usage analytics](https://cursor.com/docs/account/teams/analytics) documents team analytics and Enterprise API access; [Admin API](https://docs.cursor.com/en/account/teams/admin-api) uses administrator-created credentials. This does not establish a public personal-plan API. / 官方文档说明团队统计、Enterprise API 和管理员凭据，不能据此认定个人套餐有公开统计接口。

These are source-scope findings only, without account access or live integration acceptance. / 以上仅为来源和范围核对，未访问账号，也未完成真实接入验收。

Further candidates, not yet integrated or validated against an account / 后续候选，尚未接入或用账号验证：

- [Gemini CLI documentation](https://github.com/google-gemini/gemini-cli/blob/main/docs/get-started/index.md) describes `/stats model` in the interactive CLI, with session token statistics and quota information for supported models. An unattended, stable machine-readable read path, account identity and behavior across CLI versions remain unverified. / 官方文档说明交互式 `/stats model` 可显示当前会话 Token 及支持模型的配额信息；稳定的无人值守机器可读方式、账号归属和跨版本行为仍待验证。
- [Model Studio CLI usage and quota](https://help.aliyun.com/en/model-studio/cli/usage-quota) documents `bl usage coding-plan --output json` for the second-batch Coding Plan. Account permissions, response schema, regional support and live behavior remain unverified; do not substitute general model billing or use inference as a probe. / 官方 CLI 文档列出第二批百炼 Coding Plan 的 JSON 用量查询；账号权限、返回结构、地域和真实行为待验，不以通用账单或模型调用代替。
- [GitHub billing usage API](https://docs.github.com/en/rest/billing/usage) distinguishes personally billed Copilot usage from organization-billed licenses. Reported billing usage is not automatically a remaining-quota value; permissions, fields and entitlement coverage remain to be checked. / GitHub 账单用量接口区分个人付费和组织付费；账单用量不能自动视为剩余额度，权限、字段及覆盖范围待核实。

## Gemini app source selected — 2026-10-31 / 选择 Gemini 网页与手机应用

The user confirmed they use the Gemini website or mobile app, not Gemini CLI as the requested source. Google documents the [Gemini Apps usage-limits page](https://support.google.com/gemini/answer/16275805), while its [work and school guidance](https://support.google.com/gemini/answer/14620100) says Gemini Apps usage across devices counts toward the same limits. [CodexBar's implementation record](https://github.com/steipete/CodexBar/pull/4535) describes an undocumented web response with independent five-hour and weekly fractions; it is a third-party implementation reference, not a Google-supported API guarantee. / 用户确认使用 Gemini 网页或手机 App。Google 官方说明使用量限制页面，工作或学校账号指南说明 Gemini Apps 的跨设备用量计入同一限制。CodexBar 的实现记录描述了非公开网页响应中的 5 小时和每周占用比例；该记录是第三方实现线索，不代表 Google 承诺接口稳定。

An offline parser and an unwired read-only client are being tested against synthetic data only. Account selection, an explicitly authorized connection, response changes, session isolation and real read-only verification remain open. No Google browser cookie, session, credential or account data has been read. CLI, API-platform and Gemini app data must never silently substitute for one another. / 当前仅用合成数据测试离线解析和未接线的只读客户端；账号选择、用户明确授权的连接、响应变化、会话隔离和真实只读验收仍待完成。没有读取 Google 浏览器 Cookie、会话、凭据或账号数据；CLI、API 平台与 Gemini App 的数据不可静默互换。
