# 0.7.0 feature retention audit (in progress)

[简体中文](RELEASE_AUDIT.zh-CN.md) · [Version checks](QA.md) · [0.6.0 audit](../0.6.0/RELEASE_AUDIT.md)

These 65 baseline items are a checklist. Pending means the 0.7.0 entry point, behavior and data preservation have not yet been verified; it does not imply a defect or a pass. See the previous audit for historical evidence. This table does not clear the release gate.

2026-11-01: full dev.16 regression passed 326 Core +149 App with zero failures/skips. Rows below distinguish installed-device observations from automated edge coverage. Visible means presentation checked, not every edge/long-running behavior accepted. Unchanged rows still await device checks. The protected consent file initially returned EPERM. After user unlock, readability, original enabled consent and normal checks recovered without consent reset or card consumption. Other untested behavior remains unaccepted. See [current acceptance](QA.md) for status and Windows artifact evidence.

2026-11-03: installed dev.28 follow-up recovered both original connections, confirmed DeepSeek right-edge/details refresh and explicit-only pinning, and observed persistent suppression of the old card incident through two further read interruptions overnight. See [current acceptance and remaining limits](QA.md). Installed DeepSeek notch compact/details, manual refresh and Escape also passed; original display settings were restored. Full regression covered 517 passing tests, including three opt-in visual checks completed separately. This supplements individual rows below and does not clear unrelated device or release gates.


| ID | Capability | 0.7.0 status |
| --- | --- | --- |
| A01 | 5-hour percentage, progress and unknown state | Automated coverage passed; live installed percentage/windows visible; unknown state automated only |
| A02 | 7-day percentage, progress and unknown state | Automated coverage passed; live installed percentage/windows visible; unknown state automated only |
| A03 | Reset countdown and full date/time | QuotaResetCountdownTests passed; installed countdown and full reset date/time visible |
| A04 | Automatic / explicit primary selection; missing stays unknown; persisted choice | Installed dev.20 single-notch selection changed the collapsed display to 7d and was restored; dual order is fixed. Unknown/missing coverage remains automated; dev.22 does not change selection logic. |
| A05 | Ordinary-use eligibility, limit reasons and low-quota status | Partial automated coverage: QuotaModelsTests; device check pending |
| A06 | Source, last success/attempt and diagnostics | QuotaDataDiagnosticsTests passed; installed source, attempt/success times and valid state checked |
| A07 | Manual refresh, busy-state protection and read-only access | QuotaStoreTests passed; installed manual refresh advances success time; re-entry automated only |
| A08 | 1/3/5-minute cadence, local events and wake refresh | RefreshSchedulerTests passed; existing 1-minute setting and repeated refresh checked; wake pending |
| B01 | Plan name and explicit unknown values | Automated coverage passed; installed plan visible; unknown automated only |
| B02 | Subscription validity and historical dates | Automated coverage passed; installed validity date visible; expired state automated only |
| B03 | Billing link when subscription date is missing | Missing-date account scenarios render in MainWindowTests; QuotaCardView uses the fixed official billing-help link. The dev.27 credential-unavailable screen showed the fallback. No missing-date case was forced on the current live account. |
| B04 | Credits number, unlimited and missing remain distinct | Automated coverage passed; installed numeric Credits visible; unlimited/missing automated only |
| B05 | Available resets: zero distinct from unknown | Automated coverage passed; installed count visible; zero/unknown automated only |
| B06 | Each reset expiration, partial missing values and GMT+8 | Automated coverage passed; installed individual dates/GMT+8 visible; partial missing automated only |
| C01 | Local consumption: 24 hours / 7 days / 30 days | Automated coverage passed; installed 24-hour/7/30-day switch and original range restored |
| C02 | Select quota window in history | Automated coverage passed; installed 5-hour/7-day window switch and original selection restored |
| C03 | Quota bar hover/click, interval/point tooltip and boundaries | LocalQuotaUsageChartTests passed. User confirmed dev.28 hover date/value appears and clears on exit. Installed dev.23 click/edge/empty-plot checks remain historical evidence. |
| C04 | Account-isolated history, A→B→A and legacy preservation | Automated: AccountHistoryTests; device check pending |
| C05 | Exclude resets, increases, invalid/missing readings and long gaps | Automated: QuotaUsageAggregationTests; device check pending |
| C06 | Official daily Token chart: 7/30/90-day ranges | Installed dev.28 View → Usage and 7/90-day chart switching passed; the original 30-day selection was restored. UTC/source labels remain visible. |
| C07 | Lifetime Tokens, daily peak and streak | TokenUsageComparisonTests passed; installed three summary metrics visible |
| C08 | Today/yesterday and week comparisons; missing coverage and zero baseline | TokenUsageComparisonTests passed; installed comparisons and insufficient-coverage explanation visible |
| C09 | UTC Token dates, bar details, missing stays unknown and no quota conversion | Installed dev.28 UTC/unit/missing-data text and ranges verified; user confirmed Token-bar hover details appear and disappear. Missing-date semantics remain automated coverage. |
| D01 | Off / 5% / 10% / 20% low-quota options | LowQuotaReminderTests passed; original installed 10% threshold readable; real rules unchanged |
| D02 | Observed crossing, first baseline, account/window/cycle deduplication and retry | Automated: LowQuotaReminderTests; device check pending |
| D03 | Recovery toggle and observed recovery, not clock-only | QuotaRecoveryReminderTests passed. Installed original toggle retained; live history includes a recovery notification later recorded withdrawn. Not every cycle/state transition was forced. |
| D04 | Recovery withdrawal after consumption, cancellation and restart deduplication | QuotaRecoveryReminderTests passed; installed live recovery history contains withdrawn entries, including after same-bundle restart. Every cancellation/restart edge remains automated coverage. |
| D05 | Reset-expiration reminders at72/48/24/12 hours | QuotaReminderTests passed; all four existing nodes retained; actual expiration pending |
| D06 | Alert on observed Credits consumption after exhaustion | Partial automated coverage: QuotaReminderTests; device check pending |
| D07 | Actual notification permission/style and system settings link | NotificationReadinessTests passed; installed persistent style and system entry visible |
| D08 | Test notification, delivery state and Notification Center verification | Installed dev.28 explicit test reported Center verified; the user confirmed visibility in Notification Center. Permission/style entry retained. Focus/sleep delivery branches remain environment-dependent. |
| D09 | History summary/full list and persisted delivery/failure/withdrawal states | Automated coverage passed; installed delivered/withdrawn history readable; failure branch automated only |
| E01 | Adaptive floating Widget: capsule and slim edge forms | Current shape is the user-approved capsule and slim edge strip. Native synthetic captures plus installed dev.28 right edge/details passed; free placement and all drag combinations were not repeated on this package. |
| E02 | Both edges, first direct inward drag and frame persistence | Both-edge first-inward-drag checks remain dev.23 evidence. Dev.28 same-bundle restart retained the original right edge and saved frame exactly, without dragging/resetting. |
| E03 | Hover/ordinary-click preview, explicit-button pin; unpin restores preview and Escape | The user approved button-only pinning in dev.25. Installed dev.26/dev.28 checks cover both service previews and pin/unpin; dev.28 DeepSeek content clicks and refresh retain pinning. Outside-click/Escape have native regression coverage; complete pointer entry/exit on the current package remains a device check. |
| E04 | Both quotas and last-hour chart with5-minute bars | Automated coverage passed; installed dual quotas and one-hour/five-minute-bin chart/explanation visible |
| E05 | Card title drag, independent buttons and saved position | FloatingWidgetDragTests passed. User confirmed installed dev.23 title dragging; native Refresh busy/completion and Close/recovery controls checked. Pre-check preferences restored exactly; saved position across restart remains pending. |
| E06 | Minimal / detailed card modes | Live dev.21 minimal/detailed card switching and actual rendered fields passed; each mode retains both quotas. See the dev.22 acceptance follow-up. |
| E07 | Show/hide, restart persistence and recovery entry | Dev.28 widget/notch mutual exclusion and original widget-on/notch-off restoration passed. Same-bundle restart retained visibility and saved position. Abnormal-start/snooze cases retain separate limits. |
| E08 | Always-on-top independent from pinning and movement | Pending verification |
| E09 | Snooze30/60 minutes, deadline and immediate resume | Live dev.21 30/60-minute snooze displayed the corresponding deadlines; immediate resume cleared snooze. Actual deadline expiry/restart remains pending. |
| E10 | Reset position and recover invalid/offscreen geometry | Automated: FloatingWidgetPlacementTests; device check pending |
| E11 | Hide in fullscreen / restore and existing Spaces policy | WidgetSpaceBehaviorTests passed. User confirmed installed dev.23 capsule hides during same-display ordinary-app fullscreen and returns on exit. Multiple displays/separate Spaces and notch behavior remain pending. |
| E12 | Notch visibility/availability, physical attachment and click-only expansion | Installed physical notch attachment/dual rows were observed; user confirmed capsule-to-notch in dev.18 and downward detachment in dev.21. Other displays/fullscreen remain pending. |
| E13 | Notch selection, unknown state, details, open Overview and outside/Escape dismiss | Installed dev.20 dual details have no redundant picker; single 7d selection, opening Overview and Escape were checked. Unknown states automated; dev.22 does not change this path. |
| F01 | Status item, both quotas/reset and account summary | User confirmed dev.28 current Codex menu-bar quota/account summary is complete. DeepSeek menu content has synthetic evidence; current live DeepSeek popover not separately confirmed. |
| F02 | Menu diagnostics, refresh and open main window | User confirmed dev.28 menu refresh and open-main action work. Automated refresh/data-state boundaries remain covered by existing tests. |
| F03 | Menu Widget toggle and reminder entry | Original widget-on state retained; menu visibility/reminder routes have partial automated coverage. Optional toggle/reminder-route actions were not separately confirmed in the user report. |
| F04 | More menu: Display / Connection / General / About / Quit | Pending verification |
| G01 | OAuth-only connection and matching-account background capabilities | Automated coverage passed; installed original OAuth session refreshes; no new authorization |
| G02 | Connect, cancel authorization, replace sign-in and disconnect | Partial automated coverage: CodexOAuthTests; device check pending |
| G03 | Automatic browser callback and manual callback-URL fallback | Automated: CodexOAuthTests; device check pending |
| G04 | User-initiated Keychain retry without forced re-login | Installed dev.28 explicit retries recovered both original connections after normal Keychain authorization; same-bundle restart retained both connections without new credential entry. |
| G05 | OAuth-only connection and matching-account background capabilities | Partial automated coverage: CodexOAuthQuotaProviderTests; device check pending |
| G06 | Disconnect preserves unrelated credentials and account history | Partial automated coverage: AccountHistoryTests; device check pending |
| H01 | Bilingual UI/native menus and persisted language | Installed dev.28 English UI/native menu synchronization and English persistence after normal quit/relaunch passed; returned to Chinese with exact preference comparison. |
| H02 | Launch-at-login toggle, installation diagnostics and approval entry | Installed dev.28 reports Enabled by macOS at the fixed Applications path; login-start switch unchanged. Actual OS login/reboot launch remains pending. |
| H03 | Automatic/manual update checks, prompt/dismiss and download link | Live dev.21 manual check completed with up-to-date state. Update-available/download/dismiss remain automated-only; no new release was exposed. |
| H04 | Persistent About, version, highlights, full notes and product information | Installed dev.23 Chinese/English default-size icon, title, version, four highlight groups, notes link and footer checked. Native default/minimum scroll tests passed; installed minimum-size resizing was not separately checked. See current QA evidence; this clears the observed English clipping issue only. |
| H05 | Close window keeps running, reopen and explicit quit | Installed dev.28 normal quit was confirmed, same bundle relaunched successfully, and final main-window close left the capsule running. |
| H06 | Native fullscreen shortcut, View navigation and Escape behavior | MainMenuTests passed. Installed dev.23 View → Notification History and Control–Command–F enter/exit checked. Native-menu Escape remains unconfirmed; Cancel action used to dismiss. |
| I01 | Preserve preferences, frames, connection mode, thresholds and history backups | Dev.28 final comparison exactly matched 13 tracked language/selection/display/saved-frame preferences. Original reminder/card consent remains enabled; no credential/history removal. |
| I02 | Serialized Keychain access, no hidden prompts or weakened access control | Automated coverage passed; original credentials usable; protected card-file EPERM safely pauses, unlock recovers; no access weakening |
| I03 | Same-account stale cache/original timestamp; no cross-account reuse or fresh alerts | Automated: QuotaStoreTests; device check pending |
| I04 | Late reads cannot override a new connection or block/clear its refresh | Partial automated evidence: ConnectionReloadTests cover late credential failure/read and sign-out ownership; DeepSeek tests cover identity change and failed/rejected replacement. All concurrent/new-connection cases have not been separately accepted on-device. |

## dev.14 navigation mapping (2026-10-31)

| Previous task | Current entry | State and verification boundary |
| --- | --- | --- |
| Settings → Connection: Codex | Same path, select Codex; overview shortcut | Original OAuth login/cancel/callback/replace/sign-out/recovery controls and regression tests. |
| DeepSeek connection | Overview tab → Connect; Settings → Connection → DeepSeek | Same connection object, Keychain service/item and connection ID. Synthetic success/failure/cancel verified; explicit retry permits system authorization. |
| Settings → Reminders | Same path, select Codex / DeepSeek | Existing rules, thresholds, expiry nodes, automatic-card and receipt components/stores reused; synthetic DeepSeek rule reads consistently across entries. |
| Settings → Display | Same path | Quota-window, Widget, notch, topmost, fullscreen and existing controls retained; browsing platforms does not change fixed-display preferences. |
| Settings → General | Same path | Existing language, launch, refresh, update and notifications; no launch-at-login change this pass. |
| Card rules/notification/Widget shortcuts | Settings → Reminders / Codex; recovery routes to Connection | Navigation tests verify rules and automatic-card consent are unchanged; live operations and long-running delivery need separate acceptance. |

This mapping does not mark pending entries in the 65-item checklist as passed. See [version checks](QA.md) for native evidence and release blockers.

dev.15 only adds Connection/Reminder platform marks and changes section display order. State, shortcut and return checks are recorded in [version checks](QA.md). Existing stores and automatic-card consent are unchanged.
