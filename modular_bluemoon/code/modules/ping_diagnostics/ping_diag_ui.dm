/// Окно диагностики одного зрителя. Админ может переключить его на другого игрока.
/datum/ping_diag_ui
	/// Владелец окна: на его логауте окно закрывается.
	var/client/viewer
	/// Чьё соединение смотрим. Клиента не держим: игрок может выйти, пока окно открыто.
	var/target_ckey
	/// Датум, на котором висит наблюдение: у перезашедшей цели датум новый.
	var/datum/ping_diagnostics/watched_diag
	var/tab = "self"

/datum/ping_diag_ui/New(client/viewer)
	src.viewer = viewer
	set_target(viewer)

/datum/ping_diag_ui/Destroy()
	set_target(null)
	if(viewer?.ping_diag_ui == src)
		viewer.ping_diag_ui = null
	viewer = null
	return ..()

/datum/ping_diag_ui/proc/get_target()
	RETURN_TYPE(/client)
	return target_ckey ? GLOB.directory[target_ckey] : null

/datum/ping_diag_ui/proc/set_target(client/new_target)
	SSping_diag.unwatch(watched_diag)
	watched_diag = null
	target_ckey = new_target?.ckey
	if(new_target)
		watched_diag = SSping_diag.watch(new_target)

/datum/ping_diag_ui/proc/is_staff()
	if(!viewer)
		return FALSE
	return check_rights_for(viewer, R_ADMIN) || check_rights_for(viewer, R_DEBUG)

/datum/ping_diag_ui/proc/set_tab(new_tab)
	if(!(new_tab in list("self", "server")))
		return FALSE
	if(new_tab == "server" && !is_staff())
		return FALSE
	tab = new_tab
	return TRUE

/// Текст отчёта приходит от клиента: только экранированный и не длиннее предела.
/proc/ping_diag_report_html(text)
	text = copytext_char("[text]", 1, PING_DIAG_REPORT_MAX_LEN + 1)
	return examine_block(replacetext(html_encode(text), "\n", "<br>"))

/datum/ping_diag_ui/ui_state(mob/user)
	return GLOB.always_state

/datum/ping_diag_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PingDiagnostics")
		ui.open()

/datum/ping_diag_ui/ui_close(mob/user)
	qdel(src)

/datum/ping_diag_ui/ui_data(mob/user)
	var/list/data = list()
	var/staff = is_staff()
	var/client/target = get_target()
	// Цель вышла или зритель потерял права: окно возвращается на зрителя.
	if(!target || (target != viewer && !staff))
		set_target(viewer)
		target = viewer
	else if(target.ping_diag != watched_diag)
		set_target(target)
	data["staff"] = staff
	data["tab"] = tab
	data["hint_enabled"] = !(viewer?.prefs?.chat_toggles & CHAT_NO_PING_HINT)
	data["server_rtt_median"] = round(SSping_diag.server_rtt_median, 1)
	data["server_base_median"] = round(SSping_diag.server_base_median, 1)
	data["server_clients"] = SSping_diag.clients_with_data()
	var/datum/ping_diagnostics/diag = target?.ping_diag
	if(diag)
		var/now = REALTIMEOFDAY
		diag.recompute(now, SSping_diag.server_base_median, SSping_diag.warn_build_code())
		data["target"] = target.ckey
		data["self"] = target == viewer
		data["verdicts"] = diag.verdicts
		data["stats"] = diag.summary
		data["old_build"] = ping_diag_old_build(diag.summary)
		data["percentile"] = SSping_diag.rtt_percentile_of(diag.summary["rtt_median"] || 0)
		data["graph"] = diag.graph_points(now)
		data["byond"] = "[target.byond_version].[target.byond_build]"
	if(tab == "server" && staff)
		data["clients"] = SSping_diag.client_rows()
		data["events"] = SSping_diag.events
		data["round"] = SSping_diag.round_summary()
	return data

/datum/ping_diag_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	switch(action)
		if("tab")
			return set_tab(params["tab"])
		if("inspect")
			if(!is_staff())
				return
			var/client/new_target = GLOB.directory[ckey(params["ckey"])]
			if(new_target)
				set_target(new_target)
				tab = "self"
			return TRUE
		if("reset_target")
			set_target(viewer)
			return TRUE
		if("toggle_hint")
			if(!viewer?.prefs)
				return
			viewer.prefs.chat_toggles ^= CHAT_NO_PING_HINT
			viewer.prefs.save_pref_var("chat_toggles")
			return TRUE
		if("report")
			if(!viewer)
				return
			to_chat(viewer, ping_diag_report_html(params["text"]))
			return TRUE
