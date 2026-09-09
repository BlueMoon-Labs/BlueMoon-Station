import { useBackend } from '../../backend';
import { Box, Section, Tooltip } from '../../components';
import {
  formatDelta,
  formatTemperature,
  getPowerLevelTemperatures,
  temperatureDelta,
} from './helpers';
import { HypertorusData } from './types';

/** Высота поля графика в пикселях. */
const CHART_HEIGHT = 160;

/** Космический фон: ниже реликтового излучения температура не падает. */
const MINIMUM_TEMPERATURE = 2.73;

/** Две отметки ближе этого расстояния сливаются, вторую не рисуем. */
const LABEL_CLUTTER_PX = 16;

type Bar = {
  id: string;
  label: string;
  value: number;
  delta: number;
  color: string;
};

/**
 * Четыре контура реактора на одной логарифмической шкале. Линейная шкала здесь
 * бесполезна: газ синтеза живёт в миллионах кельвинов, а хладагент - в сотнях,
 * и на общей линейке хладагент всегда прижат к нулю.
 */
export const Temperatures = () => {
  const { data } = useBackend<HypertorusData>();
  const {
    internal_fusion_temperature,
    internal_fusion_temperature_archived,
    moderator_internal_temperature,
    moderator_internal_temperature_archived,
    internal_coolant_temperature,
    internal_coolant_temperature_archived,
    internal_output_temperature,
    internal_output_temperature_archived,
    temperature_period,
    power_level,
  } = data;

  const bars: Bar[] = [
    {
      id: 'fusion',
      label: 'Синтез',
      value: internal_fusion_temperature,
      delta: temperatureDelta(
        internal_fusion_temperature,
        internal_fusion_temperature_archived,
        temperature_period,
      ),
      color: '#c2701c',
    },
    {
      id: 'moderator',
      label: 'Модератор',
      value: moderator_internal_temperature,
      delta: temperatureDelta(
        moderator_internal_temperature,
        moderator_internal_temperature_archived,
        temperature_period,
      ),
      color: '#a06a8c',
    },
    {
      id: 'coolant',
      label: 'Хладагент',
      value: internal_coolant_temperature,
      delta: temperatureDelta(
        internal_coolant_temperature,
        internal_coolant_temperature_archived,
        temperature_period,
      ),
      color: '#4b7fa8',
    },
    {
      id: 'output',
      label: 'Выход',
      value: internal_output_temperature,
      delta: temperatureDelta(
        internal_output_temperature,
        internal_output_temperature_archived,
        temperature_period,
      ),
      color: '#5f8f4e',
    },
  ];

  const levelTemperatures = getPowerLevelTemperatures(data);
  /** Показываем порог текущего уровня и следующего: остальные только шумят. */
  const marks = levelTemperatures
    .map((temperature, index) => ({ temperature, level: index + 1 }))
    .filter((mark) => Math.abs(mark.level - power_level) <= 1 && mark.level >= power_level);

  const values = bars.map((bar) => bar.value).filter((value) => value > 0);
  const markValues = marks.map((mark) => mark.temperature);
  const maxTemperature = Math.max(10, ...values, ...markValues);
  const minTemperature = Math.max(
    MINIMUM_TEMPERATURE,
    Math.min(20, ...values, ...markValues),
  );

  const logSpan = Math.log10(maxTemperature) - Math.log10(minTemperature);
  const valueToHeight = (value: number) => {
    if (!(value > 0) || logSpan <= 0) {
      return 0;
    }
    const ratio = (Math.log10(value) - Math.log10(minTemperature)) / logSpan;
    return Math.max(0, Math.min(1, ratio)) * CHART_HEIGHT;
  };

  /** Отметки, налезающие друг на друга, скрываем: подписи важнее сетки. */
  const visibleMarks = marks.filter((mark, index) => {
    if (index === 0) {
      return true;
    }
    return (
      Math.abs(
        valueToHeight(mark.temperature) - valueToHeight(marks[index - 1].temperature),
      ) > LABEL_CLUTTER_PX
    );
  });

  return (
    <Section title="Температуры контуров" className="Hypertorus__temperatures">
      <Box className="Hypertorus__chart" style={{ height: `${CHART_HEIGHT}px` }}>
        {visibleMarks.map((mark) => (
          <Tooltip
            key={mark.level}
            content={`Уровень мощности ${mark.level} с ${formatTemperature(
              mark.temperature,
            )} газа синтеза`}
          >
            <Box
              className={`Hypertorus__chartMark${
                mark.level === power_level ? ' Hypertorus__chartMark--current' : ''
              }`}
              style={{ bottom: `${valueToHeight(mark.temperature)}px` }}
            >
              <Box className="Hypertorus__chartMarkLabel">{`ур. ${mark.level}`}</Box>
            </Box>
          </Tooltip>
        ))}
        {bars.map((bar) => (
          <Box key={bar.id} className="Hypertorus__chartColumn">
            {/* Деления рисует SCSS поверх плоской заливки: цвет контура здесь,
                штриховка - в стилях, чтобы столбец читался как шкала прибора. */}
            <Box
              className="Hypertorus__chartBar"
              style={{
                height: `${valueToHeight(bar.value)}px`,
                backgroundColor: bar.color,
              }}
            />
          </Box>
        ))}
      </Box>
      <Box className="Hypertorus__chartLegend">
        {bars.map((bar) => (
          <Box key={bar.id} className="Hypertorus__chartLegendItem">
            <Box className="Hypertorus__chartLegendLabel" style={{ color: bar.color }}>
              {bar.label}
            </Box>
            {bar.value > 0 ? (
              <>
                <Box className="Hypertorus__chartLegendValue">
                  {formatTemperature(bar.value)}
                </Box>
                {/* Знак в самой подписи уже говорит о направлении, а стрелка
                    съедала ширину колонки и склеивала соседние показания. */}
                <Box
                  className="Hypertorus__chartLegendDelta"
                  color={bar.delta > 0 ? 'orange' : bar.delta < 0 ? 'blue' : 'label'}
                >
                  {formatDelta(bar.delta)}
                </Box>
              </>
            ) : (
              <Box className="Hypertorus__chartLegendValue" color="label">
                пусто
              </Box>
            )}
          </Box>
        ))}
      </Box>
    </Section>
  );
};
