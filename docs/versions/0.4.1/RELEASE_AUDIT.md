# 0.4.1 feature-retention delta audit

[中文](RELEASE_AUDIT.zh-CN.md) · [Checks](QA.md) · [0.4.0 baseline](../0.4.0/RELEASE_AUDIT.md)

All 65 protected capabilities remain in scope. Reuse the specifically applicable unchanged-path evidence and accepted preview limits from the released 0.4.0 baseline, rather than claiming a new complete hardware run.

| Changed capability | Retained behavior and evidence |
| --- | --- |
| D05 expiry milestones | 72/48/24/12-hour nodes and independent switch retained; accepted, existing-center, overlapping, explicit-failure and restart cases in QuotaNotificationServiceTests; two installed real refreshes did not increase the existing node’s attempts. |
| D09 notification history | Optional fields preserve legacy decoding; submitted/unverified is distinct from verified delivery. Bilingual native synthetic rendering inspected. |
| C04 / I01 account history and retention | Account-scoped receipt and temporary-unknown cases covered; original installed authorization bytes and On switch preserved; no settings/history reset. |
| H04 About | Existing About routes and prior highlights retained; added bilingual deduplication highlight, version and full release link. Native render check covers both languages. |
| Other unchanged capabilities | No feature removals or setting migrations. Prior released baseline evidence reused only where unchanged; complete source regression rerun for public release. |

No real card redemption, second live account, external-display or Windows-device success is claimed. Windows retains its existing implementation; version metadata is synchronized. Final artifact and remote delivery evidence is tracked in QA.
