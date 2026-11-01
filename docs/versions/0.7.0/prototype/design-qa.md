# Design QA — 0.7.0-preview.5

Scope: isolated synthetic navigation prototype following the [interaction correction plan](../INTERACTION_REPLAN.md), awaiting user review. This is not native acceptance or a release claim. The running application, credentials and real settings are unchanged.

## Visual comparison

Source: [preview.4 Codex overview](evidence/preview5-source-overview.png). Implementation: [preview.5 Codex overview](evidence/preview5-overview-final.png). Both use the same synthetic snapshot, light theme, collapsed benefits and 900 × 760 CSS/pixel viewport. The [full side-by-side](evidence/preview5-comparison.png) and [focused header](evidence/preview5-comparison-header.png) were inspected. Product images are unscaled, with comparison captions outside them.

| Fidelity surface | Review |
| --- | --- |
| Typography | Existing native/PingFang system stack and title, figure and control scales retained. No clipped text in checked views. |
| Layout | Same sidebar, compact platform tabs, quota columns, reset row and chart. Direct shortcuts intentionally add space; Settings intentionally restores four sections and a sticky named return. |
| Color | Existing light/dark tokens retained; warning text corrected for contrast. |
| Assets | Existing ReadyCheck, Simple Icons and Phosphor assets reused. Both platform marks remain visible. ReadyCheck beside Codex is a prototype identifier, not an official Codex mark. |
| Copy | Explicit synthetic states; balance components separate; pending providers do not imply live integration. Rule state and OS notification permission are independent. |

## Findings fixed and rechecked

- P2: dialog closure lost opener focus. Capture the opener before showing the dialog and restore on unmount; Escape returns to Connect DeepSeek.
- P2: warning contrast on light surfaces. Added a semantic warning-text token and inspected the [post-fix restricted view](evidence/preview5-restricted.png).
- P2: supported catalog rows retained an unnecessary description step. They now open canonical connection settings directly with a named return to the catalog.
- P2: catalog scroll restoration ran before dialog layout. Restore on the next frame; browser readback was 100px before and 100px after the round trip. Search text DeepSeek also survived return.

## Browser verification

- [Disconnected tabs and direct connection](evidence/preview5-disconnected.png): select DeepSeek then Connect from Codex Overview, two clicks. Exercised failure, cancel, reopen without stale error and simulated success. [Failure state](evidence/preview5-form-error.png).
- Saved DeepSeek threshold 10, returned to overview and read it through Settings. Notice details reach the same rule, with named return to Notification records. [Shared rule](evidence/preview5-reminder.png).
- From DeepSeek Usage at seven days, entered reminders and scrolled down. [Fixed named return](evidence/preview5-fixed-return.png) remained visible; return restored platform/page/range.
- [Codex reminders](evidence/preview5-codex-reminders.png) retain recovery, low quota, expiry nodes and existing-consent explanation/records. No card redeemed. Restricted access offers in-place retry rather than equating it to logout.
- Optional catalog supported rows go directly to settings; planned rows retain descriptions. [Search restored](evidence/preview5-catalog-return.png), scroll restoration read back at 100px.
- Display demonstrates Widget visibility, topmost, style, notch, fullscreen, snooze and reset position; viewing a platform does not change its fixed Codex target.
- Light 900 × 760 and [dark 740 × 620](evidence/preview5-narrow-dark.png) inspected. No horizontal overflow in the checked narrow view. General content alone demonstrates language switching.
- Browser warning/error query returned no messages. Build, four catalog tests and four hosting tests passed. Temporary viewport reset before handoff.

## Limitations

User review, native implementation/migration, real authentication/upgrade, notification delivery, actual Widget/notch behavior, complete keyboard/VoiceOver coverage and the affected Windows machine remain pending. Network-error state retains a synthetic snapshot by design; real recovery is unverified. This prototype does not prove full native feature parity. The Vite chunk-size advisory remains P3 polish. No package, deployment or release this pass.

final result: passed
