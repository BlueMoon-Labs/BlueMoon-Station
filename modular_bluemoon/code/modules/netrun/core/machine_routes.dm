/// Physical machine reachability is an imported Core table, never a native route cache.
/datum/netrun_machine_transport/proc/path_tree(datum/component/netrun_node/root)
	var/datum/netrun_external_effects/machines/queries/executor = SSnetrun.external_core?.effects
	return istype(executor) ? executor.projection_tree(SSnetrun.external_core, root, "machine") : null

/// Native service policy still checks identities and live endpoints before using the C# path proof.
/datum/netrun_machine_transport/proc/reachable(datum/netrun_machine_service/source, datum/netrun_machine_service/recipient)
	var/datum/component/netrun_node/start = source?.resolve_node()
	var/datum/component/netrun_node/finish = recipient?.resolve_node()
	if(!SSnetrun.external_core?.ready || QDELETED(source) || QDELETED(recipient) || QDELETED(start) || QDELETED(finish) || !start.is_online() || !finish.is_online())
		return FALSE
	var/datum/netrun_path_tree/tree = path_tree(start)
	return tree?.path_available(SSnetrun.get_topology(), finish.address) || FALSE
