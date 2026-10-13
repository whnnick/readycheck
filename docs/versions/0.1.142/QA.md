# 0.1.142 black-box acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Version index](../../VERSIONS.md)

Status: local 0.1.142 installed and dragging repair verified on October 13, 2026.

| Requirement | Status and evidence |
| --- | --- |
| Direct inward dragging after expansion | Original regression failed on both edges. Fixed regression passes for left/right in both pinned and preview states. The installed pinned dial also collapses and moves directly to a free bubble. |
| Mouse-down capture and horizontal tracking | Native-event tests cover both directions, the four-point threshold, tracking outside the 28-point rail and screen-pointer continuity as the window moves. On the installed app, the first horizontal inward drag after docking succeeds on either edge, without vertical movement first. |
| Clicks and detail controls | Native tests cover small-movement clicks, repeated clicks and excluding detail controls from capture. Existing nine hover/pin/collapse tests pass. Installed rail clicking and pin states were checked; preview dragging is covered by automated regression. |
| Build and installation | Standard package_app script with stable ReadyCheck Preview Signing identity. Staged and installed bundles pass strict signing verification, report 0.1.142 and have matching executable SHA-256. Previous app backed up. |

Validation: final full 273 Swift tests pass with no failures/skips; version consistency, document links, diff whitespace and sensitive-information checks pass. Commands: `swift test --build-system native --scratch-path <temporary directory>`, `scripts/check_release_consistency.sh`, `scripts/package_app.sh`, `codesign --verify --deep --strict`. One existing 100 ms hover-wait assertion failed during a supplementary run; the subsequent complete run passed. Unrelated timer logic was not changed.

Completed: macOS mouse capture, direct inward dragging on both edges, expanded dragging, click distinction, version metadata, bilingual documentation, local installation and dragging acceptance. The user completed system Keychain authentication; manual refresh at 09:44 China Standard Time on October 13, 2026 confirmed fresh verified OAuth quota, an available main-window status and live edge-rail progress. Credentials were retained without signing in again. Partial items related to this drag repair: none. Real-environment checks remaining: other/multiple displays and macOS 14 devices.

Not included: public release, additional Windows real-device acceptance or campaign voice replacement. Windows version metadata only. Public-release blockers if separately requested: standard dual-platform packages, account/target-device acceptance and remote verification. Published version remains 0.1.141.
