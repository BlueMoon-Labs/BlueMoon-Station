import { BooleanLike } from 'common/react';
import { decodeHtmlEntities } from 'common/string';
import { CSSProperties, ReactNode, useEffect, useMemo, useRef, useState } from 'react';

import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Window } from '../layouts';
import { sanitizeText } from '../sanitize';
import { HereticBookAtmosphere } from './HereticBookAtmosphere';
import { HereticBookPreferences, useBookPresentation } from './HereticBookPreferences';
import { Headpiece, HereticIllumination, HereticPageOrnament, Manicule, RitualDiagram, Tailpiece } from './HereticIllumination';

type HereticPath = {
  id: string;
  name: string;
  desc: string;
  tagline?: string | null;
  craft?: string | null;
  capture?: string | null;
  escape?: string | null;
  strength_points?: string[];
  weakness_points?: string[];
  practice?: string | null;
  strengths: string[];
  weaknesses: string[];
  innate_name?: string;
  innate_desc?: string;
};

type Knowledge = {
  id: string;
  name: string;
  desc: string;
  summary?: string | null;
  details?: string[];
  role?: string | null;
  flavour: string;
  cost: number;
  sacrifices: number;
  path: string;
  stage: number;
  known: BooleanLike;
  available: BooleanLike;
  reason: string;
  kind: 'path' | 'side' | 'start';
  starter_armor?: BooleanLike;
  passive_description?: string;
  passive?: PassiveUpgrade;
};

type PassiveUpgrade = {
  level: number;
  max_level: number;
  cost: number;
  available: BooleanLike;
  reason: string | null;
  description: string;
};

type Ritual = {
  id: string;
  name: string;
  desc: string;
  ingredients: { name: string; amount: number }[];
  result?: string | null;
  hint?: string;
  hints?: string[];
  duration?: number;
  ascension: BooleanLike;
};

type CombatAbility = { id: string; name: string; summary?: string | null; desc: string; usage: string; hotkey?: string | null };

type Preparation = {
  blade_ready: BooleanLike;
  blade_status: string;
  armor_ready: BooleanLike;
  armor_status: string;
  heart: { ready: BooleanLike; can_call: BooleanLike; status: string; action_label: string };
};

export type ForbiddenLoreData = {
  points: number;
  side_points?: number;
  total_sacrifices: number;
  ascended: BooleanLike;
  selected_path: string | null;
  path_stage: number;
  paths: HereticPath[];
  knowledge: Knowledge[];
  rituals: Ritual[];
  knowledge_state?: Record<string, Pick<Knowledge, 'known' | 'available' | 'reason'>>;
  passive_upgrades?: Record<string, PassiveUpgrade>;
  book?: {
    name: string;
    title: string;
    subtitle: string;
    path: string | null;
    cover_state: string;
    page_sound?: string;
  };
  combat_resource: { name: string; value: number; max: number; description: string; rules?: string[]; state?: string } | null;
  combat_abilities?: CombatAbility[];
  ability_hotkey_help?: string;
  preparation?: Preparation | null;
  deed: { name: string; desc: string; hint: string; next_step?: string; combat_hint?: string; combat_available?: BooleanLike; tier: number; max_tier: number; progress: number; goal: number; counted: number } | null;
  hunt: {
    target_name: string | null;
    target_role: string | null;
    target_status: string;
    can_retarget: BooleanLike;
    retarget_seconds: number;
    sacrifices_required: number;
    deed_tiers?: number;
    ascension_bodies?: number;
    influences_harvested: number;
    influence_limit: number;
    influence_initial_count?: number;
    influence_interval_minutes?: number;
    pocket: { duration: number; warning: number; pull: number; tear: number; cooldown: number; hold: number; grip: number; shake: number };
  };
};

const useLoreBackend = () => {
  const backend = useBackend<ForbiddenLoreData>();
  const { data } = backend;
  if (!data.knowledge_state && !data.passive_upgrades) return backend;
  return {
    ...backend,
    data: {
      ...data,
      knowledge: data.knowledge.map((knowledge) => ({
        ...knowledge,
        ...data.knowledge_state?.[knowledge.id],
        passive: data.passive_upgrades?.[knowledge.id],
      })),
    },
  };
};

const chapters = ['Путь', 'Знания', 'Ритуалы', 'Охота', 'Помощь'] as const;
type Chapter = typeof chapters[number];
const numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI'];
const bookTitles: Record<string, string> = {
  Unbound: 'Кодекс Рубцов', Ash: 'Псалтирь последнего огня', Rust: 'Железный завет',
  Flesh: 'Анатомия голода', Void: 'Палимпсест зимы', Blade: 'Трактат о последнем ударе',
  Moon: 'Зерцало без лица', Cosmic: 'Атлас внутреннего неба',
  Lock: 'Каталог невозможных дверей', Tide: 'Лоция бездонного моря',
  Glass: 'Евангелие разбитого света', Blood: 'Служебник алой десятины',
  Echo: 'Партитура последнего голоса',
  Sand: 'Хроника истёкшего часа', Wax: 'Служба негаснущей свечи',
  Spirit: 'Список непришедших', Dance: 'Партитура бала без конца',
};

export const roleLabels: Record<string, string> = {
  craft: 'ремесло',
  capture: 'захват',
  escape: 'уход',
  attack: 'атака',
  control: 'контроль',
  defense: 'защита',
  support: 'усиление',
  passive: 'пассивка',
  relic: 'реликвия',
  mark: 'метка',
  grasp: 'хватка',
  ritual: 'обряд',
  ascension: 'вознесение',
};

type HelpTopicId = 'start' | 'path' | 'rifts' | 'hunt' | 'pocket' | 'mansus' | 'custody' | 'ascension' | 'deed' | 'hotkeys';

const countNoun = (amount: number, forms: [string, string, string]) => {
  const count = Math.abs(amount) % 100;
  if (count >= 11 && count <= 14) return forms[2];
  if (count % 10 === 1) return forms[0];
  if (count % 10 >= 2 && count % 10 <= 4) return forms[1];
  return forms[2];
};

const pointsText = (amount: number) => `${amount} ${countNoun(amount, ['очко', 'очка', 'очков'])}`;
const numeral = (value: number) => numerals[value - 1] || String(value);
const chapterFolios: Record<Chapter, number> = { Путь: 2, Знания: 34, Ритуалы: 96, Охота: 152, Помощь: 168 };
const folio = (chapter: Chapter, index = 0) => chapterFolios[chapter] + Math.max(0, index) * 2;

const fontRanges = {
  cyr: 'U+0301, U+0400-045F, U+0490-0491, U+04B0-04B1, U+2116',
  lat: 'U+0000-00FF, U+0131, U+0152-0153, U+02BB-02BC, U+02C6, U+02DA, U+02DC, U+0304, U+0308, U+0329, U+2000-206F, U+20AC, U+2122, U+2191, U+2193, U+2212, U+2215, U+FEFF, U+FFFD',
};
const bookFontFaces = () => (['roman', 'italic'] as const).flatMap((style) => (['cyr', 'lat'] as const).map((subset) => (
  `@font-face{font-family:'Heretic Garamond';font-style:${style === 'roman' ? 'normal' : 'italic'};font-weight:400 800;font-display:swap;`
  + `src:url("${resolveAsset(`heretic-garamond-${style}-${subset}.woff2`)}") format("woff2");unicode-range:${fontRanges[subset]}}`
))).join('');

const plainText = (text?: string | null) => decodeHtmlEntities(sanitizeText((text || '').replace(/<br\s*\/?>/gi, '\n'), false, []));

const InfluenceSchedule = ({ hunt }: { hunt: ForbiddenLoreData['hunt'] }) => {
  const initial = hunt.influence_initial_count ?? 3;
  const interval = hunt.influence_interval_minutes ?? 8;
  return <p>В начале раунда открыто {initial} {countNoun(initial, ['разлом', 'разлома', 'разломов'])}, потом каждые {interval} мин. проступает ещё один.</p>;
};

const LoreText = ({ text, className = '' }: { text: string; className?: string }) => (
  <div className={`HereticBook__prose ${className}`}>{plainText(text)}</div>
);

const Kicker = ({ children }: { children: ReactNode }) => <p className="HereticBook__kicker">{children}</p>;

const EntryHead = ({ kicker, title, notes, epigraph }: { kicker?: ReactNode; title: string; notes?: ReactNode; epigraph?: string | null }) => (
  <header className="HereticBook__entryHead">
    <Headpiece />
    {!!kicker && <Kicker>{kicker}</Kicker>}
    <h2 className="HereticBook__entryTitle">{title}</h2>
    {(!!notes || !!epigraph) && (
      <div className={`HereticBook__entryMeta${epigraph ? '' : ' HereticBook__entryMeta--solo'}`}>
        {!!notes && <aside className="HereticBook__marginalia" aria-label="Пометки на полях">{notes}</aside>}
        {!!epigraph && <blockquote className="HereticBook__epigraph"><LoreText text={epigraph} /></blockquote>}
      </div>
    )}
  </header>
);

const Facts = ({ lines, label }: { lines: string[]; label?: string }) => (
  <ul className="HereticBook__facts" aria-label={label}>
    {lines.map((line, index) => <li key={`${index}-${line}`}>{plainText(line)}</li>)}
  </ul>
);

const markShapes = {
  seal: <><circle cx="8" cy="8" r="6" /><circle className="HereticBook__markCore" cx="8" cy="8" r="2.6" /></>,
  soul: <path className="HereticBook__markCore" d="M8 1.5c1 3.4 4.6 5.6 4.6 9.2a4.6 4.6 0 0 1-9.2 0c0-2.6 1.6-4.4 2.6-6.2.2 1.8.9 2.8 1.9 3.1-.3-2.4 0-4.2.1-6.1Z" />,
};

/** Зарубки запаса, печати ступеней дела, огоньки принятых душ. */
const Marks = ({ total, filled, label, kind = 'tally', className = '' }: { total: number; filled: number; label: string; kind?: 'tally' | 'seal' | 'soul'; className?: string }) => (
  <span className={`HereticBook__marks HereticBook__marks--${kind} ${className}`} role="img" aria-label={label}>
    {Array.from({ length: Math.max(0, total) }, (_, index) => kind === 'tally'
      ? <i key={index} className={index < filled ? 'HereticBook__mark--on' : undefined} />
      : <svg key={index} className={index < filled ? 'HereticBook__mark--on' : undefined} viewBox="0 0 16 16" aria-hidden="true">{markShapes[kind]}</svg>)}
  </span>
);

const prepIcons: Record<string, ReactNode> = {
  Клинок: <path d="M4 16 15.5 4.5 17 3l-.6 2.1L5 16.4M3 12.5l4.5 4.5M2.2 17.8l2-2" />,
  Броня: <path d="M10 2.5c-3.6 0-5.6 3.6-5.6 7.4v7.6h11.2V9.9c0-3.8-2-7.4-5.6-7.4ZM7.4 10.5c0-2.2 1.1-3.8 2.6-3.8s2.6 1.6 2.6 3.8v1.8H7.4Z" />,
  Сердце: <path d="M10 17C4.4 13.2 2.4 10.3 2.4 7.3a3.8 3.8 0 0 1 7.6-.9 3.8 3.8 0 0 1 7.6.9c0 3-2 5.9-7.6 9.7Z" />,
};

const PrepIcon = ({ name }: { name: string }) => (
  <svg className="HereticBook__prepIcon" viewBox="0 0 20 20" fill="none" stroke="currentColor" strokeWidth="1.3" strokeLinejoin="round" strokeLinecap="round" aria-hidden="true">{prepIcons[name]}</svg>
);

const PathChoiceButton = ({ disabled, onConfirm }: { disabled: boolean; onConfirm: () => void }) => {
  const [armed, setArmed] = useState(false);
  const ref = useRef<HTMLButtonElement>(null);
  useEffect(() => {
    if (!armed) return;
    const disarm = (event: MouseEvent) => {
      if (!ref.current?.contains(event.target as Node)) setArmed(false);
    };
    window.addEventListener('click', disarm);
    return () => window.removeEventListener('click', disarm);
  }, [armed]);
  return (
    <button
      type="button"
      ref={ref}
      className={`HereticBook__seal${armed ? ' HereticBook__seal--armed' : ''}`}
      disabled={disabled}
      onClick={() => {
        if (!armed) {
          setArmed(true);
          return;
        }
        setArmed(false);
        onConfirm();
      }}
    >
      {armed ? 'Ещё раз, и пути назад не будет' : 'Принять этот путь'}
    </button>
  );
};

const ResearchButton = ({ knowledge }: { knowledge: Knowledge }) => {
  const { data, act } = useLoreBackend();
  if (knowledge.known) return null;
  const choosesPath = !data.selected_path && knowledge.kind === 'path'
    && data.paths.some((path) => path.id === knowledge.path)
    && !data.knowledge.some((other) => other.kind === 'path'
      && other.path === knowledge.path && other.stage < knowledge.stage);
  const availablePoints = data.points + (knowledge.kind === 'side' ? data.side_points || 0 : 0);
  const disabled = !knowledge.available || knowledge.cost > availablePoints;
  return (
    <div className="HereticBook__action">
      {!disabled && <Manicule />}
      {choosesPath ? (
        <PathChoiceButton key={knowledge.id} disabled={disabled} onConfirm={() => act('research', { id: knowledge.id })} />
      ) : (
        <button type="button" className="HereticBook__seal" disabled={disabled} onClick={() => act('research', { id: knowledge.id })}>
          {knowledge.cost ? `Изучить за ${pointsText(knowledge.cost)}` : 'Изучить даром'}
        </button>
      )}
      {disabled && (
        <p className="HereticBook__note" role="status">
          {knowledge.reason || (knowledge.cost > availablePoints
            ? `Не хватает знаний: нужно ${pointsText(knowledge.cost)}.`
            : 'Сначала изучите предыдущую ступень пути.')}
        </p>
      )}
    </div>
  );
};

const PassiveUpgradeButton = ({ knowledge }: { knowledge: Knowledge }) => {
  const { data, act } = useLoreBackend();
  const passive = knowledge.passive;
  if (!knowledge.known || !passive) return null;
  if (passive.level >= passive.max_level) return <p className="HereticBook__note">Пассивка раскрыта полностью.</p>;
  const canAfford = data.points + (data.side_points || 0) >= passive.cost;
  return (
    <div className="HereticBook__action">
      <button
        type="button"
        className="HereticBook__seal HereticBook__seal--quiet"
        disabled={!passive.available || !canAfford}
        onClick={() => act('upgrade_passive', { id: knowledge.id, level: passive.level })}
      >
        Усилить до {numeral(passive.level + 1)} за {pointsText(passive.cost)}
      </button>
      <p className="HereticBook__note" role="status">
        {passive.reason || (!canAfford ? `Не хватает знаний: нужно ${pointsText(passive.cost)}.`
          : 'Второй уровень стоит 1 очко, третий - 2. Сначала уходят побочные очки.')}
      </p>
    </div>
  );
};

const PassiveDetails = ({ knowledge }: { knowledge: Knowledge }) => {
  const passive = knowledge.passive;
  if (!passive && !knowledge.passive_description) return null;
  return (
    <section className="HereticBook__section" aria-label="Пассивка">
      <h3>Пассивка{passive ? `, уровень ${passive.level} из ${passive.max_level}` : ''}</h3>
      <LoreText text={passive?.description || knowledge.passive_description || ''} />
      {passive ? <PassiveUpgradeButton knowledge={knowledge} /> : <p className="HereticBook__note">Усиливать её можно после изучения.</p>}
    </section>
  );
};

/** Пометки на полях: роль, цена и состояние записи, как карандашом сбоку от текста. */
const KnowledgeNotes = ({ knowledge }: { knowledge: Knowledge }) => (
  <>
    {knowledge.kind === 'path' && <span className="HereticBook__marginNumeral">{numeral(knowledge.stage)}</span>}
    {!!knowledge.role && !!roleLabels[knowledge.role] && <span>{roleLabels[knowledge.role]}</span>}
    {!knowledge.passive && <span>{knowledge.cost ? pointsText(knowledge.cost) : 'даром'}</span>}
    <span className={`HereticBook__marginState HereticBook__marginState--${knowledge.known ? 'known' : knowledge.available ? 'open' : 'locked'}`}>{knowledge.known ? 'изучено' : knowledge.available ? 'доступно' : 'закрыто'}</span>
  </>
);

const KnowledgeConditions = ({ knowledge, showStage = false }: { knowledge: Knowledge; showStage?: boolean }) => {
  const opensAt = knowledge.kind === 'side' || showStage ? knowledge.stage : 0;
  const parts: string[] = [];
  if (knowledge.sacrifices > 0) parts.push(`нужно жертв: ${knowledge.sacrifices}`);
  if (opensAt > 0) parts.push(`открывается на ступени ${numeral(opensAt)}`);
  if (!parts.length) return null;
  const text = parts.join(', ');
  return <p className="HereticBook__note">{text[0].toUpperCase() + text.slice(1)}.</p>;
};

const RitualRecipe = ({ ritual }: { ritual: Ritual }) => (
  <section className="HereticBook__section" aria-label="Компоненты обряда">
    <h3>Положить на руну</h3>
    <ul className="HereticBook__ingredients">
      {ritual.ingredients.map((item, index) => <li key={`${item.name}-${index}`}><span>{item.name}</span><span className="HereticBook__leader" /><span className="HereticBook__amount">{item.amount}</span></li>)}
    </ul>
    {!!ritual.result && <p className="HereticBook__result">Итог обряда: <strong>{ritual.result}</strong></p>}
    {ritual.hints?.length ? <Facts lines={ritual.hints} /> : ritual.hint ? <LoreText text={ritual.hint} /> : null}
    {ritual.duration !== undefined && <p className="HereticBook__note">Обряд длится {ritual.duration} сек.</p>}
  </section>
);

const Page = ({ side, chapter, children, entryId, head, number }: { side: 'left' | 'right'; chapter: Chapter; children: ReactNode; entryId?: string; head?: ReactNode; number?: number }) => {
  const { data } = useLoreBackend();
  const scrollRef = useRef<HTMLDivElement>(null);
  const writingRef = useRef<HTMLDivElement>(null);
  const previousEntry = useRef(entryId);
  const [fade, setFade] = useState('');
  const measureScroll = () => {
    const page = scrollRef.current;
    if (!page) return;
    const above = page.scrollTop > 2;
    const below = page.scrollTop + page.clientHeight < page.scrollHeight - 2;
    const next = above && below ? 'both' : above ? 'above' : below ? 'below' : '';
    setFade((previous) => previous === next ? previous : next);
  };
  useEffect(() => {
    measureScroll();
    if (typeof ResizeObserver === 'undefined') return;
    const observer = new ResizeObserver(measureScroll);
    if (scrollRef.current) observer.observe(scrollRef.current);
    if (writingRef.current) observer.observe(writingRef.current);
    return () => observer.disconnect();
  }, []);
  useEffect(() => {
    if (previousEntry.current === entryId) return;
    previousEntry.current = entryId;
    const scroll = scrollRef.current;
    if (!scroll) return;
    scroll.scrollTop = 0;
    const page = scroll.closest('article');
    if (page) page.scrollTop = 0;
    if (window.matchMedia?.('(max-width: 600px)').matches
      && document.activeElement?.closest('.HereticBook__line, .HereticBook__oath, .HereticBook__link')) {
      scroll.scrollIntoView({ block: 'start', inline: 'nearest' });
    }
    measureScroll();
  }, [entryId]);
  return (
    <article className={`HereticBook__page HereticBook__page--${side}`} aria-label={side === 'left' ? 'Левая страница' : 'Правая страница'}>
      <HereticPageOrnament path={data.book?.path || data.selected_path || 'Unbound'} />
      <div className="HereticBook__pageBody">
        <header className="HereticBook__runningHead">{head ?? (side === 'left' ? data.book?.title || bookTitles[data.selected_path || 'Unbound'] : chapter)}</header>
        <div className="HereticBook__pageScroll" data-fade={fade || undefined} ref={scrollRef} onScroll={measureScroll} tabIndex={0} aria-label={side === 'left' ? 'Текст левой страницы' : 'Текст правой страницы'}>
          <div ref={writingRef}><div key={entryId} className="HereticBook__ink">{children}</div></div>
        </div>
        <footer className="HereticBook__folio"><span>{number ?? folio(chapter) + (side === 'left' ? 0 : 1)}</span></footer>
      </div>
    </article>
  );
};

/* Путь */

const PathAnatomy = ({ path }: { path: HereticPath }) => {
  const rows = [['Ремесло', path.craft], ['Захват', path.capture], ['Уход', path.escape]].filter(([, text]) => !!text);
  if (!rows.length) return null;
  return (
    <section className="HereticBook__anatomy" aria-label="Ремесло, захват и уход">
      {rows.map(([label, text]) => <p key={label}><b className="HereticBook__runIn">{label}.</b> {plainText(text)}</p>)}
    </section>
  );
};

const PathTraits = ({ title, points, fallback, tone }: { title: string; points?: string[]; fallback: string[]; tone: 'plus' | 'minus' }) => {
  const lines = points?.length ? points : fallback.filter((text) => !!text);
  if (!lines.length) return null;
  return (
    <section className={`HereticBook__section HereticBook__traits HereticBook__traits--${tone}`} aria-label={title}>
      <h3>{title}</h3>
      <Facts lines={lines} />
    </section>
  );
};

const PathChapter = ({ turn, openKnowledge }: { turn: () => void; openKnowledge: () => void }) => {
  const { data } = useLoreBackend();
  const [previewId, setPreviewId] = useState(data.selected_path || data.paths[0]?.id);
  const path = data.paths.find((entry) => entry.id === previewId) || data.paths[0];
  const skin = data.selected_path || 'Unbound';
  const stages = data.knowledge.filter((entry) => entry.kind === 'path' && entry.path === path?.id)
    .sort((a, b) => a.stage - b.stage);
  return (
    <>
      <Page side="left" chapter="Путь" head="Титульный лист" number={folio('Путь')}>
        <div className="HereticBook__titlePage">
          <p className="HereticBook__motto">{data.book?.subtitle || 'Пути Мансуса'}</p>
          <h1 className="HereticBook__bookTitle">{data.book?.title || bookTitles[skin] || bookTitles.Unbound}</h1>
          {data.book?.name && data.book.name !== data.book.title && <p className="HereticBook__latinTitle" lang="la">{data.book.name}</p>}
          <div className="HereticBook__titleRule" aria-hidden="true" />
        </div>
        <nav className="HereticBook__oaths" aria-label="Пути Мансуса">
          {data.paths.map((entry, index) => (
            <button
              type="button"
              key={entry.id}
              className={`HereticBook__oath HereticBook__oath--${entry.id}`}
              aria-label={entry.name}
              aria-pressed={entry.id === path?.id}
              onClick={() => { if (entry.id !== path?.id) { setPreviewId(entry.id); turn(); } }}
            >
              <span className="HereticBook__oathNumber" aria-hidden="true">{numeral(index + 1)}</span>
              <span className="HereticBook__oathName">{entry.name}</span>
              {entry.id === data.selected_path && <svg className="HereticBook__signed" viewBox="0 0 16 16" role="img" aria-label="Выбранный путь"><path d="M8 1.6 9.6 3l2.1-.3.6 2 1.9 1-.7 2 .7 2-1.9 1-.6 2-2.1-.3L8 14.4 6.4 13l-2.1.3-.6-2-1.9-1 .7-2-.7-2 1.9-1 .6-2L6.4 3Z" /><path d="m5.6 8.2 1.6 1.6 3.2-3.4" fill="none" /></svg>}
            </button>
          ))}
        </nav>
        <p className="HereticBook__note HereticBook__note--center">{data.selected_path
          ? 'Ваш путь уже выбран. Остальные можно только читать.'
          : 'Дорог много, завеса одна. Первая ступень даётся даром, но выбрать можно лишь однажды.'}
        </p>
      </Page>
      <Page side="right" chapter="Путь" entryId={path?.id} head={path ? path.name : 'Путь'} number={folio('Путь', data.paths.indexOf(path)) + 1}>
        {path ? (
          <>
            <figure className={`HereticBook__plate HereticBook__plate--${path.id}`}>
              <HereticIllumination path={path.id} />
              <figcaption><span className="HereticBook__plateNumber">Таблица {numeral(data.paths.indexOf(path) + 1)}</span>{path.name}</figcaption>
            </figure>
            <h2 className="HereticBook__entryTitle">{path.name}</h2>
            {path.tagline ? <p className="HereticBook__lead">{plainText(path.tagline)}</p> : <LoreText className="HereticBook__lead" text={path.desc} />}
            <PathAnatomy path={path} />
            {!data.selected_path && stages[0] && <ResearchButton knowledge={stages[0]} />}
            {data.selected_path === path.id && <button type="button" className="HereticBook__seal HereticBook__seal--quiet" onClick={openKnowledge}>К знаниям пути</button>}
            <PathTraits title="Сильные стороны" points={path.strength_points} fallback={path.strengths} tone="plus" />
            <PathTraits title="Слабые стороны" points={path.weakness_points} fallback={path.weaknesses} tone="minus" />
            {!!path.practice && <p className="HereticBook__aside"><b className="HereticBook__runIn">Совет.</b> {plainText(path.practice)}</p>}
            {path.innate_name && (
              <section className="HereticBook__section" aria-label="Врождённая черта">
                <h3>Врождённая черта: {path.innate_name}</h3>
                <p>{path.innate_desc}</p>
                <p className="HereticBook__note">Действует с выбора пути, без затрат знаний.</p>
              </section>
            )}
            {!data.selected_path && stages.length > 0 && (
              <details className="HereticBook__fold">
                <summary>Все ступени пути</summary>
                <ol className="HereticBook__stageList">
                  {stages.map((entry) => <li key={entry.id}><span className="HereticBook__lineNumber">{numeral(entry.stage)}</span><span>{entry.name}</span><span className="HereticBook__leader" /><span className="HereticBook__amount">{entry.cost}</span></li>)}
                </ol>
              </details>
            )}
            <Tailpiece />
          </>
        ) : <p>Нет доступных путей.</p>}
      </Page>
    </>
  );
};

/* Знания */

const KnowledgeEntry = ({ knowledge, recipe }: { knowledge: Knowledge; recipe?: Ritual }) => {
  const structured = !!knowledge.summary;
  return (
    <>
      <EntryHead
        kicker={knowledge.kind === 'side' ? 'Побочное знание' : knowledge.kind === 'start' ? 'Начальное знание' : `Ступень ${numeral(knowledge.stage)}`}
        title={knowledge.name}
        epigraph={knowledge.flavour}
        notes={<KnowledgeNotes knowledge={knowledge} />}
      />
      {structured && <p className="HereticBook__lead">{plainText(knowledge.summary)}</p>}
      <ResearchButton knowledge={knowledge} />
      {structured ? <Facts lines={knowledge.details || []} /> : <LoreText text={knowledge.desc} />}
      <KnowledgeConditions knowledge={knowledge} />
      <PassiveDetails knowledge={knowledge} />
      {knowledge.kind === 'side' && <p className="HereticBook__note">Побочное знание не двигает путь. Сначала оно берёт побочные очки, потом обычные.</p>}
      {recipe && <RitualRecipe ritual={recipe} />}
      <Tailpiece />
    </>
  );
};

const AbilityEntry = ({ ability }: { ability: CombatAbility }) => (
  <>
    <EntryHead kicker="Способность" title={ability.name} notes={ability.hotkey ? <><span>клавиша</span><kbd className="HereticBook__key">{ability.hotkey}</kbd></> : <span>без клавиши</span>} />
    {!!ability.summary && <p className="HereticBook__lead">{plainText(ability.summary)}</p>}
    <LoreText text={ability.desc} />
    <section className="HereticBook__section" aria-label="Как применить">
      <h3>Как применить</h3>
      <p>{ability.usage}</p>
    </section>
    <p className="HereticBook__note">Перезарядку показывает кнопка способности на экране.</p>
    <Tailpiece />
  </>
);

const ContentsGroup = ({ title, children }: { title: string; children: ReactNode }) => (
  <section className="HereticBook__group" aria-label={title}>
    <h3 className="HereticBook__groupTitle">{title}</h3>
    {children}
  </section>
);

const KnowledgeChapter = ({ turn, selectedId, select }: { turn: () => void; selectedId: string | null; select: (id: string | null) => void }) => {
  const { data } = useLoreBackend();
  const [selectedAbilityId, setSelectedAbilityId] = useState<string | null>(null);
  const abilities = data.combat_abilities || [];
  const selectedAbility = abilities.find((ability) => ability.id === selectedAbilityId);
  const selectKnowledge = (id: string) => { select(id); setSelectedAbilityId(null); turn(); };
  const main = data.knowledge.filter((entry) => entry.kind === 'path' && entry.path === data.selected_path)
    .sort((a, b) => a.stage - b.stage);
  const side = data.knowledge.filter((entry) => entry.kind === 'side')
    .sort((a, b) => a.stage - b.stage || a.cost - b.cost || a.name.localeCompare(b.name));
  const starting = data.knowledge.filter((entry) => entry.kind === 'start');
  const visible = [...main, ...side, ...starting];
  const selected = visible.find((entry) => entry.id === selectedId)
    || main.find((entry) => !entry.known) || visible.find((entry) => entry.available) || visible[0];
  const recipe = data.rituals.find((ritual) => ritual.id === selected?.id);
  useEffect(() => {
    if (selected && selected.id !== selectedId) select(selected.id);
  }, [selected?.id]);
  const line = (entry: Knowledge) => {
    const state = entry.known ? 'изучено' : entry.available ? 'доступно' : 'закрыто';
    return (
      <button
        type="button"
        key={entry.id}
        className={`HereticBook__line HereticBook__line--${entry.known ? 'known' : entry.available ? 'open' : 'locked'}`}
        aria-pressed={!selectedAbility && selected?.id === entry.id}
        aria-label={`${entry.name}, ${state}, ${entry.passive ? `пассивка ${entry.passive.level} из ${entry.passive.max_level}` : pointsText(entry.cost)}${entry.role && roleLabels[entry.role] ? `, ${roleLabels[entry.role]}` : ''}`}
        onClick={() => { if (selectedAbility || entry.id !== selected?.id) selectKnowledge(entry.id); }}
      >
        <span className="HereticBook__lineNumber">{entry.kind === 'path' ? numeral(entry.stage) : ''}</span>
        <span className="HereticBook__lineName">{entry.name}</span>
        <span className="HereticBook__leader" />
        <span className="HereticBook__amount">{entry.passive ? `${numeral(entry.passive.level)}/${numeral(entry.passive.max_level)}` : entry.known ? '' : entry.cost}</span>
      </button>
    );
  };
  return (
    <>
      <Page side="left" chapter="Знания" head="Оглавление">
        <Headpiece />
        <h2 className="HereticBook__chapterTitle">Содержание</h2>
        <nav className="HereticBook__contents" aria-label="Дерево знаний">
          {!data.selected_path && <p className="HereticBook__note">Сначала выберите путь в первой главе.</p>}
          {main.length > 0 && <ContentsGroup title="Ступени пути">{main.map(line)}</ContentsGroup>}
          {abilities.length > 0 && (
            <ContentsGroup title="Способности">
              {abilities.map((ability) => (
                <button
                  type="button"
                  key={ability.id}
                  className="HereticBook__line HereticBook__line--ability"
                  aria-label={ability.name}
                  aria-pressed={selectedAbility?.id === ability.id}
                  title={ability.summary ? plainText(ability.summary) : undefined}
                  onClick={() => { if (ability.id !== selectedAbility?.id) { setSelectedAbilityId(ability.id); turn(); } }}
                >
                  <span className="HereticBook__lineNumber" />
                  <span className="HereticBook__lineName">{ability.name}</span>
                  <span className="HereticBook__leader" />
                  {ability.hotkey && <kbd className="HereticBook__key">{ability.hotkey}</kbd>}
                </button>
              ))}
            </ContentsGroup>
          )}
          {side.length > 0 && <ContentsGroup title="Побочные знания">{side.map(line)}</ContentsGroup>}
          {starting.length > 0 && <ContentsGroup title="Начальные знания">{starting.map(line)}</ContentsGroup>}
        </nav>
      </Page>
      <Page
        side="right"
        chapter="Знания"
        entryId={selectedAbility?.id || selected?.id}
        head={selectedAbility ? 'Способности' : selected?.kind === 'side' ? 'Побочные знания' : selected?.kind === 'start' ? 'Начальные знания' : 'Ступени пути'}
        number={folio('Знания', selected ? visible.indexOf(selected) : 0) + 1}
      >
        {selectedAbility
          ? <AbilityEntry ability={selectedAbility} />
          : selected ? <KnowledgeEntry knowledge={selected} recipe={recipe} /> : <p>Выберите путь в первой главе, чтобы открыть его знания.</p>}
      </Page>
    </>
  );
};

/* Ритуалы */

const RitualChapter = ({ turn }: { turn: () => void }) => {
  const { data } = useLoreBackend();
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const rituals = data.rituals.filter((ritual) => {
    const knowledge = data.knowledge.find((entry) => entry.id === ritual.id);
    return (!knowledge || knowledge.known || knowledge.kind !== 'path' || !data.selected_path || knowledge.path === data.selected_path)
      && `${ritual.name} ${ritual.result || ''} ${ritual.desc} ${ritual.hint || ''} ${ritual.ingredients.map((item) => item.name).join(' ')}`
        .toLowerCase().includes(search.trim().toLowerCase());
  });
  const selected = rituals.find((ritual) => ritual.id === selectedId) || rituals[0];
  const knowledge = data.knowledge.find((entry) => entry.id === selected?.id);
  useEffect(() => {
    if (selected) setSelectedId(selected.id);
  }, [selected?.id]);
  return (
    <>
      <Page side="left" chapter="Ритуалы" head="Требник">
        <Headpiece />
        <h2 className="HereticBook__chapterTitle">Ритуалы</h2>
        <label className="HereticBook__search">
          <span>Поиск по названию, компоненту или итогу</span>
          <input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="клинок, нож, сердце..." />
        </label>
        <nav className="HereticBook__contents" aria-label="Ритуалы">
          {rituals.map((ritual) => {
            const entry = data.knowledge.find((item) => item.id === ritual.id);
            return (
              <button
                type="button"
                key={ritual.id}
                className={`HereticBook__line HereticBook__line--${!entry || entry.known ? 'known' : 'unlearned'}`}
                aria-label={`${ritual.name}${entry ? entry.known ? ', изучено' : ', не изучено' : ''}`}
                aria-pressed={selected?.id === ritual.id}
                onClick={() => { if (ritual.id !== selected?.id) { setSelectedId(ritual.id); turn(); } }}
              >
                <span className="HereticBook__lineNumber">{entry?.kind === 'path' ? numeral(entry.stage) : ''}</span>
                <span className="HereticBook__lineName">{ritual.name}</span>
              </button>
            );
          })}
        </nav>
        {rituals.some((ritual) => data.knowledge.find((item) => item.id === ritual.id && !item.known)) && <p className="HereticBook__note">Неизученные рецепты написаны бледнее.</p>}
        {!rituals.length && <p className="HereticBook__note">{search ? 'Такой записи нет. Попробуйте другое слово.' : 'Изучайте знания, чтобы открыть ритуалы.'}</p>}
        <section className="HereticBook__section" aria-label="Как провести обряд">
          <h3>Как провести обряд</h3>
          <RitualDiagram />
          <ol className="HereticBook__steps">
            <li>Начертите руну кодексом на полу станции 3×3 без стен, космоса, лавы и соседних рун.</li>
            <li>Разложите компоненты на полу в пределах руны, углы тоже считаются. Вещи в руках, на теле и в сумках не в счёт.</li>
            <li>Нажмите на центр руны пустой рукой, выберите обряд и не двигайтесь до конца.</li>
          </ol>
        </section>
      </Page>
      <Page side="right" chapter="Ритуалы" entryId={selected?.id} head={selected?.ascension ? 'Последний обряд' : 'Рецепты'} number={folio('Ритуалы', selected ? rituals.indexOf(selected) : 0) + 1}>
        {selected ? (
          <>
            <EntryHead
              kicker={`${selected.ascension ? 'Последний обряд' : 'Рецепт'}${knowledge ? ` · ${knowledge.known ? 'изучен' : 'не изучен'}` : ''}`}
              title={selected.name}
              notes={<>{!!selected.result && <span>итог: {selected.result}</span>}{selected.duration !== undefined && <span>{selected.duration} сек.</span>}{knowledge && <span className={`HereticBook__marginState HereticBook__marginState--${knowledge.known ? 'known' : 'open'}`}>{knowledge.known ? 'изучен' : 'не изучен'}</span>}</>}
            />
            {knowledge?.summary ? <p className="HereticBook__lead">{plainText(selected.desc)}</p> : <LoreText className="HereticBook__lead" text={selected.desc} />}
            {knowledge && !knowledge.known && (
              <>
                <p className="HereticBook__note">{knowledge.kind === 'path' && `Путь: ${data.paths.find((path) => path.id === knowledge.path)?.name || knowledge.path}. `}Изучите рецепт, и обряд появится в меню руны.</p>
                <KnowledgeConditions knowledge={knowledge} showStage />
                <ResearchButton knowledge={knowledge} />
              </>
            )}
            <RitualRecipe ritual={selected} />
            {!!selected.ascension && <p>Принесите {data.hunt.sacrifices_required} {countNoun(data.hunt.sacrifices_required, ['назначенную душу', 'назначенные души', 'назначенных душ'])} и изучите последнее знание. Обряд вознесения занимает 30 секунд, подношения не возвращаются.</p>}
            <Tailpiece />
          </>
        ) : <p className="HereticBook__note">Нет ритуалов для просмотра.</p>}
      </Page>
    </>
  );
};

/* Охота */

const PreparationSection = ({ openArmor }: { openArmor?: () => void }) => {
  const { data, act } = useLoreBackend();
  const preparation = data.preparation;
  if (!preparation) return null;
  const entries = [
    { name: 'Клинок', ready: preparation.blade_ready, status: preparation.blade_status },
    { name: 'Броня', ready: preparation.armor_ready, status: preparation.armor_status },
    { name: 'Сердце', ready: preparation.heart.ready, status: preparation.heart.status },
  ];
  const ready = entries.filter((entry) => !!entry.ready).length;
  return (
    <section className="HereticBook__section" aria-label="Подготовка к охоте">
      <h3>Подготовка к охоте <span className="HereticBook__count">{ready} из 3</span></h3>
      <dl className="HereticBook__checklist">
        {entries.map((entry) => (
          <div key={entry.name} className={entry.ready ? 'HereticBook__check--ready' : undefined}>
            <dt><PrepIcon name={entry.name} />{entry.name}</dt>
            <dd>{entry.status}{entry.name === 'Броня' && !entry.ready && openArmor && <> <button type="button" className="HereticBook__link" onClick={openArmor}>Рецепт брони</button></>}</dd>
          </div>
        ))}
      </dl>
      <div className="HereticBook__buttons">
        <button type="button" className="HereticBook__seal" disabled={!preparation.heart.can_call} onClick={() => act('call_heart')}>
          {preparation.heart.action_label}
        </button>
        <button type="button" className="HereticBook__link" onClick={() => act('refresh_preparation')}>Проверить подготовку</button>
      </div>
    </section>
  );
};

const DeedSection = () => {
  const { data } = useLoreBackend();
  const deed = data.deed;
  if (!deed) return <p className="HereticBook__note">Дело появится после выбора пути.</p>;
  const done = deed.tier >= deed.max_tier;
  return (
    <section className="HereticBook__section" aria-label="Дело пути">
      <h3>{deed.name} <Marks kind="seal" total={deed.max_tier} filled={deed.tier} label={`Ступеней дела: ${deed.tier} из ${deed.max_tier}`} /></h3>
      <p className="HereticBook__count">{done ? 'Дело завершено.' : `Ступень ${deed.tier + 1} из ${deed.max_tier} · ${deed.progress} из ${deed.goal}`}</p>
      {!done && deed.next_step && <p className="HereticBook__nextStep"><b className="HereticBook__runIn">Дальше.</b> {deed.next_step}</p>}
      {done || !deed.next_step ? <LoreText text={deed.desc} /> : (
        <details className="HereticBook__fold">
          <summary>Подробности дела</summary>
          <LoreText text={deed.desc} />
          {!!deed.hint && <p className="HereticBook__note">{deed.hint}</p>}
        </details>
      )}
      {!done && !deed.next_step && deed.hint && <p className="HereticBook__note">{deed.hint}</p>}
      {!done && deed.combat_hint && (
        <p className="HereticBook__aside" aria-label="Боевой шаг дела">
          <b className="HereticBook__runIn">Или охотой.</b> {deed.combat_hint} {deed.combat_available
            ? 'Это заменяет один шаг ступени, каждая душа считается один раз за всё дело.'
            : 'Боевой шаг этой ступени уже засчитан.'}
        </p>
      )}
      {!done && <p className="HereticBook__note">Каждая ступень приносит очко знаний.</p>}
    </section>
  );
};

const HuntChapter = ({ retargetDeadline, openHelp, openArmor }: { retargetDeadline: number; openHelp: (topic: HelpTopicId) => void; openArmor?: () => void }) => {
  const { data, act } = useLoreBackend();
  const hunt = data.hunt;
  const secondsLeft = () => Math.max(0, Math.ceil((retargetDeadline - Date.now()) / 1000));
  const [remaining, setRemaining] = useState(secondsLeft);
  useEffect(() => {
    setRemaining(secondsLeft());
    if (retargetDeadline <= Date.now()) return;
    const timer = setInterval(() => {
      const seconds = secondsLeft();
      setRemaining(seconds);
      if (!seconds) clearInterval(timer);
    }, 1000);
    return () => clearInterval(timer);
  }, [retargetDeadline]);
  const canRetarget = !!hunt.can_retarget || retargetDeadline <= Date.now();
  return (
    <>
      <Page side="left" chapter="Охота" head="Охота">
        <div className="HereticBook__target">
          <Headpiece />
          <Kicker>{hunt.target_name && <svg className="HereticBook__heartbeat" viewBox="0 0 20 20" aria-hidden="true">{prepIcons.Сердце}</svg>}Цель охоты</Kicker>
          <h2 className={hunt.target_name ? undefined : 'HereticBook__target--empty'}>{hunt.target_name || 'Цель не выбрана'}</h2>
          {hunt.target_role && <p className="HereticBook__targetRole">{hunt.target_role}</p>}
          <p className="HereticBook__targetStatus">{hunt.target_status}</p>
          <button type="button" className="HereticBook__seal" disabled={!canRetarget} onClick={() => act('retarget')}>
            {hunt.target_name ? 'Сменить цель' : 'Выбрать цель'}
          </button>
          {!canRetarget && <p className="HereticBook__note">Сменить цель можно через {remaining} сек.</p>}
        </div>
        <PreparationSection openArmor={openArmor} />
        <Facts lines={[
          'Сожмите живое сердце в руке, и оно укажет на цель.',
          'Alt-ЛКМ по сердцу меняет цель, касание сердцем поверженного делает целью его. Не чаще раза в 3 минуты.',
          'Целью может стать только согласный на охоту: значок у ног не серый и не перечёркнут. Синее кольцо значит "только живым".',
        ]} />
      </Page>
      <Page side="right" chapter="Охота" head="Дело и жертвы">
        <Headpiece />
        <DeedSection />
        <section className="HereticBook__section" aria-label="Жертвоприношение">
          <h3>Жертвы <span className="HereticBook__count">{data.total_sacrifices} из {hunt.sacrifices_required}</span></h3>
          <Marks kind="soul" total={hunt.sacrifices_required} filled={data.total_sacrifices} label={`Принято душ: ${data.total_sacrifices} из ${hunt.sacrifices_required}`} />
          <p>Обезвредьте цель и коснитесь её живым сердцем, или положите её на руну рядом с сердцем. Живая жертва даёт 2 очка и 1 побочное, труп - 1 очко, если цель согласна быть целью убийства.</p>
          <button type="button" className="HereticBook__link" onClick={() => openHelp('hunt')}>Все правила жертвы</button>
        </section>
        <section className="HereticBook__section" aria-label="Разломы">
          <h3>Разломы <span className="HereticBook__count">{hunt.influences_harvested} из {hunt.influence_limit}</span></h3>
          <p>{hunt.influences_harvested >= hunt.influence_limit
            ? 'Свою долю разломов вы уже собрали. Новые знания теперь дают только жертвы.'
            : 'Коснитесь разлома рукой, хваткой, кодексом или любым предметом в руке. Кодекс должен быть при вас.'}
          </p>
          <InfluenceSchedule hunt={hunt} />
        </section>
      </Page>
    </>
  );
};

/* Помощь */

const HelpTopic = ({ id, title, open, children }: { id: HelpTopicId; title: string; open: boolean; children: ReactNode }) => (
  <details className="HereticBook__topic" open={open} data-topic={id}>
    <summary>{title}</summary>
    <div className="HereticBook__topicBody">{children}</div>
  </details>
);

const HelpChapter = ({ topic, openHelp }: { topic: HelpTopicId; openHelp: (topic: HelpTopicId) => void }) => {
  const { data } = useLoreBackend();
  const hunt = data.hunt;
  const pocket = hunt.pocket;
  const deedTiers = hunt.deed_tiers ?? 3;
  const bodies = hunt.ascension_bodies ?? 3;
  return (
    <>
      <Page side="left" chapter="Помощь" head="Наставления">
        <h2 className="HereticBook__chapterTitle">Как играть</h2>
        <HelpTopic id="start" title="Начало" open={topic === 'start'}>
          <RitualDiagram />
          <ol className="HereticBook__steps" aria-label="Первые пять минут">
            <li>Откройте кодекс и выберите путь. «Призвать кодекс» кладёт книгу в руку и возвращает потерянную, Z открывает её. В главе Путь выбор подтверждают вторым нажатием, сменить путь потом нельзя.</li>
            <li>Начертите руну: с кодексом в руке нажмите на пол и стойте 8 секунд. Нужен пол станции 3×3 без стен, космоса, лавы и других рун; стирают руну кодекс или Хватка.</li>
            <li>Сделайте клинок: компоненты первого рецепта пути из главы Ритуалы положите на руну, нажмите на её центр пустой рукой и выберите строку «... → клинок».</li>
            <li>Подготовьтесь: со второй ступени изучите «Ритуал оружейника», стол и противогаз на руне дадут мантию. Готовность клинка, брони и сердца видна в главе Охота.</li>
            <li>Охотьтесь: призовите живое сердце и сожмите его в руке (Z), оно назначит цель. Обезвредьте её и коснитесь сердцем. Жертва даёт очки знаний, как разломы и дело пути.</li>
          </ol>
        </HelpTopic>
        <HelpTopic id="path" title="Путь и знания" open={topic === 'path'}>
          <Facts lines={[
            'Ступени пути открываются по порядку, побочные знания - после нужной ступени.',
            'Изучение рецепта не выдаёт предмет: проведите обряд на руне из главы Ритуалы.',
            'Броню даёт Ритуал оружейника со второй ступени: стол и противогаз становятся мантией.',
            'Пассивку пути можно усилить дважды: за 1 и за 2 очка, сначала тратятся побочные.',
            'Хватка ставит метку, удар клинком её взрывает; по вещам и полу она работает тихо, без заклинания вслух. Запас силы пути виден под разворотом.',
          ]} />
        </HelpTopic>
        <HelpTopic id="rifts" title="Разломы" open={topic === 'rifts'}>
          <p>Коснитесь разлома рукой, хваткой, кодексом или любым предметом в руке и дождитесь конца изучения. Кодекс должен быть при себе. За раунд можно изучить {hunt.influence_limit} {countNoun(hunt.influence_limit, ['разлом', 'разлома', 'разломов'])}.</p>
          <InfluenceSchedule hunt={hunt} />
          <Facts lines={[
            'Чужое изучение не забирает ваши очки, поздние еретики тоже находят разломы.',
            'След разлома держится 3 минуты. Нейтрализатор аномалий превращает его в кристалл завесы.',
            'Раздавленный кристалл 20 секунд лечит раны и выносливость, второй сразу не сработает.',
          ]} />
        </HelpTopic>
        <HelpTopic id="hunt" title="Охота и жертва" open={topic === 'hunt'}>
          <ul className="HereticBook__facts">
            <li>Цель назначают в главе Охота или сердцем, сжатое сердце ведёт к ней. Цель, которую охраняют или прячут, лучше сменить: раз в 3 минуты кнопкой в главе Охота, ссылкой в ответе сердца или Alt-ЛКМ по нему.</li>
            <li>Годится цель в наручниках, оглушённая, сбитая с ног или без сознания, в крите - и без наручников. Сама легшая или уснувшая не в счёт, еретики и их слуги тоже. Согласие на охоту видно по значку слева у ног: серый перечёркнутый круг - нельзя, синее кольцо - только живым, оранжевый прицел и красный круг - примут и труп. Проверьте значок до нападения.</li>
            <li>После захвата пути цель к нему невосприимчива: минуту после полного, 10 секунд после сорванного сразу. Сорванный ещё на предупреждении ничего не даёт цели, а вам возвращает перезарядку.</li>
            <li>Коснитесь цели сердцем или положите её с сердцем на руну и стойте 8 секунд. Перенос жертвы или прерывание срывают обряд. Без свидетелей - в <button type="button" className="HereticBook__link" onClick={() => openHelp('pocket')}>изнанке</button>.</li>
            <li>Живая жертва даёт 2 очка и 1 побочное и вернётся через Мансус, труп - 1 очко и только от согласных быть целью убийства. Одна душа - один раз.</li>
          </ul>
        </HelpTopic>
        <HelpTopic id="pocket" title="Изнанка" open={topic === 'pocket'}>
          <Facts lines={[
            `Изнанка - ваша карманная комната: дверь пути уводит туда цель охоты вместе с вами. Живое сердце предлагает дверь пути, когда вы касаетесь им цели; дверь, которая работает издалека, можно выбрать и сжав сердце - рядом с «Найти цель». Пока вы выбираете дверь и тянете цель, сердце прижимает её к полу до ${pocket.grip} сек.: касанием в «Помощи» её не поднять, растолкать можно за ${pocket.shake} сек., нулевой жезл снимает хватку сразу. Внутри цель ${pocket.hold} сек. не может двинуться.`,
            `Общая дверь: если цель повержена на вашей руне или рядом, коснитесь руны в «Помощи» и выберите «Увести за руну», увод займёт ${pocket.pull} сек.`,
            `Изнанка держится ${pocket.duration} сек., за ${pocket.warning} до конца - предупреждение. Ваш крит закрывает её сразу, и все выпадают у входа.`,
            '«Покинуть изнанку» выводит к вашим рунам, ремеслу пути, ко входу или туда, где вы стояли, если тянули цель издалека. Если разрыв закрыли или время вышло, вас выносит к вашему выходу подальше от входа. Цель и вещи выпадают у входа, ваши сердце и кодекс, оставленные на полу, уходят за завесу, а тёмные клинки выносит вместе с вами.',
            `У входа остаётся разрыв: жезл или Библия закрывают его сразу, руками его можно разорвать за ${pocket.tear} сек. Снова открыть изнанку можно через ${pocket.cooldown} сек.`,
          ]} />
        </HelpTopic>
        <HelpTopic id="mansus" title="Мансус" open={topic === 'mansus'}>
          <Facts lines={[
            'Живая жертва проходит Дом памяти: лабиринт комнат с правилом вашего пути.',
            'Три осколка нужно донести до печати перед вратами. Через 3 минуты Дом отпускает сам.',
            'Жертва возвращается в коридор станции и помнит Дом, но не похищение: кто её схватил, где и как это было, стёрто вместе с минутами перед ним. Назвать вас она не может.',
          ]} />
        </HelpTopic>
      </Page>
      <Page side="right" chapter="Помощь" head="Наставления">
        <h2 className="HereticBook__chapterTitle">Риски и цель</h2>
        <HelpTopic id="custody" title="Удержание СБ" open={topic === 'custody'}>
          <Facts lines={[
            'В наручниках и смирительной рубашке магия, обряды и побег клинком недоступны.',
            'Имплант защиты разума глушит их, пока стоит; снять его можно только хирургически.',
            'Побочное знание Разум за завесой снимает действие щита, вознёсшегося щит не держит.',
            'Разбитый клинок переносит в безопасное место станции, следующий побег - через 10 секунд.',
            'Стан культа крови сбивает еретика на 2 секунды и оглушает на 1.',
          ]} />
        </HelpTopic>
        <HelpTopic id="ascension" title="Вознесение" open={topic === 'ascension'}>
          <p>Совершите {hunt.sacrifices_required} {countNoun(hunt.sacrifices_required, ['жертвоприношение', 'жертвоприношения', 'жертвоприношений'])} и изучите последнее знание пути.</p>
          <Facts lines={[
            `Принесите на руну ${bodies} ${countNoun(bodies, ['труп', 'трупа', 'трупов'])} экипажа, которыми управлял человек; выбранные тела подсвечиваются зелёным. Обряд 30 секунд.`,
            'После второй жертвы станцию предупреждают; вознестись можно через 3 минуты после этого.',
            'Каждая попытка объявляется станции, между попытками не меньше 3 минут. Руна - в помещении, не в космосе.',
            'Вознестись могут несколько еретиков. После вознесения побег клинком закрыт.',
          ]} />
        </HelpTopic>
        <HelpTopic id="deed" title="Дело пути" open={topic === 'deed'}>
          <p>Дело состоит из {deedTiers} {countNoun(deedTiers, ['ступени', 'ступеней', 'ступеней'])}: каждая даёт 1 очко знаний, вторая и третья - ещё по 1 побочному.</p>
          <Facts lines={[
            'Дело не связано с боем, его шаги видны в главе Охота.',
            'Каждый засчитанный шаг восполняет запас силы и оставляет след, который может найти экипаж.',
          ]} />
        </HelpTopic>
        <HelpTopic id="hotkeys" title="Горячие клавиши" open={topic === 'hotkeys'}>
          <Facts lines={[
            ...(data.ability_hotkey_help ? [data.ability_hotkey_help] : []),
            'Подготовка контактной или прицельной способности выключает режим броска, включение броска её снимает.',
            'Нажатие на значок запаса силы среди уведомлений экрана применяет силу пути.',
          ]} />
        </HelpTopic>
      </Page>
    </>
  );
};

/* Строка под разворотом */

const Ledger = ({ openHunt }: { openHunt: () => void }) => {
  const { data } = useLoreBackend();
  const [rulesOpen, setRulesOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (!rulesOpen) return;
    const close = (event: MouseEvent) => {
      if (!ref.current?.contains(event.target as Node)) setRulesOpen(false);
    };
    window.addEventListener('click', close);
    return () => window.removeEventListener('click', close);
  }, [rulesOpen]);
  const resource = data.combat_resource;
  const deed = data.deed;
  const deedDone = !!deed && deed.tier >= deed.max_tier;
  const rules = resource ? resource.rules?.length ? resource.rules : [resource.description] : [];
  return (
    <div className="HereticBook__ledger" ref={ref} role="group" aria-label="Знания и сила">
      <span className="HereticBook__tally" title="Очки знаний"><b>{data.points}</b> {countNoun(data.points, ['знание', 'знания', 'знаний'])}</span>
      <span className="HereticBook__tally" title="Побочные очки"><b>{data.side_points || 0}</b> побочн.</span>
      <span className="HereticBook__tally" title="Жертвоприношения">жертвы <b>{data.total_sacrifices}/{data.hunt.sacrifices_required}</b></span>
      {resource && (
        <button
          type="button"
          className="HereticBook__tally HereticBook__tally--resource"
          aria-expanded={rulesOpen}
          aria-controls="heretic-resource-rules"
          title={resource.state ? plainText(resource.state) : 'Правила запаса'}
          onClick={() => setRulesOpen(!rulesOpen)}
        >
          {resource.name}
          {resource.max <= 12
            ? <Marks total={resource.max} filled={resource.value} label={`${resource.name}: ${resource.value} из ${resource.max}`} />
            : <b>{resource.value}/{resource.max}</b>}
          {!!resource.state && <span className="HereticBook__tallyState">{plainText(resource.state)}</span>}
        </button>
      )}
      {deed && (
        <button type="button" className="HereticBook__tally HereticBook__tally--deed" title={deedDone ? deed.name : deed.next_step || plainText(deed.desc)} onClick={openHunt}>
          {deed.name} <b>{deedDone ? 'завершено' : `${numeral(deed.tier + 1)} · ${deed.progress}/${deed.goal}`}</b>
        </button>
      )}
      {resource && rulesOpen && (
        <section id="heretic-resource-rules" className="HereticBook__popover" aria-label="Правила запаса">
          <h3>{resource.name} <span className="HereticBook__count">{resource.value} из {resource.max}</span></h3>
          {!!resource.state && <p className="HereticBook__lead">{plainText(resource.state)}</p>}
          <Facts lines={rules} />
        </section>
      )}
    </div>
  );
};

export const ForbiddenLoreContent = () => {
  const { data, config, act } = useLoreBackend();
  const retargetDeadline = useMemo(() => Date.now() + data.hunt.retarget_seconds * 1000, [data.hunt]);
  const reading = useBookPresentation(config.client?.ckey);
  const handlePresentationChange = reading.choose;
  const [chapter, setChapter] = useState<Chapter>(data.selected_path ? 'Знания' : 'Путь');
  const [helpTopic, setHelpTopic] = useState<HelpTopicId>('start');
  const [knowledgeId, setKnowledgeId] = useState<string | null>(null);
  const [turnCount, setTurnCount] = useState(0);
  const [turnBack, setTurnBack] = useState(false);
  useEffect(() => {
    setTurnCount(0);
  }, [reading.effectivePresentation, reading.reducedMotion]);
  const bookmarks = useRef<Array<HTMLButtonElement | null>>([]);
  const skin = data.book?.path || data.selected_path || 'Unbound';
  const armor = data.knowledge.find((entry) => entry.starter_armor);
  const chapterIndex = chapters.indexOf(chapter);
  const turn = (next: Chapter = chapter) => {
    if (reading.effectivePresentation === 'living' && !reading.reducedMotion) {
      setTurnBack(chapters.indexOf(next) < chapterIndex);
      setTurnCount((count) => count + 1);
    }
    act('turn_page', { chapter: next });
  };
  const open = (next: Chapter) => {
    if (next !== chapter) { setChapter(next); turn(next); }
  };
  const openHelp = (topic: HelpTopicId) => {
    setHelpTopic(topic);
    open('Помощь');
  };
  return (
    <div
      style={{
        '--book-material': skin === 'Unbound' ? undefined : `url("${resolveAsset(`heretic-${skin.toLowerCase()}.webp`)}")`,
        '--stack-left': `${3 + chapterIndex * 2}px`,
        '--stack-right': `${3 + (chapters.length - 1 - chapterIndex) * 2}px`,
      } as CSSProperties}
      lang="ru"
      className={`HereticBook HereticBook--${skin}`} data-book-path={skin} data-book-view={reading.effectivePresentation} data-book-motion={reading.reducedMotion ? 'reduced' : 'full'}>
      <style>{bookFontFaces()}</style>
      <div className="HereticBook__tableShadow" />
      <div className="HereticBook__binding">
        <nav className="HereticBook__bookmarks" role="tablist" aria-label="Главы книги">
          {chapters.map((name, index) => (
            <button
              type="button"
              key={name}
              ref={(element) => { bookmarks.current[index] = element; }}
              role="tab"
              aria-selected={chapter === name}
              aria-controls="heretic-book-spread"
              tabIndex={chapter === name ? 0 : -1}
              onClick={() => open(name)}
              onKeyDown={(event) => {
                let next = index;
                if (event.key === 'ArrowRight') next = (index + 1) % chapters.length;
                else if (event.key === 'ArrowLeft') next = (index + chapters.length - 1) % chapters.length;
                else if (event.key === 'Home') next = 0;
                else if (event.key === 'End') next = chapters.length - 1;
                else return;
                event.preventDefault();
                open(chapters[next]);
                bookmarks.current[next]?.focus();
              }}
            >{name}
            </button>
          ))}
        </nav>
        <div className="HereticBook__leaves" />
        <div className="HereticBook__stack HereticBook__stack--left" aria-hidden="true" />
        <div className="HereticBook__stack HereticBook__stack--right" aria-hidden="true" />
        <main key={chapter} id="heretic-book-spread" className="HereticBook__spread" data-chapter={chapters.indexOf(chapter)} role="tabpanel" aria-label={chapter}>
          {chapter === 'Путь' && <PathChapter turn={turn} openKnowledge={() => open('Знания')} />}
          {chapter === 'Знания' && <KnowledgeChapter turn={turn} selectedId={knowledgeId} select={setKnowledgeId} />}
          {chapter === 'Ритуалы' && <RitualChapter turn={turn} />}
          {chapter === 'Охота' && <HuntChapter retargetDeadline={retargetDeadline} openHelp={openHelp} openArmor={armor && !armor.known ? () => { setKnowledgeId(armor.id); open('Знания'); } : undefined} />}
          {chapter === 'Помощь' && <HelpChapter topic={helpTopic} openHelp={openHelp} />}
          <div className="HereticBook__spine" aria-hidden="true" />
          {turnCount > 0 && reading.effectivePresentation === 'living' && !reading.reducedMotion && <div key={turnCount} className={`HereticBook__turningLeaf${turnBack ? ' HereticBook__turningLeaf--back' : ''}`} aria-hidden="true" onAnimationEnd={(event) => { if (event.target === event.currentTarget) setTurnCount(0); }} />}
        </main>
        {chapterIndex > 0 && <button type="button" className="HereticBook__corner HereticBook__corner--prev" title={chapters[chapterIndex - 1]} aria-label={`Предыдущая глава: ${chapters[chapterIndex - 1]}`} onClick={() => open(chapters[chapterIndex - 1])} />}
        {chapterIndex < chapters.length - 1 && <button type="button" className="HereticBook__corner HereticBook__corner--next" title={chapters[chapterIndex + 1]} aria-label={`Следующая глава: ${chapters[chapterIndex + 1]}`} onClick={() => open(chapters[chapterIndex + 1])} />}
        <HereticBookAtmosphere path={skin} presentation={reading.effectivePresentation} reducedMotion={reading.reducedMotion} />
        {(skin === 'Unbound' || reading.effectivePresentation === 'plain') && <div className="HereticBook__clasp" aria-hidden="true" />}
      </div>
      <div className="HereticBook__toolbar">
        <Ledger openHunt={() => open('Охота')} />
        {!!data.ascended && <div className="HereticBook__ascended">Вы вознеслись.</div>}
        <HereticBookPreferences presentation={reading.presentation} reducedMotion={reading.reducedMotion} onChange={handlePresentationChange} />
      </div>
    </div>
  );
};

export const ForbiddenLore = () => {
  const { data } = useLoreBackend();
  return <Window width={960} height={800} title={data.book?.title || 'Кодекс Рубцов'} theme="heretic"><Window.Content fitted><ForbiddenLoreContent /></Window.Content></Window>;
};
