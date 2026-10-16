# 0.2.0 cross-version experience and delivery review

[中文](UPGRADE_REVIEW.zh-CN.md) · [Plan](PLAN.md) · [Black-box checks](QA.md) · [Version index](../../VERSIONS.md)

2026-10-16. Scope: the complete 0.1.145→0.2.0 journey. The observation column below records the starting revision, not unfixed current behavior. Native changes are included in the published `0.2.0` macOS preview; consult [QA](QA.md) for current implementation, packaged-app evidence and remaining device/release gates. Source observations alone do not establish live-account/device acceptance.

## Existing capability preservation

The 0.2.0 redesign changes where existing features appear; removal requires explicit product approval. The dev.7 account-detail omission was a regression, not an intended reduction.

| Existing capability | 0.2.0 location / preservation check |
| --- | --- |
| Plan, subscription validity and billing fallback | Overview → Account & benefits; missing date retains the billing link, past dates remain historical records. |
| Manual reset count and each expiration | Overview → Account & benefits; unknown differs from zero, partial expiration lists retain unavailable rows. Display only; no automatic credit redemption. |
| Credits balance / unlimited | Overview → Account & benefits; missing balance is labelled not provided. |
| Quota remaining, reset countdown and exact reset time | Overview quota cards; selected quota remains shared with desktop surfaces. |
| Local quota history and official Token activity | Overview and Token usage respectively, with separate units and source boundaries. |
| Refresh, source and connection repair | Page header Data status/Refresh and Settings → Connection; existing credential and login actions retained. |
| Reminder controls/history and notification test | Settings → Reminders; existing evaluator and expiry notification service retained. |
| Widget pin/show/position, last-hour chart, notch and fullscreen preferences | Settings → Display and existing desktop controls; previously recorded device acceptance and pending gates remain in QA. |
| Language, refresh cadence, login item, update and About | Settings → General and existing application menu; source compared with the pre-sidebar main window. |

This is a source/location comparison plus the separately recorded tests and native acceptance, not a claim that every device/lifecycle release gate has passed. Missing server fields must remain unknown; subscription validity cannot be inferred from reset-credit dates or authentication-token expiration.


## Required work and evidence

| ID / priority | Observation and impact | 0.2.0 action and acceptance |
| --- | --- | --- |
| R1 / P0 | Missing explicit quota falls back to the first available window; tests require that behavior. [Selector](../../../Sources/ReadyCheckCore/NotchQuotaSelection.swift), [tests](../../../Tests/ReadyCheckCoreTests/NotchQuotaSelectionTests.swift). | Only Auto may choose automatically. Explicit selections retain labels and show unknown. Update missing/reappearing cases first; align all surfaces and preserve selection across restart. |
| R2 / P0 | Native evaluation accepts only 10/20. Prototype 5% is not native support. [Evaluator](../../../Sources/ReadyCheckCore/Notifications/LowQuotaReminder.swift), [persistence](../../../Sources/ReadyCheckCore/Notifications/QuotaReminder.swift). | Support Off/5/10/20 through UI, validation, storage, evaluation, history and both languages. Test baseline/crossing/retry/account/restart/new-cycle cases; restart or setting changes are not quota recovery. |
| R3 / P0 | Quota history records providerID but no account identity; account-change path does not repartition history. Actual mixed-history behavior requires reproduction. [History](../../../Sources/ReadyCheckCore/Stores/QuotaHistoryStore.swift), [account path](../../../Sources/ReadyCheckApp/App/ReadyCheckApp.swift). | Scope new history to verified identities. Keep unknown ownership separate. Preserve/backup legacy records without guessing ownership or deleting them. Test A→B→A, logout, unknown identity, migration and corrupt files. |
| R4 / P0 | Generic thrown-refresh errors construct an empty-window snapshot, so prototype cached-reading behavior is not implemented. [Store](../../../Sources/ReadyCheckCore/Stores/QuotaStore.swift). | Distinguish transport/auth: retain same-account last-success values/time for temporary transport failure; hide old-account values after auth/identity changes. Stale snapshots never trigger low/recovery alerts. |
| R5 / P0 | Multiple connection, display, reminder and placement preferences already persist. A redesign must not reset habits. | Compare old/new connection/credentials, quota choice, threshold/Off, recovery, style, visibility/position/level, fullscreen, language and login item. Preserve disabled features. Atomic/recoverable migration; test interrupted upgrade, restart and return to old version. |
| R6 / P0 | Native permission/style/history machinery exists and should be retained. [Readiness](../../../Sources/ReadyCheckCore/Notifications/NotificationReadiness.swift). | Centralize actual system state and test result. Separate entry/banner/withdrawal evidence. Cover denied permission, Focus, lock, sleep and restart; account/window/cycle deduplication and fresh-data recovery. |
| R7 / P0 | Existing notch is fixed-height and click opens main; the proposed expanded panel does not exist. [View](../../../Sources/ReadyCheckApp/Views/NotchStatusView.swift), [controller](../../../Sources/ReadyCheckApp/Windowing/NotchWindowController.swift). | Implement the five states below with a bounded state machine. Test actual notch safe area, camera/menu exclusion, fullscreen and display changes; keep menu/widget entry on displays without a notch. |
| R8 / P0 | Existing hover/pin/drag/placement behavior is relied upon. | Preserve first direct inward drag; pinned remains open after outside click/deactivation, explicit unpin restores preview, Escape dismisses. Cover edges, focus, Spaces, unplug/scale changes; disabled windows must not intercept clicks. |
| R9 / P0 | Some reduced-motion/transparency and accessibility labels exist, but full coverage is unverified. | Use text/icons with color, keyboard entry/reading/pin/exit, VoiceOver, reduced motion/transparency, contrast and long bilingual text. Size in logical points; verify 1×/2×. |
| R10 / P0 | Releases cover Mac/Windows; Windows documentation contains historical version examples. | Publish an actual feature matrix and current install/version entries. Verify upgrades, package contents, signatures, versions and latest downloads separately; identify missing devices. Keep signing identity stable and disclose preview-signing limits accurately. |

R1/R2/R4 are confirmed source behavior gaps. R3 is a confirmed model limitation with reproduction pending. R5–R10 are acceptance requirements, not observed failures.

## Five desktop states

[Single-family concept board](prototype/public/assets/widget-notch-concept.png): synthetic design illustration only.

| State | Readings and actions |
| --- | --- |
| Collapsed orb | Keep two rings; center explicit 5h/7d and percentage, branding in expansion. Stable ring meanings and assistive descriptions; selected missing quota displays a dash. |
| Expanded widget | Calm compact card; two quotas/resets/status first. Explicit pin, reminder/main-window entries; consumption secondary. |
| Edge preview | Keep a thin rail with two vertical progress tracks stacked vertically; brief hover reveals labeled quotas, click pins. Explain state and Escape; preserve inward dragging. |
| Collapsed notch | Compact primary reading/bar must join the physical notch bottom as one continuous black silhouette using actual geometry, with no wallpaper seam. Do not obstruct camera/menu space. |
| Expanded notch | Join the physical notch through a continuous black region with no gap or triangular pointer; expand downward for both quotas, resets and status. Click to open; hovering never opens details. Click outside/Escape to dismiss. This differs from the widget's hover preview and explicit persistent pin. Main-window entry available. |

Interaction: retain reasonable hover protection and tune on-device without adding settings. Crossing into the expanded panel must not dismiss it; dragging suppresses expansion. Low/recovery states may briefly announce once; window expansion is not proof of OS notification delivery. Respect reduced motion. If expansion cannot reliably avoid system areas, retain the compact notch entry and withhold defective expansion from release.

## Other journeys and priorities

- P0 onboarding: identify connection source/verification, empty-state next action and optional reminder setup. Request permissions in context. Existing users retain settings and avoid unnecessary relogin/onboarding.
- P0 exit/disconnect: distinguish closing, hiding, quitting and disconnecting. Clarify retained/deleted history and provide recovery after hiding.
- P1 diagnostics: readable error category/source/success time with previewable redacted copy; exclude credentials, private paths and raw responses.
- P1 performance: compare idle/open/repeated refresh/sleep-wake with 0.1.145 on the same device. Record CPU/memory/redraw/listener counts and fix continuous animation, duplicate listeners or clear regressions. Reuse coalescing/backoff; no broader background scanning.
- P1 maintainability: share actual reading/state/format rules across surfaces; extract only repeated logic, keeping each change traceable.
- P2 later: validated pacing, adaptive refresh and richer charts must not delay reliable 0.2.0 delivery.

## Implementation batches and release gates

1. Data correctness: regression cases and minimal R1–R4 fixes; preserve/migrate legacy records.
2. Native main window: connect selected sidebar structure to real services and preserve old preferences/error feedback.
3. Desktop entries: implement five states, test pin/hover/drag separately and inspect native visuals.
4. Lifecycle: initial connection, upgrade, permissions, sleep, displays, quit/reopen; complete R5–R10 evidence.
5. Bilingual docs/version, clean packages, signing and platform-specific remote delivery verification. Show completed work/device gaps. Block release on quota misrepresentation, mixed identities, migration loss, duplicate alerts or stuck windows.

No Hook installation, Codex global-config changes or resurrection of removed external task-control experiments. Automatic suspension/resumption, reset-credit consumption and paid APIs remain out of scope.
