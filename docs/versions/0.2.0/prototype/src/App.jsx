import { useEffect, useRef, useState } from 'react';
import { ChartBar, Clock, Gear, ArrowClockwise, Bell, ArrowRight, Info, CheckCircle, WarningCircle, WifiSlash, Key, X, PushPin, Eye, CaretDown } from '@phosphor-icons/react';
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip } from 'recharts';

const scenes = { normal: '正常额度', low: '低额度', recovered: '额度恢复', offline: '网络异常', stale: '读数过旧', auth: '需要授权', empty: '暂无数据' };
const hourly = [1.4, 2.7, 1.1, 0.7, 2.3, 1.4, 0.9, 1.2, 2.7, 1.7, 1.1, 0.9].map((value, i) => ({ time: `19:${String(i * 5).padStart(2, '0')}`, value }));
const tokenDays = Array.from({ length: 30 }, (_, i) => {
  const day = new Date(Date.UTC(2026, 8, 16 + i));
  return { time: `${day.getUTCMonth() + 1}/${day.getUTCDate()}`, value: [1.2, 2.5, 0.8, 3.1, 2.2, 1.1, 0, 2.8, 3.4, 1.6][i % 10] };
});
const pages = [{ id: 'overview', label: '总览', icon: ChartBar }, { id: 'usage', label: '用量', icon: Clock }, { id: 'settings', label: '设置', icon: Gear }];

function Toggle({ checked, onChange, label }) {
  return <button className="toggle" type="button" role="switch" aria-checked={checked} aria-label={label} onClick={() => onChange(!checked)}><span /></button>;
}
function Row({ title, description, children }) {
  return <div className="setting-row"><div><h3>{title}</h3>{description && <p>{description}</p>}</div><div className="row-control">{children}</div></div>;
}
function ConsumptionChart({ data, tokens = false }) {
  const [selected, setSelected] = useState(null);
  useEffect(() => setSelected(null), [data]);
  return <div className="chart-wrap"><div className="chart" role="region" aria-label={tokens ? '演示 Token 历史，单位百万 Token' : '最近一小时演示消耗，每柱五分钟，单位百分点'}>
    <ResponsiveContainer width="100%" height="100%"><BarChart data={data} margin={{ top: 14, right: 4, left: -22, bottom: 0 }} accessibilityLayer>
      <CartesianGrid stroke="#3a424c" vertical={false} strokeDasharray="4 4" />
      <XAxis dataKey="time" tick={{ fill: '#a8afb9', fontSize: 12 }} axisLine={{ stroke: '#5a626b' }} tickLine={false} interval={tokens ? 'preserveStartEnd' : 0} minTickGap={16} dy={10} />
      <YAxis domain={[0, tokens ? 4 : 6]} ticks={tokens ? [0, 2, 4] : [0, 3, 6]} tick={{ fill: '#a8afb9', fontSize: 12 }} axisLine={false} tickLine={false} />
      <Tooltip cursor={{ fill: '#b9dfff10' }} contentStyle={{ background: '#262d37', border: '1px solid #59616d', borderRadius: 10, color: '#fff' }} labelFormatter={v => `${tokens ? '2026/' : ''}${v}`} formatter={v => [`${v} ${tokens ? '百万 Token' : '个百分点'}`, tokens ? 'Token 用量' : '额度下降']} />
      <Bar dataKey="value" fill="#73b9ed" radius={[3, 3, 0, 0]} maxBarSize={28} onClick={d => setSelected(d)} />
    </BarChart></ResponsiveContainer>
  </div><div className="chart-readout" aria-live="polite">{selected ? `${selected.time} · ${tokens ? '用量' : '额度下降'} ${selected.value} ${tokens ? '百万 Token' : '个百分点'}` : '指向柱形查看数值，也可用键盘聚焦图表查看。'}</div></div>;
}
function Quota({ title, value, reset, muted = false }) {
  return <section className={`quota ${muted ? 'quota-muted' : ''}`} aria-label={title}><h2><span className={`dot ${value === null ? 'unknown' : value <= 10 ? 'danger' : ''}`} />{title}</h2><div className={`quota-value ${value !== null && value <= 10 ? 'low' : ''}`}>{value === null ? '—' : `${value}%`}</div><div className="remaining">{value === null ? '暂未取得读数' : '剩余额度'}</div><progress aria-label={value === null ? `${title}额度未知` : `${title}剩余额度`} value={value === null ? undefined : value} max={100} className={value !== null && value <= 10 ? 'danger' : ''} /><p>{reset}</p></section>;
}

export function App() {
  const [page, setPage] = useState('overview');
  const [tab, setTab] = useState('display');
  const [scene, setScene] = useState('normal');
  const [sceneMenu, setSceneMenu] = useState(false);
  const [threshold, setThreshold] = useState('10');
  const [recovery, setRecovery] = useState(true);
  const [permission, setPermission] = useState('allowed');
  const [refreshing, setRefreshing] = useState(false);
  const [toast, setToast] = useState(null);
  const [modal, setModal] = useState(null);
  const [range, setRange] = useState(30);
  const [style, setStyle] = useState('bubble');
  const [widget, setWidget] = useState(true);
  const [alwaysOnTop, setAlwaysOnTop] = useState(true);
  const [fullscreen, setFullscreen] = useState(true);
  const [primary, setPrimary] = useState('5h');
  const [preview, setPreview] = useState(false);
  const [pinned, setPinned] = useState(false);
  const [hidden, setHidden] = useState(false);
  const [repaired, setRepaired] = useState(false);
  const [interval, setIntervalValue] = useState('1');
  const timer = useRef(null), toastTimer = useRef(null), menuRef = useRef(null), modalRef = useRef(null), previousFocus = useRef(null);
  const stale = ['offline', 'stale'].includes(scene);
  const unknown = ['empty', 'auth'].includes(scene);
  const five = unknown ? null : scene === 'low' ? 8 : scene === 'recovered' ? 100 : 80;
  const weekly = unknown ? null : 70;
  const status = refreshing ? '正在刷新' : scene === 'offline' ? '网络异常 · 保留上次读数' : scene === 'stale' ? '读数已过旧' : scene === 'auth' ? '需要重新授权' : scene === 'empty' ? '等待首次读取' : '刚刚更新';
  const notify = text => { clearTimeout(toastTimer.current); setToast(text); toastTimer.current = setTimeout(() => setToast(null), 4500); };
  const navigate = id => { setPage(id); setSceneMenu(false); setPreview(false); };
  const reminders = () => { navigate('settings'); setTab('reminders'); };
  const closeModal = () => { setModal(null); previousFocus.current?.focus(); };
  useEffect(() => () => { clearTimeout(timer.current); clearTimeout(toastTimer.current); }, []);
  useEffect(() => {
    const clickOutside = e => {
      if (menuRef.current && !menuRef.current.contains(e.target)) setSceneMenu(false);
      if (!pinned && !e.target.closest('.widget-demo')) setPreview(false);
    };
    document.addEventListener('pointerdown', clickOutside);
    return () => document.removeEventListener('pointerdown', clickOutside);
  }, [pinned]);
  useEffect(() => {
    if (modal) { previousFocus.current = document.activeElement; modalRef.current?.querySelector('button')?.focus(); }
  }, [modal]);
  useEffect(() => {
    const keys = e => {
      if (e.key === 'Escape') { if (modal) closeModal(); setSceneMenu(false); setPreview(false); }
      if (e.key === 'Tab' && modalRef.current) {
        const nodes = modalRef.current.querySelectorAll('button, select, input, [href]');
        const first = nodes[0], last = nodes[nodes.length - 1];
        if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
        else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
      }
    };
    document.addEventListener('keydown', keys); return () => document.removeEventListener('keydown', keys);
  }, [modal]);
  function refresh() {
    if (refreshing) return;
    setRefreshing(true);
    timer.current = setTimeout(() => {
      setRefreshing(false);
      if (scene === 'offline') notify('演示：网络仍不可用，保留原读数与时间。');
      else if (scene === 'auth') setModal('repair');
      else { if (['stale', 'empty'].includes(scene)) setScene('normal'); notify('演示数据已更新。'); }
    }, 750);
  }
  function applyScene(id) {
    clearTimeout(timer.current); setRefreshing(false); setScene(id); setSceneMenu(false); setRepaired(false);
    if (id === 'recovered' && recovery) notify('演示提醒：5 小时额度已确认恢复。');
    if (id === 'low' && threshold !== 'off' && Number(threshold) >= 8) notify('演示提醒：5 小时额度剩余 8%。');
  }
  return <div className="app-shell">
    <aside className="sidebar">
      <div className="window-controls" aria-hidden="true"><i /><i /><i /></div>
      <div className="brand"><img src="/assets/app-icon.png" alt="" /><strong>ReadyCheck</strong></div>
      <nav aria-label="主导航">{pages.map(({ id, label, icon: Icon }) => <button key={id} className={page === id ? 'nav-item active' : 'nav-item'} aria-current={page === id ? 'page' : undefined} onClick={() => navigate(id)}><Icon size={28} weight={page === id ? 'fill' : 'regular'} /><span>{label}</span></button>)}</nav>
      <div className="sidebar-bottom"><div className="demo-picker" ref={menuRef}><button className="scene-button" aria-expanded={sceneMenu} onClick={() => setSceneMenu(!sceneMenu)}>演示场景<CaretDown size={15} /></button>{sceneMenu && <div className="scene-menu" aria-label="演示场景">{Object.entries(scenes).map(([id, label]) => <button key={id} className={id === scene ? 'selected' : ''} onClick={() => applyScene(id)}>{label}{scene === id && <CheckCircle size={17} />}</button>)}</div>}</div><p>0.2.0 概念 · 演示数据</p></div>
    </aside>
    <main className="main">
      <header className="page-header"><div><h1>{pages.find(p => p.id === page).label}</h1><p>{page === 'overview' ? 'Codex 额度' : page === 'usage' ? '了解用量的变化' : '按你的习惯使用 ReadyCheck'}</p></div><div className="header-actions"><button className="button refresh" onClick={refresh} disabled={refreshing}><ArrowClockwise size={22} className={refreshing ? 'spin' : ''} />{refreshing ? '刷新中' : '刷新'}</button><button className={`status-button ${stale || unknown ? 'warning' : ''}`} onClick={() => setModal(scene === 'auth' ? 'repair' : 'status')}><span className="dot" />{status}</button></div></header>
      <div className="page-content">
        {page === 'overview' && <>
          {(stale || scene === 'auth') && <div className={`notice ${scene === 'auth' ? 'notice-danger' : ''}`} role="status">{scene === 'offline' ? <WifiSlash size={23} /> : scene === 'auth' ? <Key size={23} /> : <WarningCircle size={23} />}<div><strong>{scene === 'offline' ? '暂时无法连接，以下为上次成功读取的数据' : scene === 'auth' ? '连接需要确认，当前额度未知' : '这次读数已过旧，请刷新后再参考'}</strong><p>{scene === 'auth' ? '由你主动修复连接，演示不会访问真实账号。' : '上次成功更新 19:42 · 失败的刷新不会改变数据时间。'}</p></div><button className="text-button" onClick={() => scene === 'auth' ? setModal('repair') : refresh()}>{scene === 'auth' ? '修复连接' : '重试读取'}<ArrowRight size={18} /></button></div>}
          <div className="quota-grid"><Quota title="5 小时配额" value={five} reset={unknown ? '重置时间未知' : scene === 'recovered' ? '距重置 5 小时' : '距重置 2 小时'} muted={stale} /><Quota title="7 天配额" value={weekly} reset={unknown ? '重置时间未知' : '距重置 4 天 6 小时'} muted={stale} /></div>
          {scene === 'low' && <div className="inline-warning"><WarningCircle size={19} />5 小时额度较低，请留意后续使用。<button className="text-button" onClick={reminders}>查看提醒设置<ArrowRight size={17} /></button></div>}
          <section className="consumption"><div className="section-heading"><div><h2>最近一小时消耗</h2><p>变化（百分点）</p></div><span>{stale ? '截至 19:40 · 每柱 5 分钟' : '每柱 5 分钟'}</span></div>{unknown || scene === 'recovered' ? <div className="empty-chart"><ChartBar size={35} /><h3>{scene === 'recovered' ? '新周期记录正在积累' : '还没有可展示的额度记录'}</h3><p>{scene === 'recovered' ? '额度已恢复；等待新周期的有效采样。' : '取得有效读数后开始记录，未知数据不会填成零。'}</p><button className="button" onClick={refresh}>重试读取</button></div> : <ConsumptionChart data={stale ? hourly.slice(0, 9) : hourly} />}</section>
          <div className="reminder-summary"><Bell size={26} /><strong>低额度提醒</strong><span>{threshold === 'off' ? '已关闭' : `${threshold}%`} · 恢复提醒{recovery ? '已开启' : '已关闭'}</span><button className="text-button" onClick={reminders}>管理提醒<ArrowRight size={20} /></button></div>
        </>}
        {page === 'usage' && <>
          <div className="usage-title"><div><h2>Token 使用量</h2><p>与额度百分比分开查看，不换算为剩余工作时长。</p></div><div className="segmented" aria-label="用量时间范围">{[7, 30, 90].map(n => <button key={n} aria-pressed={range === n} className={range === n ? 'selected' : ''} onClick={() => setRange(n)}>{n} 天</button>)}</div></div>
          <div className="usage-metrics"><div><span>已记录 Token</span><strong>{tokenDays.slice(-Math.min(range, 30)).reduce((sum, x) => sum + x.value, 0).toFixed(1)}<small> 百万</small></strong></div><div><span>记录覆盖</span><strong>{Math.min(range, 30)}<small> / {range} 天</small></strong></div><div><span>时间范围</span><strong className="date-range">{range === 7 ? '10/09 — 10/15' : range === 30 ? '09/16 — 10/15' : '07/18 — 10/15'}</strong></div></div>
          {range === 90 && <div className="notice"><Info size={22} /><div><strong>历史记录未覆盖完整区间</strong><p>本演示只提供最近 30 天样本；其余日期未知，不按零计算。</p></div></div>}
          <section className="usage-chart"><div className="section-heading"><h2>每日 Token 用量</h2><span>单位：百万 Token · 截至 2026/10/15</span></div><ConsumptionChart tokens data={tokenDays.slice(-Math.min(range, 30))} /></section>
          <div className="quiet-note"><Info size={19} /><p>此处是合成的 Token 历史样本。额度的百分点变化与 Token 数量不是同一单位；记录缺失也不等于没有使用。</p></div>
        </>}
        {page === 'settings' && <>
          <div className="settings-tabs" aria-label="设置分类">{[['display', '显示'], ['reminders', '提醒'], ['account', '账号与数据']].map(([id, title]) => <button key={id} aria-pressed={tab === id} className={tab === id ? 'selected' : ''} onClick={() => setTab(id)}>{title}</button>)}</div>
          {tab === 'display' && <section className="settings-section"><h2>桌面显示</h2><p className="section-intro">把额度放在方便查看的位置。</p>
            <Row title="显示悬浮窗" description="随时查看额度，无需打开主窗口。"><Toggle checked={widget} onChange={setWidget} label="显示悬浮窗" /></Row>
            <div className="style-picker" aria-label="悬浮窗样式">{[['bubble', '圆球', 'bubble.png'], ['card', '详情卡片', 'details.png'], ['edge', '贴边竖条', 'edge.png']].map(([id, label, asset]) => <button className={style === id ? 'selected' : ''} aria-pressed={style === id} key={id} onClick={() => { setStyle(id); setHidden(false); }}><span className={`style-image ${id}`}><img src={`/assets/${asset}`} alt={`${label}原生组件演示`} /></span><strong>{label}</strong>{style === id && <CheckCircle className="style-check" size={19} weight="fill" />}</button>)}</div>
            <div className="surface-plan"><button className="button" onClick={() => setModal('surfaces')}><Eye size={20} />查看 widget 与刘海方案</button><p>刘海无缝衔接，贴边保留细窄竖条；原生实现待验收。</p></div>
            <Row title="主显示额度" description="名称、百分比和状态始终对应同一个额度窗口。"><select aria-label="主显示额度" value={primary} onChange={e => setPrimary(e.target.value)}><option value="5h">5 小时</option><option value="7d">7 天</option></select></Row>
            <Row title="浮窗置于最前" description="控制窗口层级，与“保持详情展开”分别设置。"><Toggle checked={alwaysOnTop} onChange={setAlwaysOnTop} label="浮窗置于最前" /></Row>
            <Row title="全屏时隐藏" description="返回桌面后恢复显示。"><Toggle checked={fullscreen} onChange={setFullscreen} label="全屏时隐藏" /></Row>
            <Row title="临时隐藏" description={hidden ? '演示浮窗已隐藏，可随时恢复。' : '在演示中查看隐藏和恢复的操作。'}><button className="button" onClick={() => { setHidden(!hidden); setPreview(false); }}>{hidden ? '恢复浮窗' : '隐藏浮窗'}</button></Row>
            <div className="preview-launch"><button className="button primary" disabled={!widget || hidden} onClick={() => setPreview(!preview)}><Eye size={20} />{preview ? '收起预览' : '预览浮窗'}</button><span>真实原生组件素材，浮窗操作仅在页面内演示。</span></div>
          </section>}
          {tab === 'reminders' && <section className="settings-section"><h2>额度提醒</h2><p className="section-intro">提前知道额度不足，恢复后收到一次提醒。</p>
            <Row title="低额度提前提醒" description="剩余比例降到所选阈值时提醒，同一窗口每轮一次。"><select aria-label="低额度提醒阈值" value={threshold} onChange={e => { setThreshold(e.target.value); notify('提醒阈值已在本次演示中保存。'); }}>{['off', '5', '10', '20'].map(v => <option value={v} key={v}>{v === 'off' ? '关闭' : `${v}%`}</option>)}</select></Row>
            <Row title="额度恢复提醒" description="确认实际额度恢复后提醒，时间到了本身不代表恢复。"><Toggle checked={recovery} onChange={setRecovery} label="额度恢复提醒" /></Row>
            <Row title="系统通知权限" description="展示授权后的操作流程，不读取真实系统权限。"><select aria-label="模拟通知权限" value={permission} onChange={e => setPermission(e.target.value)}><option value="allowed">已允许（模拟）</option><option value="denied">未允许（模拟）</option></select></Row>
            {permission === 'denied' && <div className="notice"><WarningCircle size={22} /><div><strong>系统通知尚未允许</strong><p>正式应用将引导你在系统设置中开启 ReadyCheck 通知。</p></div><button className="text-button" onClick={() => setModal('permission')}>查看操作说明<ArrowRight size={18} /></button></div>}
            <Row title="测试通知" description="仅在本页预览提醒，不发送真实系统通知。"><button className="button" onClick={() => permission === 'allowed' ? notify('演示通知：ReadyCheck · 5 小时额度剩余 10%。') : setModal('permission')}>预览测试通知</button></Row>
            <div className="quiet-note"><Bell size={20} /><p>系统接收通知不代表用户看到了横幅；专注模式和通知样式可能影响展示。提醒告知额度变化，不控制 Codex 任务。</p></div>
          </section>}
          {tab === 'account' && <section className="settings-section"><h2>账号与数据</h2><p className="section-intro">把当前额度状态与套餐资料分别说明。</p><Row title="Codex 连接" description={scene === 'auth' ? '需要重新确认授权。' : '独立 OAuth · 演示账号，不展示个人资料。'}><button className="button" onClick={() => setModal('repair')}>修复连接<Key size={18} /></button></Row><Row title="数据状态" description={status}><button className="button" onClick={() => setModal('status')}>查看详情<Info size={18} /></button></Row><Row title="刷新间隔" description="保留现有固定间隔，自动刷新策略另行验证。"><select value={interval} aria-label="刷新间隔" onChange={e => setIntervalValue(e.target.value)}><option value="1">1 分钟</option><option value="3">3 分钟</option><option value="5">5 分钟</option></select></Row><Row title="套餐资料" description="记录的套餐日期不能替代当前额度验证。"><button className="text-button" onClick={() => setModal('plan')}>按需查看<ArrowRight size={18} /></button></Row><div className="quiet-note"><Info size={20} /><p>演示不连接账号、不读写钥匙串，也不会改变已安装应用的设置。刷新网页将重置本次演示选择。</p></div></section>}
        </>}
      </div>
      <footer className="main-footer"><button className="text-button" onClick={() => setModal('status')}>数据来源与状态<ArrowRight size={19} /></button><span>2026/10/15 · 模拟数据</span></footer>
    </main>
    {preview && widget && !hidden && <div className="widget-demo"><div className="widget-toolbar"><strong>{style === 'edge' ? '贴边' : style === 'card' ? '卡片' : '圆球'} · 读数与固定预览</strong><button className={pinned ? 'icon-button pinned' : 'icon-button'} aria-label={pinned ? '取消保持展开' : '保持详情展开'} aria-pressed={pinned} onClick={() => setPinned(!pinned)}><PushPin size={20} weight={pinned ? 'fill' : 'regular'} /></button><button className="icon-button" aria-label="关闭浮窗预览" onClick={() => setPreview(false)}><X size={20} /></button></div><Quota title={primary === '5h' ? '5 小时配额' : '7 天配额'} value={primary === '5h' ? five : weekly} reset={unknown ? '重置时间未知' : primary === '7d' ? '距重置 4 天 6 小时' : scene === 'recovered' ? '距重置 5 小时' : '距重置 2 小时'} muted={stale} /><p>{pinned ? '已保持展开，点击页面其他区域不会收起。' : '点击页面其他区域收起；可固定保持展开。'} Esc 可关闭。</p><small>原生外观见样式选项；此处演示读数与交互。</small></div>}

    {modal && <div className="modal-backdrop" onClick={e => { if (e.target === e.currentTarget) closeModal(); }}><section className={modal === 'surfaces' ? 'modal modal-design' : 'modal'} ref={modalRef} role="dialog" aria-modal="true" aria-labelledby="modal-title"><div className="modal-heading"><h2 id="modal-title">{modal === 'surfaces' ? 'Widget 与刘海 · 0.2.0 设计方案' : modal === 'status' ? '数据来源与状态' : modal === 'repair' ? '修复 Codex 连接' : modal === 'permission' ? '开启系统通知' : '套餐资料'}</h2><button className="icon-button" aria-label="关闭对话框" onClick={closeModal}><X size={22} /></button></div>
      {modal === 'surfaces' && <><img className="surface-board" src="/assets/widget-notch-concept.png?v=preview3" alt="0.2.0 五种形态：圆球收起、widget 展开、细窄竖条贴边，以及与物理刘海无缝相连的收起和展开态。合成数据。" /><p className="modal-note">这是视觉设计稿，不代表原生窗口和刘海交互已经实现。固定、读数和异常状态仍可在当前演示中体验。</p></>}
      {modal === 'status' && <><div className={`status-callout ${stale || unknown ? 'warning' : ''}`}>{stale || unknown ? <WarningCircle size={23} /> : <CheckCircle size={23} />}<strong>{status}</strong></div><dl><div><dt>数据来源</dt><dd>合成演示样本</dd></div><div><dt>上次成功读取</dt><dd>{unknown ? '尚无有效读数' : stale ? '2026/10/15 19:42' : '2026/10/15 20:00'}</dd></div><div><dt>额度验证</dt><dd>{unknown ? '未知' : stale ? '请刷新后再参考' : '有效（模拟）'}</dd></div></dl><p className="modal-note">暂时的网络故障保留旧数据和原时间。授权失效时额度标为未知，避免把旧账号数据当成当前状态。</p><button className="button primary" onClick={() => { closeModal(); refresh(); }}>重试读取<ArrowClockwise size={19} /></button></>}
      {modal === 'repair' && <><Key size={36} className="blue" /><p>由你主动确认后，再进入连接修复流程。后台检测到问题时只显示状态提示。</p><div className="notice"><Info size={21} /><p>此处只演示流程，不启动真实登录、不读取凭据、不触发系统授权。</p></div>{repaired ? <div className="status-callout"><CheckCircle size={22} /><span>演示修复完成，可返回查看额度。</span></div> : <button className="button primary" onClick={() => { setRepaired(true); setScene('normal'); }}>模拟完成重新授权<ArrowRight size={19} /></button>}</>}
      {modal === 'permission' && <><p>正式使用时，前往系统设置 → 通知 → ReadyCheck，允许通知并选择合适的提醒样式。</p><p className="modal-note">网页演示仅切换模拟权限状态，不打开系统设置。</p><button className="button primary" onClick={() => { setPermission('allowed'); closeModal(); notify('演示通知权限已设为允许。'); }}>模拟已允许<CheckCircle size={19} /></button></>}
      {modal === 'plan' && <><dl><div><dt>套餐</dt><dd>Plus（演示）</dd></div><div><dt>记录的套餐日期</dt><dd>2026/10/01（示例旧资料）</dd></div></dl><p className="modal-note">这条历史资料不代表当前订阅是否有效。当前额度有效性在“数据来源与状态”中单独说明。</p></>}
    </section></div>}
    {toast && <div className="toast" role="status"><Bell size={21} /><span>{toast}</span><button className="icon-button" aria-label="关闭提示" onClick={() => setToast(null)}><X size={18} /></button></div>}
  </div>;
}
