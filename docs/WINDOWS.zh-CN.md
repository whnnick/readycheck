# ReadyCheck Windows 客户端

[English](WINDOWS.md) · [Windows QA](WINDOWS_QA.zh-CN.md) · [版本通道](../README.zh-CN.md#选择版本)

ReadyCheck Windows 是独立的 **Electron x64 Codex 客户端**，提供便携 ZIP，保留自己的托盘、主窗口和 Widget 界面；macOS 的 DeepSeek 余额、胶囊与刘海新能力尚未移植。

## 当前版本

- 最新公开预览下载为 **0.7.0-dev.23**，稳定发布通道为 **0.6.1**，见[下载表](../README.zh-CN.md#选择版本)。
- 最新源码/本机打包候选为 **0.7.0-dev.28**，尚无公开 Release 安装包资产。Dev.24–dev.28 的 Windows 改动仅为版本元数据。
- Dev.28 已通过 check/smoke/UI-smoke、ZIP CRC、PE x64 及 ASAR 版本检查，13 个 JS 文件与已审阅源码一致。这是跨平台制包验证，不代表 Windows 实机验收。

## 使用便携包

1. 下载已发布的 Windows x64 ZIP，并完整解压。
2. 运行 `ReadyCheck-win32-x64\ReadyCheck.exe`。
3. 在浏览器完成 Codex OAuth 后刷新；缺 token/账号、请求失败或响应无效时，额度百分比保持不可用。

凭据使用 Electron safeStorage 加密落盘。现有客户端包含额度刷新、账号状态、本机历史、提醒、托盘以及极简/详细 Widget；不通过模型生成请求测试连接。

OAuth/额度请求使用 Electron 系统网络。已报告的令牌请求 **403 仍未在受影响的 Windows 环境复测**；浏览器可访问不等于应用网络路径相同。不能据此宣称修复，排查见 [Windows QA](WINDOWS_QA.zh-CN.md)。

## 从源码构建

使用 Node.js **22.12–24**（当前打包脚本以 24 验证）：

```bash
cd apps/windows
npm ci
npm run check
npm run smoke
npm run smoke:ui
npm start
```

在仓库根目录打包：

```bash
scripts/package_windows_portable.sh
```

若系统 Node 更新，可用 `READYCHECK_NODE_BIN` 指定兼容可执行文件。脚本产出 `dist/windows/ReadyCheck-<version>-windows-x64-portable.zip`，验证后移除中间应用目录；当前流程不提供 Windows 安装器。

真实托盘、拖动/置顶、OAuth 回调、刷新、通知及加密存储检查仍需按[黑盒手册](WINDOWS_QA.zh-CN.md)在 Windows 完成，不能用 Mac 结果代替。
