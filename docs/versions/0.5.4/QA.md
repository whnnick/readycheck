# 0.5.4 black-box checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Retention](RELEASE_AUDIT.md)

| Requirement | Evidence / status |
| --- | --- |
| No trailing empty partition; smaller sheet | Final divider omitted,540×400 sheet; bilingual native snapshots inspected, no trailing empty partition |
| All three information sections, short/long cases, scrolling | Existing bilingual detail outcome/unavailable scenarios rendered at actual400-point height; short Chinese content fits, longer English content remains in the ScrollView |
| Close/Escape and exact related-notification sheet | Original actions/sheet retained;5 targeted scenario/version checks passed; installed native acceptance pending |
| Account, reminders, history and consent unchanged | No service/storage changes; final installation comparison pending |
| Public source, packages, release and actual downloads | Final public-source417 tests passed, Windows check/smoke/UI behavior and ZIP/ASAR integrity/version/privacy passed; Mac integrity/version/strict signature/privacy also passed; final installed detail/Keychain and remote download checks pending |

Reuse specific unchanged evidence from the[0.5.3 audit](../0.5.3/RELEASE_AUDIT.md), not a new claim of65 physical passes. Windows interface/hardware, second real account, multi-display and real card redemption are not newly tested. No real card for acceptance. Stable self-signed preview, not Developer ID signed or notarized.
