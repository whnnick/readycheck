# Windows Black-Box QA Guide

[中文](WINDOWS_QA.zh-CN.md) | English

Use this guide to validate the ReadyCheck Windows preview on Windows 10/11. Do not upload tokens, callback URLs, account ids, or raw usage payloads to GitHub Issues, screenshots, or chat.

## Setup

Option A: use the portable zip.

1. Copy `dist/windows/ReadyCheck-0.1.0-windows-x64-portable.zip` to the Windows machine.
2. Unzip it.
3. Run `ReadyCheck-win32-x64\ReadyCheck.exe`.

Option B: run from source.

1. Install Node.js 22 or later.
2. Check out the repository and enter the Windows subproject:

```powershell
cd apps\windows
npm install
npm run check
npm run smoke
```

3. Start the app:

```powershell
npm start
```

There is no Windows installer yet; both the portable zip and source flow are preview test flows.

## Required Path

1. After launch, confirm the system tray icon, main window, and desktop widget appear.
2. Confirm **Show widget** defaults to on and the widget is fully inside the screen.
3. Select **Connect** and complete Codex OAuth in the browser.
4. After the browser returns to `localhost:1455/auth/callback`, confirm ReadyCheck shows the connected account email.
5. Select **Refresh** and confirm the Codex 5-hour and 7-day quota windows appear.
6. Switch between Minimal and Detailed widget styles and confirm text does not turn vertical, overlap, or overflow.
7. Disable **Keep widget on top** and confirm normal windows can cover the widget while the widget remains draggable.
8. Hide the widget and show it once; confirm the placement matches **Reset position**.
9. Quit and relaunch the app; confirm the connected account state is restored.

## Failure Paths

1. Refresh before OAuth: the app should show disconnected or unavailable, not guessed quota.
2. Refresh while offline: the app should show unavailable or keep a safe state, not generate new guessed percentages.
3. If quota does not appear after refresh, record UI screenshots, time, network state, and whether OAuth had just completed; do not record tokens or raw payloads.
4. If the widget appears outside the screen, record display resolution, scale, monitor layout, and exact steps.

## Pass Criteria

- `npm run check` passes.
- `npm run smoke` passes.
- OAuth completes and restores the login email.
- Refresh shows only parsed 5-hour / 7-day quota; parser failure fails closed.
- The widget does not interfere with desktop operation and its default placement is stable.
