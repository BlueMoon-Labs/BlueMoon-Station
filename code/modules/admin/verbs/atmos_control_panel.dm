/// Живая панель SSair. Раньше интерфейс AtmosControlPanel лежал в tgui без
/// единого владельца в DM: его писали под auxmos, а после перехода на чистый
/// DM открывать окно стало нечем. Панель показывает то, что в этой ветке
/// действительно есть - счётчики фаз, рычаг скорости и переключатели.
GLOBAL_DATUM_INIT(atmos_control_panel, /datum/atmos_control_panel, new)

/// Сколько зон показывать в таблице самых шумных областей.
#define ATMOS_PANEL_TOP_AREAS 12

/datum/atmos_control_panel

/datum/atmos_control_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/atmos_control_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AtmosControlPanel", "Панель SSair")
		ui.open()

/datum/atmos_control_panel/ui_data(mob/user)
	var/list/data = list()

	data["fire_count"] = SSair.times_fired
	data["wait"] = SSair.wait
	data["base_wait"] = initial(SSair.wait)
	data["atmos_speed"] = SSair.atmos_speed
	data["speed_min"] = ATMOS_SPEED_MULTIPLIER_MIN
	data["speed_max"] = ATMOS_SPEED_MULTIPLIER_MAX
	data["lag_scale"] = SSair.lag_scale
	data["heat_enabled"] = SSair.heat_enabled
	data["equalize_enabled"] = SSair.equalize_enabled
	data["equalize_valve_mode"] = SSair.equalize_valve_mode
	data["sleeping_edges_enabled"] = SSair.sleeping_edges_enabled
	data["log_decompression"] = SSair.log_explosive_decompression

	data["counters"] = list(
		list("name" = "Активные турфы", "value" = length(SSair.active_turfs)),
		list("name" = "Возбуждённые группы", "value" = length(SSair.excited_groups)),
		list("name" = "Горячие точки", "value" = length(SSair.hotspots)),
		list("name" = "Теплопроводность", "value" = length(SSair.active_super_conductivity)),
		list("name" = "Атмос-машины в работе", "value" = length(SSair.atmos_machinery)),
		list("name" = "Атмос-машины спят", "value" = SSair.idle_machine_count()),
		list("name" = "Пайпнеты", "value" = length(SSair.networks)),
		list("name" = "Зоны разгерметизации", "value" = length(SSair.decompression_areas)),
	)

	data["costs"] = list(
		list("name" = "Полный проход", "value" = SSair.cost_full.to_string()),
		list("name" = "Турфы", "value" = "[round(SSair.cost_turfs_last, 0.1)]"),
		list("name" = "Группы", "value" = "[round(SSair.cost_groups, 0.1)]"),
		list("name" = "Эквализация", "value" = "[round(SSair.cost_equalize, 0.1)]"),
		list("name" = "Разгерметизация", "value" = "[round(SSair.cost_decompression, 0.1)]"),
		list("name" = "Высокое давление", "value" = "[round(SSair.cost_highpressure, 0.1)]"),
		list("name" = "Горячие точки", "value" = "[round(SSair.cost_hotspots, 0.1)]"),
		list("name" = "Теплопроводность", "value" = "[round(SSair.cost_superconductivity, 0.1)]"),
		list("name" = "Пайпнеты", "value" = "[round(SSair.cost_pipenets, 0.1)]"),
		list("name" = "Машинерия", "value" = "[round(SSair.cost_atmos_machinery, 0.1)]"),
		list("name" = "Атомы", "value" = "[round(SSair.cost_atmos_atoms, 0.1)]"),
	)

	data["areas"] = build_area_breakdown()
	return data

///Топ областей по числу активных турфов. То же, что вываливал в чат
///"Atmos Active Turfs Report", но живьём и с прыжком по клику.
/datum/atmos_control_panel/proc/build_area_breakdown()
	var/list/buckets = list()
	for(var/turf/open/active_turf as anything in SSair.active_turfs)
		if(!istype(active_turf))
			continue
		var/area/turf_area = active_turf.loc
		if(!turf_area)
			continue
		var/list/bucket = buckets[turf_area]
		if(!bucket)
			bucket = list("count" = 0, "sharing" = 0, "planetary" = 0, "sample" = active_turf)
			buckets[turf_area] = bucket
		bucket["count"]++
		if(active_turf.planetary_atmos)
			bucket["planetary"]++
		if(active_turf.air?.last_share > MINIMUM_MOLES_DELTA_TO_MOVE)
			bucket["sharing"]++

	var/list/rows = list()
	var/shown = 0
	while(shown < ATMOS_PANEL_TOP_AREAS && length(buckets))
		var/area/best_area
		var/best_count = 0
		for(var/area/candidate as anything in buckets)
			var/list/bucket = buckets[candidate]
			if(bucket["count"] > best_count)
				best_count = bucket["count"]
				best_area = candidate
		if(!best_area)
			break
		var/list/best = buckets[best_area]
		var/turf/sample = best["sample"]
		rows += list(list(
			"name" = "[best_area.name]",
			"count" = best["count"],
			"sharing" = best["sharing"],
			"planetary" = best["planetary"],
			"ref" = REF(sample),
		))
		buckets -= best_area
		shown++
	return rows

///Правки рычагов подсистемы видит вся админка, а не только тот, кто нажал.
/datum/atmos_control_panel/proc/announce_change(client/user_client, message)
	var/full = "[key_name(user_client)] [message]."
	log_admin(full)
	message_admins(full)

/datum/atmos_control_panel/ui_act(action, list/params, datum/tgui/ui)
	. = ..()
	if(.)
		return
	var/client/user_client = ui.user?.client
	if(!user_client?.holder)
		return
	switch(action)
		if("speed")
			var/new_speed = text2num(params["value"])
			if(isnull(new_speed))
				return
			SSair.set_atmos_speed(new_speed)
			announce_change(user_client, "set the atmos speed lever to [SSair.atmos_speed] (cadence [SSair.wait] ds)")
			return TRUE
		if("toggle_heat")
			SSair.set_heat_enabled(!SSair.heat_enabled)
			announce_change(user_client, "turned atmos heat conduction [SSair.heat_enabled ? "ON" : "OFF"]")
			return TRUE
		if("toggle_equalize")
			SSair.equalize_enabled = !SSair.equalize_enabled
			announce_change(user_client, "turned atmos equalization [SSair.equalize_enabled ? "ON" : "OFF"]")
			return TRUE
		if("toggle_sleeping_edges")
			SSair.sleeping_edges_enabled = !SSair.sleeping_edges_enabled
			announce_change(user_client, "turned atmos sleeping edges [SSair.sleeping_edges_enabled ? "ON" : "OFF"]")
			return TRUE
		if("toggle_decompression_log")
			SSair.log_explosive_decompression = !SSair.log_explosive_decompression
			return TRUE
		if("jump")
			var/turf/target = locate(params["ref"])
			if(!isturf(target))
				return
			user_client.jumptoturf(target)
			return TRUE

/datum/admins/proc/atmos_control_panel()
	set category = "Debug.3) Fixing"
	set desc = "Live SSair counters, phase costs and the speed lever."
	set name = "Atmos Control Panel"

	GLOB.atmos_control_panel.ui_interact(usr)

#undef ATMOS_PANEL_TOP_AREAS
