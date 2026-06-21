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
	var/lights_left = GLOB.lighting_update_lights.len
	var/corners_left = GLOB.lighting_update_corners.len
	var/objects_left = GLOB.lighting_update_objects.len

	GLOB.lighting_update_lights = saved_lights
	GLOB.lighting_update_corners = saved_corners
	GLOB.lighting_update_objects = saved_objects
	GLOB.lighting_deferred_atoms = saved_deferred
	level.lighting_initialized = old_init

	TEST_ASSERT(precond_parked, "precondition: emitter should be parked as deferred")
	TEST_ASSERT(precond_no_source, "precondition: deferred emitter must have no live source yet")
	TEST_ASSERT(flushed, "on-demand init must flush the deferred atom")
	TEST_ASSERT(has_source, "on-demand init must create the deferred light source")
	// Контракт Fix A: занятую z дренить синхронно, не оставляя бэклог в throttled-очереди.
	TEST_ASSERT_EQUAL(lights_left, 0, "on-demand init for an occupied z must drain its light source backlog (left [lights_left] queued)")
	TEST_ASSERT_EQUAL(corners_left, 0, "on-demand init must drain queued corners (left [corners_left])")
	TEST_ASSERT_EQUAL(objects_left, 0, "on-demand init must drain queued objects (left [objects_left])")

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
