# 0.1.112 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.111 acceptance](../0.1.111/QA.md)

Local macOS preview; public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| No square translucent backing outside round bubble, edge capsule, or expanded card | Failed in later user review; superseded by 0.1.113 | The light-background check missed a remaining square edge. The user still saw it after installing 0.1.112. See [0.1.113 acceptance](../0.1.113/QA.md). |
| Existing quota colors, contrast, and interaction | Complete for tested paths | The installed app reconnected to the local Codex account, displayed both quota windows, and expanded from and collapsed to the edge capsule; green quota colors and blue link remained visible. The release consistency check passed and all 197 core and 4 app Swift tests passed under normal local permissions. |
| Public release | Not requested | This version remains local until a release is requested. |
