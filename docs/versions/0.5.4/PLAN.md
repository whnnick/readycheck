# 0.5.4 — Compact reset-card details

[中文](PLAN.zh-CN.md) · [Checks](QA.md) · [Versions](../../VERSIONS.md)

The user requested removing the extra bottom partition and explicitly authorized packaging/push after verification. Remove the final section divider and reduce the fixed sheet height from480 to400 points; preserve540-point width and the existing ScrollView. Do not remove card facts, outcomes, timestamps, request details, notice states, related-notification sheets or Close/Escape. Long content stays scrollable.

No changes to credentials, account ownership, persistence, reminders, card eligibility, consent, notification delivery or APIs. Preserve the dedicated notification page, navigation/scroll fixes and all other0.5.3 capabilities. macOS layout fix; Windows existing interface. Validate native bilingual short/long states, related notices, regression and final signed installation. Follow the existing release process for public-source tests, dual packages, sensitive/history review, bilingual release and downloaded SHA-256 checks. Inherit previous device/real-redemption limits; no real cards for testing.
