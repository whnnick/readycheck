# 0.1.145 黑盒验收

[English](QA.md) · [需求](PLAN.zh-CN.md) · [版本索引](../../VERSIONS.md)

状态：2026年10月13日原生边缘修复、回归、稳定签名安装、中英文GitHub首页及公开0.1.145发布验收完成。

| 需求 | 状态与证据 |
| --- | --- |
| 弧线边缘 | 在当前2×屏幕检查安装版0.1.145圆球、展开及贴边形态。原生遮罩以backing两倍分辨率超采样后合成，轮廓路径和视图尺寸未变。 |
| 直接拖动 | 安装版从展开圆盘直接拖入右侧贴边竖条；既有左右拖动和几何回归通过。 |
| 固定与按钮 | 安装版详情显示固定状态且没有减号。固定后外部/失焦、取消固定controller回归通过；不声称新增每种焦点/Spaces场景的手工验收。 |
| 回归 | 5项EdgeRail限定测试和全部278项Swift测试通过，零失败、零跳过。遮罩渲染不得低于显示器分辨率，光栅化与渲染分辨率需一致。 |
| 安装 | 完整旧应用备份后安装0.1.145，ReadyCheck Preview Signing和严格签名核验通过。用户完成系统验证，重试读取后真实额度恢复。 |
| 首页 | 最新原生演示资产及中英文README已完成；GitHub Markdown API渲染的本地1280像素桌面与390像素手机预览中，图片全部加载、无页面横向溢出。详情用窗口backing宿主保留原生滚动区，圆球/贴边用4× ImageRenderer。真实GitHub中英文页面的当前原生素材显示正确；390像素中文版无横向溢出且图片全部加载。仓库About已双语更新，保留原有项目网站入口。 |
| 公开发布 | 安全公开源码/历史、Mac DMG及Windows ZIP、签名tag、Release/latest、对应源码Windows CI及实际回下载哈希已验证，详见下方。 |

已完成：限定原生轮廓调整、5项限定与278项全量回归、版本一致性、稳定签名本机安装及上表原生检查、中英文公开首页和发布/下载验收。圆环尺寸、额度计算、固定逻辑、拖动及基础轮廓路径未变；Windows仅同步版本信息。

部分完成：真实环境覆盖。实际2×截图含真实额度，仅在本地检查，不作为公开资产；组件演示导出不替代真实窗口合成验收。

未完成：真实1×外接屏、多屏移动、macOS14设备、广泛Spaces/性能条件。

验证命令：`swift test --build-system native --scratch-path <临时目录>`、`scripts/check_release_consistency.sh`、`scripts/package_app.sh`、严格`codesign`、原生截图检查及`git diff --check`。首次受限调用在编译器缓存写入阶段失败，没有运行测试；成功调用使用正常本机权限，不从该环境失败推断测试结果。

遮罩分辨率跟随窗口backing变化；Core Animation分辨率语义见[Apple文档](https://developer.apple.com/documentation/quartzcore/calayer/rasterizationscale)。相同184×184截图的外沿区域对照确认边缘覆盖有变化、轮廓未移动；此为诊断证据，不代表所有显示器均已视觉验收。

本次已验证预览版无剩余发布阻塞。预览签名不等同Developer ID或公证，上述真实环境覆盖边界仍保留。

原生组件演示：[详情](assets/details-zh.png)、[80%圆球](assets/compact-80.png)、[5%圆球](assets/compact-5.png)、[贴边](assets/edge-right.png)；[来源与哈希](assets/provenance.json)。全部读数均为合成数据。

公开源码测试记录：首次运行出现既有app-server初始化拒绝测试的1秒超时，并有一项固定窗口焦点测试跳过；紧接着单独复核的3项monitor测试全部通过。最终公开源码全量运行278项测试，零失败、零跳过；没有改动无关生产逻辑或测试超时。

[0.1.145 Release](https://github.com/whnnick/readycheck/releases/tag/v0.1.145)已确认为latest，非草稿、非预发布，恰有两个资产。签名tag `v0.1.145`指向源码`3e57811e1968f39dc3ffbfe45b7ff4b08a3b2444`；边缘修复与首页分别采用独立双语提交。Windows工作流[38390669915](https://github.com/whnnick/readycheck/actions/runs/38390669915)使用该精确head SHA构建并成功。公开源码与审查后的开发文件一致，公开历史敏感检查排除了内部协作文件及私有素材。

双平台资产均实际回下载，并与GitHub SHA-256一致。回下载Mac DMG挂载后版本为0.1.145，稳定签名严格核验通过。回下载Windows ZIP完整性通过，内部应用版本为0.1.145，不含内部协作文件；其app.asar哈希与本地验证构建相同。公开ZIP由CI产生，完整ZIP字节与本地构建有所不同。

- [macOS DMG](https://github.com/whnnick/readycheck/releases/download/v0.1.145/ReadyCheck-0.1.145-macos.dmg)：`7e1641967422e5e0ad3942626a903eecdbf72028772002316c814abed5e8a2c2`
- [Windows便携ZIP](https://github.com/whnnick/readycheck/releases/download/v0.1.145/ReadyCheck-0.1.145-windows-x64-portable.zip)：`e43683bd0f862d11abdefb35e3a91f17a750dae349a15d406a608e449c73f15a`
