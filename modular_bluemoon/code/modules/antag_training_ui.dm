/datum/antag_training_session/ui_state(mob/user)
	return GLOB.always_state

/datum/antag_training_session/ui_status(mob/user, datum/ui_state/state)
	return can_control(user) ? UI_INTERACTIVE : UI_CLOSE

/datum/antag_training_session/ui_interact(mob/user, datum/tgui/ui)
	if(!can_control(user))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "AntagTraining", "Тренировочный полигон")
		ui.open()

/datum/antag_training_session/ui_static_data(mob/user)
	var/list/data = list("target_limit" = ANTAG_TRAINING_TARGET_LIMIT, "supply_limit" = ANTAG_TRAINING_SUPPLY_LIMIT)
	data["equipment"] = list()
	for(var/equipment_id in GLOB.antag_training_equipment)
		var/list/equipment = GLOB.antag_training_equipment[equipment_id]
		data["equipment"] += list(list("id" = equipment_id, "name" = equipment["name"], "category" = equipment["category"]))
	data["creatures"] = list()
	for(var/template_id in GLOB.antag_training_creatures)
		data["creatures"] += list(list("id" = template_id, "name" = GLOB.antag_training_creatures[template_id]["name"]))
	data["programs"] = list()
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program))
		data["programs"] += list(list("id" = "[program_type]", "name" = initial(program_type.name)))
	return data

/datum/antag_training_session/ui_data(mob/user)
	arena.prune_targets()
	arena.prune_supplies()
	var/list/data = list("program" = program.name, "program_id" = "[program.type]", "auto_recover" = auto_recover, "health" = current_body.health, "max_health" = current_body.maxHealth, "busy" = arena.resetting, "supply_count" = arena.supply_count, "cleaning_personal" = cleaning_personal)
	var/list/member_counts = list()
	var/list/target_counts = list()
	data["members"] = list()
	for(var/datum/antag_training_session/member as anything in arena.members)
		var/zone_id = arena.match_zone(member.current_body)
		member_counts[zone_id]++
		data["members"] += list(list("id" = REF(member), "name" = member.current_body?.real_name || "Смена персонажа", "program" = member.program?.name, "health" = member.current_body?.health, "max_health" = member.current_body?.maxHealth, "dead" = member.current_body?.stat == DEAD, "connected" = !!member.current_body?.client, "zone" = arena.zones[zone_id]?["name"] || "Переход", "defeats" = member.defeats, "self" = member == src))
	data["reset_vote"] = null
	if(arena.pending_reset_zone)
		var/approved = 0
		for(var/datum/antag_training_session/member as anything in arena.members)
			if(arena.reset_votes[member])
				approved++
		data["reset_vote"] = list("zone" = arena.pending_reset_zone == "all" ? "Весь полигон" : arena.zones[arena.pending_reset_zone]["name"], "approved" = approved, "total" = length(arena.members), "remaining" = max(0, round((arena.reset_vote_deadline - world.time) / (1 SECONDS))), "voted" = arena.reset_votes[src])
	data["targets"] = list()
	for(var/mob/living/target as anything in arena.targets)
		var/zone_id = arena.match_zone(target)
		target_counts[zone_id]++
		var/datum/antag_training_session/creator = target.training_owner?.resolve()
		data["targets"] += list(list("id" = REF(target), "name" = target.name, "zone" = arena.zones[zone_id]?["name"] || "Переход", "health" = target.health, "max_health" = target.maxHealth, "dead" = target.stat == DEAD, "brute" = target.getBruteLoss(), "burn" = target.getFireLoss(), "toxin" = target.getToxLoss(), "oxygen" = target.getOxyLoss(), "human" = ishuman(target), "owner" = creator?.current_body?.real_name || "Общая цель", "can_manage" = can_manage_target(target)))
	data["zones"] = list()
	for(var/zone_id in arena.zones)
		var/list/zone = arena.zones[zone_id]
		data["zones"] += list(list("id" = zone_id, "name" = zone["name"], "desc" = zone["desc"], "members" = member_counts[zone_id] || 0, "targets" = target_counts[zone_id] || 0, "current" = arena.inside_bounds(get_turf(user), zone["bounds"])))
	data["options"] = program.options
	return data

/datum/antag_training_session/ui_act(action, list/params)
	if(..() || !can_control(usr))
		return FALSE
	if(action != "exit")
		if(world.time < next_action_at || (arena.resetting && action != "heal"))
			return FALSE
		next_action_at = world.time + 0.5 SECONDS
	switch(action)
		if("move")
			var/list/zone = arena.zones[params["zone"]]
			if(zone)
				current_body.forceMove(zone["spawn"])
		if("reset_zone")
			arena.request_reset(src, params["zone"])
		if("reset_approve")
			arena.approve_reset(src)
		if("reset_cancel")
			arena.cancel_reset()
		if("clean_personal")
			INVOKE_ASYNC(src, PROC_REF(clear_personal_entities))
		if("equipment")
			issue_equipment(params["id"], usr)
		if("spawn")
			if(world.time < arena.next_spawn_at)
				return FALSE
			arena.next_spawn_at = world.time + 1 SECONDS
			var/mob/living/target = arena.spawn_creature(params["id"], params["zone"], params["active"] == TRUE, src)
			if(ishuman(target))
				program.target_created(src, target)
		if("auto_recover")
			auto_recover = !auto_recover
			deltimer(recovery_timer)
			recovery_timer = null
			if(auto_recover && current_body.stat == DEAD)
				recovery_timer = addtimer(CALLBACK(src, PROC_REF(recover)), 3 SECONDS, TIMER_STOPPABLE)
		if("heal")
			if(world.time < next_heal_at)
				return FALSE
			next_heal_at = world.time + 1 SECONDS
			heal_self()
		if("target_heal", "target_delete", "target_hunt")
			var/mob/living/target = locate(params["id"]) in arena.targets
			if(!can_manage_target(target) || get_area(target) != arena.room)
				return FALSE
			if(action == "target_heal")
				target.revive(full_heal = TRUE, admin_revive = TRUE)
			else if(action == "target_hunt" && ishuman(target))
				program.target_created(src, target)
			else if(action == "target_delete")
				QDEL_NULL(target.mind)
				qdel(target)
		if("program_option")
			if(params["option"] in program.options)
				program.handle_choice(src, current_body, params["option"])
		if("restart")
			for(var/program_type in subtypesof(/datum/antag_training_program))
				if("[program_type]" == params["program"])
					restart(program_type)
					break
		if("exit")
			finish()
	return TRUE
