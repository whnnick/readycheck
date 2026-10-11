# 0.1.132 Xiaohongshu campaign

[中文](PROMO.zh-CN.md) | [Product plan](PLAN.md) | [Acceptance](QA.md)

The editable campaign project remains local and is excluded from application source releases.

## Brief and proof

Audience: Mac users who code with Codex. Channel: Xiaohongshu portrait video. Hook: “额度见底，才发现？” One benefit: check quota less and avoid interruptions. Evidence: current native 0.1.132 views with anonymous 13%/70% demo quotas, optional 20%/10% low alerts, widget hiding for 30 minutes/1 hour while refreshing and enabled reminders continue, and the three style previews. The film does not claim extra quota or guaranteed OS notification visibility.

CTA: search GitHub for whnnick/readycheck and download the [0.1.132 installers](https://github.com/whnnick/readycheck/releases/tag/v0.1.132). The post explains macOS 14+, preview-signing installation instructions, and that the video demonstrates the Mac implementation. Windows has a separate portable asset; these new interactions are not represented as Windows features.

Deliverables: 30-second 1080×1920/30fps video, separate 1080×1440 cover, Chinese publishing copy and original electronic BGM. There is no synthesized speech. Composited UI actions are identified as demonstration animation; fixture quotas are labelled. No real user account, credential or workspace content appears. Native fixture capture changes were removed after successful capture tests.

## Acceptance

| Requirement | Status and evidence |
| --- | --- |
| Current product evidence | Complete: native current SwiftUI fixtures, source behaviour traced to PLAN/QA |
| Export format, audio and final video | Complete: H.264/AAC,1080×1920,30fps,30.000s,stereo48kHz; final-film contact sheet inspected; -16.13LUFS/-1.49dBTP; no detected continuous0.1s black interval |
| Layout/runtime/motion/contrast | HyperFrames check passed, zero errors in all four browser audits; static linter retains advisory Studio edit-target/selector warnings |
| Scene/cut review | Midpoint and cut-adjacent snapshots inspected; transparent screenshot margins removed through presentation cropping, native controls remain complete |
| Cover | Independent 1080×1440 native render reviewed |
| Publishing | Submitted 2026-10-08 09:07 CST: creator console displayed publication success; note manager confirmed “Codex额度告急？让浮窗提前提醒”, 00:30, under review. Public visibility and marketing-content disclosure were selected; cover quality assessment passed |
| Public mobile playback | Pending publication approval and real-player review |
| Conversion metrics | Pending impressions, first-three-second retention, completion, profile visits and downloads; no attributed conversion claimed |

This iteration changes the hook, foreground evidence and music-led pacing; success remains to be measured. If public-player controls obscure information or audience retention does not improve, revise the opening or shorten the cut. Do not infer a measured improvement from production completion.

Generated MP4 and contact sheets remain in the project's ignored renders/ and snapshots/ directories. Submission evidence is the creator-console UI observation; an account-free status record stays in ignored renders/. Marketing production changes no app behaviour and needs no new app version.
