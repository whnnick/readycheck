# 0.1.145 black-box acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Version index](../../VERSIONS.md)

Status: native edge repair, regression testing, stable-signed installation, both GitHub homepage languages and the public 0.1.145 release are verified on October 13, 2026.

| Requirement | Status and evidence |
| --- | --- |
| Curved edges | Installed 0.1.145 compact, expanded and edge-tab forms inspected on the current 2× display. The native mask is supersampled at twice backing resolution before compositing; the shape path and view sizes are unchanged. |
| Direct dragging | Installed expanded round dial dragged directly into the right edge tab. Existing left/right drag and geometry regressions pass. |
| Pin and controls | Installed expanded details show the active pin and no minus button. Existing pinned/outside/focus and unpin controller regressions pass; this does not imply fresh manual coverage for every focus/Spaces scenario. |
| Regression tests | Five targeted EdgeRail tests and all 278 Swift tests pass with zero failures and zero skips. The mask must render at least at the display resolution and rasterization must match that render scale. |
| Installation | Version 0.1.145 installed after retaining the complete prior app. Stable ReadyCheck Preview Signing and strict bundle verification pass. The user completed system verification and live quota readings recovered after Retry Reading. |
| Homepage | Current native demo assets and both README languages prepared. GitHub Markdown API rendering checked in local desktop (1280 px) and mobile (390 px) previews: all images load, no horizontal page overflow. Native scroll content is retained in window-backed captures; compact/edge fixtures use 4× ImageRenderer. Public GitHub English/Chinese pages also show the current native assets correctly; the 390 px Chinese page has no horizontal overflow and all images load. Repository About is bilingual and its existing project-site link is retained. |
| Public release | Sanitized public source/history, Mac DMG and Windows ZIP, annotated tag, Release/latest, exact-source Windows CI and actual downloaded digests verified. Details below. |

Completed: the scoped native silhouette change, five targeted and 278 full tests, version consistency, local stable-signed build/install and the native checks above, bilingual public homepage and release/download acceptance. Ring dimensions, quota calculation, pin logic, dragging and the underlying silhouette path are unchanged. Windows receives version metadata only.

Partially completed: real-environment coverage. Native 2× screenshots are checked locally and contain real quota readings; they are excluded from public assets. Component demo exports do not substitute for native compositor verification.

Not completed: real 1× external-display checks, cross-display movement, macOS 14 hardware, broad Spaces/performance checks.

Validation: `swift test --build-system native --scratch-path <temporary directory>`, `scripts/check_release_consistency.sh`, `scripts/package_app.sh`, strict `codesign` verification, native screenshot inspection and `git diff --check`. The first restricted invocation failed to write the compiler cache before any tests ran; the successful runs used normal local permissions. No test result is inferred from that setup failure.

The mask resolution follows window backing changes. Core Animation scale semantics are documented by [Apple](https://developer.apple.com/documentation/quartzcore/calayer/rasterizationscale). A local outer-band comparison at identical 184×184 capture size confirms changed edge coverage without moving the silhouette; it is diagnostic evidence, not an assertion that all displays are visually accepted.

Public-release blockers: none remain for this verified preview. Preview signing is not Developer ID signing or notarization; the real-environment coverage limits above remain open.

Native component fixtures: [details](assets/details-en.png), [compact 80%](assets/compact-80.png), [compact 5%](assets/compact-5.png), [edge](assets/edge-right.png). [Provenance and hashes](assets/provenance.json). All values are synthetic.

Public-source test evidence: the first run had one 1-second initialization-rejection timeout in an unchanged app-server monitor test and one pinned-window focus skip. All three monitor tests passed on immediate isolated retest. The final full public-source run passed all 278 tests with zero failures and zero skips. No unrelated production logic or timeout was changed.

[Release 0.1.145](https://github.com/whnnick/readycheck/releases/tag/v0.1.145) is latest, neither draft nor prerelease, with exactly two assets. Annotated tag `v0.1.145` targets source `3e57811e1968f39dc3ffbfe45b7ff4b08a3b2444`; edge repair and homepage are separate bilingual commits. Windows workflow [38390669915](https://github.com/whnnick/readycheck/actions/runs/38390669915) succeeded with that exact head SHA. Public source matches the reviewed development files and public-history privacy checks exclude internal collaboration material and private media.

Both assets were actually downloaded and match GitHub SHA-256 digests. The downloaded Mac DMG was mounted: bundle version 0.1.145 and strict stable-signature checks pass. The downloaded Windows ZIP passes integrity, reports 0.1.145 in its app package, and contains no internal collaboration files; its app.asar hash also matches the locally verified build. ZIP bytes differ from the local build because the published package is produced by CI.

- [macOS DMG](https://github.com/whnnick/readycheck/releases/download/v0.1.145/ReadyCheck-0.1.145-macos.dmg): `7e1641967422e5e0ad3942626a903eecdbf72028772002316c814abed5e8a2c2`
- [Windows portable ZIP](https://github.com/whnnick/readycheck/releases/download/v0.1.145/ReadyCheck-0.1.145-windows-x64-portable.zip): `e43683bd0f862d11abdefb35e3a91f17a750dae349a15d406a608e449c73f15a`
