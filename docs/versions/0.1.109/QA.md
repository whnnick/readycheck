# 0.1.109 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.108 acceptance](../0.1.108/QA.md)

macOS preview release candidate. Public release was requested after local acceptance.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Remove excess bottom space in Desktop widget settings | Complete | The Widget group no longer has a minimum height. In the installed app, Bubble mode ends after the style control with only the regular 14 pt card padding. |
| Bubble and Card presentations | Complete | Visually inspected both presentations in the installed 0.1.109 app: Card mode shows its extra controls without clipping, and Bubble mode shrinks again. The original Bubble choice was restored. |
| Build and version consistency | Complete | Public-sync Swift tests passed (197 Core and 4 App), release version references passed, and the Windows package passed check, smoke, and UI smoke. The 0.1.109 DMG contains an app signed by ReadyCheck Preview Signing and passes strict code-sign verification; the Windows ZIP passes integrity testing. |
| Public release | Pending remote verification | Source, tag, both assets, and the GitHub latest-release endpoint must be checked after publication. |
