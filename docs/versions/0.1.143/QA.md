# 0.1.143 black-box acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Version index](../../VERSIONS.md)

Status: local 0.1.143 installed and visually accepted on October 13, 2026.

![80% anonymous native component](assets/compact-80-demo.png)

[100%](assets/compact-100-demo.png) · [Zero](assets/compact-zero-demo.png) · [Unknown](assets/compact-unknown-demo.png). These show the actual SwiftUI component with synthetic quotas, not live account screenshots.

| Requirement | Status and evidence |
| --- | --- |
| Percentage clearance | Anonymous renders from the actual SwiftUI component cover 80%, 100%, 0% and unknown, all visually inspected without inner-ring overlap. Installed live bubble also checked. |
| Mark proportions | Collapsed C mark reduced from 24 to 18 points with a 10-point upward offset. Percentage uses 11-point type and an 8-point downward offset. Expanded endpoint mark size and centering unchanged. |
| Scope | Ring/shell geometry, data processing and dragging untouched; expanded Chinese/English native renders retained. |
| Local installation | Standard script and stable preview signing produced 0.1.143. Staged and installed bundles pass strict signing verification with matching executable SHA-256; previous app backed up. User completed system Keychain authentication; fresh quota readings at 09:56 China Standard Time and live bubble/details checked. |

Validation: full 273 Swift tests pass with no failures/skips; native render inspection, version consistency, document links, diff whitespace and sensitive-information checks pass. Commands: `swift test --build-system native --scratch-path <temporary directory>`, `scripts/check_release_consistency.sh`, `scripts/package_app.sh`, `codesign --verify --deep --strict`.

Completed: compact layout, 80/100/0/unknown native renders, local installation and visual acceptance, account recovery and bilingual documentation. This release also includes the [0.1.142 direct-drag acceptance](../0.1.142/QA.md). Real-environment checks remaining: other screen scales and macOS 14 devices; no new Windows behavior or real-device acceptance.

Final public snapshot: all 273 Swift tests pass without failures/skips. Windows syntax/functional/UI checks and packaging pass under Node 24. Mounted DMG reports 0.1.143 and passes strict stable-preview signing verification. Windows ZIP integrity passes; ASAR reports 0.1.143 and excludes tests, internal agent folders and development dependencies. Artifact directory contains only the current DMG and Windows ZIP. Public source and public-ancestor history privacy checks pass; five apparent private-path hits were the scanner's own regex, with no actual private paths or credentials.

Public release complete: [0.1.143 Release](https://github.com/whnnick/readycheck/releases/tag/v0.1.143). The public annotated tag resolves to source `f71a656ce3b120bed4d1a95683d8f06bc7907c95`. Latest is v0.1.143, neither draft nor prerelease, with exactly two uploaded packages. Windows workflow [38335610302](https://github.com/whnnick/readycheck/actions/runs/38335610302) built and uploaded successfully from the same source. Both remote files were downloaded; sizes and SHA-256 match GitHub digests. Remote Windows ZIP integrity, ASAR version and contents also checked. Both public download links return HTTP 200. No incomplete items or blockers remain for this preview release.

- macOS DMG SHA-256: `34b31a3aa5066a7194cd19b54501936b3ae440007150d5007fb030edf0b4daf2`
- Windows ZIP SHA-256: `958d822c66768fa76d750f356caae6b8608c6fb7703ab924b62fc34ae2b409fa`
