# 0.1.137: sculpted orbital bubble and edge rails

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Versions](../../VERSIONS.md)

Supersedes the flat 0.1.136 preview following the user's selected original reference.

| Requirement | Success criterion |
| --- | --- |
| Reference styling | Sculpted continuous shell with soft neck; metallic circular bezel, ticks, thick exact-quota concentric arcs and plain C mark. Colored detail markers, separators, countdowns and blue app link. |
| Edge rails | Free round bubble snaps to a thin vertical handle at either edge; two bars follow real remaining quota. Expand inward; drag away restores the free bubble. |
| Existing behavior | Keep half-second hover, click-to-pin, Esc/outside dismissal, saved placement, all-window scrollable details and card/edge-ring/notch entries. |
| Data integrity | Reuse current quota and observed mini-trend data, no synthetic live values or extra polling. Unknown/stale values remain unknown. Four thin strokes per five-minute trend bin depict the same observed value, not four independent observations. |

Scope: macOS round bubble refinement. Windows version metadata only. Local build, installation, verification and commit; no public push or Release requested.
