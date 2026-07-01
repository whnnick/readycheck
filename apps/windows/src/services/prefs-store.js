"use strict";

const fs = require("node:fs");
const path = require("node:path");

const DEFAULT_PREFS = {
  language: "zh-CN",
  refreshIntervalMinutes: 1,
  widgetVisible: true,
  widgetAlwaysOnTop: true,
  widgetDisplayMode: "minimal"
};

class PrefsStore {
  constructor(userDataPath) {
    this.filePath = path.join(userDataPath, "readycheck-windows-preferences.json");
  }

  load() {
    try {
      const payload = fs.readFileSync(this.filePath, "utf8");
      const parsed = JSON.parse(payload);
      return normalizePrefs(parsed);
    } catch {
      return { ...DEFAULT_PREFS };
    }
  }

  save(prefs) {
    const normalized = normalizePrefs(prefs);
    fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
    fs.writeFileSync(this.filePath, `${JSON.stringify(normalized, null, 2)}\n`, "utf8");
    return normalized;
  }
}

function normalizePrefs(input) {
  const prefs = { ...DEFAULT_PREFS, ...(input || {}) };
  return {
    language: prefs.language === "en" ? "en" : "zh-CN",
    refreshIntervalMinutes: [1, 3, 5].includes(Number(prefs.refreshIntervalMinutes))
      ? Number(prefs.refreshIntervalMinutes)
      : DEFAULT_PREFS.refreshIntervalMinutes,
    widgetVisible: Boolean(prefs.widgetVisible),
    widgetAlwaysOnTop: Boolean(prefs.widgetAlwaysOnTop),
    widgetDisplayMode: prefs.widgetDisplayMode === "detailed" ? "detailed" : "minimal"
  };
}

module.exports = {
  DEFAULT_PREFS,
  PrefsStore,
  normalizePrefs
};
