# Aggregate capsule — dev.32 design contract

[中文](AGGREGATE_CAPSULE.zh-CN.md) · [Acceptance](QA.md)

Reference: the user's five Token Monitor screenshots and the project's [official Edge Dock showcase](https://github.com/Javis603/token-monitor#showcase), checked 2026-11-08. Reference the information hierarchy and aggregate interaction; no source code, assets, synced-device features or account data are copied.

## dev.33 interface refinement

Codex now labels the 5h and 7d readings separately. The active row has a service-colored outline and shows a pin when its detail is pinned. The footer ellipsis opens an action menu above a separate drag grip. A temporary preview also closes when the pointer leaves through the header, grip or space around the menu. The rail remains 84 × 392 points. The detail fades in while moving six points away from the rail and fades out on dismissal. Pinning and refreshing do not replay the animation. Reduce Motion switches the detail instantly.

## dev.32 design baseline

1. One persistent vertical capsule, 84 × 392 points, shows Codex, DeepSeek and Muse together. Codex is first. Each service uses the same 48-point icon/ring footprint, numeric scale, spacing and graphite glass shell. The installed dev.32 uses the aggregate presentation on this Mac. The dial and card are available in Display settings.
2. Codex retains two meaningful rings for 5h/7d remaining quota, with both values labeled. Muse has one weekly ring. DeepSeek has a neutral outline with currency and balance, never a fabricated remaining percentage. Unknown, stale, error and disconnected readings stay explicit. No incomparable sum, invented Token count, session count or tok/s appears.
3. Hover or ordinary click previews the corresponding detail beside the rail; the aggregate stays visible. Hover does not change the main-window service. Only the labeled pin control pins; unpin/exit/Escape/outside click follow the existing interaction rules. Open-main and settings actions target the viewed service.
4. Drag by the top/bottom grip, clamp to the screen and snap at either side. Keep a separate saved aggregate frame seeded from the previous bubble center; preserve legacy positions and display/fullscreen/snooze settings. Detail is clamped and opens toward available space. No focus stealing for previews.
5. Finish gate: all three data types render in both languages; no overflow or private account screenshots in evidence; verify selection, side placement, explicit pin, dismissal, saved position, full-screen flags and old bubble behavior. Install only after focused regression and signature checks. No public push/tag/Release.
