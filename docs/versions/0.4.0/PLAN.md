# 0.4.0 proposal: know what happens next

[中文](PLAN.zh-CN.md) · [Acceptance plan](QA.md) · [Versions](../../VERSIONS.md) · [Released0.3.0](../0.3.0/RELEASE_NOTES.md)

2026-10-21. The user-selected quotas-first design is implemented natively and accepted on the available Mac; packaging/push is authorized. [Native contract](TECHNICAL.md), [release notes](RELEASE_NOTES.md) and [checks](QA.md) define delivered scope and physical limits. Faster comprehension remains an unmeasured hypothesis.

## User outcome

Open ReadyCheck and understand the next quota reset, whether an expiring card will be attempted automatically, and whether any action is needed now.

The audience remains individual Codex users who want fewer interruptions.0.4.0 organizes existing capabilities around next events and outcomes;0.3.x handles confirmed regressions or documentation errors, without an empty patch release for its own sake. No unestimated delivery date is promised.

## Existing capabilities and actual gaps

| Assessment | Evidence | Decision |
| --- | --- | --- |
| Already available | Conditional5h pace, reset times, recovery/low/expiry reminders, automatic use, success notices, notification history and diagnostics. | Do not relabel them as newly implemented capabilities. |
| Scattered entry points | Overview shows benefits/expirations; Settings → Reminders shows automation and notification history. | Connect the next event to existing information; settings retain authorization. |
| Outcome clarity gap | Automation mostly exposes status/last update; local per-card execution results already exist, while notification history describes delivery. | Explain redemption and notification outcomes separately, including non-success and unknown outcomes. |
| Hypothesis | Prior feedback repeatedly concerned labels, duplicate entries and conflicting definitions. | Validate a small set of clear states before choosing layout. |
| Evidence limits | Historical pace errors are substantial; live redemption/banner, account switching and multiple displays have unverified scope. | No accurate-runtime, guaranteed-redemption or guaranteed-banner claims. |

Sources: [Settings](../../../Sources/ReadyCheckApp/Views/SettingsView.swift), [automation view](../../../Sources/ReadyCheckApp/Views/ResetCreditAutomationView.swift), [stored execution data](../../../Sources/ReadyCheckCore/Usage/ResetCreditAutomation.swift), [existing diagnostics](../../../Sources/ReadyCheckApp/Views/DataStatusView.swift), [final0.3.0 acceptance](../0.3.0/QA.md).

## P0-1: Next in Overview

N1: reuse verified account/quota/card facts to show at most two time-related or actionable items.

- Prioritize evidenced issues requiring user action, then the nearest event; break equal priority by event time in one shared model. Keep normal states compact rather than giving “Available” a large empty card.
- Initially cover the5h natural reset and earliest-expiring card. Times come from official readings; reaching a timestamp does not establish recovered quota without a fresh reading. Retain all7-day information in its existing location.
- When authorized, explain that use will be attempted after the card enters its final hour, conditional on running app, credentials and fresh data. Eligibility-window start is not an execution appointment or guaranteed countdown.
- When disabled, say so and open existing reminder settings. Never enable it implicitly or repeatedly nag.
- Offline, stale, missing card details or credential issues show only evidenced uncertainty and the appropriate refresh/connection route. Missing fields alone do not prove offline status. Suppress affirmative execution promises from old cache.
- Overview can show two items; menu/Widget share the highest-priority item and destination. Merge/de-duplicate with the existing pace area in reviewed layouts rather than stacking a near-identical large card.
- Preserve both Widget quota rows, last-hour chart, controls and pinning. A7-day primary still owns its chart; explicitly label the separate5h summary. Notch remains click-to-expand.

## P0-2: Card details inside Account & benefits

N2: open details from existing expiration rows, without adding a main navigation page.

- Identify the earliest-expiring card, current-account authorization, understandable waiting/verifying/used/nothing-to-reset/action-required state and next action.
- Separate redemption outcome from notification delivery. A confirmed redemption with a failed notice is pending notification retry, not a failed redemption. Say “retrying” only while an actual request is running; persisted waiting is “retry pending”.
- Reuse existing account/card/request-owned execution and notification records. Link the corresponding notice while retaining the original notification-history entry.
- Old records contain only supported fields such as latest update and final status. Mark missing attempt count/start time/stages as unrecorded; never reconstruct an invented event timeline. Any schema extension must read old data and must not create a competing ledger.
- No generic retry that may redeem another card. Unknown outcomes keep their original card/request identity and deduplication; retrying a notification cannot redeem again.
- Settings still own rules and consent; details explain outcomes. Preserve independent automation/expiry/low/recovery controls.

## Main journey

Current: notice an expiring card in Overview → find automation in settings → inspect notification history to understand the outcome.

Proposal: see the expiring card and its state in Overview → open details for the outcome/next action → use existing settings only to change a rule.

## Validation goals and sequence

These are proposed targets, not measured gains:

1. Define a state table and five synthetic scenarios, including wording, destinations and evidence, then review one concrete native design.
2. In first-pass scenario walkthroughs, correctly answer “what next, automatic or manual, action needed?” within10 seconds in at least4/5 scenarios. This is a small design check, not a population conversion metric. Revise wording before proceeding if it fails.
3. After bilingual/minimum-window native designs pass, verify the shared model, old-data loading, record associations and duplicate prevention. Same-account/same-reading surfaces must agree.
4. Exercise non-consuming paths on the available single-account Mac, then package through existing preview scripts. Observe real redemption only during a naturally eligible, user-authorized event; never spend a card early for acceptance.
5. Complete itemized retention/privacy/artifact/remote checks. Record actual account/multidisplay/Windows/redemption coverage separately and explicitly inherit any0.3.0 limits; never turn them into passes by default.

Use walkthrough answers, page switches, steps to locate an outcome, contradictory-surface count and migration preservation as measures. Record the same tasks on0.3.0 before comparison. No default telemetry, record uploads or cloud metrics.

## Retention and boundaries

Keep the [65 protected capabilities](../0.3.0/FEATURE_RETENTION.md), mapping touched items and original/equivalent entries through the [itemized audit](../0.3.0/RELEASE_AUDIT.md). Aggregate test counts do not prove completeness. Preserve account/legacy history, benefits/reset details, Token page, Widget last-hour chart, all desktop forms, About, preferences and consent. Substantive field/default/entry/authorization changes require a separate impact explanation and approval; users need not recall the old feature list.

P1 is limited to diagnostic wording/destination improvements evidenced by walkthroughs. Exclude additional styles/providers, cloud scheduling, new accounts, telemetry, accurate work-time prediction and Windows feature parity. Maintain existing Windows features without suggesting Mac additions arrived through a version bump. Do not restore Codex task pause/resume, Hook or global-notify experiments.

Implementation owns delivery/evidence; product review owns scope/wording; users review concrete new experience and explicit tradeoffs. The selected visual direction is implemented as a synthetic frontend prototype; native implementation still requires separate acceptance. No new technical-route decision is needed now.
