# 0.1.141 acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Versions](../../VERSIONS.md)

Status: installed and inspected locally on October 12, 2026; full public release preparation authorized.

![Single bars, anonymous native fixture](assets/consumption-bars-demo.png)

[English render](assets/consumption-bars-en-demo.png) · [Zero markers](assets/zero-bars-demo.png) · [Missing slots](assets/missing-bars-demo.png). These captures render the actual SwiftUI components with synthetic observations, not live account readings.

| Requirement | Result / evidence |
| --- | --- |
| Single bars | Three geometry tests verify one bar per observed bin, fixed time-slot positions across gaps, proportional heights and spacing for 12 bins. Native Chinese/English renders inspected. |
| Zero / unknown | Zero uses dim short ticks, missing/invalid samples stay blank. Existing three aggregation tests pass; no data-store or aggregation changes. Installed accessibility Help explains five-minute bins, units, zero and unknown states in Chinese; English source/render checked. |
| Installation / layout | 0.1.141 installed at the existing application path with stable preview signing; strict verification passes and executable digest matches the staged build. After user-completed Keychain verification, fresh verified OAuth quotas returned. Actual expanded edge bubble shows single bars, complete title/countdowns and the existing dial and pin. Expanded 500 × 248-point dimensions remain unchanged. |

Verification: six focused aggregation/chart tests passed. Full Swift suite executed 270 tests with zero failures and one skip: the native pinned-window sizing test could not retain foreground focus while the Mac was locked. This unchanged behavior has prior passing evidence; the unlocked installed bubble was inspected afterward. Version consistency, modified-document links, whitespace and added-text sensitive checks passed. Commands: `swift test --build-system native --scratch-path <temporary-directory>`, `scripts/check_release_consistency.sh`, `scripts/package_app.sh`, `codesign --verify --deep --strict`.

Completed: macOS bars, zero/unknown distinction, bilingual help, anonymous native renders, installed-app visual acceptance. Windows metadata synchronized; no Windows behavior changes or new Windows physical acceptance. No pending product change. Public 0.1.141 DMG/ZIP, tag and Release are now requested; final package and remote verification follow the standard release workflow. The signed build was staged outside the file-provider-managed source directory before installation to avoid Finder metadata affecting strict verification; signing identity and credentials were preserved.

Local package checks: fresh 0.1.141 DMG and Windows ZIP built successfully using the standard scripts and Node 24. Mounted DMG app version is 0.1.141 with valid strict stable signing; ZIP integrity passes. Windows automated packaging checks passed. Final public-snapshot artifact verification follows before upload.

Final public-snapshot verification: all 270 Swift tests passed with no skips or failures. Fresh final DMG passes mounted version/signature verification; Windows packaging checks, ZIP integrity and output-directory checks pass.

Remote release verified: public main and annotated tag point to 7a1c2344d2ed4fd39455395ec35efe982ce715c1. GitHub latest is v0.1.141 with exactly two uploaded assets. Both downloaded packages match GitHub SHA-256 digests; DMG app version/signature and Windows ZIP/ASAR version/content checks pass. Windows upload workflow run 38232211864 succeeded. [Release](https://github.com/whnnick/readycheck/releases/tag/v0.1.141).
