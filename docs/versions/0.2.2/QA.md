# 0.2.2 black-box functional checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Version index](../../VERSIONS.md)

2026-10-19, local preview `0.2.2-dev.1`. Public release/downloads remain 0.2.1. No public push or release in this phase.

| Requirement | Evidence | Status |
| --- | --- | --- |
| Current account source owns connection state | Three synthetic connection-race tests reproduced 12 failed assertions before the patch. Late local success/failure and stored-credential success/failure are ignored after changing source. New account snapshots and isolated history are retained. | Passed after the minimal model fix. No real account was switched. |
| New connection refresh starts independently | A blocked old fetch no longer suppresses the new connection's fetch; completing the old request cannot clear the new activity indicator. | Passed deterministic continuation-based regression. |
| Transport failure remains visibly cached; recovery becomes fresh | Same-account failure retains the original timestamp, stale/unavailable status and percentages without new quota alerts. A successful reading replaces the cache and establishes a baseline without replaying an initial low reading. | Passed store regressions. Real network connectivity was not disabled. |
| Wake schedules a fresh connection/quota read | Invoke the model's wake callback with an injected reader and an empty executable list, then observe connected status, quota and refresh timestamp. | Passed synthetic callback regression; no Codex process launched, no physical sleep/wake performed. |
| Existing low-quota and recovery reminders | Existing 5/10/20 thresholds, account/window isolation, persisted deduplication, failed-delivery retries, stale/estimated reading rejection and recovery cancellation remain covered by their suites. | Focused reminder regressions passed; physical notification visibility/Focus behavior not newly claimed. |
| Upgrade and Keychain protection | Installed 0.2.1 and retained development apps share the preview signing identity/designated requirement. Serial background reads, suppressed hidden prompts, interactive retry, update-in-place credential storage and startup history loading remain intact. | Signing comparison passed. An existing Keychain item's authorization/root cause is not established; elimination of normal macOS confirmation is not claimed. No credential or ACL changes. |
| Full regression and local package | Final full-suite, version consistency, signature, launch and native live-data results recorded below. | 327 Swift tests passed, zero failures/skips; development metadata consistent. Strictly verified signed preview launched, visible version correct. Stable installed app unchanged. After normal user system confirmation, live credential reading and manual refresh passed. |

## Coverage and release limits

Physical sleep/wake, sustained offline operation, multiple displays/Spaces, another user's Keychain and real account changes remain device-acceptance work. Local fake-client tests do not establish those device results. Windows receives version metadata only; the connection-model change is macOS-only. No task-stop/resume integration is introduced. The app remains a self-signed preview, not Developer ID signed or notarized.

Live account values/screenshots, private paths and signing details remain outside product source. Retain the stable package for rollback. Any release must separately pass the existing public-sync, artifact and remote acceptance flow.

Sanitized automated results: [acceptance evidence](acceptance-evidence.json).

Native startup retained all 16 existing product preference keys byte-for-value, both existing history files, the 10% threshold, recovery reminder switch and notification history. Private rollback snapshots were saved before launch; no credential values were exported. After user system confirmation, the existing standalone sign-in recovered. Both live quota windows, subscription validity, Credits, reset count and individual expirations were visible. Manual refresh completed; local quota history and official daily Token data were readable. Widget details showed corresponding quotas and last-hour history, and Escape collapsed it. No real account switch, reset action or test notification was performed.
