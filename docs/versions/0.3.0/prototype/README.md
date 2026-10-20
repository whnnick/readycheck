# Quota pace interactive preview

[中文](README.zh-CN.md) · [Plan](../PLAN.md) · [Functional checks](../QA.md) · [Visual QA](design-qa.md)

0.3.0-preview.1. Extends the existing native dark Overview layout and supplied brand assets to explore whether current pace may last until reset. No live data integration.

Run `npm install`, then `npm run dev -- --host 127.0.0.1 --port 4332 --strictPort`. Checks: `npm run test:pace`, `npm run build`, `npm run test:sites`.

Top controls switch seven scenarios, languages and three surfaces. Settings change5/10/20% targets and preview a notification. Choices affect this page only. Estimates assume unchanged recent pace, never guaranteed runtime. All data/screenshots are synthetic. Installed native app and settings are preserved; public download remains0.2.1.

The [Feature retention checklist](../FEATURE_RETENTION.md) defines the full retained baseline. This page omits or simplifies Display/Connection/General settings, notification history and full Token charts. Those are unfinished prototype coverage, not approved removals; native integration must retain and verify them.
