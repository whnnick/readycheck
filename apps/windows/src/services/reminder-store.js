"use strict";

const fs = require("node:fs");
const path = require("node:path");

const MANUAL_RESET_LEAD_HOURS = [12, 24, 48, 72];
const REMINDER_HISTORY_LIMIT = 50;

class QuotaReminderStore {
  constructor(userDataPath) {
    this.filePath = path.join(userDataPath, "quota-reminders.json");
  }

  evaluate(quota, now = new Date()) {
    const batch = this.prepare(quota, now);
    this.commit(batch, batch.events);
    return batch.events;
  }

  prepare(quota, now = new Date()) {
    const previousState = migrateHistoryIfNeeded(this.load());
    const result = evaluateQuotaReminders(quota, previousState, now);
    return {
      previousState,
      proposedState: result.state,
      events: result.events
    };
  }

  commit(batch, deliveredEvents, now = new Date()) {
    const delivered = new Set(deliveredEvents.map(eventKey));
    const previousState = migrateHistoryIfNeeded(batch.previousState);
    const state = migrateHistoryIfNeeded(batch.proposedState);
    for (const event of batch.events) {
      if (delivered.has(eventKey(event))) {
        continue;
      }
      if (event.type === "manualResetExpiring") {
        const timestamp = new Date(event.expiresAt).getTime();
        const previousThresholds = migratedThresholds(previousState);
        state.notifiedManualResetThresholds = state.notifiedManualResetThresholds
          .filter((key) => !thresholdMatchesExpiration(key, timestamp))
          .concat(previousThresholds.filter((key) => thresholdMatchesExpiration(key, timestamp)));
      } else if (event.type === "creditsStarted") {
        const previous = normalizeState(previousState);
        state.previousCreditBalance = previous.previousCreditBalance;
        state.creditsReminderSentForCurrentExhaustion = previous.creditsReminderSentForCurrentExhaustion;
        state.creditExhaustionCycleKey = previous.creditExhaustionCycleKey;
      }
    }
    for (const event of batch.events) {
      recordHistory(state, event, delivered.has(eventKey(event)), batch.proposedState.creditExhaustionCycleKey, now);
    }
    this.save(state);
  }

  history() {
    const storedState = this.load();
    const migratedState = migrateHistoryIfNeeded(storedState);
    if (!storedState.notificationHistoryMigrationCompleted) {
      this.save(migratedState);
    }
    return migratedState.notificationHistory;
  }

  knownManualResetExpirations(now = new Date()) {
    const state = migrateHistoryIfNeeded(this.load());
    const nowMs = now.getTime();
    return deduplicatedExpirationTimestamps(
      state.knownManualResetExpirations.concat(
        migratedThresholds(state).map(expirationTimestampFromKey)
      ),
      nowMs
    ).map((timestamp) => new Date(timestamp).toISOString());
  }

  clearKnownManualResetExpirations() {
    const state = migrateHistoryIfNeeded(this.load());
    state.knownManualResetExpirations = [];
    state.notifiedManualResetExpirations = [];
    state.notifiedManualResetThresholds = [];
    this.save(state);
  }

  load() {
    try {
      return normalizeState(JSON.parse(fs.readFileSync(this.filePath, "utf8")));
    } catch {
      return normalizeState({});
    }
  }

  save(state) {
    try {
      fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
      const temporaryPath = `${this.filePath}.tmp`;
      fs.writeFileSync(temporaryPath, `${JSON.stringify(normalizeState(state), null, 2)}\n`, "utf8");
      fs.renameSync(temporaryPath, this.filePath);
    } catch {
      // Reminder persistence must never prevent quota refresh.
    }
  }
}

function evaluateQuotaReminders(quota, originalState, now = new Date()) {
  const state = normalizeState(originalState);
  const events = [];
  const nowMs = now.getTime();
  state.notifiedManualResetExpirations = state.notifiedManualResetExpirations
    .filter((timestamp) => timestamp >= nowMs);
  const notified = new Set(state.notifiedManualResetThresholds
    .filter((key) => expirationTimestampFromKey(key) >= nowMs));
  for (const timestamp of state.notifiedManualResetExpirations) {
    notified.add(thresholdKey(timestamp, 72));
  }
  state.notifiedManualResetExpirations = [];
  const reportedExpirations = quota && Array.isArray(quota.manualResetExpirations)
    ? quota.manualResetExpirations
    : [];
  const reportedCount = Number.isInteger(quota && quota.manualResetCount)
    ? quota.manualResetCount
    : null;
  let knownExpirations;
  if (reportedExpirations.length > 0) {
    knownExpirations = deduplicatedExpirationTimestamps(
      reportedExpirations.map((value) => new Date(value).getTime()),
      nowMs
    );
  } else if (reportedCount === 0) {
    knownExpirations = [];
  } else {
    knownExpirations = deduplicatedExpirationTimestamps(
      state.knownManualResetExpirations.concat([...notified].map(expirationTimestampFromKey)),
      nowMs
    );
  }
  state.knownManualResetExpirations = knownExpirations;
  knownExpirations.forEach((timestamp, index) => {
    const interval = timestamp - nowMs;
    if (!Number.isFinite(timestamp) || interval <= 0) {
      return;
    }
    const eligibleHours = MANUAL_RESET_LEAD_HOURS
      .filter((leadHours) => interval <= leadHours * 60 * 60 * 1000);
    const leadHours = eligibleHours
      .find((hours) => !thresholdWasNotified(notified, timestamp, hours));
    if (!leadHours) {
      return;
    }
    events.push({
      type: "manualResetExpiring",
      index: index + 1,
      expiresAt: new Date(timestamp).toISOString(),
      leadHours
    });
    for (const handledHours of eligibleHours) {
      notified.add(thresholdKey(timestamp, handledHours));
    }
  });
  state.notifiedManualResetThresholds = [...notified].sort();

  const validWindows = quota && Array.isArray(quota.windows)
    ? quota.windows
      .filter((window) => window && window.status === "available" && window.confidence !== "unknown")
      .filter((window) => Number.isFinite(Number(window.remainingRatio)))
    : [];
  const currentBalance = parseCreditBalance(quota && quota.creditBalance);
  if (validWindows.length === 0 || currentBalance === null) {
    return { state, events };
  }

  const exhaustedWindows = validWindows.filter((window) => Math.round(Number(window.remainingRatio) * 100) === 0);
  const previousBalance = parseCreditBalance(state.previousCreditBalance);
  if (exhaustedWindows.length === 0) {
    state.creditsReminderSentForCurrentExhaustion = false;
    state.creditExhaustionCycleKey = null;
  } else {
    const cycleKey = exhaustedWindows
      .map((window) => `${window.id}:${resetTimestamp(window.resetAt)}`)
      .sort()
      .join("|");
    if (state.creditExhaustionCycleKey !== cycleKey) {
      state.creditExhaustionCycleKey = cycleKey;
      state.creditsReminderSentForCurrentExhaustion = false;
    }
    if (!state.creditsReminderSentForCurrentExhaustion
      && previousBalance !== null
      && currentBalance < previousBalance) {
      events.push({ type: "creditsStarted" });
      state.creditsReminderSentForCurrentExhaustion = true;
    }
  }

  state.previousCreditBalance = String(quota.creditBalance);
  return { state, events };
}

function normalizeState(input) {
  const expirations = input && Array.isArray(input.notifiedManualResetExpirations)
    ? input.notifiedManualResetExpirations.map(Number).filter(Number.isFinite)
    : [];
  return {
    notifiedManualResetExpirations: [...new Set(expirations)].sort((left, right) => left - right),
    notifiedManualResetThresholds: [...new Set(
      input && Array.isArray(input.notifiedManualResetThresholds)
        ? input.notifiedManualResetThresholds.filter((value) => typeof value === "string")
        : []
    )].sort(),
    previousCreditBalance: typeof (input && input.previousCreditBalance) === "string"
      ? input.previousCreditBalance
      : null,
    knownManualResetExpirations: deduplicatedExpirationTimestamps(
      input && Array.isArray(input.knownManualResetExpirations)
        ? input.knownManualResetExpirations.map(Number)
        : [],
      Number.NEGATIVE_INFINITY
    ),
    creditsReminderSentForCurrentExhaustion: Boolean(input && input.creditsReminderSentForCurrentExhaustion),
    creditExhaustionCycleKey: typeof (input && input.creditExhaustionCycleKey) === "string"
      ? input.creditExhaustionCycleKey
      : null,
    notificationHistory: normalizeHistory(input && input.notificationHistory),
    notificationHistoryMigrationCompleted: Boolean(input && input.notificationHistoryMigrationCompleted)
  };
}

function normalizeHistory(input) {
  if (!Array.isArray(input)) {
    return [];
  }
  return input
    .filter((record) => record && typeof record.id === "string")
    .map((record) => ({
      id: record.id,
      kind: record.kind === "creditsStarted" ? "creditsStarted" : "manualResetExpiring",
      status: ["delivered", "failed", "legacyUnknown"].includes(record.status)
        ? record.status
        : "legacyUnknown",
      lastAttemptAt: validISOString(record.lastAttemptAt),
      deliveredAt: validISOString(record.deliveredAt),
      expiresAt: validISOString(record.expiresAt),
      leadHours: Number.isInteger(record.leadHours) ? record.leadHours : null,
      resetIndex: Number.isInteger(record.resetIndex) ? record.resetIndex : null,
      attemptCount: Number.isInteger(record.attemptCount) && record.attemptCount >= 0
        ? record.attemptCount
        : 0
    }))
    .sort((left, right) => historySortTimestamp(right) - historySortTimestamp(left))
    .slice(0, REMINDER_HISTORY_LIMIT);
}

function migrateHistoryIfNeeded(input) {
  const state = normalizeState(input);
  if (state.notificationHistoryMigrationCompleted) {
    return state;
  }
  const history = [...state.notificationHistory];
  const existingIDs = new Set(history.map((record) => record.id));
  for (const key of migratedThresholds(state)) {
    const [timestamp, leadHours] = String(key).split(":").map(Number);
    if (!Number.isFinite(timestamp) || !Number.isInteger(leadHours)) {
      continue;
    }
    const id = `legacy-reset:${timestamp}:${leadHours}`;
    if (existingIDs.has(id)) {
      continue;
    }
    history.push({
      id,
      kind: "manualResetExpiring",
      status: "legacyUnknown",
      lastAttemptAt: null,
      deliveredAt: null,
      expiresAt: new Date(timestamp).toISOString(),
      leadHours,
      resetIndex: null,
      attemptCount: 0
    });
  }
  state.notificationHistory = normalizeHistory(history);
  state.notificationHistoryMigrationCompleted = true;
  return state;
}

function recordHistory(state, event, delivered, cycleKey, now) {
  const attemptTime = new Date(now).toISOString();
  let id;
  let expiresAt = null;
  let leadHours = null;
  let resetIndex = null;
  if (event.type === "manualResetExpiring") {
    expiresAt = new Date(event.expiresAt).toISOString();
    leadHours = event.leadHours;
    resetIndex = event.index;
    const timestamp = new Date(expiresAt).getTime();
    const matching = state.notificationHistory.find((record) => record.kind === "manualResetExpiring"
      && record.leadHours === leadHours
      && record.expiresAt
      && Math.abs(new Date(record.expiresAt).getTime() - timestamp) <= 5000);
    id = matching ? matching.id : `reset:${timestamp}:${leadHours}`;
  } else {
    id = `credits:${cycleKey || "unknown"}`;
  }
  const existing = state.notificationHistory.find((record) => record.id === id);
  state.notificationHistory = normalizeHistory(state.notificationHistory
    .filter((record) => record.id !== id)
    .concat({
      id,
      kind: event.type,
      status: delivered ? "delivered" : "failed",
      lastAttemptAt: attemptTime,
      deliveredAt: delivered ? attemptTime : (existing && existing.deliveredAt),
      expiresAt,
      leadHours,
      resetIndex,
      attemptCount: (existing ? existing.attemptCount : 0) + 1
    }));
}

function validISOString(value) {
  if (!value || !Number.isFinite(new Date(value).getTime())) {
    return null;
  }
  return new Date(value).toISOString();
}

function historySortTimestamp(record) {
  if (record.lastAttemptAt) {
    return new Date(record.lastAttemptAt).getTime();
  }
  const expiresAt = new Date(record.expiresAt || 0).getTime();
  return Number.isInteger(record.leadHours)
    ? expiresAt - record.leadHours * 60 * 60 * 1000
    : expiresAt;
}

function thresholdKey(expirationTimestamp, leadHours) {
  return `${expirationTimestamp}:${leadHours}`;
}

function expirationTimestampFromKey(key) {
  const timestamp = Number(String(key).split(":", 1)[0]);
  return Number.isFinite(timestamp) ? timestamp : Number.NEGATIVE_INFINITY;
}

function thresholdWasNotified(thresholds, expirationTimestamp, leadHours) {
  for (const key of thresholds) {
    const [storedTimestamp, storedLeadHours] = String(key).split(":").map(Number);
    if (Number.isFinite(storedTimestamp)
      && Math.abs(storedTimestamp - expirationTimestamp) <= 5000
      && storedLeadHours === leadHours) {
      return true;
    }
  }
  return false;
}

function thresholdMatchesExpiration(key, expirationTimestamp) {
  return Math.abs(expirationTimestampFromKey(key) - expirationTimestamp) <= 5000;
}

function deduplicatedExpirationTimestamps(timestamps, nowMs) {
  const result = [];
  for (const timestamp of timestamps.map(Number).filter(Number.isFinite).filter((value) => value >= nowMs).sort((a, b) => a - b)) {
    if (result.length > 0 && Math.abs(timestamp - result[result.length - 1]) <= 5000) {
      continue;
    }
    result.push(timestamp);
  }
  return result;
}

function migratedThresholds(stateInput) {
  const state = normalizeState(stateInput);
  const thresholds = new Set(state.notifiedManualResetThresholds);
  for (const timestamp of state.notifiedManualResetExpirations) {
    thresholds.add(thresholdKey(timestamp, 72));
  }
  return [...thresholds];
}

function eventKey(event) {
  return event.type === "manualResetExpiring"
    ? `${event.type}:${event.expiresAt}:${event.leadHours}`
    : event.type;
}

function resetTimestamp(value) {
  if (!value) {
    return "unknown";
  }
  const timestamp = new Date(value).getTime();
  return Number.isFinite(timestamp) ? String(timestamp) : "unknown";
}

function parseCreditBalance(value) {
  if (typeof value !== "string" && typeof value !== "number") {
    return null;
  }
  const parsed = Number(String(value).replaceAll(",", "").trim());
  return Number.isFinite(parsed) ? parsed : null;
}

module.exports = {
  MANUAL_RESET_LEAD_HOURS,
  REMINDER_HISTORY_LIMIT,
  QuotaReminderStore,
  evaluateQuotaReminders,
  migrateHistoryIfNeeded,
  normalizeState,
  parseCreditBalance
};
