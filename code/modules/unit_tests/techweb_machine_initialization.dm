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
