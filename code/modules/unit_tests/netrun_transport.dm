/// Real machine components and timers exercise discovery and delivery together.
/datum/netrun_machine_service/readiness_fixture
	service_id = "transport.readiness"
	start_when_ready = TRUE
	var/ready_calls = 0

/datum/netrun_machine_service/readiness_fixture/network_ready()
	ready_calls++

/datum/unit_test/netrun_transport_late_service_readiness/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/datum/netrun_machine_service/readiness_fixture/service = allocate(/datum/netrun_machine_service/readiness_fixture, scene.source.node)
	TEST_ASSERT_EQUAL(service.ready_calls, 0, "Registration must not call domain startup inline")
	TEST_ASSERT_EQUAL(transport.ready_services[service.service_key()], service, "Only opted-in startup adapters must enter the readiness index")
	TEST_ASSERT(!(scene.source.service_key() in transport.ready_services), "Ordinary data services must not occupy the startup work list")
	var/deadline = world.time + 5 SECONDS
	while(!service.ready_calls && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(service.ready_calls, 1, "A service registered after bootstrap must receive asynchronous readiness once")
	SSnetrun.get_task_scheduler().enqueue("service_initialize", service, NETRUN_TASK_BACKGROUND)
	deadline = world.time + 5 SECONDS
	while(service.ready_calls < 2 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(service.ready_calls, 2, "A later recovery must be able to initialize the same service again")
	var/key = service.service_key()
	var/task_key = "service_initialize:[REF(service)]"
	SSnetrun.get_task_scheduler().enqueue("service_initialize", service, NETRUN_TASK_BACKGROUND)
	qdel(service)
	TEST_ASSERT_NULL(SSnetrun.get_task_scheduler().by_key[task_key], "Service deletion must cancel its pending readiness task")
	TEST_ASSERT_NULL(transport.ready_services[key], "Service deletion must release the readiness index entry")

/// Power signals must not create self-requeuing startup work before the barrier.
/datum/unit_test/netrun_transport_security_startup_signals/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, scene.target_spot)
	var/datum/netrun_machine_service/security_events/publisher = scene.apc.get_netrun_machine_service("security.events")
	var/datum/netrun_machine_service/security_monitor/monitor = console.get_netrun_machine_service("security.monitor")
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	var/publisher_key = "service_initialize:[REF(publisher)]"
	var/monitor_key = "service_initialize:[REF(monitor)]"
	scheduler.cancel("service_initialize", publisher)
	scheduler.cancel("service_initialize", monitor)
	var/was_bootstrapped = transport.bootstrap_complete
	transport.bootstrap_complete = FALSE
	publisher.on_station_network_restored()
	monitor.on_station_network_restored()
	var/queued_before_ready = !!(scheduler.by_key[publisher_key] || scheduler.by_key[monitor_key])
	transport.bootstrap_complete = TRUE
	publisher.on_station_network_restored()
	monitor.on_station_network_restored()
	var/queued_after_ready = !!(scheduler.by_key[publisher_key] && scheduler.by_key[monitor_key])
	scheduler.cancel("service_initialize", publisher)
	scheduler.cancel("service_initialize", monitor)
	// Restore the shared barrier before any assertion can return from the test.
	transport.bootstrap_complete = was_bootstrapped
	publisher.on_station_network_restored()
	monitor.on_station_network_restored()
	TEST_ASSERT(!queued_before_ready, "Startup power signals must leave readiness work to the shared bootstrap wave")
	TEST_ASSERT(queued_after_ready, "Power restoration after bootstrap must still re-advertise both services")

/datum/unit_test/netrun_transport_scrubber_filter_shape/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/airalarm/alarm = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = scene.machine(/obj/machinery/atmospherics/components/unary/vent_scrubber, scene.target_spot)
	scrubber.broadcast_status()
	var/deadline = world.time + 5 SECONDS
	while(!alarm.netrun_scrub_info[scrubber.id_tag] && world.time < deadline)
		sleep(world.tick_lag)
	var/list/status = alarm.netrun_scrub_info[scrubber.id_tag]
	TEST_ASSERT_NOTNULL(status, "The native scrubber must register with its actual alarm")
	var/list/filters = status["filter_types"]
	TEST_ASSERT(length(filters), "Telemetry must retain native filter options")
	var/encoded = json_encode(filters)
	TEST_ASSERT_EQUAL(copytext(encoded, 1, 2), "\[", "The client must receive a JSON filter array, not an object")
	var/list/first = filters[1]
	TEST_ASSERT(first["gas_id"] && first["gas_name"], "Each filter must retain its native identity")
	var/list/copy = netrun_copy_wire_value(status)
	var/list/copied_filters = copy["filter_types"]
	var/list/copied_first = copied_filters[1]
	copied_first["gas_name"] = "CHANGED"
	TEST_ASSERT_NOTEQUAL(first["gas_name"], "CHANGED", "Transport copies must not alias native filter records")

/// An already indexed local alarm needs no separate discovery task for each status.
/datum/unit_test/netrun_transport_atmos_indexed_status/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/airalarm/alarm = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = scene.machine(/obj/machinery/atmospherics/components/unary/vent_pump, scene.target_spot)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/deadline = world.time + 5 SECONDS
	while(!transport.is_ready() && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(transport.is_ready(), "The indexed status path requires the normal network readiness barrier")
	var/datum/netrun_machine_service/atmos/device/device = vent.get_netrun_machine_service("atmos.device")
	deadline = world.time + 5 SECONDS
	while(device.resolutions["atmos.controller|"] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_NULL(device.resolutions["atmos.controller|"], "Initial discovery must settle before testing an indexed retry")
	vent.on = !vent.on
	alarm.netrun_vent_info -= vent.id_tag
	vent.broadcast_status()
	TEST_ASSERT_NULL(device.resolutions["atmos.controller|"], "An indexed local status must not enqueue a redundant discovery")
	deadline = world.time + 5 SECONDS
	var/list/status = alarm.netrun_vent_info[vent.id_tag]
	while((!status || status["power"] != vent.on || !device.registration_complete()) && world.time < deadline)
		sleep(world.tick_lag)
		status = alarm.netrun_vent_info[vent.id_tag]
	TEST_ASSERT(status && status["power"] == vent.on && device.registration_complete(), "The matching alarm must receive and acknowledge the new status")

/// A failed update after registration invalidates only that recipient's ACK and retries.
/datum/unit_test/netrun_transport_atmos_status_failure_retries/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/airalarm/first = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	var/obj/machinery/airalarm/second = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = scene.machine(/obj/machinery/atmospherics/components/unary/vent_pump, scene.target_spot)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/datum/netrun_machine_service/atmos/device/device = vent.get_netrun_machine_service("atmos.device")
	var/datum/netrun_machine_service/atmos/controller/first_controller = first.get_netrun_machine_service("atmos.controller")
	var/datum/netrun_machine_service/atmos/controller/second_controller = second.get_netrun_machine_service("atmos.controller")
	var/deadline = world.time + 5 SECONDS
	while(!transport.is_ready() && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(transport.is_ready(), "The failure fixture needs the normal ready network")
	vent.broadcast_status()
	deadline = world.time + 5 SECONDS
	while(!device.registration_complete() && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(device.acknowledged_controllers[REF(first_controller)] && device.acknowledged_controllers[REF(second_controller)], "Both controllers must initially acknowledge the real vent")
	vent.on = !vent.on
	vent.broadcast_status()
	var/datum/netrun_machine_packet/data/failed_packet
	for(var/datum/netrun_machine_packet/data/packet as anything in transport.packets)
		if(packet.source == device && packet.recipient == second_controller && packet.message.payload["sigtype"] == "status")
			failed_packet = packet
			break
	TEST_ASSERT_NOTNULL(failed_packet, "The changed status must first be admitted to the second controller")
	failed_packet.fail("test route failure after admission")
	TEST_ASSERT(device.acknowledged_controllers[REF(first_controller)], "A different controller's valid acknowledgement must survive")
	TEST_ASSERT_NULL(device.acknowledged_controllers[REF(second_controller)], "A failed admitted packet must revoke its recipient's old acknowledgement")
	TEST_ASSERT(device.registration_timer, "A failed packet must schedule a fresh status retry")
	deadline = world.time + 12 SECONDS
	var/list/status = second.netrun_vent_info[vent.id_tag]
	while((!status || status["power"] != vent.on || !device.registration_complete()) && world.time < deadline)
		sleep(world.tick_lag)
		status = second.netrun_vent_info[vent.id_tag]
	TEST_ASSERT(status && status["power"] == vent.on, "Retry must deliver the current status, not retain the old acknowledged value")
	TEST_ASSERT(device.registration_complete(), "Both controllers must eventually acknowledge the current registration")

/obj/machinery/netrun_server/transport_fixture/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/transport_fixture)

/datum/netrun_machine_service/transport_fixture
	service_id = "transport.fixture"
	var/received = 0
	var/list/last_payload
	var/received_at
	var/match_checks = 0

/datum/netrun_machine_service/transport_fixture/matches(datum/netrun_machine_service/source_service, recipient_tag)
	match_checks++
	return ..()

/datum/netrun_machine_service/transport_fixture/receive(datum/netrun_machine_message/message)
	received++
	received_at = world.time
	last_payload = deepCopyList(message.payload)
	if(message.payload["reply"])
		message.reply(new /datum/netrun_machine_message(list("answer" = message.payload["value"])))
	return TRUE

/datum/netrun_machine_message/transport_fixture
	var/list/outcomes

/datum/netrun_machine_message/transport_fixture/New(list/payload, list/outcomes)
	..(payload)
	src.outcomes = outcomes

/datum/netrun_machine_message/transport_fixture/copy()
	var/datum/netrun_machine_message/transport_fixture/result = ..()
	result.outcomes = outcomes
	return result

/datum/netrun_machine_message/transport_fixture/failed(reason)
	if(outcomes)
		outcomes["failed"] = (outcomes["failed"] || 0) + 1
		outcomes["reason"] = reason

/datum/netrun_machine_message/transport_fixture/delivered(datum/netrun_machine_service/recipient_service)
	if(outcomes)
		outcomes["delivered"] = (outcomes["delivered"] || 0) + 1
		outcomes["at"] = world.time

/// Observe native receiver admission without requiring the rest of its radio chain.
/obj/machinery/telecomms/receiver/prerelease_fixture
	var/received_packets = 0

/obj/machinery/telecomms/receiver/prerelease_fixture/receive_signal(datum/signal/subspace/signal)
	received_packets++

/obj/machinery/atmospherics/components/unary/vent_pump/prerelease_poll_fixture
	var/status_polls = 0

/obj/machinery/atmospherics/components/unary/vent_pump/prerelease_poll_fixture/receive_signal(datum/signal/signal)
	if("status" in signal.data)
		status_polls++
	return ..()

/// Discovery completion replays its queued poll; it must not generate another one.
/datum/unit_test/netrun_transport_atmos_poll_no_echo/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/airalarm/alarm = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	var/obj/machinery/atmospherics/components/unary/vent_pump/prerelease_poll_fixture/vent = scene.machine(/obj/machinery/atmospherics/components/unary/vent_pump/prerelease_poll_fixture, scene.target_spot)
	TEST_ASSERT(alarm.send_signal(vent.id_tag, list("status" = TRUE)), "A cold native status poll must be admitted")
	var/deadline = world.time + 4 SECONDS
	while(!alarm.netrun_vent_info[vent.id_tag] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag], "The native poll must return real vent telemetry")
	sleep(1 SECONDS)
	TEST_ASSERT_EQUAL(vent.status_polls, 1, "Service discovery completion must not echo the already replayed native poll")

/// Two real sectors, joined only by the native telecommunications relay/hub link.
/datum/netrun_communication_scene
	parent_type = /datum/netrun_transport_scene
	var/obj/item/radio/radio
	var/obj/machinery/telecomms/relay/relay
	var/obj/machinery/telecomms/hub/hub
	var/obj/machinery/telecomms/receiver/prerelease_fixture/receiver_port
	var/datum/netrun_machine_service/radio_port
	var/datum/netrun_machine_service/receiver_service

/datum/netrun_communication_scene/New(turf/origin)
	..(origin)
	var/list/levels = multiz_gravity_test_levels()
	mark_station(levels[1])
	var/area/remote_room = room(/area/netrun_route_test)
	var/turf/remote = take(locate(80, 80, levels[1]), remote_room, TRUE)
	var/turf/remote_apc = take(locate(81, 80, levels[1]), remote_room, TRUE)
	machine(/obj/machinery/power/apc, remote_apc)
	receiver.forceMove(remote)
	radio = new(source_spot)
	owned += radio
	relay = machine(/obj/machinery/telecomms/relay, source_spot)
	hub = machine(/obj/machinery/telecomms/hub, remote)
	receiver_port = machine(/obj/machinery/telecomms/receiver/prerelease_fixture, remote)
	relay.links = list(hub)
	hub.links = list(relay, receiver_port)
	receiver_port.links = list(hub)
	radio_port = radio.get_netrun_machine_service("telecomms.origin")
	receiver_service = receiver_port.get_netrun_machine_service("telecomms.receiver")
	SSnetrun.ensure_topology()

/datum/netrun_communication_scene/proc/signal()
	var/datum/signal/subspace/result = new
	result.source = radio
	result.frequency = FREQ_COMMON
	result.levels = list(radio.z)
	return result

/datum/unit_test/netrun_transport_native_relay_policy/Run()
	var/datum/netrun_communication_scene/scene = allocate(/datum/netrun_communication_scene, run_loc_floor_bottom_left)
	var/datum/signal/subspace/signal = scene.signal()
	allocated += signal
	TEST_ASSERT(scene.radio_port.send("telecomms.receiver", new /datum/netrun_machine_message/telecomms(signal), scene.receiver_service.service_tag()), "Communication discovery must be admitted across a native relay")
	var/deadline = world.time + 4 SECONDS
	while(!scene.receiver_port.received_packets && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(scene.receiver_port.received_packets, 1, "APC service discovery and communication must cross telecomms without an NTnet relay")
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	TEST_ASSERT(!transport.reachable(scene.source, scene.target), "A communication path must not enter the ordinary machine route cache")
	var/datum/component/netrun_node/start = scene.source.resolve_node()
	var/datum/netrun_path_tree/tree = new(SSnetrun.ensure_topology(), start)
	allocated += tree
	TEST_ASSERT(!tree.reached[scene.target.resolve_node().address], "Telecommunications must not widen runner, research or atmosphere topology")
	scene.relay.receiving = FALSE
	TEST_ASSERT(!transport.reachable(scene.radio_port, scene.receiver_service), "A disabled native receive direction must revoke a cached communication route")
	scene.relay.receiving = TRUE
	scene.relay.set_machine_stat(BROKEN)
	TEST_ASSERT(!transport.reachable(scene.radio_port, scene.receiver_service), "Broken native relays must revoke cached communication routes")

/datum/unit_test/netrun_transport_native_relay_delivery_revalidation/Run()
	var/datum/netrun_communication_scene/scene = allocate(/datum/netrun_communication_scene, run_loc_floor_bottom_left)
	var/datum/signal/subspace/signal = scene.signal()
	allocated += signal
	var/datum/netrun_machine_packet/data/packet = new(scene.radio_port, scene.receiver_service, new /datum/netrun_machine_message/telecomms(signal))
	TEST_ASSERT(packet.send(), "A live native relay must admit the communication packet")
	scene.relay.freq_listening = list(FREQ_SCIENCE)
	packet.deliver()
	TEST_ASSERT_EQUAL(scene.receiver_port.received_packets, 0, "A frequency change in flight must reject the packet at delivery")
	scene.relay.freq_listening = list()
	packet = new(scene.radio_port, scene.receiver_service, new /datum/netrun_machine_message/telecomms(signal))
	TEST_ASSERT(packet.send(), "Restoring a relay filter must restore communication admission")
	scene.hub.freq_listening = list(FREQ_SCIENCE)
	packet.deliver()
	TEST_ASSERT_EQUAL(scene.receiver_port.received_packets, 0, "An in-flight hub frequency change must revoke the native bridge as well")

/datum/unit_test/netrun_transport_atmos_late_controller_registration/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = scene.machine(/obj/machinery/atmospherics/components/unary/vent_pump, scene.target_spot)
	vent.broadcast_status()
	sleep(3 SECONDS)
	var/obj/machinery/airalarm/alarm = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	alarm.buildstage = 2
	var/deadline = world.time + 12 SECONDS
	while(!alarm.netrun_vent_info[vent.id_tag] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag], "An idle vent must retry after its initial discovery found no air alarm")
	var/received_at = alarm.netrun_vent_info[vent.id_tag]["timestamp"]
	sleep(11 SECONDS)
	TEST_ASSERT_EQUAL(alarm.netrun_vent_info[vent.id_tag]["timestamp"], received_at, "Acknowledged devices must stop periodic registration packets")
	qdel(alarm)
	alarm = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	alarm.buildstage = 2
	deadline = world.time + 12 SECONDS
	while(!alarm.netrun_vent_info[vent.id_tag] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag], "Deleting and replacing the controller must rearm idle device registration")

/datum/unit_test/netrun_roundstart_telecommunications_placement/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/area/science/server/science = scene.room(/area/science/server)
	var/area/tcommsat/server/telecomms = scene.room(/area/tcommsat/server)
	scene.take(locate(scene.source_spot.x + 3, scene.source_spot.y + 2, scene.source_spot.z), science)
	scene.take(locate(scene.source_spot.x + 4, scene.source_spot.y + 2, scene.source_spot.z), telecomms)
	var/list/saved_areas = GLOB.sortedAreas
	GLOB.sortedAreas = list(science, telecomms)
	var/turf/selected = SSnetrun.find_server_spot()
	GLOB.sortedAreas = saved_areas
	TEST_ASSERT(istype(get_area(selected), /area/tcommsat), "Roundstart information servers must choose telecommunications before science")
	TEST_ASSERT(SSnetrun.runlevels & RUNLEVEL_LOBBY, "Network preparation must run during the lobby after subsystem initialization")

/// A failed initial discovery window must not permanently disable registration.
/datum/unit_test/netrun_transport_atmos_registration_backoff/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/airalarm/alarm = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = scene.machine(/obj/machinery/atmospherics/components/unary/vent_pump, scene.target_spot)
	var/datum/netrun_machine_service/atmos/device/device = vent.get_netrun_machine_service("atmos.device")
	device.registration_attempts = NETRUN_ATMOS_REGISTRATION_MAX_ATTEMPTS
	if(device.registration_timer)
		deltimer(device.registration_timer)
	device.registration_timer = null
	device.registration_at = INFINITY
	device.retry_registration()
	TEST_ASSERT(device.registration_timer && device.registration_at >= world.time + 30 SECONDS, "An exhausted fast retry window must retain a bounded slow retry, rather than abandon a live controller")
	var/deadline = world.time + 4 SECONDS
	while(!alarm.netrun_vent_info[vent.id_tag] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag], "A device at its old retry limit must still deliver registration after routing recovers")
	TEST_ASSERT_NULL(device.registration_timer, "Successful registration must cancel the slow retry")

/// All native channel setters must wake idle devices and controllers.
/datum/unit_test/netrun_transport_atmos_registration_frequency_change/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/airalarm/alarm = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = scene.machine(/obj/machinery/atmospherics/components/unary/vent_pump, scene.target_spot)
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/scrubber = scene.machine(/obj/machinery/atmospherics/components/unary/vent_scrubber, scene.target_spot)
	var/datum/netrun_machine_service/atmos/device/vent_service = vent.get_netrun_machine_service("atmos.device")
	var/datum/netrun_machine_service/atmos/device/scrub_service = scrubber.get_netrun_machine_service("atmos.device")
	vent.broadcast_status()
	scrubber.broadcast_status()
	var/deadline = world.time + 5 SECONDS
	while((!alarm.netrun_vent_info[vent.id_tag] || !alarm.netrun_scrub_info[scrubber.id_tag]) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag] && alarm.netrun_scrub_info[scrubber.id_tag], "Both idle device types must first complete their initial registration")
	alarm.netrun_vent_info.Cut()
	alarm.netrun_scrub_info.Cut()
	alarm.set_frequency(FREQ_ATMOS_STORAGE)
	TEST_ASSERT(vent_service.registration_timer && scrub_service.registration_timer, "Changing the controller channel must rearm its former area devices")
	// Let the first mismatched-channel attempt settle: no matching controller must
	// leave behind recurring retries, while later device reconfiguration wakes it.
	vent_service.retry_registration()
	scrub_service.retry_registration()
	vent.set_frequency(FREQ_ATMOS_STORAGE)
	scrubber.set_frequency(FREQ_ATMOS_STORAGE)
	TEST_ASSERT(vent_service.registration_frequency == FREQ_ATMOS_STORAGE && scrub_service.registration_frequency == FREQ_ATMOS_STORAGE, "Native device setters must publish their new registration channels immediately")
	deadline = world.time + 5 SECONDS
	while((!alarm.netrun_vent_info[vent.id_tag] || !alarm.netrun_scrub_info[scrubber.id_tag]) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag] && alarm.netrun_scrub_info[scrubber.id_tag], "Idle vents and scrubbers must register on the new compatible channel without a UI status poll")

/// Reproduce the actual Peace Syndicate R&D machine types through deferred map initialization.
/datum/unit_test/netrun_transport_atmos_native_mapload/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	SSatoms.map_loader_begin()
	var/obj/machinery/atmospherics/components/unary/vent_pump/on/layer2/vent = new(scene.target_spot)
	var/obj/machinery/atmospherics/components/unary/vent_scrubber/on/layer4/scrubber = new(scene.target_spot)
	var/obj/machinery/airalarm/alarm = new(scene.source_spot)
	SSatoms.map_loader_stop()
	scene.owned += list(vent, scrubber, alarm)
	SSatoms.InitializeAtoms(list(vent, scrubber, alarm))
	// SSair initializes mapped pipe components after SSatoms. Keep those native
	// defaults: no synthetic frequency, machine_stat, buildstage or node grants.
	vent.atmosinit()
	scrubber.atmosinit()
	var/datum/netrun_machine_service/atmos/device/vent_port = vent.get_netrun_machine_service("atmos.device")
	var/datum/netrun_machine_service/atmos/device/scrub_port = scrubber.get_netrun_machine_service("atmos.device")
	var/datum/netrun_machine_service/atmos/controller/controller = alarm.get_netrun_machine_service("atmos.controller")
	TEST_ASSERT(vent.netrun_online() && scrubber.netrun_online() && alarm.netrun_online(), "The actual mapped constructors must be online with ordinary native defaults in a powered room")
	TEST_ASSERT(controller.matches(vent_port, null) && controller.matches(scrub_port, null), "Default native map types in one compartment must agree on area and control channel")
	var/deadline = world.time + 8 SECONDS
	while((!alarm.netrun_vent_info[vent.id_tag] || !alarm.netrun_scrub_info[scrubber.id_tag]) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag] && alarm.netrun_scrub_info[scrubber.id_tag], "Native mapload plus SSair startup broadcasts must register both actual R&D device types")
	TEST_ASSERT(vent_port.registration_complete() && scrub_port.registration_complete(), "Delivered native mapload status must complete registration rather than retry forever")

/// This fixture asserts the actual R&D compartment and server cluster of Peace
/// Syndicate Station. Other maps have different layouts and are covered by the
/// generic map tests rather than inheriting this station-specific contract.
/datum/unit_test/atmos_netrun_roundstart_registration
	requires_full_map = TRUE

/datum/unit_test/atmos_netrun_roundstart_registration/Run()
	if(SSmapping.config.map_name != "Peace Syndicate Station")
		return
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/obj/machinery/airalarm/research_alarm
	var/list/research_devices = list()
	var/online_apcs = 0
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	for(var/address in graph.registered_apcs)
		var/datum/component/netrun_node/node = graph.registered_apcs[address]
		var/turf/spot = node.physical_turf()
		if(node.is_online() && spot && is_station_level(spot.z))
			online_apcs++
	for(var/datum/netrun_machine_service/atmos/controller/controller as anything in transport.by_id["atmos.controller"])
		var/turf/controller_turf = get_turf(controller.host)
		var/datum/component/netrun_node/controller_node = controller.resolve_node()
		if(istype(get_base_area(controller.host), /area/science/research) && controller_turf && is_station_level(controller_turf.z) && controller_node?.is_online())
			research_alarm = controller.host
			break
	TEST_ASSERT(research_alarm, "The production map must contain a powered native R&D air alarm for this startup regression")
	for(var/datum/netrun_machine_service/atmos/device/device as anything in transport.by_id["atmos.device"])
		var/datum/component/netrun_node/device_node = device.resolve_node()
		if(device.registration_required() && device_node?.is_online() && get_base_area(device.host) == get_base_area(research_alarm))
			research_devices += device
	TEST_ASSERT(length(research_devices), "The real mapped R&D compartment must contain native vents or scrubbers")
	var/deadline = world.time + 20 SECONDS
	var/missing = length(research_devices)
	while(missing)
		missing = 0
		for(var/datum/netrun_machine_service/atmos/device/device as anything in research_devices)
			var/list/received = istype(device.host, /obj/machinery/atmospherics/components/unary/vent_pump) ? research_alarm.netrun_vent_info : research_alarm.netrun_scrub_info
			if(!received[device.service_tag()])
				missing++
		if(missing)
			if(world.time >= deadline)
				break
			sleep(1 SECONDS)
	log_world("NETRUN MAP startup: map=[SSmapping.config.map_name] apcs_online=[online_apcs] ready=[transport.is_ready()] bootstrap=[transport.bootstrap_complete] controllers=[length(transport.by_id["atmos.controller"])] devices=[length(transport.by_id["atmos.device"])] rnd_devices=[length(research_devices)] rnd_missing=[missing] packets=[length(transport.packets)] queued=[transport.queued_messages]")
	var/demanding_clients = 0
	var/list/client_types = list()
	for(var/datum/netrun_machine_service/research_client/client as anything in transport.by_id["research.client"])
		var/key = "[client.host.type]"
		client_types[key] = (client_types[key] || 0) + 1
		demanding_clients += !!client.wants_snapshots
	var/subscribers = 0
	for(var/datum/netrun_machine_service/research_server/server as anything in transport.by_id["research.server"])
		subscribers += length(server.subscribers)
	var/list/packet_kinds = list()
	for(var/datum/netrun_machine_packet/data/packet as anything in transport.packets)
		var/key = "[packet.source.service_id]>[packet.recipient.service_id]:[packet.message.payload["operation"] || packet.message.payload["sigtype"]]"
		packet_kinds[key] = (packet_kinds[key] || 0) + 1
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	var/list/pending_kinds = list()
	for(var/key in scheduler.by_key)
		var/datum/netrun_task/task = scheduler.by_key[key]
		pending_kinds[task.kind] = (pending_kinds[task.kind] || 0) + 1
	log_world("NETRUN MAP research demand: clients=[length(transport.by_id["research.client"])] demanding=[demanding_clients] subscribers=[subscribers] ready_index=[length(transport.ready_services)] types=[json_encode(client_types)]")
	log_world("NETRUN MAP queued work: packets=[json_encode(packet_kinds)] tasks=[json_encode(pending_kinds)] coalesced=[transport.coalesced_packets] peak_pending=[scheduler.peak_pending]")
	log_world("NETRUN MAP worker profile: [scheduler.profile_summary()]")
	log_world("NETRUN MAP graph publication: nodes=[length(graph.nodes)] edges=[length(graph.edges)] peak_ms=[graph.peak_rebuild_ms] phases_ms=[json_encode(graph.peak_rebuild_costs)] nearest_visits=[graph.nearest_apc_visits]")
	for(var/datum/netrun_machine_service/atmos/device/device as anything in research_devices)
		var/datum/netrun_machine_service/atmos/controller/controller = research_alarm.get_netrun_machine_service("atmos.controller")
		log_world("NETRUN MAP device: type=[device.host.type] tag=[device.service_tag()] frequency=[device.control_frequency()] controller_frequency=[controller.control_frequency()] same_area=[get_base_area(device.host) == get_base_area(research_alarm)] matches=[controller.matches(device, null)] registered=[device.registration_complete()] retries=[device.registration_attempts] queries=[length(device.resolutions)] area_index=[device.registration_area == controller.registration_area]")
	TEST_ASSERT(online_apcs, "Mapped station startup must provide powered native APC routing infrastructure")
	TEST_ASSERT(!length(transport.by_id["dns"]), "Mapped station discovery must not depend on a DNS service")
	TEST_ASSERT_EQUAL(missing, 0, "Opening the real R&D air alarm must find its native mapped devices without any forced status poll or channel override")
	var/list/station_pairs = list()
	for(var/datum/netrun_machine_service/atmos/device/device as anything in transport.by_id["atmos.device"])
		var/turf/spot = get_turf(device.host)
		var/datum/component/netrun_node/node = device.resolve_node()
		if(!spot || !is_station_level(spot.z) || !device.registration_required() || !node?.is_online())
			continue
		var/list/controllers = transport.atmos_controllers_by_area[REF(get_base_area(device.host))]
		for(var/datum/netrun_machine_service/atmos/controller/controller as anything in controllers)
			var/datum/component/netrun_node/controller_node = controller.resolve_node()
			if(controller_node?.is_online() && controller.matches(device, null) && transport.reachable(device, controller))
				station_pairs += list(list("device" = device, "controller" = controller))
	deadline = world.time + 20 SECONDS
	var/station_missing = length(station_pairs)
	while(station_missing)
		station_missing = 0
		for(var/list/pair as anything in station_pairs)
			var/datum/netrun_machine_service/atmos/device/device = pair["device"]
			var/datum/netrun_machine_service/atmos/controller/controller = pair["controller"]
			var/obj/machinery/airalarm/alarm = controller.host
			var/list/received = istype(device.host, /obj/machinery/atmospherics/components/unary/vent_pump) ? alarm.netrun_vent_info : alarm.netrun_scrub_info
			if(!received[device.service_tag()])
				station_missing++
		if(station_missing)
			if(world.time >= deadline)
				break
			sleep(1 SECONDS)
	log_world("NETRUN MAP station registration: eligible_pairs=[length(station_pairs)] missing=[station_missing] discovery_waiters=[length(transport.waiting_resolutions)] queued_messages=[transport.queued_messages] packets=[length(transport.packets)]")
	TEST_ASSERT(length(station_pairs) > 100, "The production regression must cover a large real station's atmosphere population")
	TEST_ASSERT_EQUAL(station_missing, 0, "Every powered reachable station device must register with its compatible air alarm")
	deadline = world.time + 20 SECONDS
	while((length(transport.waiting_resolutions) || transport.queued_messages) && world.time < deadline)
		sleep(world.tick_lag)
	log_world("NETRUN MAP discovery drained: waiting=[length(transport.waiting_resolutions)] queued=[transport.queued_messages] packets=[length(transport.packets)]")
	TEST_ASSERT_EQUAL(length(transport.waiting_resolutions), 0, "Finished map/shuttle loading must not strand startup discovery waiters")
	TEST_ASSERT_EQUAL(transport.queued_messages, 0, "Released startup queries must also drain their original messages through the worker")
	// Exercise real mapped research startup without sending a manual binding signal.
	var/obj/machinery/rnd/server/station_server
	var/cluster_members = 0
	for(var/obj/machinery/rnd/server/server as anything in SSresearch.servers)
		if(!server.netrun_mapped_server || !server.netrun_online() || server.research_network_id() != RND_NETWORK_STATION)
			continue
		if(!station_server)
			station_server = server
		log_world("NETRUN MAP research server: server=[server.server_id] area=[get_area(server)] web=[REF(server.stored_research)] mapped=[server.netrun_mapped_server] online=[server.netrun_online()] reachable=[netrun_research_route_available(station_server, server)]")
		if(netrun_research_route_available(station_server, server))
			TEST_ASSERT_EQUAL(server.stored_research, station_server.stored_research, "Reachable mapped station servers must already share one cluster")
			cluster_members++
	TEST_ASSERT(cluster_members > 1, "The production map must exercise a real multi-server startup cluster")
	var/consoles = 0
	for(var/datum/netrun_machine_service/research_client/client as anything in transport.by_id["research.client"])
		var/turf/client_turf = get_turf(client.host)
		if(!istype(client.host, /obj/machinery/computer/rdconsole) || !client_turf || !is_station_level(client_turf.z))
			continue
		var/obj/machinery/computer/rdconsole/console = client.host
		if(!client.resolve_node()?.is_online() || console.network_id != RND_NETWORK_AUTO || !netrun_research_route_available(console, station_server))
			continue
		var/datum/component/techweb_holder/holder = console.GetComponent(/datum/component/techweb_holder)
		log_world("NETRUN MAP research console: type=[console.type] area=[get_area(console)] native_web=[REF(console.stored_research)] holder=[REF(holder)] holder_web=[REF(holder?.linked_techweb)] had_authority=[holder?.had_authority] wants=[client.wants_snapshots] generation=[client.binding_generation] ready_cursor=[transport.ready_service_cursor] ready_pending=[length(transport.ready_service_keys)]")
		TEST_ASSERT_EQUAL(console.stored_research, station_server.stored_research, "A real mapped console must bind automatically before its first player interaction")
		TEST_ASSERT_NOTNULL(console.netrun_research_cache, "Mapped consoles must receive a startup research snapshot")
		consoles++
	TEST_ASSERT(consoles, "The production map must exercise at least one powered R&D console")
	log_world("NETRUN MAP research startup: clustered_servers=[cluster_members] consoles=[consoles]")
	for(var/datum/netrun_machine_service/atmos/device/device as anything in research_devices)
		if(istype(device.host, /obj/machinery/atmospherics/components/unary/vent_scrubber))
			var/list/status = research_alarm.netrun_scrub_info[device.service_tag()]
			TEST_ASSERT_EQUAL(copytext(json_encode(status["filter_types"]), 1, 2), "\[", "Real mapped scrubber filter telemetry must reach the client as an array")
	// Save an actual station camera frame for visual inspection, rather than a mockup.
	for(var/obj/machinery/camera/camera in GLOB.cameranet.cameras)
		if(get_base_area(camera) != get_base_area(research_alarm) || !camera.can_use())
			continue
		var/obj/item/camera/netrun_capture/capture = allocate(/obj/item/camera/netrun_capture, get_turf(camera))
		capture.captureimage(camera, null, FALSE, 4, 4, camera.get_visible_turfs().Copy())
		TEST_ASSERT_NOTNULL(capture.result, "The real R&D camera must produce a photograph")
		fcopy(icon(capture.result.picture_image, dir = SOUTH, frame = 1), "data/netrun-peace-photo.png")
		fdel("data/netrun-peace-photo.base64")
		text2file(capture.result.get_base64(), "data/netrun-peace-photo.base64")
		qdel(capture.result)
		break

/// Other mapped stations need not share Peace's R&D layout or server count.
/// Check their actual reachable alarm/device pairs without inventing a room.
/datum/unit_test/atmos_netrun_station_registration
	requires_full_map = TRUE

/datum/unit_test/atmos_netrun_station_registration/Run()
	if(SSmapping.config.map_name == "Peace Syndicate Station")
		return // The dedicated production regression above is stricter.
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/deadline = world.time + 60 SECONDS
	while(!transport.is_ready() && world.time < deadline)
		sleep(1 SECONDS)
	TEST_ASSERT(transport.is_ready(), "Station atmosphere registration requires the startup network readiness barrier")
	// Large stations finish the startup wave (service readiness, deferred discovery,
	// queued messages) under the shared worker budget well after the barrier opens.
	// Measure registration from the settled network, not from the first readiness tick.
	deadline = world.time + 120 SECONDS
	while(startup_pending(transport) && world.time < deadline)
		sleep(1 SECONDS)
	var/list/pairs = list()
	var/online_matches = 0
	for(var/datum/netrun_machine_service/atmos/device/device as anything in transport.by_id["atmos.device"])
		var/turf/spot = get_turf(device.host)
		if(!spot || !is_station_level(spot.z) || !device.registration_required() || !device.resolve_node()?.is_online())
			continue
		var/list/controllers = transport.atmos_controllers_by_area[REF(get_base_area(device.host))]
		for(var/datum/netrun_machine_service/atmos/controller/controller as anything in controllers)
			if(!controller.resolve_node()?.is_online() || !controller.matches(device, null))
				continue
			online_matches++
			if(transport.reachable(device, controller))
				pairs += list(list("device" = device, "controller" = controller))
	TEST_ASSERT(!online_matches || length(pairs), "Powered matching atmosphere devices and alarms must have at least one usable station route")
	if(!length(pairs))
		return
	// A device past its fast retry budget probes every 30 seconds; cover one full cycle.
	deadline = world.time + 60 SECONDS
	var/missing = length(pairs)
	while(missing)
		missing = 0
		for(var/list/pair as anything in pairs)
			var/datum/netrun_machine_service/atmos/device/device = pair["device"]
			var/datum/netrun_machine_service/atmos/controller/controller = pair["controller"]
			var/obj/machinery/airalarm/alarm = controller.host
			var/list/received = istype(device.host, /obj/machinery/atmospherics/components/unary/vent_pump) ? alarm.netrun_vent_info : alarm.netrun_scrub_info
			if(!received[device.service_tag()])
				missing++
		if(missing)
			if(world.time >= deadline)
				break
			sleep(1 SECONDS)
	TEST_ASSERT_EQUAL(missing, 0, "Every reachable mapped atmosphere device must register with its compatible alarm ([length(pairs)] eligible pairs)")

/datum/unit_test/atmos_netrun_station_registration/proc/startup_pending(datum/netrun_machine_transport/transport)
	if(length(transport.waiting_resolutions) || transport.queued_messages || transport.ready_service_keys)
		return TRUE
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	for(var/key in scheduler.by_key)
		var/datum/netrun_task/task = scheduler.by_key[key]
		if(task.kind == "service_ready")
			return TRUE
	return FALSE

/// Isolate readiness notifications from incidental APC signals in a busy test world.
/datum/netrun_machine_transport/readiness_fixture
	var/wake_requests = 0

/datum/netrun_machine_transport/readiness_fixture/wake_resolutions()
	wake_requests++

/// Post-bootstrap map loading must reopen waiting discovery during the live round.
/datum/unit_test/netrun_transport_postbootstrap_readiness_wake/Run()
	var/datum/netrun_machine_transport/readiness_fixture/transport = allocate(/datum/netrun_machine_transport/readiness_fixture)
	transport.bootstrap_complete = TRUE
	transport.waiting_resolutions[allocate(/datum)] = TRUE
	SSatoms.map_loader_begin()
	transport.prepare_network()
	var/wakes_while_loading = transport.wake_requests
	SSatoms.map_loader_stop()
	transport.prepare_network()
	TEST_ASSERT_EQUAL(wakes_while_loading, 0, "A loading barrier must keep admitted work suspended")
	TEST_ASSERT_EQUAL(transport.wake_requests, 1, "Reopening an already bootstrapped network must wake its waiters without an APC change")

/// Nondense mapped equipment also occupies a tile; science never substitutes for telecomms.
/datum/unit_test/netrun_roundstart_free_telecommunications_tile/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/area/tcommsat/server/telecomms = scene.room(/area/tcommsat/server)
	var/turf/only_spot = scene.take(locate(scene.source_spot.x + 4, scene.source_spot.y + 2, scene.source_spot.z), telecomms)
	var/obj/machinery/occupant = scene.machine(/obj/machinery, only_spot)
	occupant.density = FALSE
	var/list/saved_areas = GLOB.sortedAreas
	GLOB.sortedAreas = list(telecomms)
	var/turf/occupied_selection = SSnetrun.find_server_spot()
	qdel(occupant)
	var/turf/free_selection = SSnetrun.find_server_spot()
	var/area/science/server/science = scene.room(/area/science/server)
	scene.take(locate(scene.source_spot.x + 3, scene.source_spot.y + 2, scene.source_spot.z), science)
	GLOB.sortedAreas = list(science)
	var/turf/science_selection = SSnetrun.find_server_spot()
	GLOB.sortedAreas = saved_areas
	TEST_ASSERT_NULL(occupied_selection, "A nondense mapped machine must exclude its tile from roundstart server placement")
	TEST_ASSERT_EQUAL(free_selection, only_spot, "Removing the occupying machine must make its otherwise valid telecomms floor available")
	TEST_ASSERT_NULL(science_selection, "A station with no telecommunications tile must not spawn infrastructure in science")

/// An isolated transport prepares routes in the lobby only after all subsystems finish.
/datum/unit_test/netrun_transport_lobby_bootstrap_barrier/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = allocate(/datum/netrun_machine_transport)
	// Avoid creating real roundstart infrastructure in this isolated route-cache test.
	transport.bootstrap_complete = TRUE
	transport.prewarm_limit = 1
	var/key = "network_bootstrap:[REF(transport)]"
	var/saved_state = SSticker.current_state
	var/datum/controller/subsystem/saved_initializing = Master.initializing_subsystem
	SSticker.current_state = GAME_STATE_PREGAME
	Master.initializing_subsystem = SSnetrun
	transport.prepare_network()
	var/premature = SSnetrun.get_task_scheduler().by_key[key]
	var/parked_early = transport.advance_bootstrap(SSnetrun.get_execution_limits())
	var/early_steps = transport.prewarm_steps
	var/early_revision = transport.prewarm_revision
	Master.initializing_subsystem = saved_initializing
	transport.prepare_network()
	var/datum/netrun_task/queued = SSnetrun.get_task_scheduler().by_key[key]
	transport.advance_bootstrap(SSnetrun.get_execution_limits())
	SSticker.current_state = saved_state
	TEST_ASSERT_NULL(premature, "Lobby bootstrap must not start inside the Master subsystem initialization loop")
	TEST_ASSERT(parked_early && !early_steps && early_revision == -1, "A blocked bootstrap task must park without solving or publishing early routes")
	TEST_ASSERT(queued, "Finishing initialization must enqueue the same bounded infrastructure work during the lobby")
	TEST_ASSERT_EQUAL(transport.prewarm_steps, 1, "A single bootstrap task must prepare one useful infrastructure root")
	TEST_ASSERT(length(SSnetrun.get_topology().infrastructure_route_trees) >= 1 && transport.tree_builds <= 1, "Lobby preparation must borrow the graph's retained infrastructure tree without creating a second cache")
	TEST_ASSERT_EQUAL(transport.prewarm_revision, SSnetrun.get_topology().revision, "The prepared routes must match the current physical graph")
	TEST_ASSERT(!QDELETED(scene.apc), "The cache fixture must retain its real infrastructure owner")

/datum/netrun_transport_scene
	parent_type = /datum/netrun_route_scene
	var/turf/source_spot
	var/turf/target_spot
	var/turf/apc_spot
	var/turf/dns_spot
	var/obj/machinery/netrun_server/transport_fixture/sender
	var/obj/machinery/netrun_server/transport_fixture/receiver
	/// Compatibility node for older route fixtures; it provides no discovery service.
	var/obj/machinery/netrun_server/dns/dns
	var/obj/machinery/power/apc/apc
	var/datum/netrun_machine_service/transport_fixture/source
	var/datum/netrun_machine_service/transport_fixture/target
	var/answer_count = 0
	var/list/previous_delivery_trace

/datum/netrun_transport_scene/proc/answered()
	answer_count++

/// Count only this producer's packets; unrelated station automation may remain active.
/datum/netrun_transport_scene/proc/pending_packets()
	var/count = 0
	for(var/datum/netrun_machine_packet/packet as anything in SSnetrun.get_machine_transport().packets)
		if(packet.source == source && packet.recipient == target)
			count++
	return count

/// Resolved destinations must not bypass backpressure for replaceable telemetry.
/datum/unit_test/netrun_transport_capture_admission/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_packet/data/rejected = new(null, scene.target, new /datum/netrun_machine_message(list("value" = "unsent")))
	var/rejected_id = rejected.operation.id
	TEST_ASSERT_NULL(SSnetrun.packet_captures[rejected_id], "Constructing a packet must not eagerly serialize an unsent body")
	TEST_ASSERT(!rejected.send(), "A missing source must fail route admission")
	TEST_ASSERT_NULL(SSnetrun.packet_captures[rejected_id], "An unadmitted packet must not occupy the global capture buffer")
	TEST_ASSERT(scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture/queue_snapshot(list("value" = "stable"))), "A real replaceable snapshot must be admitted")
	var/datum/netrun_machine_packet/data/admitted
	for(var/datum/netrun_machine_packet/data/packet as anything in SSnetrun.get_machine_transport().packets)
		if(packet.source == scene.source && packet.recipient == scene.target)
			admitted = packet
	var/id = admitted.operation.id
	var/list/headers = admitted.operation.headers
	admitted.deliver()
	TEST_ASSERT(findtext(SSnetrun.packet_captures[id], "stable"), "An admitted snapshot must retain its body for explicit inspection")
	var/accepted = FALSE
	for(var/list/entry as anything in scene.target.node.packet_logs)
		if(entry["id"] == id && entry["phase"] == "ACCEPT")
			accepted = TRUE
			TEST_ASSERT_EQUAL(entry["headers"], headers, "Unchanged telemetry must reuse its immutable capture instead of serializing it again at delivery")
	TEST_ASSERT(accepted, "The real snapshot must complete its normal delivery")

/datum/netrun_machine_message/transport_fixture/copy_probe/copy()
	if(outcomes)
		outcomes["copies"] = (outcomes["copies"] || 0) + 1
	return ..()

/// A fanout owns independent deliveries, but its last delivery can consume the original.
/datum/unit_test/netrun_transport_resolution_moves_last_payload/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/netrun_server/transport_fixture/extra = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.target_spot)
	var/datum/netrun_machine_service/extra_target = extra.get_netrun_machine_service("transport.fixture")
	var/list/outcomes = list()
	var/datum/netrun_machine_message/message = new /datum/netrun_machine_message/transport_fixture/copy_probe(list("nested" = list("value" = "owned")), outcomes)
	var/datum/netrun_machine_resolution/query = new(scene.source, "transport.fixture", null)
	TEST_ASSERT(query.enqueue(message), "The real resolution must own its admitted original")
	query.completed = TRUE
	query.resolved_targets = list(scene.target, extra_target)
	query.deliver()
	if(!QDELETED(query))
		query.deliver()
	TEST_ASSERT_EQUAL(outcomes["copies"], 1, "Two recipients need one independent copy and the transferred original")
	var/datum/netrun_machine_packet/data/first
	var/datum/netrun_machine_packet/data/last
	for(var/datum/netrun_machine_packet/data/packet as anything in SSnetrun.get_machine_transport().packets)
		if(packet.source != scene.source)
			continue
		if(packet.recipient == scene.target)
			first = packet
		else if(packet.recipient == extra_target)
			last = packet
	TEST_ASSERT(first && last, "Both fanout branches must own real admitted packets")
	TEST_ASSERT_EQUAL(last.message, message, "The last recipient must own the admitted original")
	var/list/first_nested = first.message.payload["nested"]
	var/list/last_nested = last.message.payload["nested"]
	first_nested["value"] = "changed"
	TEST_ASSERT_EQUAL(last_nested["value"], "owned", "Moving the original must not alias earlier recipients' nested payloads")
	TEST_ASSERT(netrun_wait_delivery(outcomes), "Both separately owned branches must complete normal delivery")
	var/deadline = world.time + 5 SECONDS
	while((outcomes["delivered"] || 0) < 2 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(outcomes["delivered"], 2, "Both branch owners must settle exactly once")

/datum/unit_test/netrun_transport_replaceable_burst/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	for(var/i in 1 to 256)
		TEST_ASSERT(scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture/queue_snapshot(list("value" = i), outcomes)), "A replaceable snapshot burst must remain admissible")
	TEST_ASSERT_EQUAL(scene.pending_packets(), 1, "256 superseded snapshots must own one transport packet and one delivery task")
	var/datum/netrun_machine_packet/data/latest
	for(var/datum/netrun_machine_packet/data/packet as anything in SSnetrun.get_machine_transport().packets)
		if(packet.source == scene.source && packet.recipient == scene.target)
			latest = packet
	TEST_ASSERT_EQUAL(latest.message.payload["value"], 256, "The retained packet must carry the producer's latest snapshot")
	var/replacement_key = latest.replacement_key
	var/capture_id = latest.operation.id
	TEST_ASSERT(replacement_key, "A replaceable delivery must own its bounded coalescing index")
	if(latest.timer_id)
		deltimer(latest.timer_id)
	latest.queue_delivery()
	for(var/i in 257 to 512)
		scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture/queue_snapshot(list("value" = i), outcomes))
	TEST_ASSERT_EQUAL(scene.pending_packets(), 1, "A ready delivery must also absorb superseded state without adding scheduler tasks")
	TEST_ASSERT_EQUAL(latest.message.payload["value"], 512, "Ready-but-unexecuted state must remain replaceable")
	TEST_ASSERT(netrun_wait_delivery(outcomes), "The retained latest snapshot must actually be delivered")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "Superseded states must not execute the recipient repeatedly")
	var/list/captured = json_decode(SSnetrun.packet_captures[capture_id])
	TEST_ASSERT_EQUAL(captured["value"], 512, "Inspection must show the coalesced body actually delivered, not an obsolete admitted snapshot")
	TEST_ASSERT_EQUAL(scene.pending_packets(), 0, "Delivered snapshots must release packet capacity")
	TEST_ASSERT_NULL(SSnetrun.get_machine_transport().replaceable_packets[replacement_key], "Completion must release the coalescing index as well as packet capacity")

/// The same host/id/tag can acquire a new adapter while an old delivery is pending.
/datum/unit_test/netrun_transport_replaceable_service_identity/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	TEST_ASSERT(scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture/queue_snapshot(list("value" = 1), outcomes)), "Admit state addressed to the original adapter")
	var/datum/netrun_machine_service/transport_fixture/replacement = allocate(/datum/netrun_machine_service/transport_fixture, scene.target.node, scene.target.host)
	TEST_ASSERT_EQUAL(replacement.service_key(), scene.target.service_key(), "The replacement must reuse the same registry key")
	TEST_ASSERT_EQUAL(replacement.service_tag(), scene.target.service_tag(), "An adapter replacement need not replace its physical node")
	TEST_ASSERT(scene.source.send_to(replacement, new /datum/netrun_machine_message/transport_fixture/queue_snapshot(list("value" = 2), outcomes)), "Admit state addressed to the new adapter")
	var/datum/netrun_machine_packet/data/old_packet
	var/datum/netrun_machine_packet/data/new_packet
	for(var/datum/netrun_machine_packet/data/packet as anything in SSnetrun.get_machine_transport().packets)
		if(packet.source != scene.source)
			continue
		if(packet.recipient == scene.target)
			old_packet = packet
		else if(packet.recipient == replacement)
			new_packet = packet
	TEST_ASSERT(old_packet && new_packet && old_packet != new_packet, "Coalescing must preserve distinct recipient lifetimes")
	TEST_ASSERT_EQUAL(old_packet.message.recipient, old_packet.recipient, "A new message cannot replace only the body of an old recipient's packet")
	qdel(scene.target)
	TEST_ASSERT(QDELETED(old_packet) && !QDELETED(new_packet), "Retiring the original service must cancel only its own packet")
	new_packet.deliver()
	TEST_ASSERT_EQUAL(replacement.received, 1, "The replacement must receive its own admitted state")
	TEST_ASSERT_EQUAL(replacement.last_payload["value"], 2, "The replacement must retain its exact latest body")

/// Sustained producers stop, their finite commands complete, and the delivery queue drains.
/datum/unit_test/netrun_transport_sustained_burst_drain/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/commands = list()
	var/list/snapshots = list()
	var/peak = 0
	var/started = world.time
	for(var/wave in 1 to 8)
		for(var/i in 1 to 128)
			TEST_ASSERT(scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture/queue_snapshot(list("value" = wave * 128 + i), snapshots)), "Sustained replaceable state must remain admitted")
		for(var/i in 1 to 4)
			TEST_ASSERT(scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture(list("command" = wave * 4 + i), commands)), "Finite commands must remain separate from replaceable state")
		peak = max(peak, scene.pending_packets())
		sleep(world.tick_lag)
	var/deadline = world.time + 6 SECONDS
	while(scene.pending_packets() && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(peak <= 33, "1024 replaceable states plus 32 commands must never retain more than one snapshot and all commands")
	TEST_ASSERT_EQUAL(commands["delivered"], 32, "Every nonreplaceable command must execute exactly once")
	TEST_ASSERT_EQUAL(scene.pending_packets(), 0, "Stopping the producer must drain all owned packet and delivery capacity")
	var/settled = scene.target.received
	sleep(1 SECONDS)
	TEST_ASSERT_EQUAL(scene.target.received, settled, "A quiescent transport must not generate further deliveries")
	log_world("NETRUN LOAD transport: snapshots=1024 commands=32 waves=8 pending_peak=[peak] snapshot_deliveries=[snapshots["delivered"]] drained_ds=[world.time - started] retained_pairs=[length(SSnetrun.get_machine_transport().pair_routes)] roots=[length(SSnetrun.get_topology().infrastructure_route_trees)]")

/// A station-sized working set must survive a complete second pass without rebuilding.
/datum/unit_test/netrun_transport_station_route_working_set/Run()
	var/datum/netrun_routing_cache_scene/scene = allocate(/datum/netrun_routing_cache_scene, run_loc_floor_bottom_left)
	var/list/sources = list()
	var/list/targets = list()
	for(var/i in 1 to 64)
		var/obj/machinery/netrun_server/transport_fixture/sender = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.source_spot)
		var/obj/machinery/netrun_server/transport_fixture/receiver = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.remote_spot)
		sources += sender.get_netrun_machine_service("transport.fixture")
		targets += receiver.get_netrun_machine_service("transport.fixture")
	SSnetrun.ensure_topology()
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/list/retained = list()
	var/started = REALTIMEOFDAY
	for(var/datum/netrun_machine_service/source as anything in sources)
		for(var/datum/netrun_machine_service/target as anything in targets)
			var/datum/netrun_machine_path/path = transport.borrowed_path(source, target)
			TEST_ASSERT(path, "Every source/target pair must have a physical path")
			retained += WEAKREF(path)
		CHECK_TICK
	var/index = 0
	for(var/datum/netrun_machine_service/source as anything in sources)
		for(var/datum/netrun_machine_service/target as anything in targets)
			var/datum/weakref/previous = retained[++index]
			TEST_ASSERT_EQUAL(transport.borrowed_path(source, target), previous.resolve(), "4096 active machine pairs must retain their cached paths across a full station poll")
		CHECK_TICK
	log_world("NETRUN LOAD routing: sources=64 targets=64 pairs=4096 polls=2 elapsed_ms=[(REALTIMEOFDAY - started) * 100] retained_pairs=[length(transport.pair_routes)] roots=[length(SSnetrun.get_topology().infrastructure_route_trees)]")

/datum/netrun_transport_scene/New(turf/origin, with_dns = TRUE, with_apc = TRUE)
	..(origin.z)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	previous_delivery_trace = transport.delivery_trace
	var/area/room = room(/area/netrun_route_test)
	for(var/turf/spot as anything in block(origin, locate(origin.x + 4, origin.y + 2, origin.z)))
		take(spot, room)
	source_spot = origin
	target_spot = get_step(origin, EAST)
	apc_spot = get_step(origin, NORTH)
	dns_spot = get_step(target_spot, NORTH)
	if(with_apc)
		apc = machine(/obj/machinery/power/apc, apc_spot)
	sender = machine(/obj/machinery/netrun_server/transport_fixture, source_spot)
	receiver = machine(/obj/machinery/netrun_server/transport_fixture, target_spot)
	// with_dns remains a positional compatibility argument; this is an ordinary
	// legacy information node, never a discovery authority or routing prerequisite.
	dns = machine(/obj/machinery/netrun_server/dns, dns_spot)
	source = sender.get_netrun_machine_service("transport.fixture")
	target = receiver.get_netrun_machine_service("transport.fixture")
	SSnetrun.ensure_topology()

/datum/netrun_transport_scene/Destroy()
	. = ..()
	SSnetrun.get_machine_transport().delivery_trace = previous_delivery_trace
	source = null
	target = null
	sender = null
	receiver = null
	dns = null
	apc = null

/datum/unit_test/proc/netrun_wait_delivery(list/outcomes, timeout = 5 SECONDS)
	var/deadline = world.time + timeout
	while(!outcomes["delivered"] && !outcomes["failed"] && world.time < deadline)
		sleep(world.tick_lag)
	return outcomes["delivered"]

/// Native speech admits subspace work asynchronously. Follow this radio's exact
/// transactions through discovery and every relay branch, including failures,
/// before checking receipt or isolation; unrelated station automation may continue.
/datum/unit_test/proc/netrun_wait_radio(obj/item/radio/radio, timeout = 5 SECONDS)
	var/datum/netrun_machine_service/source = radio.get_netrun_machine_service("telecomms.origin")
	var/list/transmissions = list()
	for(var/key in source.resolutions)
		var/datum/netrun_machine_resolution/query = source.resolutions[key]
		for(var/datum/netrun_machine_message/telecomms/message in query.queued)
			if(message.transmission)
				transmissions |= message.transmission
	for(var/datum/netrun_machine_packet/data/packet as anything in SSnetrun.get_machine_transport().packets)
		var/datum/netrun_machine_message/telecomms/message = packet.message
		if(istype(message) && message.signal?.source == radio && message.transmission)
			transmissions |= message.transmission
	var/list/budget = new_wait_budget(timeout, "[radio.type] telecomms transactions settled")
	for(var/datum/netrun_telecomms_transmission/transmission as anything in transmissions)
		while(!QDELETED(transmission) && !transmission.finished)
			if(!wait_budget_tick(budget))
				return FALSE
	return TRUE

/// Transaction completion stops observers before RF fallback releases the root
/// signal. A late/deleted dependency still clears fields through an empty index.
/datum/unit_test/netrun_transport_telecomms_observer_teardown/Run()
	var/obj/item/radio/radio = allocate(/obj/item/radio)
	var/mob/living/user = allocate(/mob/living)
	var/atom/movable/virtualspeaker/speaker = allocate(/atom/movable/virtualspeaker, null, user, radio)
	var/datum/signal/subspace/vocal/signal = new(radio, FREQ_COMMON, speaker, null, "observer teardown", list())
	allocated += signal
	signal.observe_netrun_dependencies()
	TEST_ASSERT(signal.netrun_dependencies[radio] && signal.netrun_dependencies[speaker], "A live telecomms signal must observe its native dependencies")
	signal.stop_netrun_dependency_observation()
	signal.stop_netrun_dependency_observation()
	TEST_ASSERT_NULL(signal.netrun_dependencies, "Repeated completion must release the complete observer index")
	signal.on_netrun_dependency_deleted(radio)
	signal.on_netrun_dependency_deleted(speaker)
	TEST_ASSERT_NULL(signal.source, "A late source callback must clear the retained radio reference")
	TEST_ASSERT_NULL(signal.virt, "A late speaker callback must clear the retained virtual speaker")
	TEST_ASSERT_NULL(signal.netrun_dependencies, "Late callbacks must leave an empty observer index")

/// APC discovery must really deliver a packet after asynchronous admission.
/datum/unit_test/netrun_transport_cold_delivery/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	TEST_ASSERT(scene.source && scene.target, "Both physical machines must register services")
	var/list/outcomes = list()
	var/started = world.time
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = 42), outcomes), scene.target.service_tag()), "A cold request must be admitted")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "Discovery admission must not execute native receive inline")
	TEST_ASSERT_EQUAL(length(scene.source.resolutions), 1, "An admitted request must own one asynchronous service lookup")
	TEST_ASSERT(netrun_wait_delivery(outcomes), "APC discovery/data delivery failed: [outcomes["reason"]]")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "The destination must receive exactly once")
	TEST_ASSERT_EQUAL(scene.target.last_payload["value"], 42, "The wire payload must survive discovery")
	TEST_ASSERT(outcomes["at"] - started <= 1 SECONDS, "A short local machine exchange must complete within one second")
	TEST_ASSERT_EQUAL(length(scene.source.resolutions), 0, "Completed discovery must retire its pending query")
	TEST_ASSERT(!length(SSnetrun.get_machine_transport().by_id["dns"]), "A successful exchange must need no DNS service")

/// Every send uses the same bounded discovery path; replies use actual data packets.
/datum/unit_test/netrun_transport_cached_reply/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/first = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = 1), first), scene.target.service_tag())
	TEST_ASSERT(netrun_wait_delivery(first), "Initial APC discovery must succeed before checking the next exchange")
	var/list/second = list()
	var/started = world.time
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = 2, "reply" = TRUE), second), scene.target.service_tag())
	TEST_ASSERT_EQUAL(length(scene.source.resolutions), 1, "Even a repeated address must use one asynchronous service lookup")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "A repeated send must return before native receive")
	TEST_ASSERT(netrun_wait_delivery(second), "The next queued delivery must succeed")
	var/deadline = world.time + 1 SECONDS
	while(!scene.source.received && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(scene.source.last_payload?["answer"], 2, "The reply must return to the real source service")
	TEST_ASSERT(world.time - started <= 1 SECONDS, "An established local request/reply must not have gameplay animation delays")

/// Machines created before their infrastructure must attach without a thirty-second poll.
/datum/unit_test/netrun_transport_late_infrastructure/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left, FALSE, FALSE)
	var/list/outcomes = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "late"), outcomes), scene.target.service_tag())
	scene.apc = scene.machine(/obj/machinery/power/apc, scene.apc_spot)
	var/ready_at = world.time
	TEST_ASSERT(netrun_wait_delivery(outcomes), "An admitted exchange must use the APC available when its discovery task executes")
	TEST_ASSERT(outcomes["at"] - ready_at <= 1 SECONDS, "A newly constructed APC must permit the queued lookup without a retry deadline")

/// Replacing a generic early component must preserve its published services and routes.
/datum/unit_test/netrun_transport_component_replacement/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_service/previous = scene.source
	var/datum/component/netrun_node/replacement = scene.sender.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 3)
	TEST_ASSERT_EQUAL(scene.sender.get_netrun_machine_service("transport.fixture"), previous, "Component replacement must preserve the service identity")
	TEST_ASSERT_EQUAL(previous.node, replacement, "The published service must move to the new component")
	TEST_ASSERT(!QDELETED(previous), "Old component teardown must not remove the replacement's service")
	var/list/outcomes = list()
	previous.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "rebound"), outcomes), scene.target.service_tag())
	TEST_ASSERT(netrun_wait_delivery(outcomes), "A rebound service must perform actual APC discovery and delivery")

/// A power loss after admission must fail once, with a useful route failure reason.
/datum/unit_test/netrun_transport_route_failure/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	var/datum/netrun_machine_packet/data/packet = new(scene.source, scene.target, new /datum/netrun_machine_message/transport_fixture(list(), outcomes))
	TEST_ASSERT(packet.send(), "The initial physical route must be usable")
	scene.apc.set_machine_stat(BROKEN)
	packet.deliver()
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "A lost route must fail its message once")
	TEST_ASSERT(outcomes["reason"] && !outcomes["delivered"], "Failure must report its cause without acknowledging delivery")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "There is no direct receive fallback after a cable failure")

/// A client must not route through a partially initialized map or exhaust its retry budget there.
/datum/unit_test/netrun_transport_mapload_barrier/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	SSatoms.map_loader_begin()
	scene.sender.set_machine_stat(NOPOWER)
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "startup"), outcomes), scene.target.service_tag())
	var/query_key = "transport.fixture|[scene.target.service_tag()]"
	var/datum/netrun_machine_resolution/query = scene.source.resolutions[query_key]
	var/deferred = !QDELETED(query) && !outcomes["delivered"] && !outcomes["failed"]
	scene.sender.set_machine_stat(0)
	SSatoms.map_loader_stop()
	SSnetrun.get_machine_transport().prepare_network()
	TEST_ASSERT(deferred, "Mapload requests must remain admitted until native initialization finishes")
	TEST_ASSERT(netrun_wait_delivery(outcomes), "Finishing bootstrap must resume the original request")

/// An absent service fails once at the authoritative registry without DNS retries.
/datum/unit_test/netrun_transport_registry_miss/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left, FALSE)
	var/list/outcomes = list()
	TEST_ASSERT(scene.source.send("transport.absent", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), "absent"), "An absent recipient must still use asynchronous discovery admission")
	TEST_ASSERT(!netrun_wait_delivery(outcomes), "An unregistered service cannot receive a message")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "An absent service must report one final discovery failure")
	TEST_ASSERT(outcomes["reason"] && !findtext(outcomes["reason"], "DNS"), "Service failure must have a useful reason without a DNS dependency")
	TEST_ASSERT_EQUAL(length(scene.source.resolutions), 0, "Failed discovery must not leave a dangling queue")

/// Exact recipient discovery must not scan every device of the same service type.
/datum/unit_test/netrun_transport_tag_index/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/extras = list()
	for(var/i in 1 to 20)
		var/obj/machinery/netrun_server/transport_fixture/extra = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.source_spot)
		extras += extra.get_netrun_machine_service("transport.fixture")
	var/list/result = SSnetrun.get_machine_transport().lookup(scene.source, "transport.fixture", scene.target.service_tag())
	TEST_ASSERT_EQUAL(length(result), 1, "Tagged discovery must return the intended endpoint")
	TEST_ASSERT_EQUAL(result[1], scene.target, "The tag index must identify the real service")
	for(var/datum/netrun_machine_service/transport_fixture/extra as anything in extras)
		TEST_ASSERT_EQUAL(extra.match_checks, 0, "Unrelated endpoint authorization must not run during exact-address lookup")
	var/old_tag = scene.target.service_tag()
	scene.receiver.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	TEST_ASSERT_EQUAL(length(SSnetrun.get_machine_transport().lookup(scene.source, "transport.fixture", old_tag)), 0, "Replacing an address must remove its old index entry")
	TEST_ASSERT_EQUAL(length(SSnetrun.get_machine_transport().lookup(scene.source, "transport.fixture", scene.target.service_tag())), 1, "The replacement must be discoverable immediately")

/// Every actual data hop has metadata, while payloads never leak into node packet journals.
/datum/unit_test/netrun_transport_packet_journal/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("private" = "SECRET_PACKET_BODY"), outcomes), scene.target.service_tag())
	TEST_ASSERT(netrun_wait_delivery(outcomes), "The journal scenario must really deliver a message")
	var/packet_id
	for(var/list/entry as anything in scene.source.node.packet_logs)
		if(entry["kind"] == "machine" && entry["phase"] == "SEND")
			packet_id = entry["id"]
	TEST_ASSERT(packet_id, "The sender must record an identifiable packet")
	var/datum/component/netrun_node/apc_node = scene.apc.GetComponent(/datum/component/netrun_node)
	var/forwarded = FALSE
	for(var/list/entry as anything in apc_node.packet_logs)
		if(entry["id"] == packet_id && entry["phase"] == "FORWARD")
			forwarded = TRUE
	TEST_ASSERT(forwarded, "The actual forwarding APC must journal the same packet")
	var/accepted = FALSE
	for(var/list/entry as anything in scene.target.node.packet_logs)
		if(entry["id"] == packet_id && entry["phase"] == "ACCEPT")
			accepted = TRUE
	TEST_ASSERT(accepted, "The recipient must distinguish receipt from acceptance")
	TEST_ASSERT(!findtext(json_encode(scene.target.node.packet_logs), "SECRET_PACKET_BODY"), "Node metadata must not expose private message contents")
	for(var/i in 1 to NETRUN_MAX_PACKET_LOG + 20)
		scene.target.node.add_packet_log(i, "SEND", "machine", "A", "B", "fixture")
	TEST_ASSERT_EQUAL(length(scene.target.node.packet_logs), NETRUN_MAX_PACKET_LOG, "Per-node packet history must remain bounded")

/// Actual PDA -> receiver -> bus -> processor -> bus -> message server -> hub,
/// relay probe/return -> broadcaster -> PDA, using APC discovery and native messenger.
/datum/unit_test/netrun_transport_pda_chain/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/item/modular_computer/pda/sender = allocate(/obj/item/modular_computer/pda, scene.source_spot)
	var/obj/item/modular_computer/pda/recipient = allocate(/obj/item/modular_computer/pda, scene.target_spot)
	sender.enabled = TRUE
	recipient.enabled = TRUE
	sender.toff = FALSE
	recipient.toff = FALSE
	sender.imprint_id("Transport sender", "Assistant")
	recipient.imprint_id("Transport recipient", "Assistant")
	var/datum/computer_file/program/messenger/sending = locate(/datum/computer_file/program/messenger) in sender.get_all_files()
	var/datum/computer_file/program/messenger/receiving = locate(/datum/computer_file/program/messenger) in recipient.get_all_files()
	TEST_ASSERT(sending && receiving && sending.computer == sender && receiving.computer == recipient, "The native PDAs must contain real installed messenger programs")
	TEST_ASSERT(GLOB.pda_messengers[REF(sending)] == sending && GLOB.pda_messengers[REF(receiving)] == receiving, "Native imprinting must publish both messenger contacts")
	sending.alert_able = FALSE
	receiving.alert_able = FALSE
	var/obj/machinery/telecomms/receiver/receiver = scene.machine(/obj/machinery/telecomms/receiver, scene.source_spot)
	var/obj/machinery/telecomms/bus/bus = scene.machine(/obj/machinery/telecomms/bus, scene.source_spot)
	var/obj/machinery/telecomms/processor/processor = scene.machine(/obj/machinery/telecomms/processor, scene.source_spot)
	var/obj/machinery/telecomms/message_server/server = scene.machine(/obj/machinery/telecomms/message_server, scene.target_spot)
	var/obj/machinery/telecomms/hub/hub = scene.machine(/obj/machinery/telecomms/hub, scene.target_spot)
	var/obj/machinery/telecomms/relay/relay = scene.machine(/obj/machinery/telecomms/relay, scene.target_spot)
	var/obj/machinery/telecomms/broadcaster/broadcaster = scene.machine(/obj/machinery/telecomms/broadcaster, scene.target_spot)
	receiver.links = list(bus)
	bus.links = list(processor, server)
	processor.links = list(bus)
	server.links = list(hub)
	hub.links = list(relay, broadcaster)
	relay.links = list(hub)
	SSnetrun.get_machine_transport().delivery_trace = list()
	var/start = world.time
	TEST_ASSERT(sending.send_message(sender, "Real routed message", list(receiving)), "The native PDA must admit a routed transmission")
	var/deadline = world.time + 5 SECONDS
	while(sending.netrun_pending_messages && world.time < deadline)
		sleep(world.tick_lag)
	log_world("NETRUN LOAD PDA: elapsed_ds=[world.time - start] hops=[json_encode(SSnetrun.get_machine_transport().delivery_trace)]")
	var/list/rejections = list()
	for(var/atom/device as anything in scene.owned + list(sender, recipient))
		var/datum/component/netrun_node/node = device.GetComponent(/datum/component/netrun_node)
		for(var/list/entry as anything in node?.packet_logs)
			if(entry["phase"] in list("REJECT", "DROP", "DISCOVERY_FAIL"))
				rejections += "[device.type]: [json_encode(entry)]"
	TEST_ASSERT(!sending.netrun_delivery_error && !sending.netrun_pending_messages, "The native delivery must finish successfully: [sending.netrun_delivery_status]; [jointext(rejections, "; ")]")
	var/datum/pda_chat/chat = receiving.find_chat_by_recipient(REF(sending))
	TEST_ASSERT_EQUAL(length(chat?.messages), 1, "The actual recipient must receive one chat message")
	var/datum/pda_message/message = chat.messages[1]
	TEST_ASSERT_EQUAL(message.message, "Real routed message", "The full telecomms route must preserve its payload")
	TEST_ASSERT_EQUAL(length(sending.find_chat_by_recipient(REF(receiving))?.messages), 1, "Only actual receipt must commit one outgoing message")
	TEST_ASSERT_EQUAL(length(server.pda_msgs), 2, "The real message server must log the transmission once, in addition to its startup notice")
	TEST_ASSERT(world.time - start <= 2 SECONDS, "A cold multi-machine PDA route must not accumulate multi-second gameplay delays at every hop")

/// Native camera discovery/handshake must survive construction before its tag is assigned.
/datum/unit_test/netrun_transport_camera_handshake/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, scene.source_spot)
	var/obj/machinery/camera/camera = scene.machine(/obj/machinery/camera, scene.target_spot)
	camera.c_tag = "Transport camera"
	camera.network = list("ss13")
	console.network = list("ss13")
	var/datum/netrun_machine_service/camera_viewer/viewer = console.get_netrun_machine_service("camera.viewer")
	var/started = world.time
	TEST_ASSERT(viewer.request_feed(camera.c_tag), "The camera handshake must be admitted")
	var/deadline = world.time + 3 SECONDS
	while(console.active_camera != camera && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(console.active_camera, camera, "The native console must acquire the camera through APC discovery and a real reply")
	TEST_ASSERT(world.time - started <= 1 SECONDS, "A local camera handshake must not use runner animation latency")
	scene.apc.set_machine_stat(BROKEN)
	TEST_ASSERT(!viewer.feed_available(), "A broken actual cable must revoke an established feed")

/// Delivered atmospheric telemetry is controller-local, with matching area/channel policy.
/datum/unit_test/netrun_transport_atmos_status/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/airalarm/alarm = scene.machine(/obj/machinery/airalarm, scene.source_spot)
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = scene.machine(/obj/machinery/atmospherics/components/unary/vent_pump, scene.target_spot)
	alarm.buildstage = 2
	vent.id_tag = "TRANSPORT-VENT"
	var/datum/netrun_machine_service/atmos/device/service = vent.get_netrun_machine_service("atmos.device")
	TEST_ASSERT(service, "The real vent must publish its machine service")
	TEST_ASSERT(vent.netrun_atmos_send("atmos.device", "atmos.controller", list("sigtype" = "status", "device" = "VP", "tag" = vent.id_tag, "power" = TRUE)), "Native atmosphere status must enter the transport")
	var/deadline = world.time + 3 SECONDS
	while(!alarm.netrun_vent_info[vent.id_tag] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag], "The actual controller must receive its own vent's routed status")

/// Research uses a delivered cache and subscribes to server changes over the same wire.
/datum/unit_test/netrun_transport_research_snapshot/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/computer/rdconsole/console = scene.machine(/obj/machinery/computer/rdconsole, scene.source_spot)
	TEST_ASSERT(server.stored_research && console.stored_research, "Native late initialization must bind the research machines")
	TEST_ASSERT_EQUAL(server.stored_research, console.stored_research, "The scene must share a logical research authority")
	console.request_research_snapshot()
	var/deadline = world.time + 3 SECONDS
	while(!console.netrun_research_cache && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(console.netrun_research_cache, "Initial research data must arrive despite late service creation")
	TEST_ASSERT(console.netrun_research_cache != server.stored_research, "The UI must keep a delivered cache instead of a direct authority reference")
	var/datum/netrun_machine_service/research_client/client = console.get_netrun_machine_service("research.client")
	var/previous = client.snapshot_revision
	server.stored_research.netrun_research_changed()
	deadline = world.time + 3 SECONDS
	while(client.snapshot_revision == previous && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(client.snapshot_revision > previous, "Authoritative changes must push a new delivered research snapshot")

/// Registry lookup must not resurrect a recipient destroyed before worker dispatch.
/datum/unit_test/netrun_transport_recipient_deleted_before_discovery/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), scene.target.service_tag())
	qdel(scene.receiver)
	TEST_ASSERT(!netrun_wait_delivery(outcomes), "A destroyed recipient must not receive the admitted command")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Recipient destruction before discovery must report exactly one failure")
	TEST_ASSERT(!outcomes["delivered"], "No stale directory or direct fallback may acknowledge the missing recipient")
	TEST_ASSERT_EQUAL(length(scene.source.resolutions), 0, "A failed registry lookup must release its pending query")

/// Both native manufacturing adapters must receive their own delivered research cache.
/datum/unit_test/netrun_transport_manufacturing_snapshot/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/rnd/server/server = scene.machine(/obj/machinery/rnd/server, scene.target_spot)
	var/obj/machinery/rnd/production/protolathe/lathe = scene.machine(/obj/machinery/rnd/production/protolathe, scene.source_spot)
	var/obj/machinery/mecha_part_fabricator/fabricator = scene.machine(/obj/machinery/mecha_part_fabricator, scene.source_spot)
	var/datum/netrun_machine_service/research_client/lathe_client = lathe.get_netrun_machine_service("research.client")
	var/datum/netrun_machine_service/research_client/fabricator_client = fabricator.get_netrun_machine_service("research.client")
	TEST_ASSERT(lathe_client.request() && fabricator_client.request(), "Both native machines must admit research discovery")
	var/deadline = world.time + 3 SECONDS
	while((lathe_client.snapshot_revision < 0 || fabricator_client.snapshot_revision < 0) && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(lathe_client.snapshot_revision >= 0 && fabricator_client.snapshot_revision >= 0, "Both native manufacturing caches must arrive through actual packets")
	TEST_ASSERT(lathe.stored_research != server.stored_research && fabricator.stored_research != server.stored_research, "Manufacturing caches must not alias the authoritative techweb")
	TEST_ASSERT_EQUAL(length(lathe.stored_research.researched_nodes), length(server.stored_research.researched_nodes), "The lathe must receive the server's research nodes")
	for(var/id in fabricator.stored_research.researched_designs)
		var/datum/design/design = SSresearch.techweb_design_by_id(id)
		TEST_ASSERT(design.build_type & MECHFAB, "The real mechfab must retain its native recipe filter")

/// Unique external mail travels to real consoles; an answer returns to one canonical record.
/datum/unit_test/netrun_transport_communications_answer/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/communications/ingress = scene.machine(/obj/machinery/computer/communications, scene.source_spot)
	var/obj/machinery/computer/communications/terminal = scene.machine(/obj/machinery/computer/communications, scene.target_spot)
	terminal.authenticated = TRUE
	var/mob/living/carbon/human/user = allocate(/mob/living/carbon/human, scene.target_spot)
	var/datum/comm_message/canonical = allocate(/datum/comm_message, "Transport question", "Choose an answer", list("Yes", "No"))
	canonical.answer_callback = CALLBACK(scene, TYPE_PROC_REF(/datum/netrun_transport_scene, answered))
	var/datum/netrun_machine_service/communications_gateway/gateway = ingress.get_netrun_machine_service("communications.gateway")
	gateway.broadcast(canonical, FALSE, TRUE)
	var/deadline = world.time + 3 SECONDS
	while(!length(terminal.messages) && world.time < deadline)
		sleep(world.tick_lag)
	var/datum/comm_message/inbox = terminal.messages[1]
	TEST_ASSERT(inbox && inbox != canonical, "The console must receive its own packet-delivered inbox copy")
	TEST_ASSERT_EQUAL(inbox.title, canonical.title, "Inbox delivery must preserve message data")
	TEST_ASSERT(terminal.queue_netrun_answer(inbox, 1, user), "The authenticated answer must enter the actual return route")
	while(!inbox.answered && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(canonical.answered, 1, "The original ingress record must receive the answer")
	TEST_ASSERT_EQUAL(inbox.answered, 1, "The answer acknowledgement must return to the console")
	TEST_ASSERT(!inbox.netrun_answer_pending, "Acknowledged answers must clear the UI's pending state")
	TEST_ASSERT_EQUAL(scene.answer_count, 1, "A unique message callback must run once")
	terminal.queue_netrun_answer(inbox, 2, user)
	sleep(0.5 SECONDS)
	TEST_ASSERT_EQUAL(canonical.answered, 1, "A duplicate answer must not overwrite the canonical choice")
	TEST_ASSERT_EQUAL(scene.answer_count, 1, "A repeated answer must not repeat the external callback")

/// Startup signal storms coalesce admission without executing a partially loaded map.
/datum/unit_test/netrun_transport_loading_admission_coalesced/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left, FALSE)
	var/list/outcomes = list()
	SSatoms.map_loader_begin()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), scene.target.service_tag())
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	for(var/i in 1 to 32)
		query.begin()
		SSnetrun.get_machine_transport().wake_resolutions()
	var/deferred = !QDELETED(query) && !outcomes["failed"] && !outcomes["delivered"] && !scene.target.received
	SSatoms.map_loader_stop()
	SSnetrun.get_machine_transport().prepare_network()
	TEST_ASSERT(deferred, "Repeated loading notifications must keep the original command admitted without running native receive")
	TEST_ASSERT(netrun_wait_delivery(outcomes), "The original queued message must execute once after native initialization completes")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "Coalesced loading notifications must not replay the command")

/// Backpressure rejects payloads before admitting discovery work or occupying source slots.
/datum/unit_test/netrun_transport_discovery_backpressure/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	var/list/outcomes = list()
	var/saved_queued = transport.queued_messages
	SSatoms.map_loader_begin()
	var/waiting_before = length(transport.waiting_resolutions)
	var/tasks_before = length(scheduler.by_key)
	transport.queued_messages = 4096
	var/admitted = 0
	for(var/i in 1 to 100)
		admitted += scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), "backpressure-[i]")
	var/retained_queries = length(scene.source.resolutions)
	var/retained_waiting = length(transport.waiting_resolutions)
	var/retained_tasks = length(scheduler.by_key)
	var/counted_messages = transport.queued_messages
	// Restore shared subsystem state before assertions, including a failed assertion.
	transport.queued_messages = saved_queued
	SSatoms.map_loader_stop()
	transport.prepare_network()
	TEST_ASSERT_EQUAL(admitted, 0, "A full payload queue must reject every new discovery burst")
	TEST_ASSERT_EQUAL(outcomes["failed"], 100, "Each rejected command must receive exactly one failure outcome")
	TEST_ASSERT_EQUAL(retained_queries, 0, "Rejected commands must not consume the source's 64 discovery slots")
	TEST_ASSERT_EQUAL(retained_waiting, waiting_before, "Rejected commands must not retain empty prebootstrap lookups")
	TEST_ASSERT_EQUAL(retained_tasks, tasks_before, "Rejected commands must not enqueue empty discovery tasks")
	TEST_ASSERT_EQUAL(counted_messages, 4096, "Destroying an empty rejected lookup must not debit another producer's messages")
	var/list/recovered = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "recovered"), recovered), scene.target.service_tag()), "Freeing capacity must immediately admit a fresh request after more than 64 rejected tags")
	TEST_ASSERT(netrun_wait_delivery(recovered), "A recovered discovery slot must deliver its actual payload")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "Rejected lookups must never replay or duplicate the recovered command")

/// Preloaded drive software must bind without ever opening its UI, including reinstallation.
/datum/unit_test/netrun_transport_preloaded_messenger/Run()
	var/obj/item/modular_computer/tablet/computer = allocate(/obj/item/modular_computer/tablet, run_loc_floor_bottom_left)
	var/obj/item/computer_hardware/hard_drive/drive = allocate(/obj/item/computer_hardware/hard_drive, run_loc_floor_bottom_left)
	var/datum/computer_file/program/messenger/app = new
	TEST_ASSERT(drive.store_file(app), "The detached drive must accept a preloaded messenger")
	TEST_ASSERT(!app.computer && !GLOB.pda_messengers[REF(app)], "Detached software must not publish a contact")
	computer.install_component(drive)
	TEST_ASSERT_EQUAL(drive.holder, computer, "The native tablet must accept the preloaded drive")
	TEST_ASSERT_EQUAL(app.computer, computer, "Installing a populated drive must bind its programs")
	TEST_ASSERT_EQUAL(GLOB.pda_messengers[REF(app)], app, "A preloaded messenger must register before its UI opens")
	var/datum/netrun_machine_service/service = computer.get_netrun_machine_service("pda.messenger")
	TEST_ASSERT_EQUAL(service.indexed_tag, REF(app), "The installed program must have a current service registry index")
	computer.uninstall_component(drive)
	TEST_ASSERT(!app.computer && !GLOB.pda_messengers[REF(app)], "Removing the drive must detach its contact and host")
	TEST_ASSERT(isnull(service.indexed_tag), "Removing the drive must retire its old service tag")
	computer.install_component(drive)
	TEST_ASSERT_EQUAL(GLOB.pda_messengers[REF(app)], app, "Reinstallation must restore the contact without duplicate signal listeners")
	TEST_ASSERT_EQUAL(service.indexed_tag, REF(app), "Reinstallation must republish the actual program")
	computer.update_id_imprint(null, null)
	TEST_ASSERT(!GLOB.pda_messengers[REF(app)], "A reinstalled program must receive native imprint-reset signals")
	computer.update_id_imprint("Reinstalled sender", "Assistant")
	TEST_ASSERT_EQUAL(GLOB.pda_messengers[REF(app)], app, "Native imprint updates must restore its contact")

/// Removing/replacing installed software updates both native and APC service registries.
/datum/unit_test/netrun_transport_messenger_replacement/Run()
	var/obj/item/modular_computer/pda/computer = allocate(/obj/item/modular_computer/pda, run_loc_floor_bottom_left)
	var/obj/item/computer_hardware/hard_drive/drive = computer.all_components[MC_HDD]
	var/datum/computer_file/program/messenger/previous = locate(/datum/computer_file/program/messenger) in computer.get_all_files()
	TEST_ASSERT(drive && previous, "The native PDA must install a real HDD messenger")
	var/datum/netrun_machine_service/service = computer.get_netrun_machine_service("pda.messenger")
	computer.active_program = previous
	previous.program_state = PROGRAM_STATE_ACTIVE
	TEST_ASSERT(drive.remove_file(previous), "Removing the installed app must succeed")
	TEST_ASSERT(!computer.active_program && previous.program_state == PROGRAM_STATE_KILLED, "Removing a running app must retire its active execution before unbinding")
	TEST_ASSERT(!previous.computer && !GLOB.pda_messengers[REF(previous)], "Removed software must leave no live contact")
	TEST_ASSERT(isnull(service.indexed_tag), "Removed software must leave no old service tag")
	qdel(previous)
	var/datum/computer_file/program/messenger/replacement = new
	TEST_ASSERT(drive.store_file(replacement), "The installed HDD must accept its replacement app")
	TEST_ASSERT_EQUAL(replacement.computer, computer, "The new app must bind to its physical computer immediately")
	TEST_ASSERT_EQUAL(GLOB.pda_messengers[REF(replacement)], replacement, "The replacement must publish before opening its UI")
	TEST_ASSERT_EQUAL(service.indexed_tag, REF(replacement), "The service registry must publish the replacement program's identity")
	computer.idle_threads |= replacement
	replacement.program_state = PROGRAM_STATE_BACKGROUND
	TEST_ASSERT(drive.remove_file(replacement), "Removing a background app must succeed")
	TEST_ASSERT(!(replacement in computer.idle_threads) && replacement.program_state == PROGRAM_STATE_KILLED, "Removed software must not remain in the computer's background execution list")
	qdel(replacement)

/// A runtime rename must join an occupied tag bucket, even if its original member is hidden.
/datum/unit_test/netrun_transport_camera_rename_existing_tag/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, scene.source_spot)
	console.network = list("ss13")
	var/obj/machinery/camera/hidden = scene.machine(/obj/machinery/camera, scene.target_spot)
	hidden.network = list("unavailable")
	hidden.set_camera_tag("Shared camera tag")
	var/obj/machinery/camera/renamed = scene.machine(/obj/machinery/camera, scene.target_spot)
	renamed.network = list("ss13")
	renamed.set_camera_tag("Previous camera tag")
	var/datum/netrun_machine_service/camera/hidden_service = hidden.get_netrun_machine_service("camera.stream")
	var/datum/netrun_machine_service/camera/renamed_service = renamed.get_netrun_machine_service("camera.stream")
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/list/occupied = transport.by_tag["camera.stream|Shared camera tag"]
	TEST_ASSERT(hidden_service in occupied, "The old tag bucket must already exist before the rename")
	renamed.set_camera_tag("Shared camera tag")
	occupied = transport.by_tag["camera.stream|Shared camera tag"]
	TEST_ASSERT((hidden_service in occupied) && (renamed_service in occupied), "A native rename must index both cameras without waiting for a lookup miss")
	TEST_ASSERT(!length(transport.by_tag["camera.stream|Previous camera tag"]), "A native rename must retire its old service tag")
	var/datum/netrun_machine_service/camera_viewer/viewer = console.get_netrun_machine_service("camera.viewer")
	var/list/eligible = viewer.resolve("camera.stream", "Shared camera tag")
	TEST_ASSERT_EQUAL(length(eligible), 1, "Native camera network filtering must still select only the visible camera")
	TEST_ASSERT(renamed_service in eligible, "Addressed discovery must find the renamed camera in a nonempty tag bucket")
	TEST_ASSERT(viewer.request_feed(renamed.c_tag), "The native feed request must be admitted for the renamed tag")
	var/deadline = world.time + 3 SECONDS
	while(console.active_camera != renamed && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(console.active_camera, renamed, "The renamed camera must complete its actual routed request and reply")
