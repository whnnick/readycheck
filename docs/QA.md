# Real-World QA Checklist

[中文](QA.zh-CN.md) | English

Use this checklist before publishing a preview build or when validating a user-reported regression. Do not paste tokens, callback URLs, account IDs, or raw usage payloads into public issues.

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
2. Confirm the main window shows the Codex 5-hour and 7-day quota windows only when both windows are parseable.
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

## Windows Preview Black-Box QA

1. Run the `apps/windows` preview on Windows 10/11 and confirm the system tray icon, tray menu, main window, and desktop widget appear.
2. Select **Connect**, complete Codex OAuth in the browser, and confirm the app receives the `localhost:1455/auth/callback` callback automatically.
3. After authorization, confirm the account section shows the login email and refresh shows the Codex 5-hour and 7-day quota windows.
4. Compare percentages and reset times with the visible Codex / ChatGPT usage source available to the tester. If they are clearly inconsistent, capture screenshots and timestamps, but do not publish tokens, account ids, or raw usage payloads.
5. Disconnect the network and refresh. Confirm the Windows app does not show guessed quota; missing token, missing account id, request failure, or parser failure must show unavailable data.
6. On first launch, after hiding and showing the widget, and after **Reset position**, the widget should return to the same lower-right default placement and stay fully inside the screen.
7. With **Keep widget on top** disabled, normal app windows should cover the widget and the widget should remain draggable.
8. Switch between Minimal and Detailed widget styles and confirm labels do not turn vertical, overlap, or overflow.
9. Quit and relaunch the app. Confirm authorization state is restored and the token file is not readable plaintext JSON.

## Release Gate

- `swift test` must pass.
- Windows subproject `cd apps/windows && npm run check` must pass.
- `scripts/package_dmg.sh` must produce the current version DMG.
- `hdiutil imageinfo dist/ReadyCheck-<version>-macos.dmg` must read the DMG successfully.
- README, changelogs, and release notes must mention the same version.
