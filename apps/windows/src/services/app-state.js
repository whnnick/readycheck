"use strict";

const { isAllowedForRefresh } = require("./safe-refresh");
const {
  accountIDFromToken,
  completeOAuthCallback,
  planNameFromToken,
  subscriptionRenewalAtFromToken
} = require("./oauth");
const { parseManualResetDetails, parseUsagePayload } = require("./usage-parser");

const USAGE_ENDPOINT = "https://chatgpt.com/backend-api/wham/usage";

class ReadyCheckState {
  constructor(prefs, options = {}) {
    this.prefs = prefs;
    this.tokenStore = options.tokenStore || null;
    this.oauthClient = options.oauthClient || null;
    this.usageClient = options.usageClient || null;
    this.appServerClient = options.appServerClient || null;
    this.historyStore = options.historyStore || null;
    this.oauthSession = null;
    this.connected = false;
    this.accountEmail = null;
    this.lastRefreshAt = null;
    this.isRefreshing = false;
    this.status = "notConnected";
    this.quota = buildUnavailableQuota();
    this.quotaHistory = this.historyStore ? this.historyStore.load() : [];
    this.lastSupplementalRefreshAt = null;
    this.supplementalRefreshIntervalMs = 15 * 60 * 1000;
  }

  snapshot() {
    return {
      prefs: this.prefs,
      connected: this.connected,
      accountEmail: this.accountEmail,
      lastRefreshAt: this.lastRefreshAt,
      isRefreshing: this.isRefreshing,
      status: this.status,
      quota: this.quota,
      quotaHistory: this.quotaHistory,
      recoveryAction: recoveryActionForStatus(this.status, this.connected),
      safeRefresh: {
        endpoint: USAGE_ENDPOINT,
        allowed: isAllowedForRefresh(USAGE_ENDPOINT)
      }
    };
  }

  async reloadConnectionStatus() {
    if (!this.tokenStore) {
      this.connected = false;
      this.accountEmail = null;
      this.status = "notConnected";
      return this.snapshot();
    }

    try {
      const token = await this.tokenStore.loadToken();
      this.applyToken(token);
      this.status = token ? "connected" : "notConnected";
    } catch (_error) {
      this.connected = false;
      this.accountEmail = null;
      this.status = "tokenStorageUnavailable";
    }

    return this.snapshot();
  }

  updatePrefs(prefs) {
    this.prefs = prefs;
    return this.snapshot();
  }

  beginOAuth() {
    if (!this.oauthClient) {
      throw new Error("OAuth client is not configured.");
    }

    this.oauthSession = this.oauthClient.makeAuthorizationSession();
    this.status = "authorizing";
    return {
      authorizationURL: this.oauthSession.authorizationURL,
      snapshot: this.snapshot()
    };
  }

  async completeOAuth(callbackURL) {
    if (!this.tokenStore || !this.oauthClient) {
      throw new Error("OAuth storage is not configured.");
    }
    if (!this.oauthSession) {
      throw new Error("OAuth session is not active.");
    }

    const token = await completeOAuthCallback(callbackURL, this.oauthSession, this.oauthClient);
    await this.tokenStore.saveToken(token);
    this.oauthSession = null;
    this.applyToken(token);
    this.status = "connected";
    return this.snapshot();
  }

  async disconnect() {
    if (this.tokenStore) {
      await this.tokenStore.removeToken();
    }
    this.oauthSession = null;
    this.connected = false;
    this.accountEmail = null;
    this.status = "notConnected";
    this.quota = buildUnavailableQuota();
    return this.snapshot();
  }

  async refresh(options = {}) {
    this.isRefreshing = true;

    if (!isAllowedForRefresh(USAGE_ENDPOINT)) {
      this.status = "unsafeEndpoint";
      this.isRefreshing = false;
      return this.snapshot();
    }

    this.lastRefreshAt = new Date().toISOString();
    await this.reloadConnectionStatus();
    if (this.connected) {
      await this.refreshConnectedQuota(
        new Date(this.lastRefreshAt),
        Boolean(options.forceSupplemental)
      );
    } else {
      this.quota = buildUnavailableQuota();
    }
    this.isRefreshing = false;
    return this.snapshot();
  }

  applyToken(token) {
    this.connected = Boolean(token);
    this.accountEmail = token ? token.email || null : null;
  }

  preserveKnownManualResetExpirations(expirations, now = new Date()) {
    const verifiedFutureExpirations = (Array.isArray(expirations) ? expirations : [])
      .filter((value) => new Date(value).getTime() > now.getTime())
      .sort();
    if (this.status !== "available" || verifiedFutureExpirations.length === 0) {
      return this.snapshot();
    }
    this.quota = preserveManualResetDetails(this.quota, {
      manualResetCount: verifiedFutureExpirations.length,
      manualResetExpiresAt: verifiedFutureExpirations[0],
      manualResetExpirations: verifiedFutureExpirations,
      tokenUsage: null
    }, now);
    return this.snapshot();
  }

  async refreshConnectedQuota(refreshedAt, forceSupplemental) {
    if (!this.tokenStore || !this.oauthClient) {
      this.status = "usageUnavailable";
      this.quota = buildUnavailableQuota();
      return;
    }

    let token = await this.tokenStore.loadToken();
    if (!token) {
      this.status = "notConnected";
      this.quota = buildUnavailableQuota();
      return;
    }

    if (new Date(token.expiresAt).getTime() <= refreshedAt.getTime()) {
      try {
        token = await this.oauthClient.refreshToken(token.refreshToken);
        await this.tokenStore.saveToken(token);
        this.applyToken(token);
      } catch (_error) {
        this.status = "tokenRefreshFailed";
        this.quota = buildUnavailableQuota();
        return;
      }
    }

    const shouldRefreshSupplemental = this.shouldRefreshSupplemental(
      refreshedAt,
      forceSupplemental
    );
    const officialQuota = shouldRefreshSupplemental
      ? await this.fetchOfficialQuota(token, refreshedAt)
      : null;
    if (officialQuota) {
      this.status = "available";
      this.quota = preserveManualResetDetails(officialQuota, this.quota, refreshedAt);
      if (this.historyStore) {
        this.quotaHistory = this.historyStore.record(this.quota, refreshedAt);
      }
      return;
    }

    if (!this.usageClient) {
      this.status = "usageUnavailable";
      this.quota = buildUnavailableQuota();
      return;
    }

    const accountID = token.accountID || accountIDFromToken(token.accessToken);
    if (!accountID) {
      this.status = "accountIdUnavailable";
      this.quota = buildUnavailableQuota();
      return;
    }

    try {
      const payload = await this.usageClient.fetchUsage(token.accessToken, accountID);
      const windows = parseUsagePayload(payload, refreshedAt);
      const resetDetails = parseManualResetDetails(payload);
      const resetCreditDetails = shouldRefreshSupplemental
        ? await this.fetchResetCreditDetails(token.accessToken, accountID)
        : { manualResetCount: null, manualResetExpirations: [] };
      const manualResetExpirations = resetCreditDetails.manualResetExpirations.length > 0
        ? resetCreditDetails.manualResetExpirations
        : resetDetails.manualResetExpirations;
      this.status = "available";
      this.quota = preserveManualResetDetails({
        provider: "Codex",
        plan: planNameFromToken(token.idToken),
        subscriptionRenewalAt: subscriptionRenewalAtFromToken(token.idToken),
        manualResetCount: resetCreditDetails.manualResetCount ?? resetDetails.manualResetCount ?? null,
        manualResetExpiresAt: manualResetExpirations[0] || null,
        manualResetExpirations,
        creditBalance: resetDetails.creditBalance,
        creditsUnlimited: resetDetails.creditsUnlimited,
        tokenUsage: null,
        windows
      }, this.quota, refreshedAt);
      if (this.historyStore) {
        this.quotaHistory = this.historyStore.record(this.quota, refreshedAt);
      }
    } catch (error) {
      this.status = statusForUsageError(error);
      this.quota = buildUnavailableQuota();
    }
  }

  async fetchOfficialQuota(token, refreshedAt) {
    if (!this.appServerClient
      || (typeof this.appServerClient.readAccountSnapshot !== "function"
        && typeof this.appServerClient.readAccountSnapshots !== "function")) {
      return null;
    }

    try {
      const snapshots = typeof this.appServerClient.readAccountSnapshots === "function"
        ? await this.appServerClient.readAccountSnapshots()
        : [await this.appServerClient.readAccountSnapshot()];
      const matchingSnapshots = snapshots.filter((snapshot) => sameAccountEmail(token.email, snapshot.email));
      const snapshot = mergeAppServerSnapshots(matchingSnapshots);
      if (!snapshot) {
        return null;
      }
      const windows = (snapshot.rateLimits || []).flatMap((limit) => [
        makeOfficialWindow(limit.primary, `${limit.limitID}-primary`, "quota.window.codex.primary", limit),
        makeOfficialWindow(limit.secondary, `${limit.limitID}-secondary`, "quota.window.codex.secondary", limit)
      ].filter(Boolean));
      if (windows.length === 0) {
        return null;
      }

      const defaultLimit = snapshot.rateLimits.find((limit) => limit.limitID === "codex")
        || snapshot.rateLimits[0];
      const manualResetExpirations = (snapshot.resetCredits || [])
        .filter((credit) => !credit.status || credit.status === "available")
        .map((credit) => credit.expiresAt)
        .filter(Boolean)
        .sort();
      return {
        provider: "Codex",
        plan: defaultLimit.planName || snapshot.planName || planNameFromToken(token.idToken),
        subscriptionRenewalAt: subscriptionRenewalAtFromToken(token.idToken),
        manualResetCount: snapshot.manualResetCount,
        manualResetExpiresAt: manualResetExpirations[0] || null,
        manualResetExpirations,
        creditBalance: defaultLimit.hasCredits === false ? null : defaultLimit.creditBalance,
        creditsUnlimited: defaultLimit.creditsUnlimited,
        tokenUsage: snapshot.tokenUsage || null,
        windows
      };
    } catch {
      return null;
    }
  }

  async fetchResetCreditDetails(accessToken, accountID) {
    if (!this.usageClient || typeof this.usageClient.fetchResetCredits !== "function") {
      return { manualResetCount: null, manualResetExpirations: [] };
    }

    try {
      return parseManualResetDetails(await this.usageClient.fetchResetCredits(accessToken, accountID));
    } catch (_error) {
      return { manualResetCount: null, manualResetExpirations: [] };
    }
  }

  shouldRefreshSupplemental(refreshedAt, force) {
    if (force || this.lastSupplementalRefreshAt === null) {
      this.lastSupplementalRefreshAt = refreshedAt.getTime();
      return true;
    }
    if (refreshedAt.getTime() - this.lastSupplementalRefreshAt < this.supplementalRefreshIntervalMs) {
      return false;
    }
    this.lastSupplementalRefreshAt = refreshedAt.getTime();
    return true;
  }
}

function preserveManualResetDetails(current, previous, refreshedAt) {
  const now = refreshedAt.getTime();
  const previousExpirations = Array.isArray(previous && previous.manualResetExpirations)
    ? previous.manualResetExpirations.filter((value) => new Date(value).getTime() > now).sort()
    : [];

  if (current.manualResetCount === 0) {
    return { ...current, tokenUsage: current.tokenUsage || previous.tokenUsage || null, manualResetExpiresAt: null, manualResetExpirations: [] };
  }
  if (current.manualResetExpirations.length > 0) {
    return { ...current, tokenUsage: current.tokenUsage || previous.tokenUsage || null };
  }
  if (Number.isInteger(current.manualResetCount) && current.manualResetCount > 0) {
    const expirations = previousExpirations.slice(0, current.manualResetCount);
    return { ...current, tokenUsage: current.tokenUsage || previous.tokenUsage || null, manualResetExpiresAt: expirations[0] || null, manualResetExpirations: expirations };
  }
  if (previousExpirations.length > 0) {
    return {
      ...current,
      tokenUsage: current.tokenUsage || previous.tokenUsage || null,
      manualResetCount: Number.isInteger(previous.manualResetCount) ? previous.manualResetCount : previousExpirations.length,
      manualResetExpiresAt: previousExpirations[0],
      manualResetExpirations: previousExpirations
    };
  }
  if (previous && previous.manualResetCount === 0) {
    return { ...current, tokenUsage: current.tokenUsage || previous.tokenUsage || null, manualResetCount: 0, manualResetExpiresAt: null, manualResetExpirations: [] };
  }
  return { ...current, tokenUsage: current.tokenUsage || previous.tokenUsage || null };
}

function mergeAppServerSnapshots(snapshots) {
  if (!Array.isArray(snapshots) || snapshots.length === 0) {
    return null;
  }
  return snapshots.slice(1).reduce((merged, candidate) => {
    const preserveExplicitZero = merged.manualResetCount === 0;
    return {
      ...merged,
      planName: merged.planName || candidate.planName || null,
      rateLimits: Array.isArray(merged.rateLimits) && merged.rateLimits.length > 0
        ? merged.rateLimits
        : candidate.rateLimits,
      manualResetCount: Number.isInteger(merged.manualResetCount)
        ? merged.manualResetCount
        : candidate.manualResetCount,
      resetCredits: preserveExplicitZero || (Array.isArray(merged.resetCredits) && merged.resetCredits.length > 0)
        ? merged.resetCredits
        : candidate.resetCredits,
      tokenUsage: merged.tokenUsage || candidate.tokenUsage || null
    };
  }, snapshots[0]);
}

function statusForUsageError(error) {
  if (error && error.code === "authorizationRejected") {
    return "authorizationRejected";
  }
  if (error && error.code === "parserUnavailable") {
    return "parserUnavailable";
  }
  return "usageUnavailable";
}

function recoveryActionForStatus(status, connected) {
  if (status === "authorizationFailed") {
    return connected ? "reconnect" : "connect";
  }
  if (status === "tokenRefreshFailed" || status === "accountIdUnavailable" || status === "authorizationRejected") {
    return "reconnect";
  }
  if (status === "parserUnavailable") {
    return "checkForUpdates";
  }
  if (!connected || status === "notConnected") {
    return "connect";
  }
  if (status === "usageUnavailable") {
    return "retry";
  }
  return "none";
}

function buildUnavailableQuota() {
  return {
    provider: "Codex",
    plan: null,
    subscriptionRenewalAt: null,
    manualResetCount: null,
    manualResetExpiresAt: null,
    manualResetExpirations: [],
    creditBalance: null,
    creditsUnlimited: null,
    tokenUsage: null,
    windows: []
  };
}

function sameAccountEmail(readyCheckEmail, appServerEmail) {
  const expected = String(readyCheckEmail || "").trim().toLowerCase();
  const actual = String(appServerEmail || "").trim().toLowerCase();
  return Boolean(expected && actual && expected === actual);
}

function makeOfficialWindow(window, id, fallbackLabelKey, limit = {}) {
  if (!window || !Number.isFinite(Number(window.usedPercent))) {
    return null;
  }
  const used = Math.min(Math.max(Number(window.usedPercent), 0), 100);
  const labelKey = officialWindowLabel(window.durationMinutes, fallbackLabelKey);
  const limitName = typeof limit.limitName === "string" ? limit.limitName.trim() : "";
  const displayLabel = labelKey === fallbackLabelKey
    && limitName
    && limitName.toLowerCase() !== String(limit.limitID || "").toLowerCase()
    ? limitName
    : null;
  return {
    id,
    labelKey,
    displayLabel,
    limitStateCode: limit.reachedStateCode || null,
    kind: "rolling",
    used,
    limit: 100,
    remaining: 100 - used,
    remainingRatio: (100 - used) / 100,
    unit: "percent",
    resetAt: window.resetsAt || null,
    confidence: "verified",
    status: "available"
  };
}

function officialWindowLabel(durationMinutes, fallback) {
  if (Number(durationMinutes) === 300) {
    return "quota.window.codex.5h";
  }
  if (Number(durationMinutes) === 10_080) {
    return "quota.window.codex.7d";
  }
  return fallback;
}

module.exports = {
  ReadyCheckState,
  makeOfficialWindow,
  mergeAppServerSnapshots,
  preserveManualResetDetails,
  recoveryActionForStatus,
  sameAccountEmail,
  statusForUsageError
};
