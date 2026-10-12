# 0.1.141: single consumption bars

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Versions](../../VERSIONS.md)

| Requirement | Success criterion |
| --- | --- |
| Bars | Recent-hour consumption uses 12 five-minute slots, at most one bar per observed bin, with proportional height and no repeated groups. |
| Truthful states | Zero uses a dim short tick; missing/invalid data stays blank. Preserve existing aggregation and reset/recovery exclusions. Bilingual help explains the units and markers. |
| Layout | Preserve expanded dimensions, dial, edge rails and pin interactions. Verify the native render and installed app. |

Scope: macOS mini chart only, Windows version metadata synchronized. The user subsequently requested the full public release: fresh macOS DMG and Windows ZIP, sanitized source, tag, GitHub Release and remote verification.
