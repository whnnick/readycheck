# 0.1.100 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.99 plan](../0.1.99/PLAN.md)

Local macOS preview installed on this Mac. Public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Smooth bubble dragging | Complete on macOS 27 | Window movement now follows the absolute screen pointer instead of repeatedly applying a gesture translation in the moving view. A live drag moved the saved frame by the expected pointer distance; dragging to the right edge still snapped into a tab. |
| Larger target | Complete on macOS 27 | Circular bubble grew from 64 to 76 points; the edge tab grew from 28 × 64 to 32 × 72 points. The running app displayed the larger icon, percentage and ring. Saved 0.1.99 frames restore at the new size. |
| Expanded quota colors | Complete on macOS 27 | Live validated 5-hour and 7-day quotas displayed independently as orange and red, matching the main quota card's urgency scale. |
| Regression | Complete | 197 Core and 2 App Swift tests passed, including saved-position migration and screen-pointer movement. Windows version metadata is synchronized. |
| Additional hardware | Pending | Continuous hand-drag feel, left-edge snap and display unplugging still merit testing on other Macs. |

The installed 0.1.100 executable SHA-256 matches the tested package. The local package uses `ReadyCheck Preview Signing`; this does not establish Developer ID trust or notarization. The [0.1.99 acceptance](../0.1.99/QA.md) covers the original bubble, card and notch interactions.
