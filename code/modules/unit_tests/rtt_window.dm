/// Tests for /proc/rtt_window_push - the incrementally maintained sorted window used by
/// /client/proc/stabilize_rtt_ping. The old implementation copied and TimSorted the whole
/// window on every ping sample (~80k times per round); the helper must keep a sorted
/// mirror incrementally and return the exact same median as a full re-sort would.
/datum/unit_test/rtt_window/proc/reference_median(list/window)
	// Mirrors the old stabilize_rtt_ping math: full copy + sort + middle element
	var/list/sorted_samples = window.Copy()
	sortTim(sorted_samples, GLOBAL_PROC_REF(cmp_numeric_asc))
	return sorted_samples[max(1, CEILING(length(sorted_samples) * 0.5, 1))]

/datum/unit_test/rtt_window/Run()
	var/list/samples = list(
		50, 10, 10, 80, 30, 0, 999, 42, 42, 42, 5, 77, 13, 1000, 3, 250, 8, 8, 120, 60,
		5, 0, 33, 47, 251, 18, 18, 18, 90, 14, 600, 2, 71, 36, 100, 100, 1, 25, 480, 7,
	)
	for(var/window_size in list(1, 2, 15))
		var/list/window = list()
		var/list/sorted = list()
		var/step = 0
		for(var/sample in samples)
			step++
			var/median = rtt_window_push(window, sorted, sample, window_size)
			TEST_ASSERT(length(window) <= window_size, "Window size [length(window)] exceeded max [window_size] at step [step]")
			TEST_ASSERT_EQUAL(length(sorted), length(window), "Sorted mirror desynced from window at step [step] (max [window_size])")
			for(var/i in 2 to length(sorted))
				TEST_ASSERT(sorted[i - 1] <= sorted[i], "Sorted mirror is not ascending at index [i], step [step] (max [window_size])")
			var/list/expected_sorted = window.Copy()
			sortTim(expected_sorted, GLOBAL_PROC_REF(cmp_numeric_asc))
			for(var/i in 1 to length(sorted))
				TEST_ASSERT_EQUAL(sorted[i], expected_sorted[i], "Sorted mirror multiset mismatch at index [i], step [step] (max [window_size])")
			TEST_ASSERT_EQUAL(median, reference_median(window), "Median mismatch at step [step] (max [window_size])")

/// Compares the old full-resort median path against rtt_window_push and logs timings.
/// The checksum assertion doubles as a correctness check over a long pseudo-random sequence.
/datum/unit_test/rtt_window_bench
	priority = TEST_LONGER

/datum/unit_test/rtt_window_bench/Run()
	var/iterations = 20000
	var/max_size = 15

	// Old path: copy + TimSort per sample (what stabilize_rtt_ping used to do)
	var/list/window_old = list()
	var/checksum_old = 0
	var/start = REALTIMEOFDAY
	for(var/i in 1 to iterations)
		window_old += (i * 37) % 200
		if(length(window_old) > max_size)
			window_old.Cut(1, 2)
		var/list/sorted_samples = window_old.Copy()
		sortTim(sorted_samples, GLOBAL_PROC_REF(cmp_numeric_asc))
		checksum_old += sorted_samples[max(1, CEILING(length(sorted_samples) * 0.5, 1))]
	var/old_ds = REALTIMEOFDAY - start

	// New path: incrementally maintained sorted mirror
	var/list/window_new = list()
	var/list/sorted_new = list()
	var/checksum_new = 0
	start = REALTIMEOFDAY
	for(var/i in 1 to iterations)
		checksum_new += rtt_window_push(window_new, sorted_new, (i * 37) % 200, max_size)
	var/new_ds = REALTIMEOFDAY - start

	TEST_ASSERT_EQUAL(checksum_new, checksum_old, "rtt_window_push produced different medians than the full-resort reference")
	log_world("PERF: rtt window x[iterations]: full resort [old_ds * 100]ms vs incremental [new_ds * 100]ms")
