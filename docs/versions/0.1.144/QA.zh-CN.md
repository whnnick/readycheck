# 0.1.144 黑盒验收

[English](QA.md) · [需求](PLAN.zh-CN.md) · [版本索引](../../VERSIONS.md)

状态：2026年10月13日0.1.144本地修复、回归检查、打包、安装及部分原生UI操作验收已完成。公开[0.1.144 Release](https://github.com/whnnick/readycheck/releases/tag/v0.1.144)、latest、源码测试、CI及回下载包均已验证。

| 需求 | 状态与证据 |
| --- | --- |
| 固定后点击桌面 | 已有controller回归覆盖通过。本版本未另做桌面空白处手工点击，保留为安装版扩展抽查。 |
| 固定后切换其他应用 | 原生UI验收通过：从贴边竖条点击展开并固定，点击Chrome原生Play按钮、地址栏及切换浏览器焦点后，详情仍保持展开。 |
| 固定后点击本应用其他窗口 | 已有controller回归覆盖通过。本版本未另做ReadyCheck其他窗口手工点击，保留为扩展抽查。 |
| 取消固定与悬停 | 原生UI验收通过：取消固定恢复既有悬停预览，指针在外时收回；controller回归覆盖也通过。 |
| Esc | 已有controller覆盖通过。本版本未另做Esc手工验收；详情获得焦点后Esc及避免立即重开保留为扩展抽查。 |
| 按钮与提示 | 原生UI确认详情减号不存在、Bubble新提示已生效；Bubble提示与EdgeRail样式语义分开处理。更完整的中英文提示检查保留为扩展手工抽查。 |
| 几何与拖动 | 限定16项及最终全量测试通过；实际固定展开窗口截图为1000 × 496像素、2×，对应500 × 248点。保持圆球几何和既有拖动行为；测试通过不代表已新增每种屏幕条件下的手工拖动验收。 |
| Windows版本 | 公开CI构建的Windows ZIP版本为0.1.144；实际回下载文件SHA-256与GitHub资产摘要一致，ZIP完整性通过，共78个条目。本版本Windows仅同步版本信息。 |
| 本机安装 | macOS DMG版本为0.1.144，ReadyCheck Preview Signing严格签名及哈希检查通过。应用已安装到“应用程序”，原0.1.143完整应用保留为本地私有备份。用户再次完成Keychain“始终允许”验证后，真实额度读取已恢复。 |

回归证据：5个新增controller回归先红灯重现固定详情失焦收起；修复后限定16项全部通过，0失败、0跳过。

全量证据：第一次278项测试有1项失败，`EdgeRailWidgetTests.testBubbleWindowContentFollowsEdgeAndExpandedSizes`的hosting bounds为476 × 243，未达到预期500 × 248；当时同时进行macOS和Windows打包。打包负载结束后，13:24北京时间完整复核278/278通过，0失败、0跳过。公开源码复核随后观测到面板和容器已达到500 × 248，而宿主仍为472 × 242。尺寸测试现改为最多等待1秒的实际AppKit内容子树布局就绪，保留全部目标尺寸断言，生产几何和动画没有改变。6项限定测试通过，14:04的公开源码完整278项测试全部通过，零失败、零跳过。实际布局滞后支持此次测试修复；并行打包并未被证明是根因，首次失败记录仍保留。

源码中用于8× ImageRenderer高分辨率采集的临时改动已全部精确恢复。包含真实额度的原生UI截图只保留在本地，不复制到公开文档。高分辨率合成数据fixture可用于公开视觉证据；本文件不发布私有截图或本地备份路径。

已完成：固定修复、按钮与提示调整；5项修复前失败重现；限定16项controller测试、6项尺寸测试及最终公开源码全量278项测试；版本一致性；本地Mac/Windows包版本、Mac严格签名、ZIP完整性和哈希；本机安装、Keychain恢复及上表明确列出的Chrome交互、取消固定、按钮和提示原生验收；公开源码/历史隐私检查、CI、Release/latest及实际回下载/哈希/ZIP验收。

部分完成：真实环境验收。安装版已检查从贴边竖条展开、固定、Chrome交互/焦点变化、取消固定、减号移除及Bubble提示。剩余交互由controller自动覆盖支持，但不代替逐项新增手工验收。

未完成：本版本新增桌面空白、本应用其他窗口及详情获得焦点后Esc手工检查；多屏、Spaces和更广泛屏幕缩放抽查。

负责相应步骤的验证已使用`swift test --build-system native --scratch-path <临时目录>`、`scripts/check_release_consistency.sh`、`scripts/package_app.sh`、`scripts/package_dmg.sh`、`codesign --verify --deep --strict`、`zip -T`及SHA-256检查。本记录不包含本地私有路径、真实账号读数或私有截图；公开包哈希及发布证据记录于下文。

真实环境待验收：上述待补手工场景，包括桌面/ReadyCheck其他窗口焦点变化、详情获得焦点后Esc、多屏、Spaces及相关屏幕缩放。

公开发布已完成：[0.1.144 Release](https://github.com/whnnick/readycheck/releases/tag/v0.1.144)。发布时公开main和注释标签`v0.1.144`指向源码`b43111450cf60236ea610f400e2041ccd9d1c7c3`，与开发实现一致。公开源码及可见历史隐私扫描通过，无新增私有素材、凭据或内部开发材料。Release非草稿、非预发布且为latest，恰有两个上传完成的资产。Windows工作流[38355594858](https://github.com/whnnick/readycheck/actions/runs/38355594858)以该精确head SHA完成并成功。

两个公开安装包均已实际回下载，SHA-256与GitHub资产摘要完全一致；Windows下载ZIP完整性通过，共78个条目。公开macOS DMG挂载后，0.1.144应用包通过ReadyCheck Preview Signing严格签名验证。下列Windows哈希对应公开CI资产，不是此前的本地Windows构建。

- [macOS DMG](https://github.com/whnnick/readycheck/releases/download/v0.1.144/ReadyCheck-0.1.144-macos.dmg) SHA-256：`b6bf4b889562a5c741bdd7f336bf58309282fdf256c51c0d8c93980f7de8312b`
- [Windows便携ZIP](https://github.com/whnnick/readycheck/releases/download/v0.1.144/ReadyCheck-0.1.144-windows-x64-portable.zip) SHA-256：`e5b5cd570d83a71b5d3a589de103b27520e5b3e3adc7fc212443d87e74fac5d5`

公开发布阻塞项：本次已验证发布没有剩余阻塞项；上述待补手工场景继续作为真实环境覆盖边界明确保留。
