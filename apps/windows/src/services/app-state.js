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
    this.oauthSession = null;
    this.connected = false;
    this.accountEmail = null;
    this.lastRefreshAt = null;
    this.isRefreshing = false;
    this.status = "notConnected";
    this.quota = buildUnavailableQuota();
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
    if (!this.tokenStore || !this.usageClient || !this.oauthClient) {
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
      this.status = "available";
      this.quota = {
        provider: "Codex",
        plan: planNameFromToken(token.idToken),
        subscriptionRenewalAt: subscriptionRenewalAtFromToken(token.idToken),
        manualResetCount: resetDetails.manualResetCount ?? 0,
        manualResetExpiresAt: resetDetails.manualResetExpirations[0] || null,
        windows
      };
    } catch (_error) {
      this.status = "usageUnavailable";
      this.quota = buildUnavailableQuota();
    }
  }
}

function buildUnavailableQuota() {
  return {
    provider: "Codex",
    plan: null,
    subscriptionRenewalAt: null,
    manualResetCount: 0,
    manualResetExpiresAt: null,
    windows: [
      {
        id: "codex-5h",
        labelKey: "quota.fiveHour",
        remainingRatio: null,
        resetAt: null,
        status: "unavailable"
      },
      {
        id: "codex-7d",
        labelKey: "quota.sevenDay",
        remainingRatio: null,
        resetAt: null,
        status: "unavailable"
      }
    ]
  };
}

module.exports = {
  ReadyCheckState
};
