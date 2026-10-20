# 额度节奏交互预览

[English](README.md) · [产品计划](../PLAN.zh-CN.md) · [功能检查](../QA.zh-CN.md) · [视觉验收](design-qa.md)

0.3.0-preview.1。基于现有原生总览的深色布局和品牌素材，验证“按当前速度能否撑到重置”，不是已接入真实数据的产品。

运行 `npm install`、`npm run dev -- --host 127.0.0.1 --port 4332 --strictPort`。检查：`npm run test:pace`、`npm run build`、`npm run test:sites`。

顶部可切换七种场景、中英文和三种入口；设置可改5/10/20%阈值，查看通知示例；所有选择只影响本页。估算依赖近期速度不变，不是使用时长承诺。所有数据与截图均为合成；保留现有原生应用及配置。公开下载仍为0.2.1。

完整旧功能以[旧功能保留清单](../FEATURE_RETENTION.zh-CN.md)为准。当前网页没有完整展示显示／连接／通用设置、通知记录及全部Token图表，不代表这些能力被删除或允许删除；正式集成必须逐项保留验收。
