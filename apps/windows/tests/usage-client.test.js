"use strict";

const assert = require("node:assert/strict");
const { CodexUsageClient } = require("../src/services/usage-client");

async function main() {
  let recordedURL = null;
  let recordedOptions = null;
  const client = new CodexUsageClient({
    fetchImpl: async (url, options) => {
      recordedURL = url;
      recordedOptions = options;
      return {
        ok: true,
        status: 200,
        async json() {
          return { ok: true };
        }
      };
    }
  });

  const payload = await client.fetchUsage("access", "account-123");
  assert.deepEqual(payload, { ok: true });
  assert.equal(recordedURL, "https://chatgpt.com/backend-api/wham/usage");
  assert.equal(recordedOptions.method, "GET");
  assert.equal(recordedOptions.headers.Authorization, "Bearer access");
  assert.equal(recordedOptions.headers["ChatGPT-Account-Id"], "account-123");
  assert.equal(recordedOptions.headers.Accept, "application/json");

  const unsafeClient = new CodexUsageClient({
    endpoint: "https://api.openai.com/v1/chat/completions",
    fetchImpl: async () => {
      assert.fail("unsafe endpoint should be rejected before network");
    }
  });
  await assert.rejects(() => unsafeClient.fetchUsage("access", "account-123"), /Unsafe usage endpoint/);
}

main().then(
  () => console.log("Windows usage-client checks passed."),
  (error) => {
    console.error(error);
    process.exitCode = 1;
  }
);
