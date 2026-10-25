# Changelog

## 0.5.3 - 2026-10-25

- Open the complete notification history directly from the sidebar. Keep all reminder rules, delivery states, card records and account consent; remove duplicate Overview/settings-history summaries. Preserve original shortcuts, add Command4 and reset cross-page scroll position. macOS update; Windows keeps its existing interface.

## 0.5.3-dev.2 - 2026-10-25

- Reset the content scroll area on page changes so Notification history opens at its heading after browsing old records. Retain the reset-card rule scroll destination. Local development build only.

## 0.5.3-dev.1 - 2026-10-25

- Add a dedicated sidebar notification-history page with the complete existing local delivery records. Keep card outcomes separate and all reminder rules in Settings; remove the duplicate Overview reminder shortcut and embedded settings-history summary. Preserve Command1/2/3, adding Command4 for history. Local macOS development build; Windows metadata only.

## 0.5.2 - 2026-10-25

- One ReadyCheck OAuth sign-in; preserve account-owned settings, history, consent and background Token/card capabilities. Fix connection recovery and startup-check ordering. See0.5.2 release notes for scope and limits.

## 0.5.2-dev.2 - 2026-10-25

- Use one ReadyCheck OAuth sign-in. Remove the local-account selector, local quota-authentication fallback and the dev.1 subscription-file experiment. Local Codex cannot substitute for missing or rejected ReadyCheck authorization.
- Retain matching-account Token statistics, additional quota windows, events and OAuth-authorized card use through the background Codex adapter. Preserve account-owned history, reminders and card consent; saved consent waits for sign-in confirmation and cannot transfer to another account.
- Keep fresh-quota connection recovery and resolved-warning cleanup. Local macOS development build; Windows metadata synchronized. Not publicly released.

## 0.5.2-dev.1 - 2026-10-25

- Restore the matching connection from fresh quota after transient failures; reject cached recovery and late stale connection results. Resume card checks using existing consent, distinguish local read failures from credential failures, and withdraw credential warnings only after a successful card check.
- Supplement local-mode subscription dates from the matching account's read-only login cache. Label the date as a local record with its original issue time; it is not a live billing confirmation. Missing, malformed or mismatched records do not block quota reading.
- Keep separate sign-in, reminders, card records, account history and desktop surfaces. macOS fixes; Windows version metadata only. Local development build, not published.

## 0.5.1 - 2026-10-25

- Clearer current-state Overview, trends before complete benefits, independent reminder/automatic-use groups and explicit Token time ranges. Existing features, preferences and authorization stay intact.
- Quiet transient card-check failures, withdraw matching recovered warnings, preserve historical gaps and both connection methods. Explain missing local subscription dates; only matching-account tokens can supply subscription metadata.
- Retain all desktop behavior and the Widget hour chart; refresh native style previews, About and bilingual release information. Mac native update; Windows interface unchanged.

## 0.5.1-dev.6 - 2026-10-25

- Clarify current reading versus historical success, compact Overview and move trends ahead of complete account benefits; retain every reset-card date and record.
- Separate reminder/automatic-use groups with trailing controls and actual account consent states; retain confirmation, rules, milestones and all execution/notification behavior.
- Clarify Token summary/chart periods, preview adaptive circle/edge styling, and show cross-day check intervals. Native static panels use quieter tonal grouping. macOS presentation only; Windows metadata synchronized.

## 0.5.1-dev.5 - 2026-10-24

- Record transient reset-card detail failures silently and keep automatic retries; notify after at least three consecutive checks over two minutes. Restart that streak after a gap over five minutes. Credential, ledger and unknown-outcome warnings remain immediate.
- Withdraw only matching recovered card-read warnings, retain diagnostic history and identify recovery in neutral, past-tense text. Separate readable quota with missing card details/check failures from connection problems across Overview, menu and Widget. No change to consent, redemption, expiry reminders or account source.

## 0.5.1-dev.4 - 2026-10-23

- Make Follow Codex on this Mac the primary connection choice; fold separate sign-in into Other connection methods. Keep an existing separate account, its status and recovery/disconnect controls visible. No automatic source migration, credential, consent or history changes. macOS presentation update; Windows version metadata only.

## 0.5.1-dev.3 - 2026-10-23

- Keep reminder-only historical gaps in history without treating them as current card-use failures. Label their details “Historical expiry reminder” / “Historical record incomplete”, omit current authorization from that historical context, and retain genuine unresolved requests, failures and pending success notices. No ledger or consent changes.

## 0.5.1-dev.2 - 2026-10-23

- Remove the redundant card-settings button and footer divider from read-only card details; shorten the sheet. Keep results, notification details and Close, plus all settings and the useful next-event settings route.

## 0.5.1-dev.1 - 2026-10-23

- Make “Open card settings” dismiss card details and scroll directly to the reset-card controls, including repeated navigation from the reminder page. Preserve authorization, reminder rules and history.

## 0.5.0 - 2026-10-23

- Choose reset-card expiry reminders at72/48/24/12 hours without losing existing handled milestones, reminder switches or account-specific automatic-use consent.
- Inspect card observations, request preparation and account-owned check failures. Preserve a confirmed redemption receipt even if the subsequent quota refresh fails; distinguish missing cards and unknown initiators from confirmed automatic use.
- Keep the protected ledger open while running, detect file replacement, and retain the existing protection and permissions. Coalesce repeated check warnings; show unconfirmed authorization rather than a misleading Off state.
- Explain continuous observation duration, valid records and interruption reasons through the shared Data status and pace model. Preserve all65 baseline capabilities and settings.
- macOS additions; Windows retains its existing interface. Self-signed, non-notarized preview. Real redemption was not performed for acceptance; a historical overnight card outcome remains unconfirmed. New binaries may still require macOS Keychain approval.

## 0.5.0-dev.3 - 2026-10-23

- Preserve confirmed redemption receipts independently of quota refresh. Keep the protected ledger open while running, retain observed card outcomes and account-owned diagnostic checks, warn once per unresolved incident, and expose request preparation time/count plus notification state. Missing cards remain unconfirmed; no inferred success or changed consent.

## 0.5.0-dev.2 - 2026-10-23

- Show “Unconfirmed” instead of an Off switch when saved automatic-use consent or credentials cannot be read. Preserve consent, execution and recovery behavior; no Keychain permission changes.

## 0.5.0-dev.1 - 2026-10-22

- Add selectable72/48/24/12-hour reset-card expiry milestones, retaining existing toggles, per-node submission deduplication, card-use consent and history. Show continuous observation duration/count and interruption reasons through the shared pace model and Data status. Upgrade Keychain root-cause investigation remains pending; no prompt-free claim.

## 0.4.2 - 2026-10-21

- Replace ambiguous next-event arrows with explicit action buttons. Flatten usage-pace explanations to one disclosure without nested cards or repeated conclusions; compact surfaces open the full explanation in one click. Preserve estimates, reminders, card-use consent and history.

## 0.4.1 - 2026-10-21

- Suppress repeated reset-expiry banners after macOS accepts one submission for a card/milestone, including dismissal, refresh and restart. Preserve deduplication through temporary Keychain/account uncertainty, isolate account receipts, and retain72/48/24/12-hour nodes and retry after explicit submission failure. Distinguish submitted from verified delivery; other reminders and automatic use remain unchanged.

- Refresh the bilingual GitHub homepage with a clearer product story, native screenshots and direct downloads; add the reminder correction to About.

## 0.4.0 - 2026-10-21

- Share a compact next-event summary across Overview, menu and Widget, with at most two Overview items, conditional card windows and reset-reading confirmation.
- Open read-only card details and existing account-owned use records; separate redemption from exact notification delivery, without inventing old process timelines or adding another redemption action.
- Preserve actual card-detail read times through the existing15-minute supplemental cycle; stale or incomplete details cannot promise a use window. Preserve the65-item baseline, account benefits, all reminder switches, desktop controls, Token data and last-hour Widget chart.
- New features are macOS-only. Windows metadata stays synchronized; distribution remains a self-signed, non-notarized preview.
- If macOS temporarily protects the card-use ledger, show an unconfirmed authorization state instead of claiming automatic use was disabled; preserve the original ledger and consent.

## 0.4.0-dev.1 - 2026-10-21 (unpublished native development build)

- Connect the shared next-event summary and read-only account-owned card records to native Overview, menu and Widget. Separate confirmed card use from notification delivery; retained card dates cannot promise a fresh attempt window.
- Preserve reminder authorization, history, benefits and existing desktop controls. Native visual and live acceptance remain in progress; Windows metadata only.

## 0.4.0-preview.1 - 2026-10-21 (local design prototype)

- Add the selected quotas-first clickable design: compact Next summary, click-only card details, shared menu/Widget scenarios and separate redemption/notification outcomes.
- Use synthetic data only. No native app, authorization, stored settings or release changes.

## 0.3.0 - 2026-10-20

- Add a shared five-hour quota-pace reference in Overview, menu and Widget. It uses recent contiguous account-owned observations, states its constant-rate assumption, and suppresses estimates when history is missing, stale or unstable. It is not an accurate time-left guarantee and never controls Codex tasks.
- Add optional account-authorized reset-card use in the card’s final hour, earliest expiry first. Automatic use is off by default; confirmed use produces a dedicated success notification and history record, with persistent notification retry/deduplication.
- Add an independent, default-on72/48/24/12-hour expiry-reminder switch. Keep recovery/low-quota preferences, account benefits, official Token usage and the Widget’s last-hour chart.
- Label the selected primary quota explicitly; protect late connection results and independent refreshes. Preserve existing settings, account histories and credentials.
- macOS-only feature additions. Windows retains its existing interface with synchronized version metadata. Distribution remains a self-signed, non-notarized preview; real redemption is not consumed for release verification.

## 0.3.0-dev.5 - 2026-10-20 (unpublished local development build)

- Replace the Overview quota card’s unexplained star with a localized “Primary” label and existing display-purpose help. Primary-quota selection and all quota/reminder behavior remain unchanged. Windows metadata only.

## 0.3.0-dev.4 - 2026-10-20 (unpublished local development build)

- Send a dedicated automatic-card-use success notification after the service confirms `reset` or an idempotent `alreadyRedeemed` result, identifying the card by its original expiry time.
- Persist account-owned pending notices, verify Notification Center delivery, and retry notification failures without consuming another card. Verified notices are deduplicated across checks/restarts and recorded in notification history.
- Success notices are independent of expiry/recovery reminder switches. Allow system notifications; macOS controls banner visibility. No real card consumed in verification; Windows metadata only.

## 0.3.0-dev.3 - 2026-10-20 (unpublished local development build)

- Add a separate “Reset-card expiry reminders” switch above automatic card use in Settings → Reminders, with the existing72/48/24/12-hour schedule visible. Old settings default to On.
- Persist this choice independently from recovery/low-quota reminders and automatic card redemption. Disabled reminders keep card details, notification history and deduplication; re-enabling does not replay handled thresholds.
- Recheck the switch before delivery and preserve preference changes across in-flight batches; canceled, unsent expiry events are not logged as failed deliveries. Windows metadata only; no public release or real card use.

## 0.3.0-dev.2 - 2026-10-20 (unpublished local development build)

- Add an independent, default-off, account-scoped setting to use a specified earned reset card during its final hour, using the documented Codex app-server consume method.
- Check each minute while the app runs and on wake; persist the exact card/request identity before sending. Reuse that identity on retries, distinguish service outcomes, and stop other card use when a prior outcome cannot be verified until that card expires. No credits are purchased.
- Keep existing expiry/low-quota/recovery reminders and all previous controls. Enabling requires explicit in-app confirmation. Quitting, sleep, network/auth failures and unsupported clients can prevent timely use. Real redemption is not tested; Windows metadata only.

## 0.3.0-dev.1 - 2026-10-19 (unpublished native development build)

- Incrementally add one shared five-hour quota-pace evaluator to existing Overview, Widget and menu surfaces, preserving account, Token, desktop and settings entries.
- Compare the alert level with reset using contiguous account/cycle-owned history; suppress extrapolation for stale, cached, missing, reset, invalid, uneven or restricted readings.
- Retain Off/5/10/20% reminders. Off uses10% as a reference without changing notification state. Estimates are conditional, not guaranteed runtime. Update About highlights; Windows metadata only. Prediction error and device coverage remain pending; no publication.

## 0.3.0-preview.1 - 2026-10-19 (unpublished browser prototype)

- Document65 retained native capabilities, prototype omissions and per-item acceptance gates. Removals require explicit user approval; unfinished relevant checks block production release.


- Explore quota pace versus reset, with conditional estimates, seven synthetic scenarios and shared Overview/Widget/menu summaries. Retain the last-hour chart and account/Token/About entries.
- Preview5/10/20% target changes and clearer reminder wording in Chinese and English. No live quota, native integration, actual notification or task control; native development version remains0.2.2-dev.1.

## 0.2.2-dev.1 - 2026-10-19 (unpublished local preview)

- Ignore late connection results and credential-read failures after changing account source, keeping current account status and history isolated.
- Allow a new connection to refresh while the superseded request finishes; an old completion no longer clears the new request's activity indicator.
- Add synthetic transport recovery, wake-callback and connection-race regressions; retain existing low-quota/recovery reminders and their deduplication. Keychain access protections are unchanged; normal system confirmation may still be needed. Windows version metadata only.

## 0.2.1 - 2026-10-17

- Combine the round bubble and edge strip into one adaptive floating Widget. Drag to either edge for a slim vertical strip, or inward for a bubble; share details, the last-hour chart and pin behavior. Preserve legacy edge positions and backup any replaced bubble position during one-time migration.
- Restore free card movement through its native title drag region, keeping buttons independent and positions persistent.
- Make clicks on preview backgrounds and padding keep details open, including during expansion; preserve explicit unpinning, outside dismissal and Escape.
- Prevent the dial flashing during attached transitions. Retain edge anchoring, use an inset outline and preserve the supersampled mask.
- Keep release highlights in About rather than duplicating them in Connection settings. Retain About entry points, update checks, account benefits, history and existing credentials.
- Windows receives version metadata only and retains its existing interface. macOS arm64 remains a self-signed preview, not Developer ID signed or notarized.

## 0.2.1-dev.5 - 2026-10-17 (unreleased local preview)

- Remove duplicated release highlights from Settings → Connection. Keep them in About, with the full release-notes link; preserve connection guidance, About entry points and update checks. Windows receives version metadata only.

## 0.2.1-dev.4 - 2026-10-17 (unreleased local preview)

- Merge the round bubble and edge strip into one floating Widget: drag it to either edge for a slim vertical strip, or inward for a bubble. Both share details, the last-hour chart and pin behavior; keep the freely movable information card as the second style.
- Migrate the previous edge-strip selection and position once, preserving old position records and backing up any replaced bubble position. Keep the supersampled native mask and draw the attached border inside it to prevent clipping. Windows receives version metadata only.

## 0.2.1-dev.3 - 2026-10-17 (unreleased local preview)

- Drag the card Widget by its title area using native window dragging; keep refresh/close controls separate and retain its position across reopen. Moving works independently of the always-on-top option.
- Restore the round-bubble selection as a circle even when its saved position was attached to an edge. Start the edge-strip selection and side changes as a slim vertical strip instead of a rings preview. Preserve manual bubble edge snapping and explicit ring preview. Windows receives version metadata only.

## 0.2.1-dev.2 - 2026-10-17 (unreleased local preview)

- Fix clicks on the Widget preview background and padding, including during expansion, so they keep details open instead of leaving a temporary hover preview. Preserve intentional unpinning, outside dismissal, edge transitions and dragging. Windows receives version metadata only.

## 0.2.1-dev.1 - 2026-10-16 (unreleased local preview)

- Prevent the desktop dial flashing during edge-attached Widget transitions. Retain attachment and unfold details directly inward, returning to the same rail on collapse. Shorten edge transitions while retaining pin, drag, Escape and reduced-motion behavior. Development preview notes link to the published release. Windows receives metadata only.

## 0.2.0 - 2026-10-16

- Update the Windows runtime to Electron 43.5.0 and packager to 20.3.0, validating the Node.js 22.12–24 requirement; retain the existing interface.
- Reorganize the native Mac app into Overview, Token usage and Settings, with a compact menu-bar panel and persistent About entry in the sidebar and More menu. About and the product explanation now highlight this release.
- Retain Widget's last-hour consumption chart, persistent pin and slim vertical edge tab. Preserve explicit show/hide across relaunches. Join the built-in notch and open its details only on click.
- Align Widget and Overview on account-scoped local quota decreases in percentage points; explain history ranges and bar intervals. Inspect Overview bars by hover or click. Keep official daily Token counts separate, with an honest unavailable state.
- Preserve subscription validity, Credits, reset count and every returned expiration. Keep missing quota selections unknown, separate account history, retain legacy backups and handle same-account refresh failures without inventing fresh data.
- Add 5% low-quota reminders, localized native menus and fullscreen shortcuts. This monitor does not stop or resume Codex tasks.
- macOS arm64 self-signed preview; not Developer ID signed/notarized. Windows x64 portable preview retains its previous interface; the native redesign is Mac-only. See versioned QA for remaining device/lifecycle coverage.

## 0.2.0-dev.13 - 2026-10-16 (unreleased native development)

- Separate the allowance period from the displayed history range in Widget and Overview titles. Show bar duration and percentage-point units separately, with the 80% to 70% example; name the Token chart Daily Token counts and state its daily UTC grouping. Calculations, data sources and existing features are unchanged. Windows receives version metadata only.

## 0.2.0-dev.12 - 2026-10-16 (unreleased native development)

- Use one observed-decrease rule for Widget bars, Overview bars and Overview totals, excluding reset changes, missing/invalid readings and long gaps. Match totals to their displayed chart range.
- Name Widget/Overview consistently as quota consumption in percentage points, show each bar interval and their shared local-history relationship, and keep Codex daily Token counts explicitly separate. Preserve Widget last-hour history, account details and chart inspection. Windows receives version metadata only.

## 0.2.0-dev.11 - 2026-10-16 (unreleased native development)

- Inspect Overview quota-consumption bars by hovering or clicking to see the period and precise percentage-point decrease. Keep the tooltip inside the plot, clear it when leaving the chart or changing data, and preserve existing aggregation and Token charts. Windows receives version metadata only.

## 0.2.0-dev.10 - 2026-10-16 (unreleased native development)

- Add an explicit localized fullscreen toggle and Control-Command-F shortcut in both languages, so entering/exiting fullscreen does not depend on AppKit recognizing an English View menu title. Preserve existing navigation, close and quit commands.

## 0.2.0-dev.9 - 2026-10-16 (unreleased native development)

- Preserve an explicitly hidden desktop widget across relaunches; new installations still default to showing it. Temporary window closure during presentation changes does not replace the saved choice.
- Refresh the native File/View/navigation/Quit menus when language changes and name the edge strip consistently with its collapsed appearance.

## 0.2.0-dev.8 - 2026-10-16 (unreleased native development)

- Restore Overview account benefits: plan, subscription validity or billing link, manual reset count and each expiration, and Credits balance. Show exact quota reset dates alongside countdowns. Preserve unknown/zero distinctions and historical subscription labels; retain the new quota/Token charts.

## 0.2.0-dev.7 - 2026-10-16 (unreleased native development)

- Keep first/last quota bars and time labels inside the plot with horizontal padding and clipping; preserve fractional axis labels. Keep bilingual descriptions readable at the minimum window width.
- Distinguish local allowance decreases in percentage points from official daily Token counts. Rename the Usage entry to Token usage and show an explicit unavailable state when Codex returns no Token statistics, instead of substituting a second quota chart. Match chart dates and compact counts to the selected language. Windows receives version metadata only.

## 0.2.0-dev.6 - 2026-10-15 (unreleased native development)

- Remove the redundant normal “Available” line from the menu popover and fit its quota section to measured content instead of reserving empty space. Preserve cache/error/unknown/restricted messages and the scrolling limit for long content. Windows receives version metadata only.

## 0.2.0-dev.5 - 2026-10-15 (unreleased native development)

- Open notch details only on click to prevent pointer-hover activation. Keep outside-click/Escape dismissal and the physical-notch geometry; update both-language help. Bubble and edge-widget hover behavior is unchanged. Windows receives version metadata only.

## 0.2.0-dev.4 - 2026-10-15 (unreleased native development)

- Keep explicitly pinned widget details open when opening the main window. Temporary previews still close; unpinning and Escape retain their existing behavior. Windows receives version metadata only.

## 0.2.0-dev.3 - 2026-10-15 (unreleased native development)

- Rebuild the menu-bar popover around quota/reset/freshness and quick actions. Show the selected verified allowance in the status item; stale/cached/unknown values stay unknown there.
- Replace the expanded bubble’s large decorative dial with a compact branded card while preserving its selected-window last-hour consumption chart, explicit keep-open state, pin/drag behavior and thin vertical edge tabs. Keep the supersampled native silhouette mask.
- Add native notch hover/click-hold details. Both frames overlap the physical-notch bottom by one point to prevent a wallpaper gap; outside click/Esc dismisses the notch hold independently of widget pinning. Hardware/fullscreen acceptance remains pending.
- Preserve missing selected labels across surfaces and suppress per-window unknown confidence even when another window is verified. Windows receives metadata only; the public stable release remains 0.1.145.
- Compare development versions below the same stable version, preserve build-metadata equality and explain preserved unassigned history in the native UI.

## 0.2.0-dev.2 - 2026-10-15 (unreleased native development)

- Implement the native Overview/Usage/Settings sidebar, paired quota cards, dedicated reminder/display/connection/general sections and resizable main window. Connect the existing real quota, history, connection and notification services; add Command-1/2/3 navigation.
- Ask for notification permission from reminder/test actions rather than at launch. Persist language/refresh interval and label refresh status with the last successful reading. Reduce chart label crowding and keep percentage-point units explicit. Windows receives version metadata only; stable downloads remain 0.1.145.

## 0.2.0-dev.1 - 2026-10-15 (unreleased native development)

- Keep an explicitly selected missing allowance unknown, including the bubble dial and notch; retain its last known label across restart without retaining a quota value. Only automatic selection may fall back.
- Support the 5% low-quota threshold in native settings, persistence and the existing deduplicated reminder evaluator. Windows changes are version metadata only. Installed/public stable remains 0.1.145; the new native layout is still pending.
- Isolate new quota history by verified account with preserved legacy files; retain marked last-known values only for same-account transport failures, and reject cross-account supplemental details or delayed batches.

## 0.2.0-preview.3 - 2026-10-15 (design preview only)

- Join both notch states seamlessly to the physical notch and restore thin vertical edge-rail tracks. Native implementation remains pending.

## 0.2.0-preview.2 - 2026-10-15 (design preview only)

- Add the five-state widget/notch concept board to the preview and a bilingual cross-version review covering confirmed source gaps, migration, account history, notifications, lifecycle, accessibility and release gates. Native implementation remains pending.

## 0.2.0-preview.1 - 2026-10-15 (design preview only)

- Add the selected sidebar interaction prototype with Overview, Usage and Settings, synthetic quota states, reminder controls and widget interaction previews. Add paired product/acceptance documents. The installed/released native application remains 0.1.145; no native 0.2.0 feature or release is claimed.

## 0.1.145 - 2026-10-13

- Supersample the native floating-window silhouette before compositing to soften curved-edge aliasing, while preserving bubble/ring geometry, quota values, pinning and dragging. Match mask rasterization to its render scale and refresh it when display backing changes. Windows receives version metadata only.
- Refresh the bilingual GitHub homepage with current native demo components, clear download/setup entries and explicit platform scope; replace the historical release-paragraph stack with the version/acceptance index.

## 0.1.144 - 2026-10-13

- Keep pinned round-bubble details expanded when clicking the desktop, another app or another ReadyCheck window, and when the detail window loses focus. Unpinning restores hover preview; Esc remains a manual dismissal.
- Remove the detail minus button and update Bubble-specific pin/hover help without changing EdgeRail-style semantics. Preserve circle geometry and existing dragging behavior. Windows version metadata only.
- Wait for actual AppKit content layout in the existing sizing test while retaining every target-size assertion; production geometry and animation are unchanged. All 278 public-source tests pass with no failures or skips. Release assets, CI, strict Mac signing, local installation and downloaded-package hashes are verified; see [acceptance](docs/versions/0.1.144/QA.md) for the original failure and manual coverage limits.

## 0.1.143 - 2026-10-13

- Reduce the compact dial's C mark from 24 to 18 points, its percentage font from 13 to 11 points and the percentage's downward offset from 16 to 8 points. Keep the label inside the inner ring while preserving ring geometry, widget sizes, expanded logo size and interactions. Windows version metadata only.
- Include the preceding 0.1.142 mouse-capture repair: edge rails and expanded dials drag directly inward without a preliminary vertical drag.

## 0.1.142 - 2026-10-13 (local preview)

- Fix directly dragging edge rails or expanded dials inward without a preliminary vertical drag. Capture the mouse on press, prevent pending hover expansion, track screen-pointer movement outside the narrow rail, and distinguish clicks from drags. Windows version metadata only.

## 0.1.141 - 2026-10-12

- Document the 35-second current-widget campaign, Chinese narration, new original music, media validation and actual platform submission states; no application behavior change.
- Restore recent-hour quota consumption bars, with one bar per five-minute bin rather than repeated groups. Keep proportional heights, dim zero ticks and blank missing bins; update both-language help. Preserve the compact bubble layout and interactions. Windows version metadata only.

## 0.1.140 - 2026-10-12

- Keep the bubble's detail pin visible in both states; use a filled blue pin while details are kept open. Add state-specific tooltips explaining pointer-exit behavior and that this is separate from always-on-top.
- Click again to restore hover preview and release keyboard focus. Scope generic hover help to the dial so it does not override button tooltips; allow tooltips while the app is inactive and expose the state for accessibility. Windows metadata only.
- Include the 0.1.136–0.1.139 concentric bubble, compact sculpted shell, smaller dial, exact-quota edge rails, observed consumption line and outline/title corrections in this public release.

## 0.1.139 - 2026-10-12 (local preview)

- Give expanded details roughly two thirds of the width. The dial region is 176 points rather than matching the 248-point window height; rings and C scale proportionally, and free expansion keeps the actual dial center anchored.
- Keep ReadyCheck on one line when the preview pin button is visible, restoring space for both reset countdowns. Use an inset outline, one native exterior mask, display-density mask rendering and tangent-aligned neck joins to reduce edge clipping and aliasing. Retain curves, free bubbles and thin rails. Windows metadata only.

## 0.1.138 - 2026-10-12 (local preview)

- Reduce expanded bubbles from 560 × 276 to 500 × 248 points, about 20% less area, with adjusted typography. Preserve the sculpted dial, free bubble and both thin edge rails.
- Replace the four repeated strokes per five-minute bin with a thin line and subtle fill. Preserve true sample values, zero and gaps; isolated samples show a point, with no line across missing data or smoothing overshoot. This depicts observed quota decreases, not remaining quota, Token usage or energy consumption. Windows metadata only.

## 0.1.137 - 2026-10-12 (local preview)

- Restore the selected sculpted outline, layered metallic dial, thicker exact-quota arcs and plain C mark. Increase expanded dimensions to 560 × 276 points; use colored quota markers, separators, reset countdowns and a blue app link.
- Dragging a round bubble to either edge collapses it to a 28-point vertical rail with two bars proportional to remaining quota. Preserve free dragging, inward expansion, half-second hover, click-to-pin and Esc dismissal. Windows metadata only.

## 0.1.136 - 2026-10-12 (local preview)

- Round bubbles use the approved C artwork and concentric remaining-quota rings. Expanded details share a continuous surface and outline with the dial; ring strokes and the C mark scale with the window transition rather than switching cards. Free bubbles open toward available space while retaining the dial center when unclamped; resting diameter is 92 points.
- Recent-hour bars show observed local quota decreases; missing bins stay unknown, resets/recovery and gaps over ten minutes are excluded. Existing quota colors, all-window details, reset countdowns and other widget styles remain available. Windows receives version metadata only.
- Disable hosting size inference for the explicitly sized bubble panel so edge, circle and detail geometry remain synchronized after transitions.

## 0.1.135 - 2026-10-11

- Add optional hiding of widgets and notch status in native full-screen Spaces while monitoring and notifications continue. Preserve placement and temporary-hide deadlines.
- Compare today so far with yesterday and the last seven complete UTC dates with the previous seven. Missing/invalid days remain unknown; zero baselines have no change percentage. Add previous-day change to Token hover details. Windows receives version metadata only.
- Clear bubble/edge hover timers and expanded intent when switching Spaces; test preview re-entry and cancellation. Include the preceding countdown/interaction updates and user-confirmed notification-icon acceptance after a Mac restart.

## 0.1.134 - 2026-10-09 (local preview)

- Add countdowns for current, verified official quota reset times in bubble and edge-ring details; elapsed deadlines wait for a refresh rather than claiming recovery. Unknown or outdated data stays unconfirmed.
- Unify 0.5-second hover previews, click-to-keep-open details, outside-click dismissal and Esc for focused details. Cancel hover timers during dragging and prevent immediate reopening after explicit dismissal. Increase bubble detail height to accommodate countdowns. Windows receives version metadata only.

## 0.1.133 - 2026-10-09 (local preview)

- Use content-addressed macOS app-icon resources and refresh the running bundle’s Launch Services registration before notification setup, so icon updates can be rediscovered while preserving the app identity. Packaging now requires a valid ICNS instead of silently falling back to an unreferenced PNG. Windows only shares the version.
- Initial notification-icon acceptance failed after local registration and service maintenance. On October 10, the user confirmed correct artwork after restarting the Mac with 0.1.134 installed; see the [acceptance record](docs/versions/0.1.133/QA.md).

## 0.1.132 - 2026-10-08

- Add optional low-quota notifications (20% or 10%) with per-account/window/cycle deduplication and verified delivery retries; hide widgets for 30/60 minutes without stopping monitoring, including early resume and restart restoration. Add visual style selection with placement hints and data-status explanations for source, freshness, missing fields and historical subscription dates. Windows only shares the version.
- Include the 0.1.131 installation checks and recovery guidance for launch-at-login failures.

## 0.1.131 - 2026-10-07 (local preview)

- Detect incomplete macOS app installations before updating login items; explain recovery steps, expose Login Items after a system failure, and log the error domain/code without exposing private descriptions. Development launches now use a complete signed app in a persistent directory. Windows only shares the version number.

## 0.1.130 - 2026-10-02

- Keep all returned windows in scrollable round-bubble details; preserve panel size, urgency colors and the blue app link. Clarify primary quota selection for bubble/notch and retain missing saved or legacy choices while temporarily falling back. Windows version metadata only.

## 0.1.129 - 2026-10-01

- Adapt macOS edge rings, collapsed bars, and quota details to validated windows returned for the account. Shrink weekly-only capsules, distinguish additional named buckets, and resize on refresh; large lists scroll within the screen. Windows receives version metadata only.

## 0.1.128 - 2026-09-29

- Restore the daily Token chart and hover totals in separate OAuth mode when the local Codex app-server reports Token history for the exact same account. Keep OAuth quota data authoritative and show the local percentage-point chart when no matching Token history is available. Windows receives version metadata only.

## 0.1.127 - 2026-09-28 (local preview)

- Carry the C identity into the macOS menu bar and its quota popover. Replace remaining legacy gauge symbols in the main window with icons for refresh and quota selection. Windows receives version metadata only.

## 0.1.126 - 2026-09-28 (local preview)

- Replace the rejected two-window app mark with a single C-shaped progress motif selected for ReadyCheck. Keep the icon fixed while the interface shows live quota values. Windows receives version metadata only.

## 0.1.125 - 2026-09-28 (local preview)

- Replace the generic gauge app icon with a fixed two-window brand mark. Use the packaged app icon in the macOS main header and About window; live quota percentages remain in the interface. Windows receives version metadata only.

## 0.1.124 - 2026-09-28 (local preview)

- Place the account-source label above its segmented choices so the English label and both options remain readable in the narrow macOS account card. Windows receives version metadata only.

## 0.1.123 - 2026-09-27 (local preview)

- Restore the blue “Open ReadyCheck” link in the edge-rail detail card. Shorten narrow-capsule hover expansion from one second to half a second; clicking still opens it immediately. Windows receives version metadata only.

## 0.1.122 - 2026-09-27 (local preview)

- Make the whole expanded edge capsule the single control for showing or hiding the shared quota details; the two rings now display data without separate click highlights. Hover over the narrow capsule for one second to reveal both rings, or click to reveal them immediately. Leaving early cancels the hover action. Windows receives version metadata only.

## 0.1.121 - 2026-09-27 (local preview)

- Scale the edge handle's 5-hour and 7-day colored bars to their actual remaining quota ratios. Click to reveal the rings and click a ring to toggle its detail card; hover now gives a subtle highlight instead of opening details. Animate the panel's frame with reduced-motion support. Windows receives version metadata only.

## 0.1.120 - 2026-09-27 (local preview)

- Make the edge rail recoverable after it collapses: use a visible draggable handle, show the quota rings when the style is selected, and add Left/Right and Show rings controls. Clarify that Round bubble, Card, and Edge rings are alternative widget styles; the original round bubble remains available. Windows receives version metadata only.

## 0.1.119 - 2026-09-27 (local preview)

- Add an optional macOS edge-rail widget alongside the bubble and card. Its narrow edge line opens to separate live Codex 5-hour and 7-day rings on hover; hovering a ring reveals a compact detail card. Drag the rail to either screen edge, and move the pointer away to collapse it. Stale or missing percentages appear as unknown. The notch display remains available. Windows receives version metadata only.

## 0.1.118 - 2026-09-27

- Read `rate_limit.allowed` from the independent OAuth usage response as the same explicit ordinary-use permission shown for the local Codex app-server. Missing or null permission remains unknown; percentages do not substitute for it. Keep the interactive Keychain retry visible when a saved OAuth login cannot be read during refresh. Windows receives version metadata only.

## 0.1.117 - 2026-09-27 (local preview)

- Read the optional official backend permission for ordinary Codex usage separately from quota percentages. Show restricted or unknown status instead of claiming availability when permission is false or absent; quota-increase alerts remain based on verified window changes.
- Explain when a saved persistent-widget window is missing after an account change and show the temporary fallback. Link missing subscription dates to OpenAI's ChatGPT billing guidance. Windows receives version metadata only.

## 0.1.116 - 2026-09-26 (local preview)

- Keep displaying the subscription date found in the sign-in token. If that date has passed, label it as the last recorded date instead of hiding it behind “Unconfirmed”.
- When the current connection supplies no subscription date, direct users to ChatGPT billing for the current date. Windows receives version metadata only.

## 0.1.115 - 2026-09-26 (local preview)

- Put verified quota and recovery status ahead of collapsible display settings in the macOS main window.
- Populate the persistent-display quota picker from the connected account's actual windows; keep bubble and notch labels aligned with the selected or available fallback window.
- Show an outdated-data hint in the expanded bubble and stop presenting a past token subscription date as a future renewal. Windows receives version metadata only.

## 0.1.114 - 2026-09-26

- Rename the macOS account-source choices to “Follow Codex on this Mac” and “Sign in separately”, with a short explanation of each selection.
- Keep the floating window's clipping outline continuous as it expands and collapses, and remove the full-card opacity/scale transition that could flash at the edge.
- Windows receives version metadata only.

## 0.1.113 - 2026-09-26

- Mask the floating window at the AppKit layer to the current bubble, edge capsule, or expanded-card silhouette. Use a solid dark surface without an outer shadow so no rectangular backing can be composited outside that silhouette.
- Windows receives version metadata only.

## 0.1.112 - 2026-09-26 (local preview)

- Remove the square backing produced by the bubble's Liquid Glass effect. Use a shape-bounded frosted material for the round bubble, edge capsule, and expanded card.
- Windows receives version metadata only.

## 0.1.111 - 2026-09-26 (local preview)

- Clip the frosted bubble surface to its rounded shape so the expanded card has no pointed translucent corners. Restore the blue accent on the “Open ReadyCheck” link.
- Windows receives version metadata only.

## 0.1.110 - 2026-09-24 (local preview)

- Give the macOS bubble, edge capsule, and expanded quota card a consistent dark frosted surface with fixed high-contrast foregrounds. Keep a subtle system glass layer, the existing status colors, and a solid surface when Reduce Transparency is enabled.
- Windows receives version metadata only.

## 0.1.109 - 2026-09-24

- Let the Desktop widget settings card fit its controls in Bubble mode instead of retaining an unnecessary minimum height. Card mode can still grow to show its extra style controls.
- Windows receives version metadata only.

## 0.1.108 - 2026-09-24 (local preview)

- Move the shared quota-window choice above the Desktop widget and Notch display groups, and explain that bubble, card, and notch displays use the same selection.
- Windows receives version metadata only.

## 0.1.107 - 2026-09-24 (local preview)

- Reduce the minimum height of the Desktop widget and Notch display groups so their cards finish closer to the last control while retaining content-driven growth for Card mode and longer text.
- Windows receives version metadata only.

## 0.1.106 - 2026-09-24 (local preview)

- Reorganize the main dashboard's display controls into separate Desktop widget and Notch display groups. Align each group's visibility switch and put style, quota choice, and reset action beside the feature they affect.
- Keep connection status and refresh actions above the display controls. No preference behavior changes; Windows receives version metadata only.

## 0.1.105 - 2026-09-24 (local preview)

- Stop the expanded quota card's glass border from lingering as a capsule-shaped flash when collapsing back to a round bubble. Switch the circle content before the window returns to its resting frame; keep window movement and edge-tab expansion behavior.
- Windows receives version metadata only.

## 0.1.104 - 2026-09-24 (local preview)

- Remove the transient edge-capsule outline when a dragged capsule becomes a round bubble. Switch those resting shapes and their window geometry together instead of cross-fading the old border through the resize.
- Keep expansion and collapse motion. Windows receives version metadata only.

## 0.1.103 - 2026-09-24 (local preview)

- Give the bubble, screen-edge capsule, expanded quota card, and existing floating card native Liquid Glass on macOS 26 and later, with material and Reduce Transparency fallbacks. Preserve the black notch silhouette.
- Animate expansion, collapse, and snap after drag release; keep active dragging directly under the pointer and honor Reduce Motion.
- Windows receives version metadata only.

## 0.1.102 - 2026-09-24 (local preview)

- Stop the bubble's brief recovery border from flashing when switching between the 5-hour and 7-day quota windows. Highlight only a verified increase in the same selected window.
- Windows receives version metadata only.

## 0.1.101 - 2026-09-24 (local preview)

- Redesign the edge tab as a larger, readable capsule with the installed Codex or ChatGPT icon, the selected quota window's short label and verified remaining percentage, a vertical progress rail, and an inward-pointing expand cue. Mirror the layout on left and right edges and preserve saved tab positions.
- Windows receives version metadata only.

## 0.1.100 - 2026-09-24 (local preview)

- Move the bubble from absolute screen-pointer movement so dragging no longer feeds back through its moving view coordinates; enlarge the bubble and edge tab while preserving saved positions.
- Restore green, orange, and red urgency colors independently for both expanded quota bars. Windows receives version metadata only.

## 0.1.99 - 2026-09-24 (local preview)

- Add a compact Codex quota bubble that expands on click, can be dragged, and folds into a screen-edge tab. Keep the existing card and notch displays available.
- Use the icon of an installed Codex or ChatGPT app in the bubble, with a system-symbol fallback. Show percentages only for fresh, validated quota data.
- Remember the bubble position, keep one always-on surface visible at a time, and expose Bubble/Card selection in Settings and the menu bar. Windows receives version metadata only.

## 0.1.98 - 2026-09-22

- Bound the local Codex event handshake, reject initialization errors, and fall back to another installed Codex client when the first candidate is unavailable or unresponsive.
- Reconnect event monitoring with capped exponential backoff and invalidate callbacks from a stopped monitor generation.
- Show a sanitized local quota-event connection state and refresh a complete snapshot after the event stream reconnects.
- Calibrated against Codex CLI 0.155.0-alpha.9.2 generated JSON Schema. Windows includes synchronized version metadata and a portable preview package.
- Make Windows release packaging fail early on unvalidated Node versions and support an explicit compatible Node binary.

## 0.1.97 - 2026-09-20

- Add an explicit local Codex connection mode that reads the official app-server without requiring ReadyCheck's legacy OAuth token or Keychain access; keep standalone OAuth as a user-selected fallback.
- Refresh on both account and rate-limit updates, preserve account isolation with official account IDs, and parse the current reset-credit detail contract without treating unknown details as an empty list.
- Verify notification removal through a testable adapter and preserve a newly delivered recovery baseline when an older alert removal is still retrying.
- Add a system-backed Launch at Login setting that reports approval and availability through `SMAppService.mainApp`.
- Windows version metadata only. Local preview; not published.

## 0.1.96 - 2026-09-15

- Verify that recovered-quota notifications are absent from Notification Center before completing an automatic dismissal.
- Retry dismissal after an asynchronous macOS removal failure and clear any older recovered-quota notifications left behind under another request identifier.
- Windows version metadata only. Local preview; not published.

## 0.1.95 - 2026-09-15

- Automatically remove a persistent quota-recovery notification when the recovered quota starts being consumed.
- Replace older recovery notifications with the latest recovery, migrate the most recent 0.1.94 alert, and preserve retry, account isolation, and notification history behavior.
- Allow release packaging to use a temporary SwiftPM build directory and omit unshipped dSYM generation on macOS 27.
- Windows version metadata only. Local preview; not published.

## 0.1.94 - 2026-09-15

- macOS wake reconnects quota events and queues a fresh quota/reminder check, coalescing with pending event refreshes.
- Visible floating widgets are clamped to an available screen after display changes without activating the app or reopening hidden widgets.
- Windows version metadata only.

## 0.1.93 - 2026-09-13

- Fixed macOS recovery alerts to detect increases from partially consumed quota, including independent window recovery. Consumption and unchanged refreshes do not notify. Windows version metadata only.

## Unreleased

## 0.1.92 - 2026-09-11

- macOS: replace the hidden, one-time recovery action with an always-visible switch, enabled by default. Observe exhaustion automatically and notify once per recovery cycle without repeated setup.
- Persist the switch, cancel pending waits when disabled, protect against in-flight refreshes restoring cancelled requests, and explain monitoring, connection, stale data, notification settings and failed delivery beside the control.
- Keep the notification test action available after a test, show results separately, and clarify the system-notification settings link. Windows only shares the version number.

## 0.1.91 - 2026-09-11

- macOS: opt in to a one-time quota recovery notification from the main window or menu bar. Wait for verified remaining quota in every tracked window; persist requests, support cancellation, retry failed delivery, and isolate accounts.
- Windows: version synchronized; recovery reminders are not implemented in this preview.

## 0.1.90 - 2026-09-07

- Serialize Keychain operations and disable authentication UI only during background legacy-Keychain reads, restoring the process flag afterward. Preserve history loading and provide an explicit credential-read retry instead of forcing OAuth again.

- Distinguish persistent, temporary, and disabled macOS alerts using the actual notification style; recommend persistent alerts for Credits reminders.
- Retain foreground notifications in Notification Center as well as requesting banners and sound.
- Clarify macOS and Windows test-notification messages: system delivery evidence is not proof that the user saw a banner. Focus, sharing, and sleep settings remain respected.

## 0.1.89 - 2026-09-06

- Add a persistent 5-hour / 7-day quota selector beside the macOS notch toggle. The selected window drives its label, percentage, progress color, and availability dot.
- Keep 7-day as the default; show unavailable data instead of silently substituting another quota window.
- Windows version synchronized; notch remains macOS-only.

## 0.1.88 - 2026-09-05

- Clarify historical notification records on macOS and Windows: unverified past delivery does not mean reset credits could not be read.
- Explain missing delivery evidence without changing historical outcomes, reset-credit data, or reminder scheduling.

## 0.1.87 - 2026-08-31

- Refresh quota data promptly when the official Codex app-server emits `account/rateLimits/updated`, with matching macOS and Windows behavior.
- Keep the existing one-minute polling schedule as a compatibility and reconnection fallback.
- Debounce event bursts and wait for an active refresh to finish before reading official quota data again, without invoking model inference.
- Exclude tests and build-only Node dependencies from the Windows portable runtime archive.

## 0.1.86 - 2026-08-23

- Preserve official multi-bucket labels and server-classified limit states across macOS and Windows.
- Distinguish exhausted quota, depleted Credits, and workspace or member usage limits instead of showing a generic available state.
- Describe the official local Codex interface as the preferred source and the read-only OAuth endpoint as the compatibility fallback.

## 0.1.85 - 2026-08-12

- Verify macOS reminder delivery by finding the exact notification in Notification Center before recording success.
- Add notification readiness, a test notification, and a direct system notification-settings action to the macOS preferences UI.
- Reclassify pre-0.1.85 delivery records as unconfirmed instead of presenting API acceptance as verified delivery.
- Add matching test-notification and notification-settings actions to the Windows preview.

## 0.1.84 - 2026-08-11

- Read every available local Codex app-server candidate and fill missing reset-credit details only from another matching account.
- Reuse a previously verified future reset expiration across relaunches when current official sources temporarily omit the detail, while explicit zero still clears it.
- Keep macOS and Windows behavior aligned when reset-credit details are temporarily unavailable or rate limited.

## 0.1.83 - 2026-08-11

- Add a local notification history with delivery status, attempt time, retry count, and reminder details on macOS and Windows.
- Keep failed retries in one logical record and retain the latest 50 reminders instead of producing duplicate rows.
- Migrate legacy reminder thresholds as explicitly unconfirmed records rather than claiming the operating system delivered them.

## 0.1.82 - 2026-08-11

- Persist verified future manual-reset expirations so 72/48/24/12-hour reminders continue when the official detail source temporarily omits reset data.
- Mark a reminder threshold as delivered only after the operating system accepts the notification; failed deliveries remain eligible for retry.
- Treat an explicit zero reset count as the only signal that clears a persisted reset expiration, with matching macOS and Windows behavior.

## 0.1.81 - 2026-08-09

- Remind for each still-available manual reset at 72, 48, 24, and 12 hours before expiration.
- Deliver each threshold once across relaunches and stop later reminders after the reset is used.
- Collapse thresholds missed while the app was closed into the single most urgent reminder instead of sending a burst.
- Migrate the previous three-day reminder state without repeating the 72-hour notification, with matching macOS and Windows behavior.

## 0.1.80 - 2026-08-06

- Distinguish an explicit zero manual-reset balance from temporarily unavailable reset-credit details.
- Preserve unexpired reset-credit expiration data when the official detail endpoint is temporarily rate limited.
- Show a clear unavailable or missing-expiration state instead of reporting unknown reset data as zero on macOS and Windows.
- Keep one-minute quota refreshes while limiting supplemental reset and Token-detail requests to every 15 minutes; manual refresh still forces a detail attempt.

## 0.1.79 - 2026-08-05

- Notify once when a manual reset credit enters its final three days before expiration.
- Notify when verified Codex quota is exhausted and the Credits balance begins decreasing, once per exhausted quota cycle; restoring quota re-arms the next cycle.
- Persist reminder state across launches and keep macOS and Windows behavior aligned without adding model requests.
- Request macOS notification permission at launch when the user has not made a choice yet, instead of waiting until the first reminder event.

## 0.1.78 - 2026-07-30

- Show the exact date and Token count when hovering over a daily Token usage bar on macOS.
- Keep the matching Windows bar tooltip behavior covered by UI regression checks.

## 0.1.77 - 2026-07-30

- Keep the menu-bar popover fully below the macOS menu bar so its header and rounded top edge are not clipped.

## 0.1.76 - 2026-07-29

- Prefer the official local Codex app-server for quota windows, Credits, reset expirations, and account token usage when the installed Codex account matches ReadyCheck.
- Fall back safely to the existing read-only OAuth usage endpoint when app-server is unavailable, incompatible, or signed in to another account.
- Display validated quota windows dynamically instead of hard-coding a retired 5-hour or 7-day window.
- Add an official 7/30/90-day Token usage dashboard on macOS and Windows while preserving the local quota-decrease dashboard as a fallback.
- Make the macOS notch select an available quota window dynamically and keep Windows behavior aligned.
- Read small app-server stdio responses immediately instead of waiting for the long-running process to exit.

## 0.1.75 - 2026-07-25

- Remove the redundant manual-reset count from the main quota details and detailed widget.
- Show each available manual-reset expiration separately, with matching behavior on macOS and Windows.

## 0.1.74 - 2026-07-25

- Show the verified Codex credit balance or unlimited-credit state from the existing OAuth usage response in the main quota details and detailed widget.
- Keep the compact widget, menu bar, and macOS notch focused on the current quota percentage, and keep the Windows client aligned.

## 0.1.73 - 2026-07-25

- Correct the macOS notch availability dot: it is green only while verified Codex quota remains, and gray when quota is exhausted or current quota data is unavailable.
- Add regression coverage for usable, exhausted, and unknown quota states, and keep the Windows package version aligned.

## 0.1.72 - 2026-07-22

- Make the dot beside Codex in the macOS notch a binary data-status indicator: green when current quota data is available and gray otherwise. Quota urgency remains represented only by the percentage and progress bar colors.
- Keep the Windows package version aligned; notch status remains a macOS-only hardware integration.

## 0.1.71 - 2026-07-22

- Close the menu-bar panel when the user clicks an empty area or another app, so the panel remains dismissible even when menu-bar icons are crowded.
- Refresh the GitHub README preview to feature the macOS notch quota status and the current seven-day quota model without exposing account information.

- Fix the notch progress bar so normal 7-day quota uses the same green semantic color as the main quota progress bar instead of white.

## 0.1.70 - 2026-07-22

- Correct the current Codex quota presentation to show the remaining 7-day window and hide the discontinued 5-hour window across macOS and Windows.
- Update the notch status strip, widgets, menu bar, and local usage dashboard to use the verified 7-day window while retaining 5-hour parser and history compatibility.

## 0.1.69 - 2026-07-22

- Add an optional macOS notch status strip aligned to the detected hardware notch, with the current 5-hour percentage, semantic progress color, click-to-open behavior, and automatic notch-screen detection.
- Retire the discontinued Codex 7-day quota from macOS and Windows presentation while retaining parser and history compatibility for a possible future return.
- Improve main-window scrolling by replacing repeated material blur composition with static glass surfaces and reducing full-page time updates from every second to every 30 seconds unless a refresh is due.
- Keep the Windows package version aligned; the notch surface is intentionally macOS-only hardware integration.

## 0.1.68 - 2026-07-18

- Sign macOS preview packages with a stable local ReadyCheck identity when available, so rebuilt and upgraded preview apps retain the same Keychain application identity instead of inheriting a new ad-hoc identity.
- Sign the release app in a temporary local staging directory and keep only the final DMG in `dist`, preventing synced-folder metadata from invalidating an intermediate app copy.
- Build the DMG outside the synced `dist` directory and replace previous DMGs only after validation, preventing numbered conflict copies such as `macos 2.dmg`.
- Label successful OAuth exchanges that cannot be stored as “Credential save failed” rather than the misleading “Authorization failed,” while keeping the recovery action available.
- Keep the Windows package version aligned with the macOS preview release.

## 0.1.67 - 2026-07-16

- Rebuild the GitHub README preview GIF with HyperFrames and real product screenshots for a clearer product showcase.
- Align the macOS and Windows Codex OAuth request with the current Codex CLI flow by removing forced sign-in and including the expected originator parameter.
- Validate OAuth callback state before accepting provider errors, parse structured token failures, and keep user-facing diagnostics concise without logging credentials or callback data.
- Distinguish network, invalid token response, and credential-storage failures; on macOS, direct users to unlock the login Keychain when authorization succeeds but credentials cannot be saved.
- Report when the local OAuth callback listener is starting, listening, or unavailable instead of assuming it is ready immediately.

## 0.1.66 - 2026-07-15

- Show low, critical, and exhausted quota reminders consistently in both minimal and detailed widgets on macOS and Windows.

## 0.1.65 - 2026-07-15

- Distinguish exhausted quota from low quota with a clear waiting-for-reset message on macOS and Windows.
- Animate recent-usage bars from zero only when the chart first appears; automatic refreshes no longer replay the animation.
- Keep the chart on an explicit earlier-to-latest time axis and replace the blue selected-window outline with a quieter unified card state.
- Keep bar width visually consistent across the 24-hour, 7-day, and 30-day ranges instead of stretching sparse history to fill each category.
- Show a compact percentage label above every non-zero consumption bar instead of labeling only the highest bar.
- Bring the Windows recent-usage chart into parity with macOS for observed-period layout, fixed bar width, one-time entry motion, percentage labels, and quieter selected cards.
- Add headroom above the highest consumption bar on both platforms so the chart does not imply that the current top tick is a usage cap.
- Animate only newly added or increased usage bars after refresh on both platforms; unchanged bars remain still, while range changes use a short chart fade.

## 0.1.64 - 2026-07-15

- Replace the ambiguous remaining-quota line chart with a selectable 5-hour / 7-day consumption bar dashboard. Bars show detected quota decreases in percentage points and keep the current remaining percentage separate.
- Record successful quota refreshes in fixed one-minute buckets by default, retain 30 days of privacy-minimized local history, and do not attribute long refresh gaps, quota resets, or quota recoveries as consumption.

## 0.1.63 - 2026-07-14

- Fix recent-usage sampling so one-minute automatic refreshes accumulate a new history point after crossing each fixed five-minute boundary instead of overwriting one record forever.

## 0.1.62 - 2026-07-14

- Add contextual quota recovery actions: retry temporary refresh failures, reconnect only when authorization is explicitly rejected or cannot be refreshed, and keep existing credentials until replacement authorization succeeds.
- Add a local recent-usage dashboard for 24-hour, 7-day, and 30-day quota percentage trends without claiming token usage data.
- Persist privacy-minimized quota history locally in five-minute buckets for up to 30 days; account identifiers, credentials, and raw API responses are never stored in history.
- Keep the macOS and Windows recovery behavior, dashboard scope, and release version aligned.
- Make the Windows packaging script publish to the same repository-level `dist` directory when run from a git worktree.

## 0.1.61 - 2026-07-03

- Start the Windows desktop client under `apps/windows` with an Electron tray, main window, floating widget shell, local preferences, and fail-closed safe-refresh state.
- Add Codex OAuth callback handling and Electron `safeStorage` encrypted token persistence to the Windows preview; quota fetching remains fail-closed until the parser is ported.
- Add read-only Codex usage fetching and quota parsing to the Windows preview, including 5-hour / 7-day windows, subscription details, and manual reset details while keeping missing critical data fail-closed.
- Add a Windows black-box QA guide and `npm run smoke` preflight script for real-machine Windows 10/11 validation.
- Add a Windows portable packaging script that writes the current versioned `ReadyCheck-<version>-windows-x64-portable.zip` for copy-to-Windows testing.
- Document the Windows portable preview package as a downloadable GitHub Release asset for Windows 10/11 testing.
- Fix Windows preview widget always-on-top toggling, Minimal/Detailed switching, Detailed-mode clipping, and add OAuth region-restriction guidance.
- Add a Windows UI behavior smoke test that validates widget layout constraints, style switching, and OAuth guidance before packaging.
- Compact Windows main-window and widget typography, spacing, and window sizes so the persistent widget blocks less of the desktop.
- Add a Remotion product intro motion project under `marketing/remotion`, with Chinese and English 30-second ReadyCheck compositions.
- Add a procedural techno/synth background track for the Remotion product intro.
- Rework the product intro with stronger promo-style motion, prominent GitHub address placement, green/orange/red quota states, and a non-overlapping OAuth usage-flow diagram.
- Replace the soundtrack with a more restrained premium-tech bed.
- Add a lightweight animated README preview generated from the product intro.
- Replace the README preview GIF with a real ReadyCheck UI capture and a dedicated high-impact GitHub preview composition.
- Refine the README preview GIF by removing the GitHub address overlay and keeping all text clear of the real app UI.
- Add a redesigned menu-bar preview panel to the README GIF and scale the main window down so the product surfaces are easier to read without exposing user account information.
- Align macOS quota urgency thresholds with Windows so below 25% is critical, 25-49% is warning, and 31% remaining no longer appears green.

## 0.1.60 - 2026-07-02

- Add a non-interrupting update banner action to remind later, hiding the current version banner without disabling manual update checks.
- Change the main update banner action to View update because ReadyCheck opens GitHub Releases instead of installing updates in-app.
- Refine low-quota thresholds so 10-24% remaining is warning and below 10% is critical, while keeping widget warnings focused on the 5-hour quota.

## 0.1.59 - 2026-07-02

- Let detailed widget reset-expiration rows wrap onto multiple lines so long dates remain readable in the compact widget width.
- Add Cancel authorization and Retry authorization actions for Codex OAuth callback failures so users do not need to quit the app to restart the flow.
- Confirm the software update checker remains wired to the startup silent check and manual GitHub Releases check.

## 0.1.58 - 2026-07-02

- Align the Windows preview app version and portable zip name with the macOS release version.
- Read Codex reset credit expiration from the read-only `/wham/rate-limit-reset-credits` detail endpoint instead of leaving the expiration field unavailable when `/wham/usage` only provides the count.

## 0.1.57 - 2026-07-02

- Recognize Codex `rate_limit_reset_credits.available_count` as the active manual reset count in both macOS and Windows parsers.

## 0.1.56 - 2026-06-30

- Keep the detailed floating widget focused on user-facing quota and subscription details by hiding source and confidence metadata there while preserving it in the main window.

## 0.1.55 - 2026-06-30

- Add the same Minimal/Detailed widget style switcher to the menu-bar panel and share the switcher component with the floating widget.

## 0.1.54 - 2026-06-30

- Add a compact Minimal/Detailed widget style switcher directly in the floating widget header.
- Standardize the release workflow and make DMG packaging clean old ReadyCheck DMGs from `dist` before writing the current build.

## 0.1.53 - 2026-06-30

- Add a public real-world QA checklist covering first install, OAuth, safe refresh, update checks, widget placement, and failure modes.
- Add a regression assertion that update checks send the ReadyCheck version in the GitHub API User-Agent.

## 0.1.52 - 2026-06-30

- Hide the visible widget style picker label in the top control row so it no longer collapses into vertical text in Chinese layouts.
- Make app-launch widget restoration use the same default lower-right placement as Show widget and Reset position.
- Group the widget visibility, always-on-top, and style controls with clearer spacing while keeping every label on one line.
- Keep detailed widget account rows on a consistent font size instead of shrinking only the subscription summary rows.

## 0.1.51 - 2026-06-29

- Move the default widget placement closer to the bottom edge while preserving the right-side margin.
- Add a persisted Minimal/Detailed widget style selector in the top widget controls; Minimal remains the default.
- Detailed widget mode restores subscription, renewal, reset, source, and verification details inside the widget.

## 0.1.50 - 2026-06-29

- Make Show widget reopen the widget at the same default lower-right position as Reset widget.
- Avoid sending a hidden-state callback when no widget window exists.

## 0.1.49 - 2026-06-29

- Fix the Widget preference controls so Chinese labels no longer collapse into vertical text in the main window.

## 0.1.48 - 2026-06-29

- Add a non-blocking update banner in the main window when a newer GitHub Release is available.
- Add Check for updates and Download update actions to the menu-bar panel.
- Simplify compact quota cards for the desktop widget by keeping subscription details in the main window.
- Add a low-quota warning when a quota window drops below 25% remaining.
- Reorganize preferences into Language, Refresh, Widget, and Updates sections.

## 0.1.47 - 2026-06-29

- Add a lightweight GitHub Release update check with a manual Check for updates action and a download link when a newer version is available.

## 0.1.46 - 2026-06-29

- Hide source and verification metadata from compact quota cards so the desktop widget stays focused on the quota values.

## 0.1.45 - 2026-06-29

- Always render the manual reset count as a number; missing count data now falls back to `0` instead of `Not provided`.

## 0.1.44 - 2026-06-29

- Remove duplicated account email text from quota cards and the desktop widget so limited space stays focused on quota details.
- Show manual reset expiration only in the main window as a normal account-detail row, without the extra dark framed block.
- Display an explicit `0` manual reset count when the usage payload reports an empty manual reset list.
- Reduce the main window width from the previous wide layout while keeping richer account details readable.
- Restore click-to-open behavior on the desktop widget content area without making refresh and close buttons open the main window.

## 0.1.43 - 2026-06-29

- Restore the desktop widget to its original compact width while keeping Codex account and subscription details readable in a stacked narrow layout.
- Keep the main window scrollable and wide enough for the richer account details.

## 0.1.42 - 2026-06-29

- Restyle the Codex quota card to match the compact account-summary layout: provider pill, account title, subscription row, manual reset block, and quota progress rows.
- Make the main window scrollable and wider so the connected email and quota details are not clipped.

## 0.1.41 - 2026-06-29

- Add Codex account, plan, subscription renewal, and manual reset detail rows to the quota card when those fields are available.
- Keep unverified subscription and manual reset fields clearly marked as not provided instead of guessing values.

## 0.1.40 - 2026-06-26

- Start with Show widget enabled on every app launch, even if a previous session hid the widget.
- Remove the native transparent-panel shadow from the desktop widget so it no longer produces a jagged outer outline; retain the rounded SwiftUI shadow.

## 0.1.39 - 2026-06-26

- Default Show widget to on again for this release, including upgrades that previously persisted the old off state; choices made in this version remain persisted.
- Add the first public-source release materials, including a reproducible DMG packaging script, bilingual installation guidance, security policy, and issue forms.

## 0.1.38 - 2026-06-26

- Move Show widget, Keep widget on top, and Reset widget back into the top main-window action area so the lower settings copy is not clipped.
- When Keep widget on top is turned off, lower the widget instead of immediately ordering it front again.

## 0.1.37 - 2026-06-26

- Make Show widget default to on for the updated preference key.
- Keep the widget draggable when Keep widget on top is disabled by using normal window level instead of ignoring mouse events.
- Group Show widget, Keep widget on top, and Reset widget controls together in the main window and menu panel.
- Reopen the widget from Show widget at the same lower-right default position used by Reset widget.

## 0.1.36 - 2026-06-26

- Remove the main window's vertical scrolling surface so the settings view feels like a fixed macOS utility window.
- Increase small explanatory text in the main window and quota metadata to improve readability.
- Align the main window's initial size with the fixed settings layout.
- Keep widget dragging from opening the main window; only an explicit widget click opens the main window.

## 0.1.35 - 2026-06-26

- Change Show widget into a real persisted switch: turning it off closes the widget, and closing the widget syncs the switch off.
- When Keep widget on top is disabled, keep the widget at the desktop layer without intercepting desktop icon clicks.
- Clarify that dragging the widget requires Keep widget on top to be enabled.

## 0.1.34 - 2026-06-26

- Rename the widget action from Pin widget to Show widget so it matches the actual behavior.
- Make Show widget idempotent: repeated clicks bring the existing widget forward and keep it clamped instead of toggling or recreating it.
- Add a Keep widget on top setting: when enabled the widget floats above app windows, and when disabled it stays at the desktop layer.
- Keep Reset widget as the explicit recovery action that opens the widget and returns it to the lower-right visible area.

## 0.1.33 - 2026-06-26

- Keep the Codex account explanation visible after sign-in, with connected-state copy that explains Keychain storage and safe refresh behavior.
- Hide the Connect button after Codex is connected so users are not prompted to reauthorize repeatedly; the account card keeps Disconnect as the connected-state action.

## 0.1.32 - 2026-06-26

- Remember the floating widget position after dragging it, restore it inside the target screen, and add Reset widget actions in the main window and menu-bar popover.
- Mark stale quota snapshots as Stale instead of Available so old data is not mistaken for live quota.
- Show the connected account summary in the menu-bar popover header.

## 0.1.31 - 2026-06-26

- Fix floating widget placement at the bottom-right edge by using a fixed widget size and clamping against the same target screen before and after showing the window.

## 0.1.30 - 2026-06-26

- Restore concise product guidance in the main window while keeping quota status as the primary content.
- Remove duplicate connected-status labels from the account section.
- Recreate the floating widget when pinning it from the main window so a hidden or misplaced widget reopens on the first click.
- Add a Quit ReadyCheck action to the menu-bar popover.

## 0.1.29 - 2026-06-25

- Restructure the main window around quota status first, with account and preferences moved below the quota area.
- Fix floating widget close state so reopening it from the main window works on the first click.

## 0.1.28 - 2026-06-25

- Fix floating widget placement so new and reopened widgets choose the active screen before using the window frame and clamp the final frame inside the visible display area.

## 0.1.27 - 2026-06-25

- Treat the OAuth email as the connected Codex login account and stop showing internal account IDs as a fallback in the main window.

## 0.1.26 - 2026-06-25

- Show the connected Codex account identifier in the main OAuth card after sign-in, using the OAuth token email when available and falling back to account ID only when needed.

## 0.1.25 - 2026-06-25

- Keep the floating widget inside the visible area when opening it on launch or reopening it from the main window.
- Add a standard Close Window command so `Command-W` closes the main window instead of playing the system error sound.

## 0.1.24 - 2026-06-25

- Rewrite the main-window product brief with clearer user-facing copy.
- Make the menu-bar item icon-only and stop activating the main app when opening the menu popover.
- Use the same explicit green/orange/red quota progress bar rendering in the main window and desktop widget.

## 0.1.23 - 2026-06-25

- Add a concise product brief to the main window that explains ReadyCheck's safe quota-monitoring scope, credential storage, and available surfaces.

## 0.1.22 - 2026-06-25

- Change the quota refresh choices to 1, 3, and 5 minutes, with 1 minute as the default because refreshes do not call model inference endpoints.
- Rename the widget/menu status label from auto update to auto refresh.
- Improve Liquid Glass contrast for the floating widget and quota cards on lighter desktop backgrounds.

## 0.1.21 - 2026-06-25

- Add an About window with version, safe-refresh behavior, OAuth usage source, and precision policy.
- Add About entry points from the macOS app menu and the main ReadyCheck window.
- Reposition the floating widget on the primary screen when reopening it, with a higher window level so it is easier to recover.

## 0.1.20 - 2026-06-25

- Make the floating widget a borderless desktop panel with in-widget refresh and hide controls instead of a titlebar close button.
- Place the floating widget near the lower-right visible screen area with margin, keep the main window opaque, show long reset windows with date and time, and run automatic refresh while the main window is visible.

## 0.1.19 - 2026-06-25

- Move the main ReadyCheck window toward the approved Liquid Glass direction with custom glass cards instead of a plain settings form.
- Make the menu-bar item visible as `ReadyCheck` with an icon and show the floating desktop widget on launch.

## 0.1.18 - 2026-06-25

- Show Codex quota cards directly in the main ReadyCheck window after account connection.
- Refresh quota automatically when opening the main window with a connected Codex account, with a manual refresh button beside the quota status.

## 0.1.17 - 2026-06-25

- Add a local OAuth loopback callback listener on `localhost:1455` so Codex authorization can complete automatically after browser sign-in.
- Keep manual callback URL paste as a fallback when the local callback port is unavailable.

## 0.1.16 - 2026-06-24

- Restore the menu-bar ReadyCheck entry while keeping the foreground main window for settings and authorization.
- Route menu-panel Settings and Connect actions to the explicit main window instead of relying on a SwiftUI settings scene.

## 0.1.15 - 2026-06-24

- Create the main window directly from `static main()` after launch completion instead of relying on delegate callbacks.

## 0.1.14 - 2026-06-24

- Temporarily remove status-item setup during launch and prioritize showing the main window after double-click.

## 0.1.13 - 2026-06-24

- Defer main-window creation to the main run loop and force the window to the front.

## 0.1.12 - 2026-06-24

- Explicitly call `finishLaunching()` in the custom AppKit main so the launch delegate creates the main window.

## 0.1.11 - 2026-06-24

- Switched the launch layer to a traditional AppKit lifecycle that explicitly creates the main window and menu-bar status item.

## 0.1.10 - 2026-06-24

- Create the ReadyCheck main window explicitly through AppKit, fixing cases where SwiftUI `WindowGroup` did not reliably show a visible window.

## 0.1.9 - 2026-06-24

- Explicitly switch to a regular foreground app and activate the window on launch, fixing launches that appeared to do nothing.

## 0.1.8 - 2026-06-24

- Open a ReadyCheck main window on launch so the app no longer appears to do nothing as a menu-bar-only utility.
- Stop packaging the local app as background-only, so ReadyCheck appears in the Dock and app switcher.
- Default worktree packaging output to the visible repository `dist/ReadyCheck.app`.

## 0.1.7 - 2026-06-24

- Output the local acceptance build to `dist/ReadyCheck.app` so users do not need to launch from the hidden `.build` directory.
- Generate and declare a ReadyCheck icon for the local app bundle.

## 0.1.6 - 2026-06-24

- Improved the Codex v1 menu empty state so disconnected users see connection guidance instead of an automatic unauthorized error card.
- Improved Codex OAuth settings with a three-step authorization guide covering browser authorization, callback URL paste, and refresh behavior.
- Clarified quota cards by labeling percentages as remaining quota and showing reset time when available.

## 0.1.5 - 2026-06-24

- Focused the MVP on the Codex-only provider flow, enabling only Codex OAuth by default.
- Added a local `.app` packaging script and Codex v1 black-box acceptance documents.
