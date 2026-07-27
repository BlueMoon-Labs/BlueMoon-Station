/// Tests for the costs that show up when a round accumulates a lot of mobs.
///
/// Round 9800 late-game: 819 living mobs, SSmobs at 168ms per two-second pass.
/// Its own per-type profiler blamed 93 xenobio slimes for 65% of that, ~104 cube
/// monkeys for 15%, and 139 humans for 18%. The turf-exit half of that story
/// lives in turf_exit_checks.dm; what is left here is the mobs themselves.

// -----------------------------------------------------------------------------
// Idle slimes wandered on every Life tick, and one step in a packed pen costs
// ~560us because of the turf-exit walk. Hunting and following a leader are
// untouched; only aimless wandering is throttled.
// -----------------------------------------------------------------------------

/datum/unit_test/slime_idle_wander_is_throttled

/datum/unit_test/slime_idle_wander_is_throttled/Run()
	var/turf/pen = run_loc_floor_bottom_left
	var/mob/living/simple_animal/slime/lazy = allocate(/mob/living/simple_animal/slime, pen)
	lazy.Target = null
	lazy.Leader = null
	// Keep the prey scan out of it so the slime cannot acquire a target from
	// whatever else happens to be standing in the test room.
	lazy.next_hunt_scan = world.time + 10 MINUTES

	TEST_ASSERT(lazy.can_wander_now(), "A freshly spawned slime should be free to wander")
	lazy.note_wander()
	TEST_ASSERT(!lazy.can_wander_now(), "A slime that just wandered must wait out its cooldown")

	// With the cooldown running, handle_targets() must not move it, however many
	// Life ticks go by.
	for(var/i in 1 to 40)
		lazy.handle_targets()
	TEST_ASSERT_EQUAL(lazy.loc, pen, "A slime on wander cooldown must stay put")

/datum/unit_test/slime_still_wanders_when_cooldown_is_clear

/datum/unit_test/slime_still_wanders_when_cooldown_is_clear/Run()
	var/turf/pen = run_loc_floor_bottom_left
	var/mob/living/simple_animal/slime/restless = allocate(/mob/living/simple_animal/slime, pen)
	restless.Target = null
	restless.Leader = null
	restless.next_hunt_scan = world.time + 10 MINUTES

	// Each attempt clears its own cooldown, so this is only bounded by the
	// wander probability — 40 tries at >=33% each.
	var/moved = FALSE
	for(var/i in 1 to 40)
		restless.next_wander = 0
		restless.handle_targets()
		if(restless.loc != pen)
			moved = TRUE
			break
	TEST_ASSERT(moved, "A slime with a clear cooldown must still wander")

/datum/unit_test/slime_follows_leader_despite_wander_cooldown

/datum/unit_test/slime_follows_leader_despite_wander_cooldown/Run()
	var/turf/pen = run_loc_floor_bottom_left
	var/mob/living/simple_animal/slime/follower = allocate(/mob/living/simple_animal/slime, pen)
	var/mob/living/carbon/human/boss = allocate(/mob/living/carbon/human, locate(pen.x + 3, pen.y, pen.z))

	follower.Target = null
	follower.Leader = boss
	follower.holding_still = 0
	// Friends are never eaten, so the leader cannot become a hunting target.
	follower.Friends[boss] = 1
	follower.next_hunt_scan = world.time + 10 MINUTES
	follower.note_wander()
	TEST_ASSERT(!follower.can_wander_now(), "Sanity: the cooldown should be running")

	follower.handle_targets()

	TEST_ASSERT_NOTEQUAL(follower.loc, pen, "Following a leader must not be gated by the idle wander cooldown")

// -----------------------------------------------------------------------------
// The subsystem profiler named the worst mob *type* but not the mob, so a single
// 26ms slime stayed anonymous. It now records which item hit the maximum, and
// whether any measured item slept (which makes its measurement meaningless,
// because the reading then includes whatever else ran in between).
// -----------------------------------------------------------------------------

/datum/unit_test/subsystem_profile_names_worst_item

/datum/unit_test/subsystem_profile_names_worst_item/Run()
	var/mob/living/carbon/human/cheap = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/pricey = allocate(/mob/living/carbon/human)

	SSmobs.profile_cost_by_type = alist()
	SSmobs.profile_count_by_type = alist()
	SSmobs.profile_max_by_type = alist()
	SSmobs.profile_worst_by_type = alist()
	SSmobs.profile_sleepers_by_type = alist()

	SSmobs.profile_note(/mob/living/carbon/human, 3, cheap, FALSE)
	SSmobs.profile_note(/mob/living/carbon/human, 26, pricey, TRUE)
	SSmobs.profile_note(/mob/living/carbon/human, 4, cheap, FALSE)

	var/worst = SSmobs.profile_worst_by_type[/mob/living/carbon/human]
	var/sleepers = SSmobs.profile_sleepers_by_type[/mob/living/carbon/human]
	var/max_cost = SSmobs.profile_max_by_type[/mob/living/carbon/human]

	SSmobs.profile_cost_by_type = null
	SSmobs.profile_count_by_type = null
	SSmobs.profile_max_by_type = null
	SSmobs.profile_worst_by_type = null
	SSmobs.profile_sleepers_by_type = null

	TEST_ASSERT_EQUAL(max_cost, 26, "The profiler should still track the per-type maximum")
	TEST_ASSERT_NOTNULL(worst, "The profiler should record which item hit the maximum")
	TEST_ASSERT(findtext(worst, REF(pricey)), "The recorded worst item should identify the expensive mob, got: [worst]")
	TEST_ASSERT(!findtext(worst, REF(cheap)), "The recorded worst item should not be the cheap mob, got: [worst]")
	TEST_ASSERT_EQUAL(sleepers, 1, "The profiler should count how many measured items slept")

// -----------------------------------------------------------------------------
// The monkey cube cap used `>`, so it admitted cap+1 monkeys — the live server
// reported 91 tracked cube monkeys against a cap of 90. The rat caps next door
// use `>=`; monkeys now match.
// -----------------------------------------------------------------------------

/datum/unit_test/monkey_cube_cap_is_exact

/datum/unit_test/monkey_cube_cap_is_exact/Run()
	var/previous_cap = CONFIG_GET(number/monkeycap)
	CONFIG_SET(number/monkeycap, 3)

	var/tracked_before = length(SSmobs.cubemonkeys)
	var/list/spawned = list()
	for(var/i in 1 to 5)
		var/mob/living/carbon/monkey/cube_monkey = new /mob/living/carbon/monkey(run_loc_floor_bottom_left, TRUE)
		if(!QDELETED(cube_monkey))
			spawned += cube_monkey

	var/tracked_after = length(SSmobs.cubemonkeys) - tracked_before

	for(var/mob/living/carbon/monkey/spawn_result as anything in spawned)
		qdel(spawn_result)
	CONFIG_SET(number/monkeycap, previous_cap)

	TEST_ASSERT_EQUAL(tracked_after, 3, "A cap of 3 must admit exactly 3 cube monkeys")
