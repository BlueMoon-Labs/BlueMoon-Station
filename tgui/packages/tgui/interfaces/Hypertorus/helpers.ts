import { getGasName } from '../../constants';
import { formatSiBaseTenUnit } from '../../format';
import {
  HypertorusData,
  HypertorusFuel,
  HypertorusLimit,
  HypertorusThresholds,
} from './types';

/**
 * Потолок шкалы газа синтеза приходит из ui_static_data() полем
 * base_max_temperature (hfr_parts.dm = FUSION_MAXIMUM_TEMPERATURE,
 * code/__DEFINES/reactions.dm:54). Это значение здесь только на случай
 * первой отрисовки, пока статика ещё не приехала.
 */
export const FALLBACK_MAX_FUSION_TEMPERATURE = 1e8;

/**
 * heat_limiter_modifier = 5 * 10^power_level * (heating_conductor * 0.01)
 * на константах HFR_HEAT_LIMITER_BASE = 5 и HFR_MAGNETIC_VOLUME_FRAC = 0.01.
 * power_level упирается в 6, heating_conductor - в 500, значит максимум
 * 5 * 1e6 * 5 = 2.5e7.
 */
export const MAX_HEAT_LIMITER_MODIFIER = 2.5e7;

/**
 * energy = energy_modifiers * c^2 * max(T * heat_modifier / 100, 1).
 * c^2 собирается из LIGHT_SPEED_SQ_SCALED и LIGHT_SPEED_SQ_SCALE и равен ~9e16;
 * температурный множитель упирается в FUSION_MAXIMUM_TEMPERATURE 1e8 при
 * heat_modifier на потолке HFR_MODIFIER_CLAMP_MAX 100, то есть в 1e8. При
 * единичных модификаторах это ~9e24, округляем до 1e25. HFR_ENERGY_CLAMP_MAX
 * 1e35 сюда не годится: он сам подписан "float safety", это страховка от
 * переполнения, а не игровой предел.
 */
export const MAX_REACTOR_ENERGY = 1e25;

/**
 * Второй аргумент formatSiBaseTenUnit - это minBase1000, нижняя граница
 * десятичной приставки, а не точность. Единица требовала печатать не мельче
 * тысяч, и всё ниже 500 K схлопывалось в "0 · 10³ K": подпись переставала
 * отличать комнатные 293 K от настоящего нуля, а это состояние простаивающего
 * или штатно охлаждённого реактора. Ноль разрешает форматтеру остаться в
 * единицах; тысячи и миллионы он подберёт сам.
 */
const TEMPERATURE_MIN_BASE_1000 = 0;

/**
 * Выше этого уровня мощности отходы не выпускают: горячий выхлоп в трубу
 * сносит фильтры на выходе (ui_act блокировал это и раньше, молча).
 * Нужен и вкладке фильтров, и быстрому тумблеру у колонки модератора.
 */
export const WASTE_REMOVE_MAX_POWER_LEVEL = 5;

/** Пороги на случай, если ui_static_data() ещё не приехала. */
export const FALLBACK_THRESHOLDS: HypertorusThresholds = {
  fusion_mole_minimum: 25,
  subcritical_moles: 800,
  overmole_moles: 5000,
  hypercritical_moles: 10000,
  overfull_power_level: 5,
  overfull_cold_moles: 2700,
  overfull_hot_moles: 1800,
  cold_coolant_temperature: 1e5,
  instability_flip: 4,
  iron_damage: 2,
  maximum_iron: 5,
  iron_growth_power_level: 4,
  integrity_warning: 100,
  integrity_danger: 50,
  integrity_emergency: 25,
  integrity_melting: 5,
};

const FALLBACK_LIMIT: HypertorusLimit = { min: 0, max: 1 };

/** Пороги температуры синтеза для уровней 1..6 на случай отсутствия статики. */
export const FALLBACK_POWER_LEVEL_TEMPERATURES = [500, 1e3, 1e4, 1e5, 1e6, 1e7];

const isNumber = (value: unknown): value is number =>
  typeof value === 'number' && Number.isFinite(value);

/** Температура в кельвинах с десятичной приставкой: 5000 -> "5 · 10³ K". */
export const formatTemperature = (kelvin: number) =>
  formatSiBaseTenUnit(
    isNumber(kelvin) ? kelvin : 0,
    TEMPERATURE_MIN_BASE_1000,
    'K',
  );

/**
 * Тепловой выход в кельвинах; отрицательный означает, что реактор охлаждает
 * сам себя. formatSiBaseTenUnit не умеет ни ноль, ни отрицательные числа.
 */
export const formatHeatOutput = (kelvin: number) => {
  if (!isNumber(kelvin) || kelvin === 0) {
    return '0 K';
  }
  const sign = kelvin > 0 ? '+' : '-';
  return sign + formatTemperature(Math.abs(kelvin));
};

/**
 * Скорость изменения температуры. Приставку берём ту же, что и у самих
 * температур: "+1.20 · 10³ K/с" читается рядом со шкалой, а "+1.2e+3" - нет.
 */
export const formatDelta = (kelvinPerSecond: number) => {
  if (!isNumber(kelvinPerSecond) || Math.abs(kelvinPerSecond) < 0.01) {
    return '0 K/с';
  }
  const sign = kelvinPerSecond > 0 ? '+' : '-';
  return (
    sign +
    formatSiBaseTenUnit(
      Math.abs(kelvinPerSecond),
      TEMPERATURE_MIN_BASE_1000,
      'K/с',
    )
  );
};

/**
 * Скорость изменения температуры за секунду. temperature_period - это
 * seconds_per_tick последнего прохода, делить на ноль нельзя.
 */
export const temperatureDelta = (
  current: number,
  archived: number,
  period: number,
) => {
  if (!isNumber(current) || !isNumber(archived) || !isNumber(period) || period <= 0) {
    return 0;
  }
  return (current - archived) / period;
};

export const getLimit = (
  limits: HypertorusData['limits'],
  key: keyof HypertorusData['limits'],
): HypertorusLimit => limits?.[key] ?? FALLBACK_LIMIT;

export const getThresholds = (data: HypertorusData): HypertorusThresholds => ({
  ...FALLBACK_THRESHOLDS,
  ...(data.thresholds ?? {}),
});

export const getPowerLevelTemperatures = (data: HypertorusData): number[] => {
  const temperatures = data.power_level_temperatures;
  return temperatures?.length ? temperatures : FALLBACK_POWER_LEVEL_TEMPERATURES;
};

export const getMaxFusionTemperature = (data: HypertorusData) =>
  isNumber(data.base_max_temperature) && data.base_max_temperature > 0
    ? data.base_max_temperature
    : FALLBACK_MAX_FUSION_TEMPERATURE;

export const getSelectedFuel = (
  data: HypertorusData,
): HypertorusFuel | undefined =>
  (data.selectable_fuel ?? []).find(
    (fuel) => fuel.id === data.selected && fuel.id !== null,
  );

/**
 * Состояние реактора одной строкой. Пороги целостности - те же, по которым
 * check_alert() решает, что орать в рацию.
 */
export type ReactorStatus = {
  id: 'melting' | 'emergency' | 'danger' | 'active' | 'idle';
  label: string;
  color: string;
};

/**
 * Порог integrity_warning здесь намеренно не используется: DM поднимает по нему
 * тревогу при любой потере целостности, вплоть до 99.9%, и в заголовке окна это
 * читалось бы как "реактор сломан" на штатно работающей машине. Степень износа
 * видно по шкале целостности рядом, а шильдик меняется только там, где реактору
 * действительно нужно вмешательство.
 */
export const getReactorStatus = (data: HypertorusData): ReactorStatus => {
  const thresholds = getThresholds(data);
  const integrity = isNumber(data.integrity) ? data.integrity : 100;
  if (integrity < thresholds.integrity_melting) {
    return { id: 'melting', label: 'РАСПЛАВЛЕНИЕ', color: 'bad' };
  }
  if (integrity < thresholds.integrity_emergency) {
    return { id: 'emergency', label: 'АВАРИЯ', color: 'bad' };
  }
  if (integrity < thresholds.integrity_danger) {
    return { id: 'danger', label: 'ОПАСНОСТЬ', color: 'bad' };
  }
  if (data.power_level > 0) {
    return { id: 'active', label: `УРОВЕНЬ ${data.power_level}`, color: 'good' };
  }
  return { id: 'idle', label: 'ОСТАНОВЛЕН', color: 'label' };
};

/**
 * Позиция температуры синтеза между порогом текущего уровня мощности и
 * следующего, в долях. На шестом уровне расти уже некуда.
 */
export const getPowerLevelProgress = (data: HypertorusData) => {
  const temperatures = getPowerLevelTemperatures(data);
  const level = data.power_level ?? 0;
  const current = isNumber(data.internal_fusion_temperature)
    ? data.internal_fusion_temperature
    : 0;
  if (level >= temperatures.length) {
    return { progress: 1, next: 0 };
  }
  const floor = level === 0 ? 0 : temperatures[level - 1];
  const next = temperatures[level];
  if (next <= floor) {
    return { progress: 0, next };
  }
  const progress = (current - floor) / (next - floor);
  return { progress: Math.max(0, Math.min(1, progress)), next };
};

/**
 * Сколько молей топлива безопасно при текущей температуре. DM интерполирует
 * между "холодным" и "горячим" пределом линейно по температуре синтеза
 * (HYPERTORUS_OVERFULL_* в _hfr_defines.dm) и бьёт целостность за превышение,
 * начиная с overfull_power_level.
 */
export const getOverfullMoleLimit = (data: HypertorusData) => {
  const thresholds = getThresholds(data);
  const maxTemperature = getMaxFusionTemperature(data);
  const temperature = Math.max(
    0,
    Math.min(
      maxTemperature,
      isNumber(data.internal_fusion_temperature)
        ? data.internal_fusion_temperature
        : 0,
    ),
  );
  const span = thresholds.overfull_cold_moles - thresholds.overfull_hot_moles;
  return thresholds.overfull_cold_moles - span * (temperature / maxTemperature);
};

/** Склонение слова "газ" по числу: 1 газ, 2 газа, 5 газов. */
export const gasCountWord = (count: number) => {
  const tail = Math.abs(count) % 10;
  const teens = Math.abs(count) % 100;
  if (teens >= 11 && teens <= 14) {
    return 'газов';
  }
  if (tail === 1) {
    return 'газ';
  }
  if (tail >= 2 && tail <= 4) {
    return 'газа';
  }
  return 'газов';
};

export type StartupStep = {
  id: 'start_power' | 'start_cooling' | 'start_fuel' | 'start_moderator';
  label: string;
  icon: string;
  active: boolean;
  disabled: boolean;
  /** Что делает шаг, либо почему его сейчас нельзя переключить. */
  hint: string;
};

/**
 * Пусковая цепочка в порядке зависимостей. Условия блокировки повторяют те,
 * что окно всегда применяло молча: раньше кнопка просто гасла, и понять
 * причину можно было только по исходникам.
 */
export const getStartupSteps = (data: HypertorusData): StartupStep[] => {
  const { start_power, start_cooling, start_fuel, start_moderator } = data;
  const running = data.power_level > 0;
  return [
    {
      id: 'start_power',
      label: 'Питание',
      icon: 'bolt',
      active: !!start_power,
      disabled: running,
      hint: running
        ? 'Реактор уже разогнан: обесточить его можно только после остывания газа синтеза.'
        : 'Подаёт питание на магниты. Первый шаг любого запуска.',
    },
    {
      id: 'start_cooling',
      label: 'Охлаждение',
      icon: 'snowflake-o',
      active: !!start_cooling,
      disabled:
        !start_power ||
        !!start_fuel ||
        !!start_moderator ||
        (!!start_cooling && running),
      hint: !start_power
        ? 'Сначала подайте питание.'
        : start_fuel || start_moderator
          ? 'Сначала перекройте впрыск топлива и модератора.'
          : start_cooling && running
            ? 'Реактор разогнан: снимать охлаждение на ходу нельзя.'
            : 'Прокачивает хладагент через контур. Без него камера не отдаёт тепло.',
    },
    {
      id: 'start_fuel',
      label: 'Топливо',
      icon: 'fire',
      active: !!start_fuel,
      disabled: !start_power || !start_cooling,
      hint:
        !start_power || !start_cooling
          ? 'Нужны питание и охлаждение.'
          : 'Впрыскивает газы рецепта в камеру синтеза. Отсюда начинается разгон.',
    },
    {
      id: 'start_moderator',
      label: 'Модератор',
      icon: 'flask',
      active: !!start_moderator,
      disabled: !start_power || !start_cooling,
      hint:
        !start_power || !start_cooling
          ? 'Нужны питание и охлаждение.'
          : 'Впрыскивает газы модератора: они меняют выход энергии, тепло и побочные продукты.',
    },
  ];
};

export type HypertorusAlert = {
  id: string;
  level: 'danger' | 'warning' | 'info';
  text: string;
};

/**
 * Разбор состояния реактора в список претензий. Держим отдельно от разметки:
 * это единственная логика окна, которую имеет смысл проверять тестами.
 */
export const collectAlerts = (data: HypertorusData): HypertorusAlert[] => {
  const thresholds = getThresholds(data);
  const alerts: HypertorusAlert[] = [];
  const fusionMoles = isNumber(data.fusion_moles) ? data.fusion_moles : 0;
  const integrity = isNumber(data.integrity) ? data.integrity : 100;
  const iron = isNumber(data.iron_content) ? data.iron_content : 0;
  const powerLevel = data.power_level ?? 0;

  if (integrity < thresholds.integrity_emergency) {
    alerts.push({
      id: 'integrity',
      level: 'danger',
      text: `Целостность ${integrity.toFixed(1)}%: реактор на грани расплавления. Сбросьте мощность и охладите камеру.`,
    });
  } else if (integrity < thresholds.integrity_danger) {
    alerts.push({
      id: 'integrity',
      level: 'warning',
      text: `Целостность ${integrity.toFixed(1)}%: корпус серьёзно повреждён.`,
    });
  } else if (
    integrity < thresholds.integrity_warning &&
    powerLevel > thresholds.iron_growth_power_level
  ) {
    // На уровне iron_growth_power_level и ниже корпус чинится сам, и напоминать
    // об этом не о чем: подсказка нужна ровно тогда, когда мощность мешает.
    alerts.push({
      id: 'integrity',
      level: 'info',
      text: `Целостность ${integrity.toFixed(1)}%: на уровне мощности выше ${thresholds.iron_growth_power_level} корпус не восстанавливается.`,
    });
  }

  if (fusionMoles >= thresholds.hypercritical_moles) {
    alerts.push({
      id: 'hypercritical',
      level: 'danger',
      text: `Гиперкритическая масса: ${Math.round(fusionMoles)} молей при пределе ${thresholds.hypercritical_moles}. Урон растёт с каждым молем.`,
    });
  } else if (fusionMoles > thresholds.overmole_moles) {
    alerts.push({
      id: 'overmole',
      level: 'warning',
      text: `Перегруз камеры: ${Math.round(fusionMoles)} молей выше ${thresholds.overmole_moles}. Целостность падает каждые 5 секунд.`,
    });
  } else if (powerLevel >= thresholds.overfull_power_level) {
    const limit = getOverfullMoleLimit(data);
    if (fusionMoles > limit) {
      alerts.push({
        id: 'overfull',
        level: 'warning',
        text: `Переполнение на высокой мощности: ${Math.round(fusionMoles)} молей при безопасных ${Math.round(limit)} для этой температуры.`,
      });
    }
  }

  if (iron >= thresholds.iron_damage) {
    alerts.push({
      id: 'iron-damage',
      level: 'danger',
      text: `Железо ${iron.toFixed(2)}: стенки камеры разъедает. Опустите мощность до ${thresholds.iron_growth_power_level} и ниже, чтобы железо распалось.`,
    });
  } else if (iron > 0 && powerLevel > thresholds.iron_growth_power_level) {
    alerts.push({
      id: 'iron-growth',
      level: 'warning',
      text: `Железо копится (${iron.toFixed(2)} из ${thresholds.maximum_iron}): на уровне выше ${thresholds.iron_growth_power_level} оно только растёт.`,
    });
  }

  const fuel = getSelectedFuel(data);
  if (!fuel) {
    alerts.push({
      id: 'no-recipe',
      level: 'info',
      text: 'Рецепт синтеза не выбран: реакция не пойдёт.',
    });
  } else if (data.start_fuel) {
    const gases = data.fusion_gases ?? [];
    const missing = (fuel.requirements ?? []).filter((gasId) => {
      const gas = gases.find((entry) => entry.id === gasId);
      return !gas || gas.amount < thresholds.fusion_mole_minimum;
    });
    if (missing.length) {
      alerts.push({
        id: 'missing-fuel',
        level: 'warning',
        text: `Не хватает топлива: ${missing
          .map((gasId) => getGasName(gasId))
          .join(', ')} ниже ${thresholds.fusion_mole_minimum} молей.`,
      });
    }
  }

  if (data.start_cooling && !data.coolant_moles) {
    alerts.push({
      id: 'no-coolant',
      level: 'warning',
      text: 'Контур охлаждения пуст: подайте газ на вход хладагента.',
    });
  } else if (
    powerLevel > 0 &&
    powerLevel <= thresholds.iron_growth_power_level &&
    data.internal_coolant_temperature >= thresholds.cold_coolant_temperature
  ) {
    alerts.push({
      id: 'hot-coolant',
      level: 'info',
      text: `Хладагент горячее ${formatTemperature(
        thresholds.cold_coolant_temperature,
      )}: корпус не восстанавливается.`,
    });
  }

  if (
    powerLevel > 0 &&
    fusionMoles > 0 &&
    fusionMoles < thresholds.subcritical_moles
  ) {
    alerts.push({
      id: 'subcritical',
      level: 'info',
      text: `Докритическая масса: ${Math.round(fusionMoles)} молей ниже ${thresholds.subcritical_moles}. Реакция затухает, зато корпус лечится.`,
    });
  }

  if (isNumber(data.apc_energy) && data.apc_energy < 15 && data.start_power) {
    alerts.push({
      id: 'apc',
      level: 'warning',
      text: `Заряд ОРУ ${Math.round(data.apc_energy)}%: без питания регуляторы сбросятся в аварийные значения.`,
    });
  }

  return alerts;
};
