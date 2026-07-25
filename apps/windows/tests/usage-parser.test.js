"use strict";

const assert = require("node:assert/strict");
const { parseManualResetDetails, parseUsagePayload } = require("../src/services/usage-parser");

const windows = parseUsagePayload(
  {
    rate_limit: {
      primary_window: {
        used_percent: 25,
        limit_window_seconds: 18_000,
        reset_after_seconds: 3600,
        reset_at: 4600
      },
      secondary_window: {
        used_percent: 40,
        limit_window_seconds: 604_800,
        reset_after_seconds: 86_400,
        reset_at: 87_400
      }
    }
  },
  new Date(1_000 * 1000)
);

assert.equal(windows.length, 2);
assert.equal(windows[0].id, "codex-primary");
assert.equal(windows[0].labelKey, "quota.window.codex.5h");
assert.equal(windows[0].used, 25);
assert.equal(windows[0].remaining, 75);
assert.equal(windows[0].remainingRatio, 0.75);
assert.equal(windows[0].resetAt, new Date(4_600 * 1000).toISOString());
assert.equal(windows[1].labelKey, "quota.window.codex.7d");
assert.equal(windows[1].remainingRatio, 0.6);

const clamped = parseUsagePayload({
  rate_limit: {
    primary_window: {
      used_percent: 125,
      limit_window_seconds: 18_000
    }
  }
});
assert.equal(clamped[0].used, 100);
assert.equal(clamped[0].remaining, 0);
assert.equal(clamped[0].remainingRatio, 0);

assert.throws(
  () => parseUsagePayload({ rate_limit: { primary_window: { limit_window_seconds: 18_000 } } }),
  /No displayable/
);

const resetDetails = parseManualResetDetails({
  rate_limit: {
    manual_reset_count: 1,
    manual_reset_expirations: [1_782_526_542]
  }
});
assert.equal(resetDetails.manualResetCount, 1);
assert.deepEqual(resetDetails.manualResetExpirations, [new Date(1_782_526_542 * 1000).toISOString()]);

const resetCreditDetails = parseManualResetDetails({
  rate_limit_reset_credits: {
    available_count: 1
  }
});
assert.equal(resetCreditDetails.manualResetCount, 1);

const resetCreditEndpointDetails = parseManualResetDetails({
  available_count: 1,
  credits: [
    {
      reset_type: "codex_rate_limits",
      status: "available",
      granted_at: "2026-07-01T20:38:12.468133Z",
      expires_at: "2026-07-31T20:38:12.468133Z"
    },
    {
      reset_type: "codex_rate_limits",
      status: "consumed",
      expires_at: "2026-08-01T20:38:12.468133Z"
    }
  ]
});
assert.equal(resetCreditEndpointDetails.manualResetCount, 1);
assert.deepEqual(resetCreditEndpointDetails.manualResetExpirations, [
  new Date("2026-07-31T20:38:12.468133Z").toISOString()
]);

const emptyResetDetails = parseManualResetDetails({
  rate_limit: {
    manual_resets: []
  }
});
assert.equal(emptyResetDetails.manualResetCount, 0);
assert.deepEqual(emptyResetDetails.manualResetExpirations, []);

const codexCredits = parseManualResetDetails({
  credits: {
    has_credits: true,
    unlimited: false,
    balance: "3336.500"
  }
});
assert.equal(codexCredits.creditBalance, "3336.5");
assert.equal(codexCredits.creditsUnlimited, false);

const zeroCodexCredits = parseManualResetDetails({
  credits: {
    unlimited: false,
    balance: "0"
  }
});
assert.equal(zeroCodexCredits.creditBalance, "0");
assert.equal(zeroCodexCredits.creditsUnlimited, false);

const unlimitedCodexCredits = parseManualResetDetails({
  credits: {
    unlimited: true
  }
});
assert.equal(unlimitedCodexCredits.creditBalance, null);
assert.equal(unlimitedCodexCredits.creditsUnlimited, true);

const invalidCodexCredits = parseManualResetDetails({
  credits: {
    unlimited: false,
    balance: "not-a-number"
  }
});
assert.equal(invalidCodexCredits.creditBalance, null);
assert.equal(invalidCodexCredits.creditsUnlimited, false);

console.log("Windows usage-parser checks passed.");
