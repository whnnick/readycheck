"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const {
  QuotaReminderStore,
  evaluateQuotaReminders
} = require("../src/services/reminder-store");

const now = new Date("2026-08-05T00:00:00.000Z");
let state = evaluateQuotaReminders(quota(0.2, "10"), {}, now).state;
state = evaluateQuotaReminders(quota(0, "10"), state, now).state;

let result = evaluateQuotaReminders(quota(0, "9.5"), state, now);
assert.deepEqual(result.events, [{ type: "creditsStarted" }]);

result = evaluateQuotaReminders(quota(0, "9"), result.state, now);
assert.deepEqual(result.events, []);

state = evaluateQuotaReminders(quota(0.8, "9"), result.state, now).state;
state = evaluateQuotaReminders(quota(0, "9"), state, now).state;
result = evaluateQuotaReminders(quota(0, "8.5"), state, now);
assert.deepEqual(result.events, [{ type: "creditsStarted" }]);

state = evaluateQuotaReminders(quota(0.5, "10"), {}, now).state;
result = evaluateQuotaReminders(quota(0.4, "9"), state, now);
assert.deepEqual(result.events, [], "credits must not alert while quota remains");

state = evaluateQuotaReminders(quota(0.2, "10", [], "2026-08-05T01:00:00.000Z"), {}, now).state;
state = evaluateQuotaReminders(quota(0, "10", [], "2026-08-05T01:00:00.000Z"), state, now).state;
state = evaluateQuotaReminders(quota(0, "9", [], "2026-08-05T01:00:00.000Z"), state, now).state;
result = evaluateQuotaReminders(quota(0, "8.5", [], "2026-08-05T02:00:00.000Z"), state, now);
assert.deepEqual(result.events, [{ type: "creditsStarted" }], "a new reset cycle must re-arm the reminder");

const soon = new Date(now.getTime() + 71 * 60 * 60 * 1000).toISOString();
const later = new Date(now.getTime() + 80 * 60 * 60 * 1000).toISOString();
const firstExpiry = evaluateQuotaReminders(quota(0.5, "10", [soon, later]), {}, now);
assert.deepEqual(firstExpiry.events, [{ type: "manualResetExpiring", index: 1, expiresAt: soon }]);
assert.deepEqual(
  evaluateQuotaReminders(quota(0.5, "10", [soon, later]), firstExpiry.state, now).events,
  [],
  "an expiration must alert only once"
);

const directory = fs.mkdtempSync(path.join(os.tmpdir(), "readycheck-reminders-"));
const store = new QuotaReminderStore(directory);
store.evaluate(quota(0.2, "10"), now);
store.evaluate(quota(0, "10"), now);
assert.deepEqual(store.evaluate(quota(0, "9.5"), now), [{ type: "creditsStarted" }]);
assert.deepEqual(new QuotaReminderStore(directory).evaluate(quota(0, "9"), now), []);
fs.rmSync(directory, { recursive: true, force: true });

function quota(remainingRatio, creditBalance, manualResetExpirations = [], resetAt = null) {
  return {
    manualResetExpirations,
    creditBalance,
    windows: [{
      id: "codex-primary",
      status: "available",
      confidence: "verified",
      remainingRatio,
      resetAt
    }]
  };
}

console.log("Windows quota reminder checks passed.");
