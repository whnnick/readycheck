# 0.1.124 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.123 acceptance](../0.1.123/QA.md)

Status: local macOS preview; not published.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| English account-source label stays readable | Passed in signed local preview | The label appears on its own line above the segmented choices in version 0.1.124. |
| Both account-source choices stay readable | Passed in signed local preview | Both English options fit on one line without changing the selected account source. |
| Chinese layout remains clear | Passed in signed local preview | The same card was inspected in Chinese, and the original Chinese language preference was restored. |
| Build and privacy | Partially passed locally | Full Swift test suite, release-version consistency, local preview packaging, and changed-line sensitive-data scan passed. Independent strict signature verification returned `CSSMERR_TP_NOT_TRUSTED` because the preview certificate is not currently trusted on this Mac; verify with a trusted signing identity before release. |

No public release is included in this local preview.
