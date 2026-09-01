// ===== Засада на чокпоинте (A.3) =====
//
// Проверяют: сталкер в SEARCH встаёт в засаду на сужении коридора между собой и
// уликой (а не идёт к улике); без чокпоинта - обычный поиск; повадка есть только у
// террор-спайдеров (опт-ин).

///Сталкер в SEARCH держит позицию на сужении коридора между собой и уликой.
/datum/unit_test/ai_chokepoint_ambush_holds_at_pinch/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/pawn_turf = locate(start.x, start.y + 2, start.z)
	var/turf/evidence = locate(start.x + 3, start.y + 2, start.z)
	var/turf/pinch = locate(start.x + 2, start.y + 2, start.z)
	var/turf/wall_n = locate(start.x + 2, start.y + 3, start.z)
	var/turf/wall_s = locate(start.x + 2, start.y + 1, start.z)
	var/saved_n = wall_n.type
	var/saved_s = wall_s.type
	wall_n.ChangeTurf(/turf/closed/wall)
	wall_s.ChangeTurf(/turf/closed/wall)

	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_STATE, AI_STATE_SEARCH)
	controller.set_blackboard_key(BB_AI_LAST_KNOWN_POS, evidence)
	controller.blackboard[BB_AI_SEARCH_UNTIL] = world.time + 100

	var/datum/ai_planning_subtree/chokepoint_ambush/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/chokepoint_ambush]
	var/verdict = subtree.SelectBehaviors(controller, 0.5)

	wall_n.ChangeTurf(saved_n)
	wall_s.ChangeTurf(saved_s)

	TEST_ASSERT_EQUAL(controller.blackboard[BB_AI_AMBUSH_TILE], pinch, "The stalker must ambush at the corridor pinch between itself and the evidence")
	TEST_ASSERT_EQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "Holding an ambush must preempt the normal search")
	TEST_ASSERT(GET_AI_BEHAVIOR(/datum/ai_behavior/hold_covering_position) in controller.current_behaviors, "The stalker must hold position at the chokepoint")

	controller.CancelActions()
	qdel(controller)

///Без чокпоинта на пути - засады нет, обычный поиск (сабтри не преемптит).
/datum/unit_test/ai_chokepoint_ambush_no_chokepoint/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/turf/pawn_turf = locate(start.x, start.y + 2, start.z)
	var/turf/evidence = locate(start.x + 3, start.y + 2, start.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, pawn_turf)
	var/datum/ai_controller/hostile_adapter/melee_chaser/controller = new(pawn)
	controller.set_blackboard_key(BB_AI_STATE, AI_STATE_SEARCH)
	controller.set_blackboard_key(BB_AI_LAST_KNOWN_POS, evidence)
	controller.blackboard[BB_AI_SEARCH_UNTIL] = world.time + 100

	var/datum/ai_planning_subtree/chokepoint_ambush/subtree = GLOB.ai_subtrees[/datum/ai_planning_subtree/chokepoint_ambush]
	var/verdict = subtree.SelectBehaviors(controller, 0.5)

	TEST_ASSERT_NULL(controller.blackboard[BB_AI_AMBUSH_TILE], "No chokepoint means no ambush tile")
	TEST_ASSERT_NOTEQUAL(verdict, SUBTREE_RETURN_FINISH_PLANNING, "Without a chokepoint the subtree must yield to the normal search")
	TEST_ASSERT(!(GET_AI_BEHAVIOR(/datum/ai_behavior/hold_covering_position) in controller.current_behaviors), "No chokepoint must not plan an ambush hold")

	controller.CancelActions()
	qdel(controller)

///Опт-ин: засада на чокпоинте есть только у террор-спайдеров (сталкеров).
/datum/unit_test/ai_chokepoint_ambush_terror_only/Run()
	//planning_subtrees на рантайме = список ИНСТАНСОВ-синглтонов (init_subtrees), не типов
	var/datum/ai_planning_subtree/chokepoint_ambush/singleton = GLOB.ai_subtrees[/datum/ai_planning_subtree/chokepoint_ambush]
	var/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight/spider = allocate(/mob/living/simple_animal/hostile/retaliate/poison/terror_spider/knight)
	var/datum/ai_controller/hostile_adapter/terror_spider/terror_controller = spider.ai_controller
	TEST_ASSERT(istype(terror_controller), "Sanity: a terror spider must use the terror controller")
	TEST_ASSERT(singleton in terror_controller.planning_subtrees, "Terror spiders must have the chokepoint ambush subtree")

	var/mob/living/simple_animal/hostile/plain = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/hostile_adapter/melee_chaser/plain_controller = new(plain)
	TEST_ASSERT(!(singleton in plain_controller.planning_subtrees), "A plain melee mob must not stalk chokepoints (opt-in only)")
	qdel(plain_controller)
