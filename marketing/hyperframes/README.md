# ReadyCheck HyperFrames Preview

HyperFrames project for the GitHub README product preview GIF.

## Check

```bash
scripts/verify_readme_preview.sh
```

This runs HyperFrames lint, browser validation, layout inspection, GIF metadata checks, and sensitive-text checks. It also writes a six-frame contact sheet to the system temporary directory.

The contact sheet must be inspected manually before publishing. Confirm that the main window, menu-bar summary, and widget stay in separate regions with no overlap, clipping, edge artifacts, unreadable text, or personal information.

## Render

```bash
npm run render -- --output renders/readycheck-preview-hyperframes.mp4 --quality high --fps 30
ffmpeg -y -i renders/readycheck-preview-hyperframes.mp4 -vf "fps=15,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=bayer:bayer_scale=3" ../../docs/assets/readycheck-preview.gif
```

The README uses `docs/assets/readycheck-preview.gif`.

Do not commit `renders/` outputs unless a release explicitly needs the MP4.
