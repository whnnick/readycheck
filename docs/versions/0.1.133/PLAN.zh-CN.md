# 0.1.133 通知图标刷新

[English](PLAN.md) | [验收](QA.zh-CN.md)

范围：修复 C 应用图标更新后，macOS 系统提醒仍读取旧图标的问题。保留 bundle ID、签名身份、登录凭据、通知权限和既有提醒。不推送 GitHub 或发布 Release；Windows 仅同步版本号。

证据：已安装 0.1.132 的 ICNS 已是 C 图形，系统仍登记多份 ReadyCheck 旧副本；系统通知设置已显示 C，新的测试通知投递成功。这些证据支持系统查找或缓存未及时更新的推断，不能证明全部历史通知已重绘。

最小修改：图标文件名包含 ICNS 内容哈希，Info.plist 引用该准确文件；ICNS 转换失败时打包失败。创建通知客户端前，通过 LSRegisterURL(update: true) 登记当前运行应用。不用附件代替应用身份图标，不清空系统通知数据库。

验证版本一致性、Swift 测试、打包图标各尺寸、签名与身份连续性；将完整签名应用安装到原位置，确认已保存登录仍刷新、通知配置保留，再观察新测试提醒图标。系统保留的历史提醒单独记录验收状态。

参考：[Apple 图标声明](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html)、[LSRegisterURL](https://developer.apple.com/documentation/coreservices/1446350-lsregisterurl)。
