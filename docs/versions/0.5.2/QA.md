# 0.5.2 OAuth-only black-box checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Versions](../../VERSIONS.md)

Published and installed: `0.5.2`. The live same-account OAuth/benefits/Token checks passed after user-approved Keychain access, and ordinary card checking resumed without test redemption. [Current sanitized evidence](oauth-only-evidence.json). Dev.1 evidence below is historical, not a description of the current sign-in UI.

| Requirement | Evidence | Status |
| --- | --- | --- |
| One sign-in, no local authentication or subscription-file route | Removed mode enum, selector, fallback and reader; bilingual native connection scenes | Targeted tests and rendering pass |
| OAuth remains authoritative | Missing/unreadable/rejected OAuth cannot fall back to local sign-in; different local account cannot provide primary quota or Token data | Targeted tests pass |
| Retain additional windows and Token statistics | Matching-account background fixtures supplement named windows and Token totals without replacing OAuth quota | Targeted tests pass |
| Preserve original consent without premature execution | Saved account/consent retained while signed out; same-account sign-in resumes; another account cannot inherit | Targeted tests pass |
| Logout, recovery, history and desktop behavior | Late credential results, cached recovery, account-history isolation, existing reminder/Widget/menu/notch cases | Targeted tests pass |
| Full regression and development metadata | Complete Core310 and App105 groups, zero failures; version consistency | Passed (415 cases) |
| Signed installed app and real account | Strict signature; sole sign-in entry; real OAuth source, subscription/card benefits and Token data inspected | Passed |
| Original account and state | Same account; all17 owned preferences, reminder settings and original consent unchanged; post-install card check `checked`; zero redemption requests | Passed |

The user authorized retiring the local sign-in option. Eleven obsolete local-authentication/cache tests were retired, three OAuth-source boundary cases added, and connection tests rewritten around OAuth and migration. Test counts therefore differ from dev.1. No other baseline capability is intentionally removed. A second real account/device and actual card redemption are not claimed; do not use a real card for testing.

The final grouped runs cover all415 cases. A preceding combined run had four macOS-protected file reopen failures; all18 ledger cases and the complete Core group subsequently passed without permission changes. An existing handshake-rejection fixture needed a larger test-only deadline. These failures are retained as environment/test-harness evidence; no single all-target green run is claimed for the final startup adjustment. One startup-order case was added after the initial414-case run.

## Stable release candidate

The sanitized public source passed all415 tests in one run with zero failures. Windows Node24 checks, smoke and UI behavior checks passed; ZIP integrity, ASAR version and package privacy passed. Release consistency, public source/privacy, visible-history forbidden-path and relative-link checks passed. Mac DMG integrity, mounted version, strict Preview Signing signature, package contents and final installation passed. The user completed Keychain confirmation; real same-account OAuth/benefits/Token and all17 preferences, consent and reminder settings were verified. No test redemption. Public main/tag `v0.5.2` and latest Release were verified, with exactly two assets; actual downloads match both local and GitHub SHA-256. All17 preferences, original consent/reminders and history remain; a post-install ordinary card check returned `checked`, with zero redemption requests. [Release evidence](release-evidence.json). Earlier development-run failures above remain recorded.

## Archived dev.1 checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Versions](../../VERSIONS.md)

Status: local `0.5.2-dev.1` installed and running; public stable remains 0.5.1. [Sanitized evidence](repair-evidence.json).

| Requirement | Evidence | Result |
| --- | --- | --- |
| Local date with exact account ownership and provenance | File fixtures: both account IDs, issue time, date, missing/malformed/oversized data, configured home and cache replacement; provider with absent, expired, malformed and unreadable separate credentials | Targeted checks pass |
| Successful quota restores a stuck connection | Fresh/cached refresh and delayed old connection-result regression cases | Targeted checks pass |
| Automatic-use consent resumes and old warning clears only after a card check | Model lifecycle with isolated ledger and non-consuming service; notification identifiers and retained history | Targeted checks pass |
| Same-account isolation and signed-out/cached states | Existing connection switch/race tests and account-metadata tests | Targeted checks pass |
| Bilingual account benefits remain readable | Native minimum-width account panels including dated local record | Rendered and visually inspected |
| Full suite and development metadata | 422 tests, zero failures; version consistency and strict signature | Passed |
| Installed app: real quota, local date, connection and ordinary card check | Dated historical subscription label and source time visible; Connected; a post-install background check returned `checked`; staging/installed binary equality | Passed |
| State retention | All 17 owned preferences and account consent unchanged; local auth cache bytes unchanged; no redemption requests | Passed |

No feature was removed. Separate OAuth, all reminder controls, card eligibility, request/result records, account history, Token usage, menu, Widget, notch and About remain. No real card was redeemed for acceptance. Real second-account switching, additional displays, Windows native UI and live redemption remain outside this incremental verification. A missing/unreadable file or absent claim can still prevent a local date; billing remains authoritative. No new Keychain-storage fix is claimed.

### Archived dev.1 limits (superseded)

Local date support is conditional on a readable matching file record; no new live billing endpoint or local Keychain reader is implemented. Connection-failure recovery is covered by controlled regression tests; installed normal operation and background checking were observed, not a new forced physical network outage. See the retained [baseline audit](../0.5.1/RELEASE_AUDIT.md).

Before a public release, repeat the public-source/package/download audit. No GitHub publication or Windows package was requested or performed here. One existing fixture needed a count guard and a three-second test deadline after an isolated full-run failure; the final full run passed and production timeouts were not changed.
