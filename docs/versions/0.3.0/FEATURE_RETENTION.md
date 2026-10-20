# 0.3.0 feature retention and omission checklist

[中文](FEATURE_RETENTION.zh-CN.md) · [Plan](PLAN.md) · [QA](QA.md) · [JSON](FEATURE_RETENTION.json)

2026-10-19. The developer owns this audit; the user does not need to recall features. Baselines: native `b6b5bed` (0.2.2-dev.1), public `v0.2.1`, and pre-upgrade `v0.1.145`. Scope: current macOS quota, benefits, history, notifications, desktop forms, connection, preferences and migration. Windows needs independent acceptance.

**Retain every item by default; this checklist grants no new removal approval.** Moving an entry requires a discoverable equivalent and behavior verification. Missing/partial prototype controls are not approved removals or completed native work. All 65 native0.3.0 acceptance items are pending; existing test references are regression leads, not proof of direct coverage for every item or a new device pass.


Current0.3.0 acceptance is tracked separately in the [release audit](RELEASE_AUDIT.md) and [release scope decision](QA.md#release-scope-decision--2026-10-20). The “pending” labels below preserve the frozen baseline state, not a claim that no subsequent functional audit exists.

## Itemized baseline

Group links provide context; exact per-item source and regression leads are in the JSON under the same ID. Extend the register as new capabilities are found; source review alone is not an exhaustive device-behavior audit.

### A · Quota and data state

[Current source](../../../Sources/ReadyCheckApp/Views/OverviewQuotaView.swift) · [Existing test reference](../../../Tests/ReadyCheckAppTests/BubbleQuotaDisplayTests.swift)

| ID | Capability to retain | Native entry / default destination | Prototype | Native0.3 acceptance |
| --- | --- | --- | --- | --- |
| A01 | 5-hour percentage, progress and unknown state | Overview / desktop / menu | Partial demo | Pending; retain |
| A02 | 7-day percentage, progress and unknown state | Overview / desktop / menu | Partial demo | Pending; retain |
| A03 | Reset countdown and full date/time | Overview / compact rows | Partial demo | Pending; retain |
| A04 | Automatic / explicit primary selection; missing stays unknown; persisted choice | Settings → Display / notch details | Not shown | Pending; retain |
| A05 | Ordinary-use eligibility, limit reasons and low-quota status | Overview / compact surfaces | Not shown | Pending; retain |
| A06 | Source, last success/attempt and diagnostics | Data status popover | Not shown | Pending; retain |
| A07 | Manual refresh, busy-state protection and read-only access | Refresh controls | Partial demo | Pending; retain |
| A08 | 1/3/5-minute cadence, local events and wake refresh | Settings → General / lifecycle | Not shown | Pending; retain |

### B · Account and benefits

[Current source](../../../Sources/ReadyCheckApp/Views/Components/QuotaCardView.swift) · [Existing test reference](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift)

| ID | Capability to retain | Native entry / default destination | Prototype | Native0.3 acceptance |
| --- | --- | --- | --- | --- |
| B01 | Plan name and explicit unknown values | Overview → Account & benefits | Partial demo | Pending; retain |
| B02 | Subscription validity and historical dates | Overview → Account & benefits | Partial demo | Pending; retain |
| B03 | Billing link when subscription date is missing | Overview → Account & benefits | Not shown | Pending; retain |
| B04 | Credits number, unlimited and missing remain distinct | Overview → Account & benefits | Partial demo | Pending; retain |
| B05 | Available resets: zero distinct from unknown | Overview → Account & benefits | Partial demo | Pending; retain |
| B06 | Each reset expiration, partial missing values and GMT+8 | Overview → Account & benefits | Partial demo | Pending; retain |

### C · Quota history and Tokens

[Current source](../../../Sources/ReadyCheckApp/Views/RecentUsageView.swift) · [Existing test reference](../../../Tests/ReadyCheckCoreTests/TokenUsageComparisonTests.swift)

| ID | Capability to retain | Native entry / default destination | Prototype | Native0.3 acceptance |
| --- | --- | --- | --- | --- |
| C01 | Local consumption: 24 hours / 7 days / 30 days | Overview → Consumption | Partial demo | Pending; retain |
| C02 | Select quota window in history | Overview → Consumption | Not shown | Pending; retain |
| C03 | Quota bar hover/click, interval/point tooltip and boundaries | Overview → Consumption | Partial demo | Pending; retain |
| C04 | Account-isolated history, A→B→A and legacy preservation | Overview / history storage | Not shown | Pending; retain |
| C05 | Exclude resets, increases, invalid/missing readings and long gaps | Aggregation / Widget chart | Partial demo | Pending; retain |
| C06 | Official daily Token chart: 7/30/90-day ranges | Token usage page | Partial demo | Pending; retain |
| C07 | Lifetime Tokens, daily peak and streak | Token usage page | Not shown | Pending; retain |
| C08 | Today/yesterday and week comparisons; missing coverage and zero baseline | Token usage page | Not shown | Pending; retain |
| C09 | UTC Token dates, bar details, missing stays unknown and no quota conversion | Token usage page | Partial demo | Pending; retain |

### D · Reminders and notifications

[Current source](../../../Sources/ReadyCheckCore/Notifications/QuotaReminder.swift) · [Existing test reference](../../../Tests/ReadyCheckCoreTests/QuotaReminderTests.swift)

| ID | Capability to retain | Native entry / default destination | Prototype | Native0.3 acceptance |
| --- | --- | --- | --- | --- |
| D01 | Off / 5% / 10% / 20% low-quota options | Settings → Reminders | Partial demo | Pending; retain |
| D02 | Observed crossing, first baseline, account/window/cycle deduplication and retry | Low-quota evaluator / notifications | Not shown | Pending; retain |
| D03 | Recovery toggle and observed recovery, not clock-only | Settings → Reminders / recovery | Partial demo | Pending; retain |
| D04 | Recovery withdrawal after consumption, cancellation and restart deduplication | Notification service / history | Not shown | Pending; retain |
| D05 | Reset-expiration reminders at72/48/24/12 hours | Background reminders / history | Not shown | Pending; retain |
| D06 | Alert on observed Credits consumption after exhaustion | Background reminders / history | Not shown | Pending; retain |
| D07 | Actual notification permission/style and system settings link | Settings → Reminders | Not shown | Pending; retain |
| D08 | Test notification, delivery state and Notification Center verification | Settings → Reminders | Partial demo | Pending; retain |
| D09 | History summary/full list and persisted delivery/failure/withdrawal states | Settings → Reminders → History | Not shown | Pending; retain |

### E · Widget, card and notch

[Current source](../../../Sources/ReadyCheckApp/Views/SettingsView.swift) · [Existing test reference](../../../Tests/ReadyCheckAppTests/WidgetInteractionControllerTests.swift)

| ID | Capability to retain | Native entry / default destination | Prototype | Native0.3 acceptance |
| --- | --- | --- | --- | --- |
| E01 | Adaptive floating Widget: bubble and slim edge forms | Desktop / Settings → Display | Not shown | Pending; retain |
| E02 | Both edges, first direct inward drag and frame persistence | Floating Widget | Not shown | Pending; retain |
| E03 | Hover preview, click pin, outside retention, unpin and Escape | Widget details | Partial demo | Pending; retain |
| E04 | Both quotas and last-hour chart with5-minute bars | Widget details | Partial demo | Pending; retain |
| E05 | Card title drag, independent buttons and saved position | Information card | Not shown | Pending; retain |
| E06 | Minimal / detailed card modes | Settings → Display / card switcher | Not shown | Pending; retain |
| E07 | Show/hide, restart persistence and recovery entry | Settings / menu / Widget context menu | Not shown | Pending; retain |
| E08 | Always-on-top independent from pinning and movement | Settings → Display | Not shown | Pending; retain |
| E09 | Snooze30/60 minutes, deadline and immediate resume | Settings → Display / desktop controls | Not shown | Pending; retain |
| E10 | Reset position and recover invalid/offscreen geometry | Settings → Display | Not shown | Pending; retain |
| E11 | Hide in fullscreen / restore and existing Spaces policy | Settings → Display / window policy | Not shown | Pending; retain |
| E12 | Notch visibility/availability, physical attachment and click-only expansion | Settings → Display / notch | Not shown | Pending; retain |
| E13 | Notch selection, unknown state, details, open Overview and outside/Escape dismiss | Notch details | Not shown | Pending; retain |

### F · Menu bar and shortcuts

[Current source](../../../Sources/ReadyCheckApp/Views/MenuBarQuotaView.swift) · [Existing test reference](../../../Tests/ReadyCheckAppTests/MenuBarQuotaLabelTests.swift)

| ID | Capability to retain | Native entry / default destination | Prototype | Native0.3 acceptance |
| --- | --- | --- | --- | --- |
| F01 | Status item, both quotas/reset and account summary | Menu bar | Partial demo | Pending; retain |
| F02 | Menu diagnostics, refresh and open main window | Menu bar | Partial demo | Pending; retain |
| F03 | Menu Widget toggle and reminder entry | Menu bar | Partial demo | Pending; retain |
| F04 | More menu: Display / Connection / General / About / Quit | Menu → More | Not shown | Pending; retain |

### G · Sign-in and connection

[Current source](../../../Sources/ReadyCheckApp/Views/SettingsView.swift) · [Existing test reference](../../../Tests/ReadyCheckCoreTests/CodexOAuthTests.swift)

| ID | Capability to retain | Native entry / default destination | Prototype | Native0.3 acceptance |
| --- | --- | --- | --- | --- |
| G01 | Follow local Codex / standalone OAuth and current identity | Settings → Connection | Not shown | Pending; retain |
| G02 | Connect, cancel authorization, replace sign-in and disconnect | Settings → Connection | Not shown | Pending; retain |
| G03 | Automatic browser callback and manual callback-URL fallback | Settings → Connection | Not shown | Pending; retain |
| G04 | User-initiated Keychain retry without forced re-login | Connection / data status | Not shown | Pending; retain |
| G05 | Local reconnect, monitor state and recovery guidance | Settings → Connection | Not shown | Pending; retain |
| G06 | Disconnect preserves unrelated credentials and account history | Disconnect flow / history storage | Not shown | Pending; retain |

### H · General and app entries

[Current source](../../../Sources/ReadyCheckApp/App/ReadyCheckApp.swift) · [Existing test reference](../../../Tests/ReadyCheckAppTests/MainMenuTests.swift)

| ID | Capability to retain | Native entry / default destination | Prototype | Native0.3 acceptance |
| --- | --- | --- | --- | --- |
| H01 | Bilingual UI/native menus and persisted language | Settings → General / native menu | Partial demo | Pending; retain |
| H02 | Launch-at-login toggle, installation diagnostics and approval entry | Settings → General | Not shown | Pending; retain |
| H03 | Automatic/manual update checks, prompt/dismiss and download link | Settings → General / update banner | Not shown | Pending; retain |
| H04 | Persistent About, version, highlights, full notes and product information | Sidebar / General / menu bar / app menu | Partial demo | Pending; retain |
| H05 | Close window keeps running, reopen and explicit quit | Window / app menu | Not shown | Pending; retain |
| H06 | Native fullscreen shortcut, View navigation and Escape behavior | Native menu / windows | Partial demo | Pending; retain |

### I · Migration and safety

[Current source](../../../Sources/ReadyCheckApp/App/ReadyCheckApp.swift) · [Existing test reference](../../../Tests/ReadyCheckAppTests/ConnectionReloadTests.swift)

| ID | Capability to retain | Native entry / default destination | Prototype | Native0.3 acceptance |
| --- | --- | --- | --- | --- |
| I01 | Preserve preferences, frames, connection mode, thresholds and history backups | Upgrade / persistence | Not shown | Pending; retain |
| I02 | Serialized Keychain access, no hidden prompts or weakened access control | Credential storage | Not shown | Pending; retain |
| I03 | Same-account stale cache/original timestamp; no cross-account reuse or fresh alerts | Quota store / account switching | Partial demo | Pending; retain |
| I04 | Late reads cannot override a new connection or block/clear its refresh | Connection / refresh | Not shown | Pending; retain |

## Historical differences

Direct native UI localization callsites:291 old keys and300 current keys;16 old-only keys were classified from source. This is traceability, not proof of retained behavior; dynamic titles/controllers still require item checks.

1. Separate bubble/edge and side settings were consolidated with user approval in0.2.1. Retain both edges, direct inward drag and frame memory; do not restore duplicate selectors.
2. Old collapse/open-notch wording maps to pinning, Escape/outside dismissal and Open Overview. Retain behavior, not merely similar labels.
3. Missing-window fallback was corrected in0.2: explicit selections stay unknown instead of silently switching.
4. Stale/display/quota/chart wording maps to current compact state, Display settings, Overview and consistent chart units. Data/settings are not removed.
5. Hook/global-notify experiments previously removed at user request are not product capabilities and will not be restored.

## Release gate and ownership

The developer must record implementation location, automated/black-box results, device evidence and migration outcome per item. Source presence, same-name prototype entries or aggregate test totals are not acceptance. Missing entries, degraded behavior, data loss and unresolved relevant checks block release. Unchanged paths may reuse specifically applicable evidence. Any removal/change needs the ID, before/after behavior, impact, alternative and rollback, then explicit user approval evidence before changing its decision. The user reviews new value and explicit tradeoffs, not omissions.
