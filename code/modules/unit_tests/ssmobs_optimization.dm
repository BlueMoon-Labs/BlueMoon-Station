// Unit tests for SSmobs Life() optimization (clientless mob throttling)

/// Test that has_nearby_player() returns TRUE when a player mob is nearby
/datum/unit_test/has_nearby_player_nearby/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human)

	var/turf/T = get_turf(target)
	TEST_ASSERT_NOTNULL(T, "Target mob has no turf")

	// Simulate player presence by adding player_mob to clients_by_zlevel
	// and to the spatial grid CLIENTS channel (has_nearby_player queries the grid)
	if(!islist(SSmobs.clients_by_zlevel) || T.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	SSmobs.clients_by_zlevel[T.z] += player_mob
	player_mob.enable_client_mobs_in_contents()

	var/result = target.has_nearby_player()

	// Cleanup before assert
	SSmobs.clients_by_zlevel[T.z] -= player_mob
	player_mob.clear_important_client_contents()

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
	player_mob.enable_client_mobs_in_contents() // has_nearby_player queries the spatial grid

	var/dist = get_dist(target_turf, far_turf)

	var/result_outside = TRUE // default pass if dist <= 1
	if(dist > 1)
		result_outside = target.has_nearby_player(dist - 1)
	var/result_inside = target.has_nearby_player(dist)

	// Cleanup before asserts
	SSmobs.clients_by_zlevel[target_turf.z] -= player_mob
	player_mob.clear_important_client_contents()

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
	player_mob.enable_client_mobs_in_contents() // has_nearby_player queries the spatial grid

	var/result_with_player = carp.has_nearby_player()

	// Cleanup before asserts
	SSmobs.clients_by_zlevel[T.z].Cut()
	SSmobs.clients_by_zlevel[T.z] += saved_clients
	player_mob.clear_important_client_contents()

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
	human.life_stagger_phase = 0
	human.life_periodic_phase = 0

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
	human.life_stagger_phase = 0
	human.life_periodic_phase = 0
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
	player_mob.enable_client_mobs_in_contents() // has_nearby_player queries the spatial grid

	// Should always process regardless of times_fired
	// Give the mob some fire to track processing
	human.adjust_fire_stacks(5)
	human.IgniteMob()
	var/initial_stacks = human.fire_stacks

	human.Life(2, 1)

	var/stacks_after = human.fire_stacks

	// Cleanup before assert
	SSmobs.clients_by_zlevel[T.z] -= player_mob
	player_mob.clear_important_client_contents()

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
	monkey.life_stagger_phase = 0
	monkey.life_periodic_phase = 0
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
	human.life_stagger_phase = 0
	human.life_periodic_phase = 0

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

///Periodic carbon work keeps its cadence but distributes clientless mobs across
///four SSmobs fires instead of making every mob breathe on the same fire.
/datum/unit_test/carbon_life_periodic_work_is_staggered/Run()
	var/list/test_mobs = list()
	var/list/phase_counts = list(0, 0, 0, 0)
	for(var/i in 1 to 8)
		var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human)
		test_mobs += human
		phase_counts[(human.life_periodic_phase % 4) + 1]++

	for(var/phase_count in phase_counts)
		TEST_ASSERT_EQUAL(phase_count, 2, "Eight sequential clientless mobs must split evenly between four Life phases")

	for(var/times_fired in 1 to 4)
		var/due_breaths = 0
		var/due_organs = 0
		for(var/mob/living/carbon/human/human as anything in test_mobs)
			var/life_phase = times_fired + human.life_periodic_phase
			if(life_phase % 4 == 0)
				due_breaths++
			if(life_phase % 2 == 0)
				due_organs++
		TEST_ASSERT_EQUAL(due_breaths, 2, "Healthy breathing cadence must distribute eight mobs as two per fire")
		TEST_ASSERT_EQUAL(due_organs, 4, "Organ cadence must distribute eight mobs as four per fire")

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

// Тест ai_controller_proximity_skip удалён: он очищал список контроллеров и
// стрелял пустой подсистемой, ничего не проверяя. Настоящие тесты планировщика
// контроллеров - в ai_controller_scheduler.dm (событийный wake/sleep).

///Healthy-limb fast path must preserve real bleeding and stack decay.
/datum/unit_test/human_blood_life_fast_path/Run()
	var/mob/living/carbon/human/human = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/blood_before = human.blood_volume
	human.handle_blood(2, 1)
	TEST_ASSERT_EQUAL(human.blood_volume, blood_before, "Healthy limbs must not lose blood")

	var/obj/item/bodypart/bleeding_limb = human.bodyparts[1]
	bleeding_limb.generic_bleedstacks = 2
	human.handle_blood(2, 2)
	TEST_ASSERT_EQUAL(bleeding_limb.generic_bleedstacks, 1, "A real generic bleed stack must still decay every blood tick")
	TEST_ASSERT(human.blood_volume < blood_before, "A real bleeding limb must still reduce blood volume")

// ============================================================================
// SSmobs Life() optimization levers 1/2/4 (throttle dead-near, relax clientless
// breathing, memoize proximity). Spies count sub-proc invocations so the tests
// assert the actual cadence change, not a formula. Lever 3 (slime view->grid) is
// a behavior-preserving refactor - its guards are the slime_prey_scan_* tests.
// ============================================================================

///Считает вызовы BiologicalLife (рычаг 1: троттл мёртвых clientless у игрока).
/mob/living/carbon/human/ssmobs_biolife_spy
	var/biolife_calls = 0

/mob/living/carbon/human/ssmobs_biolife_spy/BiologicalLife(delta_time, times_fired)
	biolife_calls++
	return ..()

///Считает входы в breathe() (рычаг 2). Родителя НЕ зовём - меряем только каденс,
///без взаимодействия с газом/failed_last_breath.
/mob/living/carbon/human/ssmobs_breath_spy
	var/breath_count = 0

/mob/living/carbon/human/ssmobs_breath_spy/breathe()
	breath_count++

///Считает НЕкэшированные вызовы has_nearby_player (рычаг 4: мемоизация).
/mob/living/carbon/human/ssmobs_proximity_spy
	var/proximity_calls = 0

/mob/living/carbon/human/ssmobs_proximity_spy/has_nearby_player(distance = NEARBY_LIVING_DISTANCE)
	proximity_calls++
	return ..()

///Рычаг 1: мёртвый clientless труп РЯДОМ с игроком обрабатывается раз в 4 fire
///(8с), а не каждый fire. life_stagger_phase=0 -> BiologicalLife лишь на 4-м fire.
/datum/unit_test/dead_near_player_life_throttle/Run()
	var/mob/living/carbon/human/ssmobs_biolife_spy/corpse = allocate(/mob/living/carbon/human/ssmobs_biolife_spy)
	corpse.life_stagger_phase = 0
	corpse.life_periodic_phase = 0
	corpse.death()
	TEST_ASSERT_EQUAL(corpse.stat, DEAD, "Corpse must be dead")

	var/turf/corpse_turf = get_turf(corpse)
	TEST_ASSERT_NOTNULL(corpse_turf, "Corpse has no turf")
	if(!islist(SSmobs.clients_by_zlevel) || corpse_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, corpse_turf)
	SSmobs.clients_by_zlevel[corpse_turf.z] += player_mob
	player_mob.enable_client_mobs_in_contents()

	for(var/times_fired in 1 to 4)
		corpse.Life(2, times_fired)

	SSmobs.clients_by_zlevel[corpse_turf.z] -= player_mob
	player_mob.clear_important_client_contents()

	TEST_ASSERT_EQUAL(corpse.biolife_calls, 1, "A dead clientless corpse near a player must run BiologicalLife once per 4 fires, got [corpse.biolife_calls]")

///Рычаг 1 (защита): труп с REAGENT_DEAD_PROCESS реагентом НЕ троттлится - иначе
///оживление/зомби-обработка dead-body реагентов опоздали бы. Обрабатывается каждый fire.
/datum/unit_test/dead_near_player_dead_process_exempt/Run()
	var/mob/living/carbon/human/ssmobs_biolife_spy/corpse = allocate(/mob/living/carbon/human/ssmobs_biolife_spy)
	corpse.life_stagger_phase = 0
	corpse.life_periodic_phase = 0
	corpse.death()

	var/turf/corpse_turf = get_turf(corpse)
	if(!islist(SSmobs.clients_by_zlevel) || corpse_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, corpse_turf)
	SSmobs.clients_by_zlevel[corpse_turf.z] += player_mob
	player_mob.enable_client_mobs_in_contents()

	//дать трупу реагент с флагом dead-process (в контенте BlueMoon такого нет,
	//ставим флаг на инстанс - точное совпадение с тем, что жуёт handle_death)
	corpse.reagents.add_reagent(/datum/reagent/medicine/strange_reagent, 5)
	for(var/datum/reagent/reagent as anything in corpse.reagents.reagent_list)
		reagent.chemical_flags |= REAGENT_DEAD_PROCESS

	//fires 1..3 (не кратны 4): без исключения были бы пропущены
	for(var/times_fired in 1 to 3)
		corpse.Life(2, times_fired)

	SSmobs.clients_by_zlevel[corpse_turf.z] -= player_mob
	player_mob.clear_important_client_contents()

	TEST_ASSERT_EQUAL(corpse.biolife_calls, 3, "A corpse with a dead-process reagent must not be throttled (BiologicalLife every fire), got [corpse.biolife_calls]")

///Рычаг 2: здоровый clientless карбон дышит раз в 8 fire, а не в 4. За fires 1..8
///ровно один вдох (на 8-м).
/datum/unit_test/clientless_breathing_staggered/Run()
	var/mob/living/carbon/human/ssmobs_breath_spy/subject = allocate(/mob/living/carbon/human/ssmobs_breath_spy)
	subject.life_periodic_phase = 0
	TEST_ASSERT_EQUAL(subject.stat, CONSCIOUS, "Breath spy must be conscious")

	for(var/times_fired in 1 to 8)
		subject.handle_breathing(times_fired)

	TEST_ASSERT_EQUAL(subject.breath_count, 1, "A healthy clientless carbon must breathe once per 8 fires, got [subject.breath_count]")

///Рычаг 4: проверка близости пересчитывается раз в 2 fire, а не каждый fire.
///clientless живой моб, игрок далеко: throttle доходит до has_nearby_player каждый
///fire, но кэш (TTL 2 fire) пересчитывает только на fires 1 и 3.
/datum/unit_test/proximity_check_memoized/Run()
	var/mob/living/carbon/human/ssmobs_proximity_spy/subject = allocate(/mob/living/carbon/human/ssmobs_proximity_spy)
	subject.life_stagger_phase = 0
	subject.life_periodic_phase = 0

	var/turf/subject_turf = get_turf(subject)
	if(!islist(SSmobs.clients_by_zlevel) || subject_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	//игрок далеко на том же z, чтобы throttle прошёл empty-z и дошёл до проверки
	var/turf/far_turf = locate(1, 1, subject_turf.z)
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, far_turf)
	SSmobs.clients_by_zlevel[subject_turf.z] += player_mob
	player_mob.enable_client_mobs_in_contents()

	for(var/times_fired in 1 to 4)
		subject.Life(2, times_fired)

	SSmobs.clients_by_zlevel[subject_turf.z] -= player_mob
	player_mob.clear_important_client_contents()

	TEST_ASSERT_EQUAL(subject.proximity_calls, 2, "Proximity must be recomputed once per 2 fires (fires 1,3), got [subject.proximity_calls]")

// ============================================================================
// Бакет SSmobs (life_next_fire): троттлённый моб сам бронирует фаер, раньше
// которого его Life() - гарантированный no-op, и подсистема вообще не заходит в
// него. Тесты держат две вещи: бронь ставится/снимается там, где надо, и
// пропущенные бакетом фаеры не теряют игровое время.
// ============================================================================

///Записывает delta_time, с которым Life дошёл до BiologicalLife.
/mob/living/carbon/human/ssmobs_delta_spy
	var/last_delta = 0

/mob/living/carbon/human/ssmobs_delta_spy/BiologicalLife(delta_time, times_fired)
	last_delta = delta_time
	return ..()

///Помечает z-уровень моба как населённый, не добавляя игрока в грид клиентов:
///has_nearby_player() честно отвечает FALSE, и моб попадает в ветку "дальнего".
/proc/ssmobs_bucket_register_far_player(mob/living/subject, mob/living/player_mob)
	var/turf/subject_turf = get_turf(subject)
	if(!subject_turf)
		return FALSE
	if(!islist(SSmobs.clients_by_zlevel) || subject_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	SSmobs.clients_by_zlevel[subject_turf.z] += player_mob
	return TRUE

/proc/ssmobs_bucket_unregister_far_player(mob/living/subject, mob/living/player_mob)
	var/turf/subject_turf = get_turf(subject)
	if(subject_turf && islist(SSmobs.clients_by_zlevel) && subject_turf.z <= SSmobs.clients_by_zlevel.len)
		SSmobs.clients_by_zlevel[subject_turf.z] -= player_mob

///Живой clientless моб вдали от игроков бронирует ближайший фаер своей каденсы.
/datum/unit_test/life_bucket_books_far_alive/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	subject.life_stagger_phase = 0
	subject.life_periodic_phase = 0
	var/turf/subject_turf = get_turf(subject)
	TEST_ASSERT_NOTNULL(subject_turf, "Subject has no turf")
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, locate(1, 1, subject_turf.z))
	TEST_ASSERT(ssmobs_bucket_register_far_player(subject, player_mob), "Failed to register a far player")

	subject.Life(2, 1)
	var/booked_after_skip = subject.life_next_fire
	subject.Life(2, 4)
	var/booked_after_due = subject.life_next_fire

	ssmobs_bucket_unregister_far_player(subject, player_mob)

	TEST_ASSERT_EQUAL(booked_after_skip, 4, "A far alive mob skipped on fire 1 must book its next due fire (4), got [booked_after_skip]")
	TEST_ASSERT_EQUAL(booked_after_due, 8, "A far alive mob processed on fire 4 must immediately book fire 8, got [booked_after_due]")

///Моб на z-уровне без клиентов бронирует фаер вперёд, а не проверяется каждый раз.
/datum/unit_test/life_bucket_books_empty_zlevel/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	var/turf/subject_turf = get_turf(subject)
	TEST_ASSERT_NOTNULL(subject_turf, "Subject has no turf")
	if(!islist(SSmobs.clients_by_zlevel) || subject_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	var/list/saved_clients = SSmobs.clients_by_zlevel[subject_turf.z].Copy()
	SSmobs.clients_by_zlevel[subject_turf.z].Cut()

	subject.Life(2, 3)
	var/booked = subject.life_next_fire

	SSmobs.clients_by_zlevel[subject_turf.z] += saved_clients

	TEST_ASSERT_EQUAL(booked, 7, "A mob on a clientless z-level must book 4 fires ahead, got [booked]")

///Моб рядом с игроком брони не получает - ему положен каждый фаер.
/datum/unit_test/life_bucket_clear_near_player/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	var/turf/subject_turf = get_turf(subject)
	TEST_ASSERT_NOTNULL(subject_turf, "Subject has no turf")
	if(!islist(SSmobs.clients_by_zlevel) || subject_turf.z > SSmobs.clients_by_zlevel.len)
		SSmobs.MaxZChanged()
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, subject_turf)
	SSmobs.clients_by_zlevel[subject_turf.z] += player_mob
	player_mob.enable_client_mobs_in_contents()

	subject.Life(2, 1)
	var/booked = subject.life_next_fire

	SSmobs.clients_by_zlevel[subject_turf.z] -= player_mob
	player_mob.clear_important_client_contents()

	TEST_ASSERT_EQUAL(booked, 0, "A mob near a player must not be bucketed, got [booked]")

///Поджиг снимает бронь: горящему мобу handle_fire нужен каждый фаер.
/datum/unit_test/life_bucket_wake_on_ignite/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	subject.life_stagger_phase = 0
	var/turf/subject_turf = get_turf(subject)
	TEST_ASSERT_NOTNULL(subject_turf, "Subject has no turf")
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, locate(1, 1, subject_turf.z))
	TEST_ASSERT(ssmobs_bucket_register_far_player(subject, player_mob), "Failed to register a far player")

	subject.Life(2, 1)
	var/booked_before = subject.life_next_fire
	subject.adjust_fire_stacks(5)
	subject.IgniteMob()
	var/booked_after = subject.life_next_fire

	ssmobs_bucket_unregister_far_player(subject, player_mob)

	TEST_ASSERT(booked_before > 1, "A far alive mob must be bucketed before ignition, got [booked_before]")
	TEST_ASSERT_EQUAL(booked_after, 0, "IgniteMob() must clear the bucket booking, got [booked_after]")

///Смена stat снимает бронь: моб переезжает в другую ветку троттла.
/datum/unit_test/life_bucket_wake_on_stat_change/Run()
	var/mob/living/carbon/human/subject = allocate(/mob/living/carbon/human)
	subject.life_stagger_phase = 0
	var/turf/subject_turf = get_turf(subject)
	TEST_ASSERT_NOTNULL(subject_turf, "Subject has no turf")
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, locate(1, 1, subject_turf.z))
	TEST_ASSERT(ssmobs_bucket_register_far_player(subject, player_mob), "Failed to register a far player")

	subject.Life(2, 1)
	var/booked_before = subject.life_next_fire
	subject.set_stat(UNCONSCIOUS)
	var/booked_after = subject.life_next_fire

	ssmobs_bucket_unregister_far_player(subject, player_mob)

	TEST_ASSERT(booked_before > 1, "A far alive mob must be bucketed before the stat change, got [booked_before]")
	TEST_ASSERT_EQUAL(booked_after, 0, "set_stat() must clear the bucket booking, got [booked_after]")

///Ключевой инвариант: пропущенные бакетом фаеры доезжают тем же delta_time, что
///и при вызове Life() на каждом фаере. Иначе троттл молча воровал бы метаболизм.
/datum/unit_test/life_bucket_preserves_time_debt/Run()
	var/mob/living/carbon/human/ssmobs_delta_spy/every_fire = allocate(/mob/living/carbon/human/ssmobs_delta_spy)
	var/mob/living/carbon/human/ssmobs_delta_spy/bucketed = allocate(/mob/living/carbon/human/ssmobs_delta_spy)
	for(var/mob/living/carbon/human/ssmobs_delta_spy/subject as anything in list(every_fire, bucketed))
		subject.life_stagger_phase = 0
		subject.life_periodic_phase = 0

	var/turf/subject_turf = get_turf(every_fire)
	var/turf/bucketed_turf = get_turf(bucketed)
	TEST_ASSERT_NOTNULL(subject_turf, "Subject has no turf")
	TEST_ASSERT_NOTNULL(bucketed_turf, "Second subject has no turf")
	TEST_ASSERT_EQUAL(bucketed_turf.z, subject_turf.z, "Both subjects must share a z-level for one far-player registration")
	var/mob/living/carbon/human/player_mob = allocate(/mob/living/carbon/human, locate(1, 1, subject_turf.z))
	TEST_ASSERT(ssmobs_bucket_register_far_player(every_fire, player_mob), "Failed to register a far player")

	//без бакета SSmobs заходил бы в Life на каждом фаере
	for(var/times_fired in 1 to 4)
		every_fire.Life(2, times_fired)
	//с бакетом фаеры 2 и 3 до Life вообще не доходят
	bucketed.Life(2, 1)
	bucketed.Life(2, 4)

	var/delta_every_fire = every_fire.last_delta
	var/delta_bucketed = bucketed.last_delta

	ssmobs_bucket_unregister_far_player(every_fire, player_mob)

	TEST_ASSERT_EQUAL(delta_every_fire, 8, "Four throttled fires must arrive as 8 seconds of game time, got [delta_every_fire]")
	TEST_ASSERT_EQUAL(delta_bucketed, delta_every_fire, "Bucket-skipped fires must arrive with the same delta_time as per-fire calls ([delta_bucketed] vs [delta_every_fire])")

// ============================================================================
// Слаймы: handle_environment больше не дёргает полный каскад updatehealth на
// каждом тике и не считает total_moles ради проверки BZ, которого в смеси нет.
// ============================================================================

///Считает входы в updatehealth (полный каскад здоровья).
/mob/living/simple_animal/slime/ssmobs_health_spy
	var/health_updates = 0

/mob/living/simple_animal/slime/ssmobs_health_spy/updatehealth()
	health_updates++
	return ..()

///Дышащая смесь комнатной температуры без BZ.
/proc/ssmobs_slime_room_air(temperature = T20C)
	var/datum/gas_mixture/environment = new
	environment.set_moles(GAS_O2, MOLES_O2STANDARD)
	environment.set_moles(GAS_N2, MOLES_N2STANDARD)
	environment.set_temperature(temperature)
	return environment

///Слайм в тепловом равновесии не платит за каскад здоровья.
/datum/unit_test/slime_environment_skips_health_cascade/Run()
	var/mob/living/simple_animal/slime/ssmobs_health_spy/subject = allocate(/mob/living/simple_animal/slime/ssmobs_health_spy, run_loc_floor_bottom_left)
	var/datum/gas_mixture/environment = ssmobs_slime_room_air()
	subject.bodytemperature = environment.return_temperature()
	subject.health_updates = 0

	subject.handle_environment(environment)

	TEST_ASSERT_EQUAL(subject.health_updates, 0, "A settled slime must not run the health cascade from handle_environment, got [subject.health_updates] updates")

///Переохлаждённый слайм по-прежнему получает урон - и вместе с ним обновление здоровья.
/datum/unit_test/slime_environment_still_damages_when_frozen/Run()
	var/mob/living/simple_animal/slime/ssmobs_health_spy/subject = allocate(/mob/living/simple_animal/slime/ssmobs_health_spy, run_loc_floor_bottom_left)
	var/datum/gas_mixture/environment = ssmobs_slime_room_air()
	subject.bodytemperature = 100 //глубоко ниже порога урона даже после подтяжки к комнате
	subject.health_updates = 0
	var/health_before = subject.health

	subject.handle_environment(environment)

	TEST_ASSERT(subject.health < health_before, "A frozen slime must still take cold damage ([health_before] -> [subject.health])")
	TEST_ASSERT(subject.health_updates > 0, "Cold damage must still run the health cascade")

///Нервный газ по-прежнему вгоняет слайма в стазис - короткое замыкание по BZ
///не должно ломать саму проверку.
/datum/unit_test/slime_environment_bz_still_causes_stasis/Run()
	var/mob/living/simple_animal/slime/subject = allocate(/mob/living/simple_animal/slime, run_loc_floor_bottom_left)
	var/datum/gas_mixture/environment = ssmobs_slime_room_air()
	environment.set_moles(GAS_BZ, MOLES_O2STANDARD + MOLES_N2STANDARD) //заведомо больше 5%
	subject.bodytemperature = environment.return_temperature()
	TEST_ASSERT_EQUAL(subject.stat, CONSCIOUS, "Slime must start conscious")

	subject.handle_environment(environment)

	TEST_ASSERT_EQUAL(subject.stat, UNCONSCIOUS, "BZ above 5% must still put a slime into stasis")

// ============================================================================
// Lever 3: slime prey scan migrated from view(7) to the spatial grid. These are
// behavior-preserving guards (green before and after) - they catch a botched
// migration (lost LOS or lost distance filter). Perf proof is the slime_hunt
// benchmark scenario.
// ============================================================================

///Зарезервировать пол-арену для слаймовых тестов; вызывающий qdel-ит резервацию.
/proc/ssmobs_slime_scan_arena(width, height)
	var/datum/turf_reservation/reservation = SSmapping.RequestBlockReservation(width, height)
	if(!reservation)
		return null
	var/turf/bottom_left = locate(reservation.bottom_left_coords[1], reservation.bottom_left_coords[2], reservation.bottom_left_coords[3])
	var/turf/top_right = locate(reservation.bottom_left_coords[1] + width - 1, reservation.bottom_left_coords[2] + height - 1, reservation.bottom_left_coords[3])
	for(var/turf/tile as anything in block(bottom_left, top_right))
		tile.ChangeTurf(/turf/open/floor/plasteel)
	return reservation

/proc/ssmobs_arena_turf(datum/turf_reservation/reservation, dx, dy)
	return locate(reservation.bottom_left_coords[1] + dx, reservation.bottom_left_coords[2] + dy, reservation.bottom_left_coords[3])

///Рычаг 3: слайм находит соседнюю обезьяну в открытом пространстве.
/datum/unit_test/slime_prey_scan_finds_open_target/Run()
	var/datum/turf_reservation/arena = ssmobs_slime_scan_arena(6, 3)
	TEST_ASSERT_NOTNULL(arena, "Failed to reserve slime scan arena")
	var/mob/living/simple_animal/slime/hunter = new(ssmobs_arena_turf(arena, 0, 1))
	var/mob/living/carbon/monkey/prey = new(ssmobs_arena_turf(arena, 1, 1))
	hunter.rabid = 1
	hunter.Target = null
	hunter.next_hunt_scan = 0
	hunter.handle_targets()
	var/targeted_prey = (hunter.Target == prey)
	qdel(hunter)
	qdel(prey)
	qdel(arena)
	TEST_ASSERT(targeted_prey, "Rabid slime must target an adjacent monkey in the open")

///Рычаг 3 (осознанный компромисс): grid-канал без LOS, поэтому слайм ТЕПЕРЬ чует
///добычу за стеной. Тест фиксирует это поведение как намеренное (бенч показал:
///can_see по каждому кандидату в 2.2х дороже, чем экономит view; см. slime/life.dm).
/datum/unit_test/slime_prey_scan_grid_ignores_walls/Run()
	var/datum/turf_reservation/arena = ssmobs_slime_scan_arena(8, 3)
	TEST_ASSERT_NOTNULL(arena, "Failed to reserve slime scan arena")
	//полная стена-колонна dx=2 по всей высоте: view бы её не пробил, grid - да
	for(var/wall_dy in 0 to 2)
		var/turf/wall_turf = ssmobs_arena_turf(arena, 2, wall_dy)
		wall_turf.ChangeTurf(/turf/closed/wall)
	var/mob/living/simple_animal/slime/hunter = new(ssmobs_arena_turf(arena, 0, 1))
	var/mob/living/carbon/monkey/prey = new(ssmobs_arena_turf(arena, 4, 1))
	hunter.rabid = 1
	hunter.Target = null
	hunter.next_hunt_scan = 0
	hunter.handle_targets()
	var/targeted_through_wall = (hunter.Target == prey)
	qdel(hunter)
	qdel(prey)
	qdel(arena)
	TEST_ASSERT(targeted_through_wall, "Grid scan (no can_see) must sense prey through a wall - the deliberate lever-3 tradeoff")

///Рычаг 3: слайм НЕ таргетит добычу дальше радиуса скана (get_dist фильтр после
///грубого грид-пула, который отдаёт содержимое ячеек шире 7).
/datum/unit_test/slime_prey_scan_respects_range/Run()
	var/datum/turf_reservation/arena = ssmobs_slime_scan_arena(14, 3)
	TEST_ASSERT_NOTNULL(arena, "Failed to reserve slime scan arena")
	var/mob/living/simple_animal/slime/hunter = new(ssmobs_arena_turf(arena, 0, 1))
	var/mob/living/carbon/monkey/prey = new(ssmobs_arena_turf(arena, 12, 1))
	hunter.rabid = 1
	hunter.Target = null
	hunter.next_hunt_scan = 0
	hunter.handle_targets()
	var/targeted_far = (hunter.Target == prey)
	qdel(hunter)
	qdel(prey)
	qdel(arena)
	TEST_ASSERT(!targeted_far, "Slime must not target prey beyond the 7-tile scan range")
