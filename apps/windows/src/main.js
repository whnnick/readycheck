"use strict";

const http = require("node:http");
const path = require("node:path");
const { app, BrowserWindow, Menu, Tray, ipcMain, nativeImage, shell } = require("electron");
const { CodexOAuthClient } = require("./services/oauth");
const { PrefsStore } = require("./services/prefs-store");
const { ReadyCheckState } = require("./services/app-state");
const { EncryptedTokenStore } = require("./services/token-store");
const { CodexUsageClient } = require("./services/usage-client");

let mainWindow = null;
let widgetWindow = null;
let tray = null;
let prefsStore = null;
let readyState = null;
let refreshTimer = null;
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
    { label: "Refresh", click: () => refreshQuota() },
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
  const snapshot = readyState.snapshot();
  for (const window of BrowserWindow.getAllWindows()) {
    window.webContents.send("readycheck:state", snapshot);
  }
  if (tray) {
    tray.setContextMenu(buildTrayMenu());
  }
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
  return readyState.snapshot();
}

async function refreshQuota() {
  readyState.isRefreshing = true;
  broadcastState();
  const snapshot = await readyState.refresh();
  broadcastState();
  return snapshot;
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
        await readyState.completeOAuth(requestURL.toString());
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

function scheduleRefresh() {
  if (refreshTimer) {
    clearInterval(refreshTimer);
  }

  const intervalMs = readyState.prefs.refreshIntervalMinutes * 60 * 1000;
  refreshTimer = setInterval(() => {
    refreshQuota().catch(() => {});
  }, intervalMs);
}

function registerIpc() {
  ipcMain.handle("readycheck:get-state", () => readyState.snapshot());
  ipcMain.handle("readycheck:refresh", () => refreshQuota());
  ipcMain.handle("readycheck:begin-oauth", () => beginOAuth());
  ipcMain.handle("readycheck:disconnect", () => disconnectAccount());
  ipcMain.handle("readycheck:update-prefs", (_event, partial) => updatePrefs(partial));
  ipcMain.handle("readycheck:show-main-window", () => showMainWindow());
  ipcMain.handle("readycheck:reset-widget-position", () => placeWidgetNearBottomRight());
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
  readyState = new ReadyCheckState(prefsStore.load(), {
    tokenStore: new EncryptedTokenStore(userDataPath),
    oauthClient: new CodexOAuthClient(),
    usageClient: new CodexUsageClient()
  });
  registerIpc();
  await readyState.reloadConnectionStatus();
  createMainWindow();
  createWidgetWindow();
  createTray();
  scheduleRefresh();
  refreshQuota().catch(() => {});
});

app.on("window-all-closed", () => {
  // Keep the tray app alive when the main window is closed.
});

app.on("before-quit", () => {
  if (refreshTimer) {
    clearInterval(refreshTimer);
  }
  stopOAuthCallbackServer();
});
