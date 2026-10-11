# 0.1.133 notification-icon refresh

[中文](PLAN.zh-CN.md) | [Acceptance](QA.md)

Scope: macOS system reminder identity after updating the C app icon. Keep the bundle ID, signing identity, account credentials, notification permissions and existing reminders intact. No GitHub release is requested; Windows receives version metadata only.

Evidence: the installed 0.1.132 ICNS already contains the C artwork, while several older ReadyCheck bundles remain registered. System notification settings display C and a fresh test is delivered. These facts support a stale system lookup/cache hypothesis; they do not prove that every old notification redraws.

Minimum change: use the ICNS content hash in its filename and reference that exact file in Info.plist; fail packaging if ICNS conversion fails. Register the current running app with LSRegisterURL(update: true) before constructing the notification client. Do not modify notification content with a substitute attachment or clear the system notification database.

Validate version consistency, Swift tests, packaged icon representations, signature and identity continuity. Install the full signed app at its existing path, verify the saved account still refreshes and notification preferences remain enabled, then inspect a newly delivered test alert. OS-retained historical alerts are a separate acceptance item.

References: [Apple icon keys](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html), [LSRegisterURL](https://developer.apple.com/documentation/coreservices/1446350-lsregisterurl).
