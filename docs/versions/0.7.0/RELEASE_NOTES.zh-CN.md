<a id="source-candidate-dev28"></a>

# ReadyCheck 0.7.0-dev.28 — 打包源码候选

[English](RELEASE_NOTES.md#source-candidate-dev28) · [验收](QA.zh-CN.md) · [功能保留矩阵](RELEASE_AUDIT.zh-CN.md)

dev.28 Mac 与 Windows 安装包已验证，用于源码/tag 同步，不是新公开的 GitHub Release。公开预览下载仍为 dev.23，稳定下载仍为 0.6.1；下方保留[dev.23 公开预览说明](#public-preview-dev23)。

- 落实选定的 DeepSeek 微型趋势设计，覆盖胶囊、贴边及展开余额/分项，保留缺失/过期/失败状态和本机观测语义。
- 普通点击仅预览，共用显式固定按钮才保持展开；账户权益默认展开，仍可手动折叠。
- 已提醒的同一卡片异常在凭据中断/重启后继续去重，新事件仍可提醒；撤回已恢复的凭据警告，保留未确认卡片结果及检查历史。
- macOS 核心验收覆盖 338 Core +179 App（517 个不同测试通过，含三项原生截图补跑），并完成安装版连接/刷新/固定/刘海、用户确认的菜单/悬停/通知及同包重启检查；设备边界见 QA。
- Windows 保持现有 Codex 界面，dev.24–dev.28 仅同步版本元数据；Windows 403、其他设备及系统登录/Spaces/全屏等边界继续保留，打包不代表这些项目已通过。

macOS 包继续采用既有稳定自签名预览身份，不是 Developer ID 签名或公证包。本次打包/源码阶段不改变 stable latest 或公开预览发布状态。

<a id="public-preview-dev23"></a>

# ReadyCheck 0.7.0-dev.23 — 公开预览版

[English](RELEASE_NOTES.md) · [验证与边界](QA.zh-CN.md) · [旧功能保留核对](RELEASE_AUDIT.zh-CN.md)

本候选版基于本机已安装 dev.23 及已记录的分项验收；不是正式 0.7.0，旧功能保留发布门槛尚未全部解除。稳定版下载仍保留 0.6.1。

- macOS 新增 DeepSeek API 余额监控，分别显示赠送与充值余额、本机观测的余额减少、手动刷新及余额提醒。API Key 连接与 DeepSeek 网页/手机聊天用量不同；不发起模型生成请求。
- 保留 Codex 额度、权益、历史、通知、自动用卡授权、菜单栏与 Widget 路径。设置保留直接连接入口、平台图标，以及“连接 → 提醒 → 显示 → 通用”排序。
- DeepSeek 柱子可查看时段和金额。胶囊拖到刘海、刘海向下拖回胶囊形成双向操作；Codex 刘海可选上下 5h/7d 或单额度。双额度详情去掉无效下拉框，恢复平滑展开并尊重减少动态效果。
- 关于更新重点已同步本轮能力；修正英文图标/标题裁切，补充中英文默认/最小尺寸滚动检查。
- Windows 保持现有 Codex 界面；OAuth/额度请求改用 Electron 系统网络，并为 403 增加网络路径提示。朋友机器登录**尚未复测**，不能声称 403 已修好；Windows 不包含本次 macOS 的 DeepSeek/刘海新界面。

验证：dev.23 完整 332 Core +172 App（504 项）测试通过，Windows check/smoke/UI-smoke 通过。用户批准钥匙串访问后，Mac 原 Codex/DeepSeek 连接均能刷新，用户已确认真实下拉刘海、左右贴边首次拖出、卡片标题拖动、同屏全屏隐藏/恢复及 DeepSeek 悬停/移开详情。公开源码、安装包与远端验证另见 QA。

macOS 仍采用既有稳定自签名预览流程，支持 Apple 芯片、macOS 14+，不是 Developer ID 签名或公证包。更新可能需要正常钥匙串确认，不重设凭据。其他设备、完整 VoiceOver、真实账号替换及保留核对表剩余项尚未全面验收；本次发布准备未消费真实重置卡。
