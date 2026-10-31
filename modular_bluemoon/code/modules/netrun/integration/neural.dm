// MARK: Интеграция с нейроинтерфейсом
//
// Нейролинк при установке подключается к /datum/component/neural_interface носителя:
// добавляет экранный модуль сетевой панели и два монитора - события связи и «сетевое зрение».

#define NETRUN_NEURAL_SOURCE "NETLINK"
#define NETRUN_NEURAL_MODULE "netrun"

/// Экранная панель нейролинка: связь, трассировка, выбранный узел, ход подбора доступа
/datum/neural_interface_module/netrun
	name = "NETLINK MODULE"
	// DATA starts at CENTER-2.5; place this 112px block beneath it with an 8px gap.
	var/screen_loc = "LEFT+1.5,CENTER-6.25"
	var/maptext_width = 225
	var/maptext_height = 112
	var/font_size = 12
	var/font_family = "TinyUnicode"
	var/separator_color = "#6b7280"
	var/atom/movable/screen/text/panel_view
	var/datum/netrun_console/console

/datum/neural_interface_module/netrun/New(datum/component/neural_interface/new_owner, datum/netrun_console/console)
	. = ..()
	src.console = console
	panel_view = ScreenText(null, "", screen_loc, maptext_height, maptext_width)

/datum/neural_interface_module/netrun/Destroy(force, ...)
	. = ..()
	QDEL_NULL(panel_view)
	console = null

/datum/neural_interface_module/netrun/UpdateVision(mob/user)
	if(!user?.client)
		return
	user.client.screen -= panel_view
	if(!visible || QDELETED(console))
		return
	panel_view.maptext = render()
	user.client.screen += panel_view

/datum/neural_interface_module/netrun/proc/line(text, color = "#d4dcea")
	return {"<span style='font-family: \"[font_family]\"; font-size: [font_size]pt; color: [color]; line-height: 0.8; -dm-text-outline: 1px black;'>[text]</span><br>"}

/datum/neural_interface_module/netrun/proc/render()
	return {"<table width='100%' height='100%' cellpadding='0' cellspacing='0'><tr><td valign='top' align='left'><div style='height:[maptext_height]px; overflow:hidden; text-align:left;'>[render_lines()]</div></td></tr></table>"}

/datum/neural_interface_module/netrun/proc/render_lines()
	var/write = line("├─ NETLINK", separator_color)
	if(console.is_locked())
		write += line("└ LOCKED: [CEILING((console.intrusion.lockout_until - world.time) / (1 SECONDS), 1)]s", "#ef4444ff")
		return write
	var/uplink = console.has_uplink()
	write += line("└ NTnet: [uplink ? "ONLINE" : "OFFLINE"]", uplink ? "#10b981ff" : "#ef4444ff")
	var/filled = round(console.intrusion.trace / 10)
	var/trace_color = console.intrusion.trace > 66 ? "#ef4444ff" : console.intrusion.trace > 33 ? "#f59e0bff" : "#4ad1fa86"
	write += line("└ TRACE \[[netrun_repeat("█", filled)][netrun_repeat("·", 10 - filled)]\] [round(console.intrusion.trace)]%", trace_color)
	var/datum/component/netrun_node/node = console.selected_node()
	if(node)
		write += line("└ TARGET: [node.address] [netrun_neural_access_name(console.node_level(node))]", "#a78bffff")
	if(console.intrusion.breach)
		write += line("└ BREACH: [length(console.intrusion.breach.buffer)]/[console.intrusion.breach.buffer_size] · [round(console.intrusion.breach.time_left() / (1 SECONDS))]s", "#d8ff4a")
	if(length(console.listening))
		write += line("└ STREAMS: [length(console.listening)]", "#06b6d4ff")
	return write

/proc/netrun_repeat(text, count)
	. = ""
	for(var/i in 1 to count)
		. += text

/// Display-only fallback for the HUD font. Source names, files and console logs stay intact.
/// Cyrillic becomes readable Latin text; other unsupported characters use an explicit U+ code.
/proc/netrun_neural_text(value, limit = 0)
	var/static/list/cyrillic = list(
		"а" = "a", "б" = "b", "в" = "v", "г" = "g", "д" = "d", "е" = "e", "ё" = "yo", "ж" = "zh",
		"з" = "z", "и" = "i", "й" = "y", "к" = "k", "л" = "l", "м" = "m", "н" = "n", "о" = "o",
		"п" = "p", "р" = "r", "с" = "s", "т" = "t", "у" = "u", "ф" = "f", "х" = "kh", "ц" = "ts",
		"ч" = "ch", "ш" = "sh", "щ" = "shch", "ъ" = "'", "ы" = "y", "ь" = "'", "э" = "e", "ю" = "yu", "я" = "ya",
	)
	var/text = "[value]"
	var/result = ""
	for(var/i in 1 to length_char(text))
		var/character = copytext_char(text, i, i + 1)
		var/codepoint = text2ascii(character)
		if(codepoint >= 32 && codepoint <= 126)
			result += character
		else if(character == "\n" || character == "\t")
			result += character
		else if(codepoint < 32 || codepoint == 127)
			result += " "
		else
			var/replacement = cyrillic[lowertext(character)]
			if(!isnull(replacement))
				result += character == uppertext(character) ? uppertext(replacement) : replacement
			else
				result += "U+[uppertext(num2hex(codepoint, codepoint > 65535 ? 6 : 4))]"
		if(limit && length(result) >= limit)
			result = copytext(result, 1, limit + 1)
			break
	return html_encode(result)

/proc/netrun_neural_access_name(level)
	switch(level)
		if(NETRUN_ACCESS_GUEST)
			return "GUEST"
		if(NETRUN_ACCESS_USER)
			return "USER"
		if(NETRUN_ACCESS_ROOT)
			return "ROOT"
	return "NONE"

// MARK: Мониторы

/// События связи: потеря NTnet, рост трассировки, блокировка
/datum/neural_monitor/netrun_link
	name = "NETLINK MONITOR"
	processing = TRUE
	var/last_uplink
	var/last_trace_band = 0
	var/last_locked = FALSE

/datum/neural_monitor/netrun_link/process(delta_time)
	if(!..())
		return FALSE
	var/obj/item/organ/cyberimp/brain/netlink/implant = monitor_atom
	if(!istype(implant) || !implant.console)
		return FALSE
	var/datum/netrun_console/console = implant.console
	var/uplink = console.has_uplink()
	if(!isnull(last_uplink) && uplink != last_uplink)
		owner.write_log(uplink ? "NTnet: connection restored" : "NTnet: connection lost", uplink ? "SYNC" : "WARNING")
	last_uplink = uplink
	var/band = console.intrusion.trace >= 80 ? 2 : console.intrusion.trace >= 50 ? 1 : 0
	if(band > last_trace_band)
		owner.write_log("Trace [round(console.intrusion.trace)]%", band == 2 ? "ALERT" : "WARNING")
	last_trace_band = band
	var/locked = console.is_locked()
	if(locked && !last_locked)
		owner.write_log("Access point locked", "ERROR")
	last_locked = locked
	return TRUE

/// «Сетевое зрение»: подсветка ближайших узлов с адресом и уровнем доступа
/datum/neural_monitor/netrun_vision
	name = "NETVISION MONITOR"
	processing = TRUE
	var/range = 5
	var/max_marks = 10
	var/icon/overlay_node

/datum/neural_monitor/netrun_vision/New(...)
	. = ..()
	overlay_node = new(icon = 'icons/effects/neural_interface_overlays.dmi', icon_state = "circle")

/datum/neural_monitor/netrun_vision/Destroy(force, ...)
	overlay_node = null
	return ..()

/datum/neural_monitor/netrun_vision/process(delta_time)
	if(!..())
		return FALSE
	var/obj/item/organ/cyberimp/brain/netlink/implant = monitor_atom
	var/mob/living/carbon/user = implant?.owner
	if(!istype(implant) || !user || user.stat != CONSCIOUS || !implant.console)
		return FALSE
	var/datum/netrun_console/console = implant.console
	var/turf/center = get_turf(user)
	var/list/found = list()
	for(var/atom/A in view(range, user))
		var/datum/component/netrun_node/node = A.GetComponent(/datum/component/netrun_node)
		if(!node)
			continue
		found[node] = get_dist(center, A)
		if(length(found) >= max_marks * 3)
			break
	sortTim(found, GLOBAL_PROC_REF(cmp_numeric_asc), associative = TRUE)
	var/shown = 0
	for(var/datum/component/netrun_node/node as anything in found)
		if(shown >= max_marks)
			break
		var/level = console.node_level(node)
		if(level < NETRUN_ACCESS_GUEST)
			continue
		shown++
		var/image/overlay = image(icon = overlay_node)
		overlay.color = netrun_access_color(level, node.is_online())
		owner.write_image_data("\ref[node]:NETVISION", overlay, node.parent, "[node.address]\n[netrun_neural_access_name(level)]", 1.5 SECONDS, 24, -6, 12)
	return TRUE

/proc/netrun_access_color(level, online = TRUE)
	if(!online)
		return "#ff5c6c"
	switch(level)
		if(NETRUN_ACCESS_GUEST)
			return "#8b93a3"
		if(NETRUN_ACCESS_USER)
			return "#4ac0ff"
		if(NETRUN_ACCESS_ROOT)
			return "#3cdc8c"
	return "#59606e"

// MARK: Подключение нейролинка

/obj/item/organ/cyberimp/brain/netlink
	var/datum/component/neural_interface/interface

/obj/item/organ/cyberimp/brain/netlink/Insert(mob/living/carbon/M, special = FALSE, drop_if_replaced = TRUE)
	. = ..()
	if(!. || !owner)
		return
	console.operator = owner
	var/datum/component/netrun_node/node = GetComponent(/datum/component/netrun_node)
	node?.refresh_physical_host()
	attach_interface()

/obj/item/organ/cyberimp/brain/netlink/Remove(special = FALSE)
	detach_interface()
	return ..()

/obj/item/organ/cyberimp/brain/netlink/proc/attach_interface()
	if(interface || !owner)
		return
	interface = owner.LoadComponent(/datum/component/neural_interface)
	if(!interface)
		return
	RegisterSignal(interface, COMSIG_PARENT_QDELETING, PROC_REF(on_interface_qdel), override = TRUE)
	interface.AddSource(NETRUN_NEURAL_SOURCE)
	if(!interface.modules[NETRUN_NEURAL_MODULE])
		var/datum/neural_interface_module/netrun/module = new(interface, console)
		if(!interface.visible)
			module.visible = FALSE
		interface.modules[NETRUN_NEURAL_MODULE] = module
	interface.add_monitor_by_type(NETRUN_NEURAL_SOURCE, /datum/neural_monitor/netrun_link, src)
	interface.add_monitor_by_type(NETRUN_NEURAL_SOURCE, /datum/neural_monitor/netrun_vision, src)
	interface.write_log("Netlink connected", "MODULE")

/obj/item/organ/cyberimp/brain/netlink/proc/detach_interface()
	if(!interface)
		return
	var/datum/component/neural_interface/old = interface
	interface = null
	UnregisterSignal(old, COMSIG_PARENT_QDELETING)
	if(QDELETED(old))
		return
	var/datum/neural_interface_module/module = old.modules[NETRUN_NEURAL_MODULE]
	if(module)
		old.modules -= NETRUN_NEURAL_MODULE
		qdel(module)
	old.RemoveSource(NETRUN_NEURAL_SOURCE)

/obj/item/organ/cyberimp/brain/netlink/proc/on_interface_qdel(datum/source)
	SIGNAL_HANDLER
	interface = null

/obj/item/organ/cyberimp/brain/netlink/netrun_console_event(datum/netrun_console/event_console, text, kind)
	if(!interface || QDELETED(interface))
		return
	var/key = "DATA"
	switch(kind)
		if("good")
			key = "INFO"
		if("bad")
			key = "ERROR"
		if("average")
			key = "WARNING"
	// В поток логов уходит только первая строка - панель маленькая
	var/first = splittext("[text]", "\n")[1]
	SEND_SIGNAL(interface, COMSIG_NEURAL_INTERFACE_WRITE_LOG, netrun_neural_text(first, 60), key)

#undef NETRUN_NEURAL_SOURCE
#undef NETRUN_NEURAL_MODULE
