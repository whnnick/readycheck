# ReadyCheck 0.7.0-preview.5 — Usage aggregation prototype

2026-10-31 correction prototype: restore Settings → Reminders / Display / Connection / General. Select a platform inside Connection or Reminders; overview shortcuts and notice details share the same values. Codex and DeepSeek remain visible while disconnected. Connect DeepSeek directly from Overview, and use the fixed named return button to restore the originating page, platform, range and scroll. Connection forms and rules use synthetic data; no real credentials, native application or system settings are changed. General content alone demonstrates language switching. See the [interaction correction plan](../INTERACTION_REPLAN.md).

[中文](README.zh-CN.md) · [Plan](../PLAN.md) · [Black-box checks](../QA.md) · [Visual review](design-qa.md)

An isolated, local interactive prototype based on the selected light desktop design. Compact service tabs are a low-frequency control; quotas and trends receive visual priority. No installed application or native capability is replaced.

## Try the main flow

- Switch Codex / DeepSeek; the last service is remembered in prototype-only browser storage.
- Compare subscription quota percentages, locally observed percentage-point drops, official Token examples and balance. These are different units and are never combined.
- Change chart ranges; hover or use the chart keyboard controls for exact values.
- Open account benefits and reset-card records, notification filters, reset explanation and source details.
- Open More platforms: search ten agreed targets and filter two batches of five. Supported services go directly to connection settings; planned services retain source descriptions. Returning restores catalog search and scroll. Both supported services stay in the compact strip regardless of connection state.
- Settings retains four familiar sections, platform-specific rules, display controls and system/light/dark appearance. The installed app's actual reminder rules, Keychain, account history and automatic-card authorization are untouched.

## Catalog and asset sources

The directory follows [CodexBar's provider list](https://github.com/steipete/CodexBar/blob/main/README.md#providers), checked 2026-10-30. The user narrowed that research to ten target services; the original 110-entry prototype is superseded. The ten targets are not ten implemented integrations. See the [two-batch implementation matrix](../TECHNICAL.md). Summary methods/metrics are discovery hints; implementation needs provider-specific official-source review, account eligibility and live read-only acceptance. Codex retains its existing OAuth-only primary connection. DeepSeek is balance-only in this concept; Claude and Gemini are explicitly unverified. See [source notes](../SOURCES.md).

The ReadyCheck icon is an existing repository asset; DeepSeek, Claude and Gemini marks come from Simple Icons. The selected concept uses the ReadyCheck mark beside Codex as a prototype identifier; it is not an official Codex logo. Standard interface icons use Phosphor. Charts are rendered with Recharts, not images. `evidence/selected-light.png` is the accepted generated design, with synthetic data only. Screenshots and contact sheets contain no real accounts or readings.

## Local development

```sh
npm install --prefer-offline --no-audit --no-fund
npm run dev -- --host 127.0.0.1 --port 4335 --strictPort
npm run build
npm run test:catalog
npm run test:sites
```

Build, four catalog-scope tests and four hosting-runtime checks pass. The build emits one chunk above Vite's recommended size; this is prototype polish, not a native app size change. No deployment is performed. Native/provider/backend/Windows implementation and live integration acceptance remain pending.
