/// Test-only locator that records which output pulse was emitted.
/obj/item/integrated_circuit/input/advanced_locator/unit_test
	var/found_pulses = 0
	var/not_found_pulses = 0

/obj/item/integrated_circuit/input/advanced_locator/unit_test/activate_pin(pin_number)
	if(pin_number == 2)
		found_pulses++
	else if(pin_number == 3)
		not_found_pulses++
	return ..()

/// Exact-type target for the reference-input branch.
/obj/effect/advanced_locator_unit_test_target
	name = "advanced locator type target"
	desc = "type lookup fixture"

/obj/effect/advanced_locator_unit_test_target/subtype
	name = "advanced locator subtype decoy"

/// Uniquely named target for the text-input branch.
/obj/effect/advanced_locator_unit_test_text_target
	name = "unique advanced locator needle"
	desc = "text lookup fixture"

/// Adds realistic density to the benchmark's view() result.
/obj/effect/advanced_locator_unit_test_clutter
	name = "advanced locator benchmark clutter"

/// Non-atom target for weakref input validation.
/datum/advanced_locator_unit_test_non_atom

/// Covers output/pulse equivalence for rejected inputs and preserves both valid search modes.
/datum/unit_test/advanced_locator_behavior/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/obj/item/integrated_circuit/input/advanced_locator/unit_test/locator = allocate(/obj/item/integrated_circuit/input/advanced_locator/unit_test, test_turf)
	locator.radius = 8

	locator.set_pin_data(IC_INPUT, 1, 123)
	locator.do_work()
	TEST_ASSERT(isnull(locator.get_pin_data(IC_OUTPUT, 1)), "Unsupported input must clear the located-ref output")
	TEST_ASSERT_EQUAL(locator.not_found_pulses, 1, "Unsupported input must emit exactly one not-found pulse")
	TEST_ASSERT_EQUAL(locator.found_pulses, 0, "Unsupported input must not emit a found pulse")

	var/obj/effect/advanced_locator_unit_test_target/dead_target = allocate(/obj/effect/advanced_locator_unit_test_target, test_turf)
	var/datum/weakref/dead_ref = WEAKREF(dead_target)
	qdel(dead_target, force = TRUE)
	locator.set_pin_data(IC_INPUT, 1, dead_ref)
	locator.do_work()
	TEST_ASSERT(isnull(locator.get_pin_data(IC_OUTPUT, 1)), "A dead reference must clear the located-ref output")
	TEST_ASSERT_EQUAL(locator.not_found_pulses, 2, "A dead reference must emit exactly one not-found pulse")
	TEST_ASSERT_EQUAL(locator.found_pulses, 0, "A dead reference must not emit a found pulse")

	var/datum/advanced_locator_unit_test_non_atom/non_atom_target = new
	allocated += non_atom_target
	locator.set_pin_data(IC_INPUT, 1, WEAKREF(non_atom_target))
	locator.do_work()
	TEST_ASSERT(isnull(locator.get_pin_data(IC_OUTPUT, 1)), "A non-atom reference must clear the located-ref output")
	TEST_ASSERT_EQUAL(locator.not_found_pulses, 3, "A non-atom reference must emit exactly one not-found pulse")
	TEST_ASSERT_EQUAL(locator.found_pulses, 0, "A non-atom reference must not emit a found pulse")

	var/obj/effect/advanced_locator_unit_test_target/type_target = allocate(/obj/effect/advanced_locator_unit_test_target, test_turf)
	allocate(/obj/effect/advanced_locator_unit_test_target/subtype, test_turf)
	locator.set_pin_data(IC_INPUT, 1, type_target)
	locator.do_work()
	TEST_ASSERT_EQUAL(locator.get_pin_data(IC_OUTPUT, 1), type_target, "Reference lookup must retain exact-type matching and exclude subtypes")
	TEST_ASSERT_EQUAL(locator.found_pulses, 1, "A reference match must emit exactly one found pulse")
	TEST_ASSERT_EQUAL(locator.not_found_pulses, 3, "A reference match must not emit a not-found pulse")

	var/obj/effect/advanced_locator_unit_test_text_target/text_target = allocate(/obj/effect/advanced_locator_unit_test_text_target, test_turf)
	locator.set_pin_data(IC_INPUT, 1, "unique advanced locator needle")
	locator.do_work()
	TEST_ASSERT_EQUAL(locator.get_pin_data(IC_OUTPUT, 1), text_target, "Text lookup must still match the combined name and description")
	TEST_ASSERT_EQUAL(locator.found_pulses, 2, "A text match must emit exactly one found pulse")
	TEST_ASSERT_EQUAL(locator.not_found_pulses, 3, "A text match must not emit a not-found pulse")

/// The pre-optimization implementation, retained only for a paired invalid-input benchmark.
/datum/unit_test/advanced_locator_invalid_input_bench/proc/reference_do_work(obj/item/integrated_circuit/input/advanced_locator/unit_test/locator)
	var/datum/integrated_io/I = locator.inputs[1]
	var/datum/integrated_io/O = locator.outputs[1]
	O.data = null
	var/turf/T = get_turf(locator)
	var/list/nearby_things = view(locator.radius, T)
	var/list/valid_things = list()
	if(isweakref(I.data))
		var/atom/A = I.data.resolve()
		if(!A)
			O.push_data()
			locator.activate_pin(3)
			return
		var/desired_type = A.type
		if(desired_type)
			for(var/atom/thing as anything in nearby_things)
				if(ismob(thing) && !isliving(thing))
					continue
				if(thing.type == desired_type)
					valid_things.Add(thing)
	else if(istext(I.data))
		var/DT = I.data
		for(var/atom/thing as anything in nearby_things)
			if(ismob(thing) && !isliving(thing))
				continue
			if(findtext(addtext(thing.name, " ", thing.desc), DT, 1, 0))
				valid_things.Add(thing)
	if(valid_things.len)
		O.data = WEAKREF(pick(valid_things))
		O.push_data()
		locator.activate_pin(2)
	else
		O.push_data()
		locator.activate_pin(3)

/// Profiles the logged abuse shape: repeated activations with an invalid input in a populated radius.
/datum/unit_test/advanced_locator_invalid_input_bench
	priority = TEST_LONGER

/datum/unit_test/advanced_locator_invalid_input_bench/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/obj/item/integrated_circuit/input/advanced_locator/unit_test/locator = allocate(/obj/item/integrated_circuit/input/advanced_locator/unit_test, test_turf)
	locator.radius = 8
	locator.set_pin_data(IC_INPUT, 1, 123)

	for(var/i in 1 to 512)
		allocate(/obj/effect/advanced_locator_unit_test_clutter, test_turf)

	var/iterations = 1000
	var/start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		reference_do_work(locator)
	var/reference_ms = TICK_USAGE_TO_MS(start_time)
	TEST_ASSERT_EQUAL(locator.not_found_pulses, iterations, "Reference path must emit one not-found pulse per activation")

	locator.not_found_pulses = 0
	start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		locator.do_work()
	var/optimized_ms = TICK_USAGE_TO_MS(start_time)
	TEST_ASSERT_EQUAL(locator.not_found_pulses, iterations, "Optimized path must emit one not-found pulse per activation")
	TEST_ASSERT(isnull(locator.get_pin_data(IC_OUTPUT, 1)), "Both invalid-input paths must leave a null output")
	log_test("ADVANCED LOCATOR BENCH: forced view [round(reference_ms, 0.01)]ms vs early reject [round(optimized_ms, 0.01)]ms for [iterations] activations ([round(reference_ms / max(optimized_ms, 0.01), 0.1)]x)")
