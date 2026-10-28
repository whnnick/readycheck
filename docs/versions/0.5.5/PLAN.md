# 0.5.5 — Notification timestamps

[中文](PLAN.zh-CN.md) · [Checks](QA.md) · [Versions](../../VERSIONS.md)

The user cannot tell when notifications in a grouped macOS stack were sent. Add “Sent at” and a full localized date plus local time in each new notification subtitle. Use the actual submission attempt time, separately from card expiration or usage-reset dates in the body. Cover all seven notification kinds, including the test notification; preserve original title, body, sound, identifiers, deduplication, permission checks and card consent.

The existing notification-history page already displays the recorded attempt date/time. Keep its stored timestamps and statuses; do not rewrite old delivered notifications or historic records. No new redemption requests, authentication or persistence changes. macOS presentation change; Windows metadata only. Acceptance: bilingual content tests, existing delivery/retry/deduplication regressions and a real test notification visible in Notification Center. Do not redeem a real card for acceptance. Local development only; no new public release authorized in this request.
