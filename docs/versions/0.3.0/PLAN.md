# 0.3.0: quota pace

[中文](PLAN.zh-CN.md) · [Checks](QA.md) · [Prototype](prototype/README.md) · [Version index](../../VERSIONS.md) · [Feature retention](FEATURE_RETENTION.md)

2026-10-20. Current phase:0.3.0 release preparation, extending the approved `0.3.0-preview.1` direction and native development. See the latest QA scope decision for accepted device limits and delivery status. See the [native contract](TECHNICAL.md) and [checks](QA.md); this is not release acceptance.

## User problem

A remaining percentage does not answer whether the current pace can last until reset. Compare recent local quota consumption with the chosen alert level and reset time, conditionally. The first scope estimates only the 5-hour window; the 7-day reading stays separate.

| Requirement | Checkable result |
| --- | --- |
| R1 Estimate versus observation | Use “may/about”, with the observation period, rate and alert level. At34% remaining and24 points/hour, reaching10% takes about1 hour; a reset in2 hours means potentially crossing1 hour early. |
| R2 Reset comparison | At54% and12 points/hour with2 hours until reset, about30% could remain, conditional on unchanged future pace. |
| R3 No misleading countdown | Insufficient current-cycle history, resets, stale readings, uneven rates and no observed drop suppress the countdown. Idle does not imply unlimited use. |
| R4 Consistent surfaces | Overview explains the basis; Widget retains the last-hour chart plus a brief summary; menu bar shows readings and a summary. All share scenario and threshold state. |
| R5 Reminder semantics | 5/10/20% choices change the estimate target. Low-quota notifications still require an observed crossing, not an estimated future crossing. Recovery still requires verified recovery. |
| R6 Preserve functionality | Keep account benefits, resets/expirations, Token page, About and history. Retain native Widget/notch behavior, Keychain, sign-in and preferences. The expanded Widget may grow only to preserve existing content alongside the new summary. |

## Prototype limits and candidate calculation

Synthetic readings only; choices live in memory. No account/model/Keychain or system-notification access. Charts use quota percentage points; Tokens are not converted to time.

The interaction fixture requires at least7 samples covering30 minutes within one cycle. Adjacent gaps cannot exceed10 minutes; quota increases suppress extrapolation. Average rate is the observed drop divided by valid elapsed time; time to the alert level uses remaining percentage minus threshold divided by that rate. Display rounds to about5-minute granularity. A greater-than3x difference between half-period rates with a meaningful absolute difference suppresses estimates. Stale, insufficient and idle observations also show no countdown.

These are product hypotheses, not validated accuracy or a production estimator. Native design must additionally define account/cycle ownership, missing/out-of-order data, explicitly disallowed ordinary use, missing reset times, valid coverage, prediction error and real-data replay. Do not copy this fixture straight into production.

## Sequence

1. Completed prototype phase: bilingual prototype, seven scenarios, three surfaces, threshold interactions, browser/keyboard checks and user review.
2. Current native phase: implement the data contract and shared evaluation tests, integrate incrementally, then validate sanitized replays before release. Replay/error acceptance remains unfinished.
3. Before release: real cycles, sleep/offline, account changes, displays and notifications; bilingual notes, public sync and download verification.

No publication, Codex-global changes or task-stop/resume experiments in this phase. No claim to eliminate Keychain confirmation. The 0.2.2 stable device checks and release remain separate work.

Feature retention is a release prerequisite: verify implementation, behavior and migration against the[65-item baseline](FEATURE_RETENTION.md). Prototype omissions are not removal approval; the user is not responsible for recalling or finding missing features.

Native implementation extends the existing views, settings and data model with shared estimation and summaries. The simplified web prototype is not a full replacement specification; the developer owns the feature-completeness audit.

## Native development phase

The shared native evaluator and incremental three-surface integration are implemented for local validation. The [native contract](TECHNICAL.md) replaces the prototype calculation as the implementation specification. Expanded Widget height increases from304 to344 points to keep both quota rows, the last-hour chart and footer fully visible. No existing entry or control is removed. Sanitized replay/prediction-error evaluation has not been completed and remains a release blocker, alongside the per-feature and device checks. No public push or release is authorized in this phase.

## R7: expiring reset cards

[Requirement, consent and execution rules](RESET_CARD_AUTOMATION.md):0.3.0-dev.2 adds an independent, default-off account control while retaining all old reminders.

## R8: independent expiry-reminder control

Add a default-on expiry-reminder switch above automatic card use in Settings → Reminders, with72/48/24/12-hour rules. Preserve D05; disabling suppresses only expiry notices, and re-enabling does not repeat handled thresholds. See [separate controls](RESET_CARD_AUTOMATION.md).

[Release retention audit / 发布功能保留审计](RELEASE_AUDIT.md) · [Evidence / 证据](retention-release-audit.json)
