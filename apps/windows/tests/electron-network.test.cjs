"use strict";

const assert = require("node:assert/strict");
const fs = require("node:fs");
const http = require("node:http");
const os = require("node:os");
const path = require("node:path");
const { app, net, session } = require("electron");
const { CodexOAuthClient } = require("../src/services/oauth");
const { CodexUsageClient } = require("../src/services/usage-client");

const directory = fs.mkdtempSync(path.join(os.tmpdir(), "readycheck-network-"));
app.setPath("userData", directory);
app.commandLine.appendSwitch("disable-gpu");
const deadline = setTimeout(() => {
  console.error("Electron network smoke timed out.");
  app.exit(1);
}, 30000);

app.whenReady().then(async () => {
  const requests = [];
  let rejectToken = false;
  const proxy = http.createServer(async (request, response) => {
    const url = new URL(request.url);
    let body = "";
    for await (const chunk of request) body += chunk;
    requests.push({ method: request.method, path: url.pathname, body, headers: request.headers });
    response.setHeader("Content-Type", "application/json");
    if (url.pathname === "/oauth/token") {
      response.statusCode = rejectToken ? 403 : 200;
      response.end(JSON.stringify(rejectToken
        ? { error: "unsupported_region", error_description: "Synthetic region rejection" }
        : { access_token: "fixture-access", refresh_token: "fixture-refresh", expires_in: 3600, token_type: "Bearer" }));
    } else {
      response.end(JSON.stringify({ fixture: url.pathname }));
    }
  });
  let exitCode = 0;
  try {
    await new Promise((resolve, reject) => {
      proxy.once("error", reject);
      proxy.listen(0, "127.0.0.1", resolve);
    });
    const proxyAddress = `127.0.0.1:${proxy.address().port}`;
    await session.defaultSession.setProxy({ mode: "fixed_servers", proxyRules: proxyAddress });
    const tokenURL = "http://readycheck-network.invalid/oauth/token";
    assert.equal(await session.defaultSession.resolveProxy(tokenURL), `PROXY ${proxyAddress}`);
    const fetchImpl = (url, options) => net.fetch(url, { ...options, signal: AbortSignal.timeout(8000) });
    const oauth = new CodexOAuthClient({ config: { tokenURL, clientID: "fixture-client", redirectURI: "http://localhost/callback" }, fetchImpl });
    const token = await oauth.exchangeCode("fixture-code", { verifier: "fixture-verifier" });
    assert.equal(token.accessToken, "fixture-access");
    assert.equal((await oauth.refreshToken(token.refreshToken)).refreshToken, "fixture-refresh");
    const usage = new CodexUsageClient({
      fetchImpl: (url, options) => {
        const target = new URL(url);
        target.protocol = "http:";
        target.host = "readycheck-network.invalid";
        return fetchImpl(target.href, options);
      }
    });
    assert.equal((await usage.fetchUsage(token.accessToken, "fixture-account")).fixture, "/backend-api/wham/usage");
    assert.equal((await usage.fetchResetCredits(token.accessToken, "fixture-account")).fixture, "/backend-api/wham/rate-limit-reset-credits");
    rejectToken = true;
    await assert.rejects(oauth.refreshToken(token.refreshToken), /HTTP 403.*Windows/s);
    assert.deepEqual(requests.map(request => request.method), ["POST", "POST", "GET", "GET", "POST"]);
    assert.equal(new URLSearchParams(requests[0].body).get("code_verifier"), "fixture-verifier");
    assert.equal(new URLSearchParams(requests[1].body).get("grant_type"), "refresh_token");
    assert.equal(requests[2].headers.authorization, "Bearer fixture-access");
    assert.equal(requests[2].headers["chatgpt-account-id"], "fixture-account");
    console.log(`Electron network smoke passed on ${process.platform}: OAuth, refresh, usage, reset metadata and 403 guidance through a loopback proxy.`);
  } catch (error) {
    console.error(error);
    exitCode = 1;
  } finally {
    clearTimeout(deadline);
    await session.defaultSession.closeAllConnections();
    await new Promise(resolve => proxy.close(resolve));
    app.exit(exitCode);
  }
}).catch(error => {
  console.error(error);
  app.exit(1);
});
