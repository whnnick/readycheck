# 0.1.139 acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Versions](../../VERSIONS.md)

Status: local 0.1.139 installed and inspected on October 12, 2026; no public push or Release.

![Anonymous native hover-preview component](assets/bubble-preview-demo.png)

Actual SwiftUI preview state with pin button and synthetic 13% / 70% observations; not live account data or generated artwork. [English preview](assets/bubble-preview-en-demo.png). Multi-day countdowns are included so acceptance does not rely on short fixture labels.

| Requirement | Result / evidence |
| --- | --- |
| Smaller dial | 176-point dial region beside 324-point details; the rendered dial is 160 points versus 232 in 0.1.138, about 31% smaller. Proportional ring/C rendering inspected. Free-center anchoring, small-display clamping, two orientations and full transition bounds pass tests. |
| Preview title / countdowns | Chinese/English native preview captures with pin show single-line ReadyCheck and complete multi-day reset text. Installed real-data pinned details also inspected; final observed values 23% / 82%, matching red/green arcs and readable countdowns. Extra windows remain scrollable. |
| Exterior edge | Native mask backing scale equals the window backing scale in the regression test. Inset outline avoids half-clipped strokes; duplicate SwiftUI exterior clipping removed, neck joins tangent-aligned. Installed window outline inspected after the change. Other pixel densities/backgrounds still require physical review; no claim of universal pixel-perfect output. |
| Compatibility | Installed rail opens inward, Esc restores the rail, dragging away restores the free circle, click opens the new details. Curve and credential/notification identities retained. Left mirror has native capture/placement coverage, without a new physical left-edge trial in this iteration. |
| Build / account | Final signed app installed and opened; strict signature verification passes outside the sandbox and executable digest matches the package. Saved account reads actual quotas after system credential access. No credential or permission deletion. Windows metadata only. |

Completed: smaller dial, preview heading correction, edge-rendering fix, native captures and real-data local installation. Partial: other display/background combinations and subjective animation feel are not exhaustively accepted. Not implemented: additional product features or main-window redesign.

Full suite: 268 tests passed with no skips/failures. Packaging, version consistency, changed-document links, `git diff --check` and added-text sensitive-data review passed. Commands: `swift test --build-system native --scratch-path <temporary-directory>`, `scripts/package_app.sh`, `scripts/check_release_consistency.sh`, `codesign --verify --deep --strict`; captures use `READYCHECK_UI_EVIDENCE_DIR` / `READYCHECK_UI_APP_ICON`.

No blocker remains for this local preview. Public distribution requires the standard two-platform release workflow, not requested here.
