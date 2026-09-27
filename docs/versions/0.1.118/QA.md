# 0.1.118 acceptance

[中文](QA.zh-CN.md) | [Version index](../../VERSIONS.md) | [0.1.117 acceptance](../0.1.117/QA.md)

Status: 0.1.118 release. The [official Codex backend client](https://github.com/openai/codex/blob/main/codex-rs/backend-client/src/client/rate_limit_resets.rs) maps the usage response's `rate_limit.allowed` to `ordinaryUsageAllowed` without inferring it from quota percentages. ReadyCheck's separate OAuth mode reads the same usage route.

| Requirement | Status | Evidence and remaining check |
| --- | --- | --- |
| Show backend permission through standalone OAuth | Passed with a live account; no-local-installation setup pending | In standalone mode, the signed preview showed “OAuth API · Verified” and “Codex available”; a manual refresh updated the quota while retaining that source and status. This mode does not inject a local app-server into the provider. Provider and parser tests cover true, false, and absent values independently of percentages. A Mac without Codex installed has not been tested. |
| Keep unknown distinct from restricted | Implemented; live null response pending | A missing or null `rate_limit.allowed` remains unknown; false means restricted. A percentage or reset time never supplies the missing permission. |
| Recover a saved OAuth login when Keychain blocks background access | Live read recovered; OS prompt action not observed | The signed 0.1.118 preview showed “Retry reading” when Keychain blocked access. The saved login was readable on the next acceptance run and a standalone OAuth refresh succeeded. The computer-use tool could not inspect or operate the OS authorization prompt, so the exact permission action remains unverified. The original local Codex mode was restored afterward. |
| Regression and packaging | Passed | 201 core and 4 app tests (including OAuth loopback), Windows check/smoke/package, and version consistency passed. The final DMG mounted with 0.1.118 metadata and a valid stable preview signature; the Windows ZIP passed `unzip -t`. Windows production-dependency audit reported zero vulnerabilities. |
| Public release | Published | [GitHub Release v0.1.118](https://github.com/whnnick/readycheck/releases/tag/v0.1.118) includes the macOS DMG and Windows portable ZIP. The preview signing identity is not a Developer ID certificate; the macOS build is not notarized. |
