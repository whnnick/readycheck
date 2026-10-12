# 0.1.137 acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Versions](../../VERSIONS.md)

Status: local 0.1.137 installed and inspected on October 12, 2026. No public push or Release.

![Anonymous native component capture](assets/bubble-reference-demo.png)

Actual SwiftUI component with synthetic 13% / 70% observations; not live account data or generated artwork. The [rail capture](assets/bubble-edge-rail-demo.png) uses the same anonymous values and packaged C icon.

| Requirement | Result / evidence |
| --- | --- |
| Original styling | Sculpted shell, soft neck, metallic bezel, ticks, thick concentric arcs, plain C, colored markers, separators and blue link inspected. Shared native mask and visible outline; numeric date matches the reference. |
| Quota / history | Extra, weekly-only, empty and restored-selection captures pass; all windows remain scrollable. Installed actual OAuth reading at final inspection: 46% / 86%, matching orange / green arcs and detail percentages. Unknown/stale values stay unknown. Mini-trend aggregation tests pass; four strokes depict the same five-minute observation, not four new observations. |
| Edge / free placement | Computer Use dragged to both edges, observed the two-bar rail and inward expansion, then dragged away to restore a free circle. Left/right layouts inspected. Chinese restored, final free placement on the right. |
| Interaction | Installed click-to-pin, Esc collapse, automatic hover preview and pointer-exit collapse observed. Existing hover/drag cancellation tests retained. Exact frame-by-frame motion and subjective mouse feel are not fully measurable by the tool. |
| Geometry | Window/content-size test passes. New mask test covers 21 transition steps from circle and rail in both orientations, checking bounds and an intact center. System circular-arc cubic approximation requires a 0.1-point subpixel tolerance; initial 0.01-point assertions were too strict. |
| Build / account | Final package installed; strict signature verification outside the sandbox passes; executable digest matches the package. Stable identity, saved credentials and notification settings retained. User completed repeated system Keychain prompts; final process reads actual quotas. Windows metadata only. |

Completed: reference styling, both edge rails, real data, local installation and native captures. Partial: physical motion feel remains a user judgment. Not implemented: main-window redesign or additional features. Physical notch, multiple displays and full-screen behavior were not reaccepted in this visual iteration.

Final full suite: 264 tests passed, no skips/failures, including the formerly intermittent initialization-error handshake test. Packaging, release version consistency, document links, `git diff --check` and changed-text sensitive-data review passed. Verification uses `swift test --build-system native --scratch-path <temporary-directory>`, `scripts/package_app.sh`, `scripts/check_release_consistency.sh` and `codesign --verify --deep --strict`; native captures use `READYCHECK_UI_EVIDENCE_DIR` / `READYCHECK_UI_APP_ICON`.

No blocker remains for the requested local preview. Public distribution still requires the standard two-platform release workflow and remote verification; it was not requested here.
