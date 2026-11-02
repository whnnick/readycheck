# 0.7.0 — Multi-provider usage statistics aggregator

[Interaction correction plan](INTERACTION_REPLAN.md)

[中文](PLAN.zh-CN.md) · [Data-access evidence](SOURCES.md) · [Service and account settings](SETTINGS_PLAN.md) · [0.6.1 retention](../0.6.1/RELEASE_AUDIT.md)

Updated 2026-11-02. Unreleased dev.23 is installed at the fixed local path; each iteration's current connection and device-acceptance status is recorded in QA. Live Codex/DeepSeek API balances, a Notification Center test and selected retained paths were checked; full automated regression passed. Original card consent and normal checks recovered after unlock. Remaining device behavior and affected Windows login remain pending; distribution remains a self-signed preview; see [current and dated acceptance evidence](QA.md). The user clarified that aggregation means lightweight usage statistics, not chat or model invocation. The earlier chat-workspace direction and all three generated concepts are withdrawn and must not guide implementation.

## Goal and scope

Dev.26: implement the third displayed DeepSeek concept (micro-trend), not the earlier second concept. Keep the native 180x48 / 28x144 / 380x344 dimensions and shared interaction. Compact balance gets a currency heading and more trend space, edge trends run vertically, expanded balance and breakdown sit side by side above a taller chart. Retain existing notch fit, stale/error states and observation-only semantics. [Acceptance](QA.md).

Dev.25 correction: ordinary clicks must not latch or unlatch previews. Only an explicit pin control changes the pinned state; outside/exit dismissal of temporary previews remains. Use the same detail header, pin styling and refresh/reminder/open footer for quota and balance content, and update both edge-strip visuals rather than only the free capsule. Retain placement, dragging, data and account boundaries. [Acceptance](QA.md).

Dev.24 design: use the selected second concept for compact readouts. Model access method (OAuth / API Key) independently from readout kind (quota / balance); the current mappings are Codex = OAuth + quota and DeepSeek = API Key + balance, not rules for all future providers. Reuse the existing data sources and connection flows; do not add services or inference calls. The capsule becomes a shared horizontal 180x48 surface; retain Codex detail space, dual-notch options, reminder actions and bidirectional notch dragging. Balance details distinguish currencies, sampling gaps, stale data and observed decreases from official billing. [Acceptance](QA.md).

Dev.23 acceptance correction: English About must retain its brand/title and permit complete content access at default and minimum sizes; preserve all content. [Checks](QA.md).

Dev.22 acceptance correction: About highlights must describe the implemented 0.7 capabilities in both languages. Keep dev.21 draft private until the retention/device gate is complete. [Checks](QA.md).

Dev.21: the notch must also drag down into the existing capsule at the release point. Dragging follows the pointer; a deliberate downward release detaches, while a short/sideways/returned drag stays attached. Keep click-to-expand and detail controls; preserve service, primary selection and quota layout. Existing capsule-to-notch drops remain. [Checks](QA.md).

Dev.20: dual-notch details keep 5h/7d in a fixed order without a redundant primary picker. Single mode retains the selection that drives its collapsed display. Add anchored geometry/content transitions, reversible during motion and respecting reduced-motion settings; Escape stays immediate. Preserve every returned window and existing authorization. [Checks](QA.md).

Dev.19 requirements: default stacked Codex 5h/7d rows, persistent dual/single selection in Settings → Display without changing the primary quota selection, and a shared rounded lower silhouette attached to the physical notch. Retain expansion/dismissal. [Checks](QA.md).

Dev.18 requirements: hovering or clicking a DeepSeek decrease bar shows its interval, exact observed amount and currency; tooltips stay inside the plot and missing data is not zero. Dropping the capsule near a physical notch selects the existing notch display while retaining the prior capsule position and selected service. Other screens retain normal capsule/edge dragging. Existing display controls restore the capsule; no new account or consent is required. [Checks](QA.md).

Dev.17 follow-up: immediate DeepSeek refresh feedback; locally observed balance-decrease buckets with currency, recharge and sampling-gap boundaries; existing service selection drives all compact display surfaces. Retain Codex monitoring. This does not add official billing, inference, accounts or authorization. [Acceptance](QA.md).

Show the usage, quotas, balances, resets and issues each service can actually expose. Retain all existing Codex quota, benefits, reset-card automation, history, notifications, menu bar, Widget and notch capabilities.

New integrations default to read-only monitoring. Do not add conversations, prompts, inference, agents, context transfer or resale of shared credits. Existing explicitly authorized Codex automatic-card use remains a retained provider-specific capability.

Connecting personal services means connecting authorized statistics sources, accounts or explicitly selected local tool records. It does not grant inference rights. Request only the minimum necessary reporting permissions, not a universal inference or administrator key.

## Long-term target: ten services in two batches of five

Current completion scope is Codex + DeepSeek only; the other eight remain planned and are not supported by this development version.

| Batch | Services |
| --- | --- |
| First | Codex, Claude, Gemini, DeepSeek, Cursor |
| Second | GitHub Copilot, Alibaba/Bailian Coding Plan, GLM Coding Plan, Kimi Code, MiniMax Coding Plan |

The user approved ten targets instead of exposing the 110-entry reference directory. Within batch one, first complete Codex retention + real DeepSeek balance reading, then add the remaining services. Following the accepted correction plan, Overview always shows the two supported platforms, Codex and DeepSeek, with a direct connection action when disconnected. Other planned services remain catalog entries without empty quota cards. The catalog is ordered by development batch and does not claim all ten work. See the [implementation matrix](TECHNICAL.md).

## Frontend

Keep Overview, Usage, Notification history and Settings. No chat page, session list or conversation model picker.

Overview has a service switcher and concise connected-service list; pin the service of interest, display valid metrics, freshness and issues, and open per-service details. Keep the full existing Codex details and benefits. Isolate accounts and failures.

Usage filters by service, account and time; expose model breakdown only when supported by the source. Separate subscription quotas, official tokens/requests, balances and costs. Missing data and inadequate permissions are explicit, never represented as zero.

Connection settings show source, accessible fields, reporting coverage, credential state and latest success. Recommend a supported path while explaining alternate sources. Reminders are capability-driven, account/period deduplicated, and never interpret failed polling as exhaustion.

Menu bar, Widget and notch stay compact, pinned to a service/metric with a detail shortcut. Retain the hour chart, dragging, pinning, hiding and quick controls. Different units need appropriate visual treatment.

Label official data, tool records, estimates and unavailable values with coverage and time. Tokens, requests, subscription percentages, balances and costs are separate measures; no fabricated combined remaining quota or silent currency mixing.

## Backend

Extend QuotaProvider, credential storage, history and reminders. Do not introduce InferenceProvider, ConversationStore, chat storage or an inference gateway.

Each read-only adapter handles authentication/status, actual statistics retrieval, field/unit mapping, provenance/time/coverage and classified errors. Add distinct periodic usage and point-in-time balance types where required rather than forcing every metric into percentages. Preserve account/project/region identity and distinguish vendor from serving channel.

Pipeline: connection → minimum-permission credential → read-only adapter → standard statistics snapshot → account-owned history → UI surfaces → reminders.

Independent polling, backoff, cache and stale state prevent one provider from blocking the rest. Polling never invokes a model. Show official reporting delay and interval. Keep credentials in OS secure storage and sensitive account/bill details out of logs. Process/store locally first; no new ReadyCheck cloud account or statistics proxy is required.

## Common and provider-specific capabilities

Common: services/accounts, reporting periods, source/freshness, error recovery, history, trustworthy reminders and isolation.

| Service | Proposed data | Boundary |
| --- | --- | --- |
| Codex | Retain quotas, resets, Token, benefits and cards | Preserve existing automatic-card authorization/history and compact native surfaces |
| Claude | Verify subscription quota or organization reporting per source | Separate subscription/API; no default administrative-key requirement |
| Gemini | Verify per-source quota and reset | Keep CLI, app and API-platform identities/quotas separate |
| DeepSeek | Validate balance, currency and granted/paid breakdown first | No inferred Token/cost and no fabricated percentage |
| Cursor | Plan usage and billing period | Source authorization, identity and session stability pending |
| Second-batch five | Exact per-service fields/permissions in the implementation matrix | Keep region, Coding Plan, open platform and credential type boundaries |

Access levels: A=official reporting and eligible account; B=explicitly authorized attributable local tool records, limited to that tool; C=official dashboard shortcut with unsupported in-app retrieval. Never market C as integrated statistics or substitute inference tests for reporting acceptance.

## Delivery and acceptance

1. Build a real read-path matrix covering permissions, fields, units, cycles and coverage for services users actually use. Verify read-only with real eligible accounts; do not assume uniform provider support.
2. Keep Codex and add one validated source. Prioritize validation of DeepSeek official balance while investigating Claude/Gemini reporting. Complete connection → statistics → history → compact surfaces → reliable reminders; label balance-only support.
3. Add more services that pass reporting acceptance, with switching/filtering prioritized by demand and feasibility rather than logo count.
4. Redesign around statistics and service switching; reject the previous chat concepts. Retain the itemized65-feature baseline and0.5/0.6 additions, preferences, account history, credentials and card consent. Verify offline/error/reset/deduplication behavior and platforms separately, then follow bilingual release/download checks when authorized.

Success means users can quickly understand available quota/balance, recent consumption, freshness/reset and missing information. Comparable official metrics reconcile; missing is not zero, accounts do not mix, polling causes no inference spend and existing features remain discoverable. Windows and Mac need separate acceptance.

## 2026-10-30 — Prototype / 交互原型

[Interactive prototype](prototype/README.md) · [Black-box checks](QA.md) · [Technical scope](TECHNICAL.md). Preview.3 keeps the ten targets, batch filtering and compact demo-connected tabs while exploring separate service/app settings. Language switching is not implemented in this prototype. The 110-entry preview.1 is historical research; the separate Codex + DeepSeek native development acceptance is recorded in the checks.
