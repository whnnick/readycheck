# 0.1.111 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.110 acceptance](../0.1.110/QA.md)

Local macOS preview; public release has not been requested.

| Requirement | Status | Evidence |
| --- | --- | --- |
| No pointed translucent area outside the expanded card | Failed in later real-world review; superseded by 0.1.112 | The light-background check missed the Liquid Glass effect's square backing. User screenshots showed it around the round bubble, edge capsule, and expanded card. See [0.1.112 acceptance](../0.1.112/QA.md). |
| “Open ReadyCheck” link uses the blue accent | Complete | The signed installed app showed the link in blue. |
| Existing quota display and interaction | Complete for tested paths | The installed 0.1.111 app reconnected to the local Codex account, displayed both quota windows, and expanded from and collapsed to the edge capsule. The release consistency check passed. All 197 core and 4 app Swift tests passed under normal local permissions; the sandboxed run had one local OAuth loopback-port failure. The installed executable hash matched the signed preview app, and both passed strict code-sign verification. |
| Public release | Not requested | This version remains local until a release is requested. |
