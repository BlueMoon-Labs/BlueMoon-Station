/// Область прав и ключа конкретного APC; физические связи узлов хранит topology.
/datum/netrun_network
	var/id
	var/name = "Локальная сеть"
	var/short_name = "ЛВС"
	/// Защита шлюза ЛВС (1-5), прибавляется к защите узлов
	var/security = 1
	/// Нет маршрута через NTnet - попасть можно только физически
	var/isolated = FALSE
	/// Любой из этих доступов даёт легальный гостевой вход в ЛВС
	var/list/guest_access
	var/list/datum/component/netrun_node/nodes = list()
	var/list/logs = list()
	/// Ключ даёт ГОСТЯ и перемещение сущности по ЛВС, но не права управления машинами.
	var/passcode
	/// Цвет сети на карте терминала
	var/color = "#4a9eff"
	/// Короткий код сети для подключения (показывается в интерфейсе как адрес сети)
	var/code
	/// Зона-носитель ЛВС (для APC-сетей). Общая и внешние сегменты - без зоны.
	var/area/area

/datum/netrun_network/New(new_id, area/source_area)
	id = new_id
	area = source_area
	passcode = "[uppertext(copytext(md5("[new_id][world.time][rand(1, 999999)]"), 1, 17))]"
	code = "NET-[uppertext(copytext(md5("[new_id][passcode]"), 1, 6))]"
	if(new_id == NETRUN_LAN_PUBLIC || copytext(new_id, 1, 5) == "pub:")
		name = "Общая сеть станции"
		short_name = "ОБЩ"
		security = 1
		guest_access = list()
		color = "#8b93a3"
	else if(copytext(new_id, 1, 4) == "ext")
		name = "Внешний сегмент"
		short_name = "ВНШ"
		security = 2
		isolated = TRUE
		guest_access = list()
		color = "#d05090"
	else if(source_area)
		apply_area_profile(source_area)
	else
		name = "Локальная сеть [new_id]"
		short_name = "ЛВС"
	if(area)
		RegisterSignal(area, COMSIG_PARENT_QDELETING, PROC_REF(on_area_deleted))
	add_log("Сеть инициализирована.")

/datum/netrun_network/proc/on_area_deleted(datum/source)
	SIGNAL_HANDLER
	UnregisterSignal(source, COMSIG_PARENT_QDELETING)
	area = null

/// Отдел, к которому относится отсек APC. ЛВС кластеризуется по отделу, а не по отдельному APC,
/// поэтому все APC одного отдела делят одну сеть, ключ и защиту.
/proc/netrun_department_key(area/A)
	if(istype(A, /area/security))
		return "security"
	if(istype(A, /area/command) || istype(A, /area/ai_monitored))
		return "command"
	if(istype(A, /area/engineering))
		return "engineering"
	if(istype(A, /area/medical))
		return "medical"
	if(istype(A, /area/science))
		return "science"
	if(istype(A, /area/cargo))
		return "cargo"
	return "general"

/// Свойства ЛВС выводятся из отдела отсека, в котором стоит её APC.
/datum/netrun_network/proc/apply_area_profile(area/A)
	switch(netrun_department_key(A))
		if("security")
			name = "ЛВС: Служба безопасности"
			short_name = "СБ"
			security = 3
			guest_access = list(ACCESS_SECURITY)
			color = "#ff5050"
		if("command")
			name = "ЛВС: Командование"
			short_name = "КОМ"
			security = 4
			guest_access = list(ACCESS_HEADS)
			color = "#3cdc8c"
		if("engineering")
			name = "ЛВС: Инженерный отдел"
			short_name = "ИНЖ"
			security = 2
			guest_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP)
			color = "#f0a030"
		if("medical")
			name = "ЛВС: Медблок"
			short_name = "МЕД"
			security = 2
			guest_access = list(ACCESS_MEDICAL)
			color = "#5bc0de"
		if("science")
			name = "ЛВС: Научный отдел"
			short_name = "НАУ"
			security = 2
			guest_access = list(ACCESS_RESEARCH, ACCESS_TOX, ACCESS_ROBOTICS)
			color = "#b07cff"
		if("cargo")
			name = "ЛВС: Отдел снабжения"
			short_name = "КАР"
			security = 1
			guest_access = list(ACCESS_CARGO)
			color = "#c9a227"
		else
			name = "ЛВС: Общий сегмент"
			short_name = "СЕГ"
			security = 1
			guest_access = list()
			color = "#8b93a3"

/datum/netrun_network/Destroy()
	QDEL_NULL(security_audit)
	if(area)
		UnregisterSignal(area, COMSIG_PARENT_QDELETING)
	area = null
	nodes.Cut()
	SSnetrun.networks -= id
	return ..()

/datum/netrun_network/proc/add_log(text, important = FALSE)
	logs += "[STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)] [text]"
	if(length(logs) > NETRUN_MAX_LOG)
		logs.Cut(1, length(logs) - NETRUN_MAX_LOG + 1)
	if(important)
		SSnetrun.ntnet_log("[short_name]: [text]", important)
	// Native logs are stored now; viewers need one notification for the whole
	// burst, rather than one global callback for every packet and patrol message.
	SSnetrun.queue_network_publication(src)

/// Легальный гостевой доступ в ЛВС по списку доступов
/datum/netrun_network/proc/legit_guest(list/access)
	if(!length(guest_access))
		return TRUE
	if(ACCESS_NETWORK in access)
		return TRUE
	for(var/needed in guest_access)
		if(needed in access)
			return TRUE
	return FALSE

/datum/netrun_network/proc/node_count_by_type()
	. = list()
	for(var/datum/component/netrun_node/node as anything in nodes)
		.[node.node_type] = (.[node.node_type] || 0) + 1

/// Ключ всей сети ценнее доступа к одному устройству: шлюз учитывает сильнейшего участника.
/datum/netrun_network/proc/breach_security()
	. = security
	for(var/datum/component/netrun_node/node as anything in nodes)
		. = max(., node.get_security())
	return clamp(., 1, 5)

/// Unbound endpoints retain an authorization domain but gain no synthetic graph edges.
/proc/netrun_fallback_network_for(turf/T)
	if(!T)
		return null
	if(!is_station_level(T.z) && !is_mining_level(T.z))
		return SSnetrun.get_network("ext[T.z]")
	return SSnetrun.get_network("pub:[netrun_sector_for(T)]")

/// Compatibility for clients without their own endpoint. Bound nodes keep their own cached APC.
/proc/netrun_network_for(turf/T)
	if(!T)
		return null
	var/datum/netrun_topology/topology = SSnetrun.get_topology()
	var/datum/component/netrun_node/apc = topology.nearest_apc(T)
	return apc ? SSnetrun.get_apc_network(apc) : netrun_fallback_network_for(T)

/// Доступы, которые несёт моб (ID в руке, на поясе/шее; у силиконов - всё)
/proc/netrun_mob_access(mob/user)
	RETURN_TYPE(/list)
	. = list()
	if(QDELETED(user))
		return
	if((issilicon(user) && !ispAI(user)) || IsAdminGhost(user))
		return get_all_accesses()
	if(ishuman(user))
		var/mob/living/carbon/human/H = user
		for(var/obj/item/I in list(H.get_active_held_item(), H.get_inactive_held_item(), H.wear_id, H.wear_neck))
			. |= I.GetAccess()
		return
	if(isliving(user))
		var/mob/living/L = user
		var/obj/item/held = L.get_active_held_item()
		if(held)
			. |= held.GetAccess()

// Кэш идентификатора ЛВС отсека, чтобы одна зона всегда давала одну сеть.
/area
	var/netrun_lan_id
