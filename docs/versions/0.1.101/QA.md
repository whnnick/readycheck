# 0.1.101 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.100 acceptance](../0.1.100/QA.md)

Local macOS preview installed and accepted on this Mac. Public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Readable right-edge surface | Complete on macOS 27 | The running app displayed a 66 × 114-point capsule with the installed Codex icon, selected `5h` window, verified remaining percentage, colored vertical progress rail, and inward chevron. The prior tab was 32 × 72 points. |
| Expand and quota detail | Complete on macOS 27 | Clicking the live right-edge capsule opened the two-window quota card, with current values and independent urgency colors. |
| Position and opposite edge | Partial | Placement tests cover right and left edge geometry plus restoration from the previous small tab. Left-edge visual interaction has not yet been live-tested. |
| Regression | Complete | Full Swift and Windows checks passed; release version references are consistent. |
| Public release | Pending | No GitHub push or Release requested. |

The installed 0.1.101 executable SHA-256 matches the tested package. The local package uses `ReadyCheck Preview Signing`; this does not establish Developer ID trust or notarization.
