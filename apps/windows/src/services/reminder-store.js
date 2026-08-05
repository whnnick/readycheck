"use strict";

const fs = require("node:fs");
const path = require("node:path");

const MANUAL_RESET_LEAD_TIME_MS = 3 * 24 * 60 * 60 * 1000;

class QuotaReminderStore {
  constructor(userDataPath) {
    this.filePath = path.join(userDataPath, "quota-reminders.json");
  }

  evaluate(quota, now = new Date()) {
    const result = evaluateQuotaReminders(quota, this.load(), now);
    this.save(result.state);
    return result.events;
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

  const notified = new Set(state.notifiedManualResetExpirations);
  const expirations = quota && Array.isArray(quota.manualResetExpirations)
    ? quota.manualResetExpirations
    : [];
  expirations.forEach((value, index) => {
    const timestamp = new Date(value).getTime();
    const interval = timestamp - nowMs;
    if (!Number.isFinite(timestamp)
      || interval <= 0
      || interval > MANUAL_RESET_LEAD_TIME_MS
      || notified.has(timestamp)) {
      return;
    }
    events.push({ type: "manualResetExpiring", index: index + 1, expiresAt: new Date(timestamp).toISOString() });
    notified.add(timestamp);
  });
  state.notifiedManualResetExpirations = [...notified].sort((left, right) => left - right);

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
    previousCreditBalance: typeof (input && input.previousCreditBalance) === "string"
      ? input.previousCreditBalance
      : null,
    creditsReminderSentForCurrentExhaustion: Boolean(input && input.creditsReminderSentForCurrentExhaustion),
    creditExhaustionCycleKey: typeof (input && input.creditExhaustionCycleKey) === "string"
      ? input.creditExhaustionCycleKey
      : null
  };
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
  MANUAL_RESET_LEAD_TIME_MS,
  QuotaReminderStore,
  evaluateQuotaReminders,
  normalizeState,
  parseCreditBalance
};
