# ReadyCheck 0.7.2

[简体中文](RELEASE_NOTES.zh-CN.md) · [Verification](QA.md)

- Settings, overview, usage, service catalog, the menu and the aggregate capsule use the same order: **Codex → Muse → DeepSeek**. Keyboard navigation and filtered lists keep that order.
- Connected services refresh every minute while ReadyCheck is running. The interval setting is replaced by a short explanation. Manual refresh remains available. Refresh reads usage or balance without a model request.
- On macOS, **Settings → Display → Quick display** controls which connected services appear in the capsule and its menus. The right-side capsule is narrow and fits the number of visible services. An empty capsule keeps a shortcut to settings.
- The macOS menu bar shows a single ReadyCheck icon. Click it to see selected services. The side detail fades between services as you move across their icons.
- Windows continues to support Codex and also uses fixed one-minute refresh.

- The floating card has a larger title drag area. With no service to display, clicking the notch opens Display settings.

The Mac DMG uses the existing ReadyCheck self-signed identity. Windows x64 portable supports Codex. Retesting on the Windows computer that reported OAuth 403 is pending. [Verification](QA.md)
