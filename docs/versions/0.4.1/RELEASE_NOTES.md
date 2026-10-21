# ReadyCheck 0.4.1 — timely reminders, less repetition

[中文](RELEASE_NOTES.zh-CN.md) · [Checks](QA.md) · [Scope](PLAN.md)

- **One reminder per expiry milestone.** Once macOS accepts a reminder for a card and milestone, refreshing, dismissing the notification or restarting will not re-submit that milestone. The later 72/48/24/12-hour milestones remain independent.
- **Credential retries preserve deduplication.** Temporary unknown account identity no longer clears the same account’s expiry markers; receipts remain separated by account.
- **Honest notification history.** Distinguish a submitted reminder from delivery verified in Notification Center. Explicit submission failures can still retry; macOS controls banner visibility.
- **A clearer project homepage.** Reorganized bilingual product presentation, native interface evidence and direct downloads. About highlights this correction.

Existing quotas, next events, account benefits, Token statistics, Widget last-hour chart, menu/notch controls and reminder switches remain. Automatic card use retains the original account-specific authorization and success notification; this release adds no card-redemption action.

The correction is macOS-only; Windows retains its previous interface and synchronized version metadata. Mac is an Apple-silicon self-signed preview, not Developer ID signed or notarized. Automated lifecycle/account cases and available-Mac refresh checks do not claim another live account, external displays, Windows hardware or real card redemption. See [QA](QA.md) for evidence and limits.
