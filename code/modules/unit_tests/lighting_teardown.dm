/**
 * Снос света у долго пустующего отложенного z-уровня.
 *
 * Отложенный уровень (резервация, шахта, эвей-миссия, VR) поднимает свет при первом
 * посетителе и раньше не отпускал его никогда. Измерено по шести раундам 24.08: один
 * лаваландский z - это 167-253 МБ и 66 300 объектов света. Раунд 10114 держал 301 505
 * объектов против обычных 198-213 тысяч и упёрся в потолок адресного пространства на
 * 61-й минуте. Здесь проверяется, что снос действительно возвращает уровень в
 * доинициализационное состояние И что обратный подъём после него работает.
 *
 * Тесты гоняют фазы подсистемы напрямую, поэтому обязаны подменять SSlighting.state:
 * MC_TICK_CHECK внутри фаз читает `src.state != SS_RUNNING` и на SS_IDLE выходит из
 * первого же среза, ничего не сделав. State восстанавливается до ассертов - TEST_ASSERT
 * делает return, и код после упавшего ассерта не выполнится.
 */

/**
 * Оставляет зажжёнными ровно перечисленные z-уровни, гася флаг у всех остальных.
 *
 * Нужен всем тестам выбора кандидата: срок простоя зависит от того, сколько отложенных
 * уровней горит ВСЕГО (см. LIGHTING_MAX_LIT_DEFERRED_Z), а это цифра живого мира - на
 * разных картах и в разном порядке тестов она разная. Без изоляции проверка "свежий
 * уровень не берут" проходила бы на одной карте и падала на другой.
 *
 * Возвращает снимок для restore_lit_deferred_zlevels(). Восстанавливать ОБЯЗАТЕЛЬНО до
 * ассертов: TEST_ASSERT делает return.
 */
/datum/unit_test/proc/isolate_lit_deferred_zlevels(list/keep_z)
	var/list/snapshot = list()
	for(var/datum/space_level/level as anything in SSmapping.z_list)
		snapshot["[level.z_value]"] = level.lighting_initialized
		if(!(level.z_value in keep_z))
			level.lighting_initialized = FALSE
	return snapshot

/// Потолок адресного пространства для тестов давления: замеренный в CI может быть нулём.
#define LIGHTING_TEST_PRESSURE_CEILING_MB 4000

/// Ставит замеренное давление памяти на долю потолка. Снимок отдаёт первый вызов.
/datum/unit_test/proc/force_memory_pressure(fraction)
	var/list/snapshot = list(
		"ceiling" = SStime_track.process_address_ceiling_mb,
		"vsz" = SStime_track.memory_last_vsz_mb,
	)
	SStime_track.process_address_ceiling_mb = LIGHTING_TEST_PRESSURE_CEILING_MB
	SStime_track.memory_last_vsz_mb = LIGHTING_TEST_PRESSURE_CEILING_MB * fraction
	return snapshot

/// Возвращает замер давления, снятый force_memory_pressure().
/datum/unit_test/proc/restore_memory_pressure(list/snapshot)
	SStime_track.process_address_ceiling_mb = snapshot["ceiling"]
	SStime_track.memory_last_vsz_mb = snapshot["vsz"]

/// Возвращает флаги поднятости, снятые isolate_lit_deferred_zlevels().
/datum/unit_test/proc/restore_lit_deferred_zlevels(list/snapshot)
	for(var/datum/space_level/level as anything in SSmapping.z_list)
		var/saved = snapshot["[level.z_value]"]
		if(!isnull(saved))
			level.lighting_initialized = saved

/// Прокручивает снос до конца (или до заявленного лимита срезов), удерживая подсистему
/// в состоянии SS_RUNNING. Возвращает число потраченных срезов.
/datum/unit_test/proc/drive_lighting_teardown(max_slices = 4000)
	var/saved_can_fire = detach_subsystem(SSlighting)
	var/slices = 0
	while(SSlighting.teardown_zlevel && slices < max_slices)
		SSlighting.state = SS_RUNNING
		SSlighting.process_zlevel_lighting_teardown()
		slices++
		CHECK_TICK
	release_subsystem(SSlighting, saved_can_fire)
	return slices

/**
 * Предикат отсрочки обязан покрывать эвей-миссии и VR.
 *
 * Оба уровня несут ZTRAIT_AWAY, а отсрочка раньше знала только про ZTRAIT_MINING и
 * ZTRAIT_RESERVED - то есть свет им строился на инициализации мира наравне со станцией,
 * хотя на старте раунда туда не заходит никто. Содержимое разбросано восьмикратно:
 * Academy - 10 402 движимых, ihategordon - 88 942.
 */
/datum/unit_test/lighting_deferred_covers_away_levels
	requires_full_map = FALSE

/datum/unit_test/lighting_deferred_covers_away_levels/Run()
	var/datum/space_level/probe = allocate(/datum/space_level, 1, "проверочный уровень", list())
	TEST_ASSERT(!zlevel_lighting_deferred(probe), "уровень без трейтов не должен откладываться")

	probe.traits = list(ZTRAIT_AWAY = TRUE)
	TEST_ASSERT(zlevel_lighting_deferred(probe), "эвей-миссия обязана откладывать свет до первого посетителя")

	probe.traits = list(ZTRAIT_VIRTUAL_REALITY = TRUE, ZTRAIT_AWAY = TRUE)
	TEST_ASSERT(zlevel_lighting_deferred(probe), "VR обязан откладывать свет: он несёт ZTRAIT_AWAY")

	probe.traits = list(ZTRAIT_MINING = TRUE)
	TEST_ASSERT(zlevel_lighting_deferred(probe), "шахтёрский уровень обязан откладывать свет")

	probe.traits = list(ZTRAIT_RESERVED = TRUE)
	TEST_ASSERT(zlevel_lighting_deferred(probe), "резервация обязана откладывать свет")

	probe.traits = list(ZTRAIT_STATION = TRUE)
	TEST_ASSERT(!zlevel_lighting_deferred(probe), "станция обязана получать свет сразу - её видят с первой секунды")

	TEST_ASSERT(!zlevel_lighting_deferred(null), "null не должен считаться отложенным уровнем")

/// Выбор кандидата: уровень берётся, только когда давление дошло до порога, а сам уровень отложенный, поднятый и пустует дольше срока.
/datum/unit_test/lighting_teardown_candidate_selection

/datum/unit_test/lighting_teardown_candidate_selection/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)
	TEST_ASSERT_NOTNULL(level, "нет датума тестового z-уровня")
	TEST_ASSERT(zlevel_lighting_deferred(level), "предпосылка: тестовый z обязан быть отложенным уровнем")

	var/old_init = level.lighting_initialized
	var/old_teardown = SSlighting.teardown_zlevel
	var/list/saved_empty = SSlighting.zlevel_empty_since.Copy()
	// Отметки подъёма гасим на время проверки: свет тестового z поднимает сам харнес
	// (unit_test.dm зовёт create_lighting_for_zlevel перед каждым тестом), и кулдаун
	// LIGHTING_TEARDOWN_MIN_LIT_TIME иначе снимает уровень с кандидатов законно, а
	// проверка таймера простоя падала бы как поломка. Кулдаун проверяется ниже отдельно.
	var/list/saved_lit_since = SSlighting.zlevel_lit_since.Copy()
	SSlighting.zlevel_lit_since = list()
	var/list/saved_pressure = force_memory_pressure(LIGHTING_TEARDOWN_PRESSURE_HIGH + 0.05)
	var/list/saved_ledger = SSlighting.zlevel_teardown_payoff.Copy()
	SSlighting.zlevel_teardown_payoff = list()
	var/list/saved_traits = level.traits
	var/key = "[test_z]"

	// Тестовый z - резервация, а её сносить нельзя (её постоянно перерабатывают шаттлы,
	// см. zlevel_lighting_teardownable). На время проверки выдаём уровню шахтёрский трейт:
	// именно такие уровни механизм и разбирает.
	level.traits = list(ZTRAIT_MINING = TRUE)
	// Проверка про ТАЙМЕР, а таймер работает, только пока зажжённых отложенных уровней не
	// больше кванта. Гасим остальные, иначе на карте с тремя такими уровнями свежий
	// кандидат забирался бы по кванту и первый ассерт падал бы без всякой поломки.
	var/list/saved_lit = isolate_lit_deferred_zlevels(list(test_z))

	// 1. Свежеопустевший уровень не берут: сначала засекается время.
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since = list()
	level.lighting_initialized = TRUE
	SSlighting.scan_teardown_candidates()
	var/picked_too_early = SSlighting.teardown_zlevel
	var/timer_started = !isnull(SSlighting.zlevel_empty_since[key])

	// 2. Пустует дольше порога - берут, и уровень сразу помечается неподнятым, чтобы
	//    вошедший игрок мог поднять его штатным путём прямо посреди сноса.
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since[key] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.scan_teardown_candidates()
	var/picked_when_stale = SSlighting.teardown_zlevel
	var/cleared_init_flag = !level.lighting_initialized
	var/dropped_timer = isnull(SSlighting.zlevel_empty_since[key])
	SSlighting.abort_zlevel_lighting_teardown()

	// 2b. Под гейтом давления снос не запускается, но отметку простоя скан обязан завести.
	level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since -= key
	force_memory_pressure(LIGHTING_TEARDOWN_PRESSURE_HIGH - 0.05)
	SSlighting.scan_teardown_candidates()
	var/timer_started_under_gate = !isnull(SSlighting.zlevel_empty_since[key])
	SSlighting.zlevel_empty_since[key] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.scan_teardown_candidates()
	var/picked_under_gate = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()
	force_memory_pressure(LIGHTING_TEARDOWN_PRESSURE_HIGH + 0.05)

	// 2c. Пауза между сносами: после финала уровень не берётся, по её истечении и под критикой - берётся.
	level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since[key] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	var/saved_last_finished = SSlighting.last_teardown_finished_at
	SSlighting.last_teardown_finished_at = world.time
	SSlighting.scan_teardown_candidates()
	var/picked_during_spacing = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()
	level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since[key] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	force_memory_pressure(LIGHTING_TEARDOWN_PRESSURE_CRITICAL)
	SSlighting.scan_teardown_candidates()
	var/picked_during_spacing_critical = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()
	force_memory_pressure(LIGHTING_TEARDOWN_PRESSURE_HIGH + 0.05)
	level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since[key] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.last_teardown_finished_at = world.time - LIGHTING_TEARDOWN_SPACING
	SSlighting.scan_teardown_candidates()
	var/picked_after_spacing = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.last_teardown_finished_at = saved_last_finished

	// 3. Только что поднятый уровень не кандидат, даже если пустует дольше порога: иначе
	//    пролетевший гост заводит цикл "поднял - снесли - поднял" (раунд 10126, 42 подъёма).
	level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since[key] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.zlevel_lit_since[key] = world.time
	SSlighting.scan_teardown_candidates()
	var/picked_during_cooldown = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.zlevel_lit_since = list()

	// 4. Поднятый, но НЕ отложенный уровень не кандидат никогда: поднять его обратно нечем.
	level.lighting_initialized = TRUE
	level.traits = list()
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since[key] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.scan_teardown_candidates()
	var/picked_non_deferred = SSlighting.teardown_zlevel
	var/forgot_non_deferred = isnull(SSlighting.zlevel_empty_since[key])

	// 5. Резервацию не сносим никогда, хотя откладывать её на старте и правильно.
	level.lighting_initialized = TRUE
	level.traits = list(ZTRAIT_RESERVED = TRUE)
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since[key] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.scan_teardown_candidates()
	var/picked_reservation = SSlighting.teardown_zlevel
	level.traits = saved_traits

	SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.teardown_zlevel = old_teardown
	SSlighting.zlevel_empty_since = saved_empty
	SSlighting.zlevel_lit_since = saved_lit_since
	SSlighting.zlevel_teardown_payoff = saved_ledger
	restore_memory_pressure(saved_pressure)
	restore_lit_deferred_zlevels(saved_lit)
	level.lighting_initialized = old_init

	TEST_ASSERT(!picked_too_early, "уровень взяли на снос в ту же секунду, как он опустел (выбран z[picked_too_early])")
	TEST_ASSERT(timer_started, "таймер простоя не засёкся")
	TEST_ASSERT_EQUAL(picked_when_stale, test_z, "уровень, пустующий дольше порога, не взяли на снос")
	TEST_ASSERT(cleared_init_flag, "снос не снял lighting_initialized - вошедший игрок остался бы в темноте без пути наверх")
	TEST_ASSERT(dropped_timer, "таймер простоя не сброшен при старте сноса")
	TEST_ASSERT(!picked_under_gate, "снос запустился при давлении под порогом (взят z[picked_under_gate]) - рычаг не работает, качание продолжится")
	TEST_ASSERT(timer_started_under_gate, "скан под гейтом не завёл отметку простоя - гейт обязан стоять ПОСЛЕ учёта, иначе уровень получит отсрочку на ровном месте")
	TEST_ASSERT(!picked_during_spacing, "уровень взяли на снос сразу после финала прошлого сноса (z[picked_during_spacing]) - пауза между сносами не работает, при открытии гейта уровни уйдут под снос подряд")
	TEST_ASSERT_EQUAL(picked_during_spacing_critical, test_z, "под критическим давлением пауза между сносами обязана сниматься")
	TEST_ASSERT_EQUAL(picked_after_spacing, test_z, "по истечении паузы между сносами просроченный уровень обязан браться")
	TEST_ASSERT(!picked_during_cooldown, "на снос взяли уровень, поднятый секунду назад (z[picked_during_cooldown]) - кулдаун не работает")
	TEST_ASSERT(!picked_non_deferred, "на снос взяли уровень, который не умеем поднимать обратно (z[picked_non_deferred])")
	TEST_ASSERT(forgot_non_deferred, "неотложенный уровень остался с записью в таймере простоя")
	TEST_ASSERT(!picked_reservation, "на снос взяли резервацию - её перерабатывают шаттлы, снос гонялся бы со стыковкой")

/// Снос возвращает уровень в доинициализационное состояние, а обратный подъём его восстанавливает.
/datum/unit_test/lighting_teardown_releases_and_restores
	priority = TEST_LONGER

/datum/unit_test/lighting_teardown_releases_and_restores/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)
	TEST_ASSERT(zlevel_lighting_deferred(level), "предпосылка: тестовый z обязан быть отложенным уровнем")

	var/old_init = level.lighting_initialized
	var/old_teardown = SSlighting.teardown_zlevel
	var/list/saved_empty = SSlighting.zlevel_empty_since.Copy()
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()
	// Снос дойдёт до фазы 3 и запишет в книгу отдачи замер этого прогона. Замер честный, но
	// он про тестовый уровень с одним эмиттером, и оставлять его в общем состоянии нельзя:
	// книга живёт до конца раунда и запирает следующий снос уровня (см.
	// LIGHTING_TEARDOWN_MIN_PAYOFF_MB), то есть протёк бы в соседние тесты как молчаливый отказ.
	var/list/saved_payoff = SSlighting.zlevel_teardown_payoff.Copy()
	var/list/saved_traits = level.traits
	// Тестовый z - резервация, куда стыкуются шаттлы; на время проверки выдаём ему
	// шахтёрский трейт, чтобы механизм работал ровно в тех условиях, для которых написан.
	level.traits = list(ZTRAIT_MINING = TRUE)

	// "Уровень пуст" - это предусловие, а не данность: тестовый z общий на весь прогон, и
	// соседние тесты оставляют в реестрах z-уровней своих мобов. Снимаем их на время
	// проверки и возвращаем до ассертов.
	var/list/saved_clients = (test_z <= length(SSmobs.clients_by_zlevel)) ? SSmobs.clients_by_zlevel[test_z] : null
	var/list/saved_dead = (test_z <= length(SSmobs.dead_players_by_zlevel)) ? SSmobs.dead_players_by_zlevel[test_z] : null
	if(saved_clients)
		SSmobs.clients_by_zlevel[test_z] = list()
	if(saved_dead)
		SSmobs.dead_players_by_zlevel[test_z] = list()

	// Уровень поднят, на нём живой источник и объект света под ним. Углы создаются не
	// в set_light(), а при обработке очереди источников (update_corners ->
	// generate_missing_corners), поэтому очередь надо сдренить - иначе у турфа есть
	// объект света, но нет ни одного угла, и сносить в фазе 2 будет нечего.
	// Резервация лежит в /area/space, а тот динамически освещён только при включённом
	// starlight (DYNAMIC_LIGHTING_IFSTARLIGHT) - в CI-конфиге он выключен, и подъём уровня
	// объекта света такому турфу не даёт вовсе. Проверяемый путь - снос и возврат объекта -
	// живёт только на динамически освещённом турфе, поэтому турф на время теста переезжает
	// в свою зону с динамическим светом, а в конце возвращается обратно.
	var/area/original_area = get_area(test_turf)
	var/area/dynamic_area = new /area
	claim_floor_into_area(test_turf, dynamic_area)

	// Тестовый z общий на весь прогон: к этому моменту его мог начать сносить сам
	// SSlighting или строить фоновый краулер. Оба гасим и поднимаем уровень заново с
	// чистого флага - фаза 0 пропускает турфы с готовым объектом, так что повторный
	// проход по уже поднятому уровню ничего не ломает.
	SSlighting.abort_zlevel_lighting_teardown()
	if(SSlighting.bg_current_zlevel == test_z)
		SSlighting.bg_current_zlevel = 0
		SSlighting.bg_turfs = null
		SSlighting.bg_phase = 0
	level.lighting_initialized = FALSE
	create_lighting_for_zlevel(test_z)
	var/obj/effect/light_emitter/emitter = allocate(/obj/effect/light_emitter, test_turf)
	emitter.set_light(3, 1, COLOR_WHITE)
	drain_lighting_queues_snapshot()
	var/precond_has_source = !isnull(emitter.light)
	var/precond_has_object = !isnull(test_turf.lighting_object)
	var/precond_has_corners = (test_turf.lighting_flags & TURF_LIGHTING_CORNERS_INITIALISED)

	SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.begin_zlevel_lighting_teardown(test_z)
	var/slices = drive_lighting_teardown()

	var/finished = !SSlighting.teardown_zlevel
	var/abort_reason = SSlighting.teardown_abort_reason
	var/payoff_recorded = !isnull(SSlighting.zlevel_teardown_payoff["[test_z]"])
	var/list/memory_probe = get_process_memory_mb()
	var/memory_measurable = memory_probe && !isnull(memory_probe["vsz"])
	// Зона тестового турфа статически освещена, значит create_lighting_for_zlevel() его
	// пропускает и объект света вернуть не сможет. Такой объект снос обязан ОСТАВИТЬ.
	var/area/teardown_area = test_turf.loc
	var/rebuildable = IS_DYNAMIC_LIGHTING(teardown_area) && TURF_IS_DYNAMIC_LIGHTING(test_turf)
	var/object_handled = rebuildable ? isnull(test_turf.lighting_object) : !isnull(test_turf.lighting_object)
	var/corners_gone = !(test_turf.lighting_flags & TURF_LIGHTING_CORNERS_INITIALISED) && isnull(test_turf.lc_topright) && isnull(test_turf.lc_bottomleft)
	var/source_released = isnull(emitter.light)
	var/source_parked = (emitter in GLOB.lighting_deferred_atoms)
	var/level_released = !level.lighting_initialized
	var/requeued = (test_z in SSlighting.bg_queued_zlevels)

	// Обратный подъём: тот же путь, которым уровень поднимает вошедший игрок.
	create_lighting_for_zlevel(test_z)
	drain_lighting_queues_snapshot()
	var/object_restored = !isnull(test_turf.lighting_object)
	var/corners_restored = (test_turf.lighting_flags & TURF_LIGHTING_CORNERS_INITIALISED)
	var/source_restored = !isnull(emitter.light)
	var/unparked = !(emitter in GLOB.lighting_deferred_atoms)

	if(saved_clients)
		SSmobs.clients_by_zlevel[test_z] = saved_clients
	if(saved_dead)
		SSmobs.dead_players_by_zlevel[test_z] = saved_dead
	GLOB.lighting_deferred_atoms = saved_deferred
	SSlighting.zlevel_empty_since = saved_empty
	SSlighting.zlevel_teardown_payoff = saved_payoff
	SSlighting.teardown_zlevel = old_teardown
	level.traits = saved_traits
	level.lighting_initialized = old_init || level.lighting_initialized
	// Турф обратно в резервацию до ассертов: провалившийся ассерт выходит из Run() сразу.
	original_area.contents.Add(test_turf)
	allocated += dynamic_area

	// Замер в книгу пишется только там, где память вообще мерится: на Windows и в раннем
	// старте get_process_memory_mb() отдаёт null, и ключа не появляется - поэтому проверяется
	// не наличие записи, а то, что запись состоялась ИЛИ мерить было нечем.
	TEST_ASSERT(payoff_recorded || !memory_measurable, "снос дошёл до конца, память замерена, а в книгу отдачи ничего не легло - следующий снос этого уровня снова примут вслепую")

	TEST_ASSERT(precond_has_source, "предпосылка: у эмиттера на поднятом уровне обязан быть живой источник")
	TEST_ASSERT(precond_has_object, "предпосылка: у турфа на поднятом уровне обязан быть объект света")
	TEST_ASSERT(precond_has_corners, "предпосылка: у турфа на поднятом уровне обязаны быть углы")
	TEST_ASSERT(finished, "снос не дошёл до конца за [slices] срезов")
	TEST_ASSERT_NULL(abort_reason, "снос прервался вместо того, чтобы доработать (срезов: [slices])")
	TEST_ASSERT(object_handled, rebuildable \
		? "объект света остался после сноса, хотя обратный подъём умеет его вернуть" \
		: "снос убил объект света на турфе в статически освещённой зоне ([teardown_area]) - обратный подъём такой турф пропускает, и объект не вернулся бы никогда")
	TEST_ASSERT(corners_gone, "углы остались после сноса - память не освободилась")
	TEST_ASSERT(source_released, "источник света пережил снос - он бы достроил себе углы заново")
	TEST_ASSERT(source_parked, "источник не вернулся в отложку, обратный подъём его не найдёт")
	TEST_ASSERT(level_released, "уровень остался помеченным поднятым")
	TEST_ASSERT(requeued, "уровень не вернулся в очередь фонового подъёма")
	TEST_ASSERT(object_restored, "после обратного подъёма у турфа нет объекта света")
	TEST_ASSERT(corners_restored, "обратный подъём не вернул углы")
	TEST_ASSERT(source_restored, "обратный подъём не оживил запаркованный источник")
	TEST_ASSERT(unparked, "источник остался в отложке после подъёма")

/**
 * Протухшая ссылка в реестре z-уровня не считается жильцом.
 *
 * Реестры ведутся вычитанием при смене z, и моб, исчезнувший без такой смены, оставляет в
 * списке мёртвую ссылку. Длина списка при этом остаётся ненулевой навсегда, а на ответ
 * "есть ли тут кто-нибудь" завязаны обе стороны: фоновая сборка строила бы свет уровню, на
 * котором никого нет, а снос никогда бы такой уровень не разобрал.
 */
/datum/unit_test/lighting_occupant_check_ignores_stale_refs

/datum/unit_test/lighting_occupant_check_ignores_stale_refs/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	TEST_ASSERT(test_z <= length(SSmobs.clients_by_zlevel), "предпосылка: реестр клиентов обязан покрывать тестовый z")

	var/list/saved_clients = SSmobs.clients_by_zlevel[test_z]
	var/list/saved_dead = (test_z <= length(SSmobs.dead_players_by_zlevel)) ? SSmobs.dead_players_by_zlevel[test_z] : null
	SSmobs.clients_by_zlevel[test_z] = list()
	if(saved_dead)
		SSmobs.dead_players_by_zlevel[test_z] = list()

	var/empty_reads_free = !SSlighting.zlevel_has_occupant(test_z)

	// Мёртвая ссылка: ровно то, что остаётся в реестре от исчезнувшего без смены z моба.
	SSmobs.clients_by_zlevel[test_z] = list(null)
	var/stale_reads_free = !SSlighting.zlevel_has_occupant(test_z)

	// Живой моб обязан считаться жильцом - иначе снос разобрал бы уровень под игроком.
	var/mob/living/carbon/human/occupant = allocate(/mob/living/carbon/human, test_turf)
	SSmobs.clients_by_zlevel[test_z] = list(null, occupant)
	var/live_reads_occupied = SSlighting.zlevel_has_occupant(test_z)

	SSmobs.clients_by_zlevel[test_z] = saved_clients
	if(saved_dead)
		SSmobs.dead_players_by_zlevel[test_z] = saved_dead

	TEST_ASSERT(empty_reads_free, "пустой реестр прочитался как занятый уровень")
	TEST_ASSERT(stale_reads_free, "протухшая ссылка прочиталась как жилец - уровень был бы заперт до конца раунда")
	TEST_ASSERT(live_reads_occupied, "живой моб не прочитался как жилец")

/// Появившийся жилец прекращает снос немедленно: доразбирать уровень под игроком нельзя.
/datum/unit_test/lighting_teardown_aborts_on_occupant

/datum/unit_test/lighting_teardown_aborts_on_occupant/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)

	var/old_init = level.lighting_initialized
	var/old_teardown = SSlighting.teardown_zlevel
	var/list/saved_empty = SSlighting.zlevel_empty_since.Copy()

	// Снос запущен, но уровень успели поднять обратно (вход игрока / фоновый краулер).
	level.lighting_initialized = TRUE
	SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.begin_zlevel_lighting_teardown(test_z)
	var/started = SSlighting.teardown_zlevel == test_z
	level.lighting_initialized = TRUE
	var/saved_can_fire = detach_subsystem(SSlighting)
	SSlighting.state = SS_RUNNING
	SSlighting.process_zlevel_lighting_teardown()
	release_subsystem(SSlighting, saved_can_fire)
	var/aborted_on_reinit = !SSlighting.teardown_zlevel

	// И вторая причина бросить работу: чужой подъём держит init_in_progress.
	level.lighting_initialized = FALSE
	SSlighting.begin_zlevel_lighting_teardown(test_z)
	var/old_in_progress = SSlighting.init_in_progress
	SSlighting.init_in_progress = TRUE
	saved_can_fire = detach_subsystem(SSlighting)
	SSlighting.state = SS_RUNNING
	SSlighting.process_zlevel_lighting_teardown()
	release_subsystem(SSlighting, saved_can_fire)
	SSlighting.init_in_progress = old_in_progress
	var/aborted_on_builder = !SSlighting.teardown_zlevel

	SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.teardown_zlevel = old_teardown
	SSlighting.zlevel_empty_since = saved_empty
	level.lighting_initialized = old_init
	create_lighting_for_zlevel(test_z)

	TEST_ASSERT(started, "снос не запустился, тест проверил бы не то")
	TEST_ASSERT(aborted_on_reinit, "снос продолжился на уровне, который уже подняли обратно")
	TEST_ASSERT(aborted_on_builder, "снос продолжился, пока другой проход строит свет")

/**
 * Реестры мобов по z читаются за границей списка без рантайма.
 *
 * clients_by_zlevel и dead_players_by_zlevel растут только в MaxZChanged(), а обращаются
 * к ним раньше. Прямое индексирование в этот момент давало "cannot read from list" в
 * playsound() прямо на инициализации мира - и этот единственный рантайм валил dm-test на
 * КАЖДОЙ карте: FinishTestRun требует total_runtimes == 0, а декремент для ожидаемых
 * рантаймов работает только внутри теста, когда GLOB.current_test уже выставлен.
 */
/datum/unit_test/mob_zlevel_registry_reads_out_of_range
	requires_full_map = FALSE

/datum/unit_test/mob_zlevel_registry_reads_out_of_range/Run()
	var/beyond = length(SSmobs.clients_by_zlevel) + 5
	TEST_ASSERT_NULL(SSmobs.clients_on_zlevel(beyond), "чтение клиентов за границей реестра обязано отдавать null, а не рантаймить")
	TEST_ASSERT_NULL(SSmobs.dead_players_on_zlevel(beyond), "чтение мёртвых за границей реестра обязано отдавать null")
	TEST_ASSERT_NULL(SSmobs.clients_on_zlevel(0), "нулевой z не индексируется")
	TEST_ASSERT_NULL(SSmobs.clients_on_zlevel(-1), "отрицательный z не индексируется")
	TEST_ASSERT_NOTNULL(SSmobs.clients_on_zlevel(run_loc_floor_bottom_left.z), "существующий z обязан отдавать список")

/**
 * Срок простоя перед сносом: квота жёстче давления, неизмеренное давление ничего не меняет.
 *
 * Раунды 10124 и 10125 (27.08.2026) разложены по ступенькам VmSize: снос не возвращает ОС
 * ни байта, но постройка ПОСЛЕ сноса стоит 2-11 МБ вместо 41-107 - куча переиспользуется.
 * Значит раунд платит за ПИК одновременно зажжённых отложенных уровней, и именно его режет
 * квота. В 10125 три таких уровня горели все 65 минут, потому что таймер в четверть часа не
 * истёк ни разу; половина всего роста раунда (236 из 479 МБ) - это их постройка.
 */
/datum/unit_test/lighting_teardown_idle_time_tiers
	requires_full_map = FALSE

/datum/unit_test/lighting_teardown_idle_time_tiers/Run()
	// Давление не замерено (Windows, ранний старт) - механизм обязан вести себя как раньше.
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(0, 1), LIGHTING_TEARDOWN_IDLE_TIME, "без замера памяти срок простоя обязан остаться прежним")
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(0.5, LIGHTING_MAX_LIT_DEFERRED_Z), LIGHTING_TEARDOWN_IDLE_TIME, "на половине потолка и в пределах кванта срок не сокращается")

	// Давление: две ступени, обе на границе включительно.
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(LIGHTING_TEARDOWN_PRESSURE_HIGH, 1), LIGHTING_TEARDOWN_IDLE_TIME_HIGH, "на границе высокого давления срок обязан сократиться")
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(LIGHTING_TEARDOWN_PRESSURE_HIGH - 0.01, 1), LIGHTING_TEARDOWN_IDLE_TIME, "под границей высокого давления срок обязан остаться прежним")
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(LIGHTING_TEARDOWN_PRESSURE_CRITICAL, 1), LIGHTING_TEARDOWN_IDLE_TIME_CRITICAL, "на границе критического давления срок обязан стать минутным")
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(0.99, 1), LIGHTING_TEARDOWN_IDLE_TIME_CRITICAL, "почти у потолка срок обязан быть минутным")

	// Квота режет срок, но НЕ до нуля. Ноль означал "забрать уровень первым же сканом после
	// ухода последнего госта", и раунд 10126 отработал этим 42 подъёма и 41 снос, ни один из
	// которых памяти не сэкономил: квота своё уже взяла на пике, а внутри пика снос и подъём
	// бесплатны (куча переиспользуется) и стоят только тика и вспышки белого.
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(0, LIGHTING_MAX_LIT_DEFERRED_Z + 1), LIGHTING_TEARDOWN_IDLE_TIME_QUOTA, "сверх кванта срок режется до минимального простоя, а не до нуля")
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(0.05, LIGHTING_MAX_LIT_DEFERRED_Z + 5), LIGHTING_TEARDOWN_IDLE_TIME_QUOTA, "квота обязана работать и на пустом мире с огромным запасом")
	TEST_ASSERT(LIGHTING_TEARDOWN_IDLE_TIME_QUOTA < LIGHTING_TEARDOWN_IDLE_TIME_HIGH, "квотный срок обязан быть короче срока под давлением, иначе квота ничего не ускоряет")

	// Ноль остаётся ровно там, где он оправдан: у критического давления вспышка дешевле
	// смерти процесса, и там уровень отдаётся немедленно.
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(LIGHTING_TEARDOWN_PRESSURE_CRITICAL, LIGHTING_MAX_LIT_DEFERRED_Z + 1), 0, "сверх кванта у самого потолка уровень отдаётся немедленно")
	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(LIGHTING_TEARDOWN_PRESSURE_HIGH, LIGHTING_MAX_LIT_DEFERRED_Z + 1), LIGHTING_TEARDOWN_IDLE_TIME_QUOTA, "под высоким давлением сверх кванта берётся меньший из двух сроков")

/**
 * Кулдаун от ПОДЪЁМА: только что зажжённый уровень не сносится, кто бы его ни зажёг.
 *
 * Простой (zlevel_empty_since) отсчитывается с момента, когда уровень увидели пустым, и
 * пролетевший гост обнуляет его каждый раз заново - одним сроком простоя частоту качания
 * сверху не ограничить. В раунде 10126 z15 Academy подняли и снесли по девятнадцать раз.
 */
/datum/unit_test/lighting_teardown_cooldown_after_build
	requires_full_map = FALSE

/datum/unit_test/lighting_teardown_cooldown_after_build/Run()
	var/now = 100 MINUTES

	TEST_ASSERT(zlevel_teardown_cooldown_active(now, now, 0), "уровень, поднятый прямо сейчас, сносить рано")
	TEST_ASSERT(zlevel_teardown_cooldown_active(now - LIGHTING_TEARDOWN_MIN_LIT_TIME + 1, now, 0), "за тик до конца кулдауна сносить всё ещё рано")
	TEST_ASSERT(!zlevel_teardown_cooldown_active(now - LIGHTING_TEARDOWN_MIN_LIT_TIME, now, 0), "ровно на границе кулдаун кончился")
	TEST_ASSERT(!zlevel_teardown_cooldown_active(now - (30 MINUTES), now, 0), "давно поднятый уровень кулдаун не защищает")

	// Момент подъёма неизвестен - защищать нечего: уровень поднят до появления отметки.
	TEST_ASSERT(!zlevel_teardown_cooldown_active(null, now, 0), "неизвестный момент подъёма не должен запирать снос навсегда")

	// У самого потолка кулдаун снимается: там вспышка дешевле смерти процесса.
	TEST_ASSERT(!zlevel_teardown_cooldown_active(now, now, LIGHTING_TEARDOWN_PRESSURE_CRITICAL), "под критическим давлением кулдаун не действует")
	TEST_ASSERT(zlevel_teardown_cooldown_active(now, now, LIGHTING_TEARDOWN_PRESSURE_HIGH), "высокое давление кулдаун не снимает - оно и так режет срок простоя")

	// Кулдаун обязан быть длиннее квотного срока: иначе он ничего не добавляет.
	TEST_ASSERT(LIGHTING_TEARDOWN_MIN_LIT_TIME > LIGHTING_TEARDOWN_IDLE_TIME_QUOTA, "кулдаун короче квотного срока простоя не ограничивает частоту качания")

	// Ступени обязаны идти по убыванию - перепутанные местами дают срок ДЛИННЕЕ под давлением.
	TEST_ASSERT(LIGHTING_TEARDOWN_IDLE_TIME_CRITICAL < LIGHTING_TEARDOWN_IDLE_TIME_HIGH, "критический срок обязан быть короче высокого")
	TEST_ASSERT(LIGHTING_TEARDOWN_IDLE_TIME_HIGH < LIGHTING_TEARDOWN_IDLE_TIME, "срок под давлением обязан быть короче обычного")
	TEST_ASSERT(LIGHTING_TEARDOWN_PRESSURE_HIGH < LIGHTING_TEARDOWN_PRESSURE_CRITICAL, "порог высокого давления обязан быть ниже критического")

/// Выбор жертвы среди пустующих: разбирается тот, кто пустует дольше всех, и только по сроку.
/datum/unit_test/lighting_teardown_picks_longest_idle
	requires_full_map = FALSE

/datum/unit_test/lighting_teardown_picks_longest_idle/Run()
	var/now = 100 MINUTES
	var/list/candidates = list(
		"7" = now - (2 MINUTES),
		"8" = now - (40 MINUTES),
		"15" = now - (20 MINUTES),
	)

	TEST_ASSERT_EQUAL(pick_lighting_teardown_zlevel(candidates, 0, now), 8, "при нулевом сроке обязан браться самый давно пустующий")
	TEST_ASSERT_EQUAL(pick_lighting_teardown_zlevel(candidates, 30 MINUTES, now), 8, "порог в 30 мин проходит только z8")
	TEST_ASSERT_EQUAL(pick_lighting_teardown_zlevel(candidates, 10 MINUTES, now), 8, "из двух прошедших порог берётся тот, кто пустует дольше")
	TEST_ASSERT_EQUAL(pick_lighting_teardown_zlevel(candidates, 60 MINUTES, now), 0, "никто не прошёл порог - жертвы нет")
	TEST_ASSERT_EQUAL(pick_lighting_teardown_zlevel(list(), 0, now), 0, "пустой список кандидатов не должен давать жертву")
	// Ровно на границе уровень уже берётся: иначе при нулевом сроке (квота) не взялся бы никто.
	TEST_ASSERT_EQUAL(pick_lighting_teardown_zlevel(list("9" = now), 0, now), 9, "уровень, опустевший прямо сейчас, при нулевом сроке обязан браться")

/// Строка лога обязана отличать снос по кванту от сноса по таймеру - на ней держится разбор прода.
/datum/unit_test/lighting_teardown_reason_line_names_the_rule
	requires_full_map = FALSE

/datum/unit_test/lighting_teardown_reason_line_names_the_rule/Run()
	var/quota_line = zlevel_teardown_reason_line(0, LIGHTING_MAX_LIT_DEFERRED_Z + 1, 0.64)
	TEST_ASSERT(findtext(quota_line, "сверх кванта"), "снос по кванту обязан называть себя квантом: [quota_line]")
	TEST_ASSERT(findtext(quota_line, "64%"), "строка обязана называть давление, когда оно замерено: [quota_line]")

	// Ожидаемая подстрока считается из дефайна, а не пишется цифрой: с литералом правка
	// LIGHTING_TEARDOWN_IDLE_TIME роняла бы этот тест по несвязанной причине, а совпади
	// новая цифра со старой где-нибудь ещё в строке - тест прошёл бы, ничего не проверив.
	var/expected_idle = "[round(LIGHTING_TEARDOWN_IDLE_TIME / (1 MINUTES), 0.1)] мин"
	var/timer_line = zlevel_teardown_reason_line(LIGHTING_TEARDOWN_IDLE_TIME, LIGHTING_MAX_LIT_DEFERRED_Z, 0)
	TEST_ASSERT(!findtext(timer_line, "сверх кванта"), "снос по таймеру не должен выдавать себя за квант: [timer_line]")
	TEST_ASSERT(findtext(timer_line, expected_idle), "строка обязана называть фактический срок простоя [expected_idle]: [timer_line]")
	TEST_ASSERT(!findtext(timer_line, "%"), "неизмеренное давление не должно печататься процентами: [timer_line]")

	// Сокращённый срок обязан попадать в строку как есть: цифра из дефайна тут врала бы.
	var/expected_critical = "[round(LIGHTING_TEARDOWN_IDLE_TIME_CRITICAL / (1 MINUTES), 0.1)] мин"
	var/pressed_line = zlevel_teardown_reason_line(LIGHTING_TEARDOWN_IDLE_TIME_CRITICAL, 1, 0.9)
	TEST_ASSERT(findtext(pressed_line, expected_critical), "строка обязана печатать фактический сокращённый срок [expected_critical]: [pressed_line]")

/**
 * Доля потолка читается с последнего замера и молчит, когда мерить нечем.
 *
 * Ноль - это "неизвестно", и все, кто ужесточается под давлением, обязаны читать его как
 * "веди себя как раньше". Спутать его с честным нулевым давлением нельзя: на Windows
 * /proc нет вовсе, и там ноль стоит весь раунд.
 */
/datum/unit_test/memory_pressure_fraction_reads_last_sample
	requires_full_map = FALSE

/datum/unit_test/memory_pressure_fraction_reads_last_sample/Run()
	var/saved_ceiling = SStime_track.process_address_ceiling_mb
	var/saved_vsz = SStime_track.memory_last_vsz_mb

	SStime_track.process_address_ceiling_mb = 4000
	SStime_track.memory_last_vsz_mb = 2000
	var/half = memory_pressure_fraction()

	SStime_track.memory_last_vsz_mb = 0
	var/no_sample = memory_pressure_fraction()

	SStime_track.memory_last_vsz_mb = 2000
	SStime_track.process_address_ceiling_mb = 0
	var/no_ceiling = memory_pressure_fraction()

	SStime_track.process_address_ceiling_mb = saved_ceiling
	SStime_track.memory_last_vsz_mb = saved_vsz

	TEST_ASSERT_EQUAL(half, 0.5, "половина потолка обязана читаться как 0.5")
	TEST_ASSERT_EQUAL(no_sample, 0, "без замера VmSize давление обязано быть нулём-неизвестностью")
	TEST_ASSERT_EQUAL(no_ceiling, 0, "без замеренного потолка давление обязано быть нулём-неизвестностью")

/**
 * Квота РЕЖЕТ срок простоя пустующего уровня, а в пределах кванта таймер работает как был.
 *
 * Раньше сверх кванта срок был ноль, и уровень забирался первым же сканом после ухода
 * последнего госта. Раунд 10126 отработал этим 42 подъёма и 41 снос, не сэкономив ни байта:
 * квота своё берёт на ПИКЕ, а снос и подъём внутри достигнутого пика бесплатны по памяти и
 * стоят только тика и вспышки белого. Теперь сверх кванта срок - LIGHTING_TEARDOWN_IDLE_TIME_QUOTA.
 *
 * Это единственный кусок механизма, который нельзя проверить чистым проком: цифру
 * "сколько отложенных уровней горит" собирает сам scan_teardown_candidates(), и ошибка в
 * ней (посчитать только пустые, посчитать неотложенные) прошла бы мимо всех остальных
 * тестов. В раунде 10125 три уровня горели 65 минут подряд именно потому, что считать эту
 * цифру было некому.
 */
/datum/unit_test/lighting_teardown_quota_shortens_idle_timer

/datum/unit_test/lighting_teardown_quota_shortens_idle_timer/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	var/list/probe_levels = list()
	for(var/datum/space_level/level as anything in SSmapping.z_list)
		probe_levels += level
		if(length(probe_levels) > LIGHTING_MAX_LIT_DEFERRED_Z)
			break
	TEST_ASSERT(length(probe_levels) > LIGHTING_MAX_LIT_DEFERRED_Z, "предпосылка: в мире обязано быть больше [LIGHTING_MAX_LIT_DEFERRED_Z] z-уровней, иначе квоту не превысить")

	var/old_teardown = SSlighting.teardown_zlevel
	var/list/saved_empty = SSlighting.zlevel_empty_since.Copy()
	// Кулдаун от подъёма проверяется отдельным тестом; здесь он только мешал бы - свет
	// уровней поднимает сам харнес перед каждым тестом.
	var/list/saved_lit_since = SSlighting.zlevel_lit_since.Copy()
	SSlighting.zlevel_lit_since = list()
	var/saved_last_finished = SSlighting.last_teardown_finished_at
	SSlighting.last_teardown_finished_at = world.time - LIGHTING_TEARDOWN_SPACING
	var/list/saved_pressure = force_memory_pressure(LIGHTING_TEARDOWN_PRESSURE_HIGH + 0.05)
	var/list/saved_ledger = SSlighting.zlevel_teardown_payoff.Copy()
	SSlighting.zlevel_teardown_payoff = list()
	var/list/saved_traits = list()
	var/list/probe_z = list()
	var/list/saved_clients = list()
	var/list/saved_dead = list()
	for(var/datum/space_level/level as anything in probe_levels)
		var/z = level.z_value
		probe_z += z
		saved_traits["[z]"] = level.traits
		// Уровни-пробники должны быть пусты: соседние тесты оставляют в реестрах своих мобов,
		// а жилец снимает уровень с кандидатов раньше любой квоты.
		if(z <= length(SSmobs.clients_by_zlevel))
			saved_clients["[z]"] = SSmobs.clients_by_zlevel[z]
			SSmobs.clients_by_zlevel[z] = list()
		if(z <= length(SSmobs.dead_players_by_zlevel))
			saved_dead["[z]"] = SSmobs.dead_players_by_zlevel[z]
			SSmobs.dead_players_by_zlevel[z] = list()
		level.traits = list(ZTRAIT_MINING = TRUE)
	var/list/saved_lit = isolate_lit_deferred_zlevels(probe_z)

	// 1. Сверх кванта, но уровни только что опустели - жертву НЕ берут: минимальный простой
	//    сверх кванта и есть гистерезис, без которого механизм качает свет туда-сюда.
	for(var/datum/space_level/level as anything in probe_levels)
		level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since = list()
	SSlighting.scan_teardown_candidates()
	var/quota_picked_fresh = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()

	// 2. Сверх кванта и пустует дольше квотного срока - берут, хотя обычные четверть часа
	//    ещё не истекли. Это и есть весь выигрыш квоты.
	for(var/datum/space_level/level as anything in probe_levels)
		level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since = list()
	for(var/z in probe_z)
		SSlighting.zlevel_empty_since["[z]"] = world.time - LIGHTING_TEARDOWN_IDLE_TIME_QUOTA - 1
	SSlighting.scan_teardown_candidates()
	var/quota_picked = SSlighting.teardown_zlevel
	var/quota_picked_probe = (quota_picked in probe_z)
	SSlighting.abort_zlevel_lighting_teardown()

	// 3. В пределах кванта тот же свежеопустевший уровень не трогают: таймер снова главный.
	for(var/datum/space_level/level as anything in probe_levels)
		level.lighting_initialized = FALSE
	var/datum/space_level/lone = probe_levels[1]
	lone.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since = list()
	SSlighting.scan_teardown_candidates()
	var/within_quota_picked = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()

	// 4. Счёт ведётся по ЗАЖЖЁННЫМ отложенным, а не по всем подряд: неотложенные уровни
	//    квоту наполнять не должны, иначе она выбивала бы жертву на любой карте.
	for(var/datum/space_level/level as anything in probe_levels)
		level.lighting_initialized = TRUE
		level.traits = list(ZTRAIT_STATION = TRUE)
	lone.traits = list(ZTRAIT_MINING = TRUE)
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since = list()
	SSlighting.scan_teardown_candidates()
	var/non_deferred_filled_quota = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()

	for(var/datum/space_level/level as anything in probe_levels)
		var/z = level.z_value
		level.traits = saved_traits["[z]"]
		if(!isnull(saved_clients["[z]"]))
			SSmobs.clients_by_zlevel[z] = saved_clients["[z]"]
		if(!isnull(saved_dead["[z]"]))
			SSmobs.dead_players_by_zlevel[z] = saved_dead["[z]"]
	restore_lit_deferred_zlevels(saved_lit)
	SSlighting.teardown_zlevel = old_teardown
	SSlighting.zlevel_empty_since = saved_empty
	SSlighting.zlevel_lit_since = saved_lit_since
	SSlighting.last_teardown_finished_at = saved_last_finished
	SSlighting.zlevel_teardown_payoff = saved_ledger
	restore_memory_pressure(saved_pressure)

	TEST_ASSERT(!quota_picked_fresh, "сверх кванта забрали уровень, опустевший секунду назад (z[quota_picked_fresh]) - гистерезиса нет, механизм будет качать свет")
	TEST_ASSERT(quota_picked, "сверх кванта уровень, пустующий дольше квотного срока, не взяли на снос - квота не работает")
	TEST_ASSERT(quota_picked_probe, "квота взяла уровень z[quota_picked], которого нет среди пробников")
	TEST_ASSERT(!within_quota_picked, "в пределах кванта свежеопустевший уровень взяли на снос (z[within_quota_picked]) - таймер перестал защищать")
	TEST_ASSERT(!non_deferred_filled_quota, "квоту наполнили НЕотложенные уровни: взят z[non_deferred_filled_quota]")

/**
 * Посещение уже поднятого уровня обнуляет его счётчик простоя.
 *
 * Тест на конкретную дыру в сэмплировании. zlevel_empty_since писался и стирался только
 * сканом кандидатов на снос (раз в 15-30 секунд) и подъёмом уровня. Посетитель УЖЕ
 * поднятого уровня, уместившийся между двумя сканами, не оставлял следа нигде, и таймер
 * простоя тикал так, будто на уровне не было никого.
 *
 * Раунд 10134 (28.08.2026): z15 признали пустым, снесли 63 002 объекта за 60 секунд, и
 * через четыре минуты подняли обратно по поводу "живой сменил z". Прибор напечатал, что
 * подъём стоил 0 МБ VmSize: серверу цикл не вернул ничего, а видевшим уровень стоил
 * четырёх полноэкранных вспышек.
 */
/datum/unit_test/lighting_visit_clears_idle_timer

/datum/unit_test/lighting_visit_clears_idle_timer/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	var/test_z = run_loc_floor_bottom_left.z
	var/list/saved_empty = SSlighting.zlevel_empty_since.Copy()

	// Уровень "пустует" дольше любого срока простоя - следующий скан забрал бы его.
	SSlighting.zlevel_empty_since["[test_z]"] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.note_zlevel_visit(test_z)
	var/cleared = isnull(SSlighting.zlevel_empty_since["[test_z]"])

	// Выбор кандидата обязан согласиться: без отметки простоя брать нечего.
	var/picked_after_visit = pick_lighting_teardown_zlevel(SSlighting.zlevel_empty_since, 0, world.time)
	var/picked_is_other_z = picked_after_visit != test_z

	// Нулевой z - это "моб нигде"; такой вызов не должен ни падать, ни трогать список.
	SSlighting.zlevel_empty_since["[test_z]"] = world.time
	SSlighting.note_zlevel_visit(0)
	var/zero_z_left_entry = !isnull(SSlighting.zlevel_empty_since["[test_z]"])

	SSlighting.zlevel_empty_since = saved_empty

	TEST_ASSERT(cleared, "посещение уровня не обнулило его счётчик простоя - снос заберёт уровень, на котором стоит игрок")
	TEST_ASSERT(picked_is_other_z, "после посещения выбор кандидата всё равно отдал z[picked_after_visit]")
	TEST_ASSERT(zero_z_left_entry, "note_zlevel_visit(0) стёр чужую запись: моб \"нигде\" не должен трогать список")

/**
 * Гостовой дебаунс подъёма: свет целого z не строится ради пролетевшего мимо наблюдателя.
 *
 * Тест на цену из раунда 10133 (28.08.2026): z7 (Lavaland) подняли по поводу "гост сменил z" -
 * 65 025 объектов освещения, +46.2 МБ VmSize, - при НУЛЕ игровых событий на этом уровне за
 * весь раунд. Уровень потом снесли, вернув ноль.
 *
 * Проверяется чистая половина решения. Живой путь (living_movement.dm) выдержки не имеет
 * намеренно и здесь не участвует.
 */
/datum/unit_test/lighting_ghost_init_debounce_needs_occupant

/datum/unit_test/lighting_ghost_init_debounce_needs_occupant/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)
	TEST_ASSERT(test_z <= length(SSmobs.clients_by_zlevel), "предпосылка: реестр клиентов обязан покрывать тестовый z")

	var/old_init = level.lighting_initialized
	var/list/saved_clients = SSmobs.clients_by_zlevel[test_z]
	var/list/saved_dead = (test_z <= length(SSmobs.dead_players_by_zlevel)) ? SSmobs.dead_players_by_zlevel[test_z] : null

	// Уровень не поднят: без этого гейт should_ondemand_init_zlevel отсекает всё сам.
	level.lighting_initialized = FALSE
	SSmobs.clients_by_zlevel[test_z] = list()
	if(saved_dead)
		SSmobs.dead_players_by_zlevel[test_z] = list()

	// Гост улетел за время выдержки - строить нечего.
	var/empty_level_skipped = !ghost_ondemand_init_still_wanted(test_z)

	// Протухшая ссылка уровень удержать не должна: иначе один исчезнувший наблюдатель
	// заказывает постройку целого z навсегда.
	SSmobs.dead_players_by_zlevel[test_z] = list(null)
	var/stale_ref_skipped = !ghost_ondemand_init_still_wanted(test_z)

	// Гост с включённой темнотой на месте - свет обязан строиться, иначе он в темноте.
	var/mob/dead/observer/watcher = occupant_ghost(test_turf)
	SSmobs.dead_players_by_zlevel[test_z] = list(watcher)
	var/occupied_level_wanted = ghost_ondemand_init_still_wanted(test_z)

	// Уровень успели поднять за выдержку (живой игрок, шаттл, краулер) - повторять нечего.
	level.lighting_initialized = TRUE
	var/already_lit_skipped = !ghost_ondemand_init_still_wanted(test_z)

	level.lighting_initialized = old_init
	SSmobs.clients_by_zlevel[test_z] = saved_clients
	if(saved_dead)
		SSmobs.dead_players_by_zlevel[test_z] = saved_dead

	TEST_ASSERT(empty_level_skipped, "свет целого z строится ради госта, которого на уровне уже нет")
	TEST_ASSERT(stale_ref_skipped, "протухшая ссылка в реестре мёртвых заказала постройку целого z")
	TEST_ASSERT(occupied_level_wanted, "гост остался на уровне, а свет ему не построят - он будет сидеть в темноте")
	TEST_ASSERT(already_lit_skipped, "уровень уже поднят, а отложенный подъём всё равно сработает")

/**
 * Итоговая строка сноса называет, сколько памяти он ВЕРНУЛ операционной системе.
 *
 * Цена постройки печаталась с самого начала, цена сноса - нет, и вывод "снос не вернул
 * ничего" (раунд 10134: минус 64 тыс. инстансов, VmSize 2634 -> 2647 МБ) приходилось
 * собирать вручную по соседним строкам перф-CSV. Знак здесь обратный дельте VmSize:
 * упавший VmSize - это возвращённая память, и читаться она обязана как плюс.
 */
/datum/unit_test/lighting_teardown_reports_memory_returned

/datum/unit_test/lighting_teardown_reports_memory_returned/Run()
	// Память не замерена (Windows, ранний старт) - хвоста нет вовсе, а не "0 МБ".
	TEST_ASSERT_EQUAL(zlevel_teardown_memory_note(null, list("vsz" = 2600)), "", "без замера до сноса хвост обязан быть пустым")
	TEST_ASSERT_EQUAL(zlevel_teardown_memory_note(2600, null), "", "без замера после сноса хвост обязан быть пустым")
	TEST_ASSERT_EQUAL(zlevel_teardown_memory_note(2600, list("vsz" = null)), "", "с пустым VmSize после сноса хвост обязан быть пустым")

	// VmSize упал - память вернули, и это плюс.
	TEST_ASSERT_EQUAL(zlevel_teardown_memory_note(2647, list("vsz" = 2600)), ", ОС возвращено +47 МБ VmSize", "падение VmSize прочиталось не как возврат памяти")
	// Ровно случай раунда 10134: снос не вернул ничего.
	TEST_ASSERT_EQUAL(zlevel_teardown_memory_note(2634, list("vsz" = 2647)), ", ОС возвращено -13 МБ VmSize", "рост VmSize за время сноса прочитался не как отрицательный возврат")
	TEST_ASSERT_EQUAL(zlevel_teardown_memory_note(2600, list("vsz" = 2600)), ", ОС возвращено 0 МБ VmSize", "нулевой возврат обязан печататься, а не пропадать")

/**
 * Замеренная отдача прошлого сноса запирает следующий снос того же уровня.
 *
 * Четвёртая проверка решения и единственная, работающая по факту. Три предыдущие -
 * квота, срок простоя и кулдаун - предсказывают пользу от сноса косвенно, и раунд 10146
 * (Box Station, 48 минут, 102-128 игроков) показал, что все три вместе ошибаются трижды
 * за 48 минут на одном уровне: z16 (Virtual Reality) перемололи три раза по 42 099
 * объектов, вернув -1.5, -4.2 и -0.1 МБ (см. LIGHTING_TEARDOWN_MIN_PAYOFF_MB).
 */
/datum/unit_test/lighting_teardown_payoff_gate
	requires_full_map = FALSE

/datum/unit_test/lighting_teardown_payoff_gate/Run()
	// Сноса ещё не было либо мерить нечем (Windows, ранний старт) - улик нет, ведём себя
	// как раньше. Спутать это с честным нулевым возвратом нельзя: ноль - улика, null нет.
	TEST_ASSERT(!zlevel_teardown_payoff_exhausted(null), "без замера отдачи уровень обязан остаться кандидатом")

	// Ровно цифры трёх сносов z16 из раунда 10146.
	TEST_ASSERT(zlevel_teardown_payoff_exhausted(-1.5), "снос, вернувший -1.5 МБ, обязан запереть следующий")
	TEST_ASSERT(zlevel_teardown_payoff_exhausted(-4.2), "снос, вернувший -4.2 МБ, обязан запереть следующий")
	TEST_ASSERT(zlevel_teardown_payoff_exhausted(-0.1), "снос, вернувший -0.1 МБ, обязан запереть следующий")
	TEST_ASSERT(zlevel_teardown_payoff_exhausted(0), "нулевой возврат - это улика, а не отсутствие замера")

	// Настоящий снос лаваландского z возвращает 167-253 МБ - такой уровень запирать нельзя.
	TEST_ASSERT(!zlevel_teardown_payoff_exhausted(167), "полезный снос обязан остаться разрешённым")
	TEST_ASSERT(!zlevel_teardown_payoff_exhausted(LIGHTING_TEARDOWN_MIN_PAYOFF_MB), "ровно на пороге снос ещё считается полезным")
	TEST_ASSERT(zlevel_teardown_payoff_exhausted(LIGHTING_TEARDOWN_MIN_PAYOFF_MB - 0.1), "под порогом снос обязан запираться")

	// Порог обязан лежать между шумом и пользой: замеры прода дают -4.2 МБ у бесполезного
	// сноса и 167 МБ у полезного, и порог вне этих границ разделять их перестанет.
	TEST_ASSERT(LIGHTING_TEARDOWN_MIN_PAYOFF_MB > 5, "порог ниже шума замера перестанет отсекать бесполезные сносы")
	TEST_ASSERT(LIGHTING_TEARDOWN_MIN_PAYOFF_MB < 167, "порог выше настоящей отдачи запрёт и полезные сносы тоже")

/// Итог сноса обязан говорить, СДЕЛАН ли из цифры возврата вывод: в раунде 10146 три сноса
/// подряд напечатали свою бесполезность и каждый раз начинали заново.
/datum/unit_test/lighting_teardown_payoff_note_names_exclusion
	requires_full_map = FALSE

/datum/unit_test/lighting_teardown_payoff_note_names_exclusion/Run()
	TEST_ASSERT_EQUAL(zlevel_teardown_payoff_note(null), "", "без замера хвост обязан быть пустым")
	TEST_ASSERT_EQUAL(zlevel_teardown_payoff_note(167), "", "полезный снос не должен объявлять себя исключённым")
	TEST_ASSERT_EQUAL(zlevel_teardown_payoff_note(LIGHTING_TEARDOWN_MIN_PAYOFF_MB), "", "ровно на пороге снос ещё полезен и хвоста не получает")

	var/excluded = zlevel_teardown_payoff_note(-4.2)
	TEST_ASSERT(findtext(excluded, "исключён"), "бесполезный снос обязан назвать уровень исключённым: [excluded]")
	// Порог печатается из дефайна, а не цифрой: с литералом правка порога роняла бы тест
	// по несвязанной причине, а совпади новая цифра со старой - тест прошёл бы вхолостую.
	TEST_ASSERT(findtext(excluded, "[LIGHTING_TEARDOWN_MIN_PAYOFF_MB] МБ"), "хвост обязан называть фактический порог отдачи: [excluded]")

/**
 * В книгу отдачи попадает ровно то, что замерено, и ничего больше.
 *
 * Прерванный снос сюда писать нельзя: он не довёл до конца ни одну фазу освобождения, и
 * его дельта VmSize ничего не говорит о том, сколько уровень отдал бы целиком. Запись
 * поэтому живёт только в финале фазы 3, а не в abort_zlevel_lighting_teardown().
 */
/datum/unit_test/lighting_teardown_payoff_ledger_records_measurement
	requires_full_map = FALSE

/datum/unit_test/lighting_teardown_payoff_ledger_records_measurement/Run()
	var/saved_vsz_before = SSlighting.teardown_vsz_before
	var/list/saved_ledger = SSlighting.zlevel_teardown_payoff.Copy()
	SSlighting.zlevel_teardown_payoff = list()

	// Память не замерена ни до, ни после - улики не появляется, ключа в книге нет.
	SSlighting.teardown_vsz_before = null
	var/unmeasured_before = SSlighting.record_zlevel_teardown_payoff(41, list("vsz" = 2600))
	var/unmeasured_before_key = SSlighting.zlevel_teardown_payoff["41"]

	SSlighting.teardown_vsz_before = 2600
	var/unmeasured_after = SSlighting.record_zlevel_teardown_payoff(42, null)
	var/unmeasured_after_key = SSlighting.zlevel_teardown_payoff["42"]

	var/empty_vsz = SSlighting.record_zlevel_teardown_payoff(43, list("vsz" = null))
	var/empty_vsz_key = SSlighting.zlevel_teardown_payoff["43"]

	// Замер есть: знак ОБРАТНЫЙ дельте VmSize - упавший VmSize означает возвращённую память.
	SSlighting.teardown_vsz_before = 2647
	var/useful = SSlighting.record_zlevel_teardown_payoff(44, list("vsz" = 2400))
	var/useful_key = SSlighting.zlevel_teardown_payoff["44"]

	// Ровно случай z16 в раунде 10146: VmSize за время сноса ВЫРОС.
	SSlighting.teardown_vsz_before = 3216.7
	var/useless = SSlighting.record_zlevel_teardown_payoff(16, list("vsz" = 3220.9))
	var/useless_key = SSlighting.zlevel_teardown_payoff["16"]

	SSlighting.zlevel_teardown_payoff = saved_ledger
	SSlighting.teardown_vsz_before = saved_vsz_before

	TEST_ASSERT_NULL(unmeasured_before, "без замера до сноса книга обязана вернуть null")
	TEST_ASSERT_NULL(unmeasured_before_key, "без замера до сноса ключ в книге появляться не должен")
	TEST_ASSERT_NULL(unmeasured_after, "без замера после сноса книга обязана вернуть null")
	TEST_ASSERT_NULL(unmeasured_after_key, "без замера после сноса ключ в книге появляться не должен")
	TEST_ASSERT_NULL(empty_vsz, "с пустым VmSize после сноса книга обязана вернуть null")
	TEST_ASSERT_NULL(empty_vsz_key, "с пустым VmSize после сноса ключ в книге появляться не должен")
	TEST_ASSERT_EQUAL(useful, 247, "полезный снос записан в книгу неверной цифрой")
	TEST_ASSERT_EQUAL(useful_key, 247, "полезный снос не попал в книгу под своим ключом")
	// Сравнение с допуском, а не на равенство: 3216.7 - 3220.9 даёт -4.200000000000273, и
	// round(x, 0.1) эту ошибку не убирает - он делит и умножает обратно, заново её внося.
	// TEST_ASSERT_EQUAL печатал бы "Expected -4.2 to be equal to -4.2" и был бы неотличим
	// от настоящей поломки арифметики.
	TEST_ASSERT(abs(useless - (-4.2)) < 0.01, "рост VmSize за время сноса обязан читаться как отрицательная отдача, получено [useless]")
	TEST_ASSERT(abs(useless_key - (-4.2)) < 0.01, "бесполезный снос не попал в книгу под своим ключом, там [useless_key]")
	TEST_ASSERT(zlevel_teardown_payoff_exhausted(useless_key), "записанная в книгу бесполезная отдача обязана запирать следующий снос")
	TEST_ASSERT(!zlevel_teardown_payoff_exhausted(useful_key), "записанная в книгу полезная отдача не должна запирать следующий снос")

/**
 * Скан кандидатов не берёт уровень, чей прошлый снос уже доказал, что возвращать нечего.
 *
 * Живым сканом, а не чистым проком, по той же причине, что и тест квоты: цифру
 * "сколько отложенных уровней горит" собирает сам scan_teardown_candidates(), и порядок
 * проверок внутри него чистыми функциями не проверяется. Ошибка тут стоит ровно того, что
 * стоила в раунде 10146: три цикла по 42 099 объектов, 99 тяжёлых фаеров SSlighting с
 * медианой 251 мс, очередь GC до 70 781 и дилатация до 67.4% - за ноль возвращённых МБ.
 *
 * Проверка исключения ОБЯЗАНА идти после счётчика зажжённых: исключённый уровень всё равно
 * горит и в квоте участвует, иначе его исключение снимало бы давление квоты с остальных.
 */
/datum/unit_test/lighting_teardown_skips_proven_useless_zlevel

/datum/unit_test/lighting_teardown_skips_proven_useless_zlevel/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	var/list/probe_levels = list()
	for(var/datum/space_level/level as anything in SSmapping.z_list)
		probe_levels += level
		if(length(probe_levels) > LIGHTING_MAX_LIT_DEFERRED_Z)
			break
	TEST_ASSERT(length(probe_levels) > LIGHTING_MAX_LIT_DEFERRED_Z, "предпосылка: в мире обязано быть больше [LIGHTING_MAX_LIT_DEFERRED_Z] z-уровней, иначе квоту не превысить")

	var/old_teardown = SSlighting.teardown_zlevel
	var/list/saved_empty = SSlighting.zlevel_empty_since.Copy()
	var/list/saved_lit_since = SSlighting.zlevel_lit_since.Copy()
	var/list/saved_ledger = SSlighting.zlevel_teardown_payoff.Copy()
	// Кулдаун от подъёма проверяется отдельным тестом, здесь он только мешал бы.
	SSlighting.zlevel_lit_since = list()
	var/saved_last_finished = SSlighting.last_teardown_finished_at
	SSlighting.last_teardown_finished_at = world.time - LIGHTING_TEARDOWN_SPACING
	// Давление задаётся явно: в CI VmSize может быть не замерен, и тогда снос не запускается
	// вовсе, а ветка критического давления решала бы исход теста за нас.
	var/list/saved_pressure = force_memory_pressure(LIGHTING_TEARDOWN_PRESSURE_HIGH + 0.05)

	var/list/saved_traits = list()
	var/list/probe_z = list()
	var/list/saved_clients = list()
	var/list/saved_dead = list()
	for(var/datum/space_level/level as anything in probe_levels)
		var/z = level.z_value
		probe_z += z
		saved_traits["[z]"] = level.traits
		// Уровни-пробники должны быть пусты: жилец снимает уровень с кандидатов раньше
		// любой квоты, а соседние тесты оставляют в реестрах своих мобов.
		if(z <= length(SSmobs.clients_by_zlevel))
			saved_clients["[z]"] = SSmobs.clients_by_zlevel[z]
			SSmobs.clients_by_zlevel[z] = list()
		if(z <= length(SSmobs.dead_players_by_zlevel))
			saved_dead["[z]"] = SSmobs.dead_players_by_zlevel[z]
			SSmobs.dead_players_by_zlevel[z] = list()
		level.traits = list(ZTRAIT_MINING = TRUE)
	var/list/saved_lit = isolate_lit_deferred_zlevels(probe_z)

	// Все пробники горят и пустуют дольше квотного срока в каждом из пяти прогонов.
	var/idle_since = world.time - LIGHTING_TEARDOWN_IDLE_TIME_QUOTA - 1

	// 1. Книга пуста - улик нет, жертва берётся. Это базовая линия: без неё тест прошёл бы
	//    и на механизме, который вообще перестал что-либо сносить.
	for(var/datum/space_level/level as anything in probe_levels)
		level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_teardown_payoff = list()
	SSlighting.zlevel_empty_since = list()
	for(var/z in probe_z)
		SSlighting.zlevel_empty_since["[z]"] = idle_since
	SSlighting.scan_teardown_candidates()
	var/clean_ledger_picked = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()

	// 2. У всех пробников прошлый снос вернул мусор - не берут никого.
	for(var/datum/space_level/level as anything in probe_levels)
		level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_teardown_payoff = list()
	SSlighting.zlevel_empty_since = list()
	for(var/z in probe_z)
		SSlighting.zlevel_empty_since["[z]"] = idle_since
		SSlighting.zlevel_teardown_payoff["[z]"] = -4.2
	SSlighting.scan_teardown_candidates()
	var/all_useless_picked = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()

	// 3. Один пробник исключён, остальные нет - берут кого-то из остальных. Проверяет, что
	//    исключение адресное, а не глушит скан целиком.
	for(var/datum/space_level/level as anything in probe_levels)
		level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_teardown_payoff = list()
	SSlighting.zlevel_empty_since = list()
	for(var/z in probe_z)
		SSlighting.zlevel_empty_since["[z]"] = idle_since
	var/excluded_z = probe_z[1]
	SSlighting.zlevel_teardown_payoff["[excluded_z]"] = -4.2
	SSlighting.scan_teardown_candidates()
	var/partial_picked = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()

	// 4. Полезная отдача книгу не запирает: уровень, вернувший 167 МБ, остаётся кандидатом.
	for(var/datum/space_level/level as anything in probe_levels)
		level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_teardown_payoff = list()
	SSlighting.zlevel_empty_since = list()
	for(var/z in probe_z)
		SSlighting.zlevel_empty_since["[z]"] = idle_since
		SSlighting.zlevel_teardown_payoff["[z]"] = 167
	SSlighting.scan_teardown_candidates()
	var/useful_ledger_picked = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()

	// 5. Под критическим давлением запрет держится: прод сидит у потолка почти весь раунд.
	force_memory_pressure(LIGHTING_TEARDOWN_PRESSURE_CRITICAL)
	for(var/datum/space_level/level as anything in probe_levels)
		level.lighting_initialized = TRUE
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_teardown_payoff = list()
	SSlighting.zlevel_empty_since = list()
	for(var/z in probe_z)
		SSlighting.zlevel_empty_since["[z]"] = idle_since
		SSlighting.zlevel_teardown_payoff["[z]"] = -4.2
	SSlighting.scan_teardown_candidates()
	var/critical_picked = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()

	for(var/datum/space_level/level as anything in probe_levels)
		var/z = level.z_value
		level.traits = saved_traits["[z]"]
		if(!isnull(saved_clients["[z]"]))
			SSmobs.clients_by_zlevel[z] = saved_clients["[z]"]
		if(!isnull(saved_dead["[z]"]))
			SSmobs.dead_players_by_zlevel[z] = saved_dead["[z]"]
	restore_lit_deferred_zlevels(saved_lit)
	SSlighting.teardown_zlevel = old_teardown
	SSlighting.zlevel_empty_since = saved_empty
	SSlighting.zlevel_lit_since = saved_lit_since
	SSlighting.last_teardown_finished_at = saved_last_finished
	SSlighting.zlevel_teardown_payoff = saved_ledger
	restore_memory_pressure(saved_pressure)

	TEST_ASSERT(clean_ledger_picked, "с пустой книгой отдачи жертву не взяли - базовая линия теста сломана, остальные проверки ничего не значат")
	TEST_ASSERT(!all_useless_picked, "взят z[all_useless_picked], хотя его прошлый снос вернул -4.2 МБ - механизм снова будет качать свет впустую")
	TEST_ASSERT(partial_picked, "исключение одного уровня погасило скан целиком - оно обязано быть адресным")
	TEST_ASSERT_NOTEQUAL(partial_picked, excluded_z, "скан взял именно исключённый уровень z[excluded_z]")
	TEST_ASSERT(useful_ledger_picked, "уровень с полезной отдачей 167 МБ перестал быть кандидатом")
	TEST_ASSERT(!critical_picked, "под критическим давлением взят z[critical_picked] с бесполезным сносом - у потолка свет снова будут качать впустую")

/**
 * Книга отдачи держит ЛУЧШИЙ замер уровня, а не последний.
 *
 * Окно замера - это весь снос, до минуты реального времени, и всё, что мир успел выделить
 * внутри него, садится в ту же дельту VmSize. При last-write один такой шумный сэмпл запирал
 * уровень до конца раунда поверх честного прошлого замера, вернувшего сотню мегабайт:
 * механизм терял самого полезного кандидата из-за чужой аллокации.
 */
/datum/unit_test/lighting_teardown_payoff_ledger_keeps_best
	requires_full_map = FALSE
	var/saved_vsz_before
	var/list/saved_ledger
	var/ledger_swapped = FALSE

/datum/unit_test/lighting_teardown_payoff_ledger_keeps_best/Destroy()
	// Уборка в Destroy(): провалившийся TEST_ASSERT выходит из Run() немедленно, а книга
	// живёт до конца раунда и протекла бы в соседние тесты молчаливым отказом.
	if(ledger_swapped)
		SSlighting.zlevel_teardown_payoff = saved_ledger
		SSlighting.teardown_vsz_before = saved_vsz_before
	return ..()

/datum/unit_test/lighting_teardown_payoff_ledger_keeps_best/Run()
	saved_vsz_before = SSlighting.teardown_vsz_before
	saved_ledger = SSlighting.zlevel_teardown_payoff.Copy()
	ledger_swapped = TRUE
	SSlighting.zlevel_teardown_payoff = list()

	// Полезный снос: уровень вернул 247 МБ.
	SSlighting.teardown_vsz_before = 2647
	var/first = SSlighting.record_zlevel_teardown_payoff(51, list("vsz" = 2400))

	// Следующий снос того же уровня утонул в шуме - VmSize за минуту даже подрос.
	SSlighting.teardown_vsz_before = 3216.7
	var/after_noise = SSlighting.record_zlevel_teardown_payoff(51, list("vsz" = 3220.9))
	var/after_noise_key = SSlighting.zlevel_teardown_payoff["51"]

	// А вот РОСТ отдачи книга обязана принимать: уровень стал отдавать больше.
	SSlighting.teardown_vsz_before = 3000
	var/after_better = SSlighting.record_zlevel_teardown_payoff(51, list("vsz" = 2600))

	// Первый замер уровня, у которого в книге ещё ничего нет, пишется как есть - даже плохой.
	SSlighting.teardown_vsz_before = 3216.7
	var/first_bad = SSlighting.record_zlevel_teardown_payoff(52, list("vsz" = 3220.9))

	TEST_ASSERT_EQUAL(first, 247, "первый замер записан неверно")
	TEST_ASSERT_EQUAL(after_noise, 247, "шумный сэмпл перетёр честный прошлый замер: книга обязана держать максимум")
	TEST_ASSERT_EQUAL(after_noise_key, 247, "под ключом уровня осталась не лучшая цифра, там [after_noise_key]")
	TEST_ASSERT(!zlevel_teardown_payoff_exhausted(after_noise_key), "один шумный сэмпл запер уровень, который до этого честно вернул 247 МБ")
	TEST_ASSERT_EQUAL(after_better, 400, "выросшую отдачу книга обязана принимать")
	// Сравнение с допуском: 3216.7 - 3220.9 даёт -4.200000000000273, см. соседний тест книги.
	TEST_ASSERT(abs(first_bad - (-4.2)) < 0.01, "первый замер уровня пишется как есть, получено [first_bad]")

/**
 * Постройка света, взявшая у ОС свежую память, снимает с уровня улику прошлого сноса.
 *
 * Запрет держится на допущении "арена осталась за процессом, следующий подъём почти
 * бесплатный" - в 10146 обратные подъёмы z16 стоили +1.2, +1.3 и 0 МБ. Подъём дороже порога
 * отдачи это допущение опровергает: уровень занял память заново, и сносить его снова есть
 * смысл. Без снятия ключа он оставался бы вне сносов до конца раунда, сколько бы ни занял.
 */
/datum/unit_test/lighting_rebuild_reopens_excluded_zlevel
	requires_full_map = FALSE
	var/list/saved_ledger
	var/ledger_swapped = FALSE

/datum/unit_test/lighting_rebuild_reopens_excluded_zlevel/Destroy()
	if(ledger_swapped)
		SSlighting.zlevel_teardown_payoff = saved_ledger
	return ..()

/datum/unit_test/lighting_rebuild_reopens_excluded_zlevel/Run()
	// Чистая функция решения: порог тот же, что и у отдачи.
	TEST_ASSERT(!zlevel_rebuild_commits_fresh_memory(null), "без замера постройки выводов делать не из чего")
	TEST_ASSERT(!zlevel_rebuild_commits_fresh_memory(0), "бесплатный подъём допущение подтверждает, а не опровергает")
	TEST_ASSERT(!zlevel_rebuild_commits_fresh_memory(1.3), "обратный подъём z16 в 10146 стоил +1.3 МБ - это шум, а не свежая память")
	TEST_ASSERT(zlevel_rebuild_commits_fresh_memory(73.8), "первая постройка z16 стоила +73.8 МБ - это свежая память")
	TEST_ASSERT(zlevel_rebuild_commits_fresh_memory(LIGHTING_TEARDOWN_MIN_PAYOFF_MB), "ровно на пороге постройка уже считается свежей")
	TEST_ASSERT(!zlevel_rebuild_commits_fresh_memory(LIGHTING_TEARDOWN_MIN_PAYOFF_MB - 0.1), "под порогом постройка свежей не считается")

	saved_ledger = SSlighting.zlevel_teardown_payoff.Copy()
	ledger_swapped = TRUE
	SSlighting.zlevel_teardown_payoff = list()

	// Уровень исключён прошлым сносом, а обратный подъём оказался почти бесплатным -
	// улика остаётся, допущение подтвердилось.
	SSlighting.zlevel_teardown_payoff["61"] = -4.2
	var/cheap_rebuild_verdict = SSlighting.note_zlevel_lighting_rebuild(61, 1.3)
	var/still_excluded = zlevel_teardown_payoff_exhausted(SSlighting.zlevel_teardown_payoff["61"])

	// Тот же уровень, но подъём взял у ОС 73.8 МБ - улику снимаем.
	var/fresh_rebuild_verdict = SSlighting.note_zlevel_lighting_rebuild(61, 73.8)
	var/reopened = isnull(SSlighting.zlevel_teardown_payoff["61"])

	// Повторный вызов на уже чистом уровне ничего не делает и не врёт в лог.
	var/repeat_verdict = SSlighting.note_zlevel_lighting_rebuild(61, 73.8)

	// Уровня в книге нет вовсе - снимать нечего.
	var/unknown_verdict = SSlighting.note_zlevel_lighting_rebuild(62, 200)

	var/unmeasured_verdict = SSlighting.note_zlevel_lighting_rebuild(63, null)
	var/unmeasured_key = SSlighting.zlevel_teardown_payoff["63"]

	TEST_ASSERT_EQUAL(cheap_rebuild_verdict, LIGHTING_REBUILD_VERDICT_UNCHANGED, "дешёвый подъём уже исключённого уровня не меняет его допуска и не должен ничего объявлять")
	TEST_ASSERT(still_excluded, "после дешёвого подъёма уровень обязан остаться исключённым")
	TEST_ASSERT_EQUAL(fresh_rebuild_verdict, LIGHTING_REBUILD_VERDICT_REOPENED, "дорогой подъём обязан снимать улику: арена не переиспользовалась")
	TEST_ASSERT(reopened, "ключ уровня остался в книге - он не вернётся в кандидаты до конца раунда")
	TEST_ASSERT_EQUAL(repeat_verdict, LIGHTING_REBUILD_VERDICT_UNCHANGED, "повторное снятие уже снятой улики обязано быть no-op")
	TEST_ASSERT_EQUAL(unknown_verdict, LIGHTING_REBUILD_VERDICT_UNCHANGED, "у уровня без записи в книге снимать нечего")
	TEST_ASSERT_EQUAL(unmeasured_verdict, LIGHTING_REBUILD_VERDICT_UNCHANGED, "незамеренный подъём обязан молчать")
	TEST_ASSERT_NULL(unmeasured_key, "незамеренный подъём вписал уровень в книгу - на Windows это заперло бы сносы навсегда")

/// Дешёвый подъём исключает уровень сразу: его цена - потолок отдачи будущего сноса.
/datum/unit_test/lighting_cheap_rebuild_excludes_zlevel
	requires_full_map = FALSE
	var/list/saved_ledger
	var/ledger_swapped = FALSE

/datum/unit_test/lighting_cheap_rebuild_excludes_zlevel/Destroy()
	if(ledger_swapped)
		SSlighting.zlevel_teardown_payoff = saved_ledger
	return ..()

/datum/unit_test/lighting_cheap_rebuild_excludes_zlevel/Run()
	saved_ledger = SSlighting.zlevel_teardown_payoff.Copy()
	ledger_swapped = TRUE
	SSlighting.zlevel_teardown_payoff = list()

	var/first_cheap_verdict = SSlighting.note_zlevel_lighting_rebuild(71, 8)
	var/excluded_without_teardown = zlevel_teardown_payoff_exhausted(SSlighting.zlevel_teardown_payoff["71"])
	var/recorded_ceiling = SSlighting.zlevel_teardown_payoff["71"]

	var/second_cheap_verdict = SSlighting.note_zlevel_lighting_rebuild(71, 5)

	var/first_fresh_verdict = SSlighting.note_zlevel_lighting_rebuild(72, 73.8)
	var/stayed_candidate = isnull(SSlighting.zlevel_teardown_payoff["72"])

	var/threshold_verdict = SSlighting.note_zlevel_lighting_rebuild(73, LIGHTING_TEARDOWN_MIN_PAYOFF_MB)
	var/threshold_key = SSlighting.zlevel_teardown_payoff["73"]


	TEST_ASSERT_EQUAL(first_cheap_verdict, LIGHTING_REBUILD_VERDICT_EXCLUDED, "дешёвый подъём обязан исключать уровень сразу, не тратя цикл сноса на замер уже известного")
	TEST_ASSERT(excluded_without_teardown, "уровень не исключён после дешёвого подъёма - первый снос раунда снова уйдёт в никуда")
	TEST_ASSERT_EQUAL(recorded_ceiling, 8, "в книгу обязана лечь фактическая цена подъёма - это потолок отдачи будущего сноса, а там [recorded_ceiling]")
	TEST_ASSERT_EQUAL(second_cheap_verdict, LIGHTING_REBUILD_VERDICT_UNCHANGED, "повторное исключение уже исключённого уровня обязано молчать")
	TEST_ASSERT_EQUAL(first_fresh_verdict, LIGHTING_REBUILD_VERDICT_UNCHANGED, "дорогой подъём чистого уровня ничего не меняет в его допуске")
	TEST_ASSERT(stayed_candidate, "дорогой подъём вписал уровень в книгу и снял его с кандидатов - сносить было бы что, а некому")
	TEST_ASSERT_EQUAL(threshold_verdict, LIGHTING_REBUILD_VERDICT_UNCHANGED, "ровно на пороге подъём обязан считаться свежим")
	TEST_ASSERT_NULL(threshold_key, "подъём ровно на пороге не должен оставлять улики")

/// Гейт давления и пауза между сносами: ниже LIGHTING_TEARDOWN_PRESSURE_HIGH обычный снос не
/// запускается, под критическим давлением пауза снимается.
/datum/unit_test/lighting_teardown_pressure_gate
	requires_full_map = FALSE

/datum/unit_test/lighting_teardown_pressure_gate/Run()
	TEST_ASSERT(!lighting_teardown_pressure_allows(0.59), "при 59% потолка снос обязан быть запрещён - именно там раунд качал свет впустую")
	TEST_ASSERT(!lighting_teardown_pressure_allows(0.67), "при 67% потолка снос обязан быть запрещён")
	TEST_ASSERT(!lighting_teardown_pressure_allows(LIGHTING_TEARDOWN_PRESSURE_HIGH - 0.01), "под самым порогом снос обязан быть запрещён")

	TEST_ASSERT(!lighting_teardown_pressure_allows(0), "неизмеренное давление не должно открывать снос")

	TEST_ASSERT(lighting_teardown_pressure_allows(LIGHTING_TEARDOWN_PRESSURE_HIGH), "ровно на пороге снос обязан открываться")
	TEST_ASSERT(lighting_teardown_pressure_allows(0.95), "у потолка снос обязан быть разрешён")

	TEST_ASSERT(lighting_teardown_pressure_allows(LIGHTING_TEARDOWN_PRESSURE_CRITICAL), "критическое давление обязано проходить гейт")

	TEST_ASSERT(lighting_teardown_spacing_elapsed(0, world.time, LIGHTING_TEARDOWN_PRESSURE_HIGH), "без единого прошлого сноса пауза между сносами не должна действовать")
	TEST_ASSERT(!lighting_teardown_spacing_elapsed(world.time, world.time, LIGHTING_TEARDOWN_PRESSURE_HIGH), "сразу после финала сноса пауза обязана действовать")
	TEST_ASSERT(!lighting_teardown_spacing_elapsed(world.time - LIGHTING_TEARDOWN_SPACING + 1, world.time, LIGHTING_TEARDOWN_PRESSURE_HIGH), "за тик до истечения паузы она обязана действовать")
	TEST_ASSERT(lighting_teardown_spacing_elapsed(world.time - LIGHTING_TEARDOWN_SPACING, world.time, LIGHTING_TEARDOWN_PRESSURE_HIGH), "ровно по истечении паузы снос обязан открываться")
	TEST_ASSERT(lighting_teardown_spacing_elapsed(world.time, world.time, LIGHTING_TEARDOWN_PRESSURE_CRITICAL), "под критическим давлением пауза между сносами обязана сниматься")

	TEST_ASSERT_EQUAL(lighting_teardown_idle_time(LIGHTING_TEARDOWN_PRESSURE_HIGH, 1), LIGHTING_TEARDOWN_IDLE_TIME_HIGH, "на самом гейте срок простоя обязан быть уже сокращённым")

/**
 * Снос и фоновая постройка одного z не должны перемалывать друг друга.
 *
 * Краулер ставит lighting_initialized после фазы 0 и строит источники дальше срезами;
 * скан кандидатов видел "поднятый пустой уровень" и начинал снос, срез сноса рвал
 * объекты краулера, краулер добивал флаг - уровень оставался помеченным поднятым при
 * снесённых объектах (тестовый прогон 30.08: три "Снос света z18" за 80 мс).
 */
/datum/unit_test/lighting_teardown_yields_to_background_init
	var/saved_bg_zlevel
	var/saved_teardown_zlevel
	var/saved_last_finished
	var/list/saved_empty_since
	var/list/saved_lit_since
	var/list/saved_ledger
	var/list/saved_pressure
	var/list/saved_lit
	var/list/saved_traits
	var/list/saved_clients
	var/list/saved_dead
	var/probe_z
	var/datum/space_level/probe_level

/datum/unit_test/lighting_teardown_yields_to_background_init/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)
	saved_bg_zlevel = SSlighting.bg_current_zlevel
	saved_teardown_zlevel = SSlighting.teardown_zlevel
	saved_last_finished = SSlighting.last_teardown_finished_at
	saved_empty_since = SSlighting.zlevel_empty_since.Copy()
	saved_lit_since = SSlighting.zlevel_lit_since.Copy()
	saved_ledger = SSlighting.zlevel_teardown_payoff.Copy()
	SSlighting.zlevel_teardown_payoff = list()
	SSlighting.zlevel_lit_since = list()
	SSlighting.last_teardown_finished_at = world.time - LIGHTING_TEARDOWN_SPACING
	saved_pressure = force_memory_pressure(LIGHTING_TEARDOWN_PRESSURE_HIGH + 0.05)
	// Уровень резервации сносу не подлежит, а скан обязан дойти до проверки краулера.
	probe_level = level
	probe_z = test_z
	saved_traits = level.traits
	level.traits = list(ZTRAIT_MINING = TRUE)
	// Соседние тесты оставляют в реестрах SSmobs своих мобов, а жилец снимает уровень с кандидатов.
	if(test_z <= length(SSmobs.clients_by_zlevel))
		saved_clients = SSmobs.clients_by_zlevel[test_z]
		SSmobs.clients_by_zlevel[test_z] = list()
	if(test_z <= length(SSmobs.dead_players_by_zlevel))
		saved_dead = SSmobs.dead_players_by_zlevel[test_z]
		SSmobs.dead_players_by_zlevel[test_z] = list()
	saved_lit = isolate_lit_deferred_zlevels(list(test_z))

	// Снос уже идёт, краулер взялся за тот же уровень - срез сноса обязан бросить работу.
	SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.teardown_zlevel = test_z
	SSlighting.teardown_phase = 0
	level.lighting_initialized = FALSE
	SSlighting.bg_current_zlevel = test_z
	SSlighting.process_zlevel_lighting_teardown()
	var/slice_aborted = !SSlighting.teardown_zlevel
	var/abort_reason = SSlighting.teardown_abort_reason

	// Контроль: без краулера тот же поднятый и давно пустой уровень скан берёт в снос.
	level.lighting_initialized = TRUE
	SSlighting.zlevel_empty_since = list()
	SSlighting.zlevel_empty_since["[test_z]"] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.bg_current_zlevel = 0
	SSlighting.scan_teardown_candidates()
	var/picked_without_crawler = SSlighting.teardown_zlevel
	SSlighting.abort_zlevel_lighting_teardown()

	// Краулер строит уровень - скан кандидатов не должен выбирать его в снос.
	level.lighting_initialized = TRUE
	SSlighting.zlevel_empty_since = list()
	SSlighting.zlevel_empty_since["[test_z]"] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.bg_current_zlevel = test_z
	SSlighting.scan_teardown_candidates()
	var/not_picked = !SSlighting.teardown_zlevel

	TEST_ASSERT(slice_aborted, "срез сноса обязан бросить уровень, который строит фоновый краулер")
	TEST_ASSERT_EQUAL(abort_reason, "фоновый краулер строит этот уровень", "причина отмены должна называть краулер")
	TEST_ASSERT_EQUAL(picked_without_crawler, test_z, "предпосылка: без краулера скан обязан взять z[test_z], иначе проверка ниже ничего не значит")
	TEST_ASSERT(not_picked, "скан кандидатов не должен начинать снос уровня под фоновой постройкой")

/datum/unit_test/lighting_teardown_yields_to_background_init/Destroy()
	SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.bg_current_zlevel = saved_bg_zlevel
	SSlighting.teardown_zlevel = saved_teardown_zlevel
	SSlighting.last_teardown_finished_at = saved_last_finished
	if(probe_level)
		probe_level.traits = saved_traits
	if(saved_clients)
		SSmobs.clients_by_zlevel[probe_z] = saved_clients
	if(saved_dead)
		SSmobs.dead_players_by_zlevel[probe_z] = saved_dead
	if(saved_lit)
		restore_lit_deferred_zlevels(saved_lit)
	if(saved_empty_since)
		SSlighting.zlevel_empty_since = saved_empty_since
	if(saved_lit_since)
		SSlighting.zlevel_lit_since = saved_lit_since
	if(saved_ledger)
		SSlighting.zlevel_teardown_payoff = saved_ledger
	if(saved_pressure)
		restore_memory_pressure(saved_pressure)
	return ..()

/// Подъём после прерванного сноса и отрицательная цена подъёма в книгу отдачи не идут.
/datum/unit_test/lighting_partial_rebuild_keeps_ledger
	requires_full_map = FALSE
	var/list/saved_ledger
	var/list/saved_partial
	var/saved_teardown_zlevel
	var/saved_teardown_objects
	var/swapped = FALSE

/datum/unit_test/lighting_partial_rebuild_keeps_ledger/Destroy()
	if(swapped)
		SSlighting.zlevel_teardown_payoff = saved_ledger
		SSlighting.zlevel_partial_teardown = saved_partial
		SSlighting.teardown_zlevel = saved_teardown_zlevel
		SSlighting.teardown_objects = saved_teardown_objects
	return ..()

/datum/unit_test/lighting_partial_rebuild_keeps_ledger/Run()
	saved_ledger = SSlighting.zlevel_teardown_payoff.Copy()
	saved_partial = SSlighting.zlevel_partial_teardown.Copy()
	saved_teardown_zlevel = SSlighting.teardown_zlevel
	saved_teardown_objects = SSlighting.teardown_objects
	swapped = TRUE
	SSlighting.zlevel_teardown_payoff = list()
	SSlighting.zlevel_partial_teardown = list()

	SSlighting.teardown_zlevel = 81
	SSlighting.teardown_objects = 500
	SSlighting.abort_zlevel_lighting_teardown()
	var/flagged_partial = SSlighting.zlevel_partial_teardown["81"]

	var/partial_verdict = SSlighting.note_zlevel_lighting_rebuild(81, 2)
	var/partial_key = SSlighting.zlevel_teardown_payoff["81"]
	var/flag_consumed = isnull(SSlighting.zlevel_partial_teardown["81"])

	var/full_verdict = SSlighting.note_zlevel_lighting_rebuild(81, 2)
	var/full_key = SSlighting.zlevel_teardown_payoff["81"]

	SSlighting.teardown_zlevel = 82
	SSlighting.teardown_objects = 500
	SSlighting.abort_zlevel_lighting_teardown(completed = TRUE)
	var/completed_flagged = SSlighting.zlevel_partial_teardown["82"]

	SSlighting.teardown_zlevel = 84
	SSlighting.teardown_objects = 0
	SSlighting.abort_zlevel_lighting_teardown()
	var/empty_abort_flagged = SSlighting.zlevel_partial_teardown["84"]

	var/negative_verdict = SSlighting.note_zlevel_lighting_rebuild(83, -121)
	var/negative_key = SSlighting.zlevel_teardown_payoff["83"]

	TEST_ASSERT(flagged_partial, "прерванный снос со снесёнными объектами обязан пометить уровень частично снесённым")
	TEST_ASSERT_EQUAL(partial_verdict, LIGHTING_REBUILD_VERDICT_UNCHANGED, "дешёвый подъём после прерванного сноса не должен объявлять исключение")
	TEST_ASSERT_NULL(partial_key, "частичный подъём вписал в книгу [partial_key] МБ как потолок отдачи - уровень заперт на раунд замером доли объектов")
	TEST_ASSERT(flag_consumed, "пометка частичного сноса обязана сниматься первым же замеренным подъёмом")
	TEST_ASSERT_EQUAL(full_verdict, LIGHTING_REBUILD_VERDICT_EXCLUDED, "полный дешёвый подъём после снятой пометки обязан исключать уровень как обычно")
	TEST_ASSERT_EQUAL(full_key, 2, "полный дешёвый подъём обязан записать свою цену в книгу")
	TEST_ASSERT_NULL(completed_flagged, "уборка после завершённого сноса не должна помечать уровень частичным")
	TEST_ASSERT_NULL(empty_abort_flagged, "обрыв без снесённых объектов не должен помечать уровень частичным")
	TEST_ASSERT_EQUAL(negative_verdict, LIGHTING_REBUILD_VERDICT_UNCHANGED, "отрицательная цена подъёма не должна ничего решать")
	TEST_ASSERT_NULL(negative_key, "отрицательная цена подъёма легла в книгу - чужое освобождение исключило уровень")

/// Гост держит и заказывает свет отложенного уровня, только если сам включил себе темноту.
/datum/unit_test/lighting_ghost_holds_level_only_with_darkness

/datum/unit_test/lighting_ghost_holds_level_only_with_darkness/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)
	TEST_ASSERT(test_z <= length(SSmobs.dead_players_by_zlevel), "предпосылка: реестр мёртвых обязан покрывать тестовый z")

	var/old_init = level.lighting_initialized
	var/list/saved_clients = SSmobs.clients_by_zlevel[test_z]
	var/list/saved_dead = SSmobs.dead_players_by_zlevel[test_z]
	level.lighting_initialized = FALSE
	SSmobs.clients_by_zlevel[test_z] = list()

	var/mob/dead/observer/watcher = allocate(/mob/dead/observer, test_turf)
	SSmobs.dead_players_by_zlevel[test_z] = list(watcher)

	var/default_ghost_free = !SSlighting.zlevel_has_occupant(test_z)
	var/default_ghost_no_build = !ghost_ondemand_init_still_wanted(test_z)
	var/default_ghost_no_request = !watcher.request_ghost_lighting_init(test_z)

	watcher.lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	var/dark_ghost_holds = SSlighting.zlevel_has_occupant(test_z)
	var/dark_ghost_builds = ghost_ondemand_init_still_wanted(test_z)
	// Включение темноты на неподнятом уровне обязано взводить ту же заявку, что и смена z.
	var/dark_ghost_requests = watcher.request_ghost_lighting_init(test_z)

	watcher.lighting_alpha = LIGHTING_PLANE_ALPHA_INVISIBLE
	var/blind_ghost_free = !SSlighting.zlevel_has_occupant(test_z)

	// Живой клиент держит уровень безусловно: его собственная альфа тут ни при чём.
	var/mob/living/carbon/human/miner = allocate(/mob/living/carbon/human, test_turf)
	miner.lighting_alpha = LIGHTING_PLANE_ALPHA_INVISIBLE
	SSmobs.clients_by_zlevel[test_z] = list(miner)
	var/living_holds = SSlighting.zlevel_has_occupant(test_z)

	SSmobs.clients_by_zlevel[test_z] = saved_clients
	SSmobs.dead_players_by_zlevel[test_z] = saved_dead
	level.lighting_initialized = old_init

	TEST_ASSERT(default_ghost_free, "гост со штатной альфой удержал свет целого z, хотя разницы не видит")
	TEST_ASSERT(default_ghost_no_build, "ради госта со штатной альфой строится свет целого z")
	TEST_ASSERT(default_ghost_no_request, "гост со штатной альфой взвёл заявку на подъём света")
	TEST_ASSERT(dark_ghost_holds, "гост с включённой темнотой не считается жильцом - уровень снесут под ним")
	TEST_ASSERT(dark_ghost_builds, "госту с включённой темнотой не построят свет, он останется в темноте")
	TEST_ASSERT(dark_ghost_requests, "включение темноты на неподнятом уровне не взвело заявку на подъём")
	TEST_ASSERT(blind_ghost_free, "гост с выключенной плоскостью света удержал уровень")
	TEST_ASSERT(living_holds, "живой клиент обязан держать уровень независимо от своей альфы")

/// Парковка источников сносом дополняет кэш отложенных z, а сейфнет-скан кэшу верит.
/datum/unit_test/lighting_teardown_extends_deferred_z_cache

/datum/unit_test/lighting_teardown_extends_deferred_z_cache/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting не инициализирована")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)

	var/old_init = level.lighting_initialized
	var/old_teardown = SSlighting.teardown_zlevel
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()
	var/saved_cache = GLOB.lighting_deferred_z_cache
	var/list/saved_clients = SSmobs.clients_by_zlevel[test_z]
	var/list/saved_dead = SSmobs.dead_players_by_zlevel[test_z]
	var/list/saved_empty = SSlighting.zlevel_empty_since.Copy()
	SSmobs.clients_by_zlevel[test_z] = list()
	SSmobs.dead_players_by_zlevel[test_z] = list()

	// Живой источник на уровне, который сейчас снесут: фаза 0 обязана его запарковать.
	level.lighting_initialized = TRUE
	var/obj/effect/light_emitter/emitter = allocate(/obj/effect/light_emitter, test_turf)
	emitter.set_light(3, 1, COLOR_WHITE)
	var/precond_live = !isnull(emitter.light)

	GLOB.lighting_deferred_z_cache = list()
	SSlighting.abort_zlevel_lighting_teardown()
	SSlighting.begin_zlevel_lighting_teardown(test_z)
	// Крутим ровно фазу 0: объекты и углы уровня трогать незачем, проверяется парковка.
	var/saved_can_fire = detach_subsystem(SSlighting)
	var/slices = 0
	while(SSlighting.teardown_zlevel && !SSlighting.teardown_phase && slices < 500)
		SSlighting.state = SS_RUNNING
		SSlighting.process_zlevel_lighting_teardown()
		slices++
		CHECK_TICK
	release_subsystem(SSlighting, saved_can_fire)
	SSlighting.abort_zlevel_lighting_teardown()

	var/parked = (emitter in GLOB.lighting_deferred_atoms)
	var/list/parked_snapshot = GLOB.lighting_deferred_atoms.Copy()
	var/list/cache_after = GLOB.lighting_deferred_z_cache
	var/cache_kept = islist(cache_after)
	var/cache_has_z = cache_kept && (test_z in cache_after)

	// Скан обязан верить кэшу: полный проход пересобрал бы его и вписал туда z атома.
	GLOB.lighting_deferred_atoms = list(emitter)
	GLOB.lighting_deferred_z_cache = list()
	SSlighting.stuck_scan_busy_until = 0
	SSlighting.scan_stuck_deferred_zlevels()
	var/list/cache_after_scan = GLOB.lighting_deferred_z_cache
	var/scan_trusted_cache = islist(cache_after_scan) && !(test_z in cache_after_scan)

	SSlighting.teardown_zlevel = old_teardown
	SSlighting.zlevel_empty_since = saved_empty
	SSmobs.clients_by_zlevel[test_z] = saved_clients
	SSmobs.dead_players_by_zlevel[test_z] = saved_dead
	// Снятые фазой 0 источники обязаны ожить обратно, иначе тест оставит уровень тёмным.
	GLOB.lighting_deferred_atoms = parked_snapshot
	level.lighting_initialized = FALSE
	create_lighting_for_zlevel(test_z)
	level.lighting_initialized = old_init
	GLOB.lighting_deferred_atoms |= saved_deferred
	GLOB.lighting_deferred_z_cache = saved_cache

	TEST_ASSERT(precond_live, "предпосылка: источник обязан быть живым до сноса")
	TEST_ASSERT(parked, "фаза 0 не запарковала источник, тест проверил бы не то")
	TEST_ASSERT(cache_kept, "снос выбросил кэш отложенных z - сейфнет-скан пересоберёт его полным проходом")
	TEST_ASSERT(cache_has_z, "снос не вписал свой z в кэш - сейфнет потеряет запаркованные им атомы")
	TEST_ASSERT(scan_trusted_cache, "сейфнет-скан пересобрал кэш вместо того, чтобы ему поверить")

#undef LIGHTING_TEST_PRESSURE_CEILING_MB
