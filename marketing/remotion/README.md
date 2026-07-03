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

Rendered videos are written to `marketing/remotion/out/`. The README preview GIF is written to `docs/assets/readycheck-preview.gif`.

## Composition

- `ReadyCheckIntroCN`: Chinese, 30 seconds, 1920x1080, 30 fps.
- `ReadyCheckIntroEN`: English, 30 seconds, 1920x1080, 30 fps.
- `ReadyCheckPreviewGif`: GitHub README preview, 6 seconds, 800x450, 30 fps source rendered to a 15 fps GIF.

The motion uses frame-driven Remotion interpolation only. It intentionally avoids CSS transitions and CSS keyframe animations so renders are deterministic.

The background track is generated locally by `scripts/generate-tech-bgm.mjs` and saved to `public/audio/readycheck-tech-pulse.wav`. It is a procedural synth bed created for this project, so no external music license is required.
