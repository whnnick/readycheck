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
