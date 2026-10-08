# 0.1.131 black-box acceptance

Corresponds to the [fix plan](PLAN.md). Status: installed and accepted locally; unpublished.

| Requirement | Result and evidence |
| --- | --- |
| Detect incomplete installations | Complete. Five new regression tests cover missing/malformed plist, absent/non-executable binaries, wrong identity and deletion after a successful read. Complete bundles outside Applications remain accepted. |
| Actionable failures | Complete. Bilingual reinstall guidance, Login Items entry after a system failure and private diagnostic logging. Failure branches were inspected; another system registration error was not deliberately reproduced. |
| Complete bundle launches | Complete. The build/run script was executed with stable signing. The app was then installed in Applications; installed version 0.1.131 and signature were verified. |
| Toggle and retained state | Complete. On macOS 27.0.1 the real UI reported disabled, then enabled after toggling, and remained enabled after reopening. System logs confirmed the login item points to the installed app in Applications. |
| Automated checks | Full Swift tests passed, including five new App tests and the localhost OAuth callback test. Version consistency, shell syntax and diff checks passed. Original-workspace test signing failed on Finder extended attributes; a clean scratch directory passed. |

## Partial, unfinished and live follow-up

- No macOS logout or reboot was performed. Registration and retained state are not proof of startup after a real login.
- macOS 14 remains untested. Windows only shares the version; no Windows login-startup feature was added.
- The existing account still requires Keychain access confirmation. Credentials were not deleted; login-item repair does not prove quota authentication recovery.
- Stable self-signed preview identity only; no Developer ID or notarization claim. No GitHub push or Release.
- The private UI evidence is in ignored `.build/qa/0.1.131/launch-at-login.png`, excluded from public source.

## Public-release blockers

Follow the existing release workflow to package, inspect sensitive data and verify remote assets. Actual startup after logging out and back in remains pending. These do not block the locally verified toggle fix.
