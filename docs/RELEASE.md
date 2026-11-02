# Release Process

Use this flow for every user-visible ReadyCheck release. Do not publish from an ad-hoc sequence.

## Release stages

Apply only the stages requested for the agreed version and release type. A later explicit request to publish a prepared preview supersedes an earlier draft hold; complete that publication without requesting the same authorization again.

| Requested stage | Action | Completion evidence |
| --- | --- | --- |
| Package and push | Verify packages and push the agreed source/tag; preserve the current publication state. | Remote source/tag and package checks match. A source push or asset upload alone is not publication. |
| Keep a draft | Prepare or update a draft with both packages. | `draft=true`; the existing stable latest is unchanged. |
| Publish a public preview | Publish the verified preview with `draft=false`, `prerelease=true`, `latest=false`. | Anonymous release and download access succeed; the existing stable latest is unchanged. |
| Publish a stable release | Clear the stable-release gate, then publish with `draft=false`, `prerelease=false`, `latest=true`. | The release and both downloads are public; stable latest matches the released version. |

When only publication state changes, reuse the existing reviewed source, tag, packages and still-applicable verification. Rebuild or repeat checks when inputs change or evidence is missing. Record publication state separately from acceptance state: publishing a preview does not turn pending checks into passes.

## 1. Prepare The Version

1. Update `ReadyCheckCore.version`.
2. Update `scripts/package_app.sh` and `scripts/package_dmg.sh`.
3. Update `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, and `CHANGELOG.zh-CN.md`.
4. Keep the release changelog entry under the exact version heading, not under `Unreleased`.

## Feature Retention Gate (0.3.0 and later)

Before packaging or publishing, reconcile the prior native version with the proposed release using the[feature-retention baseline](versions/0.3.0/FEATURE_RETENTION.md). The initial macOS register contains65 protected capabilities; extend it when a capability is discovered. For each relevant item, record its discoverable entry, retained behavior, test/device evidence and preference/history migration result. Specifically applicable unchanged-path evidence may be reused; source presence, aggregate test counts and prototype completion alone are insufficient.

Unapproved feature removal, degraded behavior or data loss block any release. Unresolved relevant acceptance blocks stable release. A public preview with documented unverified scope requires explicit user authorization and verified source/packages; it does not clear the stable-release gate. Treat a prototype's omitted/simplified pages as unfinished work. Any removal or substantive change requires explicit user approval with the feature ID, before/after behavior, impact and rollback recorded before implementation. Do not make the user recall the old feature list. Windows needs its own acceptance; Mac results do not cover it.

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

## Distribution binary privacy

SwiftPM embeds the resource-bundle build location in the executable. For distribution, use the existing build-directory override with a temporary path that contains no personal username or internal workspace location:

```bash
READYCHECK_BUILD_DIR=/private/tmp/readycheck-release-build scripts/package_dmg.sh
```

Inspect the executable inside the mounted DMG for personal build paths and credential patterns in addition to scanning source text. If a private path is found, rebuild with a clean temporary build directory and verify the final DMG again. Keep package validation separate from installed-app/live-account acceptance.

## 3. Sync And Push The Public Repository

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

For a new source candidate, commit, tag and push. A publication-only request can reuse the already verified source and tag:

```bash
git add -A
git commit -m "Release ReadyCheck <version> / 发布 ReadyCheck <version>"
git tag -a v<version> -m "ReadyCheck <version>"
git push origin HEAD:main
git push origin v<version>
```

### Choose The GitHub Release Stage

When preparing a new release, attach both packages to a draft. Reuse an existing draft instead of creating a duplicate:

```bash
gh release create v<version> dist/ReadyCheck-<version>-macos.dmg dist/windows/ReadyCheck-<version>-windows-x64-portable.zip --repo whnnick/readycheck --title "ReadyCheck <version>" --verify-tag --draft --latest=false --notes-file <bilingual-release-notes.md>
```

Stop here if a draft was requested. After an explicit request to publish a verified preview:

```bash
gh release edit v<version> --repo whnnick/readycheck --verify-tag --draft=false --prerelease --latest=false
```

For an explicitly requested stable release whose gate has passed:

```bash
gh release edit v<version> --repo whnnick/readycheck --verify-tag --draft=false --prerelease=false --latest
```

Keep bilingual Release notes, README download entries and the version's QA/evidence record consistent with the actual stage. Retain dated draft checks as history when publishing.

If the local network cannot upload the large Windows release zip reliably, run the `Upload Windows Release Asset` GitHub Actions workflow with:

- `tag`: `v<version>`
- `ref`: `main`

The workflow rebuilds `scripts/package_windows_portable.sh` on a GitHub runner and uploads `ReadyCheck-<version>-windows-x64-portable.zip` to the existing release.

Verify the release by its saved ID, including drafts, and compare stable latest with the expected stage:

```bash
gh api repos/whnnick/readycheck/releases/<release-id> --jq '{tag_name, draft, prerelease, html_url, assets: [.assets[].name]}'
gh api repos/whnnick/readycheck/releases/latest --jq '{tag_name, name, draft, prerelease, html_url, assets: [.assets[].name]}'
```

The release's tag and flags must match the chosen stage, with both verified packages attached. Stable latest must match the new version only for a stable release; a draft or preview must retain the prior stable latest. For a public release, verify anonymous access to its release page/API and both download URLs. Retain the package integrity and downloaded SHA-256 checks; these do not replace installed-app or real-device acceptance.

The preview signing identity keeps local Keychain identity stable but is not a Developer ID certificate. A production Gatekeeper-ready release still requires Developer ID signing, hardened runtime configuration, notarization, and stapling.

Public sync excludes internal hosting/agent metadata (`.openai`, `.superpowers`) as well as all dependency `node_modules` directories and generated prototype output. Keep commit messages, README, changelogs and release notes bilingual.
