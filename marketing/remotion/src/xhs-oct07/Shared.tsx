import React from 'react';
import {AbsoluteFill, Easing, Img, interpolate, staticFile, useCurrentFrame} from 'remotion';

export const font = 'PingFang SC, sans-serif';
export const Native = ({name, style}: {name: string; style: React.CSSProperties}) => <Img src={staticFile(`images/xhs-0130/${name}.png`)} style={{objectFit: 'contain', ...style}}/>;
export const Page = ({children}: {children: React.ReactNode}) => <AbsoluteFill style={{background: '#f2f1ec', color: '#17202b', fontFamily: font}}>
  <div style={{position: 'absolute', left: 92, top: 150, display: 'flex', gap: 18, alignItems: 'center', fontSize: 34, fontWeight: 600}}><Native name="app-icon" style={{width: 60, height: 60}}/>ReadyCheck<span style={{fontSize: 28, color: '#687482', marginLeft: 22}}>Mac 开源工具</span></div>
  {children}
  <div style={{position: 'absolute', left: 92, top: 1460, fontSize: 28, color: '#65707b'}}>0.1.130 界面演示 · 配额为演示数据</div>
</AbsoluteFill>;
export const Heading = ({children, sub}: {children: React.ReactNode; sub: string}) => <div style={{position: 'absolute', top: 316, left: 92, width: 864}}><div style={{fontSize: 98, lineHeight: 1.15, letterSpacing: -3, fontWeight: 700}}>{children}</div><div style={{fontSize: 44, marginTop: 30, color: '#65707b', lineHeight: 1.5}}>{sub}</div></div>;
export const Rise = ({children, style}: {children: React.ReactNode; style: React.CSSProperties}) => {
  const frame = useCurrentFrame();
  return <div style={{...style, opacity: interpolate(frame, [0, 18], [0, 1], {extrapolateRight: 'clamp'}), translate: `${interpolate(frame, [0, 24], [34, 0], {extrapolateRight: 'clamp', easing: Easing.out(Easing.cubic)})}px 0px`}}>{children}</div>;
};
