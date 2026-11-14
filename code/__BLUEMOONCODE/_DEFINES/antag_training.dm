#define ANTAG_TRAINING_SIZE 55
#define ANTAG_TRAINING_MAX_ARENAS 1
// z = 0 у атома в контейнере: такие перемещения проверяются при любом живом полигоне.
#define ANTAG_TRAINING_MOVE_GATED(mover, target) (mover.training_origin || (length(GLOB.antag_training_z) && (!mover.z || GLOB.antag_training_z[mover.z] || GLOB.antag_training_z[target?.z] || (target && !target.z))))
#define ANTAG_TRAINING_DISCONNECT_GRACE (1 MINUTES)
#define ANTAG_TRAINING_EXIT_GHOST "В призрака"
#define ANTAG_TRAINING_EXIT_CAFE "В Гост-Кафе"
#define ANTAG_TRAINING_EXIT_STAY "Остаться"
#define ANTAG_TRAINING_TARGET_LIMIT 12
#define ANTAG_TRAINING_SUPPLY_LIMIT 100
#define ANTAG_TRAINING_STRUCTURE_LIMIT 16
#define ANTAG_TRAINING_STAND_NONE 0
/// Кодер или ментор: спавн только мимо стоп-листа.
#define ANTAG_TRAINING_STAND_LIMITED 1
#define ANTAG_TRAINING_STAND_FULL 2
#define ANTAG_TRAINING_STAND_RESULTS 40
#define ANTAG_TRAINING_STAND_QUERY_MIN 3
#define ANTAG_TRAINING_WORK_BUDGET_MS 5
/// Закрытая арена без участников чистится с большей долей тика: ждать её некому, а гейт свободного тика остаётся.
#define ANTAG_TRAINING_CLOSE_BUDGET_MS 10
// В тестах stoplag() не ждёт свободного тика, и гейт не должен: МК держит тик занятым минутами.
#ifdef UNIT_TESTS
#define ANTAG_TRAINING_TICK_FREE TRUE
#else
#define ANTAG_TRAINING_TICK_FREE (TICK_USAGE < TICK_LIMIT_TO_RUN)
#endif
/// Столько пустая арена ждёт возвращения участника, прежде чем закрыться. Тесты закрывают арену сразу, кроме теста самого ожидания.
#ifdef UNIT_TESTS
#define ANTAG_TRAINING_EMPTY_GRACE 0
#else
#define ANTAG_TRAINING_EMPTY_GRACE (3 MINUTES)
#endif
#define ANTAG_TRAINING_RESTART_DELAY (5 SECONDS)
#define ANTAG_TRAINING_VOTE_TIME (45 SECONDS)
/// Потери тела существа чаще, чем раз в это время, идут подряд; больше ANTAG_TRAINING_CREATURE_RAPID_LIMIT подряд - тело не пересоздаётся.
#define ANTAG_TRAINING_CREATURE_RAPID_WINDOW (10 SECONDS)
#define ANTAG_TRAINING_CREATURE_RAPID_LIMIT 3
#define ANTAG_TRAINING_BATCH_LIMIT 12
#define ANTAG_TRAINING_POINTS 100
#define ANTAG_TRAINING_NUKE_TIMER (30 SECONDS)
#define ANTAG_TRAINING_ARK_DELAY (60 SECONDS)
#define ANTAG_TRAINING_BRASS_SHEETS 20
/// Учебная критическая масса блоба и предел его роста: клетки станционного макета.
#define ANTAG_TRAINING_BLOB_TILES 100
/// Столько учебная болезнь ждёт выбора нулевого пациента, прежде чем выберет манекен сама; столько же ждёт заново, если манекенов нет.
#define ANTAG_TRAINING_DISEASE_FREEMOVE (2 MINUTES)
/// Открывает самые дорогие адаптации: порог required_total_points у них 25.
#define ANTAG_TRAINING_DISEASE_POINTS 25
#define ANTAG_TRAINING_DISEASE_HOSTS 3
#define ANTAG_TRAINING_HK50_PAIR 2
#define ANTAG_TRAINING_HK47_PROTECT_TIME (2 MINUTES)
#define ANTAG_TRAINING_HK47_CAPTURE_TIME (3 SECONDS)
#define ANTAG_TRAINING_HK47_SUSPECTS 3
#define ANTAG_TRAINING_PRACTICE_DELAY (5 SECONDS)
#define ANTAG_TRAINING_EXERCISE_SCORE_MAX 100
#define ANTAG_TRAINING_EXERCISE_SCORE_MIN 10
#define ANTAG_TRAINING_EXERCISE_HINT_PENALTY 15
#define ANTAG_TRAINING_EXERCISE_SECOND_PENALTY 1
#define ANTAG_TRAINING_EXERCISE_CHECK_INTERVAL (1 SECONDS)
#define ANTAG_TRAINING_GENERATOR_FUEL 10
#define ANTAG_TRAINING_MIX_OXYGEN 21
#define ANTAG_TRAINING_MIX_TOLERANCE 2
#define ANTAG_TRAINING_MIX_PRESSURE 100
#define ANTAG_TRAINING_BREACH_PRESSURE 90
#define ANTAG_TRAINING_FIRE_PLASMA 6
#define ANTAG_TRAINING_FIRE_IGNITION 1000
#define ANTAG_TRAINING_FIRE_DISTANCE 2
#define ANTAG_TRAINING_FIRE_BURNOUT 0.5
#define ANTAG_TRAINING_FIRE_CALM_CHECKS 3
#define ANTAG_TRAINING_HACK_OPEN_WAIT (1 SECONDS)
#define ANTAG_TRAINING_ROOM_LIMIT 100
#define ANTAG_TRAINING_DECOMPRESSION_RATIO 0.3
#define ANTAG_TRAINING_DUEL_INVITE (30 SECONDS)
#define ANTAG_TRAINING_DUEL_COUNTDOWN (3 SECONDS)
#define ANTAG_TRAINING_DUEL_DURATION (3 MINUTES)
#define ANTAG_TRAINING_SPAWN_RADIUS 3
#define ANTAG_TRAINING_KNOCKDOWN (10 SECONDS)
#define ANTAG_TRAINING_RUNNER_STEP (0.4 SECONDS)
#define ANTAG_TRAINING_SECTOR_UNLOADED 0
#define ANTAG_TRAINING_SECTOR_LOADING 1
#define ANTAG_TRAINING_SECTOR_READY 2
#define ANTAG_TRAINING_SECTOR_UNLOADING 3
#define ANTAG_TRAINING_CLEAR_PASSES 3
#define ANTAG_TRAINING_SCAN_TIME (1.2 SECONDS)
#define ANTAG_TRAINING_DISSOLVE_TIME (1 SECONDS)
#define ANTAG_TRAINING_SOUND_VOLUME 40
#define ANTAG_TRAINING_SOUND_ENTER 'modular_bluemoon/sound/antag_training/enter.ogg'
#define ANTAG_TRAINING_SOUND_SECTOR_LOAD 'modular_bluemoon/sound/antag_training/sector_load.ogg'
#define ANTAG_TRAINING_SOUND_SECTOR_UNLOAD 'modular_bluemoon/sound/antag_training/sector_unload.ogg'
#define ANTAG_TRAINING_SOUND_RECOVER 'modular_bluemoon/sound/antag_training/recover.ogg'
#define ANTAG_TRAINING_SOUND_STEP 'modular_bluemoon/sound/antag_training/step.ogg'
#define ANTAG_TRAINING_SOUND_SUCCESS 'modular_bluemoon/sound/antag_training/success.ogg'
#define ANTAG_TRAINING_SOUND_FAIL 'modular_bluemoon/sound/antag_training/fail.ogg'
#define ANTAG_TRAINING_SECTOR_IDLE (5 MINUTES)
#define ANTAG_TRAINING_SECTOR_IDLE_CHECK (30 SECONDS)
#define ANTAG_TRAINING_SQUAD_INVITE (30 SECONDS)
#define ANTAG_TRAINING_SQUAD_NAME_LENGTH 24
#define ANTAG_TRAINING_BOOKING_LIMIT (40 MINUTES)
/// Бронь снимается, если столько времени в секторе нет никого из группы.
#define ANTAG_TRAINING_BOOKING_IDLE (5 MINUTES)
/// Освободившийся сектор столько придержан за каждой группой из его очереди по порядку.
#define ANTAG_TRAINING_BOOKING_PRIORITY (60 SECONDS)
/// Сколько секторов всегда остаются незабронированными.
#define ANTAG_TRAINING_BOOKING_FREE_SECTORS 2
/// Угол хаба на уровне полигона: над ядром, выше полосы секторов.
#define ANTAG_TRAINING_HUB_X 1
#define ANTAG_TRAINING_HUB_Y 76
#define ANTAG_TRAINING_HUB_DEPARTMENT_IDLE (10 MINUTES)
/// Столько труб и кабелей хаб удаляет между проверками бюджета работы.
#define ANTAG_TRAINING_HUB_NETWORK_BATCH 100
#define ANTAG_TRAINING_HUB_PADS 4
/// Площадка освобождается, если столько времени на ней нет владельцев и её не трогали с пульта.
#define ANTAG_TRAINING_HUB_PAD_IDLE (20 MINUTES)
/// Пресет пустой площадки: так она выглядит до занятия и после освобождения.
#define ANTAG_TRAINING_HUB_PAD_BARE "bare"
/// Фазы сценария группы: разбор слотов, сборка тел, партия, итог.
#define ANTAG_TRAINING_SCENARIO_SETUP "setup"
#define ANTAG_TRAINING_SCENARIO_STARTING "starting"
#define ANTAG_TRAINING_SCENARIO_RUNNING "running"
#define ANTAG_TRAINING_SCENARIO_SUMMARY "summary"
/// Как часто идущая партия проверяет цели, выбывших и время.
#define ANTAG_TRAINING_SCENARIO_CHECK (1 SECONDS)
/// Мест в одном слоте и слотов в листе сценария.
#define ANTAG_TRAINING_SCENARIO_SLOT_SEATS 6
#define ANTAG_TRAINING_SCENARIO_SLOTS 12
#define ANTAG_TRAINING_SCENARIO_LABEL_LENGTH 24
#define ANTAG_TRAINING_ROLE_DEFAULT "default"
#define ANTAG_TRAINING_ROLE_TRAIT "antag_training_role"
/// Программа игнорирует должность участника.
#define ANTAG_TRAINING_ROLES_NONE 0
/// Программа работает поверх человеческой должности.
#define ANTAG_TRAINING_ROLES_HUMAN (1<<0)
/// Программа работает с учебным ИИ или киборгом.
#define ANTAG_TRAINING_ROLES_SILICON (1<<1)
