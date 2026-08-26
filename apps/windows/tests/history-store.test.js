"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { QuotaHistoryStore, makeSample } = require("../src/services/history-store");

const directory = fs.mkdtempSync(path.join(os.tmpdir(), "readycheck-history-"));
const store = new QuotaHistoryStore(directory);
const quota = {
  windows: [
    { id: "codex-5h", labelKey: "quota.window.codex.5h", displayLabel: "Codex allowance", remainingRatio: 0.8, resetAt: null, status: "available" },
    { id: "codex-7d", labelKey: "quota.window.codex.7d", remainingRatio: 0.7, resetAt: null, status: "available" }
  ]
};

assert.equal(makeSample({ windows: [] }, new Date()), null);

const firstDate = new Date("2026-07-14T00:00:00.000Z");
assert.equal(store.record(quota, firstDate).length, 1);

quota.windows[0].remainingRatio = 0.75;
const replacement = store.record(quota, new Date("2026-07-14T00:00:30.000Z"));
assert.equal(replacement.length, 1, "samples inside one minute should share one bucket");
assert.equal(replacement[0].values[0].remainingRatio, 0.75);
assert.equal(replacement[0].values[0].displayLabel, "Codex allowance");

const appended = store.record(quota, new Date("2026-07-14T00:01:00.000Z"));
assert.equal(appended.length, 2);
assert.equal(Object.hasOwn(appended[0], "accountEmail"), false);

const pollutedPath = path.join(directory, "quota-history.json");
fs.writeFileSync(pollutedPath, JSON.stringify([{ ...appended[0], accountEmail: "private@example.com" }]), "utf8");
const sanitized = store.load(new Date("2026-07-14T00:01:00.000Z"));
assert.equal(Object.hasOwn(sanitized[0], "accountEmail"), false, "unknown identity fields must be discarded on load");

const minuteDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "readycheck-minute-history-"));
const minuteStore = new QuotaHistoryStore(minuteDirectory);
let minuteSamples = [];
for (let minute = 0; minute <= 6; minute += 1) {
  minuteSamples = minuteStore.record(quota, new Date(Date.UTC(2026, 6, 14, 0, minute, 0)));
}
assert.equal(minuteSamples.length, 7, "one-minute refreshes should append in every fixed minute bucket");
fs.rmSync(minuteDirectory, { recursive: true, force: true });

const afterRetention = store.load(new Date("2026-08-20T00:00:00.000Z"));
assert.equal(afterRetention.length, 0, "samples older than 30 days should be excluded");

fs.rmSync(directory, { recursive: true, force: true });
console.log("Windows quota history checks passed.");
