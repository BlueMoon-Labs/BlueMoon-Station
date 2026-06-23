/// Tests for /atom/movable/screen/parallax_layer/proc/RelativePosition.
/// This runs per parallax layer on every player move (the single biggest non-atmos
/// self-CPU consumer in round profiles), so it must:
/// - keep the screen_loc math exact (including the 480px wrap and round-to-pixel),
/// - report via its return value whether a glide animation was started,
/// - NOT start a glide animation for sub-2px deltas (visually indistinguishable from
///   the instant screen_loc snap while the viewport itself glides a full tile).
/datum/unit_test/parallax_relative_position/Run()
	// Slow layer (0.6 px per tile): visual position changes only every other step,
	// and per-step deltas never exceed 1px so no glide animation should ever start.
	var/atom/movable/screen/parallax_layer/slow = new
	allocated += slow
	slow.speed = 0.6
	var/list/expected_x = list(-1, -1, -2, -2, -3)
	for(var/i in 1 to 5)
		var/animated = slow.RelativePosition(0, 0, 1, 0, 2)
		TEST_ASSERT(!animated, "Slow layer started a glide animation for a sub-pixel delta at step [i]")
		TEST_ASSERT_EQUAL(slow.screen_loc, "CENTER-7:[expected_x[i]],CENTER-7:0", "Slow layer screen_loc mismatch at step [i]")

	// Fast layer (2 px per tile): a 2px delta is the threshold where the glide animation
	// must still be started (and reported via the return value).
	var/atom/movable/screen/parallax_layer/fast = new
	allocated += fast
	fast.speed = 2
	var/animated_fast = fast.RelativePosition(0, 0, 1, 0, 2)
	TEST_ASSERT(animated_fast, "Fast layer did not report starting a glide animation for a 2px delta")
	TEST_ASSERT_EQUAL(fast.screen_loc, "CENTER-7:-2,CENTER-7:0", "Fast layer screen_loc mismatch after first step")

	// anim_time = 0 must never animate regardless of delta
	var/animated_noanim = fast.RelativePosition(0, 0, 1, 0, 0)
	TEST_ASSERT(!animated_noanim, "Layer started a glide animation with anim_time = 0")
	TEST_ASSERT_EQUAL(fast.screen_loc, "CENTER-7:-4,CENTER-7:0", "Fast layer screen_loc mismatch after no-anim step")

	// Mid-speed layer (1.4 px per tile) on diagonal moves: per-step visual delta
	// alternates between 1px (no animation) and 2px (animation).
	var/atom/movable/screen/parallax_layer/mid = new
	allocated += mid
	mid.speed = 1.4
	TEST_ASSERT(!mid.RelativePosition(0, 0, 1, 1, 2), "Mid layer animated a 1px diagonal delta")
	TEST_ASSERT_EQUAL(mid.screen_loc, "CENTER-7:-1,CENTER-7:-1", "Mid layer screen_loc mismatch at step 1")
	TEST_ASSERT(mid.RelativePosition(0, 0, 1, 1, 2), "Mid layer did not animate a 2px diagonal delta")
	TEST_ASSERT_EQUAL(mid.screen_loc, "CENTER-7:-3,CENTER-7:-3", "Mid layer screen_loc mismatch at step 2")

	// Wrap across the 240px boundary: position wraps by 480 and animation must be skipped
	var/atom/movable/screen/parallax_layer/wrapper = new
	allocated += wrapper
	wrapper.speed = 2
	wrapper.offset_x = 239
	var/animated_wrap = wrapper.RelativePosition(0, 0, -1, 0, 2)
	TEST_ASSERT(!animated_wrap, "Layer started a glide animation across a wrap")
	TEST_ASSERT_EQUAL(wrapper.screen_loc, "CENTER-7:-239,CENTER-7:0", "Wrapped layer screen_loc mismatch")

	// Absolute layer delegates to ResetPosition and never glides
	var/atom/movable/screen/parallax_layer/abs_layer = new
	allocated += abs_layer
	abs_layer.speed = 1
	abs_layer.absolute = TRUE
	var/animated_abs = abs_layer.RelativePosition(10, 5, 1, 1, 2)
	TEST_ASSERT(!animated_abs, "Absolute layer reported a glide animation")
	TEST_ASSERT_EQUAL(abs_layer.screen_loc, "CENTER-7:-10,CENTER-7:-5", "Absolute layer screen_loc mismatch")

/// Logs the cost of the per-move hot path (speed-1 layer, 1px deltas with glide enabled).
/// No assertions on timing, output is for before/after comparison in test logs.
/datum/unit_test/parallax_relative_position_bench
	priority = TEST_LONGER

/datum/unit_test/parallax_relative_position_bench/Run()
	var/atom/movable/screen/parallax_layer/layer = new
	allocated += layer
	layer.speed = 1
	var/iterations = 50000
	var/start = REALTIMEOFDAY
	for(var/i in 1 to iterations)
		layer.RelativePosition(0, 0, (i % 2) ? 1 : -1, 0, 2)
	log_world("PERF: parallax RelativePosition x[iterations] (speed 1, 1px glide deltas): [(REALTIMEOFDAY - start) * 100]ms")
