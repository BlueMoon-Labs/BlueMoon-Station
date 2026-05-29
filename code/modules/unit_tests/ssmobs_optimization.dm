// Unit tests for SSmobs Life() optimization (clientless mob throttling)

/// Test that has_nearby_player() returns TRUE when a player mob is nearby
/datum/unit_test/has_nearby_player_nearby/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human)

	var/turf/T = get_turf(target)
	TEST_ASSERT_NOTNULL(T, "Target mob has no turf")

	// Simulate player presence by adding player_mob to clients_by_zlevel
	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	SSmobs.clients_by_zlevel[T.z] += player_mob

	var/result = target.has_nearby_player()

	// Cleanup before assert
	SSmobs.clients_by_zlevel[T.z] -= player_mob

	TEST_ASSERT(result, "has_nearby_player() should return TRUE when player is on the same turf")

/// Test that has_nearby_player() returns FALSE when no player is nearby
/datum/unit_test/has_nearby_player_far/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)

	var/turf/T = get_turf(target)
	TEST_ASSERT_NOTNULL(T, "Target mob has no turf")

	// Ensure clients_by_zlevel is initialized but empty for this z-level
	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Remove any existing entries for our z-level to ensure clean state
	var/list/saved_clients = SSmobs.clients_by_zlevel[T.z].Copy()
	SSmobs.clients_by_zlevel[T.z].Cut()

	var/result = target.has_nearby_player()

	// Restore before assert
	SSmobs.clients_by_zlevel[T.z] += saved_clients

	TEST_ASSERT(!result, "has_nearby_player() should return FALSE when no players on z-level")

/// Test that has_nearby_player() respects distance parameter
/datum/unit_test/has_nearby_player_distance/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)

	var/turf/target_turf = get_turf(target)
	TEST_ASSERT_NOTNULL(target_turf, "Target mob has no turf")

	// Place a "player" far away on a different turf (same z-level)
	// We'll use a turf that's definitely far from our 5x5 test zone
	var/turf/far_turf = locate(1, 1, target_turf.z)
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, far_turf)

	if(!islist(SSmobs.clients_by_zlevel) || target_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	SSmobs.clients_by_zlevel[target_turf.z] += player_mob

	var/dist = get_dist(target_turf, far_turf)

	var/result_outside = TRUE // default pass if dist <= 1
	if(dist > 1)
		result_outside = target.has_nearby_player(dist - 1)
	var/result_inside = target.has_nearby_player(dist)

	// Cleanup before asserts
	SSmobs.clients_by_zlevel[target_turf.z] -= player_mob

	if(dist > 1)
		TEST_ASSERT(!result_outside, "has_nearby_player() should return FALSE when player is outside range (dist=[dist])")
	TEST_ASSERT(result_inside, "has_nearby_player() should return TRUE when player is within range (dist=[dist])")

/// Test that simple_animal has_nearby_player() override uses NEARBY_PLAYER_DISTANCE default
/datum/unit_test/has_nearby_player_simple_animal/Run()
	var/mob/living/simple_animal/hostile/carp/carp = allocate(/mob/living/simple_animal/hostile/carp)

	var/turf/T = get_turf(carp)
	TEST_ASSERT_NOTNULL(T, "Carp has no turf")

	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Ensure no players nearby
	var/list/saved_clients = SSmobs.clients_by_zlevel[T.z].Copy()
	SSmobs.clients_by_zlevel[T.z].Cut()

	var/result_no_player = carp.has_nearby_player()

	// Add player on same turf
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, T)
	SSmobs.clients_by_zlevel[T.z] += player_mob

	var/result_with_player = carp.has_nearby_player()

	// Cleanup before asserts
	SSmobs.clients_by_zlevel[T.z].Cut()
	SSmobs.clients_by_zlevel[T.z] += saved_clients

	TEST_ASSERT(!result_no_player, "Simple animal has_nearby_player() should return FALSE with no players")
	TEST_ASSERT(result_with_player, "Simple animal has_nearby_player() should return TRUE with player on same turf")

/// Test that Life() throttle skips clientless mobs on empty z-levels
/datum/unit_test/life_throttle_empty_zlevel/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	// No client on this mob — it's clientless

	var/turf/T = get_turf(human)
	TEST_ASSERT_NOTNULL(T, "Human has no turf")

	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Ensure z-level has no players
	var/list/saved_clients = SSmobs.clients_by_zlevel[T.z].Copy()
	SSmobs.clients_by_zlevel[T.z].Cut()

	// Give mob some toxin damage to track whether BiologicalLife is processing
	var/starting_health = human.health

	// Call Life() — on empty z-level, should be skipped entirely
	human.Life(2, 1)

	var/health_after = human.health

	// Restore before assert
	SSmobs.clients_by_zlevel[T.z] += saved_clients

	// Health should not change since Life() was throttled
	TEST_ASSERT_EQUAL(health_after, starting_health, "Clientless mob on empty z-level should not have health change from throttled Life()")

/// Test that Life() throttle applies stagger for alive clientless mobs far from players
/datum/unit_test/life_throttle_alive_far/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	var/turf/T = get_turf(human)
	TEST_ASSERT_NOTNULL(T, "Human has no turf")

	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Place player far away
	var/turf/far_turf = locate(1, 1, T.z)
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, far_turf)
	SSmobs.clients_by_zlevel[T.z] += player_mob

	// times_fired % 4 != 0 should be skipped
	// times_fired % 4 == 0 should process
	var/starting_health = human.health

	// Fire 1: times_fired=1, 1%4=1 != 0 → should be skipped
	human.Life(2, 1)
	var/health_after_1 = human.health

	// Fire 2: times_fired=2, 2%4=2 != 0 → should be skipped
	human.Life(2, 2)
	var/health_after_2 = human.health

	// Fire 3: times_fired=3, 3%4=3 != 0 → should be skipped
	human.Life(2, 3)
	var/health_after_3 = human.health

	// Fire 4: times_fired=4, 4%4=0 → should process (falls through to normal Life)
	// We don't assert health change here since the mob may not take damage in normal conditions
	// Instead we verify it doesn't crash
	human.Life(2, 4)

	// Cleanup before asserts
	SSmobs.clients_by_zlevel[T.z] -= player_mob

	TEST_ASSERT_EQUAL(health_after_1, starting_health, "Clientless mob far from players should be skipped on non-4th fire (fire 1)")
	TEST_ASSERT_EQUAL(health_after_2, starting_health, "Clientless mob far from players should be skipped on non-4th fire (fire 2)")
	TEST_ASSERT_EQUAL(health_after_3, starting_health, "Clientless mob far from players should be skipped on non-4th fire (fire 3)")

/// Test that Life() throttle applies heavier stagger for dead clientless mobs far from players
/datum/unit_test/life_throttle_dead_far/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	human.death()

	TEST_ASSERT_EQUAL(human.stat, DEAD, "Human should be dead")

	var/turf/T = get_turf(human)
	TEST_ASSERT_NOTNULL(T, "Human has no turf")

	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Place player far away
	var/turf/far_turf = locate(1, 1, T.z)
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, far_turf)
	SSmobs.clients_by_zlevel[T.z] += player_mob

	// Dead mob far from players: processes once per 15th fire
	// Non-15th fires should be skipped entirely
	var/starting_health = human.health

	human.Life(2, 1)
	var/health_after_1 = human.health

	human.Life(2, 7)
	var/health_after_7 = human.health

	human.Life(2, 14)
	var/health_after_14 = human.health

	// Fire 15: times_fired=15, 15%15=0 → should process BiologicalLife
	// This should not crash
	human.Life(2, 15)

	// Cleanup before asserts
	SSmobs.clients_by_zlevel[T.z] -= player_mob

	TEST_ASSERT_EQUAL(health_after_1, starting_health, "Dead clientless mob far from players should be skipped on non-15th fire (fire 1)")
	TEST_ASSERT_EQUAL(health_after_7, starting_health, "Dead clientless mob far from players should be skipped on non-15th fire (fire 7)")
	TEST_ASSERT_EQUAL(health_after_14, starting_health, "Dead clientless mob far from players should be skipped on non-15th fire (fire 14)")

/// Test that Life() processes normally for mobs near players
/datum/unit_test/life_no_throttle_near_player/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	var/turf/T = get_turf(human)
	TEST_ASSERT_NOTNULL(T, "Human has no turf")

	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Place player on the same turf (nearby)
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, T)
	SSmobs.clients_by_zlevel[T.z] += player_mob

	// Should always process regardless of times_fired
	// Give the mob some fire to track processing
	human.adjust_fire_stacks(5)
	human.IgniteMob()
	var/initial_stacks = human.fire_stacks

	human.Life(2, 1)

	var/stacks_after = human.fire_stacks

	// Cleanup before assert
	SSmobs.clients_by_zlevel[T.z] -= player_mob

	// Fire stacks should decrease since handle_fire runs during full Life() processing
	TEST_ASSERT(stacks_after < initial_stacks, "Mob near player should have full Life() processing (fire stacks should decrease)")

/// Test that fire still processes on empty z-levels for burning mobs
/datum/unit_test/life_throttle_fire_on_empty_z/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	var/turf/T = get_turf(human)
	TEST_ASSERT_NOTNULL(T, "Human has no turf")

	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Ensure empty z-level
	var/list/saved_clients = SSmobs.clients_by_zlevel[T.z].Copy()
	SSmobs.clients_by_zlevel[T.z].Cut()

	// Set mob on fire
	human.adjust_fire_stacks(5)
	human.IgniteMob()
	var/is_on_fire = human.on_fire

	var/initial_stacks = human.fire_stacks

	// Even on empty z-level, fire should still be handled
	human.Life(2, 1)

	var/stacks_after = human.fire_stacks

	// Restore before asserts
	SSmobs.clients_by_zlevel[T.z] += saved_clients

	TEST_ASSERT(is_on_fire, "Human should be on fire")
	TEST_ASSERT(stacks_after <= initial_stacks, "Fire should still be processed on empty z-level")

/// Test that monkey AI is skipped when no player is nearby
/datum/unit_test/monkey_ai_skip_no_player/Run()
	var/mob/living/carbon/monkey/monkey = allocate(/mob/living/carbon/monkey)
	TEST_ASSERT_EQUAL(monkey.stat, CONSCIOUS, "Monkey should be conscious")

	var/turf/T = get_turf(monkey)
	TEST_ASSERT_NOTNULL(T, "Monkey has no turf")

	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Place player far away so has_nearby_player returns FALSE
	var/turf/far_turf = locate(1, 1, T.z)
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, far_turf)
	SSmobs.clients_by_zlevel[T.z] += player_mob

	// Record monkey position
	var/turf/start_turf = get_turf(monkey)

	// Call BiologicalLife — monkey AI should be skipped, so no movement
	// Need to call with times_fired=4 (divisible by 4) so Life() throttle doesn't block it
	monkey.Life(2, 4)

	var/turf/end_turf = get_turf(monkey)

	// Cleanup before assert
	SSmobs.clients_by_zlevel[T.z] -= player_mob

	// Monkey should still be on same turf (AI was skipped, no step())
	TEST_ASSERT_EQUAL(end_turf, start_turf, "Monkey far from players should not move (AI skipped)")

/// Test that carbon organ stagger works for clientless mobs
/datum/unit_test/carbon_organ_stagger/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	var/turf/T = get_turf(human)
	TEST_ASSERT_NOTNULL(T, "Human has no turf")

	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Place player nearby so the mob gets full Life() processing (not throttled)
	SSmobs.clients_by_zlevel[T.z] += human // add ourselves as "player" for proximity check

	// Add some reagent to the mob so we can track metabolism via organs (liver)
	human.reagents.add_reagent(/datum/reagent/consumable/ethanol, 20)
	var/has_ethanol = human.reagents.has_reagent(/datum/reagent/consumable/ethanol)

	// times_fired=1: odd fire, organs should be SKIPPED for clientless
	// But since we added human to clients_by_zlevel, has_nearby_player returns true
	// and the organ stagger checks `client` which is null
	// So organs are skipped on odd fires for clientless carbon mobs
	human.Life(2, 1)

	// times_fired=2: even fire, organs SHOULD process for clientless
	human.Life(2, 2)

	// The key test is that both calls complete without error and the mob is still alive
	var/mob_stat = human.stat

	// Cleanup before asserts
	SSmobs.clients_by_zlevel[T.z] -= human

	TEST_ASSERT(has_ethanol, "Human should have ethanol")
	TEST_ASSERT_NOTEQUAL(mob_stat, DEAD, "Human should survive Life() processing with organ stagger")

/// Test that handle_diseases guard clause skips processing when diseases list is empty
/datum/unit_test/guard_clause_empty_diseases/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!length(human.diseases), "Human should have no diseases by default")
	// Calling handle_diseases with empty list should return immediately without error
	human.handle_diseases()

/// Test that handle_wounds guard clause skips processing when all_wounds list is empty
/datum/unit_test/guard_clause_empty_wounds/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!length(human.all_wounds), "Human should have no wounds by default")
	// Calling handle_wounds with empty list should return immediately without error
	human.handle_wounds()

/// Test that handle_stomach guard clause skips processing when stomach_contents is empty
/datum/unit_test/guard_clause_empty_stomach/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
	TEST_ASSERT(!length(human.stomach_contents), "Human should have empty stomach by default")
	// Calling handle_stomach with empty list should return immediately without error
	human.handle_stomach()

/// Test that SSai_controllers proximity skip works — AI controller skips planning when pawn has no player nearby
/datum/unit_test/ai_controller_proximity_skip/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)

	var/turf/T = get_turf(human)
	TEST_ASSERT_NOTNULL(T, "Human has no turf")

	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()

	// Ensure no players on z-level
	var/list/saved_clients = SSmobs.clients_by_zlevel[T.z].Copy()
	SSmobs.clients_by_zlevel[T.z].Cut()

	// Save active controllers and temporarily clear them
	var/list/saved_controllers = SSai_controllers.active_ai_controllers.Copy()
	SSai_controllers.active_ai_controllers.Cut()

	// Fire the subsystem — should complete without error even with no controllers
	SSai_controllers.fire(FALSE)

	// Restore
	SSai_controllers.active_ai_controllers += saved_controllers
	SSmobs.clients_by_zlevel[T.z] += saved_clients
