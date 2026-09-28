# 0.1.126 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.125 acceptance](../0.1.125/QA.md)

Status: macOS local preview; not published.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| The app icon uses the selected single C-shaped progress motif | Passed locally | Inspected the rendered 1024px master and 16px and 32px reductions. The icon is a fixed identity mark, not a live quota indicator. |
| Main header and About window use the packaged icon | Passed locally | Inspected both windows in the 0.1.126 packaged preview. |
| Packaging and version references | Passed locally | Swift tests, version consistency, a generated `.icns` resource, strict code-signature verification, and changed-line sensitive-data scan passed. The sandboxed `iconutil` attempt failed; running it with normal system permissions succeeded. |
| Real-account refresh in this temporary preview | Not passed | The ad-hoc preview could not read the existing Keychain item. The local preview certificate is currently untrusted by macOS, so signing with it did not provide a viable alternative. The previous installed version was restored and continued to read the account. Resolve before installing or releasing 0.1.126. |
| Public release | Not included | Publishing requires a trusted release signing identity and separate release checks. |
