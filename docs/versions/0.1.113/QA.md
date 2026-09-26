# 0.1.113 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.112 acceptance](../0.1.112/QA.md)

Release target: `v0.1.113`. This checklist records tested behavior and remaining real-world visual checks.

| Requirement | Status | Evidence |
| --- | --- | --- |
| No square edge outside the round bubble, left/right edge capsule, or expanded card | Complete for tested forms; dark-background and left-edge visual checks pending | AppKit masks the whole floating window to the active silhouette. The surface is solid and has no outer shadow. The signed installed 0.1.113 app was visually checked as a round bubble, right-edge capsule, and expanded card on a light background. Left and right capsules share the same mask; the left edge was not separately placed for this check. |
| Existing quota colors, text, drag, and expand/collapse behavior | Complete for tested paths | The installed app reconnected to the local Codex account, displayed both quota windows, and expanded/collapsed from the round bubble and right-edge capsule. Dragging from the right-edge capsule to the round bubble worked. All 197 core and 4 app Swift tests passed under normal local permissions; the release consistency check passed. |
| Public release | Requested; verify after publishing | Publish the signed macOS DMG and Windows portable ZIP to GitHub Release `v0.1.113`, then verify the latest-release API and asset names. |
