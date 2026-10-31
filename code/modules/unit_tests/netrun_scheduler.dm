/// The ordinary allocator supplies a turf to argument-less constructors; this one takes limits.
/datum/unit_test/proc/netrun_scheduler_fixture()
	var/datum/netrun_task_scheduler/result = new
	allocated += result
	return result

/// Scheduler tests do not mutate the live SSnetrun queues.
/datum/unit_test/netrun_scheduler_dedup_and_priority/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/sample = allocate(/datum)
	TEST_ASSERT(scheduler.enqueue("probe", sample, NETRUN_TASK_BACKGROUND), "First task must enqueue")
	TEST_ASSERT(!scheduler.enqueue("probe", sample, NETRUN_TASK_BACKGROUND), "Duplicate task must coalesce")
	TEST_ASSERT(!scheduler.enqueue("probe", sample, NETRUN_TASK_CRITICAL), "Priority promotion must not duplicate")
	TEST_ASSERT_EQUAL(scheduler.pending(), 1, "Only one task must remain")
	var/datum/netrun_task/task = scheduler.take()
	TEST_ASSERT_EQUAL(task.priority, NETRUN_TASK_CRITICAL, "Promoted task must be served at new priority")
	qdel(task)
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "No pending task remains")
	TEST_ASSERT_NULL(scheduler.take(), "Promotion tombstone must not replay")
/datum/unit_test/netrun_scheduler_cancel_and_fairness/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/list/samples = list()
	for(var/i in 1 to 21)
		var/datum/sample = allocate(/datum)
		samples += sample
		var/priority = i <= 9 ? NETRUN_TASK_CRITICAL : (i <= 16 ? NETRUN_TASK_NORMAL : NETRUN_TASK_BACKGROUND)
		scheduler.enqueue("probe", sample, priority)
	TEST_ASSERT(scheduler.cancel("probe", samples[21]), "Cancellation succeeds")
	TEST_ASSERT_EQUAL(scheduler.pending(), 20, "Cancellation drops pending count")
	var/list/served = list(0, 0, 0)
	for(var/i in 1 to 14)
		var/datum/netrun_task/task = scheduler.take()
		TEST_ASSERT(!isnull(task), "Sufficient tasks remain")
		served[task.priority]++
		qdel(task)
	TEST_ASSERT(served[1] && served[2] && served[3], "All priorities receive execution")
	TEST_ASSERT_EQUAL(scheduler.pending(), 6, "Exactly 14 tasks returned")

/// Profiling must capture CPU cost and time spent waiting without retaining a target.
/datum/unit_test/netrun_scheduler_profiles/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/subject = allocate(/datum)
	TEST_ASSERT(scheduler.enqueue("probe", subject, NETRUN_TASK_CRITICAL), "A measured task is queued")
	var/datum/netrun_task/task = scheduler.take()
	TEST_ASSERT(!isnull(task), "A measured task is returned")
	task.enqueued_at = world.time - 3 SECONDS
	scheduler.note_execution(task, 1.25)
	qdel(task)
	var/datum/netrun_task_profile/profile = scheduler.profiles["probe"]
	TEST_ASSERT_EQUAL(profile.calls, 1, "One completed sample recorded")
	TEST_ASSERT_EQUAL(profile.total_ms, 1.25, "CPU work is recorded")
	TEST_ASSERT_EQUAL(profile.peak_wait_ds, 3 SECONDS, "Queue latency is recorded")
	TEST_ASSERT_EQUAL(profile.overdue, 1, "Delayed critical task is counted")
	TEST_ASSERT_EQUAL(scheduler.overdue_by_priority[NETRUN_TASK_CRITICAL], 1, "Per-priority late counter matches profile")
	TEST_ASSERT_EQUAL(scheduler.peak_pending, 1, "High-water mark records queue size")
	TEST_ASSERT_EQUAL(scheduler.pending(), 0, "Stats do not create extra tasks")

/// Promotion affects the current priority bucket without inflating pending metrics.
/datum/unit_test/netrun_scheduler_profile_promotion/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/subject = allocate(/datum)
	scheduler.enqueue("probe", subject, NETRUN_TASK_BACKGROUND)
	scheduler.enqueue("probe", subject, NETRUN_TASK_CRITICAL)
	TEST_ASSERT_EQUAL(scheduler.pending(), 1, "Promotion leaves one pending task")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_BACKGROUND], 0, "Old priority has no pending task")
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_CRITICAL], 1, "New priority has the task")
	TEST_ASSERT_EQUAL(scheduler.peak_queued_by_priority[NETRUN_TASK_BACKGROUND], 1, "Original queue high-water survives promotion")
	TEST_ASSERT_EQUAL(scheduler.peak_queued_by_priority[NETRUN_TASK_CRITICAL], 1, "Promoted queue high-water is recorded")

/// Previously a burst of cancellations hid a live background task behind scan tombstones.
/datum/unit_test/netrun_scheduler_cancel_burst/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	for(var/i in 1 to 160)
		var/datum/subject = allocate(/datum)
		scheduler.enqueue("probe", subject, NETRUN_TASK_BACKGROUND)
		TEST_ASSERT(scheduler.cancel("probe", subject), "Every obsolete task must cancel")
	var/datum/live = allocate(/datum)
	scheduler.enqueue("probe", live, NETRUN_TASK_BACKGROUND)
	TEST_ASSERT_EQUAL(scheduler.pending(), 1, "Only the live task remains")
	var/datum/netrun_task/task = scheduler.take()
	TEST_ASSERT_NOTNULL(task, "A pending live task must be returned on this pass regardless of prior cancellations")
	TEST_ASSERT_EQUAL(task.target(), live, "Cancellation must not reorder or hide the live task")
	qdel(task)
	TEST_ASSERT_EQUAL(scheduler.counts[NETRUN_TASK_BACKGROUND], 0, "Cancellation and service must release all queue capacity")
	TEST_ASSERT_NULL(scheduler.take(), "No cancelled entry may be replayed")

/// Promotion unlinks the old entry and preserves its original age for diagnostics.
/datum/unit_test/netrun_scheduler_promotion_fifo/Run()
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	var/datum/first = allocate(/datum)
	var/datum/promoted = allocate(/datum)
	var/datum/last = allocate(/datum)
	scheduler.enqueue("probe", first, NETRUN_TASK_BACKGROUND)
	scheduler.enqueue("probe", promoted, NETRUN_TASK_BACKGROUND)
	scheduler.enqueue("probe", last, NETRUN_TASK_BACKGROUND)
	var/datum/netrun_task/middle = scheduler.by_key["probe:[REF(promoted)]"]
	middle.enqueued_at = world.time - 30 SECONDS
	scheduler.enqueue("probe", promoted, NETRUN_TASK_CRITICAL)
	var/datum/netrun_task/task = scheduler.take()
	TEST_ASSERT_EQUAL(task, middle, "Promotion must preserve task identity")
	TEST_ASSERT_EQUAL(task.enqueued_at, world.time - 30 SECONDS, "Promotion must preserve the wait clock")
	qdel(task)
	task = scheduler.take()
	TEST_ASSERT_EQUAL(task.target(), first, "Unlinking a middle task must preserve FIFO order")
	qdel(task)
	task = scheduler.take()
	TEST_ASSERT_EQUAL(task.target(), last, "The original tail must remain reachable after unlinking")
	qdel(task)
	for(var/datum/netrun_task_queue/queue as anything in scheduler.queues)
		TEST_ASSERT_NULL(queue.first, "Drained queue must release its head reference")
		TEST_ASSERT_NULL(queue.last, "Drained queue must release its tail reference")

/// Test probes exercise lifecycle without opening TGUI or waiting on a real clock.
/datum/netrun_console/netrun_scheduler_probe
	var/list/test_deltas = list()
	var/delete_during_tick = FALSE

/datum/netrun_console/netrun_scheduler_probe/process_tick(delta)
	test_deltas += delta
	if(delete_during_tick)
		qdel(src)

/datum/netrun_console/netrun_scheduler_probe/flush_ui()
	test_deltas += "flush"

/datum/unit_test/netrun_scheduler_wake_clock/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/netrun_scheduler_probe/console = allocate(/datum/netrun_console/netrun_scheduler_probe, host)
	SSnetrun.active_consoles -= console
	console.last_netrun_tick = world.time - 10 MINUTES
	console.activate()
	TEST_ASSERT_EQUAL(console.last_netrun_tick, world.time, "Waking an idle session must start a new active interval")
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	scheduler.enqueue("console", console)
	var/datum/netrun_task/task = scheduler.take()
	TEST_ASSERT(istype(task, /datum/netrun_task/console), "The task registry must select polymorphic console processing")
	var/previous_count = SSnetrun.last_processed_consoles
	task.execute(SSnetrun)
	SSnetrun.last_processed_consoles = previous_count
	qdel(task)
	TEST_ASSERT_EQUAL(console.test_deltas[1], 0, "Minutes asleep must not become trace or damage on wake")
	// Reactivation while processing is live must not lose real elapsed time.
	console.activate()
	console.last_netrun_tick = world.time - 3 SECONDS
	console.activate()
	TEST_ASSERT_EQUAL(console.last_netrun_tick, world.time - 3 SECONDS, "Repeated events must preserve an already active clock")

/datum/unit_test/netrun_scheduler_console_deleted_during_tick/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/netrun_scheduler_probe/console = allocate(/datum/netrun_console/netrun_scheduler_probe, host)
	var/list/samples = console.test_deltas
	console.delete_during_tick = TRUE
	var/datum/netrun_task_scheduler/scheduler = netrun_scheduler_fixture()
	scheduler.enqueue("console", console)
	var/datum/netrun_task/task = scheduler.take()
	task.execute(SSnetrun)
	qdel(task)
	TEST_ASSERT(QDELETED(console), "Dive processing may delete its own console")
	TEST_ASSERT_EQUAL(length(samples), 1, "A deleted console must never be asked to flush its UI")
	console.activate()
	TEST_ASSERT(!(console in SSnetrun.active_consoles), "A signal during teardown must not reactivate a deleted console")

/datum/unit_test/netrun_scheduler_client_teardown/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_task_scheduler/scheduler = SSnetrun.get_task_scheduler()
	scheduler.enqueue("console", console)
	var/key = "console:[REF(console)]"
	qdel(console)
	TEST_ASSERT_NULL(scheduler.by_key[key], "Deleting a session must cancel its queued work immediately")
	var/datum/netrun_ice/ice = new(null)
	allocated += ice
	scheduler.enqueue("ice", ice)
	key = "ice:[REF(ice)]"
	qdel(ice)
	TEST_ASSERT_NULL(scheduler.by_key[key], "Deleting an ICE must cancel its queued work immediately")

/// A delivery cannot acquire two timers, execute reentrantly or replay after early dispatch.
/datum/netrun_request/delivery/netrun_scheduler_probe
	var/list/executions = list()

/datum/netrun_request/delivery/netrun_scheduler_probe/execute()
	executions += "execute"
	deliver()
	return TRUE

/datum/unit_test/netrun_request_single_dispatch/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/datum/netrun_console/console = allocate(/datum/netrun_console, host)
	var/datum/netrun_request/delivery/netrun_scheduler_probe/packet = allocate(/datum/netrun_request/delivery/netrun_scheduler_probe, console, node, node.network)
	var/list/executions = packet.executions
	TEST_ASSERT(packet.send(30 SECONDS), "The first send must acquire one timer")
	var/timer_id = packet.timer_id
	TEST_ASSERT(!packet.send(60 SECONDS), "A second send must not create an unowned timer")
	TEST_ASSERT_EQUAL(packet.timer_id, timer_id, "Rejected redispatch must retain the original timer")
	TEST_ASSERT(packet.deliver(), "Early delivery must execute the original packet")
	TEST_ASSERT_EQUAL(length(executions), 1, "Reentrant delivery must not execute the request twice")
	TEST_ASSERT(QDELETED(packet), "A delivered packet must release its dependencies")
	TEST_ASSERT_NULL(packet.timer_id, "Early delivery must cancel its pending timer")
	TEST_ASSERT_NULL(SStimer.timer_id_dict[timer_id], "A consumed packet must not leave a timer behind")

/// Clientless residents rest without polling topology, vision or neural HUD feedback.
/datum/unit_test/netrun_scheduler_idle_resident/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/obj/item/carrier = allocate(/obj/item, origin)
	var/obj/item/host = allocate(/obj/item, carrier)
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_console/console = entity.console
	console.last_ui_at = -INFINITY
	console.stop_ui_observation()
	SSnetrun.active_consoles -= console
	SSnetrun.task_scheduler?.cancel("console", console)
	TEST_ASSERT(!entity.needs_processing(), "A healthy resident without a player or neural body has no periodic work")
	TEST_ASSERT(!console.needs_processing(), "The entity origin must not keep an idle console awake forever")
	carrier.forceMove(get_step(origin, EAST))
	TEST_ASSERT_EQUAL(entity.loc, get_turf(carrier), "A sleeping resident must still follow its moving physical carrier through a local signal")
	TEST_ASSERT(!(console in SSnetrun.active_consoles), "Following a carrier must not wake a clientless resident's UI")
	entity.take_integrity(1, "repair wake test")
	TEST_ASSERT(entity.needs_processing() && (console in SSnetrun.active_consoles), "Damage must wake the resident until its integrity has repaired")
	entity.integrity = entity.max_integrity
	TEST_ASSERT(!entity.needs_processing(), "Completed repair must allow the resident to sleep again")
	var/turf/last_position = entity.loc
	entity.leave_node()
	carrier.forceMove(origin)
	TEST_ASSERT_EQUAL(entity.loc, last_position, "Leaving a host must release its local movement subscription")

/// Native signals already track carried machinery; periodic fallback is for custom state.
/datum/unit_test/netrun_scheduler_signal_driven_machinery/Run()
	var/obj/machinery/host = allocate(/obj/machinery)
	host.anchored = FALSE
	var/datum/component/netrun_node/node = host.AddComponent(/datum/component/netrun_node, NETRUN_NODE_TERMINAL)
	SSnetrun.track_node(node)
	TEST_ASSERT(node.is_dynamic(), "The fixture must be an unanchored dynamic endpoint")
	TEST_ASSERT(isnull(SSnetrun.poll_nodes[node]), "Being movable must not add machinery with native state signals to the poll set")
	node.pending_physical_update = FALSE
	host.forceMove(get_step(get_turf(host), EAST))
	TEST_ASSERT(node.pending_physical_update, "Native movement must still enqueue physical reconciliation without a fallback poll")

/datum/component/netrun_node/netrun_scheduler_probe
	var/join_calls = 0

/datum/component/netrun_node/netrun_scheduler_probe/join_network()
	join_calls++
	return ..()

/// A presentation/status poll must not rejoin a dynamic endpoint that has not moved.
/datum/unit_test/netrun_scheduler_dynamic_binding_reuse/Run()
	var/obj/item/host = allocate(/obj/item)
	var/datum/component/netrun_node/netrun_scheduler_probe/node = host.AddComponent(/datum/component/netrun_node/netrun_scheduler_probe, NETRUN_NODE_TERMINAL)
	var/datum/controller/subsystem/netrun/netrun_execution_test/worker = allocate(/datum/controller/subsystem/netrun/netrun_execution_test)
	node.pending_physical_update = FALSE
	node.binding_checked = TRUE
	node.binding_infra_revision = worker.get_topology().infrastructure_revision
	worker.node_interest_until[node] = world.time + NETRUN_NODE_INTEREST_LEASE
	var/joins = node.join_calls
	var/datum/netrun_task_scheduler/scheduler = worker.get_task_scheduler()
	scheduler.enqueue("node", node)
	var/datum/netrun_task/task = scheduler.take()
	task.execute(worker)
	qdel(task)
	TEST_ASSERT_EQUAL(node.join_calls, joins, "Unmoved dynamic nodes must reuse their current APC/LAN binding")
	node.pending_physical_update = TRUE
	scheduler.enqueue("node", node)
	task = scheduler.take()
	task.execute(worker)
	qdel(task)
	TEST_ASSERT_EQUAL(node.join_calls, joins + 1, "A queued physical change must still reconcile the actual binding")

/// Idle patrols generate no traffic in empty LANs and resume for local gameplay only.
/datum/unit_test/netrun_scheduler_patrol_interest_lifecycle/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = allocate(/datum/netrun_route_scene, origin.z)
	var/area/engineering = scene.room(/area/engineering/netrun_route_test)
	var/area/medical = scene.room(/area/medical/netrun_route_test)
	var/obj/machinery/power/apc/local_apc = scene.machine(/obj/machinery/power/apc, scene.take(origin, engineering))
	var/obj/machinery/computer/netrun_terminal/local_terminal = scene.machine(/obj/machinery/computer/netrun_terminal, scene.take(get_step(origin, EAST), engineering))
	var/obj/machinery/power/apc/remote_apc = scene.machine(/obj/machinery/power/apc, scene.take(locate(origin.x + 5, origin.y, origin.z), medical))
	SSnetrun.ensure_topology()
	var/datum/component/netrun_node/local_node = local_apc.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/target_node = local_terminal.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/remote_node = remote_apc.GetComponent(/datum/component/netrun_node)
	var/datum/netrun_ice/local_patrol = allocate(/datum/netrun_ice, local_node, NETRUN_ICE_HUNTER)
	var/datum/netrun_ice/remote_patrol = allocate(/datum/netrun_ice, remote_node, NETRUN_ICE_HUNTER)
	local_patrol.persistent = TRUE
	remote_patrol.persistent = TRUE
	local_patrol.hop_cooldown = world.time
	remote_patrol.hop_cooldown = world.time
	SSnetrun.collect_defense_network_interest()
	TEST_ASSERT(!local_patrol.needs_netrun_tick() && !remote_patrol.needs_netrun_tick(), "Due persistent patrols must sleep when their LANs are empty")
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(target_node)
	TEST_ASSERT(SSnetrun.active_defense_networks[local_node.network.id], "A local arrival must mark its own LAN immediately")
	TEST_ASSERT(SSnetrun.task_scheduler.by_key["ice:[REF(local_patrol)]"], "A local arrival must wake its hunter without waiting for population")
	TEST_ASSERT(!SSnetrun.active_defense_networks[remote_node.network.id], "An arrival must not wake another department")
	SSnetrun.collect_defense_network_interest()
	local_patrol.hop_cooldown = world.time
	TEST_ASSERT(local_patrol.needs_netrun_tick(), "An occupied LAN must resume its patrol deadlines")
	qdel(entity)
	SSnetrun.collect_defense_network_interest()
	TEST_ASSERT(!local_patrol.needs_netrun_tick(), "Removing the last resident must let its patrol sleep again")
	var/datum/netrun_console/console = local_terminal.console
	TEST_ASSERT(console.start_breach("network", target_node.network.id), "A real network breach must remain available in the idle LAN")
	SSnetrun.collect_defense_network_interest()
	TEST_ASSERT(SSnetrun.active_defense_networks[local_node.network.id], "A live remote breach must keep its target LAN active without resident entities")
	qdel(console.intrusion.breach)
	console.intrusion.breach = null
	SSnetrun.collect_defense_network_interest()
	TEST_ASSERT(!SSnetrun.active_defense_networks[local_node.network.id], "Cancelling the last breach must release patrol interest")

/// Synchronous combat/movement admission reads fresh authority without cloning the station.
/datum/unit_test/netrun_scheduler_entity_authority_borrows/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/datum/netrun_route_scene/scene = netrun_connected_test_area()
	var/obj/machinery/computer/netrun_terminal/host = scene.machine(/obj/machinery/computer/netrun_terminal, origin)
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/datum/component/netrun_node/node = host.GetComponent(/datum/component/netrun_node)
	var/datum/component/netrun_node/next_node = node.bound_apc
	var/mob/camera/netrun_entity/entity = allocate(/mob/camera/netrun_entity)
	entity.enter_node(node)
	var/datum/netrun_console/console = entity.console
	console.access_session.node_access[next_node.address] = NETRUN_ACCESS_USER
	var/datum/netrun_path_tree/stale = console.make_path_tree()
	stale.reached.Cut()
	stale.reached_networks.Cut()
	console.ui_routes = stale
	var/copies = graph.route_snapshot_copies
	TEST_ASSERT(entity.can_enter(next_node), "Movement admission must use the current physical path even while an old UI tree says it is unreachable")
	console.access_session.node_access -= node.address
	var/datum/netrun_ice/ice = allocate(/datum/netrun_ice, node)
	TEST_ASSERT(ice.valid_program_target(SSnetrun.get_program("strike"), entity, TRUE), "A fresh combat check must still identify an unauthorized resident")
	TEST_ASSERT_EQUAL(graph.route_snapshot_copies, copies, "Synchronous movement and ICE authority checks must not deep-copy whole route trees")
	var/datum/netrun_path_tree/retained = graph.route_tables[node.address]
	TEST_ASSERT(retained && !QDELETED(retained), "Releasing a borrowed authority tree must preserve the topology's retained route table")
	console.ui_routes = null
	qdel(stale)
