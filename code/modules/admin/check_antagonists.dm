//I wish we had interfaces sigh, and i'm not sure giving team and antag common root is a better solution here
// Да, олдкодер прав, пришлось переписать antag_listing_status() на antag_check_status() и поменять условия на istype(owner.current, /mob/)

/// Отоброжаемое имя
/datum/antagonist/proc/antag_check_name()
	if(!owner)
		return "Unassigned"
	if(owner.current)
		return owner.current.real_name
	return owner.name

/// Статусы
/datum/antagonist/proc/antag_check_status()
	if(!owner)
		return list("key" = "unassigned")
	if(!owner.current)
		return list("key" = "no_body")
	if(owner.current.stat == DEAD)
		return list("key" = "dead")
	if(!owner.current.client)
		return list("key" = "no_client")
	return null

/// Стуктурная строка, добавлять тут че-то на свой страх и риск
/datum/antagonist/proc/antag_check_entry()
	if(!owner)
		return null
	. = list()
	.["ref"] = REF(src)
	.["name"] = antag_check_name()
	.["role"] = name
	.["type"] = "[type]"
	.["soft"] = soft_antag
	.["ckey"] = ckey(owner.key)
	.["mind_ref"] = REF(owner)
	var/mob/current = owner.current
	if(current)
		.["mob_ref"] = REF(current)
		.["location"] = AREACOORD(current)
		.["dead"] = current.stat == DEAD
		.["no_client"] = !current.client
		var/list/status = antag_check_status()
		if(status)
			.["status"] = status
	else
		.["status"] = list("key" = "no_body")
	var/list/objective_rows = list()
	for(var/datum/objective/objective as anything in objectives)
		objective_rows += list(list(
			"text" = objective.explanation_text,
			"completed" = objective.completed,
		))
	if(length(objective_rows))
		.["objectives"] = objective_rows

/// Все тож самое но для команд
/datum/team/proc/antag_check_name()
	return name

/// Участники команды
/datum/team/proc/antag_check_sort_members(list/members)
	return members

/datum/team/proc/antag_check_extras()
	return null

/datum/antagonist/proc/is_gamemode_hero()
	return FALSE

/datum/team/proc/is_gamemode_hero()
	return FALSE

/// Блок отделения не-антагов от реальных антагов
/datum/mind/proc/check_antag_is_antagonist()
	if(length(antag_datums))
		for(var/datum/antagonist/antag as anything in antag_datums)
			if(!antag.soft_antag)
				return TRUE
		return FALSE
	return !!special_role

// панель
GLOBAL_DATUM_INIT(check_antagonists_ui, /datum/check_antagonists_ui, new)

/datum/check_antagonists_ui

/datum/check_antagonists_ui/Destroy(force, ...)
	SStgui.close_uis(src)
	return ..()

/datum/check_antagonists_ui/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CheckAntagonists", "Проверка антагонистов")
		ui.open()

/datum/check_antagonists_ui/ui_state(mob/user)
	return GLOB.admin_state

/datum/check_antagonists_ui/ui_data(mob/user)
	. = list()
	if(!SSticker.HasRoundStarted())
		return

	var/list/round_data = list()
	round_data["mode"] = SSticker.mode.name
	if(SSticker.mode.replacementmode)
		round_data["replacement_mode"] = SSticker.mode.replacementmode.name
	round_data["duration"] = round((world.time - SSticker.round_start_time) / 10) // секунды
	.["round"] = round_data

	var/list/shuttle = list()
	if(!SSshuttle.emergency || EMERGENCY_IDLE_OR_RECALLED)
		shuttle["state"] = "idle"
	else
		shuttle["state"] = SSshuttle.emergency.mode == SHUTTLE_CALL ? "call" : "waiting"
		shuttle["eta"] = max(0, SSshuttle.emergency.timeLeft()) // секунды
	.["shuttle"] = shuttle

	.["continuous"] = !!CONFIG_GET(keyed_list/continuous)[SSticker.mode.config_tag]
	.["midround_antag"] = !!CONFIG_GET(keyed_list/midround_antag)[SSticker.mode.config_tag]
	.["midround_time_limit"] = CONFIG_GET(number/midround_antag_time_check)
	.["midround_life_limit"] = CONFIG_GET(number/midround_antag_life_check) * 100
	.["ends_with_antag_death"] = !!SSticker.mode.round_ends_with_antag_death
	.["delay_end"] = !!SSticker.delay_end
	.["delay_reason"] = SSticker.admin_delay_notice

	.["stats"] = build_stats()

	.["sections"] = build_sections()

/// Сбор статистики для реальных антагов
/datum/check_antagonists_ui/proc/build_stats()
	var/list/stats = list()

	var/connected_players = GLOB.clients.len
	var/lobby_players = 0
	var/observers = 0
	var/observers_connected = 0
	var/living_players = 0
	var/living_players_connected = 0
	var/living_players_antagonist = 0
	var/brains = 0
	var/other_players = 0
	var/living_skipped = 0
	var/drones = 0
	for(var/mob/M in GLOB.mob_list)
		if(M.ckey)
			if(isnewplayer(M))
				lobby_players++
				continue
			else if(M.stat != DEAD && M.mind && !isbrain(M))
				if(isdrone(M))
					drones++
					continue
				if(is_centcom_level(M.z))
					living_skipped++
					continue
				living_players++
				if(M.mind.check_antag_is_antagonist())
					living_players_antagonist++
				if(M.client)
					living_players_connected++
			else if(M.stat == DEAD || isobserver(M))
				observers++
				if(M.client)
					observers_connected++
			else if(isbrain(M))
				brains++
			else
				other_players++

	stats["connected"] = connected_players
	stats["lobby"] = lobby_players
	stats["ingame"] = connected_players - lobby_players
	stats["living"] = living_players
	stats["living_connected"] = living_players_connected
	stats["living_antagonists"] = living_players_antagonist
	stats["observers"] = observers
	stats["observers_connected"] = observers_connected
	stats["brains"] = brains
	stats["skipped"] = living_skipped
	stats["drones"] = drones
	stats["other"] = other_players
	return stats

/// Билд-секция для трех категорий, разделяем и скрываем мирные антаг-роли
/datum/check_antagonists_ui/proc/build_sections()
	var/list/hero_sections = list()
	var/list/normal_sections = list()
	var/list/peaceful_sections = list()

	var/list/hard_antags = list()
	var/list/peaceful_antags = list()
	for(var/datum/antagonist/antag as anything in GLOB.antagonists)
		if(!antag.owner)
			continue
		if(!antag.show_in_check_antagonists)
			continue
		if(antag.soft_antag)
			peaceful_antags += antag
		else
			hard_antags += antag

	var/list/all_teams = list()
	for(var/datum/antagonist/antag as anything in hard_antags)
		var/datum/team/team = antag.get_team()
		if(team)
			all_teams |= team

	for(var/datum/team/team as anything in all_teams)
		var/list/members = list()
		for(var/datum/antagonist/antag as anything in hard_antags)
			if(antag.get_team() == team)
				members += antag
		hard_antags -= members
		var/list/section = build_team_section(team, members)
		if(!length(section))
			continue
		if(team.is_gamemode_hero())
			hero_sections += list(section)
		else
			normal_sections += list(section)

	sortTim(hard_antags, GLOBAL_PROC_REF(cmp_antag_category))
	var/current_category
	var/list/current_section
	for(var/datum/antagonist/antag as anything in hard_antags)
		var/list/entry = antag.antag_check_entry()
		if(!entry)
			continue
		if(!current_section || antag.roundend_category != current_category)
			current_category = antag.roundend_category
			current_section = list(
				"id" = "cat-[current_category]",
				"title" = capitalize(current_category),
				"kind" = "category",
				"members" = list(),
			)
			if(antag.is_gamemode_hero())
				current_section["priority"] = TRUE
				hero_sections += list(current_section)
			else
				normal_sections += list(current_section)
		var/list/target_section = current_section
		target_section["members"] += list(entry)

	// группирую мирные роли
	var/list/peaceful_names = list()
	var/list/peaceful_groups = list()
	for(var/datum/antagonist/antag as anything in peaceful_antags)
		var/role_name = antag.name
		if(!peaceful_groups[role_name])
			peaceful_groups[role_name] = list()
			peaceful_names += role_name
		var/list/entry = antag.antag_check_entry()
		if(entry)
			peaceful_groups[role_name] += list(entry)

	for(var/role_name in peaceful_names)
		var/list/members = peaceful_groups[role_name]
		if(!length(members))
			continue
		peaceful_sections += list(list(
			"id" = "peaceful-[role_name]",
			"title" = role_name,
			"kind" = "peaceful",
			"members" = members,
		))

	return hero_sections + normal_sections + peaceful_sections

/// Для особых команд
/datum/check_antagonists_ui/proc/build_team_section(datum/team/team, list/members)
	members = team.antag_check_sort_members(members)
	var/list/entries = list()
	for(var/datum/antagonist/antag as anything in members)
		var/list/entry = antag.antag_check_entry()
		if(entry)
			entries += list(entry)
	if(!length(entries))
		return null
	var/list/section = list(
		"id" = REF(team),
		"title" = team.antag_check_name(),
		"kind" = "team",
		"members" = entries,
	)
	if(team.is_gamemode_hero())
		section["priority"] = TRUE
	var/list/extras = team.antag_check_extras()
	if(length(extras))
		section["extras"] = extras
	return section


/datum/check_antagonists_ui/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	if(..())
		return
	if(!SSticker.HasRoundStarted())
		return
	if(!usr?.client)
		return

	switch(action)
		if("call_shuttle")
			if(!check_rights(R_ADMIN))
				return
			if(EMERGENCY_AT_LEAST_DOCKED)
				return
			SSshuttle.emergency.request()
			log_admin("[key_name(usr)] called the Emergency Shuttle.")
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] called the Emergency Shuttle to the station.</span>")
			return TRUE

		if("send_shuttle_back")
			if(!check_rights(R_ADMIN))
				return
			if(EMERGENCY_AT_LEAST_DOCKED)
				return
			if(SSshuttle.emergency.mode != SHUTTLE_CALL)
				return
			SSshuttle.emergency.cancel()
			log_admin("[key_name(usr)] sent the Emergency Shuttle back.")
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] sent the Emergency Shuttle back.</span>")
			return TRUE

		if("edit_shuttle_time")
			if(!check_rights(R_SERVER))
				return
			if(!SSshuttle.emergency || EMERGENCY_IDLE_OR_RECALLED)
				return
			var/timer = tgui_input_number(usr, "Введите новое время до прибытия шаттла (секунды):", "Edit Shuttle Timeleft", SSshuttle.emergency.timeLeft(), round_value = TRUE)
			if(isnull(timer) || timer <= 0)
				return
			SSshuttle.emergency.setTimer(timer * 10)
			log_admin("[key_name(usr)] edited the Emergency Shuttle's timeleft to [timer] seconds.")
			minor_announce("Шаттл эвакуации прибудет через [round(timer / 60)] минут.")
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] edited the Emergency Shuttle's timeleft to [timer] seconds.</span>")
			return TRUE

		if("toggle_continuous")
			if(!check_rights(R_ADMIN))
				return
			var/list/continuous = CONFIG_GET(keyed_list/continuous)
			continuous[SSticker.mode.config_tag] = !continuous[SSticker.mode.config_tag]
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] toggled the round to [continuous[SSticker.mode.config_tag] ? "continue if all antagonists die" : "end with the antagonists"].</span>")
			return TRUE

		if("toggle_midround_antag")
			if(!check_rights(R_ADMIN))
				return
			var/list/midround_antag = CONFIG_GET(keyed_list/midround_antag)
			midround_antag[SSticker.mode.config_tag] = !midround_antag[SSticker.mode.config_tag]
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] toggled the round to [midround_antag[SSticker.mode.config_tag] ? "use" : "skip"] the midround antag system.</span>")
			return TRUE

		if("alter_midround_time_limit")
			if(!check_rights(R_ADMIN))
				return
			var/timer = tgui_input_number(usr, "Новый максимум времени появления антагониста (минут):", "Midround Antag Time Limit", CONFIG_GET(number/midround_antag_time_check), round_value = TRUE)
			if(isnull(timer) || timer <= 0)
				return
			CONFIG_SET(number/midround_antag_time_check, timer)
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] edited the maximum midround antagonist time to [timer] minutes.</span>")
			return TRUE

		if("alter_midround_life_limit")
			if(!check_rights(R_ADMIN))
				return
			var/ratio = tgui_input_number(usr, "Необходимый процент живого экипажа:", "Midround Antag Life Limit", CONFIG_GET(number/midround_antag_life_check) * 100, max_value = 100, min_value = 1, round_value = TRUE)
			if(isnull(ratio) || !ratio)
				return
			CONFIG_SET(number/midround_antag_life_check, ratio / 100)
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] edited the midround antagonist living crew ratio to [ratio]% alive.</span>")
			return TRUE

		if("toggle_noncontinuous_behavior")
			if(!check_rights(R_ADMIN))
				return
			SSticker.mode.round_ends_with_antag_death = !SSticker.mode.round_ends_with_antag_death
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] edited the midround antagonist system to [SSticker.mode.round_ends_with_antag_death ? "end the round" : "continue as extended"] upon failure.</span>")
			return TRUE

		if("delay_round_end")
			if(!check_rights(R_SERVER))
				return
			if(!SSticker.delay_end)
				SSticker.admin_delay_notice = tgui_input_text(usr, "Причина задержки конца раунда:", "Round Delay Reason", multiline = TRUE)
				if(isnull(SSticker.admin_delay_notice))
					return
			else
				SSticker.admin_delay_notice = null
			SSticker.delay_end = !SSticker.delay_end
			var/reason = SSticker.delay_end ? "for reason: [SSticker.admin_delay_notice]" : "."
			var/msg = "[SSticker.delay_end ? "delayed" : "undelayed"] the round end [reason]"
			log_admin("[key_name(usr)] [msg]")
			message_admins("[key_name_admin(usr)] [msg]")
			if(SSticker.ready_for_reboot && !SSticker.delay_end)
				SSticker.standard_reboot()
			return TRUE

		if("end_round")
			if(!check_rights(R_ADMIN))
				return
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] is considering ending the round.</span>")
			if(tgui_alert(usr, "Это завершит раунд. Вы УВЕРЕНЫ?", "Подтверждение", list("Да", "Нет")) != "Да")
				return
			if(tgui_alert(usr, "Окончательное подтверждение: завершить раунд СЕЙЧАС?", "Подтверждение", list("Да", "Нет")) != "Да")
				return
			message_admins("<span class='adminnotice'>[key_name_admin(usr)] has ended the round.</span>")
			log_admin("[key_name(usr)] ended the round.")
			SSticker.force_ending = 1
			return TRUE

		if("follow")
			var/atom/movable/target = locate(params["ref"])
			if(QDELETED(target))
				return
			if(!isobserver(usr) && !check_rights(R_ADMIN))
				return
			var/client/admin_client = usr.client
			if(!isobserver(usr) && !admin_client.admin_ghost())
				return
			var/mob/dead/observer/observer_mob = admin_client.mob
			if(!istype(observer_mob))
				return
			observer_mob.ManualFollow(target)
			return TRUE

		if("pm")
			var/target_ckey = params["ckey"]
			if(!target_ckey)
				return
			usr.client.cmd_admin_pm(target_ckey)
			return TRUE

		if("player_panel")
			var/mob/target = locate(params["ref"])
			if(QDELETED(target))
				return
			if(!check_rights(R_ADMIN))
				return
			usr.client.holder?.show_player_panel(target)
			return TRUE

		if("antag_panel")
			var/datum/mind/target_mind = locate(params["ref"])
			if(QDELETED(target_mind))
				return
			if(!check_rights(R_ADMIN))
				return
			target_mind.traitor_panel()
			return TRUE

/datum/admins/proc/check_antagonists()
	if(!SSticker.HasRoundStarted())
		alert("The game hasn't started yet!")
		return
	GLOB.check_antagonists_ui.ui_interact(usr)
