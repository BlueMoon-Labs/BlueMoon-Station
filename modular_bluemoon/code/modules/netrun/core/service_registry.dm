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
	var/resolution_limit = 0
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
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	transport.index_service(src)
	transport.announce_service(src, "updated")

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

/datum/netrun_machine_service/proc/send_to(datum/netrun_machine_service/target, datum/netrun_machine_message/message)
	return SSnetrun.get_machine_transport().dispatch(src, target, message)

/// Read-only discovery consumes the same APC registry and physical path contract.
/datum/netrun_machine_service/proc/resolve(destination_id, recipient_tag)
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(!transport.is_ready())
		return list()
	var/datum/netrun_external_effects/machines/queries/executor = SSnetrun.external_core?.effects
	return istype(executor) ? executor.discovery_lookup(src, destination_id, recipient_tag) : list()



/datum/netrun_machine_service/proc/get_resolution(destination_id, recipient_tag)
	if(QDELETED(src) || QDELETED(host) || QDELETED(resolve_node()))
		return null
	if(SSnetrun.get_machine_transport().is_ready() && !resolve_node().is_online())
		return null
	var/query_key = "[destination_id]|[recipient_tag]"
	var/datum/netrun_machine_resolution/query = resolutions[query_key]
	if(query)
		return query
	if(resolution_limit > 0 && length(resolutions) >= resolution_limit)
		return null
	query = new /datum/netrun_machine_resolution/external(src, destination_id, recipient_tag)
	resolutions[query_key] = query
	return query

/datum/netrun_machine_service/proc/can_reach(datum/netrun_machine_service/target)
	return !QDELETED(target) && SSnetrun.get_machine_transport().reachable(src, target)

/// APC-attached services advertise in one registry; only data needs network delivery.
/datum/netrun_machine_transport
	var/list/services = list()
	var/list/ready_services = list()
	/// Weak-owner subscriptions keyed by family; events delivered on a deferred worker.
	var/list/service_subscribers = list()
	var/list/service_events = list()
	/// Coalesce repeated updates before the deferred subscriber worker sees them.
	var/list/service_event_dedupe = list()
	var/service_event_cursor = 1
	var/service_event_timer
	var/service_delivery_active = FALSE
	/// Closed readiness barriers park services without runnable polling tasks.
	var/list/pending_ready_services = list()
	var/ready_queued = FALSE
	var/list/by_id = list()
	var/list/by_tag = list()
	/// Weak keys: lookup может завершиться до своего места в уже скопированной wake-волне.
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
	var/queued_messages = 0
	var/revision = 0
	var/bootstrap_at



/datum/netrun_machine_transport/New()
	RegisterSignal(SSatoms, COMSIG_SUBSYSTEM_POST_INITIALIZE, PROC_REF(atoms_initialized))
	RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_CHANGED, PROC_REF(network_changed))

/datum/netrun_machine_transport/proc/atoms_initialized()
	SIGNAL_HANDLER
	prepare_network()

/datum/netrun_machine_transport/proc/is_ready()
	return bootstrap_complete && SSnetrun.external_core?.ready && SSnetrun.initialized && SSatoms.initialized == INITIALIZATION_INNEW_REGULAR

/datum/netrun_machine_transport/proc/prepare_network()
	if(!bootstrap_complete && !preparing && SSnetrun.initialized && SSatoms.initialized == INITIALIZATION_INNEW_REGULAR && !Master.initializing_subsystem && Master.current_runlevel)
		SSnetrun.get_task_scheduler().enqueue("network_bootstrap", src, NETRUN_TASK_BACKGROUND)
	if(is_ready())
		wake_resolutions()
		wake_ready_services()

/datum/netrun_machine_transport/proc/advance_bootstrap(datum/netrun_execution_limits/limits)
	if(preparing || Master.initializing_subsystem || SSatoms.initialized != INITIALIZATION_INNEW_REGULAR)
		return TRUE
	preparing = TRUE
	if(!bootstrap_complete)
		SSnetrun.spawn_roundstart_servers()
		if(!bootstrap_services)
			// Snapshot хранит только ID: удалённые services не удерживаются внешними references.
			bootstrap_services = list()
			for(var/key in services)
				bootstrap_services += key
			bootstrap_cursor = 1
		var/stop = length(bootstrap_services)
		while(bootstrap_cursor <= stop)
			var/key = bootstrap_services[bootstrap_cursor++]
			var/datum/netrun_machine_service/service = services[key]
			if(!QDELETED(service))
				service.host_initialized()
			if(TICK_CHECK)
				break
		if(bootstrap_cursor <= length(bootstrap_services))
			preparing = FALSE
			return FALSE
		bootstrap_services = null
		bootstrap_complete = TRUE
		bootstrap_at = world.time
	preparing = FALSE
	if(is_ready())
		wake_resolutions()
		wake_ready_services()
	return TRUE

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
	var/stop = length(transport.ready_service_keys)
	while(transport.ready_service_cursor <= stop)
		var/key = transport.ready_service_keys[transport.ready_service_cursor++]
		var/datum/weakref/reference = transport.ready_service_keys[key]
		var/datum/netrun_machine_service/service = reference?.resolve()
		if(!QDELETED(service) && transport.services[key] == service)
			service.network_ready()
		if(!transport.is_ready())
			transport.ready_queued = FALSE
			return TRUE
		if(TICK_CHECK)
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
	var/stop = length(wake_queries)
	while(wake_cursor <= stop)
		var/datum/weakref/reference = wake_queries[wake_cursor]
		// Начатый lookup может завершиться раньше остальной волны. Не удерживаем
		// его ключ в snapshot до окончания чужих worker slices и следующего GC.
		wake_queries[wake_cursor++] = null
		var/datum/netrun_machine_resolution/query = reference?.resolve()
		if(istype(query) && (reference in waiting_resolutions))
			query.begin()
		else if(reference)
			waiting_resolutions -= reference
		if(TICK_CHECK)
			break
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
	if(service_event_timer)
		deltimer(service_event_timer)
	service_event_timer = null
	service_events.Cut()
	service_event_dedupe.Cut()
	for(var/family in service_subscribers)
		var/list/watchers = service_subscribers[family]
		for(var/datum/netrun_service_subscription/watch as anything in watchers.Copy())
			qdel(watch)
	service_subscribers.Cut()
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
	announce_service(service, "added")
	if(service.node?.node_type == NETRUN_NODE_APC || istype(service.host, /obj/machinery/ntnet_relay))
		wake_resolutions()

/datum/netrun_machine_transport/proc/index_service(datum/netrun_machine_service/service)
	// Owner/component replacement и native state важны даже когда recipient tag не поменялся.
	SSnetrun.external_core?.observe_service(service)
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
	announce_service(service, "updated")

/datum/netrun_machine_transport/proc/unregister(datum/netrun_machine_service/service)
	// Export and notify before service loses its stable identity; listener receives a tombstone.
	announce_service(service, "removed")
	SSnetrun.external_core?.forget_service(service)
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


/// Subscription callbacks are local observation, not proof of network reachability.
/// Never use them as authorization for machine receive or remote route access.
/datum/proc/netrun_service_changed(event, family, tag, identity, datum/netrun_machine_service/service)
	return

/// Explicit subscription handle. Owner and service events are weak; qdel(handle) unsubscribes.
/datum/netrun_service_subscription
	var/datum/netrun_machine_transport/registry
	var/datum/weakref/subscriber_ref
	var/family
	var/tag

/datum/netrun_service_subscription/New(datum/netrun_machine_transport/registry, datum/subscriber, family, tag)
	..()
	src.registry = registry
	subscriber_ref = WEAKREF(subscriber)
	src.family = family
	src.tag = tag
	RegisterSignal(subscriber, COMSIG_PARENT_QDELETING, PROC_REF(on_subscriber_deleted))

/datum/netrun_service_subscription/proc/on_subscriber_deleted()
	SIGNAL_HANDLER
	qdel(src)

/datum/netrun_service_subscription/Destroy()
	var/datum/subscriber = subscriber_ref?.resolve()
	if(subscriber)
		UnregisterSignal(subscriber, COMSIG_PARENT_QDELETING)
	var/list/watchers = registry?.service_subscribers[family]
	if(watchers)
		watchers -= src
		if(!length(watchers))
			registry.service_subscribers -= family
	registry = null
	subscriber_ref = null
	return ..()

/// Subscribe to one family (and optional tag); replay existing matching services once.
/// Events: added, updated, removed. Removed events carry identity but a null live service.
/datum/netrun_machine_transport/proc/subscribe_service(datum/subscriber, family, tag = null, replay = TRUE)
	if(QDELETED(subscriber) || !istext(family) || !length(family) || !isnull(tag) && !istext(tag))
		return null
	var/datum/netrun_service_subscription/watch = new(src, subscriber, family, tag)
	var/list/watchers = service_subscribers[family]
	if(!watchers)
		watchers = list()
		service_subscribers[family] = watchers
	watchers += watch
	if(replay)
		var/list/existing = by_id[family]
		for(var/datum/netrun_machine_service/service as anything in existing)
			if(!QDELETED(service) && services[service.service_key()] == service)
				enqueue_service_event(watch, service, "added")
	return watch

/// One short event per interested subscriber; no station-wide scan at each mutation.
/datum/netrun_machine_transport/proc/announce_service(datum/netrun_machine_service/service, event = "updated")
	if(QDELETED(src) || !service || !(event in list("added", "updated", "removed")))
		return
	var/list/watchers = service_subscribers[service.service_id]
	if(!length(watchers))
		return
	for(var/datum/netrun_service_subscription/watch as anything in watchers.Copy())
		enqueue_service_event(watch, service, event)

/datum/netrun_machine_transport/proc/enqueue_service_event(datum/netrun_service_subscription/watch, datum/netrun_machine_service/service, event)
	if(QDELETED(watch) || !service || !isnull(watch.tag) && watch.tag != service.service_tag())
		return
	var/datum/subscriber = watch.subscriber_ref?.resolve()
	if(QDELETED(subscriber))
		return
	var/key = json_encode(list(REF(watch), service.service_key(), event))
	if(service_event_dedupe[key])
		return
	service_event_dedupe[key] = TRUE
	service_events += list(list("watch" = WEAKREF(watch), "service" = WEAKREF(service), "event" = event, "family" = service.service_id, "tag" = service.service_tag(), "identity" = service.service_key(), "dedupe" = key))
	if(!service_delivery_active && !service_event_timer)
		service_event_timer = addtimer(CALLBACK(src, PROC_REF(deliver_service_events)), world.tick_lag, TIMER_STOPPABLE | TIMER_DELETE_ME)

/// Deferred delivery means service Destroy/signals never run arbitrary subscriber callbacks inline.
/datum/netrun_machine_transport/proc/deliver_service_events()
	set waitfor = FALSE
	if(service_delivery_active)
		return
	service_event_timer = null
	service_delivery_active = TRUE
	while(service_event_cursor <= length(service_events))
		CHECK_TICK
		var/list/notice = service_events[service_event_cursor]
		service_events[service_event_cursor++] = null
		service_event_dedupe -= notice["dedupe"]
		var/datum/weakref/watch_ref = notice["watch"]
		var/datum/netrun_service_subscription/watch = watch_ref?.resolve()
		var/datum/subscriber = watch?.subscriber_ref?.resolve()
		if(!QDELETED(watch) && !QDELETED(subscriber) && watch.registry == src)
			var/datum/weakref/service_ref = notice["service"]
			var/datum/netrun_machine_service/service = service_ref?.resolve()
			if(notice["event"] == "removed")
				service = null
			else if(QDELETED(service) || services[notice["identity"]] != service)
				continue
			subscriber.netrun_service_changed(notice["event"], notice["family"], notice["tag"], notice["identity"], service)
		if(TICK_CHECK)
			sleep(0)
	service_events.Cut()
	service_event_cursor = 1
	service_delivery_active = FALSE
