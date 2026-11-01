# 0.7.0 — Service and account settings plan

> **Superseded direction:** the user rejected dev.13 navigation depth and broken old paths. The hidden-service-page/removal direction is replaced by the [interaction correction plan](INTERACTION_REPLAN.md). The original proposal is retained below for history.


[中文](SETTINGS_PLAN.zh-CN.md) · [Product plan](PLAN.md) · [Current acceptance](QA.md)

2026-10-31. Originally a proposal; the dev.12 native build now implements the first service-settings navigation while retaining existing storage. End-to-end and release acceptance remain pending; see the current checks. Finish Codex + DeepSeek first; Gemini and other integrations are deferred. Retain the compact service switcher, four main destinations and ten-service directory.

## Product decision

Organize personal settings by service and account. Application settings hold preferences shared by the whole utility. The ownership model is application → service → connection/account → currency or quota window, presented through two visible entry points: Service settings and App settings. A single connection opens directly; show an account selector only when multiple accounts exist.

Services refer to specific products and sources. Gemini App and Gemini CLI need distinct scopes; individual models do not each need a duplicate settings system.

## Current evidence

The current reminders page mixes Codex quota recovery, low quota, card expiry, automatic card use, DeepSeek balance rules and macOS delivery controls. Supported catalog entries lead to one shared connection page. Overview can select DeepSeek while Token usage still displays Codex. DeepSeek alert storage already uses connection ID and currency, but not every Codex preference is account-scoped: the low-quota threshold is currently a shared field. A UI reorganization must not imply that storage isolation is already complete.

## Navigation

- Overview and Usage retain the compact icon switcher and show the current connection with a Service settings action.
- Service settings occupy the same content area with a clear service/account heading and return path. Sections are Connection and source, Reminders, and supported service-specific features.
- Manage connections remains the entry for adding and finding services. Connected services open their own settings; planned services show capability information.
- The sidebar Settings destination becomes App settings, retaining its position and shortcut.
- Usage follows the selected service: official tokens for Codex, balance readings for DeepSeek, with an explicit explanation that token/cost reporting is unavailable for that connection.
- Notification history aggregates by default. Entering from a service preselects that scope with a visible option to view all. Record details link to the corresponding connection's rule.

Rename the current Token usage navigation item to Usage. Viewing a service must not change the service pinned to Widget/notch. Do not add an all-services reminder master switch in phase one: it would overlap individual rules and system permissions.

## Ownership table

| Setting | Scope | Placement and behavior |
| --- | --- | --- |
| Language, theme, login at startup, updates | Application/device | App settings; independent of account selection |
| Widget/notch visibility, position, pinning, snooze, fullscreen hiding | Device display | App settings; identify the displayed service/connection and preserve existing Codex features |
| Refresh cadence | App preference constrained by source | Keep existing scheduling first; show actual service cadence, including DeepSeek's approximate five minutes |
| macOS notification permission, delivery test, persistent style | Application/device | App settings, with service-page status and link |
| Login, reconnect, replace Key, disconnect, source and last success | Connection | Service settings → Connection and source |
| Codex low quota, recovery and card-expiry rules | Target: account/window | Codex Reminders; first phase retains existing storage and explains its actual scope |
| Codex automatic card use | Existing authorized account | Separate Codex section preserving consent, checks, receipts and deduplication |
| DeepSeek balance threshold | Connection/currency | DeepSeek Reminders, explicitly based on total balance; granted and topped-up amounts remain reference components |
| Last viewed service/account | Device preference | Switcher memory; disconnection uses a clear fallback without rewriting rule ownership |
| History and delivery records | Service/source/account or connection | Filtered history; viewing another service never rewrites ownership |

Capabilities control visible fields. DeepSeek has no reset cards or percentage threshold. Balance-only sources have no invented token/model filter. Planned services cannot save pretend configuration.

## Current service flows

**Codex:** select Codex → Service settings → inspect login, source and last success → configure quota/recovery/expiry reminders. Automatic card use has a separate section showing the authorized account, checks and receipts. Viewing settings is not new consent. Credential recovery preserves consent and displays subsequent check status.

**DeepSeek:** select DeepSeek → Service settings → connection, read-only balance coverage, last success and approximate five-minute cadence → per-currency total-balance alert. Before saving, explain the exact comparison, such as CNY total balance ≤ threshold. Do not silently add granted-only or topped-up-only alerts. Rules remain off until explicitly saved and enabled. Keep disconnect/replace-Key actions separate from reminder saving.

Before a credential action, explain locally that macOS Keychain may request the Mac login password, naming the requester and purpose. Never collect the Mac password inside ReadyCheck. A blocked credential read is Needs system authorization, not automatically Signed out.

## Identity, migration and recovery

Use service, source and a verified stable account identity together. If a source does not provide reliable identity, use a local connection ID labeled as this connection. Service name, email or a user-entered nickname alone cannot establish ownership.

- Phase one moves entry points and reuses existing controls without changing persistence formats, credentials, alert-cycle state, history or automatic-card consent.
- A later multi-account migration is separate, repeatable and recoverable, with original data retained. Bind only proven ownership; keep unknown legacy history separate rather than copying it to every account.
- Explain shared legacy preferences. Do not silently propagate them to future accounts. New accounts start with safe disabled rules; automatic card use continues to require account-specific consent.
- Reconnecting the same identified connection can retain rules. A Key change without identity proof creates a new scope without inherited rules/history. Retain DeepSeek's current same-Key connection-ID behavior.
- Disconnect stops future polling and notifications for that connection and removes its credential. Explain history retention separately; deleting history requires a distinct action.
- Isolate service failures. Preserve a cached reading's original timestamp, and never show another account's balance after a failed switch.

## Delivery sequence

1. Reorganize Codex + DeepSeek pages and service context, add precise routes and simplify App settings, reusing proven connection/reminder/card components.
2. Audit actual storage scope and migrate shared preferences deliberately. Do not combine this with new providers or rewritten authorization.
3. Add account selection and per-account preferences when needed, then apply the capability-driven page structure to separately verified sources.

Phase one does not deliver multi-account support. This proposal does not change the running app or real settings.

## Black-box acceptance gate

- Reach each service's settings from its overview in no more than two actions; return to the previous service and page.
- No Codex card controls on DeepSeek, no currency threshold on Codex, and no provider forms piled into App settings.
- Usage/notification routes clearly identify their source and return to the correct connection rule.
- Existing thresholds, expiry nodes, consent, history, unconfirmed outcomes and notification-cycle state survive the upgrade unchanged.
- Account/source/Key changes, disconnection, reconnection and failures never mix values or unknown history.
- Denied macOS authorization is recoverable; background work does not repeatedly prompt and other services remain usable.
- Distinguish a saved/enabled rule from denied system delivery permission; blocked delivery is not a rule-save failure.
- Verify narrow layouts, both languages, both appearances, keyboard, accessibility, menu bar, Widget and notch routes. Device display preferences remain independent of account selection.

Record synthetic, real read-only and running-package evidence separately in the [version acceptance document](QA.md); this proposal is not proof that the gate has passed.

Next, validate a clickable prototype using three tasks: adjust a DeepSeek alert, inspect Codex automatic card use, and change language. Implement the page reorganization after validating routes and scope.
