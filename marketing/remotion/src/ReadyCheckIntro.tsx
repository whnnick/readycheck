import React from 'react';
import {Audio} from '@remotion/media';
import {
  AbsoluteFill,
  Easing,
  interpolate,
  spring,
  staticFile,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';

export type ReadyCheckIntroProps = {
  locale: 'zh' | 'en';
};

type Copy = {
  eyebrow: string;
  headline: string;
  subline: string;
  painTitle: string;
  painItems: string[];
  featureTitle: string;
  featureItems: string[];
  securityTitle: string;
  securityBody: string;
  widgetTitle: string;
  widgetBody: string;
  cta: string;
  refresh: string;
  connected: string;
  fiveHour: string;
  sevenDay: string;
  criticalState: string;
  remaining: string;
  noToken: string;
  github: string;
  githubLabel: string;
};

const copy: Record<ReadyCheckIntroProps['locale'], Copy> = {
  zh: {
    eyebrow: 'macOS 菜单栏 + 桌面 Widget',
    headline: '随时知道 Codex 额度还剩多少',
    subline: 'ReadyCheck 安全读取授权后的用量数据，不通过模型调用探测额度。',
    painTitle: '别等额度用尽才发现',
    painItems: ['5 小时窗口', '7 天窗口', '手动 / 自动刷新', '菜单栏快速查看'],
    featureTitle: '一个轻量窗口，三处可见',
    featureItems: ['主窗口', '菜单栏', '桌面 Widget'],
    securityTitle: '刷新不消耗模型 Token',
    securityBody: 'OAuth 凭据保存在系统 Keychain；刷新只读取用量端点。',
    widgetTitle: '常驻桌面，不打断工作流',
    widgetBody: '透明玻璃卡片显示关键额度，低额度状态会自动变色提醒。',
    cta: 'ReadyCheck · Codex 配额状态一眼可见',
    refresh: '自动刷新',
    connected: '已连接',
    fiveHour: '5 小时配额',
    sevenDay: '7 天配额',
    criticalState: '紧张状态',
    remaining: '剩余',
    noToken: '不消耗模型额度',
    githubLabel: '开源地址',
    github: 'github.com/whnnick/readycheck',
  },
  en: {
    eyebrow: 'macOS menu bar + desktop widget',
    headline: 'Know your Codex quota before it runs out',
    subline: 'ReadyCheck reads authorized usage data without probing quotas through model calls.',
    painTitle: 'Stop discovering limits too late',
    painItems: ['5-hour window', '7-day window', 'Manual / auto refresh', 'Menu bar glance'],
    featureTitle: 'One lightweight monitor, three surfaces',
    featureItems: ['Main window', 'Menu bar', 'Desktop widget'],
    securityTitle: 'Refresh without spending model tokens',
    securityBody: 'OAuth credentials stay in Keychain; refresh only reads the usage endpoint.',
    widgetTitle: 'Always visible, never in the way',
    widgetBody: 'A liquid-glass card shows the essential quota state and changes color when usage gets tight.',
    cta: 'ReadyCheck · Codex quota at a glance',
    refresh: 'Auto refresh',
    connected: 'Connected',
    fiveHour: '5-hour quota',
    sevenDay: '7-day quota',
    criticalState: 'Critical state',
    remaining: 'left',
    noToken: 'No model quota spent',
    githubLabel: 'Open source',
    github: 'github.com/whnnick/readycheck',
  },
};

const colors = {
  blue: '#0A84FF',
  green: '#44D36B',
  orange: '#FFB340',
  red: '#FF5C5C',
  white: '#F8FAFF',
  muted: 'rgba(248, 250, 255, 0.68)',
  panel: 'rgba(22, 26, 32, 0.68)',
  panelStrong: 'rgba(20, 23, 29, 0.86)',
  border: 'rgba(255, 255, 255, 0.18)',
};

const ease = Easing.bezier(0.16, 1, 0.3, 1);

const clamp = {
  extrapolateLeft: 'clamp' as const,
  extrapolateRight: 'clamp' as const,
};

const fade = (frame: number, start: number, end: number) =>
  interpolate(frame, [start, end], [0, 1], {...clamp, easing: ease});

const fadeOut = (frame: number, start: number, end: number) =>
  interpolate(frame, [start, end], [1, 0], {...clamp, easing: Easing.in(Easing.cubic)});

const sceneOpacity = (frame: number, start: number, end: number) =>
  fade(frame, start, start + 24) * fadeOut(frame, end - 24, end);

const px = (value: number) => `${value}px`;

export const ReadyCheckIntro: React.FC<ReadyCheckIntroProps> = ({locale}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = copy[locale];

  return (
    <AbsoluteFill
      style={{
        background:
          'radial-gradient(circle at 20% 16%, rgba(10, 132, 255, 0.44), transparent 27%), radial-gradient(circle at 82% 18%, rgba(68, 211, 107, 0.24), transparent 28%), linear-gradient(135deg, #090B10 0%, #111927 52%, #07080B 100%)',
        color: colors.white,
        fontFamily:
          '-apple-system, BlinkMacSystemFont, "SF Pro Display", "Segoe UI", sans-serif',
        overflow: 'hidden',
      }}
    >
      <Audio
        src={staticFile('audio/readycheck-tech-pulse.wav')}
        volume={(audioFrame) =>
          interpolate(audioFrame, [0, 45, 825, 900], [0, 0.55, 0.55, 0], clamp)
        }
      />
      <ImpactBackground frame={frame} />
      <Aurora />
      <Grid />
      <GithubRibbon frame={frame} text={t} />
      <SceneIntro frame={frame} text={t} />
      <SceneProblem frame={frame} text={t} />
      <SceneProduct frame={frame} text={t} />
      <SceneSecurity frame={frame} text={t} />
      <SceneWidget frame={frame} text={t} />
      <SceneOutro frame={frame} fps={fps} text={t} />
    </AbsoluteFill>
  );
};

const Aurora: React.FC = () => {
  const frame = useCurrentFrame();
  const drift = Math.sin(frame / 54) * 34;
  const pulse = interpolate(Math.sin(frame / 42), [-1, 1], [0.42, 0.78]);

  return (
    <>
      <div
        style={{
          position: 'absolute',
          width: 720,
          height: 720,
          left: 1120 + drift,
          top: -180,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(10,132,255,0.48), transparent 64%)',
          filter: 'blur(22px)',
          opacity: pulse,
        }}
      />
      <div
        style={{
          position: 'absolute',
          width: 780,
          height: 780,
          left: -170 - drift * 0.4,
          top: 520,
          borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(68,211,107,0.28), transparent 66%)',
          filter: 'blur(28px)',
          opacity: 0.7,
        }}
      />
    </>
  );
};

const ImpactBackground: React.FC<{frame: number}> = ({frame}) => {
  const beat = Math.max(0, Math.sin((frame / 30) * Math.PI * 4));
  const pulse = interpolate(beat, [0, 1], [0.08, 0.28]);
  const scanX = (frame * 9) % 2220 - 260;

  return (
    <>
      <div
        style={{
          position: 'absolute',
          inset: 0,
          width: 360,
          background:
            'linear-gradient(110deg, transparent 0%, rgba(10,132,255,0.12) 42%, rgba(255,255,255,0.20) 50%, rgba(255,92,92,0.10) 58%, transparent 100%)',
          filter: 'blur(1px)',
          opacity: 0.44,
          transform: `translateX(${px(scanX)}) skewX(-18deg)`,
        }}
      />
      <div
        style={{
          position: 'absolute',
          left: 1150,
          top: 120,
          width: 620,
          height: 620,
          borderRadius: '50%',
          border: `2px solid rgba(10,132,255,${pulse})`,
          boxShadow: `0 0 90px rgba(10,132,255,${pulse})`,
          transform: `scale(${interpolate(beat, [0, 1], [0.98, 1.04])})`,
        }}
      />
    </>
  );
};

const Grid: React.FC = () => {
  const frame = useCurrentFrame();
  const y = frame % 80;

  return (
    <div
      style={{
        position: 'absolute',
        inset: 0,
        opacity: 0.18,
        backgroundImage:
          'linear-gradient(rgba(255,255,255,0.08) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.08) 1px, transparent 1px)',
        backgroundSize: '80px 80px',
        backgroundPosition: `0 ${px(y)}`,
        maskImage: 'linear-gradient(to bottom, transparent, black 22%, black 70%, transparent)',
      }}
    />
  );
};

const GithubRibbon: React.FC<{frame: number; text: Copy}> = ({frame, text}) => {
  const appear = fade(frame, 70, 110) * fadeOut(frame, 790, 840);

  return (
    <div
      style={{
        position: 'absolute',
        right: 72,
        top: 58,
        zIndex: 20,
        display: 'flex',
        alignItems: 'center',
        gap: 14,
        padding: '18px 26px',
        borderRadius: 999,
        background: 'linear-gradient(135deg, rgba(10,132,255,0.34), rgba(2,8,20,0.82))',
        border: '1px solid rgba(82,168,255,0.55)',
        boxShadow: '0 0 70px rgba(10,132,255,0.34)',
        opacity: appear,
        transform: `translateY(${px(interpolate(appear, [0, 1], [-24, 0]))})`,
      }}
    >
      <div style={{fontSize: 22, color: colors.green, fontWeight: 950}}>GitHub</div>
      <div style={{fontSize: 26, fontWeight: 950, color: colors.white}}>{text.github}</div>
    </div>
  );
};

const SceneIntro: React.FC<{frame: number; text: Copy}> = ({frame, text}) => {
  const opacity = sceneOpacity(frame, 0, 165);
  const enter = spring({frame, fps: 30, config: {damping: 18, stiffness: 120}});
  const logoScale = interpolate(enter, [0, 1], [0.72, 1]);
  const titleY = interpolate(fade(frame, 18, 56), [0, 1], [44, 0]);

  return (
    <AbsoluteFill style={{opacity}}>
      <div style={{position: 'absolute', left: 156, top: 118, display: 'flex', gap: 18, alignItems: 'center'}}>
        <Logo scale={logoScale} />
        <div>
          <div style={{fontSize: 28, color: colors.muted, letterSpacing: 0}}>{text.eyebrow}</div>
          <div style={{fontSize: 40, fontWeight: 800}}>ReadyCheck</div>
        </div>
      </div>
      <div style={{position: 'absolute', left: 156, top: 318, width: 1030, transform: `translateY(${px(titleY)})`}}>
        <div style={{fontSize: 86, lineHeight: 1.05, fontWeight: 900, letterSpacing: 0}}>
          {text.headline}
        </div>
        <div style={{marginTop: 28, width: 900, fontSize: 32, lineHeight: 1.45, color: colors.muted}}>
          {text.subline}
        </div>
      </div>
      <HeroDevice frame={frame} left={1178} top={218} scale={0.92} />
    </AbsoluteFill>
  );
};

const SceneProblem: React.FC<{frame: number; text: Copy}> = ({frame, text}) => {
  const opacity = sceneOpacity(frame, 150, 330);
  const local = frame - 150;

  return (
    <AbsoluteFill style={{opacity}}>
      <Panel left={140} top={170} width={760} height={650}>
        <div style={{fontSize: 62, lineHeight: 1.08, fontWeight: 900}}>{text.painTitle}</div>
        <div style={{marginTop: 46, display: 'grid', gap: 18}}>
          {text.painItems.map((item, index) => {
            const itemIn = fade(local, 20 + index * 13, 48 + index * 13);
            return (
              <div
                key={item}
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  gap: 18,
                  opacity: itemIn,
                  transform: `translateX(${px(interpolate(itemIn, [0, 1], [-38, 0]))})`,
                }}
              >
                <div style={{width: 16, height: 16, borderRadius: 99, background: index === 0 ? colors.orange : colors.blue}} />
                <div style={{fontSize: 34, fontWeight: 750}}>{item}</div>
              </div>
            );
          })}
        </div>
      </Panel>
      <FloatingQuota frame={local} left={1030} top={210} text={text} />
      <MeterAlert frame={local} left={1120} top={730} />
    </AbsoluteFill>
  );
};

const SceneProduct: React.FC<{frame: number; text: Copy}> = ({frame, text}) => {
  const opacity = sceneOpacity(frame, 315, 520);
  const local = frame - 315;

  return (
    <AbsoluteFill style={{opacity}}>
      <div style={{position: 'absolute', left: 132, top: 120}}>
        <div style={{fontSize: 30, color: colors.green, fontWeight: 800}}>{text.noToken}</div>
        <div style={{marginTop: 18, fontSize: 68, fontWeight: 900}}>{text.featureTitle}</div>
      </div>
      <HeroDevice frame={local} left={240} top={290} scale={1.04} />
      <SurfaceLabels frame={local} text={text} />
    </AbsoluteFill>
  );
};

const SceneSecurity: React.FC<{frame: number; text: Copy}> = ({frame, text}) => {
  const opacity = sceneOpacity(frame, 500, 675);
  const local = frame - 500;
  const lineProgress = fade(local, 38, 122);

  return (
    <AbsoluteFill style={{opacity}}>
      <div style={{position: 'absolute', left: 150, top: 210, width: 780}}>
        <div style={{fontSize: 72, lineHeight: 1.08, fontWeight: 900}}>{text.securityTitle}</div>
        <div style={{marginTop: 28, fontSize: 32, lineHeight: 1.44, color: colors.muted}}>{text.securityBody}</div>
      </div>
      <div style={{position: 'absolute', left: 960, top: 190}}>
        <SecurityFlow progress={lineProgress} />
      </div>
    </AbsoluteFill>
  );
};

const SceneWidget: React.FC<{frame: number; text: Copy}> = ({frame, text}) => {
  const opacity = sceneOpacity(frame, 650, 815);
  const local = frame - 650;
  const widgetIn = fade(local, 20, 66);

  return (
    <AbsoluteFill style={{opacity}}>
      <div style={{position: 'absolute', left: 136, top: 145, width: 760}}>
        <div style={{fontSize: 72, lineHeight: 1.08, fontWeight: 900}}>{text.widgetTitle}</div>
        <div style={{marginTop: 28, fontSize: 32, lineHeight: 1.42, color: colors.muted}}>{text.widgetBody}</div>
      </div>
      <div
        style={{
          position: 'absolute',
          left: 1050,
          top: 210,
          transform: `translateY(${px(interpolate(widgetIn, [0, 1], [90, 0]))}) scale(${interpolate(widgetIn, [0, 1], [0.86, 1])})`,
          opacity: widgetIn,
        }}
      >
        <DesktopWidget text={text} />
      </div>
    </AbsoluteFill>
  );
};

const SceneOutro: React.FC<{frame: number; fps: number; text: Copy}> = ({frame, text}) => {
  const opacity = sceneOpacity(frame, 790, 900);
  const local = frame - 790;
  const titleIn = fade(local, 8, 44);

  return (
    <AbsoluteFill style={{opacity, justifyContent: 'center', alignItems: 'center'}}>
      <Logo scale={1.28} />
      <div
        style={{
          marginTop: 42,
          fontSize: 70,
          fontWeight: 900,
          opacity: titleIn,
          transform: `translateY(${px(interpolate(titleIn, [0, 1], [36, 0]))})`,
        }}
      >
        {text.cta}
      </div>
      <div style={{marginTop: 26, fontSize: 30, color: colors.green, fontWeight: 800}}>
        macOS · OAuth · Keychain · Desktop Widget
      </div>
      <div
        style={{
          marginTop: 26,
          padding: '24px 42px',
          borderRadius: 99,
          background: 'linear-gradient(135deg, rgba(10,132,255,0.42), rgba(10,132,255,0.12))',
          border: '1px solid rgba(82,168,255,0.72)',
          color: colors.white,
          boxShadow: '0 0 90px rgba(10,132,255,0.42)',
          fontSize: 42,
          fontWeight: 950,
        }}
      >
        {text.githubLabel} · {text.github}
      </div>
    </AbsoluteFill>
  );
};

const Logo: React.FC<{scale?: number}> = ({scale = 1}) => (
  <div
    style={{
      width: 96,
      height: 96,
      borderRadius: 30,
      background: 'linear-gradient(135deg, #0A84FF, #3AA2FF)',
      display: 'grid',
      placeItems: 'center',
      boxShadow: '0 24px 80px rgba(10,132,255,0.4)',
      transform: `scale(${scale})`,
    }}
  >
    <div style={{width: 54, height: 54, border: '5px solid rgba(255,255,255,0.92)', borderRadius: '50%', position: 'relative'}}>
      {[0, 1, 2, 3, 4].map((i) => (
        <div
          key={i}
          style={{
            position: 'absolute',
            width: 6,
            height: 6,
            borderRadius: 99,
            background: 'white',
            left: 22 + Math.cos(i * 1.2) * 16,
            top: 22 + Math.sin(i * 1.2) * 16,
          }}
        />
      ))}
      <div style={{position: 'absolute', left: 25, top: 9, width: 5, height: 24, borderRadius: 99, background: 'white', transformOrigin: '50% 100%', transform: 'rotate(42deg)'}} />
    </div>
  </div>
);

const Panel: React.FC<React.PropsWithChildren<{left: number; top: number; width: number; height: number}>> = ({
  left,
  top,
  width,
  height,
  children,
}) => (
  <div
    style={{
      position: 'absolute',
      left,
      top,
      width,
      height,
      borderRadius: 44,
      background: 'linear-gradient(145deg, rgba(255,255,255,0.13), rgba(255,255,255,0.04))',
      border: `1px solid ${colors.border}`,
      boxShadow: '0 42px 120px rgba(0,0,0,0.42), inset 0 1px 0 rgba(255,255,255,0.26)',
      padding: 56,
      backdropFilter: 'blur(28px)',
    }}
  >
    {children}
  </div>
);

const HeroDevice: React.FC<{frame: number; left: number; top: number; scale: number}> = ({frame, left, top, scale}) => {
  const float = Math.sin(frame / 38) * 12;
  const glow = interpolate(Math.sin(frame / 46), [-1, 1], [0.28, 0.56]);

  return (
    <div
      style={{
        position: 'absolute',
        left,
        top: top + float,
        width: 690,
        height: 520,
        borderRadius: 46,
        background: colors.panelStrong,
        border: '1px solid rgba(255,255,255,0.16)',
        boxShadow: `0 45px 120px rgba(0,0,0,0.48), 0 0 120px rgba(10,132,255,${glow})`,
        overflow: 'hidden',
        transform: `scale(${scale}) rotate(-2.5deg)`,
      }}
    >
      <div style={{height: 54, display: 'flex', alignItems: 'center', gap: 12, paddingLeft: 24, borderBottom: '1px solid rgba(255,255,255,0.1)'}}>
        <Dot color="#FF5F57" />
        <Dot color="#FFBD2E" />
        <Dot color="#28C840" />
        <div style={{marginLeft: 18, fontWeight: 800, color: colors.muted}}>ReadyCheck</div>
      </div>
      <div style={{padding: 32}}>
        <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
          <div style={{display: 'flex', gap: 18, alignItems: 'center'}}>
            <Logo scale={0.56} />
            <div>
              <div style={{fontSize: 30, fontWeight: 900}}>ReadyCheck</div>
              <div style={{fontSize: 17, color: colors.muted}}>Codex quota status</div>
            </div>
          </div>
          <Pill color={colors.green} label="Connected" />
        </div>
        <QuotaBars compact={false} />
      </div>
    </div>
  );
};

const Dot: React.FC<{color: string}> = ({color}) => (
  <div style={{width: 14, height: 14, borderRadius: 99, background: color}} />
);

const Pill: React.FC<{color: string; label: string}> = ({color, label}) => (
  <div
    style={{
      padding: '9px 16px',
      borderRadius: 99,
      color,
      background: `${color}24`,
      fontSize: 16,
      fontWeight: 900,
    }}
  >
    {label}
  </div>
);

const QuotaBars: React.FC<{compact: boolean; text?: Copy}> = ({compact, text}) => {
  const frame = useCurrentFrame();
  const p1 = interpolate(frame, [0, 120], [0.12, 0.78], {...clamp, easing: ease});
  const p2 = interpolate(frame, [16, 150], [0.12, 0.38], {...clamp, easing: ease});
  const p3 = interpolate(frame, [32, 168], [0.08, 0.12], {...clamp, easing: ease});

  return (
    <div style={{marginTop: compact ? 28 : 42, display: 'grid', gap: compact ? 24 : 34}}>
      <QuotaBar label={text?.fiveHour ?? '5-hour quota'} value={p1} percent="78%" color={colors.green} compact={compact} />
      <QuotaBar label={text?.sevenDay ?? '7-day quota'} value={p2} percent="38%" color={colors.orange} compact={compact} />
      <QuotaBar label={text?.criticalState ?? 'Critical state'} value={p3} percent="12%" color={colors.red} compact={compact} />
    </div>
  );
};

const QuotaBar: React.FC<{label: string; value: number; percent: string; color: string; compact: boolean}> = ({
  label,
  value,
  percent,
  color,
  compact,
}) => (
  <div>
    <div style={{display: 'flex', justifyContent: 'space-between', fontSize: compact ? 24 : 22, fontWeight: 850}}>
      <span>{label}</span>
      <span style={{color}}>{percent}</span>
    </div>
    <div style={{height: compact ? 14 : 12, marginTop: 14, borderRadius: 99, background: 'rgba(255,255,255,0.15)', overflow: 'hidden'}}>
      <div style={{height: '100%', width: `${value * 100}%`, borderRadius: 99, background: color, boxShadow: `0 0 32px ${color}80`}} />
    </div>
  </div>
);

const FloatingQuota: React.FC<{frame: number; left: number; top: number; text: Copy}> = ({frame, left, top, text}) => {
  const inProgress = fade(frame, 8, 44);

  return (
    <div
      style={{
        position: 'absolute',
        left,
        top,
        width: 620,
        height: 360,
        borderRadius: 40,
        padding: 34,
        background: colors.panel,
        border: `1px solid ${colors.border}`,
        boxShadow: '0 38px 120px rgba(0,0,0,0.48)',
        transform: `translateY(${px(interpolate(inProgress, [0, 1], [70, 0]))})`,
        opacity: inProgress,
      }}
    >
      <div style={{fontSize: 36, fontWeight: 900}}>Codex</div>
      <QuotaBars compact text={text} />
    </div>
  );
};

const MeterAlert: React.FC<{frame: number; left: number; top: number}> = ({frame, left, top}) => {
  const inProgress = fade(frame, 72, 112);

  return (
    <div
      style={{
        position: 'absolute',
        left,
        top,
        display: 'flex',
        alignItems: 'center',
        gap: 16,
        padding: '20px 26px',
        borderRadius: 99,
        background: 'rgba(255, 179, 64, 0.16)',
        color: colors.orange,
        border: '1px solid rgba(255,179,64,0.32)',
        fontSize: 26,
        fontWeight: 900,
        opacity: inProgress,
        transform: `scale(${interpolate(inProgress, [0, 1], [0.86, 1])})`,
      }}
    >
      <span>●</span>
      <span>Reset time visible before you start</span>
    </div>
  );
};

const SurfaceLabels: React.FC<{frame: number; text: Copy}> = ({frame, text}) => (
  <div style={{position: 'absolute', left: 1080, top: 320, display: 'grid', gap: 24}}>
    {text.featureItems.map((item, index) => {
      const enter = fade(frame, 32 + index * 18, 66 + index * 18);
      return (
        <div
          key={item}
          style={{
            width: 520,
            padding: '26px 30px',
            borderRadius: 30,
            background: 'rgba(255,255,255,0.1)',
            border: `1px solid ${colors.border}`,
            fontSize: 34,
            fontWeight: 850,
            opacity: enter,
            transform: `translateX(${px(interpolate(enter, [0, 1], [76, 0]))})`,
          }}
        >
          {item}
        </div>
      );
    })}
    <div
      style={{
        width: 520,
        padding: '20px 28px',
        borderRadius: 26,
        background: 'linear-gradient(135deg, rgba(10,132,255,0.42), rgba(10,132,255,0.14))',
        border: '1px solid rgba(82,168,255,0.62)',
        boxShadow: '0 0 70px rgba(10,132,255,0.28)',
        color: colors.white,
        fontSize: 30,
        fontWeight: 950,
        opacity: fade(frame, 92, 122),
        transform: `translateX(${px(interpolate(fade(frame, 92, 122), [0, 1], [76, 0]))})`,
      }}
    >
      {text.github}
    </div>
  </div>
);

const SecurityFlow: React.FC<{progress: number}> = ({progress}) => {
  const dashOffset = interpolate(progress, [0, 1], [520, 0]);

  return (
    <div style={{width: 780, height: 590, position: 'relative'}}>
      <svg width="780" height="590" style={{position: 'absolute', inset: 0, opacity: progress}}>
        <defs>
          <linearGradient id="usage-line" x1="0" x2="1" y1="0" y2="0">
            <stop offset="0%" stopColor={colors.blue} />
            <stop offset="100%" stopColor={colors.green} />
          </linearGradient>
          <linearGradient id="keychain-line" x1="0" x2="1" y1="0" y2="0">
            <stop offset="0%" stopColor={colors.blue} />
            <stop offset="100%" stopColor={colors.orange} />
          </linearGradient>
        </defs>
        <path d="M 240 292 C 340 220, 390 160, 520 160" fill="none" stroke="url(#usage-line)" strokeWidth="10" strokeLinecap="round" strokeDasharray="520" strokeDashoffset={dashOffset} />
        <path d="M 240 330 C 350 400, 420 430, 520 430" fill="none" stroke="url(#keychain-line)" strokeWidth="10" strokeLinecap="round" strokeDasharray="520" strokeDashoffset={dashOffset} />
      </svg>
      <FlowNode left={20} top={220} title="OAuth" color={colors.blue} />
      <FlowNode left={530} top={70} title="Usage API" color={colors.green} />
      <FlowNode left={530} top={340} title="Keychain" color={colors.orange} />
      <div style={{position: 'absolute', left: 292, top: 292, padding: '14px 24px', borderRadius: 99, background: 'rgba(68,211,107,0.18)', border: '1px solid rgba(68,211,107,0.36)', color: colors.green, fontSize: 26, fontWeight: 950, opacity: progress}}>
        no prompt
      </div>
    </div>
  );
};

const FlowNode: React.FC<{left: number; top: number; title: string; color: string}> = ({left, top, title, color}) => (
  <div
    style={{
      position: 'absolute',
      left,
      top,
      width: 180,
      height: 180,
      borderRadius: 48,
      display: 'grid',
      placeItems: 'center',
      textAlign: 'center',
      background: 'rgba(255,255,255,0.1)',
      border: `1px solid ${colors.border}`,
      boxShadow: `0 0 90px ${color}36`,
      color,
      fontSize: 32,
      fontWeight: 900,
    }}
  >
    {title}
  </div>
);

const DesktopWidget: React.FC<{text: Copy}> = ({text}) => (
  <div
    style={{
      width: 720,
      borderRadius: 50,
      padding: 34,
      background: 'linear-gradient(145deg, rgba(255,255,255,0.22), rgba(255,255,255,0.08))',
      border: `1px solid ${colors.border}`,
      boxShadow: '0 50px 150px rgba(0,0,0,0.52)',
      backdropFilter: 'blur(34px)',
    }}
  >
    <div style={{display: 'flex', alignItems: 'center', justifyContent: 'space-between'}}>
      <div>
        <div style={{fontSize: 36, fontWeight: 950}}>ReadyCheck</div>
        <div style={{marginTop: 6, fontSize: 22, color: colors.muted}}>Last refresh 16:36</div>
      </div>
      <Pill color={colors.green} label={text.refresh} />
    </div>
    <div style={{marginTop: 32, borderRadius: 34, padding: 30, background: 'rgba(0,0,0,0.24)', border: '1px solid rgba(255,255,255,0.12)'}}>
      <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'center'}}>
        <div style={{fontSize: 34, fontWeight: 950}}>Codex</div>
        <Pill color={colors.green} label={text.connected} />
      </div>
      <div style={{marginTop: 28}}>
        <QuotaBar label={text.fiveHour} value={0.78} percent={`78% ${text.remaining}`} color={colors.green} compact />
      </div>
      <div style={{marginTop: 28}}>
        <QuotaBar label={text.sevenDay} value={0.38} percent={`38% ${text.remaining}`} color={colors.orange} compact />
      </div>
      <div style={{marginTop: 28}}>
        <QuotaBar label={text.criticalState} value={0.12} percent={`12% ${text.remaining}`} color={colors.red} compact />
      </div>
    </div>
  </div>
);
