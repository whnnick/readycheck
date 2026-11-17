# ReadyCheck 0.7.2-dev.11 preview

[简体中文](RELEASE_NOTES.zh-CN.md) · [Verification](QA.md)

- Connected services refresh every minute while ReadyCheck is running. The interval setting is replaced by a short explanation. Manual refresh remains available. Refresh reads usage or balance without a model request.
- On macOS, **Settings → Display → Quick display** controls which connected services appear in the capsule and its menus. The right-side capsule is narrow and fits the number of visible services. An empty capsule keeps a shortcut to settings.
- The macOS menu bar shows a single ReadyCheck icon. Click it to see selected services. The side detail fades between services as you move across their icons.
- Windows remains a Codex preview and also uses fixed one-minute refresh.

The macOS package uses the ReadyCheck preview signature. Live-account cadence and the original Windows OAuth 403 device remain pending. The stable release is 0.7.1. [Verification](QA.md)
