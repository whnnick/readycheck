<p align="center">English · <a href="README.zh-CN.md">简体中文</a></p>

<h1 align="center">ReadyCheck</h1>
<p align="center"><strong>Know your Codex quota. See when it resets.</strong></p>
<p align="center">A lightweight, free, open-source Codex monitor for quotas, Token usage, account benefits and reminders.</p>
<p align="center"><a href="https://github.com/whnnick/readycheck/tree/v0.7.1"><img src="https://img.shields.io/badge/source-0.7.1-3979ef" alt="Source 0.7.1"></a> <a href="docs/INSTALL.md"><img src="https://img.shields.io/badge/macOS-14%2B-172333" alt="macOS 14+"></a> <a href="LICENSE"><img src="https://img.shields.io/github/license/whnnick/readycheck" alt="MIT license"></a></p>
<p align="center"><a href="#quick-start">Quick start</a> · <a href="docs/versions/0.7.1/RELEASE_NOTES.md">Current changes</a> · <a href="docs/versions/0.7.1/QA.md">Checks &amp; limits</a> · <a href="docs/VERSIONS.md">Versions</a></p>

**ReadyCheck 0.7.1** restores Muse weekly allowance reads after a website update. [Release notes](docs/versions/0.7.1/RELEASE_NOTES.md) · [Verification](docs/versions/0.7.1/QA.md).

The macOS fix was verified with an existing Muse session at launch, after a manual refresh, and after relaunch. Codex and DeepSeek readings were also verified.

The 0.7.1 release includes `ReadyCheck-0.7.1-macos.dmg` and `ReadyCheck-0.7.1-windows-x64-portable.zip`. Validation is tracked in [QA](docs/versions/0.7.1/QA.md).

<img src="docs/versions/0.7.0/evidence/0.7.0-aggregate-overview-en-US.png" width="470" alt="Aggregate capsule and side detail with synthetic test values" />

## Choose your version

| Channel | Version | Get it |
| --- | --- | --- |
| Stable release channel | 0.7.1 | [Mac DMG](https://github.com/whnnick/readycheck/releases/download/v0.7.1/ReadyCheck-0.7.1-macos.dmg) · [Windows ZIP](https://github.com/whnnick/readycheck/releases/download/v0.7.1/ReadyCheck-0.7.1-windows-x64-portable.zip) |
| **Public source** | **0.7.1** | [Source tag](https://github.com/whnnick/readycheck/tree/v0.7.1) · [Changes and package checksums](docs/versions/0.7.1/QA.md) |
| **Previous preview** | **0.7.0-dev.23** | [Mac DMG](https://github.com/whnnick/readycheck/releases/download/v0.7.0-dev.23/ReadyCheck-0.7.0-dev.23-macos.dmg) · [Windows ZIP](https://github.com/whnnick/readycheck/releases/download/v0.7.0-dev.23/ReadyCheck-0.7.0-dev.23-windows-x64-portable.zip) |

The stable downloads contain 0.7.1. Package checks, Windows-runner results and remaining device limits are recorded in [QA](docs/versions/0.7.1/QA.md).

<p align="center"><img src="docs/versions/0.7.0/evidence/0.7.0-codex-overview-en.png" alt="ReadyCheck 0.7.0 native Codex overview with 5-hour and 7-day remaining quotas, reset events and local history; synthetic data" width="760"></p>
<p align="center"><sub>Current 0.7.0 Codex interface. All screenshots use synthetic data, not a real account.</sub></p>

## Built around everyday Codex use

| Your question | What ReadyCheck shows |
| --- | --- |
| How much can I still use? | The 5-hour, 7-day and other returned quota windows, remaining percentages and availability. |
| When does it recover? | Reset times and countdowns, upcoming events and usage pace based on current-cycle local samples, with an explicit explanation when samples are insufficient. |
| What have I used recently? | Locally observed quota decreases in Overview and returned daily Token counts in Usage, with history ranges and bar hover details. |
| What comes with my account? | Plan, subscription expiry, Credits, reset-card counts and expiry records. Account benefits open by default and can still be collapsed. |
| When should I pay attention? | Low-quota, observed-recovery and card-expiry reminders, plus notification history. Recovered credential warnings are withdrawn; the same reported card incident does not repeatedly alert. |
| Will it use a reset card? | Optional expiring-card attempts require separate account-specific consent, independent from read-only refresh and expiry reminders. [Card rules](docs/versions/0.3.0/RESET_CARD_AUTOMATION.md). |

Account fields depend on returned data; missing values are not invented. ReadyCheck does not automatically stop or resume Codex tasks.

## Keep Codex in view without keeping a window open

<table>
<tr><th>Codex floating capsule</th><th>Codex notch details</th></tr>
<tr><td align="center"><img src="docs/versions/0.7.0/evidence/dev28-codex-capsule-en.png" alt="Current expanded Codex capsule with quota, reset and last-hour trend; synthetic data" width="360"></td><td align="center"><img src="docs/versions/0.7.0/evidence/dev28-codex-notch-en.png" alt="Current Codex notch details; synthetic data" width="360"></td></tr>
</table>

- **Choose your surface.** Menu bar, floating capsule/edge strip, information card or click-to-expand notch, with saved positions and display controls.
- **Expand when needed.** Hover or ordinary-click a capsule to preview. The explicit pin button keeps it open; content clicks preserve that choice. Pinning is separate from window always-on-top.
- **Return to the details.** Refresh, inspect reminders or open ReadyCheck from the small view to review quota, history and account benefits.

## Also supported: DeepSeek API balances

The Mac client also supports a separate DeepSeek API Key connection: official balances by currency, granted/topped-up components, last successful reads and locally observed balance decreases. Balance capsule, edge and notch layouts are available. Balance-threshold reminders are explicitly enabled and scoped to connection and currency.

<p align="center"><img src="docs/versions/0.7.0/evidence/dev28-balance-notch-en.png" alt="Additional capability: native DeepSeek balance details and locally observed decreases; synthetic data" width="440"></p>

## Also supported: Meta Muse app weekly usage

Open **Settings → Connection → Muse**, sign in through the separate window, then choose **Read usage and finish**. It reads weekly remaining allowance, reset, plan and available provider labels for additional allowance/renewal, refreshing every five minutes. Overview, menu bar, capsule, edge, card and notch views are wired. This connection is for the muse.ai personal agent; daily Token history and dedicated Muse reminders are not included.

Codex and DeepSeek have live connection acceptance. Muse live sign-in, subscription read, manual refresh and usage-page checks passed on this Mac; other accounts remain untested. The catalog now has 11 entries, with the other eight still planned. See [implementation scope](docs/versions/0.7.0/TECHNICAL.md).

## Keep the units honest

- **Quota:** remaining percentages and locally observed decreases in percentage points. A drop from 80% to 70% is 10 points, not a Token count.
- **Tokens:** returned Codex counts grouped by UTC day; there is no fixed conversion from quota percentages.
- **Balance:** currency amounts. Local decreases are observations, not an official expense or Token bill; credits, refunds and grant expiry can affect balances. No percentage bar implies a balance limit.

Missing samples stay blank. Old/failed readings retain their status and original time instead of becoming a fresh zero. History is isolated by account or connection; unknown legacy ownership stays separate.

## Quick start

1. Download a **Mac preview DMG** above, open it and copy ReadyCheck.app to Applications.
2. In **Settings → Connection**, sign in to Codex and approve normal macOS Keychain prompts if needed. DeepSeek users can add an API Key connection separately.
3. Choose your surface under **Settings → Display**. Configure reminders separately under **Settings → Reminders**.

[Mac installation and upgrades](docs/INSTALL.md) · [Windows guide](docs/WINDOWS.md)

## Platforms and verification

| Platform | Current scope |
| --- | --- |
| **macOS / Apple silicon / 14+** | Codex, DeepSeek and Muse monitoring with the aggregate capsule. **543 Swift regressions and 11 reader JavaScript tests passed**, with additional native window and installed-device checks. [QA](docs/versions/0.7.0/QA.md). |
| **Windows x64** | Separate Electron Codex client and portable ZIP. Windows-runner service, UI smoke and native network-stack checks passed. Real-account reproduction on the original OAuth 403 machine remains unavailable. [Windows QA](docs/WINDOWS_QA.md). |

Other accounts, all display/Spaces/fullscreen combinations, OS login and every live reminder boundary are not comprehensively accepted. Current evidence and release gates are recorded in [black-box checks](docs/versions/0.7.0/QA.md).

## Privacy

Normal refresh reads authorized provider data without model-generation calls. Mac API/OAuth credentials stay in Keychain; Muse web sign-in stays in a separate WebKit session. Windows uses Electron safeStorage. DeepSeek credentials are independent from Codex, and local histories retain identity boundaries. Do not share keys, OAuth callback URLs or raw account payloads in issues or screenshots.

ReadyCheck does not automatically stop or resume Codex tasks. Optional card redemption requires separate consent. ReadyCheck is independent of OpenAI, DeepSeek and Meta; their names and marks belong to their owners.

## Build and contribute

macOS source requires a Swift 6-compatible toolchain and macOS 14+:

```bash
swift test
scripts/build_and_run.sh
```

For distributable artifacts use the [release process](docs/RELEASE.md); Windows builds use Node.js 22.12–24 and the existing packaging script. See [contributing](CONTRIBUTING.md) and [security](SECURITY.md).

[Current plan](docs/versions/0.7.0/PLAN.md) · [Technical scope](docs/versions/0.7.0/TECHNICAL.md) · [Changelog](CHANGELOG.md) · [Version archive](docs/VERSIONS.md) · [Issues](https://github.com/whnnick/readycheck/issues) · [MIT license](LICENSE)
