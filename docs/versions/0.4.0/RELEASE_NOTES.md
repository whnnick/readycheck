# ReadyCheck 0.4.0 — know what happens next

[中文](RELEASE_NOTES.zh-CN.md) · [Checks](QA.md) · [Retention audit](RELEASE_AUDIT.md)

## What's new

- **One shared next step.** Overview, the menu bar and Widget show the same most relevant reset, conditional card-use window or item needing attention. Overview keeps at most two items instead of another large status card.
- **Understand card outcomes.** Open an existing expiration row or card-use record to inspect the original expiry, account authorization, recorded result and matching success-notification record. A used card with an undelivered notice is pending notification delivery, not a failed card redemption.
- **Honest freshness.** Preserve existing card details together with their actual read time. A stale or incomplete reading cannot promise an attempt window. Reaching a reset timestamp still requires a fresh reading to establish quota recovery.

## Existing features retained

Keep both quotas/reset dates, plan/subscription/Credits/reset counts and individual expiries, independent low/recovery/expiry/automatic-use controls, official Token statistics, local consumption chart/tooltips, Widget last-hour/5-minute chart, primary selection, adaptive edge Widget, movable card, click-only notch, pin/snooze/visibility, connection/diagnostics, updates, bilingual menus and About. The [65-item audit](RELEASE_AUDIT.md) records evidence and limits.

Automatic card use continues to require the original account-specific opt-in. This update adds read-only explanations, not a new redemption or generic retry button. Old records without execution stages remain explicitly unrecorded. Quota-pace estimates remain conditional references, never exact work-time promises or Codex task control.

## Distribution scope

New features are macOS-only. Windows retains its existing interface with synchronized version metadata. Mac distribution remains an Apple-silicon, self-signed preview, not Developer ID signed or notarized. Real card redemption, another live account, external-display configurations and Windows hardware are not inferred from synthetic tests.

Verification evidence and coverage limits are recorded in [QA](QA.md).
