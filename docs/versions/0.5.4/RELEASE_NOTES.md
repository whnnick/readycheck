# ReadyCheck 0.5.4 — Compact reset-card details

[中文](RELEASE_NOTES.zh-CN.md) · [Checks](QA.md)

- Remove the divider after the last detail section, eliminating the apparent empty bottom partition.
- Reduce the sheet from480 to400 points high. Keep every card fact, outcome, timestamp, request detail and notification state; long content still scrolls.
- Keep Close/Escape, exact related notifications, the dedicated notification page and all reminder rules/history/consent.

macOS layout fix; Windows retains its existing interface. Stable self-signed preview, not Developer ID signed or notarized. New builds may need Keychain confirmation. No real card redeemed for testing. Release verification is tracked in the paired checks.
