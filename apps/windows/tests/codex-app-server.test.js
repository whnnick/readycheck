"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const {
  discoverCodexExecutable,
  normalizeAppServerResponses
} = require("../src/services/codex-app-server");

const snapshot = normalizeAppServerResponses(
  {
    account: {
      email: "user@example.com",
      planType: "plus"
    }
  },
  {
    rateLimits: {
      limitId: "codex",
      primary: {
        usedPercent: 18,
        windowDurationMins: 300,
        resetsAt: 1_784_000_000
      },
      secondary: {
        usedPercent: 42,
        windowDurationMins: 10_080,
        resetsAt: 1_784_500_000
      },
      credits: {
        hasCredits: true,
        unlimited: false,
        balance: "15.5"
      },
      planType: "plus"
    },
    rateLimitsByLimitId: {
      codex: {
        limitId: "codex",
        primary: {
          usedPercent: 18,
          windowDurationMins: 300,
          resetsAt: 1_784_000_000
        },
        secondary: {
          usedPercent: 42,
          windowDurationMins: 10_080,
          resetsAt: 1_784_500_000
        },
        credits: {
          hasCredits: true,
          unlimited: false,
          balance: "15.5"
        },
        planType: "plus"
      }
    },
    rateLimitResetCredits: {
      availableCount: 1,
      credits: [
        {
          status: "available",
          expiresAt: 1_784_600_000
        }
      ]
    }
  },
  {
    summary: {
      lifetimeTokens: 123_456,
      peakDailyTokens: 12_345,
      longestRunningTurnSec: 81,
      currentStreakDays: 4,
      longestStreakDays: 9
    },
    dailyUsageBuckets: [
      { startDate: "2026-07-28", tokens: 1_234 }
    ]
  }
);

assert.equal(snapshot.email, "user@example.com");
assert.equal(snapshot.rateLimits.length, 1);
assert.equal(snapshot.rateLimits[0].primary.durationMinutes, 300);
assert.equal(snapshot.rateLimits[0].creditBalance, "15.5");
assert.equal(snapshot.manualResetCount, 1);
assert.equal(snapshot.resetCredits.length, 1);
assert.equal(snapshot.tokenUsage.summary.lifetimeTokens, 123_456);
assert.deepEqual(snapshot.tokenUsage.dailyBuckets, [
  { startDate: "2026-07-28", tokens: 1_234 }
]);

const unavailableReset = normalizeAppServerResponses(
  { account: { email: "user@example.com" } },
  {
    rateLimits: { limitId: "codex", primary: { usedPercent: 18 } },
    rateLimitResetCredits: null
  },
  null
);
assert.equal(unavailableReset.manualResetCount, null);

const temporaryDirectory = fs.mkdtempSync(path.join(os.tmpdir(), "readycheck-codex-"));
const executablePath = path.join(temporaryDirectory, process.platform === "win32" ? "codex.exe" : "codex");
fs.writeFileSync(executablePath, "");
fs.chmodSync(executablePath, 0o755);
assert.equal(discoverCodexExecutable({
  environment: { READYCHECK_CODEX_PATH: executablePath },
  homeDirectory: temporaryDirectory,
  skipPathLookup: true
}), executablePath);
fs.rmSync(temporaryDirectory, { recursive: true, force: true });

console.log("Windows Codex app-server checks passed.");
