# 0.1.128 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.127 acceptance](../0.1.127/QA.md)

Status: 0.1.128 preview release. The macOS DMG uses the stable preview identity and is not Developer ID signed or notarized.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Separate OAuth sign-in restores daily Token history for the same local Codex account | Passed locally | The 0.1.128 preview showed the daily Token chart and account totals while quota cards continued to identify OAuth API as their source. A read-only local app-server probe returned 133 daily buckets. |
| Another local account cannot supply Token history to the OAuth account | Passed in tests | Provider tests verify exact account-ID matching, even when email matches; unmatched history is omitted and the percentage-point chart remains the fallback. |
| Hovering a Token bar shows its date and Token count | Implemented; pointer check pending | The existing Token chart retains its hover tooltip implementation. Computer UI automation confirmed populated bars but did not generate a native hover event; a physical-pointer check remains open. |
| Build, tests, version and signature | Passed | 205 core and 4 app tests passed in the public sync checkout. Both release assets passed integrity checks, and the DMG app passed strict signature verification. |
| Public release | Published | [GitHub Release v0.1.128](https://github.com/whnnick/readycheck/releases/tag/v0.1.128) includes the macOS DMG and Windows portable ZIP; latest and asset download were verified. |
