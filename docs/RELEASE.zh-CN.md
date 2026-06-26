# 发布流程

1. 运行 `swift test`。
2. 运行 `scripts/package_app.sh`。
3. 运行 `scripts/package_dmg.sh`。
4. 使用 `plutil -lint`、`codesign -dv` 验证 app bundle，并使用 `hdiutil imageinfo` 验证 DMG。
5. 创建与应用版本一致的带注释 tag，并创建 GitHub Release 上传 DMG。

当前脚本使用 ad-hoc 签名。面向正式 Gatekeeper 分发还需要 Developer ID 签名、Hardened Runtime、notarization 和 stapling。
