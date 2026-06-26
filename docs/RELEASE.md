# Release Process

1. Run `swift test`.
2. Run `scripts/package_app.sh`.
3. Run `scripts/package_dmg.sh`.
4. Validate the app bundle with `plutil -lint`, `codesign -dv`, and the DMG with `hdiutil imageinfo`.
5. Create an annotated tag matching the app version and publish a GitHub Release with the DMG asset.

The current release script applies an ad-hoc signature. A production Gatekeeper-ready release additionally requires Developer ID signing, hardened runtime configuration, notarization, and stapling.
