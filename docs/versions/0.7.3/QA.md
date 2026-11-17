# ReadyCheck 0.7.3 verification

[简体中文](QA.zh-CN.md) · [Changelog](../../../CHANGELOG.md)

## 0.7.3 stable

- The stable build promotes the same startup fix validated in dev.1. The macOS change covers app launch, the service switcher icons and the Muse reader. Saved connections and preferences retain their original formats. Windows application logic is unchanged from 0.7.2.

- The public-source macOS suite ran 557 cases, including 3 opt-in native evidence skips, with zero failures. All 14 Muse-script checks passed.
- The signed DMG passed disk image integrity, strict code signature, version, private-path and resource comparisons against source. After relocating its build directory, the installed 0.7.3 opened twice from Applications and read Muse quota both times. No new stable-build crash report appeared.
- After Keychain confirmation, the installed app displayed live Codex 5-hour and 7-day quota and the DeepSeek balance. Both manual refreshes succeeded. The Muse last-read time advanced on a scheduled refresh without a click or another sign-in. The capsule showed all three services in the expected order and its saved frame matched the previous build.
- The local Windows package passed Node 24 service and UI checks, ZIP CRC, version and all 16 packaged web source comparisons. The GitHub release workflow additionally runs the Electron network/proxy smoke checks on Windows before uploading its package. Retesting on the original device with OAuth 403 remains pending.

## 0.7.3-dev.1 macOS startup fix

- On macOS 27.2.1, the installed 0.7.2 repeatedly stopped at SwiftPM’s generated resource bundle accessor when rendering a service icon. The packaged resources were present under `Contents/Resources`. The generated accessor checked the app root and the now-missing packaging build directory.
- The installed app resolves its bundled icons and Muse script within `Contents/Resources`. Missing resources return an optional value so the caller can handle their absence.
- Twelve targeted Swift cases passed, including installed bundle layout, missing resources, icon loading and Muse integration. Fourteen JavaScript reader tests passed.
- The signed DMG passed integrity, embedded script, version and private-path checks. After moving the packaging build directory, the installed app started twice and Muse showed its live quota on both launches. No dev.1 crash report was recorded, and the capsule retained its right edge and vertical center.
- After macOS Keychain confirmation, the installed app showed live Codex 5-hour and 7-day quota and the live DeepSeek balance with gift and top-up amounts. Both manual refreshes succeeded. Muse continued to show its weekly quota. No new crash reports appeared through these checks.
