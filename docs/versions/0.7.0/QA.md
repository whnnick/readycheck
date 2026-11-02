# 0.7.0 — Native and prototype black-box acceptance

## 2026-11-03 dev.28 package and public-source candidate

Requested stage: package and push source/tag. Stable 0.6.1 and public preview dev.23 remain the download targets; no new GitHub Release/publication is part of this stage. The existing public-sync script excluded internal collaboration/build/local-campaign files and passed its sensitive-data scan. Public source/tests/scripts were byte-matched to the reviewed development tree, so the 517-test acceptance remains applicable. Public main history was checked for internal agent paths.

Built from the sanitized public tree with the existing scripts. The Mac distribution build used a generic temporary build path; the final mounted DMG passed image checksum, strict application signature, dev.28/arm64 and executable private-path/internal-file checks. Signing remains the existing self-signed preview identity, not Developer ID/notarized. Windows check/smoke/UI-smoke passed using Node.js 24; the ZIP passed CRC/path/AppleDouble checks, the executable is PE x64, and ASAR contains dev.28 with 13 JS source files matching the reviewed tree and no internal/test/dependency payload.

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| ReadyCheck-0.7.0-dev.28-macos.dmg | 3564820 | `a4ce31e5778b0d15d8375769c39da33b0884dd4c7e4a970939ed420fb1011feb` |
| ReadyCheck-0.7.0-dev.28-windows-x64-portable.zip | 151013260 | `b5924ea9adbb78f5fc931baa0e0b65986783a2ced9eb718e0cfa8dddf1705794` |

Both public-sync and standard project output directories contain only the current Mac DMG and Windows ZIP; prior local installers were retained separately. The installed application was not replaced. This is package verification; source/tag visibility and unchanged Release/latest state are verified separately after pushing. Packaging does not clear the device limitations below.

## 2026-11-03 dev.28 macOS acceptance closeout

Scope: the Codex + DeepSeek macOS slice in [the product plan](PLAN.md) and [implementation scope](TECHNICAL.md). This closes the current acceptance execution and consolidates all 65 entries in the [retention matrix](RELEASE_AUDIT.md); it does not declare every device/edge case accepted or authorize a public release. Earlier dated entries below remain the evidence history.

| Requirement / result | Current evidence |
| --- | --- |
| Implemented core flow | Original Codex quotas, Token history, benefits, reminders and card records retained; DeepSeek original connection, official balance/components, local decrease history and compact/details/notch flows verified. Other catalog services remain planned. |
| Requested corrections | Account benefits default open; ordinary clicks preview and only the explicit button pins; old card incidents remain deduplicated after credential recovery and restart, while new incidents remain eligible in regression tests. |
| Automated acceptance | 338 Core +179 App tests passed across the full run and three opt-in visual follow-ups: 517 unique tests, no outstanding failures/skips. Existing results reused because runtime inputs did not change. |
| Installed package | Still dev.28; strict signature and byte comparison with the reviewed candidate passed. No rebuild/replacement in this closeout. |
| Same-bundle restart | Normal quit was confirmed, the same installed app relaunched in English and both original services connected without new credential entry. English native menus matched. Returned to Chinese; all 13 tracked language/selection/display/frame preferences exactly matched the initial snapshot. This is app restart, not OS login/reboot acceptance. |
| Notification evidence | One explicit test notification reported Center verified. Existing real recovery history retained withdrawn entries after restart. The user confirmed the test notification was visible and old credential-unavailable warnings were gone from Notification Center. |
| Human-only UI checks | The user confirmed the current menu-bar quota/account summary, refresh and open-main action worked; both Overview and Token bar hover details appeared and disappeared normally. These are user-reported device results, not automation captures. Optional menu toggles and every More-menu route were not individually confirmed. |
| Final state | Codex selected, Chinese, original 30-day Token range, main window closed, right-edge capsule collapsed/unpinned; original display settings, saved frames and reminder/card consent retained. No real account amounts/screenshots or credentials added to repository. |

**Partially complete / remaining evidence:** simulated unknown/zero/stale/identity/error cases have automated coverage; they are not all reproduced against a real account. More-menu routes, every display placement/mode, actual snooze deadlines, another account, real DeepSeek alert cycles and OS login/wake/multiple-display/Spaces/fullscreen combinations retain the specific limits in the 65-entry matrix. Windows 403 still needs the affected Windows environment. Other eight catalog services are unimplemented integrations, outside this two-service native slice.

**Release disposition:** local macOS core acceptance is complete for this slice. Stable all-platform release gates remain open where the matrix requires device evidence; no tag, public push, asset upload or release was performed. The current task needs no additional development/build/test repetition unless a remaining check exposes a defect. No scheduled follow-up was created.

## 2026-11-03 dev.28 installed acceptance follow-up

Scope: the installed macOS Codex + DeepSeek flow in [the version plan](PLAN.md), with the [retention audit](RELEASE_AUDIT.md) retaining device-specific limits. No runtime or package changes in this follow-up.

| Requirement | Result and evidence boundary |
| --- | --- |
| Existing connection recovery | Codex retained fresh reads. The user completed DeepSeek's normal Keychain retry; the original connection recovered without entering or inspecting a key. Overview manual refresh advanced its successful timestamp and reported unchanged balance. |
| Compact balance and details | The remembered right-edge balance strip and expanded balance/breakdown, shared controls and missing-sample explanation were visually checked without clipping. A missing observation interval stayed unknown instead of displaying a fresh zero. Populated bar ordering remains synthetic evidence. |
| Preview and explicit pin | Clicking the strip opened an unpinned preview; the explicit button pinned it, content clicks retained pinning, detail refresh advanced the timestamp while pinned, and unpin collapsed the strip. No dragging or position reset. |
| Installed notch | Temporarily enabled the existing notch setting. DeepSeek compact readout and expanded balance/components/footer were visible without clipping, manual refresh advanced the timestamp, and Escape collapsed details. Restored widget-on/notch-off, dual-quota preference unchanged. |
| Warning persistence overnight | Saved live checks showed the same old card incident suppressed through two further read-interruption/recovery sequences overnight. Earlier read failures were marked recovered; diagnostic history and unconfirmed card outcome remained intact. This is bounded observed evidence, not an indefinite-running guarantee. |

Complete regression: 338 Core + 179 App tests, no failures. The initial run skipped three opt-in native visual tests; all three then passed with evidence output enabled. Across these runs all 517 tests passed with no outstanding skips. Reviewed synthetic captures: [capsule](evidence/dev28-balance-capsule.png), [edge](evidence/dev28-balance-edge.png), [expanded](evidence/dev28-balance-expanded.png), [English notch details](evidence/dev28-balance-notch-en.png). These contain fixture data, not real account amounts. Version consistency, whitespace, new-link and added-line privacy checks passed.

Final state: original Codex selection, main window closed, remembered right edge collapsed/unpinned; widget on, notch off, always-on-top and fullscreen-hide unchanged. Restored the original reminder-settings section; no credential, rule, consent or position changes. No build/install or public push/release in this follow-up.

Remaining real-device limits: free horizontal capsule/left edge, Codex notch layout variants and other-display/Spaces/fullscreen combinations need separate current-build acceptance; synthetic native coverage remains distinct. Actual macOS notification removal, launch at next login/reboot, another account, real reminder thresholds and Windows 403 require their own evidence. No new service integration or public-release conclusion is implied.

### Further native-entry checks

Installed dev.28 View → Usage opened the actual Token page. The 7/90-day range controls changed chart coverage and the original 30-day selection was restored; UTC/source/missing-date explanations remained visible. Native-menu Cancel closed the menu. Escape did not produce a reliably observable dismissal and remains unaccepted. A chart-group click did not show a tooltip; pointer-hover acceptance remains pending. Restored Codex Overview and closed the main window, with the right edge collapsed/unpinned and no position/rule changes.

The user opened the status-bar popover, but current automation still returned only the capsule window. System menu/Notification Center surfaces also could not be read, so F01–F04 and actual notification withdrawal remain pending; no pass is inferred from source code, mock rendering or the user's opening action. No runtime change, version bump, rebuild or repeated full regression was needed; the 517-test result above remains applicable.

## 2026-11-02 dev.28 persistent card-warning deduplication

Requirement: restoring credential access must not replay an already submitted warning for the same unresolved card incident. Check intervals remain visible. The diagnostic ledger now records hashed, account-scoped incident subjects (card identity, expiration, status and status-change time) and a separate repeat-suppression flag. Submission acknowledgement remains distinct. Old submitted rows without incident metadata cover only incidents already observed by their last check; new/recurrent incidents and other accounts remain eligible. Missing cards remain unconfirmed and no successful use is inferred.

A successful read resulting in an outstanding card issue also withdraws earlier credential/read warnings. This does not withdraw unresolved redemption-result warnings. History labels suppressed repeats in Chinese and English. The protected consent/attempt ledger, eligibility, redemption RPC, idempotency and retry logic are unchanged. Synthetic checks do not redeem real cards. Existing release blockers and other device-acceptance limits remain in effect; no public release is requested.

Validation and installed acceptance follow below.

Regression: 338 Core + 20 targeted App tests passed with zero failures/skips. The initial three regression tests reproduced repeated warnings and missed new/recurrent incidents before the fix. Coverage includes credential interruption/restart, old-ledger migration, new and recurrent card incidents, resolving one of several incidents, unsubmitted retry, account isolation, missed-window warnings, read-warning withdrawal and preserving unknown redemption results. Development-version consistency, whitespace and added-line privacy checks passed. Installed acceptance is recorded below.

The existing package script produced dev.28 with the same designated signing requirement as dev.27. Strict candidate/installed signature verification, installed version and executable byte comparison passed. A complete dev.27 backup was retained; no preference, credential or history deletion was performed. The installed app initially required normal Keychain authorization. After access recovered, the next automatic card check explicitly displayed the repeat-suppression label for the pre-existing incident and marked the credential interruption recovered. Existing diagnostic history, unresolved card status and both available-card observations remained visible; no new local redemption was shown. This verifies one recovery/check cycle, not a long-running guarantee. Actual macOS removal behavior beyond the application history was not independently inspected; notification withdrawal is covered by the synthetic client tests. DeepSeek authorization was not re-accepted in this focused follow-up. No live values/images or credentials were saved to the repository. No public push or release occurred.

## 2026-11-02 dev.27 account discoverability

Requirement: make the Codex Overview account and benefits section expanded by default, while retaining manual collapse. The only runtime change is the view-local disclosure state initializer; account fields, credential handling, reset actions and stored preferences are unchanged. This applies to a newly created view; manually collapsing it remains effective for that view's lifetime.

Validation and installed acceptance are recorded below. Existing dev.26 capsule evidence remains applicable to unchanged paths; this change does not clear the version's other release blockers.

Validation: development version consistency and whitespace checks passed. Targeted run: Core version test passed; 16 of 17 MainWindow tests passed, with an About-window height assertion failing inside the sandbox. That single test passed when rechecked outside the sandbox; no About code was changed. The run includes account-benefit zero/unknown/partial fields, bilingual minimum-size pages and scroll-position restoration. The existing package script built dev.27 with the same designated signing requirement as dev.26; strict signature, installed version and executable byte comparison passed. A complete dev.26 backup was retained. The newly launched installed app showed the account disclosure expanded before any disclosure click. Manual collapse and re-expansion succeeded. After the user completed normal Codex Keychain authorization, plan, subscription, credits and reset details recovered in the expanded section. The main window was left on these details, with Codex selected and widget position unchanged. No live values/images or credentials were stored in the repository. DeepSeek credential recovery was not re-accepted in this account-only follow-up. No public push or release.

## 2026-11-02 dev.26 selected micro-trend design

The user chose the third displayed concept. [Selected mock](evidence/dev26-selected-concept.png) is a visual direction, not a package screenshot. Native dimensions, position restoration, shared header/footer and explicit-only pin remain unchanged. Currency and balance stack in the compact capsule; edge trends rotate to an oldest-first vertical layout; expanded balance/breakdown align side by side above a taller observed-decrease chart.

40 focused native tests passed, including new compact currency/number separation, no quota percentage, stale-state visibility and existing bilingual notch/expanded natural-height assertions. Reviewed mock-data captures: [capsule](evidence/dev26-balance-capsule.png), [edge](evidence/dev26-balance-edge.png), [details](evidence/dev26-balance-expanded.png). The implementation retains real sampling gaps rather than reproducing illustrative bars from the concept. No new assets, network calls, permissions or provider semantics. Full regression, package and installed acceptance pending.

Final complete regression passed: 333 Core +178 App (511 total), zero failures/skips. The existing packaging script produced dev.26; strict candidate/installed signature checks, installed version and executable byte comparison passed. Normal exit and whole-bundle replacement retained a complete dev.25 backup. Startup still requires normal Keychain confirmation, so live-account layout acceptance is pending. No bypass, public push or release. Windows metadata only. These results supersede the pending full-test/package status above.

### Post-authorization dev.26 device checks — 2026-11-02

After the user completed normal Keychain authorization, the installed dev.26 showed both original services connected. Codex manual refresh completed with a new successful-read time. DeepSeek manual refresh succeeded in both Overview and expanded details, advancing the timestamp and reporting unchanged balance; no credential entry or inspection was needed.

At the remembered right edge, DeepSeek displayed its service mark, currency above balance, and vertical micro-trend area. Expanded details showed balance and granted/topped-up components side by side, the taller observed-decrease area, local-observation disclaimer and complete shared header/footer without visible clipping. This live interval showed no observed decrease, so populated trend bars and their chronological ordering remain covered by synthetic evidence, not this live check.

Clicking either service strip opened an unpinned preview. DeepSeek content clicks preserved preview/pinned state; the explicit pin button pinned details, refresh retained that state, and unpin collapsed the strip. Codex explicit pin/unpin and shared details were also checked. Restored Codex selection, closed main window and collapsed/unpinned right edge without dragging or resetting position. No live account images, amounts or credentials were saved to the repository.

This supersedes the dev.26 authorization-pending status above. Free horizontal capsule, left edge, notch, other languages, multiple displays/Spaces/fullscreen and long-running behavior were not rechecked on-device in this follow-up. No runtime/package change or version bump was needed; the completed 511-test regression was reused. No credential, reminder or reset-card action, public push or release occurred.

## 2026-11-02 dev.25 preview and chrome consistency

The user found that the remembered edge strip still looked old and ordinary clicks could pin Codex differently from DeepSeek. The old controller/background/content pin paths were reproduced by changed regression assertions before removal. The explicit pin button is now the only locking action; ordinary clicks open a preview or leave its current latch unchanged.

| Requirement | Check and boundary |
| --- | --- |
| Matching interaction | Controller tests cover both service selections, free/left/right placement, padding and content clicks, native pin-button mouse events, unpin, external dismissal and clicks during expansion. |
| Matching base UI | Both detail types use the same header/pin/footer components; service-specific content remains separate. Notch content reuses the base UI without adding pinning. |
| Updated edge strips | Real service mark, currency/balance and mini-history replace the old DeepSeek DS-only strip on both edges. Positions and 28x144 strip bounds remain unchanged. |
| Fit and wording | Chinese/English capture and natural-height assertions include the shared header/footer and the two-line unchanged-balance state. Active hints describe a capsule and button-only pinning. |

The 42-test focused run and final 333 Core +178 App tests (511 total) passed with zero failures/skips. Development version consistency and whitespace checks passed. The existing script built dev.25; strict signature verification passed with the same designated requirement as the installed dev.24. The app exited normally and dev.25 replaced the fixed Applications bundle, preserving a complete dev.24 backup. Installed version and byte-for-byte executable comparison passed. Startup requested normal Keychain confirmation; real-account refresh and installed-panel interaction acceptance remain pending that confirmation. No authorization bypass was attempted.

Reviewed synthetic evidence: [right edge](evidence/dev25-balance-edge.png), [expanded panel](evidence/dev25-balance-expanded.png), [notch details](evidence/dev25-balance-notch.png). These are mock data, not live-account acceptance. No credentials, reminders, card consent or public download targets are changed. Earlier dev.24 device checks are not automatically dev.25 evidence. No public push or release occurred.

### Post-authorization dev.25 device checks

The user completed the separate normal Codex and DeepSeek Keychain prompts. Both original connections recovered without entering or inspecting credential contents. DeepSeek Overview manual refresh advanced the successful read timestamp immediately and explicitly reported unchanged balance.

On the installed app, switching service updated the remembered right-edge readout. Clicking either service strip opened an unpinned preview; only its explicit pin button changed to pinned, and unpin returned to the collapsed strip. Actual Codex and DeepSeek panels showed the shared header/pin and refresh/reminder/open footer without clipping. Live-account images and values were not saved to the repository. Restored Codex selection, closed main window and collapsed/unpinned right edge without dragging or resetting position.

These checks supersede the pending-authorization status above. Content/background clicks remain covered by native mouse-event regression tests, not a new live click claim. Left-edge placement, notch, multiple displays/Spaces/fullscreen and long-running behavior were not re-accepted on-device in this follow-up. No runtime/package changes, credential/rule/card actions or public release occurred; the 511-test result remains applicable.

## 2026-11-02 dev.24 readout families

Scope: native macOS capsule/notch presentation and supported connection grouping. The second design concept is the visual direction, not proof of exact dimensions or working animation. No new provider, credentials, inference, card use or permission change is part of this update. Public preview dev.23 and stable 0.6.1 remain unchanged.

| Requirement | Implementation and acceptance boundary |
| --- | --- |
| Independent categories | Access method and readout kind are separate values. Tests include API Key + quota and OAuth + balance combinations, without claiming such integrations are available. |
| Shared capsule | 180x48 compact quota/balance readout, real service marks and last-hour bars; older saved frames retain their center and edge restoration. Codex expanded content stays available. |
| Balance details | Per-currency total/granted/topped-up readings, observed-decrease chart, existing hover/click tooltips and accessible refresh/reminder/open controls; capsule pin retained. |
| Missing and stale | Unknown samples stay blank; failed/stale balances are not fresh zeros. Currency-scale tests preserve tiny values and the existing quota scale. |
| Motion and interactions | Reuse existing anchored capsule/notch expansion, pin, Escape, dragging and reduced-motion paths; numeric updates use a short transition, disabled under reduced motion. Live device behavior must be checked separately. |

Final source validation: 333 Core +177 App tests (510 total) passed with zero failures/skips using `READYCHECK_UI_EVIDENCE_DIR=/private/tmp/readycheck-dev24-evidence swift test --disable-sandbox`. This follows the initial 509-test run and a 40-test status follow-up. The new natural-height assertion first failed at 187pt against a 160pt notch body budget in both languages. Compact notch spacing, 28pt balance text and a 52pt chart fix that overflow; the final complete run includes the passing assertion. Fixed-size host geometry alone had not caught the scrolling crop.

Reviewed synthetic evidence: [capsule](evidence/dev24-balance-capsule.png), [notch details](evidence/dev24-balance-notch.png), [connection groups](evidence/dev24-connection-groups.png). Tiny changes, full zero-axis/disclaimer visibility and Chinese/English layouts were inspected. These are synthetic images, not live-account acceptance. Development version consistency and whitespace checks passed.

The existing script built the final arm64 dev.24 package; strict signature verification passed with the same designated signing requirement as dev.23. An initial dev.24 build was installed at the fixed Applications path with a complete dev.23 backup; DeepSeek selection persisted and live UI showed OAuth/API Key groups. The later notch-fit fix is in the retained final package but is NOT yet installed: the Mac is locked and native UI operation is blocked. Normal credential retry was requested without reading, entering or transferring a key; live reads still need authorization. Unlock before normal exit, final replacement and device acceptance. No lock bypass, account/rule/card authorization changes or release upload occurred. Windows changes are metadata only; existing device/release limits remain.

### Post-unlock final installation and device checks

This follow-up supersedes the pending-install state above. After the user unlocked the Mac, the old process exited through the native menu. The final package replaced the fixed Applications bundle, retaining the pre-fit dev.24 build as well as the earlier dev.23 backup. Strict signature verification and byte-for-byte executable comparison with the retained final candidate passed; only one fixed-path process runs.

- The user completed normal Keychain access confirmation. Original DeepSeek balance reads recovered without a new login or key entry; the agent did not inspect, copy or transfer credential contents. Overview manual refresh immediately advanced the successful reading time.
- Real edge-tab click expanded and pinned the balance panel. Total/breakdown, zero observed decrease, qualification and footer actions were visible without clipping; the panel refresh advanced its timestamp. Unpin returned to the collapsed edge tab.
- Temporarily enabling notch display hid the desktop Widget as designed. The compact currency readout, click-to-expand details, refresh and open-Overview action passed on the actual screen; the disclaimer and footer were fully visible. This account had no new observed decrease, so positive bars and bar tooltips remain covered by synthetic/native tests rather than live spending.
- Restored Widget on, notch off, floating-bubble style, always-on-top, automatic primary quota, dual-notch option, fullscreen-hide and the remembered Reminders/Codex settings section. Returned to Chinese DeepSeek Overview; no drag/reset-position, reminder or card-rule action was performed.
- Remaining limits: Codex still requires credential-access confirmation, as before this device pass; no re-login or real-card test was attempted. Hover timing, bidirectional dragging, multiple displays/Spaces/fullscreen and long-running behavior were not re-accepted here. Settings still uses legacy bubble/circle terminology; that copy was not changed. No live-account screenshots or balance values were added to the repository, and no public release was uploaded.

No runtime code or version changed during this follow-up; the final 510-test result above still applies.

## 2026-11-02 public dev.23 preview

The maintainer explicitly requested publication of prepared dev.23. The [release](https://github.com/whnnick/readycheck/releases/tag/v0.7.0-dev.23) is now public: draft=false, prerelease=true, with both verified assets. Anonymous release API and public download URLs succeeded; asset sizes and GitHub digests still match the verified packages. Stable latest remains v0.6.1. This updates the earlier draft hold; remaining Windows affected-machine/device checks are not marked passed. Runtime source and package bytes are unchanged.

## 2026-11-02 dev.23 package and source push

The maintainer requested packaging and pushing the latest version. Prepare dev.23 artifacts and source with the existing scripts; retain draft status and stable latest 0.6.1. This does not clear the remaining device/retention gate. The earlier dev.21 [package evidence](release-evidence-dev21.json) is retained separately; [current package evidence](release-evidence.json) records dev.23 preparation.

The public-sync source passed 332 Core +172 App tests (504), zero failures/skips, and matches the development runtime/test file digest. Windows check/smoke/UI-smoke, ZIP integrity, x64 PE, ASAR version, both system-networking injections and packaged-text privacy checks passed. The mounted arm64 Mac DMG passed version and strict signature checks; its designated requirement matches the installed dev.23. A first build embedded a personal resource-bundle build location; rebuilding with the existing temporary build-directory override removed it, and final binary privacy checks passed. This procedure is now documented in both release guides. The final DMG was not reinstalled during this package pass; prior installed dev.23 live acceptance remains separate. Public main and the peeled v0.7.0-dev.23 tag were verified against source commit ff9d742. The existing prerelease draft now contains exactly the dev.23 Mac DMG and Windows ZIP; authenticated re-downloads match both GitHub asset digests and local SHA-256. Prior dev.21 packages were verified and retained in a recoverable local backup before removing the older draft attachments. Both distribution directories contain only dev.23 packages. Stable latest remains v0.6.1; the draft is not publicly released. The following verification-only commit records these results without changing the tagged runtime source.

## 2026-11-02 unlocked dev.22 validation and dev.23 layout follow-up

The previously failing protected-file, focus, scroll and animation scopes passed after unlock. Exact dev.22 full regression passed 332 Core +171 App tests (503), zero failures/skips. The strictly verified dev.22 replaced dev.21 at the fixed Applications path with a rollback retained. After normal user-approved Keychain access, original Codex and DeepSeek refreshed successfully; no login replacement, credential inspection or card action.

Installed Chinese About shows the current four feature groups. Installed English About reproduced the clipped brand/title seen in the fixture, and upward scrolling did not restore it at the default size. This is a real H04 acceptance issue, not dismissed as a fixture problem. Dev.23 preserves the content stack's natural vertical size; its English fixture now shows the complete brand/title. Native default/minimum-size scroll tests cover both locales, document overflow, bottom reachability and returning to top. Geometry checks alone passed before this fix, so visual before/after review remains separate evidence.

Dev.23 full regression passed 332 Core +172 App tests (504), zero failures/skips; Windows check/smoke/UI-smoke passed with metadata-only changes. The canonical local App package and installed bundle passed strict signature checks with the existing designated requirement. Installed dev.23 About shows the complete icon/title, all four highlight groups, release-notes link and footer in both languages at the default size: [Chinese](evidence/dev23-native-about-zh-CN.png) · [English](evidence/dev23-native-about-en-US.png). Minimum-size scrolling is covered by native in-process tests, not a separately resized installed-window observation. After the user approved ordinary Keychain access, the original DeepSeek balance read succeeded and a separate manual refresh advanced its success time. Codex manual refresh also returned fresh quota windows. No re-login or credential transfer. Chinese language and the original Codex selection were restored; exported preference keys and values exactly match the fresh pre-install snapshot. Closing the main window left the running capsule available. Existing unresolved card-result and stale-card-detail states remain visible; no real card was consumed for acceptance.

User-assisted installed dev.23 check: on the capsule's display, entering fullscreen in an ordinary app hid the capsule and exiting fullscreen restored it. The user confirmed both transitions. This accepts that same-display bubble path; multiple displays, separate Spaces and notch fullscreen behavior remain unverified.

The user also confirmed first direct inward dragging from the current screen edge without opening details first, then repeated successfully after attaching the capsule to the opposite edge. Both-edge first-drag behavior is accepted on this device; position persistence after restarting remains unverified.

The user confirmed that the installed information card follows a drag from its title. Its Refresh button entered a busy state and returned with a fresh quota reading; Close hid the card and exposed the existing display recovery controls. The original bubble, enabled visibility, remembered Reminders section and pre-check card frame were restored. Preferences match the snapshot taken after the user's edge-drag checks exactly, preserving the newer capsule placement. Card-frame persistence across restart remains unverified.

Installed dev.23 chart checks: clicking a Codex quota bar displayed its interval and consumed percentage points; the rightmost bar tooltip stayed within the chart, and clicking empty plot space cleared it. A DeepSeek decrease bar displayed its interval and currency amount, and empty plot space cleared it. The user subsequently confirmed DeepSeek pointer-only hovering displays the interval and decrease amount without clicking, and moving away clears the tooltip. Codex quota pointer-only hover and daily-Token tooltip interaction remain unverified. Real account/balance screenshots were not saved to the repository.

Native View → Notification History navigated correctly. Control–Command–F entered fullscreen and returned to the original window. Native-menu Escape could not be confirmed through automation; the exposed Cancel action closed the menu, so Escape remains pending. Final preferences still match the pre-card-check snapshot.

Dev.21 remains a private draft; Windows affected-machine testing is unavailable and remains unverified. No public release or dev.23 distribution artifacts uploaded.

## 2026-11-01 dev.22 About correction and acceptance follow-up

The maintainer chose to keep dev.21 as a draft until acceptance is complete. Windows affected-machine testing is currently unavailable, not passed; no repeated retest request is pending.

Live dev.21 follow-up checked actual minimal/detailed cards, including retained quota and account-benefit fields; 30/60-minute snooze deadlines and immediate resume; English UI/native View menu and return to Chinese; manual update check returning up to date. Launch-at-login and existing reminder/automatic-card state were observed, not changed. Deadline-triggered resume, full-screen/Spaces, physical card/edge dragging and another account remain unverified. All preferences were restored against the pass snapshot, including the card frame written by the layout switch. Live account captures are not committed.

The About window still showed 0.6-era highlights under a dev.21 heading. Dev.22 replaces those highlights with DeepSeek API balance monitoring, platform settings, bidirectional notch/capsule interaction and retained Codex capabilities. No runtime/account/reminder behavior changes. [Chinese fixture](evidence/dev22-release-highlights-zh-CN.png) · [English fixture](evidence/dev22-release-highlights-en-US.png).

Targeted 5 Core +1 App checks passed; the four highlight groups were visually inspected in both languages. The local dev.22 App builds and passes strict signing verification, but is not installed. The first full dev.22 run failed while the Mac was locked: protected temporary ledger files returned EPERM, and foreground/animation/scroll tests failed or skipped. These are not recorded as passes and file protections remain intact. A separate placement assertion exposed a half-point native frame rounding difference; test-only center tolerance is now one backing pixel, with size still exact, and that focused test passed. An unlocked focused rerun and full regression are required. Fixed-size synthetic About images do not prove an entire long English page is visible without scrolling; installed scrolling/locale acceptance remains pending. Dev.21 artifacts and remote draft verification below remain historical and do not contain the dev.22 fix.

## 2026-11-01 candidate package preparation

The authorized package/push uses **0.7.0-dev.21**, with stable 0.6.1 downloads retained. This is not a stable 0.7.0 sign-off. See [candidate notes](RELEASE_NOTES.md) and the [machine-readable package checks](release-evidence-dev21.json).

- Public-sync source passed 332 Core +171 App tests (503), zero failures/skips, with native captures enabled. Windows check/smoke/UI-smoke passed under Node 24.
- The mounted Apple-silicon DMG passed version, checksum and strict signature checks; its designated signing requirement matches the installed dev.21. The final DMG was not installed again during packaging. Live device acceptance above refers to the previously installed dev.21.
- Windows ZIP integrity, x64 PE, ASAR version and both Electron-networking injections were read back; packaged text excludes credentials/internal agent files. This does not verify the affected machine's 403.
- The distribution directory contains only the current DMG and Windows ZIP. Public `main` and the peeled `v0.7.0-dev.21` tag were verified against source commit `d2f100c`. Both packages are attached to a prerelease draft; authenticated re-downloads match both GitHub asset digests and local SHA-256. Stable latest remains `v0.6.1`; the draft is not publicly released.

The [retention checklist](RELEASE_AUDIT.md) remains in progress. Its unresolved device/long-running items are not converted into passes by aggregate tests. The release-process gate remains: source and candidate artifacts can be reviewed, with no stable-release readiness claim.

## 2026-11-01 dev.21 notch-to-capsule dragging

[Product requirement](PLAN.md): make the existing capsule/notch interaction bidirectional without removing old controls.

| Requirement | Implementation and evidence |
| --- | --- |
| Pull down | Reuse native pointer tracking. The compact notch and expanded title area follow the pointer; release at least 32pt below the press point restores the capsule at the drop point. Bubble placement clamps to the destination display and persists. |
| Keep existing interaction | Short, sideways, upward and returned drags stay attached; a click still opens details. Detail controls are excluded from the drag area. Refresh does not snap an active drag; cancellation prevents detachment. Existing capsule-to-notch release behavior remains. |
| State | Detachment enables the existing bubble Widget and disables the notch, preserving selected service, primary quota and dual/single layout. Account, history, reminder and automatic-card authorization paths are unchanged. |
| Validation | Final complete regression passed 332 Core +171 App tests (503 total), zero failures/skips, with native visual evidence enabled. Windows `check`, `smoke`, `smoke:ui`, development metadata and links/sensitive/whitespace checks passed. Windows changes are metadata only. |

The strictly verified dev.21 local-preview bundle replaced the fixed Applications path after dev.20 quit; a verified dev.20 rollback is retained and the designated signing requirement matches. The installed UI reports dev.21. After the user allowed the normal macOS Keychain prompts, original Codex and DeepSeek connections recovered; a fresh DeepSeek balance read and manual Codex refresh succeeded. The original Codex selection is restored. The installed compact notch shows both rows and the downward-drag hint. Automated native dragging could not address this borderless utility window (`noWindowsAvailable`). The user then confirmed that a physical downward drag restored the capsule; the live UI showed its existing quota/details preview. A later observation showed the compact dual-notch state again. Final preference comparison shows only the saved capsule position changed; service, primary quota and dual/single preferences match the pre-install snapshot. Other-device and expanded-title dragging have native event coverage but have not received separate physical acceptance.

This scope does not resolve the affected Windows machine's 403 or other previously recorded release requirements. No public release; no credential inspection or transfer.

## 2026-11-01 dev.20 detail selection and motion

[Product requirement](PLAN.md): the old picker only reordered rows in dual-quota details. Hide that redundant control in dual mode; retain the primary selection that actually drives the collapsed single-quota notch. Keep all services/windows and the existing selection.

| Requirement | Implementation and checks |
| --- | --- |
| Dual details | Stable 5h/7d order with additional returned windows retained; no primary picker in dual details. [Chinese dual](evidence/dev20-notch-details-true-zh-CN.png). |
| Single selection | Retain the original primary picker and unknown/missing states. Settings help clarifies its effect on Widget/single-notch presentation. [English single](evidence/dev20-notch-details-false-en-US.png). |
| Real geometry animation | Approximately 260ms expansion/180ms pointer dismissal, with top/center attached to the physical notch. Geometry and content fades are separate; content layout does not stretch. `NotchWindowControllerTests` sample intermediate frames, attachment, mid-transition reversal and close without reopening. |
| Reduced motion | Respect the system setting: no geometry movement, only a brief content fade. Escape and Space changes dismiss immediately; click/open/outside dismissal remain. |
| Validation | Final complete regression passed 331 Core +165 App tests (496 total), zero failures/skips, with native visual evidence enabled. Windows `check`, `smoke`, `smoke:ui` and development metadata checks passed; Windows changes are metadata only. An earlier partial run stopped for visual fixes is excluded. |

Frame inspection caught and corrected hosting-view intrinsic sizing overriding the window animation, and implicit text-layout animation causing sideways drift. The window owns geometry; content layout and opacity are isolated. The common black silhouette stays opaque while content fades. Synthetic renders/intermediate frames do not imply complete VoiceOver or all-device acceptance.

The strictly verified dev.20 local-preview bundle is installed at the unchanged Applications path, with dev.19 retained for rollback. After the user allowed normal Keychain prompts, both original connections recovered and fresh readings succeeded. Installed dual details show fixed 5h/7d without a picker. In single mode, choosing 7d changed the collapsed display to 7d; the original automatic choice and dual layout were then restored. Escape collapsed details. The final preference export matches the pre-install snapshot; the app remains running with the Codex dual notch collapsed. Live account screenshots/values are excluded from the repository.

No account/history/reminder/card-consent changes or model calls. A pre-existing unconfirmed-card-result warning remains outside this task; no card action was requested. Affected-device Windows 403 acceptance, full VoiceOver coverage and other-device motion acceptance remain pending. This local-preview acceptance is not public-release clearance; existing release requirements below remain. No public release.

## 2026-11-01 dev.19 notch layout and silhouette

Design target: read both Codex 5h/7d quotas while collapsed, use one notch-attached silhouette for both services, and switch dual/single layouts in the existing settings path while retaining the original primary selection. DeepSeek previously used a rectangular black background instead of Codex's rounded edge. The shared native surface keeps its top attached to the physical notch and rounds the lower corners; no new floating layer is introduced.

| Requirement | Implementation and evidence |
| --- | --- |
| Two quota rows | Default 5h above 7d, each with a label, slim bar and percentage. Match actual corresponding windows; missing/stale values never borrow another window or become zero. `NotchStatusViewTests` cover order, missing/stale values and persistence. |
| Rounded notch | Both services share continuous lower corners and the existing physical attachment. Collapsed size remains 185×42pt; expansion, outside dismissal and Escape retain the existing controller. [Synthetic Codex](evidence/dev19-codex-notch-dual.png) · [Synthetic unknown DeepSeek](evidence/dev19-deepseek-notch.png). |
| Settings | Settings → Display → Notch display → Codex quota layout offers Dual (5h + 7d) / Single quota. Dual is the default; persistence does not change primary selection. Installed interaction switched to single and back to dual; persisted state matches. Original primary selection is unchanged. |
| Validation | Scoped 4 Core +18 App passed. The first new test host incorrectly used the system notification center; an isolated client corrected the fixture and the scoped run passed. Current dev.19 full regression passed 331 Core +162 App (493 total), zero failures/skips, with all native visual checks enabled. Windows check/smoke/smoke:ui, development metadata, links and sensitive-data checks passed. |

The final local-preview package passed strict signing verification and replaced the fixed Applications path, with dev.18 retained for rollback. After the user allowed normal Keychain prompts, original Codex/DeepSeek connections recovered and Codex refreshed successfully. Live notch rows show the two windows, click expands, and Escape collapses. The app is left on the Codex dual notch for review; technical acceptance does not imply user acceptance of the new appearance. Original capsule position and primary quota selection match; preference changes are limited to the inspected service and new dual-layout choice. Live screenshots are excluded from the repository.

Existing accounts, rules, history, card consent and service selection remain. The new preference only affects the collapsed Codex notch; no new integration/authorization was added. No release/upload/tag; Windows metadata only, with the affected-device 403 still untested.

## 2026-11-01 dev.18 bar details and capsule drop

- DeepSeek bars support hover/click details with interval, exact decrease and currency. Tooltips remain inside the plot and retain small amounts; blank/zero periods do not invent bars. [Synthetic details](evidence/dev18-deepseek-tooltip.png). Actual installed bar details were observed; live balance screenshots are excluded from the repository.
- Releasing the capsule near a physical notch selects the existing notch display, retaining its previous position. Other screens/locations retain normal dragging. Geometry and window-release/position tests passed. The user dragged on the built-in notch screen and confirmed the switch, then reported the harsh rectangular DeepSeek surface; dev.19 addresses its appearance, which is not yet user accepted.
- Full dev.18 regression passed 331 Core +158 App with zero failures/skips; Windows check/smoke/smoke:ui passed. The strictly verified local preview was installed at the unchanged Applications path with dev.17 backed up. Existing DeepSeek reads succeeded; after the user allowed normal Keychain access, original Codex login refreshed without a new login or consent change. No manual card action was requested by this acceptance.
- Signing initially failed when the cloud-synced Documents folder reattached FinderInfo. Reusing the existing local development directory allowed strict signature verification without weakening signing or system protection. No public release.

## 2026-11-01 dev.17 DeepSeek refresh and selected-service display

See [requirements](PLAN.md). Earlier installed/device acceptance is not proof of dev.17 acceptance.

| Requirement | Implementation and evidence |
| --- | --- |
| Manual update | Immediate request, progress, seconds-level time and updated/unchanged/failed outcome. A counting-loader test verifies a second request without waiting for the five-minute background interval. |
| History | Per-currency observed balance-decrease buckets, not official billing or Token cost. Increases and gaps over ten minutes are excluded; missing data stays unknown. Changed readings inside five minutes are retained. |
| Selected service | Menu label/content, classic Widget, collapsed/expanded capsule, edge tab and notch follow the existing selection. Codex monitoring remains active. Synthetic Chinese/English native captures cover Overview, menu, Widget, capsule and notch. |
| Pending | Live switching on enabled menu/capsule/notch surfaces, edge clipping and sustained background reads. Installed-account manual refresh passed; see the follow-up below. No key inspection, account changes or card use is required. |

Validation: `READYCHECK_UI_EVIDENCE_DIR=/private/tmp/readycheck-deepseek-evidence swift test --disable-sandbox` passed 330 Core +152 App tests, zero failures/skips. Captures use synthetic data and actual capsule/edge/notch sizes; reviewed the small-decrease chart, English menu/expanded panel and Chinese edge tab. An initial screenshot-host sizing assertion was corrected to reproduce native fixed-window constraints before this final complete run. Development version consistency and `git diff --check` passed.

The existing packaging script built dev.17; strict signature checks passed and the designated signing requirement matches dev.16. Installed at the unchanged Applications path, retaining a complete dev.16 backup. Only the fixed-path dev.17 process runs. Live UI switching updates the DeepSeek overview/sidebar, but saved credentials currently require system authorization; a normal retry was initiated without reading or changing credentials. Successful live balance refresh and other device acceptance remain pending. No card was requested, preferences/history were not migrated, and no release was uploaded. Windows changes are metadata only; existing release blockers remain.

### Same-day live-account follow-up

- DeepSeek connectivity recovered. Real total/granted/topped-up balances and the local balance-decrease chart are visible. No API key was read, entered or recorded; no live screenshots or balance values were saved.
- Clicking Overview refresh immediately advanced the reading time from 10:48:54 to 10:51:43 and displayed "Updated; balance unchanged", without waiting for the background cycle. Overview and sidebar both follow the selected DeepSeek service.
- Live capsule/menu/notch acceptance remains incomplete: native close/keyboard/menu controls did not complete reliably, so earlier synthetic images are not treated as live evidence. DeepSeek remains selected; Codex still reports credential access requiring confirmation, with no new login or authorization changes.
- This follow-up changes acceptance documentation only, not code, version or public release state.

## 2026-11-01 dev.16 prior acceptance status

This section records dev.16. The dev.11–dev.15 and prototype records below retain their dated scope and limits. The user accepted the corrected Settings interaction. Native section order is Connection → Reminders → Display → General.

| Requirement | Status | Evidence and limits |
| --- | --- | --- |
| Retain Codex and add DeepSeek API | Current live reads passed | Both services refreshed in the installed dev.16. Codex windows/resets, benefits and existing history are visible; DeepSeek total/granted/topped-up balances and local history are visible. Balance does not imply chat usage. |
| Connection discovery, marks and return | Complete | Native scoped checks, isolated renders and actual form acceptance are recorded below for dev.14–dev.16. No other service was enabled. |
| Full automated regression | Passed | One complete run on current dev.16: 326 Core +149 App, zero failures/skips, with native visual evidence enabled. Windows `check`, `smoke`, and `smoke:ui` passed. |
| Installation and residency | Local checks passed | Installed the same strictly verified dev.16 bundle in Applications, retaining a recoverable 0.6.1 backup. Only the fixed-path new build runs; existing enabled login-start state remains. Closing the main window keeps the app running; ⌘1 reopens Overview. Login after a system restart was not tested. |
| History, benefits and notifications | Partial device acceptance | Quota 24-hour/7/30-day ranges and both windows, plus Token 7/30/90-day ranges switched successfully and original ranges were restored. Plan, subscription date, Credits and individual card dates are visible. A system test notification reported Notification Center verification, and prior delivered/withdrawn records remain readable. Actual banner visibility was not confirmed. |
| Existing settings and automatic-card consent | Original-consent recovery checked | After user unlock, the protected file is readable, automatic use remains enabled for the original account, normal checks continue, and blocked-state warnings cleared from Overview/Reminders. The last attempt remains historical, with no new consumption. Consent and file protection were unchanged; existing rules, display preferences and history remain. |
| Windows 403 | Automated checks/package complete; device acceptance pending | dev.16 x64 portable ZIP integrity, PE x64, Electron 43.5.0, version and OAuth/usage source readback passed. Retest package is local only. The affected machine's proxy routing and original 403 remain untested; no fix claim is made. |

**Outstanding release requirements:** remaining device/long-running behavior in the [65-item retention checklist](RELEASE_AUDIT.md), actual Widget dragging/fullscreen/notch and live account-switch upgrades; affected Windows login. Distribution retains the existing self-signed preview workflow with explicit trust limits: no Developer ID/notarization. Purchasing a developer account is not a prerequisite for this local acceptance. No release, upload or tag was created.

Reproduce with `READYCHECK_UI_EVIDENCE_DIR="$PWD/.build/dev16-final-evidence" swift test --disable-sandbox` and the three npm scripts in `apps/windows`. Full logs remain local in `.build/dev16-full-regression.log` and `.build/dev16-windows-regression.log`; live-account screenshots are excluded from the repository.

Local Windows retest artifact: `ReadyCheck-0.7.0-dev.16-windows-x64-portable.zip`, 151013261 bytes, SHA-256 `0232ff3a4271732e52bc0cc4b1ee341ce6a4a0645de10b03db9cb606a4f774f6`. Built with the existing script from an isolated export of source commit `d887a15`. Report only error text/HTTP status; never share OAuth callback URLs or authorization codes.

Local Mac preview: `ReadyCheck-0.7.0-dev.16-macos.dmg`, 3413645 bytes, SHA-256 `fd9f9d9cd68ed6e364722186afb5e8d1e110c80bca7acca670d9782ebbfeb66f`. Read-only mounted version and strict signature checks passed; CodeDirectory hash and unsigned executable copies match the installed app. Not notarized or uploaded.

Additional installed Widget checks: clicking pins details; they remain expanded after opening/closing the main window. Both quotas and the one-hour/five-minute-bin chart/explanation remain. The bell opens Settings/Reminders/Codex; unpin plus Escape collapses details. Original collapsed state restored, position unchanged; dragging/fullscreen still need device acceptance.

## 0.7.0-dev.16 DeepSeek API connection guidance

- **Complete:** Connection page, disconnected overview action, key form and disconnect confirmation explicitly identify DeepSeek API. Explain that this connection monitors API account balances, with website/app chat usage outside its scope; users can create or reuse a key without coding.
- **Official entry:** Connection page and form link to Create or manage API key, using the same DeepSeek platform destination as the [official authentication documentation](https://api-docs.deepseek.com/api/deepseek-api/). No key was created or read on the user's behalf; actual platform key management remains a user action. No OAuth or other integration was added.
- **Validation:** 1 Core version test and 4 scoped App tests passed, covering settings state, return scroll offset, existing marks, Chinese/English light/dark settings and the new key-form renders. All four form variants fit within 400pt with input/actions visible. [Chinese light form](evidence/dev16-api-connect-zh.png) · [English dark form](evidence/dev16-api-connect-en-dark.png). Corrected a test-host appearance mismatch by setting the native window appearance as well; these are post-correction captures.
- **Scope:** Copy, official links and associated rendering checks only. Credential format, connection validation, alerts, history, background refresh and Codex OAuth reuse the existing implementation. Windows changes are version metadata only; affected-device 403 acceptance is still pending. The existing script built, strictly verified and launched the preview package; only dev.16 runs. All 18 pre-existing preference fingerprints matched at startup. Normal retry restored existing Codex and DeepSeek API connections and successful live reads. Native scope copy, official link destination, clean empty-form error state, Escape return and opener focus verified. No keys were entered, read, transferred or deleted by the agent; live screenshots remain local.

## 0.7.0-dev.15 Settings icons and order

- **Complete:** Connection and Reminder platform selectors reuse the existing overview Codex / DeepSeek marks and text. Section order is Connection → Reminders → Display → General. Current selection and direct shortcuts are retained; entry is not forced to the first section.
- **Validation:** 1 Core version test and 4 scoped App tests passed, covering bundled marks, section/platform retention, actual return scroll offset and 740×620 Chinese/English light/dark rendering. Sixteen platform-section combinations and four General views rendered; representative images inspected: [dark Connection](evidence/dev15-settings-icons-dark.png), [light English Reminders](evidence/dev15-settings-icons-light.png). All images use isolated data.
- **Native checks:** Final package section order, both platform selectors and repeated left/right selection with retained focus verified. Fixed an initial focus loss caused by rebuilding scroll content after platform selection.
- **Build and scope:** Existing build/run script and strict local-preview signature verification passed. The earlier dev.14 full 326 Core +149 App result remains the baseline; the entire suite was not repeated this pass. Windows changes are metadata only, with no new 403 fix or affected-device claim.
- **Live check:** On 2026-11-01, after the user unlocked the Mac and allowed system access, normal retry restored the existing Codex login and DeepSeek connection. Final dev.15 Codex refresh and fresh DeepSeek total/granted/topped-up balances were verified. Only dev.15 runs. No key re-entry was needed; no keys were read, transferred or deleted by the agent, and existing rules/automatic-card consent were not changed. Live screenshots remain local. Full release requirements remain below.

## 0.7.0-dev.14 native navigation correction

The user continued after prototype review. This implementation restores familiar paths and reuses existing stores and controls.

| Requirement | Status and evidence |
| --- | --- |
| DeepSeek discovery | Both supported platforms remain visible. Selecting DeepSeek then Connect opens the key form directly. [Isolated disconnected view](evidence/dev14-deepseek-disconnected.png). |
| Four Settings sections | Reminders / Display / Connection / General restored. Connection and Reminders select a platform; existing Codex rules/cards and local display/general controls are reused. |
| Explicit return | Fixed outside scrolling content; restores source platform/page, DeepSeek range and actual scroll offset. [Long-content return](evidence/dev14-fixed-return.png). Automated NSScrollView readback verifies restoration; normal sidebar navigation still starts at the top. |
| Shared rules and permission | Synthetic threshold 10 reads back through the sidebar. Enabled rule and denied system permission remain independent. [Balance alert](evidence/dev14-deepseek-alert.png). |
| Catalog and form | Supported rows go directly to connections; return retains filtering. [Catalog return](evidence/dev14-catalog-return.png). Synthetic failure/cancel/reopen clears stale errors; success shows total/granted/topped-up balances. Escape restores opener focus. |
| Credential recovery | Background reads remain silent. Explicit DeepSeek retry permits normal system authorization with the same service/item keys; no credential migration. Added identity-preservation regression test. |

Final validation: 326 Core + 149 App tests passed, zero skipped. Windows check, smoke and smoke:ui passed; development version consistency passed. Both platform Connection/Reminder settings rendered at 740×620 in Chinese/English and light/dark modes; this does not prove full VoiceOver acceptance. The native package uses the existing local preview identity and passes strict signing verification; it is not a Developer ID notarized release.

No new provider integration, consent or manual card redemption this pass. Real notification delivery, Widget dragging, full 65-feature live upgrade checks and affected-device Windows 403 acceptance remain release requirements. Windows network-path/guidance changes came from dev.11/dev.13; this pass only synchronizes metadata and runs regression checks, not proof of fixing the friend's device.

Live switch: only dev.14 runs. All 18 pre-existing ReadyCheck preference fingerprints matched after the switch. The final binary restored the existing Codex login and refreshed successfully after system authorization. Explicit DeepSeek retry reached normal system authorization. After the previous key was rejected, the user verified a key inside dev.14; fresh total/granted/topped-up balances and the signed-in Codex state were observed. No key was read or transferred by the agent. This verifies immediate connection behavior, not every release requirement.

## 0.7.0-preview.5 navigation correction

| Requirement | Status and evidence |
| --- | --- |
| Familiar Settings paths | Complete in prototype: Reminders / Display / Connection / General, platform selection inside Connection and Reminders. |
| Connection and recovery | Complete in checked synthetic flows: disconnected tabs visible, direct connection, failure/cancel/reopen, restricted-state retry. |
| Shared state and explicit return | Complete in checked flows: shortcuts read the same rule; fixed named return restores page/platform/range, catalog search and scroll. |
| Retention | Partial: dashboard, token examples, balance components, cards, notifications and display controls remain represented. Native parity is unverified by this prototype. |
| Validation | [Browser and visual evidence](prototype/design-qa.md); build, 4 catalog and 4 hosting tests passed. |
| Pending and release blockers | User review, native migration, complete retained-feature acceptance, real notifications/Widget and affected Windows 403 retest. No native change, package or release this pass. |

## 0.7.0-dev.13 Windows 403 guidance

Windows OAuth HTTP 403 responses now explain that system networking and service-region policy may differ from browser behavior. A synthetic response test verifies the guidance and excludes the authorization code and verifier; Windows checks and smoke tests passed. The dev.13 x64 preview package was built, inspected and ZIP-integrity checked, but the affected Windows machine has not yet been tested. The macOS service settings now show notification permission status. In an isolated synthetic native app, verified service switching, DeepSeek alert save and return, Codex settings, language switching and the simultaneous display of an enabled rule and denied system notifications. Four targeted tests passed. A newly packaged preview build is required for final validation. Developer ID signing and notarization remain unavailable.

A local proxy fixture using cached Electron 43.0 on macOS verified that the injected `net.fetch` sent both code exchange and refresh requests through an explicitly configured Electron proxy. This does not verify automatic Windows system-proxy discovery or the packaged Electron 43.5 binary. After the notification-status change, the final dev.13 build passed the full suite: 326 Core and 148 App tests, with two opt-in visual tests skipped in that run and previously passed separately. A preview DMG was built; its mounted app reported dev.13 and passed strict signature verification. This is a self-signed preview, not a notarized distribution build.

In the isolated synthetic native app, the Display settings exposed the Widget visibility toggle, bubble/card style selector, notch and fullscreen settings. Visibility and style controls were switched and read back; actual drag, real-account upgrade and system notification delivery remain unverified by this check.

Unlocked full regression: 326 Core tests and 148 App tests passed; two opt-in native visual tests were skipped in that run and passed when run separately. The macOS dev.12 app was built with the stable local preview identity and passed strict signature verification; it is not Developer ID signed or notarized.


## 0.7.0-dev.12 service settings implementation (in progress)

- The native overview and usage page open settings for the selected service. The catalog routes Codex and DeepSeek separately; the existing Codex reminder and automation controls and DeepSeek connection and balance-alert controls reuse their existing stores. Application settings contain the shared preferences and system notification controls.
- DeepSeek usage displays local balance readings with an explicit no-token/no-expense explanation. Existing Codex rule and connection recovery entry points route to Codex settings. Navigation state and selected renderings were tested with synthetic data; real upgrade, accessibility interaction, notification delivery, long-running behavior, and Windows 403 reproduction remain pending. No new automatic-card consent was granted.
- The first full run passed 326 Core tests; its App target had two outdated menu-label assertions, now corrected. A second run passed 147 App tests (3 skipped), while four protected-ledger Core tests failed with EPERM after the Mac locked. Re-run the full suite unlocked; do not count the combined runs as one passing run. Windows checks and smoke tests passed; the dev.12 x64 app package was built and read back, without real Windows execution.
- Release is blocked until the end-to-end checks below pass. The available local signing identity is a preview identity; Developer ID signing and notarization are not yet available.


## 0.7.0-dev.11 Windows proxy path

- The Windows main process now passes Electron `net.fetch` to the OAuth and usage clients. Node tests cover token exchange, refresh and existing usage behavior.
- An Electron proxy integration check could not run because the local Electron binary was unavailable and its download did not complete. The Windows x64 package was built and its version and network wiring read back from app.asar; system-proxy routing, browser-extension-only proxies, and the reported 403 remain unverified on the affected machine. A genuine unsupported-region response may still occur.


2026-10-31 preview.4: the App settings page language control was browser-checked in Chinese and English; other prototype pages remain Chinese. App settings and DeepSeek service settings were visually checked at 700 × 750. Build, catalog and hosting tests passed. This is a synthetic prototype, not native settings implementation.


2026-10-31 preview.3 settings prototype: browser-checked DeepSeek alert save/return, Codex automatic-card explanation and synthetic record, App settings entry, and a synthetic DeepSeek notice linking to its service settings. All data is synthetic. Language switching is not implemented; narrow-window behavior remains unaccepted. Build, catalog and hosting tests passed; this is not native settings implementation.

[Feature retention checklist](RELEASE_AUDIT.md) · [中文](QA.zh-CN.md) · [Product plan](PLAN.md) · [Prototype](prototype/README.md) · [Visual gate](prototype/design-qa.md) · [Existing native baseline](../0.6.1/RELEASE_AUDIT.md)

Historical development status (superseded by the dev.16 summary above): DeepSeek balance and a low-balance notification have been verified with a real account in isolated test applications. The installed app, real Codex account in the integrated test, other providers and Windows remain separately unaccepted. Detailed dated evidence and limitations follow below.

## Historical prototype acceptance

2026-10-30, 0.7.0-preview.2. This checks a browser prototype with synthetic fixtures. It is not native app release or new-provider live acceptance.

| Requirement | Result | Evidence |
| --- | --- | --- |
| Small low-frequency service switcher | Passed | Only demo-connected Codex/DeepSeek appear; reload remembers DeepSeek. Home/End and wraparound arrows work with two services. |
| Different units and missing data | Passed in fixtures | Codex shows quota and percentage-point history; Token page explains the separate unit. DeepSeek shows balance with Token history unavailable; planned services stay in the catalog and do not create empty quota panels. |
| Ten-service scope | Passed as catalog only | Exactly ten agreed targets, first/second batch each five; Chinese search finds the scoped Bailian Coding Plan; removed OpenRouter has no result; clear filter restores ten; source detail remains explicitly pending. |
| Charts and reset explanation | Passed | 24h/7d/30d changes; keyboard tooltip shows 10/29 12:00 and 15 percentage points. Reset explanation differentiates normal resets from card use. |
| Benefits and card record access | Passed in fixtures | Expanded plan, expiry, Credits and two cards; first card opens an observed/waiting result, without fabricated redemption. |
| Notification history | Passed in fixtures | Three timestamped examples; reset-card filter leaves one; detail states the provenance and time. |
| Reminder controls and navigation | Passed in fixtures | Threshold 5% appears in Overview, switch toggles off/on, then threshold restored to 10%. Four navigation routes and About are reachable. |
| Modal keyboard handling | Passed after fix | Escape closes; keyboard focus returns to Reset explanation. |
| Themes and narrow layout | Passed for tested views | Light/dark desktop and 520×900 captures. No document/main horizontal overflow; narrow catalog has ten rows and no horizontal overflow. Narrow icon navigation has accessible labels after correction. |
| Console/build/runtime | Passed | No browser warning/error messages; Vite build and four hosting tests pass; four catalog-scope tests pass. Vite's bundle-size advisory remains. |
| Existing native capabilities | Not changed, not re-tested wholesale | No native source or live settings changed. Existing quota, Token, benefits, reset-card authorization/history, reminders, menu bar, Widget last-hour chart, notch and drag/pin behavior remain in installed 0.6.1. |

## Partial / not implemented

The directory and source descriptions are implemented as a local discovery interface. New-service authentication, statistics adapters, live account/permission checks, real alert delivery and a native multi-service interface are not implemented. Native language coverage, provider-specific failures, offline/recovery, multiple accounts, and Windows require separate work. No real card was redeemed, and no model was invoked.

## Release blockers and remaining real acceptance

Before shipping 0.7.0, validate at least one new provider's true read-only data, isolate identities/history, verify fresh/missing/stale fields, check polling and reminders without inference costs, migrate the selected design natively, and map existing feature retention individually. Full service catalog coverage is not a first-release capability promise. No tag, package, public push or deployment is part of this milestone.

## Evidence

- [Selected design](prototype/evidence/selected-light.png), [desktop light](prototype/evidence/desktop-light-final.png), [desktop dark](prototype/evidence/desktop-dark.png)
- [Full comparison](prototype/evidence/comparison-final.png), [focused header](prototype/evidence/comparison-header.png), [focused lower area](prototype/evidence/comparison-lower.png)
- [Catalog](prototype/evidence/provider-catalog.png), [narrow catalog](prototype/evidence/catalog-narrow-dark.png), [narrow light](prototype/evidence/narrow-light.png), [narrow dark](prototype/evidence/narrow-dark.png)

## Preview.2 scope acceptance — 2026-10-30 / 范围收敛验收

[Current desktop](prototype/evidence/preview2-overview-light.png) · [ten-service catalog](prototype/evidence/preview2-catalog-light.png) · [narrow dark catalog](prototype/evidence/preview2-catalog-dark-narrow.png) · [implementation scope](TECHNICAL.md). Historical preview.1 captures remain below for traceability; they are not current service coverage. No existing native feature was removed.

## 0.7.0-dev.1 native development progress

DeepSeek Keychain connection and native balance display are implemented. Synthetic tests cover successful reads, preserving the old key when a replacement is rejected, and disconnecting without changing Codex credentials. A standalone synthetic balance view was rendered; full-window interaction and a real account remain unverified. Balance history, alerts and compact surfaces remain incomplete release blockers. The preview.2 results above describe the earlier prototype, not acceptance of this native build.

Earlier full Swift test attempts were interrupted while slow native window rendering was still progressing. A later run completed: 443 tests, 2 skipped, no failures, on the dev.1 baseline before the history changes.

## 0.7.0-dev.2 balance history

Eight focused connection/history tests passed, covering currency and connection isolation, reconnecting the same key, key replacement, legacy migration, five-minute sampling, 30-day retention, and preserving corrupted files. A synthetic standalone view was rendered; range control interaction, the complete window, and a real account remain unverified. Full regression on the dev.2 baseline passed: 448 tests, 2 skipped, 0 failures.

## 0.7.0-dev.3 background refresh

The app owns the DeepSeek connection, refreshes at startup and approximately every five minutes. Synthetic connection tests verify a read without opening a view and no duplicate startup request. Full app lifecycle, a real account, and notifications remain unverified; no inference request is sent.

## 0.7.0-dev.4 service selection

Focused tests cover Codex only, DeepSeek only, and the remembered selection when both are connected. The full native window and real-account flow remain unverified.

## 0.7.0-dev.5 balance alerts

Synthetic tests cover explicit enablement, connection/currency isolation, rearming on recovery, denied permissions, accepted but unverified delivery, deduplication across restart and notification routing. Notification content omits the balance. The notification page shows the latest submission for current rules, not a complete history. Live OS delivery, a real account and full native UI remain unverified. If local persistence fails after OS acceptance, repeat submissions are suppressed during the current process, but a restart after the system notification disappears may repeat; this is not strict exactly-once delivery across a crash.

## 0.7.0-dev.6 native interface

An isolated temporary app with synthetic Codex/DeepSeek data was inspected in light and dark: provider switching, the balance chart, alert threshold controls and the Codex account disclosure were usable. A single-point chart axis defect was corrected so the axis spans the selected 24-hour/7-day/30-day period with dates. Focused history-range and native-window tests passed. No real credentials or live system notifications were used. At the 740×648 minimum window, 24-hour and 7-day charts were inspected and overlapping date labels and edge-point clipping were corrected. At that point the 30-day chart, menu-bar interaction, live account and notification delivery remained unverified; later evidence appears below. The dev.6 layout full regression passed 459 tests with 2 skipped. It was built before the final chart tick adjustment, which was covered by focused tests and the synthetic window inspection.

## Isolated read-only acceptance preparation

The 30-day narrow-window chart and synthetic disconnect/reconnect form were inspected with a synthetic client. A separate DeepSeek read-only acceptance window was prepared with a dedicated Keychain item and temporary history, without Codex account or reset-card services; it sends no balance request until a key is provided. This window tests real balance and connection behavior only, not production-app notifications. At that point no real key had been entered; see the later result below.

## Isolated live balance read — 2026-10-30

The user entered a key directly in the isolated acceptance window and connected. The window displayed a saved connection and the official balance with currency breakdown, and one local history observation was recorded. This verifies one real read-only fetch and one observation in the isolated app only; the history file had mode 0600 and its fields contained no key or token. No real amounts, account details, or credentials are recorded here. The installed and development main apps have not been connected or validated by this check; restart/Keychain retrieval, repeated refresh, live system notifications, menu-bar behavior, and other services remain unverified. The isolated test credential and temporary data remain in place pending the user’s direction.

## Isolated refresh and simulated menu panel — 2026-10-30

While the isolated acceptance app remained running, a second real balance read and a second locally recorded observation at a different time were observed. This is not a long-running guarantee and does not validate the main app background scheduler. A separate synthetic window hosted the menu-bar panel, showing existing Codex quotas and the DeepSeek balance and invoking its detail action; the actual system status-bar popover was not tested. No real key, balance amount, or account details are stored in the repository.

## Isolated acceptance restart — 2026-10-30

The isolated acceptance app was restarted without deleting its credential or history. It restored the saved connection, displayed a newly refreshed official balance and retained local history, verifying Keychain retrieval and one read-only refresh after restart for this isolated test bundle. The installed app was not opened or replaced; the main app’s real connection and notification behavior remain unverified.

## Isolated system notification acceptance preparation

A separate test window was prepared with synthetic balance data and its own system-notification permission, reusing the development DeepSeek notification and deduplication logic. It does not access real accounts, balances or credentials, and does not change the installed app notification authorization. At preparation time no notification had been sent; see the later result below.

## Isolated system notification acceptance — 2026-10-30

The initial temporary-directory test bundle was not recognized by the macOS notification service: authorization returned an error, no notification was sent, and the user saw no permission prompt. A separate workspace test bundle signed with the existing local development identity was then used. The user allowed its notification request, the test app confirmed the synthetic notification in Notification Center, and system logs recorded banner delivery. The notification used synthetic conditions without accessing a real account, key or balance, and did not change the installed ReadyCheck notification authorization. This validates system delivery for the isolated test bundle, not the installed app or an end-to-end alert from a real balance.

## Isolated full-window live connection — 2026-10-30

A separately signed full-window acceptance bundle uses its own Keychain service and temporary history/alert data; Codex sources and reset operations are blocked in this bundle and shown as synthetic. After the user entered a key in that window, it showed a saved connection, switched between synthetic Codex and real DeepSeek, completed a manual read-only refresh and recorded two local observations; the file had mode 0600 and no key/token fields. This does not mean the installed main app was replaced or connected. End-to-end system delivery triggered by a real balance remains to be observed separately. No real amount, account or credential is recorded here.

## Deferred: Windows login token request 403

The user reported that a friend’s Windows login reached the browser callback, then the app reported HTTP 403 from the OAuth token request with a service message that the region is unsupported. ChatGPT works in the browser on the same machine. The authorization code visible in the screenshot is sensitive and is not recorded or reused. Browser availability does not establish that the app process uses the same network path; proxy inheritance, egress, service region policy and other causes remain unverified. Per the user’s request this is deferred until the current development is complete; reproduce on Windows, inspect each request path, and distinguish a service-side restriction before claiming a fix.

## Isolated full-window real-balance alert — 2026-10-30

The user enabled a test threshold in the isolated full-window bundle and authorized notifications for that test application. After a real DeepSeek balance read, the application reported verified delivery and its notification page showed the latest verified rule submission. Alert storage and credentials are isolated; notification and repository evidence do not contain a real amount or credential, and installed-app notification permissions were not changed. Acceptance exposed a confusing Codex empty state displayed alongside a DeepSeek record; a subsequent UI correction is tracked. This is not acceptance of the installed main app or a real Codex account.

## 0.7.0-dev.7 identity and notification-history corrections

A failing test reproduced old DeepSeek balance remaining visible after the stored connection identity changed and the new read failed. The correction clears the old displayed balance and timestamp without deleting old history files; a failure on the same connection still retains and labels the previous reading. Notification filtering now includes the latest DeepSeek submission per current rule without an incorrect empty state. Focused tests cover identity changes, same-connection failures and alert filtering. A synthetic window was inspected for All and card-expiry filters; visual clicking of the DeepSeek filter was interrupted by user control.

A regression test also reproduced an old delivery timestamp being reused after a new alert cycle was submitted. New submissions now clear the previous delivery timestamp until the new delivery is verified.

The dev.7 full Swift test suite passed: 462 tests, two skipped, zero failures. The focused identity, alert and history tests passed separately.

On 2026-10-31 the previously interrupted DeepSeek filter was also selected in the isolated synthetic notification window. The selected filter and its synthetic latest alert appeared correctly, without the empty state. This does not add evidence about the installed app.

## 0.7.0-dev.8 balance breakdown

The overview separates total, granted and topped-up balances for each currency; the compact menu row also includes the two components. In an isolated synthetic native window, the Chinese and English overview labels and values were checked. Parsing tests cover the individual fields and zero values. The installed app and the actual menu-bar popover were not re-tested in this check.

## 0.7.0-dev.9 native service directory

The native overview opens a ten-service directory with batch and search filters. Automated tests check the approved order, two batches, aliases, and that only Codex and DeepSeek are marked supported. An isolated synthetic window was checked for Chinese and English directory labels, search, the second batch, a planned-service detail and return, an empty search and reset, Escape dismissal, and navigation from DeepSeek to existing connection settings. The corrected English names for Bailian and GLM were subsequently checked in a rebuilt synthetic window. No additional provider was connected or tested with a real account.

The dev.9 full Swift suite passed: 464 tests, two skipped, zero failures.

## Gemini app offline parser — work in progress

Synthetic tests cover separate five-hour and weekly usage fractions, zero versus missing windows, malformed values, duplicate windows, invalid dates, signed-out responses and rejected queries. An unwired read-only client has fixture tests for a fixed Google HTTPS destination, explicit session input, HTTP failures and rejected redirects; no actual Google request or redirect was exercised. Neither component is connected to session acquisition, credential storage, UI or background refresh. The observed web response is undocumented and may change; account-bound authorization and real read-only acceptance remain outstanding.

## 0.7.0-dev.10 service icons and local launch

The Codex and DeepSeek switcher displays the existing ReadyCheck and Simple Icons DeepSeek marks. An isolated synthetic window confirmed both images and click switching; automated checks load both bundled assets. The full Swift suite passed: 471 tests, two skipped, zero failures. Packaging in the Documents worktree failed code signing on filesystem metadata; a stable signed candidate was built and verified under local Application Support instead. The old app was closed and the candidate launched. At this checkpoint the existing Codex Keychain access requires user confirmation and the real DeepSeek connection has not yet been established in the candidate.

After the user approved the macOS Keychain prompt, the candidate showed Codex signed in and a fresh quota reading. The previous automatic-card consent remained enabled; a check recorded during the initial credential-access interruption is retained, and automatic recovery after that interruption still needs observation. The candidate's separate DeepSeek credential was not copied from the isolated test; its connection form awaits the user's entry.

The user subsequently connected DeepSeek in the candidate. The live overview showed total, granted and topped-up amounts for the returned currency and a manual refresh succeeded; the two service icons were also visually present. The previously enabled automatic-card setting remained enabled, its next check completed and the earlier credential-access pause was no longer shown; no manual card redemption was performed. DeepSeek's real-app balance reminder remains off and was not altered. Login at startup was shown as enabled, but the executable macOS will launch at the next login was not independently verified. No actual balance, account identifier or credential is recorded here.
