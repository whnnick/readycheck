# 0.4.0 black-box acceptance

[中文](QA.zh-CN.md) · [Product plan](PLAN.md) · [Retention audit](RELEASE_AUDIT.md) · [Versions](../../VERSIONS.md)

2026-10-21. Native implementation and non-consuming acceptance on the available Mac are complete. The released0.3.0 baseline remains65 protected capabilities; this release adds summaries and read-only details without removing controls. Coverage below distinguishes functional tests, real UI observations and untested environments.

| Requirement | Result and evidence |
| --- | --- |
| N1 Reset and next event | Real Overview and installed menu show official reset information and require a fresh reading to confirm recovery. Six synthetic native scenarios cover normal, off, authorized, stale/unknown, pending notification and unreadable ledger. |
| N1 Card authorization and timing | Real card detail preserves original expiry/read time and existing On authorization, with a conditional final-hour window. Off/partial/old/future readings are tested; no real card was redeemed for acceptance. |
| N1 Shared surfaces | Real Overview, menu and Widget observed. Widget retains both quotas, last-hour five-minute chart and pinning; pin survives main-window opening/focus, Escape closes, and Open ReadyCheck works. Both languages and7-day primary have synthetic render/fit checks. |
| N2 Card outcomes and notices | Read-only account-owned records, old bytes, precise request/notification association and simulated account switching pass. Confirmed use and pending delivery stay separate; no generic redemption retry or invented old timeline. Actual historical redemption detail and live success-notice delivery remain unobserved because there are no real attempts. |
| Existing controls | Installed menu retains diagnostics, manual refresh/busy state, reminder route, Widget switch, main-window and More entries. More lists Display/Connection/General/About/Quit; About opens the correct0.4.0 highlights. Real reminder settings preserve existing recovery, expiry and automatic-use choices. [65-item record](retention-release-audit.json). |
| Migration and file protection | Original authorization ledger remained unchanged and On after user lock/unlock restored access. Unreadable state now reports unconfirmed authorization instead of disabled consent; re-enabling is disabled until readable. No protection weakening, consent rewrite or real redemption. |
| Comprehension target | The proposed4/5 scenarios in10 seconds is not measured; no speed improvement claimed. |
| Device limits | A second real account, external display, Windows hardware, live redemption and guaranteed banner visibility are not claimed. Applicable unchanged-path evidence from0.3.0 remains specifically scoped. |

## Verification

- Development and sanitized public source each passed372 full Swift tests. The final wording-only About correction then passed its bilingual rendering check in both source trees. The protected-ledger error plus six-scenario render checks also passed.
- Initial restricted-environment failures involved missing NSScreen and denied local OAuth callback sockets. Normal-environment rerun passed; tests were not weakened or skipped to turn failures into passes.
- Windows Node24 check/smoke/UI-smoke, ZIP integrity, ASAR version and forbidden-file scan passed. The Mac redesign is not ported to Windows.
- Final Mac DMG was mounted read-only;0.4.0 metadata, strict signature, bundle privacy and two-artifact invariant passed. The installed executable matched the mounted DMG byte-for-byte. Final installed real reading, original opt-in and menu actions passed after user Keychain confirmation. Previous installation is recoverably backed up; credentials/history/preferences were retained.
- Public source privacy, visible-history internal-file boundary, version consistency and299 local Markdown links passed. Private UI captures are not release assets. [Native Overview](assets/release-overview-en.png), [Widget](assets/release-widget-en.png) and [card result](assets/release-card-result-en.png) use synthetic data.
- Distribution is Apple-silicon self-signed preview (`ReadyCheck Preview Signing`), not Developer ID signed or notarized. Existing Charts/build-tool warnings are not new failures.

Artifact hashes and remote delivery status are recorded in [release evidence](release-evidence.json). Packaging/push was explicitly authorized; no repeated publication automation is enabled.

## Design archive

The selected [prototype](prototype/README.md) and its [visual checks](prototype/design-qa.md) remain historical design evidence, not native acceptance. Model/template checks, bilingual narrow layouts, click-only details, Escape/focus, pin behavior and five walkthrough states were checked there with fixed synthetic data only.

## Public delivery

[ReadyCheck v0.4.0](https://github.com/whnnick/readycheck/releases/tag/v0.4.0) is published and verified as latest, not draft/prerelease. Public main and the annotated tag matched the release commit. Both assets were downloaded from GitHub; SHA256, GitHub digest and file sizes matched the verified local packages. Installed0.4.0 continues to refresh real data, with the original automatic-use authorization and ledger unchanged. The one-time continuation reminder remains paused.
