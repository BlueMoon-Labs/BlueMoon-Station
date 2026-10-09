/// NTNet-релей на одном этаже связки обслуживает и другие её этажи.
/datum/unit_test/multiz_ntnet_relay_covers_stack

/datum/unit_test/multiz_ntnet_relay_covers_stack/Run()
	var/list/levels = multiz_gravity_test_levels()
	var/datum/ntnet/network = SSnetworks.station_network
	TEST_ASSERT(!network.check_relay_operation(levels[2]), "Релей нашёлся на тестовой связке до установки")

	var/obj/machinery/ntnet_relay/relay = allocate(/obj/machinery/ntnet_relay, locate(10, 10, levels[1]))
	relay.set_machine_stat(0)
	TEST_ASSERT(relay.is_operational(), "Тестовый релей не работает")
	TEST_ASSERT(network.check_relay_operation(levels[1]), "Релей не виден со своего этажа")
	TEST_ASSERT(network.check_relay_operation(levels[2]), "Релей нижнего этажа не виден с верхнего")
