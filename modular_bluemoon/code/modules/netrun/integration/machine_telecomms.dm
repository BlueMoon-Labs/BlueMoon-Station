/// Telecomms keeps its link/frequency policy; each machine hop uses the shared transport.

/// Only these contracts carry communications. APC discovery checks this policy;
/// ordinary service identifiers never grant a general route through telecomms.
/proc/netrun_communication_policy(datum/netrun_machine_service/source, destination_id)
	var/static/list/identifiers = list("telecomms.origin", "telecomms.receiver", "telecomms.relay", "pda.messenger", "communications.gateway", "communications.console")
	return (source?.service_id in identifiers) && (destination_id in identifiers)

/// A native long-range link is directional. Receiving brings a remote signal to
/// the hub; broadcasting carries the hub's signal back toward the remote sector.
/proc/netrun_communication_link(datum/component/netrun_node/first, datum/component/netrun_node/second, frequency)
	var/obj/machinery/telecomms/from_machine = first?.parent
	var/obj/machinery/telecomms/to_machine = second?.parent
	if(!istype(from_machine) || !istype(to_machine) || !first.is_online() || !second.is_online())
		return FALSE
	if(!from_machine.on || !to_machine.on || !from_machine.toggled || !to_machine.toggled || !from_machine.is_operational() || !to_machine.is_operational())
		return FALSE
	if(!(to_machine in from_machine.links) || (from_machine.z != to_machine.z && !from_machine.long_range_link && !to_machine.long_range_link))
		return FALSE
	var/obj/machinery/telecomms/relay/relay
	var/allowed = FALSE
	if(istype(from_machine, /obj/machinery/telecomms/relay) && istype(to_machine, /obj/machinery/telecomms/hub))
		relay = from_machine
		allowed = relay.receiving
	else if(istype(from_machine, /obj/machinery/telecomms/hub) && istype(to_machine, /obj/machinery/telecomms/relay))
		relay = to_machine
		allowed = relay.broadcasting
	if(!allowed)
		return FALSE
	// Native relay_information() filters both endpoints. The overlay must not
	// bypass a configured hub's channel filter merely because its relay listens.
	return isnull(frequency) || ((!length(from_machine.freq_listening) || (frequency in from_machine.freq_listening)) && (!length(to_machine.freq_listening) || (frequency in to_machine.freq_listening)))

/// Revalidate every native bridge even when the physical graph has not changed:
/// telecomms links, direction and listening frequencies still have legacy setters.
/datum/netrun_machine_transport/proc/communication_path_available(datum/netrun_topology/graph, list/path, frequency)
	for(var/i in 2 to length(path))
		var/datum/component/netrun_node/first = graph.nodes[path[i - 1]]
		var/datum/component/netrun_node/second = graph.nodes[path[i]]
		if(graph.edge_lookup["[first?.address]>[second?.address]"] || netrun_quantum_link(first, second))
			if(!netrun_link_available(first, second))
				return FALSE
		else if(!netrun_communication_link(first, second, frequency))
			return FALSE
	return TRUE

/// The overlay contains only configured hub/relay ports, never station endpoints.
/// Its local segments borrow the existing bounded APC routing cache. The ordinary
/// graph remains untouched, so runners, research and atmosphere cannot use it.
/datum/netrun_machine_transport/proc/communication_path(datum/netrun_machine_service/source, datum/netrun_machine_service/recipient, frequency)
	var/datum/component/netrun_node/start = source?.resolve_node()
	var/datum/component/netrun_node/finish = recipient?.resolve_node()
	if(QDELETED(start) || QDELETED(finish) || !start.is_online() || !finish.is_online())
		return null
	start.join_network()
	finish.join_network()
	var/datum/netrun_topology/graph = SSnetrun.ensure_topology()
	var/key = "communications:[isnull(frequency) ? "control" : frequency]:[start.address]>[finish.address]"
	var/datum/netrun_machine_path/cached = pair_routes[key]
	if(cached && cached.graph_ref?.resolve() == graph && cached.geometry_revision == graph.revision && communication_path_available(graph, cached.hops, frequency))
		cached.latency = 0
		for(var/i in 2 to length(cached.hops))
			var/first = cached.hops[i - 1]
			var/second = cached.hops[i]
			cached.latency += graph.edge_lookup["[first]>[second]"] ? graph.cached_edge_cost(first, second) : NETRUN_RELAY_LATENCY
		touch_pair_route(key)
		path_cache_hits++
		return cached
	var/list/ports = list()
	ports[start.address] = source
	ports[finish.address] = recipient
	for(var/datum/netrun_machine_service/port as anything in by_id["telecomms.relay"])
		if(!istype(port.host, /obj/machinery/telecomms/relay) && !istype(port.host, /obj/machinery/telecomms/hub))
			continue
		var/datum/component/netrun_node/node = port.resolve_node()
		if(!QDELETED(node) && node.is_online())
			ports[node.address] = port
	var/datum/netrun_path_tree/frontier = new
	var/list/settled = list()
	var/list/segments = list()
	frontier.costs[start.address] = 0
	frontier.push_candidate(start.address, 0)
	while(length(frontier.frontier_addresses))
		var/address = frontier.pop_candidate()
		if(settled[address] || frontier.popped_cost != frontier.costs[address])
			continue
		settled[address] = TRUE
		if(address == finish.address)
			break
		var/datum/netrun_machine_service/from_port = ports[address]
		for(var/next_address in ports)
			if(settled[next_address] || next_address == address)
				continue
			var/datum/netrun_machine_service/to_port = ports[next_address]
			var/datum/netrun_machine_path/physical = borrowed_path(from_port, to_port)
			var/cost = physical ? physical.latency : INFINITY
			var/native = netrun_communication_link(from_port.resolve_node(), to_port.resolve_node(), frequency)
			if(native && cost > NETRUN_RELAY_LATENCY)
				cost = NETRUN_RELAY_LATENCY
			else
				native = FALSE
			if(cost == INFINITY || (!isnull(frontier.costs[next_address]) && frontier.costs[next_address] <= frontier.costs[address] + cost))
				continue
			segments[next_address] = native ? list(address, next_address) : physical.hops.Copy()
			frontier.relax(next_address, address, frontier.costs[address] + cost, FALSE)
	var/datum/netrun_machine_path/result
	if(settled[finish.address])
		result = new
		result.hops = list(start.address)
		var/list/vertices = frontier.addresses_to(finish.address)
		// The heap tree is not a physical path tree; populate reachability only now.
		if(!length(vertices))
			var/address = finish.address
			while(address)
				vertices.Insert(1, address)
				address = frontier.previous[address]
		for(var/i in 2 to length(vertices))
			var/list/segment = segments[vertices[i]]
			for(var/j in 2 to length(segment))
				result.hops += segment[j]
		result.latency = frontier.costs[finish.address]
		result.graph_ref = WEAKREF(graph)
		result.geometry_revision = graph.revision
		if(communication_path_available(graph, result.hops, frequency))
			store_pair_route(key, result)
			path_builds++
		else
			QDEL_NULL(result)
	qdel(frontier)
	// Negative overlay paths are not retained: a newly linked native relay must
	// restore communications without depending on a general-topology revision.
	return result

/obj/machinery/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/telecomms_origin)

/obj/item/radio/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/telecomms_origin)

/obj/item/radio/netrun_online(remote = TRUE)
	return on && (!wires || !wires.is_cut(WIRE_TX))

/obj/machinery/telecomms/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/telecomms_relay)

/obj/machinery/telecomms/receiver/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/telecomms_receiver)

/obj/machinery/telecomms/allinone/netrun_machine_service_types()
	return ..() + list(/datum/netrun_machine_service/telecomms_receiver)

/// A source-only endpoint does not accept remote operations.
/datum/netrun_machine_service/telecomms_origin
	service_id = "telecomms.origin"

/datum/netrun_machine_service/telecomms_origin/accepts(datum/netrun_machine_message/message)
	return FALSE

/datum/netrun_machine_service/telecomms_relay
	service_id = "telecomms.relay"

/datum/netrun_machine_service/telecomms_relay/accepts(datum/netrun_machine_message/message)
	if(!..())
		return FALSE
	var/obj/machinery/telecomms/machine = host
	var/datum/netrun_machine_message/telecomms/packet = message
	if(!istype(machine) || !machine.on || !machine.toggled || !istype(packet) || !packet.signal)
		return FALSE
	if(istype(packet.signal, /datum/signal/subspace/vocal))
		var/datum/signal/subspace/vocal/vocal = packet.signal
		if(QDELETED(vocal.virt) || vocal.data["done"] || vocal.original?.data["done"])
			return FALSE
	if(istype(message.source?.host, /obj/machinery/computer/message_monitor))
		var/obj/machinery/computer/message_monitor/console = message.source.host
		if(!console.auth || console.linkedServer != machine)
			return FALSE
	var/obj/machinery/telecomms/machine_from = packet.machine_from?.resolve()
	if(packet.machine_from && (!machine_from || message.source?.host != machine_from))
		return FALSE
	// Relinking while a packet is travelling revokes that logical connection.
	if(machine_from && !(machine in machine_from.links))
		return FALSE
	if(machine_from && machine_from.z != machine.z && !machine_from.long_range_link && !machine.long_range_link)
		return FALSE
	return TRUE

/datum/netrun_machine_service/telecomms_relay/receive(datum/netrun_machine_message/telecomms/message)
	if(!accepts(message))
		return FALSE
	var/obj/machinery/telecomms/machine = host
	if(istype(message, /datum/netrun_machine_message/telecomms/relay_probe))
		var/datum/netrun_machine_message/telecomms/relay_probe/probe = message
		if(probe.response)
			if(!istype(machine, /obj/machinery/telecomms/hub) || probe.group?.hub?.resolve() != machine)
				return FALSE
			probe.group.add_levels(probe.signal.levels)
			return TRUE
		if(!istype(machine, /obj/machinery/telecomms/relay))
			return FALSE
		machine.receive_information(message.signal, message.machine_from?.resolve())
		return message.reply(new /datum/netrun_machine_message/telecomms/relay_probe(message.signal, machine, probe.group, TRUE))
	machine.receive_information(message.signal, message.machine_from?.resolve())
	return TRUE

/datum/netrun_machine_service/telecomms_receiver
	service_id = "telecomms.receiver"

/datum/netrun_machine_service/telecomms_receiver/accepts(datum/netrun_machine_message/message)
	if(!..())
		return FALSE
	var/datum/netrun_machine_message/telecomms/packet = message
	var/obj/machinery/telecomms/machine = host
	if(!istype(packet) || !packet.signal || !istype(machine) || !machine.on || !machine.toggled)
		return FALSE
	var/datum/signal/subspace/signal = packet.signal
	if(signal.transmission_method != TRANSMISSION_SUBSPACE || !machine.is_freq_listening(signal))
		return FALSE
	if(istype(machine, /obj/machinery/telecomms/receiver))
		var/obj/machinery/telecomms/receiver/receiver = machine
		return receiver.check_receive_level(signal)
	if(istype(machine, /obj/machinery/telecomms/allinone))
		var/obj/machinery/telecomms/allinone/mainframe = machine
		return mainframe.intercept || (mainframe.z in signal.levels) || (0 in signal.levels)
	return FALSE

/datum/netrun_machine_service/telecomms_receiver/receive(datum/netrun_machine_message/telecomms/message)
	if(!accepts(message))
		return FALSE
	if(istype(host, /obj/machinery/telecomms/receiver))
		var/obj/machinery/telecomms/receiver/receiver = host
		receiver.receive_signal(message.signal)
	else
		var/obj/machinery/telecomms/allinone/mainframe = host
		mainframe.receive_signal(message.signal)
	return TRUE

/// Find an actual sending device, including a virtual PDA's explicitly proxied host.
/proc/netrun_telecomms_origin(atom/source)
	if(QDELETED(source))
		return
	if(istype(source, /obj/item/modular_computer))
		return source.get_netrun_machine_service("pda.messenger")
	if(istype(source, /obj/machinery/telecomms))
		return source.get_netrun_machine_service("telecomms.relay")
	if(ismob(source))
		if(istype(source, /mob/camera/netrun_entity))
			var/mob/camera/netrun_entity/entity = source
			return entity.messenger_pda?.get_netrun_machine_service("pda.messenger")
		for(var/obj/item/modular_computer/computer in source.GetAllContents(/obj/item/modular_computer))
			var/datum/netrun_machine_service/service = computer.get_netrun_machine_service("pda.messenger")
			if(service)
				return service
		for(var/obj/item/radio/radio in source.GetAllContents(/obj/item/radio))
			return radio.get_netrun_machine_service("telecomms.origin")
		return
	return source.get_netrun_machine_service("telecomms.origin")

/datum/signal/subspace
	/// Shared transaction state, never used to deliver across machines directly.
	var/datum/netrun_telecomms_transmission/netrun_transmission
	/// The most recent physical transmitter supplies the source of the final PDA hop.
	var/datum/weakref/netrun_transmitter
	/// Native signal fields are strong references, so detach deleted dependencies promptly.
	var/list/netrun_dependencies

/datum/signal/subspace/proc/observe_netrun_dependencies()
	observe_netrun_dependency(source)
	observe_netrun_dependency(data?["mob"])
	if(istype(src, /datum/signal/subspace/vocal))
		var/datum/signal/subspace/vocal/vocal = src
		observe_netrun_dependency(vocal.virt)

/datum/signal/subspace/proc/observe_netrun_dependency(datum/dependency)
	if(!istype(dependency) || netrun_dependencies?[dependency])
		return
	if(QDELETED(dependency))
		on_netrun_dependency_deleted(dependency)
		return
	LAZYSET(netrun_dependencies, dependency, TRUE)
	RegisterSignal(dependency, COMSIG_PARENT_QDELETING, PROC_REF(on_netrun_dependency_deleted))

/datum/signal/subspace/proc/on_netrun_dependency_deleted(datum/dependency)
	SIGNAL_HANDLER
	if(source == dependency)
		source = null
	if(data && data["mob"] == dependency)
		data["mob"] = null
	if(istype(src, /datum/signal/subspace/vocal))
		var/datum/signal/subspace/vocal/vocal = src
		if(vocal.virt == dependency)
			vocal.virt = null
	// An already deleted source can be found before any listener was registered;
	// a callback copied by an in-flight signal can also arrive after stop(). Both
	// paths must detach native references without subtracting from a null index.
	if(netrun_dependencies?[dependency])
		UnregisterSignal(dependency, COMSIG_PARENT_QDELETING)
		LAZYREMOVE(netrun_dependencies, dependency)

/datum/signal/subspace/proc/stop_netrun_dependency_observation()
	var/list/observed = netrun_dependencies
	netrun_dependencies = null
	for(var/datum/dependency as anything in observed)
		UnregisterSignal(dependency, COMSIG_PARENT_QDELETING)

/datum/signal/subspace/Destroy()
	stop_netrun_dependency_observation()
	netrun_transmission?.forget_signal(src)
	netrun_transmission = null
	netrun_transmitter = null
	original = null
	source = null
	data = null
	levels = null
	if(istype(src, /datum/signal/subspace/vocal))
		var/datum/signal/subspace/vocal/vocal = src
		vocal.virt = null
	return ..()

/// Each packet owns its signal snapshot. The original stays alive until all branches settle.
/proc/netrun_telecomms_snapshot(datum/signal/subspace/signal)
	var/datum/signal/subspace/snapshot = signal.copy()
	snapshot.data = deepCopyList(signal.data)
	snapshot.levels = signal.levels?.Copy()
	snapshot.frequency = signal.frequency
	snapshot.server_type = signal.server_type
	snapshot.transmission_method = signal.transmission_method
	snapshot.original = signal.netrun_transmission?.signal || signal.original || signal
	snapshot.netrun_transmission = signal.netrun_transmission
	snapshot.netrun_transmitter = signal.netrun_transmitter
	snapshot.observe_netrun_dependencies()
	snapshot.netrun_transmission?.own_signal(snapshot)
	if(istype(signal, /datum/signal/subspace/pda))
		var/datum/signal/subspace/pda/pda_signal = signal
		var/datum/signal/subspace/pda/pda_snapshot = snapshot
		pda_snapshot.logged = pda_signal.logged
	return snapshot

/datum/netrun_machine_message/telecomms
	var/datum/signal/subspace/signal
	var/datum/weakref/machine_from
	var/datum/netrun_telecomms_transmission/transmission
	var/settled = FALSE

/datum/netrun_machine_message/telecomms/New(datum/signal/subspace/source_signal, obj/machinery/telecomms/from)
	..(list())
	if(source_signal)
		signal = netrun_telecomms_snapshot(source_signal)
		transmission = source_signal.netrun_transmission
		transmission?.retain_packet()
		var/mob/actor = transmission?.player_actor()
		if(!ismob(actor))
			actor = source_signal.data["mob"]
		if(!ismob(actor) && istype(source_signal, /datum/signal/subspace/vocal))
			var/datum/signal/subspace/vocal/vocal = source_signal
			actor = vocal.virt?.source
		if(ismob(actor))
			user_ref = WEAKREF(actor)
	if(from)
		machine_from = WEAKREF(from)

/datum/netrun_machine_message/telecomms/copy()
	var/datum/netrun_machine_message/telecomms/duplicate = ..()
	if(signal)
		duplicate.signal = netrun_telecomms_snapshot(signal)
	duplicate.machine_from = machine_from
	duplicate.transmission = transmission
	duplicate.transmission?.retain_packet()
	return duplicate

/datum/netrun_machine_message/telecomms/delivered(datum/netrun_machine_service/recipient)
	settle()

/datum/netrun_machine_message/telecomms/failed(reason)
	settle(reason)

/datum/netrun_machine_message/telecomms/proc/settle(reason)
	if(settled)
		return
	settled = TRUE
	transmission?.release_packet(reason)

/datum/netrun_machine_message/telecomms/Destroy()
	// Service fanout consumes an original after retaining its copies; disposal is not failure.
	// Real cancellation calls failed(reason) before the transport disposes the message.
	settle()
	if(signal)
		QDEL_NULL(signal)
	transmission = null
	machine_from = null
	return ..()

/// Tracks outstanding branches so an admitted ingress is not mistaken for delivery.
/datum/netrun_telecomms_transmission
	var/datum/signal/subspace/signal
	var/pending_packets = 0
	var/dispatching = 0
	var/finished = FALSE
	var/failure_reason
	var/list/received_by = list()
	var/list/owned_signals = list()
	var/list/watched_programs = list()

/datum/netrun_telecomms_transmission/New(datum/signal/subspace/signal)
	src.signal = signal
	signal.netrun_transmission = src
	signal.observe_netrun_dependencies()
	own_signal(signal)

/// One program subscription per transaction releases deleted targets from every snapshot.
/datum/netrun_telecomms_transmission/proc/own_signal(datum/signal/subspace/owned)
	owned_signals |= owned
	if(!istype(owned, /datum/signal/subspace/messaging/tablet_message))
		return
	var/list/targets = owned.data["targets"]
	for(var/datum/computer_file/program/messenger/app as anything in targets?.Copy())
		if(!istype(app))
			continue
		if(QDELETED(app))
			targets -= app
			continue
		if(!watched_programs[app])
			watched_programs[app] = TRUE
			RegisterSignal(app, COMSIG_PARENT_QDELETING, PROC_REF(on_program_deleted))

/datum/netrun_telecomms_transmission/proc/forget_signal(datum/signal/subspace/owned)
	owned_signals -= owned

/datum/netrun_telecomms_transmission/proc/on_program_deleted(datum/computer_file/program/messenger/app)
	SIGNAL_HANDLER
	for(var/datum/signal/subspace/owned as anything in owned_signals)
		if(istype(owned, /datum/signal/subspace/messaging/tablet_message))
			var/list/targets = owned.data?["targets"]
			targets -= app
	UnregisterSignal(app, COMSIG_PARENT_QDELETING)
	watched_programs -= app

/datum/netrun_telecomms_transmission/proc/retain_packet()
	pending_packets++

/datum/netrun_telecomms_transmission/proc/player_actor()
	return null

/datum/netrun_telecomms_transmission/proc/release_packet(reason)
	pending_packets = max(0, pending_packets - 1)
	if(reason)
		failure_reason = reason
	check_finished()

/datum/netrun_telecomms_transmission/proc/check_finished()
	if(finished || pending_packets || dispatching)
		return
	finished = TRUE
	complete()
	qdel(src)

/datum/netrun_telecomms_transmission/proc/complete()
	if(istype(signal, /datum/signal/subspace/messaging/tablet_message) && !length(received_by))
		log_game("PDA machine transport failed from [signal.source]: [failure_reason || "no recipient accepted the message"].")

/datum/netrun_telecomms_transmission/Destroy()
	for(var/datum/program as anything in watched_programs)
		UnregisterSignal(program, COMSIG_PARENT_QDELETING)
	watched_programs.Cut()
	for(var/datum/signal/subspace/owned as anything in owned_signals)
		// The root may still be used by the RF timer; remove external listener roots.
		owned.stop_netrun_dependency_observation()
		owned.netrun_transmission = null
	owned_signals.Cut()
	signal = null
	received_by = null
	return ..()

/// A hub used to depend on synchronous mutation of signal.levels by its relays.
/// Probes now bring those levels back over the same physical transport.
/obj/machinery/telecomms/hub/proc/netrun_relay_then_broadcast(datum/signal/subspace/signal)
	var/datum/netrun_telecomms_relay_group/group = new(src, signal)
	group.dispatching = TRUE
	relay_information(signal, /obj/machinery/telecomms/relay, FALSE, 20, group)
	group.dispatching = FALSE
	group.check_finished()

/datum/netrun_telecomms_relay_group
	var/datum/weakref/hub
	var/datum/signal/subspace/signal
	var/pending = 0
	var/dispatching = FALSE
	var/finished = FALSE

/datum/netrun_telecomms_relay_group/New(obj/machinery/telecomms/hub/hub, datum/signal/subspace/signal)
	src.hub = WEAKREF(hub)
	src.signal = netrun_telecomms_snapshot(signal)

/datum/netrun_telecomms_relay_group/proc/add_levels(list/levels)
	signal.levels |= levels

/datum/netrun_telecomms_relay_group/proc/release_packet()
	pending = max(0, pending - 1)
	check_finished()

/datum/netrun_telecomms_relay_group/proc/check_finished()
	if(finished || dispatching || pending)
		return
	finished = TRUE
	var/obj/machinery/telecomms/hub/machine = hub?.resolve()
	if(machine?.on)
		machine.relay_information(signal, /obj/machinery/telecomms/broadcaster)
	qdel(src)

/datum/netrun_telecomms_relay_group/Destroy()
	hub = null
	if(signal)
		QDEL_NULL(signal)
	return ..()

/datum/netrun_machine_message/telecomms/relay_probe
	var/datum/netrun_telecomms_relay_group/group
	var/response = FALSE

/datum/netrun_machine_message/telecomms/relay_probe/New(datum/signal/subspace/signal, obj/machinery/telecomms/from, datum/netrun_telecomms_relay_group/group, response = FALSE)
	..(signal, from)
	src.group = group
	src.response = response
	if(group)
		group.pending++

/datum/netrun_machine_message/telecomms/relay_probe/copy()
	var/datum/netrun_machine_message/telecomms/relay_probe/duplicate = ..()
	duplicate.group = group
	duplicate.response = response
	if(group)
		group.pending++
	return duplicate

/datum/netrun_machine_message/telecomms/relay_probe/settle(reason)
	if(settled)
		return
	// Queue the broadcaster before releasing the last transaction-owned probe.
	group?.release_packet()
	group = null
	return ..()
