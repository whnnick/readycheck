# 0.1.122 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.121 acceptance](../0.1.121/QA.md)

Status: local macOS preview; not published.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| One detail action for the whole large capsule | Passed in the live preview | The large capsule exposes one “Show quota details” button. Activating it shows both the 5-hour and 7-day rows, then changes the action to “Hide quota details”. The per-ring click highlight and selection state were removed. A real pointer check of every part of the capsule remains useful. |
| Narrow capsule reveals rings after one second of hover | Implemented; hands-on timing check pending | A cancellable one-second task starts on pointer entry, checks that the pointer remains inside the narrow panel, and opens the rings. Pointer exit cancels it; clicking still opens immediately in the live preview. The computer-control interface could verify the click but could not reliably generate a hover-only mouse-enter event. |
| Other widget styles and placement | Preserved by scope | Round bubble, card, notch, and left/right placement code is unchanged. |
| Build and privacy | Passed locally | The full test suite, release-version consistency check, signed local app packaging, and signature verification passed. Sensitive-data scan is part of the local commit review. |

The one-second hover feel, early pointer exit, and both screen edges still need a real mouse check before a public release.
