import { useState } from 'react';

import { useBackend } from '../../backend';
import { Box, Button, LabeledList, NoticeBox, Section, Stack, Table, Tabs } from '../../components';
import { Window } from '../../layouts';
import {
  adviceFor,
  breakdown,
  buildReport,
  chatRateText,
  ClientRow,
  gameWindowText,
  graphGeometry,
  GraphPoint,
  ms,
  PingDiagnosticsData,
  PingEvent,
  RoundSummary,
  SHARED_UNKNOWN_TEXT,
  Stats,
  VerdictCode,
  VERDICTS,
  whyText,
} from './model';

const GRAPH_WIDTH = 600;
const GRAPH_HEIGHT = 140;
// Меньше игроков с данными - доля ниже вашего ничего не говорит.
const PERCENTILE_MIN_CLIENTS = 5;

const EVENT_TYPES: Record<PingEvent['type'], string> = {
  server: 'простой сервера',
  server_load: 'нагрузка сервера',
  host_network: 'канал хоста',
  mass_freeze: 'подвисание у всех',
};

const Breakdown = ({ stats }: { stats: Stats }) => {
  const parts = breakdown(stats);
  // Доли меньше миллисекунды на полосе не видны, а минимальная ширина сегмента их раздувает.
  const drawn = parts.filter((part) => part.value >= 1);
  const total = drawn.reduce((sum, part) => sum + part.value, 0);
  return (
    <Section title="Из чего складывается пинг">
      {drawn.length > 0 && (
        <Stack fill>
          {drawn.map((part) => (
            <Stack.Item key={part.key} grow={Math.max(part.value / total, 0.02)} backgroundColor={part.color} height="16px" />
          ))}
        </Stack>
      )}
      <LabeledList>
        {parts.map((part) => (
          <LabeledList.Item key={part.key} label={part.label} color={part.side === 'ours' ? 'average' : undefined}>
            {part.unknown ? SHARED_UNKNOWN_TEXT : `${ms(part.value)} - ${part.side === 'ours' ? 'наша сторона' : 'ваша сторона'}`}
          </LabeledList.Item>
        ))}
      </LabeledList>
    </Section>
  );
};

const Graph = ({ points }: { points: GraphPoint[] }) => {
  if (!points.length) {
    return <NoticeBox>Замеров пока нет.</NoticeBox>;
  }
  const geometry = graphGeometry(points, GRAPH_WIDTH, GRAPH_HEIGHT);
  return (
    <Section title={`Последние 5 минут (шкала до ${geometry.maxRtt} мс)`}>
      <svg viewBox={`0 0 ${GRAPH_WIDTH} ${GRAPH_HEIGHT}`} width="100%" height={GRAPH_HEIGHT} preserveAspectRatio="none">
        <polygon points={geometry.ours} fill="#d4774a" fillOpacity={0.45} />
        <polyline points={geometry.line} fill="none" stroke="#4a8fd4" strokeWidth={1.5} />
        {geometry.spikes.map((spike, index) => (
          <circle key={index} cx={spike.x} cy={spike.y} r={3} fill="#d44a4a" />
        ))}
      </svg>
      <Box color="label" fontSize="0.9em">
        Синяя линия - пинг, оранжевое - наша доля, красные точки - скачки.
      </Box>
    </Section>
  );
};

const Numbers = ({ data, stats }: { data: PingDiagnosticsData; stats: Stats }) => (
  <Section title="Цифры">
    <LabeledList>
      <LabeledList.Item label="Сейчас / медиана">{ms(stats.rtt_now)} / {ms(stats.rtt_median)}</LabeledList.Item>
      <LabeledList.Item label="Минимум / p95">{ms(stats.rtt_min)} / {ms(stats.rtt_p95)}</LabeledList.Item>
      <LabeledList.Item label="По серверу">
        медиана {ms(data.server_rtt_median)}
        {(data.server_clients ?? 0) >= PERCENTILE_MIN_CLIENTS && `, у ${data.percentile ?? 0}% игроков пинг ниже вашего`}
      </LabeledList.Item>
      <LabeledList.Item label="Колебания">{ms(stats.personal_median)}</LabeledList.Item>
      <LabeledList.Item label="Скачки">{(stats.spikes_per_min ?? 0).toFixed(1)} в минуту</LabeledList.Item>
      <LabeledList.Item label="Подвисания">{stats.freezes ?? 0} за 5 минут</LabeledList.Item>
      <LabeledList.Item label="Окно игры">{gameWindowText(stats)}</LabeledList.Item>
      <LabeledList.Item label="Поток чата">{chatRateText(stats.chat_rate)}</LabeledList.Item>
      <LabeledList.Item label="BYOND">{data.byond}</LabeledList.Item>
    </LabeledList>
  </Section>
);

const Advice = ({ verdicts, stats }: { verdicts: VerdictCode[]; stats: Stats }) => {
  const { title, codes } = adviceFor(verdicts);
  if (!codes.length) {
    return null;
  }
  return (
    <Section title={title}>
      {codes.map((code) => (
        <Box key={code} mb={1}>
          <Box bold>{VERDICTS[code].title}</Box>
          <Box color="label">Почему так думаем: {whyText(code, stats)}</Box>
          {VERDICTS[code].advice.map((line) => (
            <Box key={line}>{line}</Box>
          ))}
        </Box>
      ))}
    </Section>
  );
};

const HintControls = () => {
  const { act, data } = useBackend<PingDiagnosticsData>();
  return (
    <Section>
      <Button.Checkbox checked={!!data.hint_enabled} onClick={() => act('toggle_hint')}>
        Подсказывать в чате, если связь плохая
      </Button.Checkbox>
      <Button icon="clipboard" onClick={() => act('report', { text: buildReport(data) })}>
        Отчёт в чат
      </Button>
    </Section>
  );
};

const SelfTab = () => {
  const { act, data } = useBackend<PingDiagnosticsData>();
  if (!data.target) {
    return (
      <>
        <NoticeBox>
          Замеров пока нет.
          {!!data.staff && <Button onClick={() => act('reset_target')}>Вернуться к своему</Button>}
        </NoticeBox>
        <HintControls />
      </>
    );
  }
  const verdicts = data.verdicts ?? ['collecting'];
  const stats = data.stats ?? {};
  const main = VERDICTS[verdicts[0]] ?? VERDICTS.collecting;
  return (
    <>
      {!data.self && (
        <NoticeBox info>
          Смотрите соединение {data.target}. <Button onClick={() => act('reset_target')}>Вернуться к своему</Button>
        </NoticeBox>
      )}
      <Section>
        <Box fontSize="1.4em" bold color={main.color}>
          {main.title}
        </Box>
        {main.side === 'ours' && <Box color="label">{whyText(verdicts[0], stats)}</Box>}
      </Section>
      <Breakdown stats={stats} />
      <Graph points={data.graph ?? []} />
      <Advice verdicts={verdicts} stats={stats} />
      <Numbers data={data} stats={stats} />
      <HintControls />
    </>
  );
};

const RoundBlock = ({ round }: { round?: RoundSummary }) =>
  round ? (
    <Section title="Итог раунда">
      <LabeledList>
        <LabeledList.Item label="Лишний пинг по нашей вине">{Math.round(round.ours_fraction * 100)}%</LabeledList.Item>
        <LabeledList.Item label="Вердикты">
          {Object.entries(round.verdicts).map(([code, count]) => `${VERDICTS[code as VerdictCode]?.title ?? code}: ${count}`).join('; ')}
        </LabeledList.Item>
        <LabeledList.Item label="Общие всплески">
          {Object.entries(round.events).map(([type, count]) => `${EVENT_TYPES[type as PingEvent['type']] ?? type}: ${count}`).join('; ') || 'не было'}
        </LabeledList.Item>
      </LabeledList>
    </Section>
  ) : null;

type Column = { key: string; label: string; value: (row: ClientRow) => number | string; cell?: (row: ClientRow) => string };

// Сервер не шлёт долю, пока лишнего почти нет: проценты от шума врут.
const percent = (fraction: number | null) => (fraction === null ? '-' : `${Math.round(fraction * 100)}%`);
const theirs = (fraction: number | null) => (fraction === null ? null : 1 - fraction);

const COLUMNS: Column[] = [
  { key: 'base', label: 'база', value: (row) => row.base },
  { key: 'rtt_median', label: 'медиана', value: (row) => row.rtt_median },
  { key: 'rtt_p95', label: 'p95', value: (row) => row.rtt_p95 },
  { key: 'personal_median', label: 'колебания', value: (row) => row.personal_median },
  { key: 'spikes_per_min', label: 'скачки/мин', value: (row) => row.spikes_per_min },
  { key: 'freezes', label: 'подвис.', value: (row) => row.freezes },
  { key: 'chat_rate', label: 'чат/с', value: (row) => row.chat_rate ?? -1, cell: (row) => (typeof row.chat_rate === 'number' ? row.chat_rate.toFixed(1) : '-') },
  { key: 'ours', label: 'наше', value: (row) => row.ours_fraction ?? -1, cell: (row) => percent(row.ours_fraction) },
  { key: 'theirs', label: 'ихнее', value: (row) => theirs(row.ours_fraction) ?? -1, cell: (row) => percent(theirs(row.ours_fraction)) },
];

const CKEY_COLUMN: Column = { key: 'ckey', label: 'ckey', value: (row) => row.ckey };
const VERDICT_COLUMN: Column = { key: 'verdict', label: 'вердикт', value: (row) => VERDICTS[row.verdict]?.title ?? row.verdict };
const SORTABLE = [CKEY_COLUMN, ...COLUMNS, VERDICT_COLUMN];

const ServerTab = () => {
  const { act, data } = useBackend<PingDiagnosticsData>();
  const [sort, setSort] = useState({ key: 'rtt_median', desc: true });
  const column = SORTABLE.find((entry) => entry.key === sort.key) ?? COLUMNS[1];
  const clients = [...(data.clients ?? [])].sort((a, b) => {
    const left = column.value(a);
    const right = column.value(b);
    const order = typeof left === 'number' && typeof right === 'number' ? left - right : String(left).localeCompare(String(right));
    return sort.desc ? -order : order;
  });
  const header = (entry: Column) => (
    <Table.Cell key={entry.key}>
      <Button
        color="transparent"
        icon={sort.key === entry.key ? (sort.desc ? 'sort-down' : 'sort-up') : undefined}
        onClick={() => setSort({ key: entry.key, desc: sort.key === entry.key ? !sort.desc : true })}>
        {entry.label}
      </Button>
    </Table.Cell>
  );
  return (
    <>
      <RoundBlock round={data.round} />
      <Section title="Игроки">
        <Table>
          <Table.Row header>{SORTABLE.map(header)}</Table.Row>
          {clients.map((row) => (
            <Table.Row key={row.ckey}>
              <Table.Cell>
                <Button onClick={() => act('inspect', { ckey: row.ckey })}>{row.ckey}</Button>
              </Table.Cell>
              {COLUMNS.map((entry) => (
                <Table.Cell key={entry.key}>{entry.cell ? entry.cell(row) : entry.value(row)}</Table.Cell>
              ))}
              <Table.Cell color={VERDICTS[row.verdict]?.color}>{VERDICTS[row.verdict]?.title ?? row.verdict}</Table.Cell>
            </Table.Row>
          ))}
        </Table>
      </Section>
      <Section title="Общие всплески">
        {data.events?.length ? (
          <Table>
            <Table.Row header>
              <Table.Cell>время</Table.Cell>
              <Table.Cell>тип</Table.Cell>
              <Table.Cell>масштаб</Table.Cell>
              <Table.Cell>источник</Table.Cell>
            </Table.Row>
            {[...data.events].reverse().map((event, index) => (
              <Table.Row key={`${event.time}-${index}`}>
                <Table.Cell>{event.time}</Table.Cell>
                <Table.Cell>{EVENT_TYPES[event.type] ?? event.type}</Table.Cell>
                <Table.Cell>
                  {Math.round(event.fraction * 100)}% из {event.clients}, +{event.extra_ms} мс, простой {event.stall_ms} мс
                </Table.Cell>
                <Table.Cell color="label">{event.source}</Table.Cell>
              </Table.Row>
            ))}
          </Table>
        ) : (
          <Box color="label">Пока не было.</Box>
        )}
      </Section>
    </>
  );
};

export const PingDiagnostics = () => {
  const { act, data } = useBackend<PingDiagnosticsData>();
  const tab = data.staff ? data.tab : 'self';
  return (
    <Window title="Диагностика пинга" width={720} height={760}>
      <Window.Content scrollable>
        {!!data.staff && (
          <Tabs>
            <Tabs.Tab selected={tab === 'self'} onClick={() => act('tab', { tab: 'self' })}>
              Моё соединение
            </Tabs.Tab>
            <Tabs.Tab selected={tab === 'server'} onClick={() => act('tab', { tab: 'server' })}>
              Сервер
            </Tabs.Tab>
          </Tabs>
        )}
        {tab === 'server' ? <ServerTab /> : <SelfTab />}
      </Window.Content>
    </Window>
  );
};
