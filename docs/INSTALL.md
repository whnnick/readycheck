# Install and upgrade ReadyCheck

[简体中文](INSTALL.zh-CN.md) · [Version channels](../README.md#choose-your-version)

## Choose a package

- macOS requires Apple silicon (arm64) and macOS 14+.
- The latest downloadable public preview is **0.7.0-dev.23**; the stable release channel is **0.6.1**.
- **0.7.0-dev.28** is the latest verified source/packaged candidate. Its source tag is public, but it has no public GitHub Release installer assets. Use the [README download table](../README.md#choose-your-version) for working download links.
- Windows is a separate x64 portable client: [Windows guide](WINDOWS.md).

## Install on Mac

1. Download the Mac DMG for your chosen published release.
2. Open it and copy ReadyCheck.app to Applications.
3. Open ReadyCheck from Applications.

Mac preview packages use the established self-signed ReadyCheck identity, not Developer ID signing or notarization. If macOS blocks the first launch, its normal approval is under **System Settings → Privacy & Security → Open Anyway**. Updates may also require normal Keychain confirmation.

## Connect a service

| Service | In Settings → Connection | Reading scope |
| --- | --- | --- |
| Codex | Select Codex, choose Sign in to ReadyCheck and complete browser OAuth. | Returned quota windows and matching-account capabilities. |
| DeepSeek | Select DeepSeek and enter your API Key directly in the native app. | Official API balance, currency and granted/topped-up components; not website/app chat usage. |

The normal Codex callback uses `localhost:1455`; if automatic completion fails, use the app's final-callback-URL fallback. Treat the complete callback URL as a credential and do not post it publicly.

Use **Retry credential access** when existing Keychain access needs confirmation. Complete the macOS prompt rather than replacing the saved Key. Each service's disconnect control removes its own stored credential; account/connection history remains separate. Never send a password or Key through an issue or chat.

## Upgrade

1. Quit ReadyCheck normally before replacing its application bundle.
2. Copy the new package to the same Applications location and reopen it.
3. Approve normal Keychain prompts if requested, then verify a fresh read for each connected service.

Existing settings, saved Widget positions, histories and account-specific card consent are retained by the current upgrade path. Dev.28 same-bundle quit/relaunch and exact comparison of 13 display/selection/frame preferences passed. That does not replace OS login/reboot or all migration/device acceptance; see [current checks](versions/0.7.0/QA.md).

## Find the controls

- **Overview:** readings, local history and account benefits; current source opens benefits by default.
- **Settings → Reminders:** independent quota, recovery, expiry and DeepSeek balance rules. Optional automatic card use requires separate account consent.
- **Settings → Display:** capsule/edge strip, information card, notch, always-on-top and visibility controls. Ordinary capsule clicks preview; only the pin button keeps details open.
- **Settings → General:** language, refresh cadence, launch at login and update checks.
- **Notification history:** delivery/withdrawal records. Card outcomes remain in Card use and checks.

For a source build use the [README instructions](../README.md#build-and-contribute). Distribution validation follows the [release process](RELEASE.md).
