import {Composition, Folder, Still} from 'remotion';
import {ReadyCheckIntro, type ReadyCheckIntroProps} from './ReadyCheckIntro';
import {ReadyCheckPreviewGif} from './ReadyCheckPreviewGif';

import {ReadyCheckXhs, xhsDuration} from './xhs/ReadyCheckXhs';
import {ReadyCheckXhsCover} from './xhs/Scenes';
import {Oct07Video} from './xhs-oct07/Video';
import {Hook} from './xhs-oct07/Hook';
import {Rings} from './xhs-oct07/Rings';
import {Details} from './xhs-oct07/Details';
import {Download, Oct07Cover} from './xhs-oct07/Download';

const defaultProps = {
  locale: 'zh',
} satisfies ReadyCheckIntroProps;

export const RemotionRoot = () => {
  return (
    <Folder name="ReadyCheck">
      <Composition id="ReadyCheckOct07" component={Oct07Video} durationInFrames={840} fps={30} width={1080} height={1920}/>
      <Still id="ReadyCheckOct07Cover" component={Oct07Cover} width={1080} height={1440}/>
      <Folder name="Oct07-Scenes">
        <Composition id="Oct07Hook" component={Hook} durationInFrames={180} fps={30} width={1080} height={1920}/>
        <Composition id="Oct07Rings" component={Rings} durationInFrames={210} fps={30} width={1080} height={1920}/>
        <Composition id="Oct07Details" component={Details} durationInFrames={240} fps={30} width={1080} height={1920}/>
        <Composition id="Oct07Download" component={Download} durationInFrames={210} fps={30} width={1080} height={1920}/>
      </Folder>
      <Composition id="ReadyCheckXhsCN" component={ReadyCheckXhs} durationInFrames={xhsDuration} fps={30} width={1080} height={1920}/>
      <Still id="ReadyCheckXhsCover" component={ReadyCheckXhsCover} width={1080} height={1440}/>
      <Composition
        id="ReadyCheckIntroCN"
        component={ReadyCheckIntro}
        durationInFrames={900}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={defaultProps}
      />
      <Composition
        id="ReadyCheckIntroEN"
        component={ReadyCheckIntro}
        durationInFrames={900}
        fps={30}
        width={1920}
        height={1080}
        defaultProps={{locale: 'en'} satisfies ReadyCheckIntroProps}
      />
      <Composition
        id="ReadyCheckPreviewGif"
        component={ReadyCheckPreviewGif}
        durationInFrames={180}
        fps={30}
        width={800}
        height={450}
      />
    </Folder>
  );
};
