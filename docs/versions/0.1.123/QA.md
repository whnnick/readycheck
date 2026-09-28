# 0.1.123 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.122 acceptance](../0.1.122/QA.md)

Status: local macOS preview; not published.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| “Open ReadyCheck” is visibly a link | Passed in the live preview | In the signed 0.1.123 app, the expanded detail card shows a blue “Open ReadyCheck” link on the dark surface. The label uses the same explicit blue as the existing bubble link. |
| Narrow capsule expands after half a second | Implemented; hands-on timing check pending | The cancellable hover task now waits 500 ms, then verifies the pointer is still over the narrow capsule. Clicking still opens it immediately. A real mouse timing and early-exit check remains necessary. |
| Build and privacy | Passed locally | 204 core and 4 app tests passed. Version consistency, signed local packaging, signature verification, and changed-line sensitive-data scan passed. |

No public release is included in this local preview.
