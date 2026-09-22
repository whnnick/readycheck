# 0.1.98 黑盒验收

[English](QA.md) | [产品计划](PLAN.zh-CN.md) | [版本索引](../../VERSIONS.md)

状态：已于 2026-09-22 发布。自动化回归完成；真实持续通知闭环、登录项及跨系统设备检查继续作为已记录的验收限制。

| 需求 | 状态 | 所需证据 |
| --- | --- | --- |
| A 连接自恢复/诊断 | 自动化完成，实机部分完成 | 初始化拒绝、无响应超时及第二候选回退测试通过；安装版从“未连接/已停止”自动恢复为已连接，显示官方额度和“额度事件：已连接”。客户端退出/断网恢复待实测 |
| B 持续通知闭环 | 未完成 | 可控恢复/消耗真实系统录屏或时间记录；自然周期单独记录 |
| B 专注/锁屏/唤醒 | 未完成 | 各系统场景观察，不以通知中心记录冒充横幅可见 |
| C 新旧协议 | 完成 | 按 ChatGPT 内 Codex CLI 0.155.0-alpha.9.2 生成 Schema；既有多桶、动态窗口、未知/零重置券回归通过 |
| P1 登录启动 | 未完成 | 注册回读、注销登录、关闭与升级实测 |
| 安装兼容性 | macOS 27 完成 | 已安装 0.1.98，About 与 Info 均显示 0.1.98；安装版与 DMG 二进制 SHA-256 均为 `c4d32176a50cc8927457ff42d49f2aa8f689202761f4193ed9714ba1c777c447`。macOS 14 待设备 |
| 回归与发布 | 已发布 | 190 项 Core + 2 项 App 测试通过，含 localhost OAuth；Windows check/smoke/UI smoke、版本一致性及 DMG 构建通过。GitHub `v0.1.98` Release 包含 macOS DMG、Windows 便携 ZIP 和 SHA-256 校验文件 |

最终 DMG 与 Windows ZIP 的 SHA-256 记录在 Release 校验文件中。DMG 使用 `ReadyCheck Preview Signing`，无 Team ID；不宣称 Developer ID 公证。

验收限制：真实持续通知闭环尚未完成端到端观察，缺少 macOS 14 实机，macOS 安装包使用预览签名而非 Developer ID 公证。登录时启动当前仍显示不可用，保持实验状态。
