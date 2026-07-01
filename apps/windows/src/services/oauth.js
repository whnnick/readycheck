"use strict";

const crypto = require("node:crypto");

const OAUTH_CONFIG = {
  authorizationURL: "https://auth.openai.com/oauth/authorize",
  tokenURL: "https://auth.openai.com/oauth/token",
  clientID: "app_EMoamEEZ73f0CkXaXp7hrann",
  redirectURI: "http://localhost:1455/auth/callback",
  scopes: ["openid", "email", "profile", "offline_access"]
};

class CodexOAuthClient {
  constructor(options = {}) {
    this.config = options.config || OAUTH_CONFIG;
    this.fetchImpl = options.fetchImpl || globalThis.fetch;
    this.now = options.now || (() => new Date());
  }

  makeAuthorizationSession() {
    const pkce = generatePKCECodes();
    const state = generateOAuthState();
    return {
      state,
      pkce,
      authorizationURL: buildAuthorizationURL(this.config, state, pkce.challenge)
    };
  }

  async exchangeCode(code, pkce) {
    return this.postTokenRequest({
      grant_type: "authorization_code",
      client_id: this.config.clientID,
      code,
      redirect_uri: this.config.redirectURI,
      code_verifier: pkce.verifier
    });
  }

  async refreshToken(refreshToken) {
    return this.postTokenRequest({
      grant_type: "refresh_token",
      client_id: this.config.clientID,
      refresh_token: refreshToken,
      scope: "openid profile email"
    });
  }

  async postTokenRequest(form) {
    if (typeof this.fetchImpl !== "function") {
      throw new Error("Fetch is not available in this Electron runtime.");
    }

    const response = await this.fetchImpl(this.config.tokenURL, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Accept: "application/json"
      },
      body: new URLSearchParams(form).toString()
    });

    if (!response.ok) {
      throw new Error(`OAuth token request failed with status ${response.status}`);
    }

    const payload = await response.json();
    return normalizeTokenResponse(payload, this.now());
  }
}

function generatePKCECodes(byteCount = 32) {
  const verifier = base64URLEncode(crypto.randomBytes(byteCount));
  const challenge = base64URLEncode(crypto.createHash("sha256").update(verifier).digest());
  return { verifier, challenge };
}

function generateOAuthState(byteCount = 24) {
  return base64URLEncode(crypto.randomBytes(byteCount));
}

function buildAuthorizationURL(config, state, challenge) {
  const url = new URL(config.authorizationURL);
  url.searchParams.set("client_id", config.clientID);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("redirect_uri", config.redirectURI);
  url.searchParams.set("scope", config.scopes.join(" "));
  url.searchParams.set("state", state);
  url.searchParams.set("code_challenge", challenge);
  url.searchParams.set("code_challenge_method", "S256");
  url.searchParams.set("prompt", "login");
  url.searchParams.set("id_token_add_organizations", "true");
  url.searchParams.set("codex_cli_simplified_flow", "true");
  return url.toString();
}

function parseOAuthCallback(callbackURL) {
  const url = new URL(callbackURL);
  const valueFor = (name) => {
    const values = url.searchParams.getAll(name);
    return values.length > 0 ? values[values.length - 1] : null;
  };

  return {
    code: valueFor("code"),
    state: valueFor("state"),
    error: valueFor("error"),
    errorDescription: valueFor("error_description")
  };
}

async function completeOAuthCallback(callbackURL, session, client) {
  const callback = parseOAuthCallback(callbackURL);
  if (callback.error) {
    throw new Error(callback.errorDescription || callback.error);
  }
  if (callback.state !== session.state) {
    throw new Error("OAuth state mismatch.");
  }
  if (!callback.code) {
    throw new Error("OAuth callback is missing an authorization code.");
  }
  return client.exchangeCode(callback.code, session.pkce);
}

function normalizeTokenResponse(payload, now) {
  const accessToken = payload.access_token;
  const refreshToken = payload.refresh_token;
  if (!accessToken || !refreshToken) {
    throw new Error("OAuth token response is incomplete.");
  }

  const expiresIn = Number(payload.expires_in || 0);
  const expiresAt = new Date(now.getTime() + Math.max(expiresIn, 0) * 1000).toISOString();
  return {
    accessToken,
    refreshToken,
    idToken: payload.id_token || null,
    tokenType: payload.token_type || "Bearer",
    expiresAt,
    accountID: jwtClaim(accessToken, "https://api.openai.com/auth", "chatgpt_account_id"),
    email: normalizeEmail(jwtClaim(accessToken, "https://api.openai.com/profile", "email"))
  };
}

function accountIDFromToken(token) {
  return jwtClaim(token, "https://api.openai.com/auth", "chatgpt_account_id");
}

function planNameFromToken(token) {
  return jwtClaim(token, "https://api.openai.com/auth", "chatgpt_plan_type");
}

function subscriptionRenewalAtFromToken(token) {
  return jwtDateClaim(token, "https://api.openai.com/auth", "chatgpt_subscription_active_until");
}

function jwtClaim(token, namespace, key) {
  const payload = decodeJWTPayload(token);
  const scoped = payload && payload[namespace];
  return scoped && typeof scoped[key] === "string" ? scoped[key] : null;
}

function jwtDateClaim(token, namespace, key) {
  const payload = decodeJWTPayload(token);
  const scoped = payload && payload[namespace];
  return scoped ? dateFromValue(scoped[key]) : null;
}

function decodeJWTPayload(token) {
  if (!token || typeof token !== "string") {
    return null;
  }

  const parts = token.split(".");
  if (parts.length !== 3) {
    return null;
  }

  try {
    const payload = parts[1].replace(/-/g, "+").replace(/_/g, "/");
    const padded = payload.padEnd(payload.length + ((4 - (payload.length % 4)) % 4), "=");
    return JSON.parse(Buffer.from(padded, "base64").toString("utf8"));
  } catch (_error) {
    return null;
  }
}

function normalizeEmail(value) {
  return typeof value === "string" && value.trim() ? value.trim().toLowerCase() : null;
}

function dateFromValue(value) {
  if (value === null || value === undefined) {
    return null;
  }

  if (typeof value === "number" || (typeof value === "string" && value.trim())) {
    const numeric = Number(value);
    if (Number.isFinite(numeric) && numeric > 0) {
      const seconds = numeric > 1_000_000_000_000 ? numeric / 1000 : numeric;
      return new Date(seconds * 1000).toISOString();
    }
  }

  if (typeof value === "string") {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date.toISOString();
  }

  return null;
}

function base64URLEncode(buffer) {
  return buffer.toString("base64").replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

module.exports = {
  OAUTH_CONFIG,
  CodexOAuthClient,
  accountIDFromToken,
  buildAuthorizationURL,
  completeOAuthCallback,
  decodeJWTPayload,
  generateOAuthState,
  generatePKCECodes,
  normalizeTokenResponse,
  planNameFromToken,
  subscriptionRenewalAtFromToken,
  parseOAuthCallback
};
