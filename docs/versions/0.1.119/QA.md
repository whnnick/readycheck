# 0.1.119 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.118 acceptance](../0.1.118/QA.md)

Status: local macOS preview; not published.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Choose edge rail without losing bubble, card, or notch | Passed on one Mac | The settings picker switched Edge rail → Bubble → Card → Edge rail in the signed preview. The separate notch toggle remained visible and off; simultaneous notch behavior was not exercised. |
| Show real Codex 5-hour and 7-day quota | Passed with the live local account | Both rail rings matched the main window's changing Codex percentages; the detail card showed both reset times. Missing or stale percentages are wired to the existing unknown-state rule, but that branch was not forced in the live app. No other provider data or usage-time prediction is synthesized. |
| Expand inward and leave to collapse | Passed with pointer-directed clicks; hover-only pending | The 16-point edge target opened the 84-point dock, a ring opened the 354-point detail card, and moving to the main window left the rail as a thin line. AppKit tracking handles pointer enter/exit, with click as an alternate opening action. Pure hover without a click and reduced-motion settings have not been exercised manually. |
| Drag between screen edges and remain on-screen | Passed on one display | A live drag saved a new vertical position and another crossed to the left edge; the detail card then opened to the right of the rail. The right-edge case opened to the left. Placement tests cover both sides and top/bottom clamping. Multiple-display changes remain untested. |
| Build, regression, and package | Passed | 204 core and 4 app tests passed, including OAuth loopback. A stable-signed 0.1.119 preview app launched with live Codex data. Signature and version consistency checks are recorded below. |

Release blocker: this is a local preview. Final user acceptance on the actual hover feel and another-display behavior is still useful before publication.

Verification: `swift test --disable-sandbox` passed 204 core and 4 app tests; `scripts/check_release_consistency.sh` reported 0.1.119; `codesign --verify --deep --strict` confirmed the packaged local preview is valid on disk and satisfies its designated requirement. `git diff --check` passed, and the changed files contained no detected credentials or private account identifiers.
