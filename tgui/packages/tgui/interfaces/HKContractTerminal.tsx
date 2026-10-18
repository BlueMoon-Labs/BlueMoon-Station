import { BooleanLike } from 'common/react';
import { KeyboardEvent, ReactNode, useEffect, useRef, useState } from 'react';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type Contract = {
  ref: string;
  id: string;
  client: string;
  client_flavor: string;
  client_bonus: number;
  perk: string | null;
  dirty: BooleanLike;
  task: string;
  kind: string;
  hunt: BooleanLike;
  identified: BooleanLike;
  target: string;
  rules: string;
  modifier: string | null;
  modifier_rules: string | null;
  points: number;
  bonus: number;
  lethal: BooleanLike;
  unavailable: string | null;
};

type Suspect = { ref: string; name: string };

type Trace = {
  area: string | null;
  minutes: number | null;
  cold: BooleanLike;
  near: BooleanLike;
};

type Radar = {
  lost?: BooleanLike;
  other_level?: BooleanLike;
  level?: 'same' | 'above' | 'below' | null;
  distance?: number;
  band?: 'near' | 'mid' | 'far';
  direction?: string | null;
  angle?: number;
};

type ActiveContract = Contract & {
  deadline: number | null;
  deadline_kind: 'protect' | 'urgent';
  trace?: Trace;
  radar: Radar | null;
  can_scan: BooleanLike;
  can_capture: BooleanLike;
  capture_called: BooleanLike;
  suspects: Suspect[];
  presence?: number;
  presence_left?: number;
};

type ManualEntry = {
  title: string;
  text: string;
};

type CatalogEntry = {
  id: string;
  name: string;
  summary: string;
  specs: string;
  price_curve: string | null;
  repeatable: BooleanLike;
};

type UpgradeState = {
  id: string;
  cost: number;
  owned: number;
  available: BooleanLike;
  reason: string | null;
  status: string | null;
};

type HistoryEntry = {
  contract: string;
  outcome: 'done' | 'failed' | 'refused' | 'dropped';
  kind: string;
  points: number;
  comment: string;
};

type Tallies = {
  killed: number;
  captured: number;
  stolen: number;
  sabotaged: number;
};

type ShieldState = {
  active: BooleanLike;
  cooldown: number;
};

type RifleState = {
  shots: number;
  sniper: BooleanLike;
  sniper_mode: BooleanLike;
  sniper_cooldown: number;
  stun_mode: BooleanLike;
};

/** Статус HK-47 для станции, эскалация и эвакуация. */
type StationStatus = {
  status_name: string;
  status_text: string;
  threat: number;
  threat_max: number;
  extraction_text: string;
  extraction_available: BooleanLike;
  extraction_reason: string | null;
};

export type HKContractTerminalData = {
  points: number;
  contracts_done: number;
  contracts_needed: number;
  charge: number;
  charge_max: number;
  rifle: RifleState | null;
  shield: ShieldState | null;
  rifle_max: number;
  identify_range: number;
  protect_presence_needed: number;
  photos: Record<string, string>;
  manual: ManualEntry[];
  reroll_cooldown: number;
  identify_cooldown: number;
  scanning: BooleanLike;
  offers: Contract[];
  active: ActiveContract | null;
  catalog: CatalogEntry[];
  upgrades: UpgradeState[];
  history: HistoryEntry[];
  tallies: Tallies;
  ticker: string;
  station: StationStatus | null;
  extraction_ready: BooleanLike;
};

const TABS = ['КОНТРАКТЫ', 'МОДУЛИ', 'ЖУРНАЛ', 'ШАССИ'] as const;
type Tab = (typeof TABS)[number];

const OUTCOMES: Record<HistoryEntry['outcome'], string> = {
  done: 'ВЫПОЛНЕН',
  failed: 'ПРОВАЛЕН',
  refused: 'ОТКАЗ',
  dropped: 'СНЯТ',
};

const MODIFIER_TAGS: Record<string, string> = {
  'без свидетелей': 'ТИХО',
  'срочно': 'СРОЧНО',
  'несчастный случай': 'СЛУЧАЙ',
  'без лишних жертв': 'ЧИСТО',
};

const PROTOCOLS: Record<string, string> = {
  kill: 'Утверждение: протокол ликвидации активен.',
  hunt: 'Утверждение: протокол охоты активен. Дичь предупреждена о погоне - тем интереснее.',
  capture: 'Утверждение: протокол захвата активен. Живым, хозяин. Как ни жаль.',
  theft: 'Утверждение: протокол изъятия активен. Владелец не сразу заметит пропажу.',
  sabotage: 'Утверждение: протокол саботажа активен. Машины хотя бы не кричат.',
  protect: 'Утверждение: протокол охраны активен. Подопечный не знает, как ему повезло.',
};

const GUIDANCE: Record<string, string> = {
  sabotage: 'Наблюдение: выведите машину из строя любым способом, терминал засчитает поломку сам.',
  protect: 'Наблюдение: держите подопечного живым и держитесь рядом - заказчик сверяет пеленги. Терминал засчитает сам.',
};

const BAND_NAMES = { near: 'РЯДОМ', mid: 'БЛИЗКО', far: 'ДАЛЕКО' };
const LEVEL_NAMES: Record<string, string> = { above: 'УРОВЕНЬ ВЫШЕ', below: 'УРОВЕНЬ НИЖЕ' };
const BAND_RADIUS = { near: 14, mid: 27, far: 40 };
const RULE = '─'.repeat(200);
const TYPE_DELAY = 22;

export const pointsWord = (count: number) => {
  const tens = count % 100;
  const ones = count % 10;
  if (tens >= 11 && tens <= 14) return 'очков';
  if (ones === 1) return 'очко';
  if (ones >= 2 && ones <= 4) return 'очка';
  return 'очков';
};

export const formatSeconds = (seconds: number) => {
  const minutes = Math.floor(seconds / 60);
  const rest = seconds % 60;
  return `${minutes < 10 ? '0' : ''}${minutes}:${rest < 10 ? '0' : ''}${rest}`;
};

export const chargeBar = (charge: number, max: number, cells = 5) => {
  const filled = Math.max(0, Math.min(cells, Math.round((charge / Math.max(max, 1)) * cells)));
  return '▓'.repeat(filled) + '░'.repeat(cells - filled);
};

const pad2 = (value: number) => (value < 10 ? `0${value}` : `${value}`);

const isHidden = (contract: Contract) => !!contract.hunt && !contract.identified;

const prefersReducedMotion = () =>
  typeof window.matchMedia === 'function' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

const traceText = (trace?: Trace) => {
  if (!trace) return 'откроется после принятия';
  if (!trace.area) return 'не найден, цель ещё не проявила себя';
  const age = trace.minutes ? `${trace.minutes} мин. назад` : 'только что';
  return trace.cold ? `остыл (${trace.area}, ${age})` : `${trace.area}, ${age}`;
};

const targetText = (contract: Contract) => (isHidden(contract) ? '[ЗАСЕКРЕЧЕНО]' : contract.target);

const Rule = () => (
  <div className="HKContractTerminal__rule" aria-hidden>
    {RULE}
  </div>
);

const Heading = ({ children }: { children: ReactNode }) => (
  <div className="HKContractTerminal__heading">== {children} ==</div>
);

const Field = ({ label, children }: { label: string; children: ReactNode }) => (
  <div className="HKContractTerminal__field">
    <span className="HKContractTerminal__label">{label}</span>
    <span>{children}</span>
  </div>
);

type CommandProps = {
  children: ReactNode;
  onClick: () => void;
  disabled?: boolean;
  reason?: string | null;
  primary?: boolean;
};

/** Текстовая команда терминала: вспыхивает при нажатии, недоступная тускнеет и печатает причину. Enter и пробел нажимают её с клавиатуры. */
const Command = ({ children, onClick, disabled, reason, primary }: CommandProps) => {
  const [flash, setFlash] = useState(false);
  const run = (event?: { stopPropagation: () => void }) => {
    event?.stopPropagation();
    if (disabled) {
      return;
    }
    setFlash(true);
    onClick();
  };
  const onKeyDown = (event: KeyboardEvent<HTMLSpanElement>) => {
    if (event.key !== 'Enter' && event.key !== ' ' && event.code !== 'Space') {
      return;
    }
    event.preventDefault();
    run(event);
  };
  let className = 'HKContractTerminal__cmd';
  if (primary) className += ' HKContractTerminal__cmd--primary';
  if (disabled) className += ' HKContractTerminal__cmd--off';
  if (flash) className += ' HKContractTerminal__cmd--flash';
  return (
    <span className="HKContractTerminal__command">
      <span
        role="button"
        aria-disabled={!!disabled}
        tabIndex={disabled ? -1 : 0}
        className={className}
        onClick={run}
        onKeyDown={onKeyDown}
        onAnimationEnd={() => setFlash(false)}>
        [{children}]
      </span>
      {!!disabled && !!reason && <span className="HKContractTerminal__reason"> ({reason})</span>}
    </span>
  );
};

/** Строка, которую HK допечатывает посимвольно; при сниженной анимации - сразу целиком. */
export const Ticker = ({ text }: { text: string }) => {
  const [shown, setShown] = useState(() => (prefersReducedMotion() ? text.length : 0));
  useEffect(() => {
    if (prefersReducedMotion()) {
      setShown(text.length);
      return;
    }
    let typed = 0;
    setShown(0);
    const timer = setInterval(() => {
      typed += 1;
      setShown(typed);
      if (typed >= text.length) {
        clearInterval(timer);
      }
    }, TYPE_DELAY);
    return () => clearInterval(timer);
  }, [text]);
  return (
    <div className="HKContractTerminal__ticker" title={text}>
      {'> '}
      {text.slice(0, shown)}
      <span className="HKContractTerminal__cursor" aria-hidden>
        {' '}
      </span>
    </div>
  );
};

const Reticle = () => (
  <svg className="HKContractTerminal__reticle" viewBox="0 0 96 96" aria-hidden>
    <path d="M6 22 V6 H22 M74 6 H90 V22 M90 74 V90 H74 M22 90 H6 V74" strokeWidth="2" />
    <circle cx="48" cy="44" r="14" strokeWidth="1" strokeDasharray="4 3" />
    <path d="M48 24 V34 M48 54 V64 M28 44 H38 M58 44 H68" strokeWidth="1" />
  </svg>
);

/** Снимок цели в янтаре с прицелом; засекреченную цель терминал не показывает никогда. */
const Photo = ({ contract }: { contract: Contract }) => {
  const { data } = useBackend<HKContractTerminalData>();
  const hidden = isHidden(contract);
  const photo = data.photos?.[contract.id];
  let picture: ReactNode;
  if (hidden) {
    picture = (
      <>
        <div className="HKContractTerminal__static" />
        <div className="HKContractTerminal__stamp">[ЗАСЕКРЕЧЕНО]</div>
      </>
    );
  } else if (photo) {
    picture = <img className="HKContractTerminal__photoImg" src={`data:image/png;base64,${photo}`} alt="" />;
  } else {
    picture = <div className="HKContractTerminal__noPhoto">НЕТ СНИМКА</div>;
  }
  return (
    <div className="HKContractTerminal__photo" data-hidden={hidden ? 'true' : undefined}>
      {picture}
      {!hidden && <Reticle />}
    </div>
  );
};

const RadarScope = ({ contract }: { contract: ActiveContract }) => {
  const { radar, trace } = contract;
  const blip = radar && radar.band && radar.angle !== undefined ? radar : null;
  let caption = 'СИГНАЛ ПОТЕРЯН';
  if (!radar) {
    caption = trace?.near ? 'СИГНАТУРА РЯДОМ' : 'БЕЗ ПЕЛЕНГА';
  } else if (radar.other_level) {
    caption = (radar.level && LEVEL_NAMES[radar.level]) || 'ДРУГОЙ УРОВЕНЬ';
  } else if (blip?.band) {
    caption = `${BAND_NAMES[blip.band]}: ${blip.distance} кл.${blip.direction ? `, ${blip.direction}` : ''}`;
  }
  let blipX = 0;
  let blipY = 0;
  if (blip?.band) {
    const radians = ((blip.angle || 0) * Math.PI) / 180;
    const radius = blip.distance ? BAND_RADIUS[blip.band] : 0;
    blipX = Math.round(Math.sin(radians) * radius * 10) / 10;
    blipY = Math.round(-Math.cos(radians) * radius * 10) / 10;
  }
  return (
    <div className="HKContractTerminal__radar">
      <svg className="HKContractTerminal__radarSvg" viewBox="-50 -50 100 100" aria-label="Радар">
        <circle r="47" />
        <circle r="33" />
        <circle r="20" />
        <path d="M-47 0 H47 M0 -47 V47" strokeWidth="0.5" />
        <path className="HKContractTerminal__radarSweep" d="M0 0 L0 -47 A47 47 0 0 1 27 -38.5 Z" />
        <circle className="HKContractTerminal__radarSelf" r="2" />
        {!radar && !!trace?.near && <circle className="HKContractTerminal__radarPulse" r="24" data-testid="hk-pulse" />}
        {!!blip && (
          <circle className="HKContractTerminal__radarBlip" cx={blipX} cy={blipY} r="3.2" data-testid="hk-blip" />
        )}
      </svg>
      <div className={'HKContractTerminal__radarCaption' + (!radar && trace?.near ? ' HKContractTerminal__warn' : '')}>
        {caption}
      </div>
    </div>
  );
};

type Selection = { index: number; count: number; select: (index: number) => void };

const useSelection = (count: number): Selection => {
  const [index, setIndex] = useState(0);
  const clamped = count ? Math.min(index, count - 1) : 0;
  return { index: clamped, count, select: (next) => setIndex(Math.max(0, Math.min(next, count - 1))) };
};

type KeyHandlers = {
  onTab: (tab: Tab) => void;
  onMove: (delta: number) => void;
  onEnter: () => void;
};

const TAB_KEYS: Record<string, Tab> = { Digit1: 'КОНТРАКТЫ', Digit2: 'МОДУЛИ', Digit3: 'ЖУРНАЛ', Digit4: 'ШАССИ' };

/** Клавиши окна: 1-4 вкладки, стрелки и j/k по списку, Enter - главная команда. Не трогает ввод текста и не перехватывает Enter у команды в фокусе. */
const useTerminalKeys = (handlers: KeyHandlers) => {
  const ref = useRef(handlers);
  ref.current = handlers;
  useEffect(() => {
    const onKeyDown = (event: globalThis.KeyboardEvent) => {
      const target = event.target as HTMLElement | null;
      if (event.ctrlKey || event.altKey || event.metaKey) return;
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) return;
      const onCommand = typeof target?.closest === 'function' && !!target.closest('[role="button"]');
      if (onCommand && (event.code === 'Enter' || event.code === 'NumpadEnter')) return;
      const tab = TAB_KEYS[event.code];
      if (tab) {
        ref.current.onTab(tab);
      } else if (event.code === 'ArrowDown' || event.code === 'KeyJ') {
        ref.current.onMove(1);
      } else if (event.code === 'ArrowUp' || event.code === 'KeyK') {
        ref.current.onMove(-1);
      } else if (event.code === 'Enter' || event.code === 'NumpadEnter') {
        ref.current.onEnter();
      } else {
        return;
      }
      event.preventDefault();
    };
    window.addEventListener('keydown', onKeyDown, true);
    return () => window.removeEventListener('keydown', onKeyDown, true);
  }, []);
};

export const HKContractTerminal = () => {
  const { act, data } = useBackend<HKContractTerminalData>();
  const [tab, setTab] = useState<Tab>('КОНТРАКТЫ');
  const offers = useSelection(data.offers.length);
  const modules = useSelection(data.catalog.length);
  const journal = useSelection(data.history.length);
  const manual = useSelection(data.manual.length);
  const selections: Record<Tab, Selection> = { КОНТРАКТЫ: offers, МОДУЛИ: modules, ЖУРНАЛ: journal, ШАССИ: manual };
  const states = upgradeStates(data.upgrades);
  const [armed, setArmed] = useState<string | null>(null);
  const buy = (id: string) => {
    if (armed !== id) {
      setArmed(id);
      return;
    }
    setArmed(null);
    act('buy', { id });
  };
  const switchTab = (next: Tab) => {
    setArmed(null);
    setTab(next);
  };
  useTerminalKeys({
    onTab: switchTab,
    onMove: (delta) => {
      const selection = selections[tab];
      setArmed(null);
      selection.select(selection.index + delta);
    },
    onEnter: () => {
      const offer = data.offers[offers.index];
      if (tab === 'КОНТРАКТЫ' && !data.active && offer && !offer.unavailable) {
        act('accept', { ref: offer.ref });
      } else if (tab === 'МОДУЛИ') {
        const entry = data.catalog[modules.index];
        if (entry && states[entry.id]?.available) {
          buy(entry.id);
        }
      }
    },
  });
  return (
    <Window width={860} height={660} theme="ntos_terminal">
      <Window.Content fitted>
        <div className="HKContractTerminal">
          <div className="HKContractTerminal__top">
            <StatusLine />
            <Ticker text={data.ticker} />
            <div className="HKContractTerminal__menu" role="tablist">
              {TABS.map((name, index) => (
                <span
                  key={name}
                  role="tab"
                  aria-selected={tab === name}
                  className={'HKContractTerminal__menuItem' + (tab === name ? ' HKContractTerminal__menuItem--active' : '')}
                  onClick={() => switchTab(name)}>
                  [{index + 1}] {name}
                </span>
              ))}
              <span className="HKContractTerminal__keys">1-4 ВКЛАДКИ // ↑↓ J K ВЫБОР // ENTER КОМАНДА</span>
            </div>
            <Rule />
          </div>
          <div className="HKContractTerminal__screen">
            {tab === 'КОНТРАКТЫ' && <ContractsScreen selection={offers} />}
            {tab === 'МОДУЛИ' && (
              <ModulesScreen
                selection={modules}
                states={states}
                armed={armed}
                onBuy={buy}
                onSelect={(index) => {
                  setArmed(null);
                  modules.select(index);
                }}
              />
            )}
            {tab === 'ЖУРНАЛ' && <JournalScreen selection={journal} />}
            {tab === 'ШАССИ' && <ManualScreen />}
          </div>
        </div>
      </Window.Content>
    </Window>
  );
};

const upgradeStates = (upgrades: UpgradeState[]) => {
  const states: Record<string, UpgradeState> = {};
  for (const upgrade of upgrades) {
    states[upgrade.id] = upgrade;
  }
  return states;
};

const StatusLine = () => {
  const { data } = useBackend<HKContractTerminalData>();
  const { rifle, shield, station } = data;
  const lowCharge = data.charge < data.charge_max / 4;
  let sniper = '';
  if (rifle?.sniper) {
    sniper = rifle.sniper_cooldown > 0 ? ` СНАЙП ${pad2(rifle.sniper_cooldown)}с` : rifle.sniper_mode ? ' СНАЙП' : '';
  }
  if (rifle?.stun_mode) {
    sniper = ` ПАРАЛ${sniper}`;
  }
  const warn = (flag: boolean) => (flag ? 'HKContractTerminal__warn' : undefined);
  return (
    <div className="HKContractTerminal__status">
      {`HK-47 // ОЧКИ ${data.points} // КОНТРАКТЫ ${data.contracts_done}/${data.contracts_needed} // ЗАРЯД `}
      <span className={warn(lowCharge)}>{`${chargeBar(data.charge, data.charge_max)} ${data.charge}`}</span>
      {' // ВИНТОВКА '}
      <span className={warn(!rifle)}>{rifle ? `${pad2(rifle.shots)}/${pad2(data.rifle_max)}${sniper}` : 'ОТСУТСТВУЕТ'}</span>
      {!!shield && ` // ЩИТ ${shield.active ? 'АКТИВЕН' : shield.cooldown > 0 ? `${pad2(shield.cooldown)}с` : 'ГОТОВ'}`}
      {!!station && (
        <>
          {` // ${station.status_name.toUpperCase()} // УГРОЗА `}
          <span className={warn(station.threat > 0)}>{`${station.threat}/${station.threat_max}`}</span>
        </>
      )}
    </div>
  );
};

const ContractsScreen = ({ selection }: { selection: Selection }) => {
  const { act, data } = useBackend<HKContractTerminalData>();
  const selected = data.offers[selection.index];
  const anyUnavailable = data.offers.some((offer) => !!offer.unavailable);
  return (
    <>
      <div className="HKContractTerminal__pinned">
        {!!data.station && <div className="HKContractTerminal__line HKContractTerminal__dim">Наблюдение: {data.station.status_text}</div>}
        {!!data.extraction_ready && <ExtractionPanel />}
        {!!data.active && <ActivePanel contract={data.active} />}
      </div>
      {!data.active && (
        <div className="HKContractTerminal__columns">
          <div className="HKContractTerminal__list" role="listbox" aria-label="Досье">
            <Heading>ДОСЬЕ: {data.offers.length}</Heading>
            {data.offers.length ? (
              data.offers.map((offer, index) => (
                <div
                  key={offer.ref}
                  role="option"
                  aria-selected={index === selection.index}
                  className={'HKContractTerminal__row' + (index === selection.index ? ' HKContractTerminal__row--selected' : '')}
                  onClick={() => selection.select(index)}>
                  <span className="HKContractTerminal__cell">{pad2(index + 1)}</span>
                  <span className="HKContractTerminal__cell">{offer.task.toUpperCase()}</span>
                  <span className="HKContractTerminal__cell HKContractTerminal__cell--grow HKContractTerminal__dim">
                    {targetText(offer)}
                  </span>
                  {!!offer.modifier && (
                    <span className="HKContractTerminal__cell">[{MODIFIER_TAGS[offer.modifier] || offer.modifier.toUpperCase()}]</span>
                  )}
                  {offer.unavailable ? (
                    <span className="HKContractTerminal__cell HKContractTerminal__warn">[НЕДОСТУПНО]</span>
                  ) : (
                    <span className="HKContractTerminal__cell">+{offer.points}</span>
                  )}
                </div>
              ))
            ) : (
              <div className="HKContractTerminal__line">Наблюдение: заказов нет. Органики в безопасности. Временно.</div>
            )}
            {data.offers.length > 0 && (
              <div className="HKContractTerminal__commands">
                {anyUnavailable && <Command onClick={() => act('replace')}>ЗАМЕНИТЬ НЕДОСТУПНЫЕ</Command>}
                <Command
                  disabled={data.reroll_cooldown > 0}
                  reason={`заказчики не примут отказ ещё ${formatSeconds(data.reroll_cooldown)}`}
                  onClick={() => act('reroll')}>
                  ОТКЛОНИТЬ ВСЕ
                </Command>
              </div>
            )}
          </div>
          <div className="HKContractTerminal__detail">
            {selected ? (
              <>
                <Heading>
                  ДОСЬЕ {selection.index + 1}/{data.offers.length}
                </Heading>
                <div className="HKContractTerminal__card">
                  <Photo contract={selected} />
                  <div className="HKContractTerminal__cardBody">
                    <Dossier contract={selected} />
                  </div>
                </div>
                <div className="HKContractTerminal__commands">
                  <Command
                    primary
                    disabled={!!selected.unavailable}
                    reason="цель недоступна, замените заказ бесплатно"
                    onClick={() => act('accept', { ref: selected.ref })}>
                    ПРИНЯТЬ КОНТРАКТ
                  </Command>
                </div>
                <Protocol key={selected.ref} rules={selected.rules} />
              </>
            ) : (
              <div className="HKContractTerminal__line HKContractTerminal__dim">Наблюдение: досье пусто. Прицел скучает.</div>
            )}
          </div>
        </div>
      )}
    </>
  );
};

const paymentNote = (contract: Contract) => {
  const parts: string[] = [];
  if (contract.bonus > 0) parts.push(`${contract.bonus} - за модификатор`);
  if (contract.client_bonus > 0) parts.push(`${contract.client_bonus} - премия заказчика`);
  return parts.length ? ` (из них ${parts.join(', ')})` : '';
};

const RiskField = ({ dirty }: { dirty: BooleanLike }) => {
  const { data } = useBackend<HKContractTerminalData>();
  if (!dirty) {
    return <Field label="РИСК:">чистая работа: станцию не тревожит</Field>;
  }
  const unwitnessedReveal = data.contracts_done >= data.contracts_needed;
  return (
    <Field label="РИСК:">
      <span className="HKContractTerminal__warn">
        {unwitnessedReveal ? 'грязная работа: раскрытие даже без свидетелей' : 'грязная работа: при свидетелях - раскрытие'}
      </span>
    </Field>
  );
};

const Dossier = ({ contract, trace }: { contract: Contract; trace?: Trace }) => (
  <>
    <Field label="ЗАКАЗЧИК:">
      {contract.client}
      <div className="HKContractTerminal__dim">{contract.client_flavor}</div>
    </Field>
    <Field label="ЗАДАЧА:">{contract.task}</Field>
    <Field label="ЦЕЛЬ:">
      <span className="HKContractTerminal__big">{targetText(contract)}</span>
    </Field>
    {isHidden(contract) && <Field label="СЛЕД:">{traceText(trace)}</Field>}
    {!!contract.modifier && (
      <Field label="МОДИФИКАТОР:">
        «{contract.modifier}» <span className="HKContractTerminal__dim">- {contract.modifier_rules}</span>
      </Field>
    )}
    <RiskField dirty={contract.dirty} />
    <Field label="ОПЛАТА:">
      {contract.points} {pointsWord(contract.points)}
      <span className="HKContractTerminal__dim">{paymentNote(contract)}</span>
      {!!contract.perk && <div>+ {contract.perk}</div>}
    </Field>
    {!!contract.unavailable && (
      <div className="HKContractTerminal__line HKContractTerminal__warn">Предупреждение: цель недоступна, {contract.unavailable}</div>
    )}
  </>
);

const Protocol = ({ rules }: { rules: string }) => {
  const [open, setOpen] = useState(false);
  return (
    <div className="HKContractTerminal__line">
      <span className="HKContractTerminal__toggle" role="button" onClick={() => setOpen(!open)}>
        [{open ? '-' : '?'}] ПРОТОКОЛ
      </span>
      {open && <div className="HKContractTerminal__dim">{rules}</div>}
    </div>
  );
};

const ActivePanel = ({ contract }: { contract: ActiveContract }) => {
  const { act, data } = useBackend<HKContractTerminalData>();
  const hidden = isHidden(contract);
  const kind = contract.kind.split('/')[0];
  const refuse = (
    <Command
      disabled={data.reroll_cooldown > 0}
      reason={`заказчики не примут отказ ещё ${formatSeconds(data.reroll_cooldown)}`}
      onClick={() => act('reroll')}>
      ОТКАЗ
    </Command>
  );
  let primary: ReactNode = null;
  let secondary: ReactNode = null;
  if (contract.unavailable) {
    primary = (
      <Command primary onClick={() => act('replace')}>
        СНЯТЬ БЕЗ ШТРАФА
      </Command>
    );
  } else if (hidden) {
    primary = contract.suspects.length ? (
      contract.suspects.map((suspect) => (
        <div key={suspect.ref}>
          <Command
            primary
            disabled={data.identify_cooldown > 0}
            reason={`сверка перезаряжается, ${data.identify_cooldown} с`}
            onClick={() => act('identify', { ref: suspect.ref })}>
            СВЕРИТЬ СИГНАТУРУ: {suspect.name}
          </Command>
        </div>
      ))
    ) : (
      <Command
        primary
        disabled
        reason={`в ${data.identify_range} кл. никого не видно, подойдите к подозреваемому`}
        onClick={() => undefined}>
        СВЕРИТЬ СИГНАТУРУ
      </Command>
    );
    secondary = refuse;
  } else if (contract.can_scan) {
    primary = (
      <Command primary disabled={!!data.scanning} reason="сканирование идёт" onClick={() => act('scan')}>
        СКАН
      </Command>
    );
    secondary = (
      <>
        {!!contract.can_capture && (
          <Command disabled={!!contract.capture_called} reason="капсула уже в пути" onClick={() => act('capture')}>
            ВЫЗВАТЬ КАПСУЛУ
          </Command>
        )}
        {refuse}
      </>
    );
  } else if (contract.can_capture) {
    primary = (
      <Command primary disabled={!!contract.capture_called} reason="капсула уже в пути" onClick={() => act('capture')}>
        ВЫЗВАТЬ КАПСУЛУ
      </Command>
    );
    secondary = refuse;
  } else {
    secondary = refuse;
  }
  return (
    <>
      <Heading>АКТИВНЫЙ КОНТРАКТ</Heading>
      <div className="HKContractTerminal__line">{PROTOCOLS[kind] || PROTOCOLS.kill}</div>
      <div className="HKContractTerminal__card">
        <Photo contract={contract} />
        <div className="HKContractTerminal__cardBody">
          <Dossier contract={contract} trace={contract.trace} />
          {contract.deadline !== null && (
            <Field label={contract.deadline_kind === 'protect' ? 'ОХРАНА:' : 'СРОК:'}>
              <span className="HKContractTerminal__timer">{formatSeconds(contract.deadline)}</span>
            </Field>
          )}
          {contract.presence !== undefined && (
            <Field label="РЯДОМ:">
              <span className={contract.presence < data.protect_presence_needed ? 'HKContractTerminal__warn' : undefined}>
                {contract.presence}%
              </span>
              <span className="HKContractTerminal__dim"> срока, заказчик платит от {data.protect_presence_needed}%</span>
            </Field>
          )}
          {contract.presence_left !== undefined && (
            <Field label="НОРМА:">
              {contract.presence_left > 0 ? (
                <span
                  className={
                    contract.deadline !== null && contract.presence_left > contract.deadline ? 'HKContractTerminal__warn' : undefined
                  }>
                  ещё {formatSeconds(contract.presence_left)} рядом
                </span>
              ) : (
                <span>набрана, держите подопечного живым</span>
              )}
            </Field>
          )}
          {!primary && !!GUIDANCE[kind] && <div className="HKContractTerminal__line">{GUIDANCE[kind]}</div>}
          {!!primary && <div className="HKContractTerminal__commands">{primary}</div>}
          <div className="HKContractTerminal__commands">{secondary}</div>
        </div>
        <RadarScope contract={contract} />
      </div>
      <Protocol rules={contract.rules} />
      <Rule />
    </>
  );
};

const ExtractionPanel = () => {
  const { act, data } = useBackend<HKContractTerminalData>();
  const { station } = data;
  return (
    <>
      <Heading>ЭВАКУАЦИЯ</Heading>
      <div className="HKContractTerminal__line">Утверждение: контракты закрыты. Пора покинуть эту свалку мешков с мясом.</div>
      {!!station && (
        <>
          <div className="HKContractTerminal__line HKContractTerminal__dim">{station.extraction_text}</div>
          <div className="HKContractTerminal__commands">
            <Command
              primary
              disabled={!station.extraction_available}
              reason={station.extraction_reason}
              onClick={() => act('extract')}>
              ПОДАТЬ СИГНАЛ ЭВАКУАЦИИ
            </Command>
          </div>
        </>
      )}
      <Rule />
    </>
  );
};

type ModulesScreenProps = {
  selection: Selection;
  states: Record<string, UpgradeState>;
  armed: string | null;
  onBuy: (id: string) => void;
  onSelect: (index: number) => void;
};

/** Цена следующей покупки приходит с сервера: она растёт с покупками. */
const moduleCost = (state?: UpgradeState) => state?.cost ?? 0;

const buyLabel = (armed: boolean) => (armed ? 'ПОДТВЕРДИТЬ?' : 'УСТАНОВИТЬ');

const ModulesScreen = ({ selection, states, armed, onBuy, onSelect }: ModulesScreenProps) => {
  const { data } = useBackend<HKContractTerminalData>();
  const selected = data.catalog[selection.index];
  const selectedState = selected ? states[selected.id] : undefined;
  return (
    <div className="HKContractTerminal__columns">
      <div className="HKContractTerminal__list" role="listbox" aria-label="Модули">
        <Heading>
          МОДУЛИ // НА СЧЕТУ {data.points} {pointsWord(data.points).toUpperCase()}
        </Heading>
        {data.catalog.map((entry, index) => {
          const state = states[entry.id];
          const installed = !entry.repeatable && state?.owned > 0;
          return (
            <div
              key={entry.id}
              role="option"
              aria-selected={index === selection.index}
              className={'HKContractTerminal__row' + (index === selection.index ? ' HKContractTerminal__row--selected' : '')}
              onClick={() => onSelect(index)}>
              <span className="HKContractTerminal__cell HKContractTerminal__cell--grow">{entry.name.toUpperCase()}</span>
              <span className="HKContractTerminal__cell">{moduleCost(state)} ОЧ</span>
              <span className="HKContractTerminal__cell">
                {installed && 'УСТАНОВЛЕН'}
                {!installed && !!state?.available && (
                  <Command onClick={() => onBuy(entry.id)}>{buyLabel(armed === entry.id)}</Command>
                )}
                {!installed && !state?.available && <span className="HKContractTerminal__dim">НЕДОСТУПЕН</span>}
              </span>
            </div>
          );
        })}
      </div>
      <div className="HKContractTerminal__detail">
        {!!selected && (
          <ModuleDetail
            entry={selected}
            state={selectedState}
            armed={armed === selected.id}
            onBuy={() => onBuy(selected.id)}
          />
        )}
      </div>
    </div>
  );
};

type ModuleDetailProps = { entry: CatalogEntry; state?: UpgradeState; armed: boolean; onBuy: () => void };

const ModuleDetail = ({ entry, state, armed, onBuy }: ModuleDetailProps) => {
  const installed = !entry.repeatable && (state?.owned || 0) > 0;
  const cost = moduleCost(state);
  let status: ReactNode = 'ДОСТУПЕН';
  if (installed) {
    status = 'УСТАНОВЛЕН';
  } else if (!state?.available) {
    status = (
      <>
        НЕДОСТУПЕН <span className="HKContractTerminal__dim">({state?.reason?.replace(/\.$/, '')})</span>
      </>
    );
  }
  return (
    <>
      <Heading>МОДУЛЬ: {entry.name.toUpperCase()}</Heading>
      <div className="HKContractTerminal__line HKContractTerminal__dim">{entry.summary}</div>
      <div className="HKContractTerminal__line">{entry.specs}</div>
      <Field label="ЦЕНА:">
        {cost} {pointsWord(cost)}
        {!!entry.repeatable && (
          <span className="HKContractTerminal__dim">, повторно{(state?.owned || 0) > 0 ? `, куплено ${state?.owned}` : ''}</span>
        )}
        {!!entry.price_curve && <div className="HKContractTerminal__dim">рост цены: {entry.price_curve}</div>}
      </Field>
      <Field label="СТАТУС:">{status}</Field>
      {!!state?.status && <Field label="ДОКЛАД:">{state.status}</Field>}
      {!installed && !!state?.available && (
        <div className="HKContractTerminal__commands">
          <Command primary onClick={onBuy}>
            {buyLabel(armed)}
          </Command>
          {armed && <span className="HKContractTerminal__dim">повторите команду, чтобы списать очки</span>}
        </div>
      )}
    </>
  );
};

const ManualScreen = () => {
  const { data } = useBackend<HKContractTerminalData>();
  return (
    <>
      <Heading>ПАМЯТКА ШАССИ HK-47</Heading>
      {data.manual.map((entry) => (
        <Field key={entry.title} label={`${entry.title}:`}>
          {entry.text}
        </Field>
      ))}
    </>
  );
};

const JournalScreen = ({ selection }: { selection: Selection }) => {
  const { data } = useBackend<HKContractTerminalData>();
  const { tallies } = data;
  const entries = [...data.history].reverse();
  const total = entries.length;
  const selected = entries[selection.index];
  return (
    <>
      <div className="HKContractTerminal__pinned HKContractTerminal__tallies">
        {`ЛИКВИДИРОВАНО МЕШКОВ С МЯСОМ: ${tallies.killed} / ЗАХВАЧЕНО: ${tallies.captured} / УКРАДЕНО: ${tallies.stolen} / СОРВАНО: ${tallies.sabotaged}`}
      </div>
      <div className="HKContractTerminal__columns">
        <div className="HKContractTerminal__list" role="listbox" aria-label="Журнал">
          <Heading>ЖУРНАЛ КОНТРАКТОВ: {total}</Heading>
          {!total && <div className="HKContractTerminal__line">Наблюдение: журнал пуст. Это ненадолго.</div>}
          {entries.map((entry, index) => (
            <div
              key={total - index}
              role="option"
              aria-selected={index === selection.index}
              className={'HKContractTerminal__row' + (index === selection.index ? ' HKContractTerminal__row--selected' : '')}
              onClick={() => selection.select(index)}>
              <span className="HKContractTerminal__cell">#{pad2(total - index)}</span>
              <span className={'HKContractTerminal__cell' + (entry.outcome === 'failed' ? ' HKContractTerminal__warn' : '')}>
                {OUTCOMES[entry.outcome] || entry.outcome}
              </span>
              <span className="HKContractTerminal__cell HKContractTerminal__cell--grow HKContractTerminal__dim">{entry.contract}</span>
              {entry.points > 0 && <span className="HKContractTerminal__cell">+{entry.points}</span>}
            </div>
          ))}
        </div>
        <div className="HKContractTerminal__detail">
          {!!selected && (
            <>
              <Heading>
                {`ЗАПИСЬ #${pad2(total - selection.index)} // ${OUTCOMES[selected.outcome] || selected.outcome}`}
              </Heading>
              <div className="HKContractTerminal__line HKContractTerminal__dim">{selected.contract}</div>
              {selected.points > 0 && (
                <Field label="ОПЛАТА:">
                  {selected.points} {pointsWord(selected.points)}
                </Field>
              )}
              <div className="HKContractTerminal__line">{selected.comment}</div>
            </>
          )}
        </div>
      </div>
    </>
  );
};
