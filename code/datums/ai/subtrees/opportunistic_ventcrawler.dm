// Вентиляция для AI. Гибрид двух доноров:
// - каркас сабтри = tgstation@14140a6355d1 basic_subtrees/opportunistic_ventcrawler.dm;
// - интеракция с вентом (гард от повторного входа) и идея парного
//   entrance/exit подбора = Paradise@6323ddd65be9 (ventcrawl_subtree.dm);
// - траверс внутри трубы = проверенный на нашем нативном атмосе обход
//   parents[1].other_atmosmch (как у terror spiders).

/// Opportunistically searches for and scurries through vents.
/datum/ai_planning_subtree/opportunistic_ventcrawler
	///радиус поиска входного вента
	var/vent_search_range = 7

/datum/ai_planning_subtree/opportunistic_ventcrawler/SelectBehaviors(datum/ai_controller/controller, delta_time)
	var/mob/living/living_pawn = controller.pawn
	var/atom/final_target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(istype(living_pawn.loc, /obj/machinery/atmospherics))
		//В трубе предпочитаем заранее выбранный выход возле боевой цели.
		controller.queue_behavior(/datum/ai_behavior/exit_vents_near_target)
		return SUBTREE_RETURN_FINISH_PLANNING
	if(QDELETED(final_target) || get_dist(living_pawn, final_target) <= vent_search_range)
		controller.clear_blackboard_key(BB_AI_ENTRY_VENT)
		controller.clear_blackboard_key(BB_AI_EXIT_VENT)
		controller.clear_blackboard_key(BB_AI_VENT_FINAL_TARGET)
		return
	controller.set_blackboard_key(BB_AI_VENT_FINAL_TARGET, final_target)

	var/obj/machinery/atmospherics/entry_vent = controller.blackboard[BB_AI_ENTRY_VENT]
	var/obj/machinery/atmospherics/exit_vent = controller.blackboard[BB_AI_EXIT_VENT]
	if(QDELETED(entry_vent) || QDELETED(exit_vent) || !entry_vent.can_crawl_through() || !exit_vent.can_crawl_through() || exit_vent.z != final_target.z || get_dist(exit_vent, final_target) > vent_search_range)
		controller.clear_blackboard_key(BB_AI_ENTRY_VENT)
		controller.clear_blackboard_key(BB_AI_EXIT_VENT)
		controller.queue_behavior(/datum/ai_behavior/find_targeted_vent_route, vent_search_range)
		return

	if(get_turf(living_pawn) != get_turf(entry_vent))
		controller.queue_behavior(/datum/ai_behavior/travel_towards, BB_AI_ENTRY_VENT)
		return

	controller.queue_behavior(/datum/ai_behavior/enter_vent, BB_AI_ENTRY_VENT)
	return SUBTREE_RETURN_FINISH_PLANNING //we are going into this vent... no distractions

///Найти пару вход/выход одной сети: вход рядом с мобом, выход ближе всего к цели.
/datum/ai_behavior/find_targeted_vent_route
	action_cooldown = 2 SECONDS

/datum/ai_behavior/find_targeted_vent_route/perform(delta_time, datum/ai_controller/controller, search_range)
	var/mob/living/living_pawn = controller.pawn
	var/atom/final_target = controller.blackboard[BB_AI_VENT_FINAL_TARGET]
	if(!istype(living_pawn) || QDELETED(final_target))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	var/obj/machinery/atmospherics/best_entry
	var/obj/machinery/atmospherics/best_exit
	var/best_score = INFINITY
	for(var/obj/machinery/atmospherics/entry in range(search_range, living_pawn))
		if(!is_type_in_typecache(entry, GLOB.ventcrawl_machinery) || !entry.can_crawl_through())
			continue
		var/datum/pipeline/pipeline = entry.returnPipenet()
		if(!pipeline)
			continue
		for(var/obj/machinery/atmospherics/exit as anything in pipeline.other_atmosmch)
			if(exit == entry || !is_type_in_typecache(exit, GLOB.ventcrawl_machinery) || !exit.can_crawl_through())
				continue
			var/exit_distance = get_dist(exit, final_target)
			if(exit_distance > search_range)
				continue
			var/route_score = get_dist(living_pawn, entry) + exit_distance
			if(route_score >= best_score)
				continue
			best_score = route_score
			best_entry = entry
			best_exit = exit
	if(!best_entry || !best_exit)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	controller.set_blackboard_key(BB_AI_ENTRY_VENT, best_entry)
	controller.set_blackboard_key(BB_AI_EXIT_VENT, best_exit)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

///Войти в вент; гард BB_AI_CURRENTLY_VENTING - от повторного входа во время
///анимации (идея Paradise interact_with_vent)
/datum/ai_behavior/enter_vent
	behavior_flags = AI_BEHAVIOR_REQUIRE_MOVEMENT | AI_BEHAVIOR_REQUIRE_REACH
	required_distance = 0
	action_cooldown = 1 SECONDS

/datum/ai_behavior/enter_vent/setup(datum/ai_controller/controller, target_key)
	. = ..()
	var/atom/target = controller.blackboard[target_key]
	if(QDELETED(target))
		return FALSE
	set_movement_target(controller, target)

/datum/ai_behavior/enter_vent/perform(delta_time, datum/ai_controller/controller, target_key)
	var/obj/machinery/atmospherics/vent = controller.blackboard[target_key]
	var/mob/living/living_pawn = controller.pawn
	if(QDELETED(vent) || !istype(living_pawn))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	if(controller.blackboard[BB_AI_CURRENTLY_VENTING])
		return AI_BEHAVIOR_DELAY
	controller.set_blackboard_key(BB_AI_CURRENTLY_VENTING, TRUE)
	living_pawn.handle_ventcrawl(vent)
	controller.set_blackboard_key(BB_AI_CURRENTLY_VENTING, FALSE)
	if(QDELETED(controller) || living_pawn.loc != vent)
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED

/datum/ai_behavior/enter_vent/finish_action(datum/ai_controller/controller, succeeded, target_key)
	. = ..()
	controller.clear_blackboard_key(target_key)

///Выйти через выбранный целевой вент; при потере маршрута — ближайший валидный.
/datum/ai_behavior/exit_vents_near_target
	action_cooldown = 2 SECONDS

/datum/ai_behavior/exit_vents_near_target/perform(delta_time, datum/ai_controller/controller)
	var/mob/living/living_pawn = controller.pawn
	var/obj/machinery/atmospherics/current_pipe = living_pawn.loc
	if(!istype(current_pipe))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED //уже снаружи

	var/list/possible_exits = list()
	var/datum/pipeline/our_pipeline = current_pipe.returnPipenet()
	if(our_pipeline)
		for(var/obj/machinery/atmospherics/exit_machine as anything in our_pipeline.other_atmosmch)
			if(!is_type_in_typecache(exit_machine, GLOB.ventcrawl_machinery))
				continue
			var/obj/machinery/atmospherics/components/unary/exit_vent = exit_machine
			if(!exit_vent.can_crawl_through())
				continue
			possible_exits += exit_vent
	if(!length(possible_exits))
		return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_FAILED

	var/obj/machinery/atmospherics/chosen_exit = controller.blackboard[BB_AI_EXIT_VENT]
	if(QDELETED(chosen_exit) || !(chosen_exit in possible_exits))
		chosen_exit = possible_exits[1]
		var/atom/final_target = controller.blackboard[BB_AI_VENT_FINAL_TARGET]
		if(!QDELETED(final_target))
			for(var/obj/machinery/atmospherics/candidate as anything in possible_exits)
				if(get_dist(candidate, final_target) < get_dist(chosen_exit, final_target))
					chosen_exit = candidate
	living_pawn.forceMove(get_turf(chosen_exit))
	living_pawn.update_pipe_vision()
	controller.clear_blackboard_key(BB_AI_ENTRY_VENT)
	controller.clear_blackboard_key(BB_AI_EXIT_VENT)
	controller.clear_blackboard_key(BB_AI_VENT_FINAL_TARGET)
	return AI_BEHAVIOR_DELAY | AI_BEHAVIOR_SUCCEEDED
