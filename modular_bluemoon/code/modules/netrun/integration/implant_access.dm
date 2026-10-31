/// The implant owns a client, while a dive owns a separate resident process and body link.
/datum/netrun_console/implant
	name = "нейролинк"
	tgui_title = "Нейролинк"
	var/diving = FALSE
	var/datum/weakref/dive_ref

/datum/netrun_console/implant/New(atom/host, origin)
	. = ..()
	state_override = GLOB.conscious_state

/datum/netrun_console/implant/proc/available_to(mob/user = operator)
	var/obj/item/organ/cyberimp/brain/netlink/implant = host
	return istype(implant) && implant.owner && user == implant.owner && user.stat == CONSCIOUS && !user.incapacitated() && implant.netrun_online()

/datum/netrun_console/implant/ui_status(mob/user, datum/ui_state/state)
	if(!available_to(user))
		return UI_CLOSE
	return ..()

/datum/netrun_console/implant/ui_interact(mob/user, datum/tgui/ui)
	if(!available_to(user))
		return
	return ..()

/datum/netrun_console/implant/ui_static_data(mob/user)
	if(!available_to(user || operator))
		return list()
	return list()

/datum/netrun_console/implant/ui_data(mob/user, datum/ui_source)
	if(!available_to(user || operator))
		return list()
	netrun_ui_source = ui_source || src
	if(user)
		operator = user
	note_ui_activity()
	var/datum/component/netrun_node/node = selected_node()
	var/list/entry
	if(node && is_local_entry(node))
		refresh_route_node(node)
		entry = node.ui_entry(src)
		entry["interactions"] = node_interactions(node)
	return list(
		"origin" = origin,
		"ui_theme" = theme_id(user),
		"input_ack" = input_ack,
		"host_actions" = host_actions(),
		"log" = log,
		"selected" = entry,
		"storage" = storage_payload(),
		"shard" = shard_payload(),
		"file" = file_payload(),
		"networks" = list(),
		"windows" = list(),
	)

/// A conscious wearer can prepare local media and an entrance, but only the
/// resident process may send packets or operate machines after diving.
/datum/netrun_console/implant/handle_ui_action(action, list/params, datum/tgui/ui, input_nonce)
	if(!available_to(ui?.user))
		return FALSE
	if(action == "node_interact" && params["id"] != "dive")
		return FALSE
	if(!(action in list("choose_entry", "choose_connection", "unjack", "insert_shard", "eject_shard", "node_interact", "file_select", "file_new", "file_edit", "file_rename", "file_copy", "file_move", "file_import", "agent_create", "delete_local", "read")))
		return FALSE
	return ..()

/// Reading a stale UID must not turn a local read into a remote request.
/datum/netrun_console/implant/read_file(mob/user, uid, input_nonce)
	var/datum/netrun_file/file = find_local_file(uid)
	file?.show(user)

/datum/netrun_console/implant/run_command(datum/component/netrun_node/node, command_id, input_nonce, packet_id)
	return FALSE

/datum/netrun_console/implant/remote_request(address, action, list/arguments, input_nonce)
	return FALSE

/datum/netrun_console/implant/open_window(address)
	return FALSE

/datum/netrun_console/implant/window_act(address, action, list/params, input_nonce)
	return FALSE

/datum/netrun_console/implant/cli(text)
	return FALSE

/datum/netrun_console/implant/start_breach(kind, id, automatic = FALSE)
	return FALSE

/datum/netrun_console/implant/transfer_from_node(uid, to_shard, datum/component/netrun_node/node, delivered = FALSE, input_nonce)
	return FALSE

/datum/netrun_console/implant/transfer_to_node(uid, datum/component/netrun_node/node, delivered = FALSE, input_nonce)
	return FALSE

/datum/netrun_console/implant/delete_from_node(uid, datum/component/netrun_node/node, delivered = FALSE, input_nonce)
	return FALSE

/datum/netrun_console/implant/program_use(uid, target_ref)
	return FALSE

/datum/netrun_console/implant/signal_entity(datum/component/netrun_node/node, recipient_ref, text, input_nonce)
	return FALSE

/datum/netrun_console/implant/chat_send(text)
	return FALSE

/datum/netrun_console/implant/can_route(datum/component/netrun_node/node, datum/netrun_path_tree/tree)
	return available_to() && ..()

/datum/netrun_console/implant/physical_route_source()
	if(!available_to())
		return
	return ..()

/datum/netrun_console/implant/has_uplink()
	return available_to() && ..()

/datum/netrun_console/implant/proc/disconnect_client(return_body = FALSE)
	if(return_body)
		var/mob/camera/netrun_entity/entity = dive_ref?.resolve()
		if(entity?.dive_link.body && !QDELETED(entity.dive_link.body))
			entity.dive_link.emergency_return("Нейролинк принудительно отключён!")
		dive_ref = null
	set_jack(null)
	stop_watch()
	for(var/datum/component/netrun_node/node as anything in listening.Copy())
		node.stop_listening(src)
	access_session.revoke_all()
	QDEL_NULL(intrusion.breach)
	SStgui.close_uis(src)

/datum/netrun_console/implant/set_jack(datum/component/netrun_node/node)
	. = ..()
	var/mob/camera/netrun_entity/entity = dive_ref?.resolve()
	if(entity?.dive_link.entry_jack_ref && entity.dive_link.entry_jack_ref.resolve() != connection.jack)
		entity.dive_link.emergency_return("Сервисный кабель нейролинка отключён!")

/datum/netrun_console/implant/process_tick(delta)
	var/mob/camera/netrun_entity/entity = dive_ref?.resolve()
	var/obj/item/organ/cyberimp/brain/netlink/implant = host
	var/active_dive = entity?.dive_link.body && entity.dive_link.body == implant?.owner
	if(!available_to() && !active_dive && (connection.jack || remote_session.watch_node || length(listening)))
		disconnect_client()
	return ..()

/// A department LAN can cover many APC rooms; entry is limited to the body's
/// actual room, including its sub-areas, instead of every reachable LAN member.
/datum/netrun_console/implant/proc/is_local_entry(datum/component/netrun_node/node, mob/user = operator)
	if(QDELETED(node) || QDELETED(node.parent) || QDELETED(user))
		return FALSE
	var/turf/body_position = get_turf(user)
	var/turf/node_position = node.physical_turf()
	if(!body_position || !node_position || body_position.z != node_position.z)
		return FALSE
	var/area/body_area = get_base_area(body_position)
	return body_area && body_area == get_base_area(node_position) && netrun_sector_for(body_position) == netrun_sector_for(node_position)

/datum/netrun_console/implant/proc/dive_denial(datum/component/netrun_node/node, mob/user = operator)
	if(!available_to(user))
		return "Имплант доступен только его владельцу в сознании."
	if(is_locked())
		return "Нейролинк заблокирован."
	if(diving)
		return "Погружение уже выполняется."
	if(!is_local_entry(node, user))
		return "Узел погружения должен находиться в вашем отсеке."
	if(QDELETED(node) || !node.is_online() || !can_route(node) || node_level(node) < NETRUN_ACCESS_USER)
		return "Нужны действующий маршрут и доступ пользователя к работающему узлу."
	if(!user.mind)
		return "Сознание не готово к погружению."
	return null

/// Node selection is useful even when the map shows a different sector or workspace.
/datum/netrun_console/implant/proc/entry_choices()
	. = list()
	if(!available_to())
		return
	var/datum/netrun_path_tree/tree = make_path_tree()
	for(var/address in tree.reached)
		var/datum/component/netrun_node/node = SSnetrun.find_node(address)
		if(is_local_entry(node) && node.is_online() && can_route(node, tree) && node_level(node, tree) >= NETRUN_ACCESS_USER)
			.["[node.get_name()] — [node.address]"] = node
	qdel(tree)

/datum/netrun_console/implant/proc/select_entry(datum/component/netrun_node/node, mob/user)
	if(!available_to(user) || !is_local_entry(node, user) || !node.is_online() || !can_route(node) || node_level(node) < NETRUN_ACCESS_USER)
		return FALSE
	map_view.selected_address = node.address
	map_view.selected_network = null
	var/turf/position = node.physical_turf()
	map_view.select_sector(node.binding_sector, position?.z)
	workspace_view = "map"
	log_line("Узел погружения выбран: [node.get_name()] [node.address].", "good")
	finish_user_action(node)
	return TRUE

/datum/netrun_console/implant/proc/choose_entry(mob/user)
	var/list/choices = entry_choices()
	if(!length(choices))
		log_line("В вашем отсеке нет доступных узлов погружения.", "average")
		return
	var/choice = tgui_input_list(user, "Выберите узел в вашем отсеке. Для погружения используйте кнопку в его карточке.", "Нейролинк: узел погружения", choices)
	if(!QDELETED(src) && choice)
		select_entry(choices[choice], user)

/datum/netrun_console/implant/host_actions()
	. = ..()
	. += list(list("id" = "choose_entry", "name" = "Выбрать узел погружения", "icon" = "person-walking-arrow-right"))
	if(!inventory.shard)
		. += list(list("id" = "insert_shard", "name" = "Подключить шард из руки", "icon" = "sd-card"))

/datum/netrun_console/implant/host_act(action, list/params, mob/user)
	if(action == "insert_shard")
		var/obj/item/organ/cyberimp/brain/netlink/implant = host
		if(available_to(user))
			INVOKE_ASYNC(implant, TYPE_PROC_REF(/obj/item/organ/cyberimp/brain/netlink, insert_held_shard), user)
		return TRUE
	if(action == "choose_entry")
		if(available_to(user))
			INVOKE_ASYNC(src, PROC_REF(choose_entry), user)
		return TRUE
	return ..()

/datum/netrun_console/implant/node_interactions(datum/component/netrun_node/node)
	. = list()
	var/reason = dive_denial(node)
	. += list(list("id" = "dive", "name" = "Погрузиться в узел", "icon" = "person-walking-arrow-right", "enabled" = !reason, "reason" = reason))

/datum/netrun_console/implant/node_interact(datum/component/netrun_node/node, id, mob/user)
	if(id != "dive")
		return FALSE
	var/reason = dive_denial(node, user)
	if(reason)
		log_line(reason, "bad")
		return FALSE
	var/obj/item/organ/cyberimp/brain/netlink/implant = host
	INVOKE_ASYNC(implant, TYPE_PROC_REF(/obj/item/organ/cyberimp/brain/netlink, try_dive), node)
	return TRUE
