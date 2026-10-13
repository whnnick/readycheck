# 0.1.143 黑盒验收

[English](QA.md) · [需求](PLAN.zh-CN.md) · [版本索引](../../VERSIONS.md)

状态：2026年10月13日0.1.143已完成本机安装及视觉验收。

![80%匿名原生组件](assets/compact-80-demo.png)

[100%](assets/compact-100-demo.png) · [零值](assets/compact-zero-demo.png) · [未知](assets/compact-unknown-demo.png)。以上是实际SwiftUI组件及合成额度，不是实时账号截图。

| 需求 | 状态与证据 |
| --- | --- |
| 数字不压线 | 实际SwiftUI组件的80%、100%、0%及未知状态匿名渲染已生成并目视检查通过，数字不压内圈。安装版实际圆球也已检查。 |
| 标志比例 | 收起时C标志从24点缩到18点，向上偏移10点；数字11点、向下偏移8点。展开终态的标志大小及中心不变。 |
| 范围 | 圆环、外壳几何、数据处理和拖动交互未修改；展开中英文原生渲染保留。 |
| 本机安装 | 标准脚本及稳定预览签名构建0.1.143；暂存和安装应用严格签名校验通过，可执行SHA-256一致，旧应用保留备份。用户完成系统钥匙串验证后额度读取恢复，09:56北京时间新鲜读数及圆球/详情均已检查。 |

验证：全量273项Swift测试通过，无失败/跳过；原生渲染检查通过；版本一致性、文档链接、差异空白及敏感信息检查通过。命令：`swift test --build-system native --scratch-path <临时目录>`、`scripts/check_release_consistency.sh`、`scripts/package_app.sh`、`codesign --verify --deep --strict`。

已完成：紧凑布局、80/100/0/未知原生渲染、本机安装与视觉验收、账号恢复及中英文文档。本次包含[0.1.142直接拖动验收](../0.1.142/QA.zh-CN.md)。真实环境待验收：其他屏幕缩放及macOS14设备，Windows无新增行为及实机验收。

最终公开快照：全量273项Swift测试通过，无失败/跳过；Node24的Windows语法/功能/界面检查及打包通过。DMG挂载后应用版本0.1.143、稳定预览签名严格验证通过；Windows ZIP完整性通过，ASAR版本0.1.143，包内没有测试、内部协作目录或依赖开发目录。最终产物目录只有当前DMG和Windows ZIP。公开源码及公开祖先历史敏感检查通过；命中的五处私人路径形式均为扫描脚本自身的正则表达式，没有实际私人路径或凭据。

公开发布已完成：[0.1.143 Release](https://github.com/whnnick/readycheck/releases/tag/v0.1.143)。公开注释标签对应源码`f71a656ce3b120bed4d1a95683d8f06bc7907c95`，latest为v0.1.143，非草稿/非预发布，且仅有两个上传完成的安装包。Windows工作流[38335610302](https://github.com/whnnick/readycheck/actions/runs/38335610302)从同一源码构建并上传成功。两个远端文件均已实际下载，大小及SHA-256匹配GitHub摘要；远端Windows ZIP完整性、ASAR版本及内容也已检查。公开下载链接均返回HTTP200。本次预览发布无未完成项或发布阻塞项。

- macOS DMG SHA-256：`34b31a3aa5066a7194cd19b54501936b3ae440007150d5007fb030edf0b4daf2`
- Windows ZIP SHA-256：`958d822c66768fa76d750f356caae6b8608c6fb7703ab924b62fc34ae2b409fa`
