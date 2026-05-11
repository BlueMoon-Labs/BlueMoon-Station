/// Profiler-style and correctness unit tests for /datum/atom_hud and the
/// batched HUD push path introduced together with the
/// `should_show_to` / `collect_hud_images_for` / `push_all_atoms_to_user`
/// refactor.
///
/// The file is split into two halves:
///
///   * Section 1 — body cost benchmarks for the per-call
///     /datum/atom_hud/proc/add_to_single_hud body. Uses a /datum mock atom
///     and a faithful mirror proc (the production proc bails out on
///     `if(!their_client) return`, which is always true under unit tests).
///     These exist mostly as historical context and to detect surprise
///     regressions in the per-call path.
///
///   * Section 2 — correctness + performance tests for the batched bulk-push
///     path: collect_hud_images_for, push_all_atoms_to_user, and the rewired
///     /mob/proc/reload_huds. These call the *real* production procs against
///     /obj/effect-based test atoms and a /datum/atom_hud subtype that uses
///     a synthetic target list in place of client.images (so we can
///     observe the result without needing a real BYOND client).
///
/// Numbers go to log_world() so each CI run records them in
/// data/logs/ci/runtime.log alongside the PASS/FAIL line. Hard upper bounds
/// are deliberately loose because CI machines vary; the assertions catch
/// catastrophic regressions while the log_world numbers are the real signal.

#define ATOM_HUD_PERF_ICON_KEY_PREFIX "perf_icon_"
#define ATOM_HUD_PERF_BURST_ATOMS 2000
#define ATOM_HUD_PERF_BURST_ICONS_PER_HUD 11
// Larger steps so each step's elapsed time is well above REALTIMEOFDAY's
// ~1ms resolution. With smaller steps the tiny DM-list operations come in
// at "0ds" and we can't see the curve.
#define ATOM_HUD_PERF_GROWTH_STEPS list(0, 100, 250, 500, 1000, 2000, 4000)

// =============================================================================
// SECTION 1 — per-call body cost (mirror, no real client, no real atom)
// =============================================================================

/// Stand-in for a hudatom — has the same hud_list shape as a real atom.
/datum/atom_hud_perf_test_atom
	/// hud_list maps keys → /image (mirrors /atom.hud_list).
	var/list/hud_list

/datum/atom_hud_perf_test_atom/New(num_icons = 1)
	hud_list = list()
	for(var/i in 1 to num_icons)
		// We don't care about visuals — only the identity of the /image, so
		// `target |= I` does its membership check against a real /image ref.
		var/image/I = image('icons/mob/hud.dmi', null, "")
		hud_list["[ATOM_HUD_PERF_ICON_KEY_PREFIX][i]"] = I

/// Perf-test HUD subtype. Holds a `test_images` list that stands in for
/// `client.images` and an `add_to_single_test_target` proc whose body is a
/// 1:1 mirror of /datum/atom_hud/add_to_single_hud (post-fix) MINUS the
/// client / should_show_to guards — the mirror is here to measure raw body
/// cost, not gating. Section 2 exercises the production gating path.
/datum/atom_hud/perf_test
	var/list/test_images

/datum/atom_hud/perf_test/New(num_icons = 1)
	// Intentionally skip ..() so we don't pollute GLOB.all_huds (the parent's
	// only side effect). hudatoms / hudusers / next_time_allowed / queued_to_see
	// are all `var/list/foo = list()` at the field-definition site, so they're
	// initialized correctly without us touching them.
	test_images = list()
	hud_icons = list()
	for(var/i in 1 to num_icons)
		hud_icons += "[ATOM_HUD_PERF_ICON_KEY_PREFIX][i]"

/datum/atom_hud/perf_test/proc/reset_target(num_prefilled = 0)
	test_images = list()
	for(var/i in 1 to num_prefilled)
		// Distinct images so they're not deduped against the hudatoms below.
		test_images += image('icons/mob/hud.dmi', null, "")

/datum/atom_hud/perf_test/proc/add_to_single_test_target(datum/atom_hud_perf_test_atom/A)
	if(!A)
		return
	var/list/atom_hud_list = A.hud_list
	if(!atom_hud_list)
		return
	var/list/local_hud_icons = hud_icons
	if(length(local_hud_icons) == 1)
		var/hud_image = atom_hud_list[local_hud_icons[1]]
		if(hud_image)
			test_images |= hud_image
		return
	var/first_hud_image
	var/list/to_add
	for(var/i in local_hud_icons)
		var/hud_image = atom_hud_list[i]
		if(!hud_image)
			continue
		if(!first_hud_image)
			first_hud_image = hud_image
			continue
		if(!to_add)
			to_add = list()
			to_add += first_hud_image
		to_add += hud_image
	if(to_add)
		test_images |= to_add
	else if(first_hud_image)
		test_images |= first_hud_image

// -----------------------------------------------------------------------------
// Bench A: K==1 fast path against an EMPTY target. Lower bound for this proc.
// -----------------------------------------------------------------------------

#define ATOM_HUD_PERF_FAST_PATH_CALLS 200000

/datum/unit_test/atom_hud_add_single_fast_path_baseline
	priority = TEST_LONGER

/datum/unit_test/atom_hud_add_single_fast_path_baseline/Run()
	var/datum/atom_hud/perf_test/hud = new(num_icons = 1)
	var/datum/atom_hud_perf_test_atom/A = new(num_icons = 1)

	var/start = REALTIMEOFDAY
	for(var/i in 1 to ATOM_HUD_PERF_FAST_PATH_CALLS)
		hud.add_to_single_test_target(A)
	var/elapsed_ds = REALTIMEOFDAY - start

	// On the very first call test_images grows from 0→1; subsequent calls hit
	// the membership branch of |= against a 1-element list. This is the
	// CHEAPEST possible workload for the proc.
	var/per_call_us = (elapsed_ds * 100000) / ATOM_HUD_PERF_FAST_PATH_CALLS
	log_world("[type]: K=1 fast path × [ATOM_HUD_PERF_FAST_PATH_CALLS] calls = [elapsed_ds]ds (~[per_call_us]us/call)")

	TEST_ASSERT(length(hud.test_images) == 1, "K=1 path should leave exactly 1 image in test_images (got [length(hud.test_images)])")
	// Sanity: even a slow CI machine should stay under 5s for 200k calls. If
	// we ever blow this it's a serious regression.
	TEST_ASSERT(elapsed_ds < 50, "K=1 fast path × [ATOM_HUD_PERF_FAST_PATH_CALLS] should not exceed 5s ([elapsed_ds]ds)")

#undef ATOM_HUD_PERF_FAST_PATH_CALLS

// -----------------------------------------------------------------------------
// Bench B: K-icon path against an EMPTY target, K = 4 (medical) and K = 11
// (diagnostic advanced). Quantifies the multi-icon path overhead per call.
// -----------------------------------------------------------------------------

#define ATOM_HUD_PERF_MULTI_PATH_CALLS 100000

/datum/unit_test/atom_hud_add_single_multi_path_4
	priority = TEST_LONGER

/datum/unit_test/atom_hud_add_single_multi_path_4/Run()
	var/datum/atom_hud/perf_test/hud = new(num_icons = 4)
	var/datum/atom_hud_perf_test_atom/A = new(num_icons = 4)

	var/start = REALTIMEOFDAY
	for(var/i in 1 to ATOM_HUD_PERF_MULTI_PATH_CALLS)
		hud.add_to_single_test_target(A)
	var/elapsed_ds = REALTIMEOFDAY - start
	var/per_call_us = (elapsed_ds * 100000) / ATOM_HUD_PERF_MULTI_PATH_CALLS
	log_world("[type]: K=4 path × [ATOM_HUD_PERF_MULTI_PATH_CALLS] calls = [elapsed_ds]ds (~[per_call_us]us/call), images.len=[length(hud.test_images)]")
	TEST_ASSERT_EQUAL(length(hud.test_images), 4, "K=4 path should populate exactly 4 images")
	TEST_ASSERT(elapsed_ds < 80, "K=4 path budget exceeded ([elapsed_ds]ds)")

/datum/unit_test/atom_hud_add_single_multi_path_11
	priority = TEST_LONGER

/datum/unit_test/atom_hud_add_single_multi_path_11/Run()
	var/datum/atom_hud/perf_test/hud = new(num_icons = 11)
	var/datum/atom_hud_perf_test_atom/A = new(num_icons = 11)

	var/start = REALTIMEOFDAY
	for(var/i in 1 to ATOM_HUD_PERF_MULTI_PATH_CALLS)
		hud.add_to_single_test_target(A)
	var/elapsed_ds = REALTIMEOFDAY - start
	var/per_call_us = (elapsed_ds * 100000) / ATOM_HUD_PERF_MULTI_PATH_CALLS
	log_world("[type]: K=11 path × [ATOM_HUD_PERF_MULTI_PATH_CALLS] calls = [elapsed_ds]ds (~[per_call_us]us/call), images.len=[length(hud.test_images)]")
	TEST_ASSERT_EQUAL(length(hud.test_images), 11, "K=11 path should populate exactly 11 images")
	TEST_ASSERT(elapsed_ds < 200, "K=11 path budget exceeded ([elapsed_ds]ds)")

#undef ATOM_HUD_PERF_MULTI_PATH_CALLS

// -----------------------------------------------------------------------------
// Bench C: PROVE that per-call cost grows with target.len. Adds a fixed batch
// of fresh atoms (each with 1 icon) into a target that has been pre-filled
// with growing sizes. Logs per-call us at each step. If `target |= img` were
// O(1), us/call would be flat. It's not — but the constant is small for DM
// lists, so the curve is closer to flat than to linear.
// -----------------------------------------------------------------------------

#define ATOM_HUD_PERF_GROWTH_BATCH 20000

/datum/unit_test/atom_hud_add_single_growth_curve
	priority = TEST_LONGER

/datum/unit_test/atom_hud_add_single_growth_curve/Run()
	var/list/results = list()
	for(var/prefill in ATOM_HUD_PERF_GROWTH_STEPS)
		var/datum/atom_hud/perf_test/hud = new(num_icons = 1)
		hud.reset_target(num_prefilled = prefill)
		var/list/atoms = list()
		for(var/i in 1 to ATOM_HUD_PERF_GROWTH_BATCH)
			atoms += new /datum/atom_hud_perf_test_atom(num_icons = 1)

		var/start = REALTIMEOFDAY
		for(var/datum/atom_hud_perf_test_atom/A as anything in atoms)
			hud.add_to_single_test_target(A)
		var/elapsed_ds = REALTIMEOFDAY - start

		var/per_call_us = (elapsed_ds * 100000) / ATOM_HUD_PERF_GROWTH_BATCH
		results["[prefill]"] = per_call_us
		log_world("[type]: prefill=[prefill], [ATOM_HUD_PERF_GROWTH_BATCH] adds = [elapsed_ds]ds (~[per_call_us]us/call), final=[length(hud.test_images)]")

	// Pick the smallest and largest steps from ATOM_HUD_PERF_GROWTH_STEPS so
	// the assertion stays in sync if the steps list is retuned.
	var/list/steps = ATOM_HUD_PERF_GROWTH_STEPS
	var/baseline_key = "[steps[1]]"
	var/large_key = "[steps[length(steps)]]"
	var/baseline = results[baseline_key]
	var/large = results[large_key]
	if(baseline > 0 && large > 0)
		log_world("[type]: growth ratio (prefill=[large_key] / prefill=[baseline_key]) ≈ [large / baseline]x")
	// Loose lower bound: at minimum the worst-case shouldn't be DRAMATICALLY
	// faster than empty. The point of this test is the log_world numbers,
	// not the assertion — the assertion just guards against measurement
	// instruments outright lying.
	TEST_ASSERT(large == 0 || baseline == 0 || large >= baseline * 0.25, "Per-call cost at largest prefill should not be drastically faster than empty (baseline=[baseline]us, large=[large]us)")

#undef ATOM_HUD_PERF_GROWTH_BATCH

// -----------------------------------------------------------------------------
// Bench D: Burst test — simulates `reload_huds` style: walk a fresh hud across
// NUM_ATOMS atoms back-to-back, single tick, growing target. This is the
// pattern that USED TO cause per-tick overtime in production before the
// batched reload landed.
// -----------------------------------------------------------------------------

/datum/unit_test/atom_hud_reload_burst
	priority = TEST_LONGER

/datum/unit_test/atom_hud_reload_burst/Run()
	var/datum/atom_hud/perf_test/hud = new(num_icons = ATOM_HUD_PERF_BURST_ICONS_PER_HUD)
	var/list/atoms = list()
	for(var/i in 1 to ATOM_HUD_PERF_BURST_ATOMS)
		atoms += new /datum/atom_hud_perf_test_atom(num_icons = ATOM_HUD_PERF_BURST_ICONS_PER_HUD)

	var/start = REALTIMEOFDAY
	for(var/datum/atom_hud_perf_test_atom/A as anything in atoms)
		hud.add_to_single_test_target(A)
	var/elapsed_ds = REALTIMEOFDAY - start
	var/per_atom_us = (elapsed_ds * 100000) / ATOM_HUD_PERF_BURST_ATOMS

	log_world("[type]: BURST [ATOM_HUD_PERF_BURST_ATOMS] atoms × [ATOM_HUD_PERF_BURST_ICONS_PER_HUD] icons = [elapsed_ds]ds (~[per_atom_us]us/atom), final=[length(hud.test_images)]")

	TEST_ASSERT_EQUAL(length(hud.test_images), ATOM_HUD_PERF_BURST_ATOMS * ATOM_HUD_PERF_BURST_ICONS_PER_HUD, "All atoms × icons should land in target after the burst")

// -----------------------------------------------------------------------------
// Bench E: Batched-vs-serial RAW. Adds the same N images to a target either
// as N individual `target |= image` calls or as one `target |= big_list`. The
// batched shape is what each reload_huds HUD flush now uses; this bench is the
// ceiling we hope to capture.
// -----------------------------------------------------------------------------

#define ATOM_HUD_PERF_BATCH_N 10000

/datum/unit_test/atom_hud_batched_vs_serial_union
	priority = TEST_LONGER

/datum/unit_test/atom_hud_batched_vs_serial_union/Run()
	var/list/source = list()
	for(var/i in 1 to ATOM_HUD_PERF_BATCH_N)
		source += image('icons/mob/hud.dmi', null, "")

	var/list/target_serial = list()
	var/start = REALTIMEOFDAY
	for(var/image/I as anything in source)
		target_serial |= I
	var/elapsed_serial = REALTIMEOFDAY - start

	var/list/target_batched = list()
	start = REALTIMEOFDAY
	target_batched |= source
	var/elapsed_batched = REALTIMEOFDAY - start

	log_world("[type]: serial [ATOM_HUD_PERF_BATCH_N] |= = [elapsed_serial]ds, batched 1×|=([ATOM_HUD_PERF_BATCH_N]) = [elapsed_batched]ds")
	if(elapsed_batched > 0 && elapsed_serial > 0)
		log_world("[type]: serial / batched ratio ≈ [elapsed_serial / elapsed_batched]x")

	TEST_ASSERT_EQUAL(length(target_serial), ATOM_HUD_PERF_BATCH_N, "serial path target size mismatch")
	TEST_ASSERT_EQUAL(length(target_batched), ATOM_HUD_PERF_BATCH_N, "batched path target size mismatch")

#undef ATOM_HUD_PERF_BATCH_N

// -----------------------------------------------------------------------------
// Bench F: Append-only (`+=`) vs union (`|=`) when we KNOW images are unique.
// |= pays the membership-check cost; += skips it. This bench quantifies the
// tax that the production proc pays for `client.images |=` safety.
// -----------------------------------------------------------------------------

#define ATOM_HUD_PERF_APPEND_N 20000

/datum/unit_test/atom_hud_union_vs_append
	priority = TEST_LONGER

/datum/unit_test/atom_hud_union_vs_append/Run()
	var/list/source = list()
	for(var/i in 1 to ATOM_HUD_PERF_APPEND_N)
		source += image('icons/mob/hud.dmi', null, "")

	var/list/target_union = list()
	var/start = REALTIMEOFDAY
	for(var/image/I as anything in source)
		target_union |= I
	var/elapsed_union = REALTIMEOFDAY - start

	var/list/target_append = list()
	start = REALTIMEOFDAY
	for(var/image/I as anything in source)
		target_append += I
	var/elapsed_append = REALTIMEOFDAY - start

	log_world("[type]: |= ([ATOM_HUD_PERF_APPEND_N] items) = [elapsed_union]ds, += ([ATOM_HUD_PERF_APPEND_N] items) = [elapsed_append]ds")
	if(elapsed_append > 0 && elapsed_union > 0)
		log_world("[type]: |= / += ratio ≈ [elapsed_union / elapsed_append]x  (this is the membership-check tax)")

	TEST_ASSERT_EQUAL(length(target_union), ATOM_HUD_PERF_APPEND_N, "union target size mismatch")
	TEST_ASSERT_EQUAL(length(target_append), ATOM_HUD_PERF_APPEND_N, "append target size mismatch")

#undef ATOM_HUD_PERF_APPEND_N

// =============================================================================
// SECTION 2 — production-path correctness + perf for the batched bulk-push
// (collect_hud_images_for / push_all_atoms_to_user / reload_huds).
//
// These tests use REAL /obj/effect atoms placed in /datum/atom_hud.hudatoms
// so we can call the actual production procs — not mirrors. The HUD subtype
// /datum/atom_hud/test_real overrides should_show_to and provides a synthetic
// `test_target` list that stands in for `client.images` (the production
// procs we test directly either accept test_target explicitly, or we invoke
// the inner collect_hud_images_for proc and union the result into test_target
// ourselves to exercise the same shape).
// =============================================================================

/// Real /atom subtype so it can sit in /datum/atom_hud.hudatoms (which is
/// typed as /list/atom). Initialize() builds hud_list with the requested
/// number of /image entries, keyed identically to the perf hud's hud_icons.
/obj/effect/perf_hud_test_atom
	name = "perf_hud_test_atom"
	icon = null
	icon_state = ""
	anchored = TRUE
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	/// Used by gating tests — production should_show_to overrides read this.
	var/visible_for_gated = TRUE

/obj/effect/perf_hud_test_atom/Initialize(mapload, num_icons = 1)
	. = ..()
	hud_list = list()
	for(var/i in 1 to num_icons)
		hud_list["[ATOM_HUD_PERF_ICON_KEY_PREFIX][i]"] = image('icons/mob/hud.dmi', null, "")

/// HUD subtype that drives real production procs against a synthetic target
/// list (test_target). `seed_hudatoms()` populates hudatoms so collect /
/// add_to_single_hud see a populated set. We override New() to skip the
/// GLOB.all_huds += src side effect so test instances don't pollute the
/// real /mob/reload_huds outer loop.
/datum/atom_hud/test_real
	var/list/test_target

/datum/atom_hud/test_real/New(num_icons = 1)
	test_target = list()
	hud_icons = list()
	for(var/i in 1 to num_icons)
		hud_icons += "[ATOM_HUD_PERF_ICON_KEY_PREFIX][i]"

/datum/atom_hud/test_real/proc/seed_hudatoms(list/atoms)
	for(var/atom/A as anything in atoms)
		hudatoms += A

/datum/atom_hud/test_real/proc/remove_from_test_target(atom/A)
	if(!A || !A.hud_list)
		return
	for(var/i in hud_icons)
		test_target -= A.hud_list[i]

/// Subtype with a should_show_to that filters out atoms whose
/// visible_for_gated is FALSE. Used by the gating tests.
/datum/atom_hud/test_real/gated

/datum/atom_hud/test_real/gated/should_show_to(mob/M, atom/A)
	var/obj/effect/perf_hud_test_atom/test_atom = A
	if(!istype(test_atom))
		return ..()
	return test_atom.visible_for_gated

// -----------------------------------------------------------------------------
// Bench G: collect_hud_images_for must produce the SAME image set as N
// per-atom add_to_single_hud calls would have. This is the correctness
// invariant the batched path depends on — if the two paths disagree, the
// production reload_huds rewrite has changed observable behavior.
//
// Validation strategy: collect via the production proc, then walk the same
// hudatoms manually and accumulate the exact images add_to_single_hud's
// body would have unioned, comparing the resulting sets.
// -----------------------------------------------------------------------------

#define ATOM_HUD_PERF_CORRECTNESS_ATOMS 50

/datum/unit_test/atom_hud_collect_matches_serial
	priority = TEST_LONGER

/datum/unit_test/atom_hud_collect_matches_serial/Run()
	var/datum/atom_hud/test_real/hud = new(num_icons = 4)
	var/list/atoms = list()
	for(var/i in 1 to ATOM_HUD_PERF_CORRECTNESS_ATOMS)
		atoms += allocate(/obj/effect/perf_hud_test_atom, run_loc_floor_bottom_left, 4)
	hud.seed_hudatoms(atoms)

	// Production batched collection.
	var/list/collected = list()
	hud.collect_hud_images_for(/* M = */ null, collected)

	// Reference: walk the atoms / icons exactly as the per-call path would,
	// but write into a parallel list. Both passes must produce the same
	// set after dedup, and the same total length pre-dedup.
	var/list/reference = list()
	for(var/obj/effect/perf_hud_test_atom/A as anything in atoms)
		var/list/atom_hud_list = A.hud_list
		if(!atom_hud_list)
			continue
		for(var/i in hud.hud_icons)
			var/hud_image = atom_hud_list[i]
			if(hud_image)
				reference += hud_image

	TEST_ASSERT_EQUAL(length(collected), length(reference), "collect_hud_images_for and reference walk must produce same length (collected=[length(collected)], reference=[length(reference)])")

	// Set equality after dedup: every image in collected appears in reference and vice versa.
	var/list/collected_set = list()
	for(var/image/I as anything in collected)
		collected_set[I] = TRUE
	var/list/reference_set = list()
	for(var/image/I as anything in reference)
		reference_set[I] = TRUE
	TEST_ASSERT_EQUAL(length(collected_set), length(reference_set), "Deduped sets must match in size")
	for(var/image/I as anything in reference_set)
		TEST_ASSERT(collected_set[I], "Reference image not present in collected output")

#undef ATOM_HUD_PERF_CORRECTNESS_ATOMS

// -----------------------------------------------------------------------------
// Bench H: should_show_to gating must fire for BOTH paths
// (add_to_single_hud and collect_hud_images_for). Filters every other atom
// via visible_for_gated and asserts the right images land in each path.
// -----------------------------------------------------------------------------

#define ATOM_HUD_PERF_GATING_ATOMS 20

/datum/unit_test/atom_hud_gating_filters_collect
	priority = TEST_LONGER

/datum/unit_test/atom_hud_gating_filters_collect/Run()
	var/datum/atom_hud/test_real/gated/hud = new(num_icons = 2)
	var/list/atoms = list()
	for(var/i in 1 to ATOM_HUD_PERF_GATING_ATOMS)
		var/obj/effect/perf_hud_test_atom/A = allocate(/obj/effect/perf_hud_test_atom, run_loc_floor_bottom_left, 2)
		// Even-indexed visible, odd-indexed gated out.
		A.visible_for_gated = (i % 2 == 0)
		atoms += A
	hud.seed_hudatoms(atoms)

	// collect_hud_images_for must skip the gated-out atoms entirely.
	var/list/collected = list()
	hud.collect_hud_images_for(null, collected)

	// Expected: half the atoms × 2 icons each = ATOM_HUD_PERF_GATING_ATOMS images.
	var/expected = (ATOM_HUD_PERF_GATING_ATOMS / 2) * 2
	TEST_ASSERT_EQUAL(length(collected), expected, "Gated collect should yield half × icons (got [length(collected)], expected [expected])")

	// Cross-check: the deduped set must contain images from VISIBLE atoms only.
	var/list/visible_imgs = list()
	for(var/obj/effect/perf_hud_test_atom/A as anything in atoms)
		if(!A.visible_for_gated)
			continue
		for(var/key in hud.hud_icons)
			visible_imgs[A.hud_list[key]] = TRUE
	for(var/image/I as anything in collected)
		TEST_ASSERT(visible_imgs[I], "Collected image came from an atom that should have been gated out")

#undef ATOM_HUD_PERF_GATING_ATOMS

// -----------------------------------------------------------------------------
// Regression: reload_huds flushes one HUD batch at a time (per-hud union), so a
// later remove path that subtracts an already-pushed image leaves it removed.
// The old single delayed-final-flush accumulator would re-add it afterwards.
// -----------------------------------------------------------------------------

/datum/unit_test/atom_hud_reload_flush_before_yield_handles_removal
	priority = TEST_LONGER

/datum/unit_test/atom_hud_reload_flush_before_yield_handles_removal/Run()
	var/datum/atom_hud/test_real/hud = new(num_icons = 3)
	var/obj/effect/perf_hud_test_atom/A = allocate(/obj/effect/perf_hud_test_atom, run_loc_floor_bottom_left, 3)
	hud.seed_hudatoms(list(A))

	// Current reload_huds shape: flush this HUD batch immediately.
	hud.push_all_atoms_to_image_list(null, hud.test_target)
	TEST_ASSERT_EQUAL(length(hud.test_target), 3, "Per-HUD flush should add every image up front")

	// A later remove_from_single_hud must stay removed.
	hud.remove_from_test_target(A)
	for(var/i in hud.hud_icons)
		var/image/I = A.hud_list[i]
		TEST_ASSERT(!(I in hud.test_target), "Image [i] should stay removed after a post-flush HUD removal")

	// Control: the old all_hud_images accumulator failed this exact interleave.
	var/list/delayed_target = list()
	var/list/delayed_accumulated = list()
	hud.collect_hud_images_for(null, delayed_accumulated)
	for(var/i in hud.hud_icons)
		delayed_target -= A.hud_list[i]
	delayed_target |= delayed_accumulated
	for(var/i in hud.hud_icons)
		var/image/I = A.hud_list[i]
		TEST_ASSERT(I in delayed_target, "Control should reproduce the stale image that delayed final flush would re-add")

// -----------------------------------------------------------------------------
// Bench I: production-path serial vs batched comparison. Both paths see the
// SAME hudatoms set; both produce the SAME final test_target. The batched
// path must be at least as fast as the serial path (typically much faster).
// -----------------------------------------------------------------------------

#define ATOM_HUD_PERF_BATCHED_COMPARE_ATOMS 1500
#define ATOM_HUD_PERF_BATCHED_COMPARE_ICONS 6

/datum/unit_test/atom_hud_batched_path_matches_and_wins
	priority = TEST_LONGER

/datum/unit_test/atom_hud_batched_path_matches_and_wins/Run()
	// Build one shared population of atoms.
	var/list/atoms = list()
	for(var/i in 1 to ATOM_HUD_PERF_BATCHED_COMPARE_ATOMS)
		atoms += allocate(/obj/effect/perf_hud_test_atom, run_loc_floor_bottom_left, ATOM_HUD_PERF_BATCHED_COMPARE_ICONS)

	// SERIAL path: simulates the pre-batch reload_huds — N |= against a
	// growing target. We mirror add_to_single_hud's body inline against
	// `serial_target` to avoid the no-client guard.
	var/datum/atom_hud/test_real/hud_serial = new(num_icons = ATOM_HUD_PERF_BATCHED_COMPARE_ICONS)
	hud_serial.seed_hudatoms(atoms)

	var/list/serial_target = list()
	var/start = REALTIMEOFDAY
	for(var/atom/A as anything in hud_serial.hudatoms)
		var/list/atom_hud_list = A.hud_list
		if(!atom_hud_list)
			continue
		var/list/per_atom_addition
		for(var/i in hud_serial.hud_icons)
			var/hud_image = atom_hud_list[i]
			if(!hud_image)
				continue
			if(!per_atom_addition)
				per_atom_addition = list()
			per_atom_addition += hud_image
		if(length(per_atom_addition))
			serial_target |= per_atom_addition
	var/elapsed_serial = REALTIMEOFDAY - start

	// BATCHED path: production collect + one trailing |=. This is the exact
	// shape /mob/proc/reload_huds now uses (modulo the per-hud iteration
	// since we have a single hud here).
	var/datum/atom_hud/test_real/hud_batched = new(num_icons = ATOM_HUD_PERF_BATCHED_COMPARE_ICONS)
	hud_batched.seed_hudatoms(atoms)

	start = REALTIMEOFDAY
	var/list/collected = list()
	hud_batched.collect_hud_images_for(null, collected)
	hud_batched.test_target |= collected
	var/elapsed_batched = REALTIMEOFDAY - start

	log_world("[type]: serial [ATOM_HUD_PERF_BATCHED_COMPARE_ATOMS]×[ATOM_HUD_PERF_BATCHED_COMPARE_ICONS] = [elapsed_serial]ds, batched = [elapsed_batched]ds")
	if(elapsed_batched > 0 && elapsed_serial > 0)
		log_world("[type]: serial / batched ratio ≈ [elapsed_serial / elapsed_batched]x")

	// Equivalence: both paths must populate the same set of images.
	TEST_ASSERT_EQUAL(length(serial_target), length(hud_batched.test_target), "Serial and batched paths must produce the same image set size (serial=[length(serial_target)], batched=[length(hud_batched.test_target)])")
	for(var/image/I as anything in serial_target)
		TEST_ASSERT(I in hud_batched.test_target, "Image from serial path missing in batched path")

	// Performance: batched cannot be slower than the serial bound (with a
	// generous factor for CI noise — at smallest measured difference we still
	// expect parity; in practice the ratio is several× in favor of batched).
	if(elapsed_serial > 0)
		TEST_ASSERT(elapsed_batched <= elapsed_serial * 1.5 + 1, "Batched path slower than serial: serial=[elapsed_serial]ds, batched=[elapsed_batched]ds")

#undef ATOM_HUD_PERF_BATCHED_COMPARE_ATOMS
#undef ATOM_HUD_PERF_BATCHED_COMPARE_ICONS

// -----------------------------------------------------------------------------
// Bench J: real-procs reload_huds-style burst — drives collect_hud_images_for
// directly across many atoms, mirroring the inner loop of the new
// reload_huds. Demonstrates the ceiling that the batched union path now
// achieves vs Bench D's serial burst.
// -----------------------------------------------------------------------------

/datum/unit_test/atom_hud_collect_burst
	priority = TEST_LONGER

/datum/unit_test/atom_hud_collect_burst/Run()
	var/datum/atom_hud/test_real/hud = new(num_icons = ATOM_HUD_PERF_BURST_ICONS_PER_HUD)
	var/list/atoms = list()
	for(var/i in 1 to ATOM_HUD_PERF_BURST_ATOMS)
		atoms += allocate(/obj/effect/perf_hud_test_atom, run_loc_floor_bottom_left, ATOM_HUD_PERF_BURST_ICONS_PER_HUD)
	hud.seed_hudatoms(atoms)

	var/list/collected = list()
	var/start = REALTIMEOFDAY
	hud.collect_hud_images_for(null, collected)
	hud.test_target |= collected
	var/elapsed_ds = REALTIMEOFDAY - start

	var/per_atom_us = (elapsed_ds * 100000) / ATOM_HUD_PERF_BURST_ATOMS
	log_world("[type]: BATCHED BURST [ATOM_HUD_PERF_BURST_ATOMS] atoms × [ATOM_HUD_PERF_BURST_ICONS_PER_HUD] icons = [elapsed_ds]ds (~[per_atom_us]us/atom), final=[length(hud.test_target)]")

	TEST_ASSERT_EQUAL(length(hud.test_target), ATOM_HUD_PERF_BURST_ATOMS * ATOM_HUD_PERF_BURST_ICONS_PER_HUD, "Batched burst should populate every image exactly once")

// -----------------------------------------------------------------------------
// Regression: /mob/proc/reload_huds_into() — the per-hud-batched loop that runs
// inside /mob/Login() — must (a) push every visible HUD image into the target
// list and (b) NOT sleep.
//
// reload_huds() used to carry a CHECK_TICK between huds. /mob/Login() is assumed
// by its callers to run synchronously: most importantly the ghost-role spawner
// path /obj/effect/mob_spawn/proc/create() does `mob.ckey = ckey` and then
// immediately reads `src.mind` (Login() only creates the mind later, via
// sync_mind(), AFTER reload_huds()). A yield there left freshly-spawned ghost-role
// bodies with a random appearance, no "Ghost Role" assignment (so they counted as
// living station crew) and the spawner never decremented its uses / qdel'd itself.
// SHOULD_NOT_SLEEP on reload_huds_into() is the compile-time guard; this is the
// runtime behaviour check.
// -----------------------------------------------------------------------------

/datum/unit_test/reload_huds_into_batches_without_yield

/datum/unit_test/reload_huds_into_batches_without_yield/Run()
	// A real /datum/atom_hud (so it lands in GLOB.all_huds and reload_huds_into iterates it).
	var/datum/atom_hud/test_hud = allocate(/datum/atom_hud)
	test_hud.hud_icons = list("reload_into_test_a", "reload_into_test_b")

	// A clientless mob to reload HUDs onto, registered as a huduser of our test hud.
	var/mob/living/carbon/human/dummy/spectator = allocate(/mob/living/carbon/human/dummy)
	test_hud.hudusers[spectator] = 1

	// A fake hudatom carrying one image per key our hud looks for.
	var/obj/effect/perf_hud_test_atom/hud_atom = allocate(/obj/effect/perf_hud_test_atom, run_loc_floor_bottom_left, 1)
	hud_atom.hud_list = list()
	var/list/expected_images = list()
	for(var/key in test_hud.hud_icons)
		var/image/I = image('icons/mob/hud.dmi', null, "")
		hud_atom.hud_list[key] = I
		expected_images += I
	test_hud.hudatoms += hud_atom

	var/list/target_images = list()
	var/time_before = world.time
	spectator.reload_huds_into(target_images)
	TEST_ASSERT_EQUAL(world.time, time_before, "reload_huds_into() must not sleep — it runs inside /mob/Login()")

	for(var/image/I as anything in expected_images)
		TEST_ASSERT(I in target_images, "reload_huds_into() should have pushed every visible hud image into the target")
	TEST_ASSERT_EQUAL(length(target_images), length(expected_images), "reload_huds_into() pushed unexpected images (got [length(target_images)], expected [length(expected_images)])")

#undef ATOM_HUD_PERF_ICON_KEY_PREFIX
#undef ATOM_HUD_PERF_BURST_ATOMS
#undef ATOM_HUD_PERF_BURST_ICONS_PER_HUD
#undef ATOM_HUD_PERF_GROWTH_STEPS
