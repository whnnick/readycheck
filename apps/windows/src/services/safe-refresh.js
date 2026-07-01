"use strict";

const DENIED_REFRESH_PATHS = [
  "/v1/responses",
  "/v1/chat/completions",
  "/v1/messages"
];

const ALLOWED_REFRESH_ENDPOINTS = [
  {
    protocol: "https:",
    host: "chatgpt.com",
    path: "/backend-api/wham/usage"
  },
  {
    protocol: "https:",
    host: "api.openai.com",
    pathPrefix: "/v1/organization/usage"
  },
  {
    protocol: "https:",
    host: "api.openai.com",
    pathPrefix: "/v1/organization/costs"
  }
];

function isDeniedInferenceEndpoint(url) {
  return DENIED_REFRESH_PATHS.some((path) => url.pathname === path || url.pathname.startsWith(`${path}/`));
}

function isAllowedForRefresh(rawUrl) {
  let url;
  try {
    url = new URL(rawUrl);
  } catch {
    return false;
  }

  if (isDeniedInferenceEndpoint(url)) {
    return false;
  }

  return ALLOWED_REFRESH_ENDPOINTS.some((endpoint) => {
    if (url.protocol !== endpoint.protocol || url.host !== endpoint.host) {
      return false;
    }

    if (endpoint.path) {
      return url.pathname === endpoint.path;
    }

    return url.pathname === endpoint.pathPrefix || url.pathname.startsWith(`${endpoint.pathPrefix}/`);
  });
}

module.exports = {
  isAllowedForRefresh
};
