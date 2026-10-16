# ReadyCheck 0.2.0 interactive preview

[中文](README.zh-CN.md) · [Product plan](../PLAN.md) · [Acceptance boundary](../QA.md)

This clickable web preview implements the selected sidebar concept. It is not the installed native app. Preview version: `0.2.0-preview.3`. All readings and native component references use synthetic data.

```sh
npm ci --prefer-offline --no-audit --no-fund
npm run dev -- --host 127.0.0.1 --port 4331 --strictPort
```

Open the local address printed by the terminal. Navigate Overview / Usage / Settings. The bottom-left scenario picker includes normal, low quota, recovered, offline, stale, authorization required and no data.

- Overview: two quota windows, status, refresh, reminder entry and keyboard chart inspection.
- Usage: 7/30/90-day ranges and incomplete-history labels; Tokens are not converted into quota.
- Settings: reminder thresholds, recovery toggle, simulated permissions/test notices, real native style references, primary quota selection, widget readings and pin/hide interactions.
- Account/data: state details, user-initiated repair and separate historical plan metadata.

No live services or system changes. Pin/unpin is an in-page simulation. Native appearance references are separate from the interaction preview; window-level/fullscreen options demonstrate setting state only. Upgrade, OS delivery, Keychain, multiple displays and dragging require native implementation and acceptance. Reload resets selections.

Check with `npm run build`. The inherited `npm run test:sites` only checks static-hosting adaptation; it does not verify product or native behavior. Nothing is deployed.

Visual target: [overview-concept.png](../assets/overview-concept.png). Captures: [overview](../assets/overview-preview.png), [reminders](../assets/reminders-preview.png), [usage](../assets/usage-preview.png). Local comparison details: [design-qa.md](design-qa.md); `qa/` is ignored local screenshot storage.

[Cross-version review](../UPGRADE_REVIEW.md) · [Five-state concept](public/assets/widget-notch-concept.png). Open Settings → Display → View widget/notch design. The board is a visual specification, not an implemented native notch.
