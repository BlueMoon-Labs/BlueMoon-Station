/// One authoritative event per accepted delivery, independent of UI log projections.
/datum/unit_test/proc/netrun_illegal_delivery_reports(datum/component/netrun_node/node)
	. = 0
	for(var/datum/netrun_incident/incident as anything in SSnetrun.incidents)
		if(incident.kind == "intrusion" && incident.address == node.address)
			. += incident.reports

/// Custom providers share the same delivery boundary as native APIs and report only handled actions.
/datum/unit_test/netrun_security_api_delivery/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/item/netrun_provider_test/conditional/target = allocate(/obj/item/netrun_provider_test/conditional, run_loc_floor_bottom_left)
	target.anchored = TRUE
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 1, list(ACCESS_RD))
	var/atom/source_host = scene.node_a.parent
	var/datum/netrun_console/console = allocate(/datum/netrun_console, source_host)
	console.operator = allocate(/mob)
	console.connection.wireless = FALSE
	console.access_session.node_access[node.address] = NETRUN_ACCESS_USER
	TEST_ASSERT(console.remote_request(node.address, "write", list("value" = -2)), "An acquired USER grant admits the ordinary provider request")
	var/datum/netrun_request/remote/packet = netrun_operation_packet(console, /datum/netrun_request/remote)
	TEST_ASSERT_NOTNULL(packet, "The API action first owns a real delivery packet")
	TEST_ASSERT_EQUAL(netrun_illegal_delivery_reports(node), 0, "Admission cannot accuse an actor before the device handles its request")
	var/trace_before = console.intrusion.trace
	TEST_ASSERT(packet.deliver(), "The available provider handles the validated request")
	TEST_ASSERT_EQUAL(target.deliveries, 1, "The actual provider side effect executes once")
	TEST_ASSERT_EQUAL(netrun_illegal_delivery_reports(node), 1, "A successful unauthorized API delivery reports exactly one incident")
	TEST_ASSERT_EQUAL(console.intrusion.trace, trace_before + 6 * node.get_security(), "Reporting must preserve the API's existing trace price")
	console.next_command = world.time
	TEST_ASSERT(console.remote_request(node.address, "write", list("value" = -3)), "A second operation may be admitted before service withdrawal")
	packet = netrun_operation_packet(console, /datum/netrun_request/remote)
	target.service_enabled = FALSE
	trace_before = console.intrusion.trace
	TEST_ASSERT(!packet.deliver(), "A withdrawn provider must reject its queued operation")
	TEST_ASSERT_EQUAL(target.deliveries, 1, "A rejected operation never reaches the provider")
	TEST_ASSERT_EQUAL(netrun_illegal_delivery_reports(node), 1, "A rejected API delivery must not create another accusation")
	TEST_ASSERT_EQUAL(console.intrusion.trace, trace_before, "A rejected API operation spends no successful-execution trace")

/// Physical evidence reveals equipment and sectors, then expires without idle polling.
/datum/unit_test/netrun_station_interference_evidence/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/netrun_terminal/target = scene.machine(/obj/machinery/computer/netrun_terminal, get_turf(scene.node_b.parent))
	var/datum/component/netrun_node/node = netrun_find_node(target)
	var/datum/netrun_console/attacker = allocate(/datum/netrun_console, scene.node_a.parent)
	var/list/examine_list = list()
	SEND_SIGNAL(target, COMSIG_PARENT_EXAMINE, null, examine_list)
	TEST_ASSERT(!findtext(jointext(examine_list, " "), "сетевого вмешательства"), "Untouched equipment cannot accuse an operator")
	attacker.report_illegal_activity(node, "station evidence fixture", NETRUN_ACCESS_ROOT)
	TEST_ASSERT(node.interference_until > world.time, "A completed illegal action leaves a physical diagnostic trace")
	TEST_ASSERT(scene.apc_node.suspicious_traffic_until > world.time, "The actual sector APC exposes the suspicious traffic")
	SEND_SIGNAL(target, COMSIG_PARENT_EXAMINE, null, examine_list)
	TEST_ASSERT(findtext(jointext(examine_list, " "), "сетевого вмешательства"), "Physical examination describes recent interference")
	var/feedback_deadline = node.next_interference_feedback
	attacker.report_illegal_activity(node, "repeated station evidence fixture", NETRUN_ACCESS_ROOT)
	TEST_ASSERT_EQUAL(node.next_interference_feedback, feedback_deadline, "Repeated interference cannot spam physical sound and visible feedback")
	examine_list.Cut()
	SEND_SIGNAL(scene.apc, COMSIG_PARENT_EXAMINE, null, examine_list)
	TEST_ASSERT(findtext(jointext(examine_list, " "), "Изолируйте сетевой интерфейс"), "The physical APC clue explains how to interrupt the connection")
	node.interference_until = world.time
	examine_list.Cut()
	SEND_SIGNAL(target, COMSIG_PARENT_EXAMINE, null, examine_list)
	TEST_ASSERT(!findtext(jointext(examine_list, " "), "сетевого вмешательства"), "Expired evidence disappears without waking an idle node")

/// A local network switch invalidates retained routes independently of power and acquired keys.
/datum/unit_test/netrun_station_apc_isolation/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, scene.node_a.parent)
	TEST_ASSERT(console.can_route(scene.node_b), "The sector initially has a real route through its APC")
	var/power_before = scene.apc.operating
	var/epoch_before = scene.apc_node.access_key_epoch
	TEST_ASSERT(scene.apc.set_netrun_isolated(TRUE), "Physical isolation can disconnect the sector network")
	TEST_ASSERT(!console.can_route(scene.node_b), "A retained route cannot pass the isolated APC")
	TEST_ASSERT_EQUAL(scene.node_a.uplink_node(), scene.apc_node, "Isolated endpoints cannot escape to another APC")
	TEST_ASSERT_EQUAL(scene.apc.operating, power_before, "Network isolation preserves the sector power breaker")
	TEST_ASSERT(scene.apc.set_netrun_isolated(FALSE), "A local operator can reconnect the interface")
	TEST_ASSERT(console.can_route(scene.node_b), "Reconnection restores the real physical route")
	TEST_ASSERT_EQUAL(scene.apc_node.access_key_epoch, epoch_before, "A reversible disconnect does not revoke acquired keys or rebind equipment")

/// The switch is a physical APC control, with the native lock and an independent locality check.
/datum/unit_test/netrun_station_apc_isolation_authority/Run()
	var/datum/netrun_client_scene/scene = allocate(/datum/netrun_client_scene, run_loc_floor_bottom_left)
	var/datum/tgui/ui = allocate(/datum/tgui, scene.user, scene.apc, "Apc")
	ui.status = UI_INTERACTIVE
	scene.apc.locked = TRUE
	usr = scene.user
	scene.apc.ui_act("netrun_isolate", list(), ui)
	usr = null
	TEST_ASSERT(!scene.apc.netrun_isolated, "A locked physical panel rejects network isolation")
	scene.apc.locked = FALSE
	scene.user.forceMove(scene.far_spot)
	usr = scene.user
	scene.apc.ui_act("netrun_isolate", list(), ui)
	usr = null
	TEST_ASSERT(!scene.apc.netrun_isolated, "Even a stale interactive UI cannot isolate a distant APC")
	scene.user.forceMove(run_loc_floor_bottom_left)
	usr = scene.user
	scene.apc.ui_act("netrun_isolate", list(), ui)
	usr = null
	TEST_ASSERT(scene.apc.netrun_isolated, "An adjacent operator can use an unlocked APC's physical network switch")
	usr = scene.user
	scene.apc.ui_act("netrun_isolate", list(), ui)
	usr = null
	TEST_ASSERT(!scene.apc.netrun_isolated, "The same local panel restores the network while the APC is isolated")
	scene.apc.failure_timer = 1
	usr = scene.user
	scene.apc.ui_act("netrun_isolate", list(), ui)
	usr = null
	TEST_ASSERT(!scene.apc.netrun_isolated, "The APC reboot exception cannot bypass the network switch guard")
	var/datum/netrun_provider/provider = SSnetrun.get_provider(scene.apc)
	TEST_ASSERT(!("netrun_isolate" in provider.actions), "The local switch cannot be reversed through a compromised netrun API")

/// Physical security consoles receive bounded, anonymous alerts through actual routed packets.
/datum/unit_test/netrun_station_security_subscription/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, get_turf(scene.node_b.parent))
	var/datum/netrun_machine_service/security_events/publisher = scene.apc.get_netrun_machine_service("security.events")
	var/datum/netrun_machine_service/security_monitor/monitor = console.get_netrun_machine_service("security.monitor")
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/deadline = world.time + 5 SECONDS
	while(!transport.is_ready() && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(transport.is_ready(), "Physical security subscriptions use the machine transport readiness barrier")
	TEST_ASSERT_NOTNULL(publisher, "One physical APC aggregates its sector's station alarms")
	TEST_ASSERT_NOTNULL(monitor, "The native camera console owns a security monitor")
	publisher.subscribers.Cut()
	monitor.alerts.Cut()
	TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message(list("operation" = "subscribe"))), "An operational security console may request a real subscription")
	var/datum/netrun_machine_packet/data/packet = netrun_security_packet(monitor, publisher, "subscribe")
	TEST_ASSERT_NOTNULL(packet, "Subscription is a normal routed machine packet")
	TEST_ASSERT(!length(publisher.subscribers), "Admission alone cannot subscribe the console")
	packet.deliver()
	TEST_ASSERT_EQUAL(length(publisher.subscribers), 1, "Subscription becomes effective on delivery")
	var/datum/netrun_incident/incident = SSnetrun.report_incident("intrusion", scene.apc_node, null, NETRUN_INCIDENT_MEDIUM, "Station security fixture")
	TEST_ASSERT(!length(publisher.pending_events), "An isolated medium incident cannot flood physical security")
	SSnetrun.report_incident("intrusion", scene.apc_node, null, NETRUN_INCIDENT_MEDIUM, "Repeated station security fixture")
	TEST_ASSERT_EQUAL(length(monitor.alerts), 0, "The global incident hook does not bypass network delivery")
	publisher.publish_slice()
	packet = netrun_security_packet(publisher, monitor, "event")
	TEST_ASSERT_NOTNULL(packet, "Repeated medium incidents enter ordinary machine delivery")
	packet.deliver()
	TEST_ASSERT_EQUAL(length(monitor.alerts), 1, "The physical console receives the delivered incident")
	var/list/received = monitor.alerts[1]
	TEST_ASSERT_EQUAL(received["id"], incident.id, "The public journal retains the authoritative incident ID")
	TEST_ASSERT_EQUAL(received["reports"], 2, "The public journal records repeat count")
	TEST_ASSERT_NULL(received["suspect"], "A public station alarm does not disclose the actor's identity")
	TEST_ASSERT(received["area"], "The physical crew receives a useful area-level clue")
	var/list/data = console.ui_data()
	TEST_ASSERT_EQUAL(length(data["network_alerts"]), 1, "The native security console exposes its delivered journal")
	SSnetrun.report_incident("intrusion", scene.apc_node, null, NETRUN_INCIDENT_MEDIUM, "Third station security fixture")
	publisher.publish_slice()
	packet = netrun_security_packet(publisher, monitor, "event")
	TEST_ASSERT_NOTNULL(packet, "Updated incidents still travel through packets")
	packet.deliver()
	TEST_ASSERT_EQUAL(length(monitor.alerts), 1, "Repeats replace the existing journal row instead of flooding it")
	received = monitor.alerts[1]
	TEST_ASSERT_EQUAL(received["reports"], 3, "An incident update refreshes the same row")
	SSnetrun.report_incident("trace", scene.apc_node, null, NETRUN_INCIDENT_HIGH, "Disconnected station security fixture")
	publisher.publish_slice()
	packet = netrun_security_packet(publisher, monitor, "event")
	TEST_ASSERT_NOTNULL(packet, "High incidents also use real packets")
	console.set_machine_stat(NOPOWER)
	TEST_ASSERT(!packet.deliver(), "A console disconnected in flight cannot receive an alert")
	TEST_ASSERT_EQUAL(length(monitor.alerts), 1, "Disconnected equipment retains only its previously delivered journal")
	publisher.prune_subscribers()
	TEST_ASSERT(!length(publisher.subscribers), "An unpowered monitor may lose its stale subscription")
	console.set_machine_stat(0)
	deadline = world.time + 5 SECONDS
	while(!publisher.subscribers[monitor.service_key()] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(publisher.subscribers[monitor.service_key()], "Restoring power resubscribes the physical console through queued network discovery")
	SSnetrun.report_incident("trace", scene.apc_node, null, NETRUN_INCIDENT_HIGH, "Restored station security fixture")
	publisher.publish_slice()
	packet = netrun_security_packet(publisher, monitor, "event")
	TEST_ASSERT_NOTNULL(packet, "Restored consoles can receive new routed alarms")
	packet.deliver()
	TEST_ASSERT_EQUAL(length(monitor.alerts), 2, "Power restoration resumes the physical security journal")

/// Full disks and missing files cannot produce tracking evidence for a mutation that never occurred.
/datum/unit_test/netrun_security_file_delivery/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/atom/source_host = scene.node_a.parent
	var/datum/netrun_console/console = allocate(/datum/netrun_console, source_host)
	console.operator = allocate(/mob)
	console.connection.wireless = FALSE
	console.access_session.node_access[scene.node_b.address] = NETRUN_ACCESS_USER
	var/datum/netrun_file/file = new("evidence-payload.txt", NETRUN_FILE_TEXT, "Personal payload", 1)
	TEST_ASSERT(console.store_file(file), "The sender owns an actual source file")
	scene.node_b.file_store.capacity = 8
	var/baseline_files = length(scene.node_b.file_store.files)
	TEST_ASSERT(console.queue_file_request("upload", scene.node_b, file.uid), "An initially writable disk admits the ordinary file request")
	var/datum/netrun_request/file/packet = netrun_operation_packet(console, /datum/netrun_request/file)
	var/trace_before = console.intrusion.trace
	scene.node_b.file_store.capacity = 0
	TEST_ASSERT(!packet.deliver(), "A disk that becomes read-only in flight rejects its actual write")
	TEST_ASSERT_EQUAL(length(scene.node_b.file_store.files), baseline_files, "The rejected upload adds no remote file")
	TEST_ASSERT(file in console.inventory.local_store.files, "A failed copy preserves the sender's original")
	TEST_ASSERT_EQUAL(netrun_illegal_delivery_reports(scene.node_b), 0, "An unhandled file write cannot produce an intrusion report")
	TEST_ASSERT_EQUAL(console.intrusion.trace, trace_before, "Failed disk writes preserve the existing no-trace behavior")
	scene.node_b.file_store.capacity = 8
	console.next_command = world.time
	TEST_ASSERT(console.queue_file_request("upload", scene.node_b, file.uid), "A repaired destination admits a new upload")
	packet = netrun_operation_packet(console, /datum/netrun_request/file)
	TEST_ASSERT(packet.deliver(), "The actual upload succeeds after free space returns")
	TEST_ASSERT_EQUAL(netrun_illegal_delivery_reports(scene.node_b), 1, "Successful acquired-access file writes emit exactly one report")
	TEST_ASSERT_EQUAL(console.intrusion.trace, trace_before + 3 * scene.node_b.get_security(), "The file wrapper must not add a second trace charge")
	var/datum/netrun_file/remote_copy
	for(var/datum/netrun_file/candidate as anything in scene.node_b.file_store.files)
		if(candidate.name == file.name && candidate.kind == file.kind)
			remote_copy = candidate
			break
	TEST_ASSERT_NOTNULL(remote_copy, "The successful upload owns a real independent remote file")
	console.next_command = world.time
	TEST_ASSERT(console.queue_file_request("download", scene.node_b, remote_copy.uid), "The real remote file initially admits a download")
	packet = netrun_operation_packet(console, /datum/netrun_request/file)
	TEST_ASSERT(scene.node_b.file_store.remove(remote_copy), "The fixture withdraws the exact source after dispatch without deleting its pending packet")
	trace_before = console.intrusion.trace
	var/local_files_before = length(console.inventory.local_store.files)
	TEST_ASSERT(!packet.deliver(), "A source withdrawn after dispatch cannot be downloaded")
	TEST_ASSERT_EQUAL(netrun_illegal_delivery_reports(scene.node_b), 1, "A missing UID does not create a duplicate intrusion report")
	TEST_ASSERT_EQUAL(console.intrusion.trace, trace_before, "The rejected missing-file delivery cannot spend a success trace charge")
	TEST_ASSERT_EQUAL(length(console.inventory.local_store.files), local_files_before, "The rejected download cannot create a local copy")
	qdel(remote_copy)

/// Only readiness announcements are observed here; control packets still use
/// the real transport and inherited receiver in the admission regressions below.
/datum/netrun_machine_service/security_events/subscription_probe
	start_when_ready = FALSE
	var/prune_calls = 0
	var/advertisements = 0

/datum/netrun_machine_service/security_events/subscription_probe/prune_subscribers()
	prune_calls++
	return ..()

/datum/netrun_machine_service/security_events/subscription_probe/send(destination_id, datum/netrun_machine_message/message, recipient_tag)
	advertisements += message.payload["operation"] == "advertise"
	qdel(message)
	return TRUE

/// Direct cybernetic reconnects must survive a temporarily closed barrier even
/// without a later machinery signal, and every ready publisher must announce itself.
/datum/unit_test/netrun_security_subscription_readiness/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/deadline = world.time + 5 SECONDS
	while(!transport.is_ready() && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(transport.is_ready(), "Readiness decisions require the ordinary transport barrier")
	var/bootstrapped = transport.bootstrap_complete
	transport.bootstrap_complete = FALSE
	var/datum/netrun_machine_service/security_events/subscription_probe/startup = allocate(/datum/netrun_machine_service/security_events/subscription_probe, scene.node_a)
	startup.network_ready()
	var/datum/weakref/parked = transport.pending_ready_services[startup.service_key()]
	var/advertisements_while_closed = startup.advertisements
	// Restore the shared barrier before any assertion can return from this fixture.
	transport.bootstrap_complete = bootstrapped
	TEST_ASSERT(parked?.resolve() == startup, "A direct reconnect during map loading must park its exact service for later replay")
	TEST_ASSERT_EQUAL(advertisements_while_closed, 0, "A closed barrier must not send an announcement early")
	transport.wake_ready_services()
	deadline = world.time + 5 SECONDS
	while(!startup.advertisements && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(startup.advertisements, 1, "Reopening the barrier must replay a direct reconnect without another power signal")
	startup.on_station_network_restored()
	SSnetrun.task_scheduler.cancel("service_initialize", startup)
	startup.network_ready()
	TEST_ASSERT_EQUAL(startup.advertisements, 2, "Native restoration must still announce a previously ready publisher")
	var/obj/item/late_host = allocate(/obj/item, run_loc_floor_bottom_left)
	var/datum/netrun_machine_service/security_events/subscription_probe/late = allocate(/datum/netrun_machine_service/security_events/subscription_probe, scene.node_a, late_host)
	late.network_ready()
	TEST_ASSERT_EQUAL(late.advertisements, 1, "A publisher registered after bootstrap must announce itself to existing monitors")

/// Only a successful current delivery can suppress duplicate advertisement replies.
/// Publisher recovery/replacement and ACK eviction remain safe idempotent retries.
/datum/unit_test/netrun_security_subscription_acknowledgements/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, get_turf(scene.node_b.parent))
	var/datum/netrun_machine_service/security_monitor/monitor = console.get_netrun_machine_service("security.monitor")
	var/datum/netrun_machine_service/security_events/subscription_probe/publisher = allocate(/datum/netrun_machine_service/security_events/subscription_probe, scene.node_a)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/deadline = world.time + 5 SECONDS
	while(!transport.is_ready() && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(transport.is_ready(), "Acknowledgements require the ordinary native routing barrier")
	publisher.subscribers.Cut()
	monitor.acknowledged_publishers.Cut()
	for(var/datum/netrun_machine_packet/data/old as anything in transport.packets.Copy())
		if(old.source == monitor && old.recipient == publisher)
			qdel(old)
	TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation)), "Admit a real initial subscription")
	TEST_ASSERT(!length(monitor.acknowledged_publishers), "Admission cannot acknowledge data that has not arrived")
	var/datum/netrun_machine_packet/data/packet = netrun_security_packet(monitor, publisher, "subscribe")
	TEST_ASSERT(packet.message.coalescing_key(), "Subscription control must remain replaceable")
	TEST_ASSERT_EQUAL(packet.delivery_priority(), NETRUN_TASK_NORMAL, "Replaceable subscription control must retain the same priority as its discovery producer")
	packet.queue_delivery()
	var/datum/netrun_task/subscribe_task = SSnetrun.task_scheduler.by_key["machine_delivery:[REF(packet)]"]
	TEST_ASSERT(subscribe_task && subscribe_task.priority == NETRUN_TASK_NORMAL, "The actual subscription delivery task must use NORMAL priority")
	packet.deliver()
	TEST_ASSERT(monitor.subscription_acknowledged(publisher, publisher.advertisement_generation), "A successful current native delivery must remember its exact publisher")
	TEST_ASSERT(publisher.send_to(monitor, new /datum/netrun_machine_message/security_advertisement(publisher.advertisement_generation)), "A delayed startup advertisement still travels over the wire")
	packet = netrun_security_packet(publisher, monitor, "advertise")
	TEST_ASSERT(packet.message.coalescing_key(), "Advertisement control must remain replaceable")
	TEST_ASSERT_EQUAL(packet.delivery_priority(), NETRUN_TASK_NORMAL, "Replaceable advertisement control must not yield behind its discovery producer")
	packet.queue_delivery()
	var/datum/netrun_task/advertise_task = SSnetrun.task_scheduler.by_key["machine_delivery:[REF(packet)]"]
	TEST_ASSERT(advertise_task && advertise_task.priority == NETRUN_TASK_NORMAL, "The actual advertisement delivery task must use NORMAL priority")
	packet.deliver()
	TEST_ASSERT_NULL(netrun_security_packet(monitor, publisher, "subscribe"), "An already acknowledged startup subscription must not send a duplicate reply")
	TEST_ASSERT(publisher.send_to(monitor, new /datum/netrun_machine_message/security_advertisement(publisher.advertisement_generation)), "An advertisement may already be queued when its monitor loses authorization")
	packet = netrun_security_packet(publisher, monitor, "advertise")
	console.set_machine_stat(NOPOWER)
	publisher.prune_subscribers()
	TEST_ASSERT(!monitor.subscription_acknowledged(publisher, publisher.advertisement_generation), "Pruning the actual subscription must invalidate its advisory acknowledgement")
	console.set_machine_stat(0)
	packet.deliver()
	var/datum/netrun_machine_packet/data/repair = netrun_security_packet(monitor, publisher, "subscribe")
	TEST_ASSERT_NOTNULL(repair, "A pre-outage advertisement must repair pruned state after native recovery instead of trusting a stale ACK")
	repair.deliver()
	var/old_advertisement_generation = publisher.advertisement_generation
	publisher.network_ready()
	publisher.subscribers.Cut()
	TEST_ASSERT(publisher.send_to(monitor, new /datum/netrun_machine_message/security_advertisement(publisher.advertisement_generation)), "Publisher recovery must advertise its new readiness generation")
	packet = netrun_security_packet(publisher, monitor, "advertise")
	TEST_ASSERT(publisher.send_to(monitor, new /datum/netrun_machine_message/security_advertisement(old_advertisement_generation)), "An old discovery wave may attempt a late advertisement replacement")
	TEST_ASSERT_EQUAL(packet.message.payload["generation"], publisher.advertisement_generation, "An old advertisement must not displace the newer pending recovery")
	packet.deliver()
	var/datum/netrun_machine_packet/data/subscribe = netrun_security_packet(monitor, publisher, "subscribe")
	TEST_ASSERT_NOTNULL(subscribe, "A new publisher readiness generation must invalidate an old acknowledgement")
	TEST_ASSERT(publisher.send_to(monitor, new /datum/netrun_machine_message/security_advertisement(publisher.advertisement_generation)), "A duplicate recovery advertisement is still an ordinary packet")
	packet = netrun_security_packet(publisher, monitor, "advertise")
	packet.deliver()
	TEST_ASSERT_EQUAL(netrun_security_packet(monitor, publisher, "subscribe"), subscribe, "Repeated ads before acknowledgement must share one pending subscription")
	subscribe.deliver()
	TEST_ASSERT(publisher.subscribers[monitor.service_key()], "Recovery retry must restore the actual publisher subscription")
	var/publisher_key = publisher.service_key()
	qdel(publisher)
	publisher = allocate(/datum/netrun_machine_service/security_events/subscription_probe, scene.node_a)
	TEST_ASSERT_EQUAL(publisher.service_key(), publisher_key, "The replacement fixture reuses the same host/service key")
	TEST_ASSERT(!monitor.subscription_acknowledged(publisher, publisher.advertisement_generation), "A weak acknowledgement cannot transfer to a new publisher instance with the same key")
	TEST_ASSERT(publisher.send_to(monitor, new /datum/netrun_machine_message/security_advertisement(publisher.advertisement_generation)), "A replacement publisher must announce over ordinary delivery")
	packet = netrun_security_packet(publisher, monitor, "advertise")
	packet.deliver()
	subscribe = netrun_security_packet(monitor, publisher, "subscribe")
	TEST_ASSERT_NOTNULL(subscribe, "A replacement instance must receive its own subscription")
	monitor.acknowledged_publishers.Cut()
	for(var/index in 1 to 512)
		monitor.acknowledged_publishers["retired-[index]"] = list("publisher" = WEAKREF(publisher), "generation" = monitor.subscription_generation, "advertisement_generation" = publisher.advertisement_generation)
	subscribe.deliver()
	TEST_ASSERT_EQUAL(length(monitor.acknowledged_publishers), 512, "Long-round publisher churn must not grow acknowledgement hints beyond their fixed bound")
	TEST_ASSERT_NULL(monitor.acknowledged_publishers["retired-1"], "A new successful peer acknowledgement must evict the oldest hint")
	TEST_ASSERT(monitor.subscription_acknowledged(publisher, publisher.advertisement_generation), "Bounded eviction must retain the latest successful subscription")

/// Subscription controls describe desired state: coalescing and delivery-time
/// generations must preserve the latest toggle without bypassing real packets.
/datum/unit_test/netrun_security_subscription_control_coalescing/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, get_turf(scene.node_b.parent))
	var/datum/netrun_machine_service/security_events/publisher = scene.apc.get_netrun_machine_service("security.events")
	var/datum/netrun_machine_service/security_monitor/monitor = console.get_netrun_machine_service("security.monitor")
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/deadline = world.time + 5 SECONDS
	while(!transport.is_ready() && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(transport.is_ready(), "Control coalescing requires usable native routing")
	publisher.subscribers.Cut()
	for(var/datum/netrun_machine_packet/data/old as anything in transport.packets.Copy())
		if(old.source == monitor && old.recipient == publisher)
			qdel(old)
	for(var/index in 1 to 64)
		TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation)), "A repeated desired state must remain admissible")
	var/packets = 0
	for(var/datum/netrun_machine_packet/data/candidate as anything in transport.packets)
		if(candidate.source == monitor && candidate.recipient == publisher)
			packets++
	TEST_ASSERT_EQUAL(packets, 1, "A burst of duplicate subscriptions must retain one real in-flight packet")
	var/datum/netrun_machine_packet/data/packet = netrun_security_packet(monitor, publisher, "subscribe")
	TEST_ASSERT_NOTNULL(packet, "The coalesced subscription must remain an ordinary machine packet")
	TEST_ASSERT(!length(publisher.subscribers), "Admission must not subscribe before delivery")
	TEST_ASSERT(monitor.set_subscription(FALSE), "The native monitor may opt out while its initial subscribe is in flight")
	var/disabled_generation = monitor.subscription_generation
	TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message/security_subscription(FALSE, disabled_generation)), "The opt-out state must enter the same peer delivery slot")
	TEST_ASSERT_EQUAL(netrun_security_packet(monitor, publisher, "unsubscribe"), packet, "Unsubscribe must replace the pending subscribe rather than race it")
	packet.deliver()
	TEST_ASSERT(!length(publisher.subscribers), "The latest disabled state must win on actual arrival")
	TEST_ASSERT(monitor.set_subscription(TRUE), "Explicit opt-in must advance the desired state again")
	var/datum/netrun_machine_resolution/query = monitor.resolutions["security.events|"]
	TEST_ASSERT_NOTNULL(query, "The latest toggle must retain its asynchronous discovery request")
	TEST_ASSERT(monitor.send("security.events", new /datum/netrun_machine_message/security_subscription(FALSE, disabled_generation)), "An earlier toggle may re-enter discovery after the current desired state")
	var/datum/netrun_machine_message/queued_control = query.queued[1]
	TEST_ASSERT_EQUAL(queued_control.payload["generation"], monitor.subscription_generation, "A stale control must not displace newer desired state still waiting in discovery")
	TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation)), "The re-enabled state must be routed normally")
	packet = netrun_security_packet(monitor, publisher, "subscribe")
	TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message/security_subscription(FALSE, disabled_generation)), "A stale opt-out may race a newer pending wire packet")
	TEST_ASSERT_EQUAL(netrun_security_packet(monitor, publisher, "subscribe"), packet, "A stale control must preserve the newer pending packet")
	TEST_ASSERT_EQUAL(packet.message.payload["generation"], monitor.subscription_generation, "The newest admitted generation must survive before delivery")
	packet.deliver()
	TEST_ASSERT(publisher.subscribers[monitor.service_key()], "Delivered opt-in establishes the real subscription")
	TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message/security_subscription(FALSE, disabled_generation)), "A delayed old generation may still arrive as a separate admitted packet")
	packet = netrun_security_packet(monitor, publisher, "unsubscribe")
	packet.deliver()
	TEST_ASSERT(publisher.subscribers[monitor.service_key()], "An older unsubscribe must not remove a newer delivered opt-in")
	TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message/security_subscription(TRUE, disabled_generation)), "The stale subscribe case also travels through a real packet")
	packet = netrun_security_packet(monitor, publisher, "subscribe")
	publisher.subscribers.Cut()
	packet.deliver()
	TEST_ASSERT(!length(publisher.subscribers), "An old subscribe cannot recreate a subscription after its generation was superseded")
	TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation)), "A live owner can admit one final subscription")
	packet = netrun_security_packet(monitor, publisher, "subscribe")
	qdel(console)
	TEST_ASSERT(QDELETED(monitor) && QDELETED(packet), "Owner deletion must cancel its actual pending subscription packet")
	TEST_ASSERT(!length(publisher.subscribers), "A deleted owner cannot leave an admitted subscription behind")

/// At capacity, a duplicate authenticates only its sender; new peers still get
/// the bounded stale sweep required to replace deleted/retired subscribers.
/datum/unit_test/netrun_security_subscription_capacity/Run()
	var/datum/netrun_fortress_scene/scene = allocate(/datum/netrun_fortress_scene, run_loc_floor_bottom_left)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, get_turf(scene.node_b.parent))
	var/datum/netrun_machine_service/security_monitor/monitor = console.get_netrun_machine_service("security.monitor")
	var/datum/netrun_machine_service/security_events/subscription_probe/publisher = allocate(/datum/netrun_machine_service/security_events/subscription_probe, scene.node_a)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/deadline = world.time + 5 SECONDS
	while(!transport.is_ready() && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(transport.is_ready(), "Capacity admission requires the real route barrier")
	publisher.subscribers[monitor.service_key()] = WEAKREF(monitor)
	for(var/index in 1 to 31)
		var/obj/item/retired_host = allocate(/obj/item)
		var/datum/netrun_machine_service/security_monitor/retired = allocate(/datum/netrun_machine_service/security_monitor, scene.node_a, retired_host)
		publisher.subscribers[retired.service_key()] = WEAKREF(retired)
		if(index <= 16)
			qdel(retired)
	TEST_ASSERT(monitor.send_to(publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation)), "An existing native monitor may repeat its desired subscription")
	var/datum/netrun_machine_packet/data/packet = netrun_security_packet(monitor, publisher, "subscribe")
	packet.deliver()
	TEST_ASSERT_EQUAL(publisher.prune_calls, 0, "A duplicate at capacity must not reauthorize the whole subscriber set")
	TEST_ASSERT_EQUAL(length(publisher.subscribers), 32, "A duplicate touches only its already-admitted subscription")
	var/obj/machinery/computer/security/replacement_host = scene.machine(/obj/machinery/computer/security, get_turf(scene.node_b.parent))
	var/datum/netrun_machine_service/security_monitor/replacement = replacement_host.get_netrun_machine_service("security.monitor")
	TEST_ASSERT(replacement.send_to(publisher, new /datum/netrun_machine_message/security_subscription(TRUE, replacement.subscription_generation)), "A new native monitor may request a place at a full publisher")
	packet = netrun_security_packet(replacement, publisher, "subscribe")
	packet.deliver()
	TEST_ASSERT_EQUAL(publisher.prune_calls, 1, "Only a new peer at capacity requires one bounded stale sweep")
	TEST_ASSERT_EQUAL(length(publisher.subscribers), 2, "Deleted and unauthorized entries must free room for the replacement")
	TEST_ASSERT(publisher.subscribers[monitor.service_key()] && publisher.subscribers[replacement.service_key()], "Pruning must retain the existing authorized monitor and the new replacement")
