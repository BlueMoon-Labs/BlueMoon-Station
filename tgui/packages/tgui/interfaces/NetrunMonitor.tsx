import { BooleanLike } from 'common/react';

import { useBackend } from '../backend';
import { Box, Chart, LabeledList, NoticeBox, Section, Stack } from '../components';
import { Window } from '../layouts';

type MetricValue = string | number | boolean | null;

type MetricSection = {
  title: string;
  rows: { label: string; value: MetricValue; unit?: string }[];
};

type HistorySample = {
  time: number;
  tx_kib_s: number;
  rx_kib_s: number;
  input_frames: number;
  pending: number;
  ack_ms: number | null;
  host_ms: number | null;
};

export type NetrunMonitorData = {
  status: {
    mode: string;
    state: string;
    ready: BooleanLike;
    health: 'ok' | 'waiting' | 'stale' | 'error' | 'offline';
    label: string;
    detail: string;
    last_error: string | null;
    telemetry_supported: BooleanLike;
    telemetry_age_s: number | null;
    binding: string | null;
  };
  sections: MetricSection[];
  history: HistorySample[];
};

const healthColors = {
  ok: 'green',
  waiting: 'blue',
  stale: 'yellow',
  error: 'red',
  offline: 'grey',
};

const formatValue = (value: MetricValue) => {
  if (value === null || value === undefined) {
    return '—';
  }
  if (typeof value === 'boolean') {
    return value ? 'да' : 'нет';
  }
  if (typeof value === 'number') {
    return value.toLocaleString('ru-RU', { maximumFractionDigits: 3 });
  }
  return value;
};

type TrendSeries = {
  label: string;
  key: 'tx_kib_s' | 'rx_kib_s' | 'input_frames' | 'pending';
  color: string;
};

const networkSeries: TrendSeries[] = [
  { label: 'Отправка', key: 'tx_kib_s', color: '#54c8ff' },
  { label: 'Приём', key: 'rx_kib_s', color: '#76db97' },
];

const queueSeries: TrendSeries[] = [
  { label: 'Input без ACK', key: 'input_frames', color: '#54c8ff' },
  { label: 'Ожидающие операции', key: 'pending', color: '#ffc35a' },
];

const Trend = (props: {
  title: string;
  unit: string;
  history: HistorySample[];
  series: TrendSeries[];
}) => {
  const { title, unit, history, series } = props;
  if (history.length < 2) {
    return (
      <Section title={title}>
        <Box color="label">Для графика нужны два снимка.</Box>
      </Section>
    );
  }
  const firstTime = history[0].time;
  const lastTime = history[history.length - 1].time;
  const maximum = Math.max(1, ...history.flatMap((sample) => (
    series.map((line) => sample[line.key])
  )));
  return (
    <Section title={`${title}, ${unit}`}>
      <Box mb={0.5}>
        {series.map((line) => (
          <Box inline mr={1.5} key={line.key} color={line.color}>
            {line.label}: {formatValue(history[history.length - 1][line.key])}
          </Box>
        ))}
      </Box>
      <Box position="relative" height="7em">
        {series.map((line) => (
          <Chart.Line
            key={line.key}
            fillPositionedParent
            data={history.map((sample) => [sample.time, sample[line.key]])}
            rangeX={[firstTime, Math.max(firstTime + 1, lastTime)]}
            rangeY={[0, maximum]}
            strokeColor={line.color}
            strokeWidth={2}
            fillColor="none"
          />
        ))}
      </Box>
      <Box mt={0.5} color="label">
        Последние {formatValue(Math.max(0, lastTime - firstTime))} с
        {' · '}шкала 0–{formatValue(maximum)} {unit}
      </Box>
    </Section>
  );
};

const Metrics = (props: { section: MetricSection }) => (
  <Section title={props.section.title}>
    <LabeledList>
      {props.section.rows.map((row) => (
        <LabeledList.Item key={row.label} label={row.label}>
          <Box style={{ overflowWrap: 'anywhere' }}>
            {formatValue(row.value)}{row.unit ? ` ${row.unit}` : ''}
          </Box>
        </LabeledList.Item>
      ))}
    </LabeledList>
  </Section>
);

export const NetrunMonitor = () => {
  const { data } = useBackend<NetrunMonitorData>();
  const { status, sections = [], history = [] } = data;
  return (
    <Window width={1100} height={850} title="NETRUN Library Monitor">
      <Window.Content scrollable>
        <NoticeBox color={healthColors[status.health]}>
          <Box bold>{status.label}</Box>
          {status.detail}
        </NoticeBox>
        <Section title="Состояние библиотеки">
          <LabeledList>
            <LabeledList.Item label="Режим / состояние">
              {status.mode} / {status.state}
            </LabeledList.Item>
            <LabeledList.Item label="Готова к работе">
              {status.ready ? 'да' : 'нет'}
            </LabeledList.Item>
            <LabeledList.Item label="Телеметрия Host">
              {!status.telemetry_supported ? 'Телеметрия не согласована с Host' : (
                status.telemetry_age_s === null
                  ? 'Ожидается первый снимок'
                  : `Получена ${formatValue(status.telemetry_age_s)} с назад`
              )}
            </LabeledList.Item>
            <LabeledList.Item label="Binding">
              <Box style={{ overflowWrap: 'anywhere' }}>
                {formatValue(status.binding)}
              </Box>
            </LabeledList.Item>
            {status.last_error && (
              <LabeledList.Item label="Последняя ошибка" color="bad">
                {status.last_error}
              </LabeledList.Item>
            )}
          </LabeledList>
        </Section>
        <Stack>
          {[0, 1].map((column) => (
            <Stack.Item key={column} grow basis={0} minWidth={0}>
              {sections.filter((_section, index) => index % 2 === column)
                .map((section) => <Metrics key={section.title} section={section} />)}
            </Stack.Item>
          ))}
        </Stack>
        <Stack>
          <Stack.Item grow basis={0} minWidth={0}>
            <Trend title="Трафик IPC" unit="KiB/s" history={history} series={networkSeries} />
          </Stack.Item>
          <Stack.Item grow basis={0} minWidth={0}>
            <Trend title="Очереди" unit="шт." history={history} series={queueSeries} />
          </Stack.Item>
        </Stack>
        <Box color="label" fontSize="0.9em">
          Снимки обновляются автоматически. CPU Host и ожидание ACK измеряются отдельно.
        </Box>
      </Window.Content>
    </Window>
  );
};
