# ReadyCheck 0.7.5 verification

[简体中文](QA.zh-CN.md) · [Changelog](../../../CHANGELOG.md)

## 0.7.5 stable

- [Release scope](RELEASE_NOTES.md) covers the aggregate capsule and main-window focus. The installed app passed mouse and arrow-key navigation in the sidebar and Settings. The native window regression checks that mouse-down hides the marker before the receiving view handles the event.
- The public-source Swift suites ran 562 cases with no failures and 3 opt-in skips. All 14 Muse reader cases passed.
- With live Muse quota, clicking beside the service icon opened its detail. Dragging the row moved the rail without selecting the service. The reverse drag restored its saved edge and original vertical center. Native event tests cover first-drag movement from either screen edge, pointer jitter and the separate menu target.
- The mounted DMG passed version, signature, resource, image and binary privacy checks. ReadyCheck 0.7.5 launched after its build directory was moved away.
- The Windows package passed Node 24 service, application and UI checks, ZIP integrity and the comparison of 16 embedded app source files. Windows application logic is unchanged from 0.7.4. The original Windows device with OAuth 403 remains unavailable for a live-account retest.

## 0.7.5-dev.2 main-window focus

- The main window records mouse input before dispatching it to the sidebar or Settings controls. This prevents the keyboard marker from appearing between mouse-down and selection. The keyboard indicator remains available during keyboard navigation.
- All 21 targeted Swift cases passed. The native window test verifies that the marker is suppressed before the receiving view handles mouse-down.
- The signed app launched with the build directory moved away. On the installed build, a held click selected Usage with a neutral glass highlight. Up switched back to Overview and showed the focus ring. Tab moved focus without changing the selection. Mouse and arrow-key switching also worked in Settings.

## 0.7.5-dev.1 aggregate capsule input

- Service rows accept a click or a drag across the visible width. A brief movement under four points preserves the click on the press target. Dragging from a row or grip moves the rail and dismisses the detail. The ellipsis retains its own click target.
- All 34 focused Swift cases passed. The regression sends native mouse events through the panel to verify jitter-tolerant selection, a grip tap, direct inward drag from both edges and no selection after a drag.
- The signed build was installed and opened with the build directory moved away. The desktop capsule appeared with live readings. End-to-end desktop drag verification remains pending.
