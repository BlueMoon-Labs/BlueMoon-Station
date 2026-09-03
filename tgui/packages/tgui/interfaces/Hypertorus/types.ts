import { BooleanLike } from 'common/react';

/** Одна запись газовой смеси: id газа и количество молей. */
export type HypertorusGas = {
  id: string;
  amount: number;
};

/** Строка списка фильтрации модератора. */
export type HypertorusFilter = {
  gas_id: string;
  gas_name: string;
  enabled: BooleanLike;
};

/**
 * Рецепт синтеза. Множители - это отношение к единице: 1 означает "как у
 * базового рецепта", больше - усиление, меньше - ослабление.
 */
export type HypertorusFuel = {
  id: string | null;
  name: string;
  /** Газы, которые надо подать во вход топлива. */
  requirements?: string[];
  /** Газы, в которые превращается топливо внутри камеры синтеза. */
  fusion_byproducts?: string[];
  /** Газы, которые уходят в модератор по мере роста уровня мощности. */
  product_gases?: string[];
  recipe_cooling_multiplier?: number;
  recipe_heating_multiplier?: number;
  energy_loss_multiplier?: number;
  fuel_consumption_multiplier?: number;
  gas_production_multiplier?: number;
  temperature_multiplier?: number;
};

/** Границы одного регулятора: ui_act() клампит ровно по ним. */
export type HypertorusLimit = {
  min: number;
  max: number;
  step?: number;
};

export type HypertorusLimits = {
  heating_conductor: HypertorusLimit;
  magnetic_constrictor: HypertorusLimit;
  fuel_injection_rate: HypertorusLimit;
  moderator_injection_rate: HypertorusLimit;
  current_damper: HypertorusLimit;
  filtering_rate: HypertorusLimit;
  cooling_volume: HypertorusLimit;
};

/** Числа, за переход через которые реактор наказывает. */
export type HypertorusThresholds = {
  /** Минимум молей каждого требуемого газа, иначе реакция не идёт. */
  fusion_mole_minimum: number;
  /** Ниже этого количества молей реакция затухает, но целостность лечится. */
  subcritical_moles: number;
  /** Выше - периодический урон по целостности. */
  overmole_moles: number;
  /** Выше - непрерывный урон, растущий с числом молей. */
  hypercritical_moles: number;
  /** С этого уровня мощности включается урон за переполнение камеры. */
  overfull_power_level: number;
  overfull_cold_moles: number;
  overfull_hot_moles: number;
  /** Ниже этой температуры кулант лечит целостность. */
  cold_coolant_temperature: number;
  /** На этой нестабильности реактор перестаёт греть и начинает охлаждать. */
  instability_flip: number;
  /** С этого содержания железа начинается урон. */
  iron_damage: number;
  maximum_iron: number;
  /** Выше этого уровня мощности железо копится, на нём и ниже - распадается. */
  iron_growth_power_level: number;
  integrity_warning: number;
  integrity_danger: number;
  integrity_emergency: number;
  integrity_melting: number;
};

export type HypertorusData = {
  // --- статика ---
  base_max_temperature: number;
  limits: HypertorusLimits;
  thresholds: HypertorusThresholds;
  /** Температуры синтеза, с которых начинается уровень 1..6. */
  power_level_temperatures: number[];
  selectable_fuel: HypertorusFuel[];

  // --- пусковая цепочка ---
  start_power: BooleanLike;
  start_cooling: BooleanLike;
  start_fuel: BooleanLike;
  start_moderator: BooleanLike;

  // --- реакция ---
  selected: string | null;
  product_gases: string;
  fusion_gases: HypertorusGas[];
  moderator_gases: HypertorusGas[];
  fusion_moles: number;
  moderator_moles: number;
  coolant_moles: number;

  // --- состояние ---
  power_level: number;
  integrity: number;
  iron_content: number;
  instability: number;
  apc_energy: number;
  energy_level: number;
  internal_power: number;
  power_output: number;
  heat_limiter_modifier: number;
  heat_output: number;
  heat_output_min: number;
  heat_output_max: number;

  // --- температуры ---
  internal_fusion_temperature: number;
  moderator_internal_temperature: number;
  internal_output_temperature: number;
  internal_coolant_temperature: number;
  internal_fusion_temperature_archived: number;
  moderator_internal_temperature_archived: number;
  internal_output_temperature_archived: number;
  internal_coolant_temperature_archived: number;
  /** Секунд между архивным и текущим замером: делитель для K/с. */
  temperature_period: number;

  // --- регуляторы ---
  heating_conductor: number;
  magnetic_constrictor: number;
  fuel_injection_rate: number;
  moderator_injection_rate: number;
  current_damper: number;
  cooling_volume: number;

  // --- фильтрация ---
  waste_remove: BooleanLike;
  mod_filtering_rate: number;
  fusion_filtering_rate: number;
  filter_types: HypertorusFilter[];
};
