# ReadyCheck 0.2.0 交互演示

[English](README.md) · [产品计划](../PLAN.zh-CN.md) · [验收边界](../QA.zh-CN.md)

这是用户选定侧栏方案的可点击网页演示，不是已安装原生应用。版本为 `0.2.0-preview.3`。页面和原生组件参考图全部使用合成数据。

```sh
npm ci --prefer-offline --no-audit --no-fund
npm run dev -- --host 127.0.0.1 --port 4331 --strictPort
```

打开终端显示的本机地址。通过“总览／用量／设置”导航；左下角“演示场景”可切换正常、低额度、恢复、断网、过旧、需要授权、暂无数据。

- 总览：双额度、状态、刷新、管理提醒和图表键盘读数。
- 用量：7/30/90 天及不完整记录说明；Token 不换算额度。
- 设置：提醒阈值、恢复开关、模拟权限/测试提示、原生样式参考、主显示选择、浮窗读数及固定/隐藏交互。
- 账号与数据：状态详情、用户主动修复、旧套餐资料分层。

不连接真实服务或修改系统。固定/取消固定在页内演示；外观参考图与交互预览分别标注，置顶/全屏只演示设置状态。真实升级、通知投递、钥匙串、多屏和拖动待原生实现验收。页面刷新会重置选择。

检查：`npm run build`。继承模板的 `npm run test:sites` 仅检查静态托管适配，不代表业务或原生功能验收。没有部署。

设计参考为 [overview-concept.png](../assets/overview-concept.png)，最终页面见[总览](../assets/overview-preview.png)、[提醒](../assets/reminders-preview.png)、[用量](../assets/usage-preview.png)。本机详细比对记录见 [design-qa.md](design-qa.md)；`qa/` 是被忽略的本地截图目录。

[跨版本检查](../UPGRADE_REVIEW.zh-CN.md) · [五状态效果稿](public/assets/widget-notch-concept.png)。演示中打开“设置 → 显示 → 查看 widget 与刘海方案”。画稿是视觉规范，不代表原生刘海功能已实现。
