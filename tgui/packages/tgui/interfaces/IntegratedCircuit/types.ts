/**
 * TGUI payload for IntegratedCircuit / legacy IE assembly UIs.
 * Fields mirror `ui_data` from wiremod and integrated_electronics.
 */

export type IeCloneCopyMode = 'assembly' | 'chip';

export interface CircuitPortPayload {
  name: string;
  type: string;
  pin_type_label?: string | null;
  ref: string;
  color: string;
  current_data: unknown;
  datatype_data: unknown;
  /** BYOND list or dense 1..N object; normalized to array in the client. */
  connected_to: unknown;
}

/** Raw component from BYOND before port lists are normalized. */
export interface CircuitComponentPayload {
  name: string;
  x: number;
  y: number;
  removable: boolean;
  /** Titlebar accent: TGUI color name or `#rrggbb` from server. */
  color?: string;
  /** Integrated Electronics: size / complexity / cooldowns (deciseconds). */
  ie_size?: number | null;
  ie_complexity?: number | null;
  ie_cooldown_ds?: number | null;
  ie_ext_cooldown_ds?: number | null;
  /** Wiremod: cell cost per input fire. */
  power_usage_per_input?: number | null;
  input_ports: CircuitPortPayload[] | Record<string, CircuitPortPayload>;
  output_ports: CircuitPortPayload[] | Record<string, CircuitPortPayload>;
}

export interface CircuitComponentView extends Omit<
  CircuitComponentPayload,
  'input_ports' | 'output_ports'
> {
  input_ports: CircuitPortPayload[];
  output_ports: CircuitPortPayload[];
  /** Нода недавно получила срабатывание входа (сервер). */
  recent_pulse?: boolean;
}

export interface PortLocation {
  x: number;
  y: number;
  color?: string;
}

export interface SelectedPortState {
  index: number;
  component_id: number;
  is_output: boolean;
  ref: string;
}

export interface IntegratedCircuitState {
  locations: Record<string, PortLocation>;
  selectedPort: SelectedPortState | null;
  dragClientX: number | null;
  dragClientY: number | null;
  zoom: number;
  backgroundX: number;
  backgroundY: number;
  menuOpen: boolean;
  /** Клиентский «ЛГБТК+ режим»: радужные переливы всего окна схемы. */
  lgbtqRainbowMode: boolean;
  /** Пока ждём ответ сервера после «к (0,0)», якорь панорамы с сервера подменяем нулями. */
  screenPanOverride: { x: number; y: number } | null;
  /** Сброс локального drag-offset в InfinitePlane (инкремент при «к началу координат»). */
  planeHomeNonce: number;
}

export interface IntegratedCircuitData {
  circuit_on?: boolean;
  display_name?: string;
  examined_name?: string | null;
  examined_desc?: string | null;
  examined_notices?: unknown;
  examined_rel_x?: number;
  examined_rel_y?: number;
  screen_x?: number;
  screen_y?: number;
  is_admin?: boolean;
  variables?: unknown[];
  global_basic_types?: string[];
  ie_circuit?: boolean;
  ie_clone_copy_mode?: IeCloneCopyMode | null;
  ie_debug_copy_ref?: boolean;
  ie_battery_percent?: number | null;
  /** IE: сумма `size` чипов / лимит корпуса (`max_components`); у одиночного чипа только число. */
  ie_used_size?: number | null;
  ie_max_size?: number | null;
  /** IE: сумма сложностей / лимит корпуса. */
  ie_used_complexity?: number | null;
  ie_max_complexity?: number | null;
  /** BYOND list, array, or dense 1..N object of component dicts. */
  components?: unknown;
  /** Краткая подсветка «какая связь сработала» (совпадает с ref портов в connections). */
  circuit_pulse_out_ref?: string | null;
  circuit_pulse_in_ref?: string | null;
  /** Wiremod: заряд power cell на плате, null если нет. */
  circuit_cell_percent?: number | null;
}

export interface WireConnection {
  color: string;
  from: PortLocation | undefined;
  to: PortLocation | undefined;
  /** REF выходного порта (wiremod / IE). */
  outRef?: string;
  /** REF входного порта. */
  inRef?: string;
  /** Временная линия при перетаскивании провода. */
  isPreview?: boolean;
}
