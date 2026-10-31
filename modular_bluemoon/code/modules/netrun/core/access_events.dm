/// Firewall events are queued by signals, then applied before any permission read.
/datum/netrun_access_session
	var/list/pending_firewalls = list()
	var/processing_events = FALSE

/datum/netrun_access_session/proc/on_firewall_changed(datum/source, datum/component/netrun_node/node)
	SIGNAL_HANDLER
	if(QDELETED(owner) || QDELETED(node))
		return
	var/datum/netrun_breach/breach = owner.intrusion?.breach
	// Node/map events already publish the visible security change. A session
	// without this grant or breach has no authority state for the firewall to revoke.
	if(!node_access[node.address] && !owner.inventory.has_acquired_node_scope(node.address) && !(breach && breach.target_kind != "network" && breach.target_id == node.address))
		return
	pending_firewalls[node.address] = WEAKREF(node)
	owner.invalidate_ui()

/datum/netrun_access_session/proc/process_events()
	if(processing_events || !length(pending_firewalls))
		return
	processing_events = TRUE
	owner.invalidate_projection_caches()
	owner.ui_node_levels?.Cut()
	owner.ui_legit_levels?.Cut()
	owner.network_level_cache?.Cut()
	owner.ui_completion_cache?.Cut()
	var/list/pending = pending_firewalls
	pending_firewalls = list()
	for(var/address in pending)
		var/datum/weakref/reference = pending[address]
		var/datum/component/netrun_node/node = reference.resolve()
		if(QDELETED(node))
			continue
		owner.map_view.invalidate_node_access(address)
		if(node_access[address])
			revoke_node(address)
			owner.add_trace(node.get_security() * 4)
			owner.log_line("[address]: сетевой экран сбросил ваш доступ.", "bad")
		var/datum/netrun_breach/breach = owner.intrusion.breach
		if(breach && breach.target_kind != "network" && breach.target_id == address)
			owner.log_line("[address]: взлом прерван сетевым экраном.", "bad")
			owner.add_trace(20)
			QDEL_NULL(owner.intrusion.breach)
	processing_events = FALSE
