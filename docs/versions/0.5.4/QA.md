# 0.5.4 black-box checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Retention](RELEASE_AUDIT.md)

| Requirement | Evidence / status |
| --- | --- |
| No trailing empty partition; smaller sheet | Final divider omitted,540×400 sheet; bilingual native snapshots inspected, no trailing empty partition |
| All three information sections, short/long cases, scrolling | Existing bilingual detail outcome/unavailable scenarios rendered at actual400-point height; short Chinese content fits, longer English content remains in the ScrollView |
| Close/Escape and exact related-notification sheet | Original actions/sheet retained;5 targeted checks passed; actual observed-card detail and Escape dismissal verified |
| Account, reminders, history and consent unchanged | Same-account OAuth restored;17 preferences, original consent On, reminders/history unchanged; ordinary check returned checked; zero test redemptions |
| Public source, packages, release and actual downloads | Final417 public tests, both package checks, strict signature, installed detail, public main/tag/latest and both actual download SHA256 comparisons passed; [evidence](release-evidence.json) |

Reuse specific unchanged evidence from the[0.5.3 audit](../0.5.3/RELEASE_AUDIT.md), not a new claim of65 physical passes. Windows interface/hardware, second real account, multi-display and real card redemption are not newly tested. No real card for acceptance. Stable self-signed preview, not Developer ID signed or notarized.
