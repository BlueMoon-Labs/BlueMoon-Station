/// A floor strip with a wall ring, wide enough for an emitter shot of a dozen tiles.
/datum/unit_test/proc/beam_test_area(width = 18, height = 10)
	var/datum/turf_reservation/area = SSmapping.RequestBlockReservation(width, height, turf_type_override = /turf/open/floor/plasteel, border_type_override = /turf/closed/wall)
	allocated += area
	create_lighting_for_zlevel(area.bottom_left_coords[3])
	for(var/turf/reserved as anything in area.reserved_turfs)
		ensure_lighting_object(reserved)
	return area

/datum/unit_test/proc/beam_area_turf(datum/turf_reservation/area, dx, dy)
	return locate(area.bottom_left_coords[1] + dx, area.bottom_left_coords[2] + dy, area.bottom_left_coords[3])

/datum/unit_test/proc/beam_area_effects(datum/turf_reservation/area, effect_type)
	. = list()
	for(var/turf/reserved as anything in area.reserved_turfs)
		for(var/atom/movable/thing as anything in reserved)
			if(istype(thing, effect_type))
				. += thing

/// Light a lone reference beam tile and return what it adds to each of its corners.
/datum/unit_test/proc/beam_unit_corner_light(turf/spot, intensity)
	var/obj/effect/projectile_lighting/reference = new(spot, null, 0.75, intensity)
	process_nightshift_lighting_work()
	var/list/values = list()
	for(var/datum/lighting_corner/corner as anything in reference.light?.effect_str)
		var/value = reference.light.effect_str[corner]
		if(value > 0.0001)
			values += value
	var/datum/light_source/source = reference.light
	var/debug = "источник [source ? "есть" : "нет"], углов [length(source?.effect_str)], значения [values.Join(" ")], z [spot.z], range [source?.light_range], height [source?.light_height], applied [source?.applied], needs_update [source?.needs_update]"
	qdel(reference)
	process_nightshift_lighting_work()
	if(length(values) != 4)
		return debug
	for(var/value in values)
		if(abs(value - values[1]) > 0.0001)
			return debug
	return values[1]

/// Compare the light the beam lights put on corners with one unit light per path tile.
/// Returns null when every corner matches within the allowed slack, otherwise a failure text.
/datum/unit_test/proc/beam_corner_mismatch(list/turf/path, list/lights, unit, max_off_corners)
	var/list/expected = list()
	for(var/turf/tile as anything in path)
		for(var/datum/lighting_corner/corner in list(tile.lc_topleft, tile.lc_topright, tile.lc_bottomleft, tile.lc_bottomright))
			expected[corner] += 1
	if(!length(expected))
		return "у тайлов пути нет углов света"
	var/list/lit = list()
	for(var/obj/effect/projectile_lighting/beam_light as anything in lights)
		var/datum/light_source/source = beam_light.light
		if(!source)
			return "у света луча на [beam_light.x],[beam_light.y] нет источника"
		for(var/datum/lighting_corner/corner as anything in source.effect_str)
			var/value = source.effect_str[corner]
			if(value > 0.0001)
				lit[corner] += value
	var/off_corners = 0
	for(var/datum/lighting_corner/corner as anything in lit)
		if(!expected[corner])
			return "свет луча задел угол [corner.x],[corner.y] вне пути"
	for(var/datum/lighting_corner/corner as anything in expected)
		var/want = expected[corner] * unit
		var/got = lit[corner] || 0
		if(got <= 0.0001)
			return "угол [corner.x],[corner.y] на пути луча остался тёмным"
		var/diff = abs(got - want)
		if(diff <= 0.001)
			continue
		if(diff > unit + 0.001)
			return "угол [corner.x],[corner.y]: свет [got] вместо [want], расхождение больше одного источника"
		off_corners++
	if(off_corners > max_off_corners)
		return "углов с расхождением [off_corners], допустимо [max_off_corners]"
	return null

/// Straight runs (three or more tiles stepping one way) in a path.
/datum/unit_test/proc/beam_straight_runs(list/turf/path)
	. = 0
	var/run_length = 1
	var/last_dx
	var/last_dy
	for(var/i in 2 to length(path))
		var/turf/previous = path[i - 1]
		var/turf/current = path[i]
		var/dx = current.x - previous.x
		var/dy = current.y - previous.y
		if(abs(dx) + abs(dy) == 1 && dx == last_dx && dy == last_dy)
			run_length++
		else
			if(run_length >= 3)
				.++
			run_length = abs(dx) + abs(dy) == 1 ? 2 : 1
		last_dx = dx
		last_dy = dy
	if(run_length >= 3)
		.++

/// Beam lights along straight and mixed paths: half the sources on straight runs, the same corner light within one source at run ends, no gaps.
/datum/unit_test/hitscan_beam_lighting_keeps_corners/Run()
	var/datum/turf_reservation/area = beam_test_area()
	var/unit = beam_unit_corner_light(beam_area_turf(area, 15, 8), 1.5)
	TEST_ASSERT(isnum(unit) && unit > 0, "одиночный свет луча должен светить ровно четыре угла своего тайла поровну: [unit]")
	var/list/cases = list(
		list(2, 2, 15, 2),
		list(2, 4, 8, 7),
		list(2, 5, 12, 7),
	)
	for(var/list/coords as anything in cases)
		var/turf/path_start = beam_area_turf(area, coords[1], coords[2])
		var/turf/path_end = beam_area_turf(area, coords[3], coords[4])
		var/datum/point/start_point = new /datum/point(path_start)
		var/datum/point/end_point = new /datum/point(path_end)
		var/list/turf/path = getline(path_start, path_end)
		var/obj/effect/projectile/tracer/tracer = generate_tracer_between_points(start_point, end_point, /obj/effect/projectile/tracer/laser/emitter, null, 0, 0.75, null, 1.5)
		var/list/lights = beam_area_effects(area, /obj/effect/projectile_lighting)
		process_nightshift_lighting_work()
		var/runs = beam_straight_runs(path)
		var/mismatch = beam_corner_mismatch(path, lights, unit, runs * 4)
		var/light_count = length(lights)
		QDEL_LIST(lights)
		qdel(tracer)
		qdel(start_point)
		qdel(end_point)
		process_nightshift_lighting_work()
		TEST_ASSERT(isnull(mismatch), "путь [coords.Join(",")]: [mismatch]")
		if(!runs)
			TEST_ASSERT_EQUAL(light_count, length(path), "путь [coords.Join(",")] без прямых отрезков должен светить каждый тайл")
		else
			TEST_ASSERT(light_count < length(path), "путь [coords.Join(",")]: [light_count] источников на [length(path)] тайлов, на прямом отрезке хватает источника через тайл")

/// An emitter shot hits its target as before, lights its path with half the sources and leaves nothing behind.
/datum/unit_test/emitter_beam_hits_and_cleans_up/Run()
	var/datum/turf_reservation/area = beam_test_area()
	var/obj/machinery/power/emitter/emitter = new(beam_area_turf(area, 1, 2))
	allocated += emitter
	emitter.setDir(EAST)
	var/mob/living/carbon/human/target = new(beam_area_turf(area, 14, 2))
	allocated += target
	var/obj/item/projectile/beam/emitter/hitscan/beam_type = emitter.projectile_type
	var/unit = beam_unit_corner_light(beam_area_turf(area, 15, 8), initial(beam_type.hitscan_light_intensity))
	TEST_ASSERT(isnum(unit) && unit > 0, "одиночный свет луча должен светить ровно четыре угла своего тайла поровну: [unit]")

	if(TICK_USAGE > 30)
		stoplag(1)
	var/obj/item/projectile/shot = emitter.fire_beam()
	TEST_ASSERT(QDELETED(shot), "луч эмиттера должен отработать за один вызов")
	var/beam_damage = initial(beam_type.damage)
	TEST_ASSERT(abs(target.getFireLoss() - beam_damage) < 1, "луч эмиттера должен нанести [beam_damage] ожогов, нанёс [target.getFireLoss()]")
	TEST_ASSERT_EQUAL(length(beam_area_effects(area, /obj/effect/projectile/tracer/laser/emitter)), 1, "у луча один след")
	TEST_ASSERT_EQUAL(length(beam_area_effects(area, /obj/effect/projectile/muzzle/laser/emitter)), 1, "у луча одна вспышка у ствола")
	var/list/impacts = beam_area_effects(area, /obj/effect/projectile/impact/laser/emitter)
	TEST_ASSERT_EQUAL(length(impacts), 1, "у луча одна вспышка попадания")
	var/obj/effect/projectile/impact/impact = impacts[1]
	TEST_ASSERT(get_dist(impact, target) <= 1, "вспышка попадания должна быть у цели, а она в [impact.x],[impact.y]")
	TEST_ASSERT(impact.light, "вспышка попадания светит")

	var/list/lights = beam_area_effects(area, /obj/effect/projectile_lighting)
	var/first_x = INFINITY
	var/last_x = 0
	for(var/obj/effect/projectile_lighting/beam_light as anything in lights)
		first_x = min(first_x, beam_light.x)
		last_x = max(last_x, beam_light.x)
	var/list/turf/path = getline(locate(first_x, target.y, target.z), locate(last_x, target.y, target.z))
	TEST_ASSERT(length(path) >= 10, "свет луча должен лежать на всём пути, а лежит на [length(path)] тайлах")
	process_nightshift_lighting_work()
	var/mismatch = beam_corner_mismatch(path, lights, unit, 4)
	TEST_ASSERT(isnull(mismatch), "свет луча эмиттера: [mismatch]")
	TEST_ASSERT(length(lights) <= length(path) / 2 + 2, "[length(lights)] источников света на [length(path)] тайлов прямого луча")

	sleep(1 SECONDS)
	for(var/effect_type in list(/obj/effect/projectile_lighting, /obj/effect/projectile/tracer, /obj/effect/projectile/muzzle, /obj/effect/projectile/impact))
		TEST_ASSERT_EQUAL(length(beam_area_effects(area, effect_type)), 0, "[effect_type] остался после выстрела")

/// A hitscan shot is resolved inside one call and never drawn, so it must not churn a light source of its own.
/datum/unit_test/hitscan_projectile_skips_own_light/Run()
	var/datum/turf_reservation/area = beam_test_area()
	var/obj/machinery/power/emitter/emitter = new(beam_area_turf(area, 1, 2))
	allocated += emitter
	var/datum/qdel_item/light_stats = SSgarbage.GetOrCreateItem(/datum/light_source)
	if(TICK_USAGE > 30)
		stoplag(1)
	var/sources_deleted_before = light_stats?.qdels || 0
	var/obj/item/projectile/beam/emitter/hitscan/shot = new(beam_area_turf(area, 1, 2))
	shot.firer = emitter
	shot.fired_from = emitter
	shot.fire(90)
	var/sources_deleted = (light_stats?.qdels || 0) - sources_deleted_before
	TEST_ASSERT(QDELETED(shot), "луч должен отработать за один вызов")
	TEST_ASSERT_EQUAL(sources_deleted, 0, "мгновенный луч создал и удалил собственный источник света")
	TEST_ASSERT(length(beam_area_effects(area, /obj/effect/projectile_lighting)), "путь луча всё равно подсвечен")

/// The glow marks a floor turning to cult; a floor that comes with a loaded map does not flash.
/datum/unit_test/cult_floor_glow_only_when_converted/Run()
	var/turf/converted = run_loc_floor_bottom_left
	converted.ChangeTurf(/turf/open/floor/engine/cult)
	TEST_ASSERT(locate(/obj/effect/temp_visual/cult/turf/floor) in converted, "обращённый в культ пол должен вспыхнуть")

	var/turf/loaded = get_step(run_loc_floor_bottom_left, EAST)
	SSatoms.map_loader_begin()
	loaded = loaded.ChangeTurf(/turf/open/floor/engine/cult)
	SSatoms.map_loader_stop()
	SSatoms.InitializeAtoms(list(loaded))
	TEST_ASSERT(istype(loaded, /turf/open/floor/engine/cult), "пол из загрузки карты должен стать полом культа")
	TEST_ASSERT_NULL(locate(/obj/effect/temp_visual/cult/turf/floor) in loaded, "пол культа из загрузки карты не должен вспыхивать")
	converted.ChangeTurf(/turf/open/floor/plasteel)
	loaded.ChangeTurf(/turf/open/floor/plasteel)
