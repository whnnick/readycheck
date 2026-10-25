# 0.5.1-dev.6 — Presentation and feature retention

[中文](DESIGN_IMPLEMENTATION.zh-CN.md) · [Design review](DESIGN_REVIEW.md) · [Plan](PLAN.md) · [Black-box checks](QA.md)

## Contract

The design contract requires existing capabilities to remain intact. This is a native SwiftUI presentation update, not a new data, authentication or card-execution implementation. No dependency, preference key, credential migration or storage schema is added. Development evidence below is historical; formal release verification is recorded in QA.

The visual direction uses quiet tonal grouping and a monitoring-first reading order. Keep native adaptive grounds, SF system type, semantic quota colors and the established system-blue controls. Floating materials and system navigation remain part of the native design. Browser CSS inspectors cannot validate SwiftUI; use native rendering, device interaction and the checks below instead.

## Changes

- Lead with current quota-reading state; keep last successful refresh as secondary historical context. Distinguish waiting, refreshing, credentials, failure, cached, stale and current readings. Card-check explanations remain independently scoped by the existing next-event model.
- Compact the quota pair and put card count/nearest expiry and trends ahead of complete benefits. Plan, subscription validity, Credits, all reset dates and history remain inline below the chart, without another disclosure.
- Separate quota reminders, card-expiry reminders and automatic use. Align controls to the trailing edge. Show actual current-account On/Off/unknown state before one-level rules; keep running/sleep/offline constraints visible and the original enable-confirmation flow intact.
- Put the Token range beside its daily chart and explicitly label the all-returned-history summary. Retain fixed comparison periods, UTC semantics, precise tooltips and unknown/zero distinctions.
- Replace the generic code glyph with circle↔edge-strip previews. Preserve all actual Widget and notch window/gesture behavior. Show both dates when a check-history incident spans midnight.
- Quiet only static panel borders/shadows; floating materials are retained. Pace explanation becomes a named one-click popover with its full content, rather than a second vertical block.

## Retention map

| Existing capability | Final location / unchanged mechanism | Verification scope |
| --- | --- | --- |
| Both quota windows, primary selection, unknown/cache/stale | Overview pair; Display settings; current state; Data status | Presentation-state regression; bilingual native states; selection/data logic unchanged |
| Plan, subscription expiry, Credits, card count and every expiry | Complete Account & benefits below trend; card summary above trend; original detail buttons | Native synthetic Overview and real reading/scroll inspection |
| Recovery reminder, low thresholds Off/20/10/5 | Settings → Reminders → Quota reminders | Original bindings and notification evaluator retained; regression |
| Expiry On/Off and72/48/24/12 milestones | Own Card-expiry reminders group | Original bindings, minimum-selection guard and deduplication retained; regression |
| Account-specific automatic use and success notifications | Own automation group; original confirmation dialog and history | No execution/consent/notification code changed; integration regression; no real card spent |
| Card attempts, old unconfirmed history, check and notification records | Original account-owned history/details and reminder View all | Retained records, routing and recovery regression; no ledger rewrite |
| Data status, refresh, credential retry and connection recovery | Header plus original state-scoped actions / Connection | State and connection-race regressions; native flow |
| Local Codex and separate OAuth, retry/disconnect/callback | Existing Connection primary/alternate hierarchy | No source migration; both-source bilingual fixtures and connection regressions |
| Token summary, comparisons, daily chart/ranges/tooltips | Token page with explicit summary/range scopes | Original aggregation/comparisons unchanged; UTC/missing-day regressions |
| Widget hour chart, bubble↔edge, card drag, pin/position/fullscreen | Existing Widget and Display controls | Preview only changed; shared surfaces/regressions reuse prior behavior evidence |
| Physical notch, click expansion, both quotas, fullscreen | Existing notch/controller/selection | No notch geometry or event-handler change; prior evidence retains its scope |
| About, update highlights, general preferences | Original sidebar and General/settings controls | Native sections and existing navigation retained |

This map is an incremental retention audit, not a claim that every older hardware/network condition was re-tested. Real second-account switching, extra displays, redemption and physical notch geometry are not induced for a presentation change. The old review's remaining optional notch/connection-footer refinements are deferred, not implemented or removed.

## Verification

Final evidence: [QA](QA.md#dev6-presentation-and-retention) and [structured record](design-retention-evidence.json).410 full tests passed; after final copy/whitespace changes,11 affected checks passed.24 bilingual/light/dark minimum native cases, actual quota/card/Token navigation, unchanged17 preferences/consent/attempts, strict Preview signature and privacy/link/diff checks are recorded there. Local dev.6 is running; no public release.

## Final visual critique

ROUND3

Seen in one second: two quota readings, current reading freshness, the next event and a visible card summary.

Idea: ReadyCheck's two quota clocks lead the workspace; card facts and the next verified action follow them.

Live thing: existing quota/card updates, range/window selection, read-only detail and explanation actions.

Layout words by section: Overview=quota pair / next event / card summary / trend / complete benefits; Token=account history / fixed comparisons / selected daily chart; Settings=trailing controls / independent groups / single-level rules.

Scores: design7.5 · usability8 · creativity6.5 · content8 → overall7.5. Subjective design review, not an external jury or automated pass. Original review baseline6.4; first implementation round still pushed trends down and led with notification mechanics, then the final pass compacted the header/pace and moved notification mechanics after card controls.

Caps applied: native-app review conventions; no landing-page imagery/motion floor. Native system materials/navigation and app controls are intentional retained constraints. No browser0-FAIL claim.

Remaining top three observations:
1. Expanded historical checks are still prose-heavy (private actual history and existing fixtures); all original diagnostics are retained. A later dedicated history design may simplify rows without deleting content.
2. Connection footer still repeats product/privacy context (`design-connection-*.png`); left unchanged to avoid widening this iteration.
3. Notch expansion's height is unchanged (prior native notch fixtures); optional geometry polish needs a separate physical-device check.

All imagery is existing product UI or synthetic native data, with no found stock assets, placeholder product claims or new decorative motion.
