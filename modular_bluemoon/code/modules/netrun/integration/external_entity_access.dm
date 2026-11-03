/// Raw identity mapping не сериализует REF/DM paths и не удерживает native объекты после удаления.
/datum/netrun_external_core
	var/entity_access_binding
	var/list/entity_access_identities = list()

/datum/netrun_external_core/proc/entity_access_identity_metadata(datum/source)
	if(QDELETED(source) || !binding_epoch || state == "closed" || state == "resync_required")
		return null
	if(entity_access_binding != binding_epoch)
		entity_access_identities = list()
		entity_access_binding = binding_epoch
	var/token = REF(source)
	var/list/metadata = entity_access_identities[token]
	var/datum/weakref/previous = metadata?["source"]
	if(previous?.resolve() != source)
		id_serial = netrun_external_decimal_next(id_serial)
		if(!id_serial)
			return null
		metadata = list("id" = "ea[id_serial]", "serial" = id_serial, "source" = WEAKREF(source))
		entity_access_identities[token] = metadata
	return metadata

/// Opaque identity одной native инкарнации; сведения о владении остаются фактами, не готовыми node levels.
/datum/netrun_external_core/proc/entity_access_identity(datum/source)
	var/list/metadata = entity_access_identity_metadata(source)
	return metadata?["id"]

/// Id ЛВС уже поставлен Core projection; generation различает повторное создание native authority-domain.
/datum/netrun_external_core/proc/entity_network_key(datum/netrun_network/network)
	var/list/metadata = entity_access_identity_metadata(network)
	if(!metadata)
		return null
	return list("id" = network.id, "generation" = metadata["serial"])

/// NodeKey DTO отличается от внутреннего bridge key именем node_id.
/datum/netrun_external_core/proc/entity_access_node_json(datum/component/netrun_node/node)
	var/list/key = node_key(node)
	if(!key)
		return null
	return netrun_external_json_object(list("node_id" = json_encode(key["id"]), "generation" = json_encode(key["generation"])))

/datum/netrun_external_core/proc/entity_access_network_json(datum/netrun_network/network)
	var/list/key = entity_network_key(network)
	return key ? netrun_external_json_object(list("id" = json_encode(key["id"]), "generation" = json_encode(key["generation"]))) : null

/// Полный compatibility helper для асинхронного preparation worker; prepare_input не должен вызывать yield.
/datum/netrun_external_core/proc/entity_access_json(datum/netrun_console/console)
	var/datum/netrun_external_entity_access_cursor/cursor = new(src, console)
	while(!cursor.complete)
		cursor.advance(32)
		if(!cursor.complete)
			CHECK_TICK
			sleep(0)
	var/result = cursor.error ? null : cursor.result_json
	qdel(cursor)
	return result

/// Явные списки numeric facts сохраняют null и [] как разные значения native requirements.
/proc/netrun_external_entity_codes_json(list/codes, nullable = FALSE)
	if(!islist(codes))
		return nullable ? "null" : "\[\]"
	var/list/parts = list()
	for(var/code in codes)
		if(isnum(code) && IS_FINITE(code) && code > 0 && round(code) == code)
			parts += json_encode(code)
	return netrun_external_json_array(parts)

/// Монотонные native epochs малы и целые; wire всё равно использует canonical UInt64 strings.
/proc/netrun_external_entity_epoch_json(value)
	if(istext(value))
		return netrun_external_valid_decimal(value, TRUE) ? json_encode(value) : null
	if(!isnum(value) || !IS_FINITE(value) || value < 0 || round(value) != value)
		return null
	var/decimal = num2text(value, 20)
	return netrun_external_valid_decimal(decimal, TRUE) ? json_encode(decimal) : null

/// Только stamp содержимого, не LAN пароль. Старый scope сохраняет свой исходный stamp.
/proc/netrun_external_entity_key_stamp(value)
	return istext(value) && length(value) ? md5(value) : null

/// Native device ownership — физический факт. Ни один adapter не вычисляет сетевой доступ.
/atom/proc/netrun_external_native_owners()
	return list()

/obj/item/netrun_deck/netrun_external_native_owners()
	return get_nested_locs(src)

/obj/item/modular_computer/netrun_external_native_owners()
	return get_nested_locs(src)

/obj/item/clothing/glasses/hud/netrun_external_native_owners()
	return get_nested_locs(src)

/obj/item/organ/cyberimp/brain/netlink/netrun_external_native_owners()
	return owner ? list(owner) : list()

/mob/living/carbon/netrun_external_native_owners()
	return list(src)

/mob/living/silicon/ai/netrun_external_native_owners()
	return list(src)

/mob/living/silicon/pai/netrun_external_native_owners()
	return list(src)

/obj/effect/netrun_endpoint/neural/netrun_external_native_owners()
	return !QDELETED(interface) && interface.host_mob ? list(interface.host_mob) : list()

/obj/item/mod/control/netrun_external_native_owners()
	var/list/result = list()
	if(wearer)
		result += wearer
	if(ai)
		result |= ai
	return result

/// Raw native ID sources. Entity/ICE используют только реально присутствующие .access файлы.
/datum/netrun_console/proc/netrun_external_native_codes()
	return netrun_mob_access(operator)

/datum/netrun_console/entity/netrun_external_native_codes()
	return list()

/datum/netrun_console/ice/netrun_external_native_codes()
	return list()

/datum/netrun_console/pai/netrun_external_native_codes()
	return list()

/datum/netrun_console/ai/netrun_external_native_codes()
	return available_to() ? netrun_mob_access(operator) : list()

/datum/netrun_console/circuit/netrun_external_native_codes()
	var/obj/item/integrated_circuit/chip = host
	var/obj/item/electronic_assembly/assembly = chip?.assembly
	if(QDELETED(chip) || QDELETED(assembly) || !(chip in assembly.assembly_components))
		return list()
	var/obj/item/card/id/card = assembly.access_card
	return !QDELETED(card) && card.loc == assembly ? card.GetAccess() : list()

/// Cooperative raw exporter: один work unit — один policy, grant либо физический file source.
/datum/netrun_external_entity_access_cursor
	var/datum/weakref/client_ref
	var/datum/weakref/console_ref
	var/binding
	var/fact_tail
	var/node_count
	var/network_count
	var/phase = 1
	var/index = 1
	var/store_index = 1
	var/file_index = 1
	var/list/store_refs = list()
	var/list/store_revisions = list()
	var/list/codes = list()
	var/list/node_policies = list()
	var/list/network_policies = list()
	var/list/node_grants = list()
	var/list/network_grants = list()
	var/list/network_keys = list()
	var/datum/weakref/grant_file_ref
	var/grant_phase = 1
	var/grant_index = 1
	var/complete = FALSE
	var/error
	var/result_json

/datum/netrun_external_entity_access_cursor/New(datum/netrun_external_core/client, datum/netrun_console/console)
	if(QDELETED(client) || QDELETED(console) || QDELETED(client.owner))
		error = "entity_access_source_lost"
		complete = TRUE
		return
	client_ref = WEAKREF(client)
	console_ref = WEAKREF(console)
	binding = client.binding_epoch
	fact_tail = client.fact_tail
	node_count = length(client.owner.nodes_by_address)
	network_count = length(client.owner.networks)
	var/list/native_codes = console.netrun_external_native_codes()
	codes = islist(native_codes) ? native_codes.Copy() : list()
	var/datum/netrun_inventory/inventory = console.inventory
	var/list/stores = list(inventory?.local_store, inventory?.shard?.file_store, inventory?.session_store)
	store_refs = list(null, null, null)
	store_revisions = list(null, null, null)
	for(var/slot in 1 to 3)
		var/datum/netrun_file_store/store = stores[slot]
		store_refs[slot] = store ? WEAKREF(store) : null
		store_revisions[slot] = store?.revision

/datum/netrun_external_entity_access_cursor/Destroy()
	client_ref = null
	console_ref = null
	grant_file_ref = null
	store_refs.Cut()
	store_revisions.Cut()
	codes.Cut()
	node_policies.Cut()
	network_policies.Cut()
	node_grants.Cut()
	network_grants.Cut()
	network_keys.Cut()
	result_json = null
	return ..()

/// Inventory replacement, source revision, topology facts и rebind отзывают недособранный snapshot.
/datum/netrun_external_entity_access_cursor/proc/valid()
	var/datum/netrun_external_core/client = client_ref?.resolve()
	var/datum/netrun_console/console = console_ref?.resolve()
	if(QDELETED(client) || QDELETED(console) || !client.owner || binding != client.binding_epoch || fact_tail != client.fact_tail || client.state == "closed" || client.state == "resync_required")
		return FALSE
	if(node_count != length(client.owner.nodes_by_address) || network_count != length(client.owner.networks))
		return FALSE
	var/datum/netrun_inventory/inventory = console.inventory
	var/list/current = list(inventory?.local_store, inventory?.shard?.file_store, inventory?.session_store)
	for(var/slot in 1 to 3)
		var/datum/weakref/reference = store_refs[slot]
		var/datum/netrun_file_store/store = current[slot]
		if(reference?.resolve() != store || (store && store.revision != store_revisions[slot]))
			return FALSE
	return TRUE

/datum/netrun_external_entity_access_cursor/proc/advance(max_records = 32)
	if(complete)
		return 0
	if(!valid())
		error = "entity_access_changed"
		complete = TRUE
		return 0
	var/datum/netrun_external_core/client = client_ref.resolve()
	var/datum/netrun_console/console = console_ref.resolve()
	var/work = 0
	while(work < clamp(max_records, 1, 32) && !complete)
		switch(phase)
			if(1)
				if(index <= length(client.owner.networks))
					var/datum/netrun_network/network = client.owner.networks[client.owner.networks[index++]]
					var/raw = network_json(client, network)
					if(raw)
						network_policies += raw
				else
					phase++
					index = 1
			if(2)
				if(index <= length(client.owner.nodes_by_address))
					var/datum/component/netrun_node/node = client.owner.nodes_by_address[client.owner.nodes_by_address[index++]]
					var/raw = node_json(client, node)
					if(raw)
						node_policies += raw
				else
					phase++
					index = 1
			if(3)
				var/list/grants = console.access_session.node_access
				if(index <= length(grants))
					var/address = grants[index++]
					var/raw = node_grant_json(client, address, grants[address], console.access_session.node_grant_scopes[address])
					if(raw)
						node_grants += raw
				else
					phase++
					index = 1
			if(4)
				var/list/grants = console.access_session.network_access
				if(index <= length(grants))
					var/id = grants[index++]
					var/raw = network_grant_json(client, id, grants[id], console.access_session.network_grant_scopes[id])
					if(raw)
						network_grants += raw
				else
					phase++
			if(5)
				advance_file(client, console)
			if(6)
				if(!valid())
					error = "entity_access_changed"
				else
					result_json = netrun_external_json_object(list("principal" = principal_json(client, console), "nodes" = netrun_external_json_array(node_policies), "networks" = netrun_external_json_array(network_policies), "node_grants" = netrun_external_json_array(node_grants), "network_grants" = netrun_external_json_array(network_grants), "network_keys" = netrun_external_json_array(network_keys)))
				complete = TRUE
		work++
	return work

/datum/netrun_external_entity_access_cursor/proc/network_json(datum/netrun_external_core/client, datum/netrun_network/network)
	if(QDELETED(network))
		return null
	var/key = client.entity_access_network_json(network)
	var/stamp = netrun_external_entity_key_stamp(network.passcode)
	if(!key || !stamp)
		return null
	return netrun_external_json_object(list("key" = key, "key_epoch" = json_encode(stamp), "guest_access" = netrun_external_entity_codes_json(network.guest_access)))

/datum/netrun_external_entity_access_cursor/proc/node_json(datum/netrun_external_core/client, datum/component/netrun_node/node)
	if(QDELETED(node) || QDELETED(node.parent))
		return null
	var/key = client.entity_access_node_json(node)
	var/epoch = netrun_external_entity_epoch_json(node.access_key_epoch)
	if(!key || !epoch)
		return null
	var/obj/object = node.parent
	if(isobj(object))
		object.gen_access()
	var/list/owners = list()
	var/atom/native_host = node.parent
	for(var/mob/owner as anything in native_host.netrun_external_native_owners())
		if(!ismob(owner) || QDELETED(owner))
			continue
		var/id = client.entity_access_identity(owner)
		if(id)
			owners += json_encode(id)
	return netrun_external_json_object(list("node" = key, "network" = client.entity_access_network_json(node.network) || "null", "key_epoch" = epoch, "required_access" = netrun_external_entity_codes_json(node.required_access, TRUE), "is_object" = netrun_external_json_bool(isobj(object)), "require_all" = isobj(object) ? netrun_external_entity_codes_json(object.req_access, TRUE) : "null", "require_any" = isobj(object) ? netrun_external_entity_codes_json(object.req_one_access, TRUE) : "null", "native_owners" = netrun_external_json_array(owners), "fortress" = fortress_json(client, node)))

/datum/netrun_external_entity_access_cursor/proc/fortress_json(datum/netrun_external_core/client, datum/component/netrun_node/node)
	var/datum/netrun_fortress/fortress = node.fortress
	if(QDELETED(fortress))
		return "null"
	var/datum/netrun_console/builder = fortress.owner_ref?.resolve()
	return netrun_external_json_object(list("has_active_gate" = netrun_external_json_bool(netrun_fortress_slots(node) > 0 && fortress.intact_count(NETRUN_FORT_GATE)), "faction_id" = json_encode(fortress.faction), "faction_family" = json_encode(client.owner.netrun_faction_family(fortress.faction)), "owner_faction_id" = json_encode(fortress.owner_faction_id), "owner_session_id" = json_encode(client.entity_access_identity(builder)), "owner_principal_id" = json_encode(fortress.owner_ckey ? "account:[fortress.owner_ckey]" : null), "owner_faction_family" = json_encode(fortress.owner_faction_id ? client.owner.netrun_faction_family(fortress.owner_faction_id) : null)))

/// Scope сериализуется с исходными объектами/epochs, а не с сегодняшним адресным lookup.
/datum/netrun_external_entity_access_cursor/proc/node_grant_json(datum/netrun_external_core/client, address, level, datum/netrun_grant_scope/scope)
	var/datum/component/netrun_node/node = scope ? scope.node_ref?.resolve() : client.owner.nodes_by_address[address]
	var/key = client.entity_access_node_json(node)
	if(!key)
		return null
	var/network = "null"
	var/stamp = "null"
	var/epoch = "null"
	if(scope)
		network = client.entity_access_network_json(scope.network_ref?.resolve())
		var/raw_stamp = netrun_external_entity_key_stamp(scope.passcode)
		epoch = netrun_external_entity_epoch_json(scope.node_epoch)
		if(!network || !raw_stamp || !epoch)
			return null
		stamp = json_encode(raw_stamp)
	return netrun_external_json_object(list("node" = key, "level" = json_encode(level), "scope_network" = network, "scope_key_epoch" = stamp, "scope_node_epoch" = epoch))

/datum/netrun_external_entity_access_cursor/proc/network_grant_json(datum/netrun_external_core/client, id, level, datum/netrun_grant_scope/scope)
	var/datum/netrun_network/network = scope ? scope.network_ref?.resolve() : client.owner.networks[id]
	var/key = client.entity_access_network_json(network)
	if(!key)
		return null
	var/stamp = scope ? netrun_external_entity_key_stamp(scope.passcode) : null
	if(scope && !stamp)
		return null
	return netrun_external_json_object(list("network" = key, "level" = json_encode(level), "scope_key_epoch" = json_encode(stamp)))

/// Файловые grants остаются отдельными исходными фактами; их нельзя слить в session grants или обновить stamps.
/datum/netrun_external_entity_access_cursor/proc/advance_file(datum/netrun_external_core/client, datum/netrun_console/console)
	var/datum/netrun_file/acquired_key/grant_file = grant_file_ref?.resolve()
	if(grant_file_ref)
		if(QDELETED(grant_file))
			error = "entity_access_changed"
			complete = TRUE
			return
		var/list/grants = grant_phase == 1 ? grant_file.node_grants : grant_file.network_grants
		if(grant_index <= length(grants))
			var/id = grants[grant_index++]
			var/raw = grant_phase == 1 ? node_grant_json(client, id, grants[id], grant_file.node_scopes[id]) : network_grant_json(client, id, grants[id], grant_file.network_scopes[id])
			// Imported files require original signed scopes; unsigned compatibility grants are session-local only.
			var/datum/netrun_grant_scope/scope = grant_phase == 1 ? grant_file.node_scopes[id] : grant_file.network_scopes[id]
			if(raw && scope)
				if(grant_phase == 1)
					node_grants += raw
				else
					network_grants += raw
			return
		if(grant_phase == 1)
			grant_phase = 2
			grant_index = 1
		else
			grant_file_ref = null
		return
	if(store_index > 3)
		phase = 6
		return
	var/datum/weakref/reference = store_refs[store_index]
	var/datum/netrun_file_store/store = reference?.resolve()
	if(!store || file_index > length(store.files))
		store_index++
		file_index = 1
		return
	var/datum/netrun_file/file = store.files[file_index++]
	if(QDELETED(file))
		return
	if(istype(file, /datum/netrun_file/access) && file.kind == NETRUN_FILE_ACCESS && (istype(console, /datum/netrun_console/entity) || istype(console, /datum/netrun_console/ice)))
		var/datum/netrun_file/access/credential = file
		codes |= credential.access_for(console)
	if(file.kind == NETRUN_FILE_KEY)
		var/stamp = netrun_external_entity_key_stamp(file.content)
		if(stamp && istext(file.network_id) && length(file.network_id))
			network_keys += netrun_external_json_object(list("network_id" = json_encode(file.network_id), "key_epoch" = json_encode(stamp)))
	if(istype(file, /datum/netrun_file/acquired_key) && store_index != 3)
		grant_file_ref = WEAKREF(file)
		grant_phase = 1
		grant_index = 1

/datum/netrun_external_entity_access_cursor/proc/principal_json(datum/netrun_external_core/client, datum/netrun_console/console)
	var/mob/camera/netrun_entity/entity = console.combat_self()
	var/datum/netrun_console/master = istype(entity) ? entity.netrun_owner_console() : null
	var/principal = console.operator?.ckey ? "account:[console.operator.ckey]" : client.entity_access_identity(console.personal_faction_principal())
	var/personal = console.get_personal_faction_id()
	var/faction = istype(entity) ? entity.netrun_faction() : null
	return netrun_external_json_object(list("session_id" = json_encode(client.entity_access_identity(console)), "principal_id" = json_encode(principal), "access_codes" = netrun_external_entity_codes_json(codes), "native_owner_id" = json_encode(client.entity_access_identity(netrun_console_owner(console))), "faction_id" = json_encode(faction), "faction_family" = json_encode(faction ? client.owner.netrun_faction_family(faction) : null), "is_entity" = netrun_external_json_bool(istype(entity)), "sanctioned" = netrun_external_json_bool(istype(entity) && !entity.defense_threat()), "locked" = netrun_external_json_bool(console.intrusion && world.time < console.intrusion.lockout_until), "master_session_id" = json_encode(client.entity_access_identity(master)), "master_principal_id" = json_encode(master?.operator?.ckey ? "account:[master.operator.ckey]" : null), "personal_faction_id" = json_encode(personal)))
