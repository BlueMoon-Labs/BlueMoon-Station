/// Сколько % тика проба вне МК сжигает за проход.
#define OUTSIDE_MC_PROBE_WORK 300
/// Одна неделимая единица её работы, % тика.
#define OUTSIDE_MC_PROBE_UNIT 1
/// Сколько попыток проба делает, чтобы встать в очередь сна до или после МК.
#define OUTSIDE_MC_PROBE_WAIT_TICKS 50
/// На сколько % сверх TICK_LIMIT_MC проба занимает тик, чтобы МК его пропустил.
#define OUTSIDE_MC_PROBE_OVERLOAD 5
/// Не чаще раза за столько тиков: МК после пропуска спит дольше тика.
#define OUTSIDE_MC_PROBE_OVERLOAD_GAP_TICKS 8
/// Меньше тиков после нагруженного МК - замер ничего не доказывает.
#define OUTSIDE_MC_PROBE_MIN_LOADED_TICKS 3
/// Тик, занятый в начале больше этого %, проверкам порога не годится: им нужно куда расти.
#define OUTSIDE_MC_PROBE_QUIET 30
/// Сколько раз проба встаёт в очередь до МК, ища такой тик.
#define OUTSIDE_MC_PROBE_QUIET_ATTEMPTS 5
/// Запас порогов на вытеснение мира планировщиком ОС под чужой нагрузкой, % тика.
#define OUTSIDE_MC_PROBE_JITTER 5

/// Настройки предела вне МК и нагрузка МК на время теста. Тест получает его через allocate(): Destroy() вернёт всё и после упавшей проверки.
/datum/outside_mc_probe_guard
	var/old_outside_limit
	var/old_pacing_forced
	var/load_timer
	/// world.time последнего прогона МК, в котором нагрузка сработала: таймер срабатывает не в каждом.
	var/last_load_time

/datum/outside_mc_probe_guard/New()
	old_outside_limit = Master.outside_tick_limit
	old_pacing_forced = Master.pacing_forced

/datum/outside_mc_probe_guard/Destroy()
	set_mc_load(0)
	Master.outside_tick_limit = old_outside_limit
	Master.pacing_forced = old_pacing_forced
	Master.set_idle_ticklimit(TICK_LIMIT_RUNNING)
	return ..()

/// Пока МК работает, его прогон занимает тик не меньше чем до percent %: нагрузка вместо настоящих подсистем.
/datum/outside_mc_probe_guard/proc/set_mc_load(percent)
	deltimer(load_timer)
	load_timer = null
	if(percent > 0)
		load_timer = addtimer(CALLBACK(src, PROC_REF(burn_mc_load), percent), world.tick_lag, TIMER_LOOP | TIMER_STOPPABLE)

/datum/outside_mc_probe_guard/proc/burn_mc_load(percent)
	last_load_time = world.time
	burn_until(percent)

/datum/outside_mc_probe_guard/proc/burn_until(percent)
	while(TICK_USAGE_REAL < percent)
		continue

/**
 * Ставит прок в очередь сна до или после МК. BYOND будит уснувших в порядке засыпания, а МК спит по тику,
 * поэтому прок, уснувший на тик, просыпается с той же стороны от МК. Перейти за МК можно, только пока он спит дольше тика
 * (перегруженный тик он пропускает), а перед МК - проспав два тика.
 */
/datum/outside_mc_probe_guard/proc/take_queue_place(after_mc)
	var/last_overload = -INFINITY
	for(var/attempt in 1 to OUTSIDE_MC_PROBE_WAIT_TICKS)
		if(after_mc)
			sleep(world.tick_lag)
			if(Master.last_run == world.time)
				return TRUE
			if(world.time >= last_overload + OUTSIDE_MC_PROBE_OVERLOAD_GAP_TICKS * world.tick_lag)
				last_overload = world.time
				burn_until(TICK_LIMIT_MC + OUTSIDE_MC_PROBE_OVERLOAD)
			continue
		sleep(world.tick_lag * 2)
		var/woke_at = world.time
		if(Master.last_run == woke_at)
			continue
		sleep(world.tick_lag)
		if(Master.last_run == woke_at && Master.last_run != world.time)
			return TRUE
	return FALSE

/// Встаёт в очередь до МК в тик, занятый меньше OUTSIDE_MC_PROBE_QUIET: голый sleep() оставляет прок за МК, если тот проспал тик.
/datum/outside_mc_probe_guard/proc/take_quiet_tick()
	for(var/attempt in 1 to OUTSIDE_MC_PROBE_QUIET_ATTEMPTS)
		if(take_queue_place(FALSE) && TICK_USAGE_REAL < OUTSIDE_MC_PROBE_QUIET)
			return TRUE
	return FALSE

/**
 * Гонит OUTSIDE_MC_PROBE_WORK единиц работы с CHECK_TICK вне МК из очереди до или после него.
 * По тикам: list(занятость в начале, занятость в конце, сколько единиц, отработал ли МК в этом тике до пробы,
 * была ли нагрузка в последнем прогоне МК - он и выставил пробе предел, занятость в начале последней единицы); null - не встала в очередь.
 */
/datum/outside_mc_probe_guard/proc/run_probe(limit, after_mc)
	Master.outside_tick_limit = limit
	Master.pacing_forced = TRUE
	if(!take_queue_place(after_mc))
		return null
	var/list/ticks = list()
	var/work_left = OUTSIDE_MC_PROBE_WORK
	while(work_left > 0)
		var/tick_key = "[world.time]"
		var/list/record = ticks[tick_key]
		if(!record)
			record = list(TICK_USAGE_REAL, 0, 0, Master.last_run == world.time, last_load_time == Master.last_run, 0)
			ticks[tick_key] = record
		var/unit_started = TICK_USAGE_REAL
		record[6] = unit_started
		while(TICK_USAGE_REAL - unit_started < OUTSIDE_MC_PROBE_UNIT)
			continue
		work_left -= OUTSIDE_MC_PROBE_UNIT
		record[2] = TICK_USAGE_REAL
		record[3]++
		CHECK_TICK
	return ticks

/// Предел между прогонами МК: после МК - бюджет сверх занятого, с начала следующего тика - от нуля; без игроков - прежний.
/datum/unit_test/mc_idle_ticklimit_rules/Run()
	allocate(/datum/outside_mc_probe_guard)
	Master.outside_tick_limit = 25

	Master.pacing_forced = FALSE
	Master.set_idle_ticklimit(80, 60)
	TEST_ASSERT_EQUAL(Master.current_ticklimit, 60, "Без игроков в раунде бюджет вне МК не должен действовать: лобби и старт раунда идут прежним пределом")
	TEST_ASSERT_EQUAL(Master.next_tick_ticklimit, 0, "Без игроков следующий тик не должен получать свой предел")

	Master.pacing_forced = TRUE
	var/usage_before = TICK_USAGE_REAL
	Master.set_idle_ticklimit(usage_before + 60, 60)
	var/usage_after = TICK_USAGE_REAL
	TEST_ASSERT(Master.current_ticklimit >= usage_before + 25 && Master.current_ticklimit <= usage_after + 25, "После МК работа вне него обязана получить 25% сверх занятого, а не до 25% тика: предел [Master.current_ticklimit], занято [usage_before]")
	TEST_ASSERT_EQUAL(Master.resume_ticklimit, 60, "stoplag() обязан будить уснувших по пределу МК на следующий тик, иначе do_after и UNTIL растянутся")
	TEST_ASSERT_EQUAL(Master.next_tick_ticklimit, 25, "С начала следующего тика бюджет вне МК отсчитывается от нуля")
	Master.apply_next_tick_ticklimit()
	TEST_ASSERT_EQUAL(Master.current_ticklimit, 25, "Конец тика обязан выставить предел для проков до МК следующего тика")
	TEST_ASSERT_EQUAL(Master.next_tick_ticklimit, 0, "Предел следующего тика применяется один раз")

	var/cap = TICK_USAGE_REAL + 5
	Master.set_idle_ticklimit(cap, 20)
	TEST_ASSERT_EQUAL(Master.current_ticklimit, cap, "Бюджет вне МК не поднимает предел выше потолка тика")
	TEST_ASSERT_EQUAL(Master.next_tick_ticklimit, 20, "Предел МК на следующий тик ниже бюджета подниматься не должен")

	Master.outside_tick_limit = 0
	Master.set_idle_ticklimit(80, 60)
	TEST_ASSERT_EQUAL(Master.current_ticklimit, 60, "Нулевой бюджет вне МК обязан его выключать")
	TEST_ASSERT_EQUAL(Master.next_tick_ticklimit, 0, "Нулевой бюджет вне МК не трогает следующий тик")

/// stoplag() будит уснувший прок, только пока тик занят меньше предела МК и TICK_LIMIT_TO_RUN.
/datum/unit_test/stoplag_resume_rule/Run()
	var/datum/outside_mc_probe_guard/burner = allocate(/datum/outside_mc_probe_guard)
	TEST_ASSERT(burner.take_quiet_tick(), "Не нашлось тика до МК, занятого меньше [OUTSIDE_MC_PROBE_QUIET]%")
	var/base = TICK_USAGE_REAL
	Master.resume_ticklimit = base + 20
	TEST_ASSERT(!TICK_CHECK_RESUME, "stoplag() не будит прок в тике, занятом меньше предела МК")
	Master.resume_ticklimit = 100
	TEST_ASSERT(!TICK_CHECK_RESUME, "Предел МК выше TICK_LIMIT_TO_RUN не должен мешать проснуться в незанятом тике")
	Master.resume_ticklimit = base + 20
	burner.burn_until(base + 25)
	TEST_ASSERT(TICK_CHECK_RESUME, "stoplag() будит прок в тике, занятом сверх предела МК")
	Master.resume_ticklimit = 100
	burner.burn_until(TICK_LIMIT_TO_RUN + 2)
	TEST_ASSERT(TICK_CHECK_RESUME, "Тик, занятый сверх TICK_LIMIT_TO_RUN, никого не будит, какой бы ни был предел МК")

/// Сколько мс DM-работы проба держала тик: медиана и максимум по тикам, и сколько единиц делала за тик.
/datum/unit_test/proc/describe_outside_mc_probe(list/probe)
	var/list/held = list()
	var/units = 0
	for(var/tick_key in probe)
		var/list/record = probe[tick_key]
		held += TICK_DELTA_TO_MS(record[2] - record[1])
		units += record[3]
	sortTim(held, GLOBAL_PROC_REF(cmp_numeric_asc))
	return "[length(held)] тиков, [round(units / length(held), 0.1)] ед./тик, держала тик медиана [round(held[CEILING(length(held) / 2, 1)], 0.1)] мс, максимум [round(held[length(held)], 0.1)] мс"

/// Тики пробы с нужной стороны от МК, предел которым выставил нагруженный прогон МК: list(тиков, единиц, самый длинный кусок до начала последней единицы, самое позднее начало последней единицы, средняя занятость в начале), % тика.
/datum/unit_test/proc/loaded_probe_ticks(list/probe, after_mc)
	var/ticks = 0
	var/units = 0
	var/longest = 0
	var/latest_start = 0
	var/starts = 0
	for(var/tick_key in probe)
		var/list/record = probe[tick_key]
		if(record[4] != after_mc || !record[5])
			continue
		ticks++
		units += record[3]
		longest = max(longest, record[6] - record[1])
		latest_start = max(latest_start, record[6])
		starts += record[1]
	return list(ticks, units, longest, latest_start, ticks ? starts / ticks : 0)

/// Проки до МК (уснувшие в нём таймеры и подсистемы) получают бюджет от начала тика, а не остаток после МК прошлого тика.
/datum/unit_test/mc_outside_work_yields_early/Run()
	var/datum/outside_mc_probe_guard/guard = allocate(/datum/outside_mc_probe_guard)
	var/list/unlimited = guard.run_probe(0, FALSE)
	TEST_ASSERT(unlimited, "Проба не встала в очередь до МК")
	guard.set_mc_load(40)
	var/list/limited = guard.run_probe(TICK_LIMIT_OUTSIDE_MC_DEFAULT, FALSE)
	TEST_ASSERT(limited, "Проба не встала в очередь до МК под нагрузкой")
	var/list/loaded = loaded_probe_ticks(limited, FALSE)
	log_test("\tДо МК без бюджета: [describe_outside_mc_probe(unlimited)]; с бюджетом [TICK_LIMIT_OUTSIDE_MC_DEFAULT]% после МК на 40%: [describe_outside_mc_probe(limited)], из них после нагруженного МК [loaded[1]] тиков, последняя единица начата не позже [round(loaded[4], 0.1)]% тика")

	var/unlimited_peak = 0
	for(var/tick_key in unlimited)
		var/list/record = unlimited[tick_key]
		unlimited_peak = max(unlimited_peak, record[2])
	TEST_ASSERT(unlimited_peak > TICK_LIMIT_OUTSIDE_MC_DEFAULT + 10, "Без бюджета проба не держала тик дальше [TICK_LIMIT_OUTSIDE_MC_DEFAULT]%: замер ничего не меряет")
	TEST_ASSERT(loaded[4] <= TICK_LIMIT_OUTSIDE_MC_DEFAULT + OUTSIDE_MC_PROBE_JITTER, "Работа до МК тянула тик до [round(loaded[4], 0.1)]%: бюджет отсчитан от занятости прошлого тика, а не от начала этого")
	TEST_ASSERT(loaded[1] >= OUTSIDE_MC_PROBE_MIN_LOADED_TICKS, "Проба до МК после нагруженного МК прошла только [loaded[1]] тиков из [length(limited)]")

/// Работа после МК (Topic, вербы, проснувшиеся после него проки) получает свой бюджет сверх занятого МК, а не голодает по единице за тик.
/datum/unit_test/mc_outside_work_after_mc_gets_budget/Run()
	var/datum/outside_mc_probe_guard/guard = allocate(/datum/outside_mc_probe_guard)
	var/list/report = list()
	var/list/failures = list()
	for(var/mc_load in list(30, 40, 50))
		guard.set_mc_load(mc_load)
		var/list/probe = guard.run_probe(TICK_LIMIT_OUTSIDE_MC_DEFAULT, TRUE)
		if(!probe)
			failures += "проба не встала в очередь после МК при нагрузке [mc_load]%"
			continue
		var/list/loaded = loaded_probe_ticks(probe, TRUE)
		var/ticks = loaded[1]
		report += "МК [mc_load]%: [describe_outside_mc_probe(probe)]; после нагруженного МК (занято в начале [round(loaded[5], 0.1)]%) [ticks] тиков, [ticks ? round(loaded[2] / ticks, 0.1) : 0] ед./тик, последняя единица начата через [round(TICK_DELTA_TO_MS(loaded[3]), 0.1)] мс"
		if(ticks < OUTSIDE_MC_PROBE_MIN_LOADED_TICKS)
			failures += "при МК [mc_load]% после нагруженного МК только [ticks] тиков"
			continue
		if(loaded[2] / ticks < TICK_LIMIT_OUTSIDE_MC_DEFAULT / OUTSIDE_MC_PROBE_UNIT / 8)
			failures += "при МК [mc_load]% после МК [round(loaded[2] / ticks, 0.1)] ед. за тик"
		if(loaded[3] > TICK_LIMIT_OUTSIDE_MC_DEFAULT + OUTSIDE_MC_PROBE_JITTER)
			failures += "при МК [mc_load]% кусок поверх МК [round(loaded[3], 0.1)]% тика"
	log_test("\tПосле МК с бюджетом [TICK_LIMIT_OUTSIDE_MC_DEFAULT]%: [report.Join("; ")]")
	// Следующие тесты идут из этого же прока: возвращаем его в очередь до МК, где тесты бегут обычно
	guard.set_mc_load(0)
	if(!guard.take_queue_place(FALSE))
		failures += "раннер не вернулся в очередь до МК"
	TEST_ASSERT(!length(failures), "Работа после МК: [failures.Join("; ")]")

/// Расчёт блокировки взрыва при выбранном бюджете вне МК проходит пачку турфов за пробуждение и не теряет турфы, дописанные после того, как догнал список.
/datum/unit_test/explosion_block_batch_on_spent_budget/Run()
	var/datum/explosion/blast = new(null)
	var/z = run_loc_floor_bottom_left.z
	var/list/all_turfs = block(locate(1, 1, z), locate(10, 10, z))
	var/list/affected = all_turfs.Copy(1, 65)
	var/old_limit = Master.current_ticklimit
	Master.current_ticklimit = 0
	var/list/cache = blast.CaculateExplosionBlock(affected)
	Master.current_ticklimit = old_limit
	var/first_slice = length(cache)
	for(var/i in 1 to OUTSIDE_MC_PROBE_WAIT_TICKS)
		if(length(cache) >= length(affected))
			break
		sleep(world.tick_lag)
	sleep(world.tick_lag * 3)
	affected += all_turfs.Copy(65)
	for(var/i in 1 to OUTSIDE_MC_PROBE_WAIT_TICKS)
		if(length(cache) >= length(affected))
			break
		sleep(world.tick_lag)
	var/cached_count = length(cache)
	blast.running = FALSE
	qdel(blast)
	TEST_ASSERT(first_slice > 1, "Расчёт блокировки при выбранном бюджете прошёл [first_slice] турф за пробуждение: реакционный взрыв растёт по турфу за тик")
	TEST_ASSERT_EQUAL(cached_count, length(affected), "Расчёт блокировки пропустил турфы, дописанные после того, как догнал список")

/// Выстрел hitscan доходит за один тик и при выбранном бюджете вне МК: уступает он, только когда тик занят по-настоящему.
/datum/unit_test/hitscan_ignores_spent_outside_budget/Run()
	var/datum/outside_mc_probe_guard/guard = allocate(/datum/outside_mc_probe_guard)
	var/obj/item/projectile/beam/emitter/hitscan/shot = new(run_loc_floor_bottom_left)
	TEST_ASSERT(guard.take_quiet_tick(), "Не нашлось тика до МК, занятого меньше [OUTSIDE_MC_PROBE_QUIET]%")
	var/old_limit = Master.current_ticklimit
	Master.current_ticklimit = 0
	shot.fire(90)
	Master.current_ticklimit = old_limit
	TEST_ASSERT(QDELETED(shot), "Выстрел hitscan уступил тик из-за бюджета вне МК и не долетел за один вызов")

/// Загрузка комнаты отеля держит свой кусок в мс и при выбранном бюджете вне МК.
/datum/unit_test/hilbert_slice_ignores_spent_outside_budget/Run()
	var/datum/outside_mc_probe_guard/guard = allocate(/datum/outside_mc_probe_guard)
	TEST_ASSERT(guard.take_quiet_tick(), "Не нашлось тика до МК, занятого меньше [OUTSIDE_MC_PROBE_QUIET]%")
	var/datum/hilbert_room_load/load = new(null)
	var/old_limit = Master.current_ticklimit
	Master.current_ticklimit = 0
	load.check_slice()
	Master.current_ticklimit = old_limit
	TEST_ASSERT_EQUAL(load.yields, 0, "Загрузка комнаты уступила тик, не выбрав свой кусок")
	qdel(load)

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
#undef OUTSIDE_MC_PROBE_OVERLOAD
#undef OUTSIDE_MC_PROBE_OVERLOAD_GAP_TICKS
#undef OUTSIDE_MC_PROBE_MIN_LOADED_TICKS
#undef OUTSIDE_MC_PROBE_QUIET
#undef OUTSIDE_MC_PROBE_QUIET_ATTEMPTS
#undef OUTSIDE_MC_PROBE_JITTER
