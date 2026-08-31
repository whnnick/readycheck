"use strict";

const http = require("node:http");
const path = require("node:path");
const { app, BrowserWindow, Menu, Notification, Tray, ipcMain, nativeImage, shell } = require("electron");
const { CodexOAuthClient } = require("./services/oauth");
const { PrefsStore } = require("./services/prefs-store");
const { QuotaHistoryStore } = require("./services/history-store");
const { QuotaReminderStore } = require("./services/reminder-store");
const { ReadyCheckState } = require("./services/app-state");
const { EncryptedTokenStore } = require("./services/token-store");
const { CodexUsageClient } = require("./services/usage-client");
const { CodexAppServerClient, CodexAppServerRateLimitMonitor } = require("./services/codex-app-server");

let mainWindow = null;
let widgetWindow = null;
let tray = null;
let prefsStore = null;
let readyState = null;
let reminderStore = null;
let refreshTimer = null;
let rateLimitEventTimer = null;
let rateLimitMonitor = null;
let oauthCallbackServer = null;

const isWindows = process.platform === "win32";
const WIDGET_BOUNDS = {
  minimal: { width: 330, height: 220 },
  detailed: { width: 350, height: 360 }
};

function createMainWindow() {
  mainWindow = new BrowserWindow({
    width: 880,
    height: 680,
    minWidth: 800,
    minHeight: 580,
    title: "ReadyCheck",
    show: false,
    backgroundColor: "#111827",
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  mainWindow.loadFile(path.join(__dirname, "renderer.html"));
  mainWindow.once("ready-to-show", () => mainWindow.show());
  mainWindow.on("closed", () => {
    mainWindow = null;
  });
}

function createWidgetWindow() {
  if (widgetWindow) {
    return;
  }

  const bounds = widgetBoundsForMode(readyState.prefs.widgetDisplayMode);
  widgetWindow = new BrowserWindow({
    width: bounds.width,
    height: bounds.height,
    frame: false,
    resizable: false,
    transparent: true,
    alwaysOnTop: readyState.prefs.widgetAlwaysOnTop,
    skipTaskbar: true,
    title: "ReadyCheck Widget",
    show: false,
    webPreferences: {
      preload: path.join(__dirname, "preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });

  widgetWindow.loadFile(path.join(__dirname, "widget.html"));
  widgetWindow.once("ready-to-show", () => {
    placeWidgetNearBottomRight();
    if (readyState.prefs.widgetVisible) {
      widgetWindow.showInactive();
    }
  });
  widgetWindow.on("closed", () => {
    widgetWindow = null;
  });
}

function placeWidgetNearBottomRight() {
  if (!widgetWindow) {
    return;
  }

  const { screen } = require("electron");
  const display = screen.getPrimaryDisplay();
  const bounds = display.workArea;
  const size = widgetWindow.getBounds();
  const marginRight = 28;
  const marginBottom = 64;
  const x = Math.max(bounds.x, bounds.x + bounds.width - size.width - marginRight);
  const y = Math.max(bounds.y, bounds.y + bounds.height - size.height - marginBottom);
  widgetWindow.setPosition(Math.round(x), Math.round(y), false);
}

function widgetBoundsForMode(mode) {
  return mode === "detailed" ? WIDGET_BOUNDS.detailed : WIDGET_BOUNDS.minimal;
}

function resizeWidgetForMode(mode) {
  if (!widgetWindow) {
    return;
  }

  const bounds = widgetBoundsForMode(mode);
  widgetWindow.setSize(bounds.width, bounds.height, false);
  clampWidgetToWorkArea();
}

function clampWidgetToWorkArea() {
  if (!widgetWindow) {
    return;
  }

  const { screen } = require("electron");
  const display = screen.getDisplayMatching(widgetWindow.getBounds());
  const workArea = display.workArea;
  const bounds = widgetWindow.getBounds();
  const x = Math.min(Math.max(bounds.x, workArea.x), workArea.x + workArea.width - bounds.width);
  const y = Math.min(Math.max(bounds.y, workArea.y), workArea.y + workArea.height - bounds.height);
  widgetWindow.setPosition(Math.round(x), Math.round(y), false);
}

function createTray() {
  const icon = nativeImage.createFromDataURL(buildTrayIconDataURL());
  tray = new Tray(icon);
  tray.setToolTip("ReadyCheck");
  tray.setContextMenu(buildTrayMenu());
  tray.on("click", () => showMainWindow());
}

function buildTrayIconDataURL() {
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32">
      <rect width="32" height="32" rx="8" fill="#1683ff"/>
      <circle cx="16" cy="16" r="9" fill="none" stroke="#ffffff" stroke-width="2.5"/>
      <path d="M16 16 L22 10" stroke="#ffffff" stroke-width="2.5" stroke-linecap="round"/>
      <circle cx="10" cy="15" r="1.8" fill="#ffffff"/>
      <circle cx="16" cy="8.5" r="1.6" fill="#ffffff"/>
      <circle cx="22" cy="18" r="1.8" fill="#ffffff"/>
    </svg>
  `;
  return `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svg)}`;
}

function buildTrayMenu() {
  return Menu.buildFromTemplate([
    { label: "ReadyCheck", enabled: false },
    { type: "separator" },
    { label: "Open", click: () => showMainWindow() },
    { label: "Refresh", click: () => refreshQuota({ forceSupplemental: true }) },
    {
      label: readyState.prefs.widgetVisible ? "Hide widget" : "Show widget",
      click: () => updatePrefs({ widgetVisible: !readyState.prefs.widgetVisible })
    },
    { label: "Reset widget position", click: () => placeWidgetNearBottomRight() },
    { type: "separator" },
    { label: "Quit", click: () => app.quit() }
  ]);
}

function showMainWindow() {
  if (!mainWindow) {
    createMainWindow();
  } else {
    mainWindow.show();
    mainWindow.focus();
  }
}

function broadcastState() {
  const snapshot = snapshotWithReminderHistory();
  for (const window of BrowserWindow.getAllWindows()) {
    window.webContents.send("readycheck:state", snapshot);
  }
  if (tray) {
    tray.setContextMenu(buildTrayMenu());
  }
}

function snapshotWithReminderHistory() {
  return {
    ...readyState.snapshot(),
    reminderHistory: reminderStore ? reminderStore.history() : []
  };
}

function updatePrefs(partial) {
  const previousPrefs = readyState.prefs;
  const prefs = prefsStore.save({ ...readyState.prefs, ...partial });
  readyState.updatePrefs(prefs);

  if (widgetWindow) {
    if (previousPrefs.widgetDisplayMode !== prefs.widgetDisplayMode) {
      resizeWidgetForMode(prefs.widgetDisplayMode);
    }

    if (previousPrefs.widgetAlwaysOnTop !== prefs.widgetAlwaysOnTop) {
      widgetWindow.setAlwaysOnTop(prefs.widgetAlwaysOnTop, prefs.widgetAlwaysOnTop ? "floating" : "normal");
      widgetWindow.setVisibleOnAllWorkspaces(false);
    }

    if (!previousPrefs.widgetVisible && prefs.widgetVisible) {
      resizeWidgetForMode(prefs.widgetDisplayMode);
      placeWidgetNearBottomRight();
      widgetWindow.showInactive();
    } else if (previousPrefs.widgetVisible && !prefs.widgetVisible) {
      widgetWindow.hide();
    }
  }

  scheduleRefresh();
  broadcastState();
  return snapshotWithReminderHistory();
}

async function refreshQuota(options = {}) {
  readyState.isRefreshing = true;
  broadcastState();
  let snapshot = await readyState.refresh(options);
  if (snapshot.status === "available" && reminderStore) {
    snapshot = readyState.preserveKnownManualResetExpirations(
      reminderStore.knownManualResetExpirations()
    );
    const reminderBatch = reminderStore.prepare(snapshot.quota);
    const deliveredEvents = await deliverReminderNotifications(reminderBatch.events, snapshot.prefs.language);
    reminderStore.commit(reminderBatch, deliveredEvents);
  }
  broadcastState();
  return readyState.snapshot();
}

async function deliverReminderNotifications(events, language) {
  if (!Notification.isSupported()) {
    return [];
  }

  const deliveredEvents = [];
  for (const event of events) {
    const delivered = await new Promise((resolve) => {
      const notification = new Notification(reminderCopy(event, language));
      let settled = false;
      const finish = (value) => {
        if (settled) {
          return;
        }
        settled = true;
        resolve(value);
      };
      notification.on("click", () => showMainWindow());
      notification.once("show", () => finish(true));
      notification.once("failed", () => finish(false));
      try {
        notification.show();
      } catch {
        finish(false);
      }
      setTimeout(() => finish(false), 3000);
    });
    if (delivered) {
      deliveredEvents.push(event);
    }
  }
  return deliveredEvents;
}

async function deliverTestNotification(language) {
  if (!Notification.isSupported()) {
    return { delivered: false, supported: false };
  }
  const isEnglish = language === "en";
  const delivered = await new Promise((resolve) => {
    const notification = new Notification(isEnglish
      ? { title: "ReadyCheck notifications are working", body: "Windows displayed this test notification." }
      : { title: "ReadyCheck 通知正常", body: "Windows 已显示这条测试通知。" });
    let settled = false;
    const finish = (value) => {
      if (settled) return;
      settled = true;
      resolve(value);
    };
    notification.on("click", () => showMainWindow());
    notification.once("show", () => finish(true));
    notification.once("failed", () => finish(false));
    try {
      notification.show();
    } catch {
      finish(false);
    }
    setTimeout(() => finish(false), 3000);
  });
  return { delivered, supported: true };
}

function reminderCopy(event, language) {
  const isEnglish = language === "en";
  if (event.type === "manualResetExpiring") {
    const expiresAt = new Intl.DateTimeFormat(isEnglish ? "en-US" : "zh-CN", {
      dateStyle: "medium",
      timeStyle: "short"
    }).format(new Date(event.expiresAt));
    return isEnglish
      ? { title: "Reset credit expires soon", body: `Reset ${event.index} expires within ${event.leadHours} hours: ${expiresAt}` }
      : { title: "重置卡即将到期", body: `第 ${event.index} 次重置额度将在 ${event.leadHours} 小时内到期：${expiresAt}` };
  }
  return isEnglish
    ? { title: "Codex Credits are now in use", body: "Your Codex quota is exhausted. Current usage is now consuming Credits." }
    : { title: "已开始使用 Codex Credits", body: "Codex 额度已用尽，当前使用已开始消耗 Credits。" };
}

async function beginOAuth() {
  await startOAuthCallbackServer();
  try {
    const { authorizationURL, snapshot } = readyState.beginOAuth();
    broadcastState();
    await shell.openExternal(authorizationURL);
    return snapshot;
  } catch (error) {
    stopOAuthCallbackServer();
    throw error;
  }
}

async function disconnectAccount() {
  const snapshot = await readyState.disconnect();
  if (reminderStore) {
    reminderStore.clearKnownManualResetExpirations();
  }
  broadcastState();
  return snapshot;
}

function startOAuthCallbackServer() {
  if (oauthCallbackServer) {
    return Promise.resolve();
  }

  return new Promise((resolve, reject) => {
    const server = http.createServer(async (request, response) => {
      const requestURL = new URL(request.url, "http://localhost:1455");
      if (requestURL.pathname !== "/auth/callback") {
        response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
        response.end("Not found");
        return;
      }

      try {
        const previousAccountEmail = readyState.accountEmail;
        await readyState.completeOAuth(requestURL.toString());
        if (reminderStore
          && normalizedEmail(previousAccountEmail) !== normalizedEmail(readyState.accountEmail)) {
          reminderStore.clearKnownManualResetExpirations();
        }
        broadcastState();
        response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
        response.end(buildOAuthResultPage("ReadyCheck 授权完成，可以回到应用。"));
      } catch (error) {
        readyState.status = "authorizationFailed";
        broadcastState();
        response.writeHead(400, { "Content-Type": "text/html; charset=utf-8" });
        response.end(buildOAuthResultPage(`授权失败：${escapeHTML(error.message)}`));
      } finally {
        stopOAuthCallbackServer();
      }
    });

    server.once("error", reject);
    server.listen(1455, "localhost", () => {
      oauthCallbackServer = server;
      resolve();
    });
  });
}

function stopOAuthCallbackServer() {
  if (!oauthCallbackServer) {
    return;
  }
  oauthCallbackServer.close();
  oauthCallbackServer = null;
}

function buildOAuthResultPage(message) {
  return `<!doctype html><html lang="zh-CN"><meta charset="utf-8"><title>ReadyCheck</title><body style="font-family:system-ui;padding:32px;background:#111827;color:#f9fafb"><h1>ReadyCheck</h1><p>${message}</p></body></html>`;
}

function escapeHTML(value) {
  return String(value)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}

function normalizedEmail(value) {
  const normalized = String(value || "").trim().toLowerCase();
  return normalized || null;
}

function scheduleRefresh() {
  if (refreshTimer) {
    clearInterval(refreshTimer);
  }

  const intervalMs = readyState.prefs.refreshIntervalMinutes * 60 * 1000;
  refreshTimer = setInterval(() => {
    refreshQuota().catch(() => {});
  }, intervalMs);
}

function scheduleRateLimitEventRefresh() {
  if (rateLimitEventTimer) {
    clearTimeout(rateLimitEventTimer);
  }
  rateLimitEventTimer = setTimeout(() => {
    rateLimitEventTimer = null;
    if (!readyState) return;
    if (readyState.isRefreshing) {
      scheduleRateLimitEventRefresh();
      return;
    }
    refreshQuota({ forceSupplemental: true }).catch(() => {});
  }, 350);
}

function registerIpc() {
  ipcMain.handle("readycheck:get-state", () => snapshotWithReminderHistory());
  ipcMain.handle("readycheck:refresh", () => refreshQuota({ forceSupplemental: true }));
  ipcMain.handle("readycheck:begin-oauth", () => beginOAuth());
  ipcMain.handle("readycheck:disconnect", () => disconnectAccount());
  ipcMain.handle("readycheck:update-prefs", (_event, partial) => updatePrefs(partial));
  ipcMain.handle("readycheck:show-main-window", () => showMainWindow());
  ipcMain.handle("readycheck:reset-widget-position", () => placeWidgetNearBottomRight());
  ipcMain.handle("readycheck:test-notification", () => deliverTestNotification(readyState.prefs.language));
  ipcMain.handle("readycheck:open-notification-settings", () => {
    shell.openExternal("ms-settings:notifications");
  });
  ipcMain.handle("readycheck:open-release-page", () => {
    shell.openExternal("https://github.com/whnnick/readycheck/releases/latest");
  });
}

app.whenReady().then(async () => {
  if (!isWindows) {
    console.warn("ReadyCheck Windows preview is intended to run on Windows.");
  }

  const userDataPath = app.getPath("userData");
  prefsStore = new PrefsStore(userDataPath);
  reminderStore = new QuotaReminderStore(userDataPath);
  readyState = new ReadyCheckState(prefsStore.load(), {
    tokenStore: new EncryptedTokenStore(userDataPath),
    oauthClient: new CodexOAuthClient(),
    usageClient: new CodexUsageClient(),
    appServerClient: new CodexAppServerClient(),
    historyStore: new QuotaHistoryStore(userDataPath)
  });
  registerIpc();
  await readyState.reloadConnectionStatus();
  createMainWindow();
  createWidgetWindow();
  createTray();
  scheduleRefresh();
  rateLimitMonitor = new CodexAppServerRateLimitMonitor();
  rateLimitMonitor.start(scheduleRateLimitEventRefresh);
  refreshQuota({ forceSupplemental: true }).catch(() => {});
});

app.on("window-all-closed", () => {
  // Keep the tray app alive when the main window is closed.
});

app.on("before-quit", () => {
  if (refreshTimer) {
    clearInterval(refreshTimer);
  }
  if (rateLimitEventTimer) {
    clearTimeout(rateLimitEventTimer);
  }
  rateLimitMonitor?.stop();
  stopOAuthCallbackServer();
});
