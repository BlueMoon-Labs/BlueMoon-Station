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
	scene.import_star()
	TEST_ASSERT(console.can_route(scene.node_b), "A fresh imported publication restores the route after reconnection")
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
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, scene.target_spot)
	var/datum/netrun_machine_service/security_events/publisher = scene.apc.get_netrun_machine_service("security.events")
	var/datum/netrun_machine_service/security_monitor/monitor = console.get_netrun_machine_service("security.monitor")
	var/datum/component/netrun_node/apc_node = scene.apc.GetComponent(/datum/component/netrun_node)
	publisher.subscribers.Cut()
	monitor.alerts.Cut()
	var/datum/netrun_external_request_context/context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation))
	TEST_ASSERT_NOTNULL(context, "The physical monitor owns an external subscription request")
	TEST_ASSERT(!length(publisher.subscribers), "Admission cannot subscribe before native invocation")
	TEST_ASSERT(fixture.deliver_context(context), "A current invocation subscribes the native monitor")
	var/datum/netrun_incident/incident = SSnetrun.report_incident("intrusion", apc_node, null, NETRUN_INCIDENT_MEDIUM, "Station security fixture")
	TEST_ASSERT(!length(publisher.pending_events), "An isolated medium incident cannot flood physical security")
	SSnetrun.report_incident("intrusion", apc_node, null, NETRUN_INCIDENT_MEDIUM, "Repeated station security fixture")
	var/list/event = publisher.pending_events[incident.id]
	TEST_ASSERT(event, "Repeated medium incidents produce a native public event")
	TEST_ASSERT_EQUAL(length(monitor.alerts), 0, "An incident hook cannot bypass delivery")
	context = fixture.admit_pair(publisher, monitor, new /datum/netrun_machine_message(list("operation" = "event", "event" = event)))
	TEST_ASSERT(fixture.deliver_context(context), "The supplied Core invocation reaches the actual security monitor")
	var/list/received = monitor.alerts[1]
	TEST_ASSERT_EQUAL(received["id"], incident.id, "The journal keeps the authoritative incident identity")
	TEST_ASSERT_EQUAL(received["reports"], 2, "The public event retains repeat count")
	TEST_ASSERT_NULL(received["suspect"], "A public station event does not disclose actor identity")
	TEST_ASSERT(received["area"], "A physical crew receives the area-level clue")
	SSnetrun.report_incident("intrusion", apc_node, null, NETRUN_INCIDENT_MEDIUM, "Third station security fixture")
	event = publisher.pending_events[incident.id]
	context = fixture.admit_pair(publisher, monitor, new /datum/netrun_machine_message(list("operation" = "event", "event" = event)))
	TEST_ASSERT(fixture.deliver_context(context), "A later event update crosses the same boundary")
	TEST_ASSERT_EQUAL(length(monitor.alerts), 1, "An incident update replaces its existing row")
	received = monitor.alerts[1]
	TEST_ASSERT_EQUAL(received["reports"], 3, "The existing row receives the newest reports")
	context = fixture.admit_pair(publisher, monitor, new /datum/netrun_machine_message(list("operation" = "event", "event" = event)))
	console.set_machine_stat(NOPOWER)
	TEST_ASSERT(!fixture.deliver_context(context), "Native power loss after admission revokes the effect")
	TEST_ASSERT_EQUAL(length(monitor.alerts), 1, "A revoked effect cannot alter the delivered journal")
	publisher.prune_subscribers()
	TEST_ASSERT(!length(publisher.subscribers), "An unpowered monitor loses its native subscription")
	console.set_machine_stat(0)
	context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation))
	TEST_ASSERT(fixture.deliver_context(context), "Recovery requires a fresh successfully delivered subscription")
	TEST_ASSERT(publisher.subscribers[monitor.service_key()], "The recovered native owner has its own subscription")

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
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_ready_fixture/ready = allocate(/datum/netrun_ready_fixture)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/datum/netrun_machine_service/security_events/subscription_probe/startup = allocate(/datum/netrun_machine_service/security_events/subscription_probe, scene.source.node)
	transport.bootstrap_complete = FALSE
	startup.network_ready()
	var/datum/weakref/parked = transport.pending_ready_services[startup.service_key()]
	var/was_parked = parked?.resolve() == startup
	var/early_calls = startup.advertisements
	transport.bootstrap_complete = TRUE
	var/datum/netrun_task/service_initialize/task = allocate(/datum/netrun_task/service_initialize, "service_initialize", "fixture-ready", NETRUN_TASK_BACKGROUND, startup)
	task.advance(SSnetrun)
	var/ready_calls = startup.advertisements
	startup.network_ready()
	var/recovery_calls = startup.advertisements
	qdel(ready)
	TEST_ASSERT(was_parked && !early_calls, "A closed native barrier parks a direct reconnect without advertising")
	TEST_ASSERT_EQUAL(ready_calls, 1, "An explicit native worker callback advertises once after Core becomes ready")
	TEST_ASSERT_EQUAL(recovery_calls, 2, "A later recovery can announce a fresh readiness generation")

/// Only a successful current delivery can suppress duplicate advertisement replies.
/// Publisher recovery/replacement and ACK eviction remain safe idempotent retries.
/datum/unit_test/netrun_security_subscription_acknowledgements/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, scene.target_spot)
	var/datum/netrun_machine_service/security_monitor/monitor = console.get_netrun_machine_service("security.monitor")
	var/datum/netrun_machine_service/security_events/subscription_probe/publisher = allocate(/datum/netrun_machine_service/security_events/subscription_probe, scene.source.node)
	publisher.subscribers.Cut()
	monitor.acknowledged_publishers.Cut()
	var/datum/netrun_external_request_context/context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation))
	TEST_ASSERT(!length(monitor.acknowledged_publishers), "Local admission cannot acknowledge an unexecuted subscription")
	var/list/invocation = fixture.invocation(context)
	fixture.executor.process_result(fixture.client, invocation)
	fixture.pump_native(invocation["invocation_id"])
	TEST_ASSERT(publisher.subscribers[monitor.service_key()], "Native receive establishes the actual subscription")
	TEST_ASSERT(!length(monitor.acknowledged_publishers), "Receive does not substitute for the Core terminal event")
	fixture.executor.process_result(fixture.client, fixture.completion(context.request_id))
	TEST_ASSERT(monitor.subscription_acknowledged(publisher, publisher.advertisement_generation), "Only a successful terminal acknowledges this publisher instance")
	context = fixture.admit_pair(publisher, monitor, new /datum/netrun_machine_message/security_advertisement(publisher.advertisement_generation))
	TEST_ASSERT(fixture.deliver_context(context), "An acknowledged delayed advertisement is harmless")
	TEST_ASSERT_EQUAL(length(fixture.executor.pending), 0, "The duplicate advertisement needs no extra native subscription")
	console.set_machine_stat(NOPOWER)
	publisher.prune_subscribers()
	TEST_ASSERT(!monitor.subscription_acknowledged(publisher, publisher.advertisement_generation), "Pruning retires the advisory acknowledgement")
	console.set_machine_stat(0)
	var/previous_generation = publisher.advertisement_generation
	var/datum/netrun_ready_fixture/ready = allocate(/datum/netrun_ready_fixture)
	publisher.network_ready()
	qdel(ready)
	TEST_ASSERT(publisher.advertisement_generation > previous_generation, "Recovery announces a new native generation")
	context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation))
	TEST_ASSERT(fixture.deliver_context(context), "Recovery requires a fresh terminal acknowledgement")
	var/key = publisher.service_key()
	qdel(publisher)
	publisher = allocate(/datum/netrun_machine_service/security_events/subscription_probe, scene.source.node)
	TEST_ASSERT_EQUAL(publisher.service_key(), key, "The replacement deliberately reuses the same native host key")
	TEST_ASSERT(!monitor.subscription_acknowledged(publisher, publisher.advertisement_generation), "A weak acknowledgement never transfers to another instance")
	monitor.acknowledged_publishers.Cut()
	for(var/index in 1 to 512)
		monitor.acknowledged_publishers["retired-[index]"] = list("publisher" = WEAKREF(publisher), "generation" = monitor.subscription_generation, "advertisement_generation" = publisher.advertisement_generation)
	context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation))
	TEST_ASSERT(fixture.deliver_context(context), "A replacement publisher receives its own subscription")
	TEST_ASSERT_EQUAL(length(monitor.acknowledged_publishers), 512, "Terminal acknowledgement hints remain bounded")
	TEST_ASSERT_NULL(monitor.acknowledged_publishers["retired-1"], "A new acknowledged peer evicts the oldest hint")
	TEST_ASSERT(monitor.subscription_acknowledged(publisher, publisher.advertisement_generation), "The newest successful instance remains acknowledged")

/// Subscription controls describe desired state: coalescing and delivery-time
/// generations must preserve the latest toggle without bypassing real packets.
/datum/unit_test/netrun_security_subscription_control_coalescing/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, scene.target_spot)
	var/datum/netrun_machine_service/security_monitor/monitor = console.get_netrun_machine_service("security.monitor")
	var/datum/netrun_machine_service/security_events/publisher = scene.apc.get_netrun_machine_service("security.events")
	publisher.subscribers.Cut()
	monitor.subscription_generation = 3
	var/datum/netrun_machine_message/security_subscription/current = new(TRUE, 3)
	var/datum/netrun_machine_message/security_subscription/stale = new(FALSE, 2)
	TEST_ASSERT_EQUAL(current.coalescing_key(), stale.coalescing_key(), "Native desired-state controls declare the same replacement slot")
	TEST_ASSERT(!stale.can_replace(current) && current.can_replace(stale), "A stale native generation cannot displace a newer desired state")
	TEST_ASSERT_EQUAL(current.delivery_priority(), NETRUN_TASK_NORMAL, "Subscription controls retain their native producer priority")
	var/datum/netrun_machine_resolution/query = allocate(/datum/netrun_machine_resolution, monitor, "security.events", null)
	TEST_ASSERT(query.enqueue(current) && query.enqueue(stale), "Native pre-discovery ownership accepts duplicate desired state")
	var/datum/netrun_machine_message/queued = query.queued[1]
	TEST_ASSERT_EQUAL(length(query.queued), 1, "The native unsent burst retains one owned desired state")
	TEST_ASSERT_EQUAL(queued.payload["generation"], 3, "The retained burst owns the latest generation")
	qdel(query)
	var/datum/netrun_external_request_context/context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, 3))
	TEST_ASSERT(fixture.deliver_context(context), "The current desired state establishes the native subscription")
	context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(FALSE, 2))
	TEST_ASSERT(!fixture.deliver_context(context), "A stale opt-out is rechecked during native receive")
	TEST_ASSERT(publisher.subscribers[monitor.service_key()], "Rejected stale control cannot remove newer delivered state")
	publisher.subscribers.Cut()
	context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, 2))
	TEST_ASSERT(!fixture.deliver_context(context), "A stale opt-in cannot restore a superseded subscription")
	TEST_ASSERT(!length(publisher.subscribers), "Rejected stale opt-in has no native side effect")
	context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, 3))
	qdel(console)
	TEST_ASSERT(!fixture.deliver_context(context), "A deleted owner cannot execute an admitted subscription")
	TEST_ASSERT(!length(publisher.subscribers), "No subscription is recreated for the deleted owner")

/// At capacity, a duplicate authenticates only its sender; new peers still get
/// the bounded stale sweep required to replace deleted/retired subscribers.
/datum/unit_test/netrun_security_subscription_capacity/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_external_fixture/fixture = allocate(/datum/netrun_external_fixture, scene)
	var/obj/machinery/computer/security/console = scene.machine(/obj/machinery/computer/security, scene.target_spot)
	var/datum/netrun_machine_service/security_monitor/monitor = console.get_netrun_machine_service("security.monitor")
	var/datum/netrun_machine_service/security_events/subscription_probe/publisher = allocate(/datum/netrun_machine_service/security_events/subscription_probe, scene.source.node)
	publisher.subscribers[monitor.service_key()] = WEAKREF(monitor)
	for(var/index in 1 to 31)
		var/obj/item/retired_host = allocate(/obj/item)
		var/datum/netrun_machine_service/security_monitor/retired = allocate(/datum/netrun_machine_service/security_monitor, scene.source.node, retired_host)
		publisher.subscribers[retired.service_key()] = WEAKREF(retired)
		if(index <= 16)
			qdel(retired)
	var/datum/netrun_external_request_context/context = fixture.admit_pair(monitor, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, monitor.subscription_generation))
	TEST_ASSERT(fixture.deliver_context(context), "A duplicate current peer crosses the same external invocation boundary")
	TEST_ASSERT_EQUAL(publisher.prune_calls, 0, "A duplicate at capacity does not authorize every peer again")
	TEST_ASSERT_EQUAL(length(publisher.subscribers), 32, "A duplicate touches its already owned subscriber slot")
	var/obj/machinery/computer/security/replacement_host = scene.machine(/obj/machinery/computer/security, scene.target_spot)
	var/datum/netrun_machine_service/security_monitor/replacement = replacement_host.get_netrun_machine_service("security.monitor")
	context = fixture.admit_pair(replacement, publisher, new /datum/netrun_machine_message/security_subscription(TRUE, replacement.subscription_generation))
	TEST_ASSERT(fixture.deliver_context(context), "A new current peer can request capacity through native receive")
	TEST_ASSERT_EQUAL(publisher.prune_calls, 1, "Only a new peer at capacity triggers one bounded stale sweep")
	TEST_ASSERT_EQUAL(length(publisher.subscribers), 2, "Deleted and unauthorized peers release their capacity")
	TEST_ASSERT(publisher.subscribers[monitor.service_key()] && publisher.subscribers[replacement.service_key()], "The actual authorized peers retain their native subscriptions")
