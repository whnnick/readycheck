# 0.1.138: compact bubble and consumption line

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Versions](../../VERSIONS.md)

| Requirement | Success criterion |
| --- | --- |
| Compact size | Expanded size 500 × 248 points, approximately 20% less area than 0.1.137. Keep Chinese/English labels readable and retain the existing sculpted dial, mirror layout, free circle and thin edge rails. |
| Consumption line | One sample per observed five-minute bin; thin line, subtle fill. No repeated strokes, smoothing overshoot, new polling or fabricated observations. Missing bins break both line and fill; isolated samples render as dots, known zero remains on the baseline. |
| Meaning | Describe observed quota decreases in percentage points, distinct from remaining quota, Token counts and energy consumption. Keep existing history aggregation and hover/click/drag behavior. |

Scope: macOS bubble sizing and mini chart. Windows metadata only. Local install and commit, no public push or Release requested.
