# 0.1.135 acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Versions](../../VERSIONS.md)

Status: implemented and accepted on the test Mac on October 11, 2026. Release packaging checks are recorded below; external-device coverage remains limited.

| Requirement | Result / evidence |
| --- | --- |
| Full-screen hiding | Passed on this Mac for edge rings, bubbles and cards. Finder entered native full screen through Computer Use; the app's own window-occlusion log changed to `visible=false` and returned to `visible=true` on exit for each style. With the switch off, the edge window remained visible in full screen. The corrected native policy combines `canJoinAllApplications` and `fullScreenNone`, without `canJoinAllSpaces` when hiding is enabled. Position preferences, monitoring and reminder code are unchanged. |
| Token comparison | Passed deterministic coverage for UTC boundaries, two complete seven-day periods excluding today, missing/negative/duplicate/malformed dates, zero previous totals and overflow. Chinese and English installed UI inspected with real data: missing today and incomplete recent week display unavailable totals, coverage and no invented change. |
| Hover / exit / drag | Passed user acceptance on October 11: “normal and smooth.” Automated intent tests cover brief hover, exit/re-entry, dragging, cancellation, pinning, dismissal and Space changes. |
| Countdown | Existing tests cover missing/stale/estimated/mock deadlines, minute/day boundaries and elapsed deadlines waiting for a refresh. Real installed details show verified quota reset countdowns. A real reset-at-zero transition has not been observed in this session. |
| Account / settings | Existing OAuth sign-in recovered through Retry reading; installed details display real current quotas. Chinese, right-edge style and full-screen hiding enabled were restored. No account, identity or notification-permission migration. |
| Notification icon | User confirmed the C icon after a Mac restart on October 10; see [0.1.133 acceptance](../0.1.133/QA.md). No additional cache reset in this version. |
| Verification / packages | Passed: 257 Swift tests, version consistency, shell syntax, document links and scoped sensitive-data checks; Windows type check and smoke/UI checks through the portable packaging script. The sealed DMG contains version 0.1.135 with the existing stable identity and passes strict signature verification. The Windows ZIP passes `unzip -t`; only the two current platform packages remain in `dist`. |

Completed: all scoped implementation, automated checks and the installed-interface acceptance above. Partial: Token hover rendering retains the prior chart overlay and adds comparison text, but this automation cannot reliably hold a continuous pointer over a chart bar; numerical behavior is tested. Not completed: physical notch-screen/multiple-display acceptance, additional desktop-Space and Stage Manager combinations, and observation of a real reset reaching zero. These are follow-up environment checks, not claimed passes. Ordinary window maximization is governed by the native window policy rather than an app-size heuristic.

Release blockers: none from the scoped tests and observed interface. The preview uses the existing stable preview signing identity; Developer ID notarization remains outside this release. Public releases must include both platform assets and pass the public-sync sensitive-data check.

Reproduce: `swift test --build-system native --scratch-path <temporary-directory>`, `scripts/check_release_consistency.sh`, `git diff --check`, `scripts/package_dmg.sh`, `scripts/package_windows_portable.sh`, `codesign --verify --deep --strict` on the app mounted from the DMG and `unzip -t` on the portable ZIP. For full-screen diagnosis, stream the `com.readycheck.app` / `widget-spaces` debug log; it contains only window visibility and behavior flags.
