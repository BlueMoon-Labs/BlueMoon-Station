#ifdef AI_MOB_ARENA_BENCH

// ===== Live all-hostile arena benchmark =====
//
// Unlike ai_benchmark.dm's deterministic subsystem passes, this benchmark lets
// the real Master Controller run. Every hostile simple-animal type is spawned
// once in an indestructible sealed arena, assigned its own faction, and seeded
// with another hostile as an enemy. Initialization, live combat, and teardown
// plus forced GC are profiled separately.
//
// This is deliberately opt-in. Run it through tools/mob_bench/run_headless.ps1;
// regular dm-test must not spend 30 seconds simulating a benchmark battle.

#define AI_MOB_ARENA_SCHEMA_VERSION 3
#define AI_MOB_ARENA_SIZE 48
#define AI_MOB_ARENA_SPAWN_SPACING 2
#if defined(AI_MOB_ARENA_ROUND16_BENCH) || defined(AI_MOB_ARENA_ROUND20_BENCH)
#define AI_MOB_ARENA_DURATION (60 SECONDS)
#else
#define AI_MOB_ARENA_DURATION (30 SECONDS)
#endif
#define AI_MOB_ARENA_SAMPLE_INTERVAL (1 SECONDS)
#define AI_MOB_ARENA_SEED 7331
#define AI_MOB_ARENA_GC_CYCLES 12
#ifdef AI_MOB_ARENA_ROUND16_BENCH
#define AI_MOB_ARENA_ROUND16 TRUE
#else
#define AI_MOB_ARENA_ROUND16 FALSE
#endif
#ifdef AI_MOB_ARENA_ROUND20_BENCH
#define AI_MOB_ARENA_ROUND20 TRUE
#else
#define AI_MOB_ARENA_ROUND20 FALSE
#endif
#ifdef AI_MOB_ARENA_HARDDEL_BENCH
#define AI_MOB_ARENA_GC_SETTLE (130 SECONDS)
#define AI_MOB_ARENA_FORCE_HARDDELS TRUE
#else
#define AI_MOB_ARENA_GC_SETTLE (10 SECONDS)
#define AI_MOB_ARENA_FORCE_HARDDELS FALSE
#endif
#ifdef AI_MOB_ARENA_SKIP_REFSCAN_BENCH
#define AI_MOB_ARENA_REFERENCE_SCAN FALSE
#else
#define AI_MOB_ARENA_REFERENCE_SCAN TRUE
#endif

/datum/unit_test/ai_mob_arena_benchmark
	parent_type = /datum/unit_test/gc_rewrite_base
	priority = TEST_LONGER + 1

	var/datum/turf_reservation/battle_arena
	var/list/arena_mob_refs = list()
	var/list/report = list()
	var/mob/dead/observer/arena_observer
	var/datum/weather/ai_mob_arena_population/arena_weather
	#ifdef AI_MOB_ARENA_MACHINES_BENCH
	var/datum/machines_benchmark/arena_machines_benchmark
	#endif
	var/arena_z
	var/old_tick_spike_ignore_empty
	var/old_tick_spike_suppress_side_effects

/datum/unit_test/ai_mob_arena_benchmark/Run()
	rand_seed(AI_MOB_ARENA_SEED)
	battle_arena = SSmapping.RequestBlockReservation(AI_MOB_ARENA_SIZE, AI_MOB_ARENA_SIZE)
	TEST_ASSERT_NOTNULL(battle_arena, "Failed to reserve the all-hostile benchmark arena")
	arena_z = arena_turf(1, 1).z
	build_cube()

	var/list/hostile_types
	#ifdef AI_MOB_ARENA_ROUND20_BENCH
	hostile_types = list()
	for(var/index in 1 to 216)
		hostile_types += /mob/living/simple_animal/hostile/syndicate/ranged/smg/space/stormtrooper
	for(var/index in 1 to 56)
		hostile_types += /mob/living/simple_animal/hostile/megafauna/demonic_frost_miner
	#else
	#ifdef AI_MOB_ARENA_ROUND16_BENCH
	hostile_types = list()
	for(var/index in 1 to 59)
		hostile_types += /mob/living/simple_animal/hostile/syndicate/ranged/shotgun/space/stormtrooper/anthro
	for(var/index in 1 to 10)
		hostile_types += /mob/living/simple_animal/hostile/megafauna/demonic_frost_miner
	#else
	hostile_types = sortTim(typesof(/mob/living/simple_animal/hostile), GLOBAL_PROC_REF(cmp_text_asc))
	#endif
	#endif
	var/interior_axis = FLOOR((AI_MOB_ARENA_SIZE - 2) / AI_MOB_ARENA_SPAWN_SPACING, 1)
	var/interior_capacity = interior_axis * interior_axis
	TEST_ASSERT(length(hostile_types) <= interior_capacity, "Arena has [interior_capacity] cells for [length(hostile_types)] hostile types")

	report["_meta"] = list(
		"schema_version" = AI_MOB_ARENA_SCHEMA_VERSION,
		"generated_at" = time2text(world.realtime, "YYYY-MM-DD hh:mm:ss"),
		"commit" = GLOB.revdata?.commit,
		"origin_commit" = GLOB.revdata?.originmastercommit,
		"byond" = "[world.byond_version].[world.byond_build]",
		"seed" = AI_MOB_ARENA_SEED,
		"arena_size" = AI_MOB_ARENA_SIZE,
		"combat_duration_ds" = AI_MOB_ARENA_DURATION,
		"sample_interval_ds" = AI_MOB_ARENA_SAMPLE_INTERVAL,
		"harddel_mode" = AI_MOB_ARENA_FORCE_HARDDELS,
		"reference_scan" = AI_MOB_ARENA_REFERENCE_SCAN,
		"round16_stress_mode" = AI_MOB_ARENA_ROUND16,
		"round20_stress_mode" = AI_MOB_ARENA_ROUND20,
		"scope" = AI_MOB_ARENA_ROUND20 ? "216 InteQ SMG stormtroopers versus 56 demonic frost miners from round-20.17.55" : (AI_MOB_ARENA_ROUND16 ? "59 InteQ shotgun stormtroopers versus 10 demonic frost miners with population weather scan" : "/mob/living/simple_animal/hostile and every subtype"),
	)
	report["catalog"] = list(
		"attempted_count" = length(hostile_types),
		"attempted_types" = stringify_type_list(hostile_types),
	)

	prepare_isolated_gc()
	prepare_tick_spike_capture()
	register_observer_presence()
	GLOB.ai_metrics.reset()

	if(AI_MOB_ARENA_FORCE_HARDDELS)
		// BYOND 516 can retain sampled src objects after PROFILE_CLEAR. Lifecycle
		// mode must not manufacture one-ref Q3 candidates from its own profiler.
		world.Profile(PROFILE_STOP)
		world.Profile(PROFILE_CLEAR)
	else
		start_phase_profile()
	var/list/spawn_result = spawn_and_arm_hostiles(hostile_types)
	if(!AI_MOB_ARENA_FORCE_HARDDELS)
		stop_phase_profile("spawn")
	report["spawn"] = spawn_result
	if(AI_MOB_ARENA_ROUND16 || AI_MOB_ARENA_ROUND20)
		start_population_weather()
	#ifdef AI_MOB_ARENA_MACHINES_BENCH
	start_machines_benchmark()
	#endif

	if(!AI_MOB_ARENA_FORCE_HARDDELS)
		start_phase_profile()
	var/list/combat_samples = run_live_combat()
	if(!AI_MOB_ARENA_FORCE_HARDDELS)
		stop_phase_profile("combat")
	report["combat"] = list(
		"samples" = combat_samples,
		"ai_metrics" = GLOB.ai_metrics.snapshot(),
	)
	#ifdef AI_MOB_ARENA_MACHINES_BENCH
	stop_machines_benchmark()
	#endif

	remove_observer_presence()
	stop_population_weather()
	qdel_arena_entities()
	var/list/gc_result = drain_and_summarize_gc()
	report["gc"] = gc_result
	report["tick_spikes"] = snapshot_tick_spikes()
	restore_tick_spike_capture()

	var/report_path = "data/mob_arena_benchmark_v2.json"
	fdel(report_path)
	text2file(json_encode(report), report_path)

	qdel(battle_arena)
	battle_arena = null

#ifdef AI_MOB_ARENA_MACHINES_BENCH
///Opt-in per-type SSmachines accounting. It is deliberately excluded from
///ordinary arena A/B runs because timing every machine process() adds overhead.
/datum/unit_test/ai_mob_arena_benchmark/proc/start_machines_benchmark()
	if(GLOB.machines_benchmark_run)
		return
	arena_machines_benchmark = new(AI_MOB_ARENA_DURATION + 1 MINUTES)
	GLOB.machines_benchmark_run = arena_machines_benchmark
	arena_machines_benchmark.start()
	report["machines"] = list("profile_path" = arena_machines_benchmark.file_path)

/datum/unit_test/ai_mob_arena_benchmark/proc/stop_machines_benchmark()
	if(!arena_machines_benchmark)
		return
	arena_machines_benchmark.finish("AI mob arena combat complete")
	qdel(arena_machines_benchmark)
	arena_machines_benchmark = null
#endif

/// Build a 48x48 indestructible, breathable square. In SS13's 2D world this is
/// the practical equivalent of the requested sealed cube.
/datum/unit_test/ai_mob_arena_benchmark/proc/build_cube()
	for(var/x in 1 to AI_MOB_ARENA_SIZE)
		for(var/y in 1 to AI_MOB_ARENA_SIZE)
			var/turf/tile = arena_turf(x, y)
			if(x == 1 || y == 1 || x == AI_MOB_ARENA_SIZE || y == AI_MOB_ARENA_SIZE)
				tile.ChangeTurf(/turf/closed/indestructible/wall)
			else
				tile.ChangeTurf(/turf/open/indestructible/boss/air)

/datum/unit_test/ai_mob_arena_benchmark/proc/arena_turf(x, y)
	return locate(battle_arena.bottom_left_coords[1] + x - 1, battle_arena.bottom_left_coords[2] + y - 1, battle_arena.bottom_left_coords[3])

/datum/unit_test/ai_mob_arena_benchmark/proc/arena_spawn_turf(index)
	var/interior_width = FLOOR((AI_MOB_ARENA_SIZE - 2) / AI_MOB_ARENA_SPAWN_SPACING, 1)
	var/x = 2 + (((index - 1) % interior_width) * AI_MOB_ARENA_SPAWN_SPACING)
	var/y = 2 + (FLOOR((index - 1) / interior_width, 1) * AI_MOB_ARENA_SPAWN_SPACING)
	return arena_turf(x, y)

/datum/unit_test/ai_mob_arena_benchmark/proc/stringify_type_list(list/type_paths)
	var/list/result = list()
	for(var/type_path in type_paths)
		result += "[type_path]"
	return result

/// Spawn one instance of every hostile type. A second pass also picks up mobs
/// created by Initialize() (armsy segments, escorts, and similar children), so
/// they join the battle and do not silently remain allied background load.
/datum/unit_test/ai_mob_arena_benchmark/proc/spawn_and_arm_hostiles(list/hostile_types)
	var/list/initialization_qdels = list()
	var/list/inactive_ai_types = list()
	var/created_count = 0
	var/index = 0
	for(var/mob_type in hostile_types)
		index++
		var/mob/living/simple_animal/hostile/subject = new mob_type(arena_spawn_turf(index))
		if(QDELETED(subject))
			initialization_qdels += "[mob_type]"
			continue
		created_count++

	var/list/combatants = list()
	for(var/turf/tile as anything in block(arena_turf(2, 2), arena_turf(AI_MOB_ARENA_SIZE - 1, AI_MOB_ARENA_SIZE - 1)))
		for(var/mob/living/simple_animal/hostile/subject in tile)
			if(QDELETED(subject))
				continue
			// AI_OFF without a controller is a player/summoner-driven or inert
			// subtype, not an autonomous AI mob. Forcing it ON creates impossible
			// interactions (notably standalone guardians) and measures harness bugs.
			if(!subject.ai_controller && subject.AIStatus == AI_OFF)
				inactive_ai_types |= "[subject.type]"
				qdel(subject)
				continue
			combatants += subject

	var/controller_count = 0
	var/legacy_count = 0
	index = 0
	for(var/mob/living/simple_animal/hostile/subject as anything in combatants)
		index++
		#if defined(AI_MOB_ARENA_ROUND16_BENCH) || defined(AI_MOB_ARENA_ROUND20_BENCH)
		if(istype(subject, /mob/living/simple_animal/hostile/megafauna/demonic_frost_miner))
			subject.faction = list("ai_arena_frost_miner")
		else
			subject.faction = list("ai_arena_inteq")
		#else
		subject.faction = list("ai_arena_[index]")
		#endif
		arena_mob_refs += WEAKREF(subject)
		if(subject.ai_controller)
			controller_count++
			subject.ai_controller.set_ai_status(AI_STATUS_ON)
		else
			legacy_count++
			subject.toggle_ai(AI_ON)

	var/seeded_targets = 0
	var/unseeded_targets = 0
	var/combatant_count = length(combatants)
	for(var/subject_index in 1 to combatant_count)
		var/mob/living/simple_animal/hostile/subject = combatants[subject_index]
		var/mob/living/simple_animal/hostile/chosen_target
		// Start opposite sides of the deterministic list against each other. This
		// produces long crossing paths and crowding instead of adjacent duels only.
		var/target_offset = max(FLOOR(combatant_count / 2, 1), 1)
		for(var/attempt in 0 to combatant_count - 2)
			var/target_index = ((subject_index + target_offset + attempt - 1) % combatant_count) + 1
			var/mob/living/simple_animal/hostile/candidate = combatants[target_index]
			if(candidate != subject && subject.CanAttack(candidate))
				chosen_target = candidate
				break
		if(chosen_target)
			subject.RetaliateAgainst(chosen_target)
			seeded_targets++
		else
			unseeded_targets++

	// Release all strong benchmark-owned mob references before yielding. Natural
	// deaths must be able to reach SSgarbage during the fight.
	combatants.Cut()
	return list(
		"created_directly" = created_count,
		"initialization_qdel_count" = length(initialization_qdels),
		"initialization_qdel_types" = initialization_qdels,
		"inactive_ai_count" = length(inactive_ai_types),
		"inactive_ai_types" = inactive_ai_types,
		"combatants_after_initialize" = combatant_count,
		"controller_count" = controller_count,
		"legacy_count" = legacy_count,
		"seeded_targets" = seeded_targets,
		"unseeded_targets" = unseeded_targets,
	)

/// Exercise the same population-wide Weather path that was spiking during the
/// round without adding damage, overlays, messages, or random timers.
/datum/unit_test/ai_mob_arena_benchmark/proc/start_population_weather()
	arena_weather = new(list(arena_z))
	arena_weather.stage = MAIN_STAGE
	arena_weather.impacted_areas = list(get_area(arena_turf(2, 2)))
	START_PROCESSING(SSweather, arena_weather)

/datum/unit_test/ai_mob_arena_benchmark/proc/stop_population_weather()
	if(!arena_weather)
		return
	STOP_PROCESSING(SSweather, arena_weather)
	qdel(arena_weather)
	arena_weather = null

/datum/unit_test/ai_mob_arena_benchmark/proc/run_live_combat()
	var/list/samples = list()
	var/elapsed = 0
	while(elapsed <= AI_MOB_ARENA_DURATION)
		samples += list(sample_combat_state(elapsed))
		if(elapsed == AI_MOB_ARENA_DURATION)
			break
		sleep(AI_MOB_ARENA_SAMPLE_INTERVAL)
		elapsed += AI_MOB_ARENA_SAMPLE_INTERVAL
	return samples

/datum/unit_test/ai_mob_arena_benchmark/proc/sample_combat_state(elapsed)
	var/resolved = 0
	var/alive = 0
	var/dead = 0
	var/with_target = 0
	var/controller_on = 0
	var/legacy_on = 0
	for(var/datum/weakref/mob_ref as anything in arena_mob_refs)
		var/mob/living/simple_animal/hostile/subject = mob_ref.resolve()
		if(!subject || QDELETED(subject))
			continue
		resolved++
		if(subject.stat == DEAD)
			dead++
		else
			alive++
		if(subject.ai_controller)
			if(subject.ai_controller.ai_status == AI_STATUS_ON)
				controller_on++
			if(subject.ai_controller.blackboard[BB_AI_CURRENT_TARGET])
				with_target++
		else
			if(subject.AIStatus == AI_ON)
				legacy_on++
			if(subject.target)
				with_target++
	return list(
		"elapsed_ds" = elapsed,
		"resolved_initial_mobs" = resolved,
		"alive" = alive,
		"dead" = dead,
		"with_target" = with_target,
		"controller_on" = controller_on,
		"legacy_on" = legacy_on,
		"world_cpu" = world.cpu,
		"world_tick_usage" = world.tick_usage,
		"mc_iteration" = Master.iteration,
		"projectile_active" = length(SSprojectiles.projectile_queue) + length(SSprojectiles.projectile_debt_queue) + length(SSprojectiles.projectile_next_queue) + length(SSprojectiles.projectile_new_queue),
		"projectile_queue" = length(SSprojectiles.projectile_queue),
		"projectile_debt" = length(SSprojectiles.projectile_debt_queue),
		"projectile_next" = length(SSprojectiles.projectile_next_queue),
		"projectile_new" = length(SSprojectiles.projectile_new_queue),
		"projectile_epoch_processed" = SSprojectiles.projectiles_processed_this_epoch,
		"projectile_pass_cost_ms" = SSprojectiles.current_pass_cost_ms,
		"projectile_paused_ticks" = SSprojectiles.paused_ticks,
	)

/// A dead observer supplies the normal CLIENTS presence channel that keeps AI
/// awake, but is not a living candidate and cannot steal aggro from combatants.
/datum/unit_test/ai_mob_arena_benchmark/proc/register_observer_presence()
	if(!islist(SSmobs.clients_by_zlevel) || arena_z > length(SSmobs.clients_by_zlevel))
		SSmobs.MaxZChanged()
	arena_observer = new(arena_turf(FLOOR(AI_MOB_ARENA_SIZE / 2, 1), FLOOR(AI_MOB_ARENA_SIZE / 2, 1)))
	SSmobs.clients_by_zlevel[arena_z] |= arena_observer
	arena_observer.enable_client_mobs_in_contents()

/datum/unit_test/ai_mob_arena_benchmark/proc/remove_observer_presence()
	if(!arena_observer)
		return
	SSmobs.clients_by_zlevel[arena_z] -= arena_observer
	arena_observer.clear_important_client_contents()
	qdel(arena_observer)
	arena_observer = null

/datum/unit_test/ai_mob_arena_benchmark/proc/prepare_isolated_gc()
	reset_gc_queues()
	SSgarbage.items = list()
	GLOB.gc_failure_cache.failures = list()
	GLOB.gc_failure_cache.failure_sources = list()
	GLOB.gc_failure_cache.total_failures = 0
	GLOB.gc_failure_cache.failures_by_ref = list()
	GLOB.gc_failure_cache.cascade_children_total = 0
	// Promote leaks through softcheck and warnfail, but keep them live in Q3.
	// Bulk del() of every leak can terminate the diagnostic world before it can
	// write a report. QDEL_HINT_HARDDEL_NOW still executes and is measured.
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 10000 HOURS
	#ifdef UNIT_TESTS
	SSgarbage.test_ref_scan_skip_async = TRUE
	#endif

/datum/unit_test/ai_mob_arena_benchmark/proc/prepare_tick_spike_capture()
	old_tick_spike_ignore_empty = SStick_spikes.ignore_empty_server
	old_tick_spike_suppress_side_effects = SStick_spikes.suppress_side_effects
	SStick_spikes.ignore_empty_server = TRUE
	SStick_spikes.suppress_side_effects = TRUE
	SStick_spikes.reset_state()
	SStick_spikes.next_spike_tag = "all-hostile arena"

/datum/unit_test/ai_mob_arena_benchmark/proc/restore_tick_spike_capture()
	SStick_spikes.reset_state()
	SStick_spikes.ignore_empty_server = old_tick_spike_ignore_empty
	SStick_spikes.suppress_side_effects = old_tick_spike_suppress_side_effects

/datum/unit_test/ai_mob_arena_benchmark/proc/snapshot_tick_spikes()
	return list(
		"samples" = SStick_spikes.samples_collected,
		"spike_count" = SStick_spikes.session_spike_count,
		"worst_drift_ms" = SStick_spikes.worst_drift_ms,
		"total_spike_drift_ms" = SStick_spikes.total_spike_drift_ms,
		"histogram" = SStick_spikes.drift_histogram.Copy(),
		"events" = SStick_spikes.spike_events.Copy(),
	)

/datum/unit_test/ai_mob_arena_benchmark/proc/start_phase_profile()
	world.Profile(PROFILE_CLEAR)
	world.Profile(PROFILE_START)

/datum/unit_test/ai_mob_arena_benchmark/proc/stop_phase_profile(phase_name)
	var/profile_data = world.Profile(PROFILE_REFRESH, format = "json")
	world.Profile(PROFILE_STOP)
	// PROFILE_STOP stops sampling but keeps native proc/src rows alive. Release
	// them before qdel/GC so the profiler cannot become the only external owner.
	world.Profile(PROFILE_CLEAR)
	if(!length(profile_data))
		return
	var/profile_path = "data/mob_arena_profile_[phase_name].json"
	fdel(profile_path)
	text2file(profile_data, profile_path)

/// qdel all initially tracked mobs even if they teleported, then all movable
/// arena contents (projectiles, loot, summons, decals). This helper owns the
/// temporary strong list frame; returning before GC releases VM operand pins.
/datum/unit_test/ai_mob_arena_benchmark/proc/qdel_arena_entities()
	for(var/datum/weakref/mob_ref as anything in arena_mob_refs)
		var/mob/living/simple_animal/hostile/subject = mob_ref.resolve()
		if(subject && !QDELETED(subject))
			qdel(subject)
	arena_mob_refs.Cut()
	for(var/turf/tile as anything in block(arena_turf(2, 2), arena_turf(AI_MOB_ARENA_SIZE - 1, AI_MOB_ARENA_SIZE - 1)))
		for(var/atom/movable/content in tile)
			if(!QDELETED(content))
				qdel(content)

/datum/unit_test/ai_mob_arena_benchmark/proc/drain_and_summarize_gc()
	// Let attack coroutines, projectile callbacks and short visual timers release
	// their locals before accelerating GC. Without this window the benchmark
	// labels normal in-flight work as a harddel candidate immediately after qdel.
	sleep(AI_MOB_ARENA_GC_SETTLE)
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 0
	// Cleanup then gets a synchronous softcheck/warnfail budget, while Q3
	// remains parked. We enumerate live Q3 entries as candidates below.
	Master.current_ticklimit = INFINITY

	SSgarbage.state = SS_IDLE
	sleep(20)
	var/cycles = 0
	while(cycles < AI_MOB_ARENA_GC_CYCLES)
		cycles++
		SSgarbage.state = SS_RUNNING
		SSgarbage.fire()
		SSgarbage.state = SS_IDLE
		if(!SSgarbage.GetQueueDepth(GC_QUEUE_SOFTCHECK) && !SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL) && !SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE))
			break

	var/list/hard_delete_candidates_by_type = list()
	var/hard_delete_candidates = 0
	var/hard_delete_head = SSgarbage.queue_heads[GC_QUEUE_HARDDELETE]
	var/hard_delete_length = length(SSgarbage.queue_refs[GC_QUEUE_HARDDELETE])
	if(hard_delete_head <= hard_delete_length)
		for(var/queue_index in hard_delete_head to hard_delete_length)
			var/datum/pending = SSgarbage.GetQueuedDatum(GC_QUEUE_HARDDELETE, queue_index)
			if(!pending)
				continue
			var/type_string = "[pending.type]"
			hard_delete_candidates++
			hard_delete_candidates_by_type[type_string] = (hard_delete_candidates_by_type[type_string] || 0) + 1

	var/manual_reference_scans = 0
	if(AI_MOB_ARENA_FORCE_HARDDELS && AI_MOB_ARENA_REFERENCE_SCAN && hard_delete_candidates)
		manual_reference_scans = scan_representative_harddel()

	// Profiling before this point pins qdeleted proc src values in BYOND's native
	// profiler and manufactures one-ref harddel candidates. Arm it only after Q3
	// survivors have been identified, so profiling cannot change which objects
	// failed soft deletion.
	var/forced_hard_delete_cycles = 0
	if(AI_MOB_ARENA_FORCE_HARDDELS)
		start_phase_profile()
		if(hard_delete_candidates)
			SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
			while(forced_hard_delete_cycles < 512 && SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE))
				forced_hard_delete_cycles++
				SSgarbage.state = SS_RUNNING
				SSgarbage.fire()
				SSgarbage.state = SS_IDLE
		stop_phase_profile("cleanup_gc")

	var/list/type_stats = list()
	var/total_qdels = 0
	var/total_softfailures = 0
	var/total_warnfails = 0
	var/total_hard_deletes = 0
	var/total_hard_delete_ms = 0
	for(var/type_path in SSgarbage.items)
		var/datum/qdel_item/item = SSgarbage.items[type_path]
		var/type_string = "[type_path]"
		var/candidates_for_type = hard_delete_candidates_by_type[type_string] || 0
		if(!item.qdels && !item.failures && !item.warnfail_count && !item.hard_deletes && !candidates_for_type)
			continue
		total_qdels += item.qdels
		total_softfailures += item.failures
		total_warnfails += item.warnfail_count
		total_hard_deletes += item.hard_deletes
		total_hard_delete_ms += item.hard_delete_time
		type_stats[type_string] = list(
			"qdels" = item.qdels,
			"destroy_ms" = item.destroy_time,
			"softfailures" = item.failures,
			"warnfails" = item.warnfail_count,
			"hard_deletes" = item.hard_deletes,
			"hard_delete_ms" = item.hard_delete_time,
			"hard_delete_max_ms" = item.hard_delete_max,
			"hard_delete_candidates" = candidates_for_type,
			"slept_destroy" = item.slept_destroy,
			"no_hint" = item.no_hint,
		)

	// Per-object diagnostics are what turns a type count into an ownership fix.
	// Warnfail collection is deliberately bounded to self refs, timers, signals
	// and ownership chains; an optional representative scan fills broader refs.
	var/list/failure_details = list()
	for(var/datum/gc_failure_viewer/gc_failure_entry/entry as anything in GLOB.gc_failure_cache.failures)
		failure_details += list(list(
			"type" = "[entry.type_path]",
			"name" = entry.obj_name,
			"ref" = entry.ref_id,
			"external_refs" = entry.external_refs_at_failure,
			"qdel_hint" = entry.qdel_hint,
			"age_ds" = world.time - entry.origin_time,
			"references" = copy_failure_references(entry),
			"world_scan_done" = entry.world_scan_done,
			"world_scan_objects" = entry.world_scan_atom_count,
			"active_timers" = entry.active_timers_count,
			"timers" = entry.timers_info,
			"components" = entry.components_info,
			"signals" = entry.signals_info,
			"contents" = entry.contents_info,
			"loc_chain" = entry.loc_chain_info,
			"cascade_parent_type" = entry.cascade_parent_type,
			"cascade_children" = entry.cascade_children,
		))

	return list(
		"cycles" = cycles,
		"forced_hard_delete_cycles" = forced_hard_delete_cycles,
		"manual_reference_scans" = manual_reference_scans,
		"settle_ds" = AI_MOB_ARENA_GC_SETTLE,
		"totals" = list(
			"qdels" = total_qdels,
			"softfailures" = total_softfailures,
			"warnfails" = total_warnfails,
			"hard_deletes" = total_hard_deletes,
			"hard_delete_candidates" = hard_delete_candidates,
			"pending_hard_deletes" = SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE),
			"hard_delete_ms" = total_hard_delete_ms,
			"highest_hard_delete_ms" = SSgarbage.highest_del_ms,
			"highest_hard_delete_type" = SSgarbage.highest_del_type_string,
		),
		"remaining_queues" = list(
			"softcheck" = SSgarbage.GetQueueDepth(GC_QUEUE_SOFTCHECK),
			"warnfail" = SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL),
			"hard_delete" = SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE),
		),
		"types" = type_stats,
		"failures" = failure_details,
	)

/// One full world/datum scan is reserved for harddel mode. The fast bounded
/// scanner cannot see suspended proc frames, while even two full scans can add
/// minutes of unrelated reftracker CPU to a combat benchmark.
/datum/unit_test/ai_mob_arena_benchmark/proc/scan_representative_harddel()
	var/datum/gc_failure_viewer/gc_failure_entry/hostile_representative
	var/datum/gc_failure_viewer/gc_failure_entry/projectile_representative
	var/datum/gc_failure_viewer/gc_failure_entry/hotspot_representative
	for(var/datum/gc_failure_viewer/gc_failure_entry/entry as anything in GLOB.gc_failure_cache.failures)
		if(!hotspot_representative && entry.type_path == /obj/effect/hotspot && entry.external_refs_at_failure)
			hotspot_representative = entry
		if(ispath(entry.type_path, /obj/item/projectile) && entry.external_refs_at_failure \
			&& (!projectile_representative || entry.external_refs_at_failure > projectile_representative.external_refs_at_failure))
			projectile_representative = entry
		if(!ispath(entry.type_path, /mob/living/simple_animal/hostile) || !entry.external_refs_at_failure)
			continue
		var/entry_is_inteq = ispath(entry.type_path, /mob/living/simple_animal/hostile/syndicate/ranged/shotgun/space)
		var/current_is_inteq = ispath(hostile_representative?.type_path, /mob/living/simple_animal/hostile/syndicate/ranged/shotgun/space)
		if(!hostile_representative \
			|| (entry_is_inteq && (!current_is_inteq || entry.external_refs_at_failure > hostile_representative.external_refs_at_failure)) \
			|| (!current_is_inteq && entry.type_path == /mob/living/simple_animal/hostile/unit_test_ai_benchmark_ranged))
			hostile_representative = entry

	var/datum/gc_failure_viewer/gc_failure_entry/representative = hostile_representative
	if(!representative)
		representative = projectile_representative
	if(!representative)
		representative = hotspot_representative
	if(!representative)
		return 0
	var/datum/target = representative.resolve_target()
	if(!target)
		return 0
	representative.trigger_world_scan(null, target, max(representative.external_refs_at_failure, 1))
	return 1

/datum/unit_test/ai_mob_arena_benchmark/proc/copy_failure_references(datum/gc_failure_viewer/gc_failure_entry/entry)
	if(islist(entry.found_references))
		return entry.found_references.Copy()
	if(entry.found_references)
		return list("[entry.found_references]")
	return list()

/datum/unit_test/ai_mob_arena_benchmark/Destroy()
	remove_observer_presence()
	stop_population_weather()
	if(battle_arena)
		qdel(battle_arena)
		battle_arena = null
	return ..()

#undef AI_MOB_ARENA_GC_CYCLES
#undef AI_MOB_ARENA_REFERENCE_SCAN
#undef AI_MOB_ARENA_ROUND16
#undef AI_MOB_ARENA_ROUND20
#undef AI_MOB_ARENA_GC_SETTLE
#undef AI_MOB_ARENA_FORCE_HARDDELS
#undef AI_MOB_ARENA_SEED
#undef AI_MOB_ARENA_SAMPLE_INTERVAL
#undef AI_MOB_ARENA_DURATION
#undef AI_MOB_ARENA_SPAWN_SPACING
#undef AI_MOB_ARENA_SIZE
#undef AI_MOB_ARENA_SCHEMA_VERSION

/datum/weather/ai_mob_arena_population
	name = "AI mob arena population probe"
	probability = 0
	perpetual = TRUE

#endif
