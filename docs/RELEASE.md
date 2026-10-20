# Release Process

Use this flow for every user-visible ReadyCheck release. Do not publish from an ad-hoc sequence.

## 1. Prepare The Version

1. Update `ReadyCheckCore.version`.
2. Update `scripts/package_app.sh` and `scripts/package_dmg.sh`.
3. Update `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, and `CHANGELOG.zh-CN.md`.
4. Keep the release changelog entry under the exact version heading, not under `Unreleased`.

## Feature Retention Gate (0.3.0 and later)

Before packaging or publishing, reconcile the prior native version with the proposed release using the[feature-retention baseline](versions/0.3.0/FEATURE_RETENTION.md). The initial macOS register contains65 protected capabilities; extend it when a capability is discovered. For each relevant item, record its discoverable entry, retained behavior, test/device evidence and preference/history migration result. Specifically applicable unchanged-path evidence may be reused; source presence, aggregate test counts and prototype completion alone are insufficient.

Missing controls, degraded behavior, data loss or unresolved relevant acceptance block release. Treat a prototype's omitted/simplified pages as unfinished work. Any removal or substantive change requires explicit user approval with the feature ID, before/after behavior, impact and rollback recorded before implementation. Do not make the user recall the old feature list. Windows needs its own acceptance; Mac results do not cover it.

## 2. Verify The Development Worktree

Run from the active ReadyCheck development worktree:

```bash
scripts/check_release_consistency.sh
swift test
git diff --check
rg -n "0\\.1\\.<previous>|ReadyCheck-0\\.1\\.<previous>" README.md README.zh-CN.md Sources Tests scripts docs -S
```

Then package locally:

```bash
scripts/package_dmg.sh
scripts/package_windows_portable.sh
```

Windows packaging requires Node.js 22.12–24 and is validated with Node.js 24. If a newer system Node is installed, set `READYCHECK_NODE_BIN` to a compatible Node executable; the script fails before packaging rather than accepting an empty Electron Packager result.

`scripts/package_dmg.sh` is the only standard local packaging entry point. It cleans old `ReadyCheck-*-macos.dmg` files from `dist` before writing the current DMG.

Release builds must use a stable signing identity. `scripts/package_app.sh` prefers `ReadyCheck Preview Signing` when it exists, or the identity supplied through `READYCHECK_SIGNING_IDENTITY`. Standalone contributor app builds may fall back to ad-hoc signing, while `scripts/package_dmg.sh` fails instead of producing a release DMG without a stable identity.

Validate the local artifact:

```bash
find ../../dist -maxdepth 1 -type f -o -type d
hdiutil imageinfo ../../dist/ReadyCheck-<version>-macos.dmg
shasum -a 256 ../../dist/ReadyCheck-<version>-macos.dmg
```

Mount the DMG and validate the app inside it, rather than a copied intermediate app:

```bash
plutil -p /Volumes/ReadyCheck/ReadyCheck.app/Contents/Info.plist | rg "CFBundleShortVersionString|CFBundleVersion"
codesign --verify --deep --strict /Volumes/ReadyCheck/ReadyCheck.app
codesign -dv --verbose=2 /Volumes/ReadyCheck/ReadyCheck.app
codesign -dr - /Volumes/ReadyCheck/ReadyCheck.app
```

The root `dist` directory must contain only:

- `ReadyCheck-<version>-macos.dmg`
- `windows/ReadyCheck-<version>-windows-x64-portable.zip`

`package_dmg.sh` removes the intermediate app after sealing it inside the DMG.

Commit the development worktree after these checks pass.

## 3. Publish The Public Repository

Use the public sync directory, not the development worktree, for the public `main` release. Preview the sync first:

```bash
scripts/sync_public_repo.sh --dry-run
```

Apply the sync after reviewing the dry-run output:

```bash
scripts/sync_public_repo.sh --apply
```

The script clears stale sync contents, excludes internal agent and build files, scans for sensitive data, and runs `git diff --check`. It never commits, tags, pushes, or creates a release.

Local campaign projects under `marketing/hyperframes/videos` are excluded together with their captures, audio and vendor bundles. Publish selected promotional assets separately after reviewing them; application releases do not upload these local campaign directories.

In the public sync directory:

```bash
swift test
git diff --check
scripts/package_dmg.sh
scripts/package_windows_portable.sh
find dist -maxdepth 1 -type f -o -type d
hdiutil imageinfo dist/ReadyCheck-<version>-macos.dmg
shasum -a 256 dist/ReadyCheck-<version>-macos.dmg
unzip -t dist/windows/ReadyCheck-<version>-windows-x64-portable.zip
```

The public sync `dist` directory must contain only:

- `ReadyCheck-<version>-macos.dmg`
- `windows/ReadyCheck-<version>-windows-x64-portable.zip`

Then commit, tag, push, and create the GitHub Release:

```bash
git add -A
git commit -m "Release ReadyCheck <version> / 发布 ReadyCheck <version>"
git tag -a v<version> -m "ReadyCheck <version>"
git push origin HEAD:main
git push origin v<version>
gh release create v<version> dist/ReadyCheck-<version>-macos.dmg dist/windows/ReadyCheck-<version>-windows-x64-portable.zip --repo whnnick/readycheck --title "ReadyCheck <version>" --verify-tag --latest --notes-file <bilingual-release-notes.md>
```

If the local network cannot upload the large Windows release zip reliably, run the `Upload Windows Release Asset` GitHub Actions workflow with:

- `tag`: `v<version>`
- `ref`: `main`

The workflow rebuilds `scripts/package_windows_portable.sh` on a GitHub runner and uploads `ReadyCheck-<version>-windows-x64-portable.zip` to the existing release.

Verify GitHub latest:

```bash
gh api repos/whnnick/readycheck/releases/latest --jq '{tag_name, name, draft, prerelease, html_url, assets: [.assets[].name]}'
```

`tag_name` must match the version just released.

The preview signing identity keeps local Keychain identity stable but is not a Developer ID certificate. A production Gatekeeper-ready release still requires Developer ID signing, hardened runtime configuration, notarization, and stapling.

Public sync excludes internal hosting/agent metadata (`.openai`, `.superpowers`) as well as all dependency `node_modules` directories and generated prototype output. Keep commit messages, README, changelogs and release notes bilingual.
