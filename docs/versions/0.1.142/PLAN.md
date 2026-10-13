# 0.1.142: Direct inward dragging

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Version index](../../VERSIONS.md)

Problem: hover details can intercept an inward drag after docking, requiring a preliminary vertical drag.

| Requirement | Success criterion |
| --- | --- |
| Direct dragging | The first horizontal inward drag undocks either edge rail; expanded dials can also be dragged. |
| Pointer capture | Mouse-down cancels hover timers. Movement of at least four points starts dragging; tracking continues outside the narrow rail. |
| Clicks and details | Subthreshold movement remains a click. Pin, collapse, scrolling and open-app controls retain their behavior. |

Scope: macOS bubble/edge-tab pointer handling, regression tests and local 0.1.142 installation. Windows version metadata only. No new GitHub Release or campaign changes in this task.
