import {AbsoluteFill, Audio, Sequence, interpolate, staticFile, useCurrentFrame} from 'remotion';
import script from '../../public/audio/xhs-0130/script.json';
import {PainScene, GlanceScene, EdgeScene, DetailScene, ReminderScene, DownloadScene, font} from './Scenes';

export const shots = [
  {component:PainScene, frames:120},
  {component:GlanceScene, frames:138},
  {component:EdgeScene, frames:156},
  {component:DetailScene, frames:126},
  {component:ReminderScene, frames:144},
  {component:DownloadScene, frames:186},
];
export const xhsDuration = shots.reduce((sum,s)=>sum+s.frames,0);
const Caption = ({text}:{text:string}) => <div style={{position:'absolute',top:1540,left:96,width:852,padding:'20px 24px',borderRadius:24,background:'rgba(0,0,0,0.45)',fontFamily:font,fontSize:44,lineHeight:1.5,color:'white',textAlign:'center'}}>{text}</div>;
export const ReadyCheckXhs = () => {
  const frame=useCurrentFrame();
  let start=0;
  return <AbsoluteFill style={{background:'#080d15'}}>
    <Audio src={staticFile('audio/readycheck-tech-pulse.wav')} volume={()=>0.065*interpolate(frame,[0,24,xhsDuration-35,xhsDuration],[0,1,1,0],{extrapolateLeft:'clamp',extrapolateRight:'clamp'})}/>
    {shots.map(({component:Scene,frames},i)=>{const from=start;start+=frames;return <Sequence key={i} from={from} durationInFrames={frames}><Scene/><Sequence from={6} durationInFrames={frames-6}><Audio src={staticFile(`audio/xhs-0130/voice-${i}.mp3`)}/><Caption text={script[i]}/></Sequence></Sequence>})}
  </AbsoluteFill>;
};
