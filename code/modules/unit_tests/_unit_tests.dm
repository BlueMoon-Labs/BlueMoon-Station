//include unit test files in this module in this ifdef
//Keep this sorted alphabetically

#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)

/// For advanced cases, fail unconditionally but don't return (so a test can return multiple results)
#define TEST_FAIL(reason) (Fail(reason || "No reason", __FILE__, __LINE__))

/// Asserts that a condition is true
/// If the condition is not true, fails the test
#define TEST_ASSERT(assertion, reason) if (!(assertion)) { return Fail("Assertion failed: [reason || "No reason"]", __FILE__, __LINE__) }

/// Asserts that a parameter is not null
#define TEST_ASSERT_NOTNULL(a, reason) if (isnull(a)) { return Fail("Expected non-null value: [reason || "No reason"]", __FILE__, __LINE__) }

/// Asserts that a parameter is null
#define TEST_ASSERT_NULL(a, reason) if (!isnull(a)) { return Fail("Expected null value but received [a]: [reason || "No reason"]", __FILE__, __LINE__) }

/// Asserts that the two parameters passed are equal, fails otherwise
/// Optionally allows an additional message in the case of a failure
#define TEST_ASSERT_EQUAL(a, b, message) do { \
	var/lhs = ##a; \
	var/rhs = ##b; \
	if (lhs != rhs) { \
		return Fail("Expected [isnull(lhs) ? "null" : lhs] to be equal to [isnull(rhs) ? "null" : rhs].[message ? " [message]" : ""]", __FILE__, __LINE__); \
	} \
} while (FALSE)

/// Asserts that the two parameters passed are not equal, fails otherwise
/// Optionally allows an additional message in the case of a failure
#define TEST_ASSERT_NOTEQUAL(a, b, message) do { \
	var/lhs = ##a; \
	var/rhs = ##b; \
	if (lhs == rhs) { \
		return Fail("Expected [isnull(lhs) ? "null" : lhs] to not be equal to [isnull(rhs) ? "null" : rhs].[message ? " [message]" : ""]", __FILE__, __LINE__); \
	} \
} while (FALSE)

/// *Only* run the test provided within the parentheses
/// This is useful for debugging when you want to reduce noise, but should never be pushed
/// Intended to be used in the manner of `TEST_FOCUS(/datum/unit_test/math)`
#define TEST_FOCUS(test_path) ##test_path { focus = TRUE; }

/// Constants indicating unit test completion status
#define UNIT_TEST_PASSED 0
#define UNIT_TEST_FAILED 1
#define UNIT_TEST_SKIPPED 2

#define TEST_PRE 0
#define TEST_DEFAULT 1
/// After most test steps, used for tests that run long so shorter issues can be noticed faster
#define TEST_LONGER 10
/// This must be the last test to run due to the inherent nature of the test iterating every single tangible atom in the game and qdeleting all of them (while taking long sleeps to make sure the garbage collector fires properly) taking a large amount of time.
#define TEST_CREATE_AND_DESTROY INFINITY

/// Change color to red on ANSI terminal output, if enabled with -DANSICOLORS.
#ifdef ANSICOLORS
#define TEST_OUTPUT_RED(text) "\x1B\x5B1;31m[text]\x1B\x5B0m"
#else
#define TEST_OUTPUT_RED(text) (text)
#endif
/// Change color to green on ANSI terminal output, if enabled with -DANSICOLORS.
#ifdef ANSICOLORS
#define TEST_OUTPUT_GREEN(text) "\x1B\x5B1;32m[text]\x1B\x5B0m"
#else
#define TEST_OUTPUT_GREEN(text) (text)
#endif

/// A trait source when adding traits through unit tests
#define TRAIT_SOURCE_UNIT_TESTS "unit_tests"

#include "advanced_locator.dm"
#include "anchored_mobs.dm"
#include "airalarm_thresholds.dm"
#include "atmos_engineering_fixes.dm"
#include "atmos_exposure_consumers.dm"
#include "atmos_gas_propagation.dm"
#include "atmos_high_pressure_pile.dm"
#include "atmos_native.dm"
#include "atmos_performance.dm"
#include "atmos_superconduction.dm"
#include "atmos_planetary_churn.dm"
#include "atmos_saturation_valve.dm"
#include "atmos_sleeping_edges.dm"
#include "atmos_speed_lever.dm"
#include "atmos_he_pipe_sleep.dm"
#include "atmos_idle_churn.dm"
#include "canister_valve.dm"
#include "atmos_zone_walk.dm"
#include "atmos_sprite_states.dm"
#include "atmos_pipe_paint.dm"
#include "atmos_pipenet_rebuild.dm"
#include "atmos_gas_balance.dm"
#include "atmos_handbook.dm"
#include "firelock_alarm.dm"
#include "rpd_fixes.dm"
#include "window_airbag.dm"
#include "bespoke_id.dm"
#include "binary_insert.dm"
// #include "bloody_footprints.dm"
// #include "breath.dm"
// #include "card_mismatch.dm"
#include "chain_pull_through_space.dm"
// #include "combat.dm"
#include "component_tests.dm"
// #include "connect_loc.dm"
// #include "confusion.dm"
// #include "crayons.dm"
#include "create_and_destroy.dm"
#include "custom_emote_panel.dm"
// #include "designs.dm"
#include "director.dm"
#include "dynamic_ruleset_sanity.dm"
// #include "egg_glands.dm"
// #include "dynamic_ruleset_sanity.dm"
// #include "emoting.dm"
#include "event_ports.dm"
#include "families.dm"
// #include "food_edibility_check.dm"
#include "gas_mixture_parser.dm"
#include "gc_rewrite.dm"
#include "healium_nerf.dm"
#include "harddel_round_9813.dm"
#include "harddel_round_9824.dm"
#include "harddel_round_9827.dm"
#include "harddel_round_9832.dm"
#include "harddel_round_9860.dm"
#include "holofan_charge.dm"
#include "immovable_rod_cleanup.dm"
// #include "greyscale_config.dm"
// #include "heretic_knowledge.dm"
// #include "holidays.dm"
// #include "hydroponics_harvest.dm"
#include "jetpack_thrust.dm"
// #include "keybinding_init.dm"
#include "keybindings_stuck_keys.dm"
// #include "language_transfer.dm"
#include "lighting.dm"
#include "lighting_deferred_init.dm"
#include "light_range_cap.dm"
#include "airalarm_danger_read.dm"
#include "area_power_signal.dm"
#include "area_tracking.dm"
#include "cleanable_decals_tracking.dm"
#include "clockwork_power.dm"
#include "login_path_async_audit.dm"
#include "lighting_performance.dm"
#include "machine_disassembly.dm"
#include "machinery_idle_sleep.dm"
#include "machinery_optimization.dm"
#include "mail_gc.dm"
#include "mapload_space_verification.dm"	// BLUEMOON EDIT: Invalid Space Turfs
#include "mapping.dm"						// BLUEMOON EDIT: Invalid Space Turfs
#include "medical_wounds.dm"
#include "merge_type.dm"
// #include "metabolizing.dm"
#include "mob_elements.dm"
#include "mod_suit_fixes.dm"
#include "modular_map_loader.dm" //SPLURT EDIT
#include "nightshift.dm"
// #include "ntnetwork_tests.dm"
// #include "outfit_sanity.dm"
// #include "pills.dm"
// #include "plantgrowth_tests.dm"
#include "projectiles.dm"
#include "weather.dm"
// #include "rcd.dm"
#include "reagent_id_typos.dm"
// #include "reagent_mod_expose.dm"
// #include "reagent_mod_procs.dm"
#include "reagent_recipe_collisions.dm"
#include "recursive_hotpaths.dm"
#include "resist.dm"
#include "runtime_null_guards.dm"
// #include "say.dm"
#include "say_input_encoding.dm"
// #include "security_officer_distribution.dm"
// #include "serving_tray.dm"
#include "shuttle_move_atmos_exposure.dm"
#include "signal_teardown.dm"
// #include "siunit.dm"
#include "sort_tim.dm"
#include "space_cleaner_gentle.dm"
#include "spatial_grid.dm"
#include "spawn_humans.dm"
#include "spawn_mobs.dm"
#include "spritesheet_asset_snapshot.dm"
#include "startup_bootstrap.dm"
// #include "species_whitelists.dm"
// #include "stomach.dm"
// #include "strippable.dm"
#include "strippable_hands_gate.dm"
#include "subsystem_init.dm"
#include "surgeries.dm"
#include "tank_idle_sleep.dm"
#include "teleporters.dm"
#include "tgui_create_message.dm"
#include "tgui_dev_asset_url.dm"
#include "timer_sanity.dm"
#include "unit_test.dm"
#include "vending_stock_keys.dm"
#include "verb_manager.dm"
// #include "wizard.dm"

/// CIT TESTS
#include "character_saving.dm"

/// SANDSTORM TESTS
#include "interactions.dm" //No regrets

#ifdef REFERENCE_TRACKING_DEBUG //Don't try and parse this file if ref tracking isn't turned on. IE: don't parse ref tracking please mr linter
#include "find_reference_sanity.dm"
#endif

/// BLUEMOON TESTS
#include "admin_log_viewer.dm"
#include "atom_hud_membership.dm"
#include "atom_hud_perf.dm"
#include "atmos_excited_group_lifecycle.dm"
#include "atmos_pump_solver.dm"
#include "atmos_vacuum_exception.dm"

#include "auto_cryo.dm"
#include "bad_defines_defined.dm"
#include "bugfix_coverage.dm"
#include "bugreports_2026_07.dm"
#include "camera_photo_probe.dm"
#include "can_inject_clothing.dm"
#include "director_beat_cost.dm"
#include "disposal_holder.dm"
#include "fov_hearers.dm"
#include "gc_refcount.dm"
#include "ghost_role_limbs.dm"
#include "gravity_deferred_update.dm"
#include "manifest_photo_deferred.dm"
#include "newscaster_alert_gate.dm"
#include "harddel_cleanup.dm"
#include "data_hud_offset_cache.dm"
#include "healthdoll_memo.dm"
#include "keybindings_idle_move_delay.dm"
#include "mob_population_perf.dm"
#include "mob_update_cascade.dm"
#include "movement_glide_math.dm"
#include "movement_probe_math.dm"
#include "movement_weight_slowdown.dm"
#include "turf_enter_checks.dm"
#include "turf_exit_checks.dm"
#include "objective_completion.dm"
#include "prod_round_9832.dm"
#include "round_9752_regressions.dm"
#include "warnfail_context.dm"
#include "runtime_guards.dm"
#include "hallucination_stationmessage.dm"
#include "hilbert_hotel.dm"
#include "hilbert_hotel_lighting.dm"
#include "holodeck_copy_isolation.dm"
#include "memory_leak_limits.dm"
#include "human_mob_gc.dm"
#include "observer_reenter_race.dm"
#include "jukebox_import.dm"
#include "stationroom_landmark.dm"
#include "latex_lockable.dm"
#include "parallax_position.dm"
#include "parallax_profiles.dm"
#include "perf_cross_ports.dm"
#include "perf_optimizations.dm"
#include "perf_pass_non_atmos.dm"
#include "ping_measurement.dm"
#include "phobia_preference.dm"
#include "psychosis_pools.dm"
#include "preload_size_budgets.dm"
#include "preferences_save_deferral.dm"
#include "image_leak_audit.dm"
#include "radiation_contamination.dm"
#include "rtt_window.dm"
#include "screen_gc.dm"
#include "shapeshift_gc.dm"
#include "simple_animal_buckets.dm"
#include "space_drift.dm"
#include "astro_sensor.dm"
#include "space_flight_modes.dm"
#include "space_weather_effects.dm"
#include "space_weather_graveyard.dm"
#include "space_weather_phases.dm"
#include "spirit_regressions.dm"
#include "statpanel_listedturf.dm"
#include "ssmobs_optimization.dm"
#include "hostile_ai_baseline.dm"
#include "ai_behavior_scenarios.dm"
#include "ai_benchmark.dm"
#include "ai_mob_arena.dm"
#include "ai_controller_scheduler.dm"
#include "ai_adapter.dm"
#include "ai_body_block.dm"
#include "ai_boss_selector.dm"
#include "ai_chokepoint_ambush.dm"
#include "ai_legacy_clusters.dm"
#include "ai_legacy_finish.dm"
#include "ai_movement_hybrid.dm"
#include "ai_pack_encircle.dm"
#include "ai_spatial_targets.dm"
#include "ai_specialists.dm"
#include "ai_tactical_approach.dm"
#include "ai_tactics.dm"
#include "ai_targeting.dm"
#include "simple_animal_environment_gate.dm"
#include "slime_ai.dm"
#include "ssobj_idle_processing.dm"
#include "proximity_monitor.dm"
#include "tattoo_system.dm"
#include "techweb_copy.dm"
#include "tick_spike_recorder.dm"
#include "tile_pipe_placement.dm"
#include "update_icon_short_circuit.dm"


#ifdef AI_BEHAVIOR_SCENE_BENCH
TEST_FOCUS(/datum/unit_test/ai_behavior_scenes)
#endif

#ifdef AI_HEADLESS_BENCH
TEST_FOCUS(/datum/unit_test/ai_benchmark_baseline)
#endif

#ifdef AI_MOB_ARENA_BENCH
TEST_FOCUS(/datum/unit_test/ai_mob_arena_benchmark)
#endif

#ifdef AI_MOB_PERF_REGRESSION
TEST_FOCUS(/datum/unit_test/projectile_elapsed_time_catchup)
TEST_FOCUS(/datum/unit_test/projectile_pattern_overload_delay)
TEST_FOCUS(/datum/unit_test/hitby_signal_qdel_safe)
TEST_FOCUS(/datum/unit_test/projectile_scheduler_fair_admission)
TEST_FOCUS(/datum/unit_test/projectile_elapsed_catchup_collision)
TEST_FOCUS(/datum/unit_test/pellet_cloud_logs_one_projectile)
TEST_FOCUS(/datum/unit_test/projectile_destroy_releases_combat_refs)
TEST_FOCUS(/datum/unit_test/projectile_qdeleted_combat_refs_clear_while_queued)
TEST_FOCUS(/datum/unit_test/weather_population_scan_resumes)
TEST_FOCUS(/datum/unit_test/ai_adapter_qdeleted_target_clears_legacy_refs)
TEST_FOCUS(/datum/unit_test/ai_targeting_corner_pursuit_memory)
TEST_FOCUS(/datum/unit_test/ai_hostile_grudge_follows_mind_transfer)
TEST_FOCUS(/datum/unit_test/ai_hybrid_distant_open_target_starts_direct)
TEST_FOCUS(/datum/unit_test/ai_hybrid_direct_to_jps_switch)
TEST_FOCUS(/datum/unit_test/ai_hybrid_direct_retries_mob_blocker)
TEST_FOCUS(/datum/unit_test/ai_hybrid_congestion_retargets_relevant_enemy)
TEST_FOCUS(/datum/unit_test/ai_tactics_safe_firing_lane)
TEST_FOCUS(/datum/unit_test/ai_ranged_seated_corpse_blocks_lane)
TEST_FOCUS(/datum/unit_test/ai_ranged_diagonal_wall_lane)
TEST_FOCUS(/datum/unit_test/ai_nanotrasen_rechecks_friendly_fire)
TEST_FOCUS(/datum/unit_test/ai_ranged_rechecks_line_of_sight)
TEST_FOCUS(/datum/unit_test/ai_buckled_pawn_requests_unbuckle_on_cooldown)
TEST_FOCUS(/datum/unit_test/ai_body_block_clears_seated_corpse)
TEST_FOCUS(/datum/unit_test/ai_body_block_barricade_attempt_budget)
TEST_FOCUS(/datum/unit_test/ai_targets_occupied_mecha)
TEST_FOCUS(/datum/unit_test/ai_ignores_empty_mecha)
TEST_FOCUS(/datum/unit_test/ai_inteq_space_pathing_capability)
TEST_FOCUS(/datum/unit_test/ai_hybrid_controller_path_budget)
TEST_FOCUS(/datum/unit_test/ai_pirate_tactical_atmosphere_gate)
TEST_FOCUS(/datum/unit_test/ai_unreachable_route_releases_target)
TEST_FOCUS(/datum/unit_test/ai_watcher_can_pursue_across_lava)
TEST_FOCUS(/datum/unit_test/patient_machine_idle_sleep)
TEST_FOCUS(/datum/unit_test/cleanbot_combined_scan_keeps_category_priority)
TEST_FOCUS(/datum/unit_test/cleanbot_combined_scan_keeps_adjacent_priority)
TEST_FOCUS(/datum/unit_test/cleanbot_grid_ground_target_lifecycle)
TEST_FOCUS(/datum/unit_test/cleanbot_small_candidate_filter_preserves_view_los)
TEST_FOCUS(/datum/unit_test/cleanbot_indexed_view_filter_preserves_priority)
TEST_FOCUS(/datum/unit_test/cleanbot_failed_path_search_has_cooldown)
TEST_FOCUS(/datum/unit_test/floorbot_failed_path_search_has_cooldown)
#endif

#undef TEST_ASSERT
#undef TEST_ASSERT_EQUAL
#undef TEST_ASSERT_NOTEQUAL
//#undef TEST_FOCUS - This define is used by vscode unit test extension to pick specific unit tests to run and appended later so needs to be used out of scope here
#endif
