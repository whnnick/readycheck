# 0.1.134 acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Versions](../../VERSIONS.md)

Status: implemented and installed as a local preview on October 9; not publicly released.

| Requirement | Status / evidence |
| --- | --- |
| Reset countdown | Implemented; focused tests pass for missing/stale/estimated/mock data, minute/day boundaries and elapsed deadlines waiting for a refresh. |
| Unified interaction | Implemented; focused tests pass for brief hover, preview exit, click pinning, explicit dismissal, dragging and timer cancellation. |
| Real interface | Passed observed checks: real OAuth reset countdowns in Chinese right-edge details and English left-edge / bubble details; blue app link; click from either edge capsule; Esc returns to the small capsule or round bubble; bubble dragging to the desktop and back. Switching keyboard focus to Finder closes final-version pinned edge details. The original Chinese / right-edge style and saved bubble placement were restored. |
| Continuous pointer behavior | Automated intent/timer checks pass. A scroll-based automation probe could not reliably establish a continuous hover; manual acceptance remains for the exact 0.5s delay, preview exit / re-entry and animation feel. |
| Build / package | Passed: final 250 Swift tests (231 Core, 19 App), version consistency, script syntax, documentation links and scoped sensitive-data checks. Existing stable-signing script produced an app installed at the original location with matching executable hashes and strict signature verification. A concurrent run hit the existing app-server handshake test's one-second timeout; the isolated final rerun passed. No DMG was created for this task. |
| Saved account / preferences | Passed: the existing Retry reading action recovered the original OAuth sign-in after updating; final details display current real quota. Notification settings, low-quota preference and app identity remain unchanged. |
| System notification icon | Passed by user confirmation on October 10: after restarting the Mac, the notification artwork displayed correctly. A fresh test from installed 0.1.134 reached Notification Center at 23:44 on October 9. Post-restart visual evidence is the user's report, not an automated screenshot. The precise stale-state cause remains unidentified. |
| Deferred work | Fullscreen hiding and Token comparison are outside this version. |
| Public release | Not requested; no push or Release. |

The countdown is the interval to a reported reset deadline, not a prediction of future quota availability. Hover previews leave the active application's keyboard focus alone; clicking details enables panel keyboard focus for Esc.

Commands: `swift test --build-system native --scratch-path <temporary-test-directory>`, `scripts/check_release_consistency.sh`, `bash -n scripts/package_app.sh scripts/package_dmg.sh`, `git diff --check`, `scripts/package_app.sh` with isolated build/dist paths and stable signing, and `codesign --verify --deep --strict`.

Before public release: complete continuous-pointer acceptance; the notification-icon blocker is closed for this Mac by user confirmation. For the diagnostic history, see [0.1.133 acceptance](../0.1.133/QA.md). Real reset-at-zero UI acceptance remains pending the next observed deadline; its waiting-for-refresh behavior is covered by deterministic tests.
