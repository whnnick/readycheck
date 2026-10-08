import {Audio} from '@remotion/media';
import {AbsoluteFill, Sequence, interpolate, staticFile, useCurrentFrame} from 'remotion';
import {Hook} from './Hook';
import {Rings} from './Rings';
import {Details} from './Details';
import {Download} from './Download';
import captions from '../../public/audio/xhs-oct07/captions.json';
import {font} from './Shared';

export const Oct07Video = () => {
  const frame = useCurrentFrame();
  const active = captions.find(c => frame * 1000 / 30 >= c.startMs && frame * 1000 / 30 < c.endMs);
  const musicGain = Math.min(...captions.map(c => interpolate(frame, [c.startMs*30/1000-9, c.startMs*30/1000+6, c.endMs*30/1000-6, c.endMs*30/1000+9], [0.42, 0.25, 0.25, 0.42], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})));
  return <AbsoluteFill style={{background: '#f2f1ec'}}>
    <Audio src={staticFile('audio/readycheck-tech-pulse.wav')} volume={interpolate(frame, [0, 18, 810, 840], [0, 1, 1, 0], {extrapolateRight: 'clamp'}) * musicGain}/>
    <Sequence name="不用切窗口" from={0} durationInFrames={180}><Hook/></Sequence>
    <Sequence name="双圆环" from={180} durationInFrames={210}><Rings/></Sequence>
    <Sequence name="展开与气泡" from={390} durationInFrames={240}><Details/></Sequence>
    <Sequence name="下载入口" from={630} durationInFrames={210}><Download/></Sequence>
    <Sequence from={12} durationInFrames={168}><Audio src={staticFile('audio/xhs-oct07/voice-0.mp3')}/></Sequence>
    <Sequence from={192} durationInFrames={198}><Audio src={staticFile('audio/xhs-oct07/voice-1.mp3')}/></Sequence>
    <Sequence from={402} durationInFrames={228}><Audio src={staticFile('audio/xhs-oct07/voice-2.mp3')}/></Sequence>
    <Sequence from={642} durationInFrames={198}><Audio src={staticFile('audio/xhs-oct07/voice-3.mp3')}/></Sequence>
    {active && <div style={{position: 'absolute', left: 92, top: 1530, width: 852, padding: '20px 24px', background: '#e3e5e7', borderRadius: 24, color: '#17202b', fontFamily: font, fontSize: 44, lineHeight: 1.5, textAlign: 'center'}}>{active.text}</div>}
  </AbsoluteFill>;
};
