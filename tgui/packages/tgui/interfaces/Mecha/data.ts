export type Reagent = { name: string; volume: number; id: string; allowed?: boolean };

export type ModuleExtra =
  | { kind: 'mode'; mode: number; modes: string[]; first_mode: number; target?: string }
  | { kind: 'rcd'; mode: number; modes: { id: number; name: string }[]; airlock_mode: boolean; window_mode: boolean; computer_mode: boolean; airlock_name: string; reinforced_windows: boolean; computer_direction: number; one_access: boolean; access_regions: { name: string; accesses: { id: number; name: string }[] }[]; selected_accesses: number[] }
  | { kind: 'extinguisher'; reagents: number; total_reagents: number }
  | { kind: 'generator'; fuel_amount: number; max_fuel: number }
  | { kind: 'ballistic'; total_ammo: number; max_ammo: number; cache: number; cache_max: number; can_rearm: boolean; rearm_reason: string | null; punching?: boolean; harmful?: boolean }
  | { kind: 'syringe'; mode: string; syringe: number; max_syringe: number; reagents: number; total_reagents: number; contained_reagents: Reagent[]; analyzed_reagents: { name: string; id: string; enabled: boolean }[]; synthesizing: boolean }
  | { kind: 'sleeper'; stasis_enabled: boolean; life_support_active: boolean; injection_reason: string | null; chems: { id: string; name: string; allowed: boolean; overdose_threshold: number | null; addiction_threshold: number | null }[]; patient: { patient_name: string; patient_health: number; max_health: number; min_health: number; patient_state: string; core_temp: number; brute_loss: number; burn_loss: number; toxin_loss: number; oxygen_loss: number } | null; contained_reagents: Reagent[]; injectible_reagents: Reagent[] };

export type MechModule = {
  name: string;
  desc: string;
  image: string;
  ref: string;
  integrity: number;
  detachable: boolean;
  can_be_triggered: boolean;
  can_be_toggled: boolean;
  toggle_action: string;
  active: boolean;
  selected_left: boolean;
  selected_right: boolean;
  equip_cooldown: string;
  energy_per_use: number;
  unavailable_reason: string | null;
  detach_reason: string | null;
  snowflake: ModuleExtra | null;
};

export type MainData = {
  name: string;
  ui_theme: string;
  mech_image: string;
  integrity: number;
  integrity_max: number;
  power_level: number | null;
  power_max: number | null;
  has_lights: boolean;
  lights: boolean;
  has_tank: boolean;
  use_internal_tank: boolean;
  cabin_temp: number;
  cabin_pressure: number;
  cabin_pressure_warning_min: number;
  cabin_pressure_warning_max: number;
  cabin_pressure_hazard_min: number;
  cabin_pressure_hazard_max: number;
  cabin_temp_warning_min: number;
  cabin_temp_warning_max: number;
  tank_temp: number;
  tank_pressure: number;
  port_connected: boolean;
  internal_damage: number;
  internal_damage_keys: Record<string, number>;
  dna_lock: string | null;
  dna_lock_name: string | null;
  id_upload: boolean;
  accesses: string[];
  maint_access: boolean;
  maintenance: boolean;
  can_equipment: boolean;
  can_settings: boolean;
  can_dna_lock: boolean;
  has_port: boolean;
  modules: MechModule[];
  max_equip: number;
  actions: { name: string; ref: string }[];
  cargo: { capacity: number; cargo_list: { name: string; amount: number; ref: string }[] } | null;
  ui_honked: boolean;
  radio_data: { microphone: boolean; speaker: boolean; frequency: number; minFrequency: number; maxFrequency: number } | null;
};
