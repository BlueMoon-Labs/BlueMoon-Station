/datum/unit_test/projectile_movetypes/Run()
	for(var/path in typesof(/obj/item/projectile))
		var/obj/item/projectile/projectile = path
		if(initial(projectile.movement_type) & PHASING)
			TEST_FAIL("[path] has default movement type PHASING. Piercing projectiles should be done using the projectile piercing system, not movement_types!")

/datum/unit_test/projectile_piercing_contracts/Run()
	var/mob/living/carbon/human/target = allocate(/mob/living/carbon/human, run_loc_floor_bottom_left)
	var/obj/item/projectile/bullet/magnetic/hyper/hyper_round = allocate(/obj/item/projectile/bullet/magnetic/hyper, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(hyper_round.prehit_pierce(target), PROJECTILE_PIERCE_HIT, "A hyper round must hit and continue through its target")

	var/obj/item/projectile/bullet/cannonball/cannonball = allocate(/obj/item/projectile/bullet/cannonball, run_loc_floor_bottom_left)
	TEST_ASSERT_EQUAL(cannonball.prehit_pierce(target), PROJECTILE_PIERCE_HIT, "A cannonball with momentum must hit and continue")
	TEST_ASSERT_EQUAL(cannonball.damage, 100, "A pierced target must consume cannonball momentum")
	cannonball.damage = 40
	TEST_ASSERT_EQUAL(cannonball.prehit_pierce(target), PROJECTILE_PIERCE_NONE, "A spent cannonball must hit its final target and stop")

/obj/item/projectile/unit_test_elapsed_processing
	var/processed_pixel_steps = 0
	var/simulated_seconds = 0

/obj/item/projectile/unit_test_elapsed_processing/pixel_move(times, hitscanning = FALSE, seconds_equivalent = world.tick_lag * 0.1, trajectory_multiplier = 1, allow_animation = TRUE)
	processed_pixel_steps += times
	simulated_seconds += times * seconds_equivalent
	return times

/datum/unit_test/projectile_elapsed_time_catchup/Run()
	var/obj/item/projectile/unit_test_elapsed_processing/projectile = allocate(/obj/item/projectile/unit_test_elapsed_processing, run_loc_floor_bottom_left)
	projectile.pixel_increment_amount = SSprojectiles.global_pixel_increment_amount
	projectile.pixels_per_second = TILES_TO_PIXELS(1)
	projectile.trajectory = new(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z, 0, 0, EAST, projectile.pixel_increment_amount)
	projectile.fired = TRUE
	projectile.process(60)

	TEST_ASSERT_EQUAL(projectile.processed_pixel_steps * projectile.pixel_increment_amount, SSprojectiles.max_pixels_per_process, "One delayed projectile must not monopolize a tick with its whole elapsed path")
	TEST_ASSERT_EQUAL(projectile.pixels_tick_leftover, TILES_TO_PIXELS(60) - SSprojectiles.max_pixels_per_process, "Untraced elapsed distance must remain explicit movement debt")

	var/safety = 100
	while(projectile.pixels_tick_leftover >= projectile.pixel_increment_amount && safety--)
		projectile.process(0)
	TEST_ASSERT(safety > 0, "Bounded catch-up must drain in a finite number of projectile epochs")
	TEST_ASSERT_EQUAL(projectile.processed_pixel_steps * projectile.pixel_increment_amount, TILES_TO_PIXELS(60), "Bounded catch-up must eventually collision-trace the whole elapsed path")
	TEST_ASSERT(abs(projectile.simulated_seconds - 60) < 0.001, "Homing time must remain distributed across every traced step")
	TEST_ASSERT_EQUAL(projectile.pixels_tick_leftover, 0, "Fully drained whole-pixel catch-up must leave no movement debt")

/datum/unit_test/projectile_pattern_overload_delay/Run()
	var/list/saved_queue = SSprojectiles.projectile_queue
	var/list/saved_debt_queue = SSprojectiles.projectile_debt_queue
	var/list/saved_next_queue = SSprojectiles.projectile_next_queue
	var/list/saved_new_queue = SSprojectiles.projectile_new_queue
	SSprojectiles.projectile_queue = new /list(SSprojectiles.pattern_soft_limit)
	SSprojectiles.projectile_debt_queue = list()
	SSprojectiles.projectile_next_queue = list()
	SSprojectiles.projectile_new_queue = list()

	TEST_ASSERT_EQUAL(SSprojectiles.recommended_pattern_delay(1), 1, "Projectile patterns must keep their normal cadence at the soft limit")
	TEST_ASSERT(!SSprojectiles.pattern_at_capacity(), "Projectile patterns must remain admitted below the hard limit")
	SSprojectiles.projectile_queue.len = SSprojectiles.pattern_soft_limit + 1
	TEST_ASSERT_EQUAL(SSprojectiles.recommended_pattern_delay(1), 2, "Projectile patterns must begin yielding above the soft limit")
	TEST_ASSERT_EQUAL(SSprojectiles.recommended_pattern_delay(8), 9, "Slower projectile patterns must also receive overload backpressure")
	SSprojectiles.projectile_queue.len = SSprojectiles.pattern_soft_limit + (SSprojectiles.pattern_delay_step * 10)
	TEST_ASSERT_EQUAL(SSprojectiles.recommended_pattern_delay(8), 18, "Projectile overload delay must scale from the pattern's normal cadence")
	SSprojectiles.projectile_queue.len = SSprojectiles.pattern_soft_limit + (SSprojectiles.pattern_delay_step * 100)
	TEST_ASSERT_EQUAL(SSprojectiles.recommended_pattern_delay(8), SSprojectiles.pattern_max_delay, "Projectile overload delay must remain capped")
	TEST_ASSERT(SSprojectiles.pattern_at_capacity(), "Projectile patterns must stop admission at the hard limit")

	SSprojectiles.projectile_queue = saved_queue
	SSprojectiles.projectile_debt_queue = saved_debt_queue
	SSprojectiles.projectile_next_queue = saved_next_queue
	SSprojectiles.projectile_new_queue = saved_new_queue

/datum/unit_test/hitby_signal_qdel_safe
	var/atom/movable/hit_target

/datum/unit_test/hitby_signal_qdel_safe/proc/delete_hit_target(datum/source)
	SIGNAL_HANDLER
	qdel(source)

/datum/unit_test/hitby_signal_qdel_safe/Run()
	hit_target = new(run_loc_floor_bottom_left)
	RegisterSignal(hit_target, COMSIG_ATOM_HITBY, PROC_REF(delete_hit_target))
	hit_target.hitby(new /obj/item(run_loc_floor_top_right))
	TEST_ASSERT(QDELETED(hit_target), "COMSIG_ATOM_HITBY must be allowed to delete its receiver without scheduling callbacks on it")
	hit_target = null

/datum/unit_test/projectile_qdeleted_combat_refs_clear_while_queued/Run()
	var/mob/living/simple_animal/shooter = new(run_loc_floor_bottom_left)
	var/mob/living/simple_animal/target = new(run_loc_floor_top_right)
	var/obj/item/projectile/projectile = new(run_loc_floor_bottom_left)
	projectile.firer = shooter
	projectile.fired_from = shooter
	projectile.original = target
	projectile.homing_target = target
	projectile.register_combat_reference_signals()

	qdel(target)
	TEST_ASSERT_NULL(projectile.original, "A queued projectile must release its qdeleted original target immediately")
	TEST_ASSERT_NULL(projectile.homing_target, "A queued projectile must release its qdeleted homing target immediately")
	TEST_ASSERT_EQUAL(projectile.firer, shooter, "Deleting the target must not clear the projectile shooter")

	qdel(shooter)
	TEST_ASSERT_NULL(projectile.firer, "A queued projectile must release its qdeleted shooter immediately")
	TEST_ASSERT_NULL(projectile.fired_from, "A queued projectile must release its qdeleted firing source immediately")
	qdel(projectile)

/datum/unit_test/pellet_cloud_logs_one_projectile/Run()
	var/mob/living/simple_animal/shooter = allocate(/mob/living/simple_animal, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/target = allocate(/mob/living/simple_animal, run_loc_floor_top_right)
	var/obj/item/ammo_casing/shotgun/buckshot/casing = allocate(/obj/item/ammo_casing/shotgun/buckshot, run_loc_floor_bottom_left)

	TEST_ASSERT(casing.fire_casing(target, shooter, fired_from = shooter), "Sanity: the buckshot casing must fire")
	var/datum/component/pellet_cloud/cloud = casing.GetComponent(/datum/component/pellet_cloud)
	TEST_ASSERT_NOTNULL(cloud, "A multi-pellet casing must create a pellet cloud")
	TEST_ASSERT_EQUAL(length(cloud.pellets), initial(casing.pellets), "The cloud must retain every gameplay pellet")

	var/logged_projectiles = 0
	var/list/fired_pellets = cloud.pellets.Copy()
	for(var/obj/item/projectile/pellet as anything in fired_pellets)
		if(!pellet.log_override)
			logged_projectiles++
	TEST_ASSERT_EQUAL(logged_projectiles, 1, "One shell must produce one combat-log record instead of one per pellet")

	for(var/obj/item/projectile/pellet as anything in fired_pellets)
		qdel(pellet)

/datum/unit_test/projectile_destroy_releases_combat_refs/Run()
	var/mob/living/simple_animal/shooter = allocate(/mob/living/simple_animal, run_loc_floor_bottom_left)
	var/mob/living/simple_animal/target = allocate(/mob/living/simple_animal, run_loc_floor_top_right)
	var/obj/item/projectile/projectile = new(run_loc_floor_bottom_left)
	projectile.firer = shooter
	projectile.fired_from = shooter
	projectile.original = target
	projectile.homing_target = target
	projectile.starting = run_loc_floor_bottom_left
	projectile.last_angle_set_hitscan_store = run_loc_floor_bottom_left
	projectile.impacted = list(target = TRUE)

	qdel(projectile)
	TEST_ASSERT_NULL(projectile.firer, "Projectile Destroy must release its shooter")
	TEST_ASSERT_NULL(projectile.fired_from, "Projectile Destroy must release its firing source")
	TEST_ASSERT_NULL(projectile.original, "Projectile Destroy must release its original target")
	TEST_ASSERT_NULL(projectile.homing_target, "Projectile Destroy must release its homing target")
	TEST_ASSERT_NULL(projectile.starting, "Projectile Destroy must release its starting turf")
	TEST_ASSERT_NULL(projectile.last_angle_set_hitscan_store, "Projectile Destroy must release its hitscan turf")
	TEST_ASSERT_NULL(projectile.impacted, "Projectile Destroy must release its impact set")

/obj/item/projectile/unit_test_scheduler_probe
	var/process_count = 0
	var/obj/item/projectile/unit_test_scheduler_probe/admit_during_process
	var/leave_debt_on_first_process = FALSE

/obj/item/projectile/unit_test_scheduler_probe/process(elapsed_seconds_override)
	process_count++
	if(admit_during_process)
		SSprojectiles.start_projectile(admit_during_process)
		admit_during_process = null
	if(leave_debt_on_first_process && process_count == 1)
		pixels_tick_leftover = pixel_increment_amount
	else
		pixels_tick_leftover = 0

/datum/unit_test_projectile_generic_probe
	var/process_count = 0
	var/datum/unit_test_projectile_generic_probe/stop_during_process

/datum/unit_test_projectile_generic_probe/process(delta_time)
	process_count++
	if(stop_during_process)
		STOP_PROCESSING(SSprojectiles, stop_during_process)
		stop_during_process = null

/datum/unit_test_projectile_generic_probe/Destroy()
	STOP_PROCESSING(SSprojectiles, src)
	return ..()

/// A projectile created while an overloaded epoch is already running must be
/// admitted alongside old work, not held behind the whole stale snapshot.
/datum/unit_test/projectile_scheduler_fair_admission/Run()
	var/list/saved_processing = SSprojectiles.processing
	var/list/saved_currentrun = SSprojectiles.currentrun
	var/list/saved_queue = SSprojectiles.projectile_queue
	var/list/saved_debt_queue = SSprojectiles.projectile_debt_queue
	var/list/saved_next_queue = SSprojectiles.projectile_next_queue
	var/list/saved_new_queue = SSprojectiles.projectile_new_queue
	var/saved_epoch_active = SSprojectiles.projectile_epoch_active
	var/saved_epoch_count = SSprojectiles.projectiles_processed_this_epoch
	var/saved_state = SSprojectiles.state
	var/saved_ticklimit = Master.current_ticklimit
	var/saved_profile_strikes = SSprojectiles.profile_strikes
	var/saved_profile_armed = SSprojectiles.profile_armed
	var/saved_profile_cooldown_until = SSprojectiles.profile_cooldown_until
	var/saved_current_pass_cost_ms = SSprojectiles.current_pass_cost_ms
	var/list/saved_profile_cost_by_type = SSprojectiles.profile_cost_by_type
	var/list/saved_profile_count_by_type = SSprojectiles.profile_count_by_type
	var/list/saved_profile_max_by_type = SSprojectiles.profile_max_by_type

	SSprojectiles.processing = list()
	SSprojectiles.currentrun = list()
	SSprojectiles.projectile_queue = list()
	SSprojectiles.projectile_debt_queue = list()
	SSprojectiles.projectile_next_queue = list()
	SSprojectiles.projectile_new_queue = list()
	SSprojectiles.projectile_epoch_active = FALSE
	SSprojectiles.state = SS_RUNNING
	SSprojectiles.profile_strikes = 0
	SSprojectiles.profile_armed = FALSE
	SSprojectiles.current_pass_cost_ms = 0
	SSprojectiles.profile_cost_by_type = null
	SSprojectiles.profile_count_by_type = null
	SSprojectiles.profile_max_by_type = null
	Master.current_ticklimit = 1000

	var/obj/item/projectile/unit_test_scheduler_probe/old_projectile = new(run_loc_floor_bottom_left)
	var/obj/item/projectile/unit_test_scheduler_probe/spawner = new(run_loc_floor_bottom_left)
	var/obj/item/projectile/unit_test_scheduler_probe/new_projectile = new(run_loc_floor_bottom_left)
	var/datum/unit_test_projectile_generic_probe/stopped_generic = new
	var/datum/unit_test_projectile_generic_probe/stopping_generic = new
	old_projectile.leave_debt_on_first_process = TRUE
	old_projectile.fired = TRUE
	old_projectile.pixels_per_second = TILES_TO_PIXELS(1)
	old_projectile.trajectory = new(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z, 0, 0, EAST, old_projectile.pixel_increment_amount)
	spawner.admit_during_process = new_projectile
	stopping_generic.stop_during_process = stopped_generic
	SSprojectiles.start_projectile(old_projectile)
	SSprojectiles.start_projectile(spawner)
	START_PROCESSING(SSprojectiles, stopped_generic)
	START_PROCESSING(SSprojectiles, stopping_generic)
	SSprojectiles.fire(FALSE)

	TEST_ASSERT_EQUAL(old_projectile.process_count, 1, "A projectile with movement debt must not run twice while caught-up shots wait for the next round")
	TEST_ASSERT_EQUAL(spawner.process_count, 1, "The projectile that creates a new shot must progress once per epoch")
	TEST_ASSERT_EQUAL(new_projectile.process_count, 1, "A shot admitted during the epoch must be serviced before that epoch drains")
	TEST_ASSERT_EQUAL(stopping_generic.process_count, 1, "Generic SSprojectiles consumers must retain their processing contract")
	TEST_ASSERT_EQUAL(stopped_generic.process_count, 0, "STOP_PROCESSING must remove a generic consumer from the active epoch before it runs")
	var/datum/weakref/new_projectile_ref = WEAKREF(new_projectile)
	qdel(new_projectile)
	TEST_ASSERT_NULL(new_projectile_ref.resolve(), "Deleting a queued projectile must synchronously invalidate the scheduler's weak reference")

	SSprojectiles.stop_projectile(old_projectile)
	SSprojectiles.stop_projectile(spawner)
	qdel(old_projectile)
	qdel(spawner)
	qdel(stopped_generic)
	qdel(stopping_generic)

	SSprojectiles.processing = saved_processing
	SSprojectiles.currentrun = saved_currentrun
	SSprojectiles.projectile_queue = saved_queue
	SSprojectiles.projectile_debt_queue = saved_debt_queue
	SSprojectiles.projectile_next_queue = saved_next_queue
	SSprojectiles.projectile_new_queue = saved_new_queue
	SSprojectiles.projectile_epoch_active = saved_epoch_active
	SSprojectiles.projectiles_processed_this_epoch = saved_epoch_count
	SSprojectiles.state = saved_state
	SSprojectiles.profile_strikes = saved_profile_strikes
	SSprojectiles.profile_armed = saved_profile_armed
	SSprojectiles.profile_cooldown_until = saved_profile_cooldown_until
	SSprojectiles.current_pass_cost_ms = saved_current_pass_cost_ms
	SSprojectiles.profile_cost_by_type = saved_profile_cost_by_type
	SSprojectiles.profile_count_by_type = saved_profile_count_by_type
	SSprojectiles.profile_max_by_type = saved_profile_max_by_type
	Master.current_ticklimit = saved_ticklimit

/obj/structure/unit_test_projectile_lag_blocker
	name = "projectile lag blocker"
	density = TRUE
	anchored = TRUE
	var/was_hit = FALSE

/obj/structure/unit_test_projectile_lag_blocker/bullet_act(obj/item/projectile/projectile, def_zone, piercing_hit = FALSE)
	was_hit = TRUE
	return ..()

/// Catch-up remains a swept trace: resolving a minute of elapsed time must not
/// teleport a shot through a dense object between its old and predicted loci.
/datum/unit_test/projectile_elapsed_catchup_collision/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/blocker_turf = get_step(get_step(start, EAST), EAST)
	var/turf/target = get_step(blocker_turf, EAST)
	var/obj/structure/unit_test_projectile_lag_blocker/blocker = allocate(/obj/structure/unit_test_projectile_lag_blocker, blocker_turf)
	var/obj/item/projectile/bullet/projectile = new(start)
	projectile.preparePixelProjectile(target, start)
	projectile.fire()
	projectile.process(60)

	TEST_ASSERT(blocker.was_hit, "Elapsed-time catch-up must preserve collision with every crossed dense object")
	TEST_ASSERT(QDELETED(projectile), "A catch-up projectile must finish its impact instead of remaining suspended with debt")
