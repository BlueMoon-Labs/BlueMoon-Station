// Политика преодоления препятствий hostile AI:
// открыть -> взломать/выломать -> сдаться. Порядок и разрешения задаются
// профилем через BB_AI_OBSTACLE_POLICY. Синглтоны в
// SSai_behaviors.obstacle_policies. Сначала ищется чистый обход через JPS;
// если его нет, контроллер строит ограниченный взвешенный путь через преграды.
// Вентиляцию решает вент-сабтри (uses_vents).
// Дверная логика - обобщение try_open_airlock terror spiders
// (modular_bluemoon/code/modules/mob/terror_spiders/terror_spiders.dm).

///Whether this pressure barrier physically separates these two cardinal turfs.
/proc/ai_pressure_barrier_blocks_step(obj/barrier, turf/from_turf, turf/to_turf)
	if(!barrier?.density || !from_turf || !to_turf)
		return FALSE
	var/barrier_side
	if(barrier.loc == from_turf)
		barrier_side = get_dir(from_turf, to_turf)
	else if(barrier.loc == to_turf)
		barrier_side = get_dir(to_turf, from_turf)
	else
		return FALSE

	var/obj/structure/window/window = barrier
	if(istype(window))
		return window.fulltile || window.dir == barrier_side
	if(istype(barrier, /obj/machinery/door/window) || istype(barrier, /obj/machinery/door/firedoor/border_only))
		return barrier.dir == barrier_side
	return istype(barrier, /obj/machinery/door) && barrier.loc == to_turf

/datum/obstacle_policy
	///Открывать ли двери по доступу (обесточенные - всегда, если TRUE)
	var/opens_doors = TRUE
	///Силой открывать запитанные двери без доступа
	var/forces_powered_doors = FALSE
	///Поддевать пожарные шлюзы
	var/pries_firedoors = TRUE
	///Ломать плотные объекты на пути
	var/smashes_structures = TRUE
	///Перелезать через штатно climbable-преграды вместо их разрушения
	var/climbs_structures = TRUE
	///Разрешение на вентиляцию (читается вент-сабтри, не этим датумом)
	var/uses_vents = FALSE
	///Relative weights used only after ordinary JPS proves that no clean route exists.
	var/climb_cost = 3
	var/forced_open_cost = 6
	var/wall_breach_cost = 12
	var/reinforced_wall_breach_cost = 24
	var/hit_breach_cost = 4

///Whether opening/destroying a pressure barrier on this edge is safe for pawn.
/datum/obstacle_policy/proc/step_preserves_atmosphere(mob/living/pawn, turf/from_turf, turf/to_turf)
	var/mob/living/simple_animal/simple_pawn = pawn
	if(!istype(simple_pawn))
		return TRUE
	if(!simple_pawn.requires_safe_atmosphere())
		return TRUE
	if(!simple_pawn.can_safely_enter_turf(to_turf))
		return FALSE
	for(var/obj/barrier in from_turf)
		if(ai_pressure_barrier_blocks_step(barrier, from_turf, to_turf) && !simple_pawn.can_safely_open_pressure_barrier(barrier))
			return FALSE
	for(var/obj/barrier in to_turf)
		if(ai_pressure_barrier_blocks_step(barrier, from_turf, to_turf) && !simple_pawn.can_safely_open_pressure_barrier(barrier))
			return FALSE
	return TRUE

///Whether the generic animal attack can actually make progress on blocker.
/datum/obstacle_policy/proc/can_smash_blocker(mob/living/pawn, datum/ai_controller/controller, obj/blocker)
	if(!smashes_structures || !blocker?.density || blocker.IsObscured() || (blocker.resistance_flags & INDESTRUCTIBLE))
		return FALSE
	if(pawn.see_invisible < blocker.invisibility)
		return FALSE
	var/list/whitelist = controller.blackboard[BB_AI_OBSTACLE_WHITELIST]
	if(whitelist && !is_type_in_typecache(blocker, whitelist))
		return FALSE
	var/mob/living/simple_animal/simple_pawn = pawn
	if(!istype(simple_pawn))
		return FALSE
	var/attack_damage = simple_pawn.obj_damage || simple_pawn.melee_damage_upper
	return attack_damage > blocker.damage_deflection

/datum/obstacle_policy/proc/can_smash_turf(mob/living/pawn, turf/blocked_turf)
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(!istype(hostile_pawn) || !hostile_pawn.environment_smash || !hostile_pawn.CanSmashTurfs(blocked_turf))
		return FALSE
	if(istype(blocked_turf, /turf/closed/wall/r_wall))
		return hostile_pawn.environment_smash & ENVIRONMENT_SMASH_RWALLS
	if(iswallturf(blocked_turf) || ismineralturf(blocked_turf))
		return hostile_pawn.environment_smash & (ENVIRONMENT_SMASH_WALLS | ENVIRONMENT_SMASH_RWALLS)
	return TRUE

///Whether this pawn can use the structure's normal climbing interaction.
/datum/obstacle_policy/proc/can_climb_blocker(mob/living/pawn, obj/blocker)
	var/obj/structure/structure = blocker
	return climbs_structures && istype(structure) && structure.climbable && CHECK_MOBILITY(pawn, MOBILITY_MOVE)

///Estimated number of attack cycles needed to clear a dense object.
/datum/obstacle_policy/proc/get_blocker_breach_cost(mob/living/pawn, datum/ai_controller/controller, obj/blocker, obj/item/card/id/id)
	if(!blocker?.density)
		return 1
	if(can_climb_blocker(pawn, blocker))
		return climb_cost

	if(istype(blocker, /obj/machinery/door/firedoor))
		var/obj/machinery/door/firedoor/fire_lock = blocker
		if(pries_firedoors && !fire_lock.welded)
			return forced_open_cost

	if(istype(blocker, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/airlock = blocker
		if(airlock.operating)
			return 1
		if(opens_doors && !airlock.welded && !airlock.locked)
			if(!airlock.hasPower() || forces_powered_doors || airlock.emergency || airlock.check_access(id))
				return forced_open_cost

	if(istype(blocker, /obj/machinery/door/window))
		var/obj/machinery/door/window/windoor = blocker
		if(windoor.operating)
			return 1
		if(opens_doors && !windoor.locked && (!windoor.hasPower() || forces_powered_doors || windoor.emergency || windoor.check_access(id)))
			return forced_open_cost

	if(!can_smash_blocker(pawn, controller, blocker))
		return 0
	var/mob/living/simple_animal/simple_pawn = pawn
	var/attack_damage = max(simple_pawn.obj_damage || simple_pawn.melee_damage_upper, 1)
	var/effective_damage = max(attack_damage - blocker.damage_deflection, 1)
	return max(hit_breach_cost, CEILING(blocker.obj_integrity / effective_damage, 1) * hit_breach_cost)

///Cost of a cardinal step for the breach A*: 0 means impossible.
/datum/obstacle_policy/proc/get_breach_step_cost(mob/living/pawn, datum/ai_controller/controller, turf/from_turf, turf/to_turf, simulated_only, turf/avoid, obj/item/card/id/id, check_environment = TRUE)
	if(!from_turf || !to_turf || from_turf.z != to_turf.z || !(get_dir(from_turf, to_turf) in GLOB.cardinals))
		return 0
	if(to_turf == avoid || (simulated_only && SSpathfinder.space_type_cache[to_turf.type]))
		return 0
	if(!controller.can_enter_dangerous_turf(to_turf))
		return 0
	if(check_environment && !step_preserves_atmosphere(pawn, from_turf, to_turf))
		return 0

	// The pathfinder snapshots whether the pawn needs the environment gate.
	if(!to_turf.density && !from_turf.LinkBlockedWithAccess(to_turf, pawn, id, FALSE))
		return 1

	var/total_cost = 1
	var/has_clearable_blocker = FALSE
	if(to_turf.density)
		if(!can_smash_turf(pawn, to_turf))
			return 0
		has_clearable_blocker = TRUE
		total_cost += istype(to_turf, /turf/closed/wall/r_wall) ? reinforced_wall_breach_cost : wall_breach_cost

	var/actual_dir = get_dir(from_turf, to_turf)
	for(var/obj/structure/window/window in from_turf)
		if(window.CanAStarPass(id, actual_dir, pawn))
			continue
		var/blocker_cost = get_blocker_breach_cost(pawn, controller, window, id)
		if(!blocker_cost)
			return 0
		has_clearable_blocker = TRUE
		total_cost += blocker_cost
	for(var/obj/machinery/door/window/windoor in from_turf)
		if(windoor.CanAStarPass(id, actual_dir))
			continue
		var/blocker_cost = get_blocker_breach_cost(pawn, controller, windoor, id)
		if(!blocker_cost)
			return 0
		has_clearable_blocker = TRUE
		total_cost += blocker_cost
	for(var/obj/structure/railing/rail in from_turf)
		if(rail.CanAStarPass(id, actual_dir, pawn))
			continue
		var/blocker_cost = get_blocker_breach_cost(pawn, controller, rail, id)
		if(!blocker_cost)
			return 0
		has_clearable_blocker = TRUE
		total_cost += blocker_cost
	for(var/obj/machinery/door/firedoor/border_only/fire_lock in from_turf)
		if(fire_lock.CanAStarPass(id, actual_dir))
			continue
		var/blocker_cost = get_blocker_breach_cost(pawn, controller, fire_lock, id)
		if(!blocker_cost)
			return 0
		has_clearable_blocker = TRUE
		total_cost += blocker_cost

	var/reverse_dir = get_dir(to_turf, from_turf)
	for(var/obj/blocker in to_turf)
		if(blocker.CanAStarPass(id, reverse_dir, pawn))
			continue
		var/blocker_cost = get_blocker_breach_cost(pawn, controller, blocker, id)
		if(!blocker_cost)
			return 0
		has_clearable_blocker = TRUE
		total_cost += blocker_cost

	return has_clearable_blocker ? total_cost : 0

///Clear the blockers on one exact edge selected by the cached route.
/datum/obstacle_policy/proc/try_step(mob/living/pawn, datum/ai_controller/controller, turf/from_turf, turf/to_turf)
	if(!step_preserves_atmosphere(pawn, from_turf, to_turf))
		return FALSE
	var/obj/item/card/id/id = controller.get_access()
	var/actual_dir = get_dir(from_turf, to_turf)
	for(var/obj/structure/window/window in from_turf)
		if(!window.CanAStarPass(id, actual_dir, pawn) && try_handle(pawn, controller, window))
			return TRUE
	for(var/obj/machinery/door/window/windoor in from_turf)
		if(ai_pressure_barrier_blocks_step(windoor, from_turf, to_turf) && try_handle(pawn, controller, windoor))
			return TRUE
	for(var/obj/structure/railing/rail in from_turf)
		if(!rail.CanAStarPass(id, actual_dir, pawn) && try_handle(pawn, controller, rail))
			return TRUE
	for(var/obj/machinery/door/firedoor/border_only/fire_lock in from_turf)
		if(ai_pressure_barrier_blocks_step(fire_lock, from_turf, to_turf) && try_handle(pawn, controller, fire_lock))
			return TRUE
	for(var/obj/blocker in to_turf)
		if(blocker.density && try_handle(pawn, controller, blocker))
			return TRUE
	return try_turf(pawn, to_turf)

///Попытаться разобраться с конкретным препятствием; TRUE = чем-то занялись
/datum/obstacle_policy/proc/try_handle(mob/living/pawn, datum/ai_controller/controller, obj/blocker)
	if(!blocker.density || blocker.IsObscured())
		return FALSE
	if(pawn.see_invisible < blocker.invisibility)
		return FALSE
	var/obj/structure/climbable_structure = blocker
	if(istype(climbable_structure) && climbable_structure.climbable)
		//Only one asynchronous do_mob() may own the structure at a time. Waiting
		//is preferable to attacking the cover underneath another climber.
		if(climbable_structure.structureclimber)
			return TRUE
		if(can_climb_blocker(pawn, climbable_structure))
			INVOKE_ASYNC(climbable_structure, TYPE_PROC_REF(/obj/structure, climb_structure), pawn)
			return TRUE

	if(istype(blocker, /obj/machinery/door/firedoor))
		var/obj/machinery/door/firedoor/fire_lock = blocker
		if(pries_firedoors && !fire_lock.welded)
			INVOKE_ASYNC(fire_lock, TYPE_PROC_REF(/obj/machinery/door, open))
			return TRUE
		return try_smash(pawn, controller, blocker)

	if(istype(blocker, /obj/machinery/door/airlock))
		var/obj/machinery/door/airlock/airlock = blocker
		if(airlock.operating)
			return TRUE
		if(try_airlock(pawn, blocker))
			return TRUE
		return try_smash(pawn, controller, blocker)

	if(istype(blocker, /obj/machinery/door/window))
		var/obj/machinery/door/window/windoor = blocker
		if(windoor.operating)
			return TRUE
		if(opens_doors && !windoor.locked && (windoor.allowed(pawn) || !windoor.hasPower() || forces_powered_doors))
			INVOKE_ASYNC(windoor, TYPE_PROC_REF(/obj/machinery/door/window, open), TRUE)
			return TRUE
		return try_smash(pawn, controller, blocker)

	return try_smash(pawn, controller, blocker)

///Открыть шлюз: по доступу, обесточенный или силой (по разрешениям политики)
/datum/obstacle_policy/proc/try_airlock(mob/living/pawn, obj/machinery/door/airlock/door)
	if(!opens_doors || door.operating || door.welded || door.locked)
		return FALSE
	if(door.hasPower())
		if(door.allowed(pawn))
			INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, open))
			return TRUE
		if(!forces_powered_doors)
			return FALSE
	//обесточенная дверь или силовой взлом: unforced open() у шлюза без питания - no-op
	playsound(door, 'sound/machines/airlock_alien_prying.ogg', 100, TRUE)
	INVOKE_ASYNC(door, TYPE_PROC_REF(/obj/machinery/door, open), TRUE)
	return TRUE

///Выломать плотный объект (с учётом вайтлиста профиля)
/datum/obstacle_policy/proc/try_smash(mob/living/pawn, datum/ai_controller/controller, obj/blocker)
	if(!can_smash_blocker(pawn, controller, blocker))
		return FALSE
	//Атаки NPC по объектам не логировались нигде: цепочка attack_animal ->
	//attack_generic -> take_damage не зовёт log_combat, и единственный объект,
	//попадающий в лог, - мех с собственным оверрайдом. Из-за этого жалобы вида
	//"моб выломал дверь" были непроверяемы в принципе.
	log_combat(pawn, blocker, "smashed as a path obstacle")
	blocker.attack_animal(pawn)
	return TRUE

///Можно ли этому пауну ломать этот турф (стены по environment_smash моба)
/datum/obstacle_policy/proc/try_turf(mob/living/pawn, turf/blocked_turf)
	var/mob/living/simple_animal/hostile/hostile_pawn = pawn
	if(!can_smash_turf(hostile_pawn, blocked_turf))
		return FALSE
	log_combat(hostile_pawn, blocked_turf, "smashed as a path obstacle")
	blocked_turf.attack_animal(hostile_pawn)
	return TRUE

///Мирная политика: только двери, ничего не ломаем
/datum/obstacle_policy/doors_only
	smashes_structures = FALSE

/datum/obstacle_policy/doors_only/try_turf(mob/living/pawn, turf/blocked_turf)
	return FALSE

///Взломщик: форсит запитанные двери (терроры-крепыши, синдикат)
/datum/obstacle_policy/forceful
	forces_powered_doors = TRUE

///Разрушитель: не возится с дверями по доступу - просто ломает всё
/datum/obstacle_policy/breacher
	opens_doors = FALSE
	forces_powered_doors = FALSE

///A small weighted A* node. This pathfinder is a fallback only: ordinary JPS
///must first prove that no route without demolition exists.
/datum/ai_breach_node
	var/turf/tile
	var/datum/ai_breach_node/parent
	var/travel_cost
	var/steps
	var/f_score

/datum/ai_breach_node/New(turf/tile, datum/ai_breach_node/parent, travel_cost, steps, turf/goal)
	. = ..()
	src.tile = tile
	src.parent = parent
	src.travel_cost = travel_cost
	src.steps = steps
	f_score = travel_cost + abs(tile.x - goal.x) + abs(tile.y - goal.y)

/datum/ai_breach_node/Destroy(force, ...)
	parent = null
	tile = null
	return ..()

/proc/HeapAIBreachWeightCompare(datum/ai_breach_node/a, datum/ai_breach_node/b)
	return b.f_score - a.f_score

/datum/ai_breach_pathfinder
	var/mob/living/pawn
	var/datum/ai_controller/controller
	var/datum/obstacle_policy/policy
	var/turf/start
	var/turf/goal
	var/max_distance
	var/minimum_distance
	var/simulated_only
	var/turf/avoid
	/// Access and atmosphere policy are immutable snapshots for this search.
	var/obj/item/card/id/id
	var/check_environment = FALSE
	var/datum/cancel_source
	var/datum/heap/open
	var/list/best_cost

/datum/ai_breach_pathfinder/New(mob/living/pawn, datum/ai_controller/controller, datum/obstacle_policy/policy, turf/start, turf/goal, max_distance, minimum_distance, simulated_only, turf/avoid, obj/item/card/id/id, datum/cancel_source)
	. = ..()
	src.pawn = pawn
	src.controller = controller
	src.policy = policy
	src.start = start
	src.goal = goal
	src.max_distance = max_distance
	src.minimum_distance = minimum_distance
	src.simulated_only = simulated_only
	src.avoid = avoid
	src.id = id
	src.cancel_source = cancel_source
	var/mob/living/simple_animal/simple_pawn = pawn
	check_environment = istype(simple_pawn) && simple_pawn.requires_safe_atmosphere()
	open = new /datum/heap(/proc/HeapAIBreachWeightCompare)
	best_cost = list()

/datum/ai_breach_pathfinder/Destroy(force, ...)
	pawn = null
	controller = null
	policy = null
	start = null
	goal = null
	avoid = null
	id = null
	cancel_source = null
	// Nodes still queued in the heap are freed by its Destroy. Popped nodes are left to
	// GC through their broken parent chains, exactly like JPS jps_nodes - tracking and
	// qdel-ing every expanded node instead flooded SSgarbage (was the top breach cost).
	QDEL_NULL(open)
	best_cost = null
	return ..()

/datum/ai_breach_pathfinder/proc/search(skip_first = TRUE)
	if(!pawn || !controller || !start || !goal || start.z != goal.z || start == goal)
		return list()
	if(max_distance)
		// This fallback expands cardinal steps only. Chebyshev get_dist() lets
		// diagonally distant, mathematically impossible requests flood the heap.
		var/minimum_cardinal_steps = max(0, abs(start.x - goal.x) - minimum_distance) + max(0, abs(start.y - goal.y) - minimum_distance)
		if(max_distance < minimum_cardinal_steps)
			return list()

	var/datum/ai_breach_node/start_node = new(start, null, 0, 0, goal)
	open.insert(start_node)
	best_cost[start] = 0
	var/max_expansions = max_distance ? min(4096, max(128, max_distance * max_distance * 2)) : 2048
	var/expansions = 0

	while(!open.is_empty() && expansions < max_expansions)
		if(QDELETED(pawn) || QDELETED(controller) || (cancel_source && QDELETED(cancel_source)))
			return list()
		var/datum/ai_breach_node/current = open.pop()
		if(current.travel_cost > best_cost[current.tile])
			continue
		expansions++

		if(current.tile == goal || (minimum_distance && get_dist(current.tile, goal) <= minimum_distance))
			var/list/path = list()
			var/datum/ai_breach_node/unwind = current
			while(unwind && unwind.tile != start)
				path.Insert(1, unwind.tile)
				unwind = unwind.parent
			if(!skip_first)
				path.Insert(1, start)
			return path

		if(max_distance && current.steps >= max_distance)
			continue
		for(var/direction in GLOB.cardinals)
			var/turf/next_turf = get_step(current.tile, direction)
			var/step_cost = policy.get_breach_step_cost(pawn, controller, current.tile, next_turf, simulated_only, avoid, id, check_environment)
			if(!step_cost)
				continue
			var/new_cost = current.travel_cost + step_cost
			var/known_cost = best_cost[next_turf]
			if(!isnull(known_cost) && known_cost <= new_cost)
				continue
			best_cost[next_turf] = new_cost
			open.insert(new /datum/ai_breach_node(next_turf, current, new_cost, current.steps + 1, goal))
		CHECK_TICK

	return list()

///Hostile adapters use the policy-aware A* only when clean JPS returned no path.
/datum/ai_controller/hostile_adapter/get_path_through_obstacles(atom/target, max_distance, minimum_distance, obj/item/card/id/id, simulated_only, turf/avoid, skip_first, datum/cancel_source)
	var/turf/start_turf = get_turf(pawn)
	var/turf/goal_turf = get_turf(target)
	if(!start_turf || !goal_turf)
		return list()

	var/pathfinder_slot = SSpathfinder.mobs.getfree(pawn)
	while(!pathfinder_slot)
		stoplag(3)
		if(QDELETED(src) || QDELETED(pawn) || (cancel_source && QDELETED(cancel_source)))
			return list()
		pathfinder_slot = SSpathfinder.mobs.getfree(pawn)

	var/datum/obstacle_policy/policy = GET_OBSTACLE_POLICY(blackboard[BB_AI_OBSTACLE_POLICY] || /datum/obstacle_policy)
	var/datum/ai_breach_pathfinder/pathfinder = new(pawn, src, policy, start_turf, goal_turf, max_distance, minimum_distance, simulated_only, avoid, id, cancel_source)
	var/list/path = pathfinder.search(skip_first)
	qdel(pathfinder)
	SSpathfinder.mobs.found(pathfinder_slot)
	return path || list()
