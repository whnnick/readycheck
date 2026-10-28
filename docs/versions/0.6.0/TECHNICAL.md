# 0.6.0 native presentation contract

[简体中文](TECHNICAL.zh-CN.md) · [Plan](PLAN.md) · [Checks](QA.md)

No new ledger, persistence format, notification rule or authorization. Notification history uses existing local records; type filters are view-local and default to All. Calendar grouping uses the local time zone and actual last attempt, falling back only to recorded receipt. Unknown time is separate, not a card expiry. Relative text refreshes once a minute in visible rows. Full time remains visible and system native notifications retain0.5.5 submission subtitles.

Card timeline consumes the existing account-scoped execution projection. The oldest retained preparation timestamp, latest recorded status, last notification attempt and verification are distinct. These are saved evidence nodes, not a full network log. Observations never become redemption requests. Historical reminder-only records have no fabricated timeline. Related success notices require a confirmed local result, exact request ID, kind and expiry; all other records remain visible in their original history. Account-wide checks stay separate because the existing metadata has no card ID.

Connection actions prioritize an in-progress login, then restricted credential access. Explicit auth rejection opens the existing sign-in settings; generic read failures refresh. Parser support opens update checks; unsafe/uncalibrated endpoint states open settings without retrying. The action is revalidated when executed, so an obsolete button cannot replace current state. Opening sign-in settings does not start OAuth, delete credentials, change consent or redeem a card. Existing refresh/background behavior continues under the user's saved consent; acceptance never triggers a test redemption.

Production pages already own scrolling. The narrow-height notification/highlight render fixtures now use the same ScrollView container, keeping the original viewport assertions. No content was removed or height threshold relaxed to hide overflow. Native device interaction and full regression are tracked separately in QA.
