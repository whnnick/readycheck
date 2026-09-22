# 0.1.97 plan: reliable connection and notifications

[中文](NEXT_RELEASE.zh-CN.md) | [Documentation](../README.md#documentation)

Research: 2026-09-20. Implemented in the local 0.1.97 development branch; packaging and real-environment acceptance are tracked in QA. README labels the public release 0.1.94.

## Outcome and scope

Use the correct signed-in Codex account reliably and make recovery notification delivery/removal explainable. Estimate 4–6 development days, conditional on client compatibility and device acceptance.

## Sources

- [OpenAI App Server](https://learn.chatgpt.com/docs/app-server): account, quota and usage reads, account/quota notifications and version-specific generated schemas. Existing quota events, multiple buckets and token history should be strengthened rather than rebuilt.
- [Apple removal API](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/removedeliverednotifications(withidentifiers:)): removal is asynchronous. Center state does not establish visible banner presentation or user acknowledgement.
- [Authentication context](https://developer.apple.com/documentation/security/ksecuseauthenticationcontext): investigate per-query authentication while preserving legacy Keychain compatibility.
- [Login launch](https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp): use the main-app service and read its actual status.
- [macOS 27 release notes](https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes): compatibility reference. The full body was not retrieved; no specific new notification defect or fix is asserted.

## P0 implemented for 0.1.97

1. **Local Codex connection, 1–2 days.** The current provider requires its own Keychain token before reading app-server. Add an explicit local-Codex mode that validates account and quota before connecting. Bind verified account/workspace identity; insufficient identity must prevent silent switching. Keep standalone OAuth as an explicit choice. Handle account changes by clearing old account quota/reminder baselines. Accept only after token-free local login, logout, switching, restart and legacy OAuth scenarios pass. Internal backend endpoints are not documented stable public contracts.
2. **Notification lifecycle, 1–2 days.** Version 0.1.96 already verifies removal, but only Core is a test target. Add notification adapter coverage for asynchronous failure, pending requests, restart and concurrent delivery/removal. Reproduce and fix the risk of a failed old dismissal overwriting a successfully delivered new baseline. Expose delivered, automatically withdrawn and retry-pending history states; absence is not proof of reading. Verify a clearly labelled acceptance notification using both system queries and screen observation with persistent style, focus, lock and wake scenarios. Detection begins when fresh official quota data reflects consumption, not necessarily on message send.
3. **Protocol compatibility, 1 day.** Generate schemas for supported client versions and retain sanitized fixtures. Check actual launch flags and handshake. Prove whether a dedicated server observes changes from other Codex processes; event documentation alone does not establish cross-process broadcasting. Keep polling fallback. Test missing fields, unknown buckets, unknown versus empty reset details, crashes and wake reconnection. Expose source, age and degraded state.

## P1 implemented for 0.1.97

User-enabled launch at login using SMAppService.mainApp, approximately half a day. Read system approval state, prevent duplicate monitors and avoid foreground activation. Explore modern Keychain APIs separately; do not migrate legacy credentials before compatibility is proven.

## Later 0.2.0 candidate

Explicit reset-credit redemption using the documented consume method. Require per-attempt confirmation, persisted idempotency, distinct outcomes and fresh quota reads afterward. A timeout must not create a new redemption attempt. Eligibility is server-authoritative. This changes the product's read-only boundary and needs separate design and acceptance.

Defer additional providers, AI predictions, automatic redemption, visual redesign and Windows notification expansion.

## Release acceptance

Map every P0 item to completed/partial/pending status in bilingual QA linked to this plan. Run all Swift tests including localhost OAuth outside the command sandbox, notification adapter tests and Windows smoke checks. Focused tests are subsets, not additive totals. Verify macOS 14 support and macOS 27 installation, upgrade, cold start and visible notification dismissal; document unavailable hardware honestly. Verify signing and installed/package binary consistency. Use existing packaging scripts for DMG, Windows ZIP and checksums. A requested GitHub push includes source, tag, Release, assets, latest and download verification.
# Archived plan: 0.1.97

For the current proposal, see the [0.1.98 plan](versions/0.1.98/PLAN.md) and [version index](VERSIONS.md).
