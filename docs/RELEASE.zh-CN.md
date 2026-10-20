# 发布流程

每次发布用户可见版本都使用这套流程。不要临时换流程，也不要等用户发现问题后再补救。

## 1. 准备版本

1. 更新 `ReadyCheckCore.version`。
2. 更新 `scripts/package_app.sh` 和 `scripts/package_dmg.sh`。
3. 更新 `README.md`、`README.zh-CN.md`、`CHANGELOG.md` 和 `CHANGELOG.zh-CN.md`。
4. 本次发布内容必须放在对应版本号标题下，不要留在 `Unreleased`。

## 旧功能保留门槛（0.3.0及以后）

打包或发布前，必须按[旧功能保留基线](versions/0.3.0/FEATURE_RETENTION.zh-CN.md)核对上一原生版与拟发布版本。目前登记65项macOS受保护能力，发现遗漏继续补充。逐项记录可发现入口、原有行为、测试／实机证据和偏好／历史迁移结果；明确适用的未修改路径证据可以复用，不能只凭源码存在、测试总数或原型通过宣布保留完成。

入口缺失、行为退化、数据丢失或相关验收未完成时阻塞发布。网页原型里未画或简化的页面按未完成处理。确需删除或实质改变，必须先提供功能ID、旧／新行为、影响与回滚方式，取得用户明确同意并记录证据，再实施。不要求用户回忆旧功能清单。Windows独立验收，不能套用Mac结果。

## 2. 验证开发工作区

在 `.worktrees/readycheck-macos-mvp` 中运行：

```bash
scripts/check_release_consistency.sh
swift test
git diff --check
rg -n "0\\.1\\.<上一版>|ReadyCheck-0\\.1\\.<上一版>" README.md README.zh-CN.md Sources Tests scripts docs -S
```

然后本地打包：

```bash
scripts/package_dmg.sh
scripts/package_windows_portable.sh
```

Windows 打包要求 Node.js 22.12–24，并使用 Node.js 24 验证。如果系统安装了更新的 Node，请用 `READYCHECK_NODE_BIN` 指定兼容的 Node 可执行文件；脚本会在打包前失败，不再接受 Electron Packager 未生成产物的假成功结果。

`scripts/package_dmg.sh` 是标准本地打包入口。它会在写入当前版本 DMG 前自动清理 `dist` 中的旧 `ReadyCheck-*-macos.dmg`。

发布包必须使用稳定签名身份。`scripts/package_app.sh` 会优先使用本机的 `ReadyCheck Preview Signing`，也可通过 `READYCHECK_SIGNING_IDENTITY` 指定其他身份。单独构建 App 时允许贡献者回退到 ad-hoc 签名，但 `scripts/package_dmg.sh` 找不到稳定身份时会直接失败，不会生成不可持续访问 Keychain 的发布 DMG。

验证本地产物：

```bash
find ../../dist -maxdepth 1 -type f -o -type d
hdiutil imageinfo ../../dist/ReadyCheck-<version>-macos.dmg
shasum -a 256 ../../dist/ReadyCheck-<version>-macos.dmg
```

挂载 DMG 后验证其中的 App，不再验证复制到同步目录的中间 App：

```bash
plutil -p /Volumes/ReadyCheck/ReadyCheck.app/Contents/Info.plist | rg "CFBundleShortVersionString|CFBundleVersion"
codesign --verify --deep --strict /Volumes/ReadyCheck/ReadyCheck.app
codesign -dv --verbose=2 /Volumes/ReadyCheck/ReadyCheck.app
codesign -dr - /Volumes/ReadyCheck/ReadyCheck.app
```

根目录 `dist` 只能包含：

- `ReadyCheck-<version>-macos.dmg`
- `windows/ReadyCheck-<version>-windows-x64-portable.zip`

`package_dmg.sh` 将应用封入 DMG 后会移除中间应用包。

这些检查通过后，再提交开发工作区。

## 3. 发布公开仓库

公开 `main` 发布只从 public sync 目录执行，不直接从开发工作区发布。先预览同步差异：

```bash
scripts/sync_public_repo.sh --dry-run
```

确认差异后执行同步：

```bash
scripts/sync_public_repo.sh --apply
```

脚本会清理旧同步内容、排除内部 agent 与构建文件、执行敏感信息扫描和 `git diff --check`，但不会提交、打标签、推送或创建 Release。

`marketing/hyperframes/videos`下的本地宣传工程及其截图、音频、第三方资源包不进入公开同步。宣传素材应单独审阅后发布，应用Release不上传这些本地工程目录。

在 public sync 目录中运行：

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

public sync 的 `dist` 只能包含：

- `ReadyCheck-<version>-macos.dmg`
- `windows/ReadyCheck-<version>-windows-x64-portable.zip`

然后提交、打标签、推送并创建 GitHub Release：

```bash
git add -A
git commit -m "Release ReadyCheck <version> / 发布 ReadyCheck <version>"
git tag -a v<version> -m "ReadyCheck <version>"
git push origin HEAD:main
git push origin v<version>
gh release create v<version> dist/ReadyCheck-<version>-macos.dmg dist/windows/ReadyCheck-<version>-windows-x64-portable.zip --repo whnnick/readycheck --title "ReadyCheck <version>" --verify-tag --latest --notes-file <bilingual-release-notes.md>
```

如果本地网络无法稳定上传较大的 Windows zip，运行 GitHub Actions 里的 `Upload Windows Release Asset` 手动 workflow：

- `tag`：`v<version>`
- `ref`：`main`

该 workflow 会在 GitHub runner 上重新执行 `scripts/package_windows_portable.sh`，并把 `ReadyCheck-<version>-windows-x64-portable.zip` 上传到已有 release。

验证 GitHub latest：

```bash
gh api repos/whnnick/readycheck/releases/latest --jq '{tag_name, name, draft, prerelease, html_url, assets: [.assets[].name]}'
```

`tag_name` 必须是刚发布的版本。

预览签名身份只用于保持 Keychain 应用身份稳定，并不是 Developer ID 证书。面向正式 Gatekeeper 分发仍需要 Developer ID 签名、Hardened Runtime、notarization 和 stapling。

公开同步排除内部托管／协作元数据（`.openai`、`.superpowers`）及所有 `node_modules` 依赖目录及原型构建输出；提交说明、README、更新日志及 Release 说明均中英文同步。
