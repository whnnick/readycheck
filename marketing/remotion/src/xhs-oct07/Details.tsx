import {interpolate, useCurrentFrame} from 'remotion';
import {Heading, Native, Page} from './Shared';

export const Details = () => {
  const frame = useCurrentFrame();
  const swap = interpolate(frame, [120, 138], [0, 1], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'});
  return <Page><Heading sub="剩余额度、重置时间，点开就有。">点一下，<br/>详情展开</Heading><div style={{position: 'absolute', left: 92, top: 720, width: 850, height: 680, borderRadius: 48, background: '#19212c'}}><Native name="detail" style={{position: 'absolute', left: 20, top: 65, width: 810, height: 540, opacity: 1-swap, scale: interpolate(frame, [0, 24], [0.92, 1], {extrapolateRight: 'clamp'})}}/><div style={{position: 'absolute', inset: 0, opacity: swap}}><Native name="bubble" style={{position: 'absolute', top: 64, left: 70, width: 180, height: 180}}/><div style={{position: 'absolute', left: 285, top: 100, fontSize: 48, color: '#a5d7ff', fontWeight: 600}}>也能换成<br/>桌面圆形气泡</div><Native name="bubble-detail" style={{position: 'absolute', left: 115, top: 285, width: 620, height: 350}}/></div></div></Page>;
};
