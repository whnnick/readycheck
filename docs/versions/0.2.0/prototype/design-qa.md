# ReadyCheck 0.2.0 preview design QA / 交互稿设计检查

Date: 2026-10-15. Scope: selected first sidebar concept and synthetic web prototype. Native application not changed.

## Comparison target / 比对目标

- Source visual truth: [overview-concept.png](../assets/overview-concept.png), 1487×1058 pixels, normalized to 1440×1024.
- Implementation: [overview-preview.png](../assets/overview-preview.png), browser viewport 1440×1024 CSS px, DPR 1, 1440×1024 screenshot pixels.
- State: Overview, normal synthetic 5h 80% / 7d 70%, Chinese, dark appearance; no dialog or toast.
- Full-view evidence: local `qa/comparison-initial.png` and `qa/comparison-final.png` place source and actual browser capture in one comparison image.
- Focused evidence: local `qa/comparison-quota.png` compares quota typography, labels, bars and timing from the same full-view captures. Images were opened and inspected.
- Responsive evidence: local `qa/overview-740.png` and `qa/overview-390.png`. Viewports 740×792 and 390×844, DPR 1. Initial transient viewport capture was rejected; recaptured after layout confirmation. No DOM horizontal overflow.

## Findings and revisions / 问题与修正

Initial result: blocked while state extensions were being reviewed. The selected concept only specified the normal overview; error and interactive states required additional review.

1. [P2] Synthetic hourly consumption exceeded the amount used in the normal window. Reduced coherent sample values while retaining twelve five-minute buckets. Final overview and focused comparison inspected.
2. [P2] Authorization-required state showed a healthy dot and could expose zero-valued progress semantics. Changed dot to neutral and omitted numeric progress value; browser confirmed missing value and unknown label. Post-fix `qa/auth-final.png` inspected.
3. [P2] Offline chart included samples after the last successful 19:42 reading. Cut samples at 19:40, retained original timestamp, added cutoff caption; browser confirmed 19:55 absent. Post-fix `qa/offline-final.png` inspected.
4. [P2] Primary quota selection could be contradicted by fixed numeric artwork in the floating preview. Kept true native appearance references in style choices and changed the interaction preview to live selected quota data. Browser confirmed 7d→70%, pin/outside click and unpin/outside dismissal after fix.

## Required fidelity surfaces / 五项检查

- Typography: native system/PingFang fallback, clear quota dominance and readable small labels. Small optical-weight differences from generated concept remain P3, not a claimed pixel-identical recreation.
- Layout: fixed sidebar, parallel quotas, consumption, reminder entry and footer retain selected hierarchy. Mobile stacks quota rows; persistent navigation/footer stay visible. Narrow content scrolls intentionally.
- Colors: charcoal surfaces, green quota, blue actions and red/amber exceptions preserve semantic intent. Flat browser surfaces replace simulated glass lighting. This is an explicit web-preview simplification; native material remains to implement.
- Assets: supplied ReadyCheck icon and existing synthetic native components are used; standard icons come from Phosphor and charts from Recharts. No fabricated brand glyphs or private screenshot assets.
- Copy/content: duplicate percentages removed; percentage points separated from Tokens; dates anchored to 2026-10-15; all simulations explicitly labeled. No automatic task-control capability advertised.

## Interaction evidence / 交互检查

Verified navigation, 5% threshold/recovery state in overview, simulated notification permission repair/test, history ranges/incomplete coverage, chart ArrowRight tooltip, loading/refresh, low/recovered/unknown/auth/offline states, user-initiated repair, widget primary selection/pin/unpin/hide/restore, dialog Escape and Shift-Tab containment. Browser console error/warn query returned no entries.

P3 follow-up: refine native typography/materials when porting to SwiftUI. Full VoiceOver, real notifications, OS window management, persistence across app restarts and all real integrations remain outside this prototype.

## Implementation checklist / 收尾

- Selected layout implemented and source/capture compared together.
- P2 state issues corrected and checked again in the browser.
- Production build and document/link/privacy checks completed.
- Native implementation and release are explicitly pending.

final result: passed


## preview.2 additive check / 新增方案入口

The original overview layout is unchanged. New Settings→Display action opens the same-family five-state visual board, explicitly labeled as a design concept. Source: `public/assets/widget-notch-concept.png` (1448×1086). The captured dialog at a 1042×977 CSS viewport reports DPR 2; the screenshot API emits 1042×977 pixels. Board region is 940×705 CSS px at x51/y134.15. Local `qa/surfaces-comparison.png` normalizes source and browser region to 940×705 and puts them together for comparison; source/capture/comparison were opened. Image proportions and content are intact, no substituted assets or clipped specimen. New entry, image load, dialog Escape and console error/warn query passed. Production build passed with the already documented chunk-size advisory. No new actionable P0/P1/P2 visual findings; native geometry, notch safe-area behavior and the cross-version source gaps remain pending. Full review: [English](../UPGRADE_REVIEW.md) / [中文](../UPGRADE_REVIEW.zh-CN.md).

final result: passed

P3 capture note: greens appear lighter in the browser capture than in the source comparison. The image file is unchanged; native color appearance remains a real-device check.

## preview.3 correction

Source board inspected: both notch states join the hardware notch with no wallpaper gap; edge handle has stacked vertical tracks. Other concepts retained. Updated board is included in the build. Browser reloaded the versioned image URL, confirmed loading and captured qa/surfaces-corrected.png. The capture was inspected: continuous black notch joins and stacked vertical edge tracks are visible. Build passed; native geometry remains pending.

final result: passed
