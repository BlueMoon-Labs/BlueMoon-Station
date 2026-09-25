import { BooleanLike } from 'common/react';
import { decodeHtmlEntities } from 'common/string';
import { CSSProperties, ReactNode, useEffect, useMemo, useRef, useState } from 'react';

import { resolveAsset } from '../assets';
import { useBackend } from '../backend';
import { Button } from '../components';
import { Window } from '../layouts';
import { sanitizeText } from '../sanitize';
import { HereticBookAtmosphere } from './HereticBookAtmosphere';
import { HereticBookPreferences, useBookPresentation } from './HereticBookPreferences';
import { HereticIllumination, HereticPageOrnament, RitualDiagram } from './HereticIllumination';

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
const numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII', 'XIII', 'XIV', 'XV'];
const bookTitles: Record<string, string> = {
  Unbound: 'Кодекс Рубцов', Ash: 'Псалтирь последнего огня', Rust: 'Железный завет',
  Flesh: 'Анатомия голода', Void: 'Палимпсест зимы', Blade: 'Трактат о последнем ударе',
  Moon: 'Зерцало без лица', Cosmic: 'Атлас внутреннего неба',
  Lock: 'Каталог невозможных дверей', Tide: 'Лоция бездонного моря',
  Glass: 'Евангелие разбитого света', Blood: 'Служебник алой десятины',
  Echo: 'Партитура последнего голоса',
  Sand: 'Хроника истёкшего часа', Wax: 'Служба негаснущей свечи',
  Spirit: 'Список непришедших',
};

export const roleLabels: Record<string, { label: string; glyph: string }> = {
  craft: { label: 'Ремесло', glyph: '◇' },
  capture: { label: 'Захват', glyph: '▣' },
  escape: { label: 'Уход', glyph: '↗' },
  attack: { label: 'Атака', glyph: '✕' },
  control: { label: 'Контроль', glyph: '◎' },
  defense: { label: 'Защита', glyph: '▲' },
  support: { label: 'Усиление', glyph: '✚' },
  passive: { label: 'Пассивка', glyph: '○' },
  relic: { label: 'Реликвия', glyph: '◈' },
  mark: { label: 'Метка', glyph: '✧' },
  grasp: { label: 'Хватка', glyph: '◐' },
  ritual: { label: 'Обряд', glyph: '⊙' },
  ascension: { label: 'Вознесение', glyph: '✶' },
};

const VISIBLE_DETAILS = 4;

type HelpTopicId = 'start' | 'path' | 'rifts' | 'hunt' | 'pocket' | 'mansus' | 'custody' | 'ascension' | 'deed' | 'hotkeys';

const countNoun = (amount: number, forms: [string, string, string]) => {
  const count = Math.abs(amount) % 100;
  if (count >= 11 && count <= 14) return forms[2];
  if (count % 10 === 1) return forms[0];
  if (count % 10 >= 2 && count % 10 <= 4) return forms[1];
  return forms[2];
};

const plainText = (text?: string | null) => decodeHtmlEntities(sanitizeText((text || '').replace(/<br\s*\/?>/gi, '\n'), false, []));

const InfluenceSchedule = ({ hunt }: { hunt: ForbiddenLoreData['hunt'] }) => {
  const initial = hunt.influence_initial_count ?? 3;
  const interval = hunt.influence_interval_minutes ?? 8;
  return <p>В начале раунда: {initial} {countNoun(initial, ['разлом', 'разлома', 'разломов'])}. Затем каждые {interval} мин. появляется ещё один.</p>;
};

const LoreText = ({ text }: { text: string }) => (
  <div className="HereticBook__prose">{plainText(text)}</div>
);

const RoleChip = ({ role }: { role?: string | null }) => {
  const meta = role ? roleLabels[role] : undefined;
  if (!meta) return null;
  return <span className={`HereticBook__role HereticBook__role--${role}`}><span aria-hidden="true">{meta.glyph}</span>{meta.label}</span>;
};

const RoleMark = ({ role }: { role?: string | null }) => {
  const meta = role ? roleLabels[role] : undefined;
  if (!meta) return null;
  return <span className={`HereticBook__roleMark HereticBook__role--${role}`} title={meta.label} aria-hidden="true">{meta.glyph}</span>;
};

const DetailList = ({ lines }: { lines: string[] }) => {
  const [expanded, setExpanded] = useState(false);
  const hidden = lines.length - VISIBLE_DETAILS;
  const visible = expanded || hidden <= 0 ? lines : lines.slice(0, VISIBLE_DETAILS);
  return (
    <>
      <ul className="HereticBook__details">
        {visible.map((line, index) => <li key={`${index}-${line}`}>{plainText(line)}</li>)}
      </ul>
      {hidden > 0 && (
        <button type="button" className="HereticBook__more" aria-expanded={expanded} onClick={() => setExpanded(!expanded)}>
          {expanded ? 'Свернуть' : `Ещё ${hidden}`}
        </button>
      )}
    </>
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
    <div className="HereticBook__research">
      {choosesPath ? (
        <Button.Confirm
          key={knowledge.id}
          role="button"
          className="HereticBook__inscribe"
          content="Выбрать этот путь"
          confirmContent="Подтвердить выбор пути"
          disabled={disabled}
          onClick={() => act('research', { id: knowledge.id })}
        />
      ) : (
        <button type="button" className="HereticBook__inscribe" disabled={disabled} onClick={() => act('research', { id: knowledge.id })}>
          Изучить · {knowledge.cost} очк. знаний
        </button>
      )}
      {disabled && (
        <p className="HereticBook__annotation" role="status">
          {knowledge.reason || (knowledge.cost > availablePoints
            ? `Не хватает очков знаний: нужно ${knowledge.cost}.`
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
  if (passive.level >= passive.max_level) return <p className="HereticBook__learned">Максимальный уровень пассивки</p>;
  const canAfford = data.points + (data.side_points || 0) >= passive.cost;
  return (
    <div className="HereticBook__research">
      <button
        type="button"
        className="HereticBook__inscribe"
        disabled={!passive.available || !canAfford}
        onClick={() => act('upgrade_passive', { id: knowledge.id, level: passive.level })}
      >
        Улучшить до {passive.level + 1} · {passive.cost} очк. знаний
      </button>
      <p className="HereticBook__annotation" role="status">
        {passive.reason || (!canAfford ? `Не хватает очков знаний: нужно ${passive.cost}.`
          : 'Второй уровень стоит 1 очко, третий - 2. Сначала расходуются побочные очки.')}
      </p>
    </div>
  );
};

const PassiveDetails = ({ knowledge }: { knowledge: Knowledge }) => {
  const passive = knowledge.passive;
  if (!passive && !knowledge.passive_description) return null;
  return (
    <section className="HereticBook__passive" aria-label="Прокачка пассивки">
      <h3>Пассивка{passive ? ` · ${passive.level} / ${passive.max_level}` : ''}</h3>
      <LoreText text={passive?.description || knowledge.passive_description || ''} />
      {!passive && <p className="HereticBook__annotation">Сначала изучите знание, чтобы открыть улучшения.</p>}
    </section>
  );
};

const KnowledgeMeta = ({ knowledge }: { knowledge: Knowledge }) => (
  <p className="HereticBook__meta">
    <RoleChip role={knowledge.role} />
    <span>{knowledge.cost} очк. знаний</span>
    <span className={`HereticBook__status${knowledge.known ? ' HereticBook__status--known' : ''}`}>
      {knowledge.known ? 'Изучено' : knowledge.available ? 'Доступно' : 'Закрыто'}
    </span>
  </p>
);

const KnowledgeRequirements = ({ knowledge, showCost = false }: { knowledge: Knowledge; showCost?: boolean }) => {
  const opensAt = knowledge.kind === 'side' || showCost ? knowledge.stage : 0;
  if (!showCost && !knowledge.sacrifices && !opensAt) return null;
  return (
    <dl className="HereticBook__requirements">
      {showCost && <><dt>Стоимость изучения</dt><dd>{knowledge.cost} очк. знаний</dd></>}
      {knowledge.sacrifices > 0 && <><dt>Жертвоприношения</dt><dd>{knowledge.sacrifices}</dd></>}
      {opensAt > 0 && <><dt>Ступень пути</dt><dd>{opensAt}</dd></>}
    </dl>
  );
};

const RitualHints = ({ ritual }: { ritual: Ritual }) => {
  if (ritual.hints?.length) {
    return <ul className="HereticBook__details">{ritual.hints.map((hint, index) => <li key={`${index}-${hint}`}>{plainText(hint)}</li>)}</ul>;
  }
  return ritual.hint ? <LoreText text={ritual.hint} /> : null;
};

const RitualIngredients = ({ ritual }: { ritual: Ritual }) => (
  <section className="HereticBook__recipe" aria-label="Компоненты обряда">
    <h3 className="HereticBook__ingredientsTitle">Компоненты обряда</h3>
    <ul className="HereticBook__ingredients">
      {ritual.ingredients.map((item, index) => <li key={`${item.name}-${index}`}><span>{item.name}</span><span className="HereticBook__leader" /><strong>×{item.amount}</strong></li>)}
    </ul>
    <RitualHints ritual={ritual} />
    {ritual.duration !== undefined && <p className="HereticBook__annotation">Время проведения: {ritual.duration} сек.</p>}
  </section>
);

type RulesToggle = { open: boolean; toggle: () => void };

const ResourceLedger = ({ resource, rules }: { resource: NonNullable<ForbiddenLoreData['combat_resource']>; rules: RulesToggle }) => (
  <div className="HereticBook__resource">
    <button
      type="button"
      className="HereticBook__resourceToggle"
      aria-expanded={rules.open}
      aria-controls="heretic-resource-rules"
      title="Правила запаса"
      onClick={() => rules.toggle()}
    >
      <span>{resource.name}</span><strong>{resource.value} / {resource.max}</strong>
    </button>
    <meter min={0} max={Math.max(1, resource.max)} value={resource.value} aria-label={resource.name} />
    {!!resource.state && <p className="HereticBook__resourceState">{plainText(resource.state)}</p>}
  </div>
);

const ResourceRules = ({ close }: { close: () => void }) => {
  const { data } = useLoreBackend();
  const sectionRef = useRef<HTMLElement>(null);
  useEffect(() => {
    sectionRef.current?.scrollIntoView?.({ block: 'nearest' });
  }, []);
  const resource = data.combat_resource;
  if (!resource) return null;
  const rules = resource.rules?.length ? resource.rules : [resource.description];
  return (
    <section ref={sectionRef} id="heretic-resource-rules" className="HereticBook__resourceRules" aria-label="Правила запаса">
      <h3>{resource.name}: правила запаса</h3>
      <ul className="HereticBook__details">{rules.map((rule, index) => <li key={`${index}-${rule}`}>{plainText(rule)}</li>)}</ul>
      <button type="button" className="HereticBook__more" onClick={close}>Свернуть</button>
    </section>
  );
};

const Ledger = ({ showDeed = true, rules }: { showDeed?: boolean; rules: RulesToggle }) => {
  const { data } = useLoreBackend();
  const resource = data.combat_resource;
  const deed = data.deed;
  const deedDone = !!deed && deed.tier >= deed.max_tier;
  return (
    <aside className="HereticBook__ledger" aria-label="Ваши знания и сила">
      <dl className="HereticBook__balances">
        <dt>Очки знаний</dt><dd>{data.points}</dd>
        <dt>Побочные очки</dt><dd>{data.side_points || 0}</dd>
        <dt>Жертвоприношения</dt><dd>{data.total_sacrifices} / {data.hunt.sacrifices_required}</dd>
      </dl>
      {resource && <ResourceLedger resource={resource} rules={rules} />}
      {showDeed && deed && (
        <div className="HereticBook__resource HereticBook__deedLine">
          <p><span>{deed.name}</span><strong>{numerals[Math.min(deed.tier, deed.max_tier - 1)] || deed.max_tier} / {numerals[deed.max_tier - 1] || deed.max_tier}{deedDone ? ' · Завершено' : ` · ${deed.progress} / ${deed.goal}`}</strong></p>
          <meter min={0} max={Math.max(1, deed.goal)} value={deedDone ? Math.max(1, deed.goal) : deed.progress} aria-label={`${deed.name}, ступень ${deed.tier} из ${deed.max_tier}`} />
        </div>
      )}
    </aside>
  );
};

const Page = ({ side, chapter, children, entryId }: { side: 'left' | 'right'; chapter: Chapter; children: ReactNode; entryId?: string }) => {
  const { data } = useLoreBackend();
  const scrollRef = useRef<HTMLDivElement>(null);
  const writingRef = useRef<HTMLDivElement>(null);
  const previousEntry = useRef(entryId);
  const [scrollState, setScrollState] = useState({ above: false, below: false });
  const [rulesOpen, setRulesOpen] = useState(false);
  const measureScroll = () => {
    const page = scrollRef.current;
    if (!page) return;
    const above = page.scrollTop > 2;
    const below = page.scrollTop + page.clientHeight < page.scrollHeight - 2;
    setScrollState((previous) => previous.above === above && previous.below === below ? previous : { above, below });
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
      && document.activeElement?.closest('.HereticBook__contentsLine, .HereticBook__oath, .HereticBook__guideLink')) {
      scroll.scrollIntoView({ block: 'start', inline: 'nearest' });
    }
    measureScroll();
  }, [entryId]);
  return (
    <article className={`HereticBook__page HereticBook__page--${side}`} aria-label={side === 'left' ? 'Левая страница' : 'Правая страница'}>
      <HereticPageOrnament path={data.book?.path || data.selected_path || 'Unbound'} />
      <div className="HereticBook__pageBody">
        <div className="HereticBook__pageScroll" ref={scrollRef} onScroll={measureScroll} tabIndex={0} aria-label={side === 'left' ? 'Текст левой страницы' : 'Текст правой страницы'}>
          <div ref={writingRef}>
            {children}
            {side === 'left' && rulesOpen && <ResourceRules close={() => setRulesOpen(false)} />}
          </div>
        </div>
        <div className="HereticBook__scrollHint" aria-hidden="true">{scrollState.below ? '↓ Дальше по странице' : scrollState.above ? '↑ Начало страницы' : '\u00a0'}</div>
        {side === 'left' && <Ledger showDeed={chapter !== 'Знания'} rules={{ open: rulesOpen, toggle: () => setRulesOpen(!rulesOpen) }} />}
        <footer className="HereticBook__folio"><span>{chapter}</span><span>{chapters.indexOf(chapter) * 2 + (side === 'left' ? 1 : 2)}</span></footer>
      </div>
    </article>
  );
};

const PathSide = ({ title, points, fallback }: { title: string; points?: string[]; fallback: string[] }) => (
  <section className="HereticBook__side" aria-label={title}>
    <h3>{title}</h3>
    {points?.length
      ? <ul className="HereticBook__details">{points.map((point, index) => <li key={`${index}-${point}`}>{plainText(point)}</li>)}</ul>
      : fallback.filter((text) => !!text).map((text) => <p key={text}>{plainText(text)}</p>)}
  </section>
);

const PathModel = ({ path }: { path: HereticPath }) => {
  const rows = [['Ремесло', path.craft], ['Захват', path.capture], ['Уход', path.escape]].filter(([, text]) => !!text);
  if (!rows.length) return null;
  return (
    <dl className="HereticBook__model" aria-label="Ремесло, захват и уход">
      {rows.map(([label, text]) => <div key={label}><dt>{label}</dt><dd>{plainText(text)}</dd></div>)}
    </dl>
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
      <Page side="left" chapter="Путь">
        <p className="HereticBook__runningTitle">{data.book?.subtitle || 'Пути Мансуса'}</p>
        <h1 className="HereticBook__bookTitle">{data.book?.title || bookTitles[skin] || bookTitles.Unbound}</h1>
        {data.book?.name && data.book.name !== data.book.title && <p className="HereticBook__latinTitle" lang="la">{data.book.name}</p>}
        <div className="HereticBook__titleRule" />
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
              <span className="HereticBook__ribbonMark" aria-hidden="true">{numerals[index] || index + 1}</span>
              <span>{entry.name}</span>
              {entry.id === data.selected_path && <span className="HereticBook__signed" aria-label="Выбранный путь">✓</span>}
            </button>
          ))}
        </nav>
        <p className="HereticBook__annotation">{data.selected_path
          ? 'Ваш путь выбран. Остальные доступны для просмотра.'
          : 'Выберите путь, чтобы прочитать о его способностях. Первое знание бесплатно. Сменить путь после подтверждения нельзя. После выбора Кодекс покажет дело пути.'}
        </p>
      </Page>
      <Page side="right" chapter="Путь" entryId={path?.id}>
        {path ? (
          <>
            <HereticIllumination path={path.id} />
            <h2>{path.name}</h2>
            {path.tagline ? <p className="HereticBook__lead">{plainText(path.tagline)}</p> : <LoreText text={path.desc} />}
            <PathModel path={path} />
            {!data.selected_path && stages[0] && <ResearchButton knowledge={stages[0]} />}
            {data.selected_path === path.id && <button type="button" className="HereticBook__inscribe" onClick={openKnowledge}>Продолжить изучение</button>}
            <div className={`HereticBook__sides${path.strength_points?.length && path.weakness_points?.length ? '' : ' HereticBook__sides--stacked'}`}>
              <PathSide title="Сильные стороны" points={path.strength_points} fallback={path.strengths} />
              <PathSide title="Слабые стороны" points={path.weakness_points} fallback={path.weaknesses} />
            </div>
            {!!path.practice && <p className="HereticBook__advice"><strong>Совет.</strong> {plainText(path.practice)}</p>}
            {path.innate_name && (
              <details className="HereticBook__innate">
                <summary>Врождённая черта: {path.innate_name}</summary>
                <p>{path.innate_desc}</p>
                <p className="HereticBook__annotation">Действует с выбора пути, без затрат знаний.</p>
              </details>
            )}
            {!data.selected_path && stages.length > 0 && (
              <details className="HereticBook__pathOutline">
                <summary>Знания пути</summary>
                <ol>
                  {stages.map((entry) => <li key={entry.id}><span>{numerals[entry.stage - 1] || entry.stage}. {entry.name}</span><RoleMark role={entry.role} /><span className="HereticBook__leader" /><span>{entry.cost} очк. знаний</span></li>)}
                </ol>
              </details>
            )}
          </>
        ) : <p>Нет доступных путей.</p>}
      </Page>
    </>
  );
};

const GuideMarker = () => <span className="HereticBook__guideMarker" aria-hidden="true" />;

const AbilityList = ({ selectAbility }: { selectAbility: (id: string) => void }) => {
  const { data } = useLoreBackend();
  const abilities = data.combat_abilities || [];
  if (!abilities.length) return null;
  const bound = abilities.filter((ability) => !!ability.hotkey);
  return (
    <details className="HereticBook__guideBlock HereticBook__abilityBlock">
      <summary title={data.ability_hotkey_help || undefined}>
        <GuideMarker />
        <span>Способности ·</span>
        {bound.length
          ? bound.map((ability) => <kbd key={ability.id} className="HereticBook__hotkey" title={ability.name}>{ability.hotkey}</kbd>)
          : <span>{abilities.length}</span>}
      </summary>
      <section aria-label="Доступные боевые способности">
        <div className="HereticBook__abilityLinks">
          {abilities.map((ability) => (
            <button
              key={ability.id}
              type="button"
              className="HereticBook__guideLink HereticBook__abilityLink"
              aria-label={ability.name}
              title={plainText(ability.desc)}
              onClick={() => selectAbility(ability.id)}>
              <span className="HereticBook__abilityHead">
                <span className="HereticBook__abilityName">{ability.name}</span>
                {ability.hotkey && <kbd className="HereticBook__hotkey">{ability.hotkey}</kbd>}
              </span>
              {!!ability.summary && <span className="HereticBook__abilitySummary">{plainText(ability.summary)}</span>}
            </button>
          ))}
        </div>
      </section>
    </details>
  );
};

const KnowledgeGuide = ({ selectKnowledge, selectAbility }: { selectKnowledge: (id: string) => void; selectAbility: (id: string) => void }) => {
  const { data } = useLoreBackend();
  if (!data.selected_path) return null;
  const armor = data.knowledge.find((entry) => entry.starter_armor);
  return (
    <aside className="HereticBook__guide" aria-label="Подсказки по развитию">
      <PreparationSection compact />
      <DeedSection compact />
      <AbilityList selectAbility={selectAbility} />
      {armor && !data.preparation && (
        <section aria-label="Стартовая броня">
          <h3>Стартовая броня</h3>
          <p>{armor.known
            ? 'Рецепт изучен. Проведите обряд со столом и противогазом, затем наденьте мантию и поднимите капюшон.'
            : armor.available
              ? `Рецепт доступен за ${armor.cost} очк. знаний. Можно потратить побочные очки.`
              : armor.reason || `Рецепт откроется на ступени ${armor.stage} пути.`}
          </p>
          <button type="button" className="HereticBook__guideLink" onClick={() => selectKnowledge(armor.id)}>Открыть рецепт брони</button>
        </section>
      )}
    </aside>
  );
};

const KnowledgeEntry = ({ knowledge, recipe }: { knowledge: Knowledge; recipe?: Ritual }) => {
  const structured = !!knowledge.summary;
  return (
    <>
      <p className="HereticBook__runningTitle">{knowledge.kind === 'side' ? 'Побочное знание' : knowledge.kind === 'start' ? 'Начальное знание' : `Ступень ${numerals[knowledge.stage - 1] || knowledge.stage}`}</p>
      <h2>{knowledge.name}</h2>
      <KnowledgeMeta knowledge={knowledge} />
      {structured
        ? <p className="HereticBook__lead">{plainText(knowledge.summary)}</p>
        : knowledge.flavour && <blockquote><LoreText text={knowledge.flavour} /></blockquote>}
      <ResearchButton knowledge={knowledge} />
      <PassiveUpgradeButton knowledge={knowledge} />
      {structured ? <DetailList key={knowledge.id} lines={knowledge.details || []} /> : <LoreText text={knowledge.desc} />}
      <KnowledgeRequirements knowledge={knowledge} />
      <PassiveDetails knowledge={knowledge} />
      {knowledge.kind === 'side' && <p className="HereticBook__annotation">Побочные знания не открывают следующую ступень пути. На них сначала расходуются побочные очки, затем обычные.</p>}
      {recipe && <RitualIngredients ritual={recipe} />}
      {structured && !!knowledge.flavour && <p className="HereticBook__flavour">{plainText(knowledge.flavour)}</p>}
    </>
  );
};

const KnowledgeChapter = ({ turn }: { turn: () => void }) => {
  const { data } = useLoreBackend();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [selectedAbilityId, setSelectedAbilityId] = useState<string | null>(null);
  const selectedAbility = data.combat_abilities?.find((ability) => ability.id === selectedAbilityId);
  const selectKnowledge = (id: string) => { setSelectedId(id); setSelectedAbilityId(null); turn(); };
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
    if (selected) setSelectedId(selected.id);
  }, [selected?.id]);
  const groups = [{ name: 'Ступени пути', entries: main }, { name: 'Побочные знания', entries: side }, { name: 'Начальные знания', entries: starting }];
  return (
    <>
      <Page side="left" chapter="Знания">
        <p className="HereticBook__runningTitle">{data.book?.title || bookTitles[data.selected_path || 'Unbound']}</p>
        <KnowledgeGuide selectKnowledge={selectKnowledge} selectAbility={(id) => { setSelectedAbilityId(id); turn(); }} />
        <h2 className="HereticBook__contentsTitle">Содержание</h2>
        <nav className="HereticBook__contents" aria-label="Дерево знаний">
          {!data.selected_path && <p>Сначала выберите путь в первой главе.</p>}
          {groups.filter((group) => group.entries.length > 0).map((group) => (
            <section key={group.name}>
              <h3>{group.name}</h3>
              {group.entries.map((entry) => (
                <button
                  type="button"
                  key={entry.id}
                  className={`HereticBook__contentsLine${entry.known ? ' HereticBook__contentsLine--known' : ''}${!entry.known && !entry.available ? ' HereticBook__contentsLine--locked' : ''}`}
                  aria-pressed={!selectedAbility && selected?.id === entry.id}
                  aria-label={`${entry.name}, ${entry.known ? 'изучено' : entry.available ? 'доступно' : 'закрыто'}, ${entry.passive ? `пассивка ${entry.passive.level} из ${entry.passive.max_level}` : `${entry.cost} очк. знаний`}${entry.role && roleLabels[entry.role] ? `, ${roleLabels[entry.role].label}` : ''}`}
                  onClick={() => { if (selectedAbility || entry.id !== selected?.id) selectKnowledge(entry.id); }}
                >
                  <span className="HereticBook__indexNumber">{entry.known ? '✓' : entry.kind === 'path' ? numerals[entry.stage - 1] || entry.stage : '·'}</span>
                  <span className="HereticBook__indexName">{entry.name}</span>
                  <RoleMark role={entry.role} />
                  <span className="HereticBook__leader" />
                  <span>{entry.passive ? `${entry.passive.level}/${entry.passive.max_level}` : entry.cost}</span>
                </button>
              ))}
            </section>
          ))}
        </nav>
      </Page>
      <Page side="right" chapter="Знания" entryId={selectedAbility?.id || selected?.id}>
        {selectedAbility ? (
          <>
            <p className="HereticBook__runningTitle">Изученная способность</p>
            <h2>{selectedAbility.name}</h2>
            {selectedAbility.hotkey && <p className="HereticBook__meta"><span>Клавиша</span><kbd className="HereticBook__hotkey">{selectedAbility.hotkey}</kbd></p>}
            <LoreText text={selectedAbility.desc} />
            <h3>Как применить</h3>
            <p>{selectedAbility.usage}</p>
            <p className="HereticBook__annotation">Перезарядка и возможность применения отображаются на кнопке способности на игровом экране.</p>
          </>
        ) : selected ? <KnowledgeEntry knowledge={selected} recipe={recipe} /> : <p>Выберите путь в первой главе, чтобы открыть его знания.</p>}
      </Page>
    </>
  );
};

const RitualChapter = ({ turn }: { turn: () => void }) => {
  const { data } = useLoreBackend();
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const rituals = data.rituals.filter((ritual) => {
    const knowledge = data.knowledge.find((entry) => entry.id === ritual.id);
    return (!knowledge || knowledge.known || knowledge.kind !== 'path' || !data.selected_path || knowledge.path === data.selected_path)
      && `${ritual.name} ${ritual.desc} ${ritual.hint || ''} ${ritual.ingredients.map((item) => item.name).join(' ')}`
        .toLowerCase().includes(search.trim().toLowerCase());
  });
  const selected = rituals.find((ritual) => ritual.id === selectedId) || rituals[0];
  const knowledge = data.knowledge.find((entry) => entry.id === selected?.id);
  useEffect(() => {
    if (selected) setSelectedId(selected.id);
  }, [selected?.id]);
  return (
    <>
      <Page side="left" chapter="Ритуалы">
        <h2>Ритуалы</h2>
        <p className="HereticBook__annotation">Здесь видны и неизученные рецепты. Изучение открывает обряд в меню руны, но предмет не выдаёт.</p>
        <label className="HereticBook__search"><span>Найти запись или ингредиент</span><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Нож, сердце, пепел..." /></label>
        <nav className="HereticBook__contents" aria-label="Ритуалы">
          {rituals.map((ritual, index) => {
            const entry = data.knowledge.find((item) => item.id === ritual.id);
            return (
              <button type="button" key={ritual.id} className="HereticBook__contentsLine" aria-pressed={selected?.id === ritual.id} onClick={() => { if (ritual.id !== selected?.id) { setSelectedId(ritual.id); turn(); } }}>
                <span className="HereticBook__indexNumber">{index + 1}</span><span className="HereticBook__indexName">{ritual.name}</span><span className="HereticBook__leader" /><span>{entry?.known ? 'Изучено' : entry ? 'Не изучено' : '→'}</span>
              </button>
            );
          })}
        </nav>
        {!rituals.length && <p>{search ? 'Такой записи нет. Попробуйте другое название или ингредиент.' : 'Изучайте знания, чтобы открыть ритуалы.'}</p>}
        <ul className="HereticBook__details HereticBook__ritualRules" aria-label="Как провести обряд">
          <li>Начертите руну кодексом на полу 3×3 без стен, космоса, лавы и соседних рун.</li>
          <li>Компоненты кладите на пол в пределах руны 3×3, углы тоже считаются.</li>
          <li>Предметы в руках, на теле и в сумках не считаются.</li>
          <li>Нажмите на центр руны пустой рукой, выберите обряд и не двигайтесь до конца.</li>
        </ul>
      </Page>
      <Page side="right" chapter="Ритуалы" entryId={selected?.id}>
        {selected ? (
          <>
            <p className="HereticBook__runningTitle">{selected.ascension ? 'Последний обряд' : 'Рецепт трансмутации'}</p>
            <h2>{selected.name}</h2>
            {knowledge?.summary ? <p className="HereticBook__lead">{plainText(selected.desc)}</p> : <LoreText text={selected.desc} />}
            {knowledge && !knowledge.known && (
              <>
                <p className="HereticBook__annotation">Рецепт ещё не изучен. {knowledge.kind === 'path' && `Путь: ${data.paths.find((path) => path.id === knowledge.path)?.name || knowledge.path}. `}Изучение открывает обряд в меню руны.</p>
                <KnowledgeRequirements knowledge={knowledge} showCost />
                <ResearchButton knowledge={knowledge} />
              </>
            )}
            {!!knowledge?.known && <p className="HereticBook__learned">Изучено · обряд доступен на руне</p>}
            <RitualIngredients ritual={selected} />
            {!!selected.ascension && <p>Принесите {data.hunt.sacrifices_required} {countNoun(data.hunt.sacrifices_required, ['назначенную душу', 'назначенные души', 'назначенных душ'])} и изучите последнее знание. Обряд вознесения занимает 30 секунд; его подношения не возвращаются.</p>}
          </>
        ) : <p className="HereticBook__annotation">Нет ритуалов для просмотра.</p>}
      </Page>
    </>
  );
};

const PreparationSection = ({ heartOnly = false, compact = false }: { heartOnly?: boolean; compact?: boolean }) => {
  const { data, act } = useLoreBackend();
  const preparation = data.preparation;
  if (!preparation) return null;
  const entries = heartOnly ? [] : [
    { name: 'Клинок', ready: preparation.blade_ready, status: preparation.blade_status },
    { name: 'Броня', ready: preparation.armor_ready, status: preparation.armor_status },
  ];
  const content = (
    <section aria-label={heartOnly ? 'Своё живое сердце' : 'Подготовка к охоте'}>
      <h3>{heartOnly ? 'Своё живое сердце' : 'Подготовка к охоте'}</h3>
      {entries.map((entry) => (
        <p key={entry.name}><strong>{entry.ready ? '✓' : '○'} {entry.name}.</strong> {entry.status}</p>
      ))}
      <p><strong>{preparation.heart.ready ? '✓' : '○'} Сердце.</strong> {preparation.heart.status}</p>
      <button type="button" className="HereticBook__inscribe" disabled={!preparation.heart.can_call} onClick={() => act('call_heart')}>
        {preparation.heart.action_label}
      </button>
      <button type="button" className="HereticBook__guideLink" onClick={() => act('refresh_preparation')}>Проверить подготовку</button>
    </section>
  );
  if (!compact) return content;
  const ready = Number(!!preparation.blade_ready) + Number(!!preparation.armor_ready) + Number(!!preparation.heart.ready);
  return <details className="HereticBook__guideBlock"><summary><GuideMarker />Подготовка к охоте · {ready}/3</summary>{content}</details>;
};

const DeedCombatStep = ({ deed }: { deed: NonNullable<ForbiddenLoreData['deed']> }) => (
  <div aria-label="Боевой шаг дела">
    <p><strong>Альтернатива - охота:</strong> {deed.combat_hint}</p>
    <p className="HereticBook__annotation">{deed.combat_available
      ? 'Заменяет один шаг этой ступени. Каждая душа засчитывается только один раз за всё дело.'
      : 'Боевой шаг этой ступени уже засчитан. Продолжите обычное дело пути.'}
    </p>
  </div>
);

const DeedSection = ({ compact = false }: { compact?: boolean }) => {
  const { data } = useLoreBackend();
  const deed = data.deed;
  if (!deed) return <p>Дело появится после выбора пути.</p>;
  const done = deed.tier >= deed.max_tier;
  const progress = <p>{done ? 'Завершено.' : <>Ступень <strong>{deed.tier + 1}</strong> из <strong>{deed.max_tier}</strong> · <strong>{deed.progress}</strong> из <strong>{deed.goal}</strong></>}</p>;
  if (compact) {
    return (
      <section aria-label="Дело пути">
        {done ? <p className="HereticBook__deedRow"><span className="HereticBook__deedName">{deed.name}</span><span>Завершено.</span></p> : (
          <details className="HereticBook__guideBlock HereticBook__deedBlock">
            <summary className="HereticBook__deedRow" title={deed.next_step || plainText(deed.desc)}>
              <GuideMarker />
              <span className="HereticBook__deedName">{deed.name}</span>
              <span className="HereticBook__deedStep">{deed.next_step || plainText(deed.desc)}</span>
              <span className="HereticBook__deedCount">{deed.progress}/{deed.goal}</span>
            </summary>
            <h3>Дело пути · {deed.name}</h3>
            {!!deed.next_step && <p><strong>Следующий шаг:</strong> {deed.next_step}</p>}
            {!!deed.next_step && <LoreText text={deed.desc} />}
            {progress}
            <p>Завершите ступень, чтобы получить очко знаний.</p>
            {deed.combat_hint && <DeedCombatStep deed={deed} />}
          </details>
        )}
      </section>
    );
  }
  return (
    <section aria-label="Дело пути">
      <h3>{deed.name}</h3>
      <LoreText text={deed.desc} />
      {!done && deed.next_step && <p><strong>Следующий шаг:</strong> {deed.next_step}</p>}
      {deed.hint && <p className="HereticBook__annotation">{deed.hint}</p>}
      {progress}
      {!done && deed.combat_hint && <DeedCombatStep deed={deed} />}
      <div className="HereticBook__soulMarks" aria-label={`Ступеней дела: ${deed.tier} из ${deed.max_tier}`}>
        {Array.from({ length: deed.max_tier }, (_, index) => <span key={index} className={index < deed.tier ? 'HereticBook__soulMarks--filled' : ''}>◇</span>)}
      </div>
    </section>
  );
};

const HuntChapter = ({ retargetDeadline, openHelp }: { retargetDeadline: number; openHelp: (topic: HelpTopicId) => void }) => {
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
      <Page side="left" chapter="Охота">
        <h2>Цель охоты</h2>
        <div className="HereticBook__target">
          <h3>{hunt.target_name || 'Цель не выбрана'}</h3>
          {hunt.target_role && <p>{hunt.target_role}</p>}
          <p className="HereticBook__annotation">{hunt.target_status}</p>
        </div>
        <button type="button" className="HereticBook__inscribe" disabled={!canRetarget} onClick={() => act('retarget')}>
          {hunt.target_name ? 'Сменить цель' : 'Выбрать цель'}
        </button>
        {!canRetarget && <p className="HereticBook__annotation">Смена цели через {remaining} сек.</p>}
        <PreparationSection heartOnly />
        <ul className="HereticBook__details">
          <li>Сожмите живое сердце в руке: оно покажет направление к цели.</li>
          <li>Alt-ЛКМ по сердцу меняет цель, касание сердцем поверженного делает целью его. Смена - раз в 3 минуты.</li>
        </ul>
        <h2>Дело пути</h2>
        <DeedSection />
      </Page>
      <Page side="right" chapter="Охота">
        <h2>Жертвоприношение</h2>
        <p>Принесено жертв: <strong>{data.total_sacrifices}</strong> из <strong>{hunt.sacrifices_required}</strong>.</p>
        <div className="HereticBook__soulMarks" aria-label={`Принято душ: ${data.total_sacrifices} из ${hunt.sacrifices_required}`}>
          {Array.from({ length: hunt.sacrifices_required }, (_, index) => <span key={index} className={index < data.total_sacrifices ? 'HereticBook__soulMarks--filled' : ''}>◇</span>)}
        </div>
        <ul className="HereticBook__details">
          <li>Обезвредьте цель и коснитесь её живым сердцем или положите на руну рядом с сердцем.</li>
          <li>Живая цель даёт 2 очка знаний и 1 побочное, труп - 1 очко.</li>
        </ul>
        <button type="button" className="HereticBook__guideLink" onClick={() => openHelp('hunt')}>Все правила жертвы - в Помощи</button>
        <h3>Разломы</h3>
        <p>Изучено {hunt.influences_harvested} из {hunt.influence_limit}. {hunt.influences_harvested >= hunt.influence_limit ? 'Лимит достигнут. Получайте новые знания за жертвоприношения.' : 'Используйте Кодекс на разломе, чтобы получить знания.'}</p>
        <InfluenceSchedule hunt={hunt} />
      </Page>
    </>
  );
};

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
      <Page side="left" chapter="Помощь">
        <h2>Как играть</h2>
        <HelpTopic id="start" title="Начало" open={topic === 'start'}>
          <ul className="HereticBook__details">
            <li>Выберите путь в главе Путь. Первое знание бесплатно, сменить путь нельзя.</li>
            <li>Очки знаний дают разломы, жертвы и дело пути. Тратьте их в главе Знания.</li>
            <li>Руну чертят кодексом 8 секунд на полу 3×3 без стен, космоса, лавы и соседних рун.</li>
            <li>Кодекс или Хватка Мансуса стирают руну, заряд хватки не тратится.</li>
            <li>Потерянный кодекс возвращает способность Зов к кодексу, прогресс не теряется.</li>
          </ul>
          <RitualDiagram />
        </HelpTopic>
        <HelpTopic id="path" title="Путь и знания" open={topic === 'path'}>
          <ul className="HereticBook__details">
            <li>Ступени пути открываются по порядку, побочные знания - после нужной ступени.</li>
            <li>Изучение рецепта не выдаёт предмет: проведите обряд на руне из главы Ритуалы.</li>
            <li>Броню даёт Ритуал оружейника со второй ступени: стол и противогаз становятся мантией.</li>
            <li>Пассивку пути можно улучшить дважды: за 1 и за 2 очка, сначала тратятся побочные.</li>
            <li>Хватка ставит метку, удар клинком её взрывает; по вещам и полу она работает тихо, без заклинания вслух. Запас силы пути - внизу левой страницы.</li>
          </ul>
        </HelpTopic>
        <HelpTopic id="rifts" title="Разломы" open={topic === 'rifts'}>
          <p>Примените кодекс к разлому и дождитесь конца изучения. За раунд можно изучить {hunt.influence_limit} {countNoun(hunt.influence_limit, ['разлом', 'разлома', 'разломов'])}.</p>
          <InfluenceSchedule hunt={hunt} />
          <ul className="HereticBook__details">
            <li>Чужое изучение не забирает ваши очки, поздние еретики тоже находят разломы.</li>
            <li>След разлома держится 3 минуты. Нейтрализатор аномалий превращает его в кристалл завесы.</li>
            <li>Раздавленный кристалл 20 секунд лечит раны и выносливость, второй сразу не сработает.</li>
          </ul>
        </HelpTopic>
        <HelpTopic id="hunt" title="Охота и жертва" open={topic === 'hunt'}>
          <ul className="HereticBook__details">
            <li>Цель назначают в главе Охота или сердцем. Сердце ведёт к ней, Alt-ЛКМ меняет цель раз в 3 минуты.</li>
            <li>Годится цель в наручниках, оглушённая, сбитая с ног или без сознания, в крите - и без наручников. Сама легшая или уснувшая не в счёт, еретики и их слуги тоже.</li>
            <li>После захвата пути цель к нему невосприимчива: минуту после полного, 10 секунд после сорванного сразу. Сорванный ещё на предупреждении ничего не даёт цели, а вам возвращает перезарядку.</li>
            <li>Коснитесь цели сердцем или положите её с сердцем на руну и стойте 8 секунд. Перенос жертвы или прерывание срывают обряд. Без свидетелей - в <button type="button" className="HereticBook__guideLink" onClick={() => openHelp('pocket')}>изнанке</button>.</li>
            <li>Живая жертва даёт 2 очка и 1 побочное и вернётся через Мансус, труп - 1 очко. Одна душа - один раз.</li>
          </ul>
        </HelpTopic>
        <HelpTopic id="pocket" title="Изнанка" open={topic === 'pocket'}>
          <ul className="HereticBook__details">
            <li>Изнанка - ваша карманная комната: дверь пути уводит туда цель охоты вместе с вами. Живое сердце предлагает дверь пути, когда вы касаетесь им цели; дверь, которая работает издалека, можно выбрать и сжав сердце - рядом с «Найти цель». Пока вы выбираете дверь и тянете цель, сердце прижимает её к полу до {pocket.grip} сек.: касанием в «Помощи» её не поднять, растолкать можно за {pocket.shake} сек., нулевой жезл снимает хватку сразу. Внутри цель {pocket.hold} сек. не может двинуться.</li>
            <li>Общая дверь: если цель повержена на вашей руне или рядом, коснитесь руны в «Помощи» и выберите «Увести за руну», увод займёт {pocket.pull} сек.</li>
            <li>Изнанка держится {pocket.duration} сек., за {pocket.warning} до конца - предупреждение. Ваш крит закрывает её сразу, и все выпадают у входа.</li>
            <li>«Покинуть изнанку» выводит к вашим рунам, ремеслу пути, ко входу или туда, где вы стояли, если тянули цель издалека. Если разрыв закрыли или время вышло, вас выносит к вашему выходу подальше от входа. Цель и вещи выпадают у входа, ваши сердце и кодекс, оставленные на полу, уходят за завесу, а тёмные клинки выносит вместе с вами.</li>
            <li>У входа остаётся разрыв: жезл или Библия закрывают его сразу, руками его можно разорвать за {pocket.tear} сек. Снова открыть изнанку можно через {pocket.cooldown} сек.</li>
          </ul>
        </HelpTopic>
        <HelpTopic id="mansus" title="Мансус" open={topic === 'mansus'}>
          <ul className="HereticBook__details">
            <li>Живая жертва проходит Дом памяти: лабиринт комнат с правилом вашего пути.</li>
            <li>Три осколка нужно донести до печати перед вратами. Через 3 минуты Дом отпускает сам.</li>
            <li>Жертва возвращается в коридор станции и помнит Дом, но не ваше лицо и имя.</li>
          </ul>
        </HelpTopic>
      </Page>
      <Page side="right" chapter="Помощь">
        <h2>Риски и цель</h2>
        <HelpTopic id="custody" title="Удержание СБ" open={topic === 'custody'}>
          <ul className="HereticBook__details">
            <li>В наручниках и смирительной рубашке магия, обряды и побег клинком недоступны.</li>
            <li>Имплант защиты разума глушит их, пока стоит; снять его можно только хирургически.</li>
            <li>Побочное знание Разум за завесой снимает действие щита, вознёсшегося щит не держит.</li>
            <li>Разбитый клинок переносит в безопасное место, следующий побег - через 10 секунд.</li>
            <li>Стан культа крови сбивает еретика на 2 секунды и оглушает на 1.</li>
          </ul>
        </HelpTopic>
        <HelpTopic id="ascension" title="Вознесение" open={topic === 'ascension'}>
          <p>Совершите {hunt.sacrifices_required} {countNoun(hunt.sacrifices_required, ['жертвоприношение', 'жертвоприношения', 'жертвоприношений'])} и изучите последнее знание пути.</p>
          <ul className="HereticBook__details">
            <li>Принесите на руну {bodies} {countNoun(bodies, ['труп', 'трупа', 'трупов'])} экипажа, которыми управлял человек; выбранные тела подсвечиваются зелёным. Обряд 30 секунд.</li>
            <li>После второй жертвы станцию предупреждают; вознестись можно через 3 минуты после этого.</li>
            <li>Каждая попытка объявляется станции, между попытками не меньше 3 минут. Руна - в помещении, не в космосе.</li>
            <li>Вознестись могут несколько еретиков. После вознесения побег клинком закрыт.</li>
          </ul>
        </HelpTopic>
        <HelpTopic id="deed" title="Дело пути" open={topic === 'deed'}>
          <p>Дело состоит из {deedTiers} {countNoun(deedTiers, ['ступени', 'ступеней', 'ступеней'])}: каждая даёт 1 очко знаний, вторая и третья - ещё по 1 побочному.</p>
          <ul className="HereticBook__details">
            <li>Дело не связано с боем, его шаги видны в главе Охота.</li>
            <li>Каждый засчитанный шаг восполняет запас силы и оставляет след, который может найти экипаж.</li>
          </ul>
        </HelpTopic>
        <HelpTopic id="hotkeys" title="Горячие клавиши" open={topic === 'hotkeys'}>
          <ul className="HereticBook__details">
            {data.ability_hotkey_help && <li>{data.ability_hotkey_help}</li>}
            <li>Подготовка контактной или прицельной способности выключает режим броска, включение броска её снимает.</li>
            <li>Нажатие на значок запаса силы среди уведомлений экрана применяет силу пути.</li>
          </ul>
        </HelpTopic>
      </Page>
    </>
  );
};

export const ForbiddenLoreContent = () => {
  const { data, config, act } = useLoreBackend();
  const retargetDeadline = useMemo(() => Date.now() + data.hunt.retarget_seconds * 1000, [data.hunt]);
  const reading = useBookPresentation(config.client?.ckey);
  const handlePresentationChange = reading.choose;
  const [chapter, setChapter] = useState<Chapter>(data.selected_path ? 'Знания' : 'Путь');
  const [helpTopic, setHelpTopic] = useState<HelpTopicId>('start');
  const [turnCount, setTurnCount] = useState(0);
  useEffect(() => {
    setTurnCount(0);
  }, [reading.effectivePresentation, reading.reducedMotion]);
  const bookmarks = useRef<Array<HTMLButtonElement | null>>([]);
  const skin = data.book?.path || data.selected_path || 'Unbound';
  const turn = (next: Chapter = chapter) => {
    if (reading.effectivePresentation === 'living' && !reading.reducedMotion) {
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
    <div style={{ '--book-material': skin === 'Unbound' ? undefined : `url("${resolveAsset(`heretic-${skin.toLowerCase()}.webp`)}")` } as CSSProperties} className={`HereticBook HereticBook--${skin}`} data-book-path={skin} data-book-view={reading.effectivePresentation} data-book-motion={reading.reducedMotion ? 'reduced' : 'full'}>
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
        <main key={chapter} id="heretic-book-spread" className="HereticBook__spread" role="tabpanel" aria-label={chapter}>
          {chapter === 'Путь' && <PathChapter turn={turn} openKnowledge={() => open('Знания')} />}
          {chapter === 'Знания' && <KnowledgeChapter turn={turn} />}
          {chapter === 'Ритуалы' && <RitualChapter turn={turn} />}
          {chapter === 'Охота' && <HuntChapter retargetDeadline={retargetDeadline} openHelp={openHelp} />}
          {chapter === 'Помощь' && <HelpChapter topic={helpTopic} openHelp={openHelp} />}
          <div className="HereticBook__spine" aria-hidden="true" />
          {turnCount > 0 && reading.effectivePresentation === 'living' && !reading.reducedMotion && <div key={turnCount} className="HereticBook__turningLeaf" aria-hidden="true" onAnimationEnd={() => setTurnCount(0)} />}
        </main>
        <HereticBookAtmosphere path={skin} presentation={reading.effectivePresentation} reducedMotion={reading.reducedMotion} />
        {(skin === 'Unbound' || reading.effectivePresentation === 'plain') && <div className="HereticBook__clasp" aria-hidden="true" />}
      </div>
      <div className="HereticBook__toolbar">
        {!!data.ascended && <div className="HereticBook__ascended">Вы достигли вознесения.</div>}
        <HereticBookPreferences presentation={reading.presentation} reducedMotion={reading.reducedMotion} onChange={handlePresentationChange} />
      </div>
    </div>
  );
};

export const ForbiddenLore = () => {
  const { data } = useLoreBackend();
  return <Window width={960} height={800} title={data.book?.title || 'Кодекс Рубцов'} theme="heretic"><Window.Content fitted><ForbiddenLoreContent /></Window.Content></Window>;
};
