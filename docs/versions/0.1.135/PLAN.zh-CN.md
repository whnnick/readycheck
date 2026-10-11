# 0.1.135：全屏避让与Token对比

[English](PLAN.md) · [黑盒验收](QA.zh-CN.md) · [版本索引](../../VERSIONS.md)

目标：减少浮窗遮挡，直观看懂Token使用变化。

| 需求 | 范围与成功标准 |
| --- | --- |
| 全屏隐藏 | 默认开启并保存开关，作用于气泡、卡片、贴边圆环和刘海。原生全屏桌面隐藏，返回桌面恢复原位置；普通最大化窗口不在范围。监控、通知权限与手动临时隐藏截止时间保持不变。使用系统窗口行为，不请求屏幕读取权限、不使用私有接口。 |
| 每日与每周对比 | 今天截至刷新对比昨天全天；最近7个完整UTC日对比之前7天。明确今天尚未结束及日期口径；每个日期均有有效桶才计算合计/变化。缺失、负值、非法或重复日期保留未知。明确返回的零有效，上期为零不计算百分比。 |
| Token悬停 | 保留准确日期、Token数量，增加与前一天的变化；缺失前一天不当作零。 |
| 交互验收 | 检查短暂/连续悬停、移开与重新移入、主动关闭、拖动抑制和到期等待新数据。切换桌面取消悬停和展开意图，保留全部样式。 |

不新增提供商、模型调用、轮询、预测或通知缓存清理。Windows只同步版本号。测试、本机验收、打包与公开同步检查后发布中英文GitHub Release。

参考：[Apple窗口行为](https://developer.apple.com/documentation/appkit/nswindow/collectionbehavior-swift.struct)、[桌面切换通知](https://developer.apple.com/documentation/appkit/nsworkspace/activespacedidchangenotification)。
