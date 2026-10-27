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
