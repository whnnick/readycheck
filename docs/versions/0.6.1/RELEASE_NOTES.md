# ReadyCheck 0.6.1 — Notifications open their history

[中文](RELEASE_NOTES.zh-CN.md) · [Checks](QA.md)

- Clicking a ReadyCheck system notification opens notification history, whether the app is already running or starts from the notification. Dismissing a notification does not navigate.
- Reminder rules, account history and automatic-card authorization remain in place.
- Notifications retain a full submission timestamp. The system's upper-right relative time may still be absent.

No real reset card was redeemed in testing. macOS is a self-signed preview, not Developer ID signed or notarized. Windows keeps its existing interface.
