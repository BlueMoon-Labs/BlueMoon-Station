// Регрессии репорта "после телепорта статика чёрная 40с/никогда" (ветка lighting-overlay-port).
//
// Reserved/mining z-уровни (эвеи, руины, лавалэнд, резервации) НЕ инициализируются на раундстарте:
// их источники паркуются в GLOB.lighting_deferred_atoms (lighting_atom.dm), а свет строится on-demand
// при входе первого клиента через create_lighting_for_zlevel (living_movement.dm -> update_z).
//
// Два дефекта этого пути:
//  A) create_lighting_for_zlevel НЕ дренит свой бэклог - отдаёт его SSlighting.fire() под адаптивным
//     капом, который под нагрузкой атмоса падает до ~20-40 источников/fire. Турфы занятой игроком z
//     стоят чёрными десятки секунд, пока очередь дренится. Контракт: занятую z дренить синхронно.
//  B) Проц ставит level.lighting_initialized = TRUE ДО работы и рано выходит, если флаг уже TRUE.
//     Если init прервался (рантайм/старвейшн), z помечена "готова" с не сфлашенными источниками и
//     НИЧЕГО не перезапустит. Контракт: самовосстановление - дренить осевшие отложенные атомы даже
//     если флаг уже TRUE.
//
// Ассерты source-local (light источника, очереди, GLOB.lighting_deferred_atoms) - на reserved z
// тестовой зоны view() пуст, кросс-тайловую яркость не меряем. T2/T3 вычисляют результат и
// восстанавливают глобальное состояние ДО ассертов (TEST_ASSERT делает return при провале).

/// Хелпер: паркует свежий light_emitter как отложенный источник на (reserved, не-инициализированной) z.
/// Возвращает запаркованный эмиттер; вызывающий обязан восстановить флаг/очереди.
/datum/unit_test/proc/park_deferred_emitter(turf/test_turf, datum/space_level/level)
	level.lighting_initialized = FALSE
	var/obj/effect/light_emitter/emitter = allocate(/obj/effect/light_emitter, test_turf)
	QDEL_NULL(emitter.light) // дефолтный power=0 источник не создаёт, но подстрахуемся
	emitter.set_light(3, 1, COLOR_WHITE) // power/range/on заданы -> уходит в отложку, а не в живой источник
	return emitter

/// Характеризация: на не-инициализированной reserved z update_light() паркует источник, а не создаёт.
/datum/unit_test/light_deferred_z_parks_source/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/datum/space_level/level = SSmapping.get_level(test_turf.z)
	TEST_ASSERT_NOTNULL(level, "test z-level datum missing")
	TEST_ASSERT(level.traits[ZTRAIT_RESERVED], "test premise: reservation z must carry ZTRAIT_RESERVED")

	var/old_init = level.lighting_initialized
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()

	var/obj/effect/light_emitter/emitter = park_deferred_emitter(test_turf, level)
	var/has_source = !isnull(emitter.light)
	var/is_parked = (emitter in GLOB.lighting_deferred_atoms)

	GLOB.lighting_deferred_atoms = saved_deferred
	level.lighting_initialized = old_init

	TEST_ASSERT(!has_source, "On a deferred (uninitialized reserved) z, update_light must NOT create a live source")
	TEST_ASSERT(is_parked, "Deferred light atom must be parked in GLOB.lighting_deferred_atoms")

/// Fix A: on-demand init занятой игроком z дренит свой бэклог синхронно, а не оставляет его
/// в throttled-очереди (иначе турфы чёрные, пока fire() медленно дренит под капом).
/datum/unit_test/light_ondemand_init_drains_occupied_z_backlog/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)

	var/old_init = level.lighting_initialized
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()
	var/list/saved_lights = GLOB.lighting_update_lights.Copy()
	var/list/saved_corners = GLOB.lighting_update_corners.Copy()
	var/list/saved_objects = GLOB.lighting_update_objects.Copy()

	var/obj/effect/light_emitter/emitter = park_deferred_emitter(test_turf, level)
	var/precond_parked = (emitter in GLOB.lighting_deferred_atoms)
	var/precond_no_source = isnull(emitter.light)

	// Изолируем очереди, чтобы проверить, что on-demand init сдренил ИМЕННО свою работу.
	GLOB.lighting_update_lights.Cut()
	GLOB.lighting_update_corners.Cut()
	GLOB.lighting_update_objects.Cut()

	create_lighting_for_zlevel(test_z)

	var/flushed = !(emitter in GLOB.lighting_deferred_atoms)
	var/has_source = !isnull(emitter.light)
	// Контракт Fix A ассертим source-local: источник игрока обработан синхронно, а не оставлен
	// в throttled-очереди fire(). Глобальные очереди не меряем: во время CHECK_TICK-снов дрейна
	// fire() легитимно доливает работу (фоновый инит другого z, отложенный старлайт этого z).
	var/source_still_queued = has_source && (emitter.light in GLOB.lighting_update_lights)
	var/source_still_dirty = has_source && emitter.light.needs_update != LIGHTING_NO_UPDATE

	GLOB.lighting_update_lights = saved_lights
	GLOB.lighting_update_corners = saved_corners
	GLOB.lighting_update_objects = saved_objects
	GLOB.lighting_deferred_atoms = saved_deferred
	level.lighting_initialized = old_init

	TEST_ASSERT(precond_parked, "precondition: emitter should be parked as deferred")
	TEST_ASSERT(precond_no_source, "precondition: deferred emitter must have no live source yet")
	TEST_ASSERT(flushed, "on-demand init must flush the deferred atom")
	TEST_ASSERT(has_source, "on-demand init must create the deferred light source")
	// Контракт Fix A: источник занятой z дренится синхронно, а не оставляется throttled-очереди.
	TEST_ASSERT(!source_still_queued, "on-demand init must drain the flushed source synchronously, not leave it in the throttled fire() queue")
	TEST_ASSERT(!source_still_dirty, "the flushed source must come out of the drain fully processed (needs_update == LIGHTING_NO_UPDATE)")

/// Fix B: повторный on-demand init самовосстанавливает застрявшую z - флашит осевшие отложенные
/// источники, даже если уровень уже помечен lighting_initialized (прерванный init = вечная чернота).
/datum/unit_test/light_ondemand_init_self_heals_stuck_zlevel/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)

	var/old_init = level.lighting_initialized
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()

	// Паркуем источник с валидными параметрами (флаг временно FALSE),...
	var/obj/effect/light_emitter/emitter = park_deferred_emitter(test_turf, level)
	var/precond_parked = (emitter in GLOB.lighting_deferred_atoms)
	var/precond_no_source = isnull(emitter.light)

	// ...затем имитируем прерванный init: флаг выставлен TRUE, но источник так и не сфлашен.
	level.lighting_initialized = TRUE

	create_lighting_for_zlevel(test_z)

	var/flushed = !(emitter in GLOB.lighting_deferred_atoms)
	var/has_source = !isnull(emitter.light)

	GLOB.lighting_deferred_atoms = saved_deferred
	level.lighting_initialized = old_init

	TEST_ASSERT(precond_parked, "precondition: emitter parked as deferred")
	TEST_ASSERT(precond_no_source, "precondition: stuck deferred emitter has no live source")
	TEST_ASSERT(flushed, "self-heal: on-demand init must flush a deferred atom left on an already-initialized z")
	TEST_ASSERT(has_source, "self-heal: orphaned deferred light source must be created on re-init")

// ----------------------------------------------------------------------------------------------------
// Fix 1 (S4, гхосты): /mob/dead/update_z не триггерил on-demand init - призрак на отложенном z сидел в
// темноте. Фикс выносит синхронный гейт в should_ondemand_init_zlevel() и зовёт его из обоих update_z.
// В юнит-тестах у мобов нет client, поэтому полный путь /mob/dead/update_z не прогнать (гейт на if(client));
// тестируем сам предикат - именно его решает оба пути.
// ----------------------------------------------------------------------------------------------------

/// Fix 1: предикат ДОЛЖЕН разрешить on-demand init для неинициализированного, не-deferred-batch z при готовых SS.
/datum/unit_test/light_ondemand_gate_fires_for_uninitialized_z/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/datum/space_level/level = SSmapping.get_level(test_turf.z)
	var/old_init = level.lighting_initialized
	var/old_defer = GLOB.lighting_defer_active

	level.lighting_initialized = FALSE
	GLOB.lighting_defer_active = FALSE
	var/fired = should_ondemand_init_zlevel(test_turf.z)

	level.lighting_initialized = old_init
	GLOB.lighting_defer_active = old_defer

	TEST_ASSERT(fired, "should_ondemand_init_zlevel must return TRUE for an uninitialized, non-deferred z while SS are ready (the gate both update_z paths use to schedule on-demand init)")

/// Fix 1: предикат НЕ должен срабатывать на уже инициализированном z (без избыточного повторного init).
/datum/unit_test/light_ondemand_gate_skips_initialized_z/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/datum/space_level/level = SSmapping.get_level(test_turf.z)
	var/old_init = level.lighting_initialized

	level.lighting_initialized = TRUE
	var/fired = should_ondemand_init_zlevel(test_turf.z)

	level.lighting_initialized = old_init

	TEST_ASSERT(!fired, "gate must NOT fire for an already lighting_initialized z (no redundant on-demand init)")

/// Fix 1: предикат НЕ должен срабатывать пока идёт bulk-операция (shuttle docking владеет светом).
/datum/unit_test/light_ondemand_gate_skips_during_defer_active/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/datum/space_level/level = SSmapping.get_level(test_turf.z)
	var/old_init = level.lighting_initialized
	var/old_defer = GLOB.lighting_defer_active
	TEST_ASSERT(!old_defer, "precondition: lighting_defer_active must start FALSE so this test controls it")

	level.lighting_initialized = FALSE
	GLOB.lighting_defer_active = TRUE
	var/fired = should_ondemand_init_zlevel(test_turf.z)

	level.lighting_initialized = old_init
	GLOB.lighting_defer_active = old_defer

	TEST_ASSERT(!fired, "gate must NOT fire while GLOB.lighting_defer_active (bulk shuttle docking owns lighting)")

// ----------------------------------------------------------------------------------------------------
// Fix 2 (S3, "не грузит никогда"): self-heal недостижим для стоящего на месте игрока - его никто не
// перезовёт. Периодический SSlighting.scan_stuck_deferred_zlevels() добивает z с осевшими отложенными
// атомами, НА КОТОРОМ ЕСТЬ ОБИТАТЕЛЬ (живой клиент или призрак), и оставляет пустые отложенные z в покое.
// ----------------------------------------------------------------------------------------------------

/// Fix 2: скан восстанавливает застрявший z (флаг TRUE + осевшие атомы) при наличии обитателя.
/datum/unit_test/light_safetynet_recovers_stuck_zlevel_with_occupant/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)

	var/old_init = level.lighting_initialized
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()
	var/list/saved_lights = GLOB.lighting_update_lights.Copy()
	var/list/saved_corners = GLOB.lighting_update_corners.Copy()
	var/list/saved_objects = GLOB.lighting_update_objects.Copy()
	TEST_ASSERT(test_z <= length(SSmobs.dead_players_by_zlevel), "test premise: dead_players_by_zlevel must have a slot for the reservation z")
	var/list/saved_deadslot = SSmobs.dead_players_by_zlevel[test_z]

	// Паркуем источник, затем имитируем прерванный init: флаг TRUE, источник так и не сфлашен.
	var/obj/effect/light_emitter/emitter = park_deferred_emitter(test_turf, level)
	var/precond_parked = (emitter in GLOB.lighting_deferred_atoms)
	GLOB.lighting_deferred_atoms = list(emitter) // изолируем скан строго на тестовый z
	level.lighting_initialized = TRUE
	SSmobs.dead_players_by_zlevel[test_z] = list(src) // обитатель: скан смотрит только length>0
	GLOB.lighting_update_lights.Cut()
	GLOB.lighting_update_corners.Cut()
	GLOB.lighting_update_objects.Cut()

	SSlighting.scan_stuck_deferred_zlevels()

	var/flushed = !(emitter in GLOB.lighting_deferred_atoms)
	var/has_source = !isnull(emitter.light)

	GLOB.lighting_update_lights = saved_lights
	GLOB.lighting_update_corners = saved_corners
	GLOB.lighting_update_objects = saved_objects
	GLOB.lighting_deferred_atoms = saved_deferred
	SSmobs.dead_players_by_zlevel[test_z] = saved_deadslot
	level.lighting_initialized = old_init

	TEST_ASSERT(precond_parked, "precondition: emitter parked as deferred on the uninitialized reserved z")
	TEST_ASSERT(flushed, "safety-net scan must flush a deferred atom orphaned on an occupied z flagged initialized (the 'never loads' case)")
	TEST_ASSERT(has_source, "safety-net scan must create the orphaned deferred light source")

/// Fix 2: скан НЕ должен форс-инитить отложенный z без обитателя (сохраняем оптимизацию отложки).
/datum/unit_test/light_safetynet_skips_zlevel_without_occupant/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)

	var/old_init = level.lighting_initialized
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()
	var/list/saved_lights = GLOB.lighting_update_lights.Copy()
	var/list/saved_corners = GLOB.lighting_update_corners.Copy()
	var/list/saved_objects = GLOB.lighting_update_objects.Copy()
	TEST_ASSERT(test_z <= length(SSmobs.clients_by_zlevel), "test premise: clients_by_zlevel slot must exist for reservation z")
	TEST_ASSERT(test_z <= length(SSmobs.dead_players_by_zlevel), "test premise: dead_players_by_zlevel slot must exist for reservation z")
	var/list/saved_clientslot = SSmobs.clients_by_zlevel[test_z]
	var/list/saved_deadslot = SSmobs.dead_players_by_zlevel[test_z]

	var/obj/effect/light_emitter/emitter = park_deferred_emitter(test_turf, level)
	var/precond_parked = (emitter in GLOB.lighting_deferred_atoms)
	GLOB.lighting_deferred_atoms = list(emitter) // изолируем скан строго на тестовый z
	SSmobs.clients_by_zlevel[test_z] = list() // никаких обитателей на этом z
	SSmobs.dead_players_by_zlevel[test_z] = list()
	GLOB.lighting_update_lights.Cut()
	GLOB.lighting_update_corners.Cut()
	GLOB.lighting_update_objects.Cut()

	SSlighting.scan_stuck_deferred_zlevels()

	var/still_parked = (emitter in GLOB.lighting_deferred_atoms)
	var/no_source = isnull(emitter.light)

	GLOB.lighting_update_lights = saved_lights
	GLOB.lighting_update_corners = saved_corners
	GLOB.lighting_update_objects = saved_objects
	GLOB.lighting_deferred_atoms = saved_deferred
	SSmobs.clients_by_zlevel[test_z] = saved_clientslot
	SSmobs.dead_players_by_zlevel[test_z] = saved_deadslot
	level.lighting_initialized = old_init

	TEST_ASSERT(precond_parked, "precondition: emitter parked as deferred")
	TEST_ASSERT(still_parked, "safety-net scan must NOT force-init a deferred z with no occupant (preserve the deferral optimization)")
	TEST_ASSERT(no_source, "no live source may be created for an unoccupied deferred z")

// ----------------------------------------------------------------------------------------------------
// Fix 3 (S1-регресс): синхронный дренаж завершался безусловным .Cut(), стирая источник, дозапханный в
// очередь во время CHECK_TICK-засыпания (его needs_update != NO_UPDATE -> EFFECT_UPDATE-гард больше не
// перезапишет -> stranded dark). Fix: prefix-cut как в fire(), дозапханное остаётся в очереди для fire().
// Тестовый источник имитирует дозапихивание "брата" в очередь прямо во время дренажа (синхронно, без
// зависимости от реального CHECK_TICK-yield).
// ----------------------------------------------------------------------------------------------------

/// Тестовый источник: при первом update_corners() синхронно дозапихивает sibling в очередь источников -
/// имитация EFFECT_UPDATE во время CHECK_TICK-засыпания дренажа (sibling оказывается за границей снапшота).
/datum/light_source/test_drain_trojan
	var/datum/light_source/sibling
	var/has_appended = FALSE

/datum/light_source/test_drain_trojan/update_corners()
	if(!has_appended && sibling)
		has_appended = TRUE
		GLOB.lighting_update_lights += sibling
	return

/datum/unit_test/light_drain_snapshot_keeps_appended_source/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")
	var/turf/test_turf = run_loc_floor_bottom_left

	var/list/saved_lights = GLOB.lighting_update_lights.Copy()
	var/list/saved_corners = GLOB.lighting_update_corners.Copy()
	var/list/saved_objects = GLOB.lighting_update_objects.Copy()

	var/datum/light_source/test_drain_trojan/trojan = new(test_turf, test_turf)
	var/datum/light_source/sibling = new(test_turf, test_turf)
	sibling.needs_update = LIGHTING_CHECK_UPDATE // dirtied + уже в очереди: EFFECT_UPDATE-гард откажется перезапихивать
	trojan.sibling = sibling
	trojan.needs_update = LIGHTING_CHECK_UPDATE

	// В снапшоте только trojan; он дозапихивает sibling за границу снапшота во время дренажа.
	GLOB.lighting_update_lights = list(trojan)
	GLOB.lighting_update_corners.Cut()
	GLOB.lighting_update_objects.Cut()

	drain_lighting_queues_snapshot()

	var/trojan_removed = !(trojan in GLOB.lighting_update_lights)
	// The fix guarantees the appended sibling is never STRANDED: either it stays queued for a later
	// fire() (no CHECK_TICK yield in the drain), or a live fire() that ran during the yield already
	// processed it (removed AND needs_update cleared). The bug (blanket .Cut()) leaves it absent yet
	// still dirty, after which EFFECT_UPDATE's guard refuses to re-enqueue it -> permanently dark.
	// Asserting "not stranded" stays deterministic regardless of whether the in-test drain yielded.
	var/sibling_stranded = !(sibling in GLOB.lighting_update_lights) && (sibling.needs_update != LIGHTING_NO_UPDATE)

	GLOB.lighting_update_lights = saved_lights
	GLOB.lighting_update_corners = saved_corners
	GLOB.lighting_update_objects = saved_objects
	qdel(trojan, force = TRUE)
	qdel(sibling, force = TRUE)

	TEST_ASSERT(trojan_removed, "the processed source must be cut from the queue")
	TEST_ASSERT(!sibling_stranded, "a source enqueued during the drain must never end stranded (absent from every queue yet still dirty); prefix-cut keeps it for fire() instead of blanket-discarding it")

// ----------------------------------------------------------------------------------------------------
// Гонки on-demand инита: два параллельных create_lighting_for_zlevel (или инит против фонового краула)
// не должны терять атомы, запаркованные во время CHECK_TICK-сна. Инвариант: глобальный список
// НИКОГДА не переприсваивается устаревшим снапшотом - флаш убирает только обработанные атомы.
// ----------------------------------------------------------------------------------------------------

/// Флаш отложенных атомов не подменяет объект GLOB.lighting_deferred_atoms: атомы, добавленные
/// в живой список во время сна инита, обязаны пережить завершение прогона.
/datum/unit_test/light_ondemand_flush_keeps_deferred_list_object/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)

	var/old_init = level.lighting_initialized
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()
	var/list/saved_lights = GLOB.lighting_update_lights.Copy()
	var/list/saved_corners = GLOB.lighting_update_corners.Copy()
	var/list/saved_objects = GLOB.lighting_update_objects.Copy()

	// Фоновый инит на паузу на время прогона: его Phase 1/2 легально ПОДМЕНЯЮТ объект
	// GLOB.lighting_deferred_atoms (сплайс без yield'ов внутри fire - для прода это
	// безопасно), и, попав в CHECK_TICK-сон нашего create_lighting_for_zlevel, фоновая
	// подмена роняла проверку идентичности списка, которая тестирует именно on-demand путь.
	var/old_bg_current = SSlighting.bg_current_zlevel
	var/old_bg_phase = SSlighting.bg_phase
	var/list/old_bg_turfs = SSlighting.bg_turfs
	var/old_bg_index = SSlighting.bg_turf_index
	var/list/old_bg_queue = SSlighting.bg_queued_zlevels
	SSlighting.bg_current_zlevel = 0
	SSlighting.bg_queued_zlevels = list()

	var/obj/effect/light_emitter/emitter = park_deferred_emitter(test_turf, level)
	var/precond_parked = (emitter in GLOB.lighting_deferred_atoms)
	GLOB.lighting_update_lights.Cut()
	GLOB.lighting_update_corners.Cut()
	GLOB.lighting_update_objects.Cut()
	var/list/live_list_before = GLOB.lighting_deferred_atoms

	create_lighting_for_zlevel(test_z)

	var/same_list_object = (GLOB.lighting_deferred_atoms == live_list_before)
	var/flushed = !(emitter in GLOB.lighting_deferred_atoms)

	GLOB.lighting_update_lights = saved_lights
	GLOB.lighting_update_corners = saved_corners
	GLOB.lighting_update_objects = saved_objects
	GLOB.lighting_deferred_atoms = saved_deferred
	level.lighting_initialized = old_init
	// Восстановление фонового инита. Середину прогона по нашему test_z не восстанавливаем:
	// прод-семантика create_lighting_for_zlevel - отменить фоновый краул этого z.
	if(old_bg_current != test_z)
		SSlighting.bg_current_zlevel = old_bg_current
		SSlighting.bg_phase = old_bg_phase
		SSlighting.bg_turfs = old_bg_turfs
		SSlighting.bg_turf_index = old_bg_index
	SSlighting.bg_queued_zlevels = old_bg_queue

	TEST_ASSERT(precond_parked, "precondition: emitter parked as deferred")
	TEST_ASSERT(flushed, "on-demand init must flush the parked atom for its z")
	TEST_ASSERT(same_list_object, "flush must mutate GLOB.lighting_deferred_atoms in place, not swap the list object (a swap loses atoms parked into the live list during CHECK_TICK sleeps of a concurrent run)")

/// Рантайм внутри спасательного вызова не должен вечно отключать сейфнет: маркер занятости
/// скана обязан протухать, а не латчиться навсегда.
/datum/unit_test/light_safetynet_survives_crashed_scan/Run()
	TEST_ASSERT(SSlighting.initialized, "SSlighting was not initialized")
	var/turf/test_turf = run_loc_floor_bottom_left
	var/test_z = test_turf.z
	var/datum/space_level/level = SSmapping.get_level(test_z)

	var/old_init = level.lighting_initialized
	var/list/saved_deferred = GLOB.lighting_deferred_atoms.Copy()
	var/list/saved_lights = GLOB.lighting_update_lights.Copy()
	var/list/saved_corners = GLOB.lighting_update_corners.Copy()
	var/list/saved_objects = GLOB.lighting_update_objects.Copy()
	TEST_ASSERT(test_z <= length(SSmobs.dead_players_by_zlevel), "test premise: dead_players_by_zlevel must have a slot for the reservation z")
	var/list/saved_deadslot = SSmobs.dead_players_by_zlevel[test_z]

	var/obj/effect/light_emitter/emitter = park_deferred_emitter(test_turf, level)
	var/precond_parked = (emitter in GLOB.lighting_deferred_atoms)
	GLOB.lighting_deferred_atoms = list(emitter)
	level.lighting_initialized = TRUE
	SSmobs.dead_players_by_zlevel[test_z] = list(src)
	GLOB.lighting_update_lights.Cut()
	GLOB.lighting_update_corners.Cut()
	GLOB.lighting_update_objects.Cut()

	// Имитация скана, упавшего с рантаймом: лиза взята и не сброшена, но уже протухла
	SSlighting.stuck_scan_busy_until = world.time

	SSlighting.scan_stuck_deferred_zlevels()

	var/flushed = !(emitter in GLOB.lighting_deferred_atoms)
	var/has_source = !isnull(emitter.light)

	SSlighting.stuck_scan_busy_until = 0
	GLOB.lighting_update_lights = saved_lights
	GLOB.lighting_update_corners = saved_corners
	GLOB.lighting_update_objects = saved_objects
	GLOB.lighting_deferred_atoms = saved_deferred
	SSmobs.dead_players_by_zlevel[test_z] = saved_deadslot
	level.lighting_initialized = old_init

	TEST_ASSERT(precond_parked, "precondition: emitter parked as deferred")
	TEST_ASSERT(flushed, "a stale busy marker left by a crashed scan must not block future rescues (lease must expire, not latch)")
	TEST_ASSERT(has_source, "the rescued deferred source must be created despite the stale busy marker")
