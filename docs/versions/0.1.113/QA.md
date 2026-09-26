# 0.1.113 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.112 acceptance](../0.1.112/QA.md)

Release target: `v0.1.113`. This checklist records tested behavior and remaining real-world visual checks.

| Requirement | Status | Evidence |
| --- | --- | --- |
| No square edge outside the round bubble, left/right edge capsule, or expanded card | Complete for tested forms; dark-background and left-edge visual checks pending | AppKit masks the whole floating window to the active silhouette. The surface is solid and has no outer shadow. The signed installed 0.1.113 app was visually checked as a round bubble, right-edge capsule, and expanded card on a light background. Left and right capsules share the same mask; the left edge was not separately placed for this check. |
| Existing quota colors, text, drag, and expand/collapse behavior | Complete for tested paths | The installed app reconnected to the local Codex account, displayed both quota windows, and expanded/collapsed from the round bubble and right-edge capsule. Dragging from the right-edge capsule to the round bubble worked. All 197 core and 4 app Swift tests passed under normal local permissions; the release consistency check passed. |
| Public release | Complete | [GitHub Release v0.1.113](https://github.com/whnnick/readycheck/releases/tag/v0.1.113) is public, not a draft or prerelease, and is the latest release. Its tag points to release commit `8587aa4`. The uploaded DMG and Windows ZIP have SHA-256 digests `63e1a79a52e5258e262355022d38b68dc01168373acae0ca4b294010b304efda` and `6941cdcb9b2d96f656b08a6dd85830a521caf2b1fe5848149cdf3a27c0028cbc`, matching the locally verified packages. |
