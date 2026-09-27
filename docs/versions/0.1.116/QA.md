# 0.1.116 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.115 acceptance](../0.1.115/QA.md)

Status: local preview; no GitHub release requested. The [Codex App Server account interface](https://learn.chatgpt.com/docs/app-server#auth-endpoints) reports account and plan, but does not document a current billing date. [OpenAI billing guidance](https://help.openai.com/en/articles/9039756-managing-billing-for-chatgpt-and-the-api-platform) directs personal subscribers to ChatGPT Settings > Billing.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Keep previously available dates | Implemented; date-present UI pending | A future token date remains visible as “Subscription active until”; a past token date is visible as “Last recorded active until”, avoiding a claim about the current billing cycle. Verify both states with controlled snapshots. |
| Explain missing dates | Preview UI verified | The connected local Codex account returned Plus and live quota, but no subscription date; the main card displayed “Subscription date · Check ChatGPT billing” without showing “Unconfirmed”. The first-viewport layout was inspected on macOS. |
| Regression checks | Passed | 198 core and 4 app Swift tests passed. Windows checks, version consistency, stable-signed preview packaging, and strict signature verification passed. |
| Public release | Not requested | Public latest remains 0.1.114. |
