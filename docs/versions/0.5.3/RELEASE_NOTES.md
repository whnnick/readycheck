# ReadyCheck 0.5.3 — Notification history, one click away

[中文](RELEASE_NOTES.zh-CN.md) · [Checks](QA.md) · [Retention audit](RELEASE_AUDIT.md)

- **A dedicated Notification history page.** Open the complete existing local delivery list from the sidebar or Command4. Inspect submitted, verified, failed, withdrawn and older unverified states without a View-all sheet.
- **Overview for status; Settings for rules.** Remove the duplicate bottom reminder shortcut and settings history summary. Every reminder switch, threshold, expiry milestone, automatic-card rule/consent and notification test remains. Card outcomes and exact related notifications remain separate.
- **Keep your place clear.** Page changes start at the heading rather than inheriting another page's scroll offset. Original Command1/2/3 and native fullscreen commands remain.

Development acceptance:417 full tests before the scroll fix, then19 affected tests after it; bilingual minimum-width light/dark rendering and installed native navigation passed. All17 preferences, original reminders/history and auto-card consent remain; no test card redemption. The final public source passed all417 tests; Windows checks/smoke/UI behavior, both package-content checks and strict Mac signing passed. Download verification is recorded in the paired checks. macOS update; Windows retains its existing interface. Stable self-signed preview, not Developer ID signed or notarized; updates may require macOS Keychain confirmation.
