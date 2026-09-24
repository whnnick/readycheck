# 0.1.99 acceptance

[中文](QA.zh-CN.md) | [Plan](PLAN.md) | [Version index](../../VERSIONS.md)

Local preview installed and accepted on this Mac. Public release and broader hardware acceptance are pending.

| Requirement | Status | Evidence |
| --- | --- | --- |
| Bubble, expansion, card selection | Complete on macOS 27 | Installed 0.1.99 app showed the Codex icon, quota ring, two-window card, Escape collapse, and card switch |
| Edge tab, drag, display clamp | Partial | Right-edge drag, tab, and click-to-expand passed in the running app; reset returned to the circular bubble and persisted across relaunch. Left-edge and disconnected-display behavior have placement unit tests but still need live hardware interaction |
| Validated percentages, installed icon fallback | Partial | Live app showed matching percentages and the installed Codex icon; missing-app fallback is code-reviewed, not observed on this Mac |
| Existing notch and card | Complete on macOS 27 | Original card rendered after switching; a saved notch setting was retained at startup and toggling the desktop widget disabled the notch |
| Swift regression | Complete | 195 Core and 2 App tests passed, including localhost OAuth; Windows `npm run check` passed |
| Public release | Pending | No GitHub push or Release requested |

The installed app reports version 0.1.99 and its executable SHA-256 matches the tested package. It uses `ReadyCheck Preview Signing`; the self-signed certificate does not establish Developer ID trust or notarization. The 0.1.98 real persistent-notification cycle and macOS 14 hardware limits remain as documented in [0.1.98 QA](../0.1.98/QA.md).
