# 0.1.103 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.102 acceptance](../0.1.102/QA.md)

Local macOS preview. Public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Native glass for floating quota surfaces | Complete on macOS 27 | The installed 0.1.103 app displayed the edge capsule, expanded card, and existing floating card with system Liquid Glass on macOS 27; the icon and green/red quota bars remained legible. Older systems retain material, and Reduce Transparency uses a solid system background. The notch silhouette is unchanged. |
| Motion and direct manipulation | Complete for live expand/collapse; drag snap code reviewed | Live expansion and collapse left the card uncropped and returned to the capsule. The controller animates snap only after drag release; active dragging still follows the pointer directly. Reduce Motion removes window movement and uses a short content fade. Drag snap and accessibility settings were code-reviewed but not separately exercised in the UI. |
| Regression | Complete | Swift tests, Windows checks, and release consistency checks passed. The installed app reports 0.1.103 and its executable SHA-256 matches the local package. |
| Public release | Pending | No GitHub push or Release requested. |
