/// Delivery fixtures keep their observations outside the packet's owned lifetime.
/datum/netrun_request/delivery/netrun_queue_probe
	var/list/observations = list()
	var/pause = 0

/datum/netrun_request/delivery/netrun_queue_probe/execute()
	observations += "start"
	if(pause)
		sleep(pause)
	observations += cancelled ? "cancelled" : "finish"
	return !cancelled

/// Ready I/O wakes the existing worker; quiet maintenance keeps its ordinary cadence.
/datum/unit_test/netrun_delivery_worker_wake/Run()
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	var/datum/target = allocate(/datum)
	scheduler.enqueue("service_discovery", target, NETRUN_TASK_BACKGROUND)
	scheduler.enqueue("service_discovery", target, NETRUN_TASK_CRITICAL)
	TEST_ASSERT_EQUAL(scheduler.ready_deliveries, 1, "Promotion/coalescing must retain one ready delivery")
	worker.next_fire = world.time + 10 SECONDS
	worker.wake_ready_delivery()
	TEST_ASSERT_EQUAL(worker.next_fire, world.time, "Already ready I/O must not pay another tick before MC admission")
	TEST_ASSERT_EQUAL(worker.wait, world.tick_lag, "A ready backlog must be served at tick cadence")
	var/datum/netrun_task/task = scheduler.take()
	qdel(task)
	TEST_ASSERT_EQUAL(scheduler.ready_deliveries, 0, "Taking a delivery must release the ready-work count")
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, NETRUN_DEFAULT_FIRE_INTERVAL, "A drained worker must return to its quiet cadence")
	scheduler.enqueue("request_delivery", target, NETRUN_TASK_CRITICAL, TRUE)
	scheduler.cancel("request_delivery", target)
	TEST_ASSERT_EQUAL(scheduler.ready_deliveries, 0, "Cancelled interactive packets must not keep the worker hot")
	scheduler.enqueue("probe", target)
	worker.refresh_delivery_interval()
	TEST_ASSERT_EQUAL(worker.wait, world.tick_lag, "Every admitted backlog needs bounded fast follow-up until drained")

/// Admitted input must obey the same finite pass budget as other runnable work.
/datum/unit_test/netrun_delivery_request_budget/Run()
	var/obj/item/host = allocate(/obj/item, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	worker.task_adaptive_budget = FALSE
	worker.task_budget_ms = NETRUN_EXECUTION_MAX_BUDGET_MS
	worker.task_max_per_pass = 3
	worker.task_min_per_pass = 3
	var/list/samples = list()
	for(var/i in 1 to 7)
		var/datum/netrun_request/delivery/netrun_queue_probe/packet = allocate(/datum/netrun_request/delivery/netrun_queue_probe, console, node, node.network)
		samples += list(packet.observations)
		TEST_ASSERT(packet.send(), "A ready request must be admitted without executing synchronously")
		TEST_ASSERT_EQUAL(length(packet.observations), 0, "send() must return before native handling")
		var/datum/netrun_task/task = SSnetrun.get_task_scheduler().by_key["request_delivery:[REF(packet)]"]
		TEST_ASSERT(istype(task, /datum/netrun_task/request_delivery) && task.interactive, "Explicit input must use its registered interactive delivery task")
		SSnetrun.task_scheduler.cancel("request_delivery", packet)
		worker.get_task_scheduler().enqueue("request_delivery", packet, NETRUN_TASK_CRITICAL, TRUE)
	worker.run_pass()
	var/started = 0
	for(var/list/sample as anything in samples)
		started += !!length(sample)
	TEST_ASSERT_EQUAL(started, 3, "A burst of input may execute only the configured number of packets per pass")
	TEST_ASSERT_EQUAL(worker.get_task_scheduler().pending(), 4, "Undispatched packets must remain owned and runnable")
	worker.run_pass()
	worker.run_pass()
	for(var/list/sample as anything in samples)
		TEST_ASSERT_EQUAL(length(sample), 2, "Every admitted request must execute exactly once across later passes")

/// A yielding callback cannot suspend the worker, and dependency cancellation must settle once.
/datum/unit_test/netrun_delivery_yield_and_cancel/Run()
	var/obj/item/host = allocate(/obj/item, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_request/delivery/netrun_queue_probe/slow = allocate(/datum/netrun_request/delivery/netrun_queue_probe, console, node, node.network)
	var/datum/netrun_request/delivery/netrun_queue_probe/fast = allocate(/datum/netrun_request/delivery/netrun_queue_probe, console, node, node.network)
	slow.pause = 0.3 SECONDS
	var/list/slow_samples = slow.observations
	var/list/fast_samples = fast.observations
	var/slow_id = slow.operation.id
	slow.send()
	fast.send()
	var/datum/netrun_task/slow_task = new /datum/netrun_task/request_delivery("request_delivery", "slow", NETRUN_TASK_CRITICAL, slow)
	var/datum/netrun_task/fast_task = new /datum/netrun_task/request_delivery("request_delivery", "fast", NETRUN_TASK_CRITICAL, fast)
	var/started_at = world.time
	slow_task.execute(SSnetrun)
	fast_task.execute(SSnetrun)
	qdel(slow_task)
	qdel(fast_task)
	TEST_ASSERT_EQUAL(world.time, started_at, "The delivery task must not sleep with a native callback")
	TEST_ASSERT_EQUAL(length(slow_samples), 1, "The yielding callback must still be in progress")
	TEST_ASSERT_EQUAL(length(fast_samples), 2, "Another ready packet must complete while the first callback waits")
	TEST_ASSERT(slow in SSnetrun.pending_requests, "Executing callbacks must retain their owned packet")
	qdel(node)
	TEST_ASSERT(!QDELETED(slow) && slow.cancelled, "Dependency deletion must mark an executing callback instead of destroying its stack")
	sleep(0.5 SECONDS)
	TEST_ASSERT(QDELETED(slow), "A resumed cancelled callback must release its packet")
	TEST_ASSERT_EQUAL(slow_samples[2], "cancelled", "The resumed callback must observe its cancellation")
	var/list/result = netrun_operation_result(console, slow_id)
	TEST_ASSERT_EQUAL(result?["phase"], "cancelled", "Cancellation during a native wait must have a terminal result")

/datum/unit_test/netrun_delivery_cancel_before_dispatch/Run()
	var/obj/item/host = allocate(/obj/item, run_loc_floor_bottom_left)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	console.origin = NETRUN_ORIGIN_CIRCUIT
	var/datum/netrun_request/delivery/netrun_queue_probe/packet = allocate(/datum/netrun_request/delivery/netrun_queue_probe, console, node, node.network)
	var/list/samples = packet.observations
	packet.send()
	var/key = "request_delivery:[REF(packet)]"
	var/datum/netrun_task/task = SSnetrun.get_task_scheduler().by_key[key]
	TEST_ASSERT(task && !task.interactive && task.priority == NETRUN_TASK_NORMAL, "Autonomous circuits must not impersonate interactive input")
	qdel(node)
	TEST_ASSERT(QDELETED(packet), "An undispatched request must be cancelled with its endpoint")
	TEST_ASSERT_NULL(SSnetrun.task_scheduler.by_key[key], "Cancellation must remove the ready scheduler entry")
	TEST_ASSERT_EQUAL(length(samples), 0, "A cancelled packet must never execute")

/// Removing the real physical deck must cancel both kinds of pending work, even
/// when the remote destination remains alive and the delivery deadline is far away.
/datum/unit_test/netrun_delivery_deleted_deck_releases_work/Run()
	var/obj/item/netrun_deck/deck = allocate(/obj/item/netrun_deck, run_loc_floor_bottom_left)
	var/datum/netrun_console/console = deck.console
	var/obj/item/target = allocate(/obj/item, get_step(run_loc_floor_bottom_left, EAST))
	var/datum/component/netrun_node/node = target.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_request/delivery/netrun_queue_probe/queued = allocate(/datum/netrun_request/delivery/netrun_queue_probe, console, node, node.network)
	var/datum/netrun_request/delivery/netrun_queue_probe/delayed = allocate(/datum/netrun_request/delivery/netrun_queue_probe, console, node, node.network)
	var/list/queued_samples = queued.observations
	var/list/delayed_samples = delayed.observations
	queued.send()
	delayed.send(30 SECONDS)
	var/queued_key = "request_delivery:[REF(queued)]"
	var/console_key = "console:[REF(console)]"
	TEST_ASSERT_NOTNULL(SSnetrun.task_scheduler.by_key[queued_key], "The ready packet must start in the scheduler")
	TEST_ASSERT_NOTNULL(delayed.timer_id, "The delayed packet must own a real pending timer")
	qdel(deck)
	TEST_ASSERT(QDELETED(console) && QDELETED(queued) && QDELETED(delayed), "Deck destruction must synchronously dispose its console and pending packets")
	TEST_ASSERT_NULL(SSnetrun.task_scheduler.by_key[queued_key], "No ready packet may survive its originating deck")
	TEST_ASSERT_NULL(SSnetrun.task_scheduler.by_key[console_key], "No console processing task may survive its originating deck")
	TEST_ASSERT_NULL(delayed.timer_id, "Deleting a deck must release its packet's delayed callback immediately")
	TEST_ASSERT(!(console in SSnetrun.consoles) && !(console in SSnetrun.active_consoles), "Deleted decks must leave both console registries")
	TEST_ASSERT(!(queued in SSnetrun.pending_requests) && !(delayed in SSnetrun.pending_requests), "Neither pending packet may retain a deleted console")
	TEST_ASSERT_EQUAL(length(queued_samples) + length(delayed_samples), 0, "No cancelled deck process may execute against the surviving remote endpoint")


/// Supply wire service identities without running a second discovery or routing implementation.
/datum/unit_test/proc/netrun_supply_discovery(datum/netrun_transport_scene/scene, datum/netrun_machine_resolution/external/query, list/services)
	query.deliver()
	var/list/keys = list()
	for(var/datum/netrun_machine_service/service as anything in services)
		keys += list(scene.bus.wire_key(scene.bus.client.service_key(service), "service_id"))
	return scene.bus.supply_discovery(query, keys)

/// Завершённый discovery не остаётся в service registry, worker или IPC dispatcher.
/datum/unit_test/netrun_delivery_discovery_retired_references/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), list()))
	var/datum/netrun_machine_resolution/external/query = scene.source.resolutions["transport.fixture|"]
	TEST_ASSERT(netrun_supply_discovery(scene, query, list(scene.target)), "Supplied discovery reaches the real decoder")
	query.deliver()
	TEST_ASSERT(QDELETED(query), "Unicast discovery must retire after transferring its message")
	// waitfor=FALSE delivery stacks release their local src on the next tick.
	sleep(world.tick_lag)
	if(refcount(query) > 1)
		query.find_references(refcount(query) - 1, skip_alert = TRUE)
	TEST_ASSERT_EQUAL(refcount(query), 1, "Only this test's local may retain the retired native lookup")

/// Завершение внутри begin воспроизводит lookup, который короче остальной wake-волны.
/datum/netrun_machine_resolution/netrun_wake_gc_probe
	var/datum/netrun_machine_transport/owner_transport

/datum/netrun_machine_resolution/netrun_wake_gc_probe/begin()
	owner_transport.waiting_resolutions -= src
	qdel(src)

/datum/netrun_machine_resolution/netrun_wake_gc_probe/Destroy()
	if(owner_transport)
		owner_transport.waiting_resolutions -= src
	owner_transport = null
	return ..()

/datum/unit_test/netrun_delivery_wake_retired_references/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = allocate(/datum/netrun_machine_transport)
	transport.bootstrap_complete = TRUE
	var/list/probes = list()
	for(var/index in 1 to 9)
		var/datum/netrun_machine_resolution/netrun_wake_gc_probe/query = new(scene.source, "transport.fixture", "probe-[index]")
		query.owner_transport = transport
		probes += query
		transport.waiting_resolutions[query] = TRUE
	var/datum/netrun_machine_resolution/first = probes[1]
	TEST_ASSERT(!transport.advance_resolutions(), "Nine lookups must leave a bounded wake continuation")
	TEST_ASSERT(QDELETED(first), "The consumed lookup retires while another one is still pending")
	sleep(world.tick_lag)
	if(refcount(first) > 2)
		first.find_references(refcount(first) - 1, skip_alert = TRUE)
	TEST_ASSERT_EQUAL(refcount(first), 2, "Only the test local and its probe list may retain the consumed lookup")
	QDEL_LIST(probes)

/datum/netrun_machine_message/transport_fixture/queue_snapshot/coalescing_key()
	return "replaceable-status"

/datum/netrun_machine_service/transport_fixture
	var/tag_override
	var/target_limit = 0

/datum/netrun_machine_service/transport_fixture/service_tag()
	return tag_override || ..()

/datum/netrun_machine_service/transport_fixture/select_targets(destination_id, list/targets)
	return target_limit ? targets.Copy(1, min(length(targets), target_limit) + 1) : targets

/// Native domain selection filters supplied identities and chooses one authorized peer.
/datum/unit_test/netrun_delivery_discovery_target_limit/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/list/peers = list(scene.target)
	for(var/index in 1 to 12)
		var/obj/machinery/netrun_server/transport_fixture/host = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.target_spot)
		peers += host.get_netrun_machine_service("transport.fixture")
	scene.receiver.set_machine_stat(BROKEN)
	scene.source.target_limit = 1
	var/list/outcomes = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes))
	var/datum/netrun_machine_resolution/external/query = scene.source.resolutions["transport.fixture|"]
	netrun_supply_discovery(scene, query, peers)
	for(var/pass in 1 to 32)
		if(QDELETED(query))
			break
		query.deliver()
	TEST_ASSERT(QDELETED(query), "Native selection finishes after supplied discovery pages")
	TEST_ASSERT_EQUAL(length(scene.pending_contexts(scene.source)), 1, "Native policy selects one eligible supplied recipient")
	var/datum/netrun_external_request_context/context = scene.pending_contexts(scene.source)[1]
	TEST_ASSERT_EQUAL(context.destination_ref.resolve(), peers[2], "Offline native recipient is excluded before domain selection")
	TEST_ASSERT(scene.deliver_context(context), "Selected recipient executes through the real native dispatcher")
	TEST_ASSERT_EQUAL(outcomes["delivered"], 1, "One unicast has one terminal success")

/// A later map load closes the same barrier as startup. Neither readiness task
/// may busy-wait; reopening must deliver the parked callback exactly once.
/datum/unit_test/netrun_delivery_readiness_parking/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	SSatoms.map_loader_begin()
	var/datum/netrun_machine_service/readiness_fixture/service = allocate(/datum/netrun_machine_service/readiness_fixture, scene.source.node)
	var/key = service.service_key()
	var/datum/weakref/reference = transport.pending_ready_services[key]
	var/parked = reference?.resolve() == service
	var/datum/netrun_task/service_initialize/initialize = allocate(/datum/netrun_task/service_initialize, "service_initialize", "parked-initialize", NETRUN_TASK_BACKGROUND, service)
	var/initialize_finished = initialize.advance(SSnetrun)
	var/datum/netrun_task/service_ready/ready = allocate(/datum/netrun_task/service_ready, "service_ready", "parked-ready", NETRUN_TASK_BACKGROUND, transport)
	var/ready_finished = ready.advance(SSnetrun)
	var/bootstrap_finished = transport.advance_bootstrap(SSnetrun.get_execution_limits())
	var/calls_while_closed = service.ready_calls
	var/queued_while_closed = !!SSnetrun.task_scheduler.by_key["service_initialize:[REF(service)]"]
	SSatoms.map_loader_stop()
	transport.prepare_network()
	TEST_ASSERT(parked && initialize_finished && ready_finished && bootstrap_finished, "A closed barrier must retain readiness demand without runnable continuations")
	TEST_ASSERT(!queued_while_closed && !calls_while_closed, "No service callback or per-service polling task may run before readiness")
	var/deadline = world.time + 5 SECONDS
	while(!service.ready_calls && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(service.ready_calls, 1, "Reopening the barrier must resume the parked service exactly once")
	TEST_ASSERT_NULL(transport.pending_ready_services[key], "A completed readiness wave must release its pending entry")
	qdel(service)
	TEST_ASSERT_NULL(transport.pending_ready_services[key], "Deleted services must never survive in the pending readiness index")

/// A delayed task from a replaced service cannot overwrite its successor's
/// readiness demand or remove the successor's registry entries during teardown.
/datum/unit_test/netrun_delivery_readiness_replacement/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	SSatoms.map_loader_begin()
	var/datum/netrun_machine_service/readiness_fixture/retired = allocate(/datum/netrun_machine_service/readiness_fixture, scene.source.node)
	var/datum/netrun_machine_service/readiness_fixture/replacement = allocate(/datum/netrun_machine_service/readiness_fixture, scene.source.node)
	var/key = replacement.service_key()
	transport.defer_ready_service(retired)
	var/datum/netrun_task/service_initialize/initialize = allocate(/datum/netrun_task/service_initialize, "service_initialize", "retired-initialize", NETRUN_TASK_BACKGROUND, retired)
	var/finished_closed = initialize.advance(SSnetrun)
	var/datum/weakref/reference = transport.pending_ready_services[key]
	var/retained_replacement = reference?.resolve() == replacement
	SSatoms.map_loader_stop()
	var/finished_open = initialize.advance(SSnetrun)
	var/retired_calls = retired.ready_calls
	qdel(retired)
	reference = transport.pending_ready_services[key]
	var/registered_replacement = transport.services[key] == replacement && transport.ready_services[key] == replacement && reference?.resolve() == replacement
	transport.prepare_network()
	TEST_ASSERT(finished_closed && finished_open && !retired_calls, "Retired readiness tasks must finish without executing or replacing pending startup")
	TEST_ASSERT(retained_replacement && registered_replacement, "Old-service deferral and deletion must preserve all replacement registry entries")
	TEST_ASSERT(!(retired in transport.by_id["transport.readiness"]), "Old-service teardown must still release its own discovery bucket membership")
	var/deadline = world.time + 5 SECONDS
	while(!replacement.ready_calls && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(replacement.ready_calls, 1, "The surviving replacement must receive its parked readiness callback exactly once")
	qdel(replacement)
	TEST_ASSERT_NULL(transport.services[key], "Final teardown must release the actual current registry owner")
	TEST_ASSERT_NULL(transport.ready_services[key], "Final teardown must release the actual current readiness owner")
	TEST_ASSERT_NULL(transport.pending_ready_services[key], "Final teardown must release the actual current pending owner")

/// Exhausted shared CPU still permits one atomic dispatch to make progress,
/// but cannot turn a warm multi-recipient result into an unbounded fanout.
/datum/unit_test/netrun_delivery_discovery_exhausted_budget/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/list/peers = list(scene.target)
	for(var/index in 1 to 9)
		var/obj/machinery/netrun_server/transport_fixture/host = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.target_spot)
		peers += host.get_netrun_machine_service("transport.fixture")
	var/datum/netrun_machine_resolution/external/query = allocate(/datum/netrun_machine_resolution/external, scene.source, "transport.fixture", null)
	query.enqueue(new /datum/netrun_machine_message/transport_fixture(list(), list()))
	query.completed = TRUE
	query.external_phase = "dispatch"
	query.resolved_targets = peers
	var/saved_budget = SSnetrun.task_slice_budget_ms
	var/saved_start = SSnetrun.task_slice_start_usage
	var/saved_time = SSnetrun.task_slice_started_at
	SSnetrun.task_slice_budget_ms = 0
	SSnetrun.task_slice_start_usage = TICK_USAGE
	SSnetrun.task_slice_started_at = world.time
	query.deliver()
	var/admitted = length(scene.pending_contexts(scene.source))
	var/remains_queued = !QDELETED(query) && query.delivery_queued
	SSnetrun.task_slice_budget_ms = saved_budget
	SSnetrun.task_slice_start_usage = saved_start
	SSnetrun.task_slice_started_at = saved_time
	TEST_ASSERT_EQUAL(admitted, 1, "An exhausted native slice admits one indivisible request")
	TEST_ASSERT(remains_queued, "Remaining fanout retains a continuation")

/// Command bursts share one lookup and yield admission before consuming the batch.
/datum/unit_test/netrun_delivery_discovery_burst_slices/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/list/outcomes = list()
	for(var/i in 1 to 17)
		TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = i), outcomes), scene.target.service_tag()), "Finite command burst is admitted")
	var/datum/netrun_machine_resolution/external/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	netrun_supply_discovery(scene, query, list(scene.target))
	query.deliver()
	TEST_ASSERT(!QDELETED(query) && length(query.queued), "One native slice retains the unfinished burst")
	TEST_ASSERT(length(scene.pending_contexts(scene.source)) <= 8, "One native slice admits at most eight contexts")
	scene.bus.auto_pump = TRUE
	var/deadline = world.time + 5 SECONDS
	while(outcomes["delivered"] != 17 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(outcomes["delivered"], 17, "Every command executes once across continuations")
	TEST_ASSERT(!outcomes["failed"] && QDELETED(query), "Successful burst releases its owned lookup")

/// Both enumeration and fanout yield; deleting a registry member cannot skip its neighbor.
/datum/unit_test/netrun_delivery_discovery_registry_slices/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/list/peers = list(scene.target)
	for(var/i in 1 to 32)
		var/obj/machinery/netrun_server/transport_fixture/host = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.target_spot)
		peers += host.get_netrun_machine_service("transport.fixture")
	var/list/outcomes = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes))
	var/datum/netrun_machine_resolution/external/query = scene.source.resolutions["transport.fixture|"]
	netrun_supply_discovery(scene, query, peers)
	query.deliver()
	TEST_ASSERT(query.external_cursor <= 9, "Native filtering examines at most eight supplied identities per slice")
	TEST_ASSERT_EQUAL(length(scene.pending_contexts(scene.source)), 0, "Incomplete filtering cannot dispatch effects")
	var/paused_cursor = query.external_cursor
	SSatoms.map_loader_begin()
	query.deliver()
	var/paused = query.external_cursor == paused_cursor && (query in SSnetrun.get_machine_transport().waiting_resolutions) && !query.delivery_queued
	SSatoms.map_loader_stop()
	TEST_ASSERT(paused, "Map loading parks the same native continuation")
	query.begin()
	var/datum/netrun_machine_service/doomed = peers[query.external_cursor]
	qdel(doomed.host)
	for(var/pass in 1 to 128)
		if(QDELETED(query))
			break
		var/before = length(scene.pending_contexts(scene.source))
		query.deliver()
		TEST_ASSERT(length(scene.pending_contexts(scene.source)) - before <= 8, "Every native fanout slice stays bounded")
	TEST_ASSERT(QDELETED(query), "Finite filtering and fanout drain")
	scene.bus.auto_pump = TRUE
	var/deadline = world.time + 5 SECONDS
	while(outcomes["delivered"] != length(peers) - 1 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(outcomes["delivered"], length(peers) - 1, "Revoked identity does not skip its surviving neighbor")
	TEST_ASSERT(!outcomes["failed"], "Revoked unselected identity does not fail surviving branches")

/// A native tag change revokes an identity supplied by the remote directory.
/datum/unit_test/netrun_delivery_discovery_tag_revocation/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/list/outcomes = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), scene.target.service_tag())
	var/datum/netrun_machine_resolution/external/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	netrun_supply_discovery(scene, query, list(scene.target))
	scene.target.tag_override = "revoked-after-page"
	query.deliver()
	TEST_ASSERT_EQUAL(length(scene.pending_contexts(scene.source)), 0, "Native tag change revokes a supplied identity before dispatch")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Empty authorized selection fails the original command once")

/// Source deletion must cancel even a generation retired from the source's coalescing map.
/datum/unit_test/netrun_delivery_discovery_lookup_source_deleted/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/queued_before = transport.queued_messages
	var/list/outcomes = list()
	for(var/i in 1 to 2)
		scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes))
	var/datum/netrun_machine_resolution/external/query = scene.source.resolutions["transport.fixture|"]
	query.deliver()
	TEST_ASSERT_EQUAL(query.external_phase, "pending", "Source deletion happens while awaiting a remote page")
	qdel(scene.source)
	TEST_ASSERT(QDELETED(query), "Source teardown disposes the remote continuation")
	TEST_ASSERT_EQUAL(transport.queued_messages, queued_before, "Teardown releases queued native capacity")
	TEST_ASSERT_EQUAL(outcomes["failed"], 2, "Both original commands fail once")

/// Source teardown must cancel later slices as well as already admitted packets.
/datum/unit_test/netrun_delivery_discovery_burst_source_deleted/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/list/outcomes = list()
	for(var/i in 1 to 17)
		scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), scene.target.service_tag())
	var/datum/netrun_machine_resolution/external/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	netrun_supply_discovery(scene, query, list(scene.target))
	query.deliver()
	var/list/admitted = scene.pending_contexts(scene.source)
	qdel(scene.source)
	for(var/datum/netrun_external_request_context/context as anything in admitted)
		scene.deliver_context(context)
	TEST_ASSERT(QDELETED(query), "Source deletion cancels remaining native fanout")
	TEST_ASSERT_EQUAL(outcomes["failed"], 17, "Pending and admitted commands each settle once")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "Revoked source cannot execute admitted effects")

/// Telemetry is ordinary background work even when its native message identifies an actor.
/datum/unit_test/netrun_delivery_machine_lane_and_cleanup/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/list/outcomes = list()
	var/datum/netrun_machine_message/transport_fixture/queue_snapshot/message = new(list(), outcomes)
	var/mob/actor = allocate(/mob, scene.source_spot)
	message.user_ref = WEAKREF(actor)
	TEST_ASSERT_EQUAL(message.delivery_priority(), NETRUN_TASK_BACKGROUND, "Actor reference does not promote replaceable telemetry")
	TEST_ASSERT(scene.source.send_to(scene.target, message), "Telemetry is admitted into external transport")
	var/datum/netrun_external_request_context/context = scene.pending_contexts(scene.source, scene.target)[1]
	TEST_ASSERT_EQUAL(scene.target.received, 0, "Admission cannot execute native receive inline")
	scene.bus.executor.process_result(scene.bus.client, scene.bus.completion(context.request_id, "cancelled", "cancelled"))
	TEST_ASSERT_EQUAL(length(scene.pending_contexts(scene.source)), 0, "Remote cancellation releases native context capacity")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Cancellation calls the native failure exactly once")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "Cancelled telemetry has no effect")

/// Admission backpressure must explain capacity separately from a missing route.
/datum/unit_test/netrun_delivery_capacity_reasons/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, scene.sender)
	var/datum/netrun_request/delivery/netrun_queue_probe/request = allocate(/datum/netrun_request/delivery/netrun_queue_probe, console, scene.source.node, scene.source.node.network)
	var/id = request.operation.id
	var/list/previous_requests = SSnetrun.pending_requests
	SSnetrun.pending_requests = new /list(NETRUN_MAX_PENDING_REQUESTS)
	var/admitted = request.send()
	SSnetrun.pending_requests = previous_requests
	TEST_ASSERT(!admitted && QDELETED(request), "A full request queue must refuse admission and release the rejected packet")
	var/list/result = netrun_operation_result(console, id)
	TEST_ASSERT_EQUAL(result?["phase"], "rejected", "Capacity refusal must be a final rejected outcome")
	TEST_ASSERT(findtext(result["reason"], "переполнена"), "Request capacity must have an actionable reason")
	var/list/outcomes = list()
	var/saved_limit = scene.bus.executor.context_limit
	scene.bus.executor.context_limit = 0
	admitted = scene.source.send_to(scene.target, new /datum/netrun_machine_message/transport_fixture(list(), outcomes))
	scene.bus.executor.context_limit = saved_limit
	TEST_ASSERT(!admitted, "Full external context capacity refuses admission")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Capacity refusal has one native callback")
	TEST_ASSERT(findtext(outcomes["reason"], "переполнена"), "Capacity reason remains actionable")

/// Every addressed send must wait for the same budgeted service-discovery task.
/datum/unit_test/netrun_delivery_discovery_admission/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "queued", "reply" = TRUE), outcomes), scene.target.service_tag()), "Addressed discovery must admit the original command")
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	TEST_ASSERT(!QDELETED(query), "The original command must own one pending service lookup")
	TEST_ASSERT(SSnetrun.get_task_scheduler().by_key["service_discovery:[REF(query)]"], "Service lookup must use the existing worker queue")
	TEST_ASSERT_EQUAL(scene.pending_packets(), 0, "Admission must not allocate routed data packets outside the worker")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "Admission must not call the recipient inline")
	TEST_ASSERT(netrun_wait_delivery(outcomes), "The worker must deliver the original queued command")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "Queued discovery must execute the command exactly once")
	TEST_ASSERT_EQUAL(outcomes["delivered"], 1, "Queued discovery must acknowledge the original command once")
	TEST_ASSERT(!outcomes["failed"], "A valid APC route must not fail the queued command")
	var/deadline = world.time + 1 SECONDS
	while(!scene.source.received && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(scene.source.last_payload?["answer"], "queued", "The real reply must return through data delivery")

/// A cable lost before lookup fails finally; restoring it requires a fresh command.
/datum/unit_test/netrun_delivery_discovery_apc_unavailable/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	scene.bus.auto_pump = FALSE
	var/list/outcomes = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), scene.target.service_tag())
	var/datum/netrun_machine_resolution/external/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	query.deliver()
	TEST_ASSERT(scene.bus.supply_discovery(query, list(), "routing_unavailable"), "Remote routing failure enters the production decoder")
	query.deliver()
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Remote failure settles the original command once")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "Routing failure has no native fallback")
	scene.bus.auto_pump = TRUE
	var/list/recovered = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "fresh"), recovered), scene.target.service_tag())
	TEST_ASSERT(netrun_wait_delivery(recovered), "Fresh remote discovery can recover")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "Recovery does not replay the failed command")

/// Loading waiters own their command until completion or explicit cancellation.
/datum/unit_test/netrun_delivery_discovery_loading_cancel/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	SSatoms.map_loader_begin()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), scene.target.service_tag())
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	var/key = "service_discovery:[REF(query)]"
	var/was_pending = !QDELETED(query) && !outcomes["failed"] && !outcomes["delivered"]
	qdel(query)
	SSatoms.map_loader_stop()
	TEST_ASSERT(was_pending, "A loading request must wait without receiving a premature failure")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Cancelling a loading lookup must fail its queued command once")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "A cancelled loading lookup must not send data")
	TEST_ASSERT_EQUAL(length(scene.source.resolutions), 0, "Cancellation must release the coalesced source lookup")
	TEST_ASSERT_NULL(SSnetrun.get_task_scheduler().by_key[key], "Cancellation must remove its admitted discovery task")

/// An indexed recipient identity is revalidated by the worker, never cached past replacement.
/datum/unit_test/netrun_delivery_service_tag_revocation/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/original_tag = scene.target.service_tag()
	var/list/outcomes = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), original_tag), "The old indexed identity must be admitted before replacement")
	scene.receiver.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL, list(), 3)
	var/current_tag = scene.target.service_tag()
	TEST_ASSERT(current_tag != original_tag, "Replacing the physical component must retire its former address")
	TEST_ASSERT(!netrun_wait_delivery(outcomes), "The worker must reject a recipient identity revoked before lookup")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "A revoked recipient identity must report one terminal failure")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "An old identity cannot silently target the replacement")
	var/list/current = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), current), current_tag), "The actual replacement identity must accept a fresh request")
	TEST_ASSERT(netrun_wait_delivery(current), "The indexed replacement must be reachable through its real APC")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "Only the fresh identity's command may execute")

/// Deleting the sender also owns and cancels its admitted discovery operation.
/datum/unit_test/netrun_delivery_discovery_source_deleted/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), scene.target.service_tag()), "Source deletion needs a real admitted lookup")
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	var/key = "service_discovery:[REF(query)]"
	qdel(scene.sender)
	TEST_ASSERT(QDELETED(query), "Deleting the physical source must destroy its admitted lookup")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Source deletion must settle its queued message once")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "A deleted sender cannot execute a queued command")
	TEST_ASSERT_NULL(SSnetrun.get_task_scheduler().by_key[key], "Source deletion must release its discovery scheduler entry")

/// Observe domain matching rather than relying on elapsed time for area scoping.
/datum/netrun_machine_service/atmos/controller/discovery_scope_fixture
	var/match_checks = 0

/datum/netrun_machine_service/atmos/controller/discovery_scope_fixture/matches(datum/netrun_machine_service/source_service, recipient_tag)
	match_checks++
	return ..()

/obj/machinery/airalarm/discovery_scope_fixture/netrun_machine_service_types()
	. = ..()
	. -= /datum/netrun_machine_service/atmos/controller
	. += /datum/netrun_machine_service/atmos/controller/discovery_scope_fixture

/// One vent registers natively without matching every air alarm on the station.
/datum/unit_test/netrun_delivery_atmos_area_candidates/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/obj/machinery/airalarm/discovery_scope_fixture/alarm = scene.machine(/obj/machinery/airalarm/discovery_scope_fixture, scene.source_spot)
	var/obj/machinery/atmospherics/components/unary/vent_pump/vent = scene.machine(/obj/machinery/atmospherics/components/unary/vent_pump, scene.target_spot)
	var/obj/machinery/atmospherics/components/unary/outlet_injector/injector = scene.machine(/obj/machinery/atmospherics/components/unary/outlet_injector, scene.target_spot)
	// Area authorization is checked on an explicitly matching native channel.
	injector.frequency = alarm.frequency
	var/datum/netrun_machine_service/atmos/controller/discovery_scope_fixture/local_controller = alarm.get_netrun_machine_service("atmos.controller")
	var/datum/netrun_machine_service/atmos/device/device = vent.get_netrun_machine_service("atmos.device")
	var/datum/netrun_machine_service/atmos/device/injector/injector_service = injector.get_netrun_machine_service("atmos.device")
	var/list/levels = multiz_gravity_test_levels()
	scene.mark_station(levels[1])
	var/list/unrelated = list()
	var/turf/other_spot
	var/datum/netrun_machine_service/atmos/controller/discovery_scope_fixture/other_controller
	for(var/i in 1 to 64)
		var/area/room = scene.room(/area/netrun_route_test)
		var/turf/spot = scene.take(locate(80 + (i - 1) % 8, 80 + round((i - 1) / 8), levels[1]), room, TRUE)
		var/obj/machinery/airalarm/discovery_scope_fixture/other_alarm = scene.machine(/obj/machinery/airalarm/discovery_scope_fixture, spot)
		var/datum/netrun_machine_service/atmos/controller/discovery_scope_fixture/controller = other_alarm.get_netrun_machine_service("atmos.controller")
		unrelated += controller
		if(i == 1)
			other_spot = spot
			other_controller = controller
	SSnetrun.ensure_topology()
	for(var/datum/netrun_machine_service/atmos/controller/discovery_scope_fixture/controller as anything in unrelated)
		controller.match_checks = 0
	local_controller.match_checks = 0
	// Native initialization may already have delivered the first broadcast.
	// Require a new real delivery after resetting the observations.
	alarm.netrun_vent_info.Cut()
	vent.broadcast_status()
	var/deadline = world.time + 5 SECONDS
	while(!alarm.netrun_vent_info[vent.id_tag] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag], "The real vent status must register with its own native air alarm")
	TEST_ASSERT(local_controller.match_checks > 0, "The local controller must still run native channel and area authorization")
	var/datum/weakref/ack = device.acknowledged_controllers[REF(local_controller)]
	TEST_ASSERT_EQUAL(ack?.resolve(), local_controller, "Successful native delivery must acknowledge the actual local controller")
	for(var/datum/netrun_machine_service/atmos/controller/discovery_scope_fixture/controller as anything in unrelated)
		TEST_ASSERT_EQUAL(controller.match_checks, 0, "A status lookup must not call matches on any of the 64 unrelated area controllers")
	TEST_ASSERT(injector_service.matches(local_controller, null), "Local device retains native area authorization")
	injector.forceMove(other_spot)
	TEST_ASSERT(!injector_service.matches(local_controller, null), "Movement revokes native authorization from the former area")
	TEST_ASSERT(injector_service.matches(other_controller, null), "Actual destination area controls native authorization")
