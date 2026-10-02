# 0.1.130 acceptance

[中文](QA.zh-CN.md) | [Product scope](PLAN.md) | [Version index](../../VERSIONS.md)

Status: preview release preparation. Stable preview signing is used; Developer ID signing and Apple notarization are not claimed.

| Requirement | Completion | Evidence and limits |
| --- | --- | --- |
| Retain every window in bubble details | Implemented and model-tested; physical scrolling pending | Native View test refreshes through three windows, weekly-only, empty and restored states, asserting every ID including distinct same-duration buckets. The two-window truncation is removed and a vertical ScrollView is used. Mouse scrolling remains unverified. |
| Names, urgency colors and blue app link | Native fixture screenshots inspected | bubble-extra, bubble-weekly and bubble-empty show names/durations, red 13%, green 70%/85% and the blue Open ReadyCheck link. These are synthetic readings. |
| Explain primary quota scope | Implemented; signed-app entry inspected | Live settings show Primary quota and explain its use by round bubble/notch while detail panels show all returned windows. Picker labels use returned window names. |
| Fall back temporarily and recover preferred choice | Tests pass; live empty-state entry inspected | Core tests cover saved IDs and legacy five-hour/seven-day choices. Missing picker selection retains the preference, display resolution falls back, and the preferred window returns when available. App refresh tests verify preferences are not overwritten. The signed app shows Saved window unavailable without data. |
| Existing interactions and styles | Partial | Existing 282 × 156 panel size, shape transitions, edge half-second hover and drag are retained. Existing highlight tests pass; live expand/collapse, left/right dragging and scrolling remain pending. No unobserved animation defect is claimed fixed. |
| Tests, version and local build | Passed | 211 Core and 6 App tests pass. Version consistency, diff checks and strict 0.1.130 app signature verification pass. |
| Windows | Version metadata synchronized; package verified | No Windows behavior change or physical Windows acceptance is claimed. |
| Release | Requested; remote verification pending | Publish source, tag, both installers and bilingual release notes through the documented workflow. |

Live acceptance/release gaps: the signed app was launched, but separate-sign-in credential access still awaits a system Keychain confirmation. Retry reading has been triggered; the user must complete that system prompt. Then verify scrolling to a third quota, expand/collapse, blue app link, left/right dragging and half-second hover. Real additional-bucket accounts, macOS 14 and Reduce Motion remain pending. Native screenshots and model tests do not prove these interactions.

Regenerate screenshots with `READYCHECK_UI_EVIDENCE_DIR` and `swift test --filter EdgeRailWidgetTests`; this version adds bubble-extra, bubble-weekly, bubble-empty and bubble-restored. Perform mouse acceptance in the signed app.

Release packaging: public-source final test run passes (211 Core + 6 App). The mounted DMG contains version 0.1.130 and passes strict ReadyCheck Preview Signing verification. Windows check, smoke and UI behavior scripts pass, as does ZIP integrity. The connection-fallback test timed out in the initial full run and grouped retest; an isolated diagnostic run and final unmodified full run pass. The intermittent timing failure is recorded without claiming its cause is confirmed.
