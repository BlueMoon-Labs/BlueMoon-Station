/obj/structure/swarmer/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	if(team && team != user.team)
		return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_TEAM
	switch(user.a_intent)
		if(INTENT_HELP)
			swarmer_help_act(user)
		if(INTENT_DISARM)
			swarmer_disarm_act(user)
		if(INTENT_GRAB)
			swarmer_grab_act(user)
		if(INTENT_HARM)
			swarmer_harm_act(user)

	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/obj/machinery/porta_turret/swarmer/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	if(team && team != user.team)
		return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_TEAM
	switch(user.a_intent)
		if(INTENT_HELP)
			swarmer_help_act(user)
		if(INTENT_DISARM)
			swarmer_disarm_act(user)
		if(INTENT_GRAB)
			swarmer_grab_act(user)
		if(INTENT_HARM)
			swarmer_harm_act(user)

	return SWARMER_ACT_IMPOSSIBLE | SWARMER_ACT_IMPOSSIBLE_REASON_OVERRIDE

/obj/structure/swarmer/collect_screentip_context(mob/living/user, obj/item/held_item, list/context)
	. = ..()
	var/mob/living/simple_animal/hostile/swarmer/swarmer = user
	if(!istype(swarmer) || (team && swarmer.team != team) || istype(src, /obj/structure/swarmer/swarmer_core_field))
		return

	var/help_hint
	var/is_core = istype(src, /obj/structure/swarmer/core)
	var/obj/structure/swarmer/repair_station/repair_station = src
	var/station_occupied = istype(repair_station) && repair_station.repair_target
	if(anchored)
		if(is_core)
			help_hint = "Выбрать корпус"
		else if(istype(src, /obj/structure/swarmer/transport_hub))
			var/obj/structure/swarmer/transport_hub/hub = src
			if(hub.enabled)
				help_hint = "Выбрать хаб для телепортации"

	var/obj/structure/swarmer/organic_processer/processer = src
	var/obj/structure/swarmer/organic_analyzer/analyzer = src
	var/obj/structure/swarmer/power_cell/power_cell = src
	var/cell_linked = istype(power_cell) && power_cell.fabricator_beam
	var/can_repair = !station_occupied && !cell_linked
	var/can_dismantle = !is_core && !station_occupied
	var/can_move = can_dismantle && !cell_linked && !(istype(processer) && processer.currently_processing) && !(istype(analyzer) && analyzer.occupant)
	return . | add_swarmer_structure_hints(swarmer, context, help_hint, can_repair, can_move, can_dismantle)

/obj/machinery/porta_turret/swarmer/collect_screentip_context(mob/living/user, obj/item/held_item, list/context)
	. = ..()
	var/mob/living/simple_animal/hostile/swarmer/swarmer = user
	if(istype(swarmer) && (!team || swarmer.team == team))
		return . | add_swarmer_structure_hints(swarmer, context, "Открыть панель турели")

/obj/proc/add_swarmer_structure_hints(mob/living/simple_animal/hostile/swarmer/swarmer, list/context, help_hint, can_repair = TRUE, can_move = TRUE, can_dismantle = TRUE)
	. = NONE
	if(help_hint)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_HELP, help_hint)
		. |= CONTEXTUAL_SCREENTIP_SET
	if(can_repair && obj_integrity < max_integrity)
		LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_DISARM, "Починить ([SWARMER_REPAIR_COST(swarmer)] ед. металла)")
		. |= CONTEXTUAL_SCREENTIP_SET
	if(is_builderswarmer(swarmer))
		if(can_move)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_GRAB, anchored ? "Открепить" : "Закрепить")
			. |= CONTEXTUAL_SCREENTIP_SET
		if(can_dismantle)
			LAZYSET(context[SCREENTIP_CONTEXT_LMB], INTENT_HARM, "Разобрать")
			. |= CONTEXTUAL_SCREENTIP_SET

/obj/item/food/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_PROCESS_ORGANIC

/obj/item/grown/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_PROCESS_ORGANIC

/obj/item/seeds/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_PROCESS_ORGANIC

/obj/machinery/hydroponics/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	if(!myseed)
		return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_DISMANTLE
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_PROCESS_ORGANIC

/obj/machinery/hydroponics/proc/harvest_for_swarmer()
	if(!myseed)
		return FALSE
	age = 0
	plant_health = 0
	if(harvest)
		harvest = FALSE
	QDEL_NULL(myseed)
	update_icon()
	return TRUE

/obj/item/reagent_containers/swarmer_act(mob/living/simple_animal/hostile/swarmer/user)
	if(!reagents?.total_volume)
		return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_CONSUME
	return SWARMER_ACT_POSSIBLE | SWARMER_ACT_POSSIBLE_ACTION_PROCESS_ORGANIC
