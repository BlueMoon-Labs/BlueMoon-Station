import { useBackend } from '../../backend';
import { Box, Icon, ProgressBar, Stack, Tooltip } from '../../components';
import { formatSiUnit } from '../../format';
import {
  formatTemperature,
  getPowerLevelProgress,
  getReactorStatus,
  getThresholds,
} from './helpers';
import { HypertorusData } from './types';

/** Крупная плашка состояния слева: одна строка, по которой всё понятно. */
const StatusBadge = () => {
  const { data } = useBackend<HypertorusData>();
  const status = getReactorStatus(data);
  const { progress, next } = getPowerLevelProgress(data);
  const alarming = status.id === 'melting' || status.id === 'emergency';

  return (
    <Box
      className={`Hypertorus__badge Hypertorus__badge--${status.id}${
        alarming ? ' Hypertorus__badge--alarm' : ''
      }`}
    >
      <Box className="Hypertorus__badgeLamp" />
      <Box className="Hypertorus__badgeBody">
        <Box className="Hypertorus__badgeLabel">{status.label}</Box>
        <Tooltip
          content={
            next > 0
              ? `Следующий уровень мощности с ${formatTemperature(next)} газа синтеза`
              : 'Максимальный уровень мощности'
          }
        >
          <Box className="Hypertorus__badgeProgress">
            <Box
              className="Hypertorus__badgeProgressFill"
              style={{ width: `${Math.round(progress * 100)}%` }}
            />
          </Box>
        </Tooltip>
      </Box>
    </Box>
  );
};

type MetricProps = {
  label: string;
  tooltip: string;
  children: any;
};

const Metric = (props: MetricProps) => (
  <Stack.Item grow basis={0} className="Hypertorus__metric">
    <Tooltip content={props.tooltip}>
      <Box className="Hypertorus__metricLabel">
        {props.label}
        <Icon name="question-circle" ml={0.5} />
      </Box>
    </Tooltip>
    {props.children}
  </Stack.Item>
);

/**
 * Шапка окна: состояние, целостность, железо, нестабильность и питание.
 * Видна на всех вкладках, чтобы разгон не приходилось сверять по памяти.
 */
export const StatusHeader = () => {
  const { data } = useBackend<HypertorusData>();
  const thresholds = getThresholds(data);
  const {
    integrity,
    iron_content,
    instability,
    apc_energy,
    power_output,
    power_level,
  } = data;
  const heating = instability < thresholds.instability_flip;

  return (
    <Box className="Hypertorus__header">
      <Stack align="center">
        <Stack.Item>
          <StatusBadge />
        </Stack.Item>
        <Metric
          label="Целостность"
          tooltip={`Ниже ${thresholds.integrity_danger}% реактор кричит в общий канал, ниже ${thresholds.integrity_melting}% начинается расплавление.`}
        >
          <ProgressBar
            value={integrity}
            minValue={0}
            maxValue={100}
            ranges={{
              good: [thresholds.integrity_warning, Infinity],
              average: [thresholds.integrity_danger, thresholds.integrity_warning],
              bad: [-Infinity, thresholds.integrity_danger],
            }}
          >
            {`${(integrity ?? 0).toFixed(1)} %`}
          </ProgressBar>
        </Metric>
        <Metric
          label="Железо"
          tooltip={`Копится выше уровня мощности ${thresholds.iron_growth_power_level}, разъедает камеру с ${thresholds.iron_damage}. На уровне ${thresholds.iron_growth_power_level} и ниже распадается само.`}
        >
          <ProgressBar
            value={iron_content}
            minValue={0}
            maxValue={thresholds.maximum_iron}
            ranges={{
              good: [-Infinity, 1],
              average: [1, thresholds.iron_damage],
              bad: [thresholds.iron_damage, Infinity],
            }}
          >
            {(iron_content ?? 0).toFixed(2)}
          </ProgressBar>
        </Metric>
        <Metric
          label={heating ? 'Режим: нагрев' : 'Режим: охлаждение'}
          tooltip={`Нестабильность ${(instability ?? 0).toFixed(
            2,
          )}. Ниже ${thresholds.instability_flip} реактор греет сам себя, на этом значении и выше - охлаждает. Демпфер тока поднимает нестабильность, железо опускает.`}
        >
          <ProgressBar
            value={instability}
            minValue={0}
            maxValue={Math.max(thresholds.instability_flip * 2, 1)}
            color={heating ? 'orange' : 'teal'}
          >
            {(instability ?? 0).toFixed(2)}
          </ProgressBar>
        </Metric>
        <Metric
          label="Выход мощности"
          tooltip="КПД * (внутренняя мощность - теплопроводность - излучение). Из него считается тепловой выход."
        >
          <Box className="Hypertorus__metricValue">
            {power_level > 0 ? formatSiUnit(Math.max(power_output ?? 0, 0), 0) : '-'}
          </Box>
        </Metric>
        <Metric
          label="Заряд ОРУ"
          tooltip="Заряд ячейки ОРУ этой области. Без питания регуляторы сбрасываются в аварийные значения, а железо копится само по себе."
        >
          <ProgressBar
            value={apc_energy}
            minValue={0}
            maxValue={100}
            ranges={{
              good: [50, Infinity],
              average: [15, 50],
              bad: [-Infinity, 15],
            }}
          >
            {`${Math.round(apc_energy ?? 0)} %`}
          </ProgressBar>
        </Metric>
      </Stack>
    </Box>
  );
};
