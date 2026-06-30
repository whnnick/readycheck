# 发布流程

每次发布用户可见版本都使用这套流程。不要临时换流程，也不要等用户发现问题后再补救。

## 1. 准备版本

1. 更新 `ReadyCheckCore.version`。
2. 更新 `scripts/package_app.sh` 和 `scripts/package_dmg.sh`。
3. 更新 `README.md`、`README.zh-CN.md`、`CHANGELOG.md` 和 `CHANGELOG.zh-CN.md`。
4. 本次发布内容必须放在对应版本号标题下，不要留在 `Unreleased`。

## 2. 验证开发工作区

在 `.worktrees/readycheck-macos-mvp` 中运行：

```bash
swift test
git diff --check
rg -n "0\\.1\\.<上一版>|ReadyCheck-0\\.1\\.<上一版>" README.md README.zh-CN.md Sources Tests scripts docs -S
```

然后本地打包：

```bash
scripts/package_dmg.sh
```

`scripts/package_dmg.sh` 是标准本地打包入口。它会在写入当前版本 DMG 前自动清理 `dist` 中的旧 `ReadyCheck-*-macos.dmg`。

验证本地产物：

```bash
find ../../dist -maxdepth 1 -type f -o -type d
plutil -p ../../dist/ReadyCheck.app/Contents/Info.plist | rg "CFBundleShortVersionString|CFBundleVersion"
hdiutil imageinfo ../../dist/ReadyCheck-<version>-macos.dmg
shasum -a 256 ../../dist/ReadyCheck-<version>-macos.dmg
```

根目录 `dist` 只能包含：

- `ReadyCheck.app`
- `ReadyCheck-<version>-macos.dmg`

这些检查通过后，再提交开发工作区。

## 3. 发布公开仓库

公开 `main` 发布只从 public sync 目录执行，不直接从开发工作区发布。在仓库根目录执行同步命令，并排除内部 agent 材料：

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

在 public sync 目录中运行：

```bash
swift test
git diff --check
scripts/package_dmg.sh
find dist -maxdepth 1 -type f -o -type d
hdiutil imageinfo dist/ReadyCheck-<version>-macos.dmg
shasum -a 256 dist/ReadyCheck-<version>-macos.dmg
```

public sync 的 `dist` 只能包含：

- `ReadyCheck.app`
- `ReadyCheck-<version>-macos.dmg`

然后提交、打标签、推送并创建 GitHub Release：

```bash
git add -A
git commit -m "Update ReadyCheck macOS preview to <version>"
git tag -a v<version> -m "ReadyCheck <version>"
git push origin HEAD:main
git push origin v<version>
gh release create v<version> dist/ReadyCheck-<version>-macos.dmg --repo whnnick/readycheck --title "ReadyCheck <version>" --notes "<release notes>"
```

验证 GitHub latest：

```bash
gh api repos/whnnick/readycheck/releases/latest --jq '{tag_name, name, draft, prerelease, html_url, assets: [.assets[].name]}'
```

`tag_name` 必须是刚发布的版本。

当前脚本使用 ad-hoc 签名。面向正式 Gatekeeper 分发还需要 Developer ID 签名、Hardened Runtime、notarization 和 stapling。
