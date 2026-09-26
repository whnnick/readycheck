# 0.1.114 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.113 acceptance](../0.1.113/QA.md)

Release target: `v0.1.114`. This checklist separates verified behavior from the remaining motion-capture limitation.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Explain the two account sources without requiring knowledge of OAuth | Complete for tested paths | Both Chinese selector states and their explanations fit in the stable-signed 0.1.114 installed app. Local mode read the Mac's signed-in Codex account; switching back restored the original separate sign-in and quota. |
| Preserve existing credential handling | Complete for tested paths | The installed app recovered the saved account after one interactive Keychain retry on first launch. A full quit and relaunch then restored the account and refreshed both quota windows automatically. No credential was deleted. |
| Remove the outline flash during bubble expansion and collapse | Resting forms verified; in-flight frames not captured | The clipping path interpolates inset and corner radius with animated window width, and the full-surface opacity/scale transition is removed. The stable-signed installed app expanded and collapsed from the round bubble and both edge capsules; each resting outline was correct. The available screenshot tool captures only completed states, and QuickTime did not produce a usable recording, so a one-frame visual artifact cannot be ruled out. |
| Validation | Passed | All 197 core and 4 app Swift tests passed under normal local permissions, including the OAuth loopback test. `scripts/check_release_consistency.sh` passed; the stable-signed 0.1.114 installed app passed `codesign --verify --deep --strict`. |
| Public release | Complete | [v0.1.114](https://github.com/whnnick/readycheck/releases/tag/v0.1.114) is public and is GitHub latest. The mounted DMG contained only the 0.1.114 app and passed strict signature verification; the Windows ZIP passed integrity checking. GitHub asset SHA-256 digests match the final local packages: macOS `d5c1648048e6f3a5b5f2eaffadcb13b35c85a576ac93ea0f365a712f9862add2`, Windows `78d0b2935b5f1112d22521888207328c293b7da36c513bc875a2cee4d09eccae`. |
