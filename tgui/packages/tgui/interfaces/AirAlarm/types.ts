import { BooleanLike } from 'common/react';

/** 0 - норма, 1 - предупреждение, 2 - опасно. */
export type DangerLevel = 0 | 1 | 2;

/** Границы TLV. -1 означает "порог отключён". */
export type TlvBounds = {
  min2: number;
  min1: number;
  max1: number;
  max2: number;
};

export type ThresholdVar = keyof TlvBounds;

export type EnvironmentEntry = {
  /** Ключ среды: pressure, temperature или id газа. */
  id: string;
  name: string;
  value: number;
  unit: string;
  /**
   * Только у газов: порог проверяется по парциальному давлению, а показывается
   * процент от смеси.
   */
  partial_pressure?: number;
  danger_level: DangerLevel;
  tlv: TlvBounds;
};

export type ThresholdSetting = {
  env: string;
  val: ThresholdVar;
  selected: number;
  default: number;
};

export type Threshold = {
  env: string;
  name: string;
  unit: string;
  is_default: BooleanLike;
  settings: ThresholdSetting[];
};

export type VentInfo = {
  id_tag: string;
  long_name: string;
  power: BooleanLike;
  checks: number;
  excheck: BooleanLike;
  incheck: BooleanLike;
  direction: BooleanLike;
  external: number;
  internal: number;
  extdefault: BooleanLike;
  intdefault: BooleanLike;
};

export type FilterInfo = {
  gas_id: string;
  gas_name: string;
  enabled: BooleanLike;
};

export type ScrubberInfo = {
  id_tag: string;
  long_name: string;
  power: BooleanLike;
  scrubbing: BooleanLike;
  widenet: BooleanLike;
  filter_types: FilterInfo[];
};

export type AirAlarmMode = {
  name: string;
  description: string;
  mode: number;
  selected: BooleanLike;
  danger: BooleanLike;
};

export type AirAlarmData = {
  locked: BooleanLike;
  siliconUser: BooleanLike;
  emagged: BooleanLike;
  danger_level: DangerLevel;
  atmos_alarm: BooleanLike;
  fire_alarm: BooleanLike;
  environment_data: EnvironmentEntry[];
  vents?: VentInfo[];
  scrubbers?: ScrubberInfo[];
  mode?: number;
  modes?: AirAlarmMode[];
  /** Идентификаторы режимов приходят из DM, чтобы не хардкодить числа в tgui. */
  panic_mode?: number;
  filtering_mode?: number;
  thresholds?: Threshold[];
};

/** Что редактирует открытая модалка порога. */
export type ThresholdEdit = {
  env: string;
  name: string;
  unit: string;
  val: ThresholdVar;
  value: number;
};
