/// Supply and arrivals get their transit reservation at init, so the first flight does not build it in-round.
/datum/unit_test/shuttle_transit_pregenerated/Run()
	var/obj/docking_port/mobile/supply = SSshuttle.supply
	TEST_ASSERT_NOTNULL(supply, "test premise: the test map has no supply shuttle")
	TEST_ASSERT_NOTNULL(supply.assigned_transit, "the supply shuttle had no transit dock after init")
	if(SSshuttle.arrivals)
		TEST_ASSERT_NOTNULL(SSshuttle.arrivals.assigned_transit, "the arrivals shuttle had no transit dock after init")

	var/obj/docking_port/stationary/home = supply.get_docked()
	var/transits_before = length(SSshuttle.transit)
	TEST_ASSERT_EQUAL(supply.check_transit_zone(), TRANSIT_READY, "a pregenerated transit was not ready for launch")
	TEST_ASSERT_EQUAL(supply.initiate_docking(supply.assigned_transit), DOCKING_SUCCESS, "the supply shuttle could not enter its pregenerated transit")
	TEST_ASSERT_EQUAL(length(SSshuttle.transit), transits_before, "entering transit reserved another transit zone")
	TEST_ASSERT(!(supply in SSshuttle.transit_requesters), "the shuttle queued a transit request although it had one")
	TEST_ASSERT_EQUAL(supply.initiate_docking(home), DOCKING_SUCCESS, "the supply shuttle could not return home")

/// The cheap air seal leaves a turf and its neighbours exactly as blocks_air plus air_update_turf(TRUE) did.
/datum/unit_test/shuttle_air_seal_equivalence/Run()
	var/turf/open/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	TEST_ASSERT(istype(center), "test premise: the center of the test floor is not open")
	allocate(/obj/structure/window/reinforced, get_step(center, NORTH))

	center.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(length(center.atmos_adjacent_turfs), "test premise: the center turf has no atmos neighbours")
	center.blocks_air = TRUE
	center.air_update_turf(TRUE)
	var/list/reference = air_snapshot(center)

	center.blocks_air = initial(center.blocks_air)
	center.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(length(center.atmos_adjacent_turfs), "test premise: restoring blocks_air did not reconnect the turf")
	center.seal_air_for_shuttle_move()
	var/list/sealed = air_snapshot(center)

	TEST_ASSERT_EQUAL(sealed.len, reference.len, "the snapshots differ in size")
	for(var/key in reference)
		TEST_ASSERT_EQUAL(sealed[key], reference[key], "the air seal differs from air_update_turf in [key]")
	center.blocks_air = initial(center.blocks_air)
	center.ImmediateCalculateAdjacentTurfs()

	// Замена турфа без пересчёта смежности, как у турфа назначения в перелёте.
	TEST_ASSERT(length(center.atmos_adjacent_turfs), "test premise: restoring blocks_air did not reconnect the turf")
	center = center.ChangeTurf(center.type, null, CHANGETURF_FORCEOP | CHANGETURF_IGNORE_AIR | CHANGETURF_SKIP_ADJACENCY)
	TEST_ASSERT(!length(center.atmos_adjacent_turfs), "test premise: CHANGETURF_SKIP_ADJACENCY still recalculated adjacency")
	center.seal_replaced_air_for_shuttle_move()
	var/list/replaced = air_snapshot(center)
	for(var/key in reference)
		TEST_ASSERT_EQUAL(replaced[key], reference[key], "the seal of a replaced turf differs from air_update_turf in [key]")
	center.blocks_air = initial(center.blocks_air)
	center.ImmediateCalculateAdjacentTurfs()

/datum/unit_test/shuttle_air_seal_equivalence/proc/air_snapshot(turf/open/center)
	. = list()
	.["blocks_air"] = center.blocks_air
	.["adjacent"] = length(center.atmos_adjacent_turfs)
	.["conductivity"] = center.conductivity_blocked_directions
	.["excited"] = center.excited
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(center, direction)
		.["[direction] sees center"] = !!LAZYACCESS(neighbor.atmos_adjacent_turfs, center)
		.["[direction] conductivity"] = neighbor.conductivity_blocked_directions

/// After a round trip every shuttle turf keeps its type, area, contents and air, and the atmos and lighting
/// state of both footprints is what a fresh recalculation gives.
/datum/unit_test/shuttle_dock_state/Run()
	var/obj/docking_port/mobile/supply = SSshuttle.supply
	TEST_ASSERT_NOTNULL(supply, "test premise: the test map has no supply shuttle")
	var/obj/docking_port/stationary/home = supply.get_docked()
	var/obj/docking_port/stationary/transit = supply.assigned_transit || SSshuttle.generate_transit_dock(supply)
	TEST_ASSERT_NOTNULL(transit, "test premise: no transit dock for the supply shuttle")

	settle_lighting()
	var/list/before = shuttle_snapshot(supply)
	TEST_ASSERT(before.len, "test premise: the supply shuttle has no turfs")
	var/list/light_before = light_snapshot(supply, before)
	var/list/objects_before = lighting_objects(supply, before)
	TEST_ASSERT_EQUAL(supply.initiate_docking(transit), DOCKING_SUCCESS, "the supply shuttle could not enter transit")
	check_footprint(pick_turfs(supply.return_ordered_turfs(home.x, home.y, home.z, home.dir), before), "vacated berth")
	compare(before, shuttle_snapshot(supply), "in transit")
	check_footprint(pick_turfs(supply.return_ordered_turfs(supply.x, supply.y, supply.z, supply.dir), before), "shuttle in transit")
	var/list/objects_after = lighting_objects(supply, before)
	for(var/key in objects_before)
		TEST_ASSERT(objects_before[key] == objects_after[key], "the lighting object of shuttle turf [key] was recreated instead of flying with the turf")

	TEST_ASSERT_EQUAL(supply.initiate_docking(home), DOCKING_SUCCESS, "the supply shuttle could not return home")
	compare(before, shuttle_snapshot(supply), "back home")
	check_footprint(pick_turfs(supply.return_ordered_turfs(supply.x, supply.y, supply.z, supply.dir), before), "shuttle back home")
	settle_lighting()
	var/list/light_after = light_snapshot(supply, before)
	// Источники шаттла и до правки дают дрожание на шаг сетки углов (1/32) между перелётами, сверяем с допуском.
	for(var/key in light_before)
		var/list/was = light_before[key]
		var/list/now = light_after[key]
		TEST_ASSERT_EQUAL(now[1], was[1], "the lighting object of shuttle turf [key] changed after a round trip")
		TEST_ASSERT_EQUAL(length(now), length(was), "the lighting colour of shuttle turf [key] changed form after a round trip")
		for(var/i in 2 to length(was))
			TEST_ASSERT(abs(now[i] - was[i]) < 0.1, "lighting of shuttle turf [key] changed after a round trip: [json_encode(now)] instead of [json_encode(was)]")

/// Доводит отложенную после стыковки работу света так, как её сделал бы SSlighting: тени, смешение зон, очереди.
/datum/unit_test/shuttle_dock_state/proc/settle_lighting()
	for(var/turf/shadow_turf as anything in GLOB.lighting_deferred_shadow_turfs.Copy())
		var/old_opaque = shadow_turf.lighting_flags & TURF_HAS_OPAQUE_ATOM
		shadow_turf.recalc_atom_opacity()
		if((shadow_turf.lighting_flags & TURF_HAS_OPAQUE_ATOM) != old_opaque)
			shadow_turf.reconsider_lights()
		if(shadow_turf.lighting_object)
			GLOB.lighting_update_blends |= shadow_turf.lighting_object
			if(!shadow_turf.lighting_object.needs_update)
				shadow_turf.lighting_object.needs_update = TRUE
				GLOB.lighting_update_objects += shadow_turf.lighting_object
	GLOB.lighting_deferred_shadow_turfs.Cut()
	for(var/atom/movable/lighting_object/blend_object as anything in GLOB.lighting_update_blends.Copy())
		if(!QDELETED(blend_object))
			blend_object.calculate_area_blend()
	GLOB.lighting_update_blends.Cut()
	drain_lighting_queues_snapshot()

/// Освещённость турфов шаттла: объект, его привязка к турфу и итог по углам.
/datum/unit_test/shuttle_dock_state/proc/light_snapshot(obj/docking_port/mobile/port, list/positions)
	. = list()
	var/list/turfs = port.return_ordered_turfs(port.x, port.y, port.z, port.dir)
	for(var/key in positions)
		var/turf/place = turfs[text2num(key)]
		var/atom/movable/lighting_object/light = place.lighting_object
		if(!light)
			.[key] = list("none")
			continue
		var/list/values = list("[light.affected_turf == place]|[light.loc == place]", place.get_lumcount())
		if(islist(light.color))
			values += light.color
		.[key] = values

/datum/unit_test/shuttle_dock_state/proc/lighting_objects(obj/docking_port/mobile/port, list/positions)
	. = list()
	var/list/turfs = port.return_ordered_turfs(port.x, port.y, port.z, port.dir)
	for(var/key in positions)
		var/turf/place = turfs[text2num(key)]
		.[key] = place.lighting_object

/datum/unit_test/shuttle_dock_state/proc/pick_turfs(list/ordered, list/positions)
	. = list()
	for(var/key in positions)
		. += ordered[text2num(key)]

/datum/unit_test/shuttle_dock_state/proc/shuttle_snapshot(obj/docking_port/mobile/port)
	. = list()
	var/list/turfs = port.return_ordered_turfs(port.x, port.y, port.z, port.dir)
	for(var/i in 1 to turfs.len)
		var/turf/place = turfs[i]
		if(!(place.loc in port.shuttle_areas))
			continue
		var/list/things = list()
		for(var/atom/movable/thing as anything in place)
			if(istype(thing, /atom/movable/lighting_object) || istype(thing, /obj/effect/abstract) || istype(thing, /obj/docking_port/stationary))
				continue
			things += "[thing.type]"
		things = sort_list(things)
		var/moles = 0
		if(isopenturf(place))
			var/turf/open/open_place = place
			moles = round(open_place.air.total_moles(), 0.1)
		.["[i]"] = "[place.type]|[place.loc.type]|[moles]|[jointext(things, ",")]"

/datum/unit_test/shuttle_dock_state/proc/compare(list/expected, list/actual, stage)
	TEST_ASSERT_EQUAL(actual.len, expected.len, "turf count changed [stage]")
	for(var/key in expected)
		TEST_ASSERT_EQUAL(actual[key], expected[key], "shuttle turf [key] changed [stage]")

/// blocks_air, lighting objects and, on open turfs, adjacency and conductivity must match a fresh recalculation.
/datum/unit_test/shuttle_dock_state/proc/check_footprint(list/turfs, stage)
	var/list/recorded = list()
	for(var/turf/place as anything in turfs)
		TEST_ASSERT_EQUAL(place.blocks_air, initial(place.blocks_air), "blocks_air stuck on [place.x],[place.y] ([stage])")
		if(isopenturf(place))
			recorded[place] = adjacency_key(place)
		var/area/place_area = place.loc
		if(SSlighting.initialized)
			if(IS_DYNAMIC_LIGHTING(place_area))
				TEST_ASSERT_NOTNULL(place.lighting_object, "no lighting object on [place.x],[place.y] ([stage])")
				TEST_ASSERT(place.lighting_object.affected_turf == place && place.lighting_object.loc == place, "the lighting object on [place.x],[place.y] belongs elsewhere ([stage])")
			else
				TEST_ASSERT_NULL(place.lighting_object, "a lighting object stayed on unlit [place.x],[place.y] ([stage])")
				TEST_ASSERT_EQUAL(place.luminosity, 1, "unlit [place.x],[place.y] is not visible ([stage])")
			for(var/datum/lighting_corner/corner as anything in list(place.lc_topright, place.lc_bottomright, place.lc_bottomleft, place.lc_topleft))
				if(!corner)
					continue
				var/should_be_active = !!(corner.northeast?.lighting_object || corner.northwest?.lighting_object || corner.southeast?.lighting_object || corner.southwest?.lighting_object)
				TEST_ASSERT_EQUAL(!!corner.active, should_be_active, "a lighting corner of [place.x],[place.y] has the wrong active state ([stage])")
	for(var/turf/place as anything in recorded)
		place.ImmediateCalculateAdjacentTurfs()
	for(var/turf/place as anything in recorded)
		TEST_ASSERT_EQUAL(recorded[place], adjacency_key(place), "atmos state of [place.type] at [place.x],[place.y],[place.z] is not what a recalculation gives ([stage])")

/datum/unit_test/shuttle_dock_state/proc/adjacency_key(turf/place)
	var/list/parts = list("c[place.conductivity_blocked_directions]")
	for(var/direction in GLOB.cardinals_multiz)
		var/turf/neighbor = get_step_multiz(place, direction)
		if(!neighbor)
			continue
		parts += "[direction]:[LAZYACCESS(place.atmos_adjacent_turfs, neighbor)]/[LAZYACCESS(neighbor.atmos_adjacent_turfs, place)]"
	return jointext(parts, " ")

/// Пустой шаттл в идущем раунде не поднимает отложенный свет уровня назначения, шаттл с наблюдателем - поднимает.
/datum/unit_test/shuttle_dock_deferred_lighting/Run()
	var/obj/docking_port/mobile/supply = SSshuttle.supply
	TEST_ASSERT_NOTNULL(supply, "test premise: the test map has no supply shuttle")
	var/obj/docking_port/stationary/home = SSshuttle.getDock("supply_home")
	TEST_ASSERT_NOTNULL(home, "test premise: the test map has no supply home dock")
	var/obj/docking_port/stationary/transit = supply.assigned_transit || SSshuttle.generate_transit_dock(supply)
	TEST_ASSERT_NOTNULL(transit, "test premise: no transit dock for the supply shuttle")
	TEST_ASSERT_EQUAL(supply.initiate_docking(home), DOCKING_SUCCESS, "test premise: the supply shuttle could not dock at home")
	var/datum/space_level/level = SSmapping.get_level(transit.z)
	TEST_ASSERT(zlevel_lighting_deferred(level), "test premise: the transit z-level does not defer its lighting")

	var/old_state = SSticker.current_state
	var/old_initialized = level.lighting_initialized
	var/list/old_clients = SSmobs.clients_by_zlevel[transit.z]
	var/list/old_dead = SSmobs.dead_players_by_zlevel[transit.z]
	SSticker.current_state = GAME_STATE_PLAYING
	SSmobs.clients_by_zlevel[transit.z] = list()
	SSmobs.dead_players_by_zlevel[transit.z] = list()
	level.lighting_initialized = FALSE

	var/empty_result = supply.initiate_docking(transit)
	var/lit_by_empty = level.lighting_initialized
	var/home_result = supply.initiate_docking(home)

	SSmobs.dead_players_by_zlevel[transit.z] = list(occupant_ghost(get_turf(transit)))
	var/watched_result = supply.initiate_docking(transit)
	var/lit_by_watched = level.lighting_initialized
	var/back_result = supply.initiate_docking(home)

	SSticker.current_state = old_state
	SSmobs.clients_by_zlevel[transit.z] = old_clients
	SSmobs.dead_players_by_zlevel[transit.z] = old_dead
	level.lighting_initialized = old_initialized || lit_by_watched

	TEST_ASSERT_EQUAL(empty_result, DOCKING_SUCCESS, "the empty supply shuttle could not enter transit")
	TEST_ASSERT_EQUAL(home_result, DOCKING_SUCCESS, "the empty supply shuttle could not return home")
	TEST_ASSERT_EQUAL(watched_result, DOCKING_SUCCESS, "the watched supply shuttle could not enter transit")
	TEST_ASSERT_EQUAL(back_result, DOCKING_SUCCESS, "the watched supply shuttle could not return home")
	TEST_ASSERT(!lit_by_empty, "an empty shuttle built the deferred lighting of its destination z-level")
	TEST_ASSERT(lit_by_watched, "a shuttle docking at a watched deferred z-level did not build its lighting")
