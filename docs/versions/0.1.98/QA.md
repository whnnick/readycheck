# 0.1.98 black-box acceptance

[中文](QA.zh-CN.md) | [Product plan](PLAN.md) | [Version index](../../VERSIONS.md)

Released on 2026-09-22. Automated regression is complete. Real persistent-alert lifecycle, login-item, and cross-version device checks remain documented acceptance limitations.

| Requirement | Status | Required evidence |
| --- | --- | --- |
| A Recovery/diagnostics | Automated; partial on-device | Initialization rejection, silent timeout and second-candidate fallback pass. The installed app recovered from disconnected/stopped to connected, displayed official quota and “Quota events: connected.” Client exit/network recovery remains pending |
| B Persistent alert lifecycle | Pending | Controlled real-system recovery/consumption recording or timeline; natural cycle separately |
| B Focus/lock/wake | Pending | Observations per scenario; Center records do not prove banners |
| C Protocol compatibility | Complete | Schema generated from Codex CLI 0.155.0-alpha.9.2 bundled with ChatGPT; existing multiple-bucket, dynamic-window, and unknown/zero reset-credit regressions pass |
| P1 Login items | Pending | Registration readback, logout/login, disable and upgrade |
| Installation | macOS 27 complete | Installed 0.1.98; About and Info report 0.1.98. Installed and DMG binaries share SHA-256 `c4d32176a50cc8927457ff42d49f2aa8f689202761f4193ed9714ba1c777c447`. macOS 14 hardware remains pending |
| Regression/release | Released | 190 Core + 2 App tests pass including localhost OAuth; Windows check/smoke/UI smoke, version consistency and DMG build pass. GitHub release `v0.1.98` includes macOS DMG, Windows portable ZIP and SHA-256 checksums |

The release checksum file records the final DMG and Windows ZIP SHA-256 values. The DMG uses `ReadyCheck Preview Signing` with no Team ID; this is not a Developer ID notarization claim.

Acceptance limitations: the real persistent-alert lifecycle has not yet been observed end to end, macOS 14 hardware was unavailable, and the macOS package uses preview signing rather than Developer ID notarization. Launch at Login still reports unavailable and remains experimental.
