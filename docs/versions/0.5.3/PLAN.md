# 0.5.3 — Notification history in the sidebar

[中文](PLAN.zh-CN.md) · [Checks](QA.md) · [Versions](../../VERSIONS.md)

Release candidate: `0.5.3`; development acceptance used `0.5.3-dev.2`. Public stable remains0.5.2. The user approved a dedicated notification-history page and removal of the duplicate Overview reminder shortcut; packaging and public publication are now explicitly authorized.

- Sidebar: Overview, Token usage, Notification history, Settings. Preserve Command1/2/3 for the original pages; Command4 opens notification history. Keep native fullscreen commands.
- The page shows the full existing local history, including all delivery states and an empty state, directly in the main content scroll area. Its refresh reloads local records, not quota data or notification submission. Keep notification delivery distinct from card redemption.
- Settings → Reminders retains every switch, threshold, expiry milestone, automatic-use consent/rule and notification test. Remove its embedded history summary and View-all sheet entry. Keep exact related-notification sheets in card details.
- Overview loses only the duplicate bottom reminder shortcut with its misleading single-threshold summary. The menu and Widget reminder shortcuts still open reminder settings.

No changes to persistence formats, credentials, account ownership, consent, history, notification scheduling/deduplication, card eligibility or network endpoints. Reuse the existing row component across the page and related-notification sheet; no new filters or settings. macOS presentation change; Windows metadata only.

Success: direct sidebar/native-menu access, old shortcuts retained, complete history beyond three rows, unchanged rules on reload, bilingual minimum-width light/dark rendering, matching regression checks and signed local installation. Preserve all other baseline capabilities and inherited physical-device limits from the [0.5.2 audit](../0.5.2/RELEASE_AUDIT.md); changed entries D09 (history entry) and the duplicate Overview shortcut presentation are navigation changes, not capability removal.
