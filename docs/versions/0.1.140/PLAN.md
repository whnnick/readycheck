# 0.1.140: clear detail pin

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Versions](../../VERSIONS.md)

| Requirement | Success criterion |
| --- | --- |
| Purpose | Tooltips explain keeping details open after pointer exit, distinct from window always-on-top. Separate wording for kept-open and preview states, Chinese and English. Permit tooltips while the application is inactive. |
| Feedback | Pin stays visible; blue filled pin and accessibility state when kept open. Generic container help does not override button help. |
| Toggle | Preview → kept open; kept open → hover preview. Pointer exit closes only preview. Cancel pending timers and release panel keyboard focus on unpin; collapsed/dragging states cannot toggle. Preserve outside/Esc dismissal and existing layout. |

Scope: macOS pin usability and the preceding widget refinements, with Windows version metadata synchronized. Release source and fresh 0.1.140 artifacts for both platforms using the standard release workflow. Previously generated 0.1.139 packages are not 0.1.140 artifacts.
