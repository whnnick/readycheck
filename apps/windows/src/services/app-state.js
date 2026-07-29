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

  async refresh() {
    this.isRefreshing = true;

    if (!isAllowedForRefresh(USAGE_ENDPOINT)) {
      this.status = "unsafeEndpoint";
      this.isRefreshing = false;
      return this.snapshot();
    }

    this.lastRefreshAt = new Date().toISOString();
    await this.reloadConnectionStatus();
    if (this.connected) {
      await this.refreshConnectedQuota(new Date(this.lastRefreshAt));
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

  async refreshConnectedQuota(refreshedAt) {
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

    const officialQuota = await this.fetchOfficialQuota(token, refreshedAt);
    if (officialQuota) {
      this.status = "available";
      this.quota = officialQuota;
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
      const resetCreditDetails = await this.fetchResetCreditDetails(token.accessToken, accountID);
      const manualResetExpirations = resetCreditDetails.manualResetExpirations.length > 0
        ? resetCreditDetails.manualResetExpirations
        : resetDetails.manualResetExpirations;
      this.status = "available";
      this.quota = {
        provider: "Codex",
        plan: planNameFromToken(token.idToken),
        subscriptionRenewalAt: subscriptionRenewalAtFromToken(token.idToken),
        manualResetCount: resetCreditDetails.manualResetCount ?? resetDetails.manualResetCount ?? 0,
        manualResetExpiresAt: manualResetExpirations[0] || null,
        manualResetExpirations,
        creditBalance: resetDetails.creditBalance,
        creditsUnlimited: resetDetails.creditsUnlimited,
        tokenUsage: null,
        windows
      };
      if (this.historyStore) {
        this.quotaHistory = this.historyStore.record(this.quota, refreshedAt);
      }
    } catch (error) {
      this.status = statusForUsageError(error);
      this.quota = buildUnavailableQuota();
    }
  }

  async fetchOfficialQuota(token, refreshedAt) {
    if (!this.appServerClient || typeof this.appServerClient.readAccountSnapshot !== "function") {
      return null;
    }

    try {
      const snapshot = await this.appServerClient.readAccountSnapshot();
      if (!sameAccountEmail(token.email, snapshot.email)) {
        return null;
      }
      const windows = (snapshot.rateLimits || []).flatMap((limit) => [
        makeOfficialWindow(limit.primary, `${limit.limitID}-primary`, "quota.window.codex.primary"),
        makeOfficialWindow(limit.secondary, `${limit.limitID}-secondary`, "quota.window.codex.secondary")
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
        manualResetCount: manualResetExpirations.length,
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
    manualResetCount: 0,
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

function makeOfficialWindow(window, id, fallbackLabelKey) {
  if (!window || !Number.isFinite(Number(window.usedPercent))) {
    return null;
  }
  const used = Math.min(Math.max(Number(window.usedPercent), 0), 100);
  return {
    id,
    labelKey: officialWindowLabel(window.durationMinutes, fallbackLabelKey),
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
  recoveryActionForStatus,
  sameAccountEmail,
  statusForUsageError
};
