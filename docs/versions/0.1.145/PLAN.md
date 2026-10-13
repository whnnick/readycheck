# 0.1.145: Smooth native edges and a current project homepage

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Version index](../../VERSIONS.md)

The compact bubble shows rough curved edges. Improve the native window silhouette without changing quota handling, ring/mark sizes, pin persistence or direct inward dragging. Then refresh both GitHub README languages around the latest native UI, useful downloads and clear evidence.

| Requirement | Success criterion |
| --- | --- |
| Curved edge coverage | Native compact, edge-tab and expanded silhouettes preserve antialiased fractional coverage at the current screen resolution. |
| Behavior | Existing geometry, pinned/outside-click and direct-drag regressions pass. |
| Current homepage | Both languages show current native demo components, explain the benefit, distinguish platform support and provide verified download/documentation entries. |
| Privacy | Public visuals use synthetic data; private screenshots, account values, local paths and internal collaboration files stay out of the public repository. |
| Bilingual delivery | Commit descriptions, Release notes, README and changelog are provided in Chinese and English. |

Validation uses the native regression suite, real app screenshots and visual inspection, package/signature checks and remote verification. Automated layer/geometry checks alone do not prove the final macOS compositor appearance. Real 1× external displays and macOS 14 devices remain separate acceptance conditions when not available locally.
