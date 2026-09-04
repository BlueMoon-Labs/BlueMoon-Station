/// Машина, не держащая трубу в своих nodes, не попадает в её сеть при обходе.
/datum/unit_test/atmos_pipenet_skips_one_sided_component_link/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/turf/open/port_spot = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/machinery/atmospherics/components/unary/portables_connector/port = allocate(/obj/machinery/atmospherics/components/unary/portables_connector, port_spot)
	port.setDir(WEST)
	port.SetInitDirections()
	var/list/obj/machinery/atmospherics/pipe/simple/pipes = lay_pipe_row(run_loc_floor_bottom_left, 2)
	port.atmosinit()
	var/obj/machinery/atmospherics/pipe/simple/last = pipes[2]
	TEST_ASSERT(port in last.nodes, "предпосылка: труба не увидела порт")
	TEST_ASSERT(last in port.nodes, "предпосылка: порт не увидел трубу")

	port.nodes[1] = null
	var/obj/machinery/atmospherics/pipe/simple/first = pipes[1]
	first.build_network(blocking = TRUE)
	var/datum/pipeline/net = first.parent
	TEST_ASSERT_NOTNULL(net, "сеть не построилась")
	TEST_ASSERT_EQUAL(length(net.members), 2, "в сети [length(net.members)] труб вместо 2")
	TEST_ASSERT(!(port in net.other_atmosmch), "порт без обратной связи попал в машины сети")
	TEST_ASSERT_EQUAL(length(net.other_airs), 0, "в сети появилась газовая смесь машины без связи")

/// Симметричная связь по-прежнему делает машину членом сети.
/datum/unit_test/atmos_pipenet_keeps_two_sided_component_link/Run()
	TEST_ASSERT(SSair?.initialized, "SSair не инициализирован")
	var/turf/open/port_spot = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z)
	var/obj/machinery/atmospherics/components/unary/portables_connector/port = allocate(/obj/machinery/atmospherics/components/unary/portables_connector, port_spot)
	port.setDir(WEST)
	port.SetInitDirections()
	var/list/obj/machinery/atmospherics/pipe/simple/pipes = lay_pipe_row(run_loc_floor_bottom_left, 2)
	port.atmosinit()

	var/obj/machinery/atmospherics/pipe/simple/first = pipes[1]
	first.build_network(blocking = TRUE)
	var/datum/pipeline/net = first.parent
	TEST_ASSERT_NOTNULL(net, "сеть не построилась")
	TEST_ASSERT(port in net.other_atmosmch, "порт с обратной связью не стал машиной сети")
	TEST_ASSERT_EQUAL(length(net.other_airs), 1, "у сети [length(net.other_airs)] смесей машин вместо 1")
	TEST_ASSERT_EQUAL(port.parents[1], net, "порт не запомнил сеть")

