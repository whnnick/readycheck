# 0.7.0 — Ten-service implementation scope

## Aggregate capsule (dev.32)

[Design contract](AGGREGATE_CAPSULE.md) · [Black-box status](QA.md). A separate aggregate presentation reuses existing read-only connection models; it adds no provider polling. The rail has its own `aggregateCapsuleFrame.v1` preference, seeded from the prior bubble center without overwriting legacy positions. A second nonactivating panel opens into available screen space. Explicit pin enables keyboard focus; the existing interaction controller handles previews, dismissal and Spaces changes. Shared detail chrome accepts an explicit service, so preview/refresh never need to change main-window selection. No-screen cases defer presentation instead of persisting a zero-sized frame.

[中文](TECHNICAL.zh-CN.md) · [Plan](PLAN.md) · [Sources](SOURCES.md) · [Checks](QA.md)

The installed dev.32 passed live reads and manual refresh for Codex, DeepSeek and Muse on 2026-11-09. Muse uses the isolated ReadyCheck WebKit profile accepted in dev.31. The expanded catalog has 11 entries, with eight still planned. Windows remains its separate Codex client. See [acceptance](QA.md) and [retention](RELEASE_AUDIT.md). The dated design below is historical.

2026-10-30. The agreed target is ten services, in two batches of five. This is a build sequence and evidence matrix, not a claim that the prototype connects them. The first native implementation slice is **Codex retained + DeepSeek official balance**. Within batch one, complete one reliable read-only flow before adding the remaining adapters.

## Target and source matrix

| Batch | Service | First useful metric | Reading candidate | Remaining acceptance |
| --- | --- | --- | --- | --- |
| 1 | Codex | Existing quotas, Token, benefits, cards | Existing ReadyCheck OAuth provider | Retain every existing capability and authorization; no local-Codex login restoration |
| 1 | Claude | Subscription quota, or separately scoped API reporting | CodexBar documents OAuth, web, CLI and Admin paths | Eligibility, authorized credential path, identity and supported fields; a working chat login is not enough |
| 1 | Gemini | Per-source quota and reset | CodexBar separates CLI OAuth and Gemini-app sessions | Current account/tier eligibility, permitted source, identity and quota scope; do not substitute API-platform data |
| 1 | DeepSeek | Balance, currency, granted/paid breakdown | Official GET `/user/balance` | Real read and notification verified in isolated test apps; installed-app acceptance remains separate; no inference request |
| 1 | Cursor | Plan usage and billing period | CodexBar documents app/browser session paths | Source authorization, account binding, encrypted-session access and endpoint stability |
| 2 | GitHub Copilot | Premium request allowance and plan | Device authorization + CodexBar's internal usage path | Supported OAuth client, account scope, permission and internal-API compatibility |
| 2 | Alibaba/Bailian Coding Plan | Reported 5h/week/month windows | Official `bl usage coding-plan --output json` is a candidate; other paths conditional | CLI permissions, schema, region/plan and actual counters remain unverified; ordinary Key alone is not a universal reporting credential |
| 2 | GLM Coding Plan | Reported quota windows | Region-scoped Key | BigModel CN versus z.ai identity/host boundaries; do not cross-use credentials |
| 2 | Kimi Code | Coding subscription windows | Kimi Code Key | Region, subscription and reported windows; not Moonshot API wallet balance |
| 2 | MiniMax Coding Plan | Coding plan quota | Coding Plan Key | Correct Key type and region; ordinary API and optional web history are separate |

Names refer to specific service surfaces rather than every model sold by that company. OpenAI API, gateways and the other entries from the initial 110-service reference snapshot are outside this first-release target. No already-supported native feature was removed.

## Existing code and the minimal next slice

Repository inspection confirmed `QuotaProvider.fetchSnapshot`, `ProviderRegistry`, per-provider `CredentialKey`, and the existing credential store. Current snapshots are centered on quota windows; do not fabricate a percentage or put DeepSeek money into Codex Credits.

For DeepSeek only, the next implementation needs:

1. Decode the official balance response using explicit currency and decimal amounts: total, granted, topped-up, and the separately reported API-availability flag. Missing or malformed fields stay unavailable. Do not combine CNY and USD.
2. Send a read-only GET to the fixed official HTTPS host. Bind cancellation and timeouts, distinguish rejected credentials, rate limits, offline/transport and decode failures. Do not test a Key by calling a model or silently switch to website sessions.
3. Add only the balance representation needed alongside existing snapshots. Keep Codex quota/card behavior and serialized defaults backward compatible; unknown fields/absent balance must not invalidate old history.
4. Store the new credential under its own provider and connection identity. Never reuse the Codex OAuth item, expose the Key to the browser prototype, or print response bodies containing identity/billing information.
5. Capture balances by connection with original observation time; a change is balance movement, not inferred spend. A cache retains its timestamp and is visibly stale. Notification thresholds need a separate per-currency rule and per-connection deduplication before release.
6. Integrate the native connection form, dashboard and selected lightweight surface; independently check account removal/reconnect and legacy feature retention. Native user-visible work gets its own development version and bilingual log.

## Development and release gate

Start with deterministic transport/decoder fixtures, including zero balance, multiple currencies, unknown fields, malformed/negative amounts and failure categories. Then validate a real connection using a Key entered in the native application's secure flow, never sent through chat. No new service credentials were read or requested during this prototype work.

A completed slice means source-permitted authentication → real read-only fetch → correct units/identity → history and stale/failure display → applicable reminder acceptance. It does not mean a green mock screen or a successful build. Broader automatic session import, browser-cookie scanning, cloud services and inference APIs are not prerequisites and are not authorized by this design milestone.

Windows requires its own implementation/acceptance. This milestone creates no package, tag, deployment or public push. The current installed app and its account/card state remain untouched.

## dev.1 implementation progress (historical)

The local development build now includes the independent read-only DeepSeek balance client, Keychain connection, native overview switcher and stale/error states. Synthetic response and credential isolation tests cover this slice. Real-account verification, persistent balance history, alerts and compact surfaces remain pending.

## dev.2 balance history

Local balance snapshots retain up to 30 days and are scoped by random connection ID and currency, with a minimum five-minute interval per currency. History contains no key. Legacy keys migrate to an identified Keychain record only after a successful read; reconnecting the same key retains its ID, while replacing the key creates a new ID without inferring account ownership. Corrupt history is not overwritten. Alerts, real-account testing and full native-window acceptance remain incomplete.

## Muse app read-only slice (dev.30)

The connection is for muse.ai (`com.meta.endo` desktop app), not Muse Code. It uses a dedicated persistent WebKit profile, opened only on explicit sign-in; neither other browsers' cookies nor Muse.app credentials are imported. Disconnect clears only this profile and rejects late in-flight results.

Dev.31 executes the reader with the result-returning WebKit async overload. Discovery reads fresh same-origin HTML in the independent session instead of retaining the signed-out DOM; that HTML stays inside WebKit. The login window can reload. The in-page reader discovers the website's `fetchSubscriptionAction` reference, then requests that read action with `includeAgreement: true` in the same-origin browser context. Static chunk reads omit credentials; navigation is limited to HTTPS Muse/Meta login hosts and explicit Apple/Google authentication hosts. Discovery caps page/settings chunks at 96/32, batches at eight, aggregate source at 8 million characters, body at 512 KiB and fetch time at 25 seconds, with one stale-action rediscovery. Only allowlisted subscription fields leave WebKit; no cookies, conversation data, payment metadata or raw responses are logged or saved.

Percentages are used directly; provider token labels remain text. Additional allowance stays separate from the weekly percentage; absent labels are not inferred from micro-dollar balances. Unknown, expired, invalid and failed reads remain unavailable rather than fresh zero. There is no Muse history, daily Token inference, card action or dedicated reminder in this slice. [Sources](SOURCES.md) and bundled [MIT notice](../../../Sources/ReadyCheckApp/Resources/CodexBar-MIT.txt).
