# ReadyCheck Windows Preview

This directory starts the Windows desktop client. It is intentionally separate from the macOS SwiftUI app so Windows shell behavior, tray controls, and widget placement can evolve without destabilizing the current macOS release line.

## Scope

Current preview:

- Electron main process with a Windows tray entry.
- Main window with quota, account, widget, refresh, and update sections.
- Floating desktop widget with Minimal and Detailed modes.
- Local preferences for language, refresh interval, widget visibility, always-on-top, and widget style.
- Safe-refresh endpoint allow-list matching the macOS safety boundary.
- Codex OAuth loopback callback flow.
- Encrypted token storage through Electron `safeStorage`.
- Read-only Codex usage fetch and parser for 5-hour / 7-day quota windows.

Not included yet:

- Windows installer, signing, and auto-update.

Quota refresh uses the same safety boundary as the macOS app: it reads the Codex usage endpoint and never calls model inference endpoints. Missing token, missing account id, request failure, or parser failure keeps quota values unavailable instead of guessing.

## Development

Requirements:

- Windows 10/11 for runtime validation.
- Node.js 22 or later.

```bash
cd apps/windows
npm install
npm run check
npm run smoke
npm start
```

`npm run check` uses `node --check` on the local JavaScript sources and parser tests. `npm run smoke` confirms the expected Electron entry files, OAuth callback configuration, and safe-refresh boundaries are present. Runtime validation for tray behavior, OAuth browser callback, and widget placement must be done on Windows.

Use the [Windows black-box QA guide](../../docs/WINDOWS_QA.md) for the first real-machine validation pass.

## Portable Package

From the repository root:

```bash
scripts/package_windows_portable.sh
```

The script writes `dist/windows/ReadyCheck-0.1.0-windows-x64-portable.zip`. Unzip it on Windows and run `ReadyCheck-win32-x64/ReadyCheck.exe`.

This is a portable preview package, not an installer. It is intended for black-box testing before the signed Windows installer work starts.

## Next Implementation Steps

1. Add a Windows QA checklist covering tray, widget drag, startup, OAuth, quota refresh, and update behavior.
2. Validate OAuth callback, token encryption, quota refresh, widget placement, and tray behavior on a real Windows machine.
3. Add Windows packaging with a signed installer.
4. Decide whether Electron `safeStorage` is sufficient or replace it with a Windows Credential Manager adapter.
