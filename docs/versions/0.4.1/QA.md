# 0.4.1 black-box checks

[中文](QA.zh-CN.md) · [Scope](PLAN.md)

| Requirement | Evidence/status |
| --- | --- |
| One reminder per milestone | Synthetic accepted-but-unverified, dismissed/restarted, existing Notification Center request and overlapping delivery tests added. |
| No suppression of later alerts | Same card at 24 hours remains eligible after its 48-hour reminder; existing 12/24/48/72 threshold tests retained. |
| Safe retry | Explicit add rejection still retries; OS acceptance is not falsely reported as verified delivery. |
| Account/lifecycle | Receipt IDs scoped to account; A→unknown→A preserves markers without exposing old details; switching to B clears A markers. |
| Existing features | Recovery, low quota, Credits and confirmed-use notices unchanged; existing regression retained. |
| Validation | All 380 Swift tests pass. Bilingual synthetic history rendering inspected; signed local installation and two successful real refreshes verified. |

Old optional-field-free history remains decodable. Missing old account ownership is not invented. Testing uses synthetic notification clients, not real card redemption. Local development preview; public stable remains 0.4.0.

Installed acceptance: 0.4.1-dev.1 is running from the normal application location. Its installed executable matches the signed development bundle; strict signature validation passed. After the user completed macOS Keychain confirmation, actual quota/account readings recovered. Two manual refreshes completed successfully, and each read-only comparison against the pre-install reminder history showed unchanged expiry-reminder attempt counts, last-attempt times and statuses. Existing reminder and automatic-use switches remain On; the automatic-use authorization file is byte-for-byte unchanged. No real reset card was redeemed for testing.

The screenshots above use synthetic data. Private account readings, receipt IDs and local baselines are excluded from this evidence. Restart/dismissal, delayed verification and account transitions are automated scenarios; the installed real check covers credential recovery and refreshes, not a new real expiry event or every device/platform. This paragraph records the local development acceptance; final publication status is below.

[Feature-retention delta / 功能保留增量审计](RELEASE_AUDIT.md)

Release preparation / 发布准备：0.4.1 metadata and bilingual About targeted checks: 10 passed, plus an exported bilingual About render check passed. 65-capability delta audit retained; public-source, artifact and remote delivery checks remain pending.

Release checks: public-source 380 Swift tests pass, zero failures; Windows check/smoke/UI-smoke and ZIP/ASAR validation pass. Mounted DMG version 0.4.1, strict stable preview signature, forbidden-file scan and two-artifact directory invariant pass. 302 documentation links checked; public main history contains no matching internal collaboration paths. Public push/download and final installation checks are pending.

Final delivery: [v0.4.1](https://github.com/whnnick/readycheck/releases/tag/v0.4.1) is public, non-draft, non-prerelease and latest. Remote main/tag point to the verified source release. Both assets were actually downloaded and their SHA256 matches local packages and GitHub digests. The redesigned live GitHub homepage was visually checked. Final installed0.4.1 matches the mounted DMG executable and passes strict signature verification; restoring live data awaits the user’s macOS Keychain confirmation. Existing authorization bytes remain unchanged.
