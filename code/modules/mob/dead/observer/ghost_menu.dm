GLOBAL_DATUM_INIT(ghost_menu, /datum/ghost_menu, new)
GLOBAL_DATUM_INIT(minigames_menu, /datum/minigames_menu, new)

/// Darkness levels a ghost can pick between, keyed by display name.
/// Maps to LIGHTING_CUTOFF_* defines. Higher number = darker.
GLOBAL_LIST_INIT(ghost_lightings, list(
	"Normal" = LIGHTING_CUTOFF_VISIBLE,
	"Darker" = LIGHTING_CUTOFF_LOW,
	"Night Vision" = LIGHTING_CUTOFF_HIGH,
	"Fullbright" = LIGHTING_CUTOFF_FULLBRIGHT,
))

/**
 * The ghost settings window: DNR, night vision, ghost vision, view range.
 *
 * Deliberately smaller than Nova's GhostMenu — Shitcode has no ghost_hud_flags
 * system, so the HUD toggles are left out rather than faked. Everything here
 * maps onto something the observer already has.
 */
/datum/ghost_menu

/datum/ghost_menu/ui_state(mob/user)
	return GLOB.observer_state

/datum/ghost_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GhostMenu")
		ui.open()

/datum/ghost_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/dead/observer/dead_user = ui.user
	if(!istype(dead_user))
		return
	switch(action)
		if("DNR")
			dead_user.stay_dead()
			return TRUE
		if("return_to_body")
			dead_user.reenter_corpse()
			return TRUE
		if("darkness")
			var/darkness_type = params["darkness_level"]
			if(isnull(darkness_type) || !(darkness_type in GLOB.ghost_lightings))
				return FALSE
			if(dead_user.lighting_cutoff == GLOB.ghost_lightings[darkness_type])
				return FALSE
			dead_user.lighting_cutoff = GLOB.ghost_lightings[darkness_type]
			dead_user.update_sight()
			return TRUE
		if("toggle_ghost_vision")
			dead_user.ghostvision = !dead_user.ghostvision
			dead_user.update_sight()
			to_chat(dead_user, span_notice("You [(dead_user.ghostvision ? "now" : "no longer")] have ghost vision."))
			return TRUE
		if("view_range")
			// Severed from the UI: the observer's client.view_size blows up on the
			// wider settings, taking the whole options window's TGUI with it.
			return FALSE
		if("toggle_notification")
			var/notify_key = params["key"]
			if(notify_key && islist(GLOB.poll_ignore[notify_key]))
				GLOB.poll_ignore[notify_key] ^= list(dead_user.ckey)
				return TRUE
			return FALSE
		if("manifest")
			if(!GLOB.crew_manifest_tgui)
				GLOB.crew_manifest_tgui = new /datum/crew_manifest(dead_user)
			GLOB.crew_manifest_tgui.ui_interact(dead_user)
			return TRUE
		if("signup_pai")
			SSpai.recruitWindow(dead_user, null)
			return TRUE
		if("toggle_data_huds")
			dead_user.toggle_data_huds()
			return TRUE
		if("toggle_health_scan")
			dead_user.health_scan = !dead_user.health_scan
			to_chat(dead_user, span_notice("Health scan is now [(dead_user.health_scan ? "ON" : "OFF")]. Click a creature to scan it."))
			return TRUE
		if("toggle_reagent_scan")
			dead_user.ghost_reagent_scan = !dead_user.ghost_reagent_scan
			to_chat(dead_user, span_notice("Reagent scan is now [(dead_user.ghost_reagent_scan ? "ON" : "OFF")]. Click a creature to scan it."))
			return TRUE
		if("toggle_gas_scan")
			dead_user.ghost_gas_scan = !dead_user.ghost_gas_scan
			to_chat(dead_user, span_notice("Gas scan is now [(dead_user.ghost_gas_scan ? "ON" : "OFF")]. Click the floor to scan its air."))
			return TRUE
		if("toggle_t_ray")
			dead_user.set_ghost_t_ray(!dead_user.ghost_t_ray)
			return TRUE

/datum/ghost_menu/ui_data(mob/dead/observer/user)
	var/list/data = list()
	data["can_reenter"] = user.can_reenter_corpse && !isnull(user.mind?.current)
	data["body_name"] = (user.can_reenter_corpse && user.mind?.current) ? user.mind.current.real_name : null
	data["ghost_vision"] = !!user.ghostvision
	data["data_huds_on"] = !!user.data_huds_on
	data["health_scan"] = !!user.health_scan
	data["reagent_scan"] = !!user.ghost_reagent_scan
	data["gas_scan"] = !!user.ghost_gas_scan
	data["t_ray"] = !!user.ghost_t_ray
	data["notification_entries"] = list()
	for(var/notify_key in GLOB.poll_ignore_desc)
		data["notification_entries"] += list(list(
			"key" = notify_key,
			"enabled" = (user.ckey in GLOB.poll_ignore[notify_key]),
			"desc" = GLOB.poll_ignore_desc[notify_key],
		))
	data["current_darkness"] = null
	for(var/level in GLOB.ghost_lightings)
		if(GLOB.ghost_lightings[level] == user.lighting_cutoff)
			data["current_darkness"] = level
			break
	return data

/datum/ghost_menu/ui_static_data(mob/user)
	var/list/data = list()
	data["darkness_levels"] = list()
	for(var/level in GLOB.ghost_lightings)
		data["darkness_levels"] += level
	return data

/**
 * The minigames window. Shitcode has mafia and deathmatch; the rest of the
 * Nova roster (CTF, basketball) has no controller here yet.
 */
/datum/minigames_menu

/datum/minigames_menu/ui_state(mob/user)
	return GLOB.observer_state

/datum/minigames_menu/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "MinigamesMenu")
		ui.open()

/datum/minigames_menu/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	var/mob/dead/observer/dead_user = ui.user
	if(!istype(dead_user))
		return
	switch(action)
		if("mafia")
			if(!GLOB.mafia_game)
				create_mafia_game()
			else
				to_chat(dead_user, span_notice("A mafia game is already running."))
			return TRUE
		if("deathmatch")
			open_deathmatch_browser(dead_user)
			return TRUE

/datum/minigames_menu/ui_data(mob/user)
	var/list/data = list()
	data["mafia_running"] = !!GLOB.mafia_game
	return data
