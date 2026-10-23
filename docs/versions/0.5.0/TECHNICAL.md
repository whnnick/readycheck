# 0.5.0 technical investigation and boundaries

[中文](TECHNICAL.zh-CN.md) · [Plan](PLAN.md) · [Checks](QA.md)

## Observations

Read-only comparison on2026-10-22 found identical designated requirements on installed0.4.2 and retained0.4.1 (same identifier/certificate root). Packaging uses stable preview signing. No credential values were read and no Keychain item changed. A different certificate on every build is therefore not established as the cause; equal requirements do not prove access control is healthy. Distribution remains self-signed and unnotarized.

`KeychainCredentialStore` uses legacy generic-password items and suppresses interaction on background reads. Only `retryCredentialRead()` permits explicit system confirmation. The existing failure category does not distinguish signing trust, locked state, legacy item access controls or other denial reasons. No new failure was reproduced and no root cause is confirmed.

Apple describes code identity through designated requirements and different Keychain implementations/access controls:[code requirements](https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements),[Mac Keychains](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains). These inform investigation; they do not prove this machine's cause.

## Next investigation

Use an isolated test service and worthless fixture value to compare old/new same-identity same-path reads, cold start and lock recovery, recording status codes and requirement matches. Change only fixture items. Do not migrate production credentials or relax trust. If fixtures pass but the original item fails, narrowly inspect nonsecret access attributes and let the system handle required approval. Never delete credentials, switch to plaintext, globally allow access or silently change login mode to remove prompts.

Distinguish restricted system access, missing login and expired login only when supported by observed results; use neutral language for unknown errors. A fix requires real upgrade/restart verification, not merely successful signature verification.

## Change map

- `QuotaReminderState`: optional milestone selection; missing means all four. Validate/deduplicate/sort without replacing old history; retain existing state storage.
- Evaluator/store/model: apply selected nodes with existing closest-expiry coalescing, revision protection, accepted receipts and account ownership. Test legacy JSON, toggles, re-enabling, multiple crossed nodes, failed retries, restart and temporarily unknown account recovery.
- `ResetExpiryReminderView`: four checkboxes directly below its toggle, minimum one selected, disabled and failed-save states.
- `QuotaPace.evaluate`: expose verifiable continuous duration/count/interruption evidence within existing filtering; no second view-side filtering implementation. Currently fewer than7 points returns before duration assignment, so `observedDuration` alone cannot support the new progress display.
- `DataStatusView` and existing pace explanations: share diagnostics, retain source/errors/retry paths. Healthy connection with insufficient history must not suggest signing in again.

## Prototype boundary

Dependency-free HTML/CSS/JavaScript, synthetic in-memory data only. Network requests load only its own static files. Six representative states do not cover every production state; the plan retains the full state contract. No real notifications, credentials or cards are touched. Simulated save failure is not disk-failure acceptance.

## Isolated reproduction update

Two different fixture binaries at the same path/certificate passed strict signature verification with equal designated requirements. Initial create/read returned0; updated and cold reads returned-25293; fixture deletion returned0. No production credentials or access controls changed. Root cause remains under investigation;[implementation evidence](implementation-evidence.json)does not claim a fix.

A separate explicit single-application ACL fixture also returned-25293 after update; its item was deleted. Available Developer ID signing identities:0. No production item or system trust settings changed.

## 2026-10-23: partition evidence and resolution boundary

Read-only inspection decoded the disposable fixture ACL's `Partitions`: it contained the old build's `cdhash`, not the updated fixture hash. The one existing ReadyCheck login item was also inspected using references/access metadata only, without requesting credential data: its partition types were likewise `cdhash`, with previously system-approved stable/dev.1 builds listed. No production item, trust setting or access list changed.

Apple's public[Security partition implementation](https://github.com/apple-oss-distributions/Security/blob/main/securityd/src/clientid.cpp#L260-L287)uses a team partition for recognized Apple developer signatures and a content hash for other signatures. Together with local observations, this explains the mechanism behind reapproval after a content change despite identical designated requirements. This is an inference supported by source and read-only observation; no permission-changing causal control or Developer ID upgrade was validated.

The current self-signed preview retains necessary system approval. No empty partition list, all-app access, plaintext credentials or silent migration was used. A future recognized developer-team signing route requires a valid identity and real upgrade validation; that identity is not available here, so upgrade approval is not claimed fixed.

The running automatic-use ledger also became unreadable under system file protection. Dev.2 changes presentation only: unreadable ledger/credentials say “Unconfirmed”, rather than a grey Off switch. Consent files/execution are unchanged; a confirmed readable state retains the existing toggle and confirmation flow. After the user completed system approval, the ledger became readable and retained its original account authorization. The same bundle cold-started and read successfully without a new prompt. The previously failing integration case and all388 current tests pass. No protection or consent was changed; this does not prove prompt-free access across future binary upgrades.

## Dev.3 redemption reliability

- A confirmed consume response now returns independently of later quota refresh; a disconnected follow-up read can no longer erase an authoritative receipt. The model still refreshes quotas after confirmed use.
- The authorization ledger keeps its open descriptor across checks and atomic replacement. Protection remains `completeUnlessOpen` with mode0600; a changed inode is reopened and revalidated, never replaced by cached consent. Empty/corrupt files fail closed. Apple documents this [open-file protection class](https://developer.apple.com/documentation/foundation/fileprotectiontype/completeunlessopen). This mechanism is not proof of the cause of the historical incident.
- Before preparing a request, persist the exact card, stable retry identity, preparation start/count and pending result. Confirmed use/notification remain separate. An unconfirmed request cannot switch to another card before its expiry.
- Retain account-owned observations of available cards. Missing cards remain unconfirmed even after their nominal expiry; only an explicit service `consumed`/`expired` observation records that fact. A consumed observation with unknown initiating client is separate from ReadyCheck success and sends no automatic-success notice. Retain explicit observed receipts when they leave the list.
- A separate bounded0600 diagnostic file stores reason, first/last check, count and warning-submission state, without credentials or redemption authority. It cannot replace consent or initiate a request. Consecutive identical failures coalesce; an accepted warning submission suppresses repeated banners for that incident. Failed submissions can retry.
- Settings → Reminders → automatic use exposes the same records as Overview. Details distinguish observation/reminder provenance from prepared requests. Account-owned old expiry reminders can identify a historical card with no receipt; they never fabricate a redemption outcome. Legacy unowned reminders are not assigned to the current account.
- Reboot, logout, app exit, sleep, revoked/blocked credentials and inaccessible storage can still prevent redemption. Restored reading and synthetic tests do not prove an overnight live redemption. Do not spend a real card just to test.
