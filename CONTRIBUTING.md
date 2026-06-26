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

## Pull Requests

Include a short summary, verification evidence, and screenshots for visible UI changes. Add or update focused tests when behavior changes.

For security-sensitive findings, follow [SECURITY.md](SECURITY.md) instead of opening a public issue.
