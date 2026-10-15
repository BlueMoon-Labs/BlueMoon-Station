import { BooleanLike, classes } from 'common/react';
import { useEffect, useState } from 'react';

import { useBackend, useLocalState } from '../backend';
import {
  Box,
  Button,
  Dropdown,
  Icon,
  Input,
  LabeledList,
  NoticeBox,
  Section,
  Stack,
  Table,
  Tabs,
} from '../components';
import { Window } from '../layouts';

// ======================= Типы данных =======================

type AntagStatus = {
  key: string;
  note?: string;
};

type AntagObjective = {
  text: string;
  completed: BooleanLike;
};

type AntagMember = {
  ref: string;
  name: string;
  role?: string;
  type: string;
  soft: BooleanLike;
  ckey?: string;
  mind_ref: string;
  mob_ref?: string;
  location?: string;
  dead?: BooleanLike;
  no_client?: BooleanLike;
  status?: AntagStatus;
  objectives?: AntagObjective[];
};

type ExtraRow = {
  text: string;
  location?: string;
  note?: string;
  dead?: BooleanLike;
  no_client?: BooleanLike;
  pm_ckey?: string;
  player_ref?: string;
  follow_ref?: string;
};

type ExtraBlock = {
  title: string;
  rows: ExtraRow[];
};

type AntagSection = {
  id: string;
  title: string;
  kind: 'team' | 'category' | 'peaceful';
  priority?: BooleanLike;
  members: AntagMember[];
  extras?: ExtraBlock[];
};

type RoundStats = {
  connected: number;
  lobby: number;
  ingame: number;
  living: number;
  living_connected: number;
  living_antagonists: number;
  observers: number;
  observers_connected: number;
  brains: number;
  skipped: number;
  drones: number;
  other: number;
};

type CheckAntagonistsData = {
  round?: {
    mode: string;
    replacement_mode?: string;
    duration: number; // секунды
  };
  shuttle?: {
    state: 'idle' | 'call' | 'waiting';
    eta?: number; // секунды
  };
  continuous: BooleanLike;
  midround_antag: BooleanLike;
  midround_time_limit: number;
  midround_life_limit: number;
  ends_with_antag_death: BooleanLike;
  delay_end: BooleanLike;
  delay_reason?: string;
  stats?: RoundStats;
  sections?: AntagSection[];
};


const STATUS_META: Record<string, { label: string; color: string }> = {
  alive: { label: 'жив', color: 'good' },
  dead: { label: 'мёртв', color: 'bad' },
  final_death: { label: 'оконч. смерть', color: 'bad' },
  no_body: { label: 'без тела', color: 'average' },
  no_client: { label: 'нет клиента', color: 'average' },
  unassigned: { label: 'не назначен', color: 'label' },
};

const STATUS_FILTERS = [
  { value: 'all', displayText: 'Все статусы' },
  { value: 'alive', displayText: 'Живые' },
  { value: 'dead', displayText: 'Мёртвые' },
  { value: 'no_body', displayText: 'Без тела' },
  { value: 'no_client', displayText: 'Оффлайн' },
  { value: 'unassigned', displayText: 'Не назначены' },
];

const KIND_LABELS: Record<string, string> = {
  team: 'команда',
  category: 'роль',
  peaceful: 'мирная',
};

type AntagViewMode = 'antags' | 'peaceful';

type DisplaySettings = {
  showCkey: BooleanLike;
  showLocation: BooleanLike;
  showObjectives: BooleanLike;
  compact: BooleanLike;
};

const useDisplaySettings = (): [
  DisplaySettings,
  (next: DisplaySettings) => void
] => {
  const [showCkey, setShowCkey] = useLocalState<BooleanLike>(
    'ca_show_ckey',
    true
  );
  const [showLocation, setShowLocation] = useLocalState<BooleanLike>(
    'ca_show_location',
    true
  );
  const [showObjectives, setShowObjectives] = useLocalState<BooleanLike>(
    'ca_show_objectives',
    true
  );
  const [compact, setCompact] = useLocalState<BooleanLike>('ca_compact', false);
  return [
    { showCkey, showLocation, showObjectives, compact },
    (next) => {
      setShowCkey(next.showCkey);
      setShowLocation(next.showLocation);
      setShowObjectives(next.showObjectives);
      setCompact(next.compact);
    },
  ];
};

const statusKeyOf = (member: AntagMember): string =>
  member.status?.key || 'alive';

const fmtClock = (totalSeconds: number): string => {
  const secs = Math.max(0, Math.floor(totalSeconds));
  const h = Math.floor(secs / 3600);
  const m = Math.floor(secs / 60) % 60;
  const s = secs % 60;
  const pad = (v: number) => String(v).padStart(2, '0');
  return `${pad(h)}:${pad(m)}:${pad(s)}`;
};

const useTickingSeconds = (serverValue: number, countsDown = false): number => {
  const [base, setBase] = useState(serverValue || 0);
  const [tick, setTick] = useState(0);

  useEffect(() => {
    setBase(serverValue || 0);
    setTick(0);
  }, [serverValue]);

  useEffect(() => {
    const id = setInterval(() => setTick((t) => t + 1), 1000);
    return () => clearInterval(id);
  }, []);

  return countsDown ? Math.max(0, base - tick) : base + tick;
};

const StatusTag = (props: { member: AntagMember }) => {
  const { member } = props;
  const key = statusKeyOf(member);
  const meta = STATUS_META[key] || STATUS_META.alive;
  return (
    <Stack vertical>
      <Stack.Item>
        <Box
          as="span"
          className="CheckAntagonists__StatusTag"
          color={meta.color}>
          {meta.label}
        </Box>
      </Stack.Item>
      {!!member.status?.note && (
        <Stack.Item>
          <Box color="label" fontSize={0.75}>
            {member.status.note}
          </Box>
        </Stack.Item>
      )}
    </Stack>
  );
};

const MemberObjectives = (props: { member: AntagMember }) => {
  const { member } = props;
  if (!member.objectives?.length) {
    return null;
  }
  return (
    <Box className="CheckAntagonists__Objectives">
      {member.objectives.map((objective, index) => (
        <Box key={index} className="CheckAntagonists__Objective">
          <Icon
            name={objective.completed ? 'check' : 'circle'}
            color={objective.completed ? 'good' : 'label'}
          />
          <Box as="span">{objective.text}</Box>
        </Box>
      ))}
    </Box>
  );
};

const MemberActions = (props: { member: AntagMember }) => {
  const { act } = useBackend<CheckAntagonistsData>();
  const { member } = props;
  return (
    <Box className="CheckAntagonists__Actions">
      <Button
        icon="envelope"
        compact
        color="blue"
        tooltip="Личное сообщение (PM)"
        disabled={!member.ckey}
        onClick={() => act('pm', { ckey: member.ckey })}
      />
      <Button
        icon="crosshairs"
        compact
        tooltip="Следить за игроком (FLW)"
        disabled={!member.mob_ref}
        onClick={() => act('follow', { ref: member.mob_ref })}
      />
      <Button
        icon="user"
        compact
        tooltip="Панель игрока"
        disabled={!member.mob_ref}
        onClick={() => act('player_panel', { ref: member.mob_ref })}
      />
      <Button
        icon="id-badge"
        compact
        color="red"
        tooltip="Панель роли (Traitor Panel)"
        onClick={() => act('antag_panel', { ref: member.mind_ref })}
      />
    </Box>
  );
};

const MemberRow = (props: {
  member: AntagMember;
  settings: DisplaySettings;
  showRole?: boolean;
}) => {
  const { member, settings, showRole } = props;
  const dead = !!member.dead || statusKeyOf(member) === 'final_death';
  return (
    <Table.Row className={classes([dead && 'CheckAntagonists__Row--dead'])}>
      <Table.Cell>
        <Box bold className="CheckAntagonists__MemberName">
          {member.name}
        </Box>
        {!!settings.showCkey && !!member.ckey && (
          <Box color="label" fontSize={0.75}>
            {member.ckey}
          </Box>
        )}
        {!!settings.showObjectives && <MemberObjectives member={member} />}
      </Table.Cell>
      {showRole && (
        <Table.Cell className="CheckAntagonists__ColRole">
          {member.role || '—'}
        </Table.Cell>
      )}
      <Table.Cell className="CheckAntagonists__ColStatus">
        <StatusTag member={member} />
      </Table.Cell>
      {!!settings.showLocation && (
        <Table.Cell className="CheckAntagonists__ColLocation">
          <Box color="label" fontSize={0.85}>
            {member.location || '—'}
          </Box>
        </Table.Cell>
      )}
      <Table.Cell className="CheckAntagonists__ColActions">
        <MemberActions member={member} />
      </Table.Cell>
    </Table.Row>
  );
};

const ExtraBlockView = (props: { block: ExtraBlock }) => {
  const { act } = useBackend<CheckAntagonistsData>();
  const { block } = props;
  return (
    <Box className="CheckAntagonists__Extras">
      <Box bold color="blue">
        {block.title}
      </Box>
      {block.rows.map((row, index) => (
        <Stack key={index} mt={0.25} align="center">
          <Stack.Item grow>
            <Box color={row.dead ? 'bad' : undefined}>{row.text}</Box>
            {!!row.note && (
              <Box color="label" fontSize={0.75}>
                {row.note}
              </Box>
            )}
            {!!row.location && (
              <Box color="label" fontSize={0.75}>
                {row.location}
              </Box>
            )}
            {!!row.no_client && (
              <Box color="average" fontSize={0.75}>
                нет клиента
              </Box>
            )}
          </Stack.Item>
          {!!row.pm_ckey && (
            <Stack.Item>
              <Button
                icon="envelope"
                compact
                color="blue"
                tooltip="Личное сообщение (PM)"
                onClick={() => act('pm', { ckey: row.pm_ckey })}
              />
            </Stack.Item>
          )}
          {!!row.follow_ref && (
            <Stack.Item>
              <Button
                icon="crosshairs"
                compact
                tooltip="Следить (FLW)"
                onClick={() => act('follow', { ref: row.follow_ref })}
              />
            </Stack.Item>
          )}
          {!!row.player_ref && (
            <Stack.Item>
              <Button
                icon="user"
                compact
                tooltip="Панель игрока"
                onClick={() => act('player_panel', { ref: row.player_ref })}
              />
            </Stack.Item>
          )}
        </Stack>
      ))}
    </Box>
  );
};

const AntagSectionView = (props: {
  section: AntagSection;
  settings: DisplaySettings;
}) => {
  const { section, settings } = props;
  const showRole = section.kind !== 'peaceful';
  return (
    <Section
      className={classes([
        'CheckAntagonists__Section',
        `CheckAntagonists__Section--${section.kind}`,
        !!section.priority && 'CheckAntagonists__Section--priority',
      ])}
      title={section.title}
      buttons={
        <Stack>
          {!!section.priority && (
            <Stack.Item>
              <Box className="CheckAntagonists__Badge CheckAntagonists__Badge--priority">
                главные
              </Box>
            </Stack.Item>
          )}
          <Stack.Item>
            <Box
              className={classes([
                'CheckAntagonists__Badge',
                section.kind === 'peaceful' &&
                  'CheckAntagonists__Badge--peaceful',
              ])}>
              {KIND_LABELS[section.kind] || section.kind} ·{' '}
              {section.members.length}
            </Box>
          </Stack.Item>
        </Stack>
      }>
      <Table className="CheckAntagonists__Table">
        <Table.Row header>
          <Table.Cell>Игрок</Table.Cell>
          {showRole && (
            <Table.Cell className="CheckAntagonists__ColRole">Роль</Table.Cell>
          )}
          <Table.Cell className="CheckAntagonists__ColStatus">
            Статус
          </Table.Cell>
          {!!settings.showLocation && (
            <Table.Cell className="CheckAntagonists__ColLocation">
              Локация
            </Table.Cell>
          )}
          <Table.Cell className="CheckAntagonists__ColActions" />
        </Table.Row>
        {section.members.map((member) => (
          <MemberRow
            key={member.ref}
            member={member}
            settings={settings}
            showRole={showRole}
          />
        ))}
      </Table>
      {section.extras?.map((block, index) => (
        <ExtraBlockView key={index} block={block} />
      ))}
    </Section>
  );
};

const memberMatches = (
  member: AntagMember,
  search: string,
  statusFilter: string
): boolean => {
  const key = statusKeyOf(member);
  if (statusFilter === 'dead') {
    if (key !== 'dead' && key !== 'final_death') {
      return false;
    }
  } else if (statusFilter !== 'all' && key !== statusFilter) {
    return false;
  }
  if (search) {
    const haystack = [member.name, member.role, member.ckey, member.location]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();
    if (!haystack.includes(search)) {
      return false;
    }
  }
  return true;
};

const AntagonistsTab = (props: { antagCount: number }) => {
  const { antagCount } = props;
  const { data } = useBackend<CheckAntagonistsData>();
  const { stats, sections = [] } = data;

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');
  // Тумблер: взаимоисключающие виды — настоящие антаги или мирные гост-роли.
  const [mode, setMode] = useLocalState<AntagViewMode>(
    'ca_view_mode',
    'antags'
  );
  const [settings, setSettings] = useDisplaySettings();
  const [showSettings, setShowSettings] = useState(false);

  const query = search.trim().toLowerCase();

  const antagSections = sections.filter(
    (section) => section.kind !== 'peaceful'
  );
  const peacefulSections = sections.filter(
    (section) => section.kind === 'peaceful'
  );
  const antagMembers = antagSections.reduce(
    (sum, section) => sum + section.members.length,
    0
  );
  const peacefulMembers = peacefulSections.reduce(
    (sum, section) => sum + section.members.length,
    0
  );

  const sourceSections = mode === 'peaceful' ? peacefulSections : antagSections;

  const visibleSections = sourceSections
    .map((section) => {
      const titleMatches =
        !!query && section.title.toLowerCase().includes(query);
      return {
        ...section,
        members: titleMatches
          ? section.members
          : section.members.filter((member) =>
              memberMatches(member, query, statusFilter)
            ),
      };
    })
    .filter((section) => section.members.length > 0);

  const hasSearch = !!query || statusFilter !== 'all';

  return (
    <Stack vertical>
      <Stack.Item>
        <Section>
          <Stack vertical>
            <Stack.Item>
              <Stack align="center">
                <Stack.Item>
                  <Box className="CheckAntagonists__Switch">
                    <Button
                      selected={mode === 'antags'}
                      icon="theater-masks"
                      tooltip="Настоящие антагонисты — считаются в статистике раунда"
                      onClick={() => setMode('antags')}>
                      Антагонисты ({antagMembers})
                    </Button>
                    <Button
                      selected={mode === 'peaceful'}
                      icon="heart"
                      tooltip="Мирные гост-роли — не считаются антагонистами"
                      onClick={() => setMode('peaceful')}>
                      Мирные гост-роли ({peacefulMembers})
                    </Button>
                  </Box>
                </Stack.Item>
                <Stack.Item grow>
                  <Input
                    fluid
                    autoFocus
                    placeholder="Поиск: имя, роль, ckey, локация…"
                    value={search}
                    onInput={(_, value) => setSearch(value)}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Dropdown
                    width={16}
                    options={STATUS_FILTERS}
                    selected={statusFilter}
                    onSelected={setStatusFilter}
                  />
                </Stack.Item>
                <Stack.Item>
                  <Button
                    icon="sliders-h"
                    selected={showSettings}
                    tooltip="Настройки отображения"
                    onClick={() => setShowSettings(!showSettings)}
                  />
                </Stack.Item>
              </Stack>
            </Stack.Item>
            {showSettings && (
              <Stack.Item>
                <Box className="CheckAntagonists__Settings">
                  <Button.Checkbox
                    checked={!!settings.showCkey}
                    onClick={() =>
                      setSettings({ ...settings, showCkey: !settings.showCkey })
                    }>
                    Показывать ckey
                  </Button.Checkbox>
                  <Button.Checkbox
                    checked={!!settings.showLocation}
                    onClick={() =>
                      setSettings({
                        ...settings,
                        showLocation: !settings.showLocation,
                      })
                    }>
                    Показывать локации
                  </Button.Checkbox>
                  <Button.Checkbox
                    checked={!!settings.showObjectives}
                    onClick={() =>
                      setSettings({
                        ...settings,
                        showObjectives: !settings.showObjectives,
                      })
                    }>
                    Показывать цели
                  </Button.Checkbox>
                  <Button.Checkbox
                    checked={!!settings.compact}
                    onClick={() =>
                      setSettings({ ...settings, compact: !settings.compact })
                    }>
                    Компактный режим
                  </Button.Checkbox>
                </Box>
              </Stack.Item>
            )}
            <Stack.Item>
              <Box className="CheckAntagonists__StatChips">
                <Box className="CheckAntagonists__StatChip">
                  <Box className="CheckAntagonists__StatChipLabel">
                    Антагонистов
                  </Box>
                  <Box bold color="red">
                    {antagCount}
                  </Box>
                </Box>
                <Box className="CheckAntagonists__StatChip">
                  <Box className="CheckAntagonists__StatChipLabel">
                    Мирных гост-ролей
                  </Box>
                  <Box bold color="green">
                    {peacefulMembers}
                  </Box>
                </Box>
                {!!stats && (
                  <>
                    <Box className="CheckAntagonists__StatChip">
                      <Box className="CheckAntagonists__StatChipLabel">
                        В игре
                      </Box>
                      <Box bold>{stats.ingame}</Box>
                    </Box>
                    <Box className="CheckAntagonists__StatChip">
                      <Box className="CheckAntagonists__StatChipLabel">
                        Живых
                      </Box>
                      <Box bold>{stats.living}</Box>
                    </Box>
                    <Box className="CheckAntagonists__StatChip">
                      <Box className="CheckAntagonists__StatChipLabel">
                        Наблюдателей
                      </Box>
                      <Box bold>{stats.observers}</Box>
                    </Box>
                  </>
                )}
              </Box>
            </Stack.Item>
          </Stack>
        </Section>
      </Stack.Item>
      {visibleSections.length === 0 && (
        <Stack.Item>
          <NoticeBox>
            {hasSearch
              ? 'Ничего не найдено по заданным фильтрам.'
              : mode === 'peaceful'
              ? 'Мирных гост-ролей нет.'
              : 'Антагонистов нет.'}
          </NoticeBox>
        </Stack.Item>
      )}
      {visibleSections.map((section) => (
        <Stack.Item key={section.id}>
          <AntagSectionView section={section} settings={settings} />
        </Stack.Item>
      ))}
    </Stack>
  );
};

const RoundInfoSection = () => {
  const { data, act } = useBackend<CheckAntagonistsData>();
  const { round, delay_end, delay_reason } = data;

  const duration = useTickingSeconds(round?.duration || 0);

  if (!round) {
    return <NoticeBox>Раунд ещё не начался.</NoticeBox>;
  }

  return (
    <Section title="Раунд">
      <LabeledList>
        <LabeledList.Item label="Режим">
          {round.mode}
          {!!round.replacement_mode && (
            <Box as="span" color="label">
              {' '}
              (заменён: {round.replacement_mode})
            </Box>
          )}
        </LabeledList.Item>
        <LabeledList.Item label="Длительность">
          <Box as="span" bold>
            {fmtClock(duration)}
          </Box>
        </LabeledList.Item>
        <LabeledList.Item label="Конец раунда">
          <Stack align="center">
            <Stack.Item>
              <Button.Checkbox
                checked={!!delay_end}
                tooltip={
                  delay_reason
                    ? `Причина: ${delay_reason}`
                    : 'Задерживает завершение раунда'
                }
                onClick={() => act('delay_round_end')}>
                {delay_end ? 'Задержан' : 'Задержать'}
              </Button.Checkbox>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="power-off"
                color="bad"
                tooltip="Завершить раунд (потребуется двойное подтверждение)"
                onClick={() => act('end_round')}>
                Завершить раунд
              </Button>
            </Stack.Item>
            {!!delay_end && !!delay_reason && (
              <Stack.Item>
                <Box color="label">{delay_reason}</Box>
              </Stack.Item>
            )}
          </Stack>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const ShuttleSection = () => {
  const { data, act } = useBackend<CheckAntagonistsData>();
  const { shuttle } = data;

  const state = shuttle?.state || 'idle';
  const eta = useTickingSeconds(shuttle?.eta || 0, true);

  const stateLabel =
    state === 'idle'
      ? 'на станции'
      : state === 'call'
      ? `в пути (ETA ${fmtClock(eta)})`
      : 'ожидает отправки';

  return (
    <Section title="Шаттл эвакуации">
      <Stack align="center" mb={1}>
        <Stack.Item>
          <Box>
            Статус:{' '}
            <Box
              as="span"
              bold
              color={
                state === 'idle'
                  ? 'label'
                  : state === 'call'
                  ? 'good'
                  : 'average'
              }>
              {stateLabel}
            </Box>
          </Box>
        </Stack.Item>
      </Stack>
      <Stack>
        <Stack.Item>
          <Button
            icon="space-shuttle"
            disabled={state !== 'idle'}
            tooltip="Вызвать шаттл эвакуации"
            onClick={() => act('call_shuttle')}>
            Вызвать шаттл
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="undo"
            disabled={state !== 'call'}
            tooltip="Отозвать шаттл обратно на ЦК"
            onClick={() => act('send_shuttle_back')}>
            Отозвать
          </Button>
        </Stack.Item>
        <Stack.Item>
          <Button
            icon="clock"
            disabled={state === 'idle'}
            tooltip="Изменить оставшееся время (только R_SERVER)"
            onClick={() => act('edit_shuttle_time')}>
            Изменить время
          </Button>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const RoundConfigSection = () => {
  const { data, act } = useBackend<CheckAntagonistsData>();
  const {
    continuous,
    midround_antag,
    midround_time_limit,
    midround_life_limit,
    ends_with_antag_death,
  } = data;

  return (
    <Section title="Продолжение раунда и midround-антаги">
      <Stack vertical>
        <Stack.Item>
          <Button.Checkbox
            checked={!!continuous}
            tooltip="Если выключено — раунд завершится вместе со смертью последнего антагониста"
            onClick={() => act('toggle_continuous')}>
            Раунд продолжается после смерти всех антагов
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={!!midround_antag}
            tooltip="Система динамических (midround) антагонистов"
            onClick={() => act('toggle_midround_antag')}>
            Midround-антаги включены
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Button.Checkbox
            checked={!!ends_with_antag_death}
            tooltip="Если выключено — при провале midround-антага раунд продолжится как extended"
            onClick={() => act('toggle_noncontinuous_behavior')}>
            Завершать раунд при провале midround-антага
          </Button.Checkbox>
        </Stack.Item>
        <Stack.Item>
          <Stack>
            <Stack.Item>
              <Button
                icon="clock"
                tooltip="Максимальное время появления midround-антага"
                onClick={() => act('alter_midround_time_limit')}>
                Лимит времени: {midround_time_limit} мин
              </Button>
            </Stack.Item>
            <Stack.Item>
              <Button
                icon="heartbeat"
                tooltip="Необходимый процент живого экипажа для появления midround-антага"
                onClick={() => act('alter_midround_life_limit')}>
                Лимит жизни экипажа: {midround_life_limit}%
              </Button>
            </Stack.Item>
          </Stack>
        </Stack.Item>
      </Stack>
    </Section>
  );
};

const StatsSection = () => {
  const { data } = useBackend<CheckAntagonistsData>();
  const { stats } = data;

  if (!stats) {
    return null;
  }

  return (
    <Section title="Статистика игроков">
      <LabeledList>
        <LabeledList.Item label="Антагонисты">
          <Box as="span" bold color="red">
            {stats.living_antagonists}
          </Box>
          <Box as="span" color="label">
            {' '}
            (живые, настоящие роли — мирные гост-роли не считаются)
          </Box>
        </LabeledList.Item>
        <LabeledList.Item label="Подключено">
          {stats.connected} · в игре: {stats.ingame} · в лобби: {stats.lobby}
        </LabeledList.Item>
        <LabeledList.Item label="Живые">
          {stats.living} (в сети: {stats.living_connected})
        </LabeledList.Item>
        <LabeledList.Item label="Наблюдатели">
          {stats.observers} (в сети: {stats.observers_connected})
        </LabeledList.Item>
        <LabeledList.Item label="Прочее">
          мозги: {stats.brains} · дроны: {stats.drones} · на ЦК: {stats.skipped}{' '}
          · прочее: {stats.other}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

const RoundTab = () => {
  return (
    <Stack vertical>
      <Stack.Item>
        <RoundInfoSection />
      </Stack.Item>
      <Stack.Item>
        <ShuttleSection />
      </Stack.Item>
      <Stack.Item>
        <RoundConfigSection />
      </Stack.Item>
      <Stack.Item>
        <StatsSection />
      </Stack.Item>
    </Stack>
  );
};

export const CheckAntagonists = (props) => {
  const { data } = useBackend<CheckAntagonistsData>();
  const { stats } = data;
  const [tab, setTab] = useState('antagonists');
  const [settings] = useDisplaySettings();

  if (!data.round) {
    return (
      <Window
        theme="admin"
        title="Проверка антагонистов"
        width={500}
        height={200}>
        <Window.Content className="CheckAntagonists">
          <NoticeBox>Раунд ещё не начался.</NoticeBox>
        </Window.Content>
      </Window>
    );
  }

  return (
    <Window
      theme="admin"
      title="Проверка антагонистов"
      width={1040}
      height={760}>
      <Window.Content
        scrollable
        className={classes([
          'CheckAntagonists',
          !!settings.compact && 'CheckAntagonists--compact',
        ])}>
        <Stack vertical fill>
          <Stack.Item>
            <Tabs fluid>
              <Tabs.Tab
                icon="theater-masks"
                selected={tab === 'antagonists'}
                onClick={() => setTab('antagonists')}>
                Антагонисты
              </Tabs.Tab>
              <Tabs.Tab
                icon="globe"
                selected={tab === 'round'}
                onClick={() => setTab('round')}>
                Раунд
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item grow>
            {tab === 'antagonists' && (
              <AntagonistsTab antagCount={stats?.living_antagonists || 0} />
            )}
            {tab === 'round' && <RoundTab />}
          </Stack.Item>
        </Stack>
      </Window.Content>
    </Window>
  );
};
