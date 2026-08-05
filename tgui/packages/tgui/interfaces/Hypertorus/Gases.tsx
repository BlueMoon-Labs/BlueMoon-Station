import { toFixed } from 'common/math';

import { useBackend } from '../../backend';
import { Box, Icon, ProgressBar, Section, Stack, Tooltip } from '../../components';
import { getGasColor, getGasName } from '../../constants';
import { getSelectedFuel, getThresholds } from './helpers';
import { HypertorusData, HypertorusGas } from './types';

/** Ниже этого количества газ не показываем: DM шлёт нули по всем ста газам. */
const VISIBLE_MOLE_THRESHOLD = 0.01;

const sortedGases = (gases: HypertorusGas[]) =>
  (gases ?? [])
    .filter((gas) => gas.amount >= VISIBLE_MOLE_THRESHOLD)
    .sort((left, right) => right.amount - left.amount);

type GasColumnProps = {
  title: string;
  gases: HypertorusGas[];
  total: number;
  /** Газы рецепта, за которыми игрок обязан следить. */
  required?: string[];
  /** Минимум молей требуемого газа, иначе реакция не идёт. */
  requiredMinimum?: number;
  emptyText: string;
  totalTooltip: string;
  totalColor?: string;
};

const GasColumn = (props: GasColumnProps) => {
  const {
    title,
    gases,
    total,
    required = [],
    requiredMinimum = 0,
    emptyText,
    totalTooltip,
    totalColor,
  } = props;
  const visible = sortedGases(gases);
  const max = Math.max(1, ...visible.map((gas) => gas.amount));

  return (
    <Section
      title={title}
      className="Hypertorus__gasColumn"
      buttons={
        <Tooltip content={totalTooltip}>
          <Box className="Hypertorus__gasTotal" color={totalColor}>
            {`${toFixed(total ?? 0, 1)} моль`}
          </Box>
        </Tooltip>
      }
    >
      {visible.length === 0 ? (
        <Box color="label" italic>
          {emptyText}
        </Box>
      ) : (
        visible.map((gas) => {
          const isRequired = required.includes(gas.id);
          const starved = isRequired && gas.amount < requiredMinimum;
          return (
            <Box key={gas.id} className="Hypertorus__gasRow">
              <Box className="Hypertorus__gasName">
                {isRequired && (
                  <Tooltip
                    content={`Топливо рецепта: нужно не меньше ${requiredMinimum} молей`}
                  >
                    <Icon
                      name={starved ? 'exclamation-triangle' : 'fire'}
                      color={starved ? 'bad' : 'good'}
                      mr={0.5}
                    />
                  </Tooltip>
                )}
                {getGasName(gas.id)}
              </Box>
              <ProgressBar
                className="Hypertorus__gasBar"
                color={starved ? 'bad' : getGasColor(gas.id)}
                value={gas.amount}
                minValue={0}
                maxValue={max}
              >
                {`${toFixed(gas.amount, 2)} моль`}
              </ProgressBar>
            </Box>
          );
        })
      )}
    </Section>
  );
};

/** Обе внутренние смеси реактора рядом: топливо слева, модератор справа. */
export const Gases = () => {
  const { data } = useBackend<HypertorusData>();
  const thresholds = getThresholds(data);
  const fuel = getSelectedFuel(data);
  const fusionMoles = data.fusion_moles ?? 0;

  const fusionTotalColor =
    fusionMoles >= thresholds.hypercritical_moles
      ? 'bad'
      : fusionMoles > thresholds.overmole_moles
        ? 'average'
        : fusionMoles && fusionMoles < thresholds.subcritical_moles
          ? 'blue'
          : 'good';

  return (
    <Stack fill>
      <Stack.Item grow basis={0}>
        <GasColumn
          title="Камера синтеза"
          gases={data.fusion_gases}
          total={fusionMoles}
          required={fuel?.requirements}
          requiredMinimum={thresholds.fusion_mole_minimum}
          totalColor={fusionTotalColor}
          emptyText="Камера пуста: подайте топливо."
          totalTooltip={`Ниже ${thresholds.subcritical_moles} молей реакция затухает и корпус лечится, выше ${thresholds.overmole_moles} - периодический урон, выше ${thresholds.hypercritical_moles} - непрерывный.`}
        />
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <GasColumn
          title="Модератор"
          gases={data.moderator_gases}
          total={data.moderator_moles ?? 0}
          emptyText="Модератор пуст: реакция идёт без присадок."
          totalTooltip="Газы модератора задают выход энергии, тепло, излучение и побочные продукты. Испаряются тем быстрее, чем выше уровень мощности."
        />
      </Stack.Item>
    </Stack>
  );
};
