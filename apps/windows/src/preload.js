"use strict";

const { contextBridge, ipcRenderer } = require("electron");

contextBridge.exposeInMainWorld("readyCheck", {
  getState: () => ipcRenderer.invoke("readycheck:get-state"),
  refresh: () => ipcRenderer.invoke("readycheck:refresh"),
  beginOAuth: () => ipcRenderer.invoke("readycheck:begin-oauth"),
  disconnect: () => ipcRenderer.invoke("readycheck:disconnect"),
  updatePrefs: (prefs) => ipcRenderer.invoke("readycheck:update-prefs", prefs),
  showMainWindow: () => ipcRenderer.invoke("readycheck:show-main-window"),
  resetWidgetPosition: () => ipcRenderer.invoke("readycheck:reset-widget-position"),
  openReleasePage: () => ipcRenderer.invoke("readycheck:open-release-page"),
  onState: (callback) => {
    const listener = (_event, state) => callback(state);
    ipcRenderer.on("readycheck:state", listener);
    return () => ipcRenderer.removeListener("readycheck:state", listener);
  }
});
