/// Machine services share physical routing, while each adapter retains native authorization.
/atom
	var/list/netrun_machine_services

/atom/proc/netrun_machine_service_types()
	return list()

/atom/proc/netrun_machine_service_node()
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(!node && length(netrun_machine_service_types()))
		node = AddComponent(/datum/component/netrun_node, NETRUN_NODE_SERVER, list(), 1)
	return node

/atom/proc/ensure_netrun_machine_services(datum/component/netrun_node/node)
	if(!node || QDELETED(src))
		return
	if(!netrun_machine_services)
		netrun_machine_services = list()
	for(var/datum/netrun_machine_service/path as anything in netrun_machine_service_types())
		var/id = initial(path.service_id)
		var/datum/netrun_machine_service/service = netrun_machine_services[id]
		if(QDELETED(service))
			netrun_machine_services[id] = new path(node, src)
		else
			// HIGHLANDER replaces a component after registering the new one.
			service.node = node
			SSnetrun.get_machine_transport().index_service(service)

/atom/proc/get_netrun_machine_service(service_id)
	var/datum/component/netrun_node/node = netrun_machine_service_node()
	ensure_netrun_machine_services(node)
	var/datum/netrun_machine_service/service = netrun_machine_services?[service_id]
	if(!QDELETED(service))
		service.node = node
		SSnetrun.get_machine_transport().index_service(service)
		return service

/datum/controller/subsystem/netrun
	var/datum/netrun_machine_transport/machine_transport

/datum/controller/subsystem/netrun/proc/get_machine_transport() as /datum/netrun_machine_transport
	RETURN_TYPE(/datum/netrun_machine_transport)
	if(!machine_transport)
		machine_transport = new
	return machine_transport

/datum/netrun_machine_service
	var/service_id
	/// Only adapters with startup work enter the readiness wave.
	var/start_when_ready = FALSE
	var/atom/host
	var/datum/component/netrun_node/node
	var/list/resolutions = list()
	var/indexed_tag

/datum/netrun_machine_service/New(datum/component/netrun_node/node, atom/host_override)
	src.node = node
	host = host_override || node?.parent
	if(host)
		RegisterSignal(host, COMSIG_PARENT_QDELETING, PROC_REF(host_deleted))
		RegisterSignal(host, list(COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE, COMSIG_ATOM_UPDATE_NAME, COMSIG_NETRUN_SERVICE_STATE_CHANGED, COMSIG_MODULAR_COMPUTER_FILE_STORE, COMSIG_MODULAR_COMPUTER_FILE_DELETE), PROC_REF(host_initialized))
	SSnetrun.get_machine_transport().register(src)

/datum/netrun_machine_service/Destroy()
	SSnetrun.task_scheduler?.cancel("service_initialize", src)
	SSnetrun.get_machine_transport().unregister(src)
	if(host)
		UnregisterSignal(host, list(COMSIG_PARENT_QDELETING, COMSIG_ATOM_AFTER_SUCCESSFUL_INITIALIZE, COMSIG_ATOM_UPDATE_NAME, COMSIG_NETRUN_SERVICE_STATE_CHANGED, COMSIG_MODULAR_COMPUTER_FILE_STORE, COMSIG_MODULAR_COMPUTER_FILE_DELETE))
		if(host.netrun_machine_services?[service_id] == src)
			host.netrun_machine_services -= service_id
	for(var/key in resolutions.Copy())
		qdel(resolutions[key])
	resolutions.Cut()
	host = null
	node = null
	return ..()

/datum/netrun_machine_service/proc/host_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/netrun_machine_service/proc/host_initialized()
	SIGNAL_HANDLER
	SSnetrun.get_machine_transport().index_service(src)

/// Domain startup which needs usable routes runs after the common readiness barrier.
/datum/netrun_machine_service/proc/network_ready()
	return

/datum/netrun_machine_service/proc/service_key()
	return "[REF(host)]:[service_id]"

/datum/netrun_machine_service/proc/resolve_node()
	RETURN_TYPE(/datum/component/netrun_node)
	return node

/datum/netrun_machine_service/proc/service_tag()
	return resolve_node()?.address

/datum/netrun_machine_service/proc/matches(datum/netrun_machine_service/source_service, recipient_tag)
	return isnull(recipient_tag) || service_tag() == recipient_tag

/datum/netrun_machine_service/proc/accepts(datum/netrun_machine_message/message)
	return !QDELETED(host) && resolve_node()?.is_online() && message.source?.resolve_node()?.is_online()

/datum/netrun_machine_service/proc/receive(datum/netrun_machine_message/message)
	return FALSE

/datum/netrun_machine_service/proc/rejection_reason(datum/netrun_machine_message/message)
	return "получатель отклонил пакет"

/datum/netrun_machine_service/proc/send(destination_id, datum/netrun_machine_message/message, recipient_tag)
	if(QDELETED(message))
		return FALSE
	var/datum/netrun_machine_resolution/query = get_resolution(destination_id, recipient_tag)
	if(!query)
		message.failed("источник недоступен")
		qdel(message)
		return FALSE
	if(!query.enqueue(message))
		// Failed admission must not occupy one of the source's discovery slots or
		// enqueue empty work. An existing burst still owns its admitted messages.
		if(!QDELETED(query) && !length(query.queued))
			qdel(query)
		return FALSE
	query.begin()
	return TRUE

/// All discovery paths use the same domain policy; shared research mutates once.
/datum/netrun_machine_service/proc/select_targets(destination_id, list/targets)
	return targets

/// Zero preserves broadcast enumeration. An adapter may stop after this many
/// eligible peers only when later candidates cannot change its selection policy.
/datum/netrun_machine_service/proc/discovery_target_limit(destination_id)
	return 0

/datum/netrun_machine_service/proc/send_to(datum/netrun_machine_service/target, datum/netrun_machine_message/message)
	return SSnetrun.get_machine_transport().dispatch(src, target, message)

/// Read-only discovery consumes the same APC registry and physical path contract.
/datum/netrun_machine_service/proc/resolve(destination_id, recipient_tag)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(!transport.is_ready())
		return list()
	return select_targets(destination_id, transport.lookup(src, destination_id, recipient_tag, netrun_communication_policy(src, destination_id)))

/// Domain adapters may narrow enumeration using native indexes. Candidates remain
/// borrowed registry entries; live matching and physical routing still authorize them.
/datum/netrun_machine_service/proc/discovery_candidates(destination_id, recipient_tag)
	return SSnetrun.get_machine_transport().discovery_candidates(destination_id, recipient_tag)

/datum/netrun_machine_service/proc/get_resolution(destination_id, recipient_tag)
	if(QDELETED(src) || QDELETED(host) || QDELETED(resolve_node()))
		return null
	if(SSnetrun.get_machine_transport().is_ready() && !resolve_node().is_online())
		return null
	var/query_key = "[destination_id]|[recipient_tag]"
	var/datum/netrun_machine_resolution/query = resolutions[query_key]
	if(query)
		return query
	if(length(resolutions) >= 64)
		return null
	query = new(src, destination_id, recipient_tag)
	resolutions[query_key] = query
	return query

/datum/netrun_machine_service/proc/can_reach(datum/netrun_machine_service/target)
	return !QDELETED(target) && SSnetrun.get_machine_transport().reachable(src, target)

/// APC-attached services advertise in one registry; only data needs network delivery.
/datum/netrun_machine_transport
	var/list/services = list()
	var/list/ready_services = list()
	/// Closed readiness barriers park services without runnable polling tasks.
	var/list/pending_ready_services = list()
	var/ready_queued = FALSE
	var/list/by_id = list()
	var/list/by_tag = list()
	var/list/waiting_resolutions = list()
	var/wake_timer
	/// Readiness notifications share one bounded common-worker continuation.
	var/wake_queued = FALSE
	var/list/wake_queries
	var/wake_cursor = 1
	var/wake_again = FALSE
	var/preparing = FALSE
	var/bootstrap_complete = FALSE
	var/list/bootstrap_services
	var/bootstrap_cursor = 1
	var/list/ready_service_keys
	var/ready_service_cursor = 1
	var/packet_serial = 0
	var/list/service_revisions = list()
	var/list/packets = list()
	var/list/interactive_packets = list()
	var/queued_messages = 0
	var/list/last_flow = list()
	var/flow_window = 0
	var/flow_count = 0
	var/revision = 0
	var/list/pair_routes = list()
	var/list/pair_used = list()
	var/list/pair_previous = list()
	var/list/pair_next = list()
	var/pair_oldest
	var/pair_newest
	var/route_cache_limit = 8192
	var/pair_serial = 0
	var/path_builds = 0
	var/path_cache_hits = 0
	var/tree_builds = 0
	var/list/prewarm_roots = list()
	var/prewarm_revision = -1
	var/prewarm_infrastructure = -1
	var/prewarm_steps = 0
	var/prewarm_limit = 512
	var/bootstrap_at
	/// Source/recipient/contract key -> one replaceable, not-yet-executing packet.
	var/list/replaceable_packets = list()
	var/coalesced_packets = 0
	/// Opt-in diagnostics: value snapshots only, bounded independently of packet lifetime.
	var/list/delivery_trace

/datum/netrun_machine_transport/proc/trace_delivery(datum/netrun_machine_packet/packet)
	if(!islist(delivery_trace))
		return
	delivery_trace += list(list("id" = packet.packet_id, "kind" = packet.kind,
		"source" = "[packet.source?.host?.type]", "destination" = "[packet.recipient?.host?.type]",
		"sent" = packet.sent_at, "due" = packet.due_at, "ready" = packet.ready_at, "run" = world.time,
		"timer_late" = max(0, packet.ready_at - packet.due_at), "queue_wait" = max(0, world.time - packet.ready_at)))
	if(length(delivery_trace) > 256)
		delivery_trace.Cut(1, length(delivery_trace) - 255)

/datum/netrun_machine_transport/New()
	RegisterSignal(SSatoms, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(atoms_initialized))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_CHANGED, PROC_REF(network_changed))

/datum/netrun_machine_transport/proc/atoms_initialized()
	SIGNAL_HANDLER
	prepare_network()

/datum/netrun_machine_transport/proc/is_ready()
	return bootstrap_complete && !preparing && SSnetrun.initialized && SSatoms.initialized == INITIALIZATION_INNEW_REGULAR

/// Master starts subsystem fire only after its whole initialization loop. The atom
/// post-init signal alone is too early: power, research and native links can change.
/datum/netrun_machine_transport/proc/prepare_network()
	if(preparing || !SSnetrun.initialized || SSatoms.initialized != INITIALIZATION_INNEW_REGULAR || Master.initializing_subsystem || !Master.current_runlevel)
		return
	// Map/shuttle loading can temporarily close readiness after the first bootstrap.
	// Its completion emits no topology signal: the ordinary worker observes the
	// reopened barrier and coalesces one bounded wake, including during a live round.
	if(bootstrap_complete && length(waiting_resolutions))
		wake_resolutions()
	if(bootstrap_complete)
		wake_ready_services()
	var/pregame = SSticker.current_state < GAME_STATE_PLAYING
	if(bootstrap_complete && !pregame)
		return
	var/datum/netrun_topology/graph = SSnetrun.get_topology()
	if(!bootstrap_complete || graph.dirty || prewarm_revision != graph.revision || length(prewarm_roots))
		SSnetrun.get_task_scheduler().enqueue("network_bootstrap", src, NETRUN_TASK_BACKGROUND)

/// One topology preparation slice or one retained infrastructure tree per task.
/datum/netrun_machine_transport/proc/advance_bootstrap(datum/netrun_execution_limits/limits)
	if(preparing || Master.initializing_subsystem || SSatoms.initialized != INITIALIZATION_INNEW_REGULAR)
		// prepare_network() observes the reopened barrier. Retain partial startup
		// state here without leaving a runnable continuation polling map loading.
		return TRUE
	preparing = TRUE
	if(!bootstrap_complete)
		SSnetrun.spawn_roundstart_servers()
	var/datum/netrun_topology/graph = SSnetrun.get_topology()
	if(graph.dirty)
		if(!graph.advance_apc_prebuild(limits.apc_operations))
			preparing = FALSE
			return FALSE
	if(!bootstrap_complete)
		if(!bootstrap_services)
			bootstrap_services = services.Copy()
			bootstrap_cursor = 1
		var/stop = min(length(bootstrap_services), bootstrap_cursor + 31)
		while(bootstrap_cursor <= stop)
			var/key = bootstrap_services[bootstrap_cursor++]
			var/datum/netrun_machine_service/service = services[key]
			if(!QDELETED(service))
				// Native area/organ/program initialization is now complete. Reuse
				// the common lifecycle hook instead of keeping stale early bindings.
				service.host_initialized()
		if(bootstrap_cursor <= length(bootstrap_services))
			preparing = FALSE
			return FALSE
		bootstrap_services = null
		bootstrap_complete = TRUE
		bootstrap_at = world.time
		wake_resolutions()
	if(prewarm_revision != graph.revision || prewarm_infrastructure != graph.infrastructure_revision)
		prewarm_roots.Cut()
		prewarm_revision = graph.revision
		prewarm_infrastructure = graph.infrastructure_revision
		// Discovery and native communications are useful first. Store APC anchors,
		// never a whole station-sized routing table per vent, radio or PDA.
		for(var/id in list("research.server", "telecomms.relay", "research.client"))
			for(var/datum/netrun_machine_service/service as anything in by_id[id])
				var/datum/component/netrun_node/node = service.resolve_node()
				var/datum/component/netrun_node/root = graph.is_infrastructure(node) ? node : node?.bound_apc
				if(root && length(prewarm_roots) < prewarm_limit)
					prewarm_roots |= root.address
		for(var/address in graph.registered_apcs)
			if(length(prewarm_roots) >= prewarm_limit)
				break
			prewarm_roots |= address
	if(length(prewarm_roots))
		var/address = prewarm_roots[1]
		prewarm_roots.Cut(1, 2)
		var/datum/component/netrun_node/root = graph.nodes[address]
		if(!QDELETED(root) && root.is_online())
			path_tree(graph, root)
			prewarm_steps++
	preparing = FALSE
	wake_ready_services()
	return !length(prewarm_roots)

/// Registration and temporarily suspended domain work reuse the same bounded
/// startup wave. Weak entries cannot retain a removed host while the barrier rests.
/datum/netrun_machine_transport/proc/defer_ready_service(datum/netrun_machine_service/service)
	if(QDELETED(service))
		return
	var/key = service.service_key()
	if(services[key] != service)
		return
	pending_ready_services[key] = WEAKREF(service)
	wake_ready_services()

/datum/netrun_machine_transport/proc/wake_ready_services()
	if(ready_queued || !is_ready() || (!ready_service_keys && !length(pending_ready_services)))
		return
	ready_queued = TRUE
	SSnetrun.get_task_scheduler().enqueue("service_ready", src, NETRUN_TASK_BACKGROUND)

/datum/netrun_task/network_bootstrap
	parent_type = /datum/netrun_task/continuation
	kind = "network_bootstrap"

/datum/netrun_task/network_bootstrap/advance(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_machine_transport/transport = target()
	return transport.advance_bootstrap(limits)

/datum/netrun_task/service_ready
	parent_type = /datum/netrun_task/continuation
	kind = "service_ready"

/datum/netrun_task/service_ready/advance(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_machine_transport/transport = target()
	if(!transport.is_ready())
		// Retain the cursor, but leave no continuation polling a closed barrier.
		transport.ready_queued = FALSE
		return TRUE
	if(!transport.ready_service_keys)
		transport.ready_service_keys = transport.pending_ready_services
		transport.pending_ready_services = list()
		transport.ready_service_cursor = 1
	var/stop = min(length(transport.ready_service_keys), transport.ready_service_cursor + 31)
	var/started = TICK_USAGE_REAL
	while(transport.ready_service_cursor <= stop)
		var/key = transport.ready_service_keys[transport.ready_service_cursor++]
		var/datum/weakref/reference = transport.ready_service_keys[key]
		var/datum/netrun_machine_service/service = reference?.resolve()
		if(!QDELETED(service) && transport.services[key] == service)
			service.network_ready()
		if(!transport.is_ready())
			transport.ready_queued = FALSE
			return TRUE
		if(TICK_DELTA_TO_MS(TICK_USAGE_REAL - started) >= 2 || TICK_USAGE > Master.current_ticklimit)
			break
	if(transport.ready_service_cursor <= length(transport.ready_service_keys))
		return FALSE
	transport.ready_service_keys = null
	transport.ready_queued = FALSE
	transport.wake_ready_services()
	return TRUE

/// Services added by a later map/template load need the same readiness contract.
/datum/netrun_task/service_initialize
	parent_type = /datum/netrun_task/continuation
	kind = "service_initialize"

/datum/netrun_task/service_initialize/advance(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_machine_service/service = target()
	var/datum/netrun_machine_transport/transport = worker.get_machine_transport()
	if(QDELETED(service) || transport.services[service.service_key()] != service)
		return TRUE
	if(!transport.is_ready())
		transport.defer_ready_service(service)
		return TRUE
	service.network_ready()
	return TRUE

/datum/netrun_machine_transport/proc/network_changed(datum/source, datum/component/netrun_node/node, flags)
	SIGNAL_HANDLER
	if(length(waiting_resolutions) && (node.node_type == NETRUN_NODE_APC || istype(node.parent, /obj/machinery/ntnet_relay)))
		wake_resolutions()

/// Registration/power restoration wakes pending discovery once, after construction unwinds.
/datum/netrun_machine_transport/proc/wake_resolutions()
	if(!bootstrap_complete || !SSnetrun.initialized || SSatoms.initialized != INITIALIZATION_INNEW_REGULAR || !length(waiting_resolutions) || wake_timer)
		return
	if(wake_queued)
		wake_again = TRUE
		return
	wake_timer = addtimer(CALLBACK(src, PROC_REF(resume_resolutions)), world.tick_lag, TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_machine_transport/proc/resume_resolutions()
	if(wake_timer)
		deltimer(wake_timer)
	wake_timer = null
	if(!length(waiting_resolutions))
		return
	if(wake_queued)
		wake_again = TRUE
		return
	wake_queued = TRUE
	SSnetrun.get_task_scheduler().enqueue("discovery_wake", src, NETRUN_TASK_BACKGROUND)
	SSnetrun.wake_ready_delivery()

/// Copying the wave and native begin() both run inside the shared MC budget.
/// A notification during a wave coalesces into one fresh snapshot afterwards.
/datum/netrun_machine_transport/proc/advance_resolutions()
	if(!is_ready())
		// The reopening barrier schedules a new wave. Do not repeatedly scan
		// thousands of waiters while map or shuttle loading keeps it closed.
		wake_queries = null
		wake_again = FALSE
		wake_queued = FALSE
		return TRUE
	if(!wake_queries)
		wake_queries = waiting_resolutions.Copy()
		wake_cursor = 1
		wake_again = FALSE
	var/stop = min(length(wake_queries), wake_cursor + 7)
	while(wake_cursor <= stop)
		var/datum/netrun_machine_resolution/query = wake_queries[wake_cursor++]
		if(!QDELETED(query) && (query in waiting_resolutions))
			query.begin()
	if(wake_cursor <= length(wake_queries))
		return FALSE
	wake_queries = null
	if(wake_again && length(waiting_resolutions))
		wake_again = FALSE
		return FALSE
	wake_again = FALSE
	wake_queued = FALSE
	return TRUE

/datum/netrun_task/discovery_wake
	parent_type = /datum/netrun_task/continuation
	kind = "discovery_wake"

/datum/netrun_task/discovery_wake/advance(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_machine_transport/transport = target()
	return transport.advance_resolutions()

/datum/netrun_machine_transport/Destroy()
	SSnetrun.task_scheduler?.cancel("network_bootstrap", src)
	SSnetrun.task_scheduler?.cancel("service_ready", src)
	SSnetrun.task_scheduler?.cancel("discovery_wake", src)
	UnregisterSignal(SSnetrun, COMSIG_NETRUN_NODE_CHANGED)
	UnregisterSignal(SSatoms, COMSIG_SUBSYSTEM_POST_INITIALIZE)
	if(wake_timer)
		deltimer(wake_timer)
	wake_queued = FALSE
	wake_queries = null
	wake_again = FALSE
	bootstrap_services = null
	ready_service_keys = null
	pending_ready_services.Cut()
	ready_queued = FALSE
	ready_services.Cut()
	QDEL_LIST(packets)
	replaceable_packets.Cut()
	clear_pair_routes()
	return ..()

/datum/netrun_machine_transport/proc/register(datum/netrun_machine_service/service)
	services[service.service_key()] = service
	if(service.start_when_ready)
		ready_services[service.service_key()] = service
		if(is_ready())
			SSnetrun.get_task_scheduler().enqueue("service_initialize", service, NETRUN_TASK_BACKGROUND)
		else
			defer_ready_service(service)
	var/list/bucket = by_id[service.service_id]
	if(!bucket)
		bucket = list()
		by_id[service.service_id] = bucket
	bucket |= service
	revision++
	service_revisions[service.service_id] = (service_revisions[service.service_id] || 0) + 1
	index_service(service)
	if(service.node?.node_type == NETRUN_NODE_APC || istype(service.host, /obj/machinery/ntnet_relay))
		wake_resolutions()

/datum/netrun_machine_transport/proc/index_service(datum/netrun_machine_service/service)
	var/tag = service.service_tag()
	if(service.indexed_tag == tag)
		return
	var/previous_key = "[service.service_id]|[service.indexed_tag]"
	var/list/previous = by_tag[previous_key]
	if(previous)
		previous -= service
	if(!length(previous))
		by_tag -= previous_key
	service.indexed_tag = tag
	if(!isnull(tag))
		var/key = "[service.service_id]|[tag]"
		var/list/bucket = by_tag[key]
		if(!bucket)
			bucket = list()
			by_tag[key] = bucket
		bucket |= service
	service_revisions[service.service_id] = (service_revisions[service.service_id] || 0) + 1

/datum/netrun_machine_transport/proc/unregister(datum/netrun_machine_service/service)
	var/key = service.service_key()
	if(ready_services[key] == service)
		ready_services -= key
	// resolve() rejects a qdel-marked service during its own Destroy(). Compare
	// its weakref identity so teardown can release only this service's demand.
	if(IS_WEAKREF_OF(service, pending_ready_services[key]))
		pending_ready_services -= key
	if(services[key] == service)
		services -= key
	var/list/bucket = by_id[service.service_id]
	if(bucket)
		bucket -= service
	var/tag_key = "[service.service_id]|[service.indexed_tag]"
	var/list/tag_bucket = by_tag[tag_key]
	if(tag_bucket)
		tag_bucket -= service
	if(!length(tag_bucket))
		by_tag -= tag_key
	revision++
	service_revisions[service.service_id] = (service_revisions[service.service_id] || 0) + 1
	for(var/datum/netrun_machine_packet/packet as anything in packets.Copy())
		if(packet.source == service || packet.recipient == service)
			packet.fail("машина отключена")

/datum/netrun_machine_transport/proc/discovery_candidates(destination_id, recipient_tag)
	var/list/bucket = isnull(recipient_tag) ? by_id[destination_id] : by_tag["[destination_id]|[recipient_tag]"]
	// Legacy tag setters can bypass the index. Return their candidate bucket
	// without scanning it here: asynchronous discovery must budget that work too.
	if(!isnull(recipient_tag) && !length(bucket))
		return by_id[destination_id]
	return bucket

/// Synchronous readers and worker continuations use the same live discovery policy.
/datum/netrun_machine_transport/proc/discoverable(datum/netrun_machine_service/source, datum/netrun_machine_service/target, recipient_tag, communications)
	if(QDELETED(source) || QDELETED(target) || !target.matches(source, recipient_tag))
		return FALSE
	if(QDELETED(source) || QDELETED(target))
		return FALSE
	if(!isnull(recipient_tag) && target.indexed_tag != recipient_tag)
		index_service(target)
	return reachable(source, target, communications)

/datum/netrun_machine_transport/proc/lookup(datum/netrun_machine_service/source, destination_id, recipient_tag, communications)
	. = list()
	if(QDELETED(source))
		return
	var/list/bucket = source.discovery_candidates(destination_id, recipient_tag)
	var/target_limit = source.discovery_target_limit(destination_id)
	for(var/datum/netrun_machine_service/target as anything in bucket)
		if(discoverable(source, target, recipient_tag, communications))
			. += target
			if(target_limit > 0 && length(.) >= target_limit)
				break

