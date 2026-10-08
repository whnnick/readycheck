# ReadyCheck Product Motion

Remotion project for a short ReadyCheck product introduction video.

## Preview

```bash
cd marketing/remotion
npm install
npm run dev
```

Open the Remotion Studio URL and choose `ReadyCheckIntroCN` or `ReadyCheckIntroEN`.

## Render

```bash
npm run generate:bgm
npm run render:preview
npm run render:cn
npm run render:en
```

Rendered videos are written to `marketing/remotion/out/`. The GitHub README preview GIF is now generated from `marketing/hyperframes`.

## Composition

- `ReadyCheckIntroCN`: Chinese, 30 seconds, 1920x1080, 30 fps.
- `ReadyCheckIntroEN`: English, 30 seconds, 1920x1080, 30 fps.
- `ReadyCheckPreviewGif`: legacy README preview source. Use `marketing/hyperframes` for the current GitHub README preview GIF.

The motion uses frame-driven Remotion interpolation only. It intentionally avoids CSS transitions and CSS keyframe animations so renders are deterministic.

The background track is generated locally by `scripts/generate-tech-bgm.mjs` and saved to `public/audio/readycheck-tech-pulse.wav`. It is a procedural synth bed created for this project, so no external music license is required.

## Xiaohongshu campaign (0.1.130)

- `ReadyCheckXhsCN`: 29 seconds, 1080×1920, 30 fps, Chinese narration and burned-in captions.
- `ReadyCheckXhsCover`: separate 1080×1440 cover.
- Brief, copy, provenance and acceptance: [English](../../docs/versions/0.1.130/PROMO.md) | [中文](../../docs/versions/0.1.130/PROMO.zh-CN.md).

```bash
npm run typecheck
npm run render:xhs
npm run cover:xhs
ffmpeg -y -i out/xhs-0130/readycheck-xiaohongshu.mp4 -c:v copy -af volume=3.3dB -c:a aac -b:a 192k -movflags +faststart out/xhs-0130/readycheck-xiaohongshu-final.mp4
```

Use `readycheck-xiaohongshu-final.mp4` for upload. Native screenshots come from the current app's test fixtures; percentages are explicitly marked as demonstration data. The workspace illustration and screenshot transitions are composited, not a live screen recording. Narration is AI-synthesized (zh-CN-XiaoxiaoNeural); disclose this in the post/platform label. The existing procedural synth track is reused at low volume. Neither an account identity nor real account usage is included.


## Second Xiaohongshu video (2026-10-07)

`ReadyCheckOct07` is a new 28-second portrait video with light visuals, native fixture screenshots, Chinese AI narration and a clearly mixed project-created music track. `ReadyCheckOct07Cover` is its independent 3:4 cover. Each scene is also available in the `Oct07-Scenes` Studio folder. Provenance, Chinese copy and acceptance are in the existing bilingual campaign documents linked above.

```bash
npm run typecheck
npm run render:xhs-oct07
npm run cover:xhs-oct07
ffmpeg -y -i out/xhs-oct07/master.mp4 -c:v copy -af 'loudnorm=I=-16:TP=-1.5:LRA=7:measured_I=-17.05:measured_TP=-2.68:measured_LRA=3.30:measured_thresh=-27.35:offset=-0.07:linear=true' -ar 48000 -c:a aac -b:a 192k -movflags +faststart out/xhs-oct07/readycheck-xiaohongshu-final.mp4
```

The measured normalization values apply to this exact master; measure them again after changing audio/timing. Local publication screenshots stay in ignored output directories.
