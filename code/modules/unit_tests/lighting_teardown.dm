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

/// Возвращает флаги поднятости, снятые isolate_lit_deferred_zlevels().
/datum/unit_test/proc/restore_lit_deferred_zlevels(list/snapshot)
	for(var/datum/space_level/level as anything in SSmapping.z_list)
		var/saved = snapshot["[level.z_value]"]
		if(!isnull(saved))
			level.lighting_initialized = saved

/// Прокручивает снос до конца (или до заявленного лимита срезов), удерживая подсистему
/// в состоянии SS_RUNNING. Возвращает число потраченных срезов.
/datum/unit_test/proc/drive_lighting_teardown(max_slices = 4000)
	var/old_state = SSlighting.state
	var/slices = 0
	while(SSlighting.teardown_zlevel && slices < max_slices)
		SSlighting.state = SS_RUNNING
		SSlighting.process_zlevel_lighting_teardown()
		slices++
		CHECK_TICK
	SSlighting.state = old_state
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

/// Выбор кандидата: уровень берётся, только когда он отложенный, поднятый и пустует дольше порога.
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
	restore_lit_deferred_zlevels(saved_lit)
	level.lighting_initialized = old_init

	TEST_ASSERT(!picked_too_early, "уровень взяли на снос в ту же секунду, как он опустел (выбран z[picked_too_early])")
	TEST_ASSERT(timer_started, "таймер простоя не засёкся")
	TEST_ASSERT_EQUAL(picked_when_stale, test_z, "уровень, пустующий дольше порога, не взяли на снос")
	TEST_ASSERT(cleared_init_flag, "снос не снял lighting_initialized - вошедший игрок остался бы в темноте без пути наверх")
	TEST_ASSERT(dropped_timer, "таймер простоя не сброшен при старте сноса")
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
	SSlighting.teardown_zlevel = old_teardown
	level.traits = saved_traits
	level.lighting_initialized = old_init || level.lighting_initialized

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
	var/old_state = SSlighting.state
	SSlighting.state = SS_RUNNING
	SSlighting.process_zlevel_lighting_teardown()
	SSlighting.state = old_state
	var/aborted_on_reinit = !SSlighting.teardown_zlevel

	// И вторая причина бросить работу: чужой подъём держит init_in_progress.
	level.lighting_initialized = FALSE
	SSlighting.begin_zlevel_lighting_teardown(test_z)
	var/old_in_progress = SSlighting.init_in_progress
	SSlighting.init_in_progress = TRUE
	old_state = SSlighting.state
	SSlighting.state = SS_RUNNING
	SSlighting.process_zlevel_lighting_teardown()
	SSlighting.state = old_state
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

	// Гост на месте - свет обязан строиться, иначе он останется в темноте.
	var/mob/dead/observer/watcher = allocate(/mob/dead/observer, test_turf)
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
