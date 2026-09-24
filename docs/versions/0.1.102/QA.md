# 0.1.102 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.101 acceptance](../0.1.101/QA.md)

Local macOS preview installed on this Mac. Public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Switching quota windows does not imply recovery | Complete | A regression test changes from 5-hour 6% to 7-day 18% and confirms no recovery border; selecting the 7-day window in the running app updated the selection and displayed quota. |
| Real increase in the same window still highlights | Complete | A regression test confirms a same-selection, same-window increase highlights; a decrease, missing ratio or changed window ID does not. |
| Existing bubble and edge capsule | Complete on macOS 27 | The 0.1.102 app built and launched with the existing floating surface. The visual layout remains as recorded in [0.1.101](../0.1.101/QA.md). |
| Regression | Complete | 197 Core and 4 App Swift tests passed, including two new quota-switch tests. Windows checks passed and release version references are consistent. |
| Public release | Pending | No GitHub push or Release requested. |

The installed 0.1.102 executable SHA-256 matches the tested package. The local package uses `ReadyCheck Preview Signing`; this does not establish Developer ID trust or notarization.
