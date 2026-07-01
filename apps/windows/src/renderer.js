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
  lastRefresh: document.getElementById("lastRefresh"),
  widgetLastRefresh: document.getElementById("widgetLastRefresh"),
  accountText: document.getElementById("accountText"),
  widgetRoot: document.getElementById("widgetRoot")
};

const isWidget = document.body.dataset.surface === "widget";
let currentState = null;

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
}

function renderQuota(state) {
  if (!elements.quotaContent) {
    return;
  }

  const mode = state.prefs.widgetDisplayMode;
  const details = state.quota;
  const rows = [];

  if (!isWidget || mode === "detailed") {
    rows.push(`
      <div class="details-grid">
        <span>${isWidget ? "套餐" : "套餐"}</span><strong>${details.plan || "未提供"}</strong>
        <span>${isWidget ? "续期" : "续期时间"}</span><strong>${formatDate(details.subscriptionRenewalAt) || "未提供"}</strong>
        <span>${isWidget ? "重置次数" : "主动重置次数"}</span><strong>${details.manualResetCount}</strong>
        <span>${isWidget ? "重置过期" : "主动重置过期时间（GMT+8）"}</span><strong>${formatDate(details.manualResetExpiresAt) || "未提供"}</strong>
      </div>
    `);
  }

  for (const window of details.windows) {
    const ratio = typeof window.remainingRatio === "number" ? window.remainingRatio : null;
    const percent = ratio === null ? "—" : `${Math.round(ratio * 100)}%`;
    const progress = ratio === null ? 0 : Math.min(Math.max(ratio, 0), 1) * 100;
    rows.push(`
      <article class="quota-row">
        <div class="quota-row-heading">
          <strong>${labels[window.labelKey] || window.labelKey}</strong>
          <span>${percent}</span>
        </div>
        <div class="progress-track">
          <div class="progress-fill ${urgencyClass(ratio)}" style="width:${progress}%"></div>
        </div>
        <p>${formatDate(window.resetAt) || "等待连接后刷新"}</p>
      </article>
    `);
  }

  elements.quotaContent.innerHTML = rows.join("");
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
  if (ratio < 0.25) {
    return "critical";
  }
  if (ratio < 0.5) {
    return "warning";
  }
  return "normal";
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
