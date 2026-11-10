/// Консоль круиза, подхватившая орбитальный объект шаттла, отпускает его при qdel.
/datum/unit_test/orbital_shuttle_console_ref/Run()
	var/obj/machinery/computer/shuttle_flight/console = allocate(/obj/machinery/computer/shuttle_flight)
	console.shuttleId = "unit_test_orbital_ref"
	var/datum/orbital_object/shuttle/orbital = new(new /datum/orbital_vector(0, 0))
	orbital.shuttle_port_id = console.shuttleId
	SSorbits.assoc_shuttles[console.shuttleId] = orbital

	console.process()
	TEST_ASSERT(console.shuttleObject == orbital, "консоль не подхватила шаттл, запущенный с другого пульта")

	qdel(orbital)
	TEST_ASSERT_NULL(console.shuttleObject, "консоль держит удалённый орбитальный объект шаттла")
	TEST_ASSERT(!(console.shuttleId in SSorbits.assoc_shuttles), "удалённый шаттл остался в SSorbits.assoc_shuttles")
	// Кроме локальной переменной теста ссылок быть не должно, иначе через ~2 минуты харддел.
	TEST_ASSERT_EQUAL(refcount(orbital), 1, "после qdel на орбитальный объект шаттла остались чужие ссылки")

/// Две консоли «Иглы» не должны оставлять дубликаты exploration_custom: getDock()
/// обязан вернуть порт новой руины, а не самый старый на уже очищенном z-уровне.
/datum/unit_test/orbital_shuttle_custom_port_ref/Run()
	var/obj/machinery/computer/shuttle_flight/console = allocate(/obj/machinery/computer/shuttle_flight)
	console.shuttlePortId = "unit_test_exploration_custom"
	var/obj/docking_port/stationary/stale_port = allocate(/obj/docking_port/stationary, run_loc_floor_bottom_left)
	var/obj/docking_port/stationary/current_port = allocate(/obj/docking_port/stationary, run_loc_floor_top_right)
	stale_port.shuttle_id = console.shuttlePortId
	current_port.shuttle_id = console.shuttlePortId
	console.my_port = current_port

	TEST_ASSERT_EQUAL(SSshuttle.getDock(console.shuttlePortId), stale_port, "не удалось воспроизвести выбор устаревшего порта")
	console.clear_stale_custom_ports()

	TEST_ASSERT(QDELETED(stale_port), "устаревший свободный порт не удалён")
	TEST_ASSERT(!QDELETED(current_port), "текущий порт удалён вместе с устаревшим")
	TEST_ASSERT_EQUAL(SSshuttle.getDock(console.shuttlePortId), current_port, "стыковка по-прежнему ведёт на старую руину")
