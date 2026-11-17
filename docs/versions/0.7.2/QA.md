# ReadyCheck 0.7.2 verification

[简体中文](QA.zh-CN.md) · [Changelog](../../../CHANGELOG.md)

## 0.7.2 stable

- This release retains Quick display, the shared service order, the menu-bar icon and one-minute polling. Credentials, local history, reminders and card-redemption consent keep their existing data formats. [Feature retention](../0.7.0/RELEASE_AUDIT.md)
- The floating card has a larger title drag area. Notch tests cover opening details when a service is available and opening Display settings when there are no services. The pace fixture uses a signed-in account that matches its snapshots. Compact readout tests exercise the actual Quick display filtering.
- 20 targeted Swift tests passed, covering the four previously failing cases. The Mac distribution retains the ReadyCheck self-signed identity. The original Windows 403 device is outside the fixes in this version and still awaits a retest.

- The public-source macOS suite ran 555 cases with no failures and 3 opt-in native evidence skips. The mounted DMG passed its disk image checksum, strict signature, version, bundled Muse reader and private-path checks. The installed app was launched from Applications and its saved capsule frame matched the previous version.
- The installed Connection and Quick display lists match the overview order of Codex, Muse and DeepSeek. The three selections remained checked and General displays the fixed one-minute cadence. Muse loaded its existing session and showed a live reading.
- The local Windows ZIP passed CRC, version and comparison of all 16 packaged web source files. The separate GitHub workflow runs Electron UI and proxy/network smoke checks on Windows before uploading the release ZIP.

## 0.7.2-dev.12 shared service order

- Connection, Reminders, Quick display, overview, usage, the catalog, the menu popover and the aggregate capsule use Codex, Muse, then DeepSeek. Filters preserve that order. Connection methods stay paired with their service, and saved service IDs are unchanged.
- 30 targeted Swift tests passed, and the two catalog tests passed again on the final source. The signed build was installed and opened. The installed checks covered overview, usage, Connection, Reminders, Quick display, the catalog, and right-arrow navigation from Codex to Muse. After Keychain confirmation, the aggregate capsule showed all three live readings in the same order and the original three options remained checked. The popover was covered by synthetic tests, with a physical menu-bar click still pending.

### Public preview package checks

- The public-source Swift run executed 554 cases, including 3 opt-in skips. Four cases failed, all of which also failed in the preceding preview run. The 30 targeted tests for the shared service order and affected surfaces passed.
- The mounted Mac DMG passed version, strict preview signature, bundled Muse reader and private-path checks. The Windows package passed CRC, version and comparison of its 16 packaged web source files. Node 24 checks and UI smoke passed.

## 0.7.2-dev.11 one-minute refresh

- **A07 and A08.** The requested change replaces the 1/3/5-minute selector with a fixed one-minute cadence and an explanation. Previous interval preferences are ignored. Manual, wake and quota-event refresh continue to use their existing routes. Roll back to the preceding release to restore the selector. Stored account credentials and history formats are unchanged.
- Codex runs its automatic timer independently of visible windows. Codex, DeepSeek and Muse use the same macOS refresh policy. Future provider integrations should use that policy for ordinary polling. DeepSeek five-minute chart buckets represent aggregation only.
- Windows keeps its Codex-only preview scope and uses the same one-minute cadence, including when a saved preference contains an older interval.
- Development verification ran 36 focused Swift tests with 1 opt-in skip and no failures. Windows check, smoke, and UI smoke passed with Node 24. Live provider cadence, menu-bar clicks and the original Windows OAuth 403 device remain pending.
- The published DMG was installed and launched. General settings show the fixed one-minute explanation, and the Muse detail page displays the same cadence and a live reading. After Keychain confirmation, Codex showed a signed-in state and DeepSeek showed its live balance. A full background cadence measurement remains pending.

### Public preview package checks

- The public-source Swift suite ran 554 cases with 4 opt-in skips. Of the 17 cases that failed in the locked-session run, 16 also failed on the preceding build. The remaining settings-scroll case passed in isolation on both builds. The isolated run also passed the one-minute refresh and scheduler tests. A full unlocked-session pass remains pending.
- The mounted DMG passed version, strict preview-signature, bundled Muse reader and private-path checks. The Windows ZIP passed CRC and version checks. Its 16 packaged JavaScript, HTML and CSS files matched the reviewed source. Node 24 checks and both smoke suites passed.
- The release provides SHA-256 checksums with the Mac and Windows packages.

## 0.7.2-dev.10 icon-only menu bar

- The macOS status item uses a square width and shows only the ReadyCheck icon. Its popover still uses Quick display selections.
- 7 targeted Swift tests passed for Quick display, the main menu, and version metadata. The local candidate passed strict signature verification. Installed menu-bar interaction is pending.

## 0.7.2-dev.9 compact menu bar

- The title shows current readings for services selected in Quick display. It retains the Codex quota window and DeepSeek currency. The tooltip identifies each service and labels Muse’s weekly window. An empty selection or no current readings leaves just the ReadyCheck icon.
- Four targeted Swift tests passed, covering compact labels, stale readings, hidden and disconnected services, saved selection, and the version. The signed local candidate was built. Installed menu-bar interaction remains pending.

## 0.7.2-dev.8 quick display

- In **Settings → Display → Quick display**, choose Codex, Muse, and DeepSeek independently. The capsule and menu bar show the connected choices in that order. Single-service widgets use the active service when visible and otherwise show the first visible choice. If the list is empty, the settings entry stays available.
- 56 targeted Swift tests passed. The checks cover initial defaults, saved choices including an empty selection, rejected credentials and recovery, menu-bar labels, the capsule's height and docked position, and closing pinned details when their service is hidden. Filtered and empty capsule and menu states and the Display settings section were rendered in both languages with synthetic data.
- The signed build is installed. Codex, Muse, and DeepSeek showed live readings after the macOS Keychain confirmations. While Codex access was pending, Display settings marked it disconnected. On the installed capsule, turning off DeepSeek immediately left Codex and Muse, and turning off all three left a working shortcut to Display settings. All three selections and live readings were restored after the check. The docked side and vertical center matched across the smaller and full sizes.
- After unlocking the Mac, 26 additional native-window tests passed for placement, transitions, and pinning. Menu-bar filtering was checked with synthetic readings and rendered menus. Installed status-item clicks were outside this acceptance pass.

## 0.7.2-dev.7 hover transitions

- An open preview now keeps the same mounted side window when hover changes the service. New content fades in with a small upward movement, and the old content fades out. Reduce Motion suppresses the transition. A pinned detail changes services on click.
- All 25 targeted Swift tests passed, covering quick hover switches on the same mounted window and preservation of its position and pin behavior. On the installed Mac the user confirmed the transition while moving the mouse directly from Codex to Muse.
- After Keychain confirmation, the installed capsule displayed all three live readings and its saved frame matched the prior build.
- Follow-up on November 17: the rail later showed that Keychain access was required for DeepSeek. After the user chose Always Allow for the existing ReadyCheck item, both a normal manual refresh and the next five-minute background refresh advanced the balance timestamp. The rail continued to show the live balance.

## 0.7.2-dev.6 row spacing

- The three service rows have 4 pt gaps. The rail now measures 48 × 204 pt. Light and dark renders show all rows and controls. The 15 targeted Swift tests passed, including docking and vertical-center preservation.
- The installed build showed all three live values after Keychain confirmation. The native capsule captured at 96 × 408 pixels on the 2× display, with all rows and the menu visible.

## 0.7.2-dev.5 icon scale and service order

- Service artwork is 20 pt in a 28 pt badge. The 48 × 196 pt capsule keeps 16 pt readings and both Codex rings. Light and dark synthetic renders were inspected. All 15 targeted Swift tests passed.
- The signed build was installed locally. The capsule showed Codex, Muse and DeepSeek in that order, and the saved frame matched the prior build. After Keychain confirmation, the capsule displayed live Codex quota, Muse weekly allowance and DeepSeek balance.

## 0.7.2-dev.4 larger icons and detail switching

- Service icon artwork grew from 13 to 18 pt, with 26 pt badges alongside the existing 16 pt readings. Light and dark synthetic renders were inspected. Codex retains both rings.
- Service changes use a short crossfade within the side detail. Window placement and explicit pin are retained. Reduce Motion suppresses the transition.
- All 15 targeted Swift checks passed. The installed Mac displayed the three live readings after Keychain confirmation. Switching from pinned Codex to DeepSeek kept the detail open, and Escape returned to the capsule. The saved frame matched the previous version.

## 0.7.2-dev.3 larger readouts and dual rings

- Selected design C keeps the 48 × 196 pt aggregate rail and increases its main readouts from 12 to 16 pt. The 5h number has the primary position when both Codex windows exist. The inner ring conveys the 7d allowance, with the precise number and reset time in the detail panel. Weekly-only accounts retain their weekly readout.
- Native tests verified entry offset and transparency, settling, rapid reopen, and pointer pass-through during dismissal. The 53 targeted Swift tests passed and the added entry assertions passed on rerun. Synthetic light and dark renders were inspected. The system Reduce Motion preference suppresses movement.
- After Keychain confirmation, the installed Mac displayed all three live readings. The Codex rail showed one percentage with a weekly inner ring, and the side detail showed both periods and could be pinned and dismissed. The saved rail frame was unchanged. Pure hover motion was covered by the implementation and was not separately accepted by a user on the installed build.

## 0.7.2-dev.2 compact capsule

- The aggregate capsule now stays visible at its 48 × 196 pt size. Small service badges and aligned readings keep Codex 5h and 7d, DeepSeek balance and currency, and Muse weekly quota visible together. The shell follows the system appearance.
- On the installed Mac, all three readings displayed together after Keychain confirmation. Muse's detail opened, pinned and unpinned. The capsule menu opened the main window. A drag away from the right edge and back left the capsule visible and preserved the original right boundary and vertical center.
- All 53 targeted Swift tests passed. Native synthetic renders were inspected in light and dark mode. The window tests cover both edges, detail behavior and dragging. Cross-display movement was outside the installed check.

## 0.7.2-dev.1

- Requirement — the macOS aggregate capsule should give back screen space when docked. After the rail snaps to either side, it shows a 22 × 76 pt tab. Hover or click reveals it inward. Moving away retracts it unless a detail is pinned. Dragging a tab moves it immediately and restores the full capsule on an interior drop.
- Installed Mac — verified both edges retract, a click opens the right tab, and the rail returns to a tab after dismissal. A direct horizontal drag from each tab restored the capsule and all three rows without changing its height on screen. The tab context menu opened the main window. After Keychain confirmation, Codex, DeepSeek and Muse resumed live readings. The original right-docked frame was restored exactly.
- Regression — all 54 targeted Swift tests passed after updating one existing hover test to wait for the observed state transition. Native-window tests cover timed hover, pointer exit, pinning, dragging, and placement persistence.
- Scope — the live test used the main display. Pure pointer-only hover and moving the capsule across displays were not exercised on the installation. The build is a local development version.
