<a id="candidate-070"></a>

## 0.7.0 release candidate (2026-11-11)

- Codex remains the primary experience for quotas, resets, account benefits, Token history and reminders.
- The aggregate capsule brings Codex, DeepSeek balance and Muse weekly allowance together. Side details support previews, explicit pinning and Reduce Motion-aware transitions.
- Fix failed Muse subscription-action caching. A cached server error triggers one rediscovery, and unsuccessful reads discard the cached action for the next retry.
- Mac 0.7.0 is installed locally. The current verification, Windows runtime gate, package digests and distribution limits are recorded in [QA](QA.md#2026-11-11--070-release-candidate).

<a id="local-dev33"></a>

## Local development 0.7.0-dev.33 — capsule interaction and motion (2026-11-10)

- Refined the aggregate capsule and added fade/slide transitions for side details, including Reduce Motion and rapid reopening.
- Installed acceptance covers three-service readings, explicit pinning, Escape, reopening and the user's Codex hover/header-exit check. All eight sampled display preferences matched the upgrade baseline.
- The capsule regression passed 37 focused Swift tests. The versioned candidate passed 12 focused tests. Isolated v0.6.1 upgrade/rollback data checks and Windows package checks also passed. [Evidence and remaining stable-release gates](QA.md).

<a id="local-dev30"></a>

<a id="source-candidate-dev32"></a>

<a id="local-dev32"></a>

## Local development 0.7.0-dev.32 — aggregate capsule (2026-11-08)

- A persistent vertical capsule shows Codex 5h/7d, DeepSeek balance and Muse weekly quota together, with matching icon/ring geometry, numeric hierarchy and graphite material. [Design](AGGREGATE_CAPSULE.md).
- Service details open beside the capsule. Preview preserves the main selection; only the pin button keeps details open. Refresh/settings/open-main target the viewed service.
- Separate saved placement, inward details, edge snapping, snooze and full-screen settings; legacy single-service dial/card and positions remain available. No mixed-unit total, invented balance percentage, sessions or tok/s.
- The local dev.32 installation passed live reads, manual refresh, click previews, pinning and position restoration. **59 focused Swift tests, 9 JavaScript tests and 29 unlocked native window checks passed**. [Black-box status](QA.md).

<a id="local-dev31"></a>

## Local development 0.7.0-dev.31 — Muse read-after-login fix (2026-11-04)

- Correct the WebKit async overload so the app receives the subscription result and JavaScript failures. A real offline WebKit regression failed before the fix and passed after it.
- Discover the subscription action from fresh same-origin HTML after client-side sign-in. Retain request/size/time limits and field allowlisting; log only fixed failure stages.
- Reopening sign-in reloads the official homepage; a Reload page button recovers expired login pages without clearing the account session.
- Synchronize main-window/menu-bar display clocks when a new reading arrives, avoiding a temporary false stale indicator after refresh.
- Installed locally with the same preview signing identity. Fourteen focused Swift tests and nine JavaScript tests passed; live sign-in, fresh subscription reads, manual refresh, usage page and reloaded official-label comparison passed on this Mac. See [acceptance](QA.md).
- No public upload/tag/Release; Windows metadata only. Other accounts, OS login and the full display/Spaces matrix remain untested.

# ReadyCheck 0.7.0-dev.30 — Meta Muse app connection

[简体中文](RELEASE_NOTES.zh-CN.md#local-dev30) · [Acceptance](QA.md)

- Add the Muse personal agent (muse.ai), with a separate ReadyCheck web sign-in profile and weekly allowance/reset/plan reads. No browser-cookie import or model requests.
- Wire overview, usage, settings, menu bar, capsule/edge, card and notch; preserve the Codex dial, DeepSeek balance views, legacy selection preference and account-specific card behavior.
- Muse Code/API billing, daily Muse Token history and dedicated Muse reminders are outside this slice. Live Muse sign-in and final on-device acceptance remain pending.
- The website's subscription-read action is not a documented public API; a changed action or response fails clearly. Discovery is bounded, and only the expected subscription fields leave WebKit. CodexBar's MIT discovery reference and license are included in the resource bundle.
- 2026-11-04: installed dev.30 after the unlocked supplemental run cleared all remaining checks (531 distinct Swift tests plus six JavaScript tests). Official login form loaded; live Muse sign-in/read is blocked because the account's SMS verification code did not arrive.
- Local Mac build only; Windows metadata only. Public source/tag dev.28, preview dev.23 and stable 0.6.1 remain unchanged.

<a id="local-dev29"></a>

# ReadyCheck 0.7.0-dev.29 — Local Codex dial restoration

[简体中文](RELEASE_NOTES.zh-CN.md#local-dev29) · [Acceptance](QA.md)

- Restore Codex's original compact concentric quota dial and recovery highlight; keep DeepSeek's balance-and-trend capsule.
- Service-specific resting sizes retain the saved center, attached edge and explicit pin state. Readings, connection methods, card consent and histories are unchanged.
- Local Mac fix; Windows metadata only. Public source/tag remains dev.28, downloadable preview dev.23 and stable 0.6.1. No new GitHub Release.

<a id="source-candidate-dev28"></a>

# ReadyCheck 0.7.0-dev.28 — Packaged source candidate

[简体中文](RELEASE_NOTES.zh-CN.md#source-candidate-dev28) · [Acceptance](QA.md) · [Retention matrix](RELEASE_AUDIT.md)

The dev.28 Mac and Windows packages have been verified for source/tag synchronization. It is not a newly published GitHub Release. Public preview downloads remain dev.23 and stable downloads remain 0.6.1; [dev.23 preview notes](#public-preview-dev23) are preserved below.

- Apply the selected DeepSeek micro-trend design to the capsule, edge strip and expanded balance/components, preserving missing/stale/error states and local-observation semantics.
- Ordinary clicks preview; only the shared explicit pin button keeps details open. Account benefits now open by default and can still be collapsed.
- Deduplicate an already reported card incident across credential interruptions/restarts; new incidents remain eligible. Clear recovered credential warnings while retaining unresolved card outcomes and diagnostic history.
- macOS core acceptance covers 338 Core +179 App tests (517 unique passing tests, including three opt-in visual follow-ups), installed connection/refresh/pin/notch checks, user-confirmed menu/hover/notification checks and same-bundle restart. See QA for device limits.
- Windows keeps the existing Codex interface; dev.24–dev.28 Windows changes are version metadata only. Windows 403, other devices and OS-login/Spaces/fullscreen boundaries remain documented and do not become accepted by packaging.

macOS packages retain the established self-signed preview identity, not Developer ID signing or notarization. This packaging/source stage does not change stable latest or public preview publication state.

<a id="public-preview-dev23"></a>

# ReadyCheck 0.7.0-dev.23 — Public preview

[简体中文](RELEASE_NOTES.zh-CN.md) · [Checks and limits](QA.md) · [Retention checklist](RELEASE_AUDIT.md)

This candidate is based on the installed dev.23 and its recorded scoped acceptance. It is not the stable 0.7.0 release; the feature-retention gate is not fully cleared. The stable download remains 0.6.1.

- macOS adds DeepSeek API balance monitoring with separate granted/topped-up amounts, local observed balance decreases, manual refresh and balance reminders. API Key connection is separate from DeepSeek website/app chat usage. No model-generation requests.
- Keep the existing Codex quota, benefits, history, notifications, automatic-card authorization, menu bar and Widget paths. Settings retain direct platform connection entries, platform icons and Connection → Reminders → Display → General order.
- DeepSeek chart bars expose interval/amount details. Capsule-to-notch drops and downward notch-to-capsule dragging work in both directions. Codex notch offers stacked 5h/7d or single-quota display; dual details remove the redundant picker and expand smoothly, respecting reduced-motion preferences.
- About highlights now describe current capabilities; English About retains the complete brand/title and content, with bilingual default/minimum-size scrolling checks.
- Windows retains its existing Codex interface. OAuth/usage networking now uses Electron's system networking and 403 errors include routing guidance. The affected friend's Windows login has **not** been retested; this is not a claim that the 403 is fixed. Windows does not gain the new macOS DeepSeek/notch interface.

Validation: dev.23 passed 332 Core +172 App tests (504 total) and Windows check/smoke/UI-smoke. Existing macOS Codex/DeepSeek connections refreshed after user-approved Keychain access; the user confirmed physical downward notch dragging, both-edge first inward dragging, card-title dragging, same-display capsule fullscreen hide/restore and DeepSeek hover/leave details. Public-source/package/remote checks are tracked separately in QA.

macOS remains an Apple-silicon, macOS 14+ self-signed preview using the established signing identity, not Developer ID signed or notarized. Upgrades may require normal Keychain confirmation; credentials are not reset. Other devices, full VoiceOver, live account replacement and remaining retention-checklist items are not comprehensively accepted. No real reset card was redeemed for this release preparation.
