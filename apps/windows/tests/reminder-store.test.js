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

const expiration = new Date(now.getTime() + 73 * 60 * 60 * 1000).toISOString();
let expiryResult = evaluateQuotaReminders(quota(0.5, "10", [expiration]), {}, now);
assert.deepEqual(expiryResult.events, []);
for (const [elapsedHours, leadHours] of [[2, 72], [26, 48], [50, 24], [62, 12]]) {
  expiryResult = evaluateQuotaReminders(
    quota(0.5, "10", [expiration]),
    expiryResult.state,
    new Date(now.getTime() + elapsedHours * 60 * 60 * 1000)
  );
  assert.deepEqual(expiryResult.events, [{
    type: "manualResetExpiring",
    index: 1,
    expiresAt: expiration,
    leadHours
  }]);
}
assert.deepEqual(
  evaluateQuotaReminders(quota(0.5, "10", [expiration]), expiryResult.state, new Date(now.getTime() + 63 * 60 * 60 * 1000)).events,
  [],
  "each expiration threshold must alert only once"
);

const urgentExpiration = new Date(now.getTime() + 10 * 60 * 60 * 1000).toISOString();
const urgentResult = evaluateQuotaReminders(quota(0.5, "10", [urgentExpiration]), {}, now);
assert.deepEqual(urgentResult.events, [{
  type: "manualResetExpiring",
  index: 1,
  expiresAt: urgentExpiration,
  leadHours: 12
}], "missed thresholds must collapse into the most urgent reminder");
assert.deepEqual(
  evaluateQuotaReminders(quota(0.5, "10", [urgentExpiration]), urgentResult.state, new Date(now.getTime() + 60 * 1000)).events,
  []
);

const usedExpiration = new Date(now.getTime() + 71 * 60 * 60 * 1000).toISOString();
const beforeUse = evaluateQuotaReminders(quota(0.5, "10", [usedExpiration]), {}, now);
assert.equal(beforeUse.events[0].leadHours, 72);
assert.deepEqual(
  evaluateQuotaReminders(quota(0.5, "10", [], null, 0), beforeUse.state, new Date(now.getTime() + 24 * 60 * 60 * 1000)).events,
  [],
  "a used reset must not produce later reminders"
);

const legacyTimestamp = new Date(usedExpiration).getTime();
const migrated = evaluateQuotaReminders(
  quota(0.5, "10", [usedExpiration]),
  { notifiedManualResetExpirations: [legacyTimestamp] },
  now
);
assert.deepEqual(migrated.events, [], "the legacy 72-hour reminder must not repeat after upgrade");
assert.deepEqual(migrated.state.notifiedManualResetExpirations, []);
assert.ok(migrated.state.notifiedManualResetThresholds.includes(`${legacyTimestamp}:72`));

const driftedExpiration = new Date(legacyTimestamp + 1000).toISOString();
assert.deepEqual(
  evaluateQuotaReminders(
    quota(0.5, "10", [driftedExpiration]),
    { notifiedManualResetThresholds: [`${legacyTimestamp}:72`] },
    now
  ).events,
  [],
  "small expiry timestamp drift must not repeat a delivered threshold"
);

const knownExpiration = new Date(now.getTime() + 40 * 60 * 60 * 1000);
const knownTimestamp = knownExpiration.getTime();
const missingPayload = evaluateQuotaReminders(
  quota(0.5, "10"),
  { knownManualResetExpirations: [knownTimestamp] },
  now
);
assert.deepEqual(missingPayload.events, [{
  type: "manualResetExpiring",
  index: 1,
  expiresAt: knownExpiration.toISOString(),
  leadHours: 48
}], "a temporarily missing reset payload must keep a verified future expiry active");
assert.deepEqual(
  evaluateQuotaReminders(
    quota(0.5, "10", [], null, 0),
    { knownManualResetExpirations: [knownTimestamp] },
    now
  ).events,
  [],
  "an explicit zero reset count must clear the verified expiry"
);

const directory = fs.mkdtempSync(path.join(os.tmpdir(), "readycheck-reminders-"));
const store = new QuotaReminderStore(directory);
store.evaluate(quota(0.2, "10"), now);
store.evaluate(quota(0, "10"), now);
assert.deepEqual(store.evaluate(quota(0, "9.5"), now), [{ type: "creditsStarted" }]);
assert.deepEqual(new QuotaReminderStore(directory).evaluate(quota(0, "9"), now), []);
fs.rmSync(directory, { recursive: true, force: true });

const deliveryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "readycheck-reminder-delivery-"));
const deliveryStore = new QuotaReminderStore(deliveryDirectory);
const deliveryQuota = quota(0.5, "10", [knownExpiration.toISOString()]);
const firstDelivery = deliveryStore.prepare(deliveryQuota, now);
assert.equal(firstDelivery.events[0].leadHours, 48);
deliveryStore.commit(firstDelivery, [], now);
let reminderHistory = deliveryStore.history();
assert.equal(reminderHistory.length, 1);
assert.equal(reminderHistory[0].status, "failed");
assert.equal(reminderHistory[0].attemptCount, 1);
const retryDelivery = deliveryStore.prepare(deliveryQuota, new Date(now.getTime() + 60 * 1000));
assert.equal(retryDelivery.events[0].leadHours, 48, "failed delivery must retry the same threshold");
deliveryStore.commit(retryDelivery, retryDelivery.events, new Date(now.getTime() + 60 * 1000));
reminderHistory = deliveryStore.history();
assert.equal(reminderHistory.length, 1);
assert.equal(reminderHistory[0].status, "delivered");
assert.equal(reminderHistory[0].attemptCount, 2);
assert.deepEqual(
  deliveryStore.prepare(deliveryQuota, new Date(now.getTime() + 120 * 1000)).events,
  [],
  "confirmed delivery must not repeat"
);
fs.rmSync(deliveryDirectory, { recursive: true, force: true });

const legacyDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "readycheck-reminder-legacy-"));
fs.writeFileSync(path.join(legacyDirectory, "quota-reminders.json"), JSON.stringify({
  notifiedManualResetThresholds: [`${legacyTimestamp}:48`]
}));
const legacyHistory = new QuotaReminderStore(legacyDirectory).history();
assert.equal(legacyHistory.length, 1);
assert.equal(legacyHistory[0].status, "legacyUnknown");
assert.equal(legacyHistory[0].leadHours, 48);
assert.equal(legacyHistory[0].attemptCount, 0);
const persistedLegacyState = JSON.parse(fs.readFileSync(path.join(legacyDirectory, "quota-reminders.json"), "utf8"));
assert.equal(persistedLegacyState.notificationHistoryMigrationCompleted, true);
assert.equal(persistedLegacyState.notificationHistory.length, 1);
fs.rmSync(legacyDirectory, { recursive: true, force: true });

function quota(remainingRatio, creditBalance, manualResetExpirations = [], resetAt = null, manualResetCount = null) {
  return {
    manualResetExpirations,
    manualResetCount,
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
