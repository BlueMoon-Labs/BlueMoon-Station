/// Ставит атмос-устройство на ручную сеть: заглушка-нода, общий объём и газ сети задаёт тест.
/datum/unit_test/proc/attach_blind_test_net(obj/machinery/atmospherics/components/unary/device, turf/node_turf, list/created)
	var/obj/machinery/atmospherics/pipe/simple/node = allocate(/obj/machinery/atmospherics/pipe/simple, node_turf)
	device.nodes[1] = node
	var/datum/pipeline/net = new()
	net.air = new(200)
	net.air.set_temperature(T20C)
	net.other_atmosmch += device
	net.other_airs += device.airs[1]
	device.parents[1] = net
	created += net
	return net

/datum/unit_test/proc/fill_blind_test_net(datum/pipeline/net, obj/machinery/atmospherics/components/unary/device, kpa)
	device.airs[1].clear()
	net.air.clear()
	net.air.set_temperature(T20C)
	if(kpa)
		net.air.set_moles(GAS_N2, kpa * net.air.return_volume() / (R_IDEAL_GAS_EQUATION * T20C))
	net.mark_dirty()
	net.process()

/// Скачок давления сети будит вент, который ждёт газ из трубы, но не вент, чья комната уже на уставке.
/datum/unit_test/atmos_vent_pipenet_wake_only_when_pipe_matters/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/turf/open/node_turf = run_loc_floor_top_right
	TEST_ASSERT(istype(room) && istype(node_turf) && room != node_turf, "test locations are not two open turfs")
	var/list/datum/pipeline/created = list()
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = allocate(/obj/machinery/atmospherics/components/unary/vent_pump, room)
	vent.on = TRUE
	vent.set_machine_stat(0)
	TEST_ASSERT(vent.is_operational, "the test vent is not operational")
	var/datum/pipeline/net = attach_blind_test_net(vent, node_turf, created)
	var/room_pressure = room.air.return_pressure()

	vent.external_pressure_bound = room_pressure - 5
	fill_blind_test_net(net, vent, 0)
	vent.atmos_wake()
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		vent.process_atmos()
	TEST_ASSERT(SSair.idle_machine_queued(vent), "a vent over a room at its target did not fall asleep")
	fill_blind_test_net(net, vent, 4000)
	TEST_ASSERT(SSair.idle_machine_queued(vent), "a pipenet refill woke a vent whose room is already at its target")
	SSair.add_to_active(room)
	TEST_ASSERT(vent.atmos_processing, "a turf air change did not wake the satisfied vent")

	vent.external_pressure_bound = room_pressure + 20
	fill_blind_test_net(net, vent, 0)
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		vent.process_atmos()
	TEST_ASSERT(SSair.idle_machine_queued(vent), "a vent with an empty pipe did not fall asleep")
	fill_blind_test_net(net, vent, 4000)
	TEST_ASSERT(vent.atmos_processing, "a pipenet refill did not wake a vent waiting for gas")
	vent.process_atmos()
	TEST_ASSERT(room.air.return_pressure() > room_pressure + 1, "the woken vent did not release gas into the room")

	vent.atmos_wake()
	vent.nodes[1] = null
	vent.parents[1] = null
	QDEL_LIST(created)

/// Скруббер над чистой комнатой не просыпается от скачка давления своей сети, а от газа в комнате - просыпается.
/datum/unit_test/atmos_scrubber_pipenet_wake_only_when_pipe_matters/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/turf/open/node_turf = run_loc_floor_top_right
	TEST_ASSERT(istype(room) && istype(node_turf) && room != node_turf, "test locations are not two open turfs")
	var/list/datum/pipeline/created = list()
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = allocate(/obj/machinery/atmospherics/components/unary/vent_scrubber, room)
	scrubber.on = TRUE
	scrubber.set_machine_stat(0)
	TEST_ASSERT(scrubber.is_operational, "the test scrubber is not operational")
	var/datum/pipeline/net = attach_blind_test_net(scrubber, node_turf, created)
	room.air.set_moles(GAS_CO2, 0)
	room.air.set_moles(GAS_PLASMA, 0)

	fill_blind_test_net(net, scrubber, 0)
	scrubber.atmos_wake()
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		scrubber.process_atmos()
	TEST_ASSERT(SSair.idle_machine_queued(scrubber), "a scrubber over a clean room did not fall asleep")
	fill_blind_test_net(net, scrubber, 1000)
	TEST_ASSERT(SSair.idle_machine_queued(scrubber), "a pipenet pressure jump woke a scrubber over a clean room")

	room.air.set_moles(GAS_CO2, 1)
	SSair.add_to_active(room)
	TEST_ASSERT(scrubber.atmos_processing, "gas in the room did not wake the scrubber")
	scrubber.process_atmos()
	TEST_ASSERT(room.air.get_moles(GAS_CO2) < 1, "the woken scrubber did not scrub")

	room.air.set_moles(GAS_CO2, 0)
	scrubber.atmos_wake()
	scrubber.nodes[1] = null
	scrubber.parents[1] = null
	QDEL_LIST(created)

/// Паук ужаса, сорвавший заварку, будит уснувший под ней вент: иначе тот ждал бы сердцебиения.
/datum/unit_test/atmos_terror_spider_unweld_wakes_vent/Run()
	TEST_ASSERT(SSair?.initialized, "SSair was not initialized")
	var/turf/open/room = run_loc_floor_bottom_left
	var/turf/open/node_turf = run_loc_floor_top_right
	var/list/datum/pipeline/created = list()
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = allocate(/obj/machinery/atmospherics/components/unary/vent_pump, room)
	vent.on = TRUE
	vent.set_machine_stat(0)
	var/datum/pipeline/net = attach_blind_test_net(vent, node_turf, created)
	// Без других вентов в сети паук не уходит в трубы, а только срывает заварку.
	net.other_atmosmch -= vent
	vent.external_pressure_bound = room.air.return_pressure() - 5
	fill_blind_test_net(net, vent, 0)
	vent.atmos_wake()
	for(var/i in 1 to ATMOS_MACHINE_IDLE_STREAK)
		vent.process_atmos()
	TEST_ASSERT(SSair.idle_machine_queued(vent), "premise: the test vent did not fall asleep")
	vent.welded = TRUE

	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/spider = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight, get_step(room, EAST))
	spider.ai_ventbreaker = TRUE
	spider.entry_vent = vent
	spider.TSVentCrawlRandom()
	TEST_ASSERT(!vent.welded, "premise: the spider did not smash the weld off")
	TEST_ASSERT(vent.atmos_processing && !SSair.idle_machine_queued(vent), "вент, с которого паук сорвал заварку, остался спать")

	vent.nodes[1] = null
	vent.parents[1] = null
	QDEL_LIST(created)
