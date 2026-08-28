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
	var/list/saved_traits = level.traits
	var/key = "[test_z]"

	// Тестовый z - резервация, а её сносить нельзя (её постоянно перерабатывают шаттлы,
	// см. zlevel_lighting_teardownable). На время проверки выдаём уровню шахтёрский трейт:
	// именно такие уровни механизм и разбирает.
	level.traits = list(ZTRAIT_MINING = TRUE)

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

	// 3. Поднятый, но НЕ отложенный уровень не кандидат никогда: поднять его обратно нечем.
	level.lighting_initialized = TRUE
	level.traits = list()
	SSlighting.teardown_zlevel = 0
	SSlighting.zlevel_empty_since[key] = world.time - LIGHTING_TEARDOWN_IDLE_TIME - 1
	SSlighting.scan_teardown_candidates()
	var/picked_non_deferred = SSlighting.teardown_zlevel
	var/forgot_non_deferred = isnull(SSlighting.zlevel_empty_since[key])

	// 4. Резервацию не сносим никогда, хотя откладывать её на старте и правильно.
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
	level.lighting_initialized = old_init

	TEST_ASSERT(!picked_too_early, "уровень взяли на снос в ту же секунду, как он опустел (выбран z[picked_too_early])")
	TEST_ASSERT(timer_started, "таймер простоя не засёкся")
	TEST_ASSERT_EQUAL(picked_when_stale, test_z, "уровень, пустующий дольше порога, не взяли на снос")
	TEST_ASSERT(cleared_init_flag, "снос не снял lighting_initialized - вошедший игрок остался бы в темноте без пути наверх")
	TEST_ASSERT(dropped_timer, "таймер простоя не сброшен при старте сноса")
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
