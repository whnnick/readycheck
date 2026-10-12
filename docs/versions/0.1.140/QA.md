# 0.1.140 acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Versions](../../VERSIONS.md)

Status: local 0.1.140 installed and inspected on October 12, 2026. Account restoration completed; both-platform public release preparation resumed after actual quota recovery.

![Kept-open pin, anonymous component](assets/pin-kept-open-demo.png)

[Hover-preview state](assets/pin-preview-demo.png). These are actual SwiftUI components with synthetic observations, not live account readings.

| Requirement | Result / evidence |
| --- | --- |
| Tooltip purpose | Installed accessibility Help on the pin reads the Chinese pointer-exit explanation and explicitly says this is not window always-on-top. Generic container help removed; dial and individual buttons own their help. Both English strings and native layout captures checked. Tool readout verifies configured tooltip text, not the exact OS tooltip delay. |
| Visible feedback | Installed button remains visible after click. First click changes label/value to cancel / kept open and uses the blue filled pin; second changes back to keep open / hover preview with an outlined pin. Title remains single-line. |
| Toggle / focus | New tests verify preview→pinned→preview, pointer-exit dismissal after unpin, outside unpin, and guards during dragging/collapse. Native controller test verifies the keyboard eligibility changes both ways. Existing Esc/outside/Space timers retained. |
| Installation / data | Final signed app installed; strict signature verification outside the sandbox passes and executable digest matches the local package. After system Keychain verification, a manual refresh returned fresh verified OAuth quotas; real-data pin Help and state switching were rechecked. Credentials were preserved. Windows metadata only. |

Completed: persistent button, state feedback, two tooltip explanations, toggle/focus logic, local installation and account restoration. Partial: system tooltip timing/subjective pointer feel. No new notification/account features. No new physical notch/multiple-display acceptance.

Verification: all 270 Swift tests passed with no skips/failures. After enabling `allowsToolTipsWhenApplicationIsInactive`, all 13 relevant interaction/native tests passed, including the panel property's regression assertion. Final installed button Help and state changes were rechecked. Version consistency, modified-document links, `git diff --check` and added-text sensitive-data checks passed. Commands: `swift test --build-system native --scratch-path <temporary-directory>`, `scripts/check_release_consistency.sh`, `scripts/package_app.sh`, `codesign --verify --deep --strict`.

Release scope: fresh 0.1.140 DMG and Windows ZIP, sanitized public source, tag and GitHub Release; verify remote latest, download URLs and asset digests. Stable preview signing is not Developer ID notarization. Windows native execution remains a physical acceptance limit; automated Windows checks run during packaging.

Package checks: both fresh 0.1.140 artifacts built successfully. Read-only mounted DMG contains app version 0.1.140 and passes deep strict signature verification with the existing signing identity. Windows ZIP integrity and ASAR version passed; the 20-entry application archive excludes development/internal files. Packaging ran the Windows OAuth, refresh, history, reminder, usage and UI checks successfully. Output contains only the current DMG and Windows ZIP.

Public-snapshot verification: 270 Swift tests executed with no failures; one native pinned-window sizing test was skipped because the background session could not retain keyboard focus (the isolated retry had the same limit). The earlier development run and installed-app acceptance above covered this behavior. Both final public-snapshot packages passed the mounted-DMG/ZIP checks described above.
