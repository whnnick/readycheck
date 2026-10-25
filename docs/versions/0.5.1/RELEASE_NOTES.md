# ReadyCheck 0.5.1 — Clearer at a glance. Everything retained.

[中文](RELEASE_NOTES.zh-CN.md) · [Checks and limits](QA.md) · [65-feature retention](RELEASE_AUDIT.md)

- **A clearer Overview.** Current quota-reading state comes first; recent trends move ahead of complete account benefits. Plan, subscription fields, Credits, every card expiry and historical record remain accessible.
- **Less noise from transient card checks.** Retry brief read failures quietly; warn after at least three consecutive failures across two minutes. Credential, ledger and unknown-redemption-result warnings remain immediate. Recovered warnings are withdrawn without deleting history.
- **Settings reflect the actual state.** Independent quota/card-reminder/automatic-use groups, trailing controls and current-account On/Off/unknown text. Full rules remain one level away; original authorization, final-hour execution and success notices are retained.
- **Clearer measurement periods.** Token account summary and fixed comparisons are separate from the7/30/90-day daily chart. Quota consumption remains percentage points; missing Token dates are not zero. Circle↔edge previews show the actual adaptive Widget style.
- **Both connection methods stay.** Follow local Codex is the primary entry; separate OAuth remains available and existing selection is preserved. A local interface can omit the subscription date even when quota and cards work. Only same-account sign-in metadata may supplement it; otherwise the billing link and source explanation remain. No current-date guarantee or fabricated expiry.
- **Historical gaps stay historical.** Old reminder-only entries no longer become current card-use failures. Their outcomes remain unconfirmed. Read-only card details keep facts/results/notification state and Close, with no redundant settings button.

Both quotas, primary selection, recovery and low-quota reminders,72/48/24/12-hour milestones, consent, success notifications, history, Widget last-hour chart/drag/pin, click-only notch, About and all settings are retained. No real card consumed for acceptance; no automatic Codex task stop/resume claim.

## Verification and distribution

Development design validation passed410 Swift tests plus11 final scoped checks; the release-source regression, package/signature, remote and download results are recorded in QA as they complete. Native screenshots use synthetic data. Real existing preferences, account consent and attempt ledger were checked unchanged. Previous hardware/account/network limits are carried forward, not relabeled as tested.

Apple-silicon macOS14+ self-signed preview; **not Developer ID signed or notarized**. A new build may require system Keychain approval. Windows x64 retains its previous interface; these native design changes are Mac-only. Automatic use requires the app to run, usable account access and network; sleep/quit/offline periods can miss expiry. No inferred or retroactive card-use success.
