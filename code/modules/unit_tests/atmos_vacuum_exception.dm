// ===== Vacuum exception: a tile draining to space must not sleep pressurized =====
//
// The space-drain branch of process_cell() gates its stall-cooldown resets on
// VENTED MOLES (mirroring LAST_SHARE_CHECK). A superheated near-vacuum tile
// holds pressure above SPACE_DRAIN_FINISH_PRESSURE on sub-0.1 mol content, so
// both mole-gated resets miss it: the stall counter kept climbing toward
// EXCITED_GROUP_INDIVIDUAL_REST_CYCLES while the tile visibly pressed against
// vacuum. The fix adds a pressure-gated reset (Baystation vacuum_exception
// lesson): while the tile reads survivable pressure against space, its stall
// budget must not advance.
//
// This test drives exactly that window (vented moles below
// MINIMUM_MOLES_DELTA_TO_MOVE while pressure is above the drain-finish
// threshold) and asserts:
//   1. the stall cooldown resets on the in-window cycle (the fix, directly);
//   2. the tile never sleeps while still pressurized against space (invariant);
//   3. the drain still completes - the pressure guard cannot pin the tile
//      awake forever, because pressure decays geometrically every vent.

/datum/unit_test/atmos_vacuum_exception
	priority = TEST_LONGER

/datum/unit_test/atmos_vacuum_exception/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	var/turf/base = run_loc_floor_bottom_left

	// Wall off a pocket; subject at +1,+1 with a single space tile at +1,+2.
	for(var/dx in 0 to 2)
		for(var/dy in 0 to 3)
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			if(dx == 0 || dx == 2 || dy == 0 || dy == 3)
				T.ChangeTurf(/turf/closed/wall)

	var/turf/open/subject = locate(base.x + 1, base.y + 1, base.z)
	var/turf/space_side = locate(base.x + 1, base.y + 2, base.z)
	space_side.ChangeTurf(/turf/open/space)
	var/turf/open/space/vacuum = locate(base.x + 1, base.y + 2, base.z)
	TEST_ASSERT(istype(vacuum), "space tile fixture did not become /turf/open/space")

	subject.ImmediateCalculateAdjacentTurfs()
	vacuum.ImmediateCalculateAdjacentTurfs()
	TEST_ASSERT(vacuum in subject.atmos_adjacent_turfs, "subject must be adjacent to the space tile")

	// Superheated near-vacuum: 0.19 mol at 45000K in a 2500L cell reads ~28 kPa,
	// above SPACE_DRAIN_FINISH_PRESSURE, while the per-cycle vented amount
	// (share_coeff fraction of 0.19 mol) stays under MINIMUM_MOLES_DELTA_TO_MOVE:
	// both mole-gated resets miss -> only the pressure-gated reset fires. Venting
	// cools the tile as well, so only cycle 1 is guaranteed inside the window -
	// all window asserts happen on that cycle.
	var/datum/gas_mixture/saved_air = subject.air.copy()
	subject.air.clear()
	subject.air.set_moles(GAS_O2, 0.19)
	subject.air.set_temperature(45000)
	var/pressure_start = subject.air.return_pressure()
	TEST_ASSERT(pressure_start >= SPACE_DRAIN_FINISH_PRESSURE, "fixture must start above the drain-finish pressure (got [pressure_start])")
	var/share_coeff = 1 / (max(1, LAZYLEN(subject.atmos_adjacent_turfs)) + 1)
	TEST_ASSERT(subject.air.total_moles() * share_coeff <= MINIMUM_MOLES_DELTA_TO_MOVE, \
		"fixture must vent below MINIMUM_MOLES_DELTA_TO_MOVE per cycle to hit the guarded window (vents [subject.air.total_moles() * share_coeff])")

	subject.atmos_cooldown = 0
	SSair.add_to_active(subject, FALSE)
	TEST_ASSERT(subject.excited, "subject must start excited")

	// Pre-build the excited group with a nearly-expired dismantle countdown:
	// pre-fix only the tile cooldown was reset by the pressure guard, the
	// group's dismantle_cooldown kept climbing and dismantle() pulled the
	// still-draining tile out of the active list on its 16th pass.
	var/datum/excited_group/drain_group = new
	drain_group.add_turf(subject) // resets cooldowns
	drain_group.dismantle_cooldown = EXCITED_GROUP_DISMANTLE_CYCLES - 1

	// Cycle 1 lands in the guarded window: pressure above the threshold, vented
	// moles below both mole gates. Pre-fix the stall counter advanced to 1 here;
	// the pressure-gated reset must hold it at 0 and zero the group countdown.
	var/fire_base = SSair.times_fired + 2000
	subject.process_cell(fire_base + 1)
	TEST_ASSERT_EQUAL(subject.atmos_cooldown, 0, "vacuum exception: stall cooldown must reset while the tile holds [subject.air.return_pressure()] kPa against space")
	TEST_ASSERT_EQUAL(drain_group.dismantle_cooldown, 0, "vacuum exception must also reset the group's dismantle countdown")

	// Drive the drain to completion: never asleep while pressurized, and the
	// pressure guard must not stall the drain itself.
	var/emptied_at = 0
	for(var/cycle in 2 to 60)
		subject.process_cell(fire_base + cycle)
		if(subject.air.return_pressure() >= SPACE_DRAIN_FINISH_PRESSURE)
			TEST_ASSERT(subject.excited, "tile slept at cycle [cycle] while holding [subject.air.return_pressure()] kPa against space")
		if(subject.air.total_moles() <= MINIMUM_MOLES_DELTA_TO_MOVE)
			emptied_at = cycle
			break

	TEST_ASSERT(emptied_at, "tile must finish draining to space (still holds [subject.air.total_moles()] mol / [subject.air.return_pressure()] kPa after 60 cycles)")

	// Cleanup: restore air and deactivate; the reservation releases the turfs.
	subject.air.copy_from(saved_air)
	if(subject.excited_group)
		subject.excited_group.dismantle()
	SSair.remove_from_active(subject)
