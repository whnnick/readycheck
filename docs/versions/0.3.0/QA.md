# 0.3.0 functional checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Prototype](prototype/README.md) · [Version index](../../VERSIONS.md)

2026-10-19: native development0.3.0-dev.1 plus historical browser prototype0.3.0-preview.1. The first table records the prototype; current native evidence follows below.

| Requirement | Result/evidence | Status |
| --- | --- | --- |
| R1/R2 Pace versus reset | Risk: about1 hour to10%, reset in2 hours. Safe: about30% at reset. Browser scenario changes update copy. | Prototype passed; predictive accuracy unvalidated. |
| R3 Suppression | Insufficient/new-cycle/uneven/stale/idle states show no future countdown. Refreshing the stale fixture restores a valid reading. | Browser plus6 evaluation tests passed. |
| R4 Shared surfaces | Main window,376px Widget and340px menu share conclusions. The first Widget was too tall; replaced detailed metrics with a summary, retaining the hourly chart. | Post-fix capture passed. |
| R5 Reminders | 5/10/20 choices update target/time. The5% example explicitly describes an observed crossing, separate from the current34% fixture. Escape closes the dialog and restores focus. | Browser passed; no actual system notification. |
| R6 Retention | About opens; account benefits and reset details remain. Token navigation remains with synthetic lists, not a replacement of native charts. | Prototype entries retained; native code unchanged. |
| Visual/build | 1049px primary viewport;900/740/390px iframe fallback; bilingual main/Widget checks; browser warn/error logs empty. Build,6 pace tests and4 Sites checks passed. | Prototype passed; [visual QA](prototype/design-qa.md). |

## Historical prototype limits

In the prototype phase, only frontend fixtures, simplified calculation and interactions were verified. No live quota, native windows, real notifications, persistence or prediction-error replay. Narrow web fallback is not a mobile product. Native integration, validity evaluation and device checks block a formal0.3.0 release. No prototype push/publication; see the native phase and remaining blockers below.

[Overview](assets/overview-preview-zh.png) · [Widget](assets/widget-preview-zh.png) · [Baseline comparison](assets/baseline-comparison.png) · [Widget before/after](assets/widget-comparison.png). All images use synthetic data.

## Historical feature-retention gate at baseline freeze

The[65-item checklist](FEATURE_RETENTION.md) and[machine-readable baseline](FEATURE_RETENTION.json) are frozen. The frozen register records historical/current source review, not final acceptance; all65 final native0.3.0 acceptance items remain pending. Native progress below does not automatically clear every item. **Prototype passed does not mean full-product acceptance.** Missing/partial prototype items explicitly include alert-off, reset/Credits notifications, history, full Token charts/comparisons and Display/Connection/General controls. No new removal approval exists. Prototype checks do not clear this production release blocker.


## Native0.3.0-dev.1 checks

[Data contract](TECHNICAL.md) · [Sanitized evidence](native-evidence.json)

| Requirement/retained area | Completed evidence | Still required |
| --- | --- | --- |
| R1/R2/R3 Evaluation | 10 Core tests cover risk/safe, Off/5/10/20, already-low/idle, ownership, new cycles/gaps/missing values, stale/cache/restrictions, window/unit/invalid values, uneven consumption and shuffled/future history. A token-unit rejection failed first, then passed with the percentage-only guard. | Real-cycle replay and prediction error; synthetic numbers establish no measured accuracy. |
| R4 Shared surfaces | One pure evaluator feeds incremental native Overview/menu/Widget additions. Bilingual and Off rendering passed. New content initially squeezed the Widget's quota rows; a visible-scroll-height assertion reproduced it, then a shorter summary and40-point height increase fixed it. 18 targeted layout/edge/geometry checks passed. | Physical multiple-display, extreme text sizing and all-state device coverage. |
| R5 Reminders | Off remains Off;10% is reference only. Existing low/recovery notification implementation is untouched and its regressions pass in the full suite. | No new claim about visible banners, Focus or all real delivery conditions. |
| R6 Retention | Existing views gain summaries while retaining benefits, Token, charts, reminders, settings and About; About highlights updated. All18 preexisting preference values survived startup unchanged, as did both existing history files and notification records; private rollback copies retained. | Final per-item65-feature device acceptance remains pending; aggregate test counts do not clear it. |
| Build/version | 338 Swift tests passed, zero failures; development metadata consistent. Existing preview-identity packaging and strict signature verification passed, matching the installed app's designated requirement;0.3.0-dev.1 visibly launched. | Not Developer ID signed/notarized or publicly released. Windows metadata only. |
| Live readings | After normal user Keychain confirmation, live quotas/risk summary, subscription/Credits/reset details and official Token charts/comparisons were readable. Widget quota rows, summary, last-hour chart and footer were fully visible; Escape collapsed it. About highlights opened. No credential deletion or ACL changes. | Menu coverage this turn is synthetic native rendering and size regressions, not a new physical popover pass. Real-cycle error and full device coverage remain pending. |

No push or release. This evidence covers particular native rules/layouts, not all65 device items or full release readiness. Prototype evidence retains its historical scope; all old capabilities remain protected by default.

Final synthetic native captures: [Overview (English, alerts off)](assets/native-overview-en-off.png) · [Widget (Chinese)](assets/native-widget-zh.png). Initial transparent capture backgrounds made colors unreadable; the test backdrop was corrected and that test reran successfully. These are the corrected captures. No live account/quota images are included.

## 0.3.0-dev.2: expiry automation

[Feature contract](RESET_CARD_AUTOMATION.md). Final source:351 Swift tests passed, zero failures, including8 policy,4 process-protocol and1 native model/bilingual UI test. Coverage includes Off/no service calls, account-bound confirmation, expiry/invalid/duplicate data, persistence failures, retry identities, unknown outcomes, revocation and overlap; existing reminder-off/recovery settings remain. Local0.3.0-dev.2 was packaged, strictly preview-signature verified and visibly launched. The Settings → Reminders entry is discoverable and off; enabling is disabled while account credentials await normal system confirmation. All18 old preference values and existing history records survived startup; no enabled-state file was created. After normal user Keychain confirmation, live account/quota and retained benefits were readable. The actual confirmation showed the current account and irreversible-use conditions; Cancel returned to Off. No enabled-state file was created and no real card was used. Physical confirmation/cancel checks passed; successful live redemption remains unverified. No real card is consumed; fake receipts do not prove live redemption.

[Sanitized evidence](reset-card-evidence.json) · [Chinese control](assets/reset-control-zh-CN.png) · [English control](assets/reset-control-en-US.png). Captures are synthetic native components, with no live account/quota values.

## 0.3.0-dev.3: independent expiry reminder switch

R8 / retained D05: a default-on expiry control sits above automatic use in the same section, with72/48/24/12-hour rules visible. New regressions cover legacy migration, independent preferences, re-enable deduplication, stale batch commits and disabling during notification permission waits. Final full suite:356 tests passed, zero failures. The isolated development app passed strict preview-signature verification and launched. The real control started On, changed Off, then On again; persisted state matched and recovery/low-quota/automatic-use choices stayed unchanged. All18 old preferences and both existing quota histories remain; all prior notification-history record IDs remain (normal delivery attempt metadata can update during account refresh). After normal user Keychain confirmation, live quotas and retained account benefits were readable. Automatic use remains Off; no real card was used and no public push/release occurred. No new physical notification banner delivery is claimed.

[Sanitized evidence](expiry-reminder-switch-evidence.json) · [Chinese grouped controls](assets/reset-settings-zh-CN.png) · [English grouped controls](assets/reset-settings-en-US.png). Images use synthetic native components only. Formal65-item retention and release gates remain open.

## 0.3.0-dev.4: automatic-use success notification

R7: dedicated success notice after service-confirmed `reset`/`alreadyRedeemed`; unknown or unused-card outcomes do not notify success. Full362 Swift tests passed, zero failures, including6 new receipt/delivery/history regressions and the extended native model integration. Fakes verify account ownership, durable pending notices, acknowledgement/restart deduplication, failure retry without another redemption, denied permission, expiry/recovery switches off, and concurrent history preservation. Bilingual controls rendered and fit; version metadata is consistent.

The isolated development app passed strict preview-signature verification and visibly launched with the success-notification helper text. The user’s automatic-use choice was observed On before replacement and its state file stayed byte-identical; the agent did not change that choice. All18 old preferences, both quota histories and existing notification-history record IDs remain. After normal user Keychain confirmation, both live quota windows and retained subscription/Credits/reset details were readable. The real automatic-use switch remained On, waiting for the final-hour window; expiry reminders and persistent system notifications remained On. No real card was consumed for verification; a real successful redemption/banner remains unverified. Fake delivery proves application wiring, not physical banner visibility. No push/release.

[Sanitized evidence](reset-success-notification-evidence.json) · [Chinese controls](assets/reset-success-controls-zh-CN.png) · [English controls](assets/reset-success-controls-en-US.png). Images use synthetic native components only. Full65-feature retention/release gates remain open.

## 0.3.0-dev.5: primary-quota label

Replace the unexplained Overview star with a localized “Primary” badge (“主显示” in Chinese). The existing primary-quota selection still determines which card carries the badge; its existing help explains use by Widget/notch. Match header height on both cards so the badge does not offset their edges. Quota, reminder and automatic-use rules are unchanged.

Final6 existing native minimum-window, localization and version checks passed with zero failures. Both language captures were inspected: the label fits and the cards align. [Chinese synthetic native view](assets/primary-badge-zh-CN.png) · [English synthetic native view](assets/primary-badge-en-US.png). This small presentation update does not clear the65-item formal retention/release gate. No public push/release.

The isolated development package passed strict preview-signature verification and launched. Existing18 preference values and the user’s automatic-use state file were preserved. After normal user Keychain confirmation, live quotas and retained account benefits were readable. The actual Overview shows “主显示” on the five-hour card, with aligned card edges; the private live screenshot is not published.

## 0.3.0 release preparation — 2026-10-20

[Item-by-item retention audit](RELEASE_AUDIT.md) · [Machine-readable evidence](retention-release-audit.json). The development source passed362 full Swift tests, with zero failures. A separately added disconnect/privacy regression also passed: disconnect removes only the selected OAuth token, preserving unrelated credentials, account history and reminder choices. Its2-test focused run overlaps the earlier full suite and must not be added to362. Final release-version and public-source tests remain pending.

User-confirmed physical sleep/wake was followed by a new successful refresh. Automatic card use remained On/waiting; recovery, low-quota and expiry preferences persisted. The generic, clearly labelled test notification was verified in the actual Notification Center. It was not a fabricated successful-card-use alert and no card was consumed. Live Widget content/pinning/open-main passed; actual menu acceptance is pending.

A private, read-only historical replay evaluated the existing native pace calculation against later observations across real cycles. Ordinary-use eligibility was not archived, so the replay assumes it solely for numerical evaluation; overlapping samples from one account do not establish general prediction accuracy. Observed errors were substantial. Retain the visible constant-rate assumption and the explicit non-guarantee; do not advertise accurate time-left predictions. Private account history, timestamps, readings and numerical usage-derived output remain outside public source.

Windows source is unchanged apart from version metadata. Node24 check, smoke and UI-behavior checks passed. This does not establish physical Windows acceptance or add the Mac-only pace/reset-card features to Windows. Packaging, public sync and remote Release verification remain unfinished.

The0.3.0 candidate version passed363 full Swift tests with zero failures. Final native bilingual Overview/Widget captures use synthetic data and the current app icon; release-version consistency passed. Public-source tests, packaging and remote publication remain pending.

## Physical acceptance required before release — 2026-10-20

The release remains blocked. Full physical acceptance was selected; the documented device gaps are not accepted release exceptions. The earlier363-test pass remains valid for the unchanged source, but does not replace these checks.

| Scenario | Pass criterion | Current result |
| --- | --- | --- |
| Menu bar | Both quotas/reset/account and conditional pace summary are visible; diagnostics/refresh/open-window, Widget/reminder controls and More destinations work. | Pending. UI automation selected the Widget/main window instead of the user-opened status popover; no menu-device pass is recorded. |
| Sustained offline and recovery | Actual network loss preserves same-account cached values/original success time, suppresses a pace estimate and new success alerts; reconnection yields a fresh successful reading without lost preferences/history. | Pending physical network cycle. Deterministic transport tests passed previously. |
| Real account A → B → A | Current identity/quota/benefits/history follow each actual account; no cross-account reuse or unintended card authorization; returning to A restores its history and existing choices. | Blocked by prerequisites: the user confirmed no second account is available. User-handled sign-in remains required; never place credentials in reports. |
| Multiple displays | Move Widget/card between real displays, expand/collapse and fullscreen/restore; disconnect the secondary display and recover the surface into a remaining visible area. Preserve final original choices/position. | Blocked by hardware: the user confirmed no external display is available. Synthetic geometry coverage is not a physical-display pass. |

Existing physical sleep/wake, quota/benefits, Widget contents/pinning and Notification Center test evidence remains scoped to its recorded scenarios. Temporary Widget hiding for menu isolation was restored. This continuation does not publish, reconfigure networking, replace sign-in or consume a reset card. Acceptance of those scenarios must be recorded before packaging/publication.

## Release scope decision — 2026-10-20

The release owner subsequently requested stopping further device checks and proceeding with packaging/publication. This supersedes the earlier full-device prerequisite, without converting missing evidence into passes. Menu-device inspection, sustained offline/recovery, real A→B→A account switching and multiple-display acceptance remain unverified. No second account/external display was available. The frozen65-item register remains the original baseline; the [itemized audit](RELEASE_AUDIT.md) records functional evidence and these accepted limitations. No feature removal was authorized. The source and363-test result are unchanged; package/public-source/remote checks still apply. Real reset-card redemption and its physical success banner were not exercised.

## Release artifacts — 2026-10-20

The actual sanitized public source passed363 Swift tests, zero failures. Windows Node24 syntax/service tests, smoke and UI behavior smoke passed. The mounted DMG contains version0.3.0/arm64/macOS14+; strict deep signature verification passed with the stable self-signed preview identity. ZIP integrity, ASAR version/privacy and executable private-string checks passed. The output directory contains exactly the current DMG and Windows ZIP. No Developer ID/notarization or physical Windows result is inferred.

[Delivery evidence and artifact SHA-256](release-delivery-evidence.json). Public main/tag/Release/latest and actual-download digest checks are pending at this preparation point. The latest approved device limits above remain unverified, not passed.

## Published0.3.0 — 2026-10-20

[GitHub release](https://github.com/whnnick/readycheck/releases/tag/v0.3.0) is public, non-draft and non-prerelease; latest resolves tov0.3.0. Public main and the annotated tag resolve to the reviewed release source (later documentation-only delivery updates may follow on main). Both assets were downloaded from GitHub; each size/SHA-256 matches the local package and GitHub digest. [Artifact/delivery evidence](release-delivery-evidence.json).

The mounted-DMG app was installed and visibly launched as0.3.0, with strict preview-signature and executable identity checks passed. All17 currently stored product-prefixed choices, the automatic-use state, all prior account-history samples and notification-history IDs were retained. Existing legacy history and the old app/package were privately preserved. After normal user Keychain confirmation, actual quotas, conditional pace, plan validity/Credits and reset counts/expirations were readable. This does not validate real redemption or its success banner. The accepted unverified menu/offline/account/multidisplay limits remain as recorded above; no feature deletion was approved or performed by this release delivery.
