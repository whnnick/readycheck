# 0.1.109 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.108 acceptance](../0.1.108/QA.md)

macOS preview published on 2026-09-24.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Remove excess bottom space in Desktop widget settings | Complete | The Widget group no longer has a minimum height. In the installed app, Bubble mode ends after the style control with only the regular 14 pt card padding. |
| Bubble and Card presentations | Complete | Visually inspected both presentations in the installed 0.1.109 app: Card mode shows its extra controls without clipping, and Bubble mode shrinks again. The original Bubble choice was restored. |
| Build and version consistency | Complete | Public-sync Swift tests passed (197 Core and 4 App), release version references passed, and the Windows package passed check, smoke, and UI smoke. The 0.1.109 DMG contains an app signed by ReadyCheck Preview Signing and passes strict code-sign verification; the Windows ZIP passes integrity testing. |
| Public release | Complete | [GitHub Release v0.1.109](https://github.com/whnnick/readycheck/releases/tag/v0.1.109) is published, not a draft. The latest-release endpoint returns v0.1.109; the tag resolves to commit `02efec5`, which is on remote `main`. Both assets are uploaded and their GitHub SHA-256 digests match the local packages below. |

| Release asset | SHA-256 |
| --- | --- |
| `ReadyCheck-0.1.109-macos.dmg` | `e0358634dde3dd6ecb31263ccd1492e6dc35e49bf983bc064acaafb451984e40` |
| `ReadyCheck-0.1.109-windows-x64-portable.zip` | `1ceee5786ab97aadfb9e303b51ffe1d07f3699bf6b0d4c21c78a928db64852f0` |
