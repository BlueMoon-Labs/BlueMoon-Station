/// Counts the real production update_icon calls made by adjust_clockwork_power.
/obj/effect/clockwork/sigil/transmission/power_update_test
	var/power_visual_updates = 0

/obj/effect/clockwork/sigil/transmission/power_update_test/update_icon()
	power_visual_updates++
	return ..()

/// Profile-shaped benchmark: clock generators add small amounts of power many
/// times per second, while a group of transmission sigils observes the shared
/// power pool. Timings are logged for explicit before/after comparison.
/datum/unit_test/clockwork_power_small_adjustment_bench
	priority = TEST_LONGER

/datum/unit_test/clockwork_power_small_adjustment_bench/proc/forced_redraw_adjustment(amount)
	GLOB.clockwork_power = clamp(GLOB.clockwork_power + amount, 0, MAX_CLOCKWORK_POWER)
	for(var/obj/effect/clockwork/sigil/transmission/sigil in GLOB.all_clockwork_objects)
		sigil.update_icon()

/datum/unit_test/clockwork_power_small_adjustment_bench/Run()
	var/old_power = GLOB.clockwork_power
	var/old_ratvar_approaches = GLOB.ratvar_approaches
	var/old_ratvar_awakens = GLOB.ratvar_awakens
	GLOB.clockwork_power = 0
	GLOB.ratvar_approaches = FALSE
	GLOB.ratvar_awakens = FALSE

	var/list/obj/effect/clockwork/sigil/transmission/power_update_test/sigils = list()
	for(var/i in 1 to 16)
		var/obj/effect/clockwork/sigil/transmission/power_update_test/sigil = allocate(/obj/effect/clockwork/sigil/transmission/power_update_test)
		sigil.power_visual_updates = 0
		sigils += sigil

	var/iterations = 2000
	var/start = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		forced_redraw_adjustment(0.1)
	var/forced_redraw_ms = TICK_USAGE_TO_MS(start)
	var/forced_visual_updates = 0
	for(var/obj/effect/clockwork/sigil/transmission/power_update_test/sigil as anything in sigils)
		forced_visual_updates += sigil.power_visual_updates
		sigil.power_visual_updates = 0

	GLOB.clockwork_power = 0
	start = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		adjust_clockwork_power(0.1)
	var/gated_redraw_ms = TICK_USAGE_TO_MS(start)
	var/gated_visual_updates = 0
	for(var/obj/effect/clockwork/sigil/transmission/power_update_test/sigil as anything in sigils)
		gated_visual_updates += sigil.power_visual_updates

	var/speedup = forced_redraw_ms / max(gated_redraw_ms, 0.001)
	log_world("PERF: clockwork power small adjustment x[iterations], [length(sigils)] sigils: forced redraw [round(forced_redraw_ms, 0.01)]ms/[forced_visual_updates] updates vs gated [round(gated_redraw_ms, 0.01)]ms/[gated_visual_updates] updates ([round(speedup, 0.1)]x)")
	TEST_ASSERT(abs(GLOB.clockwork_power - iterations * 0.1) < 0.01, "Small adjustments must all reach the shared power pool")
	TEST_ASSERT_EQUAL(forced_visual_updates, iterations * length(sigils), "The forced-redraw reference must exercise every sigil on every adjustment")
	TEST_ASSERT_EQUAL(gated_visual_updates, length(sigils), "Only the initial unpowered-to-powered transition may redraw transmission sigils")

	GLOB.clockwork_power = old_power
	GLOB.ratvar_approaches = old_ratvar_approaches
	GLOB.ratvar_awakens = old_ratvar_awakens
	for(var/obj/effect/clockwork/sigil/transmission/sigil in GLOB.all_clockwork_objects)
		sigil.update_icon()

/// Guards the visual equivalence premise behind the redraw elision, including
/// level transitions, clamping, the herald discount and Ratvar awakening.
/datum/unit_test/clockwork_power_visual_levels/Run()
	var/old_power = GLOB.clockwork_power
	var/old_ratvar_approaches = GLOB.ratvar_approaches
	var/old_ratvar_awakens = GLOB.ratvar_awakens
	var/old_script_unlocked = GLOB.script_scripture_unlocked
	var/old_application_unlocked = GLOB.application_scripture_unlocked
	var/old_servants_active = GLOB.servants_active
	GLOB.clockwork_power = 0
	GLOB.ratvar_approaches = FALSE
	GLOB.ratvar_awakens = FALSE
	GLOB.servants_active = FALSE

	var/obj/effect/clockwork/sigil/transmission/power_update_test/sigil = allocate(/obj/effect/clockwork/sigil/transmission/power_update_test)
	sigil.power_visual_updates = 0
	TEST_ASSERT_EQUAL(sigil.alpha, get_transmission_sigil_alpha(0), "A new sigil must reflect an empty power pool")
	TEST_ASSERT_EQUAL(sigil.light_range, 0, "An unpowered sigil must emit no light")

	adjust_clockwork_power(0.1)
	TEST_ASSERT_EQUAL(sigil.power_visual_updates, 1, "Powering an empty network must redraw even inside the same alpha level")
	TEST_ASSERT_EQUAL(sigil.alpha, get_transmission_sigil_alpha(GLOB.clockwork_power), "Power-on redraw must preserve the expected alpha")
	TEST_ASSERT(abs(sigil.light_range - sigil.alpha * 0.02) < 0.001, "Power-on redraw must enable the expected light range")
	TEST_ASSERT(abs(sigil.light_power - max(sigil.alpha * 0.01, 0.1)) < 0.001, "Power-on redraw must enable the expected light power")

	adjust_clockwork_power(1000)
	TEST_ASSERT_EQUAL(sigil.power_visual_updates, 2, "Crossing an alpha level must redraw once")
	TEST_ASSERT_EQUAL(sigil.alpha, get_transmission_sigil_alpha(GLOB.clockwork_power), "Level crossing must apply the expected alpha")

	adjust_clockwork_power(100)
	TEST_ASSERT_EQUAL(sigil.power_visual_updates, 2, "Adjustment inside the new level must not redraw again")

	adjust_clockwork_power(-1050)
	TEST_ASSERT_EQUAL(sigil.power_visual_updates, 3, "Crossing down an alpha level must redraw once")
	TEST_ASSERT_EQUAL(sigil.alpha, get_transmission_sigil_alpha(GLOB.clockwork_power), "Downward crossing must apply the expected alpha")

	adjust_clockwork_power(-MAX_CLOCKWORK_POWER)
	TEST_ASSERT_EQUAL(GLOB.clockwork_power, 0, "Power must still clamp at zero")
	TEST_ASSERT_EQUAL(sigil.power_visual_updates, 4, "Powering down must redraw even inside the same alpha level")
	TEST_ASSERT_EQUAL(sigil.light_range, 0, "Powering down must disable sigil light")

	GLOB.ratvar_approaches = TRUE
	adjust_clockwork_power(100)
	TEST_ASSERT_EQUAL(GLOB.clockwork_power, 75, "The herald discount must still apply before adding power")
	TEST_ASSERT_EQUAL(sigil.power_visual_updates, 5, "Powering up must redraw even when the discounted power stays in the same alpha level")
	TEST_ASSERT(sigil.light_range > 0, "Powering up with herald-discounted power must enable sigil light")

	GLOB.ratvar_approaches = FALSE
	GLOB.ratvar_awakens = TRUE
	adjust_clockwork_power(0)
	TEST_ASSERT_EQUAL(GLOB.clockwork_power, INFINITY, "Ratvar awakening must still make power infinite")
	TEST_ASSERT_EQUAL(sigil.alpha, 255, "Ratvar awakening must force maximum sigil alpha")
	TEST_ASSERT_EQUAL(sigil.power_visual_updates, 6, "Ratvar awakening must redraw a dim sigil exactly once")

	adjust_clockwork_power(1)
	TEST_ASSERT_EQUAL(sigil.power_visual_updates, 6, "Infinite power at maximum alpha must not redraw repeatedly")

	GLOB.clockwork_power = old_power
	GLOB.ratvar_approaches = old_ratvar_approaches
	GLOB.ratvar_awakens = old_ratvar_awakens
	GLOB.script_scripture_unlocked = old_script_unlocked
	GLOB.application_scripture_unlocked = old_application_unlocked
	GLOB.servants_active = old_servants_active
	for(var/obj/effect/clockwork/sigil/transmission/other_sigil in GLOB.all_clockwork_objects)
		other_sigil.update_icon()
