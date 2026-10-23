# 0.5.0 — More control, less interruption

[中文](PLAN.zh-CN.md) · [Design preview](prototype/README.md) · [Technical investigation](TECHNICAL.md) · [Black-box checks](QA.md) · [Versions](../../VERSIONS.md)

Current0.5.0-dev.3 repairs confirmed-receipt loss, retains open protected-ledger access, and exposes card observations, prepared requests and coalesced check failures.398 full regressions and final scoped/native checks pass. Real reading and historical-card provenance have been inspected; lock-period synthetic reads/writes and live app checks passed, and unlock follow-up passed after user confirmation. The historical incident outcome remains unconfirmed. No prompt-free upgrade or public release claim. See [reliability checks](QA.md#dev3-reliability-acceptance).

## Outcome and scope

1. **P0 Upgrade connection recovery:** reproduce repeated Keychain confirmation across same-path updates, cold starts and lock/unlock. Preserve necessary system approval. Claim improvement only after real upgrade evidence; do not promise prompt-free access.
2. **P1 Expiry milestones:** check72/48/24/12 hours directly under Settings → Reminders → Reset-card expiry reminders. No new primary navigation or disclosure layer.
3. **P1 Data status:** retain the existing button and directly explain source, last success, last attempt, continuous observation duration/count and the current reason an estimate is unavailable.

## Reminder contract

- Preserve the existing expiry toggle, handled/submitted milestones, history, account isolation and automatic-use consent. A missing new selection field means all four milestones, preserving old behavior. New automatic-use consent remains Off; existing consent stays as authorized.
- Keep at least one milestone while enabled. Disable the last selected checkbox and explain that the master switch turns reminders off. Turning it off retains the selection.
- Each card/milestone/account is notified once. Toggle changes, selection edits, refresh and restart do not erase handled markers. Retain0.4.1 submission deduplication and explicit-failure retry behavior.
- Preserve existing catch-up coalescing: a valid reading emits at most one closest-to-expiry selected unhandled milestone per card and handles milestones already crossed. Never loop over selected nodes to send a burst. Selecting an already-handled milestone does not resend it. Existing account/data eligibility checks still apply.
- Serialize saves with evaluation. Save failure restores the old value and shows an inline error; stale async reads cannot overwrite a new selection. The next valid refresh uses successfully saved rules.
- Expiry reminders, automatic-use consent and confirmed-success notifications remain independent. Turning expiry reminders off does not disable automation; confirmed automatic use still notifies, subject to system notification settings.
- Retain system settings access, test notification, recent/full history and precise record status semantics. The sample history is an existing capability.

## Data-state contract

Connection health and estimation eligibility are separate. A current quota may have no estimate; this should not suggest signing in again. Duration/count must come from the valid continuous suffix for the same account and cycle, not total history.

| State | Direct explanation | Action |
| --- | --- | --- |
| Insufficient history | Observed duration/count; at least30 minutes and7 records, plus stability eligibility | Keep observing; refresh available |
| Interrupted history | Known interruption cause and continuous records since recovery; older history retained | Keep observing |
| Failed refresh/cache | Distinct last success/attempt; cached data excluded from estimation | Refresh |
| Credential restriction | Cannot read existing credentials; not proof of expired login | Retry and complete necessary system approval |
| Variable/no consumption | Specific reason despite available history | Keep observing |
| Valid estimate/at threshold/service restriction/other unavailable | Retain all existing states and explanations | Existing recovery paths |

Retain local-Codex/OAuth source accuracy and missing-source/window/service restrictions. Do not change the30-minute/7-record/10-minute-gap or stability rules. A progress bar describes observation duration only, not a guaranteed estimate or work time. Overview/menu/Widget share the same diagnosis.

## Retention and sequence

Trace the[65-capability baseline](../0.3.0/FEATURE_RETENTION.md) and[0.4.2 delta audit](../0.4.2/RELEASE_AUDIT.md). Preserve benefits/reset counts/expiry dates, Token page, local quota charts, last-hour chart, dragging/pinning, edge/orb, click-to-open notch, notification history, read-only card results, About, languages and preferences. Omitted preview surfaces are not removed features.

Review the preview, reproduce upgrade access, implement/test milestone persistence, then shared diagnostics/native views. Use small commits. The first native visible change uses0.5.0-dev.1 and paired changelogs. Complete black-box retention and applicable package checks before release; no publication or installed-app change in this phase.

## Release phase

The user authorized continuation through bilingual notes, packaging and publication. Promote to0.5.0 while retaining development evidence and unverified live-redemption/historical-outcome boundaries. No prompt-free Keychain claim. See [checks](QA.md) and [release notes](RELEASE_NOTES.md) for the final status.
