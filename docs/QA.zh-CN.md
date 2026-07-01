# 真实场景验收清单

[English](QA.md) | 中文

发布预览构建或验证用户反馈回归前，使用这份清单。不要把 token、回调 URL、账号 ID 或原始 usage 响应贴到公开 issue。

## macOS 安装与更新

1. 在没有运行 ReadyCheck 的 Mac 上安装最新 DMG。
2. 确认 Finder、Dock 和菜单栏中都显示 ReadyCheck 图标。
3. 启动旧版本并执行“检查更新”。确认可以检测到 GitHub latest release，并且下载操作会打开发布页。
4. 断开网络后执行“检查更新”。确认应用显示失败提示，而不是卡住界面。

## macOS Codex OAuth

1. 点击“连接”，在浏览器完成 OAuth 授权。
2. 确认 ReadyCheck 可以自动收到 `localhost:1455` 回调。
3. 如果没有收到回调，粘贴最终回调 URL 到手动输入框并完成授权。
4. 确认已连接账号显示登录邮箱，而不是内部 account ID。
5. 断开账号，确认界面回到未连接状态。

## 安全刷新与准确性

1. 执行手动刷新，确认不会访问模型推理 endpoint。
2. 确认只有在 5 小时和 7 天窗口都能解析时，主窗口才显示 Codex 额度百分比。
3. 与测试者可见的 Codex 或 ChatGPT 用量来源对照显示数值。
4. 如果上游响应结构变化，ReadyCheck 必须显示不可用或隐藏百分比，直到 parser 测试更新。
5. 使用过期 token 场景验证，确认刷新 token 成功，或 fail-closed，不猜测百分比。

## Widget 行为

1. 首次启动后，确认“显示 widget”默认开启，并且 widget 完整位于屏幕可见区域内。
2. 隐藏 widget 后，只点击一次“显示 widget”。确认它回到和“重置位置”一致的右下角默认位置。
3. 关闭“置顶 widget”。确认普通应用窗口可以覆盖 widget，且 widget 仍可拖动。
4. 拖动 widget。确认主窗口不会被打开。
5. 单击 widget 内容区域。确认主窗口打开。
6. 在“极简”和“详细”样式之间切换，确认标签不会换成竖排文字。

## 低额度与异常状态

1. 测试或模拟任一额度窗口低于 25% 剩余，确认显示提醒和红色进度条。
2. 断网后刷新，确认应用不会把过期或失败数据变成猜测百分比。
3. 确认过期额度快照会标记为过期或不可用，而不是继续显示为当前可用。

## Windows 预览版黑盒验收

1. 在 Windows 10/11 上运行 `apps/windows` 预览版，确认系统托盘图标、托盘菜单、主窗口和桌面 widget 都能显示。
2. 点击“连接”，在浏览器完成 Codex OAuth 授权，确认应用能自动接收 `localhost:1455/auth/callback` 回调。
3. 授权后确认账号区域显示登录邮箱，刷新后显示 Codex 5 小时和 7 天额度。
4. 对照可见的 Codex / ChatGPT 用量来源检查百分比和重置时间；如果明显不一致，记录截图和时间，但不要公开 token、account id 或原始 usage 响应。
5. 断网后刷新，确认 Windows 版不会显示猜测额度；缺少 token、account id、请求失败或 parser 失败时必须显示不可用。
6. 首次启动、隐藏后重新显示、点击“重置位置”三种场景下，widget 都应回到同一个右下角默认位置，并完整位于屏幕内。
7. 关闭“置顶 widget”后，普通应用窗口应能覆盖 widget，widget 仍应可拖动。
8. 切换极简 / 详细 widget，确认文字不竖排、不遮挡、不溢出。
9. 退出应用后重新打开，确认已授权状态可以恢复，token 文件不是可读明文 JSON。

## 发布门槛

- `swift test` 必须通过。
- Windows 子项目 `cd apps/windows && npm run check` 必须通过。
- `scripts/package_dmg.sh` 必须生成当前版本 DMG。
- `hdiutil imageinfo dist/ReadyCheck-<version>-macos.dmg` 必须能成功读取 DMG。
- README、更新日志和 release notes 必须使用同一个版本号。
