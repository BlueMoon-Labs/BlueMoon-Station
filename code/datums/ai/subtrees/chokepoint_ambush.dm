// Засада на чокпоинте (A.3). Опт-ин повадка «сталкера»: потеряв цель из виду
// (state SEARCH), моб не идёт тупо к последней улике, а занимает узкое место -
// дверной проём или сужение коридора - между собой и уликой, и ЖДЁТ там, глядя на
// точку. "Я оторвался" превращается в "оно ждёт меня за дверью". Опт-ин = наличие
// этого сабтри в списке профиля (сейчас только террор-спайдеры); ставится ПЕРЕД
// hostile_fsm, чтобы перехватить его обычный поиск.
//
// Реаквизиция по своему LOS (find_potential_targets вернёт цель) -> hostile_fsm
// уводит в ENGAGE, гейт state!=SEARCH снимает засаду. Истёк SEARCH_UNTIL -> не
// преемптим, hostile_fsm сдаётся штатно. Нет чокпоинта -> обычный поиск.

/datum/ai_planning_subtree/chokepoint_ambush

/datum/ai_planning_subtree/chokepoint_ambush/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	if(controller.blackboard[BB_AI_STATE] != AI_STATE_SEARCH)
		controller.clear_blackboard_key(BB_AI_AMBUSH_TILE) //не в поиске - засада не актуальна
		return
	//SEARCH-окно истекло: не преемптим, пусть hostile_fsm сдаётся и уйдёт к мирной жизни
	if(world.time >= (controller.blackboard[BB_AI_SEARCH_UNTIL] || 0))
		return
	var/turf/evidence = controller.blackboard[BB_AI_LAST_KNOWN_POS]
	if(!evidence)
		return
	var/mob/living/pawn = controller.pawn
	if(!isliving(pawn))
		return

	//уже держим валидный чокпоинт - ждём в засаде дальше
	var/turf/held = controller.blackboard[BB_AI_AMBUSH_TILE]
	if(held && is_ambush_chokepoint(held) && controller.can_enter_turf(held))
		controller.queue_behavior(/datum/ai_behavior/hold_covering_position, held)
		return SUBTREE_RETURN_FINISH_PLANNING

	var/turf/chokepoint = find_ambush_chokepoint(controller, pawn, evidence)
	if(!chokepoint)
		controller.clear_blackboard_key(BB_AI_AMBUSH_TILE)
		return //нет чокпоинта - обычный поиск hostile_fsm
	controller.set_blackboard_key(BB_AI_AMBUSH_TILE, chokepoint)
	controller.queue_behavior(/datum/ai_behavior/hold_covering_position, chokepoint)
	return SUBTREE_RETURN_FINISH_PLANNING

///Ближайший к улике стоячий чокпоинт на линии pawn->улика, достижимый и свободный.
///Берём именно ближний к улике: там жертва пройдёт последним, туда и караулим.
/datum/ai_planning_subtree/chokepoint_ambush/proc/find_ambush_chokepoint(datum/ai_controller/controller, mob/living/pawn, turf/evidence)
	var/turf/pawn_turf = get_turf(pawn)
	if(!pawn_turf || !evidence || pawn_turf.z != evidence.z || pawn_turf == evidence)
		return null
	var/list/line = getline(pawn_turf, evidence)
	for(var/i = length(line), i >= 1, i--)
		var/turf/tile = line[i]
		if(tile == pawn_turf || tile == evidence)
			continue
		if(!is_ambush_chokepoint(tile))
			continue
		if(!controller.can_enter_turf(tile) || tile.is_blocked_turf(source_atom = pawn))
			continue
		return tile
	return null

///Чокпоинт-засады: стоячий открытый тайл, который является сужением коридора
///(зажат плотным с двух ПРОТИВОПОЛОЖНЫХ сторон) ЛИБО примыкает к двери/шлюзу
///(моб караулит проём). Проверка дешёвая: до 6 соседних is_blocked_turf.
/proc/is_ambush_chokepoint(turf/tile)
	if(!isopenturf(tile))
		return FALSE
	var/turf/north = get_step(tile, NORTH)
	var/turf/south = get_step(tile, SOUTH)
	if(north?.is_blocked_turf(exclude_mobs = TRUE) && south?.is_blocked_turf(exclude_mobs = TRUE))
		return TRUE
	var/turf/east = get_step(tile, EAST)
	var/turf/west = get_step(tile, WEST)
	if(east?.is_blocked_turf(exclude_mobs = TRUE) && west?.is_blocked_turf(exclude_mobs = TRUE))
		return TRUE
	for(var/direction in GLOB.cardinals)
		var/turf/neighbor = get_step(tile, direction)
		if(neighbor && (locate(/obj/machinery/door) in neighbor))
			return TRUE
	return FALSE
