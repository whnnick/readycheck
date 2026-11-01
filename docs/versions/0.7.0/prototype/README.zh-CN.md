# ReadyCheck 0.7.0-preview.5 — 用量聚合交互原型

2026-10-31 交互修正原型：恢复“设置 → 提醒 / 显示 / 连接 / 通用”，在连接与提醒栏目内选择平台；总览快捷入口、通知详情与设置页共享同一份数值。未连接时仍显示 Codex、DeepSeek；DeepSeek 可在总览直接连接，固定且写明目的地的返回按钮恢复来源页面、平台、时间范围与滚动位置。表单与规则均使用合成数据，不改变真实凭据、原生应用或系统设置。仅通用设置正文演示语言切换。详见[交互修正规划](../INTERACTION_REPLAN.zh-CN.md)。

[English](README.md) · [版本计划](../PLAN.zh-CN.md) · [黑盒检查](../QA.zh-CN.md) · [视觉对照](design-qa.md)

依据用户确认的浅色桌面稿制作的独立本地原型。顶部服务标签缩小为低频控件，额度与趋势作为视觉重点；不替换安装版或任何原生功能。

## 可体验的路径

- 切换 Codex / DeepSeek，使用原型专属浏览器存储记住上次选择。
- 区分订阅剩余百分比、本机观测的额度下降百分点、官方 Token 示例和余额，单位不混加。
- 切换图表范围，通过悬停或键盘查看数值。
- 展开账户权益和重置卡记录，查看通知筛选、重置说明和数据来源。
- 打开“更多平台”：搜索十家已确认目标，按两批各五家筛选；已支持服务直接管理连接，待接入服务保留说明；返回目录时保留搜索与滚动。顶部两家已支持服务不因未连接而消失。
- 设置恢复四个熟悉栏目，提供按平台的提醒、显示控件及跟随系统/浅色/深色外观。实际提醒规则、钥匙串、账号历史和自动用卡授权均未改动。

## 目录和素材来源

目录参照 [CodexBar 服务列表](https://github.com/steipete/CodexBar/blob/main/README.md#providers)，核对日期 2026-10-30。用户已将调研范围收敛为十家目标，原 110 项目录不再沿用。十家目标不代表十家已经接入；详见[两批实施矩阵](../TECHNICAL.zh-CN.md)。指标和方式只是发现读取路径的线索；开发仍需逐家核对官方依据、账号适用权限并做真实只读验收。现有 Codex 仍保留 OAuth 单一主登录；本概念的 DeepSeek 仅演示余额，Claude/Gemini 明示未验证。详见[来源说明](../SOURCES.md)。

ReadyCheck 图标取自仓库现有素材；DeepSeek、Claude 和 Gemini 标志来自 Simple Icons。所选概念在 Codex 名称旁使用 ReadyCheck 标志作为原型标识，不代表官方 Codex 标志。通用控件使用 Phosphor 图标；图表由 Recharts 实时渲染。`evidence/selected-light.png` 是已选择的生成稿，使用合成数据；浏览器截图和对照图不含真实账号或额度。

## 本地开发

```sh
npm install --prefer-offline --no-audit --no-fund
npm run dev -- --host 127.0.0.1 --port 4335 --strictPort
npm run build
npm run test:catalog
npm run test:sites
```

构建、4 项目录范围测试和 4 项宿主运行时检查通过。构建有一个超过 Vite 建议大小的前端块，属于原型后续优化，不是原生包体积变化；未部署。原生应用、新服务后端、Windows 迁移和真实接入验收仍待开发。
