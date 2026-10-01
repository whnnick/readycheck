# 0.1.129 adaptive edge rings

[中文](PLAN.zh-CN.md) | [Acceptance](QA.md) | [Version index](../../VERSIONS.md)

The edge capsule currently assumes a five-hour window and a weekly window. It must instead show each validated quota window returned for the account, with its actual duration and an additional bucket name when supplied. A weekly-only account should see one ring, with no invented five-hour allowance. Missing data must remain unavailable, never imply unlimited usage.

Scope: macOS edge rings, collapsed bars, matching detail rows, and native panel sizing on quota refresh. Keep the whole capsule as the detail control, half-second hover expansion, dragging to either edge, urgency colors, and the other widget styles. Lists exceeding the visible screen height may scroll.

Acceptance: cover zero, one, two, and extra named windows; retain separate IDs when durations match; resize after refresh without losing the selected edge; render fixture screenshots and run the signed app on macOS. Account access and real Pro/extra-bucket responses must be recorded separately from fixture checks. Windows receives version metadata only.

The [official pricing documentation](https://learn.chatgpt.com/docs/pricing) currently describes Pro without a five-hour limit. The [app-server documentation](https://learn.chatgpt.com/docs/app-server#auth-endpoints) exposes multiple quota buckets. These motivate data-driven display; do not hide or create windows based on a plan-name assumption.
