# ReadyCheck 0.7.1 验收

[English](QA.md) · [发布说明](RELEASE_NOTES.zh-CN.md)

本次修复 macOS 版 Muse 周额度读取。已安装的 0.7.1 开发版复用原会话，启动、手动刷新及退出重开后均读到真实周额度和重置时间。钥匙串确认后也读到了 Codex 额度和 DeepSeek 余额。同一修复通过 14 项读取器测试及 14 项 Swift 专项测试。[安装版实测](../0.7.0/QA.zh-CN.md)。

界面和偏好设置沿用 0.7.0 验收。Windows 本次只更新版本元数据，原 OAuth 403 设备和其他 Muse 账号仍未实测。[0.7.0 验收](../0.7.0/QA.zh-CN.md)。

公开源码运行 545 项 Swift 测试，跳过 3 项，零失败。14 项 Muse 读取器测试全部通过。挂载 DMG 后通过严格签名、版本、读取脚本内容及隐私检查。Windows ZIP 通过 CRC 检查，包内 13 个 JavaScript 文件与源码一致，本地 Node 检查和 UI 冒烟测试通过。
