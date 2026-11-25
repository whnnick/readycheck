# ReadyCheck 0.7.4 verification

[简体中文](QA.zh-CN.md) · [Changelog](../../../CHANGELOG.md)

## 0.7.4 stable

- [Release scope](RELEASE_NOTES.md) covers macOS navigation, keyboard focus and the persistent aggregate capsule. The public source suite ran 561 Swift cases with zero failures and 3 opt-in skips. All 14 Muse reader cases passed. Spring rebound, rapid reversal, selection and focus, and aggregate detail hover and pin behavior passed in native tests.
- The mounted DMG passed image integrity, strict signature, version, embedded resource and personal-path checks. The installed app launched with the build directory moved away. Its settings menu showed the neutral glass selection on click and the system focus ring after an arrow-key move.
- After renewed Keychain access, Codex quota, Muse weekly quota and DeepSeek balance were visible and each manual refresh completed. The capsule selected each service in the original order and reopened the main window. The saved three-service frame and Quick display selection matched their values before installation.
- Windows application code is unchanged from 0.7.3. The 0.7.4 package passed Node 24 service, wiring and UI smoke checks, ZIP integrity, and comparison of its 16 embedded application source files. Real-account retesting on the original Windows device with OAuth 403 remains unavailable.

## 0.7.4-dev.3 mouse selection and keyboard focus

- Mouse selection in the sidebar and settings sections uses the translucent capsule and its thin neutral highlight. Keyboard navigation adds the system focus color to the same capsule.
- All 20 targeted Swift tests passed. In the installed build, a click on General selected it without a blue ring, Left selected Display and showed the blue focus indicator, and clicking Display again cleared the indicator.
- Muse resumed reading after installation. Codex and DeepSeek are awaiting renewed Keychain access.

## 0.7.4-dev.2 main window focus

- The selected item's focus highlight follows the same moving capsule in the sidebar and settings sections. If keyboard focus moves independently of selection, a short marker identifies the focused item.
- All 18 targeted Swift tests passed, covering motion and reversal, the aggregate capsule and native pages at minimum window size. Mouse selection and arrow-key navigation passed in the installed app on macOS 27.2.1.
- Muse read successfully on the new build. Codex and DeepSeek are awaiting renewed Keychain access.

## 0.7.4-dev.1 glass selection

- The main sidebar, settings sections and persistent aggregate capsule share a translucent selection indicator with a thin highlight. Switching items stretches the indicator along its travel axis before a spring rebound. A second selection carries the current velocity into the new move.
- The floating capsule uses an adaptive frosted shell. Its indicator follows the service shown in the detail panel. The service rings, pin state, hover delay, grip and placement use their existing data and controls. Reduce Motion uses a stationary selection and Reduce Transparency uses an opaque surface.
- All 35 targeted Swift tests passed, including rebound and reversal on the motion model, aggregate detail switching and placement, and native window rendering. The rail was rendered in both appearances using synthetic data.
- The signed build was launched on macOS 27.2.1 after relocating its build directory. In the installed app, mouse and arrow-key navigation worked across the sidebar and settings sections. The existing capsule stayed at the same edge and vertical center. Muse resumed reading, its detail opened from the capsule, and pinning worked.
- Testing the installed capsule across all three live services is pending the Codex and DeepSeek Keychain confirmations. Synthetic three-service hover, pin and placement coverage passed.
