# 0.5.5 black-box checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md)

| Requirement | Evidence / status |
| --- | --- |
| New notifications carry submission date and local time | New bilingual test reproduced ten missing timestamps before the fix; after fix all seven notification kinds covered |
| Preserve content, guards and deduplication | 24 targeted tests and 418 full regression tests passed (zero failures) |
| Notification history dates retained | Actual notification-history page verified: existing delivered/withdrawn rows show full date and minute; no history code/data changed |
| Native Notification Center readability | Signed 0.5.5-dev.1 installed; real test notification verified in Notification Center. User-provided native screenshot and confirmation verify a readable full submission date/time beneath the title, with the system relative time still visible; old notifications remain unchanged |
| Settings, consent and history retained | 17 preferences, consent On, attempt ledger, reminder rules, saved account and auth-cache digests unchanged. History retained, zero test redemptions; same-account OAuth restored after system confirmation, ordinary card check returned checked |

Inherit unchanged capability evidence from [0.5.4](../0.5.4/RELEASE_AUDIT.md); this is not a new full physical-device audit. No real redemption, second-account, multi-display or Windows hardware test. Local development only; no public packaging/push completed.

[Development evidence](development-evidence.json)

System relative-time behavior is not guaranteed; [controlled native investigation](SYSTEM_TIME.md) reproduced valid delivery dates for both immediate and delayed notifications, with both labels visible after reopening Notification Center. No trigger change is justified by this result.
