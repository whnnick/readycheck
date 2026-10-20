# 0.3.0 发布功能保留审计

[English](RELEASE_AUDIT.md) · [中文](RELEASE_AUDIT.zh-CN.md) · [Checks / 验收](QA.md) · [Itemized evidence / 逐项证据](retention-release-audit.json)

65项受保护能力逐项记录了具体功能测试和可发现入口。这里是有范围的保留证据，不声称覆盖每种设备条件；旧实机结果仅用于行为未改变的路径。菜单实机检查仍未验证，已被接受为发布限制，见QA中的最新范围决定；产物及远端交付检查已完成，见QA。

| ID | Capability / 能力 | Entry / 入口 | Specific functional check / 具体功能检查 | Status / 状态 |
| --- | --- | --- | --- | --- |
| A01 | 5小时额度百分比、进度与未知态 | 总览／桌面／菜单栏 | [testSnapshotSuppressesPercentagesWhenUnavailableWithDisplayableWindow](../../../Tests/ReadyCheckCoreTests/QuotaModelsTests.swift) | 已保留（限定验收范围） |
| A02 | 7天额度百分比、进度与未知态 | 总览／桌面／菜单栏 | [testShowsSevenDayWindow](../../../Tests/ReadyCheckCoreTests/QuotaWindowPresentationTests.swift) | 已保留（限定验收范围） |
| A03 | 距重置倒计时与完整重置日期时间 | 总览／紧凑额度行 | [testFormatsMinuteHourAndDayIntervalsInBothLanguages](../../../Tests/ReadyCheckCoreTests/QuotaResetCountdownTests.swift) | 已保留（限定验收范围） |
| A04 | 自动／指定主显示额度，缺失不偷换、选择持久化 | 设置→显示／刘海详情 | [testMissingExplicitSelectionKeepsUnknownPrimaryAndOtherWindowsVisible](../../../Tests/ReadyCheckCoreTests/NotchQuotaSelectionTests.swift) | 已保留（限定验收范围） |
| A05 | 普通使用允许、受限原因及额度不足状态 | 总览／紧凑入口 | [testAvailabilityCannotTreatBlockedUnknownOrCachedAsCurrentPermission](../../../Tests/ReadyCheckCoreTests/QuotaModelsTests.swift) | 已保留（限定验收范围） |
| A06 | 数据来源、上次成功／尝试时间与故障说明 | 数据状态弹窗 | [testMissingFieldsDoNotInvalidateQuotaOrInventSubscriptionDates](../../../Tests/ReadyCheckCoreTests/QuotaDataDiagnosticsTests.swift) | 已保留（限定验收范围） |
| A07 | 手动刷新、刷新中防重入及安全只读刷新 | 各刷新入口 | [testManualRefreshIsAlwaysAllowedBeforeInterval](../../../Tests/ReadyCheckCoreTests/RefreshSchedulerTests.swift) | 已保留（限定验收范围） |
| A08 | 1／3／5分钟刷新设置、本机事件与唤醒后刷新 | 设置→通用／应用生命周期 | [testWakeCallbackRefreshesConnectionAndFreshQuotaWithoutLaunchingHost](../../../Tests/ReadyCheckAppTests/ConnectionReloadTests.swift) | 已保留（限定验收范围） |
| B01 | 套餐名称、未知值不猜测 | 总览→账户与权益 | [testAccountBenefitsPreserveKnownZeroUnknownAndPartialDetails](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| B02 | 订阅有效期、过期日期标历史记录 | 总览→账户与权益 | [testPastSubscriptionDateIsExplainedAsHistorical](../../../Tests/ReadyCheckCoreTests/QuotaDataDiagnosticsTests.swift) | 已保留（限定验收范围） |
| B03 | 订阅日期缺失时的账单查看链接 | 总览→账户与权益 | [testAccountBenefitsPreserveKnownZeroUnknownAndPartialDetails](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| B04 | Credits数字、无限与未提供分别表示 | 总览→账户与权益 | [testParserExtractsNumericAndUnlimitedCodexCredits](../../../Tests/ReadyCheckCoreTests/CodexUsageParserTests.swift) | 已保留（限定验收范围） |
| B05 | 主动重置次数：零与未知分开 | 总览→账户与权益 | [testAccountBenefitsPreserveKnownZeroUnknownAndPartialDetails](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| B06 | 每次重置到期时间、部分缺失占位及GMT+8 | 总览→账户与权益 | [testAccountBenefitsPreserveKnownZeroUnknownAndPartialDetails](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| C01 | 本机额度消耗24小时／7天／30天范围 | 总览→额度消耗 | [testRetainsThirtyDaysAndPersistsToDisk](../../../Tests/ReadyCheckCoreTests/QuotaHistoryStoreTests.swift) | 已保留（限定验收范围） |
| C02 | 历史图选择不同额度窗口 | 总览→额度消耗 | [testExpandedWidgetRetainsSelectedLastHourConsumptionWithoutFallback](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| C03 | 额度柱子悬停／点击、时段与百分点提示及边界 | 总览→额度消耗 | [testTooltipStaysInsidePlotAtBothEdges](../../../Tests/ReadyCheckAppTests/LocalQuotaUsageChartTests.swift) | 已保留（限定验收范围） |
| C04 | 历史按账号隔离、A→B→A与旧历史保全 | 总览／历史存储 | [testAccountSwitchAndRestartKeepIndependentHistory](../../../Tests/ReadyCheckCoreTests/QuotaHistoryStoreTests.swift) | 已保留（限定验收范围） |
| C05 | 重置、回升、无效／缺失及长间隔不计为消耗 | 额度聚合与Widget图 | [testAttributesOnlyVerifiedDecreasesInsideMaximumGap](../../../Tests/ReadyCheckCoreTests/QuotaUsageAggregationTests.swift) | 已保留（限定验收范围） |
| C06 | 官方每日Token图：7／30／90天范围 | Token用量页 | [testSparseQuotaChartsAndTokenEmptyStateRenderAtMinimumWidth](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| C07 | 累计Token、单日峰值与连续使用天数 | Token用量页 | [testNativePagesRenderAtMinimumSizeWithSyntheticData](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| C08 | 今天／昨天及两段7天比较、覆盖不足与零基线 | Token用量页 | [testMissingDayIsNotZeroAndExplicitZeroHasNoPercentageBaseline](../../../Tests/ReadyCheckCoreTests/TokenUsageComparisonTests.swift) | 已保留（限定验收范围） |
| C09 | Token按UTC日期统计、柱子详情、缺失不填零且不换算额度 | Token用量页 | [testDateBoundariesUseOfficialUTCDateRegardlessOfLocalTimezone](../../../Tests/ReadyCheckCoreTests/TokenUsageComparisonTests.swift) | 已保留（限定验收范围） |
| D01 | 关闭／5%／10%／20%低额度提醒 | 设置→提醒 | [testOldReminderStateStillDecodesWithAlertsOff](../../../Tests/ReadyCheckCoreTests/LowQuotaReminderTests.swift) | 已保留（限定验收范围） |
| D02 | 实际跨线、首次基线、同账号窗口周期去重及失败重试 | 低额度求值／通知 | [testFivePercentCrossingAndRestartDoNotReplayDelivery](../../../Tests/ReadyCheckCoreTests/LowQuotaReminderTests.swift) | 已保留（限定验收范围） |
| D03 | 恢复提醒开关、实际恢复确认、非单纯等时钟 | 设置→提醒／恢复求值 | [testWaitsForAllWindowsAndActualFreshRecovery](../../../Tests/ReadyCheckCoreTests/QuotaRecoveryReminderTests.swift) | 已保留（限定验收范围） |
| D04 | 恢复通知继续使用后撤回、取消保护与重启去重 | 通知服务／记录 | [testRecoveryNotificationDismissesWhenQuotaStartsBeingUsed](../../../Tests/ReadyCheckCoreTests/QuotaRecoveryReminderTests.swift) | 已保留（限定验收范围） |
| D05 | 主动重置到期前72／48／24／12小时提醒 | 后台提醒／通知历史 | [testManualResetExpirationNotifiesAtEachThreshold](../../../Tests/ReadyCheckCoreTests/QuotaReminderTests.swift) | 已保留（限定验收范围） |
| D06 | 耗尽后检测到Credits开始消耗时提醒 | 后台提醒／通知历史 | [testCreditsReminderTriggersOncePerExhaustedQuotaCycle](../../../Tests/ReadyCheckCoreTests/QuotaReminderTests.swift) | 已保留（限定验收范围） |
| D07 | 真实通知权限／样式状态与系统设置入口 | 设置→提醒 | [testPersistentAndTemporaryAlertsAreDistinct](../../../Tests/ReadyCheckCoreTests/NotificationReadinessTests.swift) | 已保留（限定验收范围） |
| D08 | 测试通知、投递状态与通知中心核验 | 设置→提醒 | [testExistingLowQuotaNotificationDoesNotProduceAnotherBanner](../../../Tests/ReadyCheckAppTests/QuotaNotificationServiceTests.swift) | 已保留（限定验收范围） |
| D09 | 通知记录摘要、全部记录及成功／失败／撤回状态持久化 | 设置→提醒→通知记录 | [testStoreRecordsFailedAttemptThenConfirmedDelivery](../../../Tests/ReadyCheckCoreTests/QuotaReminderTests.swift) | 已保留（限定验收范围） |
| E01 | 统一悬浮Widget的圆球与细窄竖条两种位置形态 | 桌面／设置→显示 | [testUnifiedWidgetRestoresAttachedStripAndOpensSharedPinnedDetails](../../../Tests/ReadyCheckAppTests/BubbleWindowControllerTests.swift) | 已保留（限定验收范围） |
| E02 | 左右贴边、首次直接向内拖动及位置保存 | 悬浮Widget | [testHorizontalDragKeepsTrackingOutsideNarrowRailInBothDirections](../../../Tests/ReadyCheckAppTests/BubbleWidgetPanelTests.swift) | 已保留（限定验收范围） |
| E03 | 悬停预览、点击固定、外部点击保持；取消后恢复预览与Esc | Widget详情 | [testPinToggleKeepsOpenAndUnpinRestoresExitDismissal](../../../Tests/ReadyCheckAppTests/WidgetInteractionControllerTests.swift) | 已保留（限定验收范围） |
| E04 | Widget双额度与最近1小时／每柱5分钟消耗图 | Widget详情 | [testExpandedWidgetRetainsSelectedLastHourConsumptionWithoutFallback](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| E05 | 卡片标题自由拖动、按钮独立、位置保存 | 信息卡片 | [testCardHeaderProvidesDragRegionAndRestoresMovedPosition](../../../Tests/ReadyCheckAppTests/FloatingWidgetDragTests.swift) | 已保留（限定验收范围） |
| E06 | 卡片精简／详细显示模式 | 设置→显示／卡片切换 | [testNativePagesRenderAtMinimumSizeWithSyntheticData](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| E07 | Widget显示／隐藏、重启保持及隐藏后的恢复入口 | 设置／菜单栏／Widget菜单 | [testExplicitHideRemainsHiddenAfterModelRecreation](../../../Tests/ReadyCheckAppTests/WidgetVisibilityLifecycleTests.swift) | 已保留（限定验收范围） |
| E08 | 窗口置顶独立于固定展开和自由移动 | 设置→显示 | [testCardHeaderProvidesDragRegionAndRestoresMovedPosition](../../../Tests/ReadyCheckAppTests/FloatingWidgetDragTests.swift) | 已保留（限定验收范围） |
| E09 | 临时隐藏30／60分钟、恢复时间及立即恢复 | 设置→显示／桌面控制 | [testRestartRetainsDeadlineAndResumeClearsIt](../../../Tests/ReadyCheckCoreTests/WidgetSnoozePreferenceTests.swift) | 已保留（限定验收范围） |
| E10 | 重置Widget位置与无效／离屏位置恢复 | 设置→显示 | [testDisconnectedDisplayFrameMovesInsideRemainingScreen](../../../Tests/ReadyCheckCoreTests/FloatingWidgetPlacementTests.swift) | 已保留（限定验收范围） |
| E11 | 全屏隐藏／返回恢复与现有Spaces层级策略 | 设置→显示／窗口策略 | [testFullscreenPolicyKeepsStationaryPlacementAndExcludesFullscreenSpaces](../../../Tests/ReadyCheckAppTests/WidgetSpaceBehaviorTests.swift) | 已保留（限定验收范围） |
| E12 | 刘海开关、设备可用性、连接物理刘海且只点击展开 | 设置→显示／刘海 | [testBothStatesOverlapPhysicalNotchBottomWithoutAGap](../../../Tests/ReadyCheckCoreTests/NotchStatusPlacementTests.swift) | 已保留（限定验收范围） |
| E13 | 刘海额度选择、未知态、详情、打开总览与外部／Esc收起 | 刘海详情 | [testClickHoldAndOutsideDismissKeepBothFramesAttachedAndCloseCleanly](../../../Tests/ReadyCheckAppTests/NotchWindowControllerTests.swift) | 已保留（限定验收范围） |
| F01 | 菜单栏图标状态、双额度／重置及账号摘要 | 菜单栏 | [testMenuAndNotchRenderWithSyntheticVerifiedAccount](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 实机未验（接受为发布限制）核验 |
| F02 | 菜单栏数据状态、刷新及打开主窗口 | 菜单栏 | [testMenuAndNotchRenderWithSyntheticVerifiedAccount](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 实机未验（接受为发布限制）核验 |
| F03 | 菜单栏Widget开关与提醒入口 | 菜单栏 | [testMenuAndNotchRenderWithSyntheticVerifiedAccount](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 实机未验（接受为发布限制）核验 |
| F04 | 更多菜单：显示／连接／通用／关于／退出 | 菜单栏→更多 | [testBothLanguagesRetainLocalizedNavigationAndNativeFullScreenShortcut](../../../Tests/ReadyCheckAppTests/MainMenuTests.swift) | 实机未验（接受为发布限制）核验 |
| G01 | 跟随本机Codex／单独OAuth账号及当前身份 | 设置→连接 | [testLateStoredCredentialCannotReplaceLocalAccount](../../../Tests/ReadyCheckAppTests/ConnectionReloadTests.swift) | 已保留（限定验收范围） |
| G02 | 连接、取消授权、更换授权与断开 | 设置→连接 | [testAuthorizerCompletesCallbackAndStoresToken](../../../Tests/ReadyCheckCoreTests/CodexOAuthTests.swift) | 已保留（限定验收范围） |
| G03 | 浏览器回调自动完成及粘贴回调URL兜底 | 设置→连接 | [testCallbackParserAcceptsManualCallbackURL](../../../Tests/ReadyCheckCoreTests/CodexOAuthTests.swift) | 已保留（限定验收范围） |
| G04 | 读取已有钥匙串失败后的主动重试，不强制重登 | 连接／数据状态 | [testRestoresInteractionAfterSuccessAndFailure](../../../Tests/ReadyCheckCoreTests/KeychainReadInteractionTests.swift) | 已保留（限定验收范围） |
| G05 | 本机连接重试、事件监控状态与故障指引 | 设置→连接 | [testMonitorEmitsAccountAndRateLimitUpdateNotifications](../../../Tests/ReadyCheckCoreTests/CodexAppServerRateLimitMonitorTests.swift) | 已保留（限定验收范围） |
| G06 | 断开不误删其他来源凭据或既有账号历史 | 断开流程／历史存储 | [testDisconnectRemovesOnlyOAuthTokenAndPreservesHistoryAndReminderChoices](../../../Tests/ReadyCheckAppTests/AccountHistoryTests.swift) | 已保留（限定验收范围） |
| H01 | 中英文界面、系统菜单同步及语言持久化 | 设置→通用／系统菜单 | [testBothLanguagesRetainLocalizedNavigationAndNativeFullScreenShortcut](../../../Tests/ReadyCheckAppTests/MainMenuTests.swift) | 已保留（限定验收范围） |
| H02 | 开机启动开关、安装位置诊断与系统批准入口 | 设置→通用 | [testCompleteBundleIsAcceptedOutsideApplicationsAndDeletionIsDetected](../../../Tests/ReadyCheckAppTests/LaunchAtLoginInstallationTests.swift) | 已保留（限定验收范围） |
| H03 | 自动／手动检查更新、提醒／关闭及下载链接 | 设置→通用／更新条 | [testCheckerReturnsUpdateWhenLatestReleaseIsNewer](../../../Tests/ReadyCheckCoreTests/UpdateCheckerTests.swift) | 已保留（限定验收范围） |
| H04 | 常驻关于入口、版号、更新重点、完整说明与产品信息 | 侧栏／通用／菜单栏／系统菜单 | [testAboutAndReleaseHighlightsRenderInBothLanguages](../../../Tests/ReadyCheckAppTests/MainWindowTests.swift) | 已保留（限定验收范围） |
| H05 | 关闭主窗口继续运行、重新打开与明确退出 | 窗口／应用菜单 | [testOpeningMainWindowKeepsPinnedDetailsExpanded](../../../Tests/ReadyCheckAppTests/BubbleWindowControllerTests.swift) | 已保留（限定验收范围） |
| H06 | 原生全屏快捷键、视图菜单导航及Esc语义 | 系统菜单／窗口 | [testBothLanguagesRetainLocalizedNavigationAndNativeFullScreenShortcut](../../../Tests/ReadyCheckAppTests/MainMenuTests.swift) | 已保留（限定验收范围） |
| I01 | 保留既有偏好、位置、连接方式、阈值与历史迁移备份 | 升级／持久化 | [testLegacyFileIsBackedUpByteForByteAndUntouchedByNewWrites](../../../Tests/ReadyCheckCoreTests/QuotaHistoryStoreTests.swift) | 已保留（限定验收范围） |
| I02 | 钥匙串串行安全读取、后台不暗弹授权、不放宽访问控制 | 凭据存储 | [testRestoresInteractionAfterSuccessAndFailure](../../../Tests/ReadyCheckCoreTests/KeychainReadInteractionTests.swift) | 已保留（限定验收范围） |
| I03 | 同账号网络失败保留旧时间／缓存标记；不跨账号复用或触发新提醒 | 额度存储／来源切换 | [testTransportFailureKeepsOnlySameAccountLastKnownValuesAndOriginalTime](../../../Tests/ReadyCheckCoreTests/QuotaStoreTests.swift) | 已保留（限定验收范围） |
| I04 | 旧读取不覆盖新连接，新刷新不被旧请求阻挡或清除 | 连接与刷新 | [testNewConnectionRefreshDoesNotWaitForOrGetClearedByOldRefresh](../../../Tests/ReadyCheckAppTests/ConnectionReloadTests.swift) | 已保留（限定验收范围） |

本机已检查真实睡眠唤醒、额度及权益、Widget显示/固定/内容和明确标识的测试通知送达。本轮没有为验收变更真实凭据、账号、网络或兑换真实卡。不声称完成其他显示器、Windows硬件、强制真实账号切换及真实用卡验收。正式65项验收必须与这些范围对应，不能单凭总测试数或源码存在下结论。
