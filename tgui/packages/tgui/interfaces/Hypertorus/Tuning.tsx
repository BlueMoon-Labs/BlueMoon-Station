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

/**
 * Термические регуляторы: их отклик - график температур слева. Впрыск топлива
 * и модератора живут у своих газовых колонок ниже, а не здесь.
 */
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
    action: 'current_damper',
    limit: 'current_damper',
    label: 'Демпфер тока',
    unit: 'Вт',
    hint: 'Поднимает нестабильность. Перевалив порог, реактор переключается с нагрева на охлаждение - так его и тормозят.',
  },
  {
    action: 'cooling_volume',
    limit: 'cooling_volume',
    label: 'Объём охлаждения',
    unit: 'л',
    hint: 'Объём хладагента на такт. Больше объём - медленнее нагрев хладагента, но и теплоотвод инертнее.',
  },
];

/** Регуляторы реактора. Границы приезжают из ui_static_data вместе с клампами. */
export const Tuning = () => {
  const { act, data } = useBackend<HypertorusData>();

  return (
    <Section title="Регуляторы" fill>
      <Stack vertical>
        {KNOBS.map((knob) => {
          const limit = getLimit(data.limits, knob.limit);
          const value = Number(data[knob.action] ?? limit.min);
          return (
            <Stack.Item key={knob.action}>
              {/* Узкая колонка рядом с графиком: подпись и точное поле в одну
                  строку, слайдер во всю ширину под ними. Диапазон - в тултипе,
                  на шкале ему уже не хватает места. */}
              <Box className="Hypertorus__knob">
                <Stack align="center">
                  <Stack.Item grow>
                    <Tooltip
                      content={`${knob.hint} Диапазон: ${limit.min}-${limit.max} ${knob.unit}.`}
                    >
                      <Box className="Hypertorus__knobLabel">
                        {knob.label}
                        <Icon name="question-circle" ml={0.5} />
                      </Box>
                    </Tooltip>
                  </Stack.Item>
                  <Stack.Item>
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
                  </Stack.Item>
                </Stack>
                <Box className="Hypertorus__knobControl">
                  {/* Точное число уже стоит в поле справа от подписи. Неразрывный
                      пробел глушит дубль-подпись слайдера, но сохраняет высоту
                      дорожки: она считается от line-height содержимого. */}
                  <Slider
                    value={value}
                    minValue={limit.min}
                    maxValue={limit.max}
                    step={limit.step ?? 1}
                    stepPixelSize={2}
                    onDrag={(event, next) => act(knob.action, { [knob.action]: next })}
                  >
                    {'\u00a0'}
                  </Slider>
                </Box>
              </Box>
            </Stack.Item>
          );
        })}
      </Stack>
    </Section>
  );
};
