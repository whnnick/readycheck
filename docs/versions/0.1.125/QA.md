# 0.1.125 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.124 acceptance](../0.1.124/QA.md)

Status: macOS local preview; not published.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| App icon has a distinct two-window mark without a check or gauge | Passed locally | Inspected the 1024px master and 16px, 32px, and 64px renderings. The icon uses a fixed mark; no quota value is baked into it. |
| Main header and About window use the same icon | Passed in 0.1.125 preview | Inspected both windows in the packaged app, then closed the temporary preview instance. |
| Packaging and version references | Passed locally | Full Swift tests, release-version consistency, ad-hoc local packaging with an `.icns` resource, strict code-signature verification, and changed-line sensitive-data scan passed. |
| Public release | Not included | The local preview is ad-hoc signed. Use a trusted release signing identity and complete release checks before publication. |
