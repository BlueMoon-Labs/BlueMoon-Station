// ===== Excited group lifecycle: VOLATILE_REACTION gate (tg port) =====
//
// tick_lifecycle() used to run self_breakdown on a pure counter: a group with a
// live fire got its members' air averaged mid-burn, smearing the hotspot's heat
// across the whole group (snuffing or teleporting the fire). The port defers
// breakdown while a member reported VOLATILE_REACTION (fire/hotspot) in the
// last air pass, freezes the dismantle countdown, and blocks dismantle while
// any reaction is live. Unlike tg, deferral has a hard ceiling
// (EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING): our breakdown also evicts settled
// members - the giant-group churn control - so a long fire must not suppress it
// forever.

/datum/unit_test/excited_group_volatile_gate/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")

	// Walled 1x1 pocket: poke_resting has no bordering open turfs to wake.
	var/turf/base = run_loc_floor_bottom_left
	for(var/dx in 0 to 2)
		for(var/dy in 0 to 2)
			if(dx == 1 && dy == 1)
				continue
			var/turf/T = locate(base.x + dx, base.y + dy, base.z)
			TEST_ASSERT_NOTNULL(T, "test zone turf missing at offset [dx],[dy]")
			T.ChangeTurf(/turf/closed/wall)
	var/turf/open/subject = locate(base.x + 1, base.y + 1, base.z)
	TEST_ASSERT(istype(subject), "pocket center must be an open turf")

	var/datum/excited_group/group = new
	group.add_turf(subject) // resets cooldowns, sets awake_members = 1

	// --- Volatile reaction defers breakdown and freezes the dismantle countdown ---
	group.breakdown_cooldown = EXCITED_GROUP_BREAKDOWN_CYCLES
	group.dismantle_cooldown = 0
	group.turf_reactions = VOLATILE_REACTION
	group.tick_lifecycle()
	TEST_ASSERT_EQUAL(group.breakdown_cooldown, EXCITED_GROUP_BREAKDOWN_CYCLES + 1, "Volatile reaction must defer breakdown (cooldown keeps counting, no reset)")
	TEST_ASSERT_EQUAL(group.dismantle_cooldown, 0, "Volatile reaction must freeze the dismantle countdown")
	TEST_ASSERT_EQUAL(group.turf_reactions, NO_REACTION, "tick_lifecycle must consume the reaction flags")

	// --- Without flags the due breakdown runs and resets its cooldown ---
	group.tick_lifecycle()
	TEST_ASSERT_EQUAL(group.breakdown_cooldown, 0, "Quiet group past the breakdown window must break down")
	TEST_ASSERT(subject.excited_group == group, "Breakdown must keep the member in the group")

	// --- Ceiling: an endless fire cannot defer breakdown past the hard cap ---
	group.turf_reactions = VOLATILE_REACTION
	group.breakdown_cooldown = EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING - 1
	group.tick_lifecycle()
	TEST_ASSERT_EQUAL(group.breakdown_cooldown, 0, "Volatile deferral must not survive past EXCITED_GROUP_VOLATILE_BREAKDOWN_CEILING")

	// --- Any live reaction blocks dismantle ---
	group.turf_reactions = REACTING
	group.dismantle_cooldown = EXCITED_GROUP_DISMANTLE_CYCLES
	group.breakdown_cooldown = 0
	group.tick_lifecycle()
	TEST_ASSERT(length(group.turf_list) == 1 && subject.excited_group == group, "Reacting group past the dismantle window must not dismantle")

	// --- Quiet group past the dismantle window dismantles ---
	group.turf_reactions = NO_REACTION
	group.dismantle_cooldown = EXCITED_GROUP_DISMANTLE_CYCLES
	group.breakdown_cooldown = 0
	group.tick_lifecycle()
	TEST_ASSERT_EQUAL(length(group.turf_list), 0, "Quiet group past the dismantle window must dismantle")
	TEST_ASSERT_NULL(subject.excited_group, "Dismantle must unlink the member turf")

	// --- Merge carries the volatile gate from the ABSORBED group to the survivor ---
	var/datum/excited_group/survivor_group = new
	survivor_group.add_turf(subject)
	survivor_group.turf_reactions = NO_REACTION
	var/datum/excited_group/burning_group = new // empty shell group about to be absorbed
	burning_group.turf_reactions = VOLATILE_REACTION
	survivor_group.merge_groups(burning_group) // survivor is larger -> absorbs burning_group
	TEST_ASSERT(survivor_group.turf_reactions & VOLATILE_REACTION, "Merge must carry VOLATILE_REACTION from the absorbed group to the survivor")

	// Cleanup
	if(subject.excited_group)
		subject.excited_group.dismantle()
	SSair.remove_from_active(subject)
