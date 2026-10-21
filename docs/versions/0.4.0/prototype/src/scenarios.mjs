export const SCENARIOS = [
  { id: 'normal', label: '正常重置', labelEn: 'Normal reset' },
  { id: 'off', label: '自动使用关闭', labelEn: 'Automatic use off' },
  { id: 'authorized', label: '已授权，等待窗口', labelEn: 'Authorized, waiting for window' },
  { id: 'unknown', label: '条件尚未确认', labelEn: 'Conditions unconfirmed' },
  { id: 'notificationPending', label: '已用卡，通知待重试', labelEn: 'Used card, notification pending' },
];
export const FIXED_NOW = '2026-10-21T10:20:00+08:00';
const words = {
  zh: {
    natural: '5h 额度预计重置', naturalDetail: '时间来自当前读数，需刷新确认额度恢复。', naturalAction: '查看重置说明',
    window: '进入自动使用窗口', windowDetail: '最早到期卡今天 13:00 到期；条件满足时尝试。', windowAction: '查看详情',
    off: '重置卡今天 13:00 到期', offDetail: '自动使用未开启；是否开启由你决定。', offAction: '管理规则',
    unknown: '最新条件尚未确认', unknownDetail: '当前显示上次读数，不能确认用卡条件。', unknownAction: '查看连接',
    used: '重置卡已使用', usedDetail: '昨天 18:06 服务端已确认；成功通知未送达，待重试。', usedAction: '查看结果',
    cached: '5h 上次记录的重置时间', cachedDetail: '今天 12:20；这是旧读数，尚未确认。',
  },
  en: {
    natural: '5h quota expected to reset', naturalDetail: 'From the current reading. Refresh to confirm recovery.', naturalAction: 'Reset details',
    window: 'Automatic-use window begins', windowDetail: 'Earliest card expires today at 13:00. Attempts depend on conditions.', windowAction: 'View details',
    off: 'Reset card expires today at 13:00', offDetail: 'Automatic use is off. You choose whether to enable it.', offAction: 'Manage rules',
    unknown: 'Latest conditions unconfirmed', unknownDetail: 'Showing the previous reading. Card-use conditions are unconfirmed.', unknownAction: 'View connection',
    used: 'Reset card used', usedDetail: 'Confirmed yesterday at 18:06. Success notification was not delivered and is pending retry.', usedAction: 'View result',
    cached: 'Last recorded 5h reset time', cachedDetail: 'Today at 12:20. This is a previous reading, not confirmation.',
  },
};
export function buildScenario(id = 'authorized', options = {}) {
  const known = SCENARIOS.some((item) => item.id === id) ? id : 'authorized';
  const language = options.language === 'en' ? 'en' : 'zh';
  const w = words[language];
  const autoEnabled = typeof options.autoEnabled === 'boolean' ? options.autoEnabled : known !== 'off';
  const isFresh = known !== 'unknown';
  const primaryWindow = options.primaryWindow === '7d' ? '7d' : '5h';
  const availableCards = known === 'normal'
    ? [{ id: 'available-1', expiresAt: '2026-10-28T13:00:00+08:00' }, { id: 'available-2', expiresAt: '2026-11-04T13:00:00+08:00' }]
    : [{ id: 'available-1', expiresAt: '2026-10-21T13:00:00+08:00' }, { id: 'available-2', expiresAt: '2026-10-28T13:00:00+08:00' }];
  const natural = { id: 'natural-reset', type: 'reset', time: '12:20', day: language === 'zh' ? '今天' : 'Today', title: w.natural, detail: w.naturalDetail, action: w.naturalAction, target: 'reset', tone: 'neutral' };
  let events;
  if (known === 'unknown') {
    events = [
      { id: 'conditions-unknown', type: 'connection', time: '—', day: language === 'zh' ? '待确认' : 'Unconfirmed', title: w.unknown, detail: w.unknownDetail, action: w.unknownAction, target: 'connection', tone: 'warning' },
      { ...natural, title: w.cached, detail: w.cachedDetail, tone: 'muted' },
    ];
  } else if (known === 'notificationPending') {
    events = [
      { id: 'historical-used-card', type: 'notification', time: '18:06', day: language === 'zh' ? '昨天' : 'Yesterday', title: w.used, detail: w.usedDetail, action: w.usedAction, target: 'historical', tone: 'warning' }, natural,
    ];
  } else if (known === 'normal') {
    events = [natural];
  } else if (!autoEnabled) {
    events = [
      { id: 'automation-off', type: 'card', time: '13:00', day: language === 'zh' ? '今天' : 'Today', title: w.off, detail: w.offDetail, action: w.offAction, target: 'rules', tone: 'neutral' }, natural,
    ];
  } else {
    events = [
      { id: 'card-window', type: 'card', time: '12:00', day: language === 'zh' ? '今天' : 'Today', title: w.window, detail: w.windowDetail, action: w.windowAction, target: 'card', tone: 'warning' }, natural,
    ];
  }
  return {
    id: known, language, now: FIXED_NOW, availableCards, events, primaryWindow, autoEnabled, isFresh,
    redemptionState: known === 'notificationPending' ? 'used' : known === 'unknown' ? 'unconfirmed' : autoEnabled ? 'waiting' : 'disabled',
    notificationState: known === 'notificationPending' ? 'pending' : 'none',
    historicalCard: { id: 'historical-used-1', usedAt: '2026-10-20T18:06:00+08:00', updatedAt: '2026-10-20T18:06:00+08:00', redemptionState: 'used', notificationState: 'pending', processRecorded: false },
    quotas: [
      { id: '5h', remaining: 34, resetAt: '2026-10-21T12:20:00+08:00', color: '#FF9F32' },
      { id: '7d', remaining: 70, resetAt: '2026-10-23T10:20:00+08:00', color: '#30D158' },
    ],
  };
}
