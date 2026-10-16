# Install ReadyCheck

## Requirements

- Apple silicon (arm64), macOS 14 Sonoma or later
- An internet connection for Codex OAuth and usage refresh

## Install From A Release

1. Download `ReadyCheck-<version>-macos.dmg` from the GitHub Release.
2. Open the disk image and drag `ReadyCheck.app` into Applications.
3. Open ReadyCheck from Applications.

The preview release uses a stable self-signed ReadyCheck identity to preserve Keychain access across preview updates, but it is not Developer ID signed or notarized. If macOS blocks the first launch, open **System Settings > Privacy & Security**, then select **Open Anyway** for ReadyCheck. This is a distribution limitation of the preview build, not an OAuth requirement.

## Connect Your Account

Choose **Connect** in the app and finish the browser OAuth flow. The local callback normally returns through `localhost:1455`; when it does not, paste the final callback URL into the fallback field in ReadyCheck.

Use **Disconnect** to remove ReadyCheck's stored OAuth credentials from Keychain.

## Upgrading to 0.2.0

Quit ReadyCheck before replacing the app. Existing settings, credentials and history are retained. A rebuilt preview may require macOS Keychain confirmation; use Settings → Connection → Retry credential read if needed. Overview retains subscription/reset/Credits details. Find About in the sidebar footer or menu-bar More menu for release highlights. Windows is a separate portable preview and retains its previous interface.
