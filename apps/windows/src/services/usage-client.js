"use strict";

const { isAllowedForRefresh } = require("./safe-refresh");

class CodexUsageClient {
  constructor(options = {}) {
    this.endpoint = options.endpoint || "https://chatgpt.com/backend-api/wham/usage";
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
      throw new Error(`Codex usage request failed with status ${response.status}`);
    }
    return response.json();
  }
}

module.exports = {
  CodexUsageClient
};
