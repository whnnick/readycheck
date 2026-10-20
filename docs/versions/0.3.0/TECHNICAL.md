# Native quota-pace contract

[中文](TECHNICAL.zh-CN.md) · [Plan](PLAN.md) · [Checks](QA.md) · [Retention](FEATURE_RETENTION.md)

2026-10-19, local0.3.0-dev.1. `QuotaPace.evaluate` is pure and shared by Overview, expanded Widget and menu. It never changes reminders, credentials, history or another application's tasks.

- Accept only available, noncached Codex app-server/OAuth snapshots with a known account, ordinary use explicitly allowed and age at most120 seconds. Future timestamps, missing eligibility and blocked usage produce no estimate.
- Require exactly one verified300-minute percentage window, without a limit code, a valid remaining ratio and a future reset within5 hours. The selected primary window does not substitute a7-day window.
- Consider at most the recent hour, never before the current cycle start. Filter provider/account ownership, sort samples, and reject history newer than the snapshot. Build a contiguous suffix ending at the current reading, with the same window/reset (5-second reset tolerance), valid ratios, positive intervals no larger than10 minutes and no quota increase. Missing/duplicate/invalid/reset data break continuity.
- Require at least7 readings spanning30 minutes. No drop produces an idle state. Compare elapsed-time-weighted half-period rates; suppress estimates when the larger exceeds both3 times the smaller and1 percentage point/hour. These cutoffs are conservative product assumptions, not measured prediction accuracy.
- Compute observed percentage-point drop/hour; extrapolate time from current remaining to the target and remaining at reset. If already at/below target, show that fact without a future countdown. Round displayed durations to about5 minutes.
- Retain Off/5/10/20% choices. Off uses10% solely as a labeled reference and never enables notifications. Existing notifications still depend on observed changes. Compact entries show a conditional summary; Overview includes duration, rate, assumptions and expandable basis.

The Widget keeps its last-hour chart tied to the existing selected quota, with an explicit window label. The new summary is independently labeled5h. Expanded size is380×344 points (40 points taller); no control, quota row or chart is exchanged for the estimate. Information card, notch and gesture semantics remain unchanged.

Initial development release blockers (superseded only as stated in the release scope decision below): real-cycle prediction-error evaluation, physical sleep/offline/account/display coverage and complete65-item retention acceptance. A synthetic native rendering is not a device accuracy result. Windows only receives version metadata; no Windows pace UI is claimed.

## Release scope decision — 2026-10-20

The release owner subsequently requested stopping further device checks and proceeding with packaging/publication. This supersedes the earlier full-device prerequisite, without converting missing evidence into passes. Menu-device inspection, sustained offline/recovery, real A→B→A account switching and multiple-display acceptance remain unverified. No second account/external display was available. The frozen65-item register remains the original baseline; the [itemized audit](RELEASE_AUDIT.md) records functional evidence and these accepted limitations. No feature removal was authorized. The source and363-test result are unchanged; package/public-source/remote checks still apply. Real reset-card redemption and its physical success banner were not exercised.
