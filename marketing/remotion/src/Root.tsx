import {Composition, Folder} from 'remotion';
import {ReadyCheckIntro, type ReadyCheckIntroProps} from './ReadyCheckIntro';

const defaultProps = {
  locale: 'zh',
} satisfies ReadyCheckIntroProps;

export const RemotionRoot = () => {
  return (
    <Folder name="ReadyCheck">
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
    </Folder>
  );
};
