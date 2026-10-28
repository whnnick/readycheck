# 0.6.0 — Understand reminders and card use at a glance

[简体中文](PLAN.zh-CN.md) · [Black-box checks](QA.md) · [Versions](../../VERSIONS.md)

The user approved local development, not public release. Retain the unpublished0.5.5 full notification submission timestamp and native system style; do not promise macOS will always render its relative-time label.

## Interaction contract

1. Notification history: an All-default type filter on the existing page; descending local calendar-date groups, separate unknown dates, relative plus full timestamps. Use actual attempt time or recorded system receipt time, never card expiry as an event time. Distinguish no matches from empty history. Filtering/grouping/refresh must not send notifications.
2. Card details: present existing observations, checks, requests, results and notice evidence directly, without another tab or nested disclosures. Only precisely associated card records enter its timeline. Account-wide checks and current aggregate state must not masquerade as past card events. Keep facts, uncertainty, related-notice details and Close/Escape.
3. Recovery actions: use existing connection/check operations, distinguish restricted credentials, rejected authentication and network/service failures. Missing pace estimates or temporary card details are not login expiry. Map actions only where state evidence supports them; no automatic login or card redemption.

Implement history selection/grouping with focused data tests first; native preview and bilingual narrow-window checks next; then card details and recovery actions. Visible changes use0.6.0-dev.1. Mark unverified work pending.

## Retention

Carry forward the[65-feature baseline](../0.3.0/FEATURE_RETENTION.md) and[0.5.4 checks](../0.5.4/QA.md): account benefits, subscription date, Credits, card count/expiry, Token page, local quota charts, last-hour graph, Widget movement/pinning/edge/bubble, click-only notch, menu bar, About, languages, shortcuts and every reminder rule. Keep OAuth-only sign-in. Preserve preferences, account isolation, history, deduplication and existing automatic-card consent/rules without migration or clearing.

Use no real card for acceptance. Keep test notifications separate from card success. Users should identify event time, outcome evidence and supported recovery action without guessing across screens; system receipt is not proof a person saw the notification.

[Itemized retention audit](RELEASE_AUDIT.md)

[Native contract](TECHNICAL.md)
