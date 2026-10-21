# 0.4.1 reset-expiry reminder correction

[中文](PLAN.zh-CN.md) · [Checks](QA.md) · [Versions](../../VERSIONS.md)

Same card and 72/48/24/12-hour milestone should produce one reminder after system acceptance. Previously, delayed Notification Center verification caused repeated submissions, and temporary unknown identity cleared deduplication on credential retries. Retain reminders at later milestones, independent controls, automatic-use authorization and all 0.4.0 features.

Persist accepted submissions separately from verified delivery using additive optional history fields, retain account-bound deduplication through temporary unknown identity, and use scoped request IDs. An explicit add error remains retryable. No new settings or card redemption. Release 0.4.1 is authorized for packaging and publication; delivery checks are tracked in QA.
