/// Сколько % тика пробная подсистема сжигает за один проход.
#define MC_PACE_PROBE_WORK 150
/// Одна неделимая единица её работы, % тика.
#define MC_PACE_PROBE_UNIT 1
/// Сколько тиков тест ждёт конца прохода.
#define MC_PACE_PROBE_TIMEOUT_TICKS 400

/// Фоновая подсистема, которая жжёт заданную долю тика и записывает, какими кусками МК дал ей это сделать.
SUBSYSTEM_DEF(mc_pace_probe)
	name = "MC Pace Probe"
	flags = SS_BACKGROUND | SS_NO_INIT
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	wait = 1 SECONDS
	can_fire = FALSE
	var/work_left = 0
	var/passes_done = 0
	var/list/slice_usages = list()
	var/list/slice_times = list()

/datum/controller/subsystem/mc_pace_probe/fire(resumed)
	if(!resumed)
		work_left = can_fire ? MC_PACE_PROBE_WORK : 0
	var/started = TICK_USAGE_REAL
	var/spins = 0
	while(work_left > 0)
		var/unit_started = TICK_USAGE_REAL
		while(TICK_USAGE_REAL - unit_started < MC_PACE_PROBE_UNIT)
			spins++
		work_left -= MC_PACE_PROBE_UNIT
		if(MC_TICK_CHECK)
			break
	slice_usages += TICK_USAGE_REAL - started
	slice_times += world.time
	if(work_left <= 0)
		passes_done++

/// Запускает один проход пробы под заданными ограничениями МК и возвращает, сколько % тика она заняла в каждом тике.
/datum/unit_test/proc/run_pace_probe(budget, pace)
	var/datum/controller/subsystem/mc_pace_probe/probe = SSmc_pace_probe
	var/old_budget = Master.background_tick_budget
	var/old_pace = Master.pace_passes
	Master.background_tick_budget = budget
	Master.pace_passes = pace
	Master.pacing_forced = TRUE
	probe.slice_usages = list()
	probe.slice_times = list()
	probe.passes_done = 0
	probe.tick_usage = MC_PACE_PROBE_WORK
	probe.can_fire = TRUE
	probe.next_fire = world.time
	var/waited = 0
	while(!probe.passes_done && waited < MC_PACE_PROBE_TIMEOUT_TICKS)
		sleep(world.tick_lag)
		waited++
	probe.can_fire = FALSE
	probe.work_left = 0
	Master.pacing_forced = FALSE
	Master.background_tick_budget = old_budget
	Master.pace_passes = old_pace
	TEST_ASSERT(probe.passes_done, "Проба не закончила проход за [MC_PACE_PROBE_TIMEOUT_TICKS] тиков")
	// МК может дать подсистеме два захода за итерацию, пока её доля не выбрана: считаем по тикам.
	var/list/per_tick = list()
	var/last_time
	for(var/i in 1 to length(probe.slice_usages))
		if(probe.slice_times[i] == last_time)
			per_tick[length(per_tick)] += probe.slice_usages[i]
		else
			per_tick += probe.slice_usages[i]
		last_time = probe.slice_times[i]
	return per_tick

/// Темп прохода считается от средней цены и интервала и снимается, когда проход засиделся в очереди.
/datum/unit_test/mc_paced_slice_math/Run()
	var/interval = 10 * world.tick_lag
	TEST_ASSERT_EQUAL(Master.paced_slice(SS_BACKGROUND, interval, 60, 0), 12, "Проход на 60% тика при интервале 10 тиков должен идти по 12% за тик")
	TEST_ASSERT_EQUAL(Master.paced_slice(SS_BACKGROUND, interval, 10, 0), MC_PACE_MIN_SLICE, "Дешёвый проход не дробится мельче минимального куска")
	TEST_ASSERT_NULL(Master.paced_slice(SS_BACKGROUND, interval, 60, interval * MC_PACE_INTERVAL_SHARE), "После своей доли интервала проход добирается без ограничения темпа")
	TEST_ASSERT_EQUAL(Master.paced_slice(SS_KEEP_TIMING, 40 * world.tick_lag, 80, 0), 10, "SS_KEEP_TIMING укладывается в пятую часть интервала")
	TEST_ASSERT_NULL(Master.paced_slice(SS_KEEP_TIMING, 40 * world.tick_lag, 80, 8 * world.tick_lag), "SS_KEEP_TIMING добирает после пятой части интервала")
	TEST_ASSERT_NULL(Master.paced_slice(SS_BACKGROUND | SS_POST_FIRE_TIMING, interval, 60, 0), "Отсчёт от конца прохода: растягивание удлинило бы период")
	TEST_ASSERT_NULL(Master.paced_slice(SS_BACKGROUND | SS_TICKER, interval, 60, 0), "SS_TICKER не растягивается")
	TEST_ASSERT_NULL(Master.paced_slice(SS_NO_TICK_CHECK, interval, 60, 0), "Подсистема без уступки тика не растягивается")
	TEST_ASSERT_NULL(Master.paced_slice(SS_BACKGROUND, (MC_PACE_MIN_WAIT_TICKS - 1) * world.tick_lag, 60, 0), "Короткий интервал растягивать некуда")

/// Фоновый проход на полтора тика размазывается по тикам, а не съедает остаток одного-двух.
/datum/unit_test/mc_background_pass_is_paced/Run()
	var/list/usages = run_pace_probe(30, TRUE)
	TEST_ASSERT(length(usages) >= 5, "Проход на [MC_PACE_PROBE_WORK]% тика уложился в [length(usages)] тиков: [usages.Join(", ")]")
	var/list/sorted = sortTim(usages.Copy(), GLOBAL_PROC_REF(cmp_numeric_asc))
	var/median = sorted[CEILING(length(sorted) / 2, 1)]
	TEST_ASSERT(median <= 22, "Медиана за тик [median]% при темпе 15%: [usages.Join(", ")]")

/// Без растягивания работает общий потолок фоновой работы на тик.
/datum/unit_test/mc_background_budget_caps_slice/Run()
	var/list/usages = run_pace_probe(20, FALSE)
	TEST_ASSERT(length(usages) >= 5, "Проход на [MC_PACE_PROBE_WORK]% тика при потолке 20% уложился в [length(usages)] тиков: [usages.Join(", ")]")
	var/list/sorted = sortTim(usages.Copy(), GLOBAL_PROC_REF(cmp_numeric_asc))
	var/median = sorted[CEILING(length(sorted) / 2, 1)]
	TEST_ASSERT(median <= 27, "Медиана за тик [median]% при потолке 20%: [usages.Join(", ")]")

/// Клапан замедлил каденс атмоса - темп прохода всё равно считается от номинального интервала.
/datum/unit_test/atmos_pace_interval_ignores_valve/Run()
	var/old_wait = SSair.wait
	var/nominal = SSair.cadence_for_valve(1)
	SSair.wait = nominal * 2
	TEST_ASSERT_EQUAL(SSair.pace_interval(), nominal, "Растянутый клапаном интервал попал в темп прохода")
	SSair.wait = old_wait

#undef MC_PACE_PROBE_WORK
#undef MC_PACE_PROBE_UNIT
#undef MC_PACE_PROBE_TIMEOUT_TICKS
