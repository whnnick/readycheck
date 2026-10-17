# ReadyCheck 0.2.1 — one Widget, fewer surprises

[中文](RELEASE_NOTES.zh-CN.md) · [Functional checks](QA.md) · [Plan](PLAN.md) · [Versions](../../VERSIONS.md)

2026-10-17

- **One floating Widget:** the bubble becomes a slim vertical strip at either screen edge; drag it inward to restore the bubble. Both use the same details, last-hour consumption chart and pin state. Existing edge positions migrate once, with old records and the previous bubble position preserved.
- **Movable information cards:** drag the card's title to move it freely. Buttons retain their own actions and its saved position is restored.
- **Predictable pinned details:** clicking a preview's content, background or padding keeps it open, even during expansion. Unpin to return to preview behavior; outside dismissal and Escape remain available as before.
- **Smoother outlines and transitions:** attached details open directly from the strip without a dial flash. Inset borders avoid being cut by the native silhouette; existing supersampled masking is retained.
- **Release information in About:** highlights and the full release-notes link remain easy to find there, without duplicated highlights in Connection settings. Update checks, quota windows, account benefits, history and credentials are retained.

Settings → Display now offers **Floating widget** and **Information card**. No new automatic popup is introduced. Account access remains read-only; this monitor does not stop/resume Codex tasks or redeem reset credits automatically.

## Downloads and upgrade

- macOS: `ReadyCheck-0.2.1-macos.dmg`, Apple silicon / macOS 14+. Quit the old app, replace it in Applications, then reopen. The preview is self-signed, **not Developer ID signed or notarized**. macOS may ask to confirm access to existing Keychain credentials; use Settings → Connection → Retry credential read if needed. No new OAuth sign-in is required solely by this update.
- Windows: `ReadyCheck-0.2.1-windows-x64-portable.zip`, separate x64 portable preview. This release updates version metadata and retains the previous Windows interface; the native Mac Widget changes do not apply to Windows. Automated package checks do not replace physical Windows acceptance.

Screenshots use the current native interface with invented demo data. See the [functional checks](QA.md) for observed acceptance, completed live-Keychain follow-up and remaining device limits; no new credential recovery improvement is claimed.
