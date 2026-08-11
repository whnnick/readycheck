"use strict";

const assert = require("node:assert/strict");
const {
  ReadyCheckState,
  preserveManualResetDetails,
  recoveryActionForStatus,
  statusForUsageError
} = require("../src/services/app-state");

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
            },
            credits: {
              has_credits: true,
              unlimited: false,
              balance: "3336.5"
            }
          };
        },
        async fetchResetCredits(_accessToken, accountID) {
          assert.equal(accountID, "account-123");
          return {
            available_count: 1,
            credits: [
              {
                reset_type: "codex_rate_limits",
                status: "available",
                expires_at: "2026-07-31T20:38:12.468133Z"
              }
            ]
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
  assert.equal(refreshed.quota.manualResetCount, 1);
  assert.equal(refreshed.quota.manualResetExpiresAt, new Date("2026-07-31T20:38:12.468133Z").toISOString());
  assert.deepEqual(refreshed.quota.manualResetExpirations, [
    new Date("2026-07-31T20:38:12.468133Z").toISOString()
  ]);
  assert.equal(refreshed.quota.creditBalance, "3336.5");
  assert.equal(refreshed.quota.creditsUnlimited, false);
  assert.equal(refreshed.quota.windows[0].labelKey, "quota.window.codex.5h");
  assert.equal(refreshed.quota.windows[0].remainingRatio, 0.8);

  let fallbackUsageCalled = false;
  const officialState = new ReadyCheckState(
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
      appServerClient: {
        async readAccountSnapshot() {
          return {
            email: "USER@example.com",
            planName: "plus",
            rateLimits: [{
              limitID: "codex",
              limitName: "Codex",
              primary: {
                usedPercent: 25,
                durationMinutes: 300,
                resetsAt: "2026-07-29T10:00:00.000Z"
              },
              secondary: {
                usedPercent: 40,
                durationMinutes: 10_080,
                resetsAt: "2026-08-04T10:00:00.000Z"
              },
              creditBalance: "9.5",
              hasCredits: true,
              creditsUnlimited: false,
              planName: "plus"
            }],
            manualResetCount: 1,
            resetCredits: [{
              status: "available",
              expiresAt: "2026-08-12T10:00:00.000Z"
            }],
            tokenUsage: {
              summary: {
                lifetimeTokens: 123_456,
                peakDailyTokens: 20_000,
                currentStreakDays: 3
              },
              dailyBuckets: [{ startDate: "2026-07-28", tokens: 1_200 }]
            }
          };
        }
      },
      usageClient: {
        async fetchUsage() {
          fallbackUsageCalled = true;
          throw new Error("fallback must not run");
        }
      }
    }
  );
  const official = await officialState.refresh();
  assert.equal(fallbackUsageCalled, false);
  assert.equal(official.status, "available");
  assert.equal(official.quota.windows.length, 2);
  assert.equal(official.quota.windows[0].labelKey, "quota.window.codex.5h");
  assert.equal(official.quota.windows[1].labelKey, "quota.window.codex.7d");
  assert.equal(official.quota.tokenUsage.summary.lifetimeTokens, 123_456);
  assert.equal(official.quota.manualResetCount, 1);

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

  assert.equal(recoveryActionForStatus("usageUnavailable", true), "retry");
  assert.equal(recoveryActionForStatus("tokenRefreshFailed", true), "reconnect");
  assert.equal(recoveryActionForStatus("authorizationRejected", true), "reconnect");
  assert.equal(recoveryActionForStatus("parserUnavailable", true), "checkForUpdates");
  assert.equal(recoveryActionForStatus("notConnected", false), "connect");
  assert.equal(recoveryActionForStatus("authorizationFailed", true), "reconnect");
  assert.equal(recoveryActionForStatus("authorizationFailed", false), "connect");
  assert.equal(statusForUsageError({ code: "authorizationRejected" }), "authorizationRejected");
  assert.equal(statusForUsageError({ code: "parserUnavailable" }), "parserUnavailable");
  assert.equal(statusForUsageError(new Error("offline")), "usageUnavailable");

  const expiration = "2026-08-20T00:00:00.000Z";
  const preserved = preserveManualResetDetails(
    { manualResetCount: null, manualResetExpiresAt: null, manualResetExpirations: [] },
    { manualResetCount: 1, manualResetExpiresAt: expiration, manualResetExpirations: [expiration] },
    new Date("2026-08-06T00:00:00.000Z")
  );
  assert.equal(preserved.manualResetCount, 1);
  assert.deepEqual(preserved.manualResetExpirations, [expiration]);

  const cleared = preserveManualResetDetails(
    { manualResetCount: 0, manualResetExpiresAt: null, manualResetExpirations: [] },
    preserved,
    new Date("2026-08-06T00:00:00.000Z")
  );
  assert.equal(cleared.manualResetCount, 0);
  assert.deepEqual(cleared.manualResetExpirations, []);

  const supplementalGateState = new ReadyCheckState({});
  assert.equal(supplementalGateState.shouldRefreshSupplemental(new Date(1_000), false), true);
  assert.equal(supplementalGateState.shouldRefreshSupplemental(new Date(61_000), false), false);
  assert.equal(supplementalGateState.shouldRefreshSupplemental(new Date(62_000), true), true);
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
