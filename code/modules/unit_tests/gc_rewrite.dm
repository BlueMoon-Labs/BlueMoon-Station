/proc/copy_gc_rewrite_test_list(list/source)
	if (!islist(source))
		return null
	var/list/copied = source.Copy()
	for (var/i in 1 to length(copied))
		if (islist(copied[i]))
			copied[i] = copy_gc_rewrite_test_list(copied[i])
	return copied

/datum/unit_test/gc_rewrite_base
	var/list/saved_collection_timeout
	var/list/saved_queue_origin_times
	var/list/saved_queue_times
	var/list/saved_queue_refs
	var/list/saved_queue_hints
	var/list/saved_queue_types
	var/list/saved_queue_heads
	var/list/saved_pass_counts
	var/list/saved_fail_counts
	var/list/saved_peak_queue_depths
	var/list/saved_recent_failures
	var/list/saved_recent_hard_deletes
	var/list/saved_queue_depth_history
	var/list/saved_items
	var/list/saved_gc_cache_failures
	var/list/saved_gc_cache_sources
	var/saved_gc_cache_total_failures
	var/saved_totaldels
	var/saved_totalgcs
	var/saved_delslasttick
	var/saved_gcedlasttick
	var/saved_highest_del_ms
	var/saved_highest_del_type_string
	var/saved_leak_rate_avg
	var/saved_harddel_ms_avg
	var/saved_leak_rate_fires
	var/saved_leak_rate_fail_accumulator
	var/saved_queue_depth_sample_counter
	var/saved_last_hd_budget_ms
	var/saved_last_hd_cap
	var/saved_last_hd_mode
	var/saved_last_hd_overflow_mode
	var/saved_last_hd_background_scheduling
	var/saved_last_hd_pass_ms
	var/saved_last_hd_yield_ratio
	var/saved_last_hd_mc_clipped
	var/saved_last_fire_hd_reached
	var/saved_last_fire_hd_yield
	var/saved_last_q3_depth_delta
	var/saved_last_q3_depth_delta_per_second
	var/saved_gas_mixture_qdel_rate_per_second
	var/saved_gas_mixture_harddel_rate_per_second
	var/saved_last_queue_health_window_ds
	var/saved_last_queue_health_sample_time
	var/saved_last_q3_depth_sample
	var/saved_last_gas_mixture_qdel_sample
	var/saved_last_gas_mixture_harddel_sample
	var/saved_last_hd_hold_sample_eligible
	var/saved_hd_hold_eligibility_streak
	var/list/saved_harddel_yield_history
	var/saved_harddel_yield_total
	var/saved_gc_harddel_budget_min_ms
	var/saved_gc_harddel_budget_max_ms
	var/saved_gc_harddel_hold_max_per_fire
	var/saved_gc_harddel_max_per_fire
	var/saved_gc_harddel_recover_threshold
	var/saved_gc_harddel_target_q3_delta_per_second
	var/saved_gc_harddel_mode_hysteresis_samples
	var/saved_gc_harddel_overflow_threshold
	var/saved_gc_harddel_overflow_budget_max_ms
	var/saved_gc_harddel_overflow_max_per_fire
	var/saved_master_ticklimit
	var/saved_state
	var/saved_flags
	#ifdef REFERENCE_TRACKING
	var/list/saved_reference_find_on_fail
	#ifdef UNIT_TESTS
	var/saved_test_ref_scan_skip_async
	#endif
	#endif

/datum/unit_test/gc_rewrite_base/Run()
	return

/datum/unit_test/gc_rewrite_base/New()
	..()
	saved_collection_timeout = SSgarbage.collection_timeout.Copy()
	saved_queue_origin_times = copy_gc_rewrite_test_list(SSgarbage.queue_origin_times)
	saved_queue_times = copy_gc_rewrite_test_list(SSgarbage.queue_times)
	saved_queue_refs = copy_gc_rewrite_test_list(SSgarbage.queue_refs)
	saved_queue_hints = copy_gc_rewrite_test_list(SSgarbage.queue_hints)
	saved_queue_types = copy_gc_rewrite_test_list(SSgarbage.queue_types)
	saved_queue_heads = SSgarbage.queue_heads.Copy()
	saved_pass_counts = SSgarbage.pass_counts.Copy()
	saved_fail_counts = SSgarbage.fail_counts.Copy()
	saved_peak_queue_depths = SSgarbage.peak_queue_depths.Copy()
	saved_recent_failures = copy_gc_rewrite_test_list(SSgarbage.recent_failures)
	saved_recent_hard_deletes = copy_gc_rewrite_test_list(SSgarbage.recent_hard_deletes)
	saved_queue_depth_history = copy_gc_rewrite_test_list(SSgarbage.queue_depth_history)
	saved_items = SSgarbage.items
	saved_gc_cache_failures = GLOB.gc_failure_cache.failures
	saved_gc_cache_sources = GLOB.gc_failure_cache.failure_sources
	saved_gc_cache_total_failures = GLOB.gc_failure_cache.total_failures
	saved_totaldels = SSgarbage.totaldels
	saved_totalgcs = SSgarbage.totalgcs
	saved_delslasttick = SSgarbage.delslasttick
	saved_gcedlasttick = SSgarbage.gcedlasttick
	saved_highest_del_ms = SSgarbage.highest_del_ms
	saved_highest_del_type_string = SSgarbage.highest_del_type_string
	saved_leak_rate_avg = SSgarbage.leak_rate_avg
	saved_harddel_ms_avg = SSgarbage.harddel_ms_avg
	saved_leak_rate_fires = SSgarbage.leak_rate_fires
	saved_leak_rate_fail_accumulator = SSgarbage.leak_rate_fail_accumulator
	saved_queue_depth_sample_counter = SSgarbage.queue_depth_sample_counter
	saved_last_hd_budget_ms = SSgarbage.last_hd_budget_ms
	saved_last_hd_cap = SSgarbage.last_hd_cap
	saved_last_hd_mode = SSgarbage.last_hd_mode
	saved_last_hd_overflow_mode = SSgarbage.last_hd_overflow_mode
	saved_last_hd_background_scheduling = SSgarbage.last_hd_background_scheduling
	saved_last_hd_pass_ms = SSgarbage.last_hd_pass_ms
	saved_last_hd_yield_ratio = SSgarbage.last_hd_yield_ratio
	saved_last_hd_mc_clipped = SSgarbage.last_hd_mc_clipped
	saved_last_fire_hd_reached = SSgarbage.last_fire_hd_reached
	saved_last_fire_hd_yield = SSgarbage.last_fire_hd_yield
	saved_last_q3_depth_delta = SSgarbage.last_q3_depth_delta
	saved_last_q3_depth_delta_per_second = SSgarbage.last_q3_depth_delta_per_second
	saved_gas_mixture_qdel_rate_per_second = SSgarbage.gas_mixture_qdel_rate_per_second
	saved_gas_mixture_harddel_rate_per_second = SSgarbage.gas_mixture_harddel_rate_per_second
	saved_last_queue_health_window_ds = SSgarbage.last_queue_health_window_ds
	saved_last_queue_health_sample_time = SSgarbage.last_queue_health_sample_time
	saved_last_q3_depth_sample = SSgarbage.last_q3_depth_sample
	saved_last_gas_mixture_qdel_sample = SSgarbage.last_gas_mixture_qdel_sample
	saved_last_gas_mixture_harddel_sample = SSgarbage.last_gas_mixture_harddel_sample
	saved_last_hd_hold_sample_eligible = SSgarbage.last_hd_hold_sample_eligible
	saved_hd_hold_eligibility_streak = SSgarbage.hd_hold_eligibility_streak
	saved_harddel_yield_history = copy_gc_rewrite_test_list(SSgarbage.harddel_yield_history)
	saved_harddel_yield_total = SSgarbage.harddel_yield_total
	saved_gc_harddel_budget_min_ms = CONFIG_GET(number/gc_harddel_budget_min_ms)
	saved_gc_harddel_budget_max_ms = CONFIG_GET(number/gc_harddel_budget_max_ms)
	saved_gc_harddel_hold_max_per_fire = CONFIG_GET(number/gc_harddel_hold_max_per_fire)
	saved_gc_harddel_max_per_fire = CONFIG_GET(number/gc_harddel_max_per_fire)
	saved_gc_harddel_recover_threshold = CONFIG_GET(number/gc_harddel_recover_threshold)
	saved_gc_harddel_target_q3_delta_per_second = CONFIG_GET(number/gc_harddel_target_q3_delta_per_second)
	saved_gc_harddel_mode_hysteresis_samples = CONFIG_GET(number/gc_harddel_mode_hysteresis_samples)
	saved_gc_harddel_overflow_threshold = CONFIG_GET(number/gc_harddel_overflow_threshold)
	saved_gc_harddel_overflow_budget_max_ms = CONFIG_GET(number/gc_harddel_overflow_budget_max_ms)
	saved_gc_harddel_overflow_max_per_fire = CONFIG_GET(number/gc_harddel_overflow_max_per_fire)
	saved_master_ticklimit = Master.current_ticklimit
	saved_state = SSgarbage.state
	saved_flags = SSgarbage.flags
	#ifdef REFERENCE_TRACKING
	saved_reference_find_on_fail = SSgarbage.reference_find_on_fail.Copy()
	#ifdef UNIT_TESTS
	saved_test_ref_scan_skip_async = SSgarbage.test_ref_scan_skip_async
	#endif
	#endif

	SSgarbage.items = list()
	SSgarbage.recent_failures = list()
	SSgarbage.recent_hard_deletes = list()
	SSgarbage.queue_depth_history = list()
	GLOB.gc_failure_cache.failures = list()
	GLOB.gc_failure_cache.failure_sources = list()
	GLOB.gc_failure_cache.total_failures = 0
	SSgarbage.totaldels = 0
	SSgarbage.totalgcs = 0
	SSgarbage.delslasttick = 0
	SSgarbage.gcedlasttick = 0
	SSgarbage.highest_del_ms = 0
	SSgarbage.highest_del_type_string = ""
	SSgarbage.leak_rate_avg = 0
	SSgarbage.harddel_ms_avg = 0
	SSgarbage.leak_rate_fires = 0
	SSgarbage.leak_rate_fail_accumulator = 0
	SSgarbage.queue_depth_sample_counter = 0
	SSgarbage.last_hd_budget_ms = SSgarbage.GetConfiguredHardDeleteBudgetMinMs()
	SSgarbage.last_hd_cap = SSgarbage.GetConfiguredHardDeleteHoldMaxPerFire()
	SSgarbage.last_hd_mode = GC_HARDDEL_MODE_HOLD
	SSgarbage.last_hd_overflow_mode = FALSE
	SSgarbage.last_hd_background_scheduling = TRUE
	SSgarbage.last_hd_pass_ms = 0
	SSgarbage.last_hd_yield_ratio = 0
	SSgarbage.last_hd_mc_clipped = FALSE
	SSgarbage.last_fire_hd_reached = FALSE
	SSgarbage.last_fire_hd_yield = FALSE
	SSgarbage.last_q3_depth_delta = 0
	SSgarbage.last_q3_depth_delta_per_second = 0
	SSgarbage.gas_mixture_qdel_rate_per_second = 0
	SSgarbage.gas_mixture_harddel_rate_per_second = 0
	SSgarbage.last_queue_health_window_ds = 0
	SSgarbage.last_queue_health_sample_time = 0
	SSgarbage.last_q3_depth_sample = 0
	SSgarbage.last_gas_mixture_qdel_sample = 0
	SSgarbage.last_gas_mixture_harddel_sample = 0
	SSgarbage.last_hd_hold_sample_eligible = FALSE
	SSgarbage.hd_hold_eligibility_streak = 0
	SSgarbage.harddel_yield_history = list()
	SSgarbage.harddel_yield_total = 0
	SSgarbage.flags = initial(SSgarbage.flags)
	#ifdef REFERENCE_TRACKING
	SSgarbage.reference_find_on_fail = list()
	#endif

/datum/unit_test/gc_rewrite_base/proc/reset_gc_queues()
	for (var/i in 1 to GC_QUEUE_COUNT)
		SSgarbage.queue_origin_times[i] = list()
		SSgarbage.queue_times[i] = list()
		SSgarbage.queue_refs[i] = list()
		SSgarbage.queue_hints[i] = list()
		SSgarbage.queue_types[i] = list()
		SSgarbage.queue_heads[i] = 1
		SSgarbage.pass_counts[i] = 0
		SSgarbage.fail_counts[i] = 0
		SSgarbage.peak_queue_depths[i] = 0

/datum/unit_test/gc_rewrite_base/proc/run_gc_fire_cycles(cycles = 1, yield_for_gc = FALSE)
	if(yield_for_gc)
		SSgarbage.state = SS_IDLE // Prevent MC from firing SSgarbage during sleep
		sleep(20) // Let BYOND process pending refcount deletions
	for (var/i in 1 to cycles)
		SSgarbage.state = SS_RUNNING
		SSgarbage.fire()
	SSgarbage.state = SS_IDLE

/datum/unit_test/gc_rewrite_base/proc/configure_immediate_gc()
	reset_gc_queues()
	SSgarbage.items = list()
	GLOB.gc_failure_cache.failures = list()
	GLOB.gc_failure_cache.failure_sources = list()
	GLOB.gc_failure_cache.total_failures = 0
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 0
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9

/datum/unit_test/gc_rewrite_base/proc/assert_no_gc_failures(type_path, label)
	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(type_path)
	TEST_ASSERT_EQUAL(item.failures, 0, "[label] unexpectedly failed softcheck")
	TEST_ASSERT_EQUAL(item.warnfail_count, 0, "[label] unexpectedly reached warnfail")

/datum/unit_test/gc_rewrite_base/proc/seed_hold_health(streak = GC_HARDDEL_MODE_HYSTERESIS_SAMPLES, eligible = TRUE, q3_delta_per_second = -0.2, gas_qdel_rate = 1, gas_harddel_rate = 1, sample_window_ds = 300)
	SSgarbage.last_queue_health_window_ds = sample_window_ds
	SSgarbage.last_q3_depth_delta_per_second = q3_delta_per_second
	SSgarbage.gas_mixture_qdel_rate_per_second = gas_qdel_rate
	SSgarbage.gas_mixture_harddel_rate_per_second = gas_harddel_rate
	SSgarbage.last_hd_hold_sample_eligible = eligible
	SSgarbage.hd_hold_eligibility_streak = streak

/datum/unit_test/gc_rewrite_base/proc/restore_gc_state()
	SSgarbage.collection_timeout = saved_collection_timeout.Copy()
	SSgarbage.queue_origin_times = copy_gc_rewrite_test_list(saved_queue_origin_times)
	SSgarbage.queue_times = copy_gc_rewrite_test_list(saved_queue_times)
	SSgarbage.queue_refs = copy_gc_rewrite_test_list(saved_queue_refs)
	SSgarbage.queue_hints = copy_gc_rewrite_test_list(saved_queue_hints)
	SSgarbage.queue_types = copy_gc_rewrite_test_list(saved_queue_types)
	SSgarbage.queue_heads = saved_queue_heads.Copy()
	SSgarbage.pass_counts = saved_pass_counts.Copy()
	SSgarbage.fail_counts = saved_fail_counts.Copy()
	SSgarbage.peak_queue_depths = saved_peak_queue_depths.Copy()
	SSgarbage.recent_failures = copy_gc_rewrite_test_list(saved_recent_failures)
	SSgarbage.recent_hard_deletes = copy_gc_rewrite_test_list(saved_recent_hard_deletes)
	SSgarbage.queue_depth_history = copy_gc_rewrite_test_list(saved_queue_depth_history)
	SSgarbage.items = saved_items
	SSgarbage.totaldels = saved_totaldels
	SSgarbage.totalgcs = saved_totalgcs
	SSgarbage.delslasttick = saved_delslasttick
	SSgarbage.gcedlasttick = saved_gcedlasttick
	SSgarbage.highest_del_ms = saved_highest_del_ms
	SSgarbage.highest_del_type_string = saved_highest_del_type_string
	SSgarbage.leak_rate_avg = saved_leak_rate_avg
	SSgarbage.harddel_ms_avg = saved_harddel_ms_avg
	SSgarbage.leak_rate_fires = saved_leak_rate_fires
	SSgarbage.leak_rate_fail_accumulator = saved_leak_rate_fail_accumulator
	SSgarbage.queue_depth_sample_counter = saved_queue_depth_sample_counter
	SSgarbage.last_hd_budget_ms = saved_last_hd_budget_ms
	SSgarbage.last_hd_cap = saved_last_hd_cap
	SSgarbage.last_hd_mode = saved_last_hd_mode
	SSgarbage.last_hd_overflow_mode = saved_last_hd_overflow_mode
	SSgarbage.last_hd_background_scheduling = saved_last_hd_background_scheduling
	SSgarbage.last_hd_pass_ms = saved_last_hd_pass_ms
	SSgarbage.last_hd_yield_ratio = saved_last_hd_yield_ratio
	SSgarbage.last_hd_mc_clipped = saved_last_hd_mc_clipped
	SSgarbage.last_fire_hd_reached = saved_last_fire_hd_reached
	SSgarbage.last_fire_hd_yield = saved_last_fire_hd_yield
	SSgarbage.last_q3_depth_delta = saved_last_q3_depth_delta
	SSgarbage.last_q3_depth_delta_per_second = saved_last_q3_depth_delta_per_second
	SSgarbage.gas_mixture_qdel_rate_per_second = saved_gas_mixture_qdel_rate_per_second
	SSgarbage.gas_mixture_harddel_rate_per_second = saved_gas_mixture_harddel_rate_per_second
	SSgarbage.last_queue_health_window_ds = saved_last_queue_health_window_ds
	SSgarbage.last_queue_health_sample_time = saved_last_queue_health_sample_time
	SSgarbage.last_q3_depth_sample = saved_last_q3_depth_sample
	SSgarbage.last_gas_mixture_qdel_sample = saved_last_gas_mixture_qdel_sample
	SSgarbage.last_gas_mixture_harddel_sample = saved_last_gas_mixture_harddel_sample
	SSgarbage.last_hd_hold_sample_eligible = saved_last_hd_hold_sample_eligible
	SSgarbage.hd_hold_eligibility_streak = saved_hd_hold_eligibility_streak
	SSgarbage.harddel_yield_history = copy_gc_rewrite_test_list(saved_harddel_yield_history)
	SSgarbage.harddel_yield_total = saved_harddel_yield_total
	Master.current_ticklimit = saved_master_ticklimit
	SSgarbage.state = saved_state
	SSgarbage.flags = saved_flags
	GLOB.gc_failure_cache.failures = saved_gc_cache_failures
	GLOB.gc_failure_cache.failure_sources = saved_gc_cache_sources
	GLOB.gc_failure_cache.total_failures = saved_gc_cache_total_failures
	CONFIG_SET(number/gc_harddel_budget_min_ms, saved_gc_harddel_budget_min_ms)
	CONFIG_SET(number/gc_harddel_budget_max_ms, saved_gc_harddel_budget_max_ms)
	CONFIG_SET(number/gc_harddel_hold_max_per_fire, saved_gc_harddel_hold_max_per_fire)
	CONFIG_SET(number/gc_harddel_max_per_fire, saved_gc_harddel_max_per_fire)
	CONFIG_SET(number/gc_harddel_recover_threshold, saved_gc_harddel_recover_threshold)
	CONFIG_SET(number/gc_harddel_target_q3_delta_per_second, saved_gc_harddel_target_q3_delta_per_second)
	CONFIG_SET(number/gc_harddel_mode_hysteresis_samples, saved_gc_harddel_mode_hysteresis_samples)
	CONFIG_SET(number/gc_harddel_overflow_threshold, saved_gc_harddel_overflow_threshold)
	CONFIG_SET(number/gc_harddel_overflow_budget_max_ms, saved_gc_harddel_overflow_budget_max_ms)
	CONFIG_SET(number/gc_harddel_overflow_max_per_fire, saved_gc_harddel_overflow_max_per_fire)
	#ifdef REFERENCE_TRACKING
	SSgarbage.reference_find_on_fail = saved_reference_find_on_fail.Copy()
	#ifdef UNIT_TESTS
	SSgarbage.test_ref_scan_skip_async = saved_test_ref_scan_skip_async
	#endif
	#endif

/datum/unit_test/gc_rewrite_base/Destroy()
	for (var/obj/effect/gc_rewrite_test_object/object in allocated)
		object.hold_refs = null
		object.destroy_hint = QDEL_HINT_HARDDEL_NOW
	restore_gc_state()
	return ..()

/obj/effect/gc_rewrite_test_object
	name = "gc rewrite test object"
	var/destroy_hint = QDEL_HINT_QUEUE
	var/list/hold_refs = list()

/obj/effect/gc_rewrite_test_object/Destroy()
	..()
	return destroy_hint

/obj/effect/gc_rewrite_test_object/capped

/obj/effect/gc_rewrite_test_object/expensive

/mob/unit_test/gc_alert_dummy

/datum/unit_test/gc_rewrite_sticky_moustache_destroy_cancels_timer
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_sticky_moustache_destroy_cancels_timer/Run()
	configure_immediate_gc()
	var/mob/living/carbon/human/wearer = allocate(/mob/living/carbon/human)
	var/obj/item/clothing/mask/fakemoustache/sticky/sticky = allocate(/obj/item/clothing/mask/fakemoustache/sticky)
	wearer.equip_to_slot_or_del(sticky, ITEM_SLOT_MASK, TRUE, TRUE, TRUE, TRUE)

	TEST_ASSERT_EQUAL(wearer.wear_mask, sticky, "Sticky moustache was not equipped into the mask slot")
	TEST_ASSERT(HAS_TRAIT_FROM(wearer, TRAIT_NO_INTERNALS, STICKY_MOUSTACHE_TRAIT), "Sticky moustache did not apply the no-internals trait")
	TEST_ASSERT_NOTNULL(sticky.unstick_timerid, "Sticky moustache did not create a stoppable unstick timer")
	TEST_ASSERT_NOTNULL(SStimer.timer_id_dict[sticky.unstick_timerid], "Sticky moustache timer was not registered")

	var/timerid = sticky.unstick_timerid
	allocated -= sticky
	qdel(sticky)
	sticky = null

	TEST_ASSERT_NULL(SStimer.timer_id_dict[timerid], "Sticky moustache timer was not cancelled during Destroy()")
	TEST_ASSERT(!HAS_TRAIT_FROM(wearer, TRAIT_NO_INTERNALS, STICKY_MOUSTACHE_TRAIT), "Sticky moustache Destroy() did not clear the wearer no-internals trait")

	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_no_gc_failures(/obj/item/clothing/mask/fakemoustache/sticky, "Sticky moustache")

/datum/unit_test/gc_rewrite_buckled_alert_destroy_scrubs_owner_refs
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_buckled_alert_destroy_scrubs_owner_refs/Run()
	configure_immediate_gc()
	var/mob/unit_test/gc_alert_dummy/dummy = allocate(/mob/unit_test/gc_alert_dummy)
	dummy.throw_alert("buckled", /atom/movable/screen/alert/buckled)

	TEST_ASSERT_NOTNULL(dummy.alerts["buckled"], "Buckled alert was not created")

	dummy.clear_alert("buckled", TRUE)

	TEST_ASSERT_NULL(dummy.alerts["buckled"], "Buckled alert Destroy() did not scrub the owner alert slot")

	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_no_gc_failures(/atom/movable/screen/alert/buckled, "Buckled alert")

/datum/unit_test/gc_rewrite_mob_destroy_clears_alerts
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_mob_destroy_clears_alerts/Run()
	configure_immediate_gc()
	var/mob/unit_test/gc_alert_dummy/dummy = allocate(/mob/unit_test/gc_alert_dummy)
	dummy.throw_alert("buckled", /atom/movable/screen/alert/buckled)
	dummy.throw_alert("handcuffed", /atom/movable/screen/alert/restrained/handcuffed)

	TEST_ASSERT_EQUAL(length(dummy.alerts), 2, "The test mob did not receive both alerts")

	allocated -= dummy
	qdel(dummy)
	dummy = null
	run_gc_fire_cycles(2, yield_for_gc = TRUE)

	assert_no_gc_failures(/atom/movable/screen/alert/buckled, "Buckled alert during mob deletion")
	assert_no_gc_failures(/atom/movable/screen/alert/restrained/handcuffed, "Handcuffed alert during mob deletion")

/datum/unit_test/gc_rewrite_disposalholder_mid_transit_cleanup
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_disposalholder_mid_transit_cleanup/Run()
	configure_immediate_gc()
	var/obj/structure/disposalpipe/pipe = allocate(/obj/structure/disposalpipe)
	var/obj/structure/disposalholder/holder = allocate(/obj/structure/disposalholder, pipe)

	holder.start_moving()
	TEST_ASSERT_NOTNULL(holder.movement_loop, "Disposalholder did not keep a handle to its move loop")
	var/datum/move_loop/disposal_holder/loop = holder.movement_loop

	allocated -= holder
	qdel(holder)
	holder = null

	TEST_ASSERT(QDELETED(loop), "Disposalholder did not qdel its move loop during cleanup")
	loop = null

	SSmovement.fire(FALSE)
	run_gc_fire_cycles(2, yield_for_gc = TRUE)
	assert_no_gc_failures(/obj/structure/disposalholder, "Disposalholder")

/datum/unit_test/gc_rewrite_qdel_in_uses_legacy_strong_ref_threshold
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_qdel_in_uses_legacy_strong_ref_threshold/Run()
	var/obj/effect/gc_rewrite_test_object/short_lived = allocate(/obj/effect/gc_rewrite_test_object)
	var/obj/effect/gc_rewrite_test_object/long_lived = allocate(/obj/effect/gc_rewrite_test_object)
	var/short_timer_id = QDEL_IN_STOPPABLE(short_lived, GC_SOFTCHECK_TIMEOUT + 1)
	var/long_timer_id = QDEL_IN_STOPPABLE(long_lived, GC_FILTER_QUEUE + 1)

	var/datum/timedevent/short_timer = SStimer.timer_id_dict[short_timer_id]
	var/datum/timedevent/long_timer = SStimer.timer_id_dict[long_timer_id]
	TEST_ASSERT_NOTNULL(short_timer, "The short qdel timer was not created")
	TEST_ASSERT_NOTNULL(long_timer, "The long qdel timer was not created")

	var/short_arg = short_timer.callBack.arguments[1]
	var/long_arg = long_timer.callBack.arguments[1]
	TEST_ASSERT_EQUAL(short_arg, short_lived, "A qdel timer shorter than GC_FILTER_QUEUE unexpectedly used a weakref")
	TEST_ASSERT(istype(long_arg, /datum/weakref), "A qdel timer longer than GC_FILTER_QUEUE did not use a weakref")

	deltimer(short_timer_id)
	deltimer(long_timer_id)

/datum/unit_test/gc_rewrite_recover_preserves_queue_times
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_recover_preserves_queue_times/Run()
	reset_gc_queues()
	var/obj/effect/gc_rewrite_test_object/queued = allocate(/obj/effect/gc_rewrite_test_object)
	queued.hold_refs = list(queued)
	var/origin_time = world.time - 100
	var/queued_at = world.time - 20
	SSgarbage.Queue(queued, GC_QUEUE_WARNFAIL, QDEL_HINT_QUEUE, origin_time, queued_at)

	var/list/snapshot_origins = copy_gc_rewrite_test_list(SSgarbage.queue_origin_times)
	var/list/snapshot_times = copy_gc_rewrite_test_list(SSgarbage.queue_times)
	var/list/snapshot_refs = copy_gc_rewrite_test_list(SSgarbage.queue_refs)
	var/list/snapshot_hints = copy_gc_rewrite_test_list(SSgarbage.queue_hints)
	var/list/snapshot_heads = SSgarbage.queue_heads.Copy()

	reset_gc_queues()
	SSgarbage.RecoverQueueEntries(snapshot_refs, snapshot_times, snapshot_origins, snapshot_hints, snapshot_heads)

	TEST_ASSERT_EQUAL(length(SSgarbage.queue_refs[GC_QUEUE_WARNFAIL]), 1, "RecoverQueueEntries() did not restore the warnfail slot")
	TEST_ASSERT_EQUAL(SSgarbage.queue_times[GC_QUEUE_WARNFAIL][1], queued_at, "RecoverQueueEntries() reset the current stage time")
	TEST_ASSERT_EQUAL(SSgarbage.queue_origin_times[GC_QUEUE_WARNFAIL][1], origin_time, "RecoverQueueEntries() reset the original qdel time")
	TEST_ASSERT_EQUAL(queued.gc_destroyed, queued_at, "RecoverQueueEntries() did not restore gc_destroyed to the recovered stage time")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_WARNFAIL, 1), queued, "Recovered queue slot was not considered live")

/datum/unit_test/gc_rewrite_recover_skips_tombstones_and_stale_slots
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_recover_skips_tombstones_and_stale_slots/Run()
	reset_gc_queues()
	var/obj/effect/gc_rewrite_test_object/live = allocate(/obj/effect/gc_rewrite_test_object)
	var/obj/effect/gc_rewrite_test_object/stale = allocate(/obj/effect/gc_rewrite_test_object)
	var/live_stage_time = world.time - 20
	var/live_origin_time = world.time - 90
	var/stale_stage_time = world.time - 15

	live.gc_destroyed = live_stage_time
	stale.gc_destroyed = world.time

	var/list/source_refs = new(GC_QUEUE_COUNT)
	var/list/source_times = new(GC_QUEUE_COUNT)
	var/list/source_origins = new(GC_QUEUE_COUNT)
	var/list/source_hints = new(GC_QUEUE_COUNT)
	var/list/source_heads = new(GC_QUEUE_COUNT)
	for (var/i in 1 to GC_QUEUE_COUNT)
		source_refs[i] = list()
		source_times[i] = list()
		source_origins[i] = list()
		source_hints[i] = list()
		source_heads[i] = 1

	source_refs[GC_QUEUE_WARNFAIL] = list(null, REF(live), REF(stale))
	source_times[GC_QUEUE_WARNFAIL] = list(null, live_stage_time, stale_stage_time)
	source_origins[GC_QUEUE_WARNFAIL] = list(null, live_origin_time, world.time - 80)
	source_hints[GC_QUEUE_WARNFAIL] = list(null, QDEL_HINT_QUEUE, QDEL_HINT_QUEUE)
	source_heads[GC_QUEUE_WARNFAIL] = 2

	SSgarbage.RecoverQueueEntries(source_refs, source_times, source_origins, source_hints, source_heads)

	TEST_ASSERT_EQUAL(length(SSgarbage.queue_refs[GC_QUEUE_WARNFAIL]), 1, "RecoverQueueEntries() restored stale or tombstoned slots")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_WARNFAIL, 1), live, "RecoverQueueEntries() did not restore the live post-head slot")
	TEST_ASSERT_EQUAL(SSgarbage.queue_origin_times[GC_QUEUE_WARNFAIL][1], live_origin_time, "RecoverQueueEntries() lost the preserved origin time")

/datum/unit_test/gc_rewrite_warnfail_lifecycle_preserves_origin
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_warnfail_lifecycle_preserves_origin/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 0
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 10000 HOURS

	var/obj/effect/gc_rewrite_test_object/leaker = allocate(/obj/effect/gc_rewrite_test_object)
	leaker.hold_refs = list(leaker)
	qdel(leaker)
	var/origin_time = leaker.gc_destroyed

	run_gc_fire_cycles(2)

	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(/obj/effect/gc_rewrite_test_object)
	TEST_ASSERT_EQUAL(item.failures, 1, "Softcheck miss was not counted")
	TEST_ASSERT_EQUAL(item.warnfail_count, 1, "Warnfail leak was not counted")
	TEST_ASSERT_EQUAL(length(item.failure_times), 1, "Warnfail timestamps were not recorded")
	TEST_ASSERT_EQUAL(length(SSgarbage.recent_failures), 2, "Softcheck and warnfail events were not both recorded")
	TEST_ASSERT_EQUAL(SSgarbage.recent_failures[1][3], GC_QUEUE_SOFTCHECK, "The first recent failure was not softcheck")
	TEST_ASSERT_EQUAL(SSgarbage.recent_failures[2][3], GC_QUEUE_WARNFAIL, "The second recent failure was not warnfail")
	TEST_ASSERT_EQUAL(SSgarbage.recent_failures[2][4], QDEL_HINT_QUEUE, "The warnfail event lost its qdel hint")
	TEST_ASSERT_EQUAL(GLOB.gc_failure_cache.total_failures, 1, "Warnfail entries were not logged per failure")

	var/datum/gc_failure_viewer/gc_failure_entry/entry = GLOB.gc_failure_cache.failures[1]
	TEST_ASSERT_EQUAL(entry.origin_time, origin_time, "Warnfail entry lost the original qdel timestamp")

	var/hd_head = SSgarbage.queue_heads[GC_QUEUE_HARDDELETE]
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 1, "The object was not promoted into the harddelete queue")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_HARDDELETE, hd_head), leaker, "The promoted harddelete slot was not live")
	TEST_ASSERT_EQUAL(SSgarbage.queue_origin_times[GC_QUEUE_HARDDELETE][hd_head], origin_time, "Harddelete promotion lost the original qdel timestamp")

	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	run_gc_fire_cycles(2)

	TEST_ASSERT_EQUAL(SSgarbage.totaldels, 1, "The harddelete stage did not delete the leaking object")
	TEST_ASSERT_EQUAL(length(SSgarbage.recent_hard_deletes), 1, "The harddelete event was not recorded")

/datum/unit_test/gc_rewrite_suspended_types_stay_diagnostic
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_suspended_types_stay_diagnostic/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 0
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0

	var/obj/effect/gc_rewrite_test_object/leaker = allocate(/obj/effect/gc_rewrite_test_object)
	leaker.hold_refs = list(leaker)
	qdel(leaker)
	var/origin_time = leaker.gc_destroyed

	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(/obj/effect/gc_rewrite_test_object)
	item.qdel_flags |= QDEL_ITEM_SUSPENDED_FOR_LAG

	run_gc_fire_cycles(2)

	TEST_ASSERT_EQUAL(item.warnfail_count, 1, "Suspended types stopped counting confirmed leaks")
	TEST_ASSERT_EQUAL(GLOB.gc_failure_cache.total_failures, 1, "Suspended types stopped creating failure-viewer entries")
	TEST_ASSERT_EQUAL(SSgarbage.totaldels, 0, "Suspended types should not be hard-deleted automatically")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 1, "Suspended types should remain visible in the harddelete queue")
	var/hd_head = SSgarbage.queue_heads[GC_QUEUE_HARDDELETE]
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_HARDDELETE, hd_head), leaker, "Suspended types lost their harddelete-stage queue entry")
	TEST_ASSERT_EQUAL(SSgarbage.queue_origin_times[GC_QUEUE_HARDDELETE][hd_head], origin_time, "Suspended types lost their original qdel timestamp")

/datum/unit_test/gc_rewrite_harddel_modes_use_config
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_harddel_modes_use_config/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9

	CONFIG_SET(number/gc_harddel_budget_min_ms, 11)
	CONFIG_SET(number/gc_harddel_budget_max_ms, 22)
	CONFIG_SET(number/gc_harddel_hold_max_per_fire, 2)
	CONFIG_SET(number/gc_harddel_max_per_fire, 5)
	CONFIG_SET(number/gc_harddel_recover_threshold, 1800)
	CONFIG_SET(number/gc_harddel_target_q3_delta_per_second, -0.1)
	CONFIG_SET(number/gc_harddel_mode_hysteresis_samples, 2)
	CONFIG_SET(number/gc_harddel_overflow_threshold, 4000)
	CONFIG_SET(number/gc_harddel_overflow_budget_max_ms, 66)
	CONFIG_SET(number/gc_harddel_overflow_max_per_fire, 9)

	seed_hold_health()
	var/obj/effect/gc_rewrite_test_object/hold_queue = allocate(/obj/effect/gc_rewrite_test_object)
	hold_queue.destroy_hint = QDEL_HINT_HARDDEL
	hold_queue.hold_refs = list(hold_queue)
	qdel(hold_queue)
	run_gc_fire_cycles(1)

	TEST_ASSERT_EQUAL(SSgarbage.last_hd_mode, GC_HARDDEL_MODE_HOLD, "Harddelete controller did not enter HOLD mode when the sampled queue health was healthy")
	TEST_ASSERT_EQUAL(SSgarbage.last_hd_budget_ms, 11, "HOLD mode did not use the configured minimum budget")
	TEST_ASSERT_EQUAL(SSgarbage.last_hd_cap, 2, "HOLD mode did not use the configured hold cap")
	TEST_ASSERT(SSgarbage.flags & SS_BACKGROUND, "HOLD mode did not keep garbage scheduled as a background subsystem")

	reset_gc_queues()
	seed_hold_health(0, FALSE, 0.25, 2, 0)
	var/obj/effect/gc_rewrite_test_object/recover_queue = allocate(/obj/effect/gc_rewrite_test_object)
	recover_queue.destroy_hint = QDEL_HINT_HARDDEL
	recover_queue.hold_refs = list(recover_queue)
	qdel(recover_queue)
	run_gc_fire_cycles(1)

	TEST_ASSERT_EQUAL(SSgarbage.last_hd_mode, GC_HARDDEL_MODE_RECOVER, "Harddelete controller did not enter RECOVER mode when q3 was no longer healthy")
	TEST_ASSERT_EQUAL(SSgarbage.last_hd_budget_ms, 22, "RECOVER mode did not use the configured recover budget")
	TEST_ASSERT_EQUAL(SSgarbage.last_hd_cap, 5, "RECOVER mode did not use the configured recover cap")
	TEST_ASSERT(!(SSgarbage.flags & SS_BACKGROUND), "RECOVER mode did not switch garbage out of background scheduling")

	reset_gc_queues()
	SSgarbage.queue_origin_times[GC_QUEUE_HARDDELETE] = new /list(4001)
	SSgarbage.queue_times[GC_QUEUE_HARDDELETE] = new /list(4001)
	SSgarbage.queue_refs[GC_QUEUE_HARDDELETE] = new /list(4001)
	SSgarbage.queue_hints[GC_QUEUE_HARDDELETE] = new /list(4001)
	for (var/i in 1 to 4001)
		SSgarbage.queue_origin_times[GC_QUEUE_HARDDELETE][i] = world.time + 10
		SSgarbage.queue_times[GC_QUEUE_HARDDELETE][i] = world.time + 10
		SSgarbage.queue_refs[GC_QUEUE_HARDDELETE][i] = "overflow-[i]"
		SSgarbage.queue_hints[GC_QUEUE_HARDDELETE][i] = QDEL_HINT_HARDDEL
	SSgarbage.queue_heads[GC_QUEUE_HARDDELETE] = 1
	run_gc_fire_cycles(1)

	TEST_ASSERT_EQUAL(SSgarbage.last_hd_mode, GC_HARDDEL_MODE_OVERFLOW, "Harddelete controller did not enter OVERFLOW mode at the configured threshold")
	TEST_ASSERT_EQUAL(SSgarbage.last_hd_budget_ms, 66, "OVERFLOW mode did not use the configured overflow budget")
	TEST_ASSERT_EQUAL(SSgarbage.last_hd_cap, 9, "OVERFLOW mode did not use the configured overflow cap")
	TEST_ASSERT(!(SSgarbage.flags & SS_BACKGROUND), "OVERFLOW mode unexpectedly left garbage in background scheduling")

/datum/unit_test/gc_rewrite_harddel_hold_requires_hysteresis
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_harddel_hold_requires_hysteresis/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9

	CONFIG_SET(number/gc_harddel_budget_min_ms, 10)
	CONFIG_SET(number/gc_harddel_budget_max_ms, 20)
	CONFIG_SET(number/gc_harddel_hold_max_per_fire, 2)
	CONFIG_SET(number/gc_harddel_max_per_fire, 4)
	CONFIG_SET(number/gc_harddel_mode_hysteresis_samples, 2)

	seed_hold_health(1, TRUE)
	SSgarbage.last_hd_mode = GC_HARDDEL_MODE_RECOVER
	var/obj/effect/gc_rewrite_test_object/first = allocate(/obj/effect/gc_rewrite_test_object)
	first.destroy_hint = QDEL_HINT_HARDDEL
	first.hold_refs = list(first)
	qdel(first)
	run_gc_fire_cycles(1)

	TEST_ASSERT_EQUAL(SSgarbage.last_hd_mode, GC_HARDDEL_MODE_RECOVER, "Harddelete controller entered HOLD mode before satisfying hysteresis")

	reset_gc_queues()
	seed_hold_health(2, TRUE)
	var/obj/effect/gc_rewrite_test_object/second = allocate(/obj/effect/gc_rewrite_test_object)
	second.destroy_hint = QDEL_HINT_HARDDEL
	second.hold_refs = list(second)
	qdel(second)
	run_gc_fire_cycles(1)

	TEST_ASSERT_EQUAL(SSgarbage.last_hd_mode, GC_HARDDEL_MODE_HOLD, "Harddelete controller did not enter HOLD mode after satisfying hysteresis")
	TEST_ASSERT(SSgarbage.flags & SS_BACKGROUND, "Harddelete controller did not restore background scheduling after satisfying hysteresis")

/datum/unit_test/gc_rewrite_harddel_bootstrap_is_single_delete
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_harddel_bootstrap_is_single_delete/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9

	CONFIG_SET(number/gc_harddel_budget_min_ms, 8)
	CONFIG_SET(number/gc_harddel_hold_max_per_fire, 2)
	CONFIG_SET(number/gc_harddel_max_per_fire, 2)
	seed_hold_health()

	SSgarbage.harddel_ms_avg = 0
	var/datum/qdel_item/expensive_item = SSgarbage.GetOrCreateItem(/obj/effect/gc_rewrite_test_object/expensive)
	expensive_item.hard_deletes = 1
	expensive_item.hard_delete_avg_ms = 20

	var/obj/effect/gc_rewrite_test_object/cheap = allocate(/obj/effect/gc_rewrite_test_object)
	cheap.destroy_hint = QDEL_HINT_HARDDEL
	cheap.hold_refs = list(cheap)
	qdel(cheap)

	var/obj/effect/gc_rewrite_test_object/expensive = allocate(/obj/effect/gc_rewrite_test_object/expensive)
	expensive.destroy_hint = QDEL_HINT_HARDDEL
	expensive.hold_refs = list(expensive)
	qdel(expensive)

	run_gc_fire_cycles(1)

	TEST_ASSERT_EQUAL(SSgarbage.totaldels, 1, "Bootstrap harddelete processing no longer stopped after a single unconditional delete")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 1, "The second harddelete entry was not preserved for the next fire")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_HARDDELETE, SSgarbage.queue_heads[GC_QUEUE_HARDDELETE]), expensive, "The expensive harddelete entry did not remain queued after bootstrap")

/// Bootstrap must fire per-type even when the global harddel_ms_avg is high from expensive types.
/datum/unit_test/gc_rewrite_harddel_bootstrap_fires_despite_high_global_avg
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_harddel_bootstrap_fires_despite_high_global_avg/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9

	CONFIG_SET(number/gc_harddel_budget_min_ms, 8)
	CONFIG_SET(number/gc_harddel_hold_max_per_fire, 2)
	CONFIG_SET(number/gc_harddel_max_per_fire, 4)
	CONFIG_SET(number/gc_harddel_recover_threshold, 0)
	seed_hold_health()

	// Global avg is high from expensive types, but the cheap type has no per-type data yet.
	SSgarbage.harddel_ms_avg = 60

	var/obj/effect/gc_rewrite_test_object/cheap = allocate(/obj/effect/gc_rewrite_test_object)
	cheap.destroy_hint = QDEL_HINT_HARDDEL
	cheap.hold_refs = list(cheap)
	qdel(cheap)

	run_gc_fire_cycles(1)

	TEST_ASSERT_EQUAL(SSgarbage.totaldels, 1, "Bootstrap did not fire for a type with no per-type data despite high global harddel_ms_avg")

/// Per-type cost estimation allows cheap types to be processed even when the global avg is inflated.
/datum/unit_test/gc_rewrite_harddel_per_type_estimation_allows_cheap_types
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_harddel_per_type_estimation_allows_cheap_types/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9

	CONFIG_SET(number/gc_harddel_budget_min_ms, 200)
	CONFIG_SET(number/gc_harddel_hold_max_per_fire, 4)
	CONFIG_SET(number/gc_harddel_max_per_fire, 4)
	CONFIG_SET(number/gc_harddel_recover_threshold, 0)
	seed_hold_health()

	// Global avg inflated by expensive types, but our type is known-cheap (per-type avg = 2ms).
	// With the old max()-based estimation, estimated_next_cost would be max(2, 60, 4) = 60ms,
	// blocking processing entirely. With per-type estimation, cost = 2ms → fits in budget.
	SSgarbage.harddel_ms_avg = 60
	var/datum/qdel_item/cheap_item = SSgarbage.GetOrCreateItem(/obj/effect/gc_rewrite_test_object)
	cheap_item.hard_deletes = 10
	cheap_item.hard_delete_time = 20
	cheap_item.hard_delete_avg_ms = 2

	var/obj/effect/gc_rewrite_test_object/obj_a = allocate(/obj/effect/gc_rewrite_test_object)
	obj_a.destroy_hint = QDEL_HINT_HARDDEL
	obj_a.hold_refs = list(obj_a)
	qdel(obj_a)

	run_gc_fire_cycles(1)

	// The key assertion: with the old code, estimated_next_cost = max(2, 60, 4) = 60ms,
	// which exceeds even a large budget after accounting for overhead. With per-type estimation,
	// the cost is 2ms → processed within budget.
	TEST_ASSERT_EQUAL(SSgarbage.totaldels, 1, "Per-type cost estimation failed to process a cheap type when global avg was inflated")

/datum/unit_test/gc_rewrite_harddel_hold_budget_blocks_expensive_gasmixture
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_harddel_hold_budget_blocks_expensive_gasmixture/Run()
	reset_gc_queues()
	// gas_mixture now uses QUEUE_THEN_HARDDEL: enters Q1 first, needs softcheck timeout=0 to promote to Q3.
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9

	CONFIG_SET(number/gc_harddel_budget_min_ms, 8)
	CONFIG_SET(number/gc_harddel_hold_max_per_fire, 2)
	CONFIG_SET(number/gc_harddel_max_per_fire, 2)
	seed_hold_health()

	SSgarbage.harddel_ms_avg = 20
	var/datum/qdel_item/gas_item = SSgarbage.GetOrCreateItem(/datum/gas_mixture)
	gas_item.hard_deletes = 1
	gas_item.hard_delete_avg_ms = 20

	var/datum/gas_mixture/gas_a = new
	var/datum/gas_mixture/gas_b = new
	allocated += gas_a
	allocated += gas_b
	qdel(gas_a)
	qdel(gas_b)

	// First fire: Q1 softcheck fails (allocated holds refs) → promoted to Q3 via QUEUE_THEN_HARDDEL.
	// Second fire: Q3 harddelete pass — budget should block expensive gas_mixtures.
	run_gc_fire_cycles(2)

	TEST_ASSERT_EQUAL(SSgarbage.last_hd_mode, GC_HARDDEL_MODE_HOLD, "The gas-mix harddelete test did not run in HOLD mode")
	TEST_ASSERT_EQUAL(SSgarbage.totaldels, 0, "Expensive gas-mixture hard deletes were still started in HOLD mode")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 2, "Expensive gas-mixture hard deletes were not left queued for a later pass")

/// In RECOVER mode, at least one expensive gas_mixture should be hard-deleted per fire
/// to prevent queue starvation — even when estimated cost exceeds the budget.
/datum/unit_test/gc_rewrite_harddel_recover_processes_expensive_gasmixture
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_harddel_recover_processes_expensive_gasmixture/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9

	// Force RECOVER mode by setting a low recover threshold.
	CONFIG_SET(number/gc_harddel_recover_threshold, 1)
	CONFIG_SET(number/gc_harddel_budget_max_ms, 30)
	CONFIG_SET(number/gc_harddel_max_per_fire, 5)

	// Seed gas_mixture as expensive (avg 50ms > budget 30ms).
	SSgarbage.harddel_ms_avg = 50
	var/datum/qdel_item/gas_item = SSgarbage.GetOrCreateItem(/datum/gas_mixture)
	gas_item.hard_deletes = 1
	gas_item.hard_delete_avg_ms = 50

	var/datum/gas_mixture/gas_a = new
	allocated += gas_a
	qdel(gas_a)

	// Single fire: Q1 softcheck fails (allocated holds ref) → promoted to Q3 via QUEUE_THEN_HARDDEL.
	// Same fire continues to Q3 harddelete pass — RECOVER mode should bootstrap the expensive delete.
	run_gc_fire_cycles(1)

	TEST_ASSERT_EQUAL(SSgarbage.last_hd_mode, GC_HARDDEL_MODE_RECOVER, "The gas-mix harddelete test did not run in RECOVER mode")
	TEST_ASSERT_EQUAL(SSgarbage.totaldels, 1, "RECOVER mode did not bootstrap the expensive gas-mixture hard delete")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 0, "Gas-mixture was not drained from hard-delete queue in RECOVER mode")

/datum/unit_test/gc_rewrite_harddel_metrics_track_mc_clipping
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_harddel_metrics_track_mc_clipping/Run()
	SSgarbage.last_hd_budget_ms = 20
	SSgarbage.harddel_yield_history = list(1, 1, 1)
	SSgarbage.harddel_yield_total = 3
	SSgarbage.last_fire_hd_reached = TRUE
	SSgarbage.last_fire_hd_yield = TRUE

	SSgarbage.FinalizeHardDeleteFireMetrics(4)

	TEST_ASSERT(SSgarbage.last_hd_yield_ratio >= 0.99, "Harddelete yield ratio did not include the current yielded pass")
	TEST_ASSERT(SSgarbage.last_hd_mc_clipped, "Harddelete metrics did not flag MC clipping when the pass yielded well below budget")

/datum/unit_test/gc_rewrite_softfail_alert_is_per_instance
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_softfail_alert_is_per_instance/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 10000 HOURS

	var/obj/effect/gc_rewrite_test_object/alerted = allocate(/obj/effect/gc_rewrite_test_object)
	alerted.destroy_hint = QDEL_HINT_SOFTFAIL_ALERT
	alerted.hold_refs = list(alerted)
	qdel(alerted)
	SSgarbage.state = SS_RUNNING
	SSgarbage.fire()

	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(/obj/effect/gc_rewrite_test_object)
	TEST_ASSERT_EQUAL(item.softfail_alert_failures, 1, "The SOFTFAIL_ALERT instance did not increment softfail_alert_failures")

	var/obj/effect/gc_rewrite_test_object/normal = allocate(/obj/effect/gc_rewrite_test_object)
	normal.destroy_hint = QDEL_HINT_QUEUE
	normal.hold_refs = list(normal)
	qdel(normal)
	SSgarbage.state = SS_RUNNING
	SSgarbage.fire()

	TEST_ASSERT_EQUAL(item.softfail_alert_failures, 1, "A later non-SOFTFAIL_ALERT instance was still treated as SOFTFAIL_ALERT")

/datum/unit_test/gc_rewrite_queue_slot_validation
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_queue_slot_validation/Run()
	reset_gc_queues()
	var/obj/effect/gc_rewrite_test_object/queued = allocate(/obj/effect/gc_rewrite_test_object)
	var/origin_time = world.time - 30
	var/queued_at = world.time - 5
	SSgarbage.Queue(queued, GC_QUEUE_WARNFAIL, QDEL_HINT_QUEUE, origin_time, queued_at)

	var/datum/queued_lookup = SSgarbage.GetQueuedDatum(GC_QUEUE_WARNFAIL, 1)
	TEST_ASSERT_EQUAL(queued_lookup, queued, "A valid queue slot was not returned by GetQueuedDatum()")
	queued.gc_destroyed = world.time
	TEST_ASSERT_NULL(SSgarbage.GetQueuedDatum(GC_QUEUE_WARNFAIL, 1), "A stale queue slot was still treated as live")
	queued.gc_destroyed = queued_at
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_WARNFAIL, 1), queued, "Restoring the queue timestamp did not make the slot valid again")

/datum/unit_test/gc_rewrite_compaction_preserves_live_entry
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_compaction_preserves_live_entry/Run()
	reset_gc_queues()
	var/obj/effect/gc_rewrite_test_object/live = allocate(/obj/effect/gc_rewrite_test_object)
	var/live_origin = world.time - 80
	var/live_stage = world.time - 5
	live.gc_destroyed = live_stage

	var/list/origins = list()
	var/list/times = list()
	var/list/refs = list()
	var/list/hints = list()
	var/list/types = list()
	for (var/i in 1 to GC_COMPACT_THRESHOLD)
		origins += null
		times += null
		refs += null
		hints += null
		types += null
	origins += live_origin
	times += live_stage
	refs += REF(live)
	hints += QDEL_HINT_QUEUE
	types += "[live.type]"

	SSgarbage.SaveQueueLevel(GC_QUEUE_WARNFAIL, origins, times, refs, hints, types)
	SSgarbage.queue_heads[GC_QUEUE_WARNFAIL] = GC_COMPACT_THRESHOLD + 1
	SSgarbage.MaybeCompact(GC_QUEUE_WARNFAIL, SSgarbage.queue_heads[GC_QUEUE_WARNFAIL])

	TEST_ASSERT_EQUAL(SSgarbage.queue_heads[GC_QUEUE_WARNFAIL], 1, "Queue compaction did not reset the head index")
	TEST_ASSERT_EQUAL(length(SSgarbage.queue_refs[GC_QUEUE_WARNFAIL]), 1, "Queue compaction dropped or duplicated live entries")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_WARNFAIL, 1), live, "Queue compaction lost the live queue entry")
	TEST_ASSERT_EQUAL(SSgarbage.queue_origin_times[GC_QUEUE_WARNFAIL][1], live_origin, "Queue compaction lost the preserved origin time")

/datum/unit_test/gc_rewrite_failure_viewer_caps
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_failure_viewer_caps/Run()
	var/start_total_failures = GLOB.gc_failure_cache.total_failures
	var/entry_count = GC_FAILURE_ENTRY_LIMIT + 5
	var/type_key = "[/obj/effect/gc_rewrite_test_object/capped]"
	for (var/i in 1 to entry_count)
		GLOB.gc_failure_cache.log_gc_failure(null, /obj/effect/gc_rewrite_test_object/capped, "cap-[i]", world.time - i, QDEL_HINT_QUEUE)

	var/datum/gc_failure_viewer/gc_failure_source/source = GLOB.gc_failure_cache.failure_sources[type_key]
	TEST_ASSERT_NOTNULL(source, "The capped GC failure source was not created")
	TEST_ASSERT_EQUAL(source.total_failures, entry_count, "Source total_failures did not track truncated history")
	TEST_ASSERT_EQUAL(length(source.failures), GC_FAILURE_SOURCE_ENTRY_LIMIT, "Source retained history did not respect GC_FAILURE_SOURCE_ENTRY_LIMIT")
	TEST_ASSERT_EQUAL(GLOB.gc_failure_cache.total_failures, start_total_failures + entry_count, "Global total_failures did not advance correctly")
	TEST_ASSERT(length(GLOB.gc_failure_cache.failures) <= GC_FAILURE_ENTRY_LIMIT, "Global retained history exceeded GC_FAILURE_ENTRY_LIMIT")

/datum/unit_test/gc_rewrite_failure_viewer_live_metadata
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_failure_viewer_live_metadata/Run()
	var/obj/effect/gc_rewrite_test_object/live = allocate(/obj/effect/gc_rewrite_test_object)
	live.hold_refs = list(live)
	SSgarbage.GetOrCreateItem(live.type)
	GLOB.gc_failure_cache.log_gc_failure(live, live.type, REF(live), world.time - 15, QDEL_HINT_QUEUE)

	var/datum/gc_failure_viewer/gc_failure_entry/entry = GLOB.gc_failure_cache.failures[1]
	TEST_ASSERT_EQUAL(entry.datum_ref, REF(live), "Live failure entries did not retain the datum ref")
	TEST_ASSERT_NOTNULL(entry.extra_info, "Live failure entries did not build the lightweight metadata")
	TEST_ASSERT_NOTNULL(entry.qdel_stats_info, "Live failure entries did not build qdel-item stats")

/datum/unit_test/gc_rewrite_hint_text
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_hint_text/Run()
	var/datum/gc_failure_viewer/gc_failure_entry/entry = new(null, /obj/effect/gc_rewrite_test_object, "test-ref", world.time - 10, QDEL_HINT_SOFTFAIL_ALERT)
	allocated += entry
	TEST_ASSERT(findtext(entry.qdel_hint_to_text(), "QDEL_HINT_SOFTFAIL_ALERT"), "QDEL_HINT_SOFTFAIL_ALERT was not rendered by qdel_hint_to_text()")
	entry.qdel_hint = QDEL_HINT_SLOWDESTROY
	TEST_ASSERT(findtext(entry.qdel_hint_to_text(), "QDEL_HINT_SLOWDESTROY"), "QDEL_HINT_SLOWDESTROY was not rendered by qdel_hint_to_text()")

#ifdef REFERENCE_TRACKING
/datum/unit_test/gc_rewrite_fast_reftrack_does_not_yield_gc_pass
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_fast_reftrack_does_not_yield_gc_pass/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9
	#ifdef UNIT_TESTS
	SSgarbage.test_ref_scan_skip_async = TRUE
	#endif

	var/start_totaldels = SSgarbage.totaldels
	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(/obj/effect/gc_rewrite_test_object)
	item.qdel_flags |= QDEL_ITEM_FAST_REFTRACK

	var/obj/effect/gc_rewrite_test_object/tracked = allocate(/obj/effect/gc_rewrite_test_object)
	tracked.destroy_hint = QDEL_HINT_QUEUE
	tracked.hold_refs = list(tracked)
	qdel(tracked)

	var/obj/effect/gc_rewrite_test_object/hard = allocate(/obj/effect/gc_rewrite_test_object)
	hard.destroy_hint = QDEL_HINT_HARDDEL
	hard.hold_refs = list(hard)
	qdel(hard)

	SSgarbage.state = SS_RUNNING
	SSgarbage.fire()

	TEST_ASSERT_EQUAL(SSgarbage.totaldels, start_totaldels + 1, "Type-wide FAST_REFTRACK still stalled unrelated harddelete processing")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL), 1, "The fast-reftracked datum was not promoted to warnfail")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_WARNFAIL, SSgarbage.queue_heads[GC_QUEUE_WARNFAIL]), tracked, "The warnfail queue did not retain the fast-reftracked datum")

/datum/unit_test/gc_rewrite_early_return_updates_metrics
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_early_return_updates_metrics/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 10000 HOURS
	Master.current_ticklimit = 1.0e9
	SSgarbage.queue_depth_sample_counter = GC_DEPTH_SAMPLE_INTERVAL - 1
	SSgarbage.leak_rate_fires = 59
	SSgarbage.leak_rate_fail_accumulator = 2
	#ifdef UNIT_TESTS
	SSgarbage.test_ref_scan_skip_async = TRUE
	#endif

	var/obj/effect/gc_rewrite_test_object/tracked = allocate(/obj/effect/gc_rewrite_test_object)
	tracked.destroy_hint = QDEL_HINT_IFFAIL_FINDREFERENCE
	tracked.hold_refs = list(tracked)
	qdel(tracked)

	SSgarbage.state = SS_RUNNING
	SSgarbage.fire()

	TEST_ASSERT_EQUAL(length(SSgarbage.queue_depth_history), 1, "Early-return fire() did not record a queue-depth sample")
	var/list/sample = SSgarbage.queue_depth_history[1]
	TEST_ASSERT_EQUAL(sample[GC_QUEUE_WARNFAIL + 1], 1, "Queue-depth sampling missed the warnfail promotion on early return")
	TEST_ASSERT_EQUAL(SSgarbage.leak_rate_fires, 0, "Early-return fire() did not flush the leak-rate counter window")
	TEST_ASSERT_EQUAL(SSgarbage.leak_rate_fail_accumulator, 0, "Early-return fire() did not reset the leak-rate accumulator")
	TEST_ASSERT(abs(SSgarbage.leak_rate_avg - 0.6) <= 0.001, "Early-return fire() did not update the leak-rate EMA")

/datum/unit_test/gc_rewrite_iffail_findreference_yields_gc_pass
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_iffail_findreference_yields_gc_pass/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 0
	Master.current_ticklimit = 1.0e9
	#ifdef UNIT_TESTS
	SSgarbage.test_ref_scan_skip_async = TRUE
	#endif

	var/start_totaldels = SSgarbage.totaldels

	var/obj/effect/gc_rewrite_test_object/tracked = allocate(/obj/effect/gc_rewrite_test_object)
	tracked.destroy_hint = QDEL_HINT_IFFAIL_FINDREFERENCE
	tracked.hold_refs = list(tracked)
	qdel(tracked)

	var/obj/effect/gc_rewrite_test_object/hard = allocate(/obj/effect/gc_rewrite_test_object)
	hard.destroy_hint = QDEL_HINT_HARDDEL
	hard.hold_refs = list(hard)
	qdel(hard)

	SSgarbage.state = SS_RUNNING
	SSgarbage.fire()

	TEST_ASSERT_EQUAL(SSgarbage.totaldels, start_totaldels, "The GC pass continued into hard deletes after scheduling a ref scan")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL), 1, "The tracked datum was not promoted to warnfail before the GC pass yielded")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_WARNFAIL, SSgarbage.queue_heads[GC_QUEUE_WARNFAIL]), tracked, "The warnfail queue did not retain the tracked datum")
	TEST_ASSERT_NULL(SSgarbage.reference_find_on_fail[REF(tracked)], "The iffail reference-tracking flag was not cleared after scheduling the scan")
#endif

/datum/unit_test/gc_rewrite_gas_mixture_soft_gc
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_gas_mixture_soft_gc/Run()
	configure_immediate_gc()
	var/start_totaldels = SSgarbage.totaldels
	var/start_totalgcs = SSgarbage.totalgcs

	var/datum/gas_mixture/test_mix = new
	test_mix.set_moles(GAS_O2, 20)
	test_mix.set_temperature(293.15)

	qdel(test_mix)
	test_mix = null

	run_gc_fire_cycles(2)

	TEST_ASSERT(SSgarbage.totalgcs > start_totalgcs, "gas_mixture was not soft-GC'd after __gasmixture_unregister()")
	TEST_ASSERT_EQUAL(SSgarbage.totaldels, start_totaldels, "gas_mixture required a hard delete despite __gasmixture_unregister()")
	assert_no_gc_failures(/datum/gas_mixture, "gas_mixture soft-GC")
	TEST_ASSERT_EQUAL(GLOB.gc_failure_cache.total_failures, 0, "gas_mixture unexpectedly created GC failure-viewer entries")

// ===== QDEL_HINT_QUEUE_THEN_HARDDEL tests =====

/// Verify that QUEUE_THEN_HARDDEL objects that have no remaining references are soft-GC'd normally.
/// Uses gas_mixture (a pure /datum) because /obj atoms retain internal BYOND refs that prevent soft GC in unit tests.
/datum/unit_test/gc_rewrite_queue_then_harddel_soft_gc_success
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_queue_then_harddel_soft_gc_success/Run()
	configure_immediate_gc()
	var/start_totaldels = SSgarbage.totaldels
	var/start_totalgcs = SSgarbage.totalgcs

	var/datum/gas_mixture/test_mix = new
	test_mix.set_moles(GAS_O2, 20)
	test_mix.set_temperature(293.15)

	qdel(test_mix)
	test_mix = null

	run_gc_fire_cycles(2)

	TEST_ASSERT(SSgarbage.totalgcs > start_totalgcs, "QUEUE_THEN_HARDDEL gas_mixture was not soft-GC'd when no refs remained")
	TEST_ASSERT_EQUAL(SSgarbage.totaldels, start_totaldels, "QUEUE_THEN_HARDDEL gas_mixture was hard-deleted despite no remaining refs")
	assert_no_gc_failures(/datum/gas_mixture, "QUEUE_THEN_HARDDEL soft-GC")
	TEST_ASSERT_EQUAL(GLOB.gc_failure_cache.total_failures, 0, "QUEUE_THEN_HARDDEL soft-GC unexpectedly created failure-viewer entries")

/// Verify that QUEUE_THEN_HARDDEL skips the warnfail stage entirely on softcheck failure.
/datum/unit_test/gc_rewrite_queue_then_harddel_skips_warnfail
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_queue_then_harddel_skips_warnfail/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 10000 HOURS
	Master.current_ticklimit = 1.0e9

	var/obj/effect/gc_rewrite_test_object/leaker = allocate(/obj/effect/gc_rewrite_test_object)
	leaker.destroy_hint = QDEL_HINT_QUEUE_THEN_HARDDEL
	leaker.hold_refs = list(leaker)
	qdel(leaker)

	run_gc_fire_cycles(2)

	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(/obj/effect/gc_rewrite_test_object)
	TEST_ASSERT_EQUAL(item.failures, 1, "QUEUE_THEN_HARDDEL softcheck miss was not counted")
	TEST_ASSERT_EQUAL(item.warnfail_count, 0, "QUEUE_THEN_HARDDEL incorrectly incremented warnfail_count")
	TEST_ASSERT_EQUAL(GLOB.gc_failure_cache.total_failures, 0, "QUEUE_THEN_HARDDEL created failure-viewer entries despite skipping warnfail")
	TEST_ASSERT_EQUAL(length(SSgarbage.recent_failures), 1, "QUEUE_THEN_HARDDEL recorded more than one recent failure event")
	TEST_ASSERT_EQUAL(SSgarbage.recent_failures[1][3], GC_QUEUE_SOFTCHECK, "QUEUE_THEN_HARDDEL recent failure was not softcheck")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL), 0, "QUEUE_THEN_HARDDEL object was placed in the warnfail queue")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 1, "QUEUE_THEN_HARDDEL object was not promoted to the harddelete queue")
	var/hd_head = SSgarbage.queue_heads[GC_QUEUE_HARDDELETE]
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_HARDDELETE, hd_head), leaker, "The harddelete queue did not contain the QUEUE_THEN_HARDDEL leaker")

/// Full lifecycle: QUEUE_THEN_HARDDEL → softcheck fail → Q3 → hard delete. Warnfail never touched.
/datum/unit_test/gc_rewrite_queue_then_harddel_eventual_harddel
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_queue_then_harddel_eventual_harddel/Run()
	configure_immediate_gc()
	var/start_totaldels = SSgarbage.totaldels

	var/obj/effect/gc_rewrite_test_object/leaker = allocate(/obj/effect/gc_rewrite_test_object)
	leaker.destroy_hint = QDEL_HINT_QUEUE_THEN_HARDDEL
	leaker.hold_refs = list(leaker)
	qdel(leaker)

	run_gc_fire_cycles(3)

	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(/obj/effect/gc_rewrite_test_object)
	TEST_ASSERT_EQUAL(SSgarbage.totaldels, start_totaldels + 1, "QUEUE_THEN_HARDDEL leaker was not hard-deleted after reaching Q3")
	TEST_ASSERT_EQUAL(item.warnfail_count, 0, "QUEUE_THEN_HARDDEL full lifecycle incorrectly touched warnfail")
	TEST_ASSERT_EQUAL(GLOB.gc_failure_cache.total_failures, 0, "QUEUE_THEN_HARDDEL full lifecycle created failure-viewer entries")
	TEST_ASSERT_EQUAL(length(SSgarbage.recent_hard_deletes), 1, "QUEUE_THEN_HARDDEL hard delete was not recorded in recent_hard_deletes")

/// Verify origin_time is preserved through Q1→Q3 promotion (skipping Q2).
/datum/unit_test/gc_rewrite_queue_then_harddel_preserves_origin_time
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_queue_then_harddel_preserves_origin_time/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 10000 HOURS
	Master.current_ticklimit = 1.0e9

	var/obj/effect/gc_rewrite_test_object/leaker = allocate(/obj/effect/gc_rewrite_test_object)
	leaker.destroy_hint = QDEL_HINT_QUEUE_THEN_HARDDEL
	leaker.hold_refs = list(leaker)
	qdel(leaker)
	var/origin_time = leaker.gc_destroyed

	run_gc_fire_cycles(2)

	var/hd_head = SSgarbage.queue_heads[GC_QUEUE_HARDDELETE]
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 1, "QUEUE_THEN_HARDDEL leaker was not promoted to harddelete queue")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_HARDDELETE, hd_head), leaker, "Harddelete queue did not contain the expected leaker")
	TEST_ASSERT_EQUAL(SSgarbage.queue_origin_times[GC_QUEUE_HARDDELETE][hd_head], origin_time, "QUEUE_THEN_HARDDEL Q1→Q3 promotion lost the original qdel timestamp")

/// Compare routing: QUEUE goes to Q2, QUEUE_THEN_HARDDEL goes directly to Q3.
/datum/unit_test/gc_rewrite_queue_then_harddel_vs_queue_comparison
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_queue_then_harddel_vs_queue_comparison/Run()
	// Part A: Standard QUEUE hint → softcheck fail → enters Q2 (warnfail)
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 10000 HOURS
	Master.current_ticklimit = 1.0e9

	var/obj/effect/gc_rewrite_test_object/queue_leaker = allocate(/obj/effect/gc_rewrite_test_object)
	queue_leaker.destroy_hint = QDEL_HINT_QUEUE
	queue_leaker.hold_refs = list(queue_leaker)
	qdel(queue_leaker)

	run_gc_fire_cycles(2)

	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL), 1, "Standard QUEUE leaker did not enter warnfail queue")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 0, "Standard QUEUE leaker prematurely entered harddelete queue")

	// Part B: QUEUE_THEN_HARDDEL hint → softcheck fail → skips Q2, enters Q3
	reset_gc_queues()
	SSgarbage.items = list()
	SSgarbage.recent_failures = list()

	var/obj/effect/gc_rewrite_test_object/qthd_leaker = allocate(/obj/effect/gc_rewrite_test_object)
	qthd_leaker.destroy_hint = QDEL_HINT_QUEUE_THEN_HARDDEL
	qthd_leaker.hold_refs = list(qthd_leaker)
	qdel(qthd_leaker)

	run_gc_fire_cycles(2)

	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL), 0, "QUEUE_THEN_HARDDEL leaker incorrectly entered warnfail queue")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 1, "QUEUE_THEN_HARDDEL leaker did not enter harddelete queue")

/// Multiple QUEUE_THEN_HARDDEL objects in a single fire cycle all skip warnfail.
/datum/unit_test/gc_rewrite_queue_then_harddel_multiple_objects
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_queue_then_harddel_multiple_objects/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 10000 HOURS
	Master.current_ticklimit = 1.0e9

	var/obj/effect/gc_rewrite_test_object/leaker_a = allocate(/obj/effect/gc_rewrite_test_object)
	leaker_a.destroy_hint = QDEL_HINT_QUEUE_THEN_HARDDEL
	leaker_a.hold_refs = list(leaker_a)
	var/obj/effect/gc_rewrite_test_object/leaker_b = allocate(/obj/effect/gc_rewrite_test_object)
	leaker_b.destroy_hint = QDEL_HINT_QUEUE_THEN_HARDDEL
	leaker_b.hold_refs = list(leaker_b)
	var/obj/effect/gc_rewrite_test_object/leaker_c = allocate(/obj/effect/gc_rewrite_test_object)
	leaker_c.destroy_hint = QDEL_HINT_QUEUE_THEN_HARDDEL
	leaker_c.hold_refs = list(leaker_c)

	qdel(leaker_a)
	qdel(leaker_b)
	qdel(leaker_c)

	run_gc_fire_cycles(2)

	var/datum/qdel_item/item = SSgarbage.GetOrCreateItem(/obj/effect/gc_rewrite_test_object)
	TEST_ASSERT_EQUAL(item.failures, 3, "Not all 3 QUEUE_THEN_HARDDEL softcheck misses were counted")
	TEST_ASSERT_EQUAL(item.warnfail_count, 0, "Multiple QUEUE_THEN_HARDDEL objects incorrectly touched warnfail")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL), 0, "Multiple QUEUE_THEN_HARDDEL objects were placed in warnfail queue")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 3, "Not all 3 QUEUE_THEN_HARDDEL objects were promoted to harddelete queue")
	TEST_ASSERT_EQUAL(GLOB.gc_failure_cache.total_failures, 0, "Multiple QUEUE_THEN_HARDDEL failures created failure-viewer entries")

/// Mixed QUEUE and QUEUE_THEN_HARDDEL objects route to the correct queues.
/datum/unit_test/gc_rewrite_queue_then_harddel_mixed_with_queue
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_queue_then_harddel_mixed_with_queue/Run()
	reset_gc_queues()
	SSgarbage.collection_timeout[GC_QUEUE_SOFTCHECK] = 0
	SSgarbage.collection_timeout[GC_QUEUE_WARNFAIL] = 10000 HOURS
	SSgarbage.collection_timeout[GC_QUEUE_HARDDELETE] = 10000 HOURS
	Master.current_ticklimit = 1.0e9

	var/obj/effect/gc_rewrite_test_object/queue_leaker = allocate(/obj/effect/gc_rewrite_test_object)
	queue_leaker.destroy_hint = QDEL_HINT_QUEUE
	queue_leaker.hold_refs = list(queue_leaker)

	var/obj/effect/gc_rewrite_test_object/qthd_leaker = allocate(/obj/effect/gc_rewrite_test_object)
	qthd_leaker.destroy_hint = QDEL_HINT_QUEUE_THEN_HARDDEL
	qthd_leaker.hold_refs = list(qthd_leaker)

	qdel(queue_leaker)
	qdel(qthd_leaker)

	run_gc_fire_cycles(2)

	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_WARNFAIL), 1, "Mixed test: QUEUE leaker did not enter warnfail queue")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueueDepth(GC_QUEUE_HARDDELETE), 1, "Mixed test: QUEUE_THEN_HARDDEL leaker did not enter harddelete queue")
	var/wf_head = SSgarbage.queue_heads[GC_QUEUE_WARNFAIL]
	var/hd_head = SSgarbage.queue_heads[GC_QUEUE_HARDDELETE]
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_WARNFAIL, wf_head), queue_leaker, "Warnfail queue contained the wrong object")
	TEST_ASSERT_EQUAL(SSgarbage.GetQueuedDatum(GC_QUEUE_HARDDELETE, hd_head), qthd_leaker, "Harddelete queue contained the wrong object")

/// Verify qdel_hint_to_text() renders QDEL_HINT_QUEUE_THEN_HARDDEL correctly.
/datum/unit_test/gc_rewrite_queue_then_harddel_hint_text
	parent_type = /datum/unit_test/gc_rewrite_base

/datum/unit_test/gc_rewrite_queue_then_harddel_hint_text/Run()
	var/datum/gc_failure_viewer/gc_failure_entry/entry = new(null, /obj/effect/gc_rewrite_test_object, "test-ref", world.time - 10, QDEL_HINT_QUEUE_THEN_HARDDEL)
	allocated += entry
	TEST_ASSERT(findtext(entry.qdel_hint_to_text(), "QDEL_HINT_QUEUE_THEN_HARDDEL"), "QDEL_HINT_QUEUE_THEN_HARDDEL was not rendered by qdel_hint_to_text()")
