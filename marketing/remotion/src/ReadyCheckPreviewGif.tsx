import React from 'react';
import {AbsoluteFill, Img, interpolate, staticFile, useCurrentFrame} from 'remotion';

export const ReadyCheckPreviewGif: React.FC = () => {
  const frame = useCurrentFrame();
  const mainDrift = Math.sin(frame / 38) * 2;
  const widgetFloat = Math.sin(frame / 23) * 5;
  const menuFloat = Math.sin(frame / 25) * 6;
  const fillPulse = interpolate(Math.sin(frame / 24), [-1, 1], [0.74, 1]);
  const spinner = frame * 6;

  return (
    <AbsoluteFill
      style={{
        background:
          'radial-gradient(circle at 18% 18%, rgba(10,132,255,0.24), transparent 32%), radial-gradient(circle at 82% 82%, rgba(53,229,153,0.16), transparent 32%), linear-gradient(135deg, #07101E 0%, #07101B 52%, #050A12 100%)',
        color: '#F7FAFF',
        fontFamily: '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif',
        overflow: 'hidden',
      }}
    >
      <div
        style={{
          position: 'absolute',
          inset: 6,
          borderRadius: 16,
          border: '1px solid rgba(120,190,255,0.22)',
          background:
            'linear-gradient(120deg, rgba(72,208,245,0.13), transparent 38%), linear-gradient(320deg, rgba(53,229,153,0.12), transparent 42%)',
          boxShadow: 'inset 0 0 0 1px rgba(255,255,255,0.04), 0 24px 80px rgba(0,0,0,0.48)',
        }}
      />

      <div
        style={{
          position: 'absolute',
          left: 22,
          top: 18 + mainDrift,
          width: 756,
          borderRadius: 14,
          overflow: 'hidden',
          border: '1px solid rgba(255,255,255,0.10)',
          background: '#050914',
          boxShadow: '0 22px 70px rgba(0,0,0,0.38)',
        }}
      >
        <Img
          src={staticFile('images/readycheck-main-cropped.jpg')}
          style={{
            display: 'block',
            width: '100%',
            height: 245,
            objectFit: 'cover',
            objectPosition: '50% 0%',
            filter: 'contrast(1.05) saturate(0.95) brightness(0.88)',
          }}
        />
      </div>

      <MenuCard
        x={22}
        y={286 + menuFloat}
        width={405}
        fillPulse={fillPulse}
        spinner={spinner}
      />

      <div
        style={{
          position: 'absolute',
          left: 444,
          top: 286 + widgetFloat,
          width: 334,
          height: 142,
          borderRadius: 13,
          overflow: 'hidden',
          padding: 5,
          border: '1px solid rgba(255,255,255,0.14)',
          background: '#09101F',
          boxShadow: '0 18px 54px rgba(0,0,0,0.34)',
        }}
      >
        <Img
          src={staticFile('images/readycheck-widget-real.jpg')}
          style={{
            display: 'block',
            width: '100%',
            height: '100%',
            borderRadius: 9,
            objectFit: 'cover',
            objectPosition: '50% 23%',
          }}
        />
      </div>
    </AbsoluteFill>
  );
};

const MenuCard: React.FC<{
  x: number;
  y: number;
  width: number;
  fillPulse: number;
  spinner: number;
}> = ({x, y, width, fillPulse, spinner}) => (
  <div
    style={{
      position: 'absolute',
      left: x,
      top: y,
      width,
      height: 142,
      borderRadius: 14,
      padding: 14,
      border: '1px solid rgba(255,255,255,0.14)',
      background: 'rgba(17,24,39,0.92)',
      boxShadow: '0 24px 70px rgba(0,0,0,0.48)',
    }}
  >
    <div style={{display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12}}>
      <div>
        <div style={{fontSize: 19, lineHeight: 1, fontWeight: 950}}>菜单栏速览</div>
        <div style={{marginTop: 7, fontSize: 14, fontWeight: 850, color: 'rgba(247,250,255,0.58)'}}>
          ReadyCheck
        </div>
      </div>
      <div
        style={{
          width: 40,
          height: 40,
          borderRadius: 11,
          display: 'grid',
          placeItems: 'center',
          background: 'linear-gradient(135deg, #48D0F5, #35E599)',
        }}
      >
        <div
          style={{
            width: 20,
            height: 20,
            borderRadius: 999,
            border: '4px solid rgba(255,255,255,0.95)',
            borderTopColor: 'rgba(255,255,255,0.42)',
            transform: `rotate(${spinner}deg)`,
          }}
        />
      </div>
    </div>

    <div style={{marginTop: 10, display: 'grid', gap: 6}}>
      <Metric label="5 小时窗口" value="88%" color="#48D0F5" width={0.82 * fillPulse} />
      <Metric label="7 天窗口" value="78%" color="#35E599" width={0.74 * fillPulse} />
    </div>

    <div
      style={{
        marginTop: 6,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        fontSize: 10,
        lineHeight: 1,
        fontWeight: 900,
        color: 'rgba(247,250,255,0.60)',
      }}
    >
      <span>自动刷新</span>
      <span style={{color: '#35E599'}}>不消耗模型额度</span>
    </div>
  </div>
);

const Metric: React.FC<{label: string; value: string; color: string; width: number}> = ({
  label,
  value,
  color,
  width,
}) => (
  <div>
    <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
      <span style={{fontSize: 13, fontWeight: 900, color: 'rgba(247,250,255,0.82)'}}>{label}</span>
      <span style={{fontSize: 13, fontWeight: 950}}>{value}</span>
    </div>
    <div style={{marginTop: 5, height: 7, overflow: 'hidden', borderRadius: 99, background: 'rgba(255,255,255,0.12)'}}>
      <div
        style={{
          width: `${Math.min(Math.max(width, 0), 1) * 100}%`,
          height: '100%',
          borderRadius: 99,
          background: color,
          boxShadow: `0 0 20px ${color}66`,
        }}
      />
    </div>
  </div>
);
