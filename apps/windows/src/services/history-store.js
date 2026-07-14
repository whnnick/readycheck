"use strict";

const fs = require("node:fs");
const path = require("node:path");

const RETENTION_MS = 30 * 24 * 60 * 60 * 1000;
const SAMPLE_INTERVAL_MS = 60 * 1000;

class QuotaHistoryStore {
  constructor(userDataPath) {
    this.filePath = path.join(userDataPath, "quota-history.json");
  }

  load(now = new Date()) {
    try {
      const samples = JSON.parse(fs.readFileSync(this.filePath, "utf8"));
      return normalizeSamples(samples, now);
    } catch {
      return [];
    }
  }

  record(quota, recordedAt = new Date()) {
    const sample = makeSample(quota, recordedAt);
    if (!sample) {
      return this.load(recordedAt);
    }

    const samples = this.load(recordedAt);
    const last = samples.at(-1);
    if (last && sampleBucket(sample.recordedAt) === sampleBucket(last.recordedAt)) {
      samples[samples.length - 1] = sample;
    } else {
      samples.push(sample);
    }

    const normalized = normalizeSamples(samples, recordedAt);
    try {
      fs.mkdirSync(path.dirname(this.filePath), { recursive: true });
      const temporaryPath = `${this.filePath}.tmp`;
      fs.writeFileSync(temporaryPath, `${JSON.stringify(normalized, null, 2)}\n`, "utf8");
      fs.renameSync(temporaryPath, this.filePath);
    } catch {
      // History is optional and must never prevent a quota refresh.
    }
    return normalized;
  }
}

function sampleBucket(value) {
  return Math.floor(new Date(value).getTime() / SAMPLE_INTERVAL_MS);
}

function makeSample(quota, recordedAt) {
  const values = (quota && Array.isArray(quota.windows) ? quota.windows : [])
    .filter((window) => window.status === "available" && Number.isFinite(window.remainingRatio))
    .map((window) => ({
      windowID: String(window.id),
      labelKey: String(window.labelKey),
      remainingRatio: Math.min(Math.max(Number(window.remainingRatio), 0), 1),
      resetAt: window.resetAt || null
    }));

  if (values.length === 0) {
    return null;
  }

  return {
    providerID: "codex-oauth",
    recordedAt: recordedAt.toISOString(),
    values
  };
}

function normalizeSamples(input, now) {
  const cutoff = now.getTime() - RETENTION_MS;
  return (Array.isArray(input) ? input : [])
    .map((sample) => {
      const timestamp = new Date(sample && sample.recordedAt).getTime();
      const values = (sample && Array.isArray(sample.values) ? sample.values : [])
        .filter((value) => value && Number.isFinite(Number(value.remainingRatio)))
        .map((value) => ({
          windowID: String(value.windowID),
          labelKey: String(value.labelKey),
          remainingRatio: Math.min(Math.max(Number(value.remainingRatio), 0), 1),
          resetAt: value.resetAt || null
        }));
      if (!sample || sample.providerID !== "codex-oauth" || !Number.isFinite(timestamp) || timestamp < cutoff || values.length === 0) {
        return null;
      }
      return {
        providerID: "codex-oauth",
        recordedAt: new Date(timestamp).toISOString(),
        values
      };
    })
    .filter(Boolean)
    .sort((left, right) => new Date(left.recordedAt) - new Date(right.recordedAt));
}

module.exports = {
  QuotaHistoryStore,
  makeSample,
  normalizeSamples
};
