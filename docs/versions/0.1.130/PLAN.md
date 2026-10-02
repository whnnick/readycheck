# 0.1.130 bubble details and primary quota

[中文](PLAN.zh-CN.md) | [Acceptance](QA.md) | [Version index](../../VERSIONS.md)

Round-bubble details previously retained only two windows. Remove truncation and scroll vertically inside the existing 282 × 156 panel. Keep the selected quota first and all other windows, including distinct buckets with matching durations. Names support two lines and full hover help. Preserve urgency colors and the blue app link.

Primary quota settings explicitly apply to the bubble and notch. Use returned window names, retain an unavailable saved choice in the picker, explain the temporary display fallback, and restore the preferred display when its window returns. Apply this to legacy five-hour/seven-day preferences too. Missing data does not fabricate quota or overwrite preferences.

Scope is limited to these macOS details and selection behaviors. No new styles or changes to edge hover timing, dragging or shape transitions. Verify extra same-duration buckets, empty/single/multiple refreshes, missing/restored preferences and native screenshots; record live-account acceptance separately. Windows version metadata only.
