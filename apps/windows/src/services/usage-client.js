"use strict";

const { isAllowedForRefresh } = require("./safe-refresh");

class CodexUsageClient {
  constructor(options = {}) {
    this.endpoint = options.endpoint || "https://chatgpt.com/backend-api/wham/usage";
    this.resetCreditsEndpoint = options.resetCreditsEndpoint || "https://chatgpt.com/backend-api/wham/rate-limit-reset-credits";
    this.fetchImpl = options.fetchImpl || globalThis.fetch;
  }

  async fetchUsage(accessToken, accountID) {
    if (!isAllowedForRefresh(this.endpoint)) {
      throw new Error("Unsafe usage endpoint.");
    }
    if (typeof this.fetchImpl !== "function") {
      throw new Error("Fetch is not available in this Electron runtime.");
    }

    const headers = {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      "User-Agent": "ReadyCheck/0.1"
    };
    if (accountID) {
      headers["ChatGPT-Account-Id"] = accountID;
    }

    const response = await this.fetchImpl(this.endpoint, {
      method: "GET",
      headers
    });
    if (!response.ok) {
      const error = new Error(`Codex usage request failed with status ${response.status}`);
      error.code = response.status === 401 || response.status === 403 ? "authorizationRejected" : "usageRequestFailed";
      throw error;
    }
    return response.json();
  }

  async fetchResetCredits(accessToken, accountID) {
    if (!isAllowedForRefresh(this.resetCreditsEndpoint)) {
      throw new Error("Unsafe reset credits endpoint.");
    }
    if (typeof this.fetchImpl !== "function") {
      throw new Error("Fetch is not available in this Electron runtime.");
    }

    const headers = {
      Authorization: `Bearer ${accessToken}`,
      Accept: "application/json",
      "User-Agent": "ReadyCheck/0.1",
      "OpenAI-Beta": "codex-1",
      originator: "Codex Desktop"
    };
    if (accountID) {
      headers["ChatGPT-Account-Id"] = accountID;
    }

    const response = await this.fetchImpl(this.resetCreditsEndpoint, {
      method: "GET",
      headers
    });
    if (!response.ok) {
      throw new Error(`Codex reset credits request failed with status ${response.status}`);
    }
    return response.json();
  }
}

module.exports = {
  CodexUsageClient
};
