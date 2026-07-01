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

const emptyResetDetails = parseManualResetDetails({
  rate_limit: {
    manual_resets: []
  }
});
assert.equal(emptyResetDetails.manualResetCount, 0);
assert.deepEqual(emptyResetDetails.manualResetExpirations, []);

console.log("Windows usage-parser checks passed.");
