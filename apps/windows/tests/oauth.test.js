"use strict";

const assert = require("node:assert/strict");
const {
  OAUTH_CONFIG,
  CodexOAuthClient,
  completeOAuthCallback,
  decodeJWTPayload,
  generatePKCECodes,
  normalizeTokenResponse,
  parseOAuthCallback
} = require("../src/services/oauth");

const pkce = generatePKCECodes();
assert.equal(typeof pkce.verifier, "string");
assert.equal(typeof pkce.challenge, "string");
assert.notEqual(pkce.verifier, pkce.challenge);

const session = new CodexOAuthClient({
  now: () => new Date("2026-06-30T00:00:00Z")
}).makeAuthorizationSession();
const authorizationURL = new URL(session.authorizationURL);
assert.equal(authorizationURL.origin + authorizationURL.pathname, OAUTH_CONFIG.authorizationURL);
assert.equal(authorizationURL.searchParams.get("client_id"), OAUTH_CONFIG.clientID);
assert.equal(authorizationURL.searchParams.get("response_type"), "code");
assert.equal(authorizationURL.searchParams.get("redirect_uri"), OAUTH_CONFIG.redirectURI);
assert.equal(authorizationURL.searchParams.get("code_challenge_method"), "S256");
assert.equal(authorizationURL.searchParams.get("state"), session.state);
assert.equal(authorizationURL.searchParams.get("prompt"), "login");
assert.equal(authorizationURL.searchParams.get("codex_cli_simplified_flow"), "true");

assert.deepEqual(parseOAuthCallback("http://localhost:1455/auth/callback?code=abc&state=xyz"), {
  code: "abc",
  state: "xyz",
  error: null,
  errorDescription: null
});

completeOAuthCallback(
  "http://localhost:1455/auth/callback?code=abc&state=wrong",
  session,
  { exchangeCode: async () => ({}) }
).then(
  () => assert.fail("state mismatch should fail"),
  (error) => assert.match(error.message, /state mismatch/i)
);

function jwt(payload) {
  const header = Buffer.from(JSON.stringify({ alg: "none" })).toString("base64url");
  const body = Buffer.from(JSON.stringify(payload)).toString("base64url");
  return `${header}.${body}.signature`;
}

const accessToken = jwt({
  "https://api.openai.com/auth": { chatgpt_account_id: "acct_1" },
  "https://api.openai.com/profile": { email: "USER@EXAMPLE.COM" }
});
const normalized = normalizeTokenResponse(
  {
    access_token: accessToken,
    refresh_token: "refresh",
    token_type: "Bearer",
    expires_in: 60
  },
  new Date("2026-06-30T00:00:00Z")
);
assert.equal(normalized.accountID, "acct_1");
assert.equal(normalized.email, "user@example.com");
assert.equal(normalized.expiresAt, "2026-06-30T00:01:00.000Z");
assert.deepEqual(decodeJWTPayload(accessToken)["https://api.openai.com/profile"], {
  email: "USER@EXAMPLE.COM"
});

console.log("Windows OAuth checks passed.");
