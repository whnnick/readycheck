# 0.1.97 下一版计划：连接与提醒可靠性

[English](NEXT_RELEASE.md) | [文档入口](../README.zh-CN.md#文档)

调研日期：2026-09-20。状态：已在本地 0.1.97 开发分支实现；打包和真实环境验收记录在 QA。README 标记公开版为 0.1.94。

## 目标与范围

让已登录 Codex 的用户稳定看到正确账号的额度，并能解释恢复提醒何时送达、何时撤回。优先完成下面 P0，再考虑 P1；预计 4–6 个开发日，实际取决于官方接口在目标客户端上的可用性和真机验收。

## 官方依据与当前差距

- [OpenAI App Server](https://learn.chatgpt.com/docs/app-server)：提供账号、额度、用量读取与账号/额度更新事件；支持按客户端版本生成 JSON Schema。当前已有额度事件监听、多额度桶解析与 Token 历史，下一版是补齐账号生命周期及兼容性。
- [Apple 通知移除](https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/removedeliverednotifications(withidentifiers:))：删除异步执行；查询结果只能证明通知中心条目状态，不能证明用户看到了屏幕横幅。
- [Apple 认证上下文](https://developer.apple.com/documentation/security/ksecuseauthenticationcontext)：提供按查询的认证上下文。旧凭据存于传统 Keychain，不能假定替换 API 就能解决升级访问问题；需先做兼容实验。
- [Apple 登录启动](https://developer.apple.com/documentation/servicemanagement/smappservice/mainapp)：主应用可注册为登录项，状态必须回读系统。
- [macOS 27 发布说明](https://developer.apple.com/documentation/macos-release-notes/macos-27-release-notes)：作为兼容测试入口；本次页面正文未完整取回，不据此宣称存在某个新的通知缺陷或已修复行为。

## P0：0.1.97 已实现

### 1. 使用本机 Codex 登录状态（约 1–2 日）

当前 CodexOAuthQuotaProvider.fetchSnapshot 先读取/刷新自己的 OAuth token，随后才访问 app-server；Keychain 不可用会阻断本可使用的官方数据。

方案：增加明确的“使用本机 Codex”连接模式，成功读取账号与额度后才设为已连接。绑定可验证账号/工作区身份，禁止静默合并不同账号；若当前协议只能提供不充分的身份信息，暂停自动切换并提示确认。原有独立 OAuth 保留为用户主动选择的连接方式。监听 account/updated，账号变化时清理旧额度与提醒基线。

验收：仅 Codex 已登录、ReadyCheck 无 token 时可读额度；Codex 登出、账号切换、客户端退出与重启不会串号；旧 OAuth 用户可继续使用；后台不弹凭据授权框。不得将内部 backend-api 端点描述为有公开稳定契约的接口。

### 2. 提醒真正闭环（约 1–2 日）

0.1.96 已实现删除回查，但当前测试 target 仅覆盖 Core，缺少系统通知服务层验证。源码还存在同时发生“旧提醒删除失败、新提醒发送成功”时旧基线覆盖新基线的风险，需复现测试后修复。

方案：补通知适配层测试，覆盖延迟删除、删除失败、进程重启、同批发送与移除、账号切换、尚未投递的 pending request。历史区分别显示“已送达通知中心”“已自动撤回”“撤回待重试”；未知原因的条目消失不能标为用户已读。

验收：人工设置持续样式，发送明确标注的验收通知并模拟额度下降；记录系统条目查询与屏幕观察两份证据。成功撤回后不反复操作；失败可重试且不丢失新提醒。锁屏、专注模式、休眠唤醒分别记录限制。正常数据刷新不是模型请求；额度下降只有官方快照更新后才能识别，不承诺发送消息瞬间消失。

### 3. 官方协议兼容检查（约 1 日）

方案：对目标 Codex 版本生成 Schema，并保存去敏的最小 fixtures；核对启动参数和初始化握手，而非直接照搬最新版文档。持续连接需验证是否能观察其他 Codex 进程产生的额度变化，不能把“存在事件方法”等同于“跨进程实时广播”。失败时保留轮询。

验收：新旧客户端、缺字段、未知额度桶、重置券详情未知/为空、进程崩溃与唤醒重连均有测试；显示数据来源、更新时间与降级状态。固定测试构建号，不把不同客户端结果混合为一个事实。

## P1：0.1.97 已实现

登录时启动（约半日）：使用 SMAppService.mainApp，默认由用户开启，显示系统实际批准状态；重登后仅出现一个监控实例，不抢前台。Keychain 现代化仅做独立实验，旧数据兼容未验证前不迁移存储。

## 后续 0.2.0 候选

一键使用重置券：官方已文档化 account/rateLimitResetCredit/consume。需要单次确认、持久化幂等键、明确区分成功/已兑换/无券/不可重置、执行后重新读取额度；取消或超时不得自动创建新兑换尝试。具体资格由服务响应决定，不硬编码未经文档确认的门槛。此项改变只读产品边界，独立设计和验收后再做。

暂不纳入：多供应商、AI 用量预测、自动兑换重置券、视觉大改、Windows 通知功能扩展。

## 发布与黑盒验收门槛

- P0 三项逐条标明完成/部分完成/未完成，更新中英文 QA，并链接本计划。
- 完整 Swift 测试含沙箱外 localhost OAuth 回调；核心、通知适配层、Windows 冒烟检查分别统计，专项是总数子集，不重复相加。
- macOS 14 最低支持环境与 macOS 27 真机安装、升级、冷启动、提醒显示/撤回验证；缺少设备明确记录，不声称已通过。
- 签名身份、安装后二进制、产物版本与源码一致；DMG、Windows ZIP、校验文件全部按现有发布脚本构建。
- 用户要求推送 GitHub 时完成源码、tag、Release、assets、latest 和下载校验全流程。
# 历史计划：0.1.97

当前规划请看 [0.1.98 计划](versions/0.1.98/PLAN.zh-CN.md)及[版本索引](VERSIONS.md)。
