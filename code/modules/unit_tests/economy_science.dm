/datum/unit_test/economy_science
	abstract_type = /datum/unit_test/economy_science
	var/datum/economy_department/science/science
	var/saved_budget
	var/list/saved_extracts
	var/list/stashed_contracts

/datum/unit_test/economy_science/New()
	. = ..()
	stashed_contracts = econ_test_stash_contracts()

/datum/unit_test/economy_science/proc/setup()
	science = SSeconomy.get_department(ACCOUNT_SCI)
	saved_budget = science.account.account_balance
	saved_extracts = science.extracts_seen.Copy()
	science.extracts_seen.Cut()

/datum/unit_test/economy_science/Destroy()
	econ_test_restore_contracts(stashed_contracts)
	if(science)
		science.account.debit(max(science.account.account_balance, 0), ECON_ADMIN)
		science.account.credit(saved_budget, ECON_ADMIN)
		science.extracts_seen = saved_extracts
		science = null
	return ..()

/datum/unit_test/economy_science/proc/research_on(datum/techweb/web, mob/user)
	var/obj/machinery/computer/rdconsole/console = allocate(/obj/machinery/computer/rdconsole/core)
	allocated += web
	SEND_SIGNAL(console, COMSIG_ATOM_SET_TECHWEB, web)
	var/datum/techweb_node/node
	for(var/id in web.available_nodes)
		var/datum/techweb_node/candidate = SSresearch.techweb_node_by_id(id)
		if(econ_node_points(candidate, web) > 0)
			node = candidate
			break
	TEST_ASSERT_NOTNULL(node, "Есть доступный платный узел")
	. = econ_node_points(node, web)
	var/list/price = node.get_price(web)
	web.add_point_list(price.Copy(), income = FALSE)
	TEST_ASSERT(console.research_node(node.id, user), "Консоль исследовала узел")
	TEST_ASSERT(web.researched_nodes[node.id], "Узел изучен")

/datum/unit_test/economy_science/proc/process_slime(obj/machinery/processor/slime/processor, colour)
	var/mob/living/simple_animal/slime/slime = allocate(/mob/living/simple_animal/slime, processor.loc, colour)
	slime.death()
	slime.forceMove(processor)
	processor.complete_processing()
	for(var/obj/item/slime_extract/extract in processor.loc)
		qdel(extract)

/datum/unit_test/economy_science/proc/extract_core(turf/where, colour)
	var/mob/living/carbon/human/surgeon = allocate(/mob/living/carbon/human, where)
	var/mob/living/simple_animal/slime/slime = allocate(/mob/living/simple_animal/slime, where, colour)
	slime.death()
	var/datum/surgery_step/extract_core/step = new
	step.success(surgeon, slime, BODY_ZONE_CHEST)
	qdel(step)
	for(var/obj/item/slime_extract/extract in where)
		qdel(extract)

/// Исследование узла со станционной консоли платит науке по стоимости узла.
/datum/unit_test/economy_science/node_pays/Run()
	setup()
	var/mob/living/carbon/human/scientist = allocate(/mob/living/carbon/human)
	var/before = science.account.account_balance
	var/points = research_on(new /datum/techweb/science, scientist)
	var/expected = round(points / ECON_NODE_POINTS_UNIT * SSeconomy.settings.work_prices[WORK_SCI_NODE])
	TEST_ASSERT(expected > 0, "Цена узла ненулевая")
	TEST_ASSERT_EQUAL(science.account.account_balance - before, expected, "Оплата узла")

/// Исследование во внестанционной сети науке не платит.
/datum/unit_test/economy_science/offstation_node_free/Run()
	setup()
	var/mob/living/carbon/human/scientist = allocate(/mob/living/carbon/human)
	var/before = science.account.account_balance
	research_on(new /datum/techweb/isolated, scientist)
	TEST_ASSERT_EQUAL(science.account.account_balance - before, 0, "Чужая сеть не платит")

/// Первый экстракт цвета из процессора платит, второй такой же - нет.
/datum/unit_test/economy_science/processor_extract_once/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/processor/slime/processor = allocate(/obj/machinery/processor/slime, station_turf)
	var/before = science.account.account_balance
	process_slime(processor, "rainbow")
	var/first = science.account.account_balance - before
	process_slime(processor, "rainbow")
	var/second = science.account.account_balance - before - first
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human, station_turf)
	TEST_ASSERT(findtext(jointext(processor.examine(viewer), "\n"), "экстракт каждого цвета"), "Процессор на станции описывает оплату")
	TEST_ASSERT_EQUAL(first, GLOB.econ_slime_extract_value["rainbow"] * SSeconomy.settings.work_prices[WORK_SCI_SLIME_DISCOVERY], "Первый радужный")
	TEST_ASSERT_EQUAL(second, 0, "Повтор не платит")

/// Ядро, извлечённое хирургией, тоже засчитывается как новый экстракт.
/datum/unit_test/economy_science/surgery_extract/Run()
	setup()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/before = science.account.account_balance
	extract_core(station_turf, "oil")
	TEST_ASSERT_EQUAL(science.account.account_balance - before, GLOB.econ_slime_extract_value["oil"] * SSeconomy.settings.work_prices[WORK_SCI_SLIME_DISCOVERY], "Хирургическое ядро")

/// Экстракты вне станции не платят, не помечают цвет, а процессор там оплату не обещает.
/datum/unit_test/economy_science/offstation_extract_free/Run()
	setup()
	TEST_ASSERT(!is_station_level(run_loc_floor_bottom_left.z), "Тестовая резервация не станционная")
	var/mob/living/carbon/human/viewer = allocate(/mob/living/carbon/human)
	var/obj/machinery/processor/slime/processor = allocate(/obj/machinery/processor/slime)
	var/before = science.account.account_balance
	process_slime(processor, "rainbow")
	extract_core(run_loc_floor_bottom_left, "oil")
	TEST_ASSERT_EQUAL(science.account.account_balance - before, 0, "Вне станции экстракты не платят")
	TEST_ASSERT(!("rainbow" in science.extracts_seen), "Процессор вне станции не помечает цвет")
	TEST_ASSERT(!("oil" in science.extracts_seen), "Хирургия вне станции не помечает цвет")
	TEST_ASSERT(!findtext(jointext(processor.examine(viewer), "\n"), "экстракт каждого цвета"), "Процессор вне станции оплату не обещает")

/// Консоль станционной сети упоминает оплату исследований, внестанционной - нет.
/datum/unit_test/economy_science/console_examine/Run()
	setup()
	var/mob/living/carbon/human/scientist = allocate(/mob/living/carbon/human)
	var/obj/machinery/computer/rdconsole/station_console = allocate(/obj/machinery/computer/rdconsole/core)
	var/obj/machinery/computer/rdconsole/offstation_console = allocate(/obj/machinery/computer/rdconsole/core)
	var/datum/techweb/station_web = new /datum/techweb/science
	var/datum/techweb/offstation_web = new /datum/techweb/isolated
	allocated += station_web
	allocated += offstation_web
	SEND_SIGNAL(station_console, COMSIG_ATOM_SET_TECHWEB, station_web)
	SEND_SIGNAL(offstation_console, COMSIG_ATOM_SET_TECHWEB, offstation_web)
	var/pay_line = "[SSeconomy.settings.work_prices[WORK_SCI_NODE]] кр. за [ECON_NODE_POINTS_UNIT] очков"
	TEST_ASSERT(findtext(jointext(station_console.examine(scientist), "\n"), pay_line), "Станционная консоль описывает оплату")
	TEST_ASSERT(!findtext(jointext(offstation_console.examine(scientist), "\n"), pay_line), "Внестанционная консоль оплату не обещает")

/// Находка ксеноархеологии, проданная сканером, платит науке, а не карго.
/datum/unit_test/economy_science/artifact_scanner/Run()
	setup()
	var/mob/living/carbon/human/scientist = allocate(/mob/living/carbon/human)
	var/obj/item/xenoarch/help/cargo/scanner = allocate(/obj/item/xenoarch/help/cargo)
	var/obj/item/ancientartifact/faunafossil/fossil = allocate(/obj/item/ancientartifact/faunafossil)
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	var/science_before = science.account.account_balance
	var/cargo_before = cargo.account_balance
	scanner.export_target(fossil, scientist, apply_elastic = FALSE)
	TEST_ASSERT(QDELETED(fossil), "Находка продана")
	TEST_ASSERT(science.account.account_balance > science_before, "Наука получила оплату за артефакт")
	TEST_ASSERT_EQUAL(cargo.account_balance, cargo_before, "Карго за артефакт не платят")

/// Скидка буста снижает оплату узла в своей сети и не трогает общую цену узла.
/datum/unit_test/economy_science/boosted_price_isolated/Run()
	var/datum/techweb/web = new /datum/techweb/science
	allocated += web
	var/datum/techweb_node/node
	for(var/id in SSresearch.techweb_nodes)
		var/datum/techweb_node/candidate = SSresearch.techweb_nodes[id]
		if(candidate.research_costs[TECHWEB_POINT_TYPE_GENERIC] > 1)
			node = candidate
			break
	TEST_ASSERT_NOTNULL(node, "Есть платный узел")
	var/full_points = econ_node_points(node, null)
	web.boosted_nodes[node.id] = list(TECHWEB_POINT_TYPE_GENERIC = round(node.research_costs[TECHWEB_POINT_TYPE_GENERIC] / 2))
	var/boosted_points = econ_node_points(node, web)
	TEST_ASSERT(boosted_points < full_points, "Буст снижает стоимость узла")
	TEST_ASSERT_EQUAL(econ_node_points(node, web), boosted_points, "Повторный расчёт цены не копит скидку")
	TEST_ASSERT_EQUAL(econ_node_points(node, null), full_points, "Общая цена узла не изменилась")
