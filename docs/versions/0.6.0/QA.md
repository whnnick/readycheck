# 0.6.0 — Black-box acceptance

[简体中文](QA.zh-CN.md) · [Product plan](PLAN.md)

Open issue: [native system time recurrence](SYSTEM_TIME.md). Full submission timestamps and local history do not guarantee the system's upper-right label.

2026-10-28 follow-up: restarting only the system notification display process did not restore the label, as confirmed by the user. Installed application identity, regular activation policy and strict signature checks found no defect. The additional test notification remains; no production code or reminder behavior changed. The linked investigation records the checks and limits; this issue is not accepted as fixed.

At the local-development gate, 0.6.0-dev.2 was installed and verified; it had not yet been published. Final grouped regression and native evidence are recorded below.

| Requirement | Status | Evidence required |
| --- | --- | --- |
| Type filters/local date groups | Implemented; installed Chinese flow verified | All default, every kind, unknown dates, day/time-zone boundaries, no matches, no writes |
| Relative/full time | Implemented; installed Chinese flow verified | Both languages, relative updates, actual attempt/receipt dates, honest unknown dates |
| Card evidence timeline | Implemented; installed Chinese flow verified | Exact card/account association, legacy uncertainty, request/result/notice separation |
| Recovery actions | Implemented; installed Chinese flow verified | Restricted credentials, rejected auth and service failures; no redemption |
| Retention | Audited; runtime state preserved | Itemized65-feature baseline and0.5.4 delta; source presence is not runtime acceptance |
| Native checks | Installed Chinese and bilingual fixtures verified | Minimum window, languages, appearance, keyboard, long history scrolling |
| Release | Authorized; final remote and installation checks tracked separately | Signing, package privacy, downloads and final installation remain separate |

No real card tests or private account/screenshots/paths in public evidence. Earlier418 tests cover0.5.5 only, not0.6.0 acceptance.

## dev.1 first milestone

Notification grouping/filtering implemented. Four data tests pass (all kinds, non-mutation, day/time-zone boundaries, stable order and timestamp provenance). With opt-in native rendering and existing notification/version checks,25 targeted tests pass, zero failures. Synthetic520-point native component captures generated in both languages/appearances; Chinese dark and English light visually inspected. Time text increased to secondary contrast. No installed live interaction or full0.6.0 regression yet; remaining requirements stay pending. Source privacy patterns, document links and diff whitespace checked. No real notifications or cards submitted by these tests.

## dev.2 evidence and limits

18 focused checks pass including opt-in bilingual light/dark native rendering. Nine evidence/action selection tests plus direct connection-route/stale-action checks protect against false success, mismatched notices and silent reauthorization. A test-harness crash from the system notification singleton was corrected by injecting a fail-on-submission silent client; no production bypass. Earlier44 related checks passed with one opt-in render skipped. Full regression and installed native interactions remain pending. See[itemized retention](RELEASE_AUDIT.md).

## Earlier installation gate (superseded by final checks)

The initial435-test run failed two fixtures that lacked the real scroll container. The original viewport assertions are unchanged; the two render cases plus cross-page scrolling now pass (3 checks). A second435-test run had2 opt-in skips and8 assertions/errors in4 existing protected-ledger cases: macOS denied reopening isolated files. Reopening the real ledger was also denied; the running old app keeps its existing descriptor. No production ledger/protection/consent changes. User asked to lock/unlock before dependent reruns or replacing the old app. Candidate0.6.0-dev.2 is built and strictly signed, but installed/live acceptance and a passing complete run remain open.

## After system unlock

Real ledger reopening recovered, with original consent matching the saved account and no card in its final hour. Fresh Core suite:310 tests, zero failures (8.941s), including all previously blocked cases. The signed0.6.0-dev.2 development bundle is installed and Retry credential read clicked; Keychain confirmation is pending.17 preferences, reminder rules, consent and attempt digests are unchanged; every earlier history-entry hash and notification ID remains. The App suite is running; live filters/card details and credential recovery are not yet accepted.

## Final local acceptance

Fresh suites after unlock pass separately: Core310/0 failures; App125/0 failures,2 opt-in native captures skipped in that run and checked separately with evidence enabled (18 focused checks). No passing single combined run is claimed; earlier failures remain recorded. Installed0.6.0-dev.2 strictly signed, same-account OAuth/readings recovered. All five notification types plus All, empty matches, keyboard menu selection, old-history scrolling and return-to-top passed in the real app; date/full/relative time layout visually inspected. Real observed-card timeline, unknown legacy outcome, scrolling, Close/Escape, fresh data status and About highlights passed. Credential retry was exercised; other error routing remains fixture-tested, not induced on the real account. Success timelines are synthetic only; no real card spent.

Final comparison: all17 preferences, reminder rules, original consent and attempt digests unchanged; every earlier quota-history entry and notification ID retained. Original automatic use remains enabled. App left open on Notification history with All selected. The65-row audit inherits existing device limits, not65 new device checks. Windows interface, second real account, external displays and real redemption add no new acceptance. Self-signed preview, not notarized. At that local gate, no public push/tag/Release had been performed.
