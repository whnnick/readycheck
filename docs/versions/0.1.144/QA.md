# 0.1.144 black-box acceptance (local preview)

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Version index](../../VERSIONS.md)

Status: local 0.1.144 repair, regression checks, packaging, installation and selected native UI operations completed on October 13, 2026. Public publication is not complete; the current public release and latest remain [0.1.143](https://github.com/whnnick/readycheck/releases/tag/v0.1.143).

| Requirement | Status and evidence |
| --- | --- |
| Pin + desktop click | Controller regression coverage passed. A new manual click on blank desktop space was not performed; retain this for an additional installed-app spot check. |
| Pin + other app | Native UI check passed: open details from the edge rail and pin them, then click Chrome's native Play control, its address bar and switch browser focus; the details remain expanded. |
| Pin + other ReadyCheck window | Controller regression coverage passed. A new manual click on another ReadyCheck window was not performed; retain this for an additional spot check. |
| Unpin + hover | Native UI check passed: unpinning returns to the existing hover preview, which collapses with the pointer outside. Controller regression coverage also passed. |
| Esc | Existing controller coverage passed. No new manual Esc check was performed; retain focused Esc and immediate-reopen behavior for an additional spot check. |
| Controls and help | Native UI check confirms that the detail minus button is absent and the new Bubble tooltip is active. Bubble help is scoped separately from EdgeRail-style semantics; broader bilingual help inspection remains an additional manual check. |
| Geometry and dragging | The 16 targeted tests and the final full suite passed. The installed expanded pinned window measures 1000 × 496 pixels at 2×, corresponding to 500 × 248 points. Circle geometry and existing drag behavior are retained; the test results do not imply a new manual drag check on every screen. |
| Windows metadata | The Windows portable ZIP reports 0.1.144 and passes ZIP integrity and hash checks. This version changes Windows metadata only. |
| Local installation | The macOS DMG reports 0.1.144 and passes strict signing verification with ReadyCheck Preview Signing and hash checks. The app is installed in Applications; the complete prior 0.1.143 app is retained as a private local backup. The user completed Keychain Always Allow verification again and live quota reading recovered. |

Regression evidence: five new controller regressions first reproduced pinned details collapsing on focus loss. The repaired implementation then passed all 16 targeted tests with zero failures and zero skips.

Full-suite evidence: the initial 278-test run had one failure in `EdgeRailWidgetTests.testBubbleWindowContentFollowsEdgeAndExpandedSizes`: hosting bounds measured 476 × 243 rather than the expected 500 × 248 while macOS and Windows packaging were also running. After packaging load ended, the full rerun at 13:24 China Standard Time passed 278/278 tests with zero failures and zero skips. Animation timing is a possible explanation, not a proven root cause; the successful rerun does not erase the initial failure.

The temporary 8× ImageRenderer capture changes in source were precisely restored. Native UI screenshots containing real quota values remain private and are not copied into public documentation. High-resolution synthetic fixtures are suitable for public visual evidence; this document does not publish the private screenshots or local backup paths.

Completed: pin repair and control/help changes; five regressions reproduced before the fix; 16 targeted tests and final 278-test full suite; version consistency; local macOS/Windows package version, strict Mac signing, ZIP integrity and hashes; local installation, Keychain recovery and the native Chrome interaction/unpin/control checks described above.

Partially completed: real-environment acceptance. The installed-app check covers edge-rail opening, pinning, Chrome interaction/focus changes, unpinning, control removal and Bubble tooltip behavior. Automated controller coverage supports the remaining interaction scenarios but does not substitute for separate manual checks.

Not completed: new manual blank-desktop, other ReadyCheck-window and focused Esc checks; multiple displays, Spaces and broader screen-scaling spot checks; public 0.1.144 publication and remote asset/latest verification.

Validation commands used in the owning verification work include `swift test --build-system native --scratch-path <temporary directory>`, `scripts/check_release_consistency.sh`, `scripts/package_app.sh`, `scripts/package_dmg.sh`, `codesign --verify --deep --strict`, `zip -T` and SHA-256 checks. Local paths, live account values and private screenshots are excluded from this record; public package hashes and release evidence will be added after publication.

Real-environment checks remaining: the manual scenarios listed above, including desktop/other ReadyCheck-window focus changes, focused Esc, multiple displays, Spaces and relevant screen scales.

Public-release blockers: 0.1.144 public publication is incomplete. Public-source/history privacy checks, tag/Release publication and remote asset/download/latest verification must be recorded in the release step. No public 0.1.144 status or latest update is claimed here.

Public-source validation also observed the host at 472 × 242 after the panel and container had reached 500 × 248. The sizing test now waits up to one second for actual content-subtree layout, with all target-size assertions retained. The six targeted tests and a new complete 278-test run passed with zero failures and zero skips; production geometry and animation are unchanged.
