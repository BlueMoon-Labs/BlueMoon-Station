import { useBackend } from '../../backend';
import { Box, Button, ProgressBar, Section, Stack } from '../../components';
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
import { Tuning } from './Tuning';
import { HypertorusData } from './types';

type ReactionProps = {
  /** Открывает вкладку рецептов: сам выбор живёт там, здесь только индикатор. */
  onOpenRecipes: () => void;
};

/** Показатели самой реакции: что горит, сколько выделяет и куда уходит. */
const Reaction = (props: ReactionProps) => {
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

  /** Три шкалы в один ряд: полоса отклика реакции, а не таблица на пол-окна. */
  const metrics = [
    {
      label: 'Энергия',
      bar: (
        <ProgressBar
          color="yellow"
          value={energy_level}
          minValue={0}
          maxValue={MAX_REACTOR_ENERGY}
        >
          {formatSiUnit(energy_level, 1, 'J')}
        </ProgressBar>
      ),
    },
    {
      label: 'Ограничитель',
      bar: (
        <ProgressBar
          color="blue"
          value={heat_limiter_modifier}
          minValue={0}
          maxValue={MAX_HEAT_LIMITER_MODIFIER}
        >
          {formatSiBaseTenUnit(heat_limiter_modifier, 0, 'K')}
        </ProgressBar>
      ),
    },
    {
      label: 'Тепловой выход',
      bar: (
        <ProgressBar
          color={safeHeatOutput < 0 ? 'teal' : 'orange'}
          value={Number.isFinite(heatActivity) ? heatActivity : 0}
          minValue={-1}
          maxValue={1.3}
        >
          {formatHeatOutput(safeHeatOutput)}
        </ProgressBar>
      ),
    },
  ];

  return (
    <Section
      title="Реакция"
      buttons={
        <Button
          icon={fuel ? 'flask' : 'exclamation-triangle'}
          color={fuel ? undefined : 'average'}
          tooltip={
            (fuel ? `Продукты: ${product_gases ?? 'нет'}. ` : '') +
            'Открыть вкладку рецептов.'
          }
          onClick={props.onOpenRecipes}
        >
          {fuel?.name ?? 'Рецепт не выбран'}
        </Button>
      }
    >
      <Stack>
        {metrics.map((metric) => (
          <Stack.Item
            key={metric.label}
            grow
            basis={0}
            className="Hypertorus__reactionMetric"
          >
            <Box className="Hypertorus__metricLabel">{metric.label}</Box>
            {metric.bar}
          </Stack.Item>
        ))}
      </Stack>
    </Section>
  );
};

type OverviewProps = {
  onOpenRecipes: () => void;
};

/**
 * Всё управление разгоном в одном окне: регуляторы стоят рядом со шкалами,
 * по которым виден их отклик, - игроки просили не гонять их по вкладкам.
 */
export const Overview = (props: OverviewProps) => (
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
          <Tuning />
        </Stack.Item>
      </Stack>
    </Stack.Item>
    <Stack.Item>
      <Reaction onOpenRecipes={props.onOpenRecipes} />
    </Stack.Item>
    <Stack.Item grow>
      <Gases />
    </Stack.Item>
  </Stack>
);
