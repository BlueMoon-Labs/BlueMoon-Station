/// Research information is copied only by delivered machine packets. A holder's
/// logical techweb selects its server; it never replaces physical APC routing.

/datum/techweb/proc/has_research_owner(obj/machinery/rnd/server/server)
	var/datum/weakref/reference = research_owner_refs[REF(server)]
	return !QDELETED(server) && reference?.resolve() == server

/datum/techweb/proc/add_research_owner(obj/machinery/rnd/server/server)
	research_owner_refs[REF(server)] = WEAKREF(server)
	var/obj/machinery/rnd/server/current_owner = research_owner_ref?.resolve()
	if(QDELETED(current_owner))
		research_owner_ref = WEAKREF(server)

/datum/techweb/proc/remove_research_owner(obj/machinery/rnd/server/server)
	research_owner_refs -= REF(server)
	research_owner_ref = null
	for(var/key in research_owner_refs.Copy())
		var/datum/weakref/reference = research_owner_refs[key]
		var/obj/machinery/rnd/server/remaining = reference?.resolve()
		if(QDELETED(remaining) || remaining.stored_research != src)
			research_owner_refs -= key
		else if(!research_owner_ref)
			research_owner_ref = reference
	if(!length(research_owner_refs))
		qdel(src)

/// An explicit binding merges physical server groups, never a presentation cache.
/// A group is one shared database: partitions do not create divergent replicas.
/obj/machinery/rnd/server/proc/link_research_cluster(datum/techweb/target)
	var/datum/techweb/previous = stored_research
	if(QDELETED(target) || QDELETED(previous) || target == previous || !length(target.research_owner_refs))
		return FALSE
	var/datum/netrun_machine_service/research_server/source_service = get_netrun_machine_service("research.server")
	var/reachable = FALSE
	for(var/key in target.research_owner_refs)
		var/datum/weakref/reference = target.research_owner_refs[key]
		var/obj/machinery/rnd/server/peer = reference?.resolve()
		if(!QDELETED(peer) && peer.netrun_online() && source_service.can_reach(peer.get_netrun_machine_service("research.server")))
			reachable = TRUE
			break
	if(!reachable)
		return FALSE
	// Merge sets directly: replaying research_node would pay science bounties twice.
	for(var/field in list("researched_nodes", "researched_designs", "custom_designs", "visible_nodes", "available_nodes", "discovered_mutations", "synthesized_gases"))
		target.vars[field] |= previous.vars[field]
	target.hidden_nodes &= previous.hidden_nodes
	for(var/field in list("research_points", "next_income", "last_bitcoins"))
		var/list/incoming = previous.vars[field]
		var/list/balance = target.vars[field]
		for(var/point_type in incoming)
			balance[point_type] += incoming[point_type]
	for(var/field in list("boosted_nodes", "deconstructed_items"))
		var/list/incoming = previous.vars[field]
		var/list/known = target.vars[field]
		for(var/id in incoming)
			if(!islist(incoming[id]))
				continue
			if(!islist(known[id]))
				known[id] = list()
			for(var/point_type in incoming[id])
				known[id][point_type] = max(known[id][point_type], incoming[id][point_type])
	for(var/key in previous.largest_values)
		target.largest_values[key] = max(target.largest_values[key], previous.largest_values[key])
	target.problem_computer_charges = min(target.get_problem_computer_charges(), previous.get_problem_computer_charges())
	target.problem_computer_last_charge_time = max(target.problem_computer_last_charge_time, previous.problem_computer_last_charge_time)
	target.research_logs += previous.research_logs
	var/list/affected = target.researched_nodes | target.visible_nodes | target.available_nodes
	for(var/id in affected)
		target.update_node_status(SSresearch.techweb_node_by_id(id), FALSE)
	previous.research_successor_ref = WEAKREF(target)
	for(var/key in previous.research_owner_refs)
		var/datum/weakref/reference = previous.research_owner_refs[key]
		var/obj/machinery/rnd/server/member = reference?.resolve()
		if(QDELETED(member))
			continue
		target.add_research_owner(member)
		SEND_SIGNAL(member, COMSIG_ATOM_SET_TECHWEB, target)
	previous.research_owner_refs.Cut()
	qdel(previous)
	target.netrun_research_changed()
	SSresearch.refresh_research_authorities()
	return TRUE
/atom/netrun_machine_service_types()
	. = ..()
	if(GetComponent(/datum/component/techweb_holder) && !istype(src, /obj/machinery/rnd/server))
		. |= /datum/netrun_machine_service/research_client

/// Selection may inspect physical connectivity; data still travels through the APC registry and data packets.
/proc/netrun_research_route_available(atom/source, obj/machinery/rnd/server/server)
	if(QDELETED(source) || QDELETED(server) || !server.netrun_online())
		return FALSE
	var/datum/component/netrun_node/source_node = source.netrun_machine_service_node()
	var/datum/component/netrun_node/server_node = server.netrun_machine_service_node()
	if(!source_node || !server_node)
		return FALSE
	var/datum/netrun_machine_service/client = source.get_netrun_machine_service(istype(source, /obj/machinery/rnd/server) ? "research.server" : "research.client")
	var/datum/netrun_machine_service/research_server/authority = server.get_netrun_machine_service("research.server")
	if(!client || !authority || !SSnetrun.get_machine_transport().is_ready())
		return FALSE
	return client.can_reach(authority)

/// Revalidate grants at the native resource/technology boundary, including route loss.
/proc/netrun_research_authorizes(atom/source, datum/techweb/web, design_id)
	if(QDELETED(source) || QDELETED(web) || netrun_atom_techweb(source) != web)
		return FALSE
	var/datum/netrun_machine_service/research_client/client = source.get_netrun_machine_service("research.client")
	if(client?.live_authority() != web)
		return FALSE
	return !design_id || web.researched_designs[design_id]

/atom/proc/netrun_research_snapshot()
	RETURN_TYPE(/datum/techweb)
	var/datum/netrun_machine_service/research_client/client = get_netrun_machine_service("research.client")
	if(!client)
		return null
	if(client.live_authority())
		if(istype(src, /obj/machinery/computer/rdconsole))
			var/obj/machinery/computer/rdconsole/console = src
			return console.netrun_research_cache
		if(istype(src, /obj/machinery/rnd/production))
			var/obj/machinery/rnd/production/production = src
			return production.stored_research
		if(istype(src, /obj/machinery/mecha_part_fabricator))
			var/obj/machinery/mecha_part_fabricator/fabricator = src
			return fabricator.stored_research
		if(client.snapshot_cache)
			return client.snapshot_cache
	client.request()
	return null

/atom/proc/netrun_research_request(operation, list/data, mob/user)
	var/datum/netrun_machine_service/research_client/client = get_netrun_machine_service("research.client")
	return client?.request(operation, user, data)
/obj/machinery/rnd/server/netrun_machine_service_types()
	. = ..()
	. |= /datum/netrun_machine_service/research_server

/obj/machinery/computer/rdconsole/netrun_machine_service_types()
	. = ..()
	. |= /datum/netrun_machine_service/research_client

/obj/machinery/rnd/production/netrun_machine_service_types()
	. = ..()
	. |= /datum/netrun_machine_service/research_client

/obj/machinery/mecha_part_fabricator/netrun_machine_service_types()
	. = ..()
	. |= /datum/netrun_machine_service/research_client

/datum/netrun_machine_message/research/failed(reason)
	var/datum/netrun_machine_service/research_client/client = requester_ref?.resolve()
	client?.finish_design(payload["design_token"], null)
	var/mob/user = user_ref?.resolve()
	if(user)
		to_chat(user, span_warning("Исследовательский пакет не доставлен: [reason]."))

/datum/netrun_machine_message/research
	var/datum/weakref/requester_ref

/datum/netrun_machine_message/research/copy()
	var/datum/netrun_machine_message/research/result = ..()
	result.requester_ref = requester_ref
	return result

/datum/netrun_machine_message/research/coalescing_key()
	var/requested = payload["requested_operation"]
	if(requested && !(requested in list("snapshot", "watch")))
		return null
	// Compact balances cannot replace a full catalogue still in flight.
	if(payload["operation"] in list("snapshot", "state", "watch"))
		return "research.[payload["operation"]]|[payload["binding"]]|[payload["generation"]]"
	return null

/datum/netrun_machine_message/research/can_replace(datum/netrun_machine_message/previous)
	var/revision = payload["revision"]
	var/previous_revision = previous.payload["revision"]
	if(isnum(revision) && isnum(previous_revision))
		return revision >= previous_revision
	return ..()

/datum/netrun_machine_service/research_server
	service_id = "research.server"
	start_when_ready = TRUE
	var/datum/techweb/web
	var/list/subscribers = list()
	var/publish_timer
	var/list/publish_addresses
	var/list/publish_data
	var/list/publish_state
	var/publish_cursor = 1
	var/publish_again = FALSE
	/// Startup joins are resumable and coalesced on the service, never on a task.
	var/cluster_listening = FALSE
	var/cluster_queued = FALSE
	var/list/cluster_candidates
	var/cluster_cursor = 1
	var/cluster_again = FALSE
	var/cluster_infrastructure = -1
	var/cluster_transit = -1
	var/cluster_backbone = -1
	var/cluster_online

/datum/netrun_machine_service/research_server/New(datum/component/netrun_node/node, atom/host_override)
	..(node, host_override)
	bind_research()
	queue_cluster()

/datum/netrun_machine_service/research_server/network_ready()
	queue_cluster()

/datum/netrun_machine_service/research_server/host_initialized()
	. = ..()
	queue_cluster()

/datum/netrun_machine_service/research_server/proc/queue_cluster()
	var/obj/machinery/rnd/server/server = host
	if(QDELETED(server) || !server.netrun_mapped_server)
		return
	cluster_online = server.netrun_online()
	if(!cluster_listening)
		cluster_listening = TRUE
		RegisterSignal(host, list(COMSIG_MACHINERY_POWER_LOST, COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED, COMSIG_MOVABLE_MOVED), PROC_REF(cluster_state_changed))
		RegisterSignal(SSnetrun, list(COMSIG_NETRUN_TOPOLOGY_DIRTY, COMSIG_NETRUN_TOPOLOGY_CHANGED), PROC_REF(cluster_topology_changed))
		RegisterSignal(SSnetrun, COMSIG_NETRUN_NODE_CHANGED, PROC_REF(cluster_node_changed))
	var/datum/netrun_machine_transport/transport = SSnetrun.get_machine_transport()
	if(!transport.is_ready())
		transport.defer_ready_service(src)
		return
	if(cluster_queued)
		cluster_again = TRUE
		return
	cluster_queued = TRUE
	SSnetrun.get_task_scheduler().enqueue("research.cluster", src, NETRUN_TASK_BACKGROUND)

/datum/netrun_machine_service/research_server/proc/cluster_state_changed()
	SIGNAL_HANDLER
	queue_cluster()

/datum/netrun_machine_service/research_server/proc/cluster_topology_changed()
	SIGNAL_HANDLER
	var/obj/machinery/rnd/server/server = host
	if(QDELETED(server))
		return
	var/datum/netrun_topology/graph = SSnetrun.get_topology()
	var/backbone = !!SSnetworks.station_network?.setting_disabled
	if(cluster_infrastructure == graph.infrastructure_revision && cluster_transit == graph.transit_availability_revision && cluster_backbone == backbone && cluster_online == server.netrun_online())
		return
	cluster_infrastructure = graph.infrastructure_revision
	cluster_transit = graph.transit_availability_revision
	cluster_backbone = backbone
	queue_cluster()

/datum/netrun_machine_service/research_server/proc/cluster_node_changed(datum/source, datum/component/netrun_node/changed_node, flags)
	SIGNAL_HANDLER
	var/obj/machinery/rnd/server/server = host
	if(changed_node == node && ((flags & NETRUN_CHANGED_BINDING) || cluster_online != server.netrun_online()))
		queue_cluster()
	else if(SSnetrun.get_topology().is_infrastructure(changed_node))
		cluster_topology_changed()

/datum/netrun_machine_service/research_server/proc/finish_cluster()
	SSnetrun.task_scheduler?.cancel("research.cluster", src)
	cluster_queued = FALSE
	cluster_candidates = null
	cluster_cursor = 1
	cluster_again = FALSE

/// One peer comparison and at most one merge per common-worker continuation.
/datum/netrun_machine_service/research_server/proc/advance_cluster()
	var/obj/machinery/rnd/server/server = host
	if(QDELETED(server) || !server.netrun_mapped_server || !server.netrun_online())
		finish_cluster()
		return TRUE
	if(!SSnetrun.get_machine_transport().is_ready())
		finish_cluster()
		SSnetrun.get_machine_transport().defer_ready_service(src)
		return TRUE
	if(!cluster_candidates)
		cluster_candidates = SSresearch.servers.Copy()
		cluster_cursor = 1
		cluster_again = FALSE
	if(cluster_cursor <= length(cluster_candidates))
		var/obj/machinery/rnd/server/peer = cluster_candidates[cluster_cursor++]
		if(peer != server && !QDELETED(peer) && peer.netrun_mapped_server && peer.stored_research != server.stored_research && peer.research_network_id() == server.research_network_id() && server.link_research_cluster(peer.stored_research))
			finish_cluster()
			return TRUE
	if(cluster_cursor <= length(cluster_candidates))
		return FALSE
	if(cluster_again)
		cluster_candidates = null
		cluster_again = FALSE
		return FALSE
	finish_cluster()
	return TRUE

/datum/netrun_task/research_cluster
	parent_type = /datum/netrun_task/continuation
	kind = "research.cluster"

/datum/netrun_task/research_cluster/advance(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_machine_service/research_server/service = target()
	return service.advance_cluster()

/datum/netrun_machine_service/research_server/Destroy()
	finish_cluster()
	if(cluster_listening)
		UnregisterSignal(host, list(COMSIG_MACHINERY_POWER_LOST, COMSIG_MACHINERY_POWER_RESTORED, COMSIG_MACHINERY_STAT_CHANGED, COMSIG_MOVABLE_MOVED))
		UnregisterSignal(SSnetrun, list(COMSIG_NETRUN_TOPOLOGY_DIRTY, COMSIG_NETRUN_TOPOLOGY_CHANGED, COMSIG_NETRUN_NODE_CHANGED))
		cluster_listening = FALSE
	if(publish_timer)
		deltimer(publish_timer)
	if(web)
		UnregisterSignal(web, COMSIG_NETRUN_RESEARCH_CHANGED)
	SSnetrun.get_task_scheduler().cancel("research.publish", src)
	publish_addresses = null
	publish_data = null
	publish_state = null
	web = null
	subscribers.Cut()
	return ..()

/datum/netrun_machine_service/research_server/service_tag()
	var/obj/machinery/rnd/server/server = host
	return server.stored_research ? REF(server.stored_research) : null

/// Explicitly linked physical servers may answer for the same authority.
/datum/netrun_machine_service/research_server/matches(datum/netrun_machine_service/source_service, recipient_tag)
	return ..() && research_peer(source_service)

/datum/netrun_machine_service/research_server/proc/bind_research()
	var/obj/machinery/rnd/server/server = host
	if(web == server.stored_research)
		return
	if(web)
		UnregisterSignal(web, COMSIG_NETRUN_RESEARCH_CHANGED)
	web = server.stored_research
	subscribers.Cut()
	publish_addresses = null
	publish_data = null
	publish_state = null
	publish_again = FALSE
	if(web)
		RegisterSignal(web, COMSIG_NETRUN_RESEARCH_CHANGED, PROC_REF(on_research_changed))

/datum/netrun_machine_service/research_server/proc/on_research_changed(datum/source)
	SIGNAL_HANDLER
	if(!length(subscribers))
		return
	if(!publish_timer)
		publish_timer = addtimer(CALLBACK(src, PROC_REF(publish)), 1.5 SECONDS, TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_machine_service/research_server/proc/snapshot()
	return list("operation" = "snapshot", "binding" = REF(web), "revision" = web.netrun_research_revision, "catalog_revision" = web.netrun_research_catalog_revision, "organization" = web.organization,
		"researched_nodes" = web.researched_nodes.Copy(), "researched_designs" = web.researched_designs.Copy(),
		"available_nodes" = web.available_nodes.Copy(), "tiers" = web.tiers.Copy(),
		"custom_designs" = web.custom_designs.Copy(), "hidden_nodes" = web.hidden_nodes.Copy(),
		"visible_nodes" = web.visible_nodes.Copy(), "boosted_nodes" = deepCopyList(web.boosted_nodes),
		"research_points" = web.research_points.Copy(), "last_bitcoins" = web.last_bitcoins.Copy(),
		"discovered_mutations" = web.discovered_mutations.Copy(), "deconstructed_items" = web.deconstructed_items.Copy(),
		"problem_computer_charges" = web.get_problem_computer_charges(), "problem_computer_max_charges" = web.problem_computer_max_charges)

/// A balance update carries values from the same immutable publication snapshot.
/// It never recopies recipe sets or forces native consumers to rebuild them.
/datum/netrun_machine_service/research_server/proc/snapshot_state(list/data)
	return list("operation" = "state", "binding" = data["binding"], "revision" = data["revision"], "catalog_revision" = data["catalog_revision"],
		"organization" = data["organization"], "research_points" = data["research_points"], "last_bitcoins" = data["last_bitcoins"],
		"problem_computer_charges" = data["problem_computer_charges"], "problem_computer_max_charges" = data["problem_computer_max_charges"])

/datum/netrun_machine_service/research_server/proc/publish()
	publish_timer = null
	bind_research()
	if(!web || !length(subscribers))
		return
	if(publish_addresses)
		publish_again = TRUE
		return
	publish_addresses = subscribers.Copy()
	publish_cursor = 1
	SSnetrun.get_task_scheduler().enqueue("research.publish", src, NETRUN_TASK_BACKGROUND)

/// One peer per continuation keeps full catalogue copies behind the worker budget.
/datum/netrun_machine_service/research_server/proc/publish_batch(datum/controller/subsystem/netrun/worker)
	if(QDELETED(web) || !publish_addresses)
		return TRUE
	if(!publish_data)
		publish_data = snapshot()
		publish_state = snapshot_state(publish_data)
	var/stop = min(length(publish_addresses), publish_cursor)
	while(publish_cursor <= stop)
		var/address = publish_addresses[publish_cursor++]
		var/list/subscription = subscribers[address]
		if(!subscription)
			continue
		var/datum/weakref/reference = subscription["client"]
		var/datum/netrun_machine_service/research_client/client = reference?.resolve()
		if(QDELETED(client) || !research_peer(client) || client.binding_generation != subscription["generation"])
			subscribers -= address
			continue
		var/datum/netrun_machine_service/research_server/current = client.subscription_ref?.resolve()
		if(!QDELETED(current) && current != src)
			subscribers -= address
			continue
		if(subscription["revision"] == publish_data["revision"])
			continue
		var/list/data = subscription["catalog_revision"] == publish_data["catalog_revision"] ? publish_state : publish_data
		data["generation"] = subscription["generation"]
		// Message construction already owns a deep copy of its payload.
		if(send_to(client, new /datum/netrun_machine_message/research(data)))
			subscription["revision"] = publish_data["revision"]
			subscription["catalog_revision"] = publish_data["catalog_revision"]
	if(publish_cursor <= length(publish_addresses))
		return FALSE
	else
		publish_addresses = null
		publish_data = null
		publish_state = null
		if(publish_again)
			publish_again = FALSE
			publish()
	return TRUE

/datum/netrun_task/research_publish
	parent_type = /datum/netrun_task/continuation
	kind = "research.publish"

/datum/netrun_task/research_publish/advance(datum/controller/subsystem/netrun/worker, datum/netrun_execution_limits/limits)
	var/datum/netrun_machine_service/research_server/service = target()
	return service.publish_batch(worker)

/datum/netrun_machine_service/research_server/proc/research_peer(datum/netrun_machine_service/peer)
	return peer?.service_id == "research.client" && !QDELETED(web) && web.has_research_owner(host) && netrun_atom_techweb(peer.host) == web

/datum/netrun_machine_service/research_server/accepts(datum/netrun_machine_message/message)
	bind_research()
	var/datum/netrun_machine_service/research_client/client = message.source
	return ..() && research_peer(client) && message.payload["binding"] == REF(web) && message.payload["generation"] == client.binding_generation

/datum/netrun_machine_service/research_server/receive(datum/netrun_machine_message/message)
	if(!accepts(message))
		return FALSE
	var/operation = message.payload["operation"]
	if(operation in list("snapshot", "watch"))
		subscribers[message.source.node.address] = list("client" = WEAKREF(message.source), "generation" = message.payload["generation"], "revision" = web.netrun_research_revision, "catalog_revision" = web.netrun_research_catalog_revision)
	var/success = TRUE
	if(operation == "watch")
		if(message.payload["revision"] == web.netrun_research_revision)
			message.reply(new /datum/netrun_machine_message/research(list("operation" = "current", "binding" = REF(web), "revision" = web.netrun_research_revision, "generation" = message.payload["generation"])))
			return TRUE
		operation = "snapshot"
	if(operation == "design")
		var/id = message.payload["design_id"]
		message.reply(new /datum/netrun_machine_message/research(list("operation" = "design", "binding" = REF(web), "generation" = message.payload["generation"], "design_token" = message.payload["design_token"], "design_id" = id, "success" = !!web.researched_designs[id])))
		return TRUE
	if(operation == "credit")
		web.add_point_list(message.payload["points"])
		// Delivery already has an outcome; credit-only telemetry needs no database reply.
		return TRUE
	if(operation == "artifact")
		var/obj/item/xenoarch/help/research/tool = message.source.host
		var/mob/living/user = message.user_ref?.resolve()
		var/obj/item/artifact = locate(message.payload["artifact"])
		if(!istype(tool) || !istype(user) || QDELETED(artifact) || !(tool in user.contents) || user.incapacitated() || !user.Adjacent(artifact))
			return FALSE
		var/points = artifact.netrun_artifact_research_points()
		if(!points)
			return FALSE
		// Identity and value come from the real artifact; duplicated packets cannot replay it.
		qdel(artifact)
		web.add_point_type(TECHWEB_POINT_TYPE_GENERIC, points)
		to_chat(user, span_notice("Артефакт исследован: получено [points] очков исследований."))
		return TRUE
	if(operation == "explosion")
		var/obj/machinery/doppler_array/research/sensor = message.source.host
		var/value = message.payload["value"]
		if(!istype(sensor) || !isnum(value) || value <= 0)
			return FALSE
		var/previous = web.largest_values[LARGEST_BOMB] || 0
		if(value > previous)
			var/points = value - previous
			web.largest_values[LARGEST_BOMB] = value
			web.add_point_type(TECHWEB_POINT_TYPE_DEFAULT, points)
			var/datum/bank_account/account = SSeconomy.get_dep_account(ACCOUNT_SCI)
			account?.adjust_money(points)
			sensor.say("Explosion analyzed: [points] research points and credits received.")
		else
			sensor.say("Data already captured. Aborting.")
		operation = "snapshot"
	if(operation == "problem")
		var/obj/item/computermath/science/computer = message.source.host
		var/mob/user = message.user_ref?.resolve()
		if(!istype(computer) || QDELETED(user) || !(message.payload["difficulty"] in list("Easy", "Medium", "Hard")))
			return FALSE
		if(web.consume_problem_computer_charge())
			computer.handle_reward(user, "Science", !!message.payload["correct"], message.payload["difficulty"], web)
		else
			computer.last_points = 0
			computer.last_message = "На сервере закончились задачи."
		web.netrun_research_changed()
		SStgui.update_uis(computer)
		operation = "snapshot"
	if(operation == "mutation")
		var/path = message.payload["mutation"]
		if(!ispath(path, /datum/mutation/human))
			return FALSE
		web.discovered_mutations |= path
		web.netrun_research_changed()
		operation = "snapshot"
	if(operation != "snapshot")
		var/obj/machinery/computer/rdconsole/console = message.source.host
		var/mob/user = message.user_ref?.resolve()
		if(!istype(console) || QDELETED(user) || console.locked)
			return FALSE
		switch(operation)
			if("research")
				if(!console.research_control)
					return FALSE
				success = console.perform_research_node(message.payload["node_id"], user, web)
			if("analyze")
				success = console.perform_research_analysis(message.payload, user, web)
			if("boost")
				var/datum/techweb_node/node = SSresearch.techweb_node_by_id(message.payload["node_id"])
				success = web.boost_with_path(node, message.payload["item_type"])
			if("upload_nodes")
				var/list/ids = message.payload["nodes"]
				if(!islist(ids))
					return FALSE
				for(var/id in ids)
					if(SSresearch.techweb_nodes[id] && !web.researched_nodes[id])
						web.research_node_id(id, TRUE, FALSE)
				var/list/design_ids = message.payload["designs"]
				for(var/id in design_ids)
					web.add_design_by_id(id, TRUE)
				web.netrun_research_changed()
			if("upload_designs")
				var/list/ids = message.payload["designs"]
				if(!islist(ids))
					return FALSE
				for(var/id in ids)
					var/datum/design/design = SSresearch.techweb_design_by_id(id)
					if(istype(design))
						web.add_design(design, TRUE)
				web.netrun_research_changed()
			if("download_disk")
				// The response carries copied data; a changed/ejected disk is not overwritten.
				success = TRUE
			else
				return FALSE
	var/list/data = snapshot()
	data["generation"] = message.payload["generation"]
	data["success"] = success
	data["requested_operation"] = operation
	data["disk"] = message.payload["disk"]
	var/datum/netrun_machine_message/research/response = new(data)
	response.user_ref = message.user_ref
	message.reply(response)
	return TRUE

/datum/netrun_machine_service/research_client
	service_id = "research.client"
	start_when_ready = TRUE
	// Binding is automatic; full database replication starts only when a native
	// reader requests it. Point producers do not need a presentation cache.
	var/wants_snapshots = FALSE
	var/binding_generation = 0
	var/datum/techweb/snapshot_cache
	var/list/pending_designs = list()
	var/design_serial = 0
	var/snapshot_binding
	var/snapshot_revision = -1
	var/snapshot_catalog_revision = -1
	var/datum/weakref/subscription_ref
	var/resync_timer

/datum/netrun_machine_service/research_client/New(datum/component/netrun_node/node, atom/host_override)
	..(node, host_override)
	RegisterSignal(host, COMSIG_ATOM_TECHWEB_CHANGED, PROC_REF(binding_changed))
	resync_timer = addtimer(CALLBACK(src, PROC_REF(check_subscription)), 30 SECONDS, TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_machine_service/research_client/Destroy()
	if(resync_timer)
		deltimer(resync_timer)
	if(host)
		UnregisterSignal(host, COMSIG_ATOM_TECHWEB_CHANGED)
	for(var/token in pending_designs.Copy())
		finish_design(token, null)
	QDEL_NULL(snapshot_cache)
	subscription_ref = null
	return ..()

/datum/netrun_machine_service/research_client/network_ready()
	// Native cached consumers request their own presentation when binding changes.
	// A producer such as a Tesla coil only needs the authority reference.
	resolve_binding()

/datum/netrun_machine_service/research_client/proc/binding_changed(datum/source, datum/techweb/new_web)
	SIGNAL_HANDLER
	binding_generation++
	for(var/token in pending_designs.Copy())
		finish_design(token, null)
	QDEL_NULL(snapshot_cache)
	snapshot_binding = null
	snapshot_revision = -1
	snapshot_catalog_revision = -1
	subscription_ref = null
	if(wants_snapshots)
		INVOKE_ASYNC(src, PROC_REF(request))

/datum/netrun_machine_service/research_client/proc/resolve_binding()
	var/datum/techweb/binding = netrun_atom_techweb(host)
	if(binding)
		return binding
	var/datum/component/techweb_holder/holder = host.GetComponent(/datum/component/techweb_holder)
	if(!holder || holder.had_authority)
		return null
	var/selector = ("network_id" in host.vars) ? host.vars["network_id"] : RND_NETWORK_AUTO
	binding = SSresearch.get_rnd_network_for(host, selector)
	if(binding)
		SEND_SIGNAL(host, COMSIG_ATOM_SET_TECHWEB, binding)
	return binding

/datum/netrun_machine_service/research_client/proc/live_authority()
	var/datum/techweb/binding = resolve_binding()
	if(QDELETED(binding))
		return null
	for(var/key in binding.research_owner_refs)
		var/datum/weakref/reference = binding.research_owner_refs[key]
		var/obj/machinery/rnd/server/owner = reference?.resolve()
		if(!QDELETED(owner) && owner.netrun_online() && can_reach(owner.get_netrun_machine_service("research.server")))
			return binding
	return null

/// A shared authority is unicast: broadcasting mutations would credit/debit it twice.
/datum/netrun_machine_service/research_client/discovery_target_limit(destination_id)
	return destination_id == "research.server" ? 1 : ..()

/datum/netrun_machine_service/research_client/select_targets(destination_id, list/targets)
	return destination_id == "research.server" && length(targets) ? list(targets[1]) : targets

/// One design request yields one grant; no retry can replay native resource consumption.
/datum/netrun_machine_service/research_client/proc/request_design(design_id, datum/callback/complete)
	if(!live_authority() || length(pending_designs) >= 1)
		qdel(complete)
		return FALSE
	var/token = "[binding_generation]:[++design_serial]"
	pending_designs[token] = list("design" = design_id, "complete" = complete)
	addtimer(CALLBACK(src, PROC_REF(finish_design), token, null), 5 SECONDS)
	if(request("design", extra = list("design_id" = design_id, "design_token" = token)))
		return TRUE
	finish_design(token, null)
	return FALSE

/datum/netrun_machine_service/research_client/proc/finish_design(token, datum/techweb/granted)
	if(!istext(token))
		return
	var/list/pending = pending_designs[token]
	if(!pending)
		return
	pending_designs -= token
	var/datum/callback/complete = pending["complete"]
	complete?.Invoke(granted)
	qdel(complete)

/// A small revision watch repairs missed pushes, including outages between checks.
/// Full snapshots are returned only when the local revision differs.
/datum/netrun_machine_service/research_client/proc/check_subscription()
	resync_timer = null
	var/datum/techweb/binding = resolve_binding()
	if(!binding && istype(host, /obj/machinery/mecha_part_fabricator))
		var/obj/machinery/mecha_part_fabricator/fabricator = host
		fabricator.sync(TRUE, TRUE)
	if(binding && wants_snapshots)
		request("watch", extra = list("revision" = snapshot_binding == REF(binding) ? snapshot_revision : -1))
	resync_timer = addtimer(CALLBACK(src, PROC_REF(check_subscription)), 30 SECONDS, TIMER_STOPPABLE | TIMER_DELETE_ME)

/datum/netrun_machine_service/research_client/proc/request(operation = "snapshot", mob/user, list/extra)
	if(QDELETED(host))
		return FALSE
	if(operation in list("snapshot", "watch"))
		wants_snapshots = TRUE
	var/datum/techweb/binding = resolve_binding()
	if(!binding)
		return FALSE
	var/list/data = extra ? extra.Copy() : list()
	data["operation"] = operation
	data["binding"] = REF(binding)
	data["generation"] = binding_generation
	var/datum/netrun_machine_message/research/message = new(data)
	message.requester_ref = WEAKREF(src)
	if(user)
		message.user_ref = WEAKREF(user)
	return send("research.server", message, REF(binding))

/datum/netrun_machine_service/research_client/accepts(datum/netrun_machine_message/message)
	var/datum/techweb/binding = netrun_atom_techweb(host)
	return !QDELETED(binding) && message.source?.service_id == "research.server" && binding.has_research_owner(message.source.host) && netrun_atom_techweb(message.source.host) == binding && message.payload["binding"] == REF(binding) && message.payload["generation"] == binding_generation

/datum/netrun_machine_service/research_client/receive(datum/netrun_machine_message/message)
	if(!accepts(message))
		return FALSE
	var/list/data = message.payload
	if(data["operation"] == "design")
		var/list/pending = pending_designs[data["design_token"]]
		if(!pending || pending["design"] != data["design_id"])
			return FALSE
		var/datum/techweb/granted = data["success"] ? live_authority() : null
		finish_design(data["design_token"], granted)
		return TRUE
	if(data["operation"] == "current")
		if(snapshot_binding != data["binding"] || snapshot_revision < data["revision"])
			request()
		else
			subscription_ref = WEAKREF(message.source)
		return TRUE
	var/compact = data["operation"] == "state"
	if(!compact && data["operation"] != "snapshot")
		return FALSE
	if(snapshot_binding == data["binding"] && snapshot_revision > data["revision"])
		var/obj/machinery/computer/rdconsole/console = host
		if(!compact && istype(console))
			console.receive_research_disk_snapshot(data)
		return TRUE
	// A restored cluster member can still have a queued copy of the last push.
	// Bare equal-revision state changes neither the current subscription nor caches.
	// Explicit action/disk outcomes retain their processing even at the same revision.
	if(snapshot_binding == data["binding"] && snapshot_revision == data["revision"] && !data["requested_operation"])
		return TRUE
	// A lost full packet, rebind or failover cannot make a partial balance update
	// authoritative for recipes we have never received. Repair over ordinary I/O.
	if(compact && (snapshot_binding != data["binding"] || snapshot_catalog_revision != data["catalog_revision"]))
		request()
		return FALSE
	snapshot_binding = data["binding"]
	snapshot_revision = data["revision"]
	subscription_ref = WEAKREF(message.source)
	if(compact)
		var/datum/techweb/cache
		if(istype(host, /obj/machinery/rnd/production))
			var/obj/machinery/rnd/production/production = host
			cache = production.stored_research
		else if(istype(host, /obj/machinery/mecha_part_fabricator))
			var/obj/machinery/mecha_part_fabricator/fabricator = host
			cache = fabricator.stored_research
		else if(istype(host, /obj/machinery/computer/rdconsole))
			var/obj/machinery/computer/rdconsole/console = host
			cache = console.netrun_research_cache
		else
			cache = snapshot_cache
		if(QDELETED(cache))
			snapshot_revision = -1
			snapshot_catalog_revision = -1
			request()
			return FALSE
		netrun_apply_research_state(cache, data)
		SStgui.update_uis(host)
		SEND_SIGNAL(host, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
		return TRUE
	snapshot_catalog_revision = data["catalog_revision"]
	var/obj/machinery/rnd/production/production = host
	if(istype(production))
		production.receive_research_snapshot(data)
	else if(istype(host, /obj/machinery/mecha_part_fabricator))
		var/obj/machinery/mecha_part_fabricator/fabricator = host
		var/list/known = fabricator.stored_research.researched_nodes.Copy()
		netrun_apply_research_snapshot(fabricator.stored_research, data)
		for(var/id in fabricator.stored_research.researched_designs.Copy())
			var/datum/design/design = SSresearch.techweb_design_by_id(id)
			if(!(design.build_type & MECHFAB))
				fabricator.stored_research.researched_designs -= id
		var/list/new_nodes = data["researched_nodes"] - known
		fabricator.update_static_data_for_all_viewers()
		INVOKE_ASYNC(fabricator, TYPE_PROC_REF(/obj/machinery/mecha_part_fabricator, handle_research_batch_complete), new_nodes)
	else
		var/obj/machinery/computer/rdconsole/console = host
		if(istype(console))
			if(!console.netrun_research_cache)
				console.netrun_research_cache = new /datum/techweb/netrun_snapshot(TRUE)
			netrun_apply_research_snapshot(console.netrun_research_cache, data)
			console.receive_research_disk_snapshot(data)
		else
			if(!snapshot_cache)
				snapshot_cache = new /datum/techweb/netrun_snapshot(TRUE)
			netrun_apply_research_snapshot(snapshot_cache, data)
			if(istype(host, /obj/machinery/computer/operating))
				var/obj/machinery/computer/operating/operating = host
				operating.sync_surgeries()
			host.update_static_data_for_all_viewers()
	SStgui.update_uis(host)
	SEND_SIGNAL(host, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
	return TRUE

/// This is a cache assignment, not research: no points are spent and no science bounty is paid.
/proc/netrun_apply_research_snapshot(datum/techweb/cache, list/data)
	var/list/list/list_data = data
	cache.researched_nodes = list_data["researched_nodes"].Copy()
	cache.available_nodes = list_data["available_nodes"].Copy()
	cache.tiers = list_data["tiers"].Copy()
	cache.researched_designs = list_data["researched_designs"].Copy()
	cache.custom_designs = list_data["custom_designs"].Copy()
	cache.hidden_nodes = list_data["hidden_nodes"].Copy()
	cache.visible_nodes = list_data["visible_nodes"].Copy()
	cache.boosted_nodes = deepCopyList(data["boosted_nodes"])
	cache.discovered_mutations = list_data["discovered_mutations"].Copy()
	cache.deconstructed_items = list_data["deconstructed_items"].Copy()
	netrun_apply_research_state(cache, data)
	// Derived server state is already consistent. Replaying node recalculation here
	// used to yield with half-applied data and mutate cached designs while deleting hosts.

/proc/netrun_apply_research_state(datum/techweb/cache, list/data)
	var/list/list/list_data = data
	cache.research_points = list_data["research_points"].Copy()
	cache.last_bitcoins = list_data["last_bitcoins"].Copy()
	cache.organization = data["organization"]
	cache.problem_computer_charges = data["problem_computer_charges"]
	cache.problem_computer_max_charges = data["problem_computer_max_charges"]

/obj/machinery/computer/rdconsole
	var/datum/techweb/netrun_research_cache

/obj/machinery/computer/rdconsole/proc/request_research_snapshot()
	var/datum/netrun_machine_service/research_client/client = get_netrun_machine_service("research.client")
	return client?.request()

/obj/machinery/computer/rdconsole/proc/request_research_action(operation, mob/user, list/data)
	var/datum/netrun_machine_service/research_client/client = get_netrun_machine_service("research.client")
	return client?.request(operation, user, data)

/obj/machinery/computer/rdconsole/proc/receive_research_disk_snapshot(list/data)
	if(data["requested_operation"] != "download_disk" || !t_disk || REF(t_disk) != data["disk"])
		return
	var/datum/techweb/disk = t_disk.stored_research
	disk.researched_nodes |= data["researched_nodes"]
	disk.researched_designs |= data["researched_designs"]
	disk.custom_designs |= data["custom_designs"]
	for(var/id in disk.hidden_nodes.Copy())
		if(!data["hidden_nodes"][id])
			disk.hidden_nodes -= id
	disk.recalculate_nodes()
	say("Техвеб получен по сети и записан на диск.")
	SStgui.update_uis(src)

/obj/machinery/rnd/production/proc/receive_research_snapshot(list/data)
	var/list/known = designs_cache_built ? stored_research.researched_designs.Copy() : null
	netrun_apply_research_snapshot(stored_research, data)
	if(known && !length(known - stored_research.researched_designs))
		update_designs_incremental(known)
	else
		update_designs()
	INVOKE_ASYNC(src, PROC_REF(handle_research_batch_complete))

/// Authoritative web mutations publish once per batch; received caches never emit this signal.
/datum/techweb
	var/netrun_research_revision = 0
	/// Balance-only changes do not invalidate the delivered recipe catalogue.
	var/netrun_research_catalog_revision = 0

/datum/techweb/proc/netrun_research_changed(catalog_changed = TRUE)
	netrun_research_revision++
	if(catalog_changed)
		netrun_research_catalog_revision++
	SEND_SIGNAL(src, COMSIG_NETRUN_RESEARCH_CHANGED)

/// Local recipes may exist before the first packet without paying research bounties.
/datum/techweb/netrun_snapshot/New(empty = FALSE)
	hidden_nodes = SSresearch.techweb_nodes_hidden.Copy()
	if(empty)
		return
	for(var/id in SSresearch.techweb_nodes_starting)
		var/datum/techweb_node/node = SSresearch.techweb_node_by_id(id)
		researched_nodes[id] = TRUE
		for(var/design_id in node.design_ids)
			researched_designs[design_id] = TRUE
		for(var/unlock_id in node.unlock_ids)
			visible_nodes[unlock_id] = TRUE
	var/list/initial_nodes = researched_nodes | visible_nodes
	for(var/id in initial_nodes)
		update_node_status(SSresearch.techweb_node_by_id(id), FALSE)

/obj/machinery/rnd/server/proc/refresh_research_service()
	var/datum/netrun_machine_service/research_server/service = get_netrun_machine_service("research.server")
	service?.bind_research()

/obj/machinery/mecha_part_fabricator/proc/on_netrun_techweb_changed(datum/source, datum/techweb/new_web)
	SIGNAL_HANDLER
	QDEL_NULL(stored_research)
	stored_research = new /datum/techweb/netrun_snapshot
	INVOKE_ASYNC(src, PROC_REF(sync), TRUE, TRUE)

/obj/machinery/mecha_part_fabricator/LateInitialize()
	. = ..()
	sync(TRUE, TRUE)

/obj/item/xenoarch/help/research/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/techweb_holder)

/// The server computes the reward; callers cannot supply an arbitrary point value.
/obj/item/proc/netrun_artifact_research_points()
	return 0

/obj/item/ancientartifact/useless/netrun_artifact_research_points()
	return 4500

/obj/item/ancientartifact/faunafossil/netrun_artifact_research_points()
	return 9000

/obj/item/ancientartifact/florafossil/netrun_artifact_research_points()
	return 9000

/obj/item/alienartifact/netrun_artifact_research_points()
	return 7500
