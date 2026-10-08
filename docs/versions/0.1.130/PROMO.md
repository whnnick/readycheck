# 0.1.130 Xiaohongshu campaign

[中文](PROMO.zh-CN.md) | [Version acceptance](QA.md) | [Video project](../../../marketing/remotion/README.md)

## Brief

Audience: Mac users who code with Codex daily. Channel: a portrait Xiaohongshu video note. First-three-second hook: running out of quota halfway through coding. One benefit: keep remaining quota visible so users can plan their coding time. CTA: search GitHub for ReadyCheck (owner whnnick), with [current installers](https://github.com/whnnick/readycheck/releases/latest).

Deliverables: a 29-second 1080×1920 / 30 fps video, a separate 1080×1440 cover, Chinese narration, burned-in captions, and post copy. Six shots cover the pain point, two quota windows, edge placement, expanded details/bubble, recovery reminders, and download. Large text avoids the top/bottom and right-side controls; upload-page and cover checks passed; public mobile-player acceptance remains pending while the note is under review.

## Provenance and acceptance

Native screenshots use current 0.1.130 SwiftUI views with synthetic quota fixtures from EdgeRailWidgetTests. Temporary capture changes were restored. Demonstration-data labels are visible; the workspace illustration and screenshot transitions are composited, not a live recording. The icon comes from the existing render_app_icon.swift generator. No account identity, credential, or real workspace content is used.

Narration is AI-synthesized with zh-CN-XiaoxiaoNeural, disclosed in the Chinese post copy. The platform's AI-content label was selected before publication. The low-volume synth bed was generated for this project. Recovery copy includes the requirement to enable reminders and keep the app running; behavior follows macOS notification settings. No additional quota is promised. Post copy explains that the Mac installer uses preview signing and may need first-launch confirmation; it is not Developer ID notarized.

| Requirement | Status | Evidence / limit |
| --- | --- | --- |
| Video, narration, captions | Complete | ReadyCheckXhsCN; H.264/AAC, 1080×1920, 30 fps, 29.056 seconds, stereo 48 kHz |
| Separate cover | Complete | ReadyCheckXhsCover, 1080×1440 |
| Current UI and privacy | Complete | Native fixture screenshots, demonstration labels, no personal account |
| Readability and timing | Sampled | All-video half-second contact sheet plus 540×960 mobile-sized frame; no visible text crop |
| Audio and export | Measured | -16.49 LUFS, -1.65 dBTP; no detected continuous 0.1-second black interval |
| Project verification | Passed | TypeScript and full render; both related native UI tests passed |
| Platform upload, cover, AI label | Passed | Video recognized as HD; separate cover passed platform quality evaluation; AI-content declaration selected |
| Public mobile playback | Pending | Note remains under review; public player/caption safe areas not yet verified |
| Account update | Submitted; under review | Publication-success page and note manager verified the title, 00:29 duration and 2026-10-02 22:04 timestamp (Asia/Shanghai); public visibility selected |
| Conversion results | Pending | Evaluate impressions, first-three-second retention, completion, profile visits, and GitHub downloads; do not infer attribution without evidence |

Ignored outputs live in marketing/remotion/out/xhs-0130/: readycheck-xiaohongshu-final.mp4, cover.png, 发布文案.txt, subtitles.srt, contact-sheet.jpg, publication-proof.jpg. The publication screenshot is local-only and excluded from Git. Source assets are reusable and contain no private data. Rendering commands are in the video README. This campaign changes no app behavior or version and creates no new Release.

The authorized creator account, video upload, cover quality, post copy, four platform topic tags, AI declaration and submission result were checked in the creator UI. Successful submission does not establish review approval or public availability. If player controls obscure captions, revise safe areas. If early retention is poor, change only the hook or cover in the next experiment.

## Chinese post copy

See [the paired Chinese document](PROMO.zh-CN.md#发布文案) for the exact title, caption, hashtags, download link and disclosures.


## 2026-10-07: second video with background music

Audience: Mac users who code with Codex. New first-three-second hook: “Checking quota still takes a window switch?” One benefit: keep quota at hand. Current 0.1.130 native fixture images demonstrate both rings, quota details and the desktop bubble, using a new light visual style and independent cover. CTA remains the verified GitHub download. Multiple creative variables changed; this is not a single-variable A/B test.

The video is 28 seconds, 1080×1920 at 30 fps; cover is 1080×1440. New AI narration uses zh-CN-XiaoxiaoNeural. The project-created synth track is audibly mixed, with smooth ducking during narration and fade-in/out. Quotas are synthetic and labeled; screenshot transitions are composited, not a live interaction recording.

| Check | Result / evidence |
| --- | --- |
| Release and CTA | Current GitHub latest remains v0.1.130; download verified |
| Build and video | TypeScript, full render and full decode passed; half-second contact sheet inspected across the entire clip |
| Voice completeness | All four audio clips fit their scenes; caption times match measured audio duration |
| Music and export | AAC, stereo 48 kHz; final -16.0 LUFS, -1.6 dBFS true peak; measurements do not establish human listening acceptance |
| Platform upload and cover | Recognized as HD; independent cover preview has no visible crop; platform cover quality evaluation passed |
| Caption and settings | Paragraphs, three platform topics, AI declaration, public visibility, scheduling off |
| Submission | Success page and note manager verified the exact title, separate cover, 00:28 duration and 2026-10-07 08:56 timestamp (Asia/Shanghai); under review |
| Real-world acceptance | Platform review, public mobile playback, device listening, impressions, first-three-second retention, completion, profile visits and download conversion remain pending |

Ignored outputs: marketing/remotion/out/xhs-oct07/readycheck-xiaohongshu-final.mp4, cover.png, contact-sheet.jpg, 发布文案.txt, publication-proof.jpg. App behavior/version remains unchanged; no Release is created. Do not claim measured conversion improvement before results exist. Exact Chinese copy is in the paired campaign document.
