# Contributing To ReadyCheck

Thanks for improving ReadyCheck.

## Before You Start

- Keep changes focused and describe user-visible behavior clearly.
- Do not commit OAuth tokens, callback URLs, account identifiers, raw usage payloads, local paths, or generated app bundles.
- Preserve the fail-closed quota policy: unknown or unparseable usage data must not be shown as a percentage.

## Development

```bash
swift test
scripts/package_app.sh
scripts/package_dmg.sh
```

The app targets macOS 14 or later. Keep user-facing documentation in English and Simplified Chinese.

For new providers, use the one-minute automatic refresh policy for read-only usage or balance reads. On macOS, use `RefreshPolicy.default` and keep manual refresh available.

新接入的服务沿用每分钟自动刷新策略，仅查询用量或余额。macOS 使用 `RefreshPolicy.default`，并保留手动刷新。

Use the shared service order in `ServiceSettingsTarget.allCases` for service lists and keyboard navigation. Check affected settings, overview, usage, catalog, popover, and widget surfaces together when changing provider behavior.

所有服务列表和键盘导航使用 `ServiceSettingsTarget.allCases` 的统一顺序。修改服务相关行为时，同时核对受影响的设置、总览、用量、服务目录、菜单和小组件。

## Pull Requests

Include a short summary, verification evidence, and screenshots for visible UI changes. Add or update focused tests when behavior changes.

For security-sensitive findings, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.
