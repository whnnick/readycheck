# Windows 黑盒测试手册

[English](WINDOWS_QA.md) | 中文

这份手册用于在 Windows 10/11 电脑上验证 ReadyCheck Windows 预览版。不要把 token、回调 URL、account id 或原始 usage 响应上传到 GitHub Issue、截图或聊天里。

## 准备

方式 A：使用便携版 zip。

1. 复制 `dist/windows/ReadyCheck-0.1.0-windows-x64-portable.zip` 到 Windows 电脑。
2. 解压 zip。
3. 运行 `ReadyCheck-win32-x64\ReadyCheck.exe`。

方式 B：从源码运行。

1. 安装 Node.js 22 或更高版本。
2. 获取仓库源码并进入 Windows 子项目：

```powershell
cd apps\windows
npm install
npm run check
npm run smoke
```

3. 启动应用：

```powershell
npm start
```

当前还没有 Windows 安装器；便携版 zip 和源码运行都属于预览测试流程。

## 必测路径

1. 启动后确认系统托盘、主窗口、桌面 widget 都出现。
2. 确认“显示 widget”默认开启，widget 完整位于屏幕内。
3. 点击“连接”，在浏览器完成 Codex OAuth。
4. 确认浏览器回到 `localhost:1455/auth/callback` 后，ReadyCheck 显示已连接账号邮箱。
5. 点击“刷新”，确认显示 Codex 5 小时和 7 天额度。
6. 切换极简 / 详细 widget，确认文字不竖排、不遮挡、不溢出。
7. 关闭“置顶 widget”，确认普通窗口可以盖住 widget，且 widget 仍可拖动。
8. 隐藏 widget 后重新打开一次，确认位置和“重置位置”一致。
9. 退出应用后重新启动，确认账号连接状态可以恢复。

## 异常路径

1. OAuth 前点击刷新：应显示未连接或不可用，不应显示猜测额度。
2. 断网后点击刷新：应显示不可用或保留安全状态，不应生成新的猜测百分比。
3. 如果刷新后没有显示额度，先记录 UI 截图、时间、网络状态和是否刚完成 OAuth；不要记录 token 或原始响应。
4. 如果 widget 跑到屏幕外，记录屏幕分辨率、缩放比例、多显示器布局和操作步骤。

## 通过标准

- `npm run check` 通过。
- `npm run smoke` 通过。
- OAuth 可以完成并恢复登录邮箱。
- 刷新只显示已解析的 5 小时 / 7 天额度；不能解析时 fail-closed。
- widget 不影响桌面操作，且默认位置稳定。
