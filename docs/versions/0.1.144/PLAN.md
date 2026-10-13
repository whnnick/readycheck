# 0.1.144: Reliable detail pin

[中文](PLAN.zh-CN.md) · [Acceptance](QA.md) · [Version index](../../VERSIONS.md)

Problem: round-bubble details can close after an outside click or focus loss even when their keep-open pin is active. The detail minus button duplicates manual dismissal and makes the controls less clear.

| Requirement | Success criterion |
| --- | --- |
| Keep pinned details open | After pinning, clicking the desktop, another app or another ReadyCheck window, or losing detail-window focus, leaves the round-bubble details expanded. |
| Restore hover preview | Clicking the pin again returns to hover preview; leaving the bubble closes the preview and hovering can open it again through the existing behavior. |
| Manual dismissal | Esc still closes the focused details explicitly. Removing the minus button leaves the pin as the detail persistence control. |
| Clear help | Bubble-only help explains the current pinned or hover-preview state. EdgeRail-style help and interaction semantics remain unchanged. |
| Preserve scope | Keep circle/ring geometry, compact and expanded sizes, direct inward dragging and quota handling unchanged. Windows receives version metadata only. |

Scope: macOS round-bubble detail pin behavior, its controls and Bubble-specific help. Use the existing test and packaging workflow for local verification and installation. Local regression checks, packaging and installation are recorded in the acceptance document; additional manual scenarios remain listed there. The public [0.1.144 release](https://github.com/whnnick/readycheck/releases/tag/v0.1.144), latest status, CI and downloaded package hashes are verified in the acceptance document. Campaign media remains a separate deliverable.
