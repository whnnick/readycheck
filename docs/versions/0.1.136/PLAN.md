# 0.1.136: continuous orbital bubble

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Versions](../../VERSIONS.md)

Implement the selected concentric-ring design with reduced separation between the detail wing and the round dial.

| Requirement | Success criterion |
| --- | --- |
| Continuous exterior | One background, outline and window mask. No separate dial bezel, disconnected card, neck gap or rectangular transparent fringe. |
| Real quota rings | Primary selection drives the outer ring; the next returned window drives the inner ring. Labels and percentages in details preserve correspondence, all additional windows remain scrollable. Unknown/stale data remains unknown. |
| Transitions / placement | Geometry and dial scale continuously. Half-second hover, click pinning, Esc/outside dismissal and drag intent remain. Free bubbles expand toward available space and retain their dial center unless clamped; edge bubbles expand inward. |
| Recent hour | Twelve five-minute bins from existing local samples. Known zero differs from missing data; exclude invalid/future values, missing-window boundaries, recovery, reset changes and gaps over ten minutes. No extra polling or Token conversion. |
| Compatibility | Preserve C branding, severity colors, account/notification identity, full-screen setting, card/edge/notch entries and saved positions. Windows metadata only. |

The current change targets the chosen round-bubble design. Main-window reorganization and other visual directions remain subsequent work. Local preview installation and a verified local commit are the delivery for this iteration.
