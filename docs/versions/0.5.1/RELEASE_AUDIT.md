# 0.5.1 feature-retention delta audit

[中文](RELEASE_AUDIT.zh-CN.md) · [Checks](QA.md) · [Prior audit](../0.5.0/RELEASE_AUDIT.md)

All65 baseline capabilities are retained. This is an incremental review, not65 new real-device passes. Changed presentation/account-metadata paths use the current native and regression evidence; unchanged paths reuse the specific0.5.0 audit and its stated device/network limits. Automatic-use consent/execution, reminder evaluation and stored history are unchanged.

| ID | Capability | Discoverable entry | Evidence / disposition |
| --- | --- | --- | --- |
| A01 | 5-hour percentage, progress and unknown state | Overview / desktop / menu | Current presentation/account guard regression + native scenarios; see QA |
| A02 | 7-day percentage, progress and unknown state | Overview / desktop / menu | Current presentation/account guard regression + native scenarios; see QA |
| A03 | Reset countdown and full date/time | Overview / compact rows | Current presentation/account guard regression + native scenarios; see QA |
| A04 | Automatic / explicit primary selection; missing stays unknown; persisted choice | Settings → Display / notch details | Unchanged path; reuse0.5.0 evidence and limits |
| A05 | Ordinary-use eligibility, limit reasons and low-quota status | Overview / compact surfaces | Unchanged path; reuse0.5.0 evidence and limits |
| A06 | Source, last success/attempt and diagnostics | Data status popover | Current presentation/account guard regression + native scenarios; see QA |
| A07 | Manual refresh, busy-state protection and read-only access | Refresh controls | Current presentation/account guard regression + native scenarios; see QA |
| A08 | 1/3/5-minute cadence, local events and wake refresh | Settings → General / lifecycle | Unchanged path; reuse0.5.0 evidence and limits |
| B01 | Plan name and explicit unknown values | Overview → Account & benefits | Current presentation/account guard regression + native scenarios; see QA |
| B02 | Subscription validity and historical dates | Overview → Account & benefits | Current presentation/account guard regression + native scenarios; see QA |
| B03 | Billing link when subscription date is missing | Overview → Account & benefits | Current presentation/account guard regression + native scenarios; see QA |
| B04 | Credits number, unlimited and missing remain distinct | Overview → Account & benefits | Current presentation/account guard regression + native scenarios; see QA |
| B05 | Available resets: zero distinct from unknown | Overview → Account & benefits | Current presentation/account guard regression + native scenarios; see QA |
| B06 | Each reset expiration, partial missing values and GMT+8 | Overview → Account & benefits | Current presentation/account guard regression + native scenarios; see QA |
| C01 | Local consumption: 24 hours / 7 days / 30 days | Overview → Consumption | Unchanged path; reuse0.5.0 evidence and limits |
| C02 | Select quota window in history | Overview → Consumption | Unchanged path; reuse0.5.0 evidence and limits |
| C03 | Quota bar hover/click, interval/point tooltip and boundaries | Overview → Consumption | Unchanged path; reuse0.5.0 evidence and limits |
| C04 | Account-isolated history, A→B→A and legacy preservation | Overview / history storage | Unchanged path; reuse0.5.0 evidence and limits |
| C05 | Exclude resets, increases, invalid/missing readings and long gaps | Aggregation / Widget chart | Unchanged path; reuse0.5.0 evidence and limits |
| C06 | Official daily Token chart: 7/30/90-day ranges | Token usage page | Current presentation/account guard regression + native scenarios; see QA |
| C07 | Lifetime Tokens, daily peak and streak | Token usage page | Current presentation/account guard regression + native scenarios; see QA |
| C08 | Today/yesterday and week comparisons; missing coverage and zero baseline | Token usage page | Current presentation/account guard regression + native scenarios; see QA |
| C09 | UTC Token dates, bar details, missing stays unknown and no quota conversion | Token usage page | Current presentation/account guard regression + native scenarios; see QA |
| D01 | Off / 5% / 10% / 20% low-quota options | Settings → Reminders | Current presentation/account guard regression + native scenarios; see QA |
| D02 | Observed crossing, first baseline, account/window/cycle deduplication and retry | Low-quota evaluator / notifications | Unchanged path; reuse0.5.0 evidence and limits |
| D03 | Recovery toggle and observed recovery, not clock-only | Settings → Reminders / recovery | Current presentation/account guard regression + native scenarios; see QA |
| D04 | Recovery withdrawal after consumption, cancellation and restart deduplication | Notification service / history | Unchanged path; reuse0.5.0 evidence and limits |
| D05 | Reset-expiration reminders at72/48/24/12 hours | Background reminders / history | Current presentation/account guard regression + native scenarios; see QA |
| D06 | Alert on observed Credits consumption after exhaustion | Background reminders / history | Unchanged path; reuse0.5.0 evidence and limits |
| D07 | Actual notification permission/style and system settings link | Settings → Reminders | Current presentation/account guard regression + native scenarios; see QA |
| D08 | Test notification, delivery state and Notification Center verification | Settings → Reminders | Current presentation/account guard regression + native scenarios; see QA |
| D09 | History summary/full list and persisted delivery/failure/withdrawal states | Settings → Reminders → History | Current presentation/account guard regression + native scenarios; see QA |
| E01 | Adaptive floating Widget: bubble and slim edge forms | Desktop / Settings → Display | Current presentation/account guard regression + native scenarios; see QA |
| E02 | Both edges, first direct inward drag and frame persistence | Floating Widget | Unchanged path; reuse0.5.0 evidence and limits |
| E03 | Hover preview, click pin, outside retention, unpin and Escape | Widget details | Unchanged path; reuse0.5.0 evidence and limits |
| E04 | Both quotas and last-hour chart with5-minute bars | Widget details | Unchanged path; reuse0.5.0 evidence and limits |
| E05 | Card title drag, independent buttons and saved position | Information card | Unchanged path; reuse0.5.0 evidence and limits |
| E06 | Minimal / detailed card modes | Settings → Display / card switcher | Unchanged path; reuse0.5.0 evidence and limits |
| E07 | Show/hide, restart persistence and recovery entry | Settings / menu / Widget context menu | Unchanged path; reuse0.5.0 evidence and limits |
| E08 | Always-on-top independent from pinning and movement | Settings → Display | Unchanged path; reuse0.5.0 evidence and limits |
| E09 | Snooze30/60 minutes, deadline and immediate resume | Settings → Display / desktop controls | Unchanged path; reuse0.5.0 evidence and limits |
| E10 | Reset position and recover invalid/offscreen geometry | Settings → Display | Unchanged path; reuse0.5.0 evidence and limits |
| E11 | Hide in fullscreen / restore and existing Spaces policy | Settings → Display / window policy | Unchanged path; reuse0.5.0 evidence and limits |
| E12 | Notch visibility/availability, physical attachment and click-only expansion | Settings → Display / notch | Unchanged path; reuse0.5.0 evidence and limits |
| E13 | Notch selection, unknown state, details, open Overview and outside/Escape dismiss | Notch details | Unchanged path; reuse0.5.0 evidence and limits |
| F01 | Status item, both quotas/reset and account summary | Menu bar | Unchanged path; reuse0.5.0 evidence and limits |
| F02 | Menu diagnostics, refresh and open main window | Menu bar | Unchanged path; reuse0.5.0 evidence and limits |
| F03 | Menu Widget toggle and reminder entry | Menu bar | Unchanged path; reuse0.5.0 evidence and limits |
| F04 | More menu: Display / Connection / General / About / Quit | Menu → More | Unchanged path; reuse0.5.0 evidence and limits |
| G01 | Follow local Codex / standalone OAuth and current identity | Settings → Connection | Current presentation/account guard regression + native scenarios; see QA |
| G02 | Connect, cancel authorization, replace sign-in and disconnect | Settings → Connection | Unchanged path; reuse0.5.0 evidence and limits |
| G03 | Automatic browser callback and manual callback-URL fallback | Settings → Connection | Unchanged path; reuse0.5.0 evidence and limits |
| G04 | User-initiated Keychain retry without forced re-login | Connection / data status | Current presentation/account guard regression + native scenarios; see QA |
| G05 | Local reconnect, monitor state and recovery guidance | Settings → Connection | Unchanged path; reuse0.5.0 evidence and limits |
| G06 | Disconnect preserves unrelated credentials and account history | Disconnect flow / history storage | Unchanged path; reuse0.5.0 evidence and limits |
| H01 | Bilingual UI/native menus and persisted language | Settings → General / native menu | Unchanged path; reuse0.5.0 evidence and limits |
| H02 | Launch-at-login toggle, installation diagnostics and approval entry | Settings → General | Unchanged path; reuse0.5.0 evidence and limits |
| H03 | Automatic/manual update checks, prompt/dismiss and download link | Settings → General / update banner | Unchanged path; reuse0.5.0 evidence and limits |
| H04 | Persistent About, version, highlights, full notes and product information | Sidebar / General / menu bar / app menu | Current presentation/account guard regression + native scenarios; see QA |
| H05 | Close window keeps running, reopen and explicit quit | Window / app menu | Unchanged path; reuse0.5.0 evidence and limits |
| H06 | Native fullscreen shortcut, View navigation and Escape behavior | Native menu / windows | Unchanged path; reuse0.5.0 evidence and limits |
| I01 | Preserve preferences, frames, connection mode, thresholds and history backups | Upgrade / persistence | Current presentation/account guard regression + native scenarios; see QA |
| I02 | Serialized Keychain access, no hidden prompts or weakened access control | Credential storage | Unchanged path; reuse0.5.0 evidence and limits |
| I03 | Same-account stale cache/original timestamp; no cross-account reuse or fresh alerts | Quota store / account switching | Current presentation/account guard regression + native scenarios; see QA |
| I04 | Late reads cannot override a new connection or block/clear its refresh | Connection / refresh | Current presentation/account guard regression + native scenarios; see QA |

Full account benefits moved below the trend, not removed. Both connection methods, original consent/attempts, all reminder nodes and historical gaps remain. Subscription date requires same-account sign-in claims; no date is inferred from reset times. Release-source/package/installed results are recorded separately in QA.
