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
	scheduler.enqueue("machine_delivery", target, NETRUN_TASK_BACKGROUND)
	scheduler.enqueue("machine_delivery", target, NETRUN_TASK_CRITICAL)
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

/datum/netrun_machine_message/transport_fixture/queue_snapshot/coalescing_key()
	return "replaceable-status"

/datum/netrun_machine_service/transport_fixture
	var/candidate_lookups = 0
	var/tag_override
	var/target_limit = 0

/datum/netrun_machine_service/transport_fixture/discovery_candidates(destination_id, recipient_tag)
	candidate_lookups++
	return ..()

/datum/netrun_machine_service/transport_fixture/service_tag()
	return tag_override || ..()

/datum/netrun_machine_service/transport_fixture/discovery_target_limit(destination_id)
	return target_limit

/// First-eligible discovery skips an unavailable peer, then stops without
/// routing or matching the rest of the registry. Ordinary services still fan out.
/datum/unit_test/netrun_delivery_discovery_target_limit/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/tag = "unicast-[REF(scene)]"
	scene.target.tag_override = tag
	transport.index_service(scene.target)
	var/list/peers = list()
	for(var/index in 1 to 12)
		var/obj/machinery/netrun_server/transport_fixture/host = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.target_spot)
		var/datum/netrun_machine_service/transport_fixture/peer = host.get_netrun_machine_service("transport.fixture")
		peer.tag_override = tag
		transport.index_service(peer)
		peers += peer
	scene.receiver.set_machine_stat(BROKEN)
	scene.source.target_limit = 1
	var/list/targets = scene.source.resolve("transport.fixture", tag)
	TEST_ASSERT_EQUAL(length(targets), 1, "Unicast discovery must select one live peer after an unavailable first entry")
	TEST_ASSERT_EQUAL(targets[1], peers[1], "Limiting discovery must preserve the existing first-eligible selection order")
	for(var/index in 2 to length(peers))
		var/datum/netrun_machine_service/transport_fixture/peer = peers[index]
		TEST_ASSERT_EQUAL(peer.match_checks, 0, "Synchronous unicast must not inspect later eligible peers")
	scene.target.match_checks = 0
	for(var/datum/netrun_machine_service/transport_fixture/peer as anything in peers)
		peer.match_checks = 0
	var/list/outcomes = list()
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), tag)
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|[tag]"]
	for(var/pass in 1 to 32)
		if(QDELETED(query))
			break
		query.deliver()
	TEST_ASSERT(QDELETED(query), "A limited lookup must finish without scanning the remaining registry")
	for(var/index in 2 to length(peers))
		var/datum/netrun_machine_service/transport_fixture/peer = peers[index]
		TEST_ASSERT_EQUAL(peer.match_checks, 0, "Asynchronous unicast must share the synchronous early-stop policy")
	TEST_ASSERT(netrun_wait_delivery(outcomes), "The first eligible recipient must receive the original unicast message")
	TEST_ASSERT_EQUAL(outcomes["delivered"], 1, "A unicast operation must execute only once")
	scene.source.target_limit = 0
	targets = scene.source.resolve("transport.fixture", tag)
	TEST_ASSERT_EQUAL(length(targets), length(peers), "The default zero limit must preserve full broadcast discovery")

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
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/tag = "bounded-fanout-[REF(scene)]"
	scene.target.tag_override = tag
	transport.index_service(scene.target)
	for(var/index in 1 to 9)
		var/obj/machinery/netrun_server/transport_fixture/host = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.target_spot)
		var/datum/netrun_machine_service/transport_fixture/peer = host.get_netrun_machine_service("transport.fixture")
		peer.tag_override = tag
		transport.index_service(peer)
	scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), list()), tag)
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|[tag]"]
	for(var/pass in 1 to 32)
		if(query.completed && !query.candidates)
			break
		query.deliver()
	TEST_ASSERT(!QDELETED(query) && !query.candidates && length(query.resolved_targets) == 10, "The regression requires a completed ten-peer lookup with pending fanout")
	var/saved_budget = SSnetrun.task_slice_budget_ms
	var/saved_start = SSnetrun.task_slice_start_usage
	var/saved_time = SSnetrun.task_slice_started_at
	SSnetrun.task_slice_budget_ms = 0
	SSnetrun.task_slice_start_usage = TICK_USAGE
	SSnetrun.task_slice_started_at = world.time
	var/before = length(transport.packets)
	query.deliver()
	var/admitted = length(transport.packets) - before
	var/remains_queued = !QDELETED(query) && query.delivery_queued
	SSnetrun.task_slice_budget_ms = saved_budget
	SSnetrun.task_slice_start_usage = saved_start
	SSnetrun.task_slice_started_at = saved_time
	TEST_ASSERT_EQUAL(admitted, 1, "An exhausted pass may admit only one indivisible packet before yielding")
	TEST_ASSERT(remains_queued, "The remaining broadcast branches must retain a runnable continuation")

/// Command bursts share one lookup and yield admission before consuming the batch.
/datum/unit_test/netrun_delivery_discovery_burst_slices/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/outcomes = list()
	for(var/i in 1 to 17)
		TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = i), outcomes), scene.target.service_tag()), "A finite command burst must be admitted")
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	TEST_ASSERT_EQUAL(scene.source.candidate_lookups, 0, "Sending a burst must not resolve synchronously")
	query.deliver()
	TEST_ASSERT(!QDELETED(query) && length(query.queued), "The first slice must retain the undispatched burst")
	TEST_ASSERT(scene.pending_packets() <= 8, "One discovery slice may admit at most eight routed packets within its CPU allowance")
	TEST_ASSERT_EQUAL(scene.source.candidate_lookups, 1, "One burst must use one recipient lookup")
	var/deadline = world.time + 5 SECONDS
	while(outcomes["delivered"] != 17 && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(outcomes["delivered"], 17, "Every original command must execute exactly once after later slices")
	TEST_ASSERT(!outcomes["failed"], "Yielding a valid burst must not lose commands")
	TEST_ASSERT_EQUAL(scene.source.candidate_lookups, 1, "Continuation slices must reuse the original recipient lookup")
	TEST_ASSERT(QDELETED(query), "A drained burst must release its lookup and scheduler task")

/// Both enumeration and fanout yield; deleting a registry member cannot skip its neighbor.
/datum/unit_test/netrun_delivery_discovery_registry_slices/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	for(var/i in 1 to 32)
		scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.target_spot)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/list/outcomes = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "broadcast"), outcomes)), "A broadcast must enter the common discovery queue")
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|"]
	query.deliver()
	TEST_ASSERT(query.candidates && query.candidate_cursor <= 9, "One slice must examine at most eight candidates from a large registry")
	TEST_ASSERT_EQUAL(length(query.queued), 1, "Enumeration must retain ownership of the original message")
	TEST_ASSERT_EQUAL(scene.pending_packets(), 0, "Partial enumeration must not bypass final target selection")
	var/paused_cursor = query.candidate_cursor
	SSatoms.map_loader_begin()
	query.deliver()
	var/paused = query.candidate_cursor == paused_cursor && (query in transport.waiting_resolutions) && !query.delivery_queued
	SSatoms.map_loader_stop()
	TEST_ASSERT(paused, "Map loading must pause even an already-started registry enumeration")
	// The common readiness wave resumes waiters through begin(), including
	// generations already retired from their source's coalescing map.
	query.begin()
	TEST_ASSERT(query.delivery_queued && !(query in transport.waiting_resolutions), "Reopening readiness must resume the retained generation without restarting lookup")
	var/expected = length(query.candidates) - 1
	var/datum/netrun_machine_service/doomed = query.candidates[query.candidate_cursor]
	qdel(doomed.host)
	for(var/pass in 1 to 128)
		if(QDELETED(query))
			break
		var/before = length(transport.packets)
		query.deliver()
		TEST_ASSERT(length(transport.packets) - before <= 8, "Every continuation must retain a finite routed-admission ceiling")
	TEST_ASSERT(QDELETED(query), "A finite broadcast must finish enumeration and fanout")
	TEST_ASSERT_EQUAL(scene.source.candidate_lookups, 1, "Registry mutations must not restart the retained enumeration")
	var/deadline = world.time + 5 SECONDS
	while((outcomes["delivered"] || 0) < expected && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT_EQUAL(outcomes["delivered"], expected, "Every surviving member of the original registry snapshot must receive exactly one copy")
	TEST_ASSERT(!outcomes["failed"], "Removing an unselected candidate must not fail surviving broadcast branches")

/// A legacy tag miss must budget fallback enumeration and repair future indexed lookups.
/datum/unit_test/netrun_delivery_discovery_tag_fallback_slices/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/list/extras = list()
	for(var/i in 1 to 32)
		var/obj/machinery/netrun_server/transport_fixture/extra = scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.target_spot)
		extras += extra.get_netrun_machine_service("transport.fixture")
	scene.target.tag_override = "legacy-[REF(scene)]"
	var/list/outcomes = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), scene.target.service_tag()), "An unindexed native tag must still admit asynchronous discovery")
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	query.deliver()
	TEST_ASSERT(query.candidates && query.candidate_cursor <= 9, "An exact-tag cache miss must not synchronously scan the service registry")
	for(var/pass in 1 to 64)
		if(QDELETED(query))
			break
		query.deliver()
	TEST_ASSERT(QDELETED(query), "Fallback discovery must finish without a registry rescan")
	TEST_ASSERT(netrun_wait_delivery(outcomes), "The legacy-renamed recipient must receive the original command")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "Fallback discovery must deliver once to the matching tag")
	for(var/datum/netrun_machine_service/transport_fixture/extra as anything in extras)
		extra.match_checks = 0
	var/list/resolved = scene.source.resolve("transport.fixture", scene.target.service_tag())
	TEST_ASSERT_EQUAL(length(resolved), 1, "Synchronous discovery must share the repaired tag index")
	TEST_ASSERT_EQUAL(resolved[1], scene.target, "Tag repair must retain the matching service identity")
	for(var/datum/netrun_machine_service/transport_fixture/extra as anything in extras)
		TEST_ASSERT_EQUAL(extra.match_checks, 0, "A repaired exact tag must not recheck unrelated services")

/// Source deletion must cancel even a generation retired from the source's coalescing map.
/datum/unit_test/netrun_delivery_discovery_lookup_source_deleted/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	for(var/i in 1 to 32)
		scene.machine(/obj/machinery/netrun_server/transport_fixture, scene.target_spot)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/queued_before = transport.queued_messages
	var/list/outcomes = list()
	for(var/i in 1 to 2)
		scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes))
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|"]
	query.deliver()
	TEST_ASSERT(query.candidates, "The source must be deleted during unfinished candidate enumeration")
	var/key = "service_discovery:[REF(query)]"
	TEST_ASSERT(SSnetrun.task_scheduler.by_key[key], "An unfinished lookup must own a worker continuation")
	qdel(scene.source)
	TEST_ASSERT(QDELETED(query), "Source teardown must dispose a partial registry snapshot immediately")
	TEST_ASSERT_NULL(SSnetrun.task_scheduler.by_key[key], "Source teardown must remove the continuation task")
	TEST_ASSERT_EQUAL(transport.queued_messages, queued_before, "Cancelling enumeration must release every original message slot")
	TEST_ASSERT_EQUAL(outcomes["failed"], 2, "Every original command must fail exactly once during enumeration cancellation")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "No command may execute after its enumerating producer is deleted")

/// Source teardown must cancel later slices as well as already admitted packets.
/datum/unit_test/netrun_delivery_discovery_burst_source_deleted/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/queued_before = transport.queued_messages
	var/list/outcomes = list()
	for(var/i in 1 to 17)
		scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list(), outcomes), scene.target.service_tag())
	var/datum/netrun_machine_resolution/query = scene.source.resolutions["transport.fixture|[scene.target.service_tag()]"]
	query.deliver()
	var/key = "service_discovery:[REF(query)]"
	TEST_ASSERT(SSnetrun.get_task_scheduler().by_key[key], "A partial burst must own a continuation")
	qdel(scene.source)
	TEST_ASSERT(QDELETED(query), "Source deletion must immediately cancel an active continuation")
	TEST_ASSERT_NULL(SSnetrun.task_scheduler.by_key[key], "Source deletion must remove the continuation task")
	TEST_ASSERT_EQUAL(transport.queued_messages, queued_before, "Cancelling a partial burst must release all owned message capacity")
	TEST_ASSERT_EQUAL(outcomes["failed"], 17, "Every unicast command must fail once across pending and already admitted work")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "Deleted-source commands must never reach the recipient")

/// Telemetry is ordinary background work even when its native message identifies an actor.
/datum/unit_test/netrun_delivery_machine_lane_and_cleanup/Run()
	var/datum/netrun_transport_scene/scene = allocate(/datum/netrun_transport_scene, run_loc_floor_bottom_left)
	var/datum/netrun_machine_message/transport_fixture/queue_snapshot/message = new(list(), list())
	var/mob/actor = allocate(/mob, scene.source_spot)
	message.user_ref = WEAKREF(actor)
	var/datum/netrun_machine_packet/data/packet = new(scene.source, scene.target, message)
	TEST_ASSERT(packet.send(), "A telemetry packet must acquire a real physical route")
	TEST_ASSERT(packet.delivery_queued && !packet.timer_id, "Sub-tick local traffic must enter the shared asynchronous queue without a per-hop timer")
	// Exercise the same owner with a genuine representable latency deadline too.
	packet.cancel_delivery()
	TEST_ASSERT(packet.schedule_delivery(5 SECONDS), "A delayed machine packet must retain cancellable admission")
	var/owned_timer = packet.timer_id
	deltimer(owned_timer)
	packet.queue_delivery()
	var/key = "machine_delivery:[REF(packet)]"
	var/datum/netrun_task/task = SSnetrun.get_task_scheduler().by_key[key]
	TEST_ASSERT(istype(task, /datum/netrun_task/machine_delivery), "Ready machine packets must use their registered delivery task")
	TEST_ASSERT(!task.interactive && task.priority == NETRUN_TASK_BACKGROUND, "An actor reference must not promote automated snapshots")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "Ready telemetry must wait for dispatch")
	packet.fail("fixture cancellation")
	TEST_ASSERT_NULL(SSnetrun.task_scheduler.by_key[key], "Cancelling ready telemetry must remove its scheduler entry")
	TEST_ASSERT(!(packet in SSnetrun.get_machine_transport().packets), "Cancelling telemetry must release packet capacity")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[owned_timer], "Cancelled telemetry must not retain its latency timer")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "Cancelled telemetry must not reach its native recipient")

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
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	var/list/outcomes = list()
	var/datum/netrun_machine_packet/data/packet = new(scene.source, scene.target, new /datum/netrun_machine_message/transport_fixture(list(), outcomes))
	var/list/previous_packets = transport.packets
	transport.packets = new /list(NETRUN_MAX_MACHINE_PACKETS)
	admitted = packet.send()
	transport.packets = previous_packets
	TEST_ASSERT(!admitted && QDELETED(packet), "Full machine capacity must refuse and consume the packet")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Capacity refusal must notify its native sender once")
	TEST_ASSERT(findtext(outcomes["reason"], "переполнена"), "Machine capacity must not masquerade as a missing route")
	scene.apc.set_machine_stat(BROKEN)
	outcomes = list()
	packet = new(scene.source, scene.target, new /datum/netrun_machine_message/transport_fixture(list(), outcomes))
	TEST_ASSERT(!packet.send(), "A packet without a physical route must fail admission")
	TEST_ASSERT(findtext(outcomes["reason"], "маршрута"), "Route failure must remain distinguishable from backpressure")

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
	var/list/outcomes = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "lost"), outcomes), scene.target.service_tag()), "A command must be admitted while its APC is available")
	scene.apc.set_machine_stat(BROKEN)
	TEST_ASSERT(!netrun_wait_delivery(outcomes), "Unavailable APC routing must reject the pending lookup")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "An unavailable route must report one final failure")
	TEST_ASSERT_EQUAL(scene.target.received, 0, "There is no native receive fallback after an APC failure")
	TEST_ASSERT_EQUAL(length(scene.source.resolutions), 0, "Final route failure must release the pending lookup")
	scene.apc.set_machine_stat(0)
	var/list/recovered = list()
	TEST_ASSERT(scene.source.send("transport.fixture", new /datum/netrun_machine_message/transport_fixture(list("value" = "fresh"), recovered), scene.target.service_tag()), "A restored APC must admit a fresh command")
	TEST_ASSERT(netrun_wait_delivery(recovered), "The fresh command must use the restored physical route")
	TEST_ASSERT_EQUAL(scene.target.received, 1, "Route restoration must not replay the failed earlier command")
	TEST_ASSERT_EQUAL(scene.target.last_payload["value"], "fresh", "Only the newly submitted command may execute")
	TEST_ASSERT_EQUAL(outcomes["failed"], 1, "Later restoration must not change the previous terminal outcome")

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
	var/list/candidates = local_controller.discovery_candidates("atmos.device", null)
	TEST_ASSERT((device in candidates) && (injector_service in candidates), "The shared area index must include both registering vents and command-only injectors")
	injector.forceMove(other_spot)
	candidates = local_controller.discovery_candidates("atmos.device", null)
	TEST_ASSERT(!(injector_service in candidates), "Moving a command-only device must remove it from its old area's candidates")
	candidates = other_controller.discovery_candidates("atmos.device", null)
	TEST_ASSERT(injector_service in candidates, "Moving a command-only device must index it in its actual new area")
	qdel(injector)
	TEST_ASSERT(!(injector_service in candidates), "Device deletion must remove the borrowed area's candidate entry")
	var/old_controller_key = REF(local_controller)
	qdel(alarm)
	alarm = scene.machine(/obj/machinery/airalarm/discovery_scope_fixture, scene.source_spot)
	local_controller = alarm.get_netrun_machine_service("atmos.controller")
	candidates = device.discovery_candidates("atmos.controller", null)
	TEST_ASSERT_EQUAL(length(candidates), 1, "Replacing an air alarm must leave exactly one live local discovery candidate")
	TEST_ASSERT(local_controller in candidates, "A fresh lookup must discover the replacement air alarm")
	vent.broadcast_status()
	deadline = world.time + 5 SECONDS
	while(!alarm.netrun_vent_info[vent.id_tag] && world.time < deadline)
		sleep(world.tick_lag)
	TEST_ASSERT(alarm.netrun_vent_info[vent.id_tag], "The replacement controller must receive actual native registration")
	TEST_ASSERT(!device.acknowledged_controllers[old_controller_key], "A deleted controller must not retain a registration acknowledgement")
	ack = device.acknowledged_controllers[REF(local_controller)]
	TEST_ASSERT_EQUAL(ack?.resolve(), local_controller, "Registration must acknowledge the replacement's service identity")
