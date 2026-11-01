# 0.7.0 feature retention audit (in progress)

[简体中文](RELEASE_AUDIT.zh-CN.md) · [Version checks](QA.md) · [0.6.0 audit](../0.6.0/RELEASE_AUDIT.md)

These 65 baseline items are a checklist. Pending means the 0.7.0 entry point, behavior and data preservation have not yet been verified; it does not imply a defect or a pass. See the previous audit for historical evidence. This table does not clear the release gate.

2026-11-01: full dev.16 regression passed 326 Core +149 App with zero failures/skips. Rows below distinguish installed-device observations from automated edge coverage. Visible means presentation checked, not every edge/long-running behavior accepted. Unchanged rows still await device checks. The protected consent file initially returned EPERM. After user unlock, readability, original enabled consent and normal checks recovered without consent reset or card consumption. Other untested behavior remains unaccepted. See [current acceptance](QA.md) for status and Windows artifact evidence.

| ID | Capability | 0.7.0 status |
| --- | --- | --- |
| A01 | 5-hour percentage, progress and unknown state | Automated coverage passed; live installed percentage/windows visible; unknown state automated only |
| A02 | 7-day percentage, progress and unknown state | Automated coverage passed; live installed percentage/windows visible; unknown state automated only |
| A03 | Reset countdown and full date/time | QuotaResetCountdownTests passed; installed countdown and full reset date/time visible |
| A04 | Automatic / explicit primary selection; missing stays unknown; persisted choice | Automated: NotchQuotaSelectionTests; device check pending |
| A05 | Ordinary-use eligibility, limit reasons and low-quota status | Partial automated coverage: QuotaModelsTests; device check pending |
| A06 | Source, last success/attempt and diagnostics | QuotaDataDiagnosticsTests passed; installed source, attempt/success times and valid state checked |
| A07 | Manual refresh, busy-state protection and read-only access | QuotaStoreTests passed; installed manual refresh advances success time; re-entry automated only |
| A08 | 1/3/5-minute cadence, local events and wake refresh | RefreshSchedulerTests passed; existing 1-minute setting and repeated refresh checked; wake pending |
| B01 | Plan name and explicit unknown values | Automated coverage passed; installed plan visible; unknown automated only |
| B02 | Subscription validity and historical dates | Automated coverage passed; installed validity date visible; expired state automated only |
| B03 | Billing link when subscription date is missing | Pending verification |
| B04 | Credits number, unlimited and missing remain distinct | Automated coverage passed; installed numeric Credits visible; unlimited/missing automated only |
| B05 | Available resets: zero distinct from unknown | Automated coverage passed; installed count visible; zero/unknown automated only |
| B06 | Each reset expiration, partial missing values and GMT+8 | Automated coverage passed; installed individual dates/GMT+8 visible; partial missing automated only |
| C01 | Local consumption: 24 hours / 7 days / 30 days | Automated coverage passed; installed 24-hour/7/30-day switch and original range restored |
| C02 | Select quota window in history | Automated coverage passed; installed 5-hour/7-day window switch and original selection restored |
| C03 | Quota bar hover/click, interval/point tooltip and boundaries | Automated: LocalQuotaUsageChartTests; device check pending |
| C04 | Account-isolated history, A→B→A and legacy preservation | Automated: AccountHistoryTests; device check pending |
| C05 | Exclude resets, increases, invalid/missing readings and long gaps | Automated: QuotaUsageAggregationTests; device check pending |
| C06 | Official daily Token chart: 7/30/90-day ranges | Installed 7/30/90-day switches/readback passed; original range restored |
| C07 | Lifetime Tokens, daily peak and streak | TokenUsageComparisonTests passed; installed three summary metrics visible |
| C08 | Today/yesterday and week comparisons; missing coverage and zero baseline | TokenUsageComparisonTests passed; installed comparisons and insufficient-coverage explanation visible |
| C09 | UTC Token dates, bar details, missing stays unknown and no quota conversion | Installed UTC/unit/missing-data explanations and chart visible; bar interaction pending |
| D01 | Off / 5% / 10% / 20% low-quota options | LowQuotaReminderTests passed; original installed 10% threshold readable; real rules unchanged |
| D02 | Observed crossing, first baseline, account/window/cycle deduplication and retry | Automated: LowQuotaReminderTests; device check pending |
| D03 | Recovery toggle and observed recovery, not clock-only | QuotaRecoveryReminderTests passed; existing enabled state readable; live cycle pending |
| D04 | Recovery withdrawal after consumption, cancellation and restart deduplication | Automated: QuotaRecoveryReminderTests; device check pending |
| D05 | Reset-expiration reminders at72/48/24/12 hours | QuotaReminderTests passed; all four existing nodes retained; actual expiration pending |
| D06 | Alert on observed Credits consumption after exhaustion | Partial automated coverage: QuotaReminderTests; device check pending |
| D07 | Actual notification permission/style and system settings link | NotificationReadinessTests passed; installed persistent style and system entry visible |
| D08 | Test notification, delivery state and Notification Center verification | QuotaNotificationServiceTests passed; installed test reports Notification Center verified; banner unconfirmed |
| D09 | History summary/full list and persisted delivery/failure/withdrawal states | Automated coverage passed; installed delivered/withdrawn history readable; failure branch automated only |
| E01 | Adaptive floating Widget: bubble and slim edge forms | Automated: EdgeRailWidgetTests; style selector checked in isolated UI; actual dragging pending |
| E02 | Both edges, first direct inward drag and frame persistence | Automated: BubbleWidgetPlacementTests; device check pending |
| E03 | Hover preview, click pin, outside retention, unpin and Escape | Automated coverage passed; installed click-pin, main-window focus changes, unpin/Escape checked; hover pending |
| E04 | Both quotas and last-hour chart with5-minute bars | Automated coverage passed; installed dual quotas and one-hour/five-minute-bin chart/explanation visible |
| E05 | Card title drag, independent buttons and saved position | Partial automated coverage: FloatingWidgetDragTests; device check pending |
| E06 | Minimal / detailed card modes | Partial automated coverage: BubbleQuotaDisplayTests; card selector checked in isolated UI; installed build pending |
| E07 | Show/hide, restart persistence and recovery entry | Automated: WidgetVisibilityLifecycleTests; visibility toggle checked in isolated UI; installed build pending |
| E08 | Always-on-top independent from pinning and movement | Pending verification |
| E09 | Snooze30/60 minutes, deadline and immediate resume | Automated: WidgetSnoozePreferenceTests; device check pending |
| E10 | Reset position and recover invalid/offscreen geometry | Automated: FloatingWidgetPlacementTests; device check pending |
| E11 | Hide in fullscreen / restore and existing Spaces policy | Automated: WidgetSpaceBehaviorTests; device check pending |
| E12 | Notch visibility/availability, physical attachment and click-only expansion | Automated: NotchWindowControllerTests; device check pending |
| E13 | Notch selection, unknown state, details, open Overview and outside/Escape dismiss | Automated: NotchQuotaSelectionTests; device check pending |
| F01 | Status item, both quotas/reset and account summary | Automated: MenuBarQuotaLabelTests; device check pending |
| F02 | Menu diagnostics, refresh and open main window | Partial automated coverage: MenuBarQuotaLabelTests; device check pending |
| F03 | Menu Widget toggle and reminder entry | Partial automated coverage: WidgetVisibilityPreferenceTests; device check pending |
| F04 | More menu: Display / Connection / General / About / Quit | Pending verification |
| G01 | OAuth-only connection and matching-account background capabilities | Automated coverage passed; installed original OAuth session refreshes; no new authorization |
| G02 | Connect, cancel authorization, replace sign-in and disconnect | Partial automated coverage: CodexOAuthTests; device check pending |
| G03 | Automatic browser callback and manual callback-URL fallback | Automated: CodexOAuthTests; device check pending |
| G04 | User-initiated Keychain retry without forced re-login | ConnectionRecoveryActionTests passed; normal dev.16 retry recovered existing OAuth/API connections |
| G05 | OAuth-only connection and matching-account background capabilities | Partial automated coverage: CodexOAuthQuotaProviderTests; device check pending |
| G06 | Disconnect preserves unrelated credentials and account history | Partial automated coverage: AccountHistoryTests; device check pending |
| H01 | Bilingual UI/native menus and persisted language | Automated: LocalizationServiceTests; bilingual switch checked in isolated native UI; installed build pending |
| H02 | Launch-at-login toggle, installation diagnostics and approval entry | Automated coverage passed; fixed Applications bundle retains enabled login-start state; restart pending |
| H03 | Automatic/manual update checks, prompt/dismiss and download link | Automated: UpdateCheckerTests; device check pending |
| H04 | Persistent About, version, highlights, full notes and product information | Partial automated coverage: MainWindowTests; device check pending |
| H05 | Close window keeps running, reopen and explicit quit | Old process exited and fixed-path new app launched; main-window close keeps app alive, ⌘1 reopens |
| H06 | Native fullscreen shortcut, View navigation and Escape behavior | Automated: MainMenuTests; device check pending |
| I01 | Preserve preferences, frames, connection mode, thresholds and history backups | Preferences/history retained; restored platform matches preference snapshot; original automatic-use consent and normal checks recovered after unlock |
| I02 | Serialized Keychain access, no hidden prompts or weakened access control | Automated coverage passed; original credentials usable; protected card-file EPERM safely pauses, unlock recovers; no access weakening |
| I03 | Same-account stale cache/original timestamp; no cross-account reuse or fresh alerts | Automated: QuotaStoreTests; device check pending |
| I04 | Late reads cannot override a new connection or block/clear its refresh | Pending verification |

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
