# ReadyCheck 0.7.0-dev.21 — Preview candidate

[简体中文](RELEASE_NOTES.zh-CN.md) · [Checks and limits](QA.md) · [Retention checklist](RELEASE_AUDIT.md)

This candidate is based on the installed and accepted dev.21. It is not the stable 0.7.0 release; the feature-retention gate is not fully cleared. The stable download remains 0.6.1.

- macOS adds DeepSeek API balance monitoring with separate granted/topped-up amounts, local observed balance decreases, manual refresh and balance reminders. API Key connection is separate from DeepSeek website/app chat usage. No model-generation requests.
- Keep the existing Codex quota, benefits, history, notifications, automatic-card authorization, menu bar and Widget paths. Settings retain direct platform connection entries, platform icons and Connection → Reminders → Display → General order.
- DeepSeek chart bars expose interval/amount details. Capsule-to-notch drops and downward notch-to-capsule dragging work in both directions. Codex notch offers stacked 5h/7d or single-quota display; dual details remove the redundant picker and expand smoothly, respecting reduced-motion preferences.
- Windows retains its existing Codex interface. OAuth/usage networking now uses Electron's system networking and 403 errors include routing guidance. The affected friend's Windows login has **not** been retested; this is not a claim that the 403 is fixed. Windows does not gain the new macOS DeepSeek/notch interface.

Validation: dev.21 passed 332 Core +171 App tests (503 total) and Windows check/smoke/UI-smoke. Existing macOS Codex/DeepSeek connections refreshed after user-approved Keychain access; the user confirmed physical downward notch dragging. Public-source/package/remote checks are tracked separately in QA.

macOS remains an Apple-silicon, macOS 14+ self-signed preview using the established signing identity, not Developer ID signed or notarized. Upgrades may require normal Keychain confirmation; credentials are not reset. Other devices, full VoiceOver, live account replacement and remaining retention-checklist items are not comprehensively accepted. No real reset card was redeemed for this release preparation.
