# Real-World QA Checklist

[中文](QA.zh-CN.md) | English

Use this checklist before publishing a preview build or when validating a user-reported regression. Do not paste tokens, callback URLs, account IDs, or raw usage payloads into public issues.

## 0.1.91 Quota recovery reminders

Product requirement: opt in after quota exhaustion, then receive one notification when fresh verified data confirms recovery. Entry points and usage are in the [README](../README.md#quota-recovery-reminders-macos-0191).

| Requirement | Status | Evidence / acceptance |
| --- | --- | --- |
| Main-window and menu-bar opt-in; cancellation | Implemented | Shared SwiftUI control; shown only for verified zero quota, with pending state and notification-settings recovery |
| Confirm actual recovery | Automated | Every originally tracked window must remain present; all current windows must have verified remaining quota and no reported limit state; reject stale, missing, estimated, failed, older or same-time snapshots |
| Persist and deliver once | Automated | Reopen store, retry failures under one request ID, commit success, preserve cancellation/new request during in-flight commit |
| Account isolation and write failures | Implemented / automated core | Match account ID, clear on account change/disconnect, report write failure; live account-switch acceptance remains pending |
| Bilingual UI | Implemented | Chinese and English labels, pending explanation, cancellation, notification history |
| Windows recovery reminder | Not implemented | Shared version number only |

Validation: 174 Swift tests passed, including six recovery tests. Full OAuth loopback tests require localhost permission outside the restricted sandbox. Version-reference and whitespace checks passed.

Local package: the standard DMG script succeeded using the stable preview signing identity. Synthetic-data UI acceptance used the actual quota card and recovery control with a test model: both languages showed the enable/wait/cancel states correctly at menu-bar width. This did not access a live account or send system notifications.

Installed-package verification on 2026-09-11: after Retry reading restored the existing Keychain credential, a full quit/relaunch automatically restored the account, live quota and official Token history without another retry.

Real-environment acceptance before release:

1. With an actually exhausted account, enable the reminder from each entry point; cancel, rearm and restart the final installed app.
2. Verify no reminder while only one of several windows recovers, or while offline/asleep. After resume, refresh must confirm recovery before sending.
3. On actual recovery, inspect notification-center delivery and history, confirm no repeat on later refresh/relaunch, and visually check foreground/background banners under the user's notification settings.
4. Switch accounts or disconnect with a pending request; verify it cannot notify for another account.
5. Repeat with notifications denied, then enabled. Confirm the settings action and retry behavior.

Preview limitation: final installed-package end-to-end quota recovery and system notification acceptance remain pending; local tests and synthetic UI checks do not establish real delivery. This limitation is disclosed for the 0.1.91 preview release. The installed 0.1.91 app launches; upgrading can require a Keychain access confirmation via Retry reading.

## 0.1.90 Notification Visibility

- Follow-up repair: background reads now return an authentication error instead of waiting indefinitely; history loads and an explicit read-retry button is available. 168 tests passed.
- The final repaired build recovered account/quota after explicit retry. On 2026-09-07, quitting and relaunching that same installation restored account, quota, and official Token history without another retry. The local startup blocker is resolved; first access after an upgrade may still require system Keychain confirmation. Silent upgrades on all machines are not guaranteed.

- Historical issue: the original build stalled in Keychain SecItemCopyMatching and was rolled back to 0.1.89. The repair above passed local recovery and relaunch acceptance. Public delivery still requires the standard Release workflow.
- 166 Swift tests and Windows check/smoke/UI smoke passed. Native status copy and the test notification's Notification Center record were verified; persistent banners still await user-approved configuration and visual verification.

- Native inspection found temporary alerts and notification suppression during screen sharing. These can explain missed alerts, but do not prove suppression of a particular past notification.
- Automated coverage includes persistent, temporary, no style, disabled alerts, provisional authorization, and denied authorization.
- Native acceptance: with user approval select persistent alerts and visually verify a test remains visible; check foreground, background, and Focus without changing global privacy settings.
- Keep one alert per Credits consumption episode; do not repeatedly resend delivered notifications merely because visibility is unknown.

## 0.1.89 Notch Quota Selection

- Verified: 164 Swift tests passed, covering the seven-day default, persistence, and exact window matching. Windows check, smoke, and UI smoke passed before packaging.
- Native check: both options fit beside the notch toggle; selecting five-hour updates the control. Installed version is 0.1.89.
- Remaining acceptance: compare the notch value with the selected window, switch back to seven-day, verify persistence after relaunch, missing-window behavior, and English layout.
- Windows only receives the synchronized version, not notch support. No quota fetching, polling, or notification behavior is changed.

## 0.1.88 Historical Notification Regression

- Legacy records show "Past delivery unverified" with an explanation of missing evidence, not delivery success or a reset-credit reading failure.
- Current reset expirations and past reminders remain distinct; old notifications do not determine currently available credits.
- Verify wrapping and status visibility in both languages, in the summary and full history.
- Automated coverage: localization completeness, legacy history migration, and Windows UI smoke. Native Windows visual acceptance still requires a Windows machine.

## macOS Installation And Update

1. Install the latest DMG on a Mac that does not already have ReadyCheck running.
2. Confirm the app icon appears in Finder, Dock, and the menu bar.
3. Launch an older build and run **Check for updates**. Confirm GitHub latest release is detected and the download action opens the release page.
4. Disconnect the network and run **Check for updates**. Confirm the app shows a failure message instead of blocking the UI.

## macOS Codex OAuth

1. Select **Connect** and complete the browser OAuth flow.
2. Confirm ReadyCheck receives the `localhost:1455` callback automatically.
3. If the callback is not received, paste the final callback URL into the manual field and complete authorization.
4. Confirm the connected account shows the login email, not an internal account ID.
5. Disconnect the account and confirm the UI returns to the disconnected state.

## Safe Refresh And Accuracy

1. Run a manual refresh and confirm no model inference endpoint is called.
2. Confirm the main window shows every quota window currently returned and validated by Codex; no fixed 5-hour/7-day pair is assumed.
3. Compare the displayed values with the visible Codex or ChatGPT usage source available to the tester.
4. If the upstream response shape changes, ReadyCheck must show unavailable or hide percentages until parser tests are updated.
5. With an expired token, confirm refresh succeeds after token refresh or fails closed without guessed percentages.

## Widget Behavior

1. On first launch, confirm **Show widget** is enabled and the widget is fully inside the visible screen.
2. Hide the widget, then enable **Show widget** once. Confirm it reappears at the same default lower-right placement used by **Reset position**.
3. Toggle **Keep widget on top** off. Confirm normal app windows can cover the widget and the widget remains draggable.
4. Drag the widget. Confirm dragging does not open the main window.
5. Click the widget content. Confirm the main window opens.
6. Switch between Minimal and Detailed widget styles and confirm labels do not wrap into vertical text.

## Low Quota And Failure States

1. Test or simulate a quota window below 25% remaining. Confirm the warning and red progress bar are visible.
2. Disconnect the network and refresh. Confirm the app does not convert stale or failed data into a guessed percentage.
3. Confirm stale quota snapshots are marked stale or unavailable instead of being shown as current.
4. With a valid login and a temporary network or server failure, confirm **Try again** appears and can recover without signing in again.
5. Simulate a rejected or unrefreshable authorization and confirm **Sign in again** appears; cancelling or failing replacement authorization must not delete a previously valid token.

## Local Quota Consumption

1. When official app-server Token usage is available for the same account, confirm the dashboard switches to actual 7/30/90-day Token totals and labels the source as official.
2. Without official Token history, complete at least two successful refreshes more than one minute apart and confirm the local dashboard shows the available quota windows.
3. Confirm local bars represent detected quota decreases in percentage points, while current remaining quota is shown separately.
4. Confirm a reset or recovery does not create negative consumption, and a long refresh gap is not attributed to a bar.
5. Confirm range switching does not affect the floating widget or trigger a network request.
6. Inspect the local history payload and confirm it contains no email, account id, credential, or raw API response.

## Quota And Credit Notifications

1. With a manual reset expiration inside the next 72 hours, confirm ReadyCheck requests notification permission when needed and sends one expiration reminder.
2. When reset-credit details are unavailable or rate limited, confirm ReadyCheck reports them as temporarily unavailable instead of zero and preserves any previously verified, unexpired expiration. Confirm an explicit `availableCount: 0` clears the previous result.
3. Refresh again and relaunch the app. Confirm the same expiration does not notify again.
4. With verified quota exhausted, confirm an unchanged Credits balance does not notify; decrease the balance and confirm one Credits-usage reminder appears.
5. Confirm later balance decreases in the same exhausted quota cycle do not repeat the reminder.
6. Restore quota, or advance the verified quota reset cycle, then exhaust it and decrease Credits again. Confirm the next cycle can notify once.
7. Deny system notification permission and confirm quota refresh remains usable without errors or model requests.

## Windows Preview Black-Box QA

1. Run the `apps/windows` preview on Windows 10/11 and confirm the system tray icon, tray menu, main window, and desktop widget appear.
2. Select **Connect**, complete Codex OAuth in the browser, and confirm the app receives the `localhost:1455/auth/callback` callback automatically.
3. After authorization, confirm the account section shows the login email and refresh shows the validated Codex quota windows.
4. If Codex is installed and logged in to the same email, confirm the official Token dashboard appears; with another account or no Codex executable, confirm the read-only OAuth fallback still refreshes quota.
5. Compare percentages and reset times with the visible Codex / ChatGPT usage source available to the tester. If they are clearly inconsistent, capture screenshots and timestamps, but do not publish tokens, account ids, or raw usage payloads.
6. Disconnect the network and refresh. Confirm the Windows app does not show guessed quota; missing token, missing account id, request failure, or parser failure must show unavailable data.
7. On first launch, after hiding and showing the widget, and after **Reset position**, the widget should return to the same lower-right default placement and stay fully inside the screen.
8. With **Keep widget on top** disabled, normal app windows should cover the widget and the widget should remain draggable.
9. Switch between Minimal and Detailed widget styles and confirm labels do not turn vertical, overlap, or overflow.
10. Quit and relaunch the app. Confirm authorization state is restored and the token file is not readable plaintext JSON.
11. Repeat the notification cases above and confirm Windows system notifications follow the same one-per-expiration and one-per-exhausted-cycle rules.

## Release Gate

- `swift test` must pass.
- Windows subproject `cd apps/windows && npm run check` must pass.
- `scripts/package_dmg.sh` must produce the current version DMG.
- `hdiutil imageinfo dist/ReadyCheck-<version>-macos.dmg` must read the DMG successfully.
- README, changelogs, and release notes must mention the same version.
