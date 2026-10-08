# 0.1.131 login startup fix plan

## Problem and goal

A running preview lost its on-disk Info.plist. macOS could no longer construct its login-item identifier, while ReadyCheck displayed only a generic error. Distinguish an incomplete installation from a system registration failure and verify that the installed app can enable and disable login startup.

## Scope

- Inspect the on-disk app identity, package type and executable, rather than potentially cached Bundle metadata. Accept complete bundles outside Applications too.
- Explain reinstall steps for incomplete installations; expose Login Items after a system failure. Log the error domain/code with a private description.
- Use the existing packaging workflow to launch a complete signed app under `.build/run`, separate from disposable release staging.
- Back up the previous local installation, replace it in Applications and verify actual macOS registration.
- Low-quota alerts and temporary hiding are outside this fix. Windows only shares the version number. No push or release is requested.

## Success criteria

Installation regression tests, full tests, version consistency and signature checks pass. The real UI can disable and enable login startup and retains the enabled state after reopening. See [acceptance](QA.md).
