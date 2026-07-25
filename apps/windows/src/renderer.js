"use strict";

const labels = {
  "quota.fiveHour": "5 小时配额",
  "quota.sevenDay": "7 天配额",
  "quota.window.codex.5h": "5 小时配额",
  "quota.window.codex.7d": "7 天配额",
  "quota.window.codex.primary": "Codex 主限额",
  "quota.window.codex.secondary": "Codex 周限额"
};

const elements = {
  connectionStatus: document.getElementById("connectionStatus"),
  refreshButton: document.getElementById("refreshButton"),
  releaseButton: document.getElementById("releaseButton"),
  widgetRefreshButton: document.getElementById("widgetRefreshButton"),
  widgetVisible: document.getElementById("widgetVisible"),
  widgetAlwaysOnTop: document.getElementById("widgetAlwaysOnTop"),
  widgetDisplayMode: document.getElementById("widgetDisplayMode"),
  widgetModeButtons: document.querySelectorAll("[data-widget-mode-option]"),
  resetWidgetButton: document.getElementById("resetWidgetButton"),
  connectButton: document.getElementById("connectButton"),
  disconnectButton: document.getElementById("disconnectButton"),
  oauthStatusText: document.getElementById("oauthStatusText"),
  language: document.getElementById("language"),
  refreshInterval: document.getElementById("refreshInterval"),
  quotaContent: document.getElementById("quotaContent"),
  quotaRecoveryActions: document.getElementById("quotaRecoveryActions"),
  quotaRetryButton: document.getElementById("quotaRetryButton"),
  quotaReconnectButton: document.getElementById("quotaReconnectButton"),
  quotaConnectButton: document.getElementById("quotaConnectButton"),
  quotaUpdateButton: document.getElementById("quotaUpdateButton"),
  usageDashboard: document.getElementById("usageDashboard"),
  usageRangeButtons: document.querySelectorAll("[data-usage-range]"),
  lastRefresh: document.getElementById("lastRefresh"),
  widgetLastRefresh: document.getElementById("widgetLastRefresh"),
  accountText: document.getElementById("accountText"),
  widgetRoot: document.getElementById("widgetRoot")
};

const isWidget = document.body.dataset.surface === "widget";
let currentState = null;
let usageRangeDays = 1;
let usageWindowID = "codex-primary";
let usageChartHasAnimated = false;
let usageChartContextKey = null;
const previousUsageBarsByContext = new Map();
const MAX_USAGE_ATTRIBUTABLE_GAP_MS = 10 * 60 * 1000;

function render(state) {
  currentState = state;
  document.body.dataset.connected = state.connected ? "true" : "false";
  document.body.dataset.widgetMode = state.prefs.widgetDisplayMode;

  if (elements.connectionStatus) {
    elements.connectionStatus.textContent = state.connected ? "已连接" : "未连接";
  }
  if (elements.accountText) {
    elements.accountText.textContent = state.accountEmail || "未连接";
  }
  if (elements.connectButton) {
    elements.connectButton.hidden = state.connected;
    elements.connectButton.disabled = state.status === "authorizing";
    elements.connectButton.textContent = state.status === "authorizing" ? "授权中…" : "连接";
  }
  if (elements.disconnectButton) {
    elements.disconnectButton.hidden = !state.connected;
  }
  if (elements.oauthStatusText) {
    elements.oauthStatusText.textContent = oauthStatusText(state);
  }
  if (elements.refreshButton) {
    elements.refreshButton.disabled = state.isRefreshing;
    elements.refreshButton.textContent = state.isRefreshing ? "正在刷新…" : "刷新";
  }
  if (elements.widgetRefreshButton) {
    elements.widgetRefreshButton.disabled = state.isRefreshing;
  }
  if (elements.lastRefresh) {
    elements.lastRefresh.textContent = formatRefreshTime(state.lastRefreshAt);
  }
  if (elements.widgetLastRefresh) {
    elements.widgetLastRefresh.textContent = formatRefreshTime(state.lastRefreshAt);
  }
  if (elements.widgetVisible) {
    elements.widgetVisible.checked = state.prefs.widgetVisible;
  }
  if (elements.widgetAlwaysOnTop) {
    elements.widgetAlwaysOnTop.checked = state.prefs.widgetAlwaysOnTop;
  }
  if (elements.widgetDisplayMode) {
    elements.widgetDisplayMode.value = state.prefs.widgetDisplayMode;
  }
  for (const button of elements.widgetModeButtons || []) {
    const active = button.dataset.widgetModeOption === state.prefs.widgetDisplayMode;
    button.classList.toggle("active", active);
    button.setAttribute("aria-pressed", active ? "true" : "false");
  }
  if (elements.language) {
    elements.language.value = state.prefs.language;
  }
  if (elements.refreshInterval) {
    elements.refreshInterval.value = String(state.prefs.refreshIntervalMinutes);
  }

  renderQuota(state);
  renderRecoveryActions(state);
  renderUsageDashboard(state);
}

function renderQuota(state) {
  if (!elements.quotaContent) {
    return;
  }

  const mode = state.prefs.widgetDisplayMode;
  const details = state.quota;
  const rows = [];
  const visibleWindows = details.windows.filter((item) => !["quota.window.codex.5h", "quota.fiveHour"].includes(item.labelKey));

  if (!isWidget || mode === "detailed") {
    const creditsRow = codexCreditsText(details);
    rows.push(`
      <div class="details-grid">
        <span>${isWidget ? "套餐" : "套餐"}</span><strong>${details.plan || "未提供"}</strong>
        <span>${isWidget ? "续期" : "续期时间"}</span><strong>${formatDate(details.subscriptionRenewalAt) || "未提供"}</strong>
        <span>${isWidget ? "重置次数" : "主动重置次数"}</span><strong>${details.manualResetCount}</strong>
        ${creditsRow ? `<span>Codex Credits</span><strong>${creditsRow}</strong>` : ""}
        <span>${isWidget ? "重置过期" : "主动重置过期时间（GMT+8）"}</span><strong>${formatDate(details.manualResetExpiresAt) || "未提供"}</strong>
      </div>
    `);
  }

  for (const window of visibleWindows) {
    const ratio = typeof window.remainingRatio === "number" ? window.remainingRatio : null;
    const percent = ratio === null ? "—" : `${Math.round(ratio * 100)}%`;
    const progress = ratio === null ? 0 : Math.min(Math.max(ratio, 0), 1) * 100;
    const warning = quotaWarning(ratio);
    rows.push(`
      <article class="quota-row">
        <div class="quota-row-heading">
          <strong>${labels[window.labelKey] || window.labelKey}</strong>
          <span>${percent}</span>
        </div>
        <div class="progress-track">
          <div class="progress-fill ${urgencyClass(ratio)}" style="width:${progress}%"></div>
        </div>
        <div class="quota-row-footer">
          <p>${formatDate(window.resetAt) || "等待连接后刷新"}</p>
          ${warning ? `<p class="quota-warning ${urgencyClass(ratio)}">${warning}</p>` : ""}
        </div>
      </article>
    `);
  }

  if (visibleWindows.length === 0) {
    rows.push('<p class="muted">当前 7 天额度暂不可用。</p>');
  }

  elements.quotaContent.innerHTML = rows.join("");
}

function codexCreditsText(details) {
  if (details.creditsUnlimited === true) {
    return "无限";
  }
  if (details.creditBalance === null || details.creditBalance === undefined || details.creditBalance === "") {
    return null;
  }

  const value = Number(details.creditBalance);
  if (!Number.isFinite(value) || value < 0) {
    return null;
  }
  return new Intl.NumberFormat(undefined, { maximumFractionDigits: 3 }).format(value);
}

function renderRecoveryActions(state) {
  if (!elements.quotaRecoveryActions) {
    return;
  }

  const action = state.recoveryAction || "none";
  elements.quotaRecoveryActions.hidden = action === "none";
  elements.quotaRetryButton.hidden = action !== "retry" && action !== "checkForUpdates";
  elements.quotaReconnectButton.hidden = action !== "reconnect";
  elements.quotaConnectButton.hidden = action !== "connect";
  elements.quotaUpdateButton.hidden = action !== "checkForUpdates";
}

function renderUsageDashboard(state) {
  if (!elements.usageDashboard) {
    return;
  }

  for (const button of elements.usageRangeButtons) {
    button.classList.toggle("active", Number(button.dataset.usageRange) === usageRangeDays);
  }

  const now = Date.now();
  const bucketSize = usageBucketSizeMs();
  const chartRangeEnd = alignedUsageRangeEnd(now, bucketSize);
  const chartRangeStart = chartRangeEnd - usageRangeDays * 24 * 60 * 60 * 1000;
  const cutoff = now - usageRangeDays * 24 * 60 * 60 * 1000;
  const series = historySeries(state.quotaHistory || []);
  if (series.length === 0) {
    elements.usageDashboard.innerHTML = `
      <div class="usage-empty">
        <strong>正在收集本地记录</strong>
        <p>完成两次成功刷新后，这里会展示检测到的额度消耗。</p>
      </div>
    `;
    return;
  }

  const sevenDay = series.find((item) => item.labelKey === "quota.window.codex.7d" || item.labelKey === "quota.sevenDay");
  // Keep five-hour history on disk for forward compatibility, but do not present the retired window.
  const availableSeries = [sevenDay].filter(Boolean);
  if (availableSeries.length === 0) {
    elements.usageDashboard.innerHTML = `
      <div class="usage-empty">
        <strong>正在收集 7 天额度记录</strong>
        <p>完成两次成功刷新后，这里会展示检测到的额度消耗。</p>
      </div>
    `;
    return;
  }
  if (!availableSeries.some((item) => item.windowID === usageWindowID)) {
    usageWindowID = availableSeries[0].windowID;
  }
  const selected = availableSeries.find((item) => item.windowID === usageWindowID) || availableSeries[0];
  const selectedPoints = selected.points.filter((point) => point.timestamp >= chartRangeStart && point.timestamp <= now);
  const latest = selected.points.at(-1);
  const allBars = usageBars(selected.points, chartRangeStart, chartRangeEnd, bucketSize);
  const bars = observedUsageBars(allBars, selectedPoints[0] && selectedPoints[0].timestamp);
  const shouldAnimateChart = selectedPoints.length >= 2 && !usageChartHasAnimated;
  const chartContextKey = `${usageRangeDays}:${selected.windowID}`;
  const shouldFadeChart = usageChartHasAnimated && usageChartContextKey !== chartContextKey;
  const previousChart = previousUsageBarsByContext.get(chartContextKey) || { values: new Map(), maximum: null };
  const chartMaximum = usageChartMaximum(bars.map((bar) => bar.consumedPercent));
  const chartStart = bars[0] ? bars[0].start : cutoff;
  const chartEnd = bars.at(-1) ? bars.at(-1).end : now;
  elements.usageDashboard.innerHTML = `
    <div class="usage-metrics">
      ${usageMetric("7 天额度", sevenDay, cutoff)}
      <div class="usage-metric data-status"><span>数据状态</span><strong>最近记录 ${formatHistoryTime(latest.timestamp)}</strong><small>成功刷新后按 1 分钟采样</small></div>
    </div>
    ${selectedPoints.length < 2 ? `
      <div class="usage-empty">
        <strong>正在积累使用记录</strong>
        <p>完成两次成功刷新后，这里会展示检测到的额度消耗。</p>
      </div>
    ` : `
      <div class="usage-chart-wrap">
        <div class="usage-chart-heading"><strong>${usageWindowLabel(selected)} · 每时段消耗</strong><span>非零柱显示百分比</span></div>
        ${usageChart(bars, chartStart, chartEnd, {
          shouldAnimateChart,
          shouldFadeChart,
          previousValues: previousChart.values,
          previousMaximum: previousChart.maximum,
          maximum: chartMaximum
        })}
        ${bars.every((bar) => bar.consumedPercent === 0) ? '<p class="usage-zero">该时间范围内未检测到额度下降。</p>' : ""}
        <p class="usage-explanation">${latest.ratio <= 0 ? "当前剩余 0% 不代表使用量为 0；零柱表示该时段未检测到新的额度下降。" : "统计本地成功刷新之间的额度下降，不代表 Token 数量；额度重置、恢复和长时间无数据不会计入消耗。"}</p>
      </div>
    `}
  `;
  if (shouldAnimateChart) {
    usageChartHasAnimated = true;
  }
  usageChartContextKey = chartContextKey;
  previousUsageBarsByContext.set(
    chartContextKey,
    {
      values: new Map(bars.map((bar) => [bar.start, bar.consumedPercent])),
      maximum: chartMaximum
    }
  );
}

function historySeries(samples) {
  const grouped = new Map();
  for (const sample of samples) {
    for (const value of sample.values || []) {
      const key = value.windowID;
      if (!grouped.has(key)) {
        grouped.set(key, { windowID: key, labelKey: value.labelKey, points: [] });
      }
      grouped.get(key).points.push({ timestamp: new Date(sample.recordedAt).getTime(), ratio: value.remainingRatio });
    }
  }
  return [...grouped.values()];
}

function consumedPercent(series, start) {
  if (!series || series.points.length < 2) {
    return null;
  }
  let consumed = 0;
  for (let index = 1; index < series.points.length; index += 1) {
    const previous = series.points[index - 1];
    const current = series.points[index];
    if (current.timestamp < start || current.timestamp - previous.timestamp > MAX_USAGE_ATTRIBUTABLE_GAP_MS) {
      continue;
    }
    consumed += Math.max(0, previous.ratio - current.ratio);
  }
  return Math.round(consumed * 100);
}

function usageMetric(label, series, cutoff) {
  const latest = series && series.points.at(-1);
  const remaining = latest ? Math.round(latest.ratio * 100) : null;
  const consumed = consumedPercent(series, cutoff);
  const selected = series && series.windowID === usageWindowID ? " selected" : "";
  const unavailable = series ? "" : " unavailable";
  return `<button class="usage-metric selectable${selected}${unavailable}" data-usage-window="${series ? series.windowID : ""}" ${series ? "" : "disabled"}>
    <span>${label}${selected ? " · 当前查看" : ""}</span>
    <strong>${consumed === null ? "记录中" : `${consumed} 个百分点消耗`}</strong>
    <small>当前剩余 <b class="${remaining !== null && remaining < 25 ? "critical-text" : ""}">${remaining === null ? "--" : `${remaining}%`}</b></small>
  </button>`;
}

function usageBucketSizeMs() {
  if (usageRangeDays === 1) return 60 * 60 * 1000;
  if (usageRangeDays === 7) return 6 * 60 * 60 * 1000;
  return 24 * 60 * 60 * 1000;
}

function alignedUsageRangeEnd(timestamp, bucketSize) {
  return (Math.floor(timestamp / bucketSize) + 1) * bucketSize;
}

function usageBars(points, start, end, bucketSize) {
  const count = Math.ceil((end - start) / bucketSize);
  const bars = Array.from({ length: count }, (_, index) => ({
    start: start + index * bucketSize,
    end: Math.min(start + (index + 1) * bucketSize, end),
    consumedPercent: 0
  }));
  for (let index = 1; index < points.length; index += 1) {
    const previous = points[index - 1];
    const current = points[index];
    if (current.timestamp < start || current.timestamp > end || current.timestamp - previous.timestamp > MAX_USAGE_ATTRIBUTABLE_GAP_MS) {
      continue;
    }
    const bucketIndex = Math.min(bars.length - 1, Math.max(0, Math.floor((current.timestamp - start) / bucketSize)));
    bars[bucketIndex].consumedPercent += Math.max(0, previous.ratio - current.ratio) * 100;
  }
  return bars;
}

function observedUsageBars(bars, firstObservedAt) {
  if (!Number.isFinite(firstObservedAt)) {
    return [];
  }
  return bars.filter((bar) => bar.end > firstObservedAt);
}

function usageChart(bars, start, end, animation) {
  const width = 760;
  const height = 184;
  const padding = { top: 12, right: 12, bottom: 28, left: 32 };
  const plotWidth = width - padding.left - padding.right;
  const plotHeight = height - padding.top - padding.bottom;
  const maximum = animation.maximum;
  const barWidth = 12;
  const columns = bars.map((bar, index) => {
    const value = bar.consumedPercent;
    const barHeight = (value / maximum) * plotHeight;
    const x = padding.left + (index + 0.5) * (plotWidth / bars.length) - barWidth / 2;
    const y = padding.top + plotHeight - barHeight;
    const previousValue = animation.previousValues.get(bar.start);
    const shouldAnimateDelta = !animation.shouldAnimateChart
      && !animation.shouldFadeChart
      && value > 0
      && value > (previousValue || 0);
    const animationClass = animation.shouldAnimateChart ? " animate" : shouldAnimateDelta ? " delta" : "";
    const previousHeightRatio = animation.previousMaximum
      ? (previousValue || 0) / animation.previousMaximum
      : 0;
    const targetHeightRatio = value / maximum;
    const startScale = shouldAnimateDelta && targetHeightRatio > 0
      ? Math.max(0, previousHeightRatio / targetHeightRatio)
      : 1;
    const animationStyle = shouldAnimateDelta ? ` style="--bar-start-scale:${startScale.toFixed(4)}"` : "";
    const valueLabel = value > 0
      ? `<text class="chart-value" x="${(x + barWidth / 2).toFixed(1)}" y="${Math.max(8, y - 4).toFixed(1)}" text-anchor="middle">${Math.round(value)}%</text>`
      : "";
    return `<rect class="chart-bar${animationClass}"${animationStyle} x="${x.toFixed(1)}" y="${y.toFixed(1)}" width="${barWidth}" height="${barHeight.toFixed(1)}" rx="3"><title>${formatHistoryTime(bar.start)} - ${formatHistoryTime(bar.end)}：消耗 ${value.toFixed(1)} 个百分点</title></rect>${valueLabel}`;
  }).join("");
  const yLabels = [maximum, maximum / 2, 0].map((value, index) => {
    const y = padding.top + index * (plotHeight / 2);
    return `<line class="chart-grid" x1="${padding.left}" y1="${y.toFixed(1)}" x2="${width - padding.right}" y2="${y.toFixed(1)}"></line><text class="chart-label" x="${padding.left - 7}" y="${(y + 4).toFixed(1)}" text-anchor="end">${Math.round(value)}</text>`;
  }).join("");
  const xLabels = [start, start + (end - start) / 2, end].map((timestamp) => {
    const x = padding.left + ((timestamp - start) / Math.max(end - start, 1)) * plotWidth;
    return `<text class="chart-label" x="${x.toFixed(1)}" y="${height - 7}" text-anchor="middle">${formatUsageAxisTime(timestamp)}</text>`;
  }).join("");
  const chartClass = animation.shouldFadeChart ? "usage-chart switching" : "usage-chart";
  return `<svg class="${chartClass}" viewBox="0 0 ${width} ${height}" role="img" aria-label="近期额度消耗柱状图">
    ${yLabels}${columns}${xLabels}
  </svg>`;
}

function usageChartMaximum(values) {
  const highest = Math.max(...values, 0);
  const headroom = Math.max(1, highest * 0.15);
  return Math.max(5, Math.ceil((highest + headroom) / 5) * 5);
}

function usageWindowLabel(series) {
  return labels[series.labelKey] || series.labelKey;
}

function formatUsageAxisTime(timestamp) {
  const date = new Date(timestamp);
  if (usageRangeDays === 1) return date.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
  if (usageRangeDays === 7) return date.toLocaleDateString([], { weekday: "short", hour: "2-digit" });
  return date.toLocaleDateString([], { month: "numeric", day: "numeric" });
}

function formatHistoryTime(value) {
  return new Date(value).toLocaleString([], { month: "numeric", day: "numeric", hour: "2-digit", minute: "2-digit" });
}

function formatRefreshTime(value) {
  if (!value) {
    return "尚未刷新";
  }
  return `上次刷新 ${new Date(value).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}`;
}

function formatDate(value) {
  if (!value) {
    return "";
  }
  return new Date(value).toLocaleString([], {
    month: "numeric",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit"
  });
}

function urgencyClass(ratio) {
  if (ratio === null) {
    return "unknown";
  }
  if (Math.round(ratio * 100) === 0) {
    return "exhausted";
  }
  if (ratio < 0.25) {
    return "critical";
  }
  if (ratio < 0.5) {
    return "warning";
  }
  return "normal";
}

function quotaWarning(ratio) {
  const urgency = urgencyClass(ratio);
  if (!["warning", "critical", "exhausted"].includes(urgency)) {
    return "";
  }
  if (urgency === "exhausted") {
    return "额度用尽，等待重置";
  }
  return urgency === "critical" ? "额度很低" : "额度偏低";
}

function oauthStatusText(state) {
  if (state.status === "authorizing") {
    return "已打开浏览器授权页。若页面提示 Country, region, or territory not supported，说明当前网络或账号地区不被 OpenAI OAuth 接受，ReadyCheck 无法绕过，请更换受支持的网络环境后重试。";
  }
  if (state.status === "authorizationFailed") {
    return "授权失败。请重新点击连接；如果浏览器显示地区不支持，需要更换受支持的网络环境后重试。";
  }
  if (state.connected) {
    return "Codex 已连接。刷新只读取用量数据，不调用模型。";
  }
  return "Windows 预览版通过 Codex OAuth 授权，token 使用 Electron safeStorage 加密保存。刷新只读取用量数据，不调用模型。";
}

async function updatePrefs(partial) {
  const next = await window.readyCheck.updatePrefs(partial);
  render(next);
}

function wireEvents() {
  if (elements.refreshButton) {
    elements.refreshButton.addEventListener("click", () => window.readyCheck.refresh());
  }
  if (elements.widgetRefreshButton) {
    elements.widgetRefreshButton.addEventListener("click", (event) => {
      event.stopPropagation();
      window.readyCheck.refresh();
    });
  }
  if (elements.releaseButton) {
    elements.releaseButton.addEventListener("click", () => window.readyCheck.openReleasePage());
  }
  if (elements.connectButton) {
    elements.connectButton.addEventListener("click", () => window.readyCheck.beginOAuth());
  }
  if (elements.quotaRetryButton) {
    elements.quotaRetryButton.addEventListener("click", () => window.readyCheck.refresh());
    elements.quotaReconnectButton.addEventListener("click", () => window.readyCheck.beginOAuth());
    elements.quotaConnectButton.addEventListener("click", () => window.readyCheck.beginOAuth());
    elements.quotaUpdateButton.addEventListener("click", () => window.readyCheck.openReleasePage());
  }
  for (const button of elements.usageRangeButtons || []) {
    button.addEventListener("click", () => {
      usageRangeDays = Number(button.dataset.usageRange);
      renderUsageDashboard(currentState);
    });
  }
  if (elements.usageDashboard) {
    elements.usageDashboard.addEventListener("click", (event) => {
      const button = event.target.closest("[data-usage-window]");
      if (!button || !button.dataset.usageWindow) return;
      usageWindowID = button.dataset.usageWindow;
      renderUsageDashboard(currentState);
    });
  }
  if (elements.disconnectButton) {
    elements.disconnectButton.addEventListener("click", () => window.readyCheck.disconnect());
  }
  if (elements.widgetVisible) {
    elements.widgetVisible.addEventListener("change", () => updatePrefs({ widgetVisible: elements.widgetVisible.checked }));
  }
  if (elements.widgetAlwaysOnTop) {
    elements.widgetAlwaysOnTop.addEventListener("change", () => updatePrefs({ widgetAlwaysOnTop: elements.widgetAlwaysOnTop.checked }));
  }
  if (elements.widgetDisplayMode) {
    elements.widgetDisplayMode.addEventListener("change", () => updatePrefs({ widgetDisplayMode: elements.widgetDisplayMode.value }));
  }
  for (const button of elements.widgetModeButtons || []) {
    button.addEventListener("click", (event) => {
      event.stopPropagation();
      updatePrefs({ widgetDisplayMode: button.dataset.widgetModeOption });
    });
  }
  if (elements.language) {
    elements.language.addEventListener("change", () => updatePrefs({ language: elements.language.value }));
  }
  if (elements.refreshInterval) {
    elements.refreshInterval.addEventListener("change", () => updatePrefs({ refreshIntervalMinutes: Number(elements.refreshInterval.value) }));
  }
  if (elements.resetWidgetButton) {
    elements.resetWidgetButton.addEventListener("click", () => window.readyCheck.resetWidgetPosition());
  }
  if (elements.widgetRoot) {
    elements.widgetRoot.addEventListener("click", (event) => {
      if (event.target.closest("button, select, input")) {
        return;
      }
      window.readyCheck.showMainWindow();
    });
  }
}

wireEvents();
window.readyCheck.onState(render);
window.readyCheck.getState().then(render);
