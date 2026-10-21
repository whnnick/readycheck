# ReadyCheck 0.4.0-preview.1 design QA

2026-10-21 · [中文视觉检查](design-qa.zh-CN.md) · [中文验收](../QA.zh-CN.md) · [Acceptance](../QA.md)

final result: passed

## Visual truth and normalization

- Source: [selected compact reference](../assets/selected-overview-compact.png), generated concept selected by the user; 1487 × 1058 raster pixels. Treat its width as 1487 CSS pixels at 1× for comparison; no source DOM or original font metrics exist.
- Implementation: [browser-rendered Overview](../assets/prototype-overview-zh.png), 1487 × 1121 pixels, from a 1487 × 1121.375 CSS-pixel app frame at 1× screenshot density. Browser viewport 1535 × 1230 CSS pixels. External preview controls are excluded from the app-frame capture.
- State: Chinese, authorized/waiting, 5h primary, 24-hour chart, fixed synthetic October21 10:20 Beijing data. No actual account data.
- [Full side-by-side comparison](../assets/design-comparison.png): source and implementation at the same 1487-pixel width, top-aligned without stretching. The implementation is 63 pixels taller to preserve the quota-definition footer and bottom padding. Browser scrolling is intentional at shorter window heights.
- [Focused Next comparison](../assets/design-next-comparison.png): source 1167 × 205; implementation 1167 × 212. Same-width crop, no density distortion. This makes the compact hierarchy, text, separators and actions readable together.

## Findings and comparison history

1. Initial build: a non-existent Phosphor Pin export prevented loading. Replaced with the library’s PushPin export; final build and browser rendering pass.
2. Initial desktop observation: 204-pixel sidebar and small text made the selected reference too dense. Enlarged the sidebar to258 pixels and key typography (quota58, event title16, body14–15) while preserving two compact events. Post-fix evidence: full and focused comparisons above. The Next panel starts at393 pixels relative to the app frame, matching the reference’s393 pixels.
3. Unknown condition initially repeated a definite card-window hint in benefits. Suppressed the hint when freshness is unknown and labeled the prior reading10:05. The browser’s unknown scenario and shared menu/Widget checks confirm unconfirmed conditions, without a12:00 promise.
4. Widget pin initially only changed appearance. Pinned Widgets now ignore backdrop dismissal; unpin restores outside-click dismissal. Both paths were exercised in the browser.
5. At960-pixel width, the reset action wrapped its last Chinese character. Gave actions sufficient width; [Chinese](../assets/prototype-narrow-zh.png) and [English](../assets/prototype-narrow-en.png) recaptures show no page-level horizontal overflow.

No remaining actionable P0/P1/P2 visual findings in the tested prototype scope.

## Fidelity surfaces

- Typography: system macOS/PingFang stack and tabular quota figures; source image lettering is not an available font specification. Key hierarchy/readability matches the selected direction.
- Spacing/layout: quotas first, compact two-event summary, account benefits and complete consumption chart. No extra large Available/pace card. Narrow windows scroll vertically.
- Colors/material: dark neutral panels, low-contrast separators, blue actions, orange conditional warning and green7-day quota. CSS does not emulate a real operating-system glass compositor.
- Assets: existing ReadyCheck icon and Phosphor icons, not invented image substitutes. Recharts renders the chart.
- Copy: both quotas, card counts/individual expiries and Token distinction retained. Clock reset requires a fresh reading; use-window start is conditional. Used-card and notice-pending results remain independent; unrecorded old stages stay unrecorded.

## Browser interaction evidence

- All five scenarios reviewed in Overview, menu and Widget; [synthetic text evidence](../assets/prototype-browser-checks.json).
- Click-only card details, historical result → notification record; no fabricated timeline. [English details](../assets/prototype-details-en.png).
- Escape closes, focus returns to trigger; Tab/Shift+Tab wrap inside the dialog. Backdrop closes ordinary dialogs; Widget pin/unpin behavior as above.
- Automation-off → rules; cancel leaves it off, explicit preview confirmation turns only the in-memory flag on. Independent expiry switch stays on.
- Unknown → connection → synthetic refresh/loading → authorized reading. Refresh preserves an explicit in-memory authorization override.
- Widget7-day primary keeps both rows and its7-day last-hour/5-minute/percentage-point chart. [Widget evidence](../assets/prototype-widget-zh.png). Pin/footer fit.
- Token/About entries open; chart range produces7 and30 daily buckets respectively. No persisted native functionality was tested or changed.
- Final browser error check contains only the initial, now-fixed Pin import error; no newer runtime errors or warnings were reported after reload. Production build succeeds, with a non-blocking >500kB bundle advisory from the chart dependency. No deployment.

## Open questions and follow-up polish

User comprehension (4/5 scenarios within10 seconds) has not been measured. Native65-item retention, migration, live readings, real redemption/notifications, notch/window positioning and platform acceptance remain future work. P3: eventual production bundle splitting and native material/font tuning; this prototype is not a release candidate.
