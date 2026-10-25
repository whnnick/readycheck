# 0.5.1 — Simpler card details, direct settings navigation

[中文](PLAN.zh-CN.md) · [Black-box checks](QA.md) · [Versions](../../VERSIONS.md)

[2026-10-25 design review](DESIGN_REVIEW.md): recommendations and feature-retention boundaries, not an implemented redesign.

Final user decision: remove the redundant settings button from the read-only card detail. Retain card facts, recorded result, exact notification/details and Close. Remove its footer divider and reduce the sheet height from530 to480 points. All rules, switches, consent and history remain in Settings → Reminders.

The shared next-event rule action still has a purpose and keeps the dev.1 direct-scroll repair, including repeated requests. No unrelated navigation or settings changes. Validate existing bilingual native detail cases and the retained route, then inspect a real detail and Close. No card redemption for acceptance.

Dev.2 local build0.5.1-dev.2; public/installed stable remain0.5.0. The earlier dev.1 design is superseded only for the detail-page button. No publication/push in this task.

## Dev.3 historical records

Classify only reminder-only unrecorded projections as historical gaps. Preserve them in account history, without producing a current Up next failure or suppressing real requests/notifications. Title their details “Historical expiry reminder”, label “Historical record incomplete”, state the unknown past outcome once, and omit current authorization from this historical context. Keep available-card and real request/receipt behavior unchanged. No stored history, account consent or execution logic is changed. Local0.5.1-dev.3; no public push/release.

## Dev.4 connection hierarchy

Make Follow Codex on this Mac the primary entry and put separate sign-in in Other connection methods. Preserve the saved source: existing separate sign-in users still see their current source, status, account and applicable retry/disconnect controls without expanding the disclosure. Only an explicit source button changes the source. Explain that Token statistics and automatic card use still need an available local Codex interface. No authentication, consent, account ownership or history migration. Verify bilingual minimum-window rendering, connection race/wake regressions and real disclosure interaction without switching the user's account. Local0.5.1-dev.4; no push/release.

## Dev.5 transient card-check failures

Keep every failed check in account-owned history. A service/card-detail read failure alerts only after at least three consecutive checks spanning120 seconds; gaps over300 seconds or clock reversal start a new streak. Existing retry scheduling continues. Credential/ledger, write, card-change, missed-window and unknown-redemption-result warnings retain immediate handling. A later successful check withdraws only prior matching service-read warnings, without deleting history or success/expiry/other-account notices; history labels the later recovery without inventing a redemption receipt.

When quota is fresh, show separate card-check, card-detail or protected-history explanations and route to card settings. Only unconfirmed quota/connection or actual credential failures route to connection settings. Preserve unknown-result priority, success-notification retry, consent, account source, card execution and reminder preferences. Validate the failing cases first, notification/model lifecycle, native shared surfaces, full regression and real retained-state reading. Local0.5.1-dev.5 only; no push/release and no real card spent for acceptance.

## Dev.6 design implementation

[Presentation contract and feature-retention map](DESIGN_IMPLEMENTATION.md). User authorization is design/UX only, without feature cuts. Keep every existing control, account field, record and compact-surface behavior. Verify native bilingual/light/dark minimum layouts, current-state semantics and unchanged functional routes before local completion. No push/release.

## 0.5.1 release scope

The user authorized packaging/publication and then reported missing subscription dates with local Codex. Code confirms that local quota/card data do not carry this date; only matching-account sign-in claims may supply it. A new synthetic regression reproduced two cross-account metadata assertions before the strict matching guard. Keep the date unknown when no valid source provides it, explicitly explain the local-source limitation and retain the billing link. Do not scrape credentials, infer dates from quota resets or present old dates as newly confirmed. No settings/consent/history migration. Release checks and the65-item delta review are linked from [release notes](RELEASE_NOTES.md) and [release audit](RELEASE_AUDIT.md).
