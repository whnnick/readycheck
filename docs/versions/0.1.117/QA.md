# 0.1.117 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.116 acceptance](../0.1.116/QA.md)

Status: local preview; no GitHub release requested. The [official Codex protocol](https://github.com/openai/codex/blob/main/codex-rs/app-server-protocol/src/protocol/v2/account.rs) defines optional `ordinaryUsageAllowed`: `null` does not confirm usage permission. The [OpenAI billing guide](https://help.openai.com/en/articles/9039756-managing-billing-for-chatgpt-and-the-api-platform) explains where to check a subscription date.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Separate ordinary-use permission from quota percentages | Preview UI verified for absent field; live `true`/`false` pending | Parser and provider tests cover `true`, `false`, and absent fields. The signed 0.1.117 preview showed “Usage status unknown” alongside valid 5-hour and 7-day percentages from the currently installed Codex app-server, which omits the field. A verified increase still triggers the separate quota-increase alert. |
| Make saved-window fallback explicit | Implemented; account-switch UI pending | A missing saved window remains selected in Settings with a temporary fallback explanation. Unit tests cover selected, missing, and legacy preferences. Real account switching and restart need macOS acceptance. |
| Give a billing action when no subscription date is returned | Preview UI verified; external click-through pending | The signed preview displayed an accessible link to OpenAI's billing guide in the missing-date row. Future and past token-date UI still need controlled-snapshot acceptance; see [0.1.116](../0.1.116/QA.md). |
| Floating bubble shape and transition | Existing implementation; real-environment check pending | Recheck circle, edge tab, expanded card, drag, and expand/collapse on light and dark backgrounds. No motion code changed in this version. |
| Regression checks | Passed | 200 core and 4 app Swift tests, Windows checks, release-version consistency, signed macOS preview packaging, and strict signature verification passed. |
| Public release | Not requested | No tag, GitHub push, or Release in this task. |
