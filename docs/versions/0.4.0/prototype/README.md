# ReadyCheck 0.4.0-preview.1

[中文](README.zh-CN.md) · [Plan](../PLAN.md) · [Acceptance](../QA.md) · [Design QA](design-qa.md)

A local clickable design prototype, using fixed synthetic data dated October 21, 2026, 10:20 Asia/Shanghai. The installed native app remains 0.3.0. No credentials, official readings, real cards, system notifications or stored settings are accessed.

## Run locally

```sh
npm ci
npm run dev -- --host 127.0.0.1 --port 4333 --strictPort
```

Open the local URL printed by Vite. Use the external scenario selector to review normal reset, automation off, authorized waiting, unconfirmed conditions, and used-card/notification-pending states. Overview, menu preview and Widget preview share the event model. Card details open on click; Escape closes them. Preview settings are in memory only and reload resets them.

## Checks

```sh
npm run test:scenarios
npm run test:sites
npm run build
```

The build includes a template-provided static worker; it is not deployed. Bilingual, narrow-window and visual checks are recorded in the version acceptance and design QA documents. Existing navigation/benefits/chart entries are illustrated; this prototype does not reimplement or authorize removal of the 65 protected native capabilities. Native persistence, migration, real card execution, notification delivery and user-comprehension validation remain separate work.
