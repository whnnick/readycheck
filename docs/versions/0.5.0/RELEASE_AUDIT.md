# 0.5.0 feature-retention delta audit

[中文](RELEASE_AUDIT.zh-CN.md) · [Checks](QA.md) · [Frozen baseline](../0.3.0/FEATURE_RETENTION.md)

Retain all65 baseline items; this is not65 direct device passes. The398 full regression tests support existing paths; unchanged capabilities reuse0.4.2 evidence and its limits. Changes focus onA06 diagnostics,D05 milestones,H04 About highlights andI01 selection persistence. Other entries are not removed. Real consent bytes and reminder history were checked. “Baseline path retained” is a delta-review conclusion, not special-device acceptance.

| ID | Capability | Original entry | Current scope |
| --- | --- | --- | --- |
| A01 | 5-hour percentage, progress and unknown state | Overview / desktop / menu | Baseline path retained; existing limits apply |
| A02 | 7-day percentage, progress and unknown state | Overview / desktop / menu | Baseline path retained; existing limits apply |
| A03 | Reset countdown and full date/time | Overview / compact rows | Baseline path retained; existing limits apply |
| A04 | Automatic / explicit primary selection; missing stays unknown; persisted choice | Settings → Display / notch details | Baseline path retained; existing limits apply |
| A05 | Ordinary-use eligibility, limit reasons and low-quota status | Overview / compact surfaces | Baseline path retained; existing limits apply |
| A06 | Source, last success/attempt and diagnostics | Data status popover | Changed behavior verified within QA scope; release-package checks tracked separately |
| A07 | Manual refresh, busy-state protection and read-only access | Refresh controls | Baseline path retained; existing limits apply |
| A08 | 1/3/5-minute cadence, local events and wake refresh | Settings → General / lifecycle | Baseline path retained; existing limits apply |
| B01 | Plan name and explicit unknown values | Overview → Account & benefits | Baseline path retained; existing limits apply |
| B02 | Subscription validity and historical dates | Overview → Account & benefits | Baseline path retained; existing limits apply |
| B03 | Billing link when subscription date is missing | Overview → Account & benefits | Baseline path retained; existing limits apply |
| B04 | Credits number, unlimited and missing remain distinct | Overview → Account & benefits | Baseline path retained; existing limits apply |
| B05 | Available resets: zero distinct from unknown | Overview → Account & benefits | Baseline path retained; existing limits apply |
| B06 | Each reset expiration, partial missing values and GMT+8 | Overview → Account & benefits | Baseline path retained; existing limits apply |
| C01 | Local consumption: 24 hours / 7 days / 30 days | Overview → Consumption | Baseline path retained; existing limits apply |
| C02 | Select quota window in history | Overview → Consumption | Baseline path retained; existing limits apply |
| C03 | Quota bar hover/click, interval/point tooltip and boundaries | Overview → Consumption | Baseline path retained; existing limits apply |
| C04 | Account-isolated history, A→B→A and legacy preservation | Overview / history storage | Baseline path retained; existing limits apply |
| C05 | Exclude resets, increases, invalid/missing readings and long gaps | Aggregation / Widget chart | Baseline path retained; existing limits apply |
| C06 | Official daily Token chart: 7/30/90-day ranges | Token usage page | Baseline path retained; existing limits apply |
| C07 | Lifetime Tokens, daily peak and streak | Token usage page | Baseline path retained; existing limits apply |
| C08 | Today/yesterday and week comparisons; missing coverage and zero baseline | Token usage page | Baseline path retained; existing limits apply |
| C09 | UTC Token dates, bar details, missing stays unknown and no quota conversion | Token usage page | Baseline path retained; existing limits apply |
| D01 | Off / 5% / 10% / 20% low-quota options | Settings → Reminders | Baseline path retained; existing limits apply |
| D02 | Observed crossing, first baseline, account/window/cycle deduplication and retry | Low-quota evaluator / notifications | Baseline path retained; existing limits apply |
| D03 | Recovery toggle and observed recovery, not clock-only | Settings → Reminders / recovery | Baseline path retained; existing limits apply |
| D04 | Recovery withdrawal after consumption, cancellation and restart deduplication | Notification service / history | Baseline path retained; existing limits apply |
| D05 | Reset-expiration reminders at72/48/24/12 hours | Background reminders / history | Changed behavior verified within QA scope; release-package checks tracked separately |
| D06 | Alert on observed Credits consumption after exhaustion | Background reminders / history | Baseline path retained; existing limits apply |
| D07 | Actual notification permission/style and system settings link | Settings → Reminders | Baseline path retained; existing limits apply |
| D08 | Test notification, delivery state and Notification Center verification | Settings → Reminders | Baseline path retained; existing limits apply |
| D09 | History summary/full list and persisted delivery/failure/withdrawal states | Settings → Reminders → History | Baseline path retained; existing limits apply |
| E01 | Adaptive floating Widget: bubble and slim edge forms | Desktop / Settings → Display | Baseline path retained; existing limits apply |
| E02 | Both edges, first direct inward drag and frame persistence | Floating Widget | Baseline path retained; existing limits apply |
| E03 | Hover preview, click pin, outside retention, unpin and Escape | Widget details | Baseline path retained; existing limits apply |
| E04 | Both quotas and last-hour chart with5-minute bars | Widget details | Baseline path retained; existing limits apply |
| E05 | Card title drag, independent buttons and saved position | Information card | Baseline path retained; existing limits apply |
| E06 | Minimal / detailed card modes | Settings → Display / card switcher | Baseline path retained; existing limits apply |
| E07 | Show/hide, restart persistence and recovery entry | Settings / menu / Widget context menu | Baseline path retained; existing limits apply |
| E08 | Always-on-top independent from pinning and movement | Settings → Display | Baseline path retained; existing limits apply |
| E09 | Snooze30/60 minutes, deadline and immediate resume | Settings → Display / desktop controls | Baseline path retained; existing limits apply |
| E10 | Reset position and recover invalid/offscreen geometry | Settings → Display | Baseline path retained; existing limits apply |
| E11 | Hide in fullscreen / restore and existing Spaces policy | Settings → Display / window policy | Baseline path retained; existing limits apply |
| E12 | Notch visibility/availability, physical attachment and click-only expansion | Settings → Display / notch | Baseline path retained; existing limits apply |
| E13 | Notch selection, unknown state, details, open Overview and outside/Escape dismiss | Notch details | Baseline path retained; existing limits apply |
| F01 | Status item, both quotas/reset and account summary | Menu bar | Baseline path retained; existing limits apply |
| F02 | Menu diagnostics, refresh and open main window | Menu bar | Baseline path retained; existing limits apply |
| F03 | Menu Widget toggle and reminder entry | Menu bar | Baseline path retained; existing limits apply |
| F04 | More menu: Display / Connection / General / About / Quit | Menu → More | Baseline path retained; existing limits apply |
| G01 | Follow local Codex / standalone OAuth and current identity | Settings → Connection | Baseline path retained; existing limits apply |
| G02 | Connect, cancel authorization, replace sign-in and disconnect | Settings → Connection | Baseline path retained; existing limits apply |
| G03 | Automatic browser callback and manual callback-URL fallback | Settings → Connection | Baseline path retained; existing limits apply |
| G04 | User-initiated Keychain retry without forced re-login | Connection / data status | Baseline path retained; existing limits apply |
| G05 | Local reconnect, monitor state and recovery guidance | Settings → Connection | Baseline path retained; existing limits apply |
| G06 | Disconnect preserves unrelated credentials and account history | Disconnect flow / history storage | Baseline path retained; existing limits apply |
| H01 | Bilingual UI/native menus and persisted language | Settings → General / native menu | Baseline path retained; existing limits apply |
| H02 | Launch-at-login toggle, installation diagnostics and approval entry | Settings → General | Baseline path retained; existing limits apply |
| H03 | Automatic/manual update checks, prompt/dismiss and download link | Settings → General / update banner | Baseline path retained; existing limits apply |
| H04 | Persistent About, version, highlights, full notes and product information | Sidebar / General / menu bar / app menu | Changed behavior verified within QA scope; release-package checks tracked separately |
| H05 | Close window keeps running, reopen and explicit quit | Window / app menu | Baseline path retained; existing limits apply |
| H06 | Native fullscreen shortcut, View navigation and Escape behavior | Native menu / windows | Baseline path retained; existing limits apply |
| I01 | Preserve preferences, frames, connection mode, thresholds and history backups | Upgrade / persistence | Changed behavior verified within QA scope; release-package checks tracked separately |
| I02 | Serialized Keychain access, no hidden prompts or weakened access control | Credential storage | Changed behavior verified within QA scope; release-package checks tracked separately |
| I03 | Same-account stale cache/original timestamp; no cross-account reuse or fresh alerts | Quota store / account switching | Baseline path retained; existing limits apply |
| I04 | Late reads cannot override a new connection or block/clear its refresh | Connection / refresh | Baseline path retained; existing limits apply |

## Automatic-use additions beyond the frozen baseline

Prepared-request traces, observed server status, reminder-only gaps, and separate diagnostic warnings are covered by the [dev.3 reliability checks](QA.md#dev3-reliability-acceptance). Authorization remains opt-in/account-owned, exact-card/final-hour only, stable-idempotency retry with cancellation protection, and confirmed success notification remains independent of future consent. No prior reminder, credential, entitlement, chart or desktop setting was removed.

## Final candidate review

The0.4.2→0.5.0 source delta retains entries and controls: C charts/Tokens, E desktop/notch, G connections and B benefits remain. Shared card/check additions are covered by QA. Final source398 regressions, installed live reading, original consent/preferences and About were checked. Unchanged device paths retain prior limits; no comprehensive hardware claim.
