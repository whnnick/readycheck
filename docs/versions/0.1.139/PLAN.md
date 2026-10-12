# 0.1.139: smaller dial and clean outline

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Versions](../../VERSIONS.md)

| Requirement | Success criterion |
| --- | --- |
| Smaller dial | Keep 500 × 248 window, but use a 176-point dial region and 324-point detail region. Scale rings/C proportionally. Preserve the actual dial center when free expansion is unclamped. Mirror on the left. |
| Preview text | ReadyCheck stays on one line even with the pin button. Both quota labels/percentages/countdowns remain readable; additional returned windows stay scrollable. Inspect pinned and preview states, Chinese and English, with a multi-day countdown. |
| Clean edge | Inset outline rather than half-clipped stroke; remove duplicate SwiftUI exterior clipping. One native mask shares the silhouette, uses display backing scale and updates when display properties change. Smooth tangent joins around the small dial. |
| Compatibility | Preserve thin edge rails, free circle, consumption line, quota semantics, credentials/notifications and existing interaction timers. Windows version metadata only. |

Local implementation, installation and commit. No public push or Release requested.
