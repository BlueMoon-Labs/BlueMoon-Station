#define BITRUNNER_COST_NONE 0
#define BITRUNNER_COST_LOW 1
#define BITRUNNER_COST_MEDIUM 2
#define BITRUNNER_COST_HIGH 3
#define BITRUNNER_COST_EXTREME 20

/// Минимальная награда.
#define BITRUNNER_REWARD_MIN 1
/// Обычная награда.
#define BITRUNNER_REWARD_LOW 3
/// Награда за среднюю сложность.
#define BITRUNNER_REWARD_MEDIUM 4
/// Награда за высокую сложность.
#define BITRUNNER_REWARD_HIGH 5
/// Максимальная награда.
#define BITRUNNER_REWARD_EXTREME 6

/// Синий: угроза только от ghost-ролей.
#define BITRUNNER_DIFFICULTY_NONE 0
/// Жёлтый: мобы слабые и легко обходятся.
#define BITRUNNER_DIFFICULTY_LOW 1
/// Оранжевый: мобы стреляют или агрессивны.
#define BITRUNNER_DIFFICULTY_MEDIUM 2
/// Красный: домен нацелен на убийство битраннеров.
#define BITRUNNER_DIFFICULTY_HIGH 3

/// Сеть камер битраннеров.
#define BITRUNNER_CAMERA_NET "bitrunner"

/// Запрещает внешнюю загрузку предметов на аватар.
#define DOMAIN_FORBIDS_ITEMS (1<<0)
/// Запрещает внешнюю загрузку способностей на аватар.
#define DOMAIN_FORBIDS_ABILITIES (1<<1)
/// Отключает бонус за прохождение без урона.
#define DOMAIN_NO_NOHIT_BONUS (1<<2)
/// Тестовый домен, не загружается обычным способом.
#define DOMAIN_TEST_ONLY (1<<3)

/// Запрещает любую внешнюю загрузку на аватар.
#define DOMAIN_FORBIDS_ALL ALL

// Алерты
#define ALERT_BITRUNNER_CROWBAR "bitrunning_crowbar"
#define ALERT_BITRUNNER_COMPLETED "bitrunning_complete"
#define ALERT_BITRUNNER_INTEGRITY "bitrunning_integrity"
#define ALERT_BITRUNNER_SHUTDOWN "bitrunning_shutdown"
#define ALERT_BITRUNNER_RESET "bitrunning_reset"
#define ALERT_BITRUNNER_THREAT "bitrunning_threat"
#define ALERT_BITRUNNER_BREACH "bitrunning_breach"
#define ALERT_BITRUNNER_GLITCH "bitrunning_glitch"

/// Сигнал после загрузки lazy-шаблона.
#define COMSIG_LAZY_TEMPLATE_LOADED "lazy_template_loaded"

// Слой совместимости со старой базой BlueMoon.
#ifndef COMSIG_QDELETING
#define COMSIG_QDELETING COMSIG_PARENT_QDELETING
#endif
#ifndef COMSIG_ATOM_EXAMINE
#define COMSIG_ATOM_EXAMINE COMSIG_PARENT_EXAMINE
#endif
#ifndef COMSIG_GHOSTROLE_SPAWNED
#define COMSIG_GHOSTROLE_SPAWNED "ghostrole_spawned"
#endif
#ifndef COMSIG_MACHINERY_REFRESH_PARTS
#define COMSIG_MACHINERY_REFRESH_PARTS "machinery_refresh_parts"
#endif
#define COMSIG_LIVING_PILL_CONSUMED "living_pill_consumed"
#define COMSIG_MIND_TRANSFERRED "mind_transferred"
#define COMSIG_GLASS_DRANK "glass_drank"

#ifndef span_infoplain
#define span_infoplain(str) span_info(str)
#endif

#ifndef MOB_SIZE_HUGE
#define MOB_SIZE_HUGE MOB_SIZE_LARGE
#endif

#ifndef ITEM_INTERACT_SUCCESS
#define ITEM_INTERACT_SUCCESS TOOL_ACT_TOOLTYPE_SUCCESS
#endif
#ifndef ITEM_INTERACT_FAILURE
#define ITEM_INTERACT_FAILURE NONE
#endif
#ifndef ITEM_INTERACT_BLOCKING
#define ITEM_INTERACT_BLOCKING TOOL_ACT_MELEE_CHAIN_BLOCKING
#endif

#ifndef DEL_ON_DEATH
#define DEL_ON_DEATH (1<<0)
#endif
#ifndef INCLUDE_POCKETS
#define INCLUDE_POCKETS (1<<0)
#endif
#ifndef INCLUDE_ACCESSORIES
#define INCLUDE_ACCESSORIES (1<<1)
#endif

#define GHOSTROLE_TAKE_PREFS_APPEARANCE (1<<0)

#define ROLE_GLITCH "Glitch"
#define ROLE_CYBER_POLICE "Cyber Police"
#define ROLE_CYBER_TAC "Cyber Tac"
#define ROLE_NETGUARDIAN "Netguardian"
#define ROLE_GHOST_ROLE "Ghost Role"
#define ANTAG_GROUP_GLITCH "glitch"
#define POLL_IGNORE_GLITCH "poll_ignore_glitch"
#define POLL_IGNORE_SHUTTLE_DENIZENS "poll_ignore_shuttle_denizens"

#define FACTION_BOSS "boss"
#define FACTION_CARP "carp"
#define FACTION_HIVEBOT "hivebot"
#define FACTION_HOSTILE "hostile"
#define FACTION_MIMIC "mimic"
#define FACTION_PIRATE "pirate"
#define FACTION_SPIDER "spider"
#define FACTION_STICKMAN "stickman"
#define FACTION_NEUTRAL "neutral"
#define FACTION_HERETIC "heretic"

#define LIGHT_COLOR_BUBBLEGUM "#ff2b9b"
#define CURRENT_STATION_YEAR "2564"

#define COLOR_CARGO_BROWN "#a1723d"
#define COLOR_COMMAND_BLUE "#334e6d"
#define CATEGORY_BITRUNNING_FLAIR "Разное"
#define CATEGORY_BITRUNNING_TECH "Технологии"
#define CATEGORY_BEPIS "Bepis"

/// Помощник для спавнеров ghost-ролей и визуала экипировки.
#define SPAWNER_TAKE_PREFS_APPEARANCE GHOSTROLE_TAKE_PREFS_APPEARANCE

// Флаги результата загрузки снаряжения.
/// Ошибка загрузки.
#define BITRUNNER_GEAR_LOAD_FAILED (1<<0)
/// Заблокировано ограничениями домена.
#define BITRUNNER_GEAR_LOAD_BLOCKED (1<<1)
