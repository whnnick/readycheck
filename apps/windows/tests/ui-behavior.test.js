"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const appRoot = path.join(__dirname, "..");
const source = (relativePath) => fs.readFileSync(path.join(appRoot, relativePath), "utf8");

const widgetHTML = source("src/widget.html");
assert.equal(widgetHTML.includes("<select"), false, "widget must not use native select controls");
assert.equal(widgetHTML.includes('data-widget-mode-option="minimal"'), true);
assert.equal(widgetHTML.includes('data-widget-mode-option="detailed"'), true);

const styles = source("src/styles.css");
assert.match(styles, /\[data-surface="widget"\]\s*\{[^}]*overflow:\s*hidden;/s);
assert.match(styles, /\.widget\s*\{[^}]*height:\s*100vh;[^}]*overflow:\s*hidden;/s);
assert.match(styles, /\.widget #quotaContent\s*\{[^}]*overflow:\s*hidden;/s);
assert.match(styles, /\.segmented-control\s*\{[^}]*-webkit-app-region:\s*no-drag;/s);

const renderer = source("src/renderer.js");
assert.match(renderer, /event\.stopPropagation\(\);\s*updatePrefs\(\{ widgetDisplayMode:/s);
assert.match(renderer, /event\.target\.closest\("button, select, input"\)/);
assert.match(renderer, /Country, region, or territory not supported/);

const main = source("src/main.js");
assert.match(main, /minimal:\s*\{\s*width:\s*330,\s*height:\s*220\s*\}/);
assert.match(main, /detailed:\s*\{\s*width:\s*350,\s*height:\s*360\s*\}/);
assert.match(main, /previousPrefs\.widgetAlwaysOnTop !== prefs\.widgetAlwaysOnTop/);
assert.match(main, /setAlwaysOnTop\(prefs\.widgetAlwaysOnTop,\s*prefs\.widgetAlwaysOnTop \? "floating" : "normal"\)/);
assert.match(main, /!previousPrefs\.widgetVisible && prefs\.widgetVisible/);

console.log("Windows UI behavior checks passed.");
