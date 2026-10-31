/// Identity-based access is separate from department access and never opens the owner's LAN.
/atom/proc/netrun_owner_access(datum/netrun_console/console)
	return NETRUN_ACCESS_NONE

/proc/netrun_console_owner(datum/netrun_console/console)
	if(!console)
		return
	// A dive changes the controlled mob, not ownership of the body's devices.
	// The live link is the authority: an abandoned resident keeps no body access.
	if(istype(console.host, /mob/camera/netrun_entity))
		var/mob/camera/netrun_entity/entity = console.host
		var/mob/living/carbon/body = entity.dive_link?.body
		if(!QDELETED(body) && entity.mind && entity.mind.current == entity && entity.dive_link.personal_principal_ref?.resolve() == entity.mind && body.netrun_personal_dive_ref?.resolve() == entity.dive_link)
			return body
	if(console.operator)
		return console.operator
	if(ismob(console.host))
		return console.host
	if(istype(console.host, /obj/item/organ))
		var/obj/item/organ/organ = console.host
		return organ.owner

/// Opt-in adapter for portable network clients. The console remains the sole session owner.
/datum/component/netrun_access_device
	var/datum/netrun_console/console
	var/datum/component/netrun_node/node
	var/owns_node = FALSE

/datum/component/netrun_access_device/Initialize(datum/netrun_console/console, node_type = NETRUN_NODE_DECK, security = 2)
	if(!isatom(parent) || !console)
		return COMPONENT_INCOMPATIBLE
	src.console = console
	node = parent.GetComponent(/datum/component/netrun_node)
	if(!node)
		node = parent.AddComponent(/datum/component/netrun_node, node_type, list(), security, list())
		owns_node = TRUE
	node.command_ids |= list("session_status", "session_sever")

/datum/component/netrun_access_device/RegisterWithParent()
	RegisterSignal(console, COMSIG_PARENT_QDELETING, PROC_REF(on_console_deleted))

/datum/component/netrun_access_device/UnregisterFromParent()
	if(console)
		UnregisterSignal(console, COMSIG_PARENT_QDELETING)

/datum/component/netrun_access_device/Destroy()
	if(console)
		UnregisterSignal(console, COMSIG_PARENT_QDELETING)
	if(owns_node)
		QDEL_NULL(node)
	else if(!QDELETED(node))
		node.command_ids -= list("session_status", "session_sever")
	node = null
	console = null
	return ..()

/datum/component/netrun_access_device/proc/on_console_deleted(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/obj/item/netrun_deck/netrun_owner_access(datum/netrun_console/source)
	var/mob/user = netrun_console_owner(source)
	return user && (user in get_nested_locs(src)) ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_NONE

/obj/item/netrun_deck/netrun_online(remote = TRUE)
	return world.time >= burnt_until

/obj/item/netrun_deck/netrun_status()
	return list("Память: [netrun_storage_used(console.inventory.local_store.files)]/[console.inventory.local_store.capacity]", "Кабель:[console.connection.jack ? console.connection.jack.address : "не подключён"]")

/obj/item/organ/cyberimp/brain/netlink/netrun_owner_access(datum/netrun_console/source)
	return owner && netrun_console_owner(source) == owner ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_NONE

/obj/item/organ/cyberimp/brain/netlink/netrun_online(remote = TRUE)
	return owner && owner.stat != DEAD && !netrun_suppressed() && owner.netrun_network_enabled()

/obj/item/organ/cyberimp/brain/netlink/netrun_name()
	return "[owner ? owner.name : name] — нейролинк"

/obj/item/modular_computer/netrun_owner_access(datum/netrun_console/console)
	var/mob/user = netrun_console_owner(console)
	return user && (user in get_nested_locs(src)) ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_NONE

/datum/netrun_command/session_status
	id = "session_status"
	read_only = TRUE
	name = "Состояние сетевого клиента"
	desc = "Получить состояние соединения, трассировки и памяти переносного клиента."
	access = NETRUN_ACCESS_USER
	trace = 2
	icon = "network-wired"

/datum/netrun_command/session_status/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg)
	var/datum/component/netrun_access_device/device = node.parent.GetComponent(/datum/component/netrun_access_device)
	var/datum/netrun_console/target = device?.console
	if(!target)
		return
	return "Связь с NTnet: [target.has_uplink() ? "есть" : "нет"].\nСессия: [target.is_locked() ? "заблокирована" : "активна"], трассировка [round(target.intrusion.trace)]%.\nПамять: [netrun_storage_used(target.inventory.local_store.files)]/[target.inventory.local_store.capacity]."

/datum/netrun_command/session_sever
	id = "session_sever"
	name = "Разорвать соединение"
	desc = "Отозвать добытые доступы, отменить взлом и заблокировать сетевой клиент на 30 секунд."
	access = NETRUN_ACCESS_ROOT
	trace = 8
	icon = "link-slash"
	danger = TRUE

/datum/netrun_command/session_sever/execute(datum/component/netrun_node/node, datum/netrun_console/console, arg)
	var/datum/component/netrun_access_device/device = node.parent.GetComponent(/datum/component/netrun_access_device)
	var/datum/netrun_console/target = device?.console
	if(!target)
		return
	target.intrusion.lockout_until = max(target.intrusion.lockout_until, world.time + 30 SECONDS)
	if(istype(target, /datum/netrun_console/implant))
		var/datum/netrun_console/implant/implant = target
		// Return first: the resident merges its acquired grants on exit, after
		// which disconnect_client revokes them from the implant as well.
		implant.disconnect_client(TRUE)
	else
		target.access_session.revoke_all()
		QDEL_NULL(target.intrusion.breach)
		target.set_jack(null)
		target.stop_watch()
	target.log_line("Сессия разорвана внешней сетевой командой.", "bad")
	SStgui.close_uis(target)
	return "Соединение клиента разорвано на 30 секунд."
