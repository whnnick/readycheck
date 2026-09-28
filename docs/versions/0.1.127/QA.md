# 0.1.127 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.126 acceptance](../0.1.126/QA.md)

Status: macOS local preview; not published.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| The menu bar uses the C mark as a monochrome template | Implemented; visual check pending | The status item now draws the same C silhouette as a template image. The macOS menu bar was not exposed to computer UI inspection, so light and dark appearance remain to be checked. |
| The menu popover uses the same app identity as the main and About windows | Implemented; visual check pending | The popover header loads the packaged app icon. Its live popover could not be opened through computer UI inspection. |
| No old gauge identity remains in macOS UI | Passed locally | The old gauge symbol has no references in the macOS app sources. The packaged main window shows a refresh symbol for refresh status; the quota selector uses a chart symbol. Provider icons in widgets retain their separate meaning. |
| Build, tests, version and signature | Passed locally | Swift tests, version consistency, `.icns` packaging, strict code-signature verification, and changed-line sensitive-data scan passed. |
| Real-account access in the 0.1.127 preview | Not passed | The temporary preview could not read the existing Keychain credential after retry. Do not replace a working installed app or rely on this preview for quota reminders until access is restored. |
| Public release | Not included | Requires trusted release signing and separate release checks. |
