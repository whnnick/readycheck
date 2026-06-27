# Changelog

## Unreleased

- Add a Remotion product intro motion project under `marketing/remotion`, with Chinese and English 30-second ReadyCheck compositions.
- Add a procedural techno/synth background track for the Remotion product intro.
- Rework the product intro with stronger promo-style motion, prominent GitHub address placement, green/orange/red quota states, and a non-overlapping OAuth usage-flow diagram.
- Replace the soundtrack with a more restrained premium-tech bed.
- Add a lightweight animated README preview generated from the product intro.

## 0.1.40 - 2026-06-26

- Start with Show widget enabled on every app launch, even if a previous session hid the widget.
- Remove the native transparent-panel shadow from the desktop widget so it no longer produces a jagged outer outline; retain the rounded SwiftUI shadow.

## 0.1.39 - 2026-06-26

- Default Show widget to on again for this release, including upgrades that previously persisted the old off state; choices made in this version remain persisted.
- Add the first public-source release materials, including a reproducible DMG packaging script, bilingual installation guidance, security policy, and issue forms.

## 0.1.38 - 2026-06-26

- Move Show widget, Keep widget on top, and Reset widget back into the top main-window action area so the lower settings copy is not clipped.
- When Keep widget on top is turned off, lower the widget instead of immediately ordering it front again.

## 0.1.37 - 2026-06-26

- Make Show widget default to on for the updated preference key.
- Keep the widget draggable when Keep widget on top is disabled by using normal window level instead of ignoring mouse events.
- Group Show widget, Keep widget on top, and Reset widget controls together in the main window and menu panel.
- Reopen the widget from Show widget at the same lower-right default position used by Reset widget.

## 0.1.36 - 2026-06-26

- Remove the main window's vertical scrolling surface so the settings view feels like a fixed macOS utility window.
- Increase small explanatory text in the main window and quota metadata to improve readability.
- Align the main window's initial size with the fixed settings layout.
- Keep widget dragging from opening the main window; only an explicit widget click opens the main window.

## 0.1.35 - 2026-06-26

- Change Show widget into a real persisted switch: turning it off closes the widget, and closing the widget syncs the switch off.
- When Keep widget on top is disabled, keep the widget at the desktop layer without intercepting desktop icon clicks.
- Clarify that dragging the widget requires Keep widget on top to be enabled.

## 0.1.34 - 2026-06-26

- Rename the widget action from Pin widget to Show widget so it matches the actual behavior.
- Make Show widget idempotent: repeated clicks bring the existing widget forward and keep it clamped instead of toggling or recreating it.
- Add a Keep widget on top setting: when enabled the widget floats above app windows, and when disabled it stays at the desktop layer.
- Keep Reset widget as the explicit recovery action that opens the widget and returns it to the lower-right visible area.

## 0.1.33 - 2026-06-26

- Keep the Codex account explanation visible after sign-in, with connected-state copy that explains Keychain storage and safe refresh behavior.
- Hide the Connect button after Codex is connected so users are not prompted to reauthorize repeatedly; the account card keeps Disconnect as the connected-state action.

## 0.1.32 - 2026-06-26

- Remember the floating widget position after dragging it, restore it inside the target screen, and add Reset widget actions in the main window and menu-bar popover.
- Mark stale quota snapshots as Stale instead of Available so old data is not mistaken for live quota.
- Show the connected account summary in the menu-bar popover header.

## 0.1.31 - 2026-06-26

- Fix floating widget placement at the bottom-right edge by using a fixed widget size and clamping against the same target screen before and after showing the window.

## 0.1.30 - 2026-06-26

- Restore concise product guidance in the main window while keeping quota status as the primary content.
- Remove duplicate connected-status labels from the account section.
- Recreate the floating widget when pinning it from the main window so a hidden or misplaced widget reopens on the first click.
- Add a Quit ReadyCheck action to the menu-bar popover.

## 0.1.29 - 2026-06-25

- Restructure the main window around quota status first, with account and preferences moved below the quota area.
- Fix floating widget close state so reopening it from the main window works on the first click.

## 0.1.28 - 2026-06-25

- Fix floating widget placement so new and reopened widgets choose the active screen before using the window frame and clamp the final frame inside the visible display area.

## 0.1.27 - 2026-06-25

- Treat the OAuth email as the connected Codex login account and stop showing internal account IDs as a fallback in the main window.

## 0.1.26 - 2026-06-25

- Show the connected Codex account identifier in the main OAuth card after sign-in, using the OAuth token email when available and falling back to account ID only when needed.

## 0.1.25 - 2026-06-25

- Keep the floating widget inside the visible area when opening it on launch or reopening it from the main window.
- Add a standard Close Window command so `Command-W` closes the main window instead of playing the system error sound.

## 0.1.24 - 2026-06-25

- Rewrite the main-window product brief with clearer user-facing copy.
- Make the menu-bar item icon-only and stop activating the main app when opening the menu popover.
- Use the same explicit green/orange/red quota progress bar rendering in the main window and desktop widget.

## 0.1.23 - 2026-06-25

- Add a concise product brief to the main window that explains ReadyCheck's safe quota-monitoring scope, credential storage, and available surfaces.

## 0.1.22 - 2026-06-25

- Change the quota refresh choices to 1, 3, and 5 minutes, with 1 minute as the default because refreshes do not call model inference endpoints.
- Rename the widget/menu status label from auto update to auto refresh.
- Improve Liquid Glass contrast for the floating widget and quota cards on lighter desktop backgrounds.

## 0.1.21 - 2026-06-25

- Add an About window with version, safe-refresh behavior, OAuth usage source, and precision policy.
- Add About entry points from the macOS app menu and the main ReadyCheck window.
- Reposition the floating widget on the primary screen when reopening it, with a higher window level so it is easier to recover.

## 0.1.20 - 2026-06-25

- Make the floating widget a borderless desktop panel with in-widget refresh and hide controls instead of a titlebar close button.
- Place the floating widget near the lower-right visible screen area with margin, keep the main window opaque, show long reset windows with date and time, and run automatic refresh while the main window is visible.

## 0.1.19 - 2026-06-25

- Move the main ReadyCheck window toward the approved Liquid Glass direction with custom glass cards instead of a plain settings form.
- Make the menu-bar item visible as `ReadyCheck` with an icon and show the floating desktop widget on launch.

## 0.1.18 - 2026-06-25

- Show Codex quota cards directly in the main ReadyCheck window after account connection.
- Refresh quota automatically when opening the main window with a connected Codex account, with a manual refresh button beside the quota status.

## 0.1.17 - 2026-06-25

- Add a local OAuth loopback callback listener on `localhost:1455` so Codex authorization can complete automatically after browser sign-in.
- Keep manual callback URL paste as a fallback when the local callback port is unavailable.

## 0.1.16 - 2026-06-24

- Restore the menu-bar ReadyCheck entry while keeping the foreground main window for settings and authorization.
- Route menu-panel Settings and Connect actions to the explicit main window instead of relying on a SwiftUI settings scene.

## 0.1.15 - 2026-06-24

- Create the main window directly from `static main()` after launch completion instead of relying on delegate callbacks.

## 0.1.14 - 2026-06-24

- Temporarily remove status-item setup during launch and prioritize showing the main window after double-click.

## 0.1.13 - 2026-06-24

- Defer main-window creation to the main run loop and force the window to the front.

## 0.1.12 - 2026-06-24

- Explicitly call `finishLaunching()` in the custom AppKit main so the launch delegate creates the main window.

## 0.1.11 - 2026-06-24

- Switched the launch layer to a traditional AppKit lifecycle that explicitly creates the main window and menu-bar status item.

## 0.1.10 - 2026-06-24

- Create the ReadyCheck main window explicitly through AppKit, fixing cases where SwiftUI `WindowGroup` did not reliably show a visible window.

## 0.1.9 - 2026-06-24

- Explicitly switch to a regular foreground app and activate the window on launch, fixing launches that appeared to do nothing.

## 0.1.8 - 2026-06-24

- Open a ReadyCheck main window on launch so the app no longer appears to do nothing as a menu-bar-only utility.
- Stop packaging the local app as background-only, so ReadyCheck appears in the Dock and app switcher.
- Default worktree packaging output to the visible repository `dist/ReadyCheck.app`.

## 0.1.7 - 2026-06-24

- Output the local acceptance build to `dist/ReadyCheck.app` so users do not need to launch from the hidden `.build` directory.
- Generate and declare a ReadyCheck icon for the local app bundle.

## 0.1.6 - 2026-06-24

- Improved the Codex v1 menu empty state so disconnected users see connection guidance instead of an automatic unauthorized error card.
- Improved Codex OAuth settings with a three-step authorization guide covering browser authorization, callback URL paste, and refresh behavior.
- Clarified quota cards by labeling percentages as remaining quota and showing reset time when available.

## 0.1.5 - 2026-06-24

- Focused the MVP on the Codex-only provider flow, enabling only Codex OAuth by default.
- Added a local `.app` packaging script and Codex v1 black-box acceptance documents.
