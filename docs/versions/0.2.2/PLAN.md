# 0.2.2: dependable connection state and refresh

[中文](PLAN.zh-CN.md) · [Version index](../../VERSIONS.md) · [Checks and limits](QA.md)

2026-10-19. Local development only; public downloads remain 0.2.1. Preserve the accepted Widget/card/notch design, settings, credentials and account history. No public push or release is authorized in this phase.

1. Inspect upgrade signing and credential access without changing real Keychain items or access control. Distinguish identical signing requirements from proof of an item's existing authorization. The installed 0.2.1 and retained development bundles have the same signing identity/designated requirement; this alone does not explain or eliminate system confirmation prompts.
2. Reproduce late connection reads and overlapping refreshes with controllable synthetic clients. After changing account source, old local/credential results and errors must not replace current account status; the new connection must refresh immediately, and old completion must not clear its activity.
3. Verify transport-failure caching, recovery, wake-triggered refresh and existing low/recovery reminder deduplication. Cached or wrong-account data must not trigger new quota reminders. Keep 5%, 10% and 20% settings and existing account benefits.

Use focused regressions before the minimal fix, then the full Swift suite and a signed local preview. Keep private signing/account evidence outside public source. Simulated transport/wake checks are separate from physical network/sleep/display acceptance. Normal macOS Keychain confirmation may still be required; do not weaken its protections or force a new OAuth sign-in to hide it. No Codex task-stop/resume capability is introduced.
