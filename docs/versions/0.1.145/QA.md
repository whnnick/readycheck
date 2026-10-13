# 0.1.145 black-box acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Version index](../../VERSIONS.md)

Status: native edge repair, regression testing, stable-signed local installation and selected native checks complete on October 13, 2026. Homepage and public-release checks remain in progress; public latest is still 0.1.144.

| Requirement | Status and evidence |
| --- | --- |
| Curved edges | Installed 0.1.145 compact, expanded and edge-tab forms inspected on the current 2× display. The native mask is supersampled at twice backing resolution before compositing; the shape path and view sizes are unchanged. |
| Direct dragging | Installed expanded round dial dragged directly into the right edge tab. Existing left/right drag and geometry regressions pass. |
| Pin and controls | Installed expanded details show the active pin and no minus button. Existing pinned/outside/focus and unpin controller regressions pass; this does not imply fresh manual coverage for every focus/Spaces scenario. |
| Regression tests | Five targeted EdgeRail tests and all 278 Swift tests pass with zero failures and zero skips. The mask must render at least at the display resolution and rasterization must match that render scale. |
| Installation | Version 0.1.145 installed after retaining the complete prior app. Stable ReadyCheck Preview Signing and strict bundle verification pass. The user completed system verification and live quota readings recovered after Retry Reading. |
| Homepage | Pending current native demo assets, bilingual README rendering, links and remote visibility. |
| Public release | Pending sanitized public sync, packages, tag/Release, latest and downloaded hashes. |

Completed: the scoped native silhouette change, five targeted and 278 full tests, version consistency, local stable-signed build/install and the native checks above. Ring dimensions, quota calculation, pin logic, dragging and the underlying silhouette path are unchanged. Windows receives version metadata only.

Partially completed: real-environment coverage. Native 2× screenshots are checked locally and contain real quota readings; they are excluded from public assets. Component demo exports do not substitute for native compositor verification.

Not completed: real 1× external-display checks, cross-display movement, macOS 14 hardware, broad Spaces/performance checks, the homepage and final public release acceptance.

Validation: `swift test --build-system native --scratch-path <temporary directory>`, `scripts/check_release_consistency.sh`, `scripts/package_app.sh`, strict `codesign` verification, native screenshot inspection and `git diff --check`. The first restricted invocation failed to write the compiler cache before any tests ran; the successful runs used normal local permissions. No test result is inferred from that setup failure.

The mask resolution follows window backing changes. Core Animation scale semantics are documented by [Apple](https://developer.apple.com/documentation/quartzcore/calayer/rasterizationscale). A local outer-band comparison at identical 184×184 capture size confirms changed edge coverage without moving the silhouette; it is diagnostic evidence, not an assertion that all displays are visually accepted.

Release blockers remaining: current homepage and public package/tag/asset/download verification. Preview signing is not Developer ID signing or notarization.
