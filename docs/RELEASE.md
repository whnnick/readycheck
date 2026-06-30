# Release Process

Use this flow for every user-visible ReadyCheck release. Do not publish from an ad-hoc sequence.

## 1. Prepare The Version

1. Update `ReadyCheckCore.version`.
2. Update `scripts/package_app.sh` and `scripts/package_dmg.sh`.
3. Update `README.md`, `README.zh-CN.md`, `CHANGELOG.md`, and `CHANGELOG.zh-CN.md`.
4. Keep the release changelog entry under the exact version heading, not under `Unreleased`.

## 2. Verify The Development Worktree

Run from `.worktrees/readycheck-macos-mvp`:

```bash
swift test
git diff --check
rg -n "0\\.1\\.<previous>|ReadyCheck-0\\.1\\.<previous>" README.md README.zh-CN.md Sources Tests scripts docs -S
```

Then package locally:

```bash
scripts/package_dmg.sh
```

`scripts/package_dmg.sh` is the only standard local packaging entry point. It cleans old `ReadyCheck-*-macos.dmg` files from `dist` before writing the current DMG.

Validate the local artifact:

```bash
find ../../dist -maxdepth 1 -type f -o -type d
plutil -p ../../dist/ReadyCheck.app/Contents/Info.plist | rg "CFBundleShortVersionString|CFBundleVersion"
hdiutil imageinfo ../../dist/ReadyCheck-<version>-macos.dmg
shasum -a 256 ../../dist/ReadyCheck-<version>-macos.dmg
```

The root `dist` directory must contain only:

- `ReadyCheck.app`
- `ReadyCheck-<version>-macos.dmg`

Commit the development worktree after these checks pass.

## 3. Publish The Public Repository

Use the public sync directory, not the development worktree, for the public `main` release. From the repository root, sync from the development worktree while excluding internal agent material:

```bash
rsync -a --delete \
  --exclude .git \
  --exclude .build \
  --exclude dist \
  --exclude .worktrees \
  --exclude .codex \
  --exclude .agents \
  --exclude AGENTS.md \
  --exclude docs/superpowers \
  .worktrees/readycheck-macos-mvp/ /private/tmp/readycheck-public-sync-20260629/
```

In the public sync directory:

```bash
swift test
git diff --check
scripts/package_dmg.sh
find dist -maxdepth 1 -type f -o -type d
hdiutil imageinfo dist/ReadyCheck-<version>-macos.dmg
shasum -a 256 dist/ReadyCheck-<version>-macos.dmg
```

The public sync `dist` directory must contain only:

- `ReadyCheck.app`
- `ReadyCheck-<version>-macos.dmg`

Then commit, tag, push, and create the GitHub Release:

```bash
git add -A
git commit -m "Update ReadyCheck macOS preview to <version>"
git tag -a v<version> -m "ReadyCheck <version>"
git push origin HEAD:main
git push origin v<version>
gh release create v<version> dist/ReadyCheck-<version>-macos.dmg --repo whnnick/readycheck --title "ReadyCheck <version>" --notes "<release notes>"
```

Verify GitHub latest:

```bash
gh api repos/whnnick/readycheck/releases/latest --jq '{tag_name, name, draft, prerelease, html_url, assets: [.assets[].name]}'
```

`tag_name` must match the version just released.

The current release script applies an ad-hoc signature. A production Gatekeeper-ready release additionally requires Developer ID signing, hardened runtime configuration, notarization, and stapling.
