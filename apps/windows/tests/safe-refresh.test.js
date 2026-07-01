"use strict";

const assert = require("node:assert/strict");
const { isAllowedForRefresh } = require("../src/services/safe-refresh");
const { normalizePrefs } = require("../src/services/prefs-store");

assert.equal(isAllowedForRefresh("https://chatgpt.com/backend-api/wham/usage"), true);
assert.equal(isAllowedForRefresh("https://api.openai.com/v1/organization/usage/completions"), true);
assert.equal(isAllowedForRefresh("https://api.openai.com/v1/organization/costs"), true);

assert.equal(isAllowedForRefresh("https://api.openai.com/v1/responses"), false);
assert.equal(isAllowedForRefresh("https://api.openai.com/v1/chat/completions"), false);
assert.equal(isAllowedForRefresh("https://chatgpt.com/backend-api/wham/usage-extra"), false);
assert.equal(isAllowedForRefresh("http://chatgpt.com/backend-api/wham/usage"), false);

assert.deepEqual(normalizePrefs({ refreshIntervalMinutes: 99, widgetDisplayMode: "full" }), {
  language: "zh-CN",
  refreshIntervalMinutes: 1,
  widgetVisible: true,
  widgetAlwaysOnTop: true,
  widgetDisplayMode: "minimal"
});

assert.deepEqual(
  normalizePrefs({
    language: "en",
    refreshIntervalMinutes: 3,
    widgetVisible: false,
    widgetAlwaysOnTop: false,
    widgetDisplayMode: "detailed"
  }),
  {
    language: "en",
    refreshIntervalMinutes: 3,
    widgetVisible: false,
    widgetAlwaysOnTop: false,
    widgetDisplayMode: "detailed"
  }
);

console.log("Windows safe-refresh checks passed.");
