/// BYOND 516 ships native list reductions (values_sum, values_dot) that collapse
/// a whole DM loop over the gas list into one engine call. The hot atmos procs
/// use them, so their contract has to be pinned rather than assumed - especially
/// the two edge cases the old DM loops handled explicitly with `|| 0`:
/// an empty gas list, and a gas id present in the mixture but absent from the
/// coefficient list. If a future BYOND changes either behaviour, this test is
/// what says so, instead of every mixture in the game quietly getting the wrong
/// heat capacity.
/datum/unit_test/atmos_vector_reductions

/datum/unit_test/atmos_vector_reductions/proc/loop_sum(list/values)
	. = 0
	for(var/key, value in values)
		. += value

/// Float comparison has to be RELATIVE here. BYOND numbers are 32-bit floats, so
/// one ulp at a heat capacity of ~2000 J/K is already about 1.2e-4 - and the
/// native reduction does not accumulate in the same order as the DM loop, so the
/// two legitimately disagree in the last digit or two. An absolute 1e-4 tolerance
/// fails on a result that prints identically to six significant figures, which is
/// exactly how this test first failed. The gas simulation never cares: every
/// threshold it compares against (MINIMUM_MOLES_DELTA_TO_MOVE and friends) is
/// larger than this by many orders of magnitude.
/datum/unit_test/atmos_vector_reductions/proc/close_enough(a, b)
	return abs(a - b) <= max(0.0001, abs(b) * 0.00001)

/datum/unit_test/atmos_vector_reductions/proc/loop_dot(list/values, list/coefficients)
	. = 0
	for(var/key, value in values)
		. += (value || 0) * (coefficients[key] || 0)

/datum/unit_test/atmos_vector_reductions/Run()
	var/list/specific_heats = GLOB.gas_data.specific_heats
	TEST_ASSERT(length(specific_heats), "gas_data.specific_heats must be populated before this test runs")

	// Empty list: the DM loop returned 0 by falling out of the loop body. A null
	// here would poison every downstream max()/division, and `null == 0` is FALSE
	// in DM, so an isnull check is the only honest way to ask.
	var/list/empty = list()
	TEST_ASSERT(!isnull(values_sum(empty)), "values_sum() on an empty list must not return null")
	TEST_ASSERT_EQUAL(values_sum(empty), 0, "values_sum() on an empty list must be 0")
	TEST_ASSERT(!isnull(values_dot(empty, specific_heats)), "values_dot() with an empty left list must not return null")
	TEST_ASSERT_EQUAL(values_dot(empty, specific_heats), 0, "values_dot() with an empty left list must be 0")

	// Ordinary station air, plus a trace gas: the overwhelmingly common shape.
	var/datum/gas_mixture/mix = new(CELL_VOLUME)
	mix.set_moles(GAS_O2, MOLES_O2STANDARD)
	mix.set_moles(GAS_N2, MOLES_N2STANDARD)
	mix.set_moles(GAS_CO2, 0.37)
	mix.set_temperature(T20C)
	var/list/gases = mix.gases
	TEST_ASSERT(close_enough(values_sum(gases), loop_sum(gases)), "values_sum() must match the DM loop it replaced")
	var/native_dot = values_dot(gases, specific_heats)
	var/loop_dot_value = loop_dot(gases, specific_heats)
	TEST_ASSERT(close_enough(native_dot, loop_dot_value), "values_dot() must match the DM loop it replaced (native [native_dot] vs loop [loop_dot_value], difference [abs(native_dot - loop_dot_value)])")

	// A single gas: guards against a reduction that needs two elements to work.
	var/datum/gas_mixture/lone = new(CELL_VOLUME)
	lone.set_moles(GAS_PLASMA, 12.5)
	TEST_ASSERT_EQUAL(values_sum(lone.gases), 12.5, "values_sum() must handle a one-key list")
	TEST_ASSERT(close_enough(values_dot(lone.gases, specific_heats), loop_dot(lone.gases, specific_heats)), "values_dot() must handle a one-key list")

	// Orphan key: a gas id with no entry in the coefficient list. The DM loop
	// scored it zero through `coefficients[key] || 0`. heat_capacity() relies on
	// that - a reduction that instead errored, or treated the missing key as 1,
	// would silently change the heat capacity of any mixture holding a gas whose
	// metadata failed to register.
	var/list/with_orphan = gases.Copy()
	with_orphan["__atmos_vector_test_orphan"] = 5
	var/orphan_dot = values_dot(with_orphan, specific_heats)
	TEST_ASSERT(close_enough(orphan_dot, native_dot), "a gas id missing from the coefficient list must contribute zero to values_dot() (got [orphan_dot], expected [native_dot])")
	TEST_ASSERT(close_enough(values_sum(with_orphan), values_sum(gases) + 5), "values_sum() must count every key, coefficient list or not")

	// Argument order: callers in this codebase pass (moles, coefficients), tg
	// passes both orders in different files. If the operation were not symmetric
	// one of the two families would be silently wrong.
	TEST_ASSERT(close_enough(values_dot(specific_heats, gases), native_dot), "values_dot() must be symmetric in its arguments")

	// The procs that actually consume the reductions.
	TEST_ASSERT(close_enough(mix.total_moles(), loop_sum(gases)), "total_moles() must equal the sum of the gas list")
	TEST_ASSERT(close_enough(mix.heat_capacity(), max(loop_dot_value, mix.min_heat_capacity)), "heat_capacity() must equal the mole-weighted specific heats, floored by min_heat_capacity")

	// Memoisation must not survive a mutation: the cache key is mutation_rev, and
	// every mutator bumps it. This is the guard that makes the vector swap safe -
	// a stale cache would be indistinguishable from a wrong reduction.
	var/moles_before = mix.total_moles()
	mix.set_moles(GAS_O2, MOLES_O2STANDARD * 2)
	TEST_ASSERT_NOTEQUAL(mix.total_moles(), moles_before, "total_moles() must not serve a cached value after the gas list changed")
	TEST_ASSERT(close_enough(mix.total_moles(), loop_sum(mix.gases)), "total_moles() must match the loop after a mutation")

	qdel(mix)
	qdel(lone)
