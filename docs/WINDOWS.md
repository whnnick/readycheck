# ReadyCheck for Windows

[简体中文](WINDOWS.zh-CN.md) · [Windows QA](WINDOWS_QA.md) · [Version channels](../README.md#choose-your-version)

ReadyCheck Windows is a separate **Electron x64 Codex client** with a portable ZIP. It retains its own tray, main window and Widget interface; the macOS DeepSeek balance, capsule and notch features are not ported to this client.

## Current versions

- Latest public preview download: **0.7.0-dev.23**; stable release channel: **0.6.1**. Use the [download table](../README.md#choose-your-version).
- Latest source/locally packaged candidate: **0.7.0-dev.28**, with no public Release installer assets. Dev.24–dev.28 Windows changes are version metadata only.
- Dev.28 package validation passed check/smoke/UI-smoke, ZIP CRC and PE x64 checks; ASAR version and 13 JS source files matched the reviewed tree. This is cross-platform package validation, not Windows hardware acceptance.

## Use the portable package

1. Download a published Windows x64 ZIP and extract it fully.
2. Run `ReadyCheck-win32-x64\ReadyCheck.exe`.
3. Complete Codex OAuth in the browser, then refresh. A missing token/account, failed request or invalid response keeps quota percentages unavailable.

Credentials use Electron safeStorage encrypted persistence. The existing client includes quota refresh, account state, local history, reminders, tray controls and Minimal/Detailed Widget modes. No model-generation request is used to test a connection.

OAuth/usage requests use Electron system networking. A reported OAuth token-request **403 remains unverified on the affected Windows environment**; browser access alone does not establish that the app uses the same network route. See [Windows QA](WINDOWS_QA.md) before treating the issue as fixed.

## Build from source

Use Node.js **22.12–24** (the packaging script currently validates with 24):

```bash
cd apps/windows
npm ci
npm run check
npm run smoke
npm run smoke:ui
npm start
```

From the repository root, package with:

```bash
scripts/package_windows_portable.sh
```

If the system Node is newer, set `READYCHECK_NODE_BIN` to a compatible executable. The script produces `dist/windows/ReadyCheck-<version>-windows-x64-portable.zip`, verifies it, and removes the intermediate application directory. There is no Windows installer in this distribution flow.

Real-device tray, drag/always-on-top, OAuth callback, refresh, notification and encrypted-storage checks remain in the [black-box guide](WINDOWS_QA.md). Current Mac results do not cover these Windows paths.
