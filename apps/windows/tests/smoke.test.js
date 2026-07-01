"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const { OAUTH_CONFIG } = require("../src/services/oauth");
const { isAllowedForRefresh } = require("../src/services/safe-refresh");

const appRoot = path.join(__dirname, "..");

for (const relativePath of [
  "src/main.js",
  "src/preload.js",
  "src/renderer.html",
  "src/widget.html",
  "src/services/app-state.js",
  "src/services/oauth.js",
  "src/services/token-store.js",
  "src/services/usage-client.js",
  "src/services/usage-parser.js"
]) {
  assert.equal(fs.existsSync(path.join(appRoot, relativePath)), true, `${relativePath} should exist`);
}

assert.equal(OAUTH_CONFIG.redirectURI, "http://localhost:1455/auth/callback");
assert.equal(OAUTH_CONFIG.scopes.includes("offline_access"), true);
assert.equal(isAllowedForRefresh("https://chatgpt.com/backend-api/wham/usage"), true);
assert.equal(isAllowedForRefresh("https://api.openai.com/v1/chat/completions"), false);

const packageJSON = JSON.parse(fs.readFileSync(path.join(appRoot, "package.json"), "utf8"));
assert.equal(packageJSON.main, "src/main.js");
assert.equal(typeof packageJSON.scripts.start, "string");
assert.equal(typeof packageJSON.scripts.check, "string");

const widgetHTML = fs.readFileSync(path.join(appRoot, "src/widget.html"), "utf8");
assert.equal(widgetHTML.includes("<select"), false, "widget should not use native select controls");
assert.equal(widgetHTML.includes('data-widget-mode-option="minimal"'), true);
assert.equal(widgetHTML.includes('data-widget-mode-option="detailed"'), true);

const rendererHTML = fs.readFileSync(path.join(appRoot, "src/renderer.html"), "utf8");
assert.equal(rendererHTML.includes('id="oauthStatusText"'), true);

console.log("Windows smoke checks passed.");
