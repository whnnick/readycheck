# 0.1.106 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.105 acceptance](../0.1.105/QA.md)

Local macOS preview. Public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Clear display-control groups | Complete on macOS 27 | The installed app showed distinct Desktop widget and Notch display panels in both Chinese and English without clipped labels. Each visibility switch, style or quota choice, and reset action sits with its related feature. Accessibility exposes each group as a labeled container. |
| Existing settings behavior | Complete for visual and style selection | Bubble/Card selection was exercised; Minimal/Detailed appeared only in Card mode. The original Chinese and Bubble preferences were restored. Visibility, always-on-top, position reset, notch visibility, and notch quota keep their previous bindings; their side effects were not re-exercised. |
| Regression | Complete | 197 Core and 4 App Swift tests, Windows checks, and release consistency passed. The installed 0.1.106 executable SHA-256 matches the local package. |
| Public release | Pending | No GitHub push or Release requested. |
