# 0.6.1 — Feature retention review

[中文](RELEASE_AUDIT.zh-CN.md) · [0.6.0 itemized 65-feature audit](../0.6.0/RELEASE_AUDIT.md) · [Checks](QA.md)

The 0.6.0 audit and its item-specific evidence and device limits remain the baseline. This patch changes only the response to a default system notification click: open the existing notification-history page and refresh its records. Dismissal does not navigate. Existing notification delivery, thresholds, deduplication, account and card authorization are not changed. Both running and cold-start click paths were checked with real test notifications in the installed development build; reminder settings, notification history, OAuth and automatic-card authorization were visible afterward. No real card was redeemed. This does not claim all 65 capabilities were newly tested on a device; Windows retains its prior interface.
