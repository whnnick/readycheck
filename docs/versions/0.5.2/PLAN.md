# 0.5.2 — One ReadyCheck sign-in

[中文](PLAN.zh-CN.md) · [Checks](QA.md) · [Versions](../../VERSIONS.md)

Release candidate: `0.5.2` (development acceptance: `0.5.2-dev.2`). The user explicitly authorized removing the local-account sign-in option and the immediately preceding subscription-cache experiment. OAuth is the only ReadyCheck sign-in. No account-source selector, local authentication fallback or direct subscription-cache reader remains in application code. The old source preference is ignored and left untouched for rollback.

Quota and account benefits come from ReadyCheck's authorized account. The background Codex adapter retains matching-account Token statistics, additional named quota windows, quota events and isolated OAuth-authorized card use. A local Codex sign-in cannot supply primary quota when ReadyCheck credentials are missing, unreadable or rejected. Background data from another account cannot overwrite OAuth quota or contribute Token statistics.

At first load, retain the saved account context for historical records and existing card consent. Without OAuth confirmation, that consent is pending rather than a confirmed Off state, and cannot execute. Signing in to the same account resumes the saved consent; a different account does not inherit it. Explicit sign-out clears the current account context, not the protected historical consent. Fresh OAuth quota recovers connection state; cached readings and late credential results cannot do so. Startup finishes the initial credential/refresh attempt before scheduling automatic card checks, so a pending credential read does not produce a false pause warning.

Retain the other quota, Token, reminder, reset-card, Widget, menu, notch and About capabilities. The authorized removal is the alternative sign-in route, not those capabilities. Do not delete credentials, rewrite historical accounts, weaken Keychain access or consume real cards for acceptance. Validate controlled migration/race cases, bilingual native UI, full regression, signed local installation and the user's real account. Packaging and public publication are now explicitly authorized. Follow the paired release audit; Windows UI is unchanged and version metadata is synchronized.

## Superseded dev.1 experiment

The following records what was implemented and tested before the user chose one OAuth entry. Its local-file subscription reader and local sign-in route are removed in dev.2; the connection-recovery repair is retained.

### Dev.1 — Local account metadata and connection recovery

[中文](PLAN.zh-CN.md) · [Black-box checks](QA.md) · [Versions](../../VERSIONS.md)

Scope: fix the two reported local-mode defects without removing features or changing sign-in source, consent, reminders, credentials or history. Local build `0.5.2-dev.1`; public stable remains `0.5.1`. No push or release is authorized in this repair task.

## Subscription metadata

The installed CLI and desktop protocol schemas have no subscription-date field in `account/read`. Read optional display metadata from the configured `CODEX_HOME/auth.json`, otherwise the default Codex home. Require the cache account and ID-token account to exactly match the current app-server account, a non-future token issue time and a valid subscription date. Limit the file read to 1 MiB; missing, protected, malformed or mismatched caches supply no metadata. Do not probe Keychain alternatives, copy tokens, refresh them, or write Codex files.

This is a saved login record, including when its ID token has expired. Never use it for authentication, eligibility, redemption or a claim of current billing validity. Show the original issue time and billing link; a past subscription date is explicitly labeled as previous. An existing valid matching separate credential keeps its original priority. Keep separate sign-in behavior; an expired or corrupt separate credential must not block an available local quota.

## Connection and automatic use

A non-cached, non-stale successful quota for the selected source and a known account restores connection status. It cannot finish an in-progress sign-in. A newer successful refresh invalidates older connection reload results. Existing account-switch generation guards and account-owned consent remain in force.

A local connection-read failure is a retryable service check, not automatically a credential error. Actual credential access errors retain immediate warnings. Only a successful same-account card check resolves a credential warning; retain its diagnostic history and all unresolved redemption-result warnings. Existing background scheduling, eligibility and consume guards are unchanged.

## Evidence and limits

Validate regression cases first, bilingual native layout, full Swift suite and the signed local app. Observe real quota, dated subscription metadata and an ordinary background card check without redeeming a real card. Preserve all 65 baseline capabilities; this patch has incremental coverage, not a new claim of complete physical-device acceptance.

Sources: [App Server](https://learn.chatgpt.com/docs/app-server#auth-endpoints), [credential storage](https://learn.chatgpt.com/docs/auth#credential-storage). The cached date claim is an observed implementation detail, not a guaranteed public billing API.
