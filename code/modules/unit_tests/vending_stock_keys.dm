// Regression test: ui_data() stock must key records uniquely. Product names are not unique
// (translated items and duplicates across products/contraband share display names), so a
// name-keyed stock map let one record overwrite another's amount - the count in the UI froze
// on the shadowing record's value until the real one said "sold out".

/datum/unit_test/vending_stock_keys/Run()
	var/obj/machinery/vending/machine = allocate(/obj/machinery/vending/assist)
	var/mob/user = allocate(/mob)

	// Two different products that share one display name, plus a contraband twin.
	var/datum/data/vending_product/first = new
	first.name = "тестовый товар"
	first.product_path = /obj/item/pen
	first.amount = 5

	var/datum/data/vending_product/second = new
	second.name = "тестовый товар"
	second.product_path = /obj/item/pen/red
	second.amount = 3

	var/datum/data/vending_product/hidden = new
	hidden.name = "тестовый товар"
	hidden.product_path = /obj/item/pen/blue
	hidden.amount = 7

	machine.product_records = list(first, second)
	machine.coin_records = list()
	machine.hidden_records = list(hidden)

	var/list/data = machine.ui_data(user)
	var/list/stock = data["stock"]
	TEST_ASSERT_EQUAL(length(stock), 3, "every record must get its own stock entry even with duplicate names")

	// Each record must be resolvable by the same key the client reads from static data (REF).
	var/list/expected = list(first, second, hidden)
	for(var/datum/data/vending_product/record as anything in expected)
		TEST_ASSERT(REF(record) in stock, "stock entry for [record.product_path] must be keyed by its REF")
		TEST_ASSERT_EQUAL(stock[REF(record)], record.amount, "stock amount for [record.product_path] must come from its own record")

	// A purchase must be visible through the same key immediately.
	second.amount--
	data = machine.ui_data(user)
	stock = data["stock"]
	TEST_ASSERT_EQUAL(stock[REF(second)], 2, "a decremented record must report its new amount under its own key")

/// Exact pre-optimization stock payload for equivalence and paired timing.
/datum/unit_test/vending_stock_payload_bench/proc/reference_stock_data(obj/machinery/vending/machine)
	. = list()
	for(var/datum/data/vending_product/product_record in machine.product_records + machine.coin_records + machine.hidden_records)
		var/list/product_data = list(
			name = product_record.name,
			amount = product_record.amount,
			colorable = product_record.colorable,
			free = !!product_record.returned_products,
		)
		.[REF(product_record)] = product_data

/datum/unit_test/vending_stock_payload_bench
	priority = TEST_LONGER

/datum/unit_test/vending_stock_payload_bench/Run()
	var/obj/machinery/vending/machine = allocate(/obj/machinery/vending/assist)
	machine.product_records = list()
	machine.coin_records = list()
	machine.hidden_records = list()

	for(var/i in 1 to 180)
		var/datum/data/vending_product/record = new
		record.name = "benchmark product [i]"
		record.product_path = /obj/item/pen
		record.amount = i % 12
		record.max_amount = 12
		record.colorable = !(i % 3)
		if(!(i % 10))
			record.returned_products = list(/obj/item/pen)
		if(i <= 120)
			machine.product_records += record
		else if(i <= 150)
			machine.coin_records += record
		else
			machine.hidden_records += record

	var/list/reference = reference_stock_data(machine)
	var/list/optimized_payload = machine.collect_stock_data()
	var/list/optimized = optimized_payload["stock"]
	var/list/optimized_free = optimized_payload["free_stock"]
	TEST_ASSERT_EQUAL(length(optimized), length(reference), "Stock payload must retain every record")
	for(var/record_ref in reference)
		var/list/reference_entry = reference[record_ref]
		TEST_ASSERT(record_ref in optimized, "Optimized stock payload lost [record_ref]")
		TEST_ASSERT_EQUAL(optimized[record_ref], reference_entry["amount"], "Stock amount changed for [record_ref]")
		TEST_ASSERT_EQUAL(!!optimized_free[record_ref], !!reference_entry["free"], "Returned-product state changed for [record_ref]")

	var/mob/user = allocate(/mob)
	var/list/static_data = machine.ui_static_data(user)
	var/list/all_static_records = static_data["product_records"] + static_data["coin_records"] + static_data["hidden_records"]
	var/static_colorable_count = 0
	for(var/list/static_record as anything in all_static_records)
		if(static_record["colorable"])
			static_colorable_count++
	TEST_ASSERT_EQUAL(static_colorable_count, 60, "Colorability must move to static data without changing its values")

	var/iterations = 500
	var/start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		reference = reference_stock_data(machine)
	var/reference_ms = TICK_USAGE_TO_MS(start_time)
	TEST_ASSERT_EQUAL(length(reference), 180, "Reference benchmark payload has an unexpected size")

	start_time = TICK_USAGE_REAL
	for(var/i in 1 to iterations)
		optimized_payload = machine.collect_stock_data()
	var/optimized_ms = TICK_USAGE_TO_MS(start_time)
	optimized = optimized_payload["stock"]
	TEST_ASSERT_EQUAL(length(optimized), 180, "Optimized benchmark payload has an unexpected size")
	log_test("VENDING STOCK BENCH: redundant dynamic fields [round(reference_ms, 0.01)]ms vs split static/dynamic [round(optimized_ms, 0.01)]ms for [iterations] updates ([round(reference_ms / max(optimized_ms, 0.01), 0.1)]x)")

// Brand Intelligence turns infected vendors into mimics. The original machine must
// remain inside the mimic and fall back onto the turf when that mimic dies.
/datum/unit_test/vending_mimic_restores_machine/Run()
	var/obj/machinery/vending/machine = allocate(/obj/machinery/vending/assist)
	var/mob/living/simple_animal/hostile/mimic/copy/vending/mimic = allocate(
		/mob/living/simple_animal/hostile/mimic/copy/vending,
		run_loc_floor_bottom_left,
		machine,
	)

	TEST_ASSERT(!QDELETED(machine), "creating a Brand Intelligence mimic must not delete its vending machine")
	TEST_ASSERT_EQUAL(machine.loc, mimic, "the vending machine must be stored inside its mimic while it is alive")

	var/turf/death_turf = get_turf(mimic)
	mimic.death()

	TEST_ASSERT(!QDELETED(machine), "the vending machine must survive the mimic's death")
	TEST_ASSERT_EQUAL(machine.loc, death_turf, "the vending machine must fall onto the mimic's turf when it dies")
