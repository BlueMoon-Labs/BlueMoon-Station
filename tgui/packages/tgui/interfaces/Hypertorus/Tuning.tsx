import { useBackend } from '../../backend';
import { Box, Icon, NumberInput, Section, Slider, Stack, Tooltip } from '../../components';
import { getLimit } from './helpers';
import { HypertorusData, HypertorusLimits } from './types';

type Knob = {
  /** Совпадает и с полем ui_data, и с действием ui_act. */
  action: keyof HypertorusData & string;
  limit: keyof HypertorusLimits;
  label: string;
  unit: string;
  hint: string;
};

const KNOBS: Knob[] = [
  {
    action: 'heating_conductor',
    limit: 'heating_conductor',
    label: 'Теплопроводник',
    unit: 'Дж/см',
    hint: 'Поднимает потолок теплового выхода: ограничитель растёт линейно вместе с ним. Больше нагрева - быстрее разгон и быстрее износ.',
  },
  {
    action: 'magnetic_constrictor',
    limit: 'magnetic_constrictor',
    label: 'Магнитный констриктор',
    unit: 'м³/Тл',
    hint: 'Сжимает объём камеры синтеза. Меньше объём - плотнее смесь и выше нестабильность, но и перегруз наступает раньше.',
  },
  {
    action: 'fuel_injection_rate',
    limit: 'fuel_injection_rate',
    label: 'Впрыск топлива',
    unit: 'моль/с',
    hint: 'Сколько газа рецепта уходит в камеру за такт. Прямо задаёт скорость набора молей, а с ней и риск перегруза.',
  },
  {
    action: 'moderator_injection_rate',
    limit: 'moderator_injection_rate',
    label: 'Впрыск модератора',
    unit: 'моль/с',
    hint: 'Подача присадок. Модератор задаёт выход энергии и тепла, но испаряется тем быстрее, чем выше уровень мощности.',
  },
  {
    action: 'current_damper',
    limit: 'current_damper',
    label: 'Демпфер тока',
    unit: 'Вт',
    hint: 'Поднимает нестабильность. Перевалив порог, реактор переключается с нагрева на охлаждение - так его и тормозят.',
  },
  {
    action: 'cooling_volume',
    limit: 'cooling_volume',
    label: 'Объём контура охлаждения',
    unit: 'л',
    hint: 'Объём хладагента на такт. Больше объём - медленнее нагрев хладагента, но и теплоотвод инертнее.',
  },
];

/** Регуляторы реактора. Границы приезжают из ui_static_data вместе с клампами. */
export const Tuning = () => {
  const { act, data } = useBackend<HypertorusData>();

  return (
    <Section title="Тонкая настройка">
      <Stack vertical>
        {KNOBS.map((knob) => {
          const limit = getLimit(data.limits, knob.limit);
          const value = Number(data[knob.action] ?? limit.min);
          return (
            <Stack.Item key={knob.action}>
              <Box className="Hypertorus__knob">
                <Tooltip
                  content={`${knob.hint} Диапазон: ${limit.min}-${limit.max} ${knob.unit}.`}
                >
                  <Box className="Hypertorus__knobLabel">
                    {knob.label}
                    <Icon name="question-circle" ml={0.5} />
                  </Box>
                </Tooltip>
                {/* Точное число живёт в поле справа, поэтому шкала показывает
                    только положение регулятора в своём диапазоне. */}
                <Box className="Hypertorus__knobControl">
                  <Slider
                    value={value}
                    minValue={limit.min}
                    maxValue={limit.max}
                    step={limit.step ?? 1}
                    stepPixelSize={2}
                    onDrag={(event, next) => act(knob.action, { [knob.action]: next })}
                  >
                    <Box className="Hypertorus__knobRange">
                      {`${limit.min} - ${limit.max}`}
                    </Box>
                  </Slider>
                </Box>
                <Box className="Hypertorus__knobInput">
                  <NumberInput
                    animated
                    value={value}
                    width="70px"
                    unit={knob.unit}
                    minValue={limit.min}
                    maxValue={limit.max}
                    step={limit.step ?? 1}
                    onDrag={(event, next) => act(knob.action, { [knob.action]: next })}
                  />
                </Box>
              </Box>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
};
