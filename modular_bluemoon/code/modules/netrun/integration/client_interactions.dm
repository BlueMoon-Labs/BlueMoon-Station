/// Physical entry changes the route source, never the operator's credentials.
/datum/netrun_console/proc/has_service_lead()
	return istype(host, /obj/item/netrun_deck) || istype(host, /obj/item/organ/cyberimp/brain/netlink)

/datum/netrun_connection/proc/connect_denial(datum/component/netrun_node/node, mob/user)
	if(!owner?.has_service_lead() || QDELETED(user) || user != owner.operator || user.incapacitated())
		return "Сетевой клиент недоступен."
	if(owner.is_locked())
		return "Точка подключения заблокирована."
	if(istype(owner.host, /obj/item/netrun_deck))
		var/obj/item/netrun_deck/deck = owner.host
		if(!(user in get_nested_locs(deck)) || !deck.netrun_online())
			return "Возьмите исправную кибердеку с собой."
	else
		var/obj/item/organ/cyberimp/brain/netlink/implant = owner.host
		if(implant.owner != user || !implant.netrun_online())
			return "Нейролинк не отвечает."
	if(QDELETED(node) || QDELETED(node.parent) || node.parent == owner.host)
		return "Нет сервисного порта."
	var/atom/target = node.parent
	if(!(istype(target, /obj/machinery) || istype(target, /obj/item) || iscyborg(target)))
		return "У этого узла нет внешнего сервисного порта."
	var/turf/here = owner.physical_turf()
	var/turf/there = node.physical_turf()
	if(!here || !there || here.z != there.z || get_dist(here, there) > 1 || !(target in view(1, user)) || !user.CanReach(target))
		return "Подойдите к сервисному порту вплотную."
	return null

/// Revalidate after the physical plugging delay; map visibility is not physical reach.
/datum/netrun_connection/proc/connect_node(datum/component/netrun_node/node, mob/user)
	var/reason = connect_denial(node, user)
	if(reason)
		owner?.log_line(reason, "bad")
		return FALSE
	owner.set_jack(node)
	owner.map_view.selected_network = null
	owner.workspace_view = "map"
	owner.log_line("Сервисный порт подключён: [node.get_name()] [node.address].", "good")
	return TRUE

/datum/netrun_console/proc/plug_into(datum/component/netrun_node/node, mob/user)
	var/reason = connection.connect_denial(node, user)
	if(reason)
		log_line(reason, "bad")
		return FALSE
	to_chat(user, span_notice("Вы подключаете сервисный кабель к [node.get_name()]..."))
	if(!do_after(user, 3 SECONDS, target = node.parent) || QDELETED(src))
		return FALSE
	if(!connection.connect_node(node, user))
		return FALSE
	playsound(node.parent, 'sound/machines/click.ogg', 40, TRUE)
	finish_user_action(node)
	return TRUE

/datum/netrun_console/proc/local_connection_choices(mob/user)
	. = list()
	for(var/atom/target in view(1, user))
		var/datum/component/netrun_node/node = target.GetComponent(/datum/component/netrun_node)
		if(!connection.connect_denial(node, user))
			.["[node.get_name()] — [node.address]"] = node

/datum/netrun_console/proc/choose_connection(mob/user)
	var/list/choices = local_connection_choices(user)
	if(!length(choices))
		log_line("Рядом нет доступных сервисных портов. Подойдите к машине вплотную.", "average")
		return
	var/choice = tgui_input_list(user, "Выберите сервисный порт рядом. Подключение не выдаёт прав управления.", "Подключение к сети", choices)
	if(QDELETED(src) || !choice)
		return
	var/datum/component/netrun_node/node = choices[choice]
	plug_into(node, user)

/// One set of capabilities drives the selected-node UI and is rechecked on dispatch.
/datum/netrun_console/proc/node_interactions(datum/component/netrun_node/node)
	. = list()
	if(QDELETED(node))
		return
	if(has_service_lead())
		if(connection.jack == node)
			. += list(list("id" = "unjack", "name" = "Отключить порт", "icon" = "plug-circle-xmark", "enabled" = TRUE))
		else
			var/reason = connection.connect_denial(node, operator)
			. += list(list("id" = "jack", "name" = "Подключить сервисный порт", "icon" = "plug", "enabled" = !reason, "reason" = reason))
	var/allowed = !is_locked() && node.is_online() && can_route(node) && node_level(node) >= NETRUN_ACCESS_USER
	var/reason = allowed ? null : "Нужны действующий маршрут и доступ пользователя к работающему узлу."
	if(SSnetrun.get_provider(node.parent))
		. += list(list("id" = "manage", "name" = "Управление устройством", "icon" = "sliders", "enabled" = allowed, "reason" = reason))
	var/atom/target = node.parent
	if(target.netrun_view_capable())
		var/watching = remote_session.watch_node == node
		var/view_reason = view_denial(node)
		. += list(list("id" = watching ? "unwatch" : "watch", "name" = watching ? "Отключить обзор" : "Подключить обзор", "icon" = "eye", "enabled" = watching || (allowed && !view_reason), "reason" = watching ? null : (view_reason || reason)))
	if("listen" in node.all_command_ids())
		var/listening_now = (node in listening)
		. += list(list("id" = listening_now ? "unlisten" : "listen", "name" = listening_now ? "Отключить звук" : "Слушать узел", "icon" = "headphones", "enabled" = listening_now || allowed, "reason" = listening_now ? null : reason))

/datum/netrun_console/proc/node_interact(datum/component/netrun_node/node, id, mob/user)
	if(QDELETED(node) || user != operator || !node_visible(node))
		return FALSE
	var/allowed = FALSE
	for(var/list/entry as anything in node_interactions(node))
		if(entry["id"] == id)
			if(!entry["enabled"])
				log_line(entry["reason"], "bad")
				return FALSE
			allowed = TRUE
			break
	if(!allowed)
		return FALSE
	switch(id)
		if("jack")
			INVOKE_ASYNC(src, PROC_REF(plug_into), node, user)
		if("unjack")
			set_jack(null)
		if("manage")
			return open_window(node.address)
		if("watch")
			return window_act(node.address, "view_watch", list())
		if("unwatch")
			stop_watch()
		if("listen")
			return run_command(node, "listen")
		if("unlisten")
			node.stop_listening(src)
		else
			return FALSE
	return TRUE
