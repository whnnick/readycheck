# 0.1.120 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.119 acceptance](../0.1.119/QA.md)

Status: local macOS preview; not published.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Recover the edge rings after moving away | Passed in the live preview | The signed app opened with both real Codex rings visible. After the panel collapsed, a 32-point edge target retained the icon and two status bars; clicking it reopened the rings. Detail expansion was also observed. Handle dragging still needs a separate manual check. |
| Switch between left and right without dragging across the screen | Passed in the live preview | The Left/Right setting changed from Left to Right, and the right-side dock and inward detail card were visually inspected. The Show rings action is available; its hidden-widget path still needs a separate manual check. |
| Keep the original round bubble available | Passed in the live preview | Selecting Round bubble replaced Edge rings. Its saved edge position first appeared as the existing side tab; Reset position restored the circular bubble, which was visually inspected. |
| Regression, package, and security | Passed locally | All 204 core and 4 app tests passed; release version references matched 0.1.120; a stable-signed local app passed `codesign --verify --deep --strict`. Sensitive-data scan is recorded in the local commit review. |

Publication remains separate from this local preview.
