// Regression tests for gas propagation out of drip-fed tiles (corpse rot,
// plague rats): a settled room must not swallow the emissions into a
// never-spreading pocket, and a tile stranded with stale empty adjacency
// must heal itself once gas is fed into it.

/// Corpse rot scenario: a fully settled room (stale stall counters, no excited
/// groups - the state any room reaches a few minutes after the last activity)
/// receives a small miasma drip on one tile every "Life tick". The gas must
/// reach the distance-2 tiles of the room instead of piling up around the
/// corpse while sleeping neighbors never pass it on.
/datum/unit_test/atmos_corpse_gas_spreads
	priority = TEST_LONGER

/datum/unit_test/atmos_corpse_gas_spreads/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	var/turf/base = run_loc_floor_bottom_left

	// Wall off the 5x5 perimeter so the inner 3x3 room is sealed.
	for(var/dx in 0 to 4)
		for(var/dy in 0 to 4)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			if(dx == 0 || dy == 0 || dx == 4 || dy == 4)
				T.ChangeTurf(/turf/closed/wall)

	var/list/turf/open/room = list()
	for(var/dx in 1 to 3)
		for(var/dy in 1 to 3)
			var/turf/open/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT(istype(T), "inner room turf is not open at offset [dx],[dy]")
			T.ImmediateCalculateAdjacentTurfs()
			room += T

	// Settle the room the way a real one settles: identical standard air,
	// no excited groups, everything off the active list, and the personal
	// stall counters left maxed out (stale from the last activity).
	for(var/turf/open/T as anything in room)
		T.air.copy_from_turf(T)
		if(T.excited_group)
			T.excited_group.garbage_collect()
		SSair.remove_from_active(T)
		T.atmos_cooldown = EXCITED_GROUP_INDIVIDUAL_REST_CYCLES + 1

	var/turf/open/corpse_turf = locate(base.x + 2, base.y + 2, base.z)
	var/turf/open/corner_one = locate(base.x + 1, base.y + 1, base.z)
	var/turf/open/corner_two = locate(base.x + 3, base.y + 3, base.z)

	// Drive the same stage sequence SSair runs: rot feed, active turfs,
	// then the excited group lifecycle. 80 cycles at one feed per 4 cycles
	// mirrors one rot tick per 2 seconds at a 0.5s subsystem wait.
	var/fire_base = SSair.times_fired + 5000
	var/injected = 0
	for(var/cycle in 1 to 80)
		if(cycle % 4 == 1)
			var/datum/gas_mixture/stank = new
			stank.set_moles(GAS_MIASMA, 0.25)
			stank.set_temperature(BODYTEMP_NORMAL)
			corpse_turf.assume_air(stank)
			qdel(stank)
			injected += 0.25
		var/fire = fire_base + cycle
		for(var/turf/open/T as anything in room)
			if(T.excited)
				T.process_cell(fire)
		for(var/datum/excited_group/EG as anything in SSair.excited_groups.Copy())
			if(!length(EG.turf_list & room))
				continue
			EG.tick_lifecycle()

	var/corner_one_miasma = corner_one.air.get_moles(GAS_MIASMA)
	var/corner_two_miasma = corner_two.air.get_moles(GAS_MIASMA)
	var/corpse_miasma = corpse_turf.air.get_moles(GAS_MIASMA)

	// Cleanup before asserting so a failure does not leak state into the
	// shared reservation (stale current_cycle breaks the other atmos tests).
	for(var/turf/open/T as anything in room)
		if(T.excited_group)
			T.excited_group.garbage_collect()
		SSair.remove_from_active(T)
		T.atmos_cooldown = 0
		T.current_cycle = 0
		T.archived_cycle = 0
		T.air.copy_from_turf(T)
		T.update_visuals()

	TEST_ASSERT(corner_one_miasma > 0.05, "corpse gas never reached a distance-2 tile: corner has [corner_one_miasma] mol of miasma, corpse tile holds [corpse_miasma] of [injected] injected")
	TEST_ASSERT(corner_two_miasma > 0.05, "corpse gas never reached a distance-2 tile: corner has [corner_two_miasma] mol of miasma, corpse tile holds [corpse_miasma] of [injected] injected")
	TEST_ASSERT(corpse_miasma < injected * 0.6, "corpse tile hoarded the emissions: [corpse_miasma] of [injected] mol stayed on the tile")

/// A tile whose atmos adjacency was left stale-empty (a blocking object was
/// moved or its density dropped without an air update) must re-verify its
/// adjacency once gas is fed into it, instead of hoarding pressure forever.
/datum/unit_test/atmos_stranded_turf_self_heals/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/origin = run_loc_floor_bottom_left
	var/turf/open/stranded = locate(origin.x + 1, origin.y + 1, origin.z)
	TEST_ASSERT(istype(stranded), "test location is not an open turf")

	// Simulate the stranded state: adjacency emptied and nothing queued.
	stranded.clear_adjacencies()
	SSadjacent_air.queue -= stranded
	TEST_ASSERT_EQUAL(LAZYLEN(stranded.atmos_adjacent_turfs), 0, "clear_adjacencies left adjacency populated")

	// A corpse feeds gas into the tile: this activates it.
	var/datum/gas_mixture/stank = new
	stank.set_moles(GAS_MIASMA, 0.25)
	stank.set_temperature(BODYTEMP_NORMAL)
	stranded.assume_air(stank)
	qdel(stank)
	TEST_ASSERT(stranded in SSair.active_turfs, "assume_air did not activate the turf")

	var/fire_count = stranded.current_cycle + 1
	stranded.process_cell(fire_count)

	var/queued = SSadjacent_air.queue[stranded]

	// Run the adjacency recalculation the queue would perform and clean up.
	stranded.ImmediateCalculateAdjacentTurfs()
	SSadjacent_air.queue -= stranded
	var/healed_neighbors = LAZYLEN(stranded.atmos_adjacent_turfs)
	if(stranded.excited_group)
		stranded.excited_group.garbage_collect()
	SSair.remove_from_active(stranded)
	stranded.atmos_cooldown = 0
	stranded.air.copy_from_turf(stranded)

	TEST_ASSERT(queued, "an active turf with empty adjacency did not queue an adjacency re-check")
	TEST_ASSERT(healed_neighbors >= 1, "adjacency recalculation did not restore any neighbors")
