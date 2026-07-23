// ===== update_icon() UPDATE_OVERLAYS short-circuit =====
//
// Profile snapshot (perf.log 2026-07): /atom/proc/update_appearance - 705k calls,
// 11.7s total CPU per round; the UPDATE_OVERLAYS branch unconditionally did
// cut_overlay(managed_overlays) + add_overlay(new_overlays) even when the
// rebuilt overlay set was identical to the current one (the common case for
// periodic update_appearance callers: smoothing, windows, machines).
//
// The port (from /tg/) normalizes update_overlays() output to appearances,
// compares against managed_overlays and skips the overlays churn entirely when
// nothing changed. BYOND interns appearances (identical appearance == same
// instance), which is what makes the equality compare valid.
//
// Unlike /tg/, string entries are normalized via iconstate2appearance() in the
// same pre-pass (tg leaves them as text, so string-overlay atoms never
// short-circuit there - build_appearance_list converts them in place at
// add_overlay time and the next compare always mismatches).

/// Fixture: an atom whose update_overlays() output is fully scripted.
/obj/update_icon_short_circuit_fixture
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "flagpole"
	/// Script for update_overlays: list of entries (strings and/or MAs are built per call)
	var/list/scripted_states
	/// Counts update_overlays invocations
	var/update_overlays_calls = 0
	/// When TRUE, each scripted string state is returned as a fresh mutable_appearance instead
	var/return_mutable_appearances = FALSE

/obj/update_icon_short_circuit_fixture/update_overlays()
	. = ..()
	update_overlays_calls++
	for(var/state in scripted_states)
		if(return_mutable_appearances)
			. += mutable_appearance(icon, state)
		else
			. += state

/datum/unit_test/update_icon_overlay_correctness/Run()
	var/obj/update_icon_short_circuit_fixture/fixture = allocate(/obj/update_icon_short_circuit_fixture)

	// Multi-overlay set applies
	fixture.scripted_states = list("light_on", "light_bulb")
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 2, "Both scripted overlays must be applied")
	TEST_ASSERT(islist(fixture.managed_overlays), "Two managed overlays must be stored as a list")
	TEST_ASSERT_EQUAL(length(fixture.managed_overlays), 2, "managed_overlays must track both entries")

	// Repeat with identical output: still exactly 2 overlays, no dupes/loss
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 2, "Identical rebuild must leave overlays unchanged")

	// Shrink to a single overlay
	fixture.scripted_states = list("light_on")
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 1, "Shrinking the set must drop the removed overlay")
	TEST_ASSERT(!islist(fixture.managed_overlays), "A single managed overlay must be stored bare, not in a list")

	// Empty set clears managed overlays
	fixture.scripted_states = list()
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 0, "Empty rebuild must clear managed overlays")
	TEST_ASSERT_NULL(fixture.managed_overlays, "managed_overlays must be null after an empty rebuild")

	// External (unmanaged) overlays survive managed churn
	var/mutable_appearance/external = mutable_appearance(fixture.icon, "light_bulb_broken")
	fixture.add_overlay(external)
	fixture.scripted_states = list("light_on", "light_bulb")
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 3, "External overlay must survive a managed rebuild")
	fixture.scripted_states = list("light_bulb")
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 2, "External overlay must survive managed shrink")
	fixture.cut_overlay(external)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 1, "Cutting the external overlay must leave only the managed one")

	// Null entries in update_overlays output are dropped quietly
	fixture.scripted_states = list("light_on", null, "light_bulb")
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 2, "Null entries must be dropped from the rebuilt set")

/// Fixture: mimics legacy update_overlays() overrides that call ..() bare (no
/// `. = ..()`) and then `. += "state"`, returning a bare string instead of a list.
/obj/update_icon_short_circuit_fixture/legacy_string_return

/obj/update_icon_short_circuit_fixture/legacy_string_return/update_overlays()
	..()
	. += "light_on"

// Regression: the normalization pre-pass used to index-write into the returned
// value, which runtimes on a non-list ("cannot write to indexed value in this
// type of list") - seen live on every pumpaction/decloner energy gun.
/datum/unit_test/update_icon_nonlist_overlays/Run()
	var/obj/update_icon_short_circuit_fixture/legacy_string_return/fixture = allocate(/obj/update_icon_short_circuit_fixture/legacy_string_return)
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 1, "A bare string return from update_overlays() must still apply as one overlay")
	TEST_ASSERT_NOTNULL(fixture.managed_overlays, "managed_overlays must be tracked for a bare string return")
	TEST_ASSERT(!islist(fixture.managed_overlays), "A single overlay from a bare string return must be stored bare, not in a list")

	// Second identical rebuild must stay stable (and short-circuit like any other single overlay)
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(length(fixture.overlays), 1, "Repeat rebuild from a bare string return must not duplicate or drop the overlay")

#define SHORT_CIRCUIT_BENCH_ITERATIONS 20000

/datum/unit_test/update_icon_short_circuit/Run()
	var/obj/update_icon_short_circuit_fixture/fixture = allocate(/obj/update_icon_short_circuit_fixture)
	fixture.return_mutable_appearances = TRUE
	fixture.scripted_states = list("light_on", "light_bulb", "light_bulb_broken")
	fixture.update_appearance(UPDATE_OVERLAYS)

	// --- Benchmark: identical rebuilds (short-circuit path) ---
	var/start = REALTIMEOFDAY
	for(var/i in 1 to SHORT_CIRCUIT_BENCH_ITERATIONS)
		fixture.update_appearance(UPDATE_OVERLAYS)
	var/unchanged_ds = REALTIMEOFDAY - start

	// --- Benchmark: alternating rebuilds (forced churn ~= pre-fix cost) ---
	var/list/set_a = list("light_on", "light_bulb", "light_bulb_broken")
	var/list/set_b = list("light_on", "light_bulb")
	start = REALTIMEOFDAY
	for(var/i in 1 to SHORT_CIRCUIT_BENCH_ITERATIONS)
		fixture.scripted_states = (i % 2) ? set_a : set_b
		fixture.update_appearance(UPDATE_OVERLAYS)
	var/churn_ds = REALTIMEOFDAY - start

	log_world("### UPDATE_ICON BENCH: [SHORT_CIRCUIT_BENCH_ITERATIONS] unchanged rebuilds = [unchanged_ds] ds; alternating rebuilds = [churn_ds] ds")

	// --- Behavioral proof of the short-circuit ---
	// When the rebuilt set is identical, managed_overlays must keep the OLD list
	// instance (the fresh new_overlays list is discarded without touching state).
	fixture.scripted_states = set_a
	fixture.update_appearance(UPDATE_OVERLAYS)
	var/ref_before = "\ref[fixture.managed_overlays]"
	var/calls_before = fixture.update_overlays_calls
	fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL(fixture.update_overlays_calls, calls_before + 1, "update_overlays must still be invoked on every update")
	TEST_ASSERT_EQUAL("\ref[fixture.managed_overlays]", ref_before, "Identical rebuild must not replace managed_overlays (short-circuit)")

	// Strings must short-circuit too (our improvement over the tg port):
	// normalization happens in the pre-pass, so a scripted string set compares
	// equal against the stored appearances on the second pass.
	var/obj/update_icon_short_circuit_fixture/string_fixture = allocate(/obj/update_icon_short_circuit_fixture)
	string_fixture.scripted_states = list("light_on", "light_bulb")
	string_fixture.update_appearance(UPDATE_OVERLAYS)
	var/string_ref_before = "\ref[string_fixture.managed_overlays]"
	string_fixture.update_appearance(UPDATE_OVERLAYS)
	TEST_ASSERT_EQUAL("\ref[string_fixture.managed_overlays]", string_ref_before, "Identical string-overlay rebuild must short-circuit as well")

#undef SHORT_CIRCUIT_BENCH_ITERATIONS
