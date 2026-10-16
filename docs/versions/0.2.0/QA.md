# 0.2.0 black-box functional checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Interactive preview](prototype/README.md) · [Version index](../../VERSIONS.md)

2026-10-16. Current stage: 0.2.0 release preparation. The native redesign and dev.13 real-data acceptance are recorded below; About discoverability and release highlights are being verified. Packaging and public remote delivery are pending. This is a scoped self-signed macOS preview, with the existing Windows preview interface. [Release notes](RELEASE_NOTES.md).

## 0.2.0 release candidate and About — 2026-10-16

About remains in the application menu and Settings → General; the redesign made it difficult to discover. A persistent sidebar-footer button and menu-bar More → About now open the same window. Its existing icon/version/read-only/source/precision/copyright content is retained, followed by bilingual release highlights and a full-notes link. Settings → Connection also displays the same highlights. The About window scrolls, resizes and reuses a visible instance with updated language. No new credentials or task-control hooks are introduced.

Eight focused tests passed; the complete suite ran **319 tests, zero failures, one skip**. The existing pinned-window sizing test could not retain foreground focus. It is not claimed passed. New About/highlights native fixtures in both languages were inspected. Existing Charts and deprecated API warnings remain. Release metadata is consistent. The local DMG was mounted read-only; the actual bundled app reports 0.2.0 and passes strict deep signature verification. Its sidebar About entry and Connection product highlights were observed. English About initially opened below its header; the explicit top scroll anchor fixed it, and three affected tests plus real English/Chinese views were rechecked. Existing settings were retained and Chinese restored. Credential access in this rebuilt preview still requires macOS confirmation, so a fresh live quota read is not claimed for this exact bundle. Earlier dev.13 live-data evidence remains separate. Windows Electron 43.0.0 / packager 18 locked dependencies initially reported 11 advisories. Electron 43.5.0 and packager 20.3.0, plus the allowed undici lock refresh, now report zero npm advisories. Node.js 22.12–24 is checked before packaging (validated on 24). One build interrupted while its environment guard was being edited; it was discarded. The final fixed-script rebuild passed check/smoke/UI-smoke and ZIP integrity. These are source/package checks, not a Windows-device GUI run. Public-source rebuild and remote delivery remain pending.

## Public-source preflight — 2026-10-16

The sanitized public worktree rebuilt the final source: **319 Swift tests, zero failures, zero skips**. This run also passed the earlier foreground-sensitive pinned sizing test; the earlier skipped run is retained above. Release consistency passed. Windows check, smoke and UI behavior checks passed using Node 24, with zero npm advisories. Final ZIP/ASAR checks verified version 0.2.0, Electron 43.5.0, pruned development dependencies and no forbidden internal entries. The final Mac DMG was mounted read-only: arm64, version 0.2.0, strict deep signature passed with the existing preview identity. Only the current DMG and Windows ZIP are in the artifact directory.

Current public text, forbidden filenames/symlinks and 1,479 text blobs reachable in existing public history were checked; no private-content findings remained (example addresses were excluded). Public commits use a GitHub noreply address; existing public commit metadata is retained without rewriting history. This is a scoped preflight, not an exhaustive historical binary/media audit. SHA-256 values are in [release evidence](release-evidence.json). Push/tag/Release/latest and downloaded-asset verification are not yet claimed in this preflight.

## Current requirement acceptance

`0.2.0-dev.6` removes the menu's redundant normal availability text and sizes the quota section from measured content, capped for scrolling. The old native fitting height was 423 points and failed the under-400 regression; the corrected healthy and cached native captures pass, with cache warnings retained. Two focused rendering/version tests and local package/signature checks pass. [Updated native menu fixture](assets/native-menu-bar.png) uses synthetic data; this does not establish live popover placement acceptance.

[Sanitized structured evidence](native-acceptance-evidence.json). Test counts refer to their named source stage; the graph/data-boundary verification is recorded below.

| Requirement | Completed evidence | Remaining acceptance |
| --- | --- | --- |
| R1 explicit selection | Missing/reappearing cases pass; unknown stays a dash in the live package. | Live service removing/reintroducing a selected allowance. |
| R2 reminders | Native 5% selection and restoration to the existing 10% preference; evaluator/persistence/deduplication tests pass. | Actual 5% crossing and recovery across restart, Focus and sleep. |
| R3 account history | Account-isolation/migration regressions; live new history uses hashed ownership. Legacy file and backup verified against the pre-upgrade bytes. | Real second-account switch and interrupted upgrade. |
| R4 refresh failure | Same-account transport cache, original timestamp and auth/identity rejection tests pass; real Keychain-unavailable UI stays unknown. | Controlled live transport outage and recovery. |
| R5 upgrade | Existing standalone login reads real quotas after explicit credential retry; preference/legacy baselines preserved, test drag position restored; dev.9 explicit Show/Hide survives real relaunch. | Automatic credential access across rebuilt packages and interrupted upgrade/rollback. |
| R6 notification state | Live permission readback and explicit test returned “Verified in Notification Center”; existing records remain visible. | Independently observed banner, denied permission, lock/Focus/sleep and real cycle delivery. |
| R7 notch | User manually accepted the dev.4 appearance. Dev.5 preserves its geometry, removes hover callbacks/timers and opens only on click. Real collapsed/expanded views, help and main-window dismissal checked; 20 affected tests pass. | Fullscreen and multiple displays. Automated full-desktop seam capture is unavailable; appearance acceptance is user-reported. |
| R8 widget | Live vertical tab, first inward drag, expansion, unpin collapse and retained real last-hour chart; pinned main-window action reproduced, fixed and rechecked. | Other overlay/focus contexts, Spaces and display changes; current-screen bubble fullscreen visibility was observed in dev.9. |
| R9 accessibility | Command-1/2/3 navigation and dev.9 immediate bilingual native-menu updates observed; minimum-size/dark synthetic native renders and chart accessibility values checked. | VoiceOver, high contrast, reduced motion/transparency and physical 1×/2× devices. |
| R10 delivery | Local package/version checks and strict signature verification pass using the existing preview identity. | Formal installation/notarization, Windows feature work and authorized public delivery/remote checks. |

Menu-bar source tests and synthetic component capture pass, but the UI tool kept returning the main window after the user opened the status-item popover. Actual popover placement/shortcuts remain unverified; repeated user clicks are not evidence of success.

The test notification verifies a Notification Center entry, not a visible banner. No real account identifiers, quota values, paths or desktop captures are published. Local testing briefly launched the stable app by name; it was exited, its test-time legacy write was preserved privately and the original legacy bytes restored. New account-scoped history was retained. Existing authentication material was not deleted or copied.

The original development gate required all pending P0 device/lifecycle, upgrade, notification and platform coverage. That broader gate has not passed. The 0.2.0 delivery decision is explicitly limited to a self-signed macOS preview with the existing Windows preview, consistent with the existing distribution channel; it is not a fully validated production/notarized or platform-parity release. Pending checks in the table remain open. As specified in the upgrade review, known quota misrepresentation, mixed identities, migration loss, duplicate alerts or stuck windows would still block this preview. None is currently known from the recorded tests and device checks; untested conditions are not represented as passed.

## Chart boundaries and distinct histories — 2026-10-16

`0.2.0-dev.7` corrects fixed-width bars centered on the first/last continuous date-domain endpoints. The local quota chart reserves 24 points at both horizontal ends and clips the plot. Axis labels remain within the card; fractional ticks retain their decimal value. The minimum-width layout wraps explanatory text and separates the title/source from range controls.

Overview records locally observed quota declines in **percentage points**: 80%→70% is 10 points. **Token usage** shows Codex-returned daily Token counts, with UTC date buckets. Coverage differs and there is no fixed conversion. When Token statistics are absent, the page now explains the missing source instead of substituting another quota chart. No aggregation or account/credential behavior was changed.

Native SwiftUI/AppKit fixtures were visually inspected for sparse two-hour, single-bucket and dense records, in Chinese and English, at a 500-point component width and the 740-point minimum main-window width. The Token page remains vertically scrollable. Synthetic evidence: [sparse quota chart](assets/native-quota-sparse-en.png), [missing Tokens](assets/native-token-empty-en.png), [official Token fixture](assets/native-token-usage-en.png). These images contain invented data, not live-account evidence.

Full regression: **305 tests, zero failures, one skip**. The existing pinned-window sizing test could not retain foreground keyboard focus and remains unverified in that run. After the final UTC/calendar display adjustment, all **nine affected rendering, Token comparison and localization tests** passed without skips. Swift Charts emitted an axis-anchor warning; rendered labels were inspected, so logs are not claimed warning-free. Development metadata and strict local bundle signature checks passed using the existing preview identity.

The exact separate local package was launched and confirmed as dev.7. Before authentication, the actual Token page displayed the explicit unavailable state. After the user completed macOS Keychain confirmation, live quota refresh and official daily Token data returned. The refreshed Overview bars/time labels were visually checked inside the plot; the real Token page showed its separate source/unit explanation and UTC dates. Private live readings and captures are not included in the published evidence. The stable installation remains 0.1.145; nothing was pushed or published. Existing broader release blockers above still apply.

## Account benefits restored — 2026-10-16

The sidebar redesign omitted the old account-detail section. `0.2.0-dev.8` reconnects the existing quota-card detail presentation in an account-only mode on Overview, retaining the new quota and Token charts. It restores plan, subscription validity (or the original billing link), Credits balance/unlimited, manual reset count and every reset expiration. Exact quota reset dates are again visible beside the countdowns. The [capability preservation table](UPGRADE_REVIEW.md#existing-capability-preservation) maps the other prior main-window functions to their current entries.

Missing values are not zero. A partial reset list shows unavailable dates without dropping rows; absent subscription dates retain the billing link, and past subscription dates remain labelled as historical. Reset expirations explicitly use GMT+8. No provider, credential, reset-redemption or notification-engine behavior changed.

Ten focused native rendering/localization/version tests passed. Full regression: **306 tests, zero failures, zero skips**. Chinese/English 500-point account fixtures were inspected for complete, zero, unknown, partial, historical and unlimited data; the minimum 740-point main-window renders retain scrolling. [Restored account fixture](assets/native-account-benefits-en.png) contains synthetic values only. Swift Charts and the existing deprecated build/Keychain APIs still emit warnings; these logs are not warning-free.

Development metadata, local package and strict signature verification passed. The exact separate dev.8 package is running and its account section and billing fallback were observed. After the existing-credential retry, live data returned in dev.8. The actual account section was visually checked with the returned plan, manual reset count, every returned expiration and Credits balance; a past subscription date was correctly labelled as historical. Actual quota reset dates were also visible. No live values or account screenshots are included in public evidence. The prior dev.7 live chart/Token acceptance remains recorded above. Stable installation/public version remains 0.1.145; no push or release occurred.

## Desktop visibility and native menus — 2026-10-16

`0.2.0-dev.9` corrects a startup helper that always returned visible and ignored saved false. Explicit Show/Hide now persists through the existing visibility key; new installs still default to visible. Window-close synchronization during presentation transitions does not overwrite the explicit saved choice. The model accepts a scoped visibility defaults store so regressions can avoid the user's actual visibility setting.

The hidden-start regression first reproduced one failure. After the fix, 14 visibility/snooze/edge tests and 13 menu-language/localization/version checks passed; the complete dev.9 regression ran **309 tests with zero failures/skips**. The initial model fixture incorrectly initialized the real notification center under XCTest and was corrected to use the existing injected-client pattern; that interrupted run is not counted as a pass.

In the exact separate dev.9 package: explicitly hide→quit/reopen retained Off; show→quit/reopen retained On. The original running state (widget shown, notch off, fullscreen hiding on, selected bubble style and Chinese) was restored. A previously ignored saved false conflicted with the running On state; final visibility is deliberately saved as On to preserve the actual pre-test UI. Chinese is now explicitly saved rather than only being the default. Other scoped preference values, including positions, matched the pre-test capture; no old whole-domain preferences were restored.

Native File/View/navigation/Quit labels updated immediately on Chinese→English→Chinese changes, and the actual navigation menu and Quit action were exercised. Closing the main window kept the desktop entry alive and Command-1 reopened Overview. Existing window telemetry recorded the bubble becoming nonvisible on fullscreen entry and visible again on return; the app returned to windowed mode. This covers the current bubble/screen only, not every overlay or monitor.

The fullscreen exercise also exposed a separate bilingual menu gap: AppKit added a native fullscreen command to an English View menu, but the Chinese menu had none. Track its explicit-command correction in the next section; dev.9 is not claimed to have passed that keyboard path. Rebuilt-package credential access still requires separate verification. No credentials, real readings or desktop captures are published, and the stable installation remains 0.1.145.

## Explicit fullscreen command — 2026-10-16

`0.2.0-dev.10` supplies the fullscreen toggle and Control-Command-F in both languages. It no longer depends on AppKit inserting commands after recognizing an English View menu title. Menu construction is separated from launch/authentication side effects so the bilingual labels, actions, navigation shortcuts, quit command and fullscreen modifier keys can be checked without starting real services.

The menu regression first reproduced one missing-item failure. After correction the complete suite ran **310 tests, zero failures/skips**. Development metadata, build and strict local signature verification passed with the existing preview identity. Existing Charts/build/Keychain deprecation warnings remain. After the user unlocked the Mac, the old dev.9 process was exited through its native Quit menu and the exact dev.10 bundle was launched. In both Chinese and English, View contained one explicit fullscreen command; selecting it entered real fullscreen, and Control-Command-F both exited and re-entered fullscreen. Windowed mode and Chinese were restored.

With the main window closed, the desktop tab remained available. Clicking it opened pinned details; Escape collapsed the focused panel back to the tab. After reopening and pinning, opening ReadyCheck, clicking Settings and closing the main window left the details expanded. Cancelling the pin collapsed the panel. The retained last-hour consumption area showed its honest insufficient-data state while credentials were unavailable. This covers the current focused edge-docked bubble panel, not every overlay or focus context. Display choices remained widget On, notch Off and fullscreen hiding On.

Before replacing the running process, dev.9 had refreshed real data successfully. Dev.10 reported that existing Keychain access required confirmation. After the explicit retry and user-handled system prompt, live data returned. The actual dev.10 Overview showed plan, subscription validity, Credits, manual reset count and every returned expiration, along with exact quota reset dates. The official daily Token page and live last-hour widget chart were also visually checked. Escape collapsed the refreshed details and Command-1 restored Overview. Unknown/missing days stayed unknown. Private readings and captures are excluded from public evidence; automatic credential access across future rebuilt packages remains unverified. No credentials or system trust settings were changed, and nothing was pushed/published.

## Quota period versus history range — 2026-10-16

`0.2.0-dev.13` spells out the selected quota's full name on Widget, includes the viewed history range in Overview's chart title, and puts bar duration and percentage-point units on a separate line. The example explicitly says remaining 80%→70% consumes 10 percentage points. The Token chart is named “Daily Token counts”, with daily UTC grouping. Shared aggregation, data sources, account details and existing interactions are unchanged.

Seven affected localization/version/native-render checks passed, zero failures/skips. Chinese and English Widget, 500-point quota components and 740-point main-window/Token fixtures were visually inspected; titles and explanatory lines remain readable. Reuse the dev.12 full 317-test result for unchanged calculations; no new full-suite run is claimed. Existing Charts/build/Keychain warnings remain. Local dev.13 packaging, strict existing-preview signature and development metadata passed.

After user-confirmed existing Keychain access, live readings and account benefits returned. Real Overview titles followed all three selected ranges and displayed separate bar-duration/unit lines; Daily Token counts retained its returned data and daily UTC explanation. The tool could capture the collapsed widget but its click action repeatedly returned `noWindowsAvailable`; this was not counted as a product failure or success. After the user opened the details, the actual full quota name, last-hour title, five-minute duration and percentage-point unit were visually inspected. Escape collapsed it and Command-1 restored Chinese Overview at 24 hours. Private live readings/captures are excluded. No push/release; stable remains 0.1.145.

## Shared consumption meaning — 2026-10-16

`0.2.0-dev.12` uses one `observedDecreases` path for Widget bars, Overview bars and Overview totals. Before correction, two regressions produced three failed assertions: Overview bridged reset/missing/invalid transitions that Widget excluded. Both now exclude reset-time changes, invalid or missing window readings and gaps over 600 seconds, and count only positive decreases between valid samples inside the requested range. Recovery adds no consumption. Overview totals use the same aligned range as its plotted buckets and exclude future samples. No history files, credentials, notification logic or official Token counts were changed.

The [product data table](PLAN.md#user-outcome-and-scope) defines the two types. Widget is the selected allowance's last hour in five-minute bars; Overview groups the same local history into 1-hour / 6-hour / 1-day bars for its 24-hour / 7-day / 30-day ranges. Both display percentage points. Compact Widget heights scale to their own maximum, so raw heights are not comparable across surfaces. Daily Codex Token counts are a separate metric without a fixed conversion. Both languages state these relationships in the interface.

After the rule fix, 15 focused checks and **317 full regression tests passed, zero failures/skips**. After final text, development-version and English Widget fixture updates, seven display/localization/version checks passed. Chinese/English minimum-width Overview, Widget and Token fixtures were inspected: [Overview](assets/native-consumption-overview-en.png), [Widget](assets/native-consumption-widget-en.png), [Tokens](assets/native-consumption-token-en.png). All use synthetic data; existing Charts/build/Keychain warnings remain.

Local dev.12 package, strict existing-preview signature and development metadata passed. After explicit existing-credential retry and user confirmation, real Overview totals matched the visible bucket sum, all range labels changed correctly and returned to 24 hours, the Token page retained its returned data, and Widget displayed the shared unit/source and five-minute interval. Escape collapsed Widget and Command-1 restored Chinese Overview. Private readings/captures are not published. Stable remains 0.1.145; no push/release. Broader device and delivery gates above remain.

## Quota bar inspection — 2026-10-16

`0.2.0-dev.11` adds pointer-hover and click inspection to Overview's local quota bars. The tooltip shows the bucket's local date/time interval and consumed **percentage points**, retaining one decimal when needed. It does not report remaining quota or Token counts. Leaving a bar/plot or changing its data clears the inspected value; invisible zero bars and chart gaps do not produce a fabricated consumption result. Existing aggregation, range controls, chart padding/clipping, reveal animation and the separate Token page are preserved.

Five focused checks cover bar hit testing, first/last edges, gaps/zero values, bilingual fractional units and native inspected-bar rendering. The full suite passed **315 tests, zero failures/skips**. At 430-point chart width, Chinese/English first/middle/last native fixtures were visually inspected. The initial native annotation was cropped at an edge; the final tooltip uses a horizontally bounded plot overlay. Synthetic examples: [Chinese tooltip](assets/native-quota-tooltip-zh.png), [English tooltip](assets/native-quota-tooltip-en.png). These contain invented data. Existing Charts/build/Keychain warnings remain.

The exact dev.11 preview was launched. After the user confirmed existing Keychain access, real quota history and account benefits returned. Clicking the actual first and last bars showed the matching time interval and consumption, inside the plot; clicking a gap cleared the tooltip. The hover callback uses the same inspected-bar path, but pointer-only movement is not exposed by the current UI tool and was not independently observed. Package/strict signature and development metadata checks passed using the existing preview identity. The sandbox-only signature trust lookup failed; the same read-only verification outside that restriction passed, without changing system trust. Stable installation/public version remains 0.1.145. No push or release.

## Historical prototype acceptance

The following section records the web-only prototype stage. Native completion is tracked above and in the later implementation batches.

preview.2 adds the Settings→Display five-state board entry, verified image loading, close/Escape paths and build. The board shows orb, expanded widget, edge preview and collapsed/expanded notch as visual concepts only. [Cross-version review](UPGRADE_REVIEW.md) R1–R10 still require native implementation and acceptance; source inspection is not live-device validation.

| Requirement | Prototype result and evidence | Native acceptance pending |
| --- | --- | --- |
| Navigation / first view | Passed: three pages and settings categories switch. Both quotas visible at 1440×1024 and 740×792; 390×844 has no horizontal overflow and scrollable content. | Native window sizes, keyboard, VoiceOver, light/high-contrast appearance. |
| Reminders | Passed: select 5%, disable recovery, return to matching overview; restore 10%/enabled. Simulated denial→instructions→allow→in-page test notice. | Actual permission, notification entries/banners, lock/Focus behavior, deduplication across restarts. |
| Data states | Passed: low 8%, recovered 100% with new-cycle accumulation, offline retains 19:42 timestamp and chart only through 19:40, stale refresh recovery, unknown does not become zero. | Real transport/auth errors, sources/accounts and actual resets. |
| Repair | Passed: authorization required→user opens repair→explicit simulation→normal. | Live OAuth, Keychain, preserved upgrade credentials and non-interactive background reads. |
| Usage | Passed: 7/30/90-day selection; 90-day view labels 30-day coverage; unknown not zero. Arrow keys inspect chart values and units. | Real history, gaps/resets and source consistency. |
| Widget controls | Passed: primary 7d produces 70% interaction preview; pinned stays open on outside click, unpinned closes; hide disables preview, restore enables it. | Native geometry, window level, fullscreen, drag, displays and focus behavior. |

Visuals: [selected direction](assets/overview-concept.png), [overview](assets/overview-preview.png), [reminders](assets/reminders-preview.png), [incomplete usage](assets/usage-preview.png). All assets are synthetic. Full and focused local comparisons: [design-qa.md](prototype/design-qa.md).

Completed: clickable prototype, browser paths/capture inspection above, production build, link and sensitive-data checks. Browser error/warn logs contained no entries. Dialog Escape, focus indication and Shift-Tab focus containment were checked; this is not a full accessibility-compliance claim.

Partial: real component appearance references and in-page state simulations. Pin/hide do not control OS windows. Settings do not affect the installed application; window-level, fullscreen and refresh-interval controls only retain in-page choices.

Not completed: all native 0.2.0 implementation, real notifications/auth/upgrade, Windows counterparts, installers, public release and remote acceptance. The released app remains 0.1.145.

Release blockers: native implementation and requirement-by-requirement acceptance. A passed prototype is not production acceptance. Build emits a chunk-size warning above 500 kB; the local demo runs, and this web bundle is not the native production implementation.

preview.3: corrected both notch joins and the thin vertical edge rail in the concept board. Versioned image loaded and its browser capture was inspected; build passed. Native geometry remains unimplemented.

## Native development batch 1 — 2026-10-15

Unreleased source version `0.2.0-dev.1`; installed/public version remains 0.1.145. R1 and R2 have implementation and regression coverage, not native visual acceptance. Explicit missing windows remain unknown in the selector, bubble and notch; saved label metadata contains no quota values. The 5% threshold uses the existing reminder engine. Nineteen targeted tests passed after reproducing six assertions against the old implementation. SwiftPM uses the native build system and a temporary scratch/cache directory because the sandboxed default manifest and old Xcode test bundle signing failed before tests could run. Full lifecycle and native UI acceptance remain pending.

Development metadata: `bash scripts/check_release_consistency.sh --development`; public stable download references are intentionally preserved and excluded by this explicit development mode. Default release validation remains strict.

## Native data integrity batch — 2026-10-15

R3/R4 implemented in source. Verified snapshot identity scopes new history via a SHA-256 account key; no identity means no assignment. The v2 file is separate, the legacy file remains byte-for-byte intact, and a backup is required before new writes. Corrupt v2 files and failed backups are not overwritten. Tests cover A→B→A, restart/logout, unowned/corrupt legacy data, stale/out-of-order samples and failed backup. Old per-account supplemental details cannot carry into a different account, including a batch completing after the switch.

Only same-account, same-source transport/server failures retain last known values, original success time and a stale/cache marker. Auth/identity/parser errors do not borrow cached values. Cached readings cannot trigger low/recovery notifications or add history. The app model adopts the verified account and clears visible history on identity changes. Generic thrown errors without identity remain unknown deliberately.

Validation: full native SwiftPM regression ran 292 tests, 0 failures, one existing foreground-focus sizing test skipped; a subsequent targeted run after the in-flight guard passed 53 tests. No skips were silently removed. Earlier sandbox execution could not access NSScreen/loopback; normal local execution resolved those environment failures. Real upgrade, focus sizing and new visual acceptance remain pending. The initial R4 regression reproduced nine failed assertions before the fix.

## Native sidebar batch — 2026-10-15

`0.2.0-dev.2` implements Overview/Usage/Settings, reminder/display/connection/general sections, a resizable 740-point-minimum main window and Command-1/2/3 menu entries. The existing quota, history, connection repair and notification actions are connected. Permission is read at launch and requested from explicit reminder/test actions. Language and refresh interval now persist; other existing preference keys remain in use. The native root retains page/category selection while hidden.

Inspected actual SwiftUI/AppKit fixture renders at 740 points in Chinese/English, all four settings sections, empty/cached states and a 900-point dark environment: [native overview](assets/native-overview.png), [native reminders](assets/native-reminders.png). Values are synthetic, not live account data. Fixed the selected-row capture contrast and crowded chart labels; dates now use a temporal axis with explicit consumed-point accessibility values. Fixture captures paint the normal window background and wait for the existing chart animation; they are not packaged-app screenshots or full VoiceOver tests.

Full normal-session regression: 294 tests, zero failures, one existing focus-dependent sizing test skipped. Build and paired development version checks pass. Desktop redesign, packaged-app keyboard/resize/persistence checks, actual notification banners, migration/rollback and device acceptance remain release blockers. Installed/public stable is still 0.1.145.

## Native desktop entries — 2026-10-15

Unreleased source `0.2.0-dev.3` implements the concise menu-bar popover and selected-quota status text, a 380×304 expanded widget card with its selected-window **last-hour consumption** chart preserved, thin vertical edge tabs, and 360×264 notch hover/click-hold details. Widget pinning remains explicit and independent of temporary notch hold. Both notch frames overlap the physical gap bottom by one logical point. Existing supersampling is retained for the new card silhouette.

Inspected synthetic native component renders: [menu bar](assets/native-menu-bar.png), [widget and last hour](assets/native-widget.png), [notch details](assets/native-notch.png), [100% collapsed orb](assets/native-orb-100.png). Fixed a collapsed-layout offset caused by the invisible expanded card; checked 80%, 100% and unknown outputs. Replaced the optimized rounded-path storage with an explicit CGPath after transition center-containment checks failed; all tested transition centers/bounds now pass. These are native component fixtures, not evidence of a physical camera-notch seam or real notification delivery.

Full regression after desktop/availability/upgrade-comparison changes: **302 tests, zero failures/skips**. After the final collapsed-layout correction, 27 affected native window/drag/pin/mask/trend tests passed. A late window without verified confidence remains unknown even if another window is verified. Development versions compare below their stable release, and build metadata is ignored; the old comparison first reproduced three failed assertions. Legacy history is kept separate and explained in Overview/Usage; unverified identity never receives old samples.

Pending: packaged-app smoke tests, physical notch seam/hover, real notification entries/banners and sleep/lock/Focus, multi-display/Spaces, VoiceOver/high contrast and interrupted upgrades/rollback. This development batch is not a public 0.2.0 release. Windows has version metadata only; its existing interface did not receive these macOS features.

## Packaged-app pin correction — 2026-10-15

The live `0.2.0-dev.3` package revealed that the main-window button explicitly collapsed even pinned details. `0.2.0-dev.4` preserves pinned details and only dismisses temporary previews. The new regression first reproduced two failed pin/expansion assertions; all eight affected pin/version tests pass after the fix. The rebuilt, strictly verified local preview also keeps its pinned card open after opening, interacting with and closing the main window. The stable installed binary remains 0.1.145; no public release or push was performed.

## Click-only notch — 2026-10-15

The user manually checked the previous notch appearance and accepted it. `0.2.0-dev.5` removes the notch's hover event wiring and shared hover timers, using only explicit expanded/collapsed state. The physical-gap placement and dimensions are unchanged. Twenty affected notch placement/window, widget hover, localization and version tests pass. They cover refresh while expanded, dismissal, repeated click, closing/reopening and unchanged attachment geometry. The strictly verified local package was launched and its real compact/expanded views, updated help and main-window dismissal inspected; real quotas loaded after explicit credential retry. Physical mouse hovering was not simulated by the UI tool. No stable installation, push or publication was performed.
