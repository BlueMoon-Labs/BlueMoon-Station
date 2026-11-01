/// A dive's identity is a private file, captured once from its actual ID source.
/// Ordinary stolen .access files remain portable; this subtype is never one.
/datum/netrun_file/access/session_snapshot
	var/datum/weakref/dive_ref

/datum/netrun_file/access/session_snapshot/New(file_name, list/source_access, datum/netrun_dive_link/dive)
	dive_ref = WEAKREF(dive)
	..(file_name, source_access)

/datum/netrun_file/access/session_snapshot/can_copy()
	return FALSE

/datum/netrun_file/access/session_snapshot/copy()
	return null

/datum/netrun_file/access/session_snapshot/can_transfer(datum/netrun_file_store/destination, move = FALSE)
	return FALSE

/datum/netrun_file/access/session_snapshot/can_delete(datum/netrun_file_store/source)
	var/datum/netrun_dive_link/dive = dive_ref?.resolve()
	return source && !QDELETED(dive) && source == dive.owner?.console?.inventory.session_store && (src in source.files)

/datum/netrun_file/access/session_snapshot/can_store(datum/netrun_file_store/destination)
	var/datum/netrun_dive_link/dive = dive_ref?.resolve()
	return destination && !QDELETED(dive) && dive.body && !dive.returning && dive.owner?.console?.inventory.session_store == destination

/datum/netrun_file/access/session_snapshot/access_for(datum/netrun_console/console)
	var/datum/netrun_dive_link/dive = dive_ref?.resolve()
	if(QDELETED(dive) || dive.returning || QDELETED(dive.body) || dive.owner?.console != console || !(src in console.inventory.session_store?.files))
		return null
	return accesses

/datum/netrun_file/access/session_snapshot/ui_entry(selected_uid)
	. = ..()
	.["session_bound"] = TRUE
	.["preview"] = "Снимок ID погружения: [length(accesses)] доступов. Удаление отзывает их до выхода; перенос запрещён."

/datum/netrun_file/access/session_snapshot/Destroy()
	dive_ref = null
	return ..()

/// Every exported scope binds the original live object and its authorization
/// domain. A recycled address, moved node or rotated LAN key is not that scope.
/datum/netrun_grant_scope
	var/datum/weakref/node_ref
	var/datum/weakref/network_ref
	var/node_epoch
	var/passcode
	/// Proven acquired level only; unsigned compatibility/residency grants are zero.
	var/export_level = NETRUN_ACCESS_NONE

/datum/netrun_grant_scope/New(datum/netrun_network/network, datum/component/netrun_node/node)
	network_ref = network ? WEAKREF(network) : null
	passcode = network?.passcode
	if(node)
		node_ref = WEAKREF(node)
		node_epoch = node.access_key_epoch

/datum/netrun_grant_scope/proc/valid_network(datum/netrun_network/network)
	return !QDELETED(network) && network_ref?.resolve() == network && network.passcode == passcode

/datum/netrun_grant_scope/proc/valid_node(datum/component/netrun_node/node)
	return !QDELETED(node) && node_ref?.resolve() == node && node.access_key_epoch == node_epoch && valid_network(node.network)

/datum/netrun_grant_scope/proc/copy()
	var/datum/netrun_grant_scope/result = new
	result.node_ref = node_ref
	result.network_ref = network_ref
	result.node_epoch = node_epoch
	result.passcode = passcode
	result.export_level = export_level
	return result

/datum/netrun_grant_scope/Destroy()
	node_ref = null
	network_ref = null
	passcode = null
	return ..()

/// This is effective network authority only. It carries no numeric station ID
/// accesses, firmware state, passwords, source session or escalation shortcut.
/datum/netrun_file/acquired_key
	var/list/node_grants = list()
	var/list/network_grants = list()
	var/list/datum/netrun_grant_scope/node_scopes = list()
	var/list/datum/netrun_grant_scope/network_scopes = list()

/datum/netrun_file/acquired_key/New(file_name)
	..(netrun_file_name(file_name, "acquired.grants"), "grants", "Ключ добытых сетевых прав.", 1)

/datum/netrun_file/acquired_key/copy()
	var/datum/netrun_file/acquired_key/result = new(name)
	result.node_grants = node_grants.Copy()
	result.network_grants = network_grants.Copy()
	for(var/address in node_scopes)
		var/datum/netrun_grant_scope/scope = node_scopes[address]
		result.node_scopes[address] = scope.copy()
	for(var/id in network_scopes)
		var/datum/netrun_grant_scope/scope = network_scopes[id]
		result.network_scopes[id] = scope.copy()
	result.size = size
	result.content = content
	return result

/datum/netrun_file/acquired_key/proc/node_level(datum/component/netrun_node/node)
	var/datum/netrun_grant_scope/scope = node_scopes[node?.address]
	return scope?.valid_node(node) ? clamp(node_grants[node.address] || 0, NETRUN_ACCESS_NONE, NETRUN_ACCESS_ROOT) : NETRUN_ACCESS_NONE

/datum/netrun_file/acquired_key/proc/network_level(datum/netrun_network/network)
	var/datum/netrun_grant_scope/scope = network_scopes[network?.id]
	return scope?.valid_network(network) ? clamp(network_grants[network.id] || 0, NETRUN_ACCESS_NONE, NETRUN_ACCESS_ROOT) : NETRUN_ACCESS_NONE

/// Consume only currently valid stronger scopes. Copy the original stamps;
/// never rebuild a scope from today's node/network while importing an old file.
/datum/netrun_file/acquired_key/proc/merge_from(datum/netrun_file/acquired_key/incoming)
	if(QDELETED(incoming) || incoming == src)
		return FALSE
	var/changed = FALSE
	for(var/address in incoming.node_grants)
		var/datum/component/netrun_node/node = SSnetrun.find_node(address)
		var/level = incoming.node_level(node)
		if(level <= node_level(node))
			continue
		var/datum/netrun_grant_scope/scope = incoming.node_scopes[address]
		var/datum/netrun_grant_scope/previous = node_scopes[address]
		node_grants[address] = level
		node_scopes[address] = scope.copy()
		qdel(previous)
		changed = TRUE
	for(var/id in incoming.network_grants)
		var/datum/netrun_network/network = SSnetrun.networks[id]
		var/level = incoming.network_level(network)
		if(level <= network_level(network))
			continue
		var/datum/netrun_grant_scope/scope = incoming.network_scopes[id]
		var/datum/netrun_grant_scope/previous = network_scopes[id]
		network_grants[id] = level
		network_scopes[id] = scope.copy()
		qdel(previous)
		changed = TRUE
	update_description()
	return changed

/datum/netrun_file/acquired_key/proc/update_description()
	// Reserve one real metadata cell before a breach; adding scopes cannot grow
	// an existing key past its disk capacity when the operation completes.
	size = 1
	var/list/lines = list("Добытые сетевые права. Не являются ID-доступами; экран, смена сети или ключа отзывают соответствующую область.")
	for(var/address in node_grants)
		lines += "Узел [address]: [netrun_access_name(node_grants[address])]"
	for(var/id in network_grants)
		lines += "ЛВС [id]: [netrun_access_name(network_grants[id])]"
	content = jointext(lines, "\n")

/datum/netrun_file/acquired_key/ui_entry(selected_uid)
	. = ..()
	.["preview"] = "Добытые права: [length(node_grants)] узлов, [length(network_grants)] ЛВС. Сброшенные области не восстанавливаются копированием."
	.["node_count"] = length(node_grants)
	.["network_count"] = length(network_grants)

/datum/netrun_file/acquired_key/show(mob/user)
	if(!user?.client)
		return
	var/datum/browser/popup = new(user, "netrun_file_[uid]", html_encode(name), 450, 500)
	popup.set_content("<tt>[replacetext(html_encode(content), "\n", "<br>")]</tt>")
	popup.open()

/datum/netrun_file/acquired_key/Destroy()
	QDEL_LIST_ASSOC_VAL(node_scopes)
	QDEL_LIST_ASSOC_VAL(network_scopes)
	node_grants = null
	network_grants = null
	return ..()

/// Direct grants also remember their original domain, so exporting after a
/// rotation cannot launder a stale session grant into a freshly signed key.
/datum/netrun_access_session
	var/list/datum/netrun_grant_scope/node_grant_scopes = list()
	var/list/datum/netrun_grant_scope/network_grant_scopes = list()
	var/residency_address

/datum/netrun_access_session/proc/direct_node_level(datum/component/netrun_node/node)
	if(QDELETED(node))
		return NETRUN_ACCESS_NONE
	var/datum/netrun_grant_scope/scope = node_grant_scopes[node.address]
	if(scope && !scope.valid_node(node))
		return NETRUN_ACCESS_NONE
	return clamp(node_access[node.address] || 0, NETRUN_ACCESS_NONE, NETRUN_ACCESS_ROOT)

/datum/netrun_access_session/proc/direct_network_level(datum/netrun_network/network)
	if(QDELETED(network))
		return NETRUN_ACCESS_NONE
	var/datum/netrun_grant_scope/scope = network_grant_scopes[network.id]
	if(scope && !scope.valid_network(network))
		return NETRUN_ACCESS_NONE
	return clamp(network_access[network.id] || 0, NETRUN_ACCESS_NONE, NETRUN_ACCESS_ROOT)

/datum/netrun_access_session/proc/grant_node(datum/component/netrun_node/node, level, export_level = NETRUN_ACCESS_NONE)
	if(QDELETED(node) || !node.network || !isnum(level) || level <= NETRUN_ACCESS_NONE)
		return FALSE
	node_access[node.address] = max(direct_node_level(node), clamp(level, NETRUN_ACCESS_NONE, NETRUN_ACCESS_ROOT))
	var/datum/netrun_grant_scope/previous = node_grant_scopes[node.address]
	var/proven_level = previous?.valid_node(node) ? previous.export_level : NETRUN_ACCESS_NONE
	var/datum/netrun_grant_scope/scope = new(node.network, node)
	scope.export_level = max(proven_level, min(node_access[node.address], clamp(export_level, NETRUN_ACCESS_NONE, NETRUN_ACCESS_ROOT)))
	node_grant_scopes[node.address] = scope
	qdel(previous)
	if(residency_address == node.address)
		residency_address = null
	invalidate_grants()
	return TRUE

/datum/netrun_access_session/proc/grant_network(datum/netrun_network/network, level, export_level = NETRUN_ACCESS_NONE)
	if(QDELETED(network) || !isnum(level) || level <= NETRUN_ACCESS_NONE)
		return FALSE
	network_access[network.id] = max(direct_network_level(network), clamp(level, NETRUN_ACCESS_NONE, NETRUN_ACCESS_ROOT))
	var/datum/netrun_grant_scope/previous = network_grant_scopes[network.id]
	var/proven_level = previous?.valid_network(network) ? previous.export_level : NETRUN_ACCESS_NONE
	var/datum/netrun_grant_scope/scope = new(network)
	scope.export_level = max(proven_level, min(network_access[network.id], clamp(export_level, NETRUN_ACCESS_NONE, NETRUN_ACCESS_ROOT)))
	network_grant_scopes[network.id] = scope
	qdel(previous)
	invalidate_grants()
	return TRUE

/datum/netrun_access_session/proc/invalidate_grants()
	owner?.ui_node_levels?.Cut()
	owner?.network_level_cache?.Cut()
	owner?.invalidate_projection_caches()

/datum/netrun_access_session/proc/clear_grant_scopes()
	QDEL_LIST_ASSOC_VAL(node_grant_scopes)
	QDEL_LIST_ASSOC_VAL(network_grant_scopes)
	residency_address = null

/datum/netrun_access_session/proc/acquired_node_level(datum/component/netrun_node/node)
	return max(direct_node_level(node), owner.inventory.acquired_node_level(node))

/datum/netrun_access_session/proc/acquired_network_level(datum/netrun_network/network)
	return max(direct_network_level(network), owner.inventory.acquired_network_level(network))

/// Imported authority is read from actual owned files; it is never merged into
/// direct grants and cannot survive removal of its last physical source file.
/datum/netrun_inventory/proc/acquired_node_level(datum/component/netrun_node/node)
	. = NETRUN_ACCESS_NONE
	for(var/datum/netrun_file/acquired_key/key as anything in get_acquired_keys())
		if(!QDELETED(key))
			. = max(., key.node_level(node))

/datum/netrun_inventory/proc/acquired_network_level(datum/netrun_network/network)
	. = NETRUN_ACCESS_NONE
	for(var/datum/netrun_file/acquired_key/key as anything in get_acquired_keys())
		if(!QDELETED(key))
			. = max(., key.network_level(network))

/// Storage facts invalidate this index. Neither effective levels nor revocation
/// generations are cached, and ordinary files add no per-node scanning cost.
/datum/netrun_inventory/proc/get_acquired_keys()
	if(!acquired_keys)
		acquired_keys = list()
		for(var/datum/netrun_file/acquired_key/key as anything in local_store.files)
			if(istype(key) && !QDELETED(key))
				acquired_keys += key
		if(!QDELETED(shard))
			for(var/datum/netrun_file/acquired_key/key as anything in shard.file_store.files)
				if(istype(key) && !QDELETED(key))
					acquired_keys += key
	return acquired_keys

/// Used only on a firewall fact, including a scope invalidated before this
/// signal. That ensures active UI caches are dropped without polling each key.
/datum/netrun_inventory/proc/has_acquired_node_scope(address)
	for(var/datum/netrun_file/acquired_key/key as anything in get_acquired_keys())
		if(!QDELETED(key) && key.node_grants[address])
			return TRUE
	return FALSE

/datum/netrun_access_session/proc/exportable_node_level(datum/component/netrun_node/node)
	var/datum/netrun_grant_scope/scope = node_grant_scopes[node?.address]
	return scope ? min(direct_node_level(node), scope.export_level) : NETRUN_ACCESS_NONE

/datum/netrun_access_session/proc/exportable_network_level(datum/netrun_network/network)
	var/datum/netrun_grant_scope/scope = network_grant_scopes[network?.id]
	return scope ? min(direct_network_level(network), scope.export_level) : NETRUN_ACCESS_NONE

/datum/netrun_inventory
	var/canonical_key_uid

/// Resolve actual local/shard membership, never a retained file reference.
/datum/netrun_console/proc/canonical_acquired_key(create = FALSE)
	RETURN_TYPE(/datum/netrun_file/acquired_key)
	var/datum/netrun_file/acquired_key/key = inventory.find_file(inventory.canonical_key_uid)
	if(istype(key) && !QDELETED(key) && inventory.store_for(key))
		return key
	inventory.canonical_key_uid = null
	for(var/datum/netrun_file/acquired_key/owned as anything in inventory.get_acquired_keys())
		if(QDELETED(owned) || inventory.find_file(owned.uid) != owned || !inventory.store_for(owned))
			continue
		inventory.canonical_key_uid = owned.uid
		return owned
	if(!create)
		return null
	key = new("acquired.grants")
	var/datum/netrun_file/acquired_key/stored = store_file(key)
	if(!stored)
		stored = store_file(key, TRUE)
	if(!stored)
		qdel(key)
		return null
	key = stored
	inventory.canonical_key_uid = key.uid
	return key

/// Only the newly hacked scope is refreshed. Unrelated old scopes, including
/// invalid ones, retain their original stamps and cannot be revived by merging.
/datum/netrun_console/proc/record_breach_grant(kind, id, level)
	if(!(kind in list("node", "network")) || !isnum(level) || level <= NETRUN_ACCESS_NONE)
		return FALSE
	var/datum/netrun_file/acquired_key/key = canonical_acquired_key(TRUE)
	if(!key)
		return FALSE
	if(kind == "node")
		var/datum/component/netrun_node/node = SSnetrun.find_node(id)
		if(QDELETED(node) || !node.network)
			return FALSE
		var/granted = max(key.node_level(node), clamp(level, NETRUN_ACCESS_NONE, NETRUN_ACCESS_ROOT))
		var/datum/netrun_grant_scope/previous = key.node_scopes[id]
		key.node_grants[id] = granted
		key.node_scopes[id] = new /datum/netrun_grant_scope(node.network, node)
		qdel(previous)
	else
		var/datum/netrun_network/network = SSnetrun.networks[id]
		if(QDELETED(network))
			return FALSE
		var/granted = max(key.network_level(network), min(level, NETRUN_ACCESS_GUEST))
		var/datum/netrun_grant_scope/previous = key.network_scopes[id]
		key.network_grants[id] = granted
		key.network_scopes[id] = new /datum/netrun_grant_scope(network)
		qdel(previous)
	key.update_description()
	var/datum/netrun_file_store/store = inventory.store_for(key)
	store.notify_changed()
	return TRUE

/// A value union of currently proven rights. Reading or exporting a mounted key
/// never merges its authority into permanent direct-session tables.
/datum/netrun_console/proc/acquired_grant_summary(include_scopes = FALSE)
	access_session.process_events()
	var/list/nodes = list()
	var/list/networks = list()
	var/list/node_scopes = include_scopes ? list() : null
	var/list/network_scopes = include_scopes ? list() : null
	for(var/address in access_session.node_access)
		var/level = access_session.exportable_node_level(SSnetrun.find_node(address))
		if(level)
			nodes[address] = level
			if(include_scopes)
				node_scopes[address] = access_session.node_grant_scopes[address]
	for(var/id in access_session.network_access)
		var/level = access_session.exportable_network_level(SSnetrun.networks[id])
		if(level)
			networks[id] = level
			if(include_scopes)
				network_scopes[id] = access_session.network_grant_scopes[id]
	for(var/datum/netrun_file/acquired_key/key as anything in inventory.get_acquired_keys())
		if(QDELETED(key) || inventory.find_file(key.uid) != key || !inventory.store_for(key))
			continue
		for(var/address in key.node_grants)
			var/level = key.node_level(SSnetrun.find_node(address))
			if(level > (nodes[address] || 0))
				nodes[address] = level
				if(include_scopes)
					node_scopes[address] = key.node_scopes[address]
		for(var/id in key.network_grants)
			var/level = key.network_level(SSnetrun.networks[id])
			if(level > (networks[id] || 0))
				networks[id] = level
				if(include_scopes)
					network_scopes[id] = key.network_scopes[id]
	return list("nodes" = nodes, "networks" = networks, "node_scopes" = node_scopes, "network_scopes" = network_scopes)

/datum/netrun_console/proc/acquired_key_payload()
	var/list/summary = acquired_grant_summary()
	var/node_count = length(summary["nodes"])
	var/network_count = length(summary["networks"])
	var/datum/netrun_file/acquired_key/key = canonical_acquired_key()
	return list("node_count" = node_count, "network_count" = network_count, "can_export" = !!(node_count || network_count),
		"key_uid" = key?.uid, "key_name" = key?.name,
		"reason" = (node_count || network_count) ? null : "Нет добытых прав для выпуска ключа. ID, проживание и прошивка в ключ не входят.")

/datum/netrun_console/proc/snapshot_acquired_key(file_name, node_cap = NETRUN_ACCESS_ROOT)
	RETURN_TYPE(/datum/netrun_file/acquired_key)
	var/list/summary = acquired_grant_summary(TRUE)
	var/list/nodes = summary["nodes"]
	var/list/networks = summary["networks"]
	var/list/node_scopes = summary["node_scopes"]
	var/list/network_scopes = summary["network_scopes"]
	if(!length(nodes) && !length(networks))
		return null
	var/datum/netrun_file/acquired_key/key = new(file_name)
	for(var/address in nodes)
		var/datum/netrun_grant_scope/scope = node_scopes[address]
		key.node_grants[address] = min(nodes[address], node_cap)
		key.node_scopes[address] = scope.copy()
	for(var/id in networks)
		var/datum/netrun_grant_scope/scope = network_scopes[id]
		key.network_grants[id] = networks[id]
		key.network_scopes[id] = scope.copy()
	key.update_description()
	return key

/datum/netrun_console/proc/export_acquired_key(file_name, to_shard = FALSE)
	RETURN_TYPE(/datum/netrun_file/acquired_key)
	var/datum/netrun_file/acquired_key/key = snapshot_acquired_key(file_name)
	if(!key)
		log_line("Нет добытых сетевых прав для выпуска ключа.", "bad")
		return null
	var/datum/netrun_file/acquired_key/stored = store_file(key, to_shard)
	if(!stored)
		qdel(key)
		log_line("Недостаточно памяти для ключа добытых прав.", "bad")
		return null
	key = stored
	inventory.selected_file_uid = key.uid
	log_line("Сохранён ключ [key.name]: [length(key.node_grants)] узлов, [length(key.network_grants)] ЛВС.", "good")
	return key
