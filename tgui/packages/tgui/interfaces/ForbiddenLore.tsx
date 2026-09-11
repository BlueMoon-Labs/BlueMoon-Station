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
  strengths: string[];
  weaknesses: string[];
};

type Knowledge = {
  id: string;
  name: string;
  desc: string;
  flavour: string;
  cost: number;
  sacrifices: number;
  path: string;
  stage: number;
  known: BooleanLike;
  available: BooleanLike;
  reason: string;
  kind: 'path' | 'side' | 'start';
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
  ascension: BooleanLike;
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
  combat_resource: { name: string; value: number; max: number; description: string } | null;
  deed: { name: string; desc: string; hint: string; tier: number; max_tier: number; progress: number; goal: number; counted: number } | null;
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
      rituals: data.knowledge_state
        ? data.rituals.filter((ritual) => data.knowledge_state![ritual.id]?.known)
        : data.rituals,
    },
  };
};

const chapters = ['Путь', 'Знания', 'Ритуалы', 'Охота', 'Помощь'] as const;
type Chapter = typeof chapters[number];
const numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X', 'XI', 'XII'];
const bookTitles: Record<string, string> = {
  Unbound: 'Кодекс Рубцов', Ash: 'Псалтирь последнего огня', Rust: 'Железный завет',
  Flesh: 'Анатомия голода', Void: 'Палимпсест зимы', Blade: 'Трактат о последнем ударе',
  Moon: 'Зерцало без лица', Cosmic: 'Атлас внутреннего неба',
  Lock: 'Каталог невозможных дверей', Tide: 'Лоция бездонного моря',
  Glass: 'Евангелие разбитого света', Blood: 'Служебник алой десятины',
  Echo: 'Партитура последнего голоса',
};

const countNoun = (amount: number, forms: [string, string, string]) => {
  const count = Math.abs(amount) % 100;
  if (count >= 11 && count <= 14) return forms[2];
  if (count % 10 === 1) return forms[0];
  if (count % 10 >= 2 && count % 10 <= 4) return forms[1];
  return forms[2];
};

const InfluenceSchedule = ({ hunt }: { hunt: ForbiddenLoreData['hunt'] }) => {
  const initial = hunt.influence_initial_count ?? 3;
  const interval = hunt.influence_interval_minutes ?? 8;
  return <p>В начале раунда — {initial} {countNoun(initial, ['разлом', 'разлома', 'разломов'])}. Затем каждые {interval} мин. появляется ещё один.</p>;
};

const LoreText = ({ text }: { text: string }) => (
  <div className="HereticBook__prose">
    {decodeHtmlEntities(sanitizeText((text || '').replace(/<br\s*\/?>/gi, '\n'), false, []))}
  </div>
);

const ResearchButton = ({ knowledge }: { knowledge: Knowledge }) => {
  const { data, act } = useLoreBackend();
  if (knowledge.known) {
    return <p className="HereticBook__learned">Изучено</p>;
  }
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

const PassiveResearch = ({ knowledge }: { knowledge: Knowledge }) => {
  const { data, act } = useLoreBackend();
  const passive = knowledge.passive;
  if (!passive && !knowledge.passive_description) return null;
  const maxed = !!passive && passive.level >= passive.max_level;
  const canAfford = !!passive && data.points + (data.side_points || 0) >= passive.cost;
  return (
    <section className="HereticBook__research" aria-label="Прокачка пассивки">
      <h3>Пассивка{passive ? ` · ${passive.level} / ${passive.max_level}` : ''}</h3>
      <LoreText text={passive?.description || knowledge.passive_description || ''} />
      {passive && !maxed && (
        <button
          type="button"
          className="HereticBook__inscribe"
          disabled={!passive.available || !canAfford}
          onClick={() => act('upgrade_passive', { id: knowledge.id, level: passive.level })}
        >
          Улучшить до {passive.level + 1} · {passive.cost} очк. знаний
        </button>
      )}
      {maxed ? (
        <p className="HereticBook__learned">Максимальный уровень пассивки</p>
      ) : (
        <p className="HereticBook__annotation" role="status">
          {passive?.reason || (passive && !canAfford ? `Не хватает очков знаний: нужно ${passive.cost}.`
            : !passive ? 'Сначала изучите знание, чтобы открыть улучшения.' : 'Второй уровень стоит 1 очко, третий — 2. Сначала расходуются побочные очки, затем обычные. Улучшение не продвигает по ступеням пути.')}
        </p>
      )}
    </section>
  );
};

const Ledger = () => {
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
      {resource && (
        <div className="HereticBook__resource">
          <details>
            <summary><span>{resource.name}</span><strong>{resource.value} / {resource.max}</strong></summary>
            <p>{resource.description}</p>
          </details>
          <meter min={0} max={Math.max(1, resource.max)} value={resource.value} aria-label={resource.name} />
        </div>
      )}
      {deed && (
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
      && document.activeElement?.closest('.HereticBook__contentsLine, .HereticBook__oath')) {
      scroll.scrollIntoView({ block: 'start', inline: 'nearest' });
    }
    measureScroll();
  }, [entryId]);
  return (
    <article className={`HereticBook__page HereticBook__page--${side}`} aria-label={side === 'left' ? 'Левая страница' : 'Правая страница'}>
      <HereticPageOrnament path={data.book?.path || data.selected_path || 'Unbound'} />
      <div className="HereticBook__pageBody">
        <div className="HereticBook__pageScroll" ref={scrollRef} onScroll={measureScroll} tabIndex={0} aria-label={side === 'left' ? 'Текст левой страницы' : 'Текст правой страницы'}>
          <div ref={writingRef}>{children}</div>
        </div>
        <div className="HereticBook__scrollHint" aria-hidden="true">{scrollState.below ? '↓ Дальше по странице' : scrollState.above ? '↑ Начало страницы' : '\u00a0'}</div>
        {side === 'left' && <Ledger />}
        <footer className="HereticBook__folio"><span>{chapter}</span><span>{chapters.indexOf(chapter) * 2 + (side === 'left' ? 1 : 2)}</span></footer>
      </div>
    </article>
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
            <LoreText text={path.desc} />
            <dl className="HereticBook__promises">
              <dt>Преимущества</dt><dd>{path.strengths.map((text) => <p key={text}>{text}</p>)}</dd>
              <dt>Слабости</dt><dd>{path.weaknesses.map((text) => <p key={text}>{text}</p>)}</dd>
            </dl>
            {!data.selected_path && stages[0] && <ResearchButton knowledge={stages[0]} />}
            {data.selected_path === path.id && <button type="button" className="HereticBook__inscribe" onClick={openKnowledge}>Продолжить изучение</button>}
            {!data.selected_path && stages.length > 0 && (
              <details className="HereticBook__pathOutline">
                <summary>Знания пути</summary>
                <ol>
                  {stages.map((entry) => <li key={entry.id}><span>{numerals[entry.stage - 1] || entry.stage}. {entry.name}</span><span className="HereticBook__leader" /><span>{entry.cost} очк. знаний</span></li>)}
                </ol>
              </details>
            )}
          </>
        ) : <p>Нет доступных путей.</p>}
      </Page>
    </>
  );
};

const KnowledgeChapter = ({ turn }: { turn: () => void }) => {
  const { data } = useLoreBackend();
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const main = data.knowledge.filter((entry) => entry.kind === 'path' && entry.path === data.selected_path)
    .sort((a, b) => a.stage - b.stage);
  const side = data.knowledge.filter((entry) => entry.kind === 'side')
    .sort((a, b) => a.stage - b.stage || a.cost - b.cost || a.name.localeCompare(b.name));
  const starting = data.knowledge.filter((entry) => entry.kind === 'start');
  const visible = [...main, ...side, ...starting];
  const selected = visible.find((entry) => entry.id === selectedId)
    || main.find((entry) => !entry.known) || visible.find((entry) => entry.available) || visible[0];
  useEffect(() => {
    if (selected) setSelectedId(selected.id);
  }, [selected?.id]);
  const groups = [{ name: 'Ступени пути', entries: main }, { name: 'Побочные знания', entries: side }, { name: 'Начальные знания', entries: starting }];
  return (
    <>
      <Page side="left" chapter="Знания">
        <p className="HereticBook__runningTitle">{data.book?.title || bookTitles[data.selected_path || 'Unbound']}</p>
        <h2>Содержание</h2>
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
                  aria-pressed={selected?.id === entry.id}
                  aria-label={`${entry.name}, ${entry.known ? 'изучено' : entry.available ? 'доступно' : 'закрыто'}, ${entry.passive ? `пассивка ${entry.passive.level} из ${entry.passive.max_level}` : `${entry.cost} очк. знаний`}`}
                  onClick={() => { if (entry.id !== selected?.id) { setSelectedId(entry.id); turn(); } }}
                >
                  <span className="HereticBook__indexNumber">{entry.known ? '✓' : entry.kind === 'path' ? numerals[entry.stage - 1] || entry.stage : '·'}</span>
                  <span className="HereticBook__indexName">{entry.name}</span>
                  <span className="HereticBook__leader" />
                  <span>{entry.passive ? `${entry.passive.level}/${entry.passive.max_level}` : entry.cost}</span>
                </button>
              ))}
            </section>
          ))}
        </nav>
      </Page>
      <Page side="right" chapter="Знания" entryId={selected?.id}>
        {selected ? (
          <>
            <p className="HereticBook__runningTitle">{selected.kind === 'side' ? 'Побочное знание' : selected.kind === 'start' ? 'Начальное знание' : `Ступень ${numerals[selected.stage - 1] || selected.stage}`}</p>
            <h2>{selected.name}</h2>
            {selected.flavour && <blockquote><LoreText text={selected.flavour} /></blockquote>}
            <LoreText text={selected.desc} />
            <dl className="HereticBook__requirements">
              <dt>Стоимость</dt><dd>{selected.cost} очк. знаний</dd>
              {selected.sacrifices > 0 && <><dt>Жертвоприношения</dt><dd>{selected.sacrifices}</dd></>}
              {selected.kind === 'side' && selected.stage > 0 && <><dt>Ступень пути</dt><dd>{selected.stage}</dd></>}
            </dl>
            <ResearchButton knowledge={selected} />
            <PassiveResearch knowledge={selected} />
            {selected.kind === 'side' && <p className="HereticBook__annotation">Побочные знания не открывают следующую ступень пути. На них сначала расходуются очки для побочных знаний, затем обычные.</p>}
          </>
        ) : <p>Выберите путь в первой главе, чтобы открыть его знания.</p>}
      </Page>
    </>
  );
};

const RitualChapter = ({ turn }: { turn: () => void }) => {
  const { data } = useLoreBackend();
  const [search, setSearch] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const rituals = data.rituals.filter((ritual) => `${ritual.name} ${ritual.desc} ${ritual.ingredients.map((item) => item.name).join(' ')}`
    .toLowerCase().includes(search.trim().toLowerCase()));
  const selected = rituals.find((ritual) => ritual.id === selectedId) || rituals[0];
  useEffect(() => {
    if (selected) setSelectedId(selected.id);
  }, [selected?.id]);
  return (
    <>
      <Page side="left" chapter="Ритуалы">
        <h2>Ритуалы</h2>
        <label className="HereticBook__search"><span>Найти запись или ингредиент</span><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Нож, сердце, пепел…" /></label>
        <nav className="HereticBook__contents" aria-label="Ритуалы">
          {rituals.map((ritual, index) => (
            <button type="button" key={ritual.id} className="HereticBook__contentsLine" aria-pressed={selected?.id === ritual.id} onClick={() => { if (ritual.id !== selected?.id) { setSelectedId(ritual.id); turn(); } }}>
              <span className="HereticBook__indexNumber">{index + 1}</span><span className="HereticBook__indexName">{ritual.name}</span><span className="HereticBook__leader" /><span>→</span>
            </button>
          ))}
        </nav>
        {!rituals.length && <p>{search ? 'Такой записи нет. Попробуйте другое название или ингредиент.' : 'Изучайте знания, чтобы открыть ритуалы.'}</p>}
        <p className="HereticBook__annotation">Начертите руну Кодексом и положите на неё ингредиенты. Нажмите на руну пустой рукой, чтобы выбрать ритуал.</p>
      </Page>
      <Page side="right" chapter="Ритуалы" entryId={selected?.id}>
        {selected ? (
          <>
            <p className="HereticBook__runningTitle">{selected.ascension ? 'Последний обряд' : 'Рецепт трансмутации'}</p>
            <h2>{selected.name}</h2>
            <LoreText text={selected.desc} />
            <h3 className="HereticBook__ingredientsTitle">Положить на руну</h3>
            <ul className="HereticBook__ingredients">
              {selected.ingredients.map((item, index) => <li key={`${item.name}-${index}`}><span>{item.name}</span><span className="HereticBook__leader" /><strong>×{item.amount}</strong></li>)}
            </ul>
            <p className="HereticBook__annotation">Оставайтесь рядом с руной до окончания ритуала.</p>
            {!!selected.ascension && <p>Принесите {data.hunt.sacrifices_required} назначенных душ и изучите последнее знание. Обряд вознесения занимает 30 секунд; его подношения не возвращаются.</p>}
          </>
        ) : <p className="HereticBook__annotation">Нет ритуалов для просмотра.</p>}
      </Page>
    </>
  );
};

const DeedSection = () => {
  const { data } = useLoreBackend();
  const deed = data.deed;
  if (!deed) return <p>Дело появится после выбора пути.</p>;
  const done = deed.tier >= deed.max_tier;
  return (
    <section aria-label="Дело пути">
      <h3>{deed.name}</h3>
      <LoreText text={deed.desc} />
      {deed.hint && <p className="HereticBook__annotation">{deed.hint}</p>}
      <p>{done ? 'Завершено.' : <>Ступень <strong>{deed.tier + 1}</strong> из <strong>{deed.max_tier}</strong> · <strong>{deed.progress}</strong> из <strong>{deed.goal}</strong></>}</p>
      <div className="HereticBook__soulMarks" aria-label={`Ступеней дела: ${deed.tier} из ${deed.max_tier}`}>
        {Array.from({ length: deed.max_tier }, (_, index) => <span key={index} className={index < deed.tier ? 'HereticBook__soulMarks--filled' : ''}>◇</span>)}
      </div>
    </section>
  );
};

const HuntChapter = ({ retargetDeadline }: { retargetDeadline: number }) => {
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
        <p className="HereticBook__annotation">Активируйте живое сердце в руке, чтобы узнать направление к цели. Alt-ЛКМ по сердцу позволяет сменить цель.</p>
        <h2>Дело пути</h2>
        <DeedSection />
      </Page>
      <Page side="right" chapter="Охота">
        <h2>Жертвоприношение</h2>
        <p>Принесено жертв: <strong>{data.total_sacrifices}</strong> из <strong>{hunt.sacrifices_required}</strong>.</p>
        <div className="HereticBook__soulMarks" aria-label={`Принято душ: ${data.total_sacrifices} из ${hunt.sacrifices_required}`}>
          {Array.from({ length: hunt.sacrifices_required }, (_, index) => <span key={index} className={index < data.total_sacrifices ? 'HereticBook__soulMarks--filled' : ''}>◇</span>)}
        </div>
        <ol className="HereticBook__steps">
          <li>Доставьте названную цель к руне. Живую цель достаточно связать наручниками, оглушить или сбить с ног. Хватка Мансуса помогает в захвате. Если назначенная цель погибла, подойдёт её труп.</li>
          <li>Положите рядом своё живое сердце. Выберите «Обряд возвращения» и сохраняйте неподвижность 8 секунд. Живую жертву руна удержит и защитит от кровотечения. Перемещение жертвы или прерывание еретика срывает обряд.</li>
          <li>Живая жертва даёт 2 очка знаний и 1 побочное, проходит через Мансус и возвращается живой на станцию не позднее чем через 45 секунд. Труп даёт только 1 очко знаний без побочного и остаётся на месте для возможной реанимации. Оба варианта засчитываются для вознесения. Одна душа принимается лишь однажды, даже после реанимации.</li>
        </ol>
        <h3>Разломы</h3>
        <p>Изучено {hunt.influences_harvested} из {hunt.influence_limit}. {hunt.influences_harvested >= hunt.influence_limit ? 'Лимит достигнут. Получайте новые знания за жертвоприношения.' : 'Используйте Кодекс на разломе, чтобы получить знания.'}</p>
        <InfluenceSchedule hunt={hunt} />
      </Page>
    </>
  );
};

const HelpChapter = () => {
  const { data } = useLoreBackend();
  const deedTiers = data.hunt.deed_tiers ?? 3;
  return (
    <>
      <Page side="left" chapter="Помощь">
        <h2>С чего начать</h2>
        <h3>Выберите путь</h3>
        <p>В главе «Путь» сравните способности и подтвердите выбор. Первое знание бесплатно, сменить путь нельзя. Все его ступени и побочные знания доступны в главе «Знания».</p>
        <h3>Изучите разломы</h3>
        <p>Используйте Кодекс на разломе и дождитесь окончания изучения. За раунд можно изучить {data.hunt.influence_limit} {countNoun(data.hunt.influence_limit, ['разлом', 'разлома', 'разломов'])}. Потеря книги не стирает вашу память.</p>
        <InfluenceSchedule hunt={data.hunt} />
        <p>Новые разломы доступны и тем, кто стал еретиком позднее.</p>
        <h3>Приготовьте место</h3>
        <p>Кодексом на полу начертите руну. Нужна свободная площадка 3×3 без стен, космоса и лавы. Рисование занимает 8 секунд. Ингредиенты кладут на руну; пустой рукой на ней выбирают обряд. Кодексом руну можно стереть.</p>
        <RitualDiagram />
      </Page>
      <Page side="right" chapter="Помощь">
        <h2>Охота и вознесение</h2>
        <h3>Хватка и клинок</h3>
        <p>Хватка Мансуса накладывает метку, удар клинком её активирует. У каждого пути свой запас силы. Он показан внизу левой страницы; нажмите на его название, чтобы прочитать, как он работает.</p>
        <p>У каждого пути есть пассивка с тремя уровнями. Найдите её в главе «Знания»: после изучения появится кнопка улучшения. Второй уровень стоит 1 очко знаний, третий — 2; сначала тратятся побочные очки. Улучшения сохраняются при смене тела и потере книги.</p>
        <h3>Сердце ведёт к жертве</h3>
        <p>В главе «Охота» выберите живую цель. Призовите живое сердце: сожмите его для поиска, Alt-ЛКМ меняет цель. Доставьте человека к руне вместе со своим сердцем. Живую цель достаточно связать, оглушить или сбить с ног; цель без сознания тоже подойдёт. Если назначенный человек погиб, можно принести его труп.</p>
        <p>Жертвоприношение длится 8 секунд. Живая цель даёт 2 очка знаний и 1 побочное, труп — только 1 очко знаний без побочного. Оба засчитываются для вознесения. Труп остаётся на месте для возможной реанимации; повторно принести ту же душу нельзя, даже после её оживления.</p>
        <p>На время обряда руна удерживает живую жертву и останавливает кровотечение. Перемещение жертвы или прерывание еретика срывает обряд. В Мансусе живой человек ищет дорогу домой: выйти можно через 30 секунд, а через 45 секунд он вернётся автоматически.</p>
        <p>Жертва помнит Дом и след на коже, но не может восстановить лицо, голос и имя похитителя по этому событию. Её более ранние знания сохраняются.</p>
        <h3>Вознесение</h3>
        <p>Совершите {data.hunt.sacrifices_required} жертвоприношений и изучите последнее знание пути. Для вознесения принесите на руну человеческие трупы: {data.hunt.ascension_bodies ?? 3}. Финальный обряд длится 30 секунд; его подношения не возвращаются. Каждая попытка объявляется станции, между началами попыток должно пройти три минуты. Выбранные тела подсвечиваются для вас зелёным.</p>
        <p>Станция заранее получает предупреждение об оккультной угрозе. Вознесение доступно не раньше чем через три минуты после этого предупреждения.</p>
        <h3>Дело пути</h3>
        <p>У каждого пути есть дело, не связанное с боем; оно описано в главе «Охота» после выбора пути. Дело состоит из {deedTiers} {countNoun(deedTiers, ['ступени', 'ступеней', 'ступеней'])}: каждая завершённая ступень даёт 1 очко знаний, вторая и третья — ещё по 1 побочному очку.</p>
        <p>Каждое засчитанное действие восполняет запас силы пути на единицу и оставляет на полу заметный след, который может найти экипаж.</p>
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
          {chapter === 'Охота' && <HuntChapter retargetDeadline={retargetDeadline} />}
          {chapter === 'Помощь' && <HelpChapter />}
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
