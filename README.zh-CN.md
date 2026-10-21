[English](README.md) · 简体中文

<p align="center"><img src="docs/assets/readycheck-app-icon.png" alt="ReadyCheck 图标" width="72"></p>
<h1 align="center">ReadyCheck</h1>
<p align="center"><strong>工作时，一眼掌握 Codex 剩余额度。</strong></p>
<p align="center"><a href="https://github.com/whnnick/readycheck/releases/latest"><img src="https://img.shields.io/badge/release-v0.4.0-blue" alt="发布 0.4.0"></a> <a href="docs/INSTALL.zh-CN.md"><img src="https://img.shields.io/badge/macOS-14%2B-101820" alt="macOS 14+"></a> <a href="LICENSE"><img src="https://img.shields.io/github/license/whnnick/readycheck" alt="MIT"></a></p>
<p align="center"><a href="https://github.com/whnnick/readycheck/releases/latest"><strong>下载</strong></a> · <a href="docs/versions/0.4.0/RELEASE_NOTES.zh-CN.md">更新重点</a> · <a href="docs/INSTALL.zh-CN.md">安装</a> · <a href="docs/VERSIONS.md">版本与验收</a></p>

ReadyCheck 是免费开源的 Codex 额度监控工具。在原生 Mac 窗口、菜单栏或可选桌面 Widget 中查看剩余额度、重置时间和账户权益。刷新只读取已授权的用量数据，不发送模型生成请求。

## 0.4.0 更新重点

- **下一步，一眼清楚：** 总览、菜单栏与Widget统一展示最近重置、条件用卡窗口或待处理事项；总览最多两条，减少重复大卡片。
- **用卡与通知分开看：** 从到期行或用卡记录点开详情，看清原到期时间、授权、用卡结果及对应通知；通知待重试不代表用卡失败。
- **新旧读数有依据：** 保留卡片实际读取时间，过旧或不完整明细不承诺尝试窗口；计时结束仍需新读数确认恢复。
- **常用功能完整保留：** 账户权益、逐卡日期、独立提醒、Token与消耗图、Widget最近1小时图、固定、拖动、刘海及关于均保留，见65项审计。

<p align="center"><img src="docs/versions/0.4.0/assets/release-overview-zh.png" alt="ReadyCheck 0.4.0 原生界面，合成数据" width="900"></p>
<p align="center"><sub>原生macOS界面 · 合成数据，不公开私人账号截图。</sub></p>

[完整更新说明](docs/versions/0.4.0/RELEASE_NOTES.zh-CN.md) · [功能验收](docs/versions/0.4.0/QA.zh-CN.md) · [功能保留审计](docs/versions/0.4.0/RELEASE_AUDIT.zh-CN.md)

## 从这里开始

1. 在[最新发布](https://github.com/whnnick/readycheck/releases/latest)下载 **ReadyCheck-0.4.0-macos.dmg**，将 ReadyCheck.app 拖到“应用程序”。
2. 启动后跟随本机 Codex 登录账号，或使用独立 OAuth 登录；如 macOS 请求钥匙串访问，请完成系统确认。
3. 在“设置 → 提醒”选择门槛，在“设置 → 显示”开启 Widget 或刘海。

Mac 下载为 **arm64 / Apple 芯片、macOS 14+**，沿用稳定的**自签名预览**身份，**未经 Developer ID 签名或公证**，见[安装说明](docs/INSTALL.zh-CN.md)。Windows 可在同一发布页下载 **ReadyCheck-0.4.0-windows-x64-portable.zip**，解压运行 ReadyCheck.exe。

## 三处界面，两类数据

| 入口 | 柱子的含义 | 来源 |
| --- | --- | --- |
| Widget → 额度消耗 | 所选配额最近一小时，每柱五分钟，单位为**百分点**。 | 当前账号在本机成功刷新留下的记录。 |
| 总览 → 额度消耗 | 同一指标查看最近 24 小时／7 天／30 天，每柱一小时／六小时／一天。 | 与 Widget 相同的本机历史和下降计算规则。 |
| Token 用量 → 每日 Token 数量 | 接口返回的 Token 数量，按 UTC 自然日汇总。 | 官方返回且匹配当前账号的 Codex 统计，可能缺失。 |

剩余 80% 降到 70%，记为消耗 **10 个百分点**，不是 10 个 Token，也不是原来 80% 的 10%。本机记录排除重置切换、无效或缺失读数、额度回升及超过十分钟的断档。跨多个周期的累计消耗可以超过 100 个百分点。Widget 柱高按自身最大值缩放。额度与 Token **没有固定换算关系**，缺少 Token 数据不会用第二份额度图替代。

## 桌面交互与平台范围

<p align="center"><img src="docs/versions/0.2.1/assets/bubble-compact-80-demo.png" alt="悬浮圆球，合成演示数据" width="92"> &nbsp; <img src="docs/versions/0.2.1/assets/bubble-rail-right.png" alt="同一 Widget 贴边后的细竖条" width="28"></p>

<p align="center"><img src="docs/versions/0.4.0/assets/release-widget-zh.png" alt="原生 Widget 最近一小时消耗，合成演示数据" width="380"></p>

在“设置 → 显示”选择悬浮气泡或信息卡片；悬浮气泡拖到边缘收成细竖条，向内拖回圆球，信息卡片通过标题拖动。Widget 固定详情后，点击其他区域或切换焦点仍保持展开；取消固定恢复预览行为，Esc 可收起获得焦点的详情。支持桌面与左右贴边之间直接拖动。刘海点击展开，点击外部或 Esc 收起。

| 平台 | 0.4.0 范围 |
| --- | --- |
| macOS | 共享下一步与只读用卡结果，保留自适应Widget、一小时图、可拖卡片、侧栏／菜单、点击刘海及账户历史；见[当前验收与边界](docs/versions/0.4.0/QA.zh-CN.md)。 |
| Windows x64 | 独立便携预览，保留原界面；本次没有把 Mac 重构移植到 Windows，见 [Windows 说明](docs/WINDOWS.zh-CN.md)和[验收](docs/WINDOWS_QA.zh-CN.md)。 |

ReadyCheck 提供提醒，**不会自动停止或恢复 Codex 任务**，仅在单独按账号授权后自动使用临期重置卡。恢复提醒只依据新鲜且可验证的读数，关闭期间未观测到的恢复不会补发。多显示器／Spaces、专注／睡眠、VoiceOver 及正式分发签名仍未宣称全面验收。

## 隐私与账户访问

额度刷新只读，可选的自动用卡属于单独授权的变更操作。可跟随本机 Codex 账号或独立 OAuth 登录，Mac 凭据存于系统钥匙串。新历史按账号隔离，无法归属的旧历史单独保全。反馈日志或截图前请移除账号和凭据。

ReadyCheck 是独立项目，与 OpenAI 无隶属或背书关系；Codex、ChatGPT 及其标识归 OpenAI 所有。

## 文档与开发

当前版本：[0.4.0计划](docs/versions/0.4.0/PLAN.zh-CN.md) · [原生契约](docs/versions/0.4.0/TECHNICAL.zh-CN.md) · [保留审计](docs/versions/0.4.0/RELEASE_AUDIT.zh-CN.md)。[可点击设计原型](docs/versions/0.4.0/prototype/README.zh-CN.md)作为过程档案。

[旧功能保留基线](docs/versions/0.3.0/FEATURE_RETENTION.zh-CN.md)：登记65项原生能力；原型未展示项按未完成处理，不能默认为删减。

产品探索：[0.3.0 额度节奏原型](docs/versions/0.3.0/prototype/README.zh-CN.md) · [计划与边界](docs/versions/0.3.0/PLAN.zh-CN.md)。合成方向已确认；0.3.0候选版见[原生开发契约](docs/versions/0.3.0/TECHNICAL.zh-CN.md)。发布验收状态见逐项审计。

本地开发：[0.2.2 连接可靠性](docs/versions/0.2.2/PLAN.zh-CN.md) · [检查与覆盖边界](docs/versions/0.2.2/QA.zh-CN.md)。连接修复已包含于0.3.0。

[0.2.1 计划](docs/versions/0.2.1/PLAN.zh-CN.md) · [功能检查](docs/versions/0.2.1/QA.zh-CN.md)。0.2.0 基础版本的完整检查归档见下方。

- [安装](docs/INSTALL.zh-CN.md) · [更新日志](CHANGELOG.zh-CN.md) · [版本索引](docs/VERSIONS.md)
- [0.2.0 计划](docs/versions/0.2.0/PLAN.zh-CN.md) · [完整检查](docs/versions/0.2.0/UPGRADE_REVIEW.zh-CN.md) · [黑盒检查](docs/versions/0.2.0/QA.zh-CN.md)
- [贡献指南](CONTRIBUTING.md) · [发布流程](docs/RELEASE.zh-CN.md) · [安全政策](SECURITY.md) · [问题反馈](https://github.com/whnnick/readycheck/issues)

源码构建需要 macOS 14+ 及兼容 Swift 6 的工具链：

```bash
swift test
scripts/package_app.sh
```

开发启动使用 `scripts/build_and_run.sh`，分发遵循发布流程。采用 [MIT](LICENSE) 许可。

0.3.0包含[临期重置卡自动使用](docs/versions/0.3.0/RESET_CARD_AUTOMATION.zh-CN.md)，默认关闭、需账号授权；未通过兑换真实卡进行验证，适用平台和验收边界见上文。

本地开发版在同一区域提供独立“重置卡到期提醒”（默认开启），与“临期自动用卡”（默认关闭）分开控制。

自动用卡经服务端确认成功后，会发送独立成功通知并记录通知历史，不受到期提醒开关影响。
