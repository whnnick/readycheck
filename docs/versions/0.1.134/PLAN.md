# 0.1.134: reset countdowns and widget interaction

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Versions](../../VERSIONS.md)

Goal: show the time until a quota reset and give bubble / edge-ring interactions consistent intent.

| Requirement | Scope |
| --- | --- |
| Reset countdown | Show days, hours and minutes from each window's official resetAt in bubble and edge details, updating every 30 seconds. The tooltip retains the absolute reset time. Only current, available, verified OAuth/app-server data qualifies. Missing, stale or estimated data stays unconfirmed; an elapsed deadline waits for refresh confirmation. |
| Half-second hover preview | Preview bubble details or the large edge-ring capsule. Brief passes and dragging do not expand. Leaving dismisses a preview after 200ms; re-entering cancels dismissal. Explicitly revealing rings still starts with the large capsule. |
| Click to keep details open | Clicking a bubble, its preview or the whole edge capsule keeps details open after pointer exit. Close via outside click, collapse button or Esc while details have keyboard focus. Explicit dismissal requires pointer exit before another hover preview. |
| Existing styles | Retain freely draggable bubbles, left/right edge rings, cards and notch status. Slightly increase bubble detail height; additional quota windows remain scrollable. |

No fullscreen hiding, usage prediction, new providers, extra network polling or inference requests. The separate notification-icon issue was confirmed resolved on this Mac by the user after a restart on October 10; this preview is not automatically published.

Validate time boundaries, freshness and source, both languages, canceled hover, pinned details, dragging and timer cleanup; then inspect the stable-signed installed app with real quotas.

Technical references: [Apple TimelineView](https://developer.apple.com/documentation/swiftui/timelineview), [nonactivating panels](https://developer.apple.com/documentation/appkit/nswindow/stylemask-swift.struct/nonactivatingpanel).
