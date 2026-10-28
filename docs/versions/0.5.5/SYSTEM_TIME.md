# System relative-time investigation

[中文](SYSTEM_TIME.zh-CN.md) · [Checks](QA.md) · [Plan](PLAN.md)

The user observed missing system-generated relative time in the upper-right corner even though the new fixed submission-time subtitle was present. The previous screenshot acceptance establishes that the system time can appear; it does not establish that it always appears.

A temporary isolated native notification helper used the existing application notification permission. It never initialized the account model, accessed credentials or requested a card redemption. It submitted exactly two labeled diagnostics: A with an immediate nil trigger and B with a one-second nonrepeating interval trigger. Both used the same title/subtitle/body structure. On macOS 27.0.1, the public notification API returned valid delivery dates for both, approximately 0.001 and 1.002 seconds after submission respectively.

After the user opened Notification Center, their native screenshot showed a relative time on both A and B; the pre-existing expiry reminder also showed its time. This rules out treating the short delay as a demonstrated fix. Reopening coincided with display recovery; the precise cause of the intermittent missing label remains unconfirmed. No production trigger, presentation option, permission or reminder rule was changed. The full fixed submission timestamp remains the application-controlled fallback. Do not claim a permanent fix for macOS relative-time rendering.

Only the two diagnostic identifiers were removed, zero remained, the helper exited and the installed application registration was restored. The original application continued running. All 17 preferences, consent, attempt ledger, reminder settings, account and authentication-cache digests matched before/after; ordinary card checks remained healthy, with zero test redemptions. Private screenshots and helper files are not public assets. Existing 418-test result reused because this investigation changed no production code.

References: [Apple notification date](https://developer.apple.com/documentation/usernotifications/unnotification/date), [editable notification content](https://developer.apple.com/documentation/usernotifications/unmutablenotificationcontent).
