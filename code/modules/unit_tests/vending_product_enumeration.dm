/// Статический обход ассортимента даёт один и тот же набор и в том же порядке при одном и том же коде.
/datum/unit_test/vending_product_enumeration_is_deterministic
	requires_full_map = FALSE

/datum/unit_test/vending_product_enumeration_is_deterministic/Run()
	var/list/first = collect_vending_product_types()
	TEST_ASSERT(length(first) > 0, "статический обход вендоматов не нашёл ни одного товара")

	var/list/second = collect_vending_product_types()
	TEST_ASSERT_EQUAL(length(second), length(first), "два обхода подряд дали разное число товаров")

	// Порядок - тоже часть входа хэша: шарды листа режутся по порядку записей.
	for(var/index in 1 to length(first))
		if(first[index] == second[index])
			continue
		TEST_FAIL("обходы разошлись на позиции [index]: [first[index]] против [second[index]]")
		return

/// Статический обход покрывает всё, что набралось в GLOB.vending_products этого раунда.
/datum/unit_test/vending_static_walk_covers_round_products
	requires_full_map = FALSE

/datum/unit_test/vending_static_walk_covers_round_products/Run()
	var/list/static_products = collect_vending_product_types()
	var/list/missed = list()
	for(var/product_path in GLOB.vending_products)
		if(!(product_path in static_products))
			missed += product_path

	TEST_ASSERT(!length(missed), "статический обход не покрыл [length(missed)] товар(ов) из GLOB.vending_products: [jointext(missed, ", ")]")

/// Обход не оставляет за собой машин в нулевом пространстве.
/datum/unit_test/vending_enumeration_leaves_no_machines
	requires_full_map = FALSE

/datum/unit_test/vending_enumeration_leaves_no_machines/Run()
	var/machines_before = length(GLOB.machines)
	collect_vending_product_types()

	TEST_ASSERT_EQUAL(length(GLOB.machines), machines_before, "обход ассортимента оставил после себя машины в нулевом пространстве")

/// Пропущенный статическим обходом товар всё равно попадает во вход листа.
/datum/unit_test/vending_sheet_adds_products_missed_by_static_walk
	requires_full_map = FALSE

/datum/unit_test/vending_sheet_adds_products_missed_by_static_walk/Run()
	var/list/static_products = collect_vending_product_types()
	// Товар вне ассортимента, но со спрайтом в файле: без спрайта лист выбросил бы его законно.
	var/atom/orphan
	for(var/atom/candidate as anything in list(/obj/item/nuclear_challenge, /obj/item/paper, /obj/item/toy/cards/deck))
		if(static_products[candidate])
			continue
		if(!(initial(candidate.icon_state) in icon_states(initial(candidate.icon))))
			continue
		orphan = candidate
		break
	TEST_ASSERT_NOTNULL(orphan, "не нашлось товара вне ассортимента со спрайтом в файле - тесту нечем проверять добор")

	var/list/missed = log_vending_products_missed_by_static_walk(list(orphan), static_products)
	TEST_ASSERT_EQUAL(length(missed), 1, "сверка обязана вернуть ровно один пропущенный товар")
	TEST_ASSERT_EQUAL(missed[1], orphan, "сверка обязана вернуть именно пропущенный товар")
	var/list/covering_set = list()
	covering_set[orphan] = TRUE
	TEST_ASSERT_EQUAL(length(log_vending_products_missed_by_static_walk(list(orphan), covering_set)), 0, "товар из статического набора не должен считаться пропущенным")

	var/list/saved_round_products = GLOB.vending_products.Copy()
	GLOB.vending_products |= orphan
	var/list/sheet_products = collect_vending_sheet_product_types()
	GLOB.vending_products = saved_round_products
	TEST_ASSERT(sheet_products[orphan], "пропущенный статическим обходом товар [orphan] не попал во вход листа - на витрине он останется без спрайта")
	TEST_ASSERT(length(sheet_products) >= length(static_products) + 1, "вход листа обязан быть статическим набором плюс пропущенные товары")

/// Свип подменышей удаляет только машины без loc, машину с карты не трогает.
/datum/unit_test/vending_enumeration_stray_sweep_spares_mapped_machines
	requires_full_map = FALSE

/datum/unit_test/vending_enumeration_stray_sweep_spares_mapped_machines/Run()
	var/machines_before = length(GLOB.machines)
	var/obj/machinery/vending/mapped = allocate(/obj/machinery/vending/snack, run_loc_floor_bottom_left)
	TEST_ASSERT(mapped in GLOB.machines, "Sanity: машина на турфе обязана числиться в GLOB.machines")
	TEST_ASSERT(length(GLOB.machines) > machines_before, "Sanity: хвост GLOB.machines вырос на нашу машину")

	qdel_vending_enumeration_strays(machines_before)
	TEST_ASSERT(!QDELETED(mapped), "свип подменышей удалил машину, стоящую на турфе")

	var/obj/machinery/vending/stray = new /obj/machinery/vending/snack(null)
	TEST_ASSERT(stray in GLOB.machines, "Sanity: машина в нулевом пространстве числится в GLOB.machines")
	qdel_vending_enumeration_strays(machines_before)
	TEST_ASSERT(QDELETED(stray), "свип подменышей обязан удалить машину без loc")
	TEST_ASSERT(!QDELETED(mapped), "свип подменышей не должен трогать машину на турфе даже рядом с настоящим подменышем")
