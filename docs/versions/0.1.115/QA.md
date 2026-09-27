# 0.1.115 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.114 acceptance](../0.1.114/QA.md)

Status: local development preview; no GitHub release has been requested. [Codex App Server documentation](https://learn.chatgpt.com/docs/app-server) defines optional quota windows, variable durations, multiple limit IDs, and version-specific schema generation.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Show quota before configuration | Preview UI verified | The stable-signed preview places quota and recovery monitoring directly after connection/refresh status. The first viewport was inspected in macOS; display controls are collapsed below quota. |
| Select an actual quota window | Tests and preview UI verified | The live account's picker showed Automatic, 5-hour, and 7-day windows; switching to Automatic and restoring the prior 5-hour choice worked. A missing saved choice resolves to an available window; the bubble and notch use the same resolver and actual duration labels. Single-window, multiple-ID, unknown-duration, account-switch, and relaunch UI cases remain to be checked. |
| Explain stale and subscription data | Partly preview UI verified | The preview showed “Subscription active until · Unconfirmed”, but that UI alone could not establish whether the token claim was absent or past. The expanded bubble has a stale-data marker in code; stale/future-date visual cases remain to be checked. |
| Regression checks | Passed | Full Swift suite: 202 tests passed, including the localhost OAuth callback test. Windows checks and version consistency passed. The preview app was packaged with stable signing and passed strict signature verification. macOS first-viewport and picker interactions were inspected. |
| Public release | Not requested | The public latest release remains 0.1.114. |
