# 0.5.0 black-box checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Technical investigation](TECHNICAL.md) · [65-item retention](RELEASE_AUDIT.md)

2026-10-23: the0.5.0 release candidate is packaged from sanitized public source and installed; public latest remains0.4.2 until publication. Dev.1/dev.2/dev.3 results retain their original scope. Final-package and installed-device results are recorded below.

| Requirement | Completed evidence | Remaining/limits |
| --- | --- | --- |
| Milestone selection/persistence | Dev.1 full387 pass; legacy defaults, edits, coalescing, failed saves, old batches and submission deduplication covered; device edit restored to all four | Tests do not prove a real visible banner; existing account/device limits retained |
| Expiry/automatic-use independence | Dev.1 model simulation checked success notification and retained original consent | Earlier dev.2 rerun had6 assertion failures withstorageFailed; after system access recovered, that case and the full388-test run passed; no real card consumed for acceptance |
| Unknown consent does not look Off | New case covers ledger/credential failure and confirmed On/Off; bilingual light/dark native renders pass; dev.2 device displays “Unconfirmed” | After user approval, live ledger access and confirmed On were verified; original account authorization retained without toggling |
| Continuous observation | Continuous suffix/duration/count/interruption regression; seven states in both languages/themes rendered | Collecting, gap, stale, variable, idle, service restriction and credential restriction are synthetic, not seven induced real service failures |
| Minimum/compact interaction |740-point reminder page,390-point status and310-point explanation checked in both languages/themes; Widget opens full reason once and retains pin after dismiss; data-status Escape checked | Menu shares rendered explanation; no separate physical status-item click claimed; no full VoiceOver pass |
| Upgrade Keychain | Default/explicit single-app fixtures reproduced-25293 after update; read-only partitions align with Apple source; fixture items deleted | Reapproval persists; no permission bypass or validated Developer ID build |
| Regression/packages | Dev.1 full387 pass; dev.2 two targeted native cases pass; metadata and strict stable preview signing pass; development bundle launched | Current dev.2 full388 tests pass; live reading and same-binary cold start pass without another prompt; no public release |
| Retention |65-item delta audit; this change only affects unknown-state presentation, copy/tests/metadata, not execution/storage/reminder algorithms | Never roll back naturally occurring reminders/records; unknown consent is neither confirmed Off nor confirmed recovered; the subsequent confirmed readable On state was separately verified |

Synthetic native views contain no real account/quota:[unconfirmed consent](assets/consent-unknown-en-US-dark.png),[credential restriction](assets/data-credentials-en-US-light.png). Earlier[browser design evidence](prototype/design-evidence.json)is design-stage only.

## Overnight incident — unresolved

A real overnight observation showed simultaneous recovery of both quotas before the previously reported reset times, followed by one card no longer appearing as available. The local execution ledger has no attempts and no success-notification receipt. This does **not** establish redemption, expiration or the initiating client. The earlier likely-expired interpretation is withdrawn. Protected-ledger failures were observed during the eligibility interval, but do not explain the earlier quota recovery. Full regression and subsequent live reading do not validate overnight redemption.

Original blocker addressed in dev.3: persist pre-request failure diagnostics and retain authoritative server outcomes when available. Historical reconstruction remains an explicit limitation, not a confirmed redemption. A missing card must remain unconfirmed without a receipt; never manufacture a successful execution or notification. The incident occurred before dev.3, when only local attempts were retained. Dev.3 adds card observations and independent failure diagnostics; the historical outcome still cannot be reconstructed as confirmed use. Do not change protection, consent or consume a real card for diagnosis.

## Dev.3 reliability acceptance

[Structured evidence](reliability-evidence.json). Scope: repair confirmed-receipt loss, retain protected open-file access, make preflight failures and missing-card observations inspectable. The historical cause remains unresolved.

| Requirement | Evidence | Remaining boundary |
| --- | --- | --- |
| Confirmed consume survives follow-up read failure | New isolated RPC case reproduced the old error, then passed after repair | No live card redemption performed |
| Protected ledger remains open and detects replacement | Descriptor/replacement, unchanged protection/0600 and corrupt-file tests | Physical lock observed:102 synthetic reads and102 writes,0 failures; unchanged protection/0600. Live app check also advanced while locked. Probe ended before unlock; after user confirmation, protected-ledger reading, live app reading and retained preferences were verified |
| Request trace survives restart | Persist-before-client and preparation time/count tests; stable idempotent retry retained | Preparation is not proof bytes were sent |
| Missing/server-used/expired are distinct | Card-change, explicit consumed observation and receipt retention tests | Available-card lists are not a full service redemption-history interface |
| Failures are inspectable and warnings do not repeat | Persistent/account-owned/coalesced diagnostics and model warning-submission test | An accepted OS notification does not prove a visible banner |
| Existing functions retained | 398 full regressions pass; final18-case subset and4 native integration cases pass after last changes; synthetic paired details visually checked;65-item delta audit remains | No65-item direct device/full hardware claim |

Development bundle0.5.0-dev.3 has not been publicly released. Original account consent, settings and history must remain intact.

Synthetic native evidence: [unconfirmed reminder history](assets/card-unconfirmed-zh-CN.png), [confirmed request and separate notification](assets/card-confirmed-en-US.png), [server observation with unknown initiator](assets/card-server-observation-zh-CN.png). These contain synthetic dates and no account data.

Unlock follow-up: the user confirmed unlock. The protected ledger was readable, original account consent/reminder nodes/thresholds matched the pre-change baseline, and same-binary cold start recovered live reading without another approval. No real redemption request occurred during acceptance; the historical overnight outcome is still unconfirmed.

## Release acceptance

The65-item audit covers entry/behavior deltas, not65 device passes. Changed-path live reading, preferences, ledger and lock/unlock checks pass; unchanged paths reuse0.4.2 evidence with its existing limits. Public-source, package and remote checks remain pending. No real card is spent.

### Final0.5.0 packages and installation

[Release evidence](release-evidence.json): sanitized public source398 tests,0 failures; release metadata1 pass; Windows check/smoke/smoke:ui and ZIP/ASAR checks pass. Mounted DMG version, strict stable Preview signature, bundle privacy and two-package directory invariant pass.

After final-DMG installation and user Keychain approval, live reading, original account-specific automatic-use On consent,17 stored preferences, reminder milestones and threshold were retained. Real card/check records and About0.5.0 were inspected. No real card used. Public main/tag/Release and actual downloads remain pending.
