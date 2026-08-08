import { toFixed } from 'common/math';
import { ReactNode } from 'react';

import { useBackend } from '../../backend';
import {
  Box,
  Button,
  Icon,
  NumberInput,
  ProgressBar,
  Section,
  Stack,
  Tooltip,
} from '../../components';
import { getGasColor, getGasName } from '../../constants';
import {
  getLimit,
  getSelectedFuel,
  getThresholds,
  WASTE_REMOVE_MAX_POWER_LEVEL,
} from './helpers';
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
  /** Быстрый регулятор контура в шапке секции: действие рядом с откликом. */
  controls?: ReactNode;
  /** Строка действий под списком газов: тумблеры этого же контура. */
  footer?: ReactNode;
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
    controls,
    footer,
  } = props;
  const visible = sortedGases(gases);
  const max = Math.max(1, ...visible.map((gas) => gas.amount));

  return (
    <Section
      fill
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
      {controls}
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
      {footer}
    </Section>
  );
};

/** Регулятор впрыска первой строкой колонки: действие рядом с его откликом. */
const InjectionControl = (props: {
  action: 'fuel_injection_rate' | 'moderator_injection_rate';
  label: string;
  hint: string;
}) => {
  const { act, data } = useBackend<HypertorusData>();
  const limit = getLimit(data.limits, props.action);
  const value = Number(data[props.action] ?? limit.min);
  return (
    <Box className="Hypertorus__injectRow">
      <Stack align="center">
        <Stack.Item grow>
          <Tooltip
            content={`${props.hint} Диапазон: ${limit.min}-${limit.max} моль/с.`}
          >
            <Box className="Hypertorus__knobLabel">
              {props.label}
              <Icon name="question-circle" ml={0.5} />
            </Box>
          </Tooltip>
        </Stack.Item>
        <Stack.Item>
          <NumberInput
            animated
            value={value}
            width="66px"
            unit="моль/с"
            minValue={limit.min}
            maxValue={limit.max}
            step={limit.step ?? 1}
            onDrag={(event, next) => act(props.action, { [props.action]: next })}
          />
        </Stack.Item>
      </Stack>
    </Box>
  );
};

/**
 * Тумблер отвода отходов у самого модератора: включил - и тут же видно, как
 * уходят выбранные газы. Какие именно газы отводить - на вкладке «Фильтры».
 */
const WasteControls = () => {
  const { act, data } = useBackend<HypertorusData>();
  const { waste_remove, mod_filtering_rate, filter_types = [], power_level } = data;
  const limit = getLimit(data.limits, 'filtering_rate');
  const enabledCount = filter_types.filter((filter) => filter.enabled).length;
  const wasteLocked = power_level > WASTE_REMOVE_MAX_POWER_LEVEL;

  return (
    <Box className="Hypertorus__wasteRow">
      <Stack align="center">
        <Stack.Item>
          <Tooltip
            content={
              wasteLocked
                ? `Уровень мощности выше ${WASTE_REMOVE_MAX_POWER_LEVEL}: выхлоп слишком горяч, отвод заблокирован.`
                : 'Выкачивает выбранные газы из модератора в порт отходов.'
            }
          >
            <Box inline>
              <Button
                disabled={wasteLocked}
                icon={waste_remove ? 'power-off' : 'times'}
                content={waste_remove ? 'Отвод: вкл' : 'Отвод: выкл'}
                selected={waste_remove}
                onClick={() => act('waste_remove')}
              />
            </Box>
          </Tooltip>
        </Stack.Item>
        <Stack.Item>
          <NumberInput
            animated
            value={mod_filtering_rate}
            width="66px"
            unit="моль/с"
            minValue={limit.min}
            maxValue={limit.max}
            step={1}
            onDrag={(event, next) =>
              act('mod_filtering_rate', { mod_filtering_rate: next })
            }
          />
        </Stack.Item>
        <Stack.Item grow textAlign="right">
          <Box color={enabledCount ? 'label' : 'average'}>
            {enabledCount
              ? `газов: ${enabledCount}`
              : 'газы не выбраны'}
          </Box>
        </Stack.Item>
      </Stack>
    </Box>
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
          controls={
            <InjectionControl
              action="fuel_injection_rate"
              label="Впрыск топлива"
              hint="Сколько газа рецепта уходит в камеру за такт. Прямо задаёт скорость набора молей, а с ней и риск перегруза."
            />
          }
        />
      </Stack.Item>
      <Stack.Item grow basis={0}>
        <GasColumn
          title="Модератор"
          gases={data.moderator_gases}
          total={data.moderator_moles ?? 0}
          emptyText="Модератор пуст: реакция идёт без присадок."
          totalTooltip="Газы модератора задают выход энергии, тепло, излучение и побочные продукты. Испаряются тем быстрее, чем выше уровень мощности."
          controls={
            <InjectionControl
              action="moderator_injection_rate"
              label="Впрыск модератора"
              hint="Подача присадок. Модератор задаёт выход энергии и тепла, но испаряется тем быстрее, чем выше уровень мощности."
            />
          }
          footer={<WasteControls />}
        />
      </Stack.Item>
    </Stack>
  );
};
