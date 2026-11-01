# 0.7.0 interaction correction plan

[中文](INTERACTION_REPLAN.zh-CN.md) · [Retention checklist](RELEASE_AUDIT.md) · [Earlier settings plan](SETTINGS_PLAN.md) · [Checks](QA.md)

2026-10-31. Navigation from the [preview.5 prototype](prototype/README.md) is implemented in native dev.14 following the user’s continuation. See [native checks](QA.md); this does not establish release acceptance. Based on the user's correction, a seven-step audit of the current native dev.13 app using Product Design, and a separate Product Manager review. This supersedes the earlier direction that removed the old Connection/Reminders entry points and introduced a hidden service-settings destination.

2026-10-31 follow-up: native dev.15 uses Connection → Reminders → Display → General, with platform marks in Connection/Reminders, following the latest user correction. The earlier prototype order is superseded; the last selection and existing shortcuts are retained.

## Product boundary

Add platform connections and statistics to the familiar utility. Existing tasks must remain accessible. Keep the four main destinations and existing shortcuts; restore Settings → Reminders / Display / Connection / General. Within Connection and Reminders, select the platform instead of stacking every provider's forms.

Preserve Codex quota, tokens, benefits, every reset card, automatic-card consent, checks and receipts, notifications, history, menu bar, Widget, notch and preferences. Hiding a control or keeping its source code is not retention evidence. This pass covers Codex and DeepSeek discoverability and display, not new integrations, chat, or credential/storage redesign.

## Observed audit

Only navigation and an empty connection form were exercised. No credential was submitted, alert changed or card redeemed. Local screenshots contain live readings and are excluded from the public repository.

| Step | Observed behavior | Assessment |
| --- | --- | --- |
| E01 Overview | DeepSeek selector absent while disconnected or credential-restricted | Critical discoverability failure |
| E02 App settings | Only General and Display; old Connection/Reminders paths absent | Old task paths broken |
| E03 Manage connections | Ten supported/planned services share the View integration action | Discovery catalog blocks a daily task |
| E04 DeepSeek description | Another Open connection settings button | Unnecessary intermediate step |
| E05 Service settings | No sidebar location; scrolling Back link has no named destination; disconnected and Keychain error coexist | Location and recovery are unclear |
| E06 Connection form | Another Connect click opens an empty Key form already showing a save failure | Prior access error mixed with current submission state |
| E07 Cancel and return | Cancel returns to service settings; Back returns to Overview rather than the catalog | Works in this case, but destination requires guessing |

Retain the existing distinction between balances and tokens, balance components, alert controls, system permission status and preserved history. Success authentication, full keyboard/VoiceOver, light appearance and long-content return behavior were not checked in this audit.

## Recommended structure

| Location | Behavior |
| --- | --- |
| Overview and Usage | Existing content plus compact Codex / DeepSeek selector with actual connection state |
| Disconnected platform | Small empty state and direct Connect action; no zero balances or invented charts |
| Current platform heading | Name, state and explicit connection/retry action; alert shortcut |
| Settings → Connection | Supported platform list with the selected connection details and login controls |
| Settings → Reminders | Platform selector; existing Codex rules/automation or DeepSeek balance rules |
| Settings → Display | Existing device-wide Widget, notch, topmost, snooze, position and fullscreen controls |
| Settings → General | Language, launch at login, refresh, updates and system notification controls; retain the notification summary/link in Reminders |
| More platforms | Optional ten-service discovery catalog; planned integrations clearly labeled |

Keeping the two supported platforms visible revises the previous connected-only selector rule. The tradeoff is one extra small item; new users and restricted connections retain an obvious DeepSeek entry. Future integrations stay in More platforms until supported.

Service-specific settings and old entry points coexist: each platform's configuration has one canonical location inside Connection/Reminders. Overview shortcuts focus that same location, not a second copy or hidden page. The first Settings visit defaults to Codex for existing users; later visits remember section and platform. Shortcuts specify their target explicitly.

## Tasks and return behavior

1. First DeepSeek connection: Overview → DeepSeek → Connect DeepSeek → Key form. Two clicks to input, with guidance inside the form; the catalog is optional.
2. Familiar path: Settings → Connection → DeepSeek opens the same form. Preserve Codex login, cancel, callback fallback, reauthorization, disconnect and credential-read retry.
3. Alerts: Overview → Alert settings focuses Settings/Reminders/current platform. Old Settings → Reminders still works. Never show Codex cards under DeepSeek or currency thresholds under Codex.
4. Return: a fixed toolbar outside the scroll area names its destination, such as Back to DeepSeek Overview or Back to DeepSeek Usage. Restore platform, range and scroll position. Settings remains selected in the sidebar, with visible section/platform context.
5. Cancel/Escape: close the form and return focus to its initiating control without clearing an existing connection, saving partial input or changing platform.
6. Browsing another platform changes display context only, not pinned Widget/notch targets, rules, authorization or history ownership.

Keep the discovery catalog as an independently closable panel. Avoid overlapping Close, Back to directory and generic Back paths in the main connection task.

## States

| State | Visible explanation | Action |
| --- | --- | --- |
| Never connected | Not connected; supported read-only metrics | Connect/login |
| Stored credential restricted | macOS authorization required; do not assert signed out | Retry credential read, with user handling system approval |
| Validating | Reading balance; prevent duplicate submission | Wait or cancel |
| Key rejected | Validation failed; retain existing connection if any | Edit and retry |
| Network error | Refresh failed; retain last-success timestamp and stale marker | Refresh, not forced credential replacement |
| Connected | Platform, scope and last success | Refresh, manage connection, alert settings |
| Enabled rule, denied permission | Both states shown independently | System notification settings |
| Disconnect | Explain platform scope and separate history policy | Explicit disconnect action, without deleting another platform or history |

Do not display a previous credential-access failure as a new unsent form's save failure. Keep the existing connection problem separate; show submission errors only after that form's submission.

## Retention and implementation order

For every existing baseline item, record old/new entry points, behavior, preferences/history/consent and evidence. Unchanged paths may inherit applicable baseline evidence; changed paths require interaction verification. Test totals or source presence do not clear retention.

First review this plan and a focused prototype using existing layout, density, icons and controls. Then wire canonical routes, platform states and fixed return navigation using existing stores. Next address credential retry and form-state separation. Finally validate real upgrades and each platform. Do not simultaneously migrate storage or rewrite authorization/automation.

## Black-box acceptance

| Task | Required result |
| --- | --- |
| Find DeepSeek | Visible from Overview; at most two clicks to a Key input; no catalog required |
| Use old connection/reminder paths | All four original sections remain and Codex controls retain behavior |
| Enable balance rule with notifications denied | Rule and system permission states remain distinct |
| Restrict credential access | Platform stays visible; explain authorization and offer in-place retry |
| Enter settings from Overview/Usage and return | Fixed return control; restore source, platform, range and position |
| Edit a rule from both entry points | Same connection/rule and consistent readback |
| Switch platforms | No mutation of card consent, history or pinned display targets |
| Upgrade | Compare thresholds, expiry nodes, consent/pending receipts, DeepSeek rule/dedup, positions and actual launch-at-login path |
| Keyboard/minimum window | 740×620, both languages and appearances; long content keeps navigation/focus reachable; form close restores focus |

Deliver a clickable prototype after this plan is reviewed, then implement native changes after user confirmation. Existing dev.13 tests do not establish that this new proposal is implemented.
