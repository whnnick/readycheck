# 0.1.132 black-box acceptance

[中文](QA.zh-CN.md) · [Requirements](PLAN.md) · [Version index](../../VERSIONS.md)

Local preview acceptance on macOS 27.0.1, 2026-10-07. Public release requested on 2026-10-08; remote validation is tracked separately from local acceptance.

| Requirement | Result and evidence |
| --- | --- |
| Early warning | Implemented. Regression tests cover first-read baseline, independent windows, 10%/20%, account/reset changes, missing windows, invalid/stale/out-of-order data, persistence, failed-delivery retry and cancellation during delivery. Notification-client tests verify window-specific body, verified delivery, reuse of delivered identifiers and disabled alerts. Real UI selected both thresholds; the saved 20% setting survived restart. Restored to off after testing. |
| Temporary hiding | Implemented. Deadline and preference tests cover 30/60 minutes, exact expiry, invalid values and reload. Real UI hid for 30 minutes, retained the original deadline after restart, continued reading actual quota and restored immediately on request. |
| Style previews | Implemented. Real UI verifies selection and explanatory captions. Round bubble was dragged from an edge into the desktop, expanded and collapsed with actual quota, then returned to its prior edge position. Existing controllers retain separate style positions. |
| Data status | Implemented. Tests distinguish unavailable reads from missing metadata, fresh/stale values, blocked permission and historical subscription dates. Real OAuth data was read after the existing credential retry. Chinese dates and historical-date explanations were inspected; long-text width and duplicate restore controls were corrected during acceptance. |
| Packaging/checks | 241 Swift tests pass (227 Core + 14 App), including the localhost OAuth callback. Release app build and stable preview signing pass; installed bundle version is 0.1.132 and strict signature verification passes. Version consistency and diff checks pass. |

## Partial and real-environment follow-up

- No real low-quota threshold crossing occurred during acceptance. Specific warning behavior is covered by evaluator and notification-client tests; actual low-quota banner delivery remains to be observed during ordinary use. No quota was deliberately consumed to force a warning.
- Automatic restoration after a full 30/60-minute wait, wake after expiry, multi-display behavior and Reduce Motion remain live follow-ups. Deadline logic is tested; that is not proof of a real sleep/wake cycle.
- Still-frame expansion/collapse inspection does not prove frame-perfect motion. No new animation implementation is claimed.
- Main-window previews were checked in Chinese and English, including a one-hour hide and the single restore control. Native menu-bar layout remains a live follow-up; its shared controls are compiled but not visually accepted here.
- Replacing the final signed binary requested Keychain confirmation again. The system security window cannot be operated by the automation tool; final credential confirmation is left to the user. Earlier installed 0.1.132 builds successfully read real OAuth quota. Private screenshot evidence is in ignored `.build/qa/0.1.132/english-snooze.png`.
- macOS 14 and Windows are not live-tested. Windows shares only the version bump. No real logout/startup test is claimed.
- Preview identity is self-signed, not Developer ID/notarized. Credentials and private UI evidence are excluded from source and release materials.

## Public-release checks

Follow the existing [release workflow](../../RELEASE.md): package the current version, review sensitive data and public source/history, verify remote assets/latest and retain the pending live checks above. Release preparation points documentation to v0.1.132; it is not proof that remote publication succeeded.


## Verified publication — 2026-10-08

Public-source tests pass (227 Core + 14 App). Windows checks, service smoke and UI smoke pass. The mounted DMG contains 0.1.132 with a valid stable preview signature; ZIP integrity passes. Both local artifact directories contain only the current DMG and Windows ZIP. Public history was checked for internal configuration paths and private-path/token patterns.

Source/tag commit: `a2ef0e2`. The [Release](https://github.com/whnnick/readycheck/releases/tag/v0.1.132) is public; latest is v0.1.132. Both download URLs return HTTP 200 and GitHub's SHA-256 digests match the locally checked upload files:

- macOS DMG: `592bb8d527e71085c9d391f6f8968e114509b44fe0a65c5edcbf14cabe921f49`
- Windows ZIP: `3b9f78fa7f99835a134993f90ffcc70092ece055d7f25380b4db2b03248d6d09`

Publication does not resolve the live follow-ups listed above.
