# 发布流程

每次发布用户可见版本都使用这套流程。不要临时换流程，也不要等用户发现问题后再补救。

## 发布阶段

按已确定的版本和发布类型，只执行用户要求的阶段。用户随后明确要求公开已准备好的预览版时，更新先前暂存草稿的决定，直接完成公开动作，不重复索取同一授权。

| 用户要求的阶段 | 执行动作 | 完成证据 |
| --- | --- | --- |
| 打包、推送 | 验证安装包，推送约定的源码和标签，保留当前公开状态。 | 远端源码、标签及制包检查一致；仅推送源码或上传附件不算公开发布。 |
| 保留草稿 | 准备或更新带两端包的草稿。 | `draft=true`，原稳定 latest 不变。 |
| 公开预览 | 将已验证预览版设为 `draft=false`、`prerelease=true`、`latest=false`。 | 未登录可访问发布信息和下载入口，原稳定 latest 不变。 |
| 稳定发布 | 通过稳定发布门槛后，设为 `draft=false`、`prerelease=false`、`latest=true`。 | 发布信息及两端下载公开，稳定 latest 指向本次版本。 |

只改变公开状态时，复用已有已审阅源码、标签、安装包及仍然适用的验证结果；输入变化或证据缺失时重新构建或补验。公开状态与验收状态分别记录，公开预览不把待验项改写为通过。

## 1. 准备版本

1. 更新 `ReadyCheckCore.version`。
2. 更新 `scripts/package_app.sh` 和 `scripts/package_dmg.sh`。
3. 更新 `README.md`、`README.zh-CN.md`、`CHANGELOG.md` 和 `CHANGELOG.zh-CN.md`。
4. 本次发布内容必须放在对应版本号标题下，不要留在 `Unreleased`。

## 旧功能保留门槛（0.3.0及以后）

打包或发布前，必须按[旧功能保留基线](versions/0.3.0/FEATURE_RETENTION.zh-CN.md)核对上一原生版与拟发布版本。目前登记65项macOS受保护能力，发现遗漏继续补充。逐项记录可发现入口、原有行为、测试／实机证据和偏好／历史迁移结果；明确适用的未修改路径证据可以复用，不能只凭源码存在、测试总数或原型通过宣布保留完成。

未经批准的功能缺失、行为退化或数据丢失阻塞任何发布。相关验收未完成时阻塞稳定发布。明确记录未验证范围的公开预览须有用户明确授权且源码、安装包已验证，不代表稳定发布门槛已解除。网页原型里未画或简化的页面按未完成处理。确需删除或实质改变，必须先提供功能ID、旧／新行为、影响与回滚方式，取得用户明确同意并记录证据，再实施。不要求用户回忆旧功能清单。Windows独立验收，不能套用Mac结果。

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

## 分发二进制隐私检查

SwiftPM 会把资源包构建位置写入可执行文件。分发时使用已有构建目录参数，指定不含个人用户名或内部工作区位置的临时路径：

```bash
READYCHECK_BUILD_DIR=/private/tmp/readycheck-release-build scripts/package_dmg.sh
```

除了源码文本，还应扫描挂载 DMG 内可执行文件的个人构建路径和凭据特征。发现私人路径时，改用干净临时构建目录重新生成，并再次验证最终 DMG；制包验证与安装版/真实账号验收分别记录。

## 3. 同步并推送公开仓库

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

新源码候选版再提交、打标签并推送；只改变公开状态时，可复用已验证的源码与标签：

```bash
git add -A
git commit -m "Release ReadyCheck <version> / 发布 ReadyCheck <version>"
git tag -a v<version> -m "ReadyCheck <version>"
git push origin HEAD:main
git push origin v<version>
```

### 选择 GitHub Release 阶段

准备新 Release 时，先将两端包附到草稿；已有草稿则复用，不重复创建：

```bash
gh release create v<version> dist/ReadyCheck-<version>-macos.dmg dist/windows/ReadyCheck-<version>-windows-x64-portable.zip --repo whnnick/readycheck --title "ReadyCheck <version>" --verify-tag --draft --latest=false --notes-file <bilingual-release-notes.md>
```

用户要求保留草稿时，到此停止。用户明确要求公开已验证预览版后执行：

```bash
gh release edit v<version> --repo whnnick/readycheck --verify-tag --draft=false --prerelease --latest=false
```

用户明确要求稳定发布且对应门槛已通过时执行：

```bash
gh release edit v<version> --repo whnnick/readycheck --verify-tag --draft=false --prerelease=false --latest
```

中英文 Release 说明、README 下载入口及本版本 QA/证据记录应与实际阶段一致；公开时保留有日期的历史草稿验证记录。

如果本地网络无法稳定上传较大的 Windows zip，运行 GitHub Actions 里的 `Upload Windows Release Asset` 手动 workflow：

- `tag`：`v<version>`
- `ref`：`main`

该 workflow 会在 GitHub runner 上重新执行 `scripts/package_windows_portable.sh`，并把 `ReadyCheck-<version>-windows-x64-portable.zip` 上传到已有 release。

按已保存的 Release ID 核对本次状态（包括草稿），并按阶段核对稳定 latest：

```bash
gh api repos/whnnick/readycheck/releases/<release-id> --jq '{tag_name, draft, prerelease, html_url, assets: [.assets[].name]}'
gh api repos/whnnick/readycheck/releases/latest --jq '{tag_name, name, draft, prerelease, html_url, assets: [.assets[].name]}'
```

本次 Release 的标签和标记须符合所选阶段，两个已验证安装包均应在附件中。只有稳定发布要求 stable latest 指向本次版本；草稿或预览应保留先前稳定 latest。公开发布后，还应验证未登录可访问发布页面/API 和两个下载入口。安装包完整性及重新下载的 SHA-256 检查继续保留，不替代安装版或真实设备验收。

预览签名身份只用于保持 Keychain 应用身份稳定，并不是 Developer ID 证书。面向正式 Gatekeeper 分发仍需要 Developer ID 签名、Hardened Runtime、notarization 和 stapling。

公开同步排除内部托管／协作元数据（`.openai`、`.superpowers`）及所有 `node_modules` 依赖目录及原型构建输出；提交说明、README、更新日志及 Release 说明均中英文同步。
