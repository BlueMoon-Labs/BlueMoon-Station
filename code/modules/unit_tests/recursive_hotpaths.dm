/obj/effect/get_all_contents_test_container
	name = "GetAllContents test container"

/obj/effect/get_all_contents_test_leaf
	name = "GetAllContents test leaf"

/obj/effect/get_all_contents_test_other
	name = "GetAllContents test non-match"

/obj/effect/hearer_contents_test_container
	name = "hearer contents test container"
	flags_1 = HEAR_1

/obj/effect/hearer_contents_test_leaf
	name = "hearer contents test leaf"

/obj/effect/hearer_contents_test_listener
	name = "nested hearer contents test listener"
	flags_1 = HEAR_1

/// Exact pre-optimization GetAllContents implementation for paired equivalence and timing.
/datum/unit_test/get_all_contents_fast_leaf/proc/reference_get_all_contents(atom/root, filter_type)
	var/list/processing_list = list(root)
	var/i = 0
	var/lim = 1
	if(filter_type)
		. = list()
		while(i < lim)
			var/atom/A = processing_list[++i]
			processing_list += A.contents
			lim = processing_list.len
			if(istype(A, filter_type))
				. += A
	else
		while(i < lim)
			var/atom/A = processing_list[++i]
			processing_list += A.contents
			lim = processing_list.len
		return processing_list

/datum/unit_test/proc/assert_same_list_order(list/reference, list/optimized, length_error, order_error)
	TEST_ASSERT_EQUAL(length(optimized), length(reference), length_error)
	for(var/i in 1 to length(reference))
		TEST_ASSERT_EQUAL(optimized[i], reference[i], "[order_error] at index [i]")

/datum/unit_test/get_all_contents_fast_leaf
	priority = TEST_LONGER

/datum/unit_test/get_all_contents_fast_leaf/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/obj/effect/get_all_contents_test_container/root = allocate(/obj/effect/get_all_contents_test_container, test_turf)
	allocate(/obj/effect/get_all_contents_test_leaf, root)
	var/obj/effect/get_all_contents_test_container/nested = allocate(/obj/effect/get_all_contents_test_container, root)
	allocate(/obj/effect/get_all_contents_test_other, nested)
	allocate(/obj/effect/get_all_contents_test_leaf, nested)

	assert_same_list_order(reference_get_all_contents(root, null), root.GetAllContents(), "unfiltered nested tree: result length changed", "unfiltered nested tree: result order changed")
	assert_same_list_order(reference_get_all_contents(root, /obj/effect/get_all_contents_test_leaf), root.GetAllContents(/obj/effect/get_all_contents_test_leaf), "filtered nested tree: result length changed", "filtered nested tree: result order changed")

	var/obj/effect/get_all_contents_test_leaf/lone_leaf = allocate(/obj/effect/get_all_contents_test_leaf, test_turf)
	assert_same_list_order(reference_get_all_contents(lone_leaf, null), lone_leaf.GetAllContents(), "unfiltered leaf: result length changed", "unfiltered leaf: result order changed")
	assert_same_list_order(reference_get_all_contents(lone_leaf, /obj/effect/get_all_contents_test_leaf), lone_leaf.GetAllContents(/obj/effect/get_all_contents_test_leaf), "matching filtered leaf: result length changed", "matching filtered leaf: result order changed")
	assert_same_list_order(reference_get_all_contents(lone_leaf, /mob), lone_leaf.GetAllContents(/mob), "non-matching filtered leaf: result length changed", "non-matching filtered leaf: result order changed")

	for(var/i in 1 to 256)
		allocate(/obj/effect/get_all_contents_test_leaf, root)

	var/iterations = 1000
	var/list/sink
	var/start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		sink = reference_get_all_contents(root, null)
	var/reference_tree_ms = TICK_USAGE_TO_MS(start_time)
	TEST_ASSERT_EQUAL(length(sink), 261, "Reference benchmark tree has an unexpected size")

	start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		sink = root.GetAllContents()
	var/optimized_tree_ms = TICK_USAGE_TO_MS(start_time)
	TEST_ASSERT_EQUAL(length(sink), 261, "Optimized benchmark tree has an unexpected size")

	iterations = 20000
	start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		sink = reference_get_all_contents(lone_leaf, null)
	var/reference_leaf_ms = TICK_USAGE_TO_MS(start_time)
	start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		sink = lone_leaf.GetAllContents()
	var/optimized_leaf_ms = TICK_USAGE_TO_MS(start_time)
	TEST_ASSERT_EQUAL(sink[1], lone_leaf, "Optimized leaf benchmark must return the source atom")

	log_test("GET ALL CONTENTS BENCH: flat tree old [round(reference_tree_ms, 0.01)]ms/new [round(optimized_tree_ms, 0.01)]ms ([round(reference_tree_ms / max(optimized_tree_ms, 0.01), 0.1)]x); leaf old [round(reference_leaf_ms, 0.01)]ms/new [round(optimized_leaf_ms, 0.01)]ms ([round(reference_leaf_ms / max(optimized_leaf_ms, 0.01), 0.1)]x)")

/// Exact pre-optimization hearer walk, including recursive inventory traversal.
/datum/unit_test/get_hearers_leaf_contents/proc/reference_get_hearers_in_view(range_to_use, atom/source)
	var/turf/T = get_turf(source)
	. = list()
	if(!T)
		return
	var/list/processing = list()
	if(range_to_use == 0)
		processing += T.contents
	else
		var/lum = T.luminosity
		T.luminosity = 6
		for(var/atom/movable/AM in view(range_to_use, T))
			processing += AM
		T.luminosity = lum
	var/i = 0
	while(i < length(processing))
		var/atom/A = processing[++i]
		if(A.flags_1 & HEAR_1)
			. += A
			SEND_SIGNAL(A, COMSIG_ATOM_HEARER_IN_VIEW, processing, .)
		processing += A.contents

/datum/unit_test/get_hearers_leaf_contents
	priority = TEST_LONGER

/datum/unit_test/get_hearers_leaf_contents/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/obj/effect/hearer_contents_test_container/container = allocate(/obj/effect/hearer_contents_test_container, test_turf)
	allocate(/obj/effect/hearer_contents_test_leaf, container)
	allocate(/obj/effect/hearer_contents_test_listener, container)

	var/list/reference = reference_get_hearers_in_view(0, test_turf)
	var/list/optimized = get_hearers_in_view(0, test_turf)
	assert_same_list_order(reference, optimized, "Recursive hearer count changed", "Recursive hearer order changed")

	for(var/i in 1 to 48)
		var/obj/effect/hearer_contents_test_container/bench_container = allocate(/obj/effect/hearer_contents_test_container, test_turf)
		for(var/j in 1 to 8)
			allocate(/obj/effect/hearer_contents_test_leaf, bench_container)

	var/iterations = 1000
	var/list/sink
	var/start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		sink = reference_get_hearers_in_view(7, test_turf)
	var/reference_ms = TICK_USAGE_TO_MS(start_time)
	var/reference_count = length(sink)

	start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		sink = get_hearers_in_view(7, test_turf)
	var/optimized_ms = TICK_USAGE_TO_MS(start_time)
	TEST_ASSERT_EQUAL(length(sink), reference_count, "Optimized hearer benchmark changed the number of listeners")
	log_test("GET HEARERS BENCH: recursive leaf walk old [round(reference_ms, 0.01)]ms/new [round(optimized_ms, 0.01)]ms for [iterations] calls ([round(reference_ms / max(optimized_ms, 0.01), 0.1)]x)")

/// contains_atom() и in_direct_access() отвечают на вопрос членства, который раньше
/// задавали через `in GetAllContents()` / `in DirectAccess()` - то есть собирая всё
/// дерево содержимого игрока на каждый клик, MouseDrop и тик квирка-реликвии. Тест
/// закрепляет, что быстрый ответ совпадает с медленным на всех интересных случаях:
/// иначе оптимизация тихо разойдётся со своим определением.
/datum/unit_test/direct_access_membership_matches_contents_walk/Run()
	var/turf/test_turf = run_loc_floor_bottom_left
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, test_turf)

	// Три уровня вложенности - ровно та форма, из-за которой GetAllContents на
	// игроке разворачивается в десятки элементов: сумка в мобе, коробка в сумке,
	// предмет в коробке.
	var/obj/item/held_bag = allocate(/obj/item, test_turf)
	held_bag.forceMove(user)
	var/obj/item/inner_box = allocate(/obj/item, test_turf)
	inner_box.forceMove(held_bag)
	var/obj/item/nested_item = allocate(/obj/item, test_turf)
	nested_item.forceMove(inner_box)

	var/obj/item/loose_item = allocate(/obj/item, test_turf)

	TEST_ASSERT(nested_item in user.GetAllContents(), "Sanity: вложенный предмет должен попадать в GetAllContents игрока")
	TEST_ASSERT(!(loose_item in user.GetAllContents()), "Sanity: предмет на полу не должен попадать в GetAllContents игрока")

	var/list/subjects = list(user, held_bag, inner_box, nested_item, loose_item, test_turf)

	// contains_atom == `in GetAllContents()` на каждом уровне вложенности и вне его.
	for(var/atom/subject as anything in subjects)
		var/expected = (subject in user.GetAllContents())
		TEST_ASSERT_EQUAL(!!user.contains_atom(subject), !!expected, "contains_atom() разошёлся с GetAllContents() на [subject.type]")

	TEST_ASSERT(!user.contains_atom(null), "contains_atom(null) обязан быть FALSE")

	// in_direct_access == `in DirectAccess()`, включая loc (турф) и внешний предмет.
	var/list/direct_access = user.DirectAccess()
	for(var/atom/subject as anything in subjects)
		var/expected = (subject in direct_access)
		TEST_ASSERT_EQUAL(!!user.in_direct_access(subject), !!expected, "in_direct_access() разошёлся с DirectAccess() на [subject.type]")

	// Тот же инвариант для не-моба: там DirectAccess это ровно list(src, loc).
	var/list/item_access = loose_item.DirectAccess()
	for(var/atom/subject as anything in subjects + list(loose_item))
		var/expected = (subject in item_access)
		TEST_ASSERT_EQUAL(!!loose_item.in_direct_access(subject), !!expected, "in_direct_access() у /obj/item разошёлся с DirectAccess() на [subject.type]")
