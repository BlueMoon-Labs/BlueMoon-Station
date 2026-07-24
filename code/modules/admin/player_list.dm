/datum/admin_player_list

/datum/admin_player_list/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PlayerList", "Player Panel")
		ui.open()

/datum/admin_player_list/ui_state(mob/user)
	return GLOB.admin_state

/datum/admin_player_list/ui_data(mob/user)
	. = list()
	var/list/mobs = sortmobs()
	var/list/players_data = list()
	for(var/mob/M in mobs)
		if(!M.ckey)
			continue
		var/job = ""
		if(isliving(M))
			if(iscarbon(M))
				if(ishuman(M))
					job = M.job
				else if(ismonkey(M))
					job = "Monkey"
				else if(isalien(M))
					if(islarva(M))
						job = "Alien larva"
					else
						job = ROLE_ALIEN
				else
					job = "Carbon-based"
			else if(issilicon(M))
				if(isAI(M))
					job = "AI"
				else if(ispAI(M))
					job = ROLE_PAI
				else if(iscyborg(M))
					job = "Cyborg"
				else
					job = "Silicon-based"
			else if(isanimal(M))
				if(iscorgi(M))
					job = "Corgi"
				else if(isslime(M))
					job = "Slime"
				else
					job = "Animal"
			else
				job = "Living"
		else if(isnewplayer(M))
			job = "New player"
		else if(isobserver(M))
			var/mob/dead/observer/O = M
			job = O.started_as_observer ? "Observer" : "Ghost"
		var/is_ghost_role = FALSE
		if(job in GLOB.exp_specialmap[EXP_TYPE_SPECIAL])
			is_ghost_role = TRUE
		else if(job in list(ROLE_PAI, ROLE_POSIBRAIN))
			is_ghost_role = TRUE

		players_data += list(list(
			"name" = "[M.name]",
			"real_name" = "[M.real_name]",
			"key" = "[M.key]",
			"job" = "[job]",
			"ref" = "[REF(M)]",
			"ip" = "[M.lastKnownIP]",
			"cid" = "[M.computer_id]",
			"antag" = is_special_character(M),
			"is_cyborg" = iscyborg(M),
			"stat" = M.stat,
			"is_observer" = isobserver(M),
			"is_new_player" = isnewplayer(M),
			"is_ghost_role" = is_ghost_role,
			"is_sec_or_cmd" = (job in GLOB.security_positions) || (job in GLOB.command_positions),
		))
	.["players"] = players_data
	.["total"] = length(players_data)

/datum/admin_player_list/ui_act(action, params, datum/tgui/ui)
	if(..())
		return
	switch(action)
		if("check_antagonists")
			var/datum/admins/holder = usr.client?.holder
			if(holder)
				holder.Topic("", list(
					"check_antagonist" = "1",
					"admin_token" = holder.href_token,
				))
			return TRUE
		if("kick_all_from_lobby")
			var/datum/admins/holder = usr.client?.holder
			if(holder)
				holder.Topic("", list(
					"kick_all_from_lobby" = "1",
					"afkonly" = params["afkonly"] || "0",
					"admin_token" = holder.href_token,
				))
			return TRUE
	var/mob/target = locate(params["ref"]) in GLOB.mob_list
	if(!istype(target))
		return
	switch(action)
		if("open_pp")
			usr.client?.holder?.show_player_panel2(target)
		if("open_notes")
			browse_messages(target_ckey = target.ckey)
		if("open_vv")
			usr.client?.debug_variables(target)
		if("open_tp")
			usr.client?.holder?.show_traitor_panel(target)
		if("open_bp")
			usr.client?.holder?.open_borgopanel(target)
		if("open_pm")
			usr.client?.cmd_admin_pm_context(target)
		if("open_sm")
			usr.client?.cmd_admin_subtle_headset_message(target)
		if("open_flw")
			if(!isobserver(usr))
				usr.client?.admin_ghost()
			var/mob/dead/observer/ghost = usr.client?.mob
			if(istype(ghost))
				ghost.ManualFollow(target)
		if("open_logs")
			var/datum/log_viewer/LV = new(target)
			LV.ui_interact(usr)
		if("open_kick")
			usr.client?.holder?.kick(target)
			return TRUE
		if("open_ban")
			usr.client?.holder?.DB_ban_panel(target.ckey)
	return TRUE
