# 0.1.104 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.103 acceptance](../0.1.103/QA.md)

Local macOS preview. Public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Capsule-to-bubble transition | Complete on macOS 27 | In the installed 0.1.104 app, dragging the right-edge capsule inward produced a round bubble with no lingering capsule outline in the resulting frame; dragging it back restored the capsule. The code removes the implicit cross-fade and old-outline window resize. The brief transition was not video-captured frame by frame. |
| Existing motion and drag | Complete on macOS 27 | Live drag worked in both directions and returned to the original right-edge capsule. Expansion and collapse keep their transitions. |
| Regression | Complete | 197 Core and 4 App Swift tests, Windows checks, and release consistency passed. The installed 0.1.104 executable SHA-256 matches the local package. |
| Public release | Pending | No GitHub push or Release requested. |
