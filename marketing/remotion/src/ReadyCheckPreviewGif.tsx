import React from 'react';
import {
  AbsoluteFill,
  Easing,
  Img,
  interpolate,
  staticFile,
  useCurrentFrame,
} from 'remotion';

const clamp = {
  extrapolateLeft: 'clamp' as const,
  extrapolateRight: 'clamp' as const,
};

const ease = Easing.bezier(0.16, 1, 0.3, 1);

const fade = (frame: number, start: number, end: number) =>
  interpolate(frame, [start, end], [0, 1], {...clamp, easing: ease});

const fadeOut = (frame: number, start: number, end: number) =>
  interpolate(frame, [start, end], [1, 0], {...clamp, easing: Easing.in(Easing.cubic)});

export const ReadyCheckPreviewGif: React.FC = () => {
  const frame = useCurrentFrame();
  const intro = fade(frame, 0, 20);
  const productFocus = fade(frame, 24, 78);
  const widgetFocus = fade(frame, 66, 118);
  const loopFade = fadeOut(frame, 168, 180);
  const sweepX = interpolate(frame, [0, 180], [-220, 1010], clamp);

  const mainScale = interpolate(productFocus, [0, 1], [0.34, 0.38]);
  const mainX = interpolate(productFocus, [0, 1], [94, 72]);
  const mainY = interpolate(productFocus, [0, 1], [116, 96]);
  const widgetScale = interpolate(widgetFocus, [0, 1], [0.29, 0.34]);
  const widgetX = interpolate(widgetFocus, [0, 1], [558, 520]);
  const widgetY = interpolate(widgetFocus, [0, 1], [176, 150]);

  return (
    <AbsoluteFill
      style={{
        background:
          'radial-gradient(circle at 22% 10%, rgba(10,132,255,0.50), transparent 30%), radial-gradient(circle at 86% 20%, rgba(68,211,107,0.28), transparent 26%), linear-gradient(135deg, #05070B 0%, #0D1624 54%, #050608 100%)',
        color: '#F7FAFF',
        fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif',
        overflow: 'hidden',
      }}
    >
      <Grid frame={frame} />
      <GlowBand x={sweepX} />
      <QuotaStripes frame={frame} />
      <TopBar frame={frame} />

      <div
        style={{
          position: 'absolute',
          left: mainX,
          top: mainY,
          width: 1488,
          height: 1110,
          borderRadius: 26,
          overflow: 'hidden',
          boxShadow: '0 36px 120px rgba(0,0,0,0.62), 0 0 90px rgba(10,132,255,0.42)',
          transform: `scale(${mainScale}) rotate(${interpolate(productFocus, [0, 1], [-1.4, -0.45])}deg)`,
          transformOrigin: 'top left',
          opacity: intro * loopFade,
        }}
      >
        <Img
          src={staticFile('images/readycheck-main-real.png')}
          style={{width: '100%', height: '100%', objectFit: 'cover'}}
        />
      </div>

      <div
        style={{
          position: 'absolute',
          left: widgetX,
          top: widgetY,
          width: 700,
          height: 650,
          borderRadius: 30,
          overflow: 'hidden',
          boxShadow: '0 36px 120px rgba(0,0,0,0.66), 0 0 88px rgba(68,211,107,0.36)',
          transform: `scale(${widgetScale}) rotate(${interpolate(widgetFocus, [0, 1], [3.2, 0.6])}deg)`,
          transformOrigin: 'top left',
          opacity: interpolate(frame, [32, 62], [0.76, 1], clamp) * loopFade,
        }}
      >
        <Img
          src={staticFile('images/readycheck-widget-real.png')}
          style={{width: '100%', height: '100%', objectFit: 'cover'}}
        />
      </div>
    </AbsoluteFill>
  );
};

const Grid: React.FC<{frame: number}> = ({frame}) => (
  <div
    style={{
      position: 'absolute',
      inset: 0,
      opacity: 0.18,
      backgroundImage:
        'linear-gradient(rgba(255,255,255,0.08) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.08) 1px, transparent 1px)',
      backgroundSize: '42px 42px',
      backgroundPosition: `0 ${frame % 42}px`,
      maskImage: 'linear-gradient(to bottom, transparent 0%, black 16%, black 78%, transparent 100%)',
    }}
  />
);

const GlowBand: React.FC<{x: number}> = ({x}) => (
  <div
    style={{
      position: 'absolute',
      left: x,
      top: -80,
      width: 150,
      height: 620,
      transform: 'skewX(-18deg)',
      background:
        'linear-gradient(90deg, transparent, rgba(255,255,255,0.16), rgba(10,132,255,0.28), transparent)',
      filter: 'blur(2px)',
      opacity: 0.82,
    }}
  />
);

const QuotaStripes: React.FC<{frame: number}> = ({frame}) => {
  const lift = Math.sin(frame / 16) * 5;
  const colors = ['#44D36B', '#FFB340', '#FF5C5C'];
  return (
    <div style={{position: 'absolute', right: 34, bottom: 30, display: 'grid', gap: 8}}>
      {colors.map((color, index) => (
        <div
          key={color}
          style={{
            width: 138 - index * 18,
            height: 8,
            borderRadius: 99,
            background: color,
            boxShadow: `0 0 24px ${color}88`,
            transform: `translateX(${interpolate(frame, [18 + index * 8, 58 + index * 8], [56, 0], clamp)}px) translateY(${lift}px)`,
            opacity: fade(frame, 18 + index * 8, 48 + index * 8),
          }}
        />
      ))}
    </div>
  );
};

const TopBar: React.FC<{frame: number}> = ({frame}) => {
  const show = fade(frame, 0, 14);
  const chips = ['5 小时额度', '7 天额度', '桌面 Widget', '安全刷新'];
  return (
    <div
      style={{
        position: 'absolute',
        left: 34,
        right: 34,
        top: 26,
        height: 58,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        opacity: show,
        transform: `translateY(${interpolate(show, [0, 1], [-12, 0])}px)`,
      }}
    >
      <div>
        <div style={{fontSize: 32, lineHeight: 1, fontWeight: 950, letterSpacing: 0}}>
          ReadyCheck
        </div>
        <div style={{marginTop: 8, fontSize: 14, color: 'rgba(247,250,255,0.70)', fontWeight: 750}}>
          Codex 配额状态实时可见
        </div>
      </div>
      <div style={{display: 'flex', alignItems: 'center', gap: 8}}>
        {chips.map((label, index) => {
          const show = fade(frame, 34 + index * 10, 58 + index * 10);
          return (
            <div
              key={label}
              style={{
                padding: '7px 10px',
                borderRadius: 999,
                background: 'rgba(255,255,255,0.10)',
                border: '1px solid rgba(255,255,255,0.14)',
                color: 'rgba(247,250,255,0.82)',
                fontSize: 12,
                fontWeight: 850,
                opacity: show,
                transform: `translateY(${interpolate(show, [0, 1], [-14, 0])}px)`,
              }}
            >
              {label}
            </div>
          );
        })}
      </div>
    </div>
  );
};
