# 0.1.99 plan: less obstructive always-on quota

[中文](PLAN.zh-CN.md) | [Acceptance](QA.md) | [Version index](../../VERSIONS.md)

Keep the existing notch and desktop card. Add a compact bubble as the default desktop-widget presentation because the notch can cover top-of-screen controls. Show only one always-on surface at a time. Read the Codex or ChatGPT icon from an installed app at runtime rather than distributing a copied logo; keep ReadyCheck as the app identity.

The resting bubble shows a verified remaining percentage, opens a two-window quota card on click, and can be dragged. Near either screen edge it folds into a narrow tab. Click outside or press Escape to collapse. Save the resting position and clamp it to an available display after monitor changes. Keep the existing menu-bar path to restore a hidden widget.

Acceptance: bubble/card selection survives restart; the notch still works; dragging and both edge orientations are usable; expanded content remains on screen; stale or unavailable data never shows a guessed percentage; the icon falls back safely when Codex and ChatGPT are absent. Verify in a running macOS app as well as Swift tests before publication.
