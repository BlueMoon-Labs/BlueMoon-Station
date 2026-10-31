/// Клиент сети для модульных компьютеров: легальная работа с узлами по своему ID
/datum/computer_file/program/netrun
	filename = "netcommander"
	filedesc = "NetCommander"
	category = PROGRAM_CATEGORY_ENGI
	program_icon_state = "generic"
	program_icon = "network-wired"
	extended_desc = "Клиент локальных сетей станции: карта узлов, журналы и управление машинами в пределах вашего доступа."
	size = 8
	requires_ntnet = TRUE
	usage_flags = PROGRAM_ALL
	tgui_id = "NtosNetrun"
	var/datum/netrun_console/console
	var/allow_breach = FALSE

/datum/computer_file/program/netrun/Destroy()
	QDEL_NULL(console)
	return ..()

/datum/computer_file/program/netrun/clone()
	var/datum/computer_file/program/netrun/temp = ..()
	temp.allow_breach = allow_breach
	return temp

/datum/computer_file/program/netrun/ui_interact(mob/user, datum/tgui/ui)
	. = ..()
	ui = SStgui.get_open_ui(user, src)
	if(ui)
		ui.set_autoupdate(FALSE)

/datum/computer_file/program/netrun/proc/get_console()
	if(!computer)
		return
	if(console && console.host != computer)
		QDEL_NULL(console)
	if(!console)
		console = new(computer, NETRUN_ORIGIN_NTOS)
		console.connection.wireless = TRUE
		console.intrusion.can_breach = allow_breach
		console.inventory.local_store.capacity = 4 * NETRUN_STORAGE_SCALE
	return console

/datum/computer_file/program/netrun/ui_data(mob/user)
	var/list/data = get_header_data()
	var/datum/netrun_console/active = get_console()
	if(active)
		data += active.ui_data(user, src)
	return data

/datum/computer_file/program/netrun/ui_static_data(mob/user)
	var/list/data = ..()
	var/datum/netrun_console/active = get_console()
	if(active)
		data += active.ui_static_data(user)
	return data

/datum/computer_file/program/netrun/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/datum/netrun_console/active = get_console()
	if(active)
		return active.ui_act(action, params, ui, state)

/// Та же программа с модулем взлома - только с SyndiNet
/datum/computer_file/program/netrun/breach
	filename = "netbreach"
	filedesc = "NetBreach"
	program_icon = "user-secret"
	extended_desc = "Модифицированный сетевой клиент с модулем подбора кодов доступа. Распространяется через SyndiNet."
	size = 14
	available_on_ntnet = FALSE
	available_on_syndinet = TRUE
	allow_breach = TRUE
