# ReadyCheck native interface design review

[中文](DESIGN_REVIEW.zh-CN.md) · [Version plan](PLAN.md) · [Functional checks](QA.md) · [Version index](../../VERSIONS.md)

2026-10-25, based on local0.5.1-dev.5. Review and recommendations only: no redesign implementation, feature or preference changes, or public release claim.

## Direction

Organize around trustworthy data, a clear next step and an effortless glance. Keep native macOS conventions, system type, the product mark and semantic quota colors. Improve state language, reading order and action hierarchy before visual details. Overview is the quota dashboard; the menu is a quick check; Widget supports ongoing observation; the notch is a lightweight signal.

## Evidence and scope

| ID | Surface | Evidence |
| --- | --- | --- |
| S01 | Overview with unconfirmed quota and unreadable benefits | Same-day native capture and accessibility state |
| S02 | Overview after refresh recovery, with benefits/card summary | Same-day native capture and accessibility state |
| S03 | Token usage: range, historical statistics, fixed-period comparisons and chart | Same-day native capture; source checked for metric scope |
| S04 | Reminders: automatic use On, expiry milestones and notification settings | Same-day native capture; switches untouched |
| S05 | Display and connection settings | Same-day native capture; notch currently Off and left Off |
| S06 | Menu, Widget, expanded notch and740-point Overview | Existing dev.5 native test renders with synthetic data; not same-day device interaction |

Real images remain private locally and are not public assets. This review covers dark Chinese device screens and existing native component images. Light mode, English device interaction, keyboard/VoiceOver, multiple displays and physical notch attachment were not revalidated. SwiftUI has no browser DOM: no web lint/inspect, automated contrast or three-viewport results are claimed. No new style was dealt, no mockup generated and no user usability study performed.

## Data and jobs

- Current account and source: local Codex or separate sign-in, without automatic account migration.
- Five-hour and seven-day quotas: remaining percentages, validity and reported reset times.
- A reported reset time requires a fresh reading to confirm actual recovery.
- Local quota consumption: observed percentage-point decreases for the same account; quota cycle and viewing range are separate dimensions.
- Official Token usage: Token counts, UTC daily records, historical totals and fixed-period comparisons.
- Account benefits: plan, subscription expiry, Credits, card count and each expiry.
- Reminders: recovery, low-quota threshold,72/48/24/12-hour card milestones and delivery records.
- Automatic card use: per-account consent, the final-hour window, checks, requests/receipts and success notices.
- History: unknown outcomes, failures, recovered checks and notification delivery remain distinct.
- Frequent glances and occasional configuration need both compact surfaces and a complete inspection destination.

## The first question on each surface

| Surface | Main question | Retained action |
| --- | --- | --- |
| Overview | How much remains, is it fresh, and what needs attention? | Refresh, specific recovery route, card details and full trends |
| Token usage | How much in which period, compared with what? | Range, exact values and missing-record explanation |
| Reminders | What is enabled, and is automatic use authorized and running? | Existing switches, threshold, milestones, consent, checks and notification history |
| Display | What will this display choice actually look like? | True previews, visibility, pinning, placement and fullscreen behavior |
| Connection | Which account/source is monitored, and what needs recovery? | Current status, applicable retry/disconnect and alternate source |
| Menu | A quick check of remaining quota and the next event | Refresh, reminder shortcut and main-window entry |
| Widget | Ongoing quota and last-hour consumption observation | Pin/collapse, drag, edge attachment and main-window entry |
| Notch | Does the selected quota need attention? | Physical attachment, click-only expansion, both quotas and main-window entry |

## The three changes to make first

### Unify current state and recovery actions

S01 prominently retains a last-success label while also showing unavailable data, an unconfirmed-conditions panel and a separate retry, alongside header refresh and connection actions. A truthful historical success must not imply current validity.

Use one compact current-state/freshness row. Keep an error inside its affected block with one primary recovery action. An unavailable quota shows its last successful time and Retry; readable quota with a failed card check says that the card check is retrying, without equating it with expired sign-in. Unknown redemption results remain prominent. Preserve distinct refresh, connection and check-history routes, exposed for the state they address.

Acceptance: fresh, refreshing, cached, quota failure, card-detail failure and unknown redemption outcome are distinguishable quickly. Retain reading validity and fresh-reading recovery rules; unknown is not zero.

### Make the Overview fold a summary

S02 and S06 show the quota pair, next event and full benefits occupying substantial vertical space before trends. Source dimensions include40-point quota figures,14-point inner gaps and18-point padding. The figures are readable; several equally large blocks are the problem. Do not shrink all text to raise density.

Recommended order: compact state row → both quotas → nearest event/action → card summary and recent trend → expandable full benefits and records. Keep legible figures, card count and nearest expiry discoverable. Plan, validity, Credits and every expiry stay accessible in one action. Preserve selected quota and viewing ranges. Use side-by-side content only when width supports it, then stack deliberately.

Acceptance: at900×760 and740×620 points, both quotas, the next event and card summary can be found without scrolling, with at least the trend heading and first content visible. All benefits and history keep explicit entries; no removed capability or nested disclosure chain.

### Show current results beside settings

In S04 automatic use is On but its explanation starts with the initial default being Off. The switch describes today; the copy describes first use. Long mechanism and notification explanations compete with the actual operating state.

Group quota reminders, card reminders, automatic use and records. Give automatic use its own section with current-account consent, last check and waiting conditions. Align switches/thresholds to a consistent trailing edge. Keep complete mechanics in one Rules and limitations disclosure, with material authorization and sleep/exit limitations visible before activation. Show a short recent-notification summary and View all.

Acceptance: switch, consent and actual checking state agree. Turning reminders off does not disable automatic use, and disabling automatic use does not erase records. Retain original consent, milestones, deduplication and every existing control.

## Follow-up refinements

| Area | Observation | Recommendation |
| --- | --- | --- |
| Token scope | S03 places the30-day selector with account-summary lifetime/peak/streak figures, while chart rows are range-filtered | Separate account history from selected-period figures; position the range beside the chart it controls. Label fixed seven-day comparisons independently. Missing today remains unknown |
| Explanations | Data source, model-free refresh and limitations recur across screens | Keep one current conclusion; attach source and unit to the data, with complete detail one level away |
| Charts | Percentage points and Token counts are separated but explained in long paragraphs | Carry window, period and unit in titles/axes/tooltips. Retain exact-value inspection and explicit UTC dates |
| History | Expanded checks become lengthy prose | Time, event, result and notification per summary row, plus View all and one-level detail. Show both dates across midnight. Recovered rows stay neutral; unknown outcomes stay prominent |
| Display previews | S05 uses a generic code symbol for the bubble | Show the actual circle, edge strip and draggable card. Retain unified circle↔strip behavior and independent card placement |
| Connection | Primary and alternate sources are clear, with lengthy generic footer copy | Lead with current account/source/result; match explanation to the mode. Keep separate sign-in and existing credentials; no silent switching |
| Compact surfaces | S06 menu and Widget repeat both quotas; Widget adds last-hour chart and pinning | Menu for checking, Widget for observation, main window for full analysis. Keep the last-hour chart; share terms and states without making every surface identical |
| Notch | Existing native render has a noticeable void beneath the quota pair | Fit expansion height to content; keep both quotas and primary selection. Preserve physical attachment, click expansion and fullscreen hiding; actual geometry needs later device validation |

## Visual and retention boundaries

Use neutral adaptive grounds, system type and restrained hierarchy. Keep blue for interaction and green/orange/red for quota and risk. Reduce repeated large rounded wrappers while retaining useful grouping and native controls. Main content favors clear opaque layers; system materials on existing native floating surfaces remain part of the product language rather than inheriting a blanket web prohibition. Motion provides control/window feedback, without unrelated entrances or continuous effects.

Later designs must map every existing capability: both quotas/primary selection; benefits/expiry/Credits; every reset card/expiry; recovery and low-quota reminders; four expiry milestones; per-account automatic use and success notices; card and notification history; data status/recovery; both connection sources; Widget last-hour chart/pin/drag/edge attachment; physical notch attachment/click expansion; fullscreen hiding; About and release highlights. Presentation cleanup is not permission to remove a capability or alter card execution.

## Next step and acceptance

Start with before/after designs for normal/error Overview and reminder settings, then Token, menu, Widget and notch. Implement after the presentation proposal is accepted. Shareable artwork uses synthetic demonstration data. Later checks must cover both languages/themes, minimum window, keyboard focus/Escape, zero/unknown/stale states and text contrast, as well as discoverability. This review does not pass those gates.

No new functional tests, release or push were performed. Validation is documentation links, privacy and diff checks; prior functional evidence retains its original scope.

Implementation follow-through: [dev.6 contract and retention map](DESIGN_IMPLEMENTATION.md). The review below records the original dev.5 baseline.
