# 0.6.1 — Notification click acceptance

[中文](QA.zh-CN.md) · [0.6.0 baseline](../0.6.0/QA.md)

| Requirement | Status | Evidence |
| --- | --- | --- |
| Default click opens notification history | Passed with a real test notification | Targeted route test plus real Notification Center click from Settings; history page visible. |
| Dismissal does not navigate | Implemented | Targeted route test. |
| Existing rules, account and history | Retained in installed development build | OAuth and live quota recovered; notification history and existing reminder and automatic-card settings were visible after restart. |
| Cold start | Passed with a real test notification | The app was quit, then the user clicked the test notification; the launched app displayed notification history. |
| Release | Authorized; final package and remote checks tracked separately | Local native acceptance above. |

Native notification style and complete submission time are retained. The system upper-right time issue remains open; no real reset card is used for testing.

## Native acceptance and regression

On the installed signed 0.6.1-dev.1, the user clicked a real test notification while the app was open on Settings and the app showed notification history. A separate test notification launched the app after quit and again showed notification history. A prior click did not navigate; the test notification had been muted while screen sharing, and the exact clicked item could not be confirmed. Notification tests: 20 passed; route test: 1 passed; the Objective-C delegate selector was verified. No real card was redeemed. Full product regression and public release were not performed in this local fix.
