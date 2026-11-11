/// Percentage of tick to leave for master controller to run
#define MAPTICK_MC_MIN_RESERVE 70
/// internal_tick_usage is updated every tick by extools
#if DM_VERSION > 513
#define MAPTICK_LAST_INTERNAL_TICK_USAGE world.map_cpu
#else
#define MAPTICK_LAST_INTERNAL_TICK_USAGE 50
#endif
/// Tick limit while running normally
#define TICK_BYOND_RESERVE 2
#define TICK_LIMIT_RUNNING (max(100 - TICK_BYOND_RESERVE - MAPTICK_LAST_INTERNAL_TICK_USAGE, MAPTICK_MC_MIN_RESERVE))
/// Tick limit used to resume things in stoplag
#define TICK_LIMIT_TO_RUN 70
/// Tick limit for MC while running
#define TICK_LIMIT_MC 70
/// Tick limit while initializing
#define TICK_LIMIT_MC_INIT_DEFAULT (100 - TICK_BYOND_RESERVE)
/// Бюджет CHECK_TICK вне МК (Topic, вербы, проснувшиеся проки), % тика, пока в раунде есть игроки: после МК - сверх уже занятого, с world/Tick() до МК следующего тика - от нуля.
#define TICK_LIMIT_OUTSIDE_MC_DEFAULT 25

/// Сколько % тика фоновые подсистемы вместе занимают за одну итерацию МК, пока в раунде есть игроки.
#define MC_BACKGROUND_TICK_BUDGET_DEFAULT 35
/// Кусок растянутого прохода мельче этого не дробится, % тика.
#define MC_PACE_MIN_SLICE 5
/// На какую долю своего интервала растягивается проход; дальше он добирается без ограничения темпа.
#define MC_PACE_INTERVAL_SHARE 0.5
/// То же для SS_KEEP_TIMING: следующий запуск ждёт 0.75 интервала от конца прохода, поэтому с запасом до четверти.
#define MC_PACE_INTERVAL_SHARE_KEEP_TIMING 0.2
/// Подсистемы с интервалом короче этого числа тиков не растягиваются.
#define MC_PACE_MIN_WAIT_TICKS 4

/// for general usage of tick_usage
#define TICK_USAGE world.tick_usage
/// to be used where the result isn't checked
#define TICK_USAGE_REAL world.tick_usage

/// Returns true if tick_usage is above the limit
#define TICK_CHECK ( TICK_USAGE > Master.current_ticklimit )

#define TICK_REMAINING_MS ((Master.current_ticklimit - TICK_USAGE) * world.tick_lag)

/// runs stoplag if tick_usage is above the limit
#define CHECK_TICK ( TICK_CHECK ? stoplag() : 0 )

/// Тик занят так, что stoplag() не будит уснувших: здесь уступает и то, что нельзя растягивать по бюджету вне МК (выстрел).
#define TICK_CHECK_RESUME ( TICK_USAGE > min(TICK_LIMIT_TO_RUN, Master.resume_ticklimit) )

/// Returns true if tick usage is above 95, for high priority usage
#define TICK_CHECK_HIGH_PRIORITY ( TICK_USAGE > 95 )
/// runs stoplag if tick_usage is above 95, for high priority usage
#define CHECK_TICK_HIGH_PRIORITY ( TICK_CHECK_HIGH_PRIORITY? stoplag() : 0 )
