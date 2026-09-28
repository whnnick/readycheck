# 0.1.121 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.120 acceptance](../0.1.120/QA.md)

Status: local macOS preview; not published.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Edge colors represent actual remaining quotas | Passed in the live preview | With real Codex data near 21% (5-hour) and 73% (7-day), the red fill occupied roughly one fifth of its track and the green fill roughly three quarters. Both matched the ring values. Missing-data appearance still needs a live scenario. |
| Predictable, smooth expansion | Partially accepted | Clicking the handle reopened both rings; clicking a ring opened details, and leaving collapsed the panel. Source review confirms hover no longer opens details and Reduce Motion bypasses frame animation. Motion feel, both edges, and rapid click reversal still need hands-on acceptance. |
| Preserve other widget styles | Passed by regression scope | The style selector and bubble/card/notch paths are unchanged; the previous preview visually checked the round bubble. |
| Build and privacy | Passed locally | Full rerun: 204 core and 4 app tests passed. Version references matched 0.1.121; the stable-signed local app passed package verification. Sensitive-data scan is part of the local commit review. |

The handle's drag feel and a real user feel check remain manual acceptance items. Public release is separate.
