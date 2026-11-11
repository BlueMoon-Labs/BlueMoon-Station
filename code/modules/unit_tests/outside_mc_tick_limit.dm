/// Сколько % тика проба вне МК сжигает за проход.
#define OUTSIDE_MC_PROBE_WORK 300
/// Одна неделимая единица её работы, % тика.
#define OUTSIDE_MC_PROBE_UNIT 1
/// Сколько тиков проба ждёт, пока МК выставит предел.
#define OUTSIDE_MC_PROBE_WAIT_TICKS 50

/// Предел между прогонами МК: в раунде с игроками режется до предела вне МК, будить уснувших stoplag() продолжает по прежнему.
/datum/unit_test/mc_idle_ticklimit_rules/Run()
	var/old_forced = Master.pacing_forced
	var/old_limit = Master.outside_tick_limit
	Master.outside_tick_limit = 25

	Master.pacing_forced = FALSE
	Master.set_idle_ticklimit(80)
	TEST_ASSERT_EQUAL(Master.current_ticklimit, 80, "Без игроков в раунде предел вне МК не должен действовать: лобби и старт раунда идут полным тиком")

	Master.pacing_forced = TRUE
	Master.set_idle_ticklimit(80)
	TEST_ASSERT_EQUAL(Master.current_ticklimit, 25, "В раунде с игроками CHECK_TICK вне МК обязан уступать тик на своём пределе")
	TEST_ASSERT_EQUAL(Master.resume_ticklimit, 80, "stoplag() обязан будить уснувших по пределу МК, иначе do_after и UNTIL растянутся")
	Master.set_idle_ticklimit(20)
	TEST_ASSERT_EQUAL(Master.current_ticklimit, 20, "Предел МК ниже предела вне МК подниматься не должен")

	Master.outside_tick_limit = 0
	Master.set_idle_ticklimit(80)
	TEST_ASSERT_EQUAL(Master.current_ticklimit, 80, "Нулевой предел вне МК обязан его выключать")

	Master.outside_tick_limit = old_limit
	Master.pacing_forced = old_forced
	Master.set_idle_ticklimit(TICK_LIMIT_RUNNING)

/// Гонит работу с CHECK_TICK вне МК. По тикам: с какой занятости начала, на какой кончила и с какой начинала единицы после первой.
/datum/unit_test/proc/run_outside_mc_probe(limit)
	var/old_limit = Master.outside_tick_limit
	var/old_forced = Master.pacing_forced
	Master.outside_tick_limit = limit
	Master.pacing_forced = TRUE
	var/waited = 0
	while(waited < OUTSIDE_MC_PROBE_WAIT_TICKS && (limit ? Master.current_ticklimit > limit : Master.current_ticklimit <= TICK_LIMIT_OUTSIDE_MC_DEFAULT))
		sleep(world.tick_lag)
		waited++
	var/list/starts = list()
	var/list/ends = list()
	var/list/late_starts = list()
	var/work_left = OUTSIDE_MC_PROBE_WORK
	var/spins = 0
	while(work_left > 0)
		var/tick_key = "[world.time]"
		var/unit_started = TICK_USAGE_REAL
		if(isnull(starts[tick_key]))
			starts[tick_key] = unit_started
		else
			late_starts[tick_key] = max(late_starts[tick_key], unit_started)
		while(TICK_USAGE_REAL - unit_started < OUTSIDE_MC_PROBE_UNIT)
			spins++
		work_left -= OUTSIDE_MC_PROBE_UNIT
		ends[tick_key] = TICK_USAGE_REAL
		CHECK_TICK
	Master.pacing_forced = old_forced
	Master.outside_tick_limit = old_limit
	return list(starts, ends, late_starts)

/// Сколько мс DM-работы проба держала тик: медиана и максимум по тикам.
/datum/unit_test/proc/describe_outside_mc_probe(list/probe)
	var/list/starts = probe[1]
	var/list/ends = probe[2]
	var/list/held = list()
	for(var/tick_key in ends)
		held += TICK_DELTA_TO_MS(ends[tick_key] - starts[tick_key])
	sortTim(held, GLOBAL_PROC_REF(cmp_numeric_asc))
	return "[length(held)] тиков, держала тик медиана [round(held[CEILING(length(held) / 2, 1)], 0.1)] мс, максимум [round(held[length(held)], 0.1)] мс"

/// Работа вне МК (Topic, вербы, проснувшиеся проки) в раунде с игроками уступает тик на пределе вне МК, а не держит его до конца.
/datum/unit_test/mc_outside_work_yields_early/Run()
	var/list/unlimited = run_outside_mc_probe(0)
	var/list/limited = run_outside_mc_probe(TICK_LIMIT_OUTSIDE_MC_DEFAULT)
	log_test("\tБез предела: [describe_outside_mc_probe(unlimited)]; с пределом [TICK_LIMIT_OUTSIDE_MC_DEFAULT]%: [describe_outside_mc_probe(limited)]")

	var/unlimited_peak = 0
	var/list/unlimited_late = unlimited[3]
	for(var/tick_key in unlimited_late)
		unlimited_peak = max(unlimited_peak, unlimited_late[tick_key])
	TEST_ASSERT(unlimited_peak > TICK_LIMIT_OUTSIDE_MC_DEFAULT + 10, "Без предела проба не держала тик дальше [TICK_LIMIT_OUTSIDE_MC_DEFAULT]%: замер ничего не меряет")

	var/list/limited_late = limited[3]
	var/list/overruns = list()
	for(var/tick_key in limited_late)
		if(limited_late[tick_key] > TICK_LIMIT_OUTSIDE_MC_DEFAULT + OUTSIDE_MC_PROBE_UNIT)
			overruns += "[tick_key]: [round(limited_late[tick_key], 0.1)]%"
	TEST_ASSERT(!length(overruns), "Работа вне МК продолжала тик после предела [TICK_LIMIT_OUTSIDE_MC_DEFAULT]%: [overruns.Join(", ")]")
	var/list/limited_ticks = limited[2]
	TEST_ASSERT(length(limited_ticks) >= OUTSIDE_MC_PROBE_WORK / TICK_LIMIT_OUTSIDE_MC_DEFAULT / 2, "Проба на [OUTSIDE_MC_PROBE_WORK]% тика уложилась в [length(limited_ticks)] тиков")

/// Медленный Topic пишется в кольцо медленной работы, а уснувший - нет: его разность TICK_USAGE взята по двум разным тикам.
/datum/unit_test/slow_topic_after_sleep_skipped/Run()
	var/started = TICK_USAGE - 200
	record_slow_topic("unit_test_ckey", started, world.time, "unit_test_same_tick", "test")
	record_slow_topic("unit_test_ckey", started, world.time - world.tick_lag, "unit_test_after_sleep", "test")
	var/same_tick_found = FALSE
	var/after_sleep_found = FALSE
	for(var/desc in SStick_spikes.slow_work_desc)
		if(desc == "unit_test_ckey: unit_test_same_tick")
			same_tick_found = TRUE
		else if(desc == "unit_test_ckey: unit_test_after_sleep")
			after_sleep_found = TRUE
	TEST_ASSERT(same_tick_found, "Медленный Topic без сна не попал в кольцо медленной работы")
	TEST_ASSERT(!after_sleep_found, "Уснувший Topic записан ценой чужой работы тика пробуждения")

#undef OUTSIDE_MC_PROBE_WORK
#undef OUTSIDE_MC_PROBE_UNIT
#undef OUTSIDE_MC_PROBE_WAIT_TICKS
