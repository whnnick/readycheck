"use strict";

const assert = require("node:assert/strict");
const { ReadyCheckState } = require("../src/services/app-state");

class MemoryTokenStore {
  constructor() {
    this.token = null;
  }

  async loadToken() {
    return this.token;
  }

  async saveToken(token) {
    this.token = token;
  }

  async removeToken() {
    this.token = null;
  }
}

async function main() {
  const tokenStore = new MemoryTokenStore();
  const oauthClient = {
    makeAuthorizationSession() {
      return {
        state: "state-1",
        pkce: { verifier: "verifier", challenge: "challenge" },
        authorizationURL: "https://auth.openai.com/oauth/authorize?state=state-1"
      };
    },
    async exchangeCode(code, pkce) {
      assert.equal(code, "code-1");
      assert.equal(pkce.verifier, "verifier");
      return {
        accessToken: "access",
        refreshToken: "refresh",
        expiresAt: "2026-06-30T01:00:00.000Z",
        email: "user@example.com"
      };
    }
  };

  const state = new ReadyCheckState(
    {
      language: "zh-CN",
      refreshIntervalMinutes: 1,
      widgetVisible: true,
      widgetAlwaysOnTop: true,
      widgetDisplayMode: "minimal"
    },
    { tokenStore, oauthClient }
  );

  const started = state.beginOAuth();
  assert.equal(started.authorizationURL, "https://auth.openai.com/oauth/authorize?state=state-1");
  assert.equal(started.snapshot.status, "authorizing");

  const connected = await state.completeOAuth("http://localhost:1455/auth/callback?code=code-1&state=state-1");
  assert.equal(connected.connected, true);
  assert.equal(connected.accountEmail, "user@example.com");
  assert.equal(tokenStore.token.email, "user@example.com");

  const disconnected = await state.disconnect();
  assert.equal(disconnected.connected, false);
  assert.equal(tokenStore.token, null);

  const quotaStore = new MemoryTokenStore();
  quotaStore.token = {
    accessToken: jwt({
      "https://api.openai.com/auth": { chatgpt_account_id: "account-123" },
      "https://api.openai.com/profile": { email: "user@example.com" }
    }),
    refreshToken: "refresh",
    idToken: jwt({
      "https://api.openai.com/auth": {
        chatgpt_plan_type: "Plus",
        chatgpt_subscription_active_until: 1_782_526_542
      }
    }),
    expiresAt: "2099-06-30T01:00:00.000Z",
    email: "user@example.com"
  };
  let requestedAccountID = null;
  const quotaState = new ReadyCheckState(
    {
      language: "zh-CN",
      refreshIntervalMinutes: 1,
      widgetVisible: true,
      widgetAlwaysOnTop: true,
      widgetDisplayMode: "minimal"
    },
    {
      tokenStore: quotaStore,
      oauthClient,
      usageClient: {
        async fetchUsage(_accessToken, accountID) {
          requestedAccountID = accountID;
          return {
            rate_limit: {
              primary_window: {
                used_percent: 20,
                limit_window_seconds: 18_000,
                reset_at: 4600
              },
              secondary_window: {
                used_percent: 30,
                limit_window_seconds: 604_800,
                reset_at: 605800
              },
              manual_reset_count: 0
            }
          };
        }
      }
    }
  );

  const refreshed = await quotaState.refresh();
  assert.equal(requestedAccountID, "account-123");
  assert.equal(refreshed.status, "available");
  assert.equal(refreshed.connected, true);
  assert.equal(refreshed.quota.plan, "Plus");
  assert.equal(refreshed.quota.manualResetCount, 0);
  assert.equal(refreshed.quota.windows[0].labelKey, "quota.window.codex.5h");
  assert.equal(refreshed.quota.windows[0].remainingRatio, 0.8);

  const refreshStore = new MemoryTokenStore();
  refreshStore.token = {
    accessToken: jwt({
      "https://api.openai.com/auth": { chatgpt_account_id: "old-account" },
      "https://api.openai.com/profile": { email: "old@example.com" }
    }),
    refreshToken: "old-refresh",
    idToken: null,
    expiresAt: "2000-06-30T01:00:00.000Z",
    email: "old@example.com"
  };
  let didRefreshToken = false;
  let refreshedAccessToken = null;
  const refreshState = new ReadyCheckState(
    {
      language: "zh-CN",
      refreshIntervalMinutes: 1,
      widgetVisible: true,
      widgetAlwaysOnTop: true,
      widgetDisplayMode: "minimal"
    },
    {
      tokenStore: refreshStore,
      oauthClient: {
        async refreshToken(refreshToken) {
          didRefreshToken = true;
          assert.equal(refreshToken, "old-refresh");
          return {
            accessToken: jwt({
              "https://api.openai.com/auth": { chatgpt_account_id: "new-account" },
              "https://api.openai.com/profile": { email: "new@example.com" }
            }),
            refreshToken: "new-refresh",
            idToken: null,
            expiresAt: "2099-06-30T01:00:00.000Z",
            email: "new@example.com"
          };
        }
      },
      usageClient: {
        async fetchUsage(accessToken, accountID) {
          refreshedAccessToken = accessToken;
          assert.equal(accountID, "new-account");
          return {
            rate_limit: {
              primary_window: {
                used_percent: 50,
                limit_window_seconds: 18_000
              }
            }
          };
        }
      }
    }
  );

  const refreshedAfterTokenRefresh = await refreshState.refresh();
  assert.equal(didRefreshToken, true);
  assert.equal(refreshStore.token.refreshToken, "new-refresh");
  assert.equal(refreshedAccessToken, refreshStore.token.accessToken);
  assert.equal(refreshedAfterTokenRefresh.accountEmail, "new@example.com");
  assert.equal(refreshedAfterTokenRefresh.status, "available");
}

function jwt(payload) {
  const header = Buffer.from(JSON.stringify({ alg: "none" })).toString("base64url");
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  return `${header}.${body}.signature`;
}

main().then(
  () => console.log("Windows app-state auth checks passed."),
  (error) => {
    console.error(error);
    process.exitCode = 1;
  }
);
