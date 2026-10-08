# 0.1.132: quieter desktop monitoring

[中文](PLAN.zh-CN.md) · [Black-box acceptance](QA.md) · [Version index](../../VERSIONS.md)

Local preview, 2026-10-07. Keep the existing recovery reminder, round bubble, card and edge rings.

| Requirement | Shipped behavior |
| --- | --- |
| Optional early warning | Off by default. Select either 20% or 10% in the main window or menu bar. A verified, fresh Codex window crossing the threshold creates one notification per account/window/reset cycle. The first valid observation only establishes a baseline. Changing the threshold resets that baseline. |
| Temporarily hide the widget | Choose 30 minutes or 1 hour from display settings, the menu bar or the widget context menu. Quota monitoring continues while the app runs. The absolute deadline survives restart; manual restore cancels it. Expired deadlines are reconciled on startup and wake. |
| Clear style selection | Three illustrative previews distinguish freely draggable round bubble/card from left/right edge rings. Select one style at a time; reuse each style's existing position storage. |
| Explain data status | Main-window and menu-bar entry shows the attempted source, this run's latest successful read, last refresh attempt and relevant reasons. Unknown permission and subscription fields are explained without inventing data; past subscription dates are identified as historical. Credential failures expose the existing retry action. |

Reuse the existing notification verification/history pipeline, quota sources, window controllers and localization service. No model generation requests, new provider, forecast, billing scrape, additional animation mode or Windows feature is added.

The low-quota deduplication state uses backward-compatible optional fields. Failed delivery retries with the same identifier; cancellation or threshold changes during delivery cannot restore an obsolete setting. Stale, estimated, mock and out-of-order data cannot trigger warnings. Without a reset timestamp, a recovery above the chosen threshold re-arms the window.

Validation covers evaluator boundaries, delivery/history behavior, persisted hide deadlines and data explanations, followed by real installed UI checks. Existing edge-hover timing remains 0.5 seconds and click remains immediate. See [acceptance and remaining release checks](QA.md).
