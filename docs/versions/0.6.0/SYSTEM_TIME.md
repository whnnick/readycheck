# Native notification time — unresolved recurrence

[简体中文](SYSTEM_TIME.zh-CN.md) · [Checks](QA.md) · [Earlier investigation](../0.5.5/SYSTEM_TIME.md)

2026-10-28: the user supplied another screenshot showing real card-expiry and quota-recovery notifications with the fixed submission subtitle but no upper-right system time. An iPhone-mirrored weather notification has its system time. This does not establish that the label is limited to mirrored notifications: earlier local native A/B notifications displayed it too. A temporary test showing the label is not acceptance of production reminders.

The production code still uses standard UNNotificationRequest with an immediate trigger and the normal system delegate presentation options. It does not set a custom timestamp property or use a custom notification UI. Apple documents UNNotification.date as the read-only delivery date displayed in Notification Center. Root cause of the absent label remains unconfirmed; the fixed subtitle is a fallback, not a repair of system chrome.

A signed isolated read-only helper queried notification settings and existing delivered records without initializing the product model, accessing account credentials, submitting notifications, changing rules or deleting existing notifications. The host now reports macOS27.2. Settings were returned, but the delivered list was empty. This does **not** prove that production notifications lack dates, that their dates are correct, or that the screenshot notifications were cleared. The helper may not have observed the production notification context. The user subsequently confirmed the screenshot notifications had already been cleared, which explains the empty list; it is not evidence of invalid dates.

The helper exited, its temporary registration was removed and the installed product registration restored.17 preference values and the consent/attempt digests are unchanged. No production code, package, notification style or permissions were changed. No new app tests were needed for this documentation-only observation. The private screenshot and diagnostic outputs are not public assets.

Source: [Apple notification delivery date](https://developer.apple.com/documentation/usernotifications/unnotification/date).

## Production test after clarification

One clearly labeled test notification was submitted through the installed product settings, not created by the helper. The product verified it in Notification Center. A read-only query then returned that one record: its system delivery date was valid, was not in the future, and the trigger was immediate. This confirms a production-path local notification has a valid system date; it does not validate the already-cleared overnight reminders or fix the missing label. The helper registration was again removed and the installed registration restored. The user confirmed that this production test also has no upper-right time. A valid stored date therefore does not establish successful system rendering. Native automation still selects the battery widget. No reminder rules, consent or real cards are changed.

## Presentation comparison did not establish a fix

An isolated comparison was planned for standard foreground presentation, the deprecated alert compatibility option, and background delivery. Only background requests were submitted: automatic foreground activation failed, and computer-use tooling could not select the same-identifier helper window. Thus neither foreground variant was evaluated; no conclusion about presentation options or causal comparison is valid. The first background record had a valid date. No production presentation change was made.

The helper was stopped. Exactly3 owned diagnostic notifications were removed: the production test and two background-only matrix requests. Verification found zero of those remaining; all other notifications were untouched. Temporary registrations were removed, installed registration restored, and only the original product process remains.17 preferences, consent and attempt digests are unchanged. The system upper-right time remains unresolved; native style and the complete-date fallback are retained.

Reference: [Apple foreground presentation options](https://developer.apple.com/documentation/usernotifications/unnotificationpresentationoptions).

## Display-process refresh and application identity checks

One additional test was submitted through the installed application's Settings. The application reported that its Notification Center record was verified. Only the system NotificationCenter display process was then restarted; the notification service and ReadyCheck processes continued running. The user reopened Notification Center and confirmed that the test still had no upper-right time. Restarting the display process did **not** resolve this occurrence. No notification database, permissions or notification records were cleared. This one test remains available for inspection; it has not been deleted because its exact identifier was not collected.

Read-only checks found one LaunchServices registration for the production bundle identifier, pointing to the installed application with the expected executable, name and icon. The installed Info.plist has `LSUIElement=false` and no `LSBackgroundOnly` flag; the application entry point explicitly selects the regular activation policy. Strict deep code-signature verification passed. These checks found no identity or background-only configuration defect to repair; they do not prove that every system rendering path is correct.

The local SDK exposes the delivery date as read-only and provides no public notification-content property that forces the system time label to appear. The screenshot's weather notifications also have a Time Sensitive header, which is a visual difference, not proof of the cause. Changing ReadyCheck to Time Sensitive would change interruption behavior, including Focus handling, so it is not a timestamp repair. Immediate delivery and the standard banner/list/sound presentation remain unchanged.

All 17 preferences, the saved automatic-use authorization and attempt-record digests matched before and after the refresh. No real card was used. No production code, installed bundle or version changed, and no public release was performed. Documentation links, whitespace and sensitive-content checks cover this documentation-only update; the existing application test results are not new visual acceptance. The native upper-right time remains unresolved, with no evidence-backed application patch identified.

References: [Apple notification date](https://developer.apple.com/documentation/usernotifications/unnotification/date), [editable notification content](https://developer.apple.com/documentation/usernotifications/unmutablenotificationcontent), [Time Sensitive interruption behavior](https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive).
