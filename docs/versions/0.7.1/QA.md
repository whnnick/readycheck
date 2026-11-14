# ReadyCheck 0.7.1 verification

[简体中文](QA.zh-CN.md) · [Release notes](RELEASE_NOTES.md)

The macOS patch restores Muse weekly allowance reads. In the installed 0.7.1 development build, the existing session returned a weekly percentage and reset time after launch, manual refresh and relaunch. After Keychain confirmation, Codex quota and DeepSeek balance also displayed live. Fourteen reader and fourteen focused Swift tests passed on the same fix. [Installed checks](../0.7.0/QA.md).

The previous 0.7.0 checks cover the unchanged interface and preferences. The Windows patch changes package metadata only. The original Windows OAuth 403 device and other Muse accounts remain unverified. [0.7.0 checks](../0.7.0/QA.md).

The public-source build ran 545 Swift tests with 3 skips and zero failures. All 14 Muse reader tests passed. The mounted DMG passed strict signature, version, bundled reader and privacy checks. The Windows ZIP passed CRC and all 13 shipped JavaScript files matched the checked source. Local Node checks and UI smoke passed.
