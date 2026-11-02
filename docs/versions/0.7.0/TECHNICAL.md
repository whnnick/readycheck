# 0.7.0 — Ten-service implementation scope

[中文](TECHNICAL.zh-CN.md) · [Plan](PLAN.md) · [Sources](SOURCES.md) · [Checks](QA.md)

Current status (2026-11-03, dev.28): the macOS Codex + DeepSeek native slice is implemented and its core local acceptance is closed; see [the consolidated acceptance](QA.md) and [65-entry retention matrix](RELEASE_AUDIT.md) for remaining device/release boundaries. Other eight services remain catalog/planning entries; Windows balance integration is not implied. The dated design and historical progress below are retained for traceability.

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
