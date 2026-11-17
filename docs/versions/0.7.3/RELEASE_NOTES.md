# ReadyCheck 0.7.3

[简体中文](RELEASE_NOTES.zh-CN.md) · [Verification](QA.md)

- Fix a macOS startup crash seen after restarting or clearing the build directory. The installed app now locates the service icons and Muse quota reader inside its own bundle.
- If a resource is missing, the affected view or reader handles the error without terminating ReadyCheck.
- Existing credentials and preferences use the same storage. Windows remains a Codex-only portable app.

The macOS DMG uses the existing ReadyCheck self-signed identity and has no Apple notarization. [Verification](QA.md)
