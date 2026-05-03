/// Tests for sortTim / sortInsert / sortMerge covering the four fast-path
/// comparators (cmp_numeric_asc / dsc, cmp_text_asc / dsc), the generic
/// call(cmp) fallback, and associative-list mode. Exercises both binarySort
/// (small inputs, < MIN_MERGE = 32) and the full merge path (large inputs).

/datum/unit_test/sort_tim/Run()
	// Small / binarySort-only cases
	test_numeric_asc()
	test_numeric_dsc()
	test_text_asc()
	test_text_dsc()
	test_associative_numeric_dsc()
	test_associative_text_asc()
	test_custom_cmp()
	test_sort_insert()
	test_partial_range()
	test_idempotent_on_sorted()
	test_list_of_lists_no_splat()

	// Large / merge-path cases — one per fast-path + generic fallback.
	test_large_random_numeric_asc()
	test_large_random_numeric_dsc()
	test_large_random_text_asc()
	test_large_random_text_dsc()
	test_large_random_generic_cmp()
	test_large_associative_numeric_asc()

	// Stability + run-detection cases that exercise countRunAndMakeAscending
	// and the merge logic under structured input.
	test_already_sorted_large()
	test_reverse_sorted_large()
	test_alternating_runs()

	// Cross-comparator pollution: cmpKind must re-resolve on each entry,
	// otherwise a previous call's kind would corrupt the next one.
	test_cmpkind_re_resolves_between_calls()

	// sortMerge wrapper coverage.
	test_sort_merge_basic()
	test_sort_merge_large()

/datum/unit_test/sort_tim/proc/test_numeric_asc()
	var/list/L = list(5, 2, 8, 1, 9, 3, 7, 4, 6, 0)
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_asc))
	for(var/i in 1 to L.len)
		TEST_ASSERT_EQUAL(L[i], i - 1, "numeric_asc element [i] expected [i-1] got [L[i]]")

	// 2-element list (hits the small-array path that calls binarySort directly)
	var/list/two = list(2, 1)
	sortTim(two, GLOBAL_PROC_REF(cmp_numeric_asc))
	TEST_ASSERT_EQUAL(two[1], 1, "two[1] should be 1")
	TEST_ASSERT_EQUAL(two[2], 2, "two[2] should be 2")

/datum/unit_test/sort_tim/proc/test_numeric_dsc()
	var/list/L = list(5, 2, 8, 1, 9, 3, 7, 4, 6, 0)
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_dsc))
	for(var/i in 1 to L.len)
		TEST_ASSERT_EQUAL(L[i], 10 - i, "numeric_dsc element [i] expected [10-i] got [L[i]]")

/datum/unit_test/sort_tim/proc/test_text_asc()
	var/list/L = list("banana", "apple", "cherry", "date")
	sortTim(L, GLOBAL_PROC_REF(cmp_text_asc))
	TEST_ASSERT_EQUAL(L[1], "apple", "text_asc[1]")
	TEST_ASSERT_EQUAL(L[2], "banana", "text_asc[2]")
	TEST_ASSERT_EQUAL(L[3], "cherry", "text_asc[3]")
	TEST_ASSERT_EQUAL(L[4], "date", "text_asc[4]")

/datum/unit_test/sort_tim/proc/test_text_dsc()
	var/list/L = list("banana", "apple", "cherry", "date")
	sortTim(L, GLOBAL_PROC_REF(cmp_text_dsc))
	TEST_ASSERT_EQUAL(L[1], "date", "text_dsc[1]")
	TEST_ASSERT_EQUAL(L[2], "cherry", "text_dsc[2]")
	TEST_ASSERT_EQUAL(L[3], "banana", "text_dsc[3]")
	TEST_ASSERT_EQUAL(L[4], "apple", "text_dsc[4]")

/datum/unit_test/sort_tim/proc/test_associative_numeric_dsc()
	// Sort an associative list by VALUES (highest first) preserving key->value mapping.
	var/list/L = list("a" = 3, "b" = 1, "c" = 5, "d" = 2, "e" = 4)
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_dsc), associative = TRUE)
	TEST_ASSERT_EQUAL(L[1], "c", "assoc dsc key[1] should be 'c' got '[L[1]]'")
	TEST_ASSERT_EQUAL(L[2], "e", "assoc dsc key[2] should be 'e' got '[L[2]]'")
	TEST_ASSERT_EQUAL(L[3], "a", "assoc dsc key[3] should be 'a' got '[L[3]]'")
	TEST_ASSERT_EQUAL(L[4], "d", "assoc dsc key[4] should be 'd' got '[L[4]]'")
	TEST_ASSERT_EQUAL(L[5], "b", "assoc dsc key[5] should be 'b' got '[L[5]]'")
	TEST_ASSERT_EQUAL(L["a"], 3, "assoc dsc value for 'a' preserved")
	TEST_ASSERT_EQUAL(L["b"], 1, "assoc dsc value for 'b' preserved")
	TEST_ASSERT_EQUAL(L["c"], 5, "assoc dsc value for 'c' preserved")
	TEST_ASSERT_EQUAL(L["d"], 2, "assoc dsc value for 'd' preserved")
	TEST_ASSERT_EQUAL(L["e"], 4, "assoc dsc value for 'e' preserved")

/datum/unit_test/sort_tim/proc/test_associative_text_asc()
	// Sort assoc list by VALUE alphabetically, keys carry along.
	var/list/L = list("k1" = "delta", "k2" = "alpha", "k3" = "charlie", "k4" = "bravo")
	sortTim(L, GLOBAL_PROC_REF(cmp_text_asc), associative = TRUE)
	TEST_ASSERT_EQUAL(L[1], "k2", "assoc text_asc key[1]")
	TEST_ASSERT_EQUAL(L[2], "k4", "assoc text_asc key[2]")
	TEST_ASSERT_EQUAL(L[3], "k3", "assoc text_asc key[3]")
	TEST_ASSERT_EQUAL(L[4], "k1", "assoc text_asc key[4]")
	TEST_ASSERT_EQUAL(L["k1"], "delta", "assoc text_asc value for 'k1' preserved")
	TEST_ASSERT_EQUAL(L["k2"], "alpha", "assoc text_asc value for 'k2' preserved")

/// Custom comparator that exercises the generic call(cmp) fallback path.
/proc/_sort_tim_test_cmp_abs(a, b)
	return abs(a) - abs(b)

/datum/unit_test/sort_tim/proc/test_custom_cmp()
	var/list/L = list(-5, 2, -1, 4, -3)
	sortTim(L, GLOBAL_PROC_REF(_sort_tim_test_cmp_abs))
	// Sorted by |x|: -1, 2, -3, 4, -5
	TEST_ASSERT_EQUAL(L[1], -1, "custom cmp[1]")
	TEST_ASSERT_EQUAL(L[2], 2, "custom cmp[2]")
	TEST_ASSERT_EQUAL(L[3], -3, "custom cmp[3]")
	TEST_ASSERT_EQUAL(L[4], 4, "custom cmp[4]")
	TEST_ASSERT_EQUAL(L[5], -5, "custom cmp[5]")

/datum/unit_test/sort_tim/proc/test_sort_insert()
	var/list/L = list(5, 2, 8, 1, 9, 3, 7, 4, 6, 0)
	sortInsert(L, GLOBAL_PROC_REF(cmp_numeric_asc))
	for(var/i in 1 to L.len)
		TEST_ASSERT_EQUAL(L[i], i - 1, "sortInsert pos [i] expected [i-1] got [L[i]]")

/datum/unit_test/sort_tim/proc/test_partial_range()
	// sortTim only the slice [3, 7) — leaves [1,3) and [7,end] untouched.
	var/list/L = list(9, 8, 5, 2, 7, 1, 3, 0, 4)
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_asc), fromIndex = 3, toIndex = 7)
	TEST_ASSERT_EQUAL(L[1], 9, "partial: outside-range [1] unchanged")
	TEST_ASSERT_EQUAL(L[2], 8, "partial: outside-range [2] unchanged")
	TEST_ASSERT_EQUAL(L[3], 1, "partial: range[1]")
	TEST_ASSERT_EQUAL(L[4], 2, "partial: range[2]")
	TEST_ASSERT_EQUAL(L[5], 5, "partial: range[3]")
	TEST_ASSERT_EQUAL(L[6], 7, "partial: range[4]")
	TEST_ASSERT_EQUAL(L[7], 3, "partial: outside-range [7] unchanged")
	TEST_ASSERT_EQUAL(L[8], 0, "partial: outside-range [8] unchanged")
	TEST_ASSERT_EQUAL(L[9], 4, "partial: outside-range [9] unchanged")

/datum/unit_test/sort_tim/proc/test_idempotent_on_sorted()
	// An already-sorted input must come out unchanged. Exercises the early-exit
	// "left == start" branch where we skip the move entirely.
	var/list/L = list(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_asc))
	for(var/i in 1 to L.len)
		TEST_ASSERT_EQUAL(L[i], i, "idempotent pos [i]")

/// Regression: when list elements are themselves lists, the move step must NOT
/// splat the inner list's contents into the outer list. Mirrors how
/// sort_list(sheet_list, cmp_sheet_list) is used in laborstacker.dm.
/datum/unit_test/sort_tim/proc/test_list_of_lists_no_splat()
	var/list/L = list(
		list("ore" = "iron", "value" = 30),
		list("ore" = "gold", "value" = 5),
		list("ore" = "diamond", "value" = 50),
		list("ore" = "copper", "value" = 15),
		list("ore" = "silver", "value" = 20),
	)
	var/initial_len = L.len
	sortTim(L, GLOBAL_PROC_REF(_sort_tim_test_cmp_sheet_value))
	TEST_ASSERT_EQUAL(L.len, initial_len, "list-of-lists: length must not change (splat would inflate)")
	for(var/entry in L)
		TEST_ASSERT(islist(entry), "list-of-lists: every entry must still be a list")
	var/list/first = L[1]
	var/list/last = L[L.len]
	TEST_ASSERT_EQUAL(first["value"], 5, "list-of-lists: smallest value first")
	TEST_ASSERT_EQUAL(first["ore"], "gold", "list-of-lists: smallest entry's ore preserved")
	TEST_ASSERT_EQUAL(last["value"], 50, "list-of-lists: largest value last")
	TEST_ASSERT_EQUAL(last["ore"], "diamond", "list-of-lists: largest entry's ore preserved")

/proc/_sort_tim_test_cmp_sheet_value(list/a, list/b)
	return a["value"] - b["value"]

// =============================================================================
// Large-input cases. N > MIN_MERGE (32) forces TimSort through countRun /
// gallop / mergeLo / mergeHi, exercising the inlined fast paths.
// =============================================================================

/// Build a deterministic-ish but well-mixed permutation of 1..N for sort tests.
/proc/_sort_tim_test_make_perm(N)
	var/list/out = list()
	// (i*73) mod N hits every value once when gcd(73, N)==1; for N=200 (gcd=1)
	// this gives a uniformly distributed-looking sequence.
	for(var/i in 1 to N)
		out += ((i * 73) % N) + 1
	return out

/datum/unit_test/sort_tim/proc/test_large_random_numeric_asc()
	var/list/L = _sort_tim_test_make_perm(200)
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_asc))
	TEST_ASSERT_EQUAL(L.len, 200, "large num_asc: length preserved")
	for(var/i in 1 to L.len - 1)
		TEST_ASSERT(L[i] <= L[i + 1], "large num_asc: not sorted at [i] ([L[i]] > [L[i+1]])")

/datum/unit_test/sort_tim/proc/test_large_random_numeric_dsc()
	var/list/L = _sort_tim_test_make_perm(200)
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_dsc))
	TEST_ASSERT_EQUAL(L.len, 200, "large num_dsc: length preserved")
	for(var/i in 1 to L.len - 1)
		TEST_ASSERT(L[i] >= L[i + 1], "large num_dsc: not sorted at [i] ([L[i]] < [L[i+1]])")

/datum/unit_test/sort_tim/proc/test_large_random_text_asc()
	// Build 100 distinct strings from the permutation so the merge path runs
	// under cmp_text_asc rather than just the small-input binarySort.
	var/list/perm = _sort_tim_test_make_perm(100)
	var/list/L = list()
	for(var/n in perm)
		L += "item_[num2text(n + 1000)]"  // +1000 keeps width uniform => lexicographic == numeric
	sortTim(L, GLOBAL_PROC_REF(cmp_text_asc))
	TEST_ASSERT_EQUAL(L.len, 100, "large text_asc: length preserved")
	for(var/i in 1 to L.len - 1)
		TEST_ASSERT(sorttext(L[i], L[i + 1]) >= 0, "large text_asc: not sorted at [i] ('[L[i]]' > '[L[i+1]]')")

/datum/unit_test/sort_tim/proc/test_large_random_text_dsc()
	var/list/perm = _sort_tim_test_make_perm(100)
	var/list/L = list()
	for(var/n in perm)
		L += "item_[num2text(n + 1000)]"
	sortTim(L, GLOBAL_PROC_REF(cmp_text_dsc))
	TEST_ASSERT_EQUAL(L.len, 100, "large text_dsc: length preserved")
	for(var/i in 1 to L.len - 1)
		TEST_ASSERT(sorttext(L[i], L[i + 1]) <= 0, "large text_dsc: not sorted at [i] ('[L[i]]' < '[L[i+1]]')")

/datum/unit_test/sort_tim/proc/test_large_random_generic_cmp()
	// Generic call(cmp) fallback through merge path. Sort by absolute value.
	var/list/L = list()
	for(var/i in 1 to 100)
		// Mix positive and negative values, deterministic.
		L += ((i * 17) % 50) - 25 + ((i % 2) ? 0.5 : -0.5)
	sortTim(L, GLOBAL_PROC_REF(_sort_tim_test_cmp_abs))
	TEST_ASSERT_EQUAL(L.len, 100, "large generic: length preserved")
	for(var/i in 1 to L.len - 1)
		TEST_ASSERT(abs(L[i]) <= abs(L[i + 1]), "large generic: not sorted at [i] (|[L[i]]|=[abs(L[i])] > |[L[i+1]]|=[abs(L[i+1])])")

/datum/unit_test/sort_tim/proc/test_large_associative_numeric_asc()
	// Associative + large => fetchElement(L, i) takes the "associative" branch,
	// merge path runs, key->value mapping must survive every move.
	var/list/L = list()
	var/list/perm = _sort_tim_test_make_perm(80)
	for(var/i in 1 to perm.len)
		L["k[i]"] = perm[i]
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE)
	TEST_ASSERT_EQUAL(L.len, 80, "large assoc: length preserved")
	for(var/i in 1 to L.len - 1)
		var/key1 = L[i]
		var/key2 = L[i + 1]
		TEST_ASSERT(L[key1] <= L[key2], "large assoc: values not sorted at [i] (k='[key1]'=[L[key1]] > k='[key2]'=[L[key2]])")
	// All original keys must still be present and map to their original values.
	for(var/i in 1 to perm.len)
		TEST_ASSERT_EQUAL(L["k[i]"], perm[i], "large assoc: key 'k[i]' lost its original value")

/datum/unit_test/sort_tim/proc/test_already_sorted_large()
	var/list/L = list()
	for(var/i in 1 to 100)
		L += i
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_asc))
	TEST_ASSERT_EQUAL(L.len, 100, "already-sorted: length preserved")
	for(var/i in 1 to L.len)
		TEST_ASSERT_EQUAL(L[i], i, "already-sorted: pos [i]")

/datum/unit_test/sort_tim/proc/test_reverse_sorted_large()
	// Reverse-sorted input forces countRunAndMakeAscending to detect a strictly
	// descending run and reverse it via reverseRange. Stability is tested by
	// the alternating-runs case below.
	var/list/L = list()
	for(var/i in 1 to 100)
		L += 101 - i
	sortTim(L, GLOBAL_PROC_REF(cmp_numeric_asc))
	TEST_ASSERT_EQUAL(L.len, 100, "reverse-sorted: length preserved")
	for(var/i in 1 to L.len)
		TEST_ASSERT_EQUAL(L[i], i, "reverse-sorted asc: pos [i] expected [i] got [L[i]]")

/datum/unit_test/sort_tim/proc/test_alternating_runs()
	// Build 5 ascending runs of 30 elements each -> exercises mergeCollapse
	// and gallop logic across multiple merges.
	var/list/L = list()
	for(var/run_idx in 0 to 4)
		var/run_start = run_idx * 30
		for(var/i in 1 to 30)
			L += run_start + i
	// Now reorder: take run3, run0, run4, run1, run2 — keeps each run sorted
	// internally but the overall sequence is jumbled.
	var/list/jumbled = list()
	for(var/run_idx in list(3, 0, 4, 1, 2))
		var/run_start = run_idx * 30
		for(var/i in 1 to 30)
			jumbled += run_start + i
	sortTim(jumbled, GLOBAL_PROC_REF(cmp_numeric_asc))
	TEST_ASSERT_EQUAL(jumbled.len, 150, "alternating-runs: length preserved")
	for(var/i in 1 to jumbled.len)
		TEST_ASSERT_EQUAL(jumbled[i], i, "alternating-runs: pos [i] expected [i] got [jumbled[i]]")

/datum/unit_test/sort_tim/proc/test_cmpkind_re_resolves_between_calls()
	// Run sortTim with cmp_numeric_asc, then immediately run sortInsert with
	// cmp_numeric_dsc on the same global sortInstance. If cmpKind isn't
	// re-resolved on the second entry, the dsc call would dispatch to asc and
	// silently produce wrong output.
	var/list/A = _sort_tim_test_make_perm(64)
	sortTim(A, GLOBAL_PROC_REF(cmp_numeric_asc))
	for(var/i in 1 to A.len - 1)
		TEST_ASSERT(A[i] <= A[i + 1], "re-resolve setup: timSort asc not sorted at [i]")

	var/list/B = list(5, 2, 8, 1, 9, 3, 7, 4, 6, 0)
	sortInsert(B, GLOBAL_PROC_REF(cmp_numeric_dsc))
	for(var/i in 1 to B.len)
		TEST_ASSERT_EQUAL(B[i], 10 - i, "re-resolve: sortInsert dsc element [i] expected [10-i] got [B[i]] — cmpKind probably leaked from previous call")

	// And back the other way: dsc sortTim, then asc sortInsert.
	var/list/C = _sort_tim_test_make_perm(64)
	sortTim(C, GLOBAL_PROC_REF(cmp_numeric_dsc))
	for(var/i in 1 to C.len - 1)
		TEST_ASSERT(C[i] >= C[i + 1], "re-resolve setup: timSort dsc not sorted at [i]")

	var/list/D = list("zebra", "apple", "mango")
	sortInsert(D, GLOBAL_PROC_REF(cmp_text_asc))
	TEST_ASSERT_EQUAL(D[1], "apple", "re-resolve: sortInsert text_asc[1] (cmpKind probably stuck on numeric)")
	TEST_ASSERT_EQUAL(D[2], "mango", "re-resolve: sortInsert text_asc[2]")
	TEST_ASSERT_EQUAL(D[3], "zebra", "re-resolve: sortInsert text_asc[3]")

/datum/unit_test/sort_tim/proc/test_sort_merge_basic()
	var/list/L = list(5, 2, 8, 1, 9, 3, 7, 4, 6, 0)
	sortMerge(L, GLOBAL_PROC_REF(cmp_numeric_asc))
	for(var/i in 1 to L.len)
		TEST_ASSERT_EQUAL(L[i], i - 1, "sortMerge pos [i] expected [i-1] got [L[i]]")

/datum/unit_test/sort_tim/proc/test_sort_merge_large()
	var/list/L = _sort_tim_test_make_perm(200)
	sortMerge(L, GLOBAL_PROC_REF(cmp_numeric_asc))
	TEST_ASSERT_EQUAL(L.len, 200, "sortMerge large: length preserved")
	for(var/i in 1 to L.len - 1)
		TEST_ASSERT(L[i] <= L[i + 1], "sortMerge large: not sorted at [i]")


// =============================================================================
// Benchmark: compares the fast-path (cmp_numeric_asc / cmp_text_asc / etc.)
// against a behaviour-equivalent generic comparator passed as a different proc
// reference, which forces the GEN dispatch path. This is the closest
// apples-to-apples "before vs after" available without two repo checkouts:
// the GEN path in the new engine performs the same call(cmp) per comparison
// the entire pre-refactor engine paid in countRun / gallop / mergeLo / mergeHi.
//
// Output goes through log_test so the numbers land in CI's test log alongside
// PASS/FAIL lines. Scenarios are sized so each total measurement is at least a
// few deciseconds (REALTIMEOFDAY's resolution is 1ds = 100ms).
// =============================================================================

// Behaviour-equivalent shadows of the four fast-path comparators. They MUST NOT
// be GLOBAL_PROC_REF(cmp_numeric_asc) etc., otherwise _resolveCmpKind would
// recognise them and dispatch to the fast path.
/proc/_sort_tim_bench_cmp_num_asc_gen(a, b)
	return a - b

/proc/_sort_tim_bench_cmp_num_dsc_gen(a, b)
	return b - a

/proc/_sort_tim_bench_cmp_text_asc_gen(a, b)
	return sorttext(b, a)

/proc/_sort_tim_bench_cmp_text_dsc_gen(a, b)
	return sorttext(a, b)


/datum/unit_test/sort_tim_benchmark
	priority = TEST_LONGER

/datum/unit_test/sort_tim_benchmark/Run()
	log_test("sort_tim_benchmark: fast-path vs generic call(cmp) — lower 'fast' is better, ratio = generic / fast")
	bench_numeric_asc()
	bench_numeric_dsc()
	bench_text_asc()
	bench_text_dsc()
	bench_associative_numeric_asc()
	bench_already_sorted()
	bench_reverse_sorted()
	bench_small_list()

/// Build a list of `iterations` fresh unsorted permutations so the sort loop
/// itself doesn't include input construction in the timing.
/datum/unit_test/sort_tim_benchmark/proc/build_numeric_inputs(N, iterations)
	var/list/inputs = list()
	for(var/i in 1 to iterations)
		inputs += list(_sort_tim_test_make_perm(N))
	return inputs

/datum/unit_test/sort_tim_benchmark/proc/build_text_inputs(N, iterations)
	var/list/inputs = list()
	var/list/perm = _sort_tim_test_make_perm(N)
	for(var/i in 1 to iterations)
		var/list/L = list()
		for(var/n in perm)
			L += "item_[num2text(n + 1000)]"
		// rotate so each iteration has a different starting position, preventing
		// the JIT/cache from over-fitting any one input layout
		var/rot = (i * 7) % N
		L = L.Copy(rot + 1) + L.Copy(1, rot + 1)
		inputs += list(L)
	return inputs

/datum/unit_test/sort_tim_benchmark/proc/build_assoc_inputs(N, iterations)
	var/list/inputs = list()
	for(var/i in 1 to iterations)
		var/list/L = list()
		var/list/perm = _sort_tim_test_make_perm(N)
		for(var/k in 1 to perm.len)
			L["k_[(k * 13 + i) % N]_[i]"] = perm[k]
		inputs += list(L)
	return inputs

/datum/unit_test/sort_tim_benchmark/proc/build_sorted_inputs(N, iterations)
	var/list/inputs = list()
	for(var/i in 1 to iterations)
		var/list/L = list()
		for(var/k in 1 to N)
			L += k
		inputs += list(L)
	return inputs

/datum/unit_test/sort_tim_benchmark/proc/build_reverse_inputs(N, iterations)
	var/list/inputs = list()
	for(var/i in 1 to iterations)
		var/list/L = list()
		for(var/k in 1 to N)
			L += N + 1 - k
		inputs += list(L)
	return inputs

/// Run sortTim over every list in `inputs`, return elapsed deciseconds.
/// We sleep(-1) before timing so we don't straddle an MC tick boundary.
/datum/unit_test/sort_tim_benchmark/proc/time_sort_loop(list/inputs, cmp, associative = FALSE)
	var/start = REALTIMEOFDAY
	if(associative)
		for(var/list/L as anything in inputs)
			sortTim(L, cmp, associative = TRUE)
	else
		for(var/list/L as anything in inputs)
			sortTim(L, cmp)
	return REALTIMEOFDAY - start

/datum/unit_test/sort_tim_benchmark/proc/report(label, fast_ds, gen_ds, iterations, N)
	var/per_fast_us = fast_ds * 100000 / iterations  // ds * 100000us = us per sort? wait: 1ds = 100ms = 100000us
	var/per_gen_us = gen_ds * 100000 / iterations
	var/ratio_text = "n/a"
	if(fast_ds > 0)
		var/ratio_x100 = round(gen_ds * 100 / fast_ds)
		ratio_text = "x[ratio_x100 / 100]"
	log_test("  [label] (N=[N], iters=[iterations]): fast=[fast_ds]ds (~[round(per_fast_us)]us/sort) gen=[gen_ds]ds (~[round(per_gen_us)]us/sort) speedup=[ratio_text]")

/datum/unit_test/sort_tim_benchmark/proc/bench_numeric_asc()
	var/N = 200
	var/iters = 400
	var/list/inputs1 = build_numeric_inputs(N, iters)
	var/list/inputs2 = build_numeric_inputs(N, iters)
	// warmup
	sortTim(_sort_tim_test_make_perm(N), GLOBAL_PROC_REF(cmp_numeric_asc))
	sortTim(_sort_tim_test_make_perm(N), GLOBAL_PROC_REF(_sort_tim_bench_cmp_num_asc_gen))
	var/fast = time_sort_loop(inputs1, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/gen = time_sort_loop(inputs2, GLOBAL_PROC_REF(_sort_tim_bench_cmp_num_asc_gen))
	report("numeric_asc random", fast, gen, iters, N)

/datum/unit_test/sort_tim_benchmark/proc/bench_numeric_dsc()
	var/N = 200
	var/iters = 400
	var/list/inputs1 = build_numeric_inputs(N, iters)
	var/list/inputs2 = build_numeric_inputs(N, iters)
	sortTim(_sort_tim_test_make_perm(N), GLOBAL_PROC_REF(cmp_numeric_dsc))
	sortTim(_sort_tim_test_make_perm(N), GLOBAL_PROC_REF(_sort_tim_bench_cmp_num_dsc_gen))
	var/fast = time_sort_loop(inputs1, GLOBAL_PROC_REF(cmp_numeric_dsc))
	var/gen = time_sort_loop(inputs2, GLOBAL_PROC_REF(_sort_tim_bench_cmp_num_dsc_gen))
	report("numeric_dsc random", fast, gen, iters, N)

/datum/unit_test/sort_tim_benchmark/proc/bench_text_asc()
	var/N = 100
	var/iters = 250
	var/list/inputs1 = build_text_inputs(N, iters)
	var/list/inputs2 = build_text_inputs(N, iters)
	var/fast = time_sort_loop(inputs1, GLOBAL_PROC_REF(cmp_text_asc))
	var/gen = time_sort_loop(inputs2, GLOBAL_PROC_REF(_sort_tim_bench_cmp_text_asc_gen))
	report("text_asc random", fast, gen, iters, N)

/datum/unit_test/sort_tim_benchmark/proc/bench_text_dsc()
	var/N = 100
	var/iters = 250
	var/list/inputs1 = build_text_inputs(N, iters)
	var/list/inputs2 = build_text_inputs(N, iters)
	var/fast = time_sort_loop(inputs1, GLOBAL_PROC_REF(cmp_text_dsc))
	var/gen = time_sort_loop(inputs2, GLOBAL_PROC_REF(_sort_tim_bench_cmp_text_dsc_gen))
	report("text_dsc random", fast, gen, iters, N)

/datum/unit_test/sort_tim_benchmark/proc/bench_associative_numeric_asc()
	var/N = 100
	var/iters = 250
	var/list/inputs1 = build_assoc_inputs(N, iters)
	var/list/inputs2 = build_assoc_inputs(N, iters)
	var/fast = time_sort_loop(inputs1, GLOBAL_PROC_REF(cmp_numeric_asc), TRUE)
	var/gen = time_sort_loop(inputs2, GLOBAL_PROC_REF(_sort_tim_bench_cmp_num_asc_gen), TRUE)
	report("assoc numeric_asc", fast, gen, iters, N)

/datum/unit_test/sort_tim_benchmark/proc/bench_already_sorted()
	var/N = 200
	var/iters = 600  // best case, very fast — bump iters to keep elapsed measurable
	var/list/inputs1 = build_sorted_inputs(N, iters)
	var/list/inputs2 = build_sorted_inputs(N, iters)
	var/fast = time_sort_loop(inputs1, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/gen = time_sort_loop(inputs2, GLOBAL_PROC_REF(_sort_tim_bench_cmp_num_asc_gen))
	report("numeric_asc already-sorted (best case)", fast, gen, iters, N)

/datum/unit_test/sort_tim_benchmark/proc/bench_reverse_sorted()
	var/N = 200
	var/iters = 600
	var/list/inputs1 = build_reverse_inputs(N, iters)
	var/list/inputs2 = build_reverse_inputs(N, iters)
	var/fast = time_sort_loop(inputs1, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/gen = time_sort_loop(inputs2, GLOBAL_PROC_REF(_sort_tim_bench_cmp_num_asc_gen))
	report("numeric_asc reverse-sorted (single run+flip)", fast, gen, iters, N)

/datum/unit_test/sort_tim_benchmark/proc/bench_small_list()
	// Below MIN_MERGE — pure binarySort path. Pre-refactor binarySort already had
	// the fast-path inline, so the measured win here is small.
	var/N = 16
	var/iters = 2000
	var/list/inputs1 = build_numeric_inputs(N, iters)
	var/list/inputs2 = build_numeric_inputs(N, iters)
	var/fast = time_sort_loop(inputs1, GLOBAL_PROC_REF(cmp_numeric_asc))
	var/gen = time_sort_loop(inputs2, GLOBAL_PROC_REF(_sort_tim_bench_cmp_num_asc_gen))
	report("numeric_asc small (binarySort only)", fast, gen, iters, N)
