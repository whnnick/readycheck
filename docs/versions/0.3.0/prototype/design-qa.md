# 0.3.0-preview.1 visual QA

[中文功能检查](../QA.zh-CN.md) · [Functional checks](../QA.md)

## Target and scope

Source visual truth: [accepted native Overview](../../0.2.1/assets/release-overview-zh.png), the existing supplied app icon and the user's accepted Widget/chart behavior. This is a proposed extension, not a pixel-for-pixel recreation. Added pace content, its prominence and the synthetic readings intentionally differ; native typography/rendering must be reviewed again during integration.

Implementation: [Overview capture](../assets/overview-preview-zh.png), [Widget capture](../assets/widget-preview-zh.png). Primary browser screenshot1049×977 pixels; DOM viewport1049×977 CSS pixels, reported devicePixelRatio2, but the screenshot API already emits CSS-size pixels. Do not halve that capture. The native baseline is1800×1520; normalize to900×760 for comparison. The900px iframe capture is1280×720 including outer page: crop x0–900,y127–720 to compare the visible593px app region against the same-size baseline crop. No claim of identical data or product content.

State: Chinese dark Overview, synthetic risk scenario,10% target. Bilingual Widget also inspected at376px; menu at340px. Browser-rendered900/740/390px iframe checks supplement the primary1049px viewport. The temporary viewport harness was removed after capture; narrow web fallback is not a mobile product.

Full-view comparison: [baseline and extension together](../assets/baseline-comparison.png). Focused-region comparison: [Widget before and after together](../assets/widget-comparison.png). Both comparison images were opened and inspected; they are not inferred from file paths or separate image views.

## Findings and comparison history

- [P2, resolved] First Widget summary duplicated Overview metrics and made the floating panel unnecessarily tall. The first browser capture was compared with the revised capture at the same1049×977 viewport and risk/10% state. Replaced detailed metrics and repeated advice with a short shared summary; retained both quota readings and the last-hour chart. Before/after comparison shows panel height reducing from about705px to543px, with no clipped controls.
- No remaining actionable P0/P1/P2 issue within this frontend review. Native dimensions and window placement are outside this prototype acceptance.

## Five fidelity surfaces

- Typography: system sans-serif stack, strong quota numbers, smaller secondary labels. Chinese and English hierarchy/readability checked. Native font sizing is not asserted pixel-identical; browser concept gives the new conclusion priority. No cropped headlines in compact surfaces.
- Spacing/layout: retain sidebar, two quota cards and lower account/history sections; inserted pace block intentionally shifts lower sections. Widget summary compacted after the P2 review. At740px, cards/metrics reflow; at390px, cards stack without hiding navigation. The document scrolls vertically.
- Colors/tokens: dark gray surfaces and subtle dividers retained. Blue navigation/chart and green observed quota remain distinct from amber risk and neutral unavailable estimates. Stale quota values are dimmed and labeled.
- Image/assets: reuse supplied ReadyCheck raster icon with its original proportions. No invented logo, custom decorative illustration or generated product screenshot. Phosphor library icons and Recharts data visualization are functional UI elements.
- Copy/content: current quota percentages, consumed percentage points, conditional estimates and Token counts remain separate. “May/about” and the unchanged-pace assumption are explicit. Insufficient/new-cycle/stale/uneven/idle data does not produce a countdown; alerts describe observed threshold crossing.

## Interaction and runtime checks

Browser checked: risk/safe switching; short/reset/volatile/stale/idle states; three surfaces;5/10/20% target changes; stale refresh returning to valid state; bilingual main and Widget; notification modal with Escape and focus return; About entry. Console warn/error entries inspected: none. Build passed;6 pace tests and4 Sites packaging checks passed. A nonblocking build bundle-size warning remains.

## Open questions and follow-up

- User review of the concept and usefulness is pending; technical visual QA does not replace that choice.
- Candidate sample/volatility gates are assumptions, not measured prediction accuracy. Native contracts, real-data replay and lifecycle/device checks remain release blockers.
- P3: production bundling and deeper VoiceOver/zoom/native-font checks belong to implementation, not this fixture preview.

## Implementation checklist

- [x] Preserve accepted visual language and supplied assets.
- [x] Compare full view and compact region; resolve tall Widget.
- [x] Verify shared fixture/target state and suppression states in browser.
- [x] Verify build and focused rules; keep live app untouched.
- [ ] User direction review, native evaluator and real-data validation before production.

final result: passed
