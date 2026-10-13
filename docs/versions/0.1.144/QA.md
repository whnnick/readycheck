# 0.1.144 black-box acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Version index](../../VERSIONS.md)

Status: local 0.1.144 repair, regression checks, packaging, installation and selected native UI operations completed on October 13, 2026. The public [0.1.144 release](https://github.com/whnnick/readycheck/releases/tag/v0.1.144), latest status, source tests, CI and downloaded packages are verified.

| Requirement | Status and evidence |
| --- | --- |
| Pin + desktop click | Controller regression coverage passed. A new manual click on blank desktop space was not performed; retain this for an additional installed-app spot check. |
| Pin + other app | Native UI check passed: open details from the edge rail and pin them, then click Chrome's native Play control, its address bar and switch browser focus; the details remain expanded. |
| Pin + other ReadyCheck window | Controller regression coverage passed. A new manual click on another ReadyCheck window was not performed; retain this for an additional spot check. |
| Unpin + hover | Native UI check passed: unpinning returns to the existing hover preview, which collapses with the pointer outside. Controller regression coverage also passed. |
| Esc | Existing controller coverage passed. No new manual Esc check was performed; retain focused Esc and immediate-reopen behavior for an additional spot check. |
| Controls and help | Native UI check confirms that the detail minus button is absent and the new Bubble tooltip is active. Bubble help is scoped separately from EdgeRail-style semantics; broader bilingual help inspection remains an additional manual check. |
| Geometry and dragging | The 16 targeted tests and the final full suite passed. The installed expanded pinned window measures 1000 × 496 pixels at 2×, corresponding to 500 × 248 points. Circle geometry and existing drag behavior are retained; the test results do not imply a new manual drag check on every screen. |
| Windows metadata | The published CI-built Windows ZIP reports 0.1.144. Its actual downloaded file matches the GitHub asset SHA-256 and passes ZIP integrity with 78 entries. This version changes Windows metadata only. |
| Local installation | The macOS DMG reports 0.1.144 and passes strict signing verification with ReadyCheck Preview Signing and hash checks. The app is installed in Applications; the complete prior 0.1.143 app is retained as a private local backup. The user completed Keychain Always Allow verification again and live quota reading recovered. |

Regression evidence: five new controller regressions first reproduced pinned details collapsing on focus loss. The repaired implementation then passed all 16 targeted tests with zero failures and zero skips.

Full-suite evidence: the initial 278-test run had one failure in `EdgeRailWidgetTests.testBubbleWindowContentFollowsEdgeAndExpandedSizes`: hosting bounds measured 476 × 243 rather than the expected 500 × 248 while macOS and Windows packaging were also running. After packaging load ended, the 13:24 China Standard Time rerun passed 278/278 with zero failures and zero skips. Public-source validation then observed the host at 472 × 242 after the panel and container had reached 500 × 248. The test now waits up to one second for actual AppKit content-subtree layout, retaining every target-size assertion; production geometry and animation are unchanged. Six targeted tests passed, and the complete public-source run at 14:04 passed 278/278 with zero failures and zero skips. The observed layout lag supports this test repair; concurrent packaging was not established as the root cause. The initial failure remains part of the record.

The temporary 8× ImageRenderer capture changes in source were precisely restored. Native UI screenshots containing real quota values remain private and are not copied into public documentation. High-resolution synthetic fixtures are suitable for public visual evidence; this document does not publish the private screenshots or local backup paths.

Completed: pin repair and control/help changes; five regressions reproduced before the fix; 16 controller-targeted tests, six sizing-targeted tests and final 278-test public-source suite; version consistency; local macOS/Windows package version, strict Mac signing, ZIP integrity and hashes; local installation, Keychain recovery and the native Chrome interaction/unpin/control checks described above; public source/history privacy checks, CI, Release/latest and actual download/hash/ZIP acceptance.

Partially completed: real-environment acceptance. The installed-app check covers edge-rail opening, pinning, Chrome interaction/focus changes, unpinning, control removal and Bubble tooltip behavior. Automated controller coverage supports the remaining interaction scenarios but does not substitute for separate manual checks.

Not completed: new manual blank-desktop, other ReadyCheck-window and focused Esc checks; multiple displays, Spaces and broader screen-scaling spot checks.

Validation commands used in the owning verification work include `swift test --build-system native --scratch-path <temporary directory>`, `scripts/check_release_consistency.sh`, `scripts/package_app.sh`, `scripts/package_dmg.sh`, `codesign --verify --deep --strict`, `zip -T` and SHA-256 checks. Local paths, live account values and private screenshots are excluded from this record; published package hashes and release evidence appear below.

Real-environment checks remaining: the manual scenarios listed above, including desktop/other ReadyCheck-window focus changes, focused Esc, multiple displays, Spaces and relevant screen scales.

Public release complete: [0.1.144 Release](https://github.com/whnnick/readycheck/releases/tag/v0.1.144). At publication, public main and the annotated `v0.1.144` tag point to source `b43111450cf60236ea610f400e2041ccd9d1c7c3`. The source matches the development implementation; public-source and visible-history privacy scans passed without new private media, credentials or internal development materials. The Release is neither draft nor prerelease, is latest, and contains exactly two uploaded assets. Windows workflow [38355594858](https://github.com/whnnick/readycheck/actions/runs/38355594858) completed successfully with that exact source as its head SHA.

Both public packages were actually downloaded, and their SHA-256 values match the GitHub asset digests. The downloaded Windows ZIP passes integrity with 78 entries; the published macOS DMG was mounted and its 0.1.144 bundle passed strict ReadyCheck Preview Signing verification. The Windows hash below belongs to the published CI artifact, not an earlier local Windows build.

- [macOS DMG](https://github.com/whnnick/readycheck/releases/download/v0.1.144/ReadyCheck-0.1.144-macos.dmg) SHA-256: `b6bf4b889562a5c741bdd7f336bf58309282fdf256c51c0d8c93980f7de8312b`
- [Windows portable ZIP](https://github.com/whnnick/readycheck/releases/download/v0.1.144/ReadyCheck-0.1.144-windows-x64-portable.zip) SHA-256: `e5b5cd570d83a71b5d3a589de103b27520e5b3e3adc7fc212443d87e74fac5d5`

Public-release blockers: none remain for the verified release. The additional manual scenarios above remain explicit real-environment coverage limits.
