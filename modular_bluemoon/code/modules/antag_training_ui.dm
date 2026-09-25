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
	var/list/data = list("target_limit" = ANTAG_TRAINING_TARGET_LIMIT, "supply_limit" = ANTAG_TRAINING_SUPPLY_LIMIT, "structure_limit" = ANTAG_TRAINING_STRUCTURE_LIMIT)
	data["equipment"] = list()
	for(var/equipment_id in GLOB.antag_training_equipment)
		var/list/equipment = GLOB.antag_training_equipment[equipment_id]
		data["equipment"] += list(list("id" = equipment_id, "name" = equipment["name"], "category" = equipment["category"], "desc" = equipment["desc"]))
	data["structures"] = list()
	for(var/structure_id in GLOB.antag_training_structures)
		var/list/template = GLOB.antag_training_structures[structure_id]
		data["structures"] += list(list("id" = structure_id, "name" = template["name"], "category" = template["category"], "desc" = template["desc"]))
	data["injuries"] = list()
	for(var/injury_id in GLOB.antag_training_injuries)
		data["injuries"] += list(list("id" = injury_id, "name" = GLOB.antag_training_injuries[injury_id]["name"]))
	data["creatures"] = list()
	for(var/template_id in GLOB.antag_training_creatures)
		data["creatures"] += list(list("id" = template_id, "name" = GLOB.antag_training_creatures[template_id]["name"]))
	data["programs"] = list()
	data["kits"] = list()
	for(var/kit_id in GLOB.antag_training_kits)
		data["kits"] += list(list("id" = kit_id, "name" = GLOB.antag_training_kits[kit_id]["name"]))
	data["paths"] = list()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		data["paths"] += list(list("id" = path.id, "name" = path.name, "desc" = path.desc))
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program))
		data["programs"] += list(list("id" = "[program_type]", "name" = initial(program_type.name)))
	return data

/datum/antag_training_session/ui_data(mob/user)
	arena.prune_targets()
	arena.prune_supplies()
	var/list/data = list("program" = program.name, "program_id" = "[program.type]", "auto_recover" = auto_recover, "health" = current_body.health, "max_health" = current_body.maxHealth, "busy" = arena.resetting, "supply_count" = arena.supply_count, "cleaning_personal" = cleaning_personal)
	data["structure_count"] = length(arena.placed_structures)
	data["build_error"] = arena.construction_error(get_step(current_body, current_body.dir))
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
		data["targets"] += list(list("id" = REF(target), "name" = target.name, "zone" = arena.zones[zone_id]?["name"] || "Переход", "health" = target.health, "max_health" = target.maxHealth, "dead" = target.stat == DEAD, "brute" = target.getBruteLoss(), "burn" = target.getFireLoss(), "toxin" = target.getToxLoss(), "oxygen" = target.getOxyLoss(), "stamina" = ishuman(target) ? target.getStaminaLoss() : null, "human" = ishuman(target), "owner" = creator?.current_body?.real_name || "Общая цель", "can_manage" = can_manage_target(target)))
	data["zones"] = list()
	for(var/zone_id in arena.zones)
		var/list/zone = arena.zones[zone_id]
		data["zones"] += list(list("id" = zone_id, "name" = zone["name"], "desc" = zone["desc"], "members" = member_counts[zone_id] || 0, "targets" = target_counts[zone_id] || 0, "current" = arena.inside_bounds(get_turf(user), zone["bounds"])))
	data["options"] = program.options
	data["preparing"] = preparing
	data["supply_ready"] = world.time >= next_supply_at && !preparing
	data["practice_ready"] = world.time >= arena.next_spawn_at && !preparing
	data["last_feedback"] = last_feedback
	data["last_kit"] = last_kit
	data["recipes"] = training_recipes()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(current_body)
	data["selected_path"] = heretic?.selected_path
	data["path_stage"] = heretic?.path_stage || 0
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic?.selected_path]
	var/datum/eldritch_knowledge/base = path ? heretic.get_knowledge(path.knowledge[1]) : null
	data["resource"] = base?.get_combat_resource_data()
	data["practice"] = null
	if(practice_id)
		var/mob/living/target = practice_target?.resolve()
		data["practice"] = list("id" = practice_id, "target" = target?.name || "Цель недоступна", "complete" = practice_complete, "hint" = practice_hint, "damage" = measurement?.damage || 0, "healing" = measurement?.healing || 0, "last_damage" = measurement?.last_damage || 0, "critical_seconds" = isnull(measurement?.critical_after) ? null : measurement.critical_after / (1 SECONDS))
	data["duel"] = null
	data["last_duel_result"] = last_duel_result
	data["duel_ready"] = world.time >= next_duel_at
	if(arena.duel)
		var/datum/antag_training_duel/duel = arena.duel
		data["duel"] = list("phase" = duel.phase, "first" = duel.challenger.current_body?.real_name, "second" = duel.opponent.current_body?.real_name, "lethal" = duel.to_death, "remaining" = max(0, round((duel.deadline - world.time) / (1 SECONDS))), "involved" = duel.includes(src), "can_accept" = duel.opponent == src && duel.phase == "invite")
	return data

/datum/antag_training_session/ui_act(action, list/params)
	if(..() || !can_control(usr))
		return FALSE
	if(action != "exit")
		if(world.time < next_action_at || ((arena.resetting || preparing) && action != "heal"))
			return FALSE
		next_action_at = world.time + 0.5 SECONDS
	if(arena.duel?.includes(src) && !(action in list("duel_accept", "duel_cancel", "reset_approve", "reset_cancel")))
		arena.duel.finish("Дуэль завершена: участник изменил условия через пульт.")
	switch(action)
		if("kit")
			issue_kit(params["id"])
		if("practice")
			start_practice(params["id"])
		if("practice_stop")
			stop_practice()
		if("prepare_path")
			prepare_path(params["id"], text2num("[params["stage"]]"))
		if("recipe")
			var/datum/antagonist/heretic/heretic = IS_HERETIC(current_body)
			for(var/knowledge_type in heretic?.researched_knowledge)
				var/datum/eldritch_knowledge/recipe = heretic.researched_knowledge[knowledge_type]
				if(REF(recipe) == params["id"])
					issue_recipe(recipe, params["components"] == TRUE)
					break
		if("duel_request")
			var/datum/antag_training_session/opponent = locate(params["id"]) in arena.members
			request_duel(opponent, params["lethal"] == TRUE)
		if("duel_accept")
			arena.duel?.accept(src)
		if("duel_cancel")
			if(arena.duel?.includes(src))
				arena.duel.finish("Дуэль отменена участником.")
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
		if("build")
			build_structure(params["id"], usr)
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
		if("target_heal", "target_delete", "target_hunt", "target_injure")
			var/mob/living/target = locate(params["id"]) in arena.targets
			if(!can_manage_target(target) || get_area(heretic_pocket_anchor(get_turf(target))) != arena.room)
				return FALSE
			if(action == "target_heal")
				if(practice_target?.resolve() == target)
					stop_practice()
				target.revive(full_heal = TRUE, admin_revive = TRUE)
			else if(action == "target_injure")
				injure_target(target, params["injury"])
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
