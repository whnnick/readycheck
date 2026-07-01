# Windows 开发计划

[English](WINDOWS.md) | 中文

ReadyCheck Windows 版从 `apps/windows` 下的 Electron 桌面客户端开始。macOS 版仍是当前可用的预览发布线；Windows 是新的平台线。

## MVP 边界

- 以系统托盘为核心的桌面应用。
- 主窗口承载账号、额度、刷新、widget 和更新控制。
- 桌面悬浮 widget 支持极简和详细模式。
- 只做安全刷新：绝不调用模型推理端点。
- 预留中文和英文偏好设置。

## 当前状态

Windows 代码已经包含桌面壳层、UI 状态流、Codex OAuth 回调、加密 token 存储、只读 usage 拉取和 Codex 额度解析。刷新仍然遵循 fail-closed：缺 token、缺 account id、接口失败或解析失败时不显示百分比，避免误报。

## 技术方向

- 运行时：Electron。
- UI：本地 HTML/CSS/JavaScript。
- 凭据存储：Electron `safeStorage` 加密落盘，Windows 上使用系统加密能力；后续可替换为更底层的 Windows Credential Manager。
- 更新来源：GitHub Releases，与 macOS 预览版保持一致。
- 打包目标：Windows 黑盒验收通过后再做签名 Windows 安装包。

## 验证

非 Windows 环境可做的验证：

```bash
cd apps/windows
npm run check
npm run smoke
```

生成 Windows 便携版预览包：

```bash
scripts/package_windows_portable.sh
```

输出：`dist/windows/ReadyCheck-0.1.0-windows-x64-portable.zip`。

仍需在 Windows 上验收：

- 托盘图标显示，菜单操作可用。
- 主窗口可从托盘和 widget 点击打开。
- widget 位于工作区内且可拖动。
- 置顶开关能改变窗口层级。
- OAuth 未连接前刷新必须 fail-closed。
- Codex OAuth 授权后账号状态应显示为已连接。
- 授权后刷新应显示 5 小时和 7 天额度；低额度颜色与 macOS 版一致。
- token 文件不得以明文 JSON 保存。
