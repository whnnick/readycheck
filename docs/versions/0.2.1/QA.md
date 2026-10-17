# 0.2.1 black-box functional checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Version index](../../VERSIONS.md)

Current 0.2.1 release acceptance is recorded at the end. Development-preview entries below are historical evidence; their no-public-release statements describe those earlier stages. See [release notes](RELEASE_NOTES.md).

Historical baseline on 2026-10-16: preview `0.2.1-dev.1` was installed; public release was 0.2.0 and no publication was performed at that stage.

| Requirement | Evidence | Status |
| --- | --- | --- |
| No dial while edge-attached | Old implementation reproduced six failed assertions across both edges. Attachment now survives expansion/collapse, including rapid reversal; the attached renderer does not instantiate the orbital quota dial. | Passed controller regression. |
| Continuous attached rendering | Native synthetic frames inspected at widths 28, 92, 180 and 380 points on both sides. Rail blends into the details surface; no intermediate quota dial. | Passed staged native rendering; these are not a timed animation recording. |
| Position and controls preserved | 25 focused tests and 321 full tests passed, zero failures/skips; existing pin, outside interaction, inward drag, masks and layout coverage retained. Installed app click-to-pin, Escape-to-rail, live quota and last-hour chart checked. | Automated regression and installed-app checks passed. On 2026-10-16, the user confirmed both edge transitions no longer flash a circle and the animation feels normal. |
| Honest delivery | Standard local package built with existing preview signing identity; strict signature verification passed outside the sandbox. Installed version confirmed, live credentials read after system confirmation; original stable app preserved for rollback. | Passed local delivery. Self-signed preview, not notarized; no public tag/assets replaced. Windows metadata synchronized only; no Windows UI change. |
| Reduced motion and devices | Existing accessibility branch retained; no system preferences changed. | Reduced-motion device observation, multiple displays and Spaces not claimed. |

Native fixture evidence uses synthetic data. Live screenshots/accounts/readings and cleanup restoration manifests remain private, outside product source. Cleanup restored useful backups, evidence, scripts, audio tools/models and current development dependencies; only verified old caches, empty mount directories and byte-identical installer duplicates remain recoverable in Trash.

## 0.2.1-dev.2 preview-click follow-up — 2026-10-17

| Requirement | Evidence | Status |
| --- | --- | --- |
| Clicked details should not stay in hover preview | Before the patch, sending a native down/up pair to the preview's outer padding failed the keep-open assertion. Both free and attached background surfaces now receive the existing pin action. | Reproduced before fix; passed after fix. |
| Free, left and right placements; intermediate expansion | Two new native-window regressions cover all three placements at full and intermediate sizes, repeated background clicks and external dismissal after pinning. | 27 focused tests and 323 full Swift tests passed, no failures/skips, using the project's native build backend. |
| Explicit unpin and existing controls | Existing controller tests retain pin/unpin, pointer exit, focus, drag, Escape and edge attachment coverage. No state-machine or timer behavior changed. | Passed regression; do not interpret a hover-opened preview as a persistent preference change. |
| Signed installed app | Built by the existing packaging script with ReadyCheck Preview Signing; strict installed signature and metadata verified as 0.2.1-dev.2. Previous app preserved for rollback, settings/history/credentials retained. Native UI: click opens pinned; unpin followed by a click on the padding returns to kept-open state; Open ReadyCheck still opens the main window. | Installed interaction checked. Self-signed local preview, not publicly released. |
| Live quota after rebuilding | User completed the macOS confirmation. Connection returned to signed in; the running app showed a successful refresh, both quota windows, subscription validity, Credits, reset count/expirations and retained local history. Widget showed live quotas and the last-hour chart; kept-open state survived opening and closing the main window. | Passed installed-app follow-up on 2026-10-17. Private values/account details remain outside source. |

Private native proof is kept outside source. Public download remains 0.2.0; Windows changes are version metadata only. Initial default-backend testing hit a generated test-bundle signing attribute error; the existing native-backend workflow completed the full suite. Device-specific reduced-motion/multiple-display coverage remains as documented above.

## 0.2.1-dev.3 card drag and style selection — 2026-10-17

| Requirement | Evidence | Status |
| --- | --- | --- |
| Card moves freely | The pre-fix native-window regression found no explicit title drag region. The title now forwards its press to native window dragging, including first clicks on inactive windows. Buttons remain outside that region. Tests cover normal/floating levels and saved-position restore. | 22 focused tests and 327 full Swift tests passed, no failures/skips. The user confirmed physical free movement on 2026-10-17; subsequent saved-position inspection found an updated card origin. |
| Round and edge choices match their initial surfaces | Reproduced on installed dev.2: Round bubble restored a saved slim tab; Edge strip initially displayed the double-ring dock. Round selection now restores a circle, while edge selection and changing sides start collapsed. Tests also verify first rail click opens details. | Automated checks and installed dev.3 visual selection/click checks passed. Manual bubble snapping and explicit ring preview retained. |
| Installed package | Strict signature and installed 0.2.1-dev.3 metadata verified. User confirmed title dragging; card minimal/detailed switching, refresh and open-main-window actions checked with live data. Restored the user's previous round style and card display mode after checks. | Passed installed acceptance within the documented device scope; self-signed local preview, not a public release. |
| Existing account and history | The running dev.3 app now reads the existing account, current quota windows, subscription benefits and local history successfully. No new login or credential migration was needed during this follow-up. | Passed live-data follow-up. Account details and actual quota values remain private. |

No credential/history migration or public release is part of this patch. Three styles keep their independent saved-position keys. Hardware/multiple-display limits remain as above.

[Sanitized dev.3 evidence](evidence/dev3-widget-interactions.json)

## 0.2.1-dev.4 adaptive Widget — 2026-10-17

This update supersedes dev.3's separate round/edge selector requirement above. The two forms now belong to one floating Widget; Information card remains separate.

| Requirement | Evidence | Status |
| --- | --- | --- |
| One Widget with two resting forms | Settings now offer only Floating widget and Information card. The floating implementation handles circle, slim rail and common details; the duplicate rail controller/view/placement implementation and eight obsolete standalone-rail tests were retired. | Passed native settings inspection and controller regression. Three migration tests were added; total count changes from 327 to 322 for this reason. |
| Preserve existing choices and position | Legacy edge selection migrates once to the floating Widget, copying its valid frame while retaining the legacy source and a backup of the previous bubble frame. Invalid geometry keeps the existing bubble position; card selection does not run rail migration. | New assertions failed before implementation, then passed. Installed old edge selection migrated successfully; old rail record, bubble backup, card frame/mode and visibility were verified preserved. Vertical center remained within one point after the drag round trip. |
| Common interaction and content | Both edges retain attachment during open/close, direct inward drag, click-to-pin, explicit unpin and anchored refresh with every returned quota window. Circle and rail use the same detail view and last-hour chart. | 30 focused tests passed before the contour adjustment; 322 full Swift tests passed after it, zero failures/skips; four localization checks passed again after the final English label alignment. Installed right rail → pinned details → inward drag to circle → pinned details → outward drag to rail passed with native input. |
| Outer contour | The previous attached centered stroke extended outside the silhouette and was partly clipped. It is now an inset one-point border matching the free surface; the supersampled native mask remains enabled. | Native component circle/rail images inspected at 1× and 2×; staged attached widths 28/92/180/380 inspected. Installed circle/rail/detail corners inspected at the display's 2× scale with no obvious jagged outline. This is visual acceptance on the current display, not a claim of pixel-perfect edges on every screen. |
| Build and settings | Existing packaging workflow produced signed 0.2.1-dev.4; strict installed signature and version passed. Development metadata is consistent. Chinese minimum-width display settings and both-language release highlights inspected. Old app preserved privately for rollback. | Passed local delivery. Windows metadata only; public download remains 0.2.0. |
| Existing live account | New build requires the normal macOS confirmation for its existing Keychain item; retry was requested. Credentials and history were not removed or reauthorized. | Awaiting system confirmation and live-data follow-up. Native interactions and synthetic rendering above do not depend on this confirmation. |

No public push/release was performed at this preview stage. Other displays, Spaces and reduced-motion device observation remain outside this pass. Private screenshots, actual values and preference snapshots remain outside source. [Sanitized dev.4 evidence](evidence/dev4-unified-widget.json).

## 0.2.1-dev.5: release information placement — 2026-10-17

| Requirement | Evidence | Status |
| --- | --- | --- |
| Settings are for controls | Removed only the duplicate highlights and its divider from Connection settings; connection guidance and safe-refresh/Keychain explanations remain. | Installed dev.5 connection page inspected: no release-highlights block. |
| Highlights remain discoverable | About still contains all four current highlights and the full release-notes link. Sidebar/app-menu entry points and the General → About button remain. | Installed sidebar opens About; native screenshot and accessibility text show highlights and notes link. General still shows Check for updates. |
| Bilingual layout and local delivery | Three focused checks passed (bilingual About/highlights, native minimum-size pages, version), zero failures/skips; development metadata and strict installed signature passed. Earlier 322-test functional run is reused because this patch only removes static duplicated content and updates metadata. | Signed 0.2.1-dev.5 installed and About left open. No new popup, public push or release; Windows metadata only. |

The existing Keychain confirmation/live-data follow-up from dev.4 remains separate and is not claimed completed by these layout checks. No user preference, credential or history migration occurs in this patch.

## 0.2.1 release acceptance — 2026-10-17

| Requirement | Evidence | Status |
| --- | --- | --- |
| Adaptive Widget, card drag, pin rules, contour and About placement | Development acceptance above plus fresh 322-test release-version run, zero failures/skips. Updated About highlights name the actual 0.2.1 changes. Native synthetic current-version screenshots inspected; historical 0.2.0 screenshots remain archived. | Passed source regression and native rendering. |
| Existing account, benefits and history | Earlier dev.3 live acceptance and user-confirmed physical card drag retained. Later preview migration retained preference and legacy-frame backups. No credential/history code was changed by these UI fixes. | The new signed package may still require normal macOS confirmation for the existing Keychain item. Release-package live-data follow-up is not yet verified; no credential-recovery improvement is claimed. |
| Public source, packages and remote state | Standard sanitized public-sync flow, package and remote verification. | Public source 322 tests passed; Windows check/smoke/UI-smoke passed. DMG mounted version/signature/content and Windows ZIP/ASAR checks passed. Both packages generated; remote verification pending. |

Device limits remain: other displays, Spaces, reduced-motion hardware and physical Windows acceptance are not newly claimed. macOS is Apple silicon / macOS 14+ with self-signed preview identity, not Developer ID signed/notarized. Windows keeps its previous interface with version metadata only. No task-stop/resume capability or automatic credit redemption is introduced.

[0.2.1 package evidence](release-evidence.json). The mounted DMG app was installed and opened; its signed executable is byte-identical to the installed copy. Existing Keychain confirmation has been requested; this is not recorded as completed live-data acceptance.

### Final public and live-data follow-up

GitHub v0.2.1 is public, non-draft, non-prerelease and latest. The annotated tag resolves to release code commit `3c0ed0a`; main receives this documentation-only acceptance follow-up. Both uploaded asset sizes and GitHub SHA-256 digests match the local packages. Actual public downloads of the DMG and Windows ZIP match those same hashes.

The user completed the existing macOS Keychain confirmation. The installed final 0.2.1 app is connected and refreshed successfully, showing numeric values for both quota windows, subscription validity, Credits, reset count/expirations and local history. The stable Widget opens pinned details with live values and the last-hour/five-minute/percentage-point chart labels. Escape returns it to the original right rail. About shows the actual 0.2.1 features and release URL. No private values or account details are included in these records.

These follow-up results supersede the pending packaging/remote/live-Keychain statuses above. Remaining limits are the documented device coverage, Windows physical acceptance and self-signed/not-notarized distribution boundary, rather than unfinished package uploads. [Release](https://github.com/whnnick/readycheck/releases/tag/v0.2.1).
