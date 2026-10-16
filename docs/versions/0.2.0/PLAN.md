# 0.2.0: clear quota overview and reminders

[中文](PLAN.zh-CN.md) · [Black-box checks](QA.md) · [Interactive preview](prototype/README.md) · [Version index](../../VERSIONS.md)

[Cross-version review and five-state specification](UPGRADE_REVIEW.md): confirmed source gaps, migration, account boundaries, lifecycle checks and release blockers.

2026-10-16. Current stage: 0.2.0 release preparation. The native redesign and dev.13 real-data acceptance are recorded below; About discoverability and release highlights are being verified. Packaging and public remote delivery are pending. This is a scoped self-signed macOS preview, with the existing Windows preview interface. [Release notes](RELEASE_NOTES.md).

## User outcome and scope

Show remaining allowance, reset timing and data freshness immediately, with discoverable, verifiable reminder settings. Keep the menu bar and optional floating widget as everyday entry points.

Existing capabilities must remain reachable during the redesign. Account benefits (subscription validity, reset credits and Credits balance) stay on Overview; the [preservation table](UPGRADE_REVIEW.md#existing-capability-preservation) maps the other prior functions.

There are two data types across three surfaces:

| Entry | Question and unit | Source and coverage |
| --- | --- | --- |
| Widget → Quota consumption | Last hour of the selected allowance; each bar is five minutes, in **percentage points**. | The same account-scoped local samples and decrease rule as Overview. Compact bar heights scale to their local maximum. |
| Overview → Quota consumption | The same metric over 24 hours / 7 days / 30 days; bars cover 1 hour / 6 hours / 1 day. An 80%→70% change consumes **10 percentage points**. | Same local history as Widget. Reset changes, missing/invalid readings, increases and gaps over 10 minutes are excluded. Totals use the plotted range; accumulated consumption across cycles can exceed 100 points. |
| Token usage | How many Tokens did the account use each day? | Daily statistics returned by Codex, with UTC date buckets. Missing Token statistics show an explicit unavailable state rather than a quota-chart substitute. |

Widget and Overview differ in time range, grouping and vertical scale; compare the same account, allowance and period by value, not pixel height. Token statistics have different coverage and no fixed conversion to quota consumption. Quota changes cannot reconstruct missing Token counts; Token totals cannot reconstruct a missing allowance reading.

Keep quota period and history range explicit in titles: Widget uses “5-hour quota · Consumption over the last hour”; Overview uses “5-hour quota · Consumption over 24 hours” and updates the range when selected. A separate line gives bar duration and percentage-point units. The Token chart is titled “Daily Token counts”, with one day per bar and UTC dates. These labels change presentation only.

| Priority | Requirement | Native release acceptance |
| --- | --- | --- |
| P0 | Overview / Usage / Settings | Both quota windows, resets and refresh state fit the first view at the usual window size; navigation remains visible. |
| P0 | Consistent data state | Preserve the last successful reading and timestamp on transport errors; show unknown after authorization failure. Unknown is not zero; old plan metadata is separate from current quota validity. |
| P0 | Explicit quota / account ownership | Missing selected windows do not become another window; scope history to verified accounts and retain backed-up legacy provenance. |
| P0 | Safe upgrade | Preserve credentials, preferences, disabled reminders and placement. Use atomic/recoverable migration and check interruption/return to the old version. |
| P0 | Unified reminders | Reuse the existing engine; include 5%, 10%, 20% and Off. Deduplicate by account, window and cycle across restarts. Confirm recovery from actual readings. |
| P0 | Inspectable notification state | Read actual permission and provide a test action. Record notification-center entries separately from observed banners; system acceptance does not prove visibility. |
| P1 | Understandable widget controls | Use real component references. Match selected quota labels, values and state. Distinguish keeping details open from window level, and provide recovery after hiding. |
| P1 | User-initiated connection repair | Regress background non-interactive reads; enter authorization only through the relevant user action. Preserve existing credentials on upgrade. |

Use the selected [first concept](assets/overview-concept.png): persistent sidebar, two quota columns, consumption chart and nearby reminder entry. Remove duplicate percentages and use the existing brand asset and native fonts. Quota percentage-point changes and Token history retain separate units.

## Completed design deliverable

The local React/Vite prototype, `0.2.0-preview.3`, includes three-page navigation, settings categories, threshold/recovery controls, simulated permissions and test notices, 7/30/90-day ranges, keyboard chart inspection, simulated refresh and seven data scenarios. Widget readings, keep-open/unpin and hide/restore are simulated in the page; window-level and fullscreen controls only demonstrate configuration state. Settings→Display now opens the five-state concept board; expanded-notch behavior and the revised orb appearance remain design concepts.

All data is synthetic, anchored to 2026-10-15. The page does not connect accounts, access Keychain, send OS notifications, control Codex or change installed app settings. Native style references reuse 0.1.145 synthetic demo components. Selections persist within the page session and reset on reload.

## Implementation and delivery

1. Review and refine the interactive design.
2. Integrate the window sections into the existing SwiftUI/AppKit structure, adding meaningful state/behavior tests before view changes.
3. Connect existing quota and notification services; verify permissions, deduplication, recovery, credentials and errors.
4. Run native black-box checks for direct inward drag, pin/unpin, keyboard, assistive technology, restart, sleep/wake, multiple displays and display scale. Identify unavailable devices explicitly.
5. Align bilingual version metadata, changelogs and acceptance documents before packaging. When publication is authorized, verify public source, Release/latest and downloaded hashes. Map Windows behavior independently; the web preview does not verify native platform support.

## Later 0.3.0 candidates

After reliable sampling: remaining-quota trends, recent consumption summaries, validated pace guidance and adaptive refresh. Gaps/resets must not count as consumption. Hide predictions without enough evidence; estimates do not promise task duration. CodexBar [pace tracking](https://github.com/steipete/CodexBar/blob/main/docs/ui.md#pace-tracking), [refresh policies](https://github.com/steipete/CodexBar/blob/main/docs/refresh-loop.md) and [Keychain interactions](https://github.com/steipete/CodexBar/blob/main/docs/keychain-prompts.md) are design references; no code was copied.

This version does not promise automatic Codex task suspension/resumption, broad provider expansion, automatic reset-credit consumption or new paid APIs. Assess completion through observable viewing/configuration/repair workflows without adding telemetry.

Native development has started at `0.2.0-dev.1`: R1/R2 implementation and targeted tests are complete; native layout and release acceptance remain pending. See the paired QA record.

Native sidebar implementation has progressed to `0.2.0-dev.2`; source tests and synthetic native renders are recorded in QA. Desktop redesign and packaged-app acceptance remain pending.

Menu bar is part of the native upgrade: concise quota/reset/freshness summary with quick refresh, reminders and main-window access. Preserve the expanded widget’s last-hour consumption chart, based on local samples with gaps/resets excluded.

Native menu bar, expanded widget with last-hour chart, and notch details are implemented in `0.2.0-dev.3`. Track source/fixture evidence separately from packaged-app and hardware acceptance in QA.
