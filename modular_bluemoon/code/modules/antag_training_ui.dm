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
	var/list/data = list("target_limit" = ANTAG_TRAINING_TARGET_LIMIT, "supply_limit" = ANTAG_TRAINING_SUPPLY_LIMIT, "structure_limit" = ANTAG_TRAINING_STRUCTURE_LIMIT, "sector_idle_minutes" = ANTAG_TRAINING_SECTOR_IDLE / (1 MINUTES))
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
	data["conditions"] = list()
	for(var/condition_id in GLOB.antag_training_conditions)
		data["conditions"] += list(list("id" = condition_id, "name" = GLOB.antag_training_conditions[condition_id]))
	data["creatures"] = list()
	for(var/template_id in GLOB.antag_training_creatures)
		data["creatures"] += list(list("id" = template_id, "name" = GLOB.antag_training_creatures[template_id]["name"]))
	data["roles"] = antag_training_role_entries()
	data["programs"] = list()
	data["kits"] = list()
	for(var/kit_id in GLOB.antag_training_kits)
		data["kits"] += list(list("id" = kit_id, "name" = GLOB.antag_training_kits[kit_id]["name"]))
	data["paths"] = list()
	for(var/path_id in GLOB.heretic_paths)
		var/datum/heretic_path/path = GLOB.heretic_paths[path_id]
		data["paths"] += list(list("id" = path.id, "name" = path.name, "desc" = path.desc))
	var/list/sector_names = antag_training_sector_names()
	for(var/datum/antag_training_program/program_type as anything in subtypesof(/datum/antag_training_program))
		if(antag_training_program_selectable(program_type))
			data["programs"] += list(antag_training_program_entry(program_type, sector_names))
	data["start_tab"] = exercises_requested ? "exercises" : null
	exercises_requested = FALSE
	return data

/datum/antag_training_session/ui_data(mob/user)
	arena.prune_targets()
	arena.prune_supplies(once_per_tick = TRUE)
	var/mob/living/body = isliving(current_body) ? current_body : null
	var/list/data = list("program" = program.name, "program_id" = "[program.type]", "auto_recover" = auto_recover, "health" = body?.health, "max_health" = body?.maxHealth, "busy" = arena.resetting, "supply_count" = arena.supply_count, "cleaning_personal" = cleaning_personal)
	data["return_to_body"] = !!return_body
	data["hub"] = !!arena.hub?.ready
	data["structure_count"] = length(arena.placed_structures)
	data["build_error"] = arena.construction_error(get_step(current_body, current_body.dir), src)
	data["stand"] = stand_data()
	var/list/member_counts = list()
	var/list/target_counts = list()
	data["members"] = list()
	for(var/datum/antag_training_session/member as anything in arena.members)
		var/zone_id = arena.match_zone(member.current_body)
		member_counts[zone_id]++
		var/mob/living/member_body = isliving(member.current_body) ? member.current_body : null
		data["members"] += list(list("id" = REF(member), "name" = member.current_body?.real_name || "Смена персонажа", "program" = member.program?.name, "health" = member_body?.health, "max_health" = member_body?.maxHealth, "dead" = member.current_body?.stat == DEAD, "connected" = !!member.current_body?.client, "zone" = arena.zones[zone_id]?["name"] || "Переход", "defeats" = member.defeats, "self" = member == src))
	data["reset_vote"] = null
	if(arena.pending_reset_zone)
		var/list/voters = arena.reset_voters(arena.pending_reset_zone)
		var/approved = 0
		for(var/datum/antag_training_session/member as anything in voters)
			if(arena.reset_votes[member])
				approved++
		data["reset_vote"] = list("zone" = arena.pending_reset_zone == "all" ? "Весь полигон" : arena.zones[arena.pending_reset_zone]["name"], "approved" = approved, "total" = length(voters), "remaining" = max(0, round((arena.reset_vote_deadline - world.time) / (1 SECONDS))), "voted" = arena.reset_votes[src], "can_vote" = (src in arena.reset_votes), "can_cancel" = arena.may_cancel_reset(src))
	data["targets"] = list()
	for(var/atom/movable/entity as anything in arena.targets)
		var/zone_id = arena.match_zone(entity)
		target_counts[zone_id]++
		var/datum/antag_training_session/creator = entity.training_owner?.resolve()
		var/list/entry = list("id" = REF(entity), "name" = entity.name, "zone" = arena.zones[zone_id]?["name"] || "Переход", "owner" = creator?.current_body?.real_name || "Общая цель", "can_manage" = can_manage_target(entity), "human" = ishuman(entity), "living" = isliving(entity))
		if(isliving(entity))
			var/mob/living/target = entity
			entry += list("health" = target.health, "max_health" = target.maxHealth, "dead" = target.stat == DEAD, "brute" = target.getBruteLoss(), "burn" = target.getFireLoss(), "toxin" = target.getToxLoss(), "oxygen" = target.getOxyLoss(), "stamina" = ishuman(target) ? target.getStaminaLoss() : null, "states" = antag_training_target_states(target))
		else
			var/obj/thing = entity
			entry += list("health" = isobj(entity) ? thing.obj_integrity : 0, "max_health" = isobj(entity) ? thing.max_integrity : 0, "dead" = FALSE, "states" = list())
		data["targets"] += list(entry)
	var/list/exercise_totals = list()
	var/list/exercise_done = list()
	var/list/records = exercise_records()
	for(var/exercise_id in GLOB.antag_training_exercises)
		var/datum/antag_training_exercise/exercise = GLOB.antag_training_exercises[exercise_id]
		if(exercise.available(src))
			exercise_totals[exercise.sector]++
			if(records[exercise_id])
				exercise_done[exercise.sector]++
	var/list/practice_counts = list()
	for(var/practice_key in GLOB.antag_training_practice_exercises)
		if(practice_available(practice_key))
			practice_counts[GLOB.antag_training_practice_exercises[practice_key]["zone"]]++
	data["zones"] = list()
	for(var/zone_id in arena.zones)
		var/list/zone = arena.zones[zone_id]
		data["zones"] += list(list("id" = zone_id, "name" = zone["name"], "desc" = zone["desc"], "members" = member_counts[zone_id] || 0, "targets" = target_counts[zone_id] || 0, "current" = arena.inside_bounds(get_turf(user), zone["bounds"]), "exercises_done" = exercise_done[zone_id] || 0, "exercises_total" = exercise_totals[zone_id] || 0, "practice" = practice_counts[zone_id] || 0))
	data["sectors"] = list()
	for(var/sector_id in arena.sectors)
		var/datum/antag_training_sector/sector = arena.sectors[sector_id]
		data["sectors"] += list(list("id" = sector_id, "name" = sector.name, "desc" = sector.desc, "state" = antag_training_sector_state_name(sector.state), "members" = member_counts[sector_id] || 0, "current" = !!(sector.bounds && arena.inside_bounds(get_turf(user), sector.bounds)), "exercises_done" = exercise_done[sector_id] || 0, "exercises_total" = exercise_totals[sector_id] || 0))
	data["options"] = program.options
	var/list/route = antag_training_program_route(program.type)
	route += antag_training_exercise_progress(antag_training_program_exercises(program.type, antag_training_sector_names(), antag_training_program_body(program.type, role)), exercise_records())
	data["route"] = route
	var/list/goals = role_objectives()
	data["role_objectives"] = goals
	data["role_next"] = role_next_step(goals)
	data["role"] = role.id
	data["role_applies"] = !!(program.allowed_roles & role.kind)
	data["program_allowed_roles"] = program.allowed_roles
	data["option_hints"] = program.option_hints
	data["target_action"] = program.target_action
	data["preparing"] = preparing
	data["supply_ready"] = world.time >= next_supply_at && !preparing
	data["practice_ready"] = world.time >= arena.next_spawn_at && !preparing
	data["last_feedback"] = last_feedback
	data["last_kit"] = last_kit
	data["recipes"] = training_recipes()
	var/datum/antagonist/heretic/heretic = IS_HERETIC(current_body)
	data["heretic"] = !!heretic
	data["selected_path"] = heretic?.selected_path
	data["path_stage"] = heretic?.path_stage || 0
	data["dance_lesson"] = !!dance_knowledge()
	data["spirit_lesson"] = !!spirit_knowledge()
	var/datum/heretic_path/path = GLOB.heretic_paths[heretic?.selected_path]
	var/datum/eldritch_knowledge/base = path ? heretic.get_knowledge(path.knowledge[1]) : null
	data["resource"] = base?.get_combat_resource_data()
	data["practice"] = null
	if(practice_id)
		var/mob/living/target = practice_target?.resolve()
		data["practice"] = list("id" = practice_id, "target" = target?.name || "Цель недоступна", "complete" = practice_complete, "hint" = practice_hint, "damage" = measurement?.damage || 0, "healing" = measurement?.healing || 0, "last_damage" = measurement?.last_damage || 0, "critical_seconds" = isnull(measurement?.critical_after) ? null : measurement.critical_after / (1 SECONDS), "steps" = dance_lesson?.steps() || spirit_lesson?.steps())
	data["exercises"] = exercise_data()
	data["duel"] = null
	data["last_duel_result"] = last_duel_result
	data["duel_ready"] = world.time >= next_duel_at
	if(arena.duel)
		var/datum/antag_training_duel/duel = arena.duel
		data["duel"] = list("phase" = duel.phase, "first" = duel.challenger.current_body?.real_name, "second" = duel.opponent.current_body?.real_name, "lethal" = duel.to_death, "remaining" = max(0, round((duel.deadline - world.time) / (1 SECONDS))), "involved" = duel.includes(src), "can_accept" = duel.opponent == src && duel.phase == "invite")
	squad_ui_data(data)
	pads_ui_data(data)
	scenario_ui_data(data)
	return data

/datum/antag_training_session/ui_act(action, list/params)
	if(..() || !can_control(usr))
		return FALSE
	// Числовой ключ читает ассоциативные списки зон и каталогов по позиции.
	for(var/param in list("id", "zone", "injury"))
		if(!isnull(params[param]) && !istext(params[param]))
			return FALSE
	if(action != "exit")
		if(world.time < next_action_at || ((arena.resetting || preparing) && action != "heal"))
			return FALSE
		next_action_at = world.time + 0.5 SECONDS
	if(action in GLOB.antag_training_squad_actions)
		return squad_act(action, params)
	if(action in GLOB.antag_training_pad_actions)
		return pad_act(action, params)
	if(scenario_intercepts(action, params))
		return TRUE
	if(arena.duel?.includes(src) && !(action in list("duel_accept", "duel_cancel", "reset_approve", "reset_cancel")))
		arena.duel.finish("Дуэль завершена: участник изменил условия через пульт.")
	if(findtext(action, "stand_") == 1)
		return stand_act(action, params)
	switch(action)
		if("kit")
			issue_kit(params["id"])
		if("practice")
			start_practice(params["id"])
		if("practice_stop")
			stop_practice()
		if("exercise_start")
			start_exercise(params["id"])
		if("exercise_stop")
			stop_exercise()
		if("exercise_hint")
			exercise_hint()
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
		if("hub")
			var/turf/arrival = arena.hub_arrival()
			if(arrival)
				current_body.forceMove(arrival)
		if("sector_enter")
			INVOKE_ASYNC(src, PROC_REF(try_enter_sector), params["id"])
		if("reset_zone")
			arena.request_reset(src, params["zone"])
		if("reset_approve")
			arena.approve_reset(src)
		if("reset_cancel")
			if(arena.may_cancel_reset(src))
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
		if("target_heal", "target_delete", "target_hunt", "target_injure", "target_condition")
			var/mob/living/target = locate(params["id"]) in arena.targets
			if(!can_manage_target(target) || !arena.owns_area(get_area(heretic_pocket_anchor(get_turf(target)))))
				return FALSE
			if(!isliving(target))
				if(action == "target_delete")
					qdel(target)
				return TRUE
			if(action == "target_heal")
				if(exercise_holds_target(target))
					return FALSE
				if(practice_target?.resolve() == target)
					stop_practice()
				target.revive(full_heal = TRUE, admin_revive = TRUE)
			else if(action == "target_injure")
				injure_target(target, params["injury"])
			else if(action == "target_condition")
				condition_target(target, params["condition"])
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
				if("[program_type]" == params["program"] && antag_training_program_selectable(program_type))
					restart(program_type)
					break
		if("set_role")
			if(istext(params["role"]))
				set_role(params["role"])
		if("exit")
			INVOKE_ASYNC(src, PROC_REF(request_exit), usr)
	return TRUE

/// Учебные цели ролей участника с отметкой выполнения: брифинг в чате уходит вверх, а пульт держит их под рукой.
/datum/antag_training_session/proc/role_objectives()
	. = list()
	for(var/datum/antagonist/role_datum as anything in avatar_mind?.antag_datums)
		for(var/datum/objective/antag_training/objective in role_datum.objectives)
			. += list(list("text" = objective.explanation_text, "done" = !!objective.completed))

/// Что делать дальше: текущий шаг идущего упражнения, иначе первая невыполненная цель роли.
/datum/antag_training_session/proc/role_next_step(list/goals)
	var/datum/antag_training_exercise_step/active = exercise_run?.current_step()
	if(active && !exercise_run.ended)
		return "Упражнение «[exercise_run.exercise.name]», шаг [exercise_run.step_index] из [length(exercise_run.steps)]: [active.name]."
	for(var/list/goal as anything in goals)
		if(!goal["done"])
			return goal["text"]
	return null

/datum/antag_training_session/proc/console_enter_sector(sector_id)
	var/datum/antag_training_sector/sector = arena.sectors[sector_id]
	var/failure = "Сектор не удалось загрузить. Попробуйте ещё раз или сбросьте полигон."
	if(enter_sector(sector))
		if(last_feedback == failure)
			last_feedback = null
		return TRUE
	// Сектор готов, значит за время загрузки сменилось тело: это не отказ.
	if(finished || arena.finished || sector?.state == ANTAG_TRAINING_SECTOR_READY || sector?.entry_refusal(src))
		return FALSE
	last_feedback = failure
	to_chat(current_body, span_warning(failure))
	return FALSE

/proc/antag_training_sector_state_name(state)
	switch(state)
		if(ANTAG_TRAINING_SECTOR_LOADING)
			return "loading"
		if(ANTAG_TRAINING_SECTOR_READY)
			return "ready"
		if(ANTAG_TRAINING_SECTOR_UNLOADING)
			return "unloading"
	return "unloaded"
