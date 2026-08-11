"use strict";

const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { spawn, spawnSync } = require("node:child_process");
const { version } = require("../../package.json");

class CodexAppServerClient {
  constructor(options = {}) {
    this.executablePath = options.executablePath || null;
    this.timeoutMs = options.timeoutMs || 12_000;
  }

  async readAccountSnapshot() {
    const executablePath = this.executablePath || discoverCodexExecutable();
    if (!executablePath) {
      const error = new Error("Codex executable is unavailable.");
      error.code = "executableUnavailable";
      throw error;
    }

    return readAppServerSnapshot(executablePath, this.timeoutMs);
  }
}

function discoverCodexExecutable(options = {}) {
  const environment = options.environment || process.env;
  const homeDirectory = options.homeDirectory || os.homedir();
  const localAppData = environment.LOCALAPPDATA || "";
  const configured = environment.READYCHECK_CODEX_PATH;
  const candidates = [
    configured,
    localAppData && path.join(localAppData, "Programs", "Codex", "resources", "codex.exe"),
    localAppData && path.join(localAppData, "Programs", "Codex", "Codex.exe"),
    path.join(homeDirectory, ".local", "bin", "codex.exe"),
    path.join(homeDirectory, ".local", "bin", "codex")
  ].filter(Boolean);

  const directMatch = candidates.find(isExecutableFile);
  if (directMatch) {
    return directMatch;
  }

  if (options.skipPathLookup) {
    return null;
  }

  const command = process.platform === "win32" ? "where.exe" : "which";
  const result = spawnSync(command, ["codex"], {
    encoding: "utf8",
    windowsHide: true,
    timeout: 2_000
  });
  if (result.status !== 0) {
    return null;
  }
  return String(result.stdout || "")
    .split(/\r?\n/)
    .map((value) => value.trim())
    .find(isExecutableFile) || null;
}

function isExecutableFile(candidate) {
  if (!candidate) {
    return false;
  }
  try {
    fs.accessSync(candidate, fs.constants.X_OK);
    return fs.statSync(candidate).isFile();
  } catch {
    return false;
  }
}

function readAppServerSnapshot(executablePath, timeoutMs) {
  return new Promise((resolve, reject) => {
    const processHandle = spawn(executablePath, ["app-server", "--stdio"], {
      stdio: ["pipe", "pipe", "ignore"],
      windowsHide: true
    });
    let buffer = "";
    let settled = false;
    let accountResult = null;
    let rateLimitsResult = null;
    let usageResult;
    let usageFinished = false;

    const timer = setTimeout(() => {
      finish(newAppServerError("timedOut", "Codex app-server timed out."));
    }, timeoutMs);

    function finish(error, value) {
      if (settled) {
        return;
      }
      settled = true;
      clearTimeout(timer);
      if (!processHandle.killed) {
        processHandle.kill();
      }
      if (error) {
        reject(error);
      } else {
        resolve(value);
      }
    }

    function send(message) {
      processHandle.stdin.write(`${JSON.stringify(message)}\n`);
    }

    function handleMessage(message) {
      const id = Number(message && message.id);
      if (message && message.error) {
        if (id === 4) {
          usageFinished = true;
          maybeFinish();
          return;
        }
        finish(newAppServerError("requestFailed", `Codex app-server request ${id || "unknown"} failed.`));
        return;
      }

      if (id === 1) {
        send({ method: "initialized", params: {} });
        send({ method: "account/read", id: 2, params: { refreshToken: false } });
        send({ method: "account/rateLimits/read", id: 3 });
        send({ method: "account/usage/read", id: 4 });
      } else if (id === 2) {
        accountResult = message.result;
      } else if (id === 3) {
        rateLimitsResult = message.result;
      } else if (id === 4) {
        usageFinished = true;
        usageResult = message.result;
      }
      maybeFinish();
    }

    function maybeFinish() {
      if (accountResult && rateLimitsResult && usageFinished) {
        try {
          finish(null, normalizeAppServerResponses(accountResult, rateLimitsResult, usageResult));
        } catch (error) {
          finish(error);
        }
      }
    }

    processHandle.once("error", () => {
      finish(newAppServerError("launchFailed", "Codex app-server could not be started."));
    });
    processHandle.once("close", () => {
      if (!settled) {
        finish(newAppServerError("invalidResponse", "Codex app-server closed before returning data."));
      }
    });
    processHandle.stdout.setEncoding("utf8");
    processHandle.stdout.on("data", (chunk) => {
      buffer += chunk;
      const lines = buffer.split(/\r?\n/);
      buffer = lines.pop() || "";
      for (const line of lines) {
        if (!line.trim()) {
          continue;
        }
        try {
          handleMessage(JSON.parse(line));
        } catch {
          // App-server can emit unrelated notifications; malformed lines are ignored.
        }
      }
    });

    send({
      method: "initialize",
      id: 1,
      params: {
        clientInfo: {
          name: "readycheck",
          title: "ReadyCheck",
          version
        }
      }
    });
  });
}

function normalizeAppServerResponses(accountResult, rateLimitsResult, usageResult) {
  const snapshotsByID = rateLimitsResult && rateLimitsResult.rateLimitsByLimitId;
  const snapshots = snapshotsByID && typeof snapshotsByID === "object"
    ? Object.values(snapshotsByID)
    : [rateLimitsResult && rateLimitsResult.rateLimits].filter(Boolean);
  const account = accountResult && accountResult.account;
  const resetCredits = rateLimitsResult
    && rateLimitsResult.rateLimitResetCredits
    && rateLimitsResult.rateLimitResetCredits.credits;

  if (!account || snapshots.length === 0) {
    throw newAppServerError("invalidResponse", "Codex app-server returned incomplete account data.");
  }

  return {
    email: stringOrNull(account.email),
    planName: stringOrNull(account.planType),
    rateLimits: snapshots.map(normalizeRateLimit),
    manualResetCount: integerOrNull(
      rateLimitsResult
        && rateLimitsResult.rateLimitResetCredits
        && rateLimitsResult.rateLimitResetCredits.availableCount
    ),
    resetCredits: (Array.isArray(resetCredits) ? resetCredits : []).map((credit) => ({
      status: stringOrNull(credit && credit.status),
      expiresAt: epochISOString(credit && credit.expiresAt)
    })),
    tokenUsage: normalizeTokenUsage(usageResult)
  };
}

function normalizeRateLimit(snapshot) {
  return {
    limitID: stringOrNull(snapshot && snapshot.limitId) || "codex",
    limitName: stringOrNull(snapshot && snapshot.limitName),
    primary: normalizeRateLimitWindow(snapshot && snapshot.primary),
    secondary: normalizeRateLimitWindow(snapshot && snapshot.secondary),
    creditBalance: stringOrNull(snapshot && snapshot.credits && snapshot.credits.balance),
    hasCredits: booleanOrNull(snapshot && snapshot.credits && snapshot.credits.hasCredits),
    creditsUnlimited: booleanOrNull(snapshot && snapshot.credits && snapshot.credits.unlimited),
    planName: stringOrNull(snapshot && snapshot.planType)
  };
}

function normalizeRateLimitWindow(window) {
  if (!window || !Number.isFinite(Number(window.usedPercent))) {
    return null;
  }
  return {
    usedPercent: Number(window.usedPercent),
    durationMinutes: Number.isFinite(Number(window.windowDurationMins))
      ? Number(window.windowDurationMins)
      : null,
    resetsAt: epochISOString(window.resetsAt)
  };
}

function normalizeTokenUsage(usageResult) {
  const summary = usageResult && usageResult.summary;
  if (!summary || !Number.isFinite(Number(summary.lifetimeTokens))) {
    return null;
  }
  return {
    summary: {
      lifetimeTokens: Number(summary.lifetimeTokens),
      peakDailyTokens: numberOrZero(summary.peakDailyTokens),
      longestRunningTurnSeconds: numberOrZero(summary.longestRunningTurnSec),
      currentStreakDays: numberOrZero(summary.currentStreakDays),
      longestStreakDays: numberOrZero(summary.longestStreakDays)
    },
    dailyBuckets: (Array.isArray(usageResult.dailyUsageBuckets) ? usageResult.dailyUsageBuckets : [])
      .filter((bucket) => bucket && typeof bucket.startDate === "string" && Number.isFinite(Number(bucket.tokens)))
      .map((bucket) => ({
        startDate: bucket.startDate,
        tokens: Number(bucket.tokens)
      }))
  };
}

function epochISOString(value) {
  if (!Number.isFinite(Number(value)) || Number(value) <= 0) {
    return null;
  }
  const numeric = Number(value);
  const milliseconds = numeric > 1_000_000_000_000 ? numeric : numeric * 1000;
  return new Date(milliseconds).toISOString();
}

function stringOrNull(value) {
  if (typeof value !== "string") {
    return null;
  }
  const normalized = value.trim();
  return normalized || null;
}

function booleanOrNull(value) {
  return typeof value === "boolean" ? value : null;
}

function integerOrNull(value) {
  if (value === null || value === undefined || value === "") {
    return null;
  }
  const numeric = Number(value);
  return Number.isInteger(numeric) && numeric >= 0 ? numeric : null;
}

function numberOrZero(value) {
  return Number.isFinite(Number(value)) ? Number(value) : 0;
}

function newAppServerError(code, message) {
  const error = new Error(message);
  error.code = code;
  return error;
}

module.exports = {
  CodexAppServerClient,
  discoverCodexExecutable,
  normalizeAppServerResponses
};
