// ===== Экономия поиска пути ИИ =====
//
// Факты клетки в JPS должны давать тот же ответ, что честный LinkBlockedWithAccess(),
// а союзник на маршруте обходится шагом в сторону без нового поиска.

///Клетка, где ничего не стоит, и клетки с разными помехами: ответ JPS по каждому ребру
///совпадает с прямой проверкой и для безразличного к воздуху моба, и для того, кому воздух вреден
/datum/unit_test/ai_jps_turf_facts_match_link_check/Run()
	var/turf/center = locate(run_loc_floor_bottom_left.x + 2, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	allocate(/obj/structure/table, get_step(center, NORTH))
	var/obj/structure/window/pane = allocate(/obj/structure/window, get_step(center, EAST))
	pane.setDir(WEST)
	allocate(/obj/structure/ai_unit_test_path_probe, get_step(center, SOUTHWEST))
	allocate(/obj/effect/decal/cleanable/dirt, get_step(center, SOUTH))
	allocate(/obj/structure/railing, center)

	var/mob/living/simple_animal/hostile/plain = allocate(/mob/living/simple_animal/hostile, center)
	var/mob/living/simple_animal/hostile/fragile = allocate(/mob/living/simple_animal/hostile, center)
	fragile.atmos_requirements = list("min_oxy" = 0, "max_oxy" = 1, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	fragile.unsuitable_atmos_damage = 1
	fragile.refresh_atmos_pathing_sensitivity()
	TEST_ASSERT(fragile.requires_safe_atmosphere(), "Sanity: station air must be unsafe for the fragile mob")

	for(var/mob/living/simple_animal/hostile/walker as anything in list(plain, fragile))
		var/check_environment = walker.requires_safe_atmosphere()
		var/datum/pathfind/pathfinder = new(walker, center, get_step(center, NORTH), null, 30, 0, TRUE, null)
		for(var/turf/source as anything in list(center, get_step(center, WEST)))
			for(var/direction in GLOB.alldirs)
				var/turf/destination = get_step(source, direction)
				var/expected = source.LinkBlockedWithAccess(destination, walker, null, check_environment, TRUE)
				TEST_ASSERT_EQUAL(pathfinder.link_blocked(source, destination, direction), expected, "JPS edge [source.x],[source.y] -> [dir2text(direction)] must match LinkBlockedWithAccess() for a mob [walker == plain ? "in breathable air" : "that cannot breathe here"]")
		qdel(pathfinder)

///Союзник на следующей клетке маршрута: моб берёт соседнюю клетку, от которой маршрут
///продолжается, и новый поиск пути не запускается
/datum/unit_test/ai_hybrid_sidesteps_ally_without_search/Run()
	var/turf/start = locate(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z)
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, start)
	var/turf/blocked = get_step(start, EAST)
	var/turf/rejoin = get_step(blocked, EAST)
	var/mob/living/simple_animal/hostile/ally = allocate(/mob/living/simple_animal/hostile, blocked)
	ally.faction = pawn.faction.Copy()
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(start.x + 4, start.y, start.z))
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	mover.start_jps_loop(controller, prey)
	var/datum/move_loop/has_target/jps/loop = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT(istype(loop), "Sanity: the hybrid JPS loop must start")
	TEST_ASSERT(loop.defer_failed_step_repath, "A hybrid JPS loop must leave failed-step repaths to its post-move handler")
	hold_move_loop(loop)
	await_initial_route(loop)

	var/turf/finish = get_step(rejoin, EAST)
	loop.movement_path = list(blocked, rejoin, finish)
	var/searches_before = GLOB.ai_metrics.jps_requests
	mover.post_move_jps(loop, FALSE)
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.jps_requests, searches_before, "Stepping around an ally must not start a path search")
	TEST_ASSERT_NULL(loop.avoid, "A sidestep needs no avoided turf")
	TEST_ASSERT_EQUAL(length(loop.movement_path), 3, "The sidestep must keep the rest of the route")
	var/turf/detour = loop.movement_path[1]
	TEST_ASSERT(detour != blocked && get_dist(detour, start) == 1 && get_dist(detour, rejoin) == 1, "The detour must be a free tile next to us and next to the rest of the route")
	TEST_ASSERT(loop.movement_path[2] == rejoin, "The route must continue from the same tile")

	//обе соседние обходные клетки заняты: сначала ждём шаг, потом короткий поиск до маршрута впереди
	for(var/direction in list(NORTHEAST, SOUTHEAST))
		allocate(/obj/structure/ai_unit_test_boundary, get_step(start, direction))
	loop.movement_path = list(blocked, rejoin, finish)
	mover.post_move_jps(loop, FALSE)
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.jps_requests, searches_before, "The first block without a detour must just wait a step")
	TEST_ASSERT(loop.movement_path[1] == blocked, "Waiting must keep the route")
	mover.post_move_jps(loop, FALSE)
	TEST_ASSERT(GLOB.ai_metrics.jps_requests > searches_before, "A second block in a row must search a way around")
	TEST_ASSERT(wait_for_var(loop, "repath_in_progress", FALSE, 5 SECONDS), "The short detour search must finish")
	TEST_ASSERT_NULL(loop.avoid, "A short detour must not leave the ally's tile avoided")
	TEST_ASSERT(length(loop.movement_path) && !(blocked in loop.movement_path), "The repaired route must skip the ally's tile")
	TEST_ASSERT(loop.movement_path[length(loop.movement_path)] == finish, "The repaired route must end where the old one did")

	mover.stop_moving_towards(controller)
	qdel(controller)

///Шаг сорвался о неподвижную преграду: перепрокладка по-прежнему запускается, только из обработчика
/datum/unit_test/ai_hybrid_static_block_still_repaths/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/turf/blocked = get_step(run_loc_floor_bottom_left, EAST)
	allocate(/obj/structure/ai_unit_test_boundary, blocked)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 3, run_loc_floor_bottom_left.y, run_loc_floor_bottom_left.z))
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	mover.start_jps_loop(controller, prey)
	var/datum/move_loop/has_target/jps/loop = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT(istype(loop), "Sanity: the hybrid JPS loop must start")
	hold_move_loop(loop)
	await_initial_route(loop)

	loop.movement_path = list(blocked)
	COOLDOWN_RESET(loop, repath_cooldown)
	var/repaths_before = GLOB.ai_metrics.jps_repaths
	TEST_ASSERT(!loop.move(), "Sanity: the step into the boundary must fail")
	TEST_ASSERT_EQUAL(GLOB.ai_metrics.jps_repaths, repaths_before, "The failed step itself must leave the search to the post-move handler")
	var/attempts_before = controller.pathing_attempts
	mover.post_move_jps(loop, FALSE)
	TEST_ASSERT(GLOB.ai_metrics.jps_repaths > repaths_before, "A step failed on a static blocker must still start a new search")
	TEST_ASSERT_EQUAL(controller.pathing_attempts, attempts_before + 1, "A step failed on a static blocker must still count as a pathing failure")

	mover.stop_moving_towards(controller)
	qdel(controller)

///Новая цель у конца живого маршрута (тайл подхода у той же жертвы) берёт этот маршрут, а далёкая - нет
/datum/unit_test/ai_hybrid_keeps_route_for_nearby_goal/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile, run_loc_floor_bottom_left)
	var/mob/living/carbon/human/prey = allocate(/mob/living/carbon/human, locate(run_loc_floor_bottom_left.x + 4, run_loc_floor_bottom_left.y + 2, run_loc_floor_bottom_left.z))
	var/datum/ai_controller/unit_test_mover/controller = new(pawn)
	var/datum/ai_movement/hybrid/mover = SSai_movement.movement_types[/datum/ai_movement/hybrid]
	mover.start_jps_loop(controller, prey)
	var/datum/move_loop/has_target/jps/loop = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT(istype(loop), "Sanity: the hybrid JPS loop must start")
	hold_move_loop(loop)
	await_initial_route(loop)
	var/turf/route_end = get_step(prey, WEST)
	loop.movement_path = list(get_step(pawn, NORTHEAST), get_step(get_step(pawn, NORTHEAST), NORTHEAST), route_end)

	var/turf/approach = get_step(prey, NORTHWEST)
	mover.start_moving_towards(controller, approach, 1)
	TEST_ASSERT(SSmove_manager.processing_on(pawn, SSai_movement) == loop, "A goal next to the end of the live route must keep that route")
	TEST_ASSERT(loop.target == approach, "The kept route must chase the new goal")
	TEST_ASSERT_EQUAL(length(loop.movement_path), 3, "The kept route must stay as it was")

	var/turf/far_goal = locate(run_loc_floor_bottom_left.x, run_loc_floor_bottom_left.y + 4, run_loc_floor_bottom_left.z)
	mover.start_moving_towards(controller, far_goal, 1)
	var/datum/move_loop/fresh = SSmove_manager.processing_on(pawn, SSai_movement)
	TEST_ASSERT(fresh != loop && !istype(fresh, /datum/move_loop/has_target/jps), "A goal far from the live route must start a fresh direct chase")

	mover.stop_moving_towards(controller)
	qdel(controller)
