# ReadyCheck 0.3.0

[中文](RELEASE_NOTES.zh-CN.md) · [Checks](QA.md) · [Retention audit](RELEASE_AUDIT.md)

Quota pace, expiring-card controls and clear result notifications — while retaining your existing quota/account/Token/Widget features.

## What's new in 0.3.0

- **Quota pace at a glance:** Overview, menu bar and Widget share a conditional five-hour consumption reference. It needs sufficient recent valid history; changing work intensity can cause substantial error, so it is not a time-left promise.
- **Expiring cards, under your control:** optionally authorize automatic use in the final hour, earliest expiry first. It is off by default and bound to the account. Confirmed use sends a dedicated notification and records its delivery result.
- **Separate reminder choices:** expiry alerts have their own default-on switch, independent of recovery/low-quota reminders and automatic use.
- **Keep the details you rely on:** plan validity, Credits, reset counts/expirations, official Token charts and the Widget’s last-hour chart remain. “Primary” now labels the selected display allowance clearly.
- **Safer connection recovery:** late reads cannot replace a newer connection; original settings, credentials and account histories are retained.

## Before enabling automatic card use

It is off by default, requires explicit account authorization, and uses the earliest eligible card in its final hour regardless of remaining quota. The service decides eligible reset windows; use is irreversible. Keep the app running and allow system notifications. Sleep/offline/authentication or unsupported-client periods can miss expiry. An unconfirmed outcome retries only the same card/request; a confirmed success has its own notification and history. Existing consent is preserved during upgrade. No purchased Credits are bought. Real-card redemption was not consumed for verification.

## Platforms and distribution

macOS14+ on Apple silicon. This is self-signed preview distribution, not Developer ID signed/notarized. Windows x64 keeps its existing interface; new pace/automatic-card features are macOS-only. Other monitor/Spaces, network and account/device conditions retain the documented acceptance limits. Package/remote delivery status is recorded in QA; preparing these notes alone is not publication.

Device acceptance limits: physical menu inspection, sustained offline/recovery, live account switching and multiple displays were not completed. Automated functional coverage is not a substitute for those device results; the release owner accepted these limits before publication.
