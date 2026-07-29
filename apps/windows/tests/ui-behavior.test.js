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
assert.match(renderer, /state\.recoveryAction/);
assert.match(renderer, /quotaRetryButton.*readyCheck\.refresh/s);
assert.match(renderer, /quotaReconnectButton.*readyCheck\.beginOAuth/s);
assert.match(renderer, /Math\.round\(ratio \* 100\) === 0/);
assert.match(renderer, /额度用尽，等待重置/);
assert.match(renderer, /Codex Credits/);
assert.match(renderer, /function codexCreditsText\(details\)/);
assert.equal(renderer.includes("主动重置次数"), false);
assert.match(renderer, /function manualResetExpirationRows\(details\)/);
assert.match(renderer, /第 \$\{index \+ 1\} 次/);
assert.match(renderer, /const warning = quotaWarning\(ratio\);/);
assert.match(styles, /\.quota-warning\.critical,\s*\.quota-warning\.exhausted\s*\{[^}]*color:\s*var\(--red\);/s);
assert.match(renderer, /class="quota-row-footer"/);
assert.match(styles, /\.quota-row-footer\s*\{[^}]*display:\s*flex;[^}]*justify-content:\s*space-between;/s);

const rendererHTML = source("src/renderer.html");
assert.equal(rendererHTML.includes('id="usageDashboard"'), true);
assert.equal(rendererHTML.includes('id="quotaRecoveryActions"'), true);
assert.match(rendererHTML, /柱形表示每个时段检测到的额度下降/);
assert.match(renderer, /function renderOfficialTokenUsage\(tokenUsage\)/);
assert.match(renderer, /Codex 官方数据/);
assert.match(renderer, /每日 Token 使用/);
assert.match(renderer, /state\.quota && state\.quota\.tokenUsage/);
assert.equal(renderer.includes('filter((item) => !["quota.window.codex.5h"'), false);
assert.match(renderer, /usageWindowID/);
assert.match(renderer, /usageBars\(/);
assert.match(renderer, /observedUsageBars\(/);
assert.match(renderer, /MAX_USAGE_ATTRIBUTABLE_GAP_MS/);
assert.match(renderer, /const barWidth = 12;/);
assert.match(renderer, /usageChartHasAnimated/);
assert.match(renderer, /officialTokenChart/);
assert.match(renderer, /previousUsageBarsByContext/);
assert.match(renderer, /function alignedUsageRangeEnd\(timestamp, bucketSize\)/);
assert.match(renderer, /shouldAnimateDelta/);
assert.match(renderer, /--bar-start-scale/);
assert.match(renderer, /previousHeightRatio/);
assert.match(renderer, /previousMaximum/);
assert.match(renderer, /class="chart-value"/);
assert.match(renderer, /function usageChartMaximum\(values\)/);
assert.match(renderer, /highest \* 0\.15/);
assert.match(styles, /\.chart-bar\.animate\s*\{/);
assert.match(styles, /\.chart-bar\.delta\s*\{/);
assert.match(styles, /\.usage-chart\.switching\s*\{/);
assert.match(styles, /button\.usage-metric\.selected\s*\{[^}]*border-color:\s*transparent;/s);

const main = source("src/main.js");
assert.match(main, /minimal:\s*\{\s*width:\s*330,\s*height:\s*220\s*\}/);
assert.match(main, /detailed:\s*\{\s*width:\s*350,\s*height:\s*360\s*\}/);
assert.match(main, /previousPrefs\.widgetAlwaysOnTop !== prefs\.widgetAlwaysOnTop/);
assert.match(main, /setAlwaysOnTop\(prefs\.widgetAlwaysOnTop,\s*prefs\.widgetAlwaysOnTop \? "floating" : "normal"\)/);
assert.match(main, /!previousPrefs\.widgetVisible && prefs\.widgetVisible/);

console.log("Windows UI behavior checks passed.");
