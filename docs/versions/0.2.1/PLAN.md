# 0.2.1: adaptive Widgets and consistent interaction

[中文](PLAN.zh-CN.md) · [Black-box checks](QA.md) · [Version index](../../VERSIONS.md)

Release 0.2.1 combines the validated development changes below. See [release notes](RELEASE_NOTES.md) and [functional checks](QA.md). Earlier preview descriptions are historical scope records.

Initial scope on 2026-10-16: local preview `0.2.1-dev.1`, with public download still at 0.2.0. The paragraphs below describe that earlier patch validation.

The edge-attached Widget must unfold directly from its vertical rail into details and return to that rail. It must not briefly display the free-floating quota dial. Keep the selected screen edge anchored and preserve hover/pin, outside-click rules, inward dragging, Escape and the last-hour chart. Free-floating dial behavior stays the same.

The controller retains attachment during expansion/collapse; the attached surface blends rail/details within one rounded shell. Edge open/close timings are 220/180 ms, using the existing native window animator. The existing reduced-motion branch still avoids window-size animation. Development About links to the currently published release rather than an unpublished development tag.

Acceptance: reproduce the old state-loss regression first, then test both edges and rapid reversal; inspect native intermediate frames and the real package. Keep user settings/history/credentials. Document reduced-motion and hardware cases that are not observed rather than claiming them passed.

[Campaign delivery](PROMO.md) — 2026-10-17.

## 0.2.1-dev.2: preview background clicks

2026-10-17. A hover-opened detail is an unpinned preview; no persistent hover setting is changed. Clicks on its outer padding previously missed the keep-open gesture, including while the native surface was expanding. Add the same pin action to the painted background of free and edge-attached surfaces. Preserve child-control actions, explicit unpin, outside dismissal, dragging and the previous edge animation fix.

Acceptance: reproduce a failed native padding-click assertion before the patch; check free/left/right placements at expanded and intermediate sizes, repeated background clicks and existing pin/unpin/drag coverage. Run the full suite, then build and inspect the signed local app. Public download remains 0.2.0.

## 0.2.1-dev.3: card movement and matching style selection

2026-10-17. Provide a native title drag region for the card, excluding refresh/close buttons and the display-mode switcher. Keep existing frame persistence and window-level settings. A round-style selection must restore a circle even from an old attached position; selecting the edge style or moving it to the other side starts with its slim strip. Manual round-bubble edge snapping and an explicitly requested ring preview remain available. Validate native drag dispatch, position restoration, saved-edge round restoration and strip/detail transitions, then inspect the installed package.

## 0.2.1-dev.4: one adaptive floating Widget

2026-10-17. Supersede dev.3's separate round/edge selections with one floating Widget. At rest away from the edge it is a circle; dragging it to either edge produces the slim vertical strip, and dragging inward restores the circle. Both use the same native window, interaction controller, detail content, last-hour chart and pin/unpin rules. The separate information card retains native title dragging and its own position.

Settings offer Floating widget and Information card. Migrate the previous edge-strip choice to the floating Widget once, preserving side and vertical position. Retain the old rail frame and back up any replaced bubble frame; invalid legacy geometry must not overwrite a valid bubble position. Do not alter credentials, account history, visibility or card settings.

Inspect outer contours for circle, rail and intermediate expansion at native scale. Keep the shared supersampled native mask; use an inset attached border so the native mask does not cut off half of its stroke. Verify both edges, inward drag, common pinned details, refresh, relaunch and the signed installed development build. Public download remains 0.2.0; Windows receives version metadata only.

## 0.2.1-dev.5: release information belongs in About

2026-10-17. Remove the duplicate release highlights from Settings → Connection. Keep the existing full highlights and release-notes link in About, reachable from the persistent sidebar and app menu, and retain connection guidance and Settings → General update checks. No new automatic popup or notification is introduced. Verify bilingual native rendering, the installed connection page and About entry. Windows metadata only; no public release.
