export type NetNode = {
  address: string;
  name: string;
  type: string;
  x: number;
  y: number;
  z?: number;
  /** Movable endpoints use the retained Pixi actor layer above stationary scenery. */
  dynamic?: boolean;
  security: number;
  online: boolean;
  access: number;
  can_hop?: boolean;
  /** Player/ghost-role residents; autonomous bots are counted separately. */
  entities: number;
  bots?: number;
  /** Bounded, authorized occupant aggregates for role/faction map markers. */
  processes?: MapProcess[];
  /** A network police process is present on the node. */
  police?: boolean;
  ice?: number;
  active: boolean;
  uplink: string | null;
  apc?: string | null;
  network?: string;
  sector?: string;
  fortress?: FortressSummary | null;
};

export type MapProcess = {
  kind: 'entity' | 'bot' | 'ice';
  bot_kind?: string;
  ice_kind?: IceKind;
  faction?: string;
  faction_color?: string;
  count: number;
};

/** Faction registry ids also include personal owner:<id> factions. */
export type NetFaction = string;

/** Map overlay summary of a node fortress (live layer, never static scenery). */
export type FortressSummary = {
  /** 1-3 by the number of intact modules. */
  tier: number;
  /** Intact walls (siege layer). */
  walls: number;
  faction: NetFaction;
  faction_color?: string | null;
  damaged: boolean;
  online: boolean;
};

export type FortressModule = {
  ref: string;
  kind: 'wall' | 'gate' | 'turret' | 'trap' | 'alarm' | 'vault' | 'regen';
  name: string;
  desc: string;
  integrity: number;
  max_integrity: number;
  status: 'online' | 'building' | 'destroyed' | 'offline';
  /** Remaining construction or re-arm time, seconds. */
  remaining?: number | null;
  id?: string;
  jammed?: boolean;
  repair_command?: string;
  dismantle_command?: string;
};

export type FortressDetails = {
  name: string;
  owner: string | null;
  faction: NetFaction;
  preset: string | null;
  security_bonus: number;
  slots_used: number;
  slots_max: number;
  modules: FortressModule[];
  /** The viewer may build, repair or dismantle (ROOT and forge.exe). */
  can_manage: boolean;
  manage_reason?: string | null;
  storage?: { used: number; capacity: number; vault_bonus: number; required_access: number };
};

export type NetCommand = {
  id: string;
  name: string;
  desc: string;
  help?: string;
  details?: string;
  latency_ms?: number;
  works_offline?: boolean;
  unavailable_reason?: string | null;
  icon: string;
  danger: boolean;
  access: number;
  allowed: boolean;
  illegal: boolean;
  trace: number;
  /** Rendered by a dedicated section (e.g. 'fortress') instead of the generic command list. */
  group?: string | null;
};

export type NetFile = {
  uid: string;
  name: string;
  kind: string;
  size: number;
  copy_size?: number;
  preview: string | null;
  selected?: boolean;
  agent_profile?: string | null;
  packed_files?: number;
  session_bound?: boolean;
  transferable?: boolean;
  copyable?: boolean;
  transfer_reason?: string | null;
  deletable?: boolean;
  delete_reason?: string | null;
};

export type Storage = {
  files: NetFile[];
  used: number;
  capacity: number;
};

export type AgentBuilder = {
  template_uid: string;
  profile: string;
  name: string;
  description: string;
  capacity: number;
  base_size: number;
  defaults: { id: string; name: string; size: number }[];
  programs: { uid: string; name: string; program_id: string; size: number }[];
  modules?: { uid: string; id: string; name: string; desc: string; size: number; requirements: string[]; allowed: boolean; reason?: string | null }[];
  orders: { id: string; name: string }[];
  avatars: { id: string; name: string }[];
  accents: { id: string; name: string; color: string }[];
  themes: string[];
  max_programs?: number;
  max_modules?: number;
};

export type NodeInteraction = {
  id: string;
  name: string;
  icon: string;
  enabled: boolean;
  reason?: string | null;
};

export type IceKind = 'sentry' | 'hunter' | 'black';

export type EntityContact = {
  ref: string;
  name: string;
  kind: 'entity' | 'ice' | 'bot';
  /** Bot archetype id (raider, custodian, police, sentinel, mender). */
  bot_kind?: string | null;
  faction?: NetFaction | null;
  /** Current goal of a bot, in plain words. */
  goal?: string | null;
  integrity: number;
  max_integrity: number;
  state: string;
  self: boolean;
  can_signal: boolean;
  can_message: boolean;
  can_offer?: boolean;
  offer_reason?: string | null;
  faction_name?: string | null;
  faction_color?: string | null;
  threat?: string | null;
  ice_kind?: IceKind;
  persona?: Persona;
};

export type SelectedNode = NetNode & {
  /** Cheap movement admission; the server validates every transit hop on dispatch. */
  movement?: { action: 'hop' | 'travel'; allowed: boolean; reason: string | null };
  network: string;
  legit: number;
  commands: NetCommand[];
  status: string[];
  interactions?: NodeInteraction[];
  contacts?: EntityContact[];
  logs?: string[];
  packets?: NetPacketHeader[];
  manual_uid?: string;
  files?: NetFile[];
  storage?: { used: number; capacity: number };
  fortress?: FortressDetails | null;
  lan?: {
    id: string;
    code: string;
    name: string;
    color: string;
    security: number;
    access: number;
    has_key: boolean;
    can_breach: boolean;
  };
};

export type NetworkEntry = {
  id: string;
  name: string;
  short: string;
  code: string;
  color: string;
  security: number;
  isolated: boolean;
  home: boolean;
  reachable: boolean;
  access: number;
  has_key: boolean;
  can_breach: boolean;
  nodes: number;
};

export type NetworkView = {
  id: string;
  name: string;
  code: string;
  color: string;
  access: number;
  nodes: NetNode[];
  log: string[];
};

export type Daemon = {
  name: string;
  reward: number;
  sequence: string[];
  done: boolean;
};

export type MatrixState = {
  minigame?: 'matrix' | 'sequence' | 'automatic';
  target: string;
  security: number;
  size: number;
  cells: {
    code: string | null;
    active: boolean;
    order?: number;
    done?: boolean;
  }[];
  buffer?: string[];
  buffer_size?: number;
  daemons: Daemon[];
  time_left: number;
  pick_row?: boolean;
  progress?: number;
  total?: number;
};

export type LogLine = { time?: string; text: string; kind: string };

export type HostAction = { id: string; name: string; icon: string };

export type EntityState = {
  name: string;
  integrity: number;
  max_integrity: number;
  host: string | null;
  host_name: string | null;
  diving: boolean;
  travel?: { target: string; remaining: number } | null;
  persona?: Persona;
};

export type Persona = {
  avatar: string;
  accent: string;
  tagline: string;
  name?: string;
  theme?: string;
  options?: {
    avatars: { id: string; name: string; icon: string }[];
    accents: { id: string; name: string; color: string }[];
    themes: string[];
  };
};

export type CombatTarget = {
  ref: string;
  name: string;
  kind: 'entity' | 'ice' | 'bot' | 'fortress';
  bot_kind?: string | null;
  ice_kind?: IceKind;
  faction?: NetFaction | null;
  faction_name?: string | null;
  faction_color?: string | null;
  /** Fortress module kind for structure targets. */
  module?: string | null;
  persona?: Persona;
  hostile: boolean;
  integrity: number;
  max_integrity: number;
  stunned: boolean;
  programs?: EnemyProgram[];
  shielded?: boolean;
  casting?: IncomingProgram | null;
  node?: string | null;
  node_name?: string | null;
  unavailable_reason?: string | null;
};

export type IncomingProgram = {
  name: string; role: string; power: number; remaining: number;
  source?: string; source_ref?: string; source_node?: string | null; stun_turns?: number;
};
export type EnemyProgram = {
  name: string; desc: string; role: string; power: number; cooldown: number; windup: number; ready_in: number;
  ap_cost?: number; ready_turns?: number; cooldown_turns?: number;
};

export type CombatProgram = {
  id: string;
  uid: string;
  name: string;
  desc: string;
  size: number;
  role: string;
  power: number;
  cooldown: number;
  consumable: boolean;
  needs_target: boolean;
  icon: string;
  ready_in: number;
  unavailable_reason?: string | null;
  ap_cost?: number;
  ready_turns?: number;
  cooldown_turns?: number;
  shield_turns?: number;
  stun_turns?: number;
};

export type CombatTurn = {
  /** An exact decision identity; delayed input cannot act on another turn. */
  id?: string;
  /** Stable encounter identity for joining across other actors' turn changes. */
  join_id?: string;
  round: number;
  actor_ref: string;
  actor_name: string;
  your_turn: boolean;
  ap: number;
  max_ap: number;
  remaining: number;
  decision_seconds?: number;
  can_pass: boolean;
  participating?: boolean;
  can_join?: boolean;
  participants?: { ref: string; name: string; current: boolean; ap: number; max_ap: number }[];
};

export type CombatState = {
  node: string | null;
  node_name: string | null;
  self: { integrity: number; max_integrity: number; stunned: boolean; shielded?: boolean } | null;
  targets: CombatTarget[];
  programs: CombatProgram[];
  /** Shared launch recovery, in seconds rounded up by the server. */
  action_ready_in?: number;
  turn?: CombatTurn | null;
  incoming?: IncomingProgram[];
  loot?: NetFile[];
  pursuit_available?: boolean;
  pursuit?: { target_ref: string; name: string; node: string | null; following: boolean; status: string } | null;
};

export type SearchResult = {
  address: string;
  name: string;
  type: string;
  network: string | null;
  online: boolean;
  visible: boolean;
};

export type WorkspaceView = 'terminal' | 'map' | 'files' | 'agents' | 'pinned' | 'combat' | 'breach' | 'web';

export type NetOperation = {
  id: string;
  operation_id: string;
  nonce?: string | null;
  kind: string;
  label: string;
  from: string | null;
  to: string | null;
  service?: string | null;
  phase: 'queued' | 'running' | 'completed' | 'rejected' | 'cancelled';
  reason?: string | null;
  result?: string | null;
  started_at: number;
  updated_at: number;
  route: string[];
};

export type NetPacketHeader = {
  id: string;
  time: number;
  phase: string;
  kind: string;
  from: string | null;
  to: string | null;
  service: string | null;
  reason?: string | null;
  headers?: Record<string, string | number | boolean> | null;
};

export type SecurityEvidence = {
  id: string;
  kind: string;
  age: number;
  /** Remaining seconds of the attributed contact; unknown evidence can have ttl=0. */
  ttl: number;
  attributed: boolean;
  name?: string | null;
  source_address?: string | null;
  source_name?: string | null;
  active: boolean;
  status: string;
  map_allowed: boolean;
  map_reason?: string | null;
  pursue_allowed: boolean;
  pursue_reason?: string | null;
  trace_allowed: boolean;
  trace_reason?: string | null;
};

export type SecurityState = {
  defended: { address: string; name: string; can_countertrace: boolean; reason?: string | null } | null;
  entries: SecurityEvidence[];
};

export type IncomingFileOffer = {
  id: string;
  sender: string;
  name: string;
  kind: string;
  size: number;
  ttl: number;
  can_accept: boolean;
  reason?: string | null;
};

export type NetrunNotice = {
  id: number;
  text: string;
  kind: 'good' | 'bad' | 'average' | 'label';
  topic?: 'combat' | null;
};

export type NetrunData = {
  notices?: NetrunNotice[];
  operations?: NetOperation[];
  security?: SecurityState | null;
  file_exchange?: { incoming: IncomingFileOffer[]; max_offers: number } | null;
  access_export?: { node_count: number; network_count: number; can_export: boolean; reason?: string | null;
    key_uid?: string | null; key_name?: string | null } | null;
  /** Receipt of a UI request; it does not imply the game action succeeded. */
  input_ack?: string | null;
  workspace_view?: WorkspaceView;
  ui_theme?: string;
  origin: string;
  wireless: boolean;
  uplink: boolean;
  trace: number;
  locked: number;
  can_breach: boolean;
  can_autobreach?: boolean;
  log: LogLine[];
  jack: { address: string; name: string } | null;
  host_actions: HostAction[];
  networks: NetworkEntry[];
  view: NetworkView | null;
  selected: SelectedNode | null;
  storage: Storage;
  shard: (Storage & { name: string }) | null;
  breach: MatrixState | null;
  entity: EntityState | null;
  combat: CombatState | null;
  chat: { handle: string; messages: string[] };
  web: WebState | null;
  cli?: {
    verbs: {
      id: string;
      args: string;
      desc: string;
      category?: string;
      completions?: string[];
      completion_key?: string;
    }[];
    completions?: Record<string, string[]>;
  };
  windows: WindowTab[];
  window: MachineWindow | null;
  map: NetMapPacket | null;
  selected_network: SelectedNetwork | null;
  ping_route: PingHop[] | null;
  ping?: { id: number; remaining_ms: number } | null;
  agents?: AgentState[] | null;
  agent_count?: number;
  events?: NetEvent[] | null;
  waypoint?: Waypoint | null;
  search?: SearchResult[] | null;
  file?: (NetFile & {
    content: string | null;
    image: string | null;
    width?: number;
    height?: number;
    source: 'local' | 'shard' | 'session';
    can_import?: boolean;
    transfer?: Record<'local' | 'shard', { copy: boolean; move: boolean; reason: string | null; merge: boolean }>;
    agent_builder?: AgentBuilder | null;
  }) | null;
};

export type PingHop = { kind: 'node' | 'gateway' | 'hub'; ref?: string };

export type Waypoint = {
  address: string;
  name: string;
  type?: string;
  reachable: boolean;
  hops: number;
  route: string[];
  next: string | null;
  lost?: boolean;
};

export type NetEvent = {
  kind: 'command' | 'intrusion' | 'breach' | 'trace' | 'purge' | 'machine' | 'dns' | 'packet';
  from: string | null;
  to: string | null;
  /** Seconds since the server posted the event. */
  age: number;
  /** Stable server event identity, independent of repeated UI pushes. */
  event_id?: string | number;
  /** Remaining real transit / visibility lifetime at serialization, in milliseconds. */
  remaining_ms?: number;
  lifetime_ms?: number;
  /** Hop addresses; undisclosed hops are "". */
  route?: string[] | null;
  /** Packet flight id (kind === 'packet'). */
  id?: string;
  /** Packet class: command, remote, window, file, entity.signal, entity.message, machine… */
  packet?: string;
  /** send: dispatched with its real transit time; done/fail: outcome at the destination. */
  phase?: 'send' | 'done' | 'fail';
  /** Transit time in seconds (send phase). */
  duration?: number;
  /** The viewer's own packet. */
  own?: boolean;
  /** Operation label, only for the viewer's own packets. */
  label?: string | null;
};

/** An autonomous agent launched by this console's owner. */
export type AgentBehavior = {
  strategy: 'profile' | 'patrol' | 'scavenge' | 'guard';
  aggression: number;
  caution: number;
  cooperation: boolean;
};

export type AgentState = {
  ref: string;
  name: string;
  bot_kind: string;
  node: string | null;
  node_name: string | null;
  integrity: number;
  max_integrity: number;
  state: string;
  goal: string | null;
  storage: { used: number; capacity: number };
  persona?: Persona;
  programs?: CombatProgram[];
  files?: NetFile[];
  goals?: { id: string; name: string; desc: string; selected?: boolean }[];
  behavior?: AgentBehavior;
  orders: { id: string; name: string; needs_node?: boolean; enabled?: boolean; reason?: string }[];
};

export type Gateway = {
  id: string;
  code: string;
  name: string;
  color: string;
  security: number;
  access: number;
  has_key: boolean;
  can_breach: boolean;
};

export type NetEdge = {
  id: string;
  from: string;
  to: string;
  kind: 'endpoint' | 'apc' | 'relay';
  online?: boolean;
};

export type NetMap = {
  /** A full baseline for one authorized UI stream; omitted by legacy payloads. */
  epoch?: string;
  full?: true | 1;
  gateways: Gateway[];
  nodes: NetNode[];
  edges: NetEdge[];
  focus: string | null;
  revision: number;
  /** Per-console projected graph generations; legacy snapshots use semantic comparison. */
  structure_revision?: number;
  state_revision?: number;
  /** Stationary geometry/status only; actor movement and activity do not advance it. */
  static_revision?: number;
  source_sector?: string | null;
  source_z?: number | null;
  active_sector?: string | null;
  active_z?: number | null;
  sectors?: { id: string; name: string; levels: number[] }[];
  apc_zones?: ApcZone[];
  relay_destinations?: RelayDestination[];
  /** Server-cached path to the selected target; latency is milliseconds. */
  route?: {
    route: string[];
    hops: number;
    latency: number;
    revision: number;
    reachable: boolean;
  } | null;
};

/** Graph entries are upserts; unchanged stationary entries are not transported again. */
export type NetMapDelta = Partial<Omit<NetMap, 'nodes' | 'edges' | 'full' | 'state_revision'>> & {
  epoch: string;
  full: false | 0;
  base_revision: number;
  state_revision: number;
  nodes?: NetNode[];
  edges?: NetEdge[];
  removed_nodes?: string[];
  removed_edges?: string[];
};
export type NetMapPacket = NetMap | NetMapDelta;

export type ApcZone = { address: string; z: number; runs: { x: number; y: number; width: number }[] };
export type RelayDestination = {
  from: string; to: string; name: string; sector: string; z: number;
  online: boolean; can_hop: boolean; unavailable_reason?: string | null;
};

export type SelectedNetwork = {
  id: string;
  code: string;
  name: string;
  color: string;
  security: number;
  access: number;
  has_key: boolean;
  can_breach: boolean;
  log: string[];
};

export type WindowTab = {
  address: string;
  title: string;
  type: string;
  online: boolean;
};

export type WindowAction = {
  id: string;
  name: string;
  icon: string;
  access: number;
  danger?: boolean;
  desc?: string;
  allowed: boolean;
};

export type MachineWindow = {
  address: string;
  title: string;
  type: string;
  online: boolean;
  access: number;
  legit?: number;
  security?: number;
  can_breach?: boolean;
  network?: {
    id: string;
    name: string;
    code: string;
    access: number;
    can_breach: boolean;
  };
  fields: string[];
  commands: NetCommand[];
  extra: WindowAction[];
  feed: string[] | null;
  watching: boolean;
  logs?: string[];
  remote?: {
    interface: string;
    data: Record<string, unknown>;
    actions: {
      id: string;
      name: string;
      desc?: string;
      access: number;
      allowed: boolean;
      danger?: boolean;
      reason?: string | null;
      params?: { id: string; name: string; type: 'text' | 'number'; value?: string | number; min?: number; max?: number; options?: { value: string; name: string }[] }[];
    }[];
  } | null;
};

export type WebSite = { id: string; domain: string; title: string };

export type WebState = {
  available: boolean;
  sites: WebSite[];
  site: {
    id: string;
    domain: string;
    title: string;
    pages: { slug: string; title: string }[];
  } | null;
  page: {
    slug: string;
    title: string;
    text: string | null;
    loading: boolean;
    failed: boolean;
  } | null;
};

export const ACCESS_NAMES = ['НЕТ', 'ГОСТЬ', 'ПОЛЬЗОВАТЕЛЬ', 'ROOT'];
export const ACCESS_COLORS = ['#59606e', '#8b93a3', '#4ac0ff', '#3cdc8c'];

export const NODE_ICONS: Record<string, string> = {
  modsuit: 'user-shield',
  atmos: 'wind',
  relay: 'tower-broadcast',
  airlock: 'door-closed',
  apc: 'car-battery',
  camera: 'video',
  optic: 'glasses',
  turret: 'crosshairs',
  vendor: 'shop',
  terminal: 'desktop',
  server: 'server',
  circuit: 'microchip',
  intercom: 'microphone',
  implant: 'brain',
  borg: 'robot',
  ai: 'network-wired',
  gateway: 'network-wired',
  neural: 'brain',
  pai: 'robot',
  deck: 'keyboard',
};

export { BOT_ICONS, BOT_NAMES, FACTION_COLORS } from './actorTaxonomy';

export const FORTRESS_MODULE_NAMES: Record<string, string> = {
  wall: 'Стена',
  gate: 'Врата',
  turret: 'Турель',
  trap: 'Ловушка',
  alarm: 'Сигнализация',
  vault: 'Хранилище',
  regen: 'Регенератор',
};

export const FORTRESS_MODULE_ICONS: Record<string, string> = {
  wall: 'dungeon',
  gate: 'torii-gate',
  turret: 'crosshairs',
  trap: 'bug',
  alarm: 'bell',
  vault: 'vault',
  regen: 'kit-medical',
};

/** Packet class colours shared by the map flights and the legend. */
export const PACKET_COLORS: Record<string, string> = {
  command: '#ffc26b',
  remote: '#c792ff',
  window: '#c792ff',
  file: '#6fe0ff',
  'entity.signal': '#f19bdc',
  'entity.message': '#f19bdc',
  machine: '#50e8c0',
  fail: '#ff6470',
};

export const PACKET_NAMES: Record<string, string> = {
  command: 'Команды',
  remote: 'Запросы устройств',
  file: 'Файлы',
  'entity.message': 'Сообщения процессам',
  machine: 'Обмен машин',
  fail: 'Отказ доставки',
};

export const NODE_NAMES: Record<string, string> = {
  modsuit: 'МОД-костюмы',
  atmos: 'Атмосфера',
  relay: 'Реле NTnet',
  airlock: 'Шлюзы',
  apc: 'Щитки APC',
  camera: 'Камеры',
  optic: 'HUD-очки',
  turret: 'Турели',
  vendor: 'Торгоматы',
  terminal: 'Терминалы',
  server: 'Серверы',
  circuit: 'Схемы',
  intercom: 'Интеркомы',
  implant: 'Импланты',
  borg: 'Кибники',
  ai: 'ИИ',
  gateway: 'Шлюзы сетей',
  neural: 'Нейроинтерфейсы',
  pai: 'пИИ',
  deck: 'Кибердеки',
};

export const THEME = {
  bg: 'var(--net-bg, #080f18)',
  panel: 'var(--net-panel, #101d29)',
  line: 'var(--net-border, #294053)',
  text: 'var(--net-text, #e5f1fa)',
  muted: 'var(--net-muted, #8298a8)',
  accent: 'var(--net-accent, #55cbe9)',
  good: 'var(--net-good, #5bdab1)',
  warn: 'var(--net-warn, #f5c477)',
  bad: 'var(--net-bad, #f08387)',
};
