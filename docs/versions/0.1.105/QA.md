# 0.1.105 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.104 acceptance](../0.1.104/QA.md)

Local macOS preview. Public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Expanded card collapses to round bubble without a capsule-shaped border flash | Complete on macOS 27 | In the installed 0.1.105 app, two round-bubble → expanded-card → round-bubble cycles returned to the circular progress ring without a lingering card border in the resulting frame. The circular resting state switches content without cross-fading the old card surface before the window moves. The brief animation was not video-captured frame by frame. |
| Existing edge-tab and quota behavior | Complete on macOS 27 | The expanded card showed both quota windows with distinct green/red bars. The collapsed bubble kept its circular ring. Edge-tab behavior was not separately exercised in this focused check. |
| Regression | Complete | 197 Core and 4 App Swift tests, Windows checks, and release consistency passed. The installed 0.1.105 executable SHA-256 matches the local package. |
| Public release | Pending | No GitHub push or Release requested. |
