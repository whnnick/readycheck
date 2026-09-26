# 0.1.110 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.109 acceptance](../0.1.109/QA.md)

Local macOS preview. Public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Bubble, edge capsule, and expanded card remain readable over different apps | Partially complete | All three shapes share the same dark frosted background, fixed light foregrounds, and existing quota colors. The signed 0.1.110 app's edge capsule and expanded card were visually readable on a light background. Dark and colorful backgrounds, plus the round resting shape, still need direct visual acceptance. |
| Reduce Transparency | Implemented; system-setting test pending | The surface code uses an opaque dark fill when the system setting is enabled. The setting was not changed during this pass. |
| Interaction and version integrity | Complete for tested paths | The installed 0.1.110 app opened and collapsed the quota card, reconnected to the signed-in local Codex account, and refreshed real quota data. All Swift tests passed from a clean temporary build directory, and the release version-reference check passed. The installed executable SHA-256 matched the signed preview package; strict code-sign verification passed. Dragging and docking were covered by existing placement tests but were not manually repeated. |
| Public release | Not requested | No GitHub push or Release requested for this preview. |
