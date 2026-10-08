/// Плату консоли заданий брига можно напечатать: без дизайна сломанную консоль штрафов не восстановить.
/datum/unit_test/brig_assistant_board_printable

/datum/unit_test/brig_assistant_board_printable/Run()
	var/datum/design/board_design = SSresearch.techweb_designs["brig_assistant_console"]
	TEST_ASSERT_NOTNULL(board_design, "Нет дизайна платы консоли заданий брига")
	TEST_ASSERT_EQUAL(board_design.build_path, /obj/item/circuitboard/computer/brig_assistant_console, "Дизайн печатает не ту плату")
	TEST_ASSERT(board_design.build_type & IMPRINTER, "Плату нельзя напечатать в импринтере")
	TEST_ASSERT(board_design.departmental_flags & DEPARTMENTAL_FLAG_SECURITY, "Плату нельзя напечатать на фабрикаторе СБ")

	var/datum/techweb_node/node = SSresearch.techweb_nodes["comp_recordkeeping"]
	TEST_ASSERT_NOTNULL(node, "Нет узла Computerized Recordkeeping")
	TEST_ASSERT(node.design_ids["brig_assistant_console"], "Узел с консолями записей СБ не открывает плату консоли заданий брига")

/// На станции есть консоль заданий брига: через неё оплачивают штрафы.
/datum/unit_test/station_has_brig_assistant_console
	requires_full_map = TRUE

/datum/unit_test/station_has_brig_assistant_console/Run()
	for(var/obj/machinery/computer/brig_assistant_console/console as anything in SSmachines.get_machines_by_type(/obj/machinery/computer/brig_assistant_console))
		if(is_station_level(console.z))
			return
	TEST_FAIL("На станции нет консоли заданий брига")
