import { Fragment, ReactNode, useEffect, useMemo, useState } from 'react';

import { BooleanLike } from '../../common/react';
import { useBackend } from '../backend';
import {
  Box,
  Button,
  Divider,
  Icon,
  NoticeBox,
  Section,
  Stack,
  Tooltip,
} from '../components';
import { Window } from '../layouts';
import { JOB_INFO, JOB_INFO_DEFAULT } from './jobInfoData';

type JobEntry = {
  title: string;
  displayTitle?: string;
  command?: BooleanLike;
  /** Глава отдела */
  head?: BooleanLike;
  current: number;
  total: number;
  /** Приоритет */
  pinned?: BooleanLike;
  /** Причина по которой недоступна строка */
  blocked?: string;
  priority?: number;
  overflow?: BooleanLike;
  locked?: BooleanLike;
  hasAltTitles?: BooleanLike;
};

/** Копактное описание гост ролбки */
type GhostRole = {
  name: string;
  category: string;
  group?: string;
  amount: number;
  /** 0 — чужой облик, 1 — можно своего персонажа, 2 — только свой */
  canLoad?: number;
  infinite?: BooleanLike;
  antag?: BooleanLike;
  previewable?: BooleanLike;
  kind?: 'silicon' | 'animal' | 'other';
};

type GhostInfo = {
  short?: string;
  flavour?: string;
  warning?: string;
  addition?: string;
};

type Department = {
  name: string;
  color: string;
  command?: BooleanLike;
  /** Отдел пуст, вход даёт бонус метадолларов */
  needed?: BooleanLike;
  jobs: JobEntry[];
};

type RoundInfo = {
  duration?: string;
  alert?: string;
  alertColor?: string;
  shuttle?: string;
  relief?: string;
};

type JobMenuData = {
  mode?: string;
  selected?: string | null;
  selectedGhost?: string | null;
  preview?: string;
  previewJob?: string;
  departments?: Department[];
  ghostRoles?: GhostRole[];
  ghostInfo?: GhostInfo | null;
  round?: RoundInfo;
  joblessrole?: string;
  overflowRole?: string;
};

/** Шкала приоритета не забыть не менять после */
const PRIORITY_LEVELS = [
  { level: 0, label: 'Никогда', color: 'red' },
  { level: 1, label: 'Низкий', color: 'orange' },
  { level: 2, label: 'Средний', color: 'green' },
  { level: 3, label: 'Высокий', color: 'slateblue' },
];

const slotLabel = (job: JobEntry) =>
  `${job.current}/${job.total === -1 ? '∞' : job.total}`;

/** Главы отделов золотом */
const HEAD_COLOR = '#ffcc66';
/** Белый для прозрачных кнопок */
const ROW_COLOR = '#ffffff';
/** Вторичный текст */
const SUBTLE = '#c9d1d9';

const tinted = (hex: string, alpha = 0.16) => {
  const match = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || '');
  if (!match) return 'rgba(255,255,255,0.04)';
  const [r, g, b] = [1, 2, 3].map((i) => parseInt(match[i], 16));
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
};

/** Цвета отделов местами тёмные */
const readable = (hex: string, amount = 0.45) => {
  const match = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex || '');
  if (!match) return '#9fb3c8';
  const [r, g, b] = [1, 2, 3].map((i) => parseInt(match[i], 16));
  const mix = (c: number) => Math.round(c + (255 - c) * amount);
  return `rgb(${mix(r)}, ${mix(g)}, ${mix(b)})`;
};

function splitColumns<T>(items: T[], columns: number, weight: (item: T) => number): T[][] {
  const result: T[][] = [];
  for (let i = 0; i < columns; i++) result.push([]);
  const sizes: number[] = [];
  for (let i = 0; i < columns; i++) sizes.push(0);
  for (const item of items) {
    let index = 0;
    for (let i = 1; i < columns; i++) if (sizes[i] < sizes[index]) index = i;
    result[index].push(item);
    sizes[index] += weight(item);
  }
  return result;
}

/** Категории гост ролей, как их разложил сам SpawnersMenu */
const GHOST_CATEGORIES: Record<
  string,
  { label: string; icon: string; color: string }
> = {
  misc: { label: 'Прочее', icon: 'ghost', color: '#9fb3c8' },
  syndicate: { label: 'Синдикат', icon: 'handshake', color: '#e06c5a' },
  inteq: { label: 'InteQ', icon: 'skull-crossbones', color: '#e0a458' },
  sol: { label: 'Солнечная Федерация', icon: 'flag', color: '#e6c94a' },
  midround: { label: 'Мидраунд', icon: 'dice-five', color: '#6fb7e0' },
  special: { label: 'Особые', icon: 'heart', color: '#b98fe0' },
  offstation: { label: 'Оффстаншн', icon: 'person-digging', color: '#6fd08c' },
  trauma: { label: 'Травма', icon: 'heartbeat', color: '#f08a9a' },
};

const GHOST_CATEGORY_ORDER = [
  'misc',
  'syndicate',
  'inteq',
  'sol',
  'midround',
  'special',
  'offstation',
  'trauma',
];

const ghostCategory = (key?: string) =>
  GHOST_CATEGORIES[key || ''] ||
  ({ label: key || 'Прочее', icon: 'ghost', color: '#9fb3c8' });

type GhostBlock = {
  key: string;
  title: string;
  color: string;
  icon: string;
  roles: GhostRole[];
};

/**
 * Разбиваем гост роли сначала по категориям, потом внутри по подстатусу
 */
function buildGhostBlocks(roles: GhostRole[]): GhostBlock[] {
  const categories = new Map<string, Map<string, GhostRole[]>>();
  for (const role of roles) {
    const cat = role.category || 'misc';
    if (!categories.has(cat)) categories.set(cat, new Map());
    const groups = categories.get(cat)!;
    const group = role.group || '';
    if (!groups.has(group)) groups.set(group, []);
    groups.get(group)!.push(role);
  }

  const catKeys = [...categories.keys()].sort(
    (a, b) =>
      (GHOST_CATEGORY_ORDER.indexOf(a) + 1 || 99) -
        (GHOST_CATEGORY_ORDER.indexOf(b) + 1 || 99) ||
      a.localeCompare(b, 'ru'),
  );

  const blocks: GhostBlock[] = [];
  for (const cat of catKeys) {
    const meta = ghostCategory(cat);
    const groups = [...categories.get(cat)!.entries()].sort((a, b) => {
      const multi = (b[1].length > 1 ? 1 : 0) - (a[1].length > 1 ? 1 : 0);
      if (multi) return multi;
      return a[0].localeCompare(b[0], 'ru');
    });

    const multi = groups.filter(([group, list]) => group && list.length > 1);
    const singles = groups
      .filter(([group, list]) => !group || list.length <= 1)
      .flatMap(([, list]) => list);
    const soloTitle = groups.length <= 1 || multi.length === 0;

    for (const [group, list] of multi) {
      blocks.push({
        key: `${cat}|${group}`,
        title: soloTitle ? meta.label : `${meta.label} · ${group}`,
        color: meta.color,
        icon: meta.icon,
        roles: [...list].sort((a, b) => a.name.localeCompare(b.name, 'ru')),
      });
    }
    if (singles.length) {
      blocks.push({
        key: `${cat}|`,
        title: meta.label,
        color: meta.color,
        icon: meta.icon,
        roles: [...singles].sort((a, b) => a.name.localeCompare(b.name, 'ru')),
      });
    }
  }
  return blocks;
}

const PriorityDots = (props: {
  job: JobEntry;
  onPriority: (title: string, level: number) => void;
}) => {
  const { job, onPriority } = props;
  const locked = !!job.locked;

  const levels = job.overflow
    ? [
        { level: 0, label: 'Нет', color: 'red' },
        { level: 3, label: 'Да', color: 'green' },
      ]
    : PRIORITY_LEVELS;
  const current = job.overflow ? (job.priority ? 3 : 0) : job.priority || 0;

  return (
    <Box style={{ display: 'flex', gap: '3px', alignItems: 'center' }}>
      {levels.map((entry) => {
        const isCurrent = current === entry.level;
        const tooltip = locked
          ? 'Снимите «Да» у резервной роли, чтобы включить остальные профессии'
          : `${entry.label}${isCurrent ? ' · выбран' : ''}`;
        return (
          <Button
            key={entry.level}
            color="transparent"
            tooltip={tooltip}
            tooltipPosition="top"
            style={{
              width: '14px',
              minWidth: '14px',
              height: '14px',
              margin: 0,
              padding: 0,
              borderRadius: '50%',
              border: `2px solid ${entry.color}`,
              background: isCurrent ? entry.color : 'transparent',
              opacity: locked ? 0.5 : 1,
            }}
            onClick={(event) => {
              event.stopPropagation();
              if (locked) return;
              onPriority(job.title, entry.level);
            }}
          />
        );
      })}
    </Box>
  );
};

const JobRow = (props: {
  job: JobEntry;
  mode: string;
  selected: string | null;
  onSelect: (title: string) => void;
  onPriority: (title: string, level: number) => void;
}) => {
  const { job, mode, selected, onSelect, onPriority } = props;
  // Название строки базовая профессия, выбранное альтернативное показываем под ней
  const rowTitle = job.displayTitle || job.title;
  const baseTitle =
    job.displayTitle && job.displayTitle !== job.title ? job.title : null;
  const isSelected = selected === job.title;

  // Подсказка строки
  const hints: string[] = [];
  if (baseTitle) hints.push(`Профессия: ${baseTitle}`);
  if (job.pinned) hints.push('Приоритетная вакансия — ×2 метадоллара за час');

  let rightSide: ReactNode = null;
  let rightColor: string | undefined;

  if (mode === 'latejoin') {
    rightSide = job.pinned ? (
      <>
        <Icon
          name="star"
          style={{ color: 'orange', marginRight: '3px' }}
        />
        {slotLabel(job)}
      </>
    ) : (
      slotLabel(job)
    );
    rightColor = job.pinned ? 'orange' : undefined;
  } else if (!job.blocked) {
    rightSide = <PriorityDots job={job} onPriority={onPriority} />;
  }

  return (
    <Button
      fluid
      color="transparent"
      selected={isSelected}
      tooltip={hints.length ? hints.join(' · ') : undefined}
      style={{
        display: 'block',
        textAlign: 'left',
        color: ROW_COLOR,
        fontWeight: job.command || job.head ? 700 : 400,
        opacity: job.locked ? 0.6 : 1,
      }}
      onClick={() => onSelect(job.title)}>
      <Box
        style={{
          display: 'flex',
          alignItems: 'baseline',
          gap: '4px',
        }}>
        <Box
          style={{
            flex: '1 1 auto',
            minWidth: 0,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
            color: job.head ? HEAD_COLOR : undefined,
          }}>
          {rowTitle}
        </Box>
        <Box style={{ flex: '0 0 auto' }} color={rightColor}>
          {rightSide}
        </Box>
      </Box>
      {job.blocked && (
        <Box fontSize="11px" color="bad" bold>
          {job.blocked}
        </Box>
      )}
    </Button>
  );
};

const Group = (props: {
  color: string;
  title: string;
  icon?: string;
  badge?: string;
  children?: ReactNode;
}) => {
  const { color, title, icon, badge, children } = props;
  return (
    <Box
      as="fieldset"
      style={{
        border: `2px solid ${color}`,
        background: tinted(color),
        margin: '0 0 6px',
        padding: '2px 8px 6px',
        minInlineSize: 0,
        borderRadius: '4px',
      }}>
      <Box
        as="legend"
        px={1}
        style={{
          color: readable(color),
          fontSize: '13px',
          fontWeight: 700,
          textShadow: '0 1px 2px rgba(0,0,0,0.85)',
        }}>
        {!!icon && (
          <Icon
            name={icon}
            style={{ fontSize: '11px', marginRight: '5px' }}
          />
        )}
        {title}
        {!!badge && (
          <Box as="span" color="orange" ml={1}>
            {badge}
          </Box>
        )}
      </Box>
      {children}
    </Box>
  );
};

/** Маленькая плашка статус для левой колонки гост роли */
const Chip = (props: { color: string; children?: ReactNode }) => {
  const { color, children } = props;
  return (
    <Box
      px={0.75}
      style={{
        border: `1px solid ${color}`,
        color,
        borderRadius: '3px',
        fontSize: '11px',
        lineHeight: '16px',
        whiteSpace: 'nowrap',
      }}>
      {children}
    </Box>
  );
};

const GhostRow = (props: {
  role: GhostRole;
  selected: string | null;
  onSelect: (name: string) => void;
}) => {
  const { role, selected, onSelect } = props;
  const canLoad = role.canLoad || 0;

  return (
    <Button
      fluid
      color="transparent"
      selected={selected === role.name}
      style={{ display: 'block', textAlign: 'left', color: ROW_COLOR }}
      onClick={() => onSelect(role.name)}>
      <Box style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
        <Box
          style={{
            flex: '1 1 auto',
            minWidth: 0,
            overflow: 'hidden',
            textOverflow: 'ellipsis',
            whiteSpace: 'nowrap',
          }}>
          {role.name}
        </Box>
        <Box
          style={{
            flex: '0 0 auto',
            display: 'flex',
            alignItems: 'center',
            gap: '3px',
          }}>
          {!!role.antag && (
            <Tooltip content="Антагонист">
              <Icon
                name="skull-crossbones"
                color="bad"
                style={{ fontSize: '11px' }}
              />
            </Tooltip>
          )}
          {role.kind === 'silicon' && (
            <Tooltip content="Силикон">
              <Icon
                name="robot"
                color="#6fb7e0"
                style={{ fontSize: '11px' }}
              />
            </Tooltip>
          )}
          {role.kind === 'animal' && (
            <Tooltip content="Разумное животное">
              <Icon name="paw" color="orange" style={{ fontSize: '11px' }} />
            </Tooltip>
          )}
          {role.kind === 'other' && (
            <Tooltip content="Не человек">
              <Icon name="ghost" color="label" style={{ fontSize: '11px' }} />
            </Tooltip>
          )}
          {canLoad > 0 && (
            <Tooltip
              content={
                canLoad === 2
                  ? 'Роль обязана использовать вашего персонажа'
                  : 'Роль позволяет использовать вашего персонажа'
              }>
              <Icon
                name="user"
                color={canLoad === 2 ? 'yellow' : 'green'}
                style={{ fontSize: '11px' }}
              />
            </Tooltip>
          )}
          <Box
            fontSize="11px"
            color={SUBTLE}
            width="22px"
            textAlign="right">
            {role.infinite ? '∞' : role.amount}
          </Box>
        </Box>
      </Box>
    </Button>
  );
};

export const JobMenu = () => {
  const { act, data } = useBackend<JobMenuData>();

  const mode = data?.mode || 'latejoin';
  const selected = data?.selected || null;
  const selectedGhost = data?.selectedGhost || null;
  const departments = data?.departments || [];
  const ghostRoles = data?.ghostRoles || [];
  const ghostInfo = data?.ghostInfo;
  const round = data?.round || {};
  const joblessrole = data?.joblessrole;
  const isLatejoin = mode === 'latejoin';

  const [tab, setTab] = useState<'jobs' | 'ghosts'>('jobs');

  // БЕЙС 64 МОЙ ЛЮБИМЫЙ БОЖЕ
  const [previewCache, setPreviewCache] = useState<Record<string, string>>({});
  useEffect(() => {
    if (data?.preview && data?.previewJob) {
      const job = data.previewJob;
      const image = data.preview;
      setPreviewCache((prev) => ({ ...prev, [job]: image }));
    }
  }, [data?.preview, data?.previewJob]);

  const deptMatches = departments.filter((dept) =>
    dept.jobs.some((job) => job.title === selected),
  );
  const selectedDept =
    deptMatches.find((dept) => !dept.command) || deptMatches[0];
  const selectedJob = selectedDept?.jobs.find(
    (job) => job.title === selected,
  );

  // Гост роль показываем только когда стоим на её вкладке
  const showGhost = isLatejoin && tab === 'ghosts' && !!selectedGhost;
  const ghostRole = showGhost
    ? ghostRoles.find((role) => role.name === selectedGhost)
    : undefined;
  const ghostName = showGhost ? selectedGhost : null;
  const ghostBlock = showGhost
    ? ghostCategory(ghostRole?.category)
    : null;

  const info = (selectedJob && JOB_INFO[selectedJob.title]) || JOB_INFO_DEFAULT;

  const previewKey: string | null =
    showGhost && selectedGhost ? `ghost:${selectedGhost}` : selected || null;
  const previewImage = previewKey ? previewCache[previewKey] : null;

  // Гост роли уходят в свою вкладку, чтобы не забивать список профессий.
  // Пустые отделы не показываем — от них остаётся только пустая рамка.
  const visibleGroups = departments.filter((dept) => dept.jobs.length > 0);
  const jobColumns = splitColumns(visibleGroups, 3, (dept) => dept.jobs.length + 1);
  const ghostBlocks = useMemo(() => buildGhostBlocks(ghostRoles), [ghostRoles]);
  const ghostColumns = splitColumns(ghostBlocks, 3, (block) => block.roles.length + 1);

  return (
    <Window width={1000} height={700}>
      <Window.Content>
        <Stack vertical fill>
          {isLatejoin && (
            <Stack.Item shrink={0}>
              <Box
                px={1}
                py={0.5}
                style={{
                  border: '1px solid rgba(255,255,255,0.2)',
                  background: 'rgba(0,0,0,0.25)',
                }}>
                <Stack>
                  <Stack.Item grow basis={0}>
                    Длительность раунда: <b>{round.duration || '—'}</b>
                    {' · '}Уровень тревоги:{' '}
                    <b style={{ color: round.alertColor || undefined }}>
                      {round.alert || '—'}
                    </b>
                    {!!round.shuttle && (
                      <Box color="red" bold>
                        {round.shuttle}
                      </Box>
                    )}
                    {!!round.relief && (
                      <Box color="orange">{round.relief}</Box>
                    )}
                  </Stack.Item>
                  <Stack.Item shrink={0}>
                    <Button
                      color="transparent"
                      icon="sync"
                      tooltip="Обновить список вакансий"
                      tooltipPosition="bottom-end"
                      onClick={() => act('refresh', {})} />
                  </Stack.Item>
                </Stack>
              </Box>
            </Stack.Item>
          )}

          <Stack.Item grow basis={0} style={{ minHeight: 0 }}>
            <Stack fill>
              {/* Левая колонка вся текстовая информация */}
              <InfoColumn
                selected={selected}
                selectedGhost={ghostName}
                selectedJob={selectedJob}
                selectedDept={selectedDept}
                ghostRole={ghostRole}
                ghostInfo={ghostInfo}
                ghostBlock={ghostBlock}
                info={info}
                previewImage={previewImage}
                onGhostTab={isLatejoin && tab === 'ghosts'}
                isLatejoin={isLatejoin}
                act={act}
              />

              {/* Правая колонка выбор профессий и приоритетов */}
              <SelectColumn
                mode={mode}
                selected={selected}
                selectedGhost={selectedGhost}
                isLatejoin={isLatejoin}
                tab={tab}
                onTabChange={setTab}
                jobColumns={jobColumns}
                ghostColumns={ghostColumns}
                visibleGroups={visibleGroups}
                ghostRoles={ghostRoles}
                act={act}
              />
            </Stack>
          </Stack.Item>

          {!isLatejoin && (
            <Stack.Item shrink={0}>
              <Section fitted>
                <Stack fill align="center" px={1} py={0.5}>
                  <Stack.Item grow basis={0}>
                    <Button
                      fluid
                      align="center"
                      color="transparent"
                      icon="door-open"
                      style={{ fontWeight: 600, color: ROW_COLOR }}
                      tooltip="Что делать, если выбранные профессии не подойдут"
                      tooltipPosition="top"
                      onClick={() => act('joblessrole')}>
                      {joblessrole || 'Что делать, если префы недоступны'}
                    </Button>
                  </Stack.Item>
                  <Stack.Item grow basis={0}>
                    <Button
                      fluid
                      align="center"
                      color="transparent"
                      icon="undo"
                      style={{ fontWeight: 600, color: ROW_COLOR }}
                      tooltip="Сбросить все выставленные приоритеты"
                      tooltipPosition="top"
                      onClick={() => act('reset')}>
                      Сбросить приоритеты
                    </Button>
                  </Stack.Item>
                  <Stack.Item shrink={0}>
                    <Button
                      color="transparent"
                      icon="times"
                      style={{ color: ROW_COLOR }}
                      tooltip="Закрыть окно"
                      tooltipPosition="top-end"
                      onClick={() => act('close')}>
                      Закрыть
                    </Button>
                  </Stack.Item>
                </Stack>
              </Section>
            </Stack.Item>
          )}
        </Stack>
      </Window.Content>
    </Window>
  );
};

/** Креплю кнопку захода в хату. Первым делом при прибытии на станцию персонаж говорит "Кто тут у нас петушок, кого ебать в пердак с просвистоном" */
const buildJoinButton = (
  isLatejoin: boolean,
  selectedJob: JobEntry | undefined,
  selectedGhost: string | null,
  act: (action: string, params?: Record<string, unknown>) => void,
): ReactNode => {
  if (!isLatejoin) {
    return null;
  }
  if (selectedGhost) {
    return (
      <Button
        color="good"
        icon="sign-in-alt"
        content="Присоединиться"
        onClick={() => act('join_ghost', { spawner: selectedGhost })}
      />
    );
  }
  if (selectedJob) {
    return (
      <Button
        color="good"
        icon="sign-in-alt"
        content="Присоединиться"
        onClick={() => act('join', { job: selectedJob.title })}
      />
    );
  }
  return null;
};

const PREVIEW_BOX = 256;
const PREVIEW_CACHE_MAX = 64;

type FramedPreview = { url: string; w: number; h: number };
const previewFrameCache = new Map<string, FramedPreview>();

const framePreview = (image: HTMLImageElement): FramedPreview | null => {
  const width = image.naturalWidth;
  const height = image.naturalHeight;
  if (!width || !height) return null;

  let x0 = 0;
  let y0 = 0;
  let x1 = width - 1;
  let y1 = height - 1;

  const probe = document.createElement('canvas');
  probe.width = width;
  probe.height = height;
  const probeCtx = probe.getContext('2d', { willReadFrequently: true });
  if (probeCtx) {
    probeCtx.imageSmoothingEnabled = false;
    probeCtx.drawImage(image, 0, 0);
    try {
      const { data } = probeCtx.getImageData(0, 0, width, height);
      let left = width;
      let right = -1;
      let top = height;
      let bottom = -1;
      for (let y = 0; y < height; y++) {
        const row = y * width * 4;
        for (let x = 0; x < width; x++) {
          if (data[row + x * 4 + 3] === 0) continue;
          if (x < left) left = x;
          if (x > right) right = x;
          if (y < top) top = y;
          if (y > bottom) bottom = y;
        }
      }
      if (right >= 0 && bottom >= 0) {
        x0 = left;
        y0 = top;
        x1 = right;
        y1 = bottom;
      }
    } catch {
      x0 = 0;
      y0 = 0;
      x1 = width - 1;
      y1 = height - 1;
    }
  }

  const contentWidth = x1 - x0 + 1;
  const contentHeight = y1 - y0 + 1;
  const scale = Math.max(
    1,
    Math.floor(PREVIEW_BOX / Math.max(contentWidth, contentHeight)),
  );

  const out = document.createElement('canvas');
  out.width = contentWidth * scale;
  out.height = contentHeight * scale;
  const outCtx = out.getContext('2d');
  if (!outCtx) return null;
  outCtx.imageSmoothingEnabled = false;
  outCtx.drawImage(
    image,
    x0,
    y0,
    contentWidth,
    contentHeight,
    0,
    0,
    out.width,
    out.height,
  );

  return { url: out.toDataURL('image/png'), w: out.width, h: out.height };
};

const PixelPreview = (props: { src: string }) => {
  const { src } = props;
  const [framed, setFramed] = useState<FramedPreview | null>(
    () => previewFrameCache.get(src) || null,
  );

  useEffect(() => {
    const cached = previewFrameCache.get(src);
    if (cached) {
      setFramed(cached);
      return;
    }
    setFramed(null);

    let cancelled = false;
    const image = new Image();
    image.onload = () => {
      const result = framePreview(image);
      if (result) {
        if (previewFrameCache.size >= PREVIEW_CACHE_MAX) {
          const oldest = previewFrameCache.keys().next();
          if (!oldest.done) previewFrameCache.delete(oldest.value);
        }
        previewFrameCache.set(src, result);
      }
      if (!cancelled) setFramed(result);
    };
    image.src = `data:image/png;base64,${src}`;
    return () => {
      cancelled = true;
    };
  }, [src]);

  return (
    <Box
      style={{
        width: PREVIEW_BOX,
        height: PREVIEW_BOX,
        margin: '0 auto',
        overflow: 'hidden',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }}>
      {framed && (
        <Box
          as="img"
          src={framed.url}
          style={{
            width: `${framed.w}px`,
            height: `${framed.h}px`,
            imageRendering: 'pixelated',
          }}
        />
      )}
    </Box>
  );
};

/** Левая колонка превью, название, подчинение, описание, кнопки. */
const InfoColumn = (props: {
  selected: string | null;
  selectedGhost: string | null;
  selectedJob?: JobEntry;
  selectedDept?: Department;
  ghostRole?: GhostRole;
  ghostInfo?: GhostInfo | null;
  ghostBlock: { label: string; icon: string; color: string } | null;
  info: { summary: string; tasks?: string[]; reports?: string[] };
  previewImage: string | null;
  onGhostTab: boolean;
  isLatejoin: boolean;
  act: (action: string, params?: Record<string, unknown>) => void;
}) => {
  const {
    selected,
    selectedGhost,
    selectedJob,
    selectedDept,
    ghostRole,
    ghostInfo,
    ghostBlock,
    info,
    previewImage,
    onGhostTab,
    isLatejoin,
    act,
  } = props;

  let previewFallback = 'Профессия не выбрана.';
  if (selectedGhost) {
    previewFallback =
      ghostRole && !ghostRole.previewable
        ? 'Для этой роли превью не отображается.'
        : 'Превью грузится…';
  } else if (selected) {
    previewFallback = 'Превью грузится…';
  } else if (onGhostTab) {
    previewFallback = 'Гост-роль не выбрана.';
  }

  const joinButton = buildJoinButton(
    isLatejoin,
    selectedJob,
    selectedGhost,
    act,
  );

  return (
    <Stack.Item
      width="300px"
      shrink={0}
      style={{ display: 'flex', flexDirection: 'column' }}>
      <Box
        style={{
          flex: '1 1 auto',
          minHeight: 0,
          overflowY: 'auto',
          overflowX: 'hidden',
          paddingRight: '6px',
          paddingBottom: '6px',
        }}>
        <Box
          px={1}
          py={1}
          style={{
            border: '1px solid rgba(255,255,255,0.2)',
            background: 'rgba(0,0,0,0.25)',
            textAlign: 'center',
          }}>
          {previewImage ? (
            <PixelPreview key={previewImage} src={previewImage} />
          ) : (
            <Box color="label">{previewFallback}</Box>
          )}
        </Box>

        {!!selectedJob && (
          <>
            <JobTitle job={selectedJob} dept={selectedDept} act={act} />

            {!!selectedJob.command && (
              <Box fontSize="11px" color={SUBTLE}>
                Отдел: {selectedDept?.name}
                {selectedJob.head ? ' · Глава отдела' : ''}
              </Box>
            )}

            {!!info.reports?.length && (
              <Box fontSize="12px" mt={0.5}>
                Кому подчиняется: <b>{info.reports.join(' → ')}</b>
              </Box>
            )}

            <Divider />

            <Box>{info.summary}</Box>

            {!!info.tasks?.length && (
              <>
                <Box mt={1} bold fontSize="12px">
                  Обязанности
                </Box>
                {info.tasks.map((task) => (
                  <Box key={task} ml={1} fontSize="12px">
                    — {task}
                  </Box>
                ))}
              </>
            )}

            {isLatejoin && (
              <>
                <Divider />
                <Box>
                  Свободные места: <b>{slotLabel(selectedJob)}</b>
                </Box>
                {!!selectedJob.pinned && (
                  <Box color="orange" bold fontSize="12px">
                    Приоритетная вакансия
                  </Box>
                )}
                {!!selectedJob.pinned && (
                  <Box fontSize="11px" color={SUBTLE}>
                    За час на ней начисляется{' '}
                    <b style={{ color: HEAD_COLOR }}>×2 метадоллара</b>
                  </Box>
                )}
              </>
            )}
          </>
        )}

        {!!selectedGhost && (
          <>
            <Box
              mt={1}
              fontSize="16px"
              bold
              color={ghostBlock?.color || '#ffffff'}>
              {selectedGhost}
            </Box>

            <Box fontSize="11px" color={SUBTLE}>
              {ghostBlock?.label || 'Гост-роль'}
              {!!ghostRole?.group && ` · ${ghostRole.group}`}
            </Box>

            <Box
              mt={0.5}
              style={{ display: 'flex', flexWrap: 'wrap', gap: '4px' }}>
              {!!ghostRole?.antag && (
                <Chip color="#e06c5a">Антагонист</Chip>
              )}
              {ghostRole?.kind === 'silicon' && (
                <Chip color="#6fb7e0">Силикон</Chip>
              )}
              {ghostRole?.kind === 'animal' && (
                <Chip color="orange">Разумное животное</Chip>
              )}
              {ghostRole?.kind === 'other' && (
                <Chip color="#9fb3c8">Не человек</Chip>
              )}
              {!!ghostRole &&
                (ghostRole.canLoad === 2 ? (
                  <Chip color="yellow">Только ваш персонаж</Chip>
                ) : ghostRole.canLoad === 1 ? (
                  <Chip color="green">Можно своего персонажа</Chip>
                ) : (
                  <Chip color="#e06c5a">Чужой облик</Chip>
                ))}
              {!!ghostRole &&
                (ghostRole.infinite ? (
                  <Chip color="#9fb3c8">Без лимита</Chip>
                ) : (
                  <Chip color="#9fb3c8">
                    Точек спавна: {ghostRole.amount}
                  </Chip>
                ))}
            </Box>

            <Divider />

            {!ghostInfo ? (
              <Box color="label" fontSize="12px">
                Описание загружается…
              </Box>
            ) : (
              <>
                {!!ghostInfo.short && (
                  <Box fontSize="13px" bold>
                    {ghostInfo.short}
                  </Box>
                )}
                {!!ghostInfo.flavour && (
                  <Box mt={0.5} fontSize="12px">
                    {ghostInfo.flavour}
                  </Box>
                )}
                {!!ghostInfo.warning && (
                  <Box mt={1} color="bad" bold fontSize="12px">
                    {ghostInfo.warning}
                  </Box>
                )}
                {!!ghostInfo.addition && (
                  <Box mt={1}>
                    <NoticeBox>
                      <Box fontSize="12px">{ghostInfo.addition}</Box>
                    </NoticeBox>
                  </Box>
                )}
              </>
            )}
          </>
        )}

        {!selectedJob && !selectedGhost && (
          <Box color="label" fontSize="12px">
            {onGhostTab
              ? 'Выберите гост-роль в списке справа, чтобы прочитать её описание и условия.'
              : 'Выберите профессию в списке справа, чтобы увидеть описание, обязанности и цепочку подчинения.'}
          </Box>
        )}
      </Box>
      {joinButton && (
        <Box
          style={{
            flex: '0 0 auto',
            display: 'flex',
            justifyContent: 'flex-start',
            marginTop: '6px',
            paddingTop: '6px',
            marginRight: '6px',
            borderTop: '1px solid rgba(255,255,255,0.2)',
          }}>
          {joinButton}
        </Box>
      )}
    </Stack.Item>
  );
};

/** Название профессии динамическое, по клику открывает выбор названия. */
const JobTitle = (props: {
  job: JobEntry;
  dept?: Department;
  act: (action: string, params?: Record<string, unknown>) => void;
}) => {
  const { job, dept, act } = props;
  // Показываем уже выбранное название, базовое — в тултипе кнопки
  const jobTitle = job.displayTitle || job.title;
  const baseTitle =
    job.displayTitle && job.displayTitle !== job.title ? job.title : null;
  const color = job.head ? HEAD_COLOR : dept?.color;

  return (
    <Box
      mt={1}
      style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
      {!!job.head && (
        <Icon
          name="crown"
          style={{ color: HEAD_COLOR, fontSize: '14px', flex: '0 0 auto' }}
        />
      )}
      <Box style={{ flex: '1 1 auto', minWidth: 0 }}>
        {!job.hasAltTitles ? (
          <Box fontSize="16px" bold color={color}>
            {jobTitle}
          </Box>
        ) : (
          <Button
            fluid
            color="transparent"
            icon="pen"
            tooltip={
              baseTitle
                ? `Профессия: ${baseTitle}. Нажмите, чтобы изменить`
                : 'Изменить название должности'
            }
            tooltipPosition="bottom-end"
            style={{
              textAlign: 'left',
              fontSize: '16px',
              fontWeight: 700,
              color: color || ROW_COLOR,
              padding: '2px 0',
            }}
            onClick={() => act('alt_title', { job: job.title })}>
            {jobTitle}
          </Button>
        )}
      </Box>
    </Box>
  );
};

/** Правая колонка вкладки и сам список. */
const SelectColumn = (props: {
  mode: string;
  selected: string | null;
  selectedGhost: string | null;
  isLatejoin: boolean;
  tab: 'jobs' | 'ghosts';
  onTabChange: (tab: 'jobs' | 'ghosts') => void;
  jobColumns: Department[][];
  ghostColumns: GhostBlock[][];
  visibleGroups: Department[];
  ghostRoles: GhostRole[];
  act: (action: string, params?: Record<string, unknown>) => void;
}) => {
  const {
    mode,
    selected,
    selectedGhost,
    isLatejoin,
    tab,
    onTabChange,
    jobColumns,
    ghostColumns,
    visibleGroups,
    ghostRoles,
    act,
  } = props;

  const jobCount = visibleGroups.reduce(
    (sum, dept) => sum + dept.jobs.length,
    0,
  );

  return (
    <Stack.Item grow basis={0} style={{ minWidth: 0 }}>
      <Box height="100%" style={{ display: 'flex', flexDirection: 'column' }}>
        {isLatejoin && (
          <Stack shrink={0}>
            <Stack.Item>
              <Button
                icon="briefcase"
                selected={tab === 'jobs'}
                content={`Профессии (${jobCount})`}
                onClick={() => onTabChange('jobs')} />
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="user-astronaut"
                selected={tab === 'ghosts'}
                content={`Гост-роли (${ghostRoles.length})`}
                onClick={() => onTabChange('ghosts')} />
            </Stack.Item>
          </Stack>
        )}
        <Box
          mt={isLatejoin ? 1 : 0}
          style={{
            flex: '1 1 auto',
            minHeight: 0,
            overflowY: 'auto',
            overflowX: 'hidden',
          }}>
          {tab === 'jobs' && (
            <JobColumns
              columns={jobColumns}
              empty={visibleGroups.length === 0}
              mode={mode}
              selected={selected}
              act={act}
            />
          )}

          {tab === 'ghosts' &&
            (ghostRoles.length === 0 ? (
              <Box color="red" fontSize="12px">
                В настоящее время нет гост-спавнеров.
              </Box>
            ) : (
              <GhostColumns
                columns={ghostColumns}
                selected={selectedGhost}
                act={act}
              />
            ))}
        </Box>
      </Box>
    </Stack.Item>
  );
};

/** Вот тут менять линию между профами */
const RowDivider = () => (
  <Box
    style={{
      height: '1px',
      margin: '1px 0',
      background: 'rgba(255,255,255,0.12)',
    }}
  />
);

/** Три колонки со списком профессий. */
const JobColumns = (props: {
  columns: Department[][];
  empty: boolean;
  mode: string;
  selected: string | null;
  act: (action: string, params?: Record<string, unknown>) => void;
}) => {
  const { columns, empty, mode, selected, act } = props;

  if (empty) {
    return (
      <Box color="label" fontSize="12px">
        Нет доступных вакансий.
      </Box>
    );
  }

  return (
    <Stack align="flex-start">
      {columns.map((column, index) => (
        <Stack.Item key={index} grow basis={0} style={{ minWidth: 0 }}>
          {column.map((dept) =>
            dept.jobs.length ? (
              <Group
                key={dept.name}
                color={dept.color}
                title={dept.name}
                badge={dept.needed ? 'нужны' : undefined}>
                {dept.jobs.map((job, jobIndex) => (
                  <Fragment key={job.title}>
                    {jobIndex > 0 && <RowDivider />}
                    <JobRow
                      job={job}
                      mode={mode}
                      selected={selected}
                      onSelect={(title) => act('select', { job: title })}
                      onPriority={(title, level) =>
                        act('set_priority', { job: title, level })
                      }
                    />
                  </Fragment>
                ))}
              </Group>
            ) : null,
          )}
        </Stack.Item>
      ))}
    </Stack>
  );
};

/** Три колонки со списком гост ролей, разложенных по категориям и подстатусам */
const GhostColumns = (props: {
  columns: GhostBlock[][];
  selected: string | null;
  act: (action: string, params?: Record<string, unknown>) => void;
}) => {
  const { columns, selected, act } = props;

  return (
    <Stack align="flex-start">
      {columns.map((column, index) => (
        <Stack.Item key={index} grow basis={0} style={{ minWidth: 0 }}>
          {column.map((block) => (
            <Group
              key={block.key}
              color={block.color}
              icon={block.icon}
              title={`${block.title} (${block.roles.length})`}>
              {block.roles.map((role) => (
                <GhostRow
                  key={role.name}
                  role={role}
                  selected={selected}
                  onSelect={(name) => act('select_ghost', { spawner: name })}
                />
              ))}
            </Group>
          ))}
        </Stack.Item>
      ))}
    </Stack>
  );
};
