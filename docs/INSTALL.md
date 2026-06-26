# Install ReadyCheck

## Requirements

- macOS 14 Sonoma or later
- An internet connection for Codex OAuth and usage refresh

## Install From A Release

1. Download `ReadyCheck-<version>-macos.dmg` from the GitHub Release.
2. Open the disk image and drag `ReadyCheck.app` into Applications.
3. Open ReadyCheck from Applications.

The preview release is ad-hoc signed and not notarized. If macOS blocks the first launch, open **System Settings > Privacy & Security**, then select **Open Anyway** for ReadyCheck. This is a distribution limitation of the preview build, not an OAuth requirement.

## Connect Your Account

Choose **Connect** in the app and finish the browser OAuth flow. The local callback normally returns through `localhost:1455`; when it does not, paste the final callback URL into the fallback field in ReadyCheck.

Use **Disconnect** to remove ReadyCheck's stored OAuth credentials from Keychain.
