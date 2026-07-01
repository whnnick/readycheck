"use strict";

function parseUsagePayload(payload, refreshedAt = new Date()) {
  const windows = [
    makeWindow(payload && payload.rate_limit && payload.rate_limit.primary_window, {
      id: "codex-primary",
      fallbackLabelKey: "quota.window.codex.primary",
      refreshedAt
    }),
    makeWindow(payload && payload.rate_limit && payload.rate_limit.secondary_window, {
      id: "codex-secondary",
      fallbackLabelKey: "quota.window.codex.secondary",
      refreshedAt
    })
  ].filter(Boolean);

  if (windows.length === 0) {
    throw new Error("No displayable Codex quota windows.");
  }

  return windows;
}

function parseManualResetDetails(payload) {
  const root = payload && typeof payload === "object" ? payload : {};
  return {
    manualResetCount: firstInt(root, [
      ["manual_reset_count"],
      ["manual_resets_count"],
      ["manual_resets"],
      ["manual_reset_expirations"],
      ["rate_limit", "manual_reset_count"],
      ["rate_limit", "manual_resets_count"],
      ["rate_limit", "manual_resets"],
      ["rate_limit", "manual_reset_expirations"]
    ]),
    manualResetExpirations: firstDateArray(root, [
      ["manual_reset_expires_at"],
      ["manual_reset_expire_at"],
      ["manual_reset_expirations"],
      ["manual_resets", "expires_at"],
      ["rate_limit", "manual_reset_expires_at"],
      ["rate_limit", "manual_reset_expire_at"],
      ["rate_limit", "manual_reset_expirations"],
      ["rate_limit", "manual_resets", "expires_at"]
    ])
  };
}

function makeWindow(payload, options) {
  if (!payload || !Number.isFinite(Number(payload.used_percent))) {
    return null;
  }

  const used = Math.min(Math.max(Number(payload.used_percent), 0), 100);
  const remaining = Math.max(0, 100 - used);
  return {
    id: options.id,
    labelKey: labelKeyForWindowSeconds(payload.limit_window_seconds, options.fallbackLabelKey),
    kind: "rolling",
    used,
    limit: 100,
    remaining,
    remainingRatio: remaining / 100,
    unit: "percent",
    resetAt: resetDate(payload, options.refreshedAt),
    confidence: "verified",
    status: "available"
  };
}

function resetDate(payload, refreshedAt) {
  const resetAt = epochDate(payload.reset_at);
  if (resetAt) {
    return resetAt;
  }

  const resetAfterSeconds = Number(payload.reset_after_seconds);
  if (Number.isFinite(resetAfterSeconds)) {
    return new Date(refreshedAt.getTime() + resetAfterSeconds * 1000).toISOString();
  }

  return null;
}

function firstInt(root, paths) {
  for (const path of paths) {
    const value = valueAtPath(root, path);
    const parsed = intFrom(value);
    if (parsed !== null) {
      return parsed;
    }
  }
  return null;
}

function firstDateArray(root, paths) {
  for (const path of paths) {
    const value = valueAtPath(root, path);
    const parsed = datesFrom(value);
    if (parsed.length > 0) {
      return parsed;
    }
  }
  return [];
}

function valueAtPath(root, path) {
  let current = root;
  for (const key of path) {
    if (Array.isArray(current)) {
      current = current.map((item) => item && item[key]).filter((value) => value !== undefined);
    } else if (current && typeof current === "object" && Object.hasOwn(current, key)) {
      current = current[key];
    } else {
      return undefined;
    }
  }
  return current;
}

function intFrom(value) {
  if (Array.isArray(value)) {
    return value.length;
  }

  if (typeof value === "number" && Number.isFinite(value)) {
    const int = Math.trunc(value);
    return int >= 0 ? int : null;
  }

  if (typeof value === "string" && value.trim()) {
    const int = Number.parseInt(value.trim(), 10);
    return Number.isFinite(int) && int >= 0 ? int : null;
  }

  return null;
}

function datesFrom(value) {
  if (Array.isArray(value)) {
    return value.flatMap((item) => {
      if (item && typeof item === "object" && !Array.isArray(item)) {
        return [
          epochDate(item.expires_at),
          epochDate(item.expire_at),
          epochDate(item.reset_at)
        ].filter(Boolean);
      }
      const date = epochDate(item);
      return date ? [date] : [];
    });
  }

  const date = epochDate(value);
  return date ? [date] : [];
}

function epochDate(value) {
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value === "number" || (typeof value === "string" && value.trim())) {
    const numeric = Number(value);
    if (Number.isFinite(numeric) && numeric > 0) {
      const seconds = numeric > 1_000_000_000_000 ? numeric / 1000 : numeric;
      return new Date(seconds * 1000).toISOString();
    }
  }

  if (typeof value === "string") {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
  }

  return null;
}

function labelKeyForWindowSeconds(value, fallback) {
  const seconds = Number(value);
  if (!Number.isFinite(seconds)) {
    return fallback;
  }
  if (Math.abs(seconds - 18_000) <= 60) {
    return "quota.window.codex.5h";
  }
  if (Math.abs(seconds - 604_800) <= 3_600) {
    return "quota.window.codex.7d";
  }
  return fallback;
}

module.exports = {
  parseManualResetDetails,
  parseUsagePayload
};
