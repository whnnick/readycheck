# ReadyCheck 0.5.2 — One clear sign-in

[中文](RELEASE_NOTES.zh-CN.md) · [Checks](QA.md) · [Retention audit](RELEASE_AUDIT.md)

- **Sign in to ReadyCheck once.** OAuth is the sole sign-in and primary quota source. Remove the local-account selector, authentication fallback and experimental subscription-file cache.
- **Your account stays yours.** Preserve settings, account history and existing card-use consent. Confirm the same OAuth account to resume; a different account never inherits consent.
- **Recover without a restart.** Fresh quota restores the connection; cached readings and late results cannot. Startup waits for the initial sign-in check before automatic card checks. Successful checks resolve earlier credential warnings while retaining history.
- **Keep the useful surfaces.** Both quotas, subscription/card benefits, Token statistics, reminders, records, Widget hour chart, menu, notch and About remain. Matching-account Codex interfaces still provide background Token/card capabilities.

The sanitized public source passed all415 tests in one run. Windows checks, smoke/UI behavior checks and both package-content checks passed. The final DMG installation restored the same-account OAuth, benefits and Token data after macOS Keychain confirmation; all17 preferences and original card consent remain unchanged. No real card was redeemed for testing. macOS changes; Windows retains its existing interface. Stable self-signed preview, not Developer ID signed or notarized. New builds may need macOS Keychain access confirmation.
