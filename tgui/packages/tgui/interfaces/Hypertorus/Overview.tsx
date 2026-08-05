import { useBackend } from '../../backend';
import { Box, LabeledList, ProgressBar, Section, Stack } from '../../components';
import { getGasName } from '../../constants';
import { formatSiBaseTenUnit, formatSiUnit } from '../../format';
import { Alerts } from './Alerts';
import { Gases } from './Gases';
import {
  formatHeatOutput,
  getSelectedFuel,
  MAX_HEAT_LIMITER_MODIFIER,
  MAX_REACTOR_ENERGY,
} from './helpers';
import { Startup } from './Startup';
import { Temperatures } from './Temperatures';
import { HypertorusData } from './types';

/** Показатели самой реакции: что горит, сколько выделяет и куда уходит. */
const Reaction = () => {
  const { data } = useBackend<HypertorusData>();
  const {
    energy_level,
    heat_limiter_modifier,
    heat_output,
    heat_output_min,
    heat_output_max,
    product_gases,
  } = data;
  const fuel = getSelectedFuel(data);

  /**
   * Тепловой выход зажат между heat_output_min и heat_output_max, и эти границы
   * несимметричны. Показываем долю от того предела, в который упираемся.
   */
  const safeHeatOutput = Number.isFinite(heat_output) ? heat_output : 0;
  const heatLimitMin = Number.isFinite(heat_output_min) ? heat_output_min : -1;
  const heatLimitMax =
    Number.isFinite(heat_output_max) && heat_output_max !== 0 ? heat_output_max : 1;
  const heatDenominator = safeHeatOutput < 0 ? heatLimitMin : heatLimitMax;
  const heatActivity = heatDenominator !== 0 ? safeHeatOutput / heatDenominator : 0;

  return (
    <Section title="Реакция" fill>
      <LabeledList>
        <LabeledList.Item label="Рецепт">
          <Box color={fuel ? 'good' : 'average'}>{fuel?.name ?? 'не выбран'}</Box>
        </LabeledList.Item>
        <LabeledList.Item label="Топливо">
          {fuel?.requirements?.length
            ? fuel.requirements.map((gasId) => getGasName(gasId)).join(' + ')
            : '-'}
        </LabeledList.Item>
        <LabeledList.Item label="Продукты">
          <Box style={{ whiteSpace: 'pre-wrap' }}>{product_gases ?? 'нет'}</Box>
        </LabeledList.Item>
        <LabeledList.Item label="Энергия">
          <ProgressBar
            color="yellow"
            value={energy_level}
            minValue={0}
            maxValue={MAX_REACTOR_ENERGY}
          >
            {formatSiUnit(energy_level, 1, 'J')}
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item label="Ограничитель">
          <ProgressBar
            color="blue"
            value={heat_limiter_modifier}
            minValue={0}
            maxValue={MAX_HEAT_LIMITER_MODIFIER}
          >
            {formatSiBaseTenUnit(heat_limiter_modifier, 0, 'K')}
          </ProgressBar>
        </LabeledList.Item>
        <LabeledList.Item label="Тепловой выход">
          <ProgressBar
            color={safeHeatOutput < 0 ? 'teal' : 'orange'}
            value={Number.isFinite(heatActivity) ? heatActivity : 0}
            minValue={-1}
            maxValue={1.3}
          >
            {formatHeatOutput(safeHeatOutput)}
          </ProgressBar>
        </LabeledList.Item>
      </LabeledList>
    </Section>
  );
};

export const Overview = () => (
  <Stack vertical fill>
    <Stack.Item>
      <Startup />
    </Stack.Item>
    <Stack.Item>
      <Alerts />
    </Stack.Item>
    <Stack.Item>
      <Stack>
        <Stack.Item grow basis={0}>
          <Temperatures />
        </Stack.Item>
        <Stack.Item grow basis={0}>
          <Reaction />
        </Stack.Item>
      </Stack>
    </Stack.Item>
    <Stack.Item grow>
      <Gases />
    </Stack.Item>
  </Stack>
);
