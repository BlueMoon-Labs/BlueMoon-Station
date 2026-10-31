/// Пины схем хранят датумы слабыми ссылками, и в списках тоже: чтение отдаёт копию с разрешёнными ссылками.
/datum/unit_test/integrated_circuit_list_refs

/datum/unit_test/integrated_circuit_list_refs/proc/stored_value(obj/item/integrated_circuit/chip, pin_type, pin_number)
	var/datum/integrated_io/pin = chip.get_pin_ref(pin_type, pin_number)
	return pin.data

/datum/unit_test/integrated_circuit_list_refs/proc/stored_entry(obj/item/integrated_circuit/chip, pin_type, pin_number, index)
	var/list/stored = stored_value(chip, pin_type, pin_number)
	return stored[index]

/datum/unit_test/integrated_circuit_list_refs/proc/read_entry(obj/item/integrated_circuit/chip, pin_type, pin_number, index)
	var/list/read = chip.get_pin_data(pin_type, pin_number)
	return read[index]

/datum/unit_test/integrated_circuit_list_refs/proc/pulse(obj/item/integrated_circuit/chip)
	chip.check_then_do_work(1, ignore_power = TRUE)

/datum/unit_test/integrated_circuit_list_refs/Run()
	var/obj/item/integrated_circuit/lists/append/append = allocate(/obj/item/integrated_circuit/lists/append)
	var/obj/item/integrated_circuit/lists/at/at = allocate(/obj/item/integrated_circuit/lists/at)
	var/obj/item/integrated_circuit/lists/search/search = allocate(/obj/item/integrated_circuit/lists/search)
	var/obj/item/integrated_circuit/lists/pick/pick = allocate(/obj/item/integrated_circuit/lists/pick)
	var/obj/item/integrated_circuit/transfer/demultiplexer/demux = allocate(/obj/item/integrated_circuit/transfer/demultiplexer)
	var/datum/integrated_io/appended = append.get_pin_ref(IC_OUTPUT, 1)
	appended.connect_pin(at.get_pin_ref(IC_INPUT, 1))
	appended.connect_pin(search.get_pin_ref(IC_INPUT, 1))
	appended.connect_pin(pick.get_pin_ref(IC_INPUT, 1))

	var/obj/item/pen/item = new(run_loc_floor_bottom_left)
	append.set_pin_data(IC_INPUT, 2, item)
	pulse(append)
	TEST_ASSERT(isweakref(stored_entry(append, IC_OUTPUT, 1, 1)), "append хранит атом в списке жёсткой ссылкой")
	TEST_ASSERT(read_entry(append, IC_OUTPUT, 1, 1) == item, "Чтение списка не разрешило слабую ссылку")
	TEST_ASSERT(isweakref(stored_entry(append, IC_OUTPUT, 1, 1)), "Чтение списка подменило слабую ссылку в пине на атом")
	TEST_ASSERT(isweakref(stored_entry(at, IC_INPUT, 1, 1)), "Список, переданный по проводу, хранит атом жёстко")

	at.set_pin_data(IC_INPUT, 2, 1)
	pulse(at)
	TEST_ASSERT(at.get_pin_data(IC_OUTPUT, 1) == item, "at не выдал атом по индексу")
	search.set_pin_data(IC_INPUT, 2, item)
	pulse(search)
	TEST_ASSERT(search.get_pin_data(IC_OUTPUT, 1) == 1, "search не нашёл атом в списке")
	pulse(pick)
	TEST_ASSERT(pick.get_pin_data(IC_OUTPUT, 1) == item, "pick не выдал атом из списка")
	TEST_ASSERT(isweakref(stored_value(pick, IC_OUTPUT, 1)), "Одиночный пин хранит атом жёстко")

	demux.set_pin_data(IC_INPUT, 1, 1)
	demux.set_pin_data(IC_INPUT, 2, item)
	pulse(demux)
	TEST_ASSERT(isweakref(stored_value(demux, IC_OUTPUT, 1)), "Демультиплексор кладёт атом в выход жёсткой ссылкой")
	TEST_ASSERT(demux.get_pin_data(IC_OUTPUT, 1) == item, "Демультиплексор не передал атом")

	qdel(item)
	TEST_ASSERT(isnull(read_entry(append, IC_OUTPUT, 1, 1)), "Удалённый атом читается из списка не как null")
	TEST_ASSERT(isnull(pick.get_pin_data(IC_OUTPUT, 1)), "Удалённый атом читается из одиночного пина не как null")
	TEST_ASSERT_EQUAL(refcount(item), 1, "Пины схем держат удалённый атом")

/// Локатор по списку образцов сравнивает типы атомов, а не слабых ссылок на них.
/datum/unit_test/integrated_circuit_locator_list_refs

/datum/unit_test/integrated_circuit_locator_list_refs/Run()
	var/obj/item/integrated_circuit/input/advanced_locator_list/locator = allocate(/obj/item/integrated_circuit/input/advanced_locator_list)
	var/obj/item/pen/sample = allocate(/obj/item/pen)
	var/obj/item/pen/target = allocate(/obj/item/pen, locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	locator.set_pin_data(IC_INPUT, 1, list(sample))
	locator.set_pin_data(IC_INPUT, 2, 1)
	locator.check_then_do_work(1, ignore_power = TRUE)
	var/list/found = locator.get_pin_data(IC_OUTPUT, 1)
	TEST_ASSERT(target in found, "Локатор не нашёл предмет того же типа, что образец из списка")
