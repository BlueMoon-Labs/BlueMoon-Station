/// Таймер камеры находит шлюз брига по id и открывает его по окончании срока.
/datum/unit_test/door_timer_airlock

/datum/unit_test/door_timer_airlock/Run()
	var/obj/machinery/door/airlock/security/glass/cell_airlock = allocate(/obj/machinery/door/airlock/security/glass)
	var/obj/machinery/door_timer/timer = allocate(/obj/machinery/door_timer, get_step(cell_airlock, EAST))
	cell_airlock.id = "unit_test_cell"
	timer.id = "unit_test_cell"
	timer.find_targets()
	TEST_ASSERT(cell_airlock in timer.targets, "Таймер не нашёл шлюз брига со своим id")

	cell_airlock.set_machine_stat(NONE)
	timer.set_machine_stat(NONE)
	TEST_ASSERT(cell_airlock.density, "Шлюз должен стартовать закрытым")
	timer.timer_end()
	for(var/i in 1 to 30)
		if(!cell_airlock.density)
			break
		sleep(1)
	TEST_ASSERT(!cell_airlock.density, "Таймер не открыл шлюз по окончании срока")
