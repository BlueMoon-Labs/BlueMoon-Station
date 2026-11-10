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

	var/list/before = shuttle_snapshot(supply)
	TEST_ASSERT(before.len, "test premise: the supply shuttle has no turfs")
	TEST_ASSERT_EQUAL(supply.initiate_docking(transit), DOCKING_SUCCESS, "the supply shuttle could not enter transit")
	check_footprint(pick_turfs(supply.return_ordered_turfs(home.x, home.y, home.z, home.dir), before), "vacated berth")
	compare(before, shuttle_snapshot(supply), "in transit")
	check_footprint(pick_turfs(supply.return_ordered_turfs(supply.x, supply.y, supply.z, supply.dir), before), "shuttle in transit")

	TEST_ASSERT_EQUAL(supply.initiate_docking(home), DOCKING_SUCCESS, "the supply shuttle could not return home")
	compare(before, shuttle_snapshot(supply), "back home")
	check_footprint(pick_turfs(supply.return_ordered_turfs(supply.x, supply.y, supply.z, supply.dir), before), "shuttle back home")

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
		if(SSlighting.initialized && IS_DYNAMIC_LIGHTING(place_area))
			TEST_ASSERT_NOTNULL(place.lighting_object, "no lighting object on [place.x],[place.y] ([stage])")
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
