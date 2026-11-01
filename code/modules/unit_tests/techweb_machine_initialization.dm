/// Проверяет создание исследовательских машин в раунде и смену их сети.
/datum/unit_test/techweb_machine_initialization/Run()
	var/list/machine_types = list(
		/obj/machinery/computer/operating = "linked_techweb",
		/obj/machinery/computer/scan_consolenew = "stored_research",
		/obj/machinery/doppler_array/research = "linked_techweb",
		/obj/machinery/doppler_array/research/science = "linked_techweb",
		/obj/machinery/power/tesla_coil = "linked_techweb",
		/obj/machinery/rnd/production/protolathe = "host_research",
		/obj/machinery/nanite_program_hub = "linked_techweb",
		/obj/machinery/computer/rdconsole/production = "stored_research",
		/obj/machinery/research_table = "linked_techweb",
	)
	var/datum/techweb/research = new
	allocated += research
	for(var/machine_type in machine_types)
		var/obj/machinery/machine = allocate(machine_type, run_loc_floor_bottom_left)
		if(istype(machine, /obj/machinery/rnd/production))
			TEST_ASSERT(wait_for_var(machine, "designs_cache_built", TRUE), "[machine_type] не загрузила начальные рецепты")
		var/datum/component/techweb_holder/holder = machine.GetComponent(/datum/component/techweb_holder)
		TEST_ASSERT_NOTNULL(holder, "[machine_type] создана без подключения к исследовательской сети")
		SEND_SIGNAL(machine, COMSIG_ATOM_SET_TECHWEB, research)
		TEST_ASSERT_EQUAL(holder.linked_techweb, research, "Компонент [machine_type] не сменил сеть")
		TEST_ASSERT_EQUAL(machine.vars[machine_types[machine_type]], research, "[machine_type] не получила новую исследовательскую сеть")
		if(istype(machine, /obj/machinery/rnd/production))
			TEST_ASSERT(wait_for_var(machine, "designs_cache_built", TRUE), "[machine_type] не загрузила рецепты новой сети")
		qdel(machine)

/// Машины РнД, построенные вне станции, подхватывают сеть сервера своей базы, а фракционные сети остаются отдельными.
/datum/unit_test/techweb_off_station_auto_network/Run()
	TEST_ASSERT(!is_station_level(run_loc_floor_bottom_left.z), "Площадка теста должна быть вне станции")
	var/turf/server_spot = locate(run_loc_floor_bottom_left.x + 1, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/turf/console_spot = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/turf/lathe_spot = locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	// Дальше трёх клеток от протолата, чтобы консоль не забрала его себе в SyncRDevices()
	var/turf/syndicate_spot = run_loc_floor_top_right

	var/obj/machinery/rnd/server/tarkoff/base_server = allocate(/obj/machinery/rnd/server/tarkoff, run_loc_floor_bottom_left)
	var/datum/techweb/base_web = base_server.stored_research
	TEST_ASSERT_EQUAL(base_web, SSresearch.get_rnd_network(RND_NETWORK_TARKON), "Сервер Таркова не в своей сети")

	var/obj/machinery/rnd/server/rebuilt_server = allocate(/obj/machinery/rnd/server, server_spot)
	TEST_ASSERT_EQUAL(rebuilt_server.stored_research, base_web, "Сервер, собранный рядом с сервером базы, завёл отдельную сеть")
	var/obj/machinery/computer/rdconsole/console = allocate(/obj/machinery/computer/rdconsole, console_spot)
	TEST_ASSERT_EQUAL(console.stored_research, base_web, "Консоль, собранная рядом с сервером базы, осталась без сети")
	TEST_ASSERT(base_web.consoles_accessing[console], "Консоль не записана в сеть базы")
	var/obj/machinery/rnd/production/protolathe/lathe = allocate(/obj/machinery/rnd/production/protolathe, lathe_spot)
	TEST_ASSERT(wait_for_var(lathe, "designs_cache_built", TRUE), "Протолат не загрузил рецепты")
	TEST_ASSERT_EQUAL(lathe.host_research, base_web, "Протолат, собранный рядом с сервером базы, завёл отдельную сеть")

	var/obj/machinery/computer/rdconsole/syndicate/syndicate_console = allocate(/obj/machinery/computer/rdconsole/syndicate, syndicate_spot)
	TEST_ASSERT_EQUAL(syndicate_console.stored_research, SSresearch.get_rnd_network(RND_NETWORK_SYNDICATE), "Фракционная консоль ушла в чужую сеть")

	qdel(base_server)
	qdel(rebuilt_server)
	var/obj/machinery/rnd/server/lone_server = allocate(/obj/machinery/rnd/server, server_spot)
	TEST_ASSERT_NOTNULL(lone_server.stored_research, "Одиночный сервер вне станции остался без сети")
	TEST_ASSERT(lone_server.stored_research != base_web, "Одиночный сервер подхватил сеть удалённого сервера")
	qdel(lone_server)
	var/obj/machinery/computer/rdconsole/lone_console = allocate(/obj/machinery/computer/rdconsole, console_spot)
	TEST_ASSERT_NULL(lone_console.stored_research, "Консоль без сервера рядом получила сеть")
