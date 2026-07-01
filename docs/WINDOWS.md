# Windows Development Plan

[中文](WINDOWS.zh-CN.md) | English

ReadyCheck Windows starts as an Electron desktop client under `apps/windows`.
The macOS app remains the production preview; Windows is a new platform track.

## MVP Boundary

- Tray-first desktop app.
- Main window for account, quota, refresh, widget, and update controls.
- Floating desktop widget with Minimal and Detailed modes.
- Safe refresh only: never call model inference endpoints.
- Chinese and English preference plumbing.

## First Build State

The Windows code now includes the desktop shell, UI state flow, Codex OAuth callback handling, encrypted token storage, read-only usage fetching, and Codex quota parsing. Refresh remains fail-closed: missing token, missing account id, request failure, or parser failure must suppress percentages instead of showing guessed quota.

## Technical Direction

- Runtime: Electron.
- UI: local HTML/CSS/JavaScript.
- Secret storage: Electron `safeStorage` encrypted persistence, which uses system encryption on Windows; this can later be replaced with a lower-level Windows Credential Manager adapter.
- Update source: GitHub Releases, matching the macOS preview.
- Packaging target: signed Windows installer after Windows black-box validation passes.

## Validation

Non-Windows validation:

```bash
cd apps/windows
npm run check
npm run smoke
```

Build the Windows portable preview package:

```bash
scripts/package_windows_portable.sh
```

Output: `dist/windows/ReadyCheck-0.1.0-windows-x64-portable.zip`.

Windows validation still required:

- Tray icon appears and menu actions work.
- Main window opens from tray and widget click.
- Widget stays inside the work area and can be dragged.
- Always-on-top toggle changes window level.
- Refresh fails closed before OAuth is connected.
- Codex OAuth completion updates the account state to connected.
- After authorization, refresh shows the 5-hour and 7-day quota windows with the same low-quota colors as macOS.
- The token file must not be stored as plaintext JSON.
