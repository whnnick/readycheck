# 0.5.3 black-box checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Versions](../../VERSIONS.md)

Published and installed:`0.5.3`; development evidence below used `0.5.3-dev.2`. Dev.1 full regression:417 tests, zero failures. After the observed cross-page scroll fix and dev.2 metadata update:19 affected navigation/window/card-integration/version tests passed; native re-entry and credential acceptance passed. [Sanitized evidence](evidence.json).

| Requirement | Evidence / status |
| --- | --- |
| Sidebar page and native commands; preserve original shortcuts | Red regression reproduced the missing fourth page; bilingual native-menu regression passed; old Command1/2/3 retained, new Command4 |
| Full history beyond three rows; no record/rule rewrite on refresh | Isolated persistence/model regression passed:all6 fixture records and normalized file bytes/rules unchanged across repeated refreshes |
| Empty state, submission/verified/failed/withdrawn/pending/legacy states | Eight minimum-width bilingual light/dark empty/mixed renders inspected; states remain distinct |
| Settings keep all reminder/automatic-use controls; Overview duplicate removed | Final installed app:sidebar and Command4 open history, older records scroll, refresh works; Command1/3 retained, re-entry scroll offset0; all settings controls present, no embedded summary or Overview bottom shortcut |
| Card details keep exact related-notification sheet | Shared original rows and sheet retained; affected card-integration regression passed |
| Existing account, preferences, history and consent | Strict signature and installed binary match; user-approved Keychain read restored same-account OAuth; all17 preferences, reminder settings, original consent On and history retained; ordinary post-install card check returned `checked`; zero test redemptions |

No new Windows interface, second real account/device or live card-redemption acceptance is claimed. Do not consume real cards for testing. Preserve inherited limitations from the [previous audit](../0.5.2/RELEASE_AUDIT.md). The user has now authorized packaging and publication. Final public source passed417 tests, zero failures, after the correction below. Windows checks/smoke/UI behavior, both package integrity/version/privacy checks and strict Mac signing passed. Public main/tag/latest and both actual downloads were verified, matching local and GitHub SHA-256. The final DMG app restored same-account OAuth after user-approved Keychain access; all17 preferences, original consent/reminders and history remain, and an ordinary card check returned `checked`. Zero test redemptions. [Release evidence](release-evidence.json).

## Public-source test-harness correction

The first public417-case run reported two assertions against a disposed scroll view after a page identity change. The test now resolves the current displayed scroll view after navigation; it also covers Notification history → card rules and scrolling old history → Settings → return to the heading. The strengthened targeted case passed. Application code and packaged runtime are unchanged; the fresh complete public run passed all417 tests.
