# 0.1.129 acceptance

[中文](QA.zh-CN.md) | [Product scope](PLAN.md) | [Version index](../../VERSIONS.md)

Status: preview release preparation. The preview uses the existing stable signing identity; Developer ID signing and notarization are not claimed.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Show only returned, validated windows | Passed in tests and native fixture views | Weekly-only fixture shows one 7d ring; two-window fixture retains 5h and 7d. Invalid or absent windows produce an unavailable state with no fake rings. No plan-name inference is used. |
| Keep extra buckets distinct and label them | Passed in tests and native fixture views | Distinct bucket IDs survive matching durations. A third named one-hour allowance is visible in the capsule and corresponding details. Native screenshots were inspected. |
| Resize after quota refresh, on either edge | Passed in native window integration test | Model updates change the actual panel through empty, weekly, two-window, extra-window, and weekly-again states. The right edge is retained; left-edge refresh also passes. |
| Keep oversized lists inside the screen | Geometry passed; physical scrolling pending | Core tests constrain twelve windows to the visible screen. Ring and detail lists use vertical scrolling. Large live lists have not been observed. |
| Whole-capsule click, half-second hover, drag, blue app link | Implemented; signed-app interaction check pending | Existing interaction handlers are retained. The native detail screenshot preserves the blue Open ReadyCheck link. System Keychain access is awaiting user confirmation in the launched 0.1.129 preview. |
| Build, tests, version and signature | Passed locally | 209 Core tests and 5 App tests pass, including localhost OAuth callbacks and the native resizing test. Release-reference consistency and strict app signature verification pass. |
| Windows | Metadata only | No Windows edge-ring implementation or Windows runtime acceptance is claimed. |
| Public release | Requested; remote verification pending | Source, tag and both installers will use the documented release workflow. |

Native evidence can be regenerated with `READYCHECK_UI_EVIDENCE_DIR` set when running `swift test --filter EdgeRail`. The outputs include empty, weekly, two, extra, weekly-again, left-extra, and extra-detail PNGs. These are synthetic quota fixtures, not real account readings.

Remaining real-environment checks: complete the existing Keychain access prompt and verify live capsule interactions; verify a real weekly-only/Pro account and an account returning additional buckets; check physical scrolling on an oversized list and macOS 14 compatibility. These are acceptance gaps, not inferred passes. The preview retains this interaction acceptance gap, disclosed in release notes. Packaging and remote verification remain required.

Release packaging: public-source tests pass (209 Core + 5 App). The mounted DMG contains version 0.1.129 and passes strict signature verification with ReadyCheck Preview Signing. Windows check, smoke and UI behavior scripts pass; ZIP integrity passes. No physical Windows acceptance is claimed.
