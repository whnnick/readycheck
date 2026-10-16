# ReadyCheck 0.2.0 — quota at a glance

[中文](RELEASE_NOTES.zh-CN.md) · [Acceptance](QA.md) · [Version index](../../VERSIONS.md)

2026-10-16

- Update the Windows runtime to Electron 43.5.0 and packager to 20.3.0, validating the Node.js 22.12–24 requirement; retain the existing interface.
- Reorganize the native Mac app into Overview, Token usage and Settings, with a compact menu-bar panel and persistent About entry in the sidebar and More menu. About and the product explanation now highlight this release.
- Retain Widget's last-hour consumption chart, persistent pin and slim vertical edge tab. Preserve explicit show/hide across relaunches. Join the built-in notch and open its details only on click.
- Align Widget and Overview on account-scoped local quota decreases in percentage points; explain history ranges and bar intervals. Inspect Overview bars by hover or click. Keep official daily Token counts separate, with an honest unavailable state.
- Preserve subscription validity, Credits, reset count and every returned expiration. Keep missing quota selections unknown, separate account history, retain legacy backups and handle same-account refresh failures without inventing fresh data.
- Add 5% low-quota reminders, localized native menus and fullscreen shortcuts. This monitor does not stop or resume Codex tasks.
- macOS arm64 self-signed preview; not Developer ID signed/notarized. Windows x64 portable preview retains its previous interface; the native redesign is Mac-only. See versioned QA for remaining device/lifecycle coverage.

This release updates the macOS preview. It retains the existing Windows portable interface. The Mac DMG is Apple silicon / macOS 14+, self-signed with the existing preview identity, not Developer ID signed or notarized. Device coverage limits remain in the linked QA; synthetic screenshots are illustrations, not live-account evidence. About is available in the sidebar footer, menu bar More menu, app menu and Settings → General. Widget/Overview show local quota consumption in percentage points; Daily Token counts are separate, UTC-based official statistics with no fixed conversion.
