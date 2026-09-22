# 0.1.98: Connection diagnostics and reminder acceptance

[中文](PLAN.zh-CN.md) | [Version index](../../VERSIONS.md) | [Acceptance](QA.md)

Researched 2026-09-22. In development. Baseline: 0.1.97 at 1cb4d80. Connection recovery and sanitized event status are implemented in 0.1.98; real notification-lifecycle and login-item acceptance remain pending.

## Official evidence

[OpenAI App Server](https://learn.chatgpt.com/docs/app-server) documents version-specific schema generation, initialization, account/quota events, multiple quota buckets, and experimental capabilities. Validate against the installed binary rather than assuming every client supports the online contract.
[Apple notification removal](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/removedeliverednotifications(withidentifiers:)) is asynchronous; 0.1.97 already verifies removal. Notification Center presence does not prove a visible banner.
[SMAppService](https://developer.apple.com/documentation/servicemanagement/smappservice) supports registration and unregistration of login services.
These are current documentation findings, not claims of changes released in the last two days or new macOS 27 dismissal behavior.

## Existing capabilities and gaps

Local Codex/OAuth, multiple buckets, event-triggered refresh, polling fallback, wake refresh, verified dismissal and history already exist.
The event monitor uses the first discovered executable, fixed 30-second reconnects, and acknowledges initialization by response ID without checking errors. Its blocking read has no explicit handshake timeout. The reader already has multiple candidates and a 12-second timeout: align these paths without a wholesale rewrite.
0.1.97 QA still lacks persistent-alert, Focus/lock/wake, login-cycle and macOS 14 device evidence.

## P0 release scope

### A. Connection recovery and diagnostics

Align executable selection across reads and monitoring. Distinguish missing installation, signed-out account, handshake failure, unsupported protocol, temporary network failure and stale data.
Bound initialization; never accept an error as successful initialization. Reconnect after exit with capped backoff, and invalidate old callbacks after stop/account changes. Retain polling and coalesce refreshes. Show last successful refresh and a retry action; event connectivity alone does not establish freshness.
Diagnostics contain only app/client versions, connection mode, stage and sanitized error codes, excluding email, account IDs, credentials, paths and raw responses.
Acceptance: deterministic tests for silent/error initialization, unusable first candidate, exit, network recovery, stop/reconnect races and account switching. Recovery must not require unnecessary login. Fix timeout/backoff values in implementation tests.

### B. Real notification lifecycle

Preserve recovery from nonzero quota and dismissal after verified renewed consumption.
Drive the real notification adapter with injected snapshots, clearly marked test notifications and isolated from real reminder state, then observe a natural cycle.
Check persistent alerts in foreground/background, verified removal, delayed deletion, restart, duplicate refreshes, account switching, Focus, lock and wake. Removal starts after a successful snapshot confirms consumption, not necessarily when a user starts a request. Keep retry state visible; manual removal is not automatic dismissal.
Require one controlled recovery → visible persistent alert → consumption → removal cycle on macOS before release. Record an unobserved natural cycle explicitly.

### C. Protocol compatibility

Generate schemas from target binaries and record versions. Retain 0.1.97 fixtures and add current, missing-field and unknown-field cases. Cover multiple buckets, arbitrary windows, reached states and unknown versus zero reset credits. Do not infer model-to-bucket mappings.
Treat events as refresh signals and evaluate full snapshots. Unsupported experimental history must not break quota reads.
Acceptance: old/new fixtures pass; stale/unknown data never triggers recovery or becomes fabricated 0/100 percent.

## P1 after P0

Investigate installed-preview SMAppService notFound using bundle, install location, registration errors and signing evidence; do not assume self-signing caused it. Read system status, link pending approval to system settings, and refresh on return. Verify enable, logout/login, disable and upgrade on-device. Otherwise label experimental and avoid reliable-startup claims.

## Delivery and release

Add A/C failure tests first, implement recovery/diagnostics, verify B on-device, then address login items and packaging. Prefer three feature commits plus one version/documentation commit. Estimate 3–5 development days, excluding natural quota cycles and extra devices.
Exclude new providers, inferred model mappings, automatic reset-credit redemption, remote connections, visual redesign and Windows notification expansion. Bump to 0.1.98 with bilingual changelogs during implementation only.
Track complete/partial/pending items in [QA](QA.md). Run full Swift tests including localhost OAuth, Windows check/smoke/UI smoke, version and secret checks. Use existing packaging scripts and verify installed binary identity. Record missing macOS 14 hardware and preview-signing versus Developer ID/notarization limits. Follow the full existing GitHub release process when publishing.
