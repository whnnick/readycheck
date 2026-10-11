# 0.1.135: full-screen hiding and Token comparisons

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Versions](../../VERSIONS.md)

Goal: reduce overlay obstruction and explain how Token activity changes.

| Requirement | Scope / success criterion |
| --- | --- |
| Full-screen hiding | A persisted switch, enabled by default, applies to bubbles, cards, edge rings and notch status. Native full-screen Spaces hide them and desktop return restores placement. Ordinary maximized windows are excluded. Monitoring, notification permissions and temporary-hide deadlines are unchanged. Use native window collection behavior; no screen-reading permission or private API. |
| Daily / weekly comparison | Today so far versus yesterday's full daily bucket; last seven complete UTC dates versus preceding seven. Explain the ongoing day and date convention. Require every expected bucket for a total/change; missing, negative, malformed or duplicate dates remain unknown. Explicit zero is valid; zero previous totals cannot yield a percentage. |
| Token hover | Retain exact daily date/count and add change against the previous day. Missing prior dates never become zero. |
| Interaction acceptance | Check brief/continuous hover, exit/re-entry, explicit dismissal, drag suppression and reset deadline waiting for fresh data. Switching Spaces cancels hover and expanded intent. Keep all styles. |

No new provider, model call, extra polling, prediction or notification-cache reset. Windows gets version metadata only. Ship a bilingual GitHub Release after tests, installed-app acceptance, packaging and public-sync review.

References: [Apple window behaviors](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct), [Spaces changes](https://developer.apple.com/documentation/appkit/nsworkspace/activespacedidchangenotification).
