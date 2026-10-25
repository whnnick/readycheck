# 0.5.1 black-box checks

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Retained baseline](../0.5.0/RELEASE_AUDIT.md)

## Published verification

v0.5.1 is published as the latest non-draft, non-prerelease release at public code commit13041d5. Both Mac DMG and Windows ZIP were actually re-downloaded; each SHA-256 matches its locally verified package and GitHub digest. [Release](https://github.com/whnnick/readycheck/releases/tag/v0.5.1). Installed reading and retained-state acceptance above use the final DMG, not an intermediate development build.

## 0.5.1 release candidate

[Release notes](RELEASE_NOTES.md) · [65-feature delta audit](RELEASE_AUDIT.md).

The local-subscription investigation reproduced two failures in a synthetic cross-account test: a different sign-in token could supply a plan/date to the local account. The repair requires the existing strict account match before supplementing either field. The same-account path remains; missing local dates retain a billing link and explicit source explanation, without labeling sign-in expired. No real credential was read or account switched for this regression. Actual subscription-date availability is not guaranteed when neither source provides it; no cached-date freshness claim.

Formal-source tests, current synthetic screenshots, package/signature and public-source/download acceptance are pending and will be recorded separately. Prior development evidence below remains scoped to its original build.


### Formal development source

411 complete Swift tests passed,0 failures. After improving the native screenshot harness to yield asynchronously for real view/animation updates, the full bilingual shared-surface scenario passed again. The prior18 scoped cases cover About, benefits, navigation, integration and native rendering; public-source validation will re-run the final harness. Selected8 current-version screenshots use synthetic data and the real icon, are visually reviewed, and replace old UI proof in the bilingual README. The cross-account date/plan case now passes; local-source missing dates remain explicitly unknown. Strict candidate Preview signing and release metadata pass. Public build, packages, upload and final installed acceptance remain pending.

### Public source, packages and installation

Final public source passes411 Swift tests,0 failures in173.3 seconds. Windows check/smoke/UI-smoke, ZIP integrity and ASAR version/internal-file inspection pass. The mounted DMG is0.5.1 with a strict ReadyCheck Preview Signing signature; bundle contents and both-package directory invariants pass. [Structured release evidence](release-verification.json).

Installed from the final public DMG into Applications after preserving the old app. Live quota/card reading, the local subscription-date explanation and About highlights were checked. Original17 owned preferences, local source, account consent and attempt ledger compare unchanged; recovery/expiry/automatic-use On,10% threshold and all four milestones remain. No real card spent or source switched. The local source still does not supply a subscription date; the billing link/source explanation is an explicit limit, not a fixed upstream-data guarantee. Remote publication and downloaded digests are verified separately after upload.

## Dev.6 presentation and retention

[Contract and retention map](DESIGN_IMPLEMENTATION.md) · [Structured evidence](design-retention-evidence.json).

Full Swift regression passed410 tests,0 failures in157.5 seconds. After final first-use-default wording clarification and whitespace cleanup,11 affected native/state/integration/navigation/version checks passed again. Native synthetic rendering covers24 minimum740×620 cases: Overview, Token empty state and all four settings sections, both languages and light/dark. Existing populated Token, both source, account benefits, chart inspection, menu, Widget and unknown-authorization render scenarios also ran. Images were inspected individually and/or in contact sheets; the fixture folder icon is not a product artwork defect. These are native render checks, not a browser inspector or65 new real-device tests.

The final strictly Preview-signed local dev.6 bundle is running. Real quota and card details recovered without a new credential confirmation. Actual checks verified complete benefits/Credits/card dates below the chart, preserved historical gaps and recovered checks, one-click pace explanation and Escape, Data status and Escape, card detail and Escape, and Token7→30-day selection with unchanged account summary. An initially stale card-detail state remained distinct from healthy quota and subsequently returned a fresh card-detail timestamp; no synthetic state was described as a real outage. Original17 owned preferences, local source, account consent and attempt ledger compare unchanged; automatic use remains On. No card redeemed or account switched for acceptance. Device interaction was Chinese/dark; bilingual/light states are native fixtures. Real screenshots and state baselines remain private.

Development metadata, strict signature, local links, sensitive-pattern and diff checks pass. Only Views, localized copy/version and related tests/metadata changed; authentication, notification execution/deduplication, card execution and storage schemas did not. No new physical-notch, extra-display, prolonged-offline or real-redemption claim. Windows metadata only. Local commits; no push/release and stable remains0.5.0.


## Dev.5 transient card-check warnings

Three new regressions reproduced11 failing assertions: first-failure notification submission, a read-failure streak spanning a long gap/clock reversal, and healthy quota being routed to connection settings. Notification threshold/immediate-critical-warning checks, model recovery cleanup, retained consent/no redemption, and the shared card-check route now pass within isolated fixtures. Bilingual native Overview, menu and Widget card-check explanations were inspected. [Structured evidence](check-warning-evidence.json).

The earlier unblocked scoped run passed29 tests while explicitly retaining two protected-file gates. After the user's system lock/unlock, both protected cases passed without weakening file protection. A full-suite attempt stopped in an existing one-second fake-process candidate test with an array-bounds trap; that case passed in isolation, and the complete retry passed409 tests,0 failures. The final neutral, past-tense recovered-history presentation was subsequently checked on device and with the affected scoped regressions. Development metadata, privacy, local links and diff checks pass.

The final strictly Preview-signed local dev.5 bundle is running. Native quota/card reading and scheduled successful checks recovered; the existing local source,17 owned preferences, automatic-use On consent, reminder switches/four milestones and attempt ledger remain unchanged. The original historical gaps and check rows remain, and actual recovered failures use neutral past-tense text with the later recovery explanation. No real card was spent and no account was switched for acceptance. Only account-matched recovered service warnings are removed by the notification client; isolation tests verify the exact pending/delivered identifiers and retained unrelated notices. Actual macOS banner withdrawal was not independently observed, and no real network outage or redemption was induced. Windows receives metadata only. No public push/release; stable remains0.5.0.

## Dev.4 connection hierarchy

[Evidence](connection-hierarchy-evidence.json):23 scoped Swift regressions pass, covering connection race/wake handling, bilingual account rendering, retained card history/navigation and integration, and version consistency. Eight synthetic740×760 native cases cover both sources and languages with connected/recovery states. Existing source and card-use consent remain unchanged during rendering. Dark account-panel layouts were inspected; fixture app icons are not release artwork.

Real dev.4 interaction: Other connection methods expands/collapses; the saved separate source, account and applicable Retry/Disconnect remain outside it. After user Keychain approval, live reading recovered. The original17 owned preferences, account consent and attempt ledger compare unchanged. Recovery and card-expiry reminders, all four milestones, the10% threshold and automatic use On remain visible. No real card spent, account switch, disconnect or new sign-in for acceptance. Existing source-switch logic was not changed; real local-source switching, light appearance and a new full-suite run are not claimed. Dev.3's402 full tests retain their earlier scope. Strict Preview signing and development metadata pass. Local bundle only; public stable remains0.5.0 without push/release.

## Earlier card-detail checks

Dev.2 removes the detail footer button at the user’s request. The dev.1 navigation evidence below is historical; the shared next-event route remains. Final simplification checks are recorded at the end.

| Requirement | Evidence | State |
| --- | --- | --- |
| Explicit card-settings destination | Original device click opened the reminder page, not the specific group; new regression reproduced retained card selection on the shared route | Verified repair |
| Dismiss detail and repeat navigation | Shared route clears selection and issues a new transient request; no consent mutation | 2 targeted cases pass |
| Native scroll position | Chinese/English740×620 host, both same-page and cross-page requests | Passed within stated scope |
| Installed interaction / retained settings | Live clicks from Overview and reminder records; original rules/account consent retained | Passed within stated scope |
| Regression / version / signing | Appropriate tests, development consistency and stable Preview bundle | Passed within stated scope |

No published release, real card redemption, Windows feature port, full hardware or65-item direct-device claim. The previously unresolved historical card remains unconfirmed. Scope is navigation only.

## Completion evidence

[Structured evidence](implementation-evidence.json). A failing assertion first reproduced retained card selection on the shared rules route; both targeted navigation cases pass after repair. Chinese/English740×620 native hosts verify same/cross-page scrolling and request consumption. Final full regression:400 tests,0 failures. Development metadata and strict stable Preview signing pass.

Actual clicks from Overview historical-card details and reminder-page record details close the sheet and reveal card settings, including repeated navigation. Live reading recovered after user Keychain approval; original preferences, account consent and attempt ledger compare unchanged. No real card consumed. Real screenshots stay private locally. A local development bundle is running; installed stable/public GitHub remain0.5.0, without push/publication. Other paths reuse0.5.0 retention evidence and its limits.

## Dev.2 detail simplification

[Evidence](detail-simplification-evidence.json):4 existing targeted cases pass (bilingual native details, retained same/cross-page route and version). Strict stable Preview signature and development consistency pass; local bundle launched. After user Keychain approval, live reading recovered. Real card facts, outcome and notification sections remain; the footer settings button is absent and the480-point sheet was visually inspected. Close and Escape return to Overview; original preferences, consent and attempt ledger compare unchanged. No new mirror tests and no public release.

## Dev.3 historical gap classification

Regression first reproduced reminder-only records taking priority over reset, genuine unresolved requests and pending success notifications. [Evidence](history-classification-evidence.json): final full402 Swift tests pass,0 failures. New cases retain real unresolved statuses and pending success notices while excluding historical reminders. Chinese/English native historical details were visually checked; current authorization is omitted and the outcome stays unknown. Metadata, strict Preview signature and local launch pass. After user Keychain approval, live reading recovered. Overview no longer shows the old reminder as a current card failure; the history row remains Historical record incomplete and opens Historical expiry reminder, without current authorization text or an invented outcome. Close works. Original preferences, account consent and attempt ledger compare unchanged; the real automatic check advanced after approval. Real screenshots remain private. No real redemption or public release. Existing dev.1/dev.2 evidence keeps its historical scope. The card’s past use/expiry remains unknown; no data deletion or real redemption is allowed for acceptance.
