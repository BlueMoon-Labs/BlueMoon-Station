/// A MOD controller is a mobile endpoint; the suit, modules and native controller retain ownership.
/obj/item/mod/control
	var/netrun_firewall_cd = 0
	var/netrun_intrusion_warning_until = 0
	var/list/netrun_last_state

/obj/item/mod/control/Initialize(mapload, new_theme, new_skin, list/parts)
	. = ..()
	AddComponent(/datum/component/netrun_node, NETRUN_NODE_MODSUIT, list("mod_status", "mod_lights", "mod_module_stop"), 3, list(ACCESS_ROBOTICS))
	new /datum/action/item_action/mod/netrun_firewall(src)

/obj/item/mod/control/Destroy()
	netrun_last_state = null
	return ..()

/obj/item/mod/control/netrun_physical_host()
	return wearer || src

/obj/item/mod/control/proc/netrun_controller_owner(datum/netrun_console/console)
	var/mob/user = netrun_console_owner(console)
	return user && (user == wearer || user == ai)

/obj/item/mod/control/netrun_owner_access(datum/netrun_console/console)
	return netrun_controller_owner(console) ? NETRUN_ACCESS_ROOT : NETRUN_ACCESS_NONE

/obj/item/mod/control/netrun_online(remote = TRUE)
	var/obj/item/stock_parts/cell/cell = get_cell()
	return cell?.charge > 0 && !is_malfunctioning() && !interface_break

/obj/item/mod/control/netrun_status()
	var/obj/item/stock_parts/cell/cell = get_cell()
	return list(
		"Системы: [is_active() ? "включены" : "выключены"][is_activating() ? " (переключение)" : ""]",
		"Батарея: [cell ? round(cell.percent(), 0.1) : 0]%",
		"Панель обслуживания: [is_open() ? "открыта" : "закрыта"]",
		"Носитель: [wearer ? wearer.name : "отсутствует"]",
		"Модули: [length(modules)], сложность [complexity]/[complexity_max]",
	)

/obj/item/mod/control/set_wearer(mob/user)
	. = ..()
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	node?.refresh_physical_host()
	netrun_publish_state()

/obj/item/mod/control/unset_wearer()
	. = ..()
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	node?.refresh_physical_host()
	netrun_publish_state()

/obj/item/mod/control/process(delta_time)
	. = ..()
	netrun_publish_state()

/obj/item/mod/control/finish_activation(on)
	. = ..()
	netrun_publish_state()

/obj/item/mod/control/install(module, mob/user)
	. = ..()
	netrun_publish_state()

/obj/item/mod/control/uninstall(module, user, deleting = FALSE)
	. = ..()
	netrun_publish_state()

/obj/item/mod/control/toggle_state(flag)
	. = ..()
	netrun_publish_state()

/obj/item/mod/control/disable_emp_status()
	. = ..()
	netrun_publish_state()

/// Publish meaningful status changes, rather than one UI update for every power-processing tick.
/obj/item/mod/control/proc/netrun_publish_state()
	if(QDELETED(src))
		return
	var/obj/item/stock_parts/cell/cell = get_cell()
	var/list/current = list(wearer, ai, cell, cell ? round(cell.percent()) : 0, is_active(), is_activating(), is_open(), is_malfunctioning(), interface_break, selected_module, length(modules))
	if(netrun_last_state && netrun_snapshot_equal(netrun_last_state, current))
		return
	netrun_last_state = current
	SEND_SIGNAL(src, COMSIG_NETRUN_SERVICE_STATE_CHANGED)

/obj/item/mod/control/netrun_on_illegal(datum/netrun_console/console, datum/component/netrun_node/node)
	if(!wearer || world.time < netrun_intrusion_warning_until)
		return
	netrun_intrusion_warning_until = world.time + 8 SECONDS
	to_chat(wearer, span_userdanger("ТРЕВОГА MOD: обнаружено внешнее вмешательство в контроллер. Поднимите сетевой экран костюма!"))
	SEND_SOUND(wearer, sound('sound/machines/triple_beep.ogg', volume = 50))

/obj/item/mod/control/proc/netrun_raise_firewall(mob/user)
	if(user != wearer && user != ai)
		return FALSE
	if(world.time < netrun_firewall_cd)
		to_chat(user, span_warning("Сетевой экран MOD ещё перезаряжается."))
		return FALSE
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	if(!node)
		return FALSE
	netrun_firewall_cd = world.time + 1 MINUTES
	node.raise_firewall(20 SECONDS)
	to_chat(user, span_notice("Сетевой экран MOD поднят: внешние доступы сброшены на 20 секунд."))
	return TRUE

/datum/action/item_action/mod/netrun_firewall
	name = "Сетевой экран MOD"
	desc = "Отозвать внешние сетевые доступы и усилить защиту костюма на 20 секунд. Перезарядка — минута."
	button_icon_state = "panel"

/datum/action/item_action/mod/netrun_firewall/Trigger(trigger_flags)
	if(!IsAvailable())
		return FALSE
	return mod?.netrun_raise_firewall(owner)

/// Only explicitly supported utility modules may be operated by remote network users.
/obj/item/mod/module/proc/netrun_remote_utility()
	return FALSE

/obj/item/mod/module/flashlight/netrun_remote_utility()
	return TRUE

/obj/item/mod/module/visor/netrun_remote_utility()
	return TRUE

/obj/item/mod/module/t_ray/netrun_remote_utility()
	return TRUE

/obj/item/mod/control/proc/netrun_module_denial(obj/item/mod/module/module)
	if(QDELETED(module) || !(module in modules) || module.mod != src || !module.netrun_remote_utility())
		return "Модуль не установлен или не поддерживает сетевое управление."
	if(!wearer)
		return "Наденьте контроллер MOD в штатный слот."
	if(is_open() || is_activating())
		return "Закройте сервисную панель и завершите переключение костюма."
	if(!is_active() && !module.allowed_inactive)
		return "Сначала включите системы костюма."
	if(!COOLDOWN_FINISHED(module, cooldown_current_timer))
		return "Модуль ещё перезаряжается."
	if(!module.check_required_modpart())
		return "Сначала разверните нужную часть костюма."
	if(!module.check_minimum_cell_charge())
		return "Заряда батареи недостаточно для этого модуля."
	return null

/obj/item/mod/control/proc/netrun_toggle_utility(obj/item/mod/module/module, datum/netrun_console/console)
	var/reason = netrun_module_denial(module)
	if(reason)
		console?.log_line(reason, "bad")
		return FALSE
	var/previous = module.active
	module.on_select()
	SEND_SIGNAL(src, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
	return module.active != previous

/obj/item/mod/control/proc/netrun_flashlight()
	for(var/obj/item/mod/module/flashlight/light as anything in modules)
		if(istype(light))
			return light
	return null

/datum/netrun_provider/modsuit
	atom_type = /obj/item/mod/control
	interface_name = "MODsuit"
	state_signals = list(COMSIG_MOD_MODULE_SELECTED, COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED, COMSIG_ATOM_UPDATED_ICON, COMSIG_UI_ACT)
	actions = list(
		"lights" = list("name" = "Переключить фонарь", "desc" = "Штатное управление фонарём; нужны развёрнутый шлем и питание.", "access" = NETRUN_ACCESS_USER),
		"select_module" = list("name" = "Переключить служебный модуль", "desc" = "Выберите готовый фонарь, визор или T-ray из установленных модулей.", "access" = NETRUN_ACCESS_USER, "params" = list(list("id" = "module", "name" = "Модуль", "type" = "text"))),
		"light_range" = list("name" = "Дальность фонаря", "desc" = "Настроить дальность света штатным контроллером.", "access" = NETRUN_ACCESS_USER, "params" = list(list("id" = "range", "name" = "Дальность", "type" = "number", "min" = 2, "max" = 5))),
		"module_stop" = list("name" = "Отключить служебные модули", "desc" = "Отключить фонарь, визор и T-ray, сохранив силовые и защитные системы.", "access" = NETRUN_ACCESS_ROOT, "danger" = TRUE),
		"notify" = list("name" = "Сообщить носителю", "desc" = "Отправить короткое сообщение на дисплей костюма.", "access" = NETRUN_ACCESS_USER, "params" = list(list("id" = "message", "name" = "Сообщение", "type" = "text"))),
		"toggle_power" = list("name" = "Переключить системы MOD", "desc" = "Штатное включение/выключение с герметизацией: только носитель или установленный ИИ.", "access" = NETRUN_ACCESS_ROOT, "danger" = TRUE),
		"firewall" = list("name" = "Поднять сетевой экран", "desc" = "Отозвать внешние доступы к костюму. Только носитель или установленный ИИ.", "access" = NETRUN_ACCESS_ROOT),
	)

/datum/netrun_provider/modsuit/action_unavailable_reason(atom/target, action, datum/netrun_console/console, datum/component/netrun_node/node)
	. = ..()
	if(.)
		return
	var/obj/item/mod/control/suit = target
	if(!suit.netrun_online())
		return "Контроллер MOD обесточен или повреждён ЭМИ."
	if(action == "firewall")
		if(!suit.netrun_controller_owner(console))
			return "Сетевой экран доступен только носителю или установленному ИИ."
		if(world.time < suit.netrun_firewall_cd)
			return "Сетевой экран ещё перезаряжается."
		return null
	if(action == "notify")
		return suit.wearer ? null : "В костюме нет носителя."
	if(!suit.wearer || suit.is_open() || suit.is_activating())
		return "Костюм должен быть надет, сервисная панель закрыта, переключение завершено."
	if(action == "toggle_power")
		if(!suit.netrun_controller_owner(console))
			return "Включение и разгерметизация доступны только носителю или установленному ИИ."
		if(!suit.is_active() && !suit.can_activate())
			return "Штатный контроллер требует сначала развернуть части костюма."
	if(action == "lights" || action == "light_range")
		var/obj/item/mod/module/flashlight/light = suit.netrun_flashlight()
		if(!light)
			return "В костюме нет фонаря."
		if(action == "lights")
			return suit.netrun_module_denial(light)
	return null

/// Instance-specific choices belong to this payload, never to the shared provider schema.
/datum/netrun_provider/modsuit/payload(atom/target, datum/netrun_console/console, datum/component/netrun_node/node)
	. = ..()
	if(!.)
		return
	var/obj/item/mod/control/suit = target
	var/list/options = list()
	for(var/obj/item/mod/module/module as anything in suit.modules)
		if(module.netrun_remote_utility() && !suit.netrun_module_denial(module))
			options += list(list("value" = REF(module), "name" = "[module.name] — [module.active ? "включён" : "выключен"]"))
	for(var/list/entry as anything in .["actions"])
		if(entry["id"] != "select_module")
			continue
		var/list/params = list()
		for(var/list/param as anything in entry["params"])
			var/list/copy = param.Copy()
			copy["options"] = options
			if(length(options))
				var/list/first = options[1]
				copy["value"] = first["value"]
			params += list(copy)
		entry["params"] = params
		if(!length(options))
			entry["allowed"] = FALSE
			entry["reason"] = "Нет готовых служебных модулей. Проверьте питание и развёртывание частей костюма."

/datum/netrun_provider/modsuit/read_data(atom/target, datum/netrun_console/console, datum/component/netrun_node/node)
	var/obj/item/mod/control/suit = target
	var/obj/item/stock_parts/cell/cell = suit.get_cell()
	var/list/installed = list()
	for(var/obj/item/mod/module/module as anything in suit.modules)
		installed += list(list("name" = module.name, "active" = module.active, "remote_utility" = module.netrun_remote_utility(), "selected" = module == suit.selected_module))
	return list("active" = suit.is_active(), "charge" = cell ? round(cell.percent(), 0.1) : 0, "wearer" = suit.wearer?.name, "open" = suit.is_open(), "modules" = installed)

/datum/netrun_provider/modsuit/execute(atom/target, action, list/arguments, datum/netrun_console/console, datum/component/netrun_node/node)
	if(action_unavailable_reason(target, action, console, node))
		return FALSE
	var/obj/item/mod/control/suit = target
	if(console.legit_node_level(node) < action_access(action))
		suit.netrun_on_illegal(console, node)
	switch(action)
		if("lights")
			return suit.netrun_toggle_utility(suit.netrun_flashlight(), console)
		if("select_module")
			var/obj/item/mod/module/module = locate(arguments["module"]) in suit.modules
			return suit.netrun_toggle_utility(module, console)
		if("light_range")
			var/obj/item/mod/module/flashlight/light = suit.netrun_flashlight()
			light.configure_edit("light_range", arguments["range"])
		if("module_stop")
			for(var/obj/item/mod/module/module as anything in suit.modules)
				if(module.active && module.netrun_remote_utility())
					module.on_deactivation()
		if("notify")
			var/message = html_encode(trim(copytext_char(arguments["message"], 1, 161)))
			if(!length(message))
				return FALSE
			suit.send_modsuit_message(suit.wearer, "СЕТЬ · [html_encode(console.get_handle())]", message)
		if("toggle_power")
			return suit.toggle_activate(console.operator)
		if("firewall")
			return suit.netrun_raise_firewall(console.operator)
		else
			return FALSE
	SEND_SIGNAL(suit, COMSIG_NETRUN_SERVICE_STATE_CHANGED)
	return TRUE

/datum/netrun_command/mod_status
	id = "mod_status"
	read_only = TRUE
	name = "Диагностика MOD"
	desc = "Получить питание, состояние контроллера и список установленных модулей костюма."
	access = NETRUN_ACCESS_USER
	trace = 2
	icon = "user-astronaut"

/datum/netrun_command/mod_status/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/item/mod/control/suit = node.parent
	var/list/lines = suit.netrun_status()
	for(var/obj/item/mod/module/module as anything in suit.modules)
		lines += "[module.name]: [module.active ? "включён" : "выключен"][module.netrun_remote_utility() ? " (сетевое управление)" : ""]"
	return jointext(lines, "\n")

/datum/netrun_command/mod_lights
	id = "mod_lights"
	name = "Фонарь MOD"
	desc = "Переключить установленный фонарь через штатный контроллер MOD."
	access = NETRUN_ACCESS_USER
	trace = 4
	icon = "lightbulb"

/datum/netrun_command/mod_lights/ui_entry(datum/component/netrun_node/node, datum/netrun_console/console, full_id)
	. = ..()
	if(!.["allowed"])
		return
	var/obj/item/mod/control/suit = node.parent
	var/reason = suit.netrun_module_denial(suit.netrun_flashlight())
	if(reason)
		.["allowed"] = FALSE
		.["unavailable_reason"] = reason

/datum/netrun_command/mod_lights/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/obj/item/mod/control/suit = node.parent
	if(!suit.netrun_toggle_utility(suit.netrun_flashlight(), console))
		return null
	return "Фонарь MOD переключён."

/datum/netrun_command/mod_module_stop
	id = "mod_module_stop"
	name = "Остановить модули MOD"
	desc = "Отключить только служебные модули: фонарь, визор и T-ray."
	help = "Силовые модули, тяга, магнитные ботинки и герметизация этим запросом не затрагиваются."
	access = NETRUN_ACCESS_ROOT
	trace = 8
	danger = TRUE
	icon = "power-off"

/datum/netrun_command/mod_module_stop/execute(datum/component/netrun_node/node, datum/netrun_console/console)
	var/datum/netrun_provider/provider = SSnetrun.get_provider(node.parent)
	if(!provider?.execute(node.parent, "module_stop", list(), console, node))
		return null
	return "Служебные модули MOD отключены."
