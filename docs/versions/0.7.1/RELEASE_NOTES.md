# ReadyCheck 0.7.1

[简体中文](RELEASE_NOTES.zh-CN.md) · [Verification](QA.md)

- Restores Muse weekly allowance and reset time on macOS after a Muse website update. ReadyCheck can reuse an active Muse session and retries one temporary startup failure.
- Windows remains a Codex client. Its package version is updated for this release.

macOS uses the ReadyCheck self-signed certificate. The app is not notarized. macOS may ask again for access to existing Codex and DeepSeek Keychain entries.
