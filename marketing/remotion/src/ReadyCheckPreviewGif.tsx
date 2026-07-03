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
  const menuFocus = fade(frame, 50, 98);
  const widgetFocus = fade(frame, 78, 126);
  const loopFade = fadeOut(frame, 168, 180);
  const sweepX = interpolate(frame, [0, 180], [-220, 1010], clamp);

  const mainScale = interpolate(productFocus, [0, 1], [0.27, 0.30]);
  const mainX = interpolate(productFocus, [0, 1], [62, 48]);
  const mainY = interpolate(productFocus, [0, 1], [92, 82]);
  const menuX = interpolate(menuFocus, [0, 1], [536, 498]);
  const menuY = interpolate(menuFocus, [0, 1], [104, 88]);
  const widgetScale = interpolate(widgetFocus, [0, 1], [0.25, 0.29]);
  const widgetX = interpolate(widgetFocus, [0, 1], [534, 496]);
  const widgetY = interpolate(widgetFocus, [0, 1], [278, 252]);

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
          transform: `scale(${mainScale}) rotate(${interpolate(productFocus, [0, 1], [-1.0, -0.25])}deg)`,
          transformOrigin: 'top left',
          opacity: intro * loopFade,
        }}
      >
        <Img
          src={staticFile('images/readycheck-main-real.png')}
          style={{width: '100%', height: '100%', objectFit: 'cover'}}
        />
      </div>

      <MenuPanel frame={frame} x={menuX} y={menuY} progress={menuFocus} loopFade={loopFade} />

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
          transform: `scale(${widgetScale}) rotate(${interpolate(widgetFocus, [0, 1], [2.2, 0.35])}deg)`,
          transformOrigin: 'top left',
          opacity: interpolate(frame, [58, 86], [0.72, 1], clamp) * loopFade,
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

const MenuPanel: React.FC<{
  frame: number;
  x: number;
  y: number;
  progress: number;
  loopFade: number;
}> = ({frame, x, y, progress, loopFade}) => {
  const rows = [
    {label: '5 小时', value: '88%', color: '#44D36B', width: 0.88},
    {label: '7 天', value: '78%', color: '#44D36B', width: 0.78},
  ];
  const show = interpolate(frame, [42, 70], [0, 1], clamp);

  return (
    <div
      style={{
        position: 'absolute',
        left: x,
        top: y,
        width: 238,
        padding: 12,
        borderRadius: 24,
        color: '#F7FAFF',
        background:
          'linear-gradient(145deg, rgba(28,32,38,0.94), rgba(16,18,22,0.90))',
        border: '1px solid rgba(255,255,255,0.16)',
        boxShadow: '0 30px 90px rgba(0,0,0,0.58), 0 0 70px rgba(10,132,255,0.22)',
        opacity: show * loopFade,
        transform: `translateY(${interpolate(progress, [0, 1], [-18, 0])}px) rotate(${interpolate(progress, [0, 1], [1.6, 0.25])}deg)`,
      }}
    >
      <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
        <div>
          <div style={{fontSize: 15, fontWeight: 950}}>菜单栏速览</div>
          <div style={{marginTop: 2, fontSize: 10, color: 'rgba(247,250,255,0.58)', fontWeight: 750}}>
            ReadyCheck
          </div>
        </div>
        <div
          style={{
            width: 30,
            height: 30,
            borderRadius: 12,
            display: 'grid',
            placeItems: 'center',
            background: 'linear-gradient(135deg, #0A84FF, #44D36B)',
            boxShadow: '0 0 30px rgba(10,132,255,0.38)',
          }}
        >
          <div
            style={{
              width: 13,
              height: 13,
              borderRadius: 99,
              border: '3px solid white',
              borderTopColor: 'rgba(255,255,255,0.45)',
              transform: `rotate(${frame * 3}deg)`,
            }}
          />
        </div>
      </div>

      <div style={{marginTop: 10, display: 'grid', gap: 8}}>
        {rows.map((row, index) => (
          <div key={row.label}>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'space-between',
                fontSize: 11,
                fontWeight: 850,
              }}
            >
              <span>{row.label}</span>
              <span>{row.value}</span>
            </div>
            <div
              style={{
                marginTop: 5,
                height: 6,
                borderRadius: 99,
                overflow: 'hidden',
                background: 'rgba(255,255,255,0.15)',
              }}
            >
              <div
                style={{
                  width: `${row.width * interpolate(frame, [60 + index * 8, 100 + index * 8], [0.2, 1], clamp) * 100}%`,
                  height: '100%',
                  borderRadius: 99,
                  background: row.color,
                  boxShadow: `0 0 18px ${row.color}88`,
                }}
              />
            </div>
          </div>
        ))}
      </div>

      <div
        style={{
          marginTop: 10,
          display: 'flex',
          gap: 8,
          alignItems: 'center',
          justifyContent: 'space-between',
          fontSize: 10,
          color: 'rgba(247,250,255,0.68)',
          fontWeight: 800,
        }}
      >
        <span>自动刷新</span>
        <span style={{color: '#44D36B'}}>不消耗模型额度</span>
      </div>
    </div>
  );
};

const TopBar: React.FC<{frame: number}> = ({frame}) => {
  const show = fade(frame, 0, 14);
  const chips = ['主窗口', '菜单栏', '桌面 Widget', '安全刷新'];
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
