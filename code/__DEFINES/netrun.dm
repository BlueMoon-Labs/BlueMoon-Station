// Уровни доступа к узлу сети
#define NETRUN_ACCESS_NONE 0
#define NETRUN_ACCESS_GUEST 1
#define NETRUN_ACCESS_USER 2
#define NETRUN_ACCESS_ROOT 3

// Типы узлов
#define NETRUN_NODE_GATEWAY "gateway"
#define NETRUN_NODE_AIRLOCK "airlock"
#define NETRUN_NODE_APC "apc"
#define NETRUN_NODE_CAMERA "camera"
#define NETRUN_NODE_OPTIC "optic"
#define NETRUN_NODE_TURRET "turret"
#define NETRUN_NODE_VENDOR "vendor"
#define NETRUN_NODE_ATMOS "atmos"
#define NETRUN_NODE_TERMINAL "terminal"
#define NETRUN_NODE_SERVER "server"
#define NETRUN_NODE_CIRCUIT "circuit"
#define NETRUN_NODE_INTERCOM "intercom"
#define NETRUN_NODE_IMPLANT "implant"
#define NETRUN_NODE_BORG "borg"
#define NETRUN_NODE_AI "ai"
#define NETRUN_NODE_NEURAL "neural"
#define NETRUN_NODE_PAI "pai"
#define NETRUN_NODE_DECK "deck"
#define NETRUN_NODE_MODSUIT "modsuit"

// Точки подключения консоли
#define NETRUN_ORIGIN_TERMINAL "terminal"
#define NETRUN_ORIGIN_DECK "deck"
#define NETRUN_ORIGIN_IMPLANT "implant"
#define NETRUN_ORIGIN_NTOS "ntos"
#define NETRUN_ORIGIN_ENTITY "entity"
#define NETRUN_ORIGIN_CIRCUIT "circuit"
#define NETRUN_ORIGIN_PAI "pai"
#define NETRUN_ORIGIN_AI "ai"

/// Shared by scheduler implementations and unit tests included before module sources.
#define NETRUN_TASK_CRITICAL 1
#define NETRUN_TASK_NORMAL 2
#define NETRUN_TASK_BACKGROUND 3

/// Execution defaults. Times are deciseconds unless the name ends in _MS.
/// Slow maintenance cadence; admitted work and explicit input wake the bounded worker.
#define NETRUN_DEFAULT_FIRE_INTERVAL 20
#define NETRUN_DEFAULT_TASK_BUDGET_MS 6.0
#define NETRUN_DEFAULT_TASK_MIN_BUDGET_MS 1.0
#define NETRUN_DEFAULT_TASK_PRESSURE_TICK_USAGE 100
#define NETRUN_DEFAULT_TASK_MIN_PER_PASS 2
#define NETRUN_DEFAULT_TASK_MAX_PER_PASS 192
#define NETRUN_DEFAULT_INTERACTIVE_BURST 8
#define NETRUN_DEFAULT_INTERACTIVE_PRIORITY NETRUN_TASK_CRITICAL
#define NETRUN_DEFAULT_INTERACTIVE_FLUSH TRUE
#define NETRUN_INPUT_ACK_MAX_LENGTH 64
#define NETRUN_ICE_MIN_TELEGRAPH (2 SECONDS)
/// In turn combat the victim cannot react during the opponent's preparation.
#define NETRUN_ICE_COMBAT_TELEGRAPH (0.5 SECONDS)
/// Give players time to recover earned loot before station maintenance collects it.
#define NETRUN_SALVAGE_RECYCLE_GRACE (30 SECONDS)
#define NETRUN_DEFAULT_TASK_COST_FLOOR_MS 0.05
#define NETRUN_DEFAULT_TASK_INITIAL_COST_MS 0.1
#define NETRUN_DEFAULT_TASK_COST_SMOOTHING 0.15
#define NETRUN_DEFAULT_TASK_POPULATION_INTERVAL (1 SECONDS)
#define NETRUN_DEFAULT_APC_PREBUILD_OPERATIONS 96
/// Fast registration attempts before slow backoff while a compatible controller is online.
/// Controller/device signals (power, move, config) restart the fast retry window.
#define NETRUN_ATMOS_REGISTRATION_MAX_ATTEMPTS 10
#define NETRUN_DEFAULT_ROUTE_REFRESH_INTERVAL (1 SECONDS)
#define NETRUN_DEFAULT_ROUTE_EXPIRY_INTERVAL (30 SECONDS)
#define NETRUN_DEFAULT_UI_REFRESH_INTERVAL (1 SECONDS)
#define NETRUN_DEFAULT_UI_ACTIVITY_LEASE (3 SECONDS)
#define NETRUN_DEFAULT_NODE_ACTIVITY_DURATION (5 SECONDS)
#define NETRUN_DEFAULT_NODE_POLL_INTERVAL (1 SECONDS)
#define NETRUN_DEFAULT_NODE_IDLE_POLL_INTERVAL (30 SECONDS)
#define NETRUN_DEFAULT_NODE_UPDATE_INTERVAL (10 SECONDS)
#define NETRUN_NODE_INTEREST_LEASE (3 SECONDS)
#define NETRUN_NODE_INTEREST_RADIUS 7
#define NETRUN_DEFAULT_TASK_CRITICAL_LATE_AFTER (2 SECONDS)
#define NETRUN_DEFAULT_TASK_NORMAL_LATE_AFTER (5 SECONDS)
#define NETRUN_DEFAULT_TASK_BACKGROUND_LATE_AFTER (20 SECONDS)
#define NETRUN_DEFAULT_TASK_PRIORITY_ROTATION list(NETRUN_TASK_CRITICAL, NETRUN_TASK_NORMAL, NETRUN_TASK_CRITICAL, NETRUN_TASK_BACKGROUND, NETRUN_TASK_CRITICAL, NETRUN_TASK_NORMAL, NETRUN_TASK_CRITICAL)
/// Hard validation bounds prevent malformed live configuration from disabling all progress.
#define NETRUN_EXECUTION_MIN_BUDGET_MS 0.01
#define NETRUN_EXECUTION_MAX_BUDGET_MS 50
#define NETRUN_EXECUTION_MAX_PRESSURE_TICK_USAGE 1000
#define NETRUN_EXECUTION_MAX_TASKS_PER_PASS 1024
#define NETRUN_EXECUTION_MAX_PREBUILD_OPERATIONS 4096
#define NETRUN_EXECUTION_MAX_PRIORITY_ROTATION 64
#define NETRUN_EXECUTION_MIN_INTERVAL 1
#define NETRUN_EXECUTION_MAX_INTERVAL (10 MINUTES)

// Сети
#define NETRUN_GLOBAL_ID "ntnet"
#define NETRUN_LAN_PUBLIC "pub"
#define NETRUN_LAN_ENGINEERING "eng"
#define NETRUN_LAN_MEDICAL "med"
#define NETRUN_LAN_SCIENCE "sci"
#define NETRUN_LAN_CARGO "cargo"
#define NETRUN_LAN_SECURITY "sec"
#define NETRUN_LAN_COMMAND "cmd"

/// Geographic physical links: each started block of tiles adds one decisecond.
#define NETRUN_LINK_TILES_PER_DS 15
#define NETRUN_RELAY_LATENCY 3
/// Machine I/O uses network time; runner actions retain their gameplay latency.
#define NETRUN_MACHINE_LATENCY_SCALE 0.02
#define NETRUN_MACHINE_MAX_LATENCY (0.25 SECONDS)
#define NETRUN_MAX_PACKET_LOG 100
/// Shared map event ring: arrivals, alerts and packet flights (send/done/fail).
#define NETRUN_MAX_MAP_EVENTS 96
/// Minimum display lifetime of a map event; a flight additionally lives for its transit time.
#define NETRUN_MAP_EVENT_LIFETIME (4 SECONDS)
/// Arrival ring shown after a flight reaches its destination.
#define NETRUN_MAP_EVENT_TAIL (2 SECONDS)
#define NETRUN_MAX_PENDING_REQUESTS 2048
#define NETRUN_MAX_MACHINE_PACKETS 2048
/// Machine flights drawn on maps per second; one station pair is drawn at most every two seconds.
#define NETRUN_MAX_MACHINE_FLIGHTS 8
#define NETRUN_APC_NEIGHBORS 3

// Типы файлов
#define NETRUN_FILE_TEXT "text"
#define NETRUN_FILE_KEY "key"
#define NETRUN_FILE_ACCESS "access"
#define NETRUN_FILE_DAEMON "daemon"
#define NETRUN_FILE_SEED "seed"
#define NETRUN_FILE_TECHWEB "techweb"
#define NETRUN_FILE_TECHWEB_LINK "techweb_link"
#define NETRUN_FILE_PHOTO "photo"

/// Maximum broker payout per mind and round, shared by settlement and help text.
#define NETRUN_CONTRACT_TC_CAP 6
/// Активная боевая программа ("карточка"): её запускают против цели в узле
#define NETRUN_FILE_PROGRAM "program"

// Боевые роли программ
#define NETRUN_PROGRAM_ATTACK "attack"
#define NETRUN_PROGRAM_SHIELD "shield"
#define NETRUN_PROGRAM_STUN "stun"
#define NETRUN_PROGRAM_REPAIR "repair"
#define NETRUN_PROGRAM_PURGE "purge"
#define NETRUN_PROGRAM_TRACE "trace"
/// Bounded recoverable files left by defeated processes, separate from machine storage.
#define NETRUN_MAX_SALVAGE_FILES 12
/// SSnetrun: (node); entity: (file, node), after actual ownership changes.
#define COMSIG_NETRUN_SALVAGE_CHANGED "netrun_salvage_changed"
#define COMSIG_NETRUN_SALVAGE_RECOVERED "netrun_salvage_recovered"

// Враждебные процессы (ICE)
#define NETRUN_ICE_SENTRY "sentry"
#define NETRUN_ICE_HUNTER "hunter"
#define NETRUN_ICE_BLACK "black"
#define COMSIG_NETRUN_ICE_PROGRAM_RESOLVED "netrun_ice_program_resolved"
#define COMSIG_NETRUN_ENTITY_SPEAK "netrun_entity_speak"
#define COMSIG_NETRUN_AGENT_ORDER_LIST "netrun_agent_order_list"
#define COMSIG_NETRUN_AGENT_CONTROL "netrun_agent_control"
/// Сколько персистентных патрульных процессов поднимается в начале раунда
#define NETRUN_MAX_PATROLS 400
/// Сколько лорных документов раскладывается по серверам станции в начале раунда
#define NETRUN_MAX_LORE_FILES 300

/// События расширений: источник сигнала — сущность или её консоль.
#define COMSIG_NETRUN_ENTITY_NODE_CHANGED "netrun_entity_node_changed"
#define COMSIG_NETRUN_ENTITY_TICK "netrun_entity_tick"
#define COMSIG_NETRUN_ENTITY_GOALS_CHANGED "netrun_entity_goals_changed"
#define COMSIG_NETRUN_ENTITY_COMMAND_FINISHED "netrun_entity_command_finished"
#define COMSIG_NETRUN_ENTITY_MODULE_READY "netrun_entity_module_ready"
/// Receiving actor: (datum/netrun_console/sender, message), after authorized packet delivery.
#define COMSIG_NETRUN_ACTOR_CONTACT "netrun_actor_contact"
/// Receiving actor: (datum/attacker), after a hostile effect or intent.
#define COMSIG_NETRUN_ACTOR_ATTACKED "netrun_actor_attacked"
/// Allied actor: (datum/victim, datum/attacker), bounded to local residents.
#define COMSIG_NETRUN_ACTOR_DISTRESS "netrun_actor_distress"
#define COMSIG_NETRUN_ENTITY_INTEGRITY "netrun_entity_integrity"
#define COMSIG_NETRUN_CONSOLE_EVENT "netrun_console_event"
/// Нелегальный сетевой доступ к кибернетическому узлу носителя: (datum/netrun_console, datum/component/netrun_node)
#define COMSIG_NETRUN_IMPLANT_INTRUSION "netrun_implant_intrusion"

/// SSnetrun lifecycle events; callbacks only invalidate caches or enqueue tasks.
#define COMSIG_NETRUN_NODE_REGISTERED "netrun_node_registered"
#define COMSIG_NETRUN_NODE_UNREGISTERED "netrun_node_unregistered"
#define COMSIG_NETRUN_NODE_MOVED "netrun_node_moved"
#define COMSIG_NETRUN_TOPOLOGY_DIRTY "netrun_topology_dirty"
#define COMSIG_NETRUN_EVENT_POSTED "netrun_event_posted"
/// Device atom: a provider's externally visible native state changed (no arguments).
#define COMSIG_NETRUN_SERVICE_STATE_CHANGED "netrun_service_state_changed"
#define COMSIG_NETRUN_RESEARCH_CHANGED "netrun_research_changed"

/// Domain notifications. Handlers invalidate caches; they must not serialize UI.
/// Node: live gameplay change (node, changed_flags). SSnetrun: native binding/availability.
#define COMSIG_NETRUN_NODE_CHANGED "netrun_node_changed"
/// SSnetrun: one coalesced observational publication (address => changed_flags).
#define COMSIG_NETRUN_NODES_CHANGED "netrun_nodes_changed"
/// SSnetrun: (revision), after a complete structural graph commit.
#define COMSIG_NETRUN_TOPOLOGY_CHANGED "netrun_topology_changed"
/// SSnetrun: (node), before affected sessions revoke grants.
#define COMSIG_NETRUN_FIREWALL_CHANGED "netrun_firewall_changed"
/// File store / inventory: no payload; the source owns its current contents.
#define COMSIG_NETRUN_STORAGE_CHANGED "netrun_storage_changed"
#define COMSIG_NETRUN_INVENTORY_CHANGED "netrun_inventory_changed"
/// ICE and console: combat state changed.
#define COMSIG_NETRUN_COMBAT_CHANGED "netrun_combat_changed"
#define COMSIG_NETRUN_TURN_CHANGED "netrun_turn_changed"
/// One encounter owns the current participant's decision deadline.
#define NETRUN_COMBAT_AP 3
#define NETRUN_COMBAT_DECISION_TIME (12 SECONDS)
/// Consecutive complete rounds without a committed hostile action end the encounter.
#define NETRUN_COMBAT_IDLE_ROUNDS 3
/// Shared UI state outside the physical map: (network), and a new channel message.
#define COMSIG_NETRUN_NETWORK_CHANGED "netrun_network_changed"
#define COMSIG_NETRUN_CHAT_CHANGED "netrun_chat_changed"
/// SSnetrun: (ice, victim), emitted only after an attack is actually queued.
#define COMSIG_NETRUN_ICE_CAST_STARTED "netrun_ice_cast_started"
/// ICE: (old_node, new_node).
#define COMSIG_NETRUN_ICE_NODE_CHANGED "netrun_ice_node_changed"
#define NETRUN_CHANGED_STATE (1<<0)
#define NETRUN_CHANGED_BINDING (1<<1)
#define NETRUN_CHANGED_OCCUPANTS (1<<2)
#define NETRUN_CHANGED_REMOVED (1<<3)
/// Journals and file contents change selected-device panels, never map markers or routing.
#define NETRUN_CHANGED_DETAILS (1<<4)

/// Storage capacities are authored in base cells and scaled once by this factor.
#define NETRUN_STORAGE_SCALE 8

/// Autonomous round content (bot population, fortress presets). Unit tests create it explicitly
/// so ambient processes never interfere with unrelated assertions.
#ifdef UNIT_TESTS
#define NETRUN_AUTONOMOUS_CONTENT FALSE
#else
#define NETRUN_AUTONOMOUS_CONTENT TRUE
#endif

// Автономные сетевые боты: архетипы поведения
#define NETRUN_BOT_RAIDER "raider"
#define NETRUN_BOT_CUSTODIAN "custodian"
#define NETRUN_BOT_RECYCLER "recycler"
#define NETRUN_BOT_POLICE "police"
#define NETRUN_BOT_MENDER "mender"
#define NETRUN_BOT_SENTINEL "sentinel"
// Стороны ботов и крепостей
#define NETRUN_FACTION_ROGUE "rogue"
#define NETRUN_FACTION_STATION "station"
#define NETRUN_FACTION_OWNER "owner"
/// Запускаемая программа-агент: содержимое файла — id архетипа бота
#define NETRUN_FILE_BOT "bot"
/// Result of one bot goal step.
#define NETRUN_BOT_GOAL_CONTINUE 0
#define NETRUN_BOT_GOAL_DONE 1
#define NETRUN_BOT_GOAL_FAILED 2
/// Result of one movement action toward a node.
#define NETRUN_BOT_MOVE_PROGRESS 0
#define NETRUN_BOT_MOVE_ARRIVED 1
#define NETRUN_BOT_MOVE_BLOCKED 2
/// Autonomous processes alive at once, including player agents.
#define NETRUN_MAX_BOTS 28
#define NETRUN_MAX_AGENTS_PER_CONSOLE 2
#define NETRUN_POLICE_QUOTA 2
#define NETRUN_ROGUE_QUOTA 2
#define NETRUN_CUSTODIAN_QUOTA 3
#define NETRUN_RECYCLER_QUOTA 2

// Модули сетевых крепостей
#define NETRUN_FORT_WALL "wall"
#define NETRUN_FORT_GATE "gate"
#define NETRUN_FORT_TURRET "turret"
#define NETRUN_FORT_TRAP "trap"
#define NETRUN_FORT_ALARM "alarm"
#define NETRUN_FORT_VAULT "vault"
#define NETRUN_FORT_REGEN "regen"
/// Intact walls add at most this much to a node's effective security (still capped at 5).
#define NETRUN_FORT_MAX_SECURITY_BONUS 2
#define NETRUN_FORT_MODULE_BUILDING "building"
#define NETRUN_FORT_MODULE_ONLINE "online"
#define NETRUN_FORT_MODULE_DESTROYED "destroyed"
/// Extra node storage while an intact vault stands.
#define NETRUN_FORT_VAULT_STORAGE (16 * NETRUN_STORAGE_SCALE)
#define NETRUN_FORT_TRAP_REARM (30 SECONDS)
/// Round-start/new important nodes fortified automatically, at most.
#define NETRUN_MAX_FORTRESS_PRESETS 24

/// Police incident registry is bounded; the oldest closed record is evicted first.
#define NETRUN_MAX_INCIDENTS 32
#define NETRUN_INCIDENT_LOW 1
#define NETRUN_INCIDENT_MEDIUM 2
#define NETRUN_INCIDENT_HIGH 3
/// An incident without new reports for this long is no longer worth a police response.
#define NETRUN_INCIDENT_STALE_AFTER (3 MINUTES)

/// SSnetrun: (datum/netrun_incident) after a new incident is registered or an open one escalates.
#define COMSIG_NETRUN_INCIDENT_REPORTED "netrun_incident_reported"
/// SSnetrun: (datum/component/netrun_node) after a fortress is built, damaged, repaired or removed.
#define COMSIG_NETRUN_FORTRESS_CHANGED "netrun_fortress_changed"

#define NETRUN_TRACE_MAX 100
/// Сколько трассировки спадает за секунду простоя
#define NETRUN_TRACE_DECAY 0.5
/// Блокировка точки подключения после полной трассировки
#define NETRUN_TRACE_LOCKOUT (1 MINUTES)
/// Окно «след потерян» после заметания следов: лёд не атакует и не перезахватывает цель
#define NETRUN_DISENGAGE_GRACE (8 SECONDS)

#define NETRUN_MAX_LOG 60
#define NETRUN_MAX_CONSOLE_LOG 40

/// Коды матрицы взлома
#define NETRUN_BREACH_CODES list("1C", "55", "BD", "E9", "7A", "FF")
