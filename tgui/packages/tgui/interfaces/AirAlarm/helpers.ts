import { toFixed } from 'common/math';

import { getGasColor, getGasLabel } from '../../constants';
import { DangerLevel, EnvironmentEntry, ThresholdVar } from './types';

/** Порог, выключенный значением -1, показывается прочерком, а не как "-1.00". */
export const THRESHOLD_DISABLED = -1;

export const DANGER_COLOR: Record<DangerLevel, string> = {
  0: 'good',
  1: 'average',
  2: 'bad',
};

export const DANGER_TEXT: Record<DangerLevel, string> = {
  0: 'Норма',
  1: 'Осторожно',
  2: 'Опасно - нужны внутренние баллоны',
};

export const THRESHOLD_LABEL: Record<ThresholdVar, string> = {
  min2: 'Опасный мин.',
  min1: 'Мин.',
  max1: 'Макс.',
  max2: 'Опасный макс.',
};

export const THRESHOLD_HINT: Record<ThresholdVar, string> = {
  min2: 'Опасно низко',
  min1: 'Предупреждение о низком значении',
  max1: 'Предупреждение о высоком значении',
  max2: 'Опасно высоко',
};

const ENV_LABEL: Record<string, string> = {
  pressure: 'Давление',
  temperature: 'Температура',
};

const ENV_UNIT: Record<string, string> = {
  kPa: 'кПа',
  K: 'К',
  '%': '%',
};

/** Русская единица для строки среды; неизвестные пропускаем как есть. */
export const localizeUnit = (unit: string): string => ENV_UNIT[unit] ?? unit;

/**
 * Давление и температура переводятся, газы отдаются в getGasLabel: она уже
 * умеет узнавать газ и по id, и по английскому имени из GLOB.gas_data.
 */
export const localizeEnvName = (id: string, fallback: string): string =>
  ENV_LABEL[id] ?? getGasLabel(id, fallback);

export const envColor = (id: string): string | undefined =>
  ENV_LABEL[id] ? undefined : getGasColor(id);

export const formatThreshold = (value: number, unit: string): string => {
  if (value === null || value === undefined || value === THRESHOLD_DISABLED) {
    return '—';
  }
  return `${toFixed(value, 2)} ${localizeUnit(unit)}`;
};

/**
 * Подпись под строкой среды: какой именно порог нарушен. Без неё игрок видит
 * красную полосу и гадает, слишком много газа или слишком мало.
 */
export const describeBreach = (entry: EnvironmentEntry): string | null => {
  if (!entry.danger_level || !entry.tlv) {
    return null;
  }
  const checked = entry.partial_pressure ?? entry.value;
  const unit = entry.partial_pressure !== undefined ? 'кПа' : localizeUnit(entry.unit);
  const { min2, min1, max1, max2 } = entry.tlv;
  const shown = `${toFixed(checked, 2)} ${unit}`;
  if (max2 !== THRESHOLD_DISABLED && checked >= max2) {
    return `${shown} - выше опасного порога ${toFixed(max2, 2)} ${unit}`;
  }
  if (min2 !== THRESHOLD_DISABLED && checked <= min2) {
    return `${shown} - ниже опасного порога ${toFixed(min2, 2)} ${unit}`;
  }
  if (max1 !== THRESHOLD_DISABLED && checked >= max1) {
    return `${shown} - выше порога ${toFixed(max1, 2)} ${unit}`;
  }
  if (min1 !== THRESHOLD_DISABLED && checked <= min1) {
    return `${shown} - ниже порога ${toFixed(min1, 2)} ${unit}`;
  }
  return null;
};

/**
 * Диапазон для полосы среды. Опираемся на опасные пороги, чтобы полоса имела
 * осмысленный масштаб; когда порогов нет - на само значение.
 */
export const barRange = (entry: EnvironmentEntry): [number, number] => {
  const checked = entry.partial_pressure ?? entry.value;
  if (entry.unit === '%') {
    return [0, 100];
  }
  const upper = entry.tlv?.max2;
  if (upper !== undefined && upper !== THRESHOLD_DISABLED && upper > 0) {
    return [0, Math.max(upper * 1.25, checked)];
  }
  return [0, Math.max(checked * 1.25, 1)];
};
