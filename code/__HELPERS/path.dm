/**
 * This file contains the stuff you need for using JPS (Jump Point Search) pathing, an alternative to A* that skips
 * over large numbers of uninteresting tiles resulting in much quicker pathfinding solutions. Mind that diagonals
 * cost the same as cardinal moves currently, so paths may look a bit strange, but are optimal: the goal waits until no open node could beat it.
 */

/// Rate-limited warning for invalid path requests that would otherwise spam runtimes.
/proc/log_invalid_astar_request(atom/movable/path_owner, turf/start, turf/end)
	var/static/next_log_time = 0
	if(world.time < next_log_time)
		return
	next_log_time = world.time + (5 SECONDS)
	WARNING("Invalid A* start or destination (suppressed runtime): owner=[path_owner ? "[path_owner] ([path_owner.type])" : "null"], start=[start ? "[start] ([start.type])" : "null"], end=[end ? "[end] ([end.type])" : "null"]")

/**
 * This is the proc you use whenever you want to have pathfinding more complex than "try stepping towards the thing".
 * If no path was found, returns an empty list, which is important for bots like medibots who expect an empty list rather than nothing.
 *
 * Arguments:
 * * path_owner: The movable atom that's trying to find the path
 * * end: What we're trying to path to. It doesn't matter if this is a turf or some other atom, we're gonna just path to the turf it's on anyway
 * * max_distance: The maximum number of steps we can take in a given path to search (default: 30, 0 = infinite)
 * * mintargetdistance: Minimum distance to the target before path returns, could be used to get near a target, but not right to it - for an AI mob with a gun, for example.
 * * id: An ID card representing what access we have and what doors we can open. Its location relative to the pathing atom is irrelevant
 * * simulated_only: Whether we consider turfs without atmos simulation (AKA do we want to ignore space)
 * * exclude: If we want to avoid a specific turf, like if we're a mulebot who already got blocked by some turf
 * * skip_first: Whether or not to delete the first item in the path. This would be done because the first item is the starting tile, which can break movement for some creatures.
 * * search_status: Optional list filled with the search outcome; see [JPS_SEARCH_EXHAUSTED].
 */
/**
 * Bounds an AI pathfinding search radius to what a chase actually needs.
 *
 * JPS (and the breach fallback) explore the entire `max_path_length` diamond before
 * conceding that a target is unreachable. Because the expensive failed searches are for
 * targets that are close in a straight line but sealed off behind a wall, capping the
 * radius to their real distance plus a generous detour allowance ([AI_JPS_DETOUR_SLACK])
 * removes most of that wasted exploration without shrinking any reachable detour.
 *
 * Returns 0 (unbounded) when `max_path_length` is 0, preserving infinite-search callers.
 */
/proc/ai_effective_path_radius(atom/mover, atom/target, max_path_length)
	if(!max_path_length)
		return 0
	return min(max_path_length, get_dist(mover, target) + AI_JPS_DETOUR_SLACK)

/proc/get_path_to(atom/movable/path_owner, end, max_distance = 30, mintargetdist, id=null, simulated_only = TRUE, turf/exclude, skip_first=TRUE, datum/cancel_source, list/search_status)
	var/turf/start_turf = get_turf(path_owner)
	var/turf/end_turf = get_turf(end)
	if(!path_owner || !start_turf || !end_turf || (cancel_source && QDELETED(cancel_source)))
		return list()
	AI_METRIC_INC(jps_requests)

	var/datum/pathfinder_lease/l = SSpathfinder.mobs.getfree(path_owner)
	while(!l)
		stoplag(3)
		if(!path_owner || (cancel_source && QDELETED(cancel_source)))
			return list()
		l = SSpathfinder.mobs.getfree(path_owner)

	// Recheck after sleep — path owner may have been deleted or moved to nullspace
	start_turf = get_turf(path_owner)
	if(!path_owner || !start_turf || (cancel_source && QDELETED(cancel_source)))
		SSpathfinder.mobs.found(l)
		return list()

	var/list/path
	var/datum/pathfind/pathfind_datum = new(path_owner, start_turf, end_turf, id, max_distance, mintargetdist, simulated_only, exclude, cancel_source)
	l.search = pathfind_datum
	var/started_at = world.time
	path = pathfind_datum.search()
	AI_METRIC_INC(jps_searches)
	if(world.time != started_at && GLOB.ai_metrics)
		var/ticks_taken = round((world.time - started_at) / world.tick_lag)
		GLOB.ai_metrics.jps_search_ticks += ticks_taken
		GLOB.ai_metrics.jps_search_ticks_max = max(GLOB.ai_metrics.jps_search_ticks_max, ticks_taken)
	if(search_status)
		search_status[JPS_SEARCH_EXHAUSTED] = pathfind_datum.exhausted_search
	qdel(pathfind_datum)

	SSpathfinder.mobs.found(l)
	if(!path)
		path = list()
	if(length(path) > 0 && skip_first)
		path.Cut(1,2)
	return path

/// JPS forced neighbour of a lateral step: the diagonal ahead is reachable here but not from the side tile, which a wall or a railing can stop.
#define LATERAL_FORCED(cur_turf, side, forward_diagonal, heading) (!(can_step(cur_turf, get_step(cur_turf, side), side) && can_step(get_step(cur_turf, side), get_step(cur_turf, forward_diagonal), heading)) && can_step(cur_turf, get_step(cur_turf, forward_diagonal), forward_diagonal))
/// JPS forced neighbour of a diagonal step: the back tile and the diagonal past it are covered only if the subscan from lag_turf along parent_heading reaches them.
#define DIAGONAL_FORCED(lag_turf, cur_turf, back_side, forward_diagonal, parent_heading) (can_step(lag_turf, get_step(cur_turf, back_side), parent_heading) ? (!can_step(get_step(cur_turf, back_side), get_step(cur_turf, forward_diagonal), parent_heading) && can_step(cur_turf, get_step(cur_turf, forward_diagonal), forward_diagonal)) : (can_step(cur_turf, get_step(cur_turf, back_side), back_side) || can_step(cur_turf, get_step(cur_turf, forward_diagonal), forward_diagonal)))

// Direction values top out at SOUTHWEST (10), so the second eleven bits can
// hold the pass result alongside the first eleven checked bits.
#define JPS_EDGE_PASS_SHIFT 11

///Факты клетки уже собраны в этом поиске
#define JPS_TURF_KNOWN (1<<0)
///В клетке нет объекта, способного перекрыть ребро в неё или из неё
#define JPS_TURF_NO_BLOCKERS (1<<1)
///Атмосфера клетки не вредит путнику (или он к ней равнодушен)
#define JPS_TURF_SAFE (1<<2)
///Клетка вошла бы в путь без оговорок: между двумя такими соседями любое ребро открыто, проверки рёбер не нужны
#define JPS_TURF_CLEAR (1<<3)
#define JPS_CLEAR(T) (T && ((turf_facts[T] || get_turf_facts(T)) & JPS_TURF_CLEAR))
///Скан проверяет тик раз в столько шагов (маска), чтобы одно раскрытие узла не съедало тик целиком
#define JPS_YIELD_STEP_MASK 7
///Сколько % тика поиск работает с пробуждения, прежде чем уступить: при выбранном бюджете вне МК поиск без этого шёл по восемь клеток за тик
#define JPS_MIN_SLICE_USAGE 2

///Порядок сканов к цели, предел боковых сканов, быстрые открытые клетки и уступка тика внутри сканов; кратчайший путь. Бенч (--define=AI_HORDE_BENCH) переключает их на лету
#ifdef AI_HORDE_BENCH
#define JPS_SCAN_SAVINGS GLOB.jps_scan_savings
#define JPS_SHORTEST GLOB.jps_shortest
#define JPS_BENCH_CHECKPOINT GLOB.jps_bench_gap = max(GLOB.jps_bench_gap, TICK_USAGE - GLOB.jps_bench_last_check); GLOB.jps_bench_last_check = TICK_USAGE
#else
#define JPS_SCAN_SAVINGS TRUE
#define JPS_SHORTEST TRUE
#define JPS_BENCH_CHECKPOINT
#endif

/// The JPS Node datum represents a turf that we find interesting enough to add to the open list and possibly search for new tiles from
/datum/jps_node
	/// The turf associated with this node
	var/turf/tile
	/// The node we just came from
	var/datum/jps_node/previous_node
	/// The A* node weight (f_value = number_of_tiles + heuristic)
	var/f_value
	/// The A* node heuristic (a rough estimate of how far we are from the goal)
	var/heuristic
	/// How many steps it's taken to get here from the start (currently pulling double duty as steps taken & cost to get here, since all moves incl diagonals cost 1 rn)
	var/number_tiles
	/// How many steps it took to get here from the last node
	var/jumps
	/// Nodes store the endgoal so they can process their heuristic without a reference to the pathfind datum
	var/turf/node_goal

/datum/jps_node/New(turf/our_tile, datum/jps_node/incoming_previous_node, jumps_taken, turf/incoming_goal)
	tile = our_tile
	jumps = jumps_taken
	if(incoming_goal) // if we have the goal argument, this must be the first/starting node
		node_goal = incoming_goal
	else if(incoming_previous_node) // if we have the parent, this is from a direct lateral/diagonal scan, we can fill it all out now
		previous_node = incoming_previous_node
		number_tiles = previous_node.number_tiles + jumps
		node_goal = previous_node.node_goal
		heuristic = get_dist(tile, node_goal)
		f_value = number_tiles + heuristic
	// otherwise, no parent node means this is from a subscan lateral scan, so we just need the tile for now until we call [datum/jps/proc/update_parent] on it

/datum/jps_node/Destroy(force, ...)
	previous_node = null
	return ..()

/datum/jps_node/proc/update_parent(datum/jps_node/new_parent)
	previous_node = new_parent
	node_goal = previous_node.node_goal
	jumps = get_dist(tile, previous_node.tile)
	number_tiles = previous_node.number_tiles + jumps
	heuristic = get_dist(tile, node_goal)
	f_value = number_tiles + heuristic

///Меньший f первым, при равном - узел дальше от старта: он ближе к цели, и кратчайший путь находится раньше
/proc/HeapPathWeightCompare(datum/jps_node/a, datum/jps_node/b)
	. = b.f_value - a.f_value
	#ifdef AI_HORDE_BENCH
	if(!GLOB.jps_shortest)
		return
	#endif
	if(!.)
		. = a.number_tiles - b.number_tiles

/// The datum used to handle the JPS pathfinding, completely self-contained
/datum/pathfind
	/// The thing that we're actually trying to path for
	var/atom/movable/pathing_movable
	/// The turf where we started at
	var/turf/start
	/// The turf we're trying to path to (note that this won't track a moving target)
	var/turf/end
	/// The open list/stack we pop nodes out from (TODO: make this a normal list and macro-ize the heap operations to reduce proc overhead)
	var/datum/heap/open
	///An assoc list that serves as the closed list & tracks what turfs came from where. Key is the turf, and the value is what turf it came from
	var/alist/sources
	/// The list we compile at the end if successful to pass back
	var/list/path
	/// Per-search directed edge snapshot. One integer per source turf stores
	/// checked direction bits and passable direction bits.
	var/alist/edge_cache
	///Клетка -> биты JPS_TURF_*: объекты и атмосфера клетки читаются раз за поиск, а не на каждое из восьми рёбер
	var/alist/turf_facts
	/// Whether this path owner actually needs the expensive atmosphere checks.
	var/check_environment = FALSE
	/// Optional owner whose deletion cancels this otherwise synchronous search.
	var/datum/cancel_source
	/// TRUE only when the open list ran dry without a path: proof that no clean route
	/// exists inside max_distance. Early bail-outs and cancellations leave it FALSE.
	var/exhausted_search = FALSE
	///Поиск уснул посреди скана, а путник или владелец отмены за это время удалён
	var/aborted = FALSE
	///Сканы идут к цели первыми, боковые сканы обрезаны бюджетом длины, тик уступается внутри сканов
	var/scan_savings = FALSE
	///Сколько раз поиск уступил тик
	var/yields = 0
	///TICK_USAGE начала текущего куска работы и сколько % тика кусок держит при занятом тике
	var/slice_started = 0
	var/min_slice_usage = JPS_MIN_SLICE_USAGE
	///Путь берётся кратчайший: найденная цель ждёт, пока в куче не кончатся узлы, способные дать путь короче
	var/shortest = FALSE
	///Самый короткий из найденных узлов цели
	var/datum/jps_node/best_goal
	///Нижняя оценка пути через раскрываемый узел; у всех узлов кучи она не меньше
	var/expanding_bound = 0

	// general pathfinding vars/args
	/// An ID card representing what access we have and what doors we can open. Its location relative to the pathing atom is irrelevant
	var/obj/item/card/id/id
	/// How far away we have to get to the end target before we can call it quits
	var/mintargetdist = 0
	/// I don't know what this does vs , but they limit how far we can search before giving up on a path
	var/max_distance = 30
	/// Space is big and empty, if this is TRUE then we ignore pathing through unsimulated tiles
	var/simulated_only
	/// A specific turf we're avoiding, like if a mulebot is being blocked by someone t-posing in a doorway we're trying to get through
	var/turf/avoid

/datum/pathfind/New(atom/movable/path_owner, turf/start_turf, turf/goal_turf, id, max_distance, mintargetdist, simulated_only, avoid, datum/cancel_source)
	pathing_movable = path_owner
	start = start_turf
	end = goal_turf
	open = new /datum/heap(/proc/HeapPathWeightCompare)
	sources = AI_PATH_SAVINGS ? alist() : list()
	edge_cache = AI_PATH_SAVINGS ? alist() : list()
	turf_facts = alist()
	src.id = id
	src.max_distance = max_distance
	src.mintargetdist = mintargetdist
	src.simulated_only = simulated_only
	src.avoid = avoid
	src.cancel_source = cancel_source
	var/mob/living/simple_animal/pathing_animal = path_owner
	check_environment = istype(pathing_animal) && pathing_animal.requires_safe_atmosphere()
	scan_savings = JPS_SCAN_SAVINGS
	shortest = JPS_SHORTEST

/datum/pathfind/Destroy(force, ...)
	pathing_movable = null
	best_goal = null
	start = null
	end = null
	id = null
	avoid = null
	sources = null
	path = null
	edge_cache = null
	turf_facts = null
	cancel_source = null
	if(open)
		qdel(open)
		open = null
	return ..()

/// Cached equivalent of the link portion of CAN_STEP. JPS repeatedly probes
/// the same forced-neighbor edges, while path owner, access and environment policy
/// are immutable for one search. Movement still validates the returned path.
/datum/pathfind/proc/link_blocked(turf/from_turf, turf/to_turf, direction)
	var/direction_bit = 1 << direction
	var/cached_edges = edge_cache[from_turf]
	if(cached_edges & direction_bit)
		return !(cached_edges & (direction_bit << JPS_EDGE_PASS_SHIFT))

	var/blocked
	if(ISDIAGONALDIR(direction))
		var/vertical_direction = direction & (NORTH | SOUTH)
		var/horizontal_direction = direction & (EAST | WEST)
		var/turf/vertical_midpoint = get_step(from_turf, vertical_direction)
		var/turf/horizontal_midpoint = get_step(from_turf, horizontal_direction)
		// Match LinkBlockedWithAccess(): try the horizontal midpoint first and
		// avoid evaluating the second route when the first is clear.
		blocked = TRUE
		if(!horizontal_midpoint.density && !link_blocked(from_turf, horizontal_midpoint, horizontal_direction) && !link_blocked(horizontal_midpoint, to_turf, vertical_direction))
			blocked = FALSE
		else if(!vertical_midpoint.density && !link_blocked(from_turf, vertical_midpoint, vertical_direction) && !link_blocked(vertical_midpoint, to_turf, horizontal_direction))
			blocked = FALSE
	else if(!AI_PATH_SAVINGS || !turf_facts)
		blocked = from_turf.LinkBlockedWithAccess(to_turf, pathing_movable, id, check_environment, TRUE)
	else
		var/to_facts = get_turf_facts(to_turf)
		if(!(to_facts & JPS_TURF_SAFE))
			blocked = TRUE
		else if((to_facts & JPS_TURF_NO_BLOCKERS) && (get_turf_facts(from_turf) & JPS_TURF_NO_BLOCKERS))
			blocked = FALSE
		else
			blocked = from_turf.LinkBlockedWithAccess(to_turf, pathing_movable, id, check_environment, TRUE)

	// Recursive diagonal checks may have populated cardinal bits for this turf.
	cached_edges = edge_cache[from_turf]
	cached_edges |= direction_bit
	if(!blocked)
		cached_edges |= direction_bit << JPS_EDGE_PASS_SHIFT
	edge_cache[from_turf] = cached_edges
	return blocked

///То же, что прочитал бы LinkBlockedWithAccess() на клетке: пустая от помех клетка с безопасным воздухом ребро не перекрывает
/datum/pathfind/proc/get_turf_facts(turf/tile)
	. = turf_facts[tile]
	if(.)
		return
	. = JPS_TURF_KNOWN | JPS_TURF_NO_BLOCKERS
	var/mob/living/simple_animal/pathing_animal = pathing_movable
	if(!check_environment || pathing_animal.can_safely_enter_turf(tile, TRUE))
		. |= JPS_TURF_SAFE
	for(var/obj/thing in tile)
		if((thing.density || thing.can_astar_pass != CANASTARPASS_DENSITY) && !QDELETED(thing))
			. &= ~JPS_TURF_NO_BLOCKERS
			break
	if((. & (JPS_TURF_NO_BLOCKERS | JPS_TURF_SAFE)) == (JPS_TURF_NO_BLOCKERS | JPS_TURF_SAFE) && !tile.density && tile != avoid && !(simulated_only && SSpathfinder.space_type_cache[tile.type]))
		. |= JPS_TURF_CLEAR
	turf_facts[tile] = .

/// Hot JPS step predicate with cheap exclusions first and a per-search edge cache.
/datum/pathfind/proc/can_step(turf/from_turf, turf/to_turf, direction)
	#ifdef AI_HORDE_BENCH
	GLOB.jps_bench_can_steps++
	#endif
	return to_turf && !to_turf.density && to_turf != avoid && !(simulated_only && SSpathfinder.space_type_cache[to_turf.type]) && !link_blocked(from_turf, to_turf, direction)

/datum/pathfind/proc/search_cancelled()
	return !pathing_movable || QDELETED(pathing_movable) || (cancel_source && QDELETED(cancel_source))

///Уступить тик; после сна поиск продолжается с того же шага, если путник ещё жив. TRUE - поиск надо бросить
/datum/pathfind/proc/yield_search()
	yields++
	AI_METRIC_INC(jps_yields)
	#ifdef AI_HORDE_BENCH
	GLOB.jps_bench_slice_max = max(GLOB.jps_bench_slice_max, TICK_USAGE - slice_started)
	#endif
	stoplag()
	slice_started = TICK_USAGE
	#ifdef AI_HORDE_BENCH
	GLOB.jps_bench_last_check = TICK_USAGE
	#endif
	if(search_cancelled())
		aborted = TRUE
	return aborted

///Кусок с пробуждения отработан, или тик занят так, что ждать нельзя
/datum/pathfind/proc/slice_spent()
	return TICK_USAGE - slice_started >= min_slice_usage || TICK_USAGE > TICK_LIMIT_TO_RUN

///Восемь направлений сканов, ближайшие к цели первыми: найденный путь обрывает раскрытие узла, и сканы в сторону от цели обычно не нужны
/proc/jps_scan_order(goal_dir)
	var/static/list/orders
	if(!orders)
		orders = new /list(SOUTHWEST + 1)
		//без направления к цели - прежний порядок
		orders[1] = list(EAST, WEST, NORTH, SOUTH, NORTHEAST, SOUTHEAST, NORTHWEST, SOUTHWEST)
		for(var/direction in GLOB.cardinals)
			var/list/side = (direction & (NORTH | SOUTH)) ? list(EAST, WEST) : list(NORTH, SOUTH)
			var/back = REVERSE_DIR(direction)
			orders[direction + 1] = list(direction, direction | side[1], direction | side[2], side[1], side[2], back | side[1], back | side[2], back)
		for(var/direction in GLOB.diagonals)
			var/vertical = direction & (NORTH | SOUTH)
			var/horizontal = direction & (EAST | WEST)
			var/flip_vertical = REVERSE_DIR(vertical)
			var/flip_horizontal = REVERSE_DIR(horizontal)
			orders[direction + 1] = list(direction, vertical, horizontal, vertical | flip_horizontal, flip_vertical | horizontal, flip_horizontal, flip_vertical, flip_vertical | flip_horizontal)
	return orders[goal_dir + 1]

/**
 * search() is the proc you call to kick off and handle the actual pathfinding, and kills the pathfind datum instance when it's done.
 *
 * If a valid path was found, it's returned as a list. If invalid or cross-z-level params are entered, or if there's no valid path found, we
 * return null, which [/proc/get_path_to] translates to an empty list (notable for simple bots, who need empty lists)
 */
/datum/pathfind/proc/search()
	if(!start || !end)
		return
	if(start.z != end.z || start == end ) //no pathfinding between z levels
		return
	if(max_distance && (max_distance < get_dist(start, end))) //if start turf is farther than max_distance from end turf, no need to do anything
		return

	//initialization
	var/datum/jps_node/current_processed_node = new (start, -1, 0, end)
	current_processed_node.number_tiles = 0
	current_processed_node.heuristic = get_dist(start, end)
	current_processed_node.f_value = current_processed_node.heuristic
	open.insert(current_processed_node)
	sources[start] = 0
	slice_started = TICK_USAGE
	#ifdef UNIT_TESTS
	var/test_checkpoint_sent = FALSE
	#endif

	//then run the main loop
	while(!open.is_empty() && !path)
		if(aborted || search_cancelled())
			aborted = TRUE
			break
		current_processed_node = open.pop() //get the lower f_value turf in the open list
		if(max_distance && (current_processed_node.number_tiles > max_distance))//if too many steps, don't process that path
			continue
		//узел устарел: его клетку потом прошёл скан ближе к старту
		if(shortest && sources[current_processed_node.tile] < current_processed_node.number_tiles)
			continue
		expanding_bound = node_bound(current_processed_node)
		if(best_goal && best_goal.number_tiles <= expanding_bound)
			unwind_path(best_goal)
			break

		var/turf/current_turf = current_processed_node.tile
		for(var/heading in jps_scan_order(scan_savings ? get_dir(current_turf, end) : 0))
			if(ISDIAGONALDIR(heading))
				diag_scan_spec(current_turf, heading, current_processed_node)
			else
				lateral_scan_spec(current_turf, heading, current_processed_node)
			if(path || aborted)
				break

		JPS_BENCH_CHECKPOINT
		if(!aborted && TICK_CHECK && slice_spent())
			yield_search()
		#ifdef UNIT_TESTS
		if(!test_checkpoint_sent)
			test_checkpoint_sent = TRUE
			SEND_SIGNAL(pathing_movable, COMSIG_TEST_PATHFIND_AFTER_FIRST_TICK, src)
		#endif

	if(!path && !aborted && best_goal)
		unwind_path(best_goal)
	best_goal = null
	//we're done! reverse the path to get it from start to finish
	if(aborted)
		AI_METRIC_INC(jps_aborted)
		path = null
	else if(path)
		for(var/i = 1 to round(0.5 * length(path)))
			path.Swap(i, length(path) - i + 1)
	else
		exhausted_search = TRUE

	sources = null
	if(open)
		qdel(open)
		open = null
	return path

///Сколько шагов пути через узел нельзя избежать: пройденное плюс расстояние до края зоны цели, и хотя бы шаг со старта, даже если он уже в зоне
/datum/pathfind/proc/node_bound(datum/jps_node/node)
	return max(1, node.number_tiles + max(0, node.heuristic - mintargetdist))

///Скан дошёл до цели. Путь готов сразу, если он не длиннее нижней оценки раскрываемого узла: короче через кучу не выйдет
/datum/pathfind/proc/found_goal(datum/jps_node/goal_node)
	if(!shortest)
		unwind_path(goal_node)
		return
	if(!best_goal || goal_node.number_tiles < best_goal.number_tiles)
		best_goal = goal_node
	if(best_goal.number_tiles <= expanding_bound)
		unwind_path(best_goal)

/// Called when we've hit the goal with the node that represents the last tile, then sets the path var to that path so it can be returned by [datum/pathfind/proc/search]
/datum/pathfind/proc/unwind_path(datum/jps_node/unwind_node)
	path = new()
	var/turf/iter_turf = unwind_node.tile
	path.Add(iter_turf)

	while(unwind_node.previous_node)
		var/dir_goal = get_dir(iter_turf, unwind_node.previous_node.tile)
		for(var/i = 1 to unwind_node.jumps)
			iter_turf = get_step(iter_turf,dir_goal)
			path.Add(iter_turf)
		unwind_node = unwind_node.previous_node

/**
 * For performing lateral scans from a given starting turf.
 *
 * These scans are called from both the main search loop, as well as subscans for diagonal scans, and they treat finding interesting turfs slightly differently.
 * If we're doing a normal lateral scan, we already have a parent node supplied, so we just create the new node and immediately insert it into the heap, ezpz.
 * If we're part of a subscan, we still need for the diagonal scan to generate a parent node, so we return a node datum with just the turf and let the diag scan
 * proc handle transferring the values and inserting them into the heap.
 *
 * Arguments:
 * * original_turf: What turf did we start this scan at?
 * * heading: What direction are we going in? Obviously, should be cardinal
 * * parent_node: Only given for normal lateral scans, if we don't have one, we're a diagonal subscan.
 * * step_budget: Subscans only: how many steps are left before the path would outgrow max_distance. Null means unbounded.
 * * subscan_steps: Subscans only: steps from the start to original_turf.
*/
/datum/pathfind/proc/lateral_scan_spec(turf/original_turf, heading, datum/jps_node/parent_node, step_budget, subscan_steps)
	var/steps_taken = 0
	var/start_steps = parent_node ? parent_node.number_tiles : subscan_steps

	var/turf/current_turf = original_turf
	var/turf/lag_turf = original_turf
	var/blocked_side_a
	var/forced_diagonal_a
	var/blocked_side_b
	var/forced_diagonal_b
	switch(heading)
		if(NORTH)
			blocked_side_a = WEST
			forced_diagonal_a = NORTHWEST
			blocked_side_b = EAST
			forced_diagonal_b = NORTHEAST
		if(SOUTH)
			blocked_side_a = WEST
			forced_diagonal_a = SOUTHWEST
			blocked_side_b = EAST
			forced_diagonal_b = SOUTHEAST
		if(EAST)
			blocked_side_a = NORTH
			forced_diagonal_a = NORTHEAST
			blocked_side_b = SOUTH
			forced_diagonal_b = SOUTHEAST
		if(WEST)
			blocked_side_a = NORTH
			forced_diagonal_a = NORTHWEST
			blocked_side_b = SOUTH
			forced_diagonal_b = SOUTHWEST

	if(path || aborted)
		return
	var/fast = scan_savings
	while(TRUE)
		lag_turf = current_turf
		current_turf = get_step(current_turf, heading)
		steps_taken++
		//две чистые клетки подряд: ребро между ними открыто без проверки
		var/open_step = fast && JPS_CLEAR(current_turf) && JPS_CLEAR(lag_turf)
		if(!open_step && !can_step(lag_turf, current_turf, heading))
			return

		var/steps_here = start_steps + steps_taken
		if(current_turf == end || (mintargetdist && (get_dist(current_turf, end) <= mintargetdist)))
			var/datum/jps_node/final_node = new(current_turf, parent_node, steps_taken)
			sources[current_turf] = steps_here
			if(parent_node) // if this is a direct lateral scan we can wrap up, if it's a subscan from a diag, we need to let the diag make their node first, then finish
				found_goal(final_node)
			return final_node
		var/known_steps = sources[current_turf]
		if(!isnull(known_steps) && (!shortest || known_steps <= steps_here)) //клетку уже прошёл скан не дальше от старта
			return
		sources[current_turf] = steps_here

		if(parent_node && max_distance && parent_node.number_tiles + steps_taken > max_distance)
			return
		if(!isnull(step_budget) && steps_taken > step_budget)
			return

		//вынужденного соседа нет, если обе стороны и обе диагонали впереди чистые
		var/sides_open = FALSE
		if(open_step)
			var/turf/probe = get_step(current_turf, blocked_side_a)
			if(JPS_CLEAR(probe))
				probe = get_step(current_turf, forced_diagonal_a)
				if(JPS_CLEAR(probe))
					probe = get_step(current_turf, blocked_side_b)
					if(JPS_CLEAR(probe))
						probe = get_step(current_turf, forced_diagonal_b)
						sides_open = JPS_CLEAR(probe)
		if(!sides_open && (LATERAL_FORCED(current_turf, blocked_side_a, forced_diagonal_a, heading) || LATERAL_FORCED(current_turf, blocked_side_b, forced_diagonal_b, heading)))
			var/datum/jps_node/newnode = new(current_turf, parent_node, steps_taken)
			if(parent_node) // if we're a diagonal subscan, we'll handle adding ourselves to the heap in the diag
				open.insert(newnode)
			return newnode

		if(fast && !(steps_taken & JPS_YIELD_STEP_MASK))
			JPS_BENCH_CHECKPOINT
			if(TICK_CHECK && slice_spent() && yield_search())
				return

/**
 * For performing diagonal scans from a given starting turf.
 *
 * Unlike lateral scans, these only are called from the main search loop, so we don't need to worry about returning anything,
 * though we do need to handle the return values of our lateral subscans of course.
 *
 * Arguments:
 * * original_turf: What turf did we start this scan at?
 * * heading: What direction are we going in? Obviously, should be diagonal
 * * parent_node: We should always have a parent node for diagonals
*/
/datum/pathfind/proc/diag_scan_spec(turf/original_turf, heading, datum/jps_node/parent_node)
	var/steps_taken = 0
	var/turf/current_turf = original_turf
	var/turf/lag_turf = original_turf
	var/blocked_side_a
	var/forced_diagonal_a
	var/blocked_side_b
	var/forced_diagonal_b
	var/lateral_heading_a
	var/lateral_heading_b
	switch(heading)
		if(NORTHWEST)
			blocked_side_a = EAST
			forced_diagonal_a = NORTHEAST
			blocked_side_b = SOUTH
			forced_diagonal_b = SOUTHWEST
			lateral_heading_a = WEST
			lateral_heading_b = NORTH
		if(NORTHEAST)
			blocked_side_a = WEST
			forced_diagonal_a = NORTHWEST
			blocked_side_b = SOUTH
			forced_diagonal_b = SOUTHEAST
			lateral_heading_a = EAST
			lateral_heading_b = NORTH
		if(SOUTHWEST)
			blocked_side_a = EAST
			forced_diagonal_a = SOUTHEAST
			blocked_side_b = NORTH
			forced_diagonal_b = NORTHWEST
			lateral_heading_a = SOUTH
			lateral_heading_b = WEST
		if(SOUTHEAST)
			blocked_side_a = WEST
			forced_diagonal_a = SOUTHWEST
			blocked_side_b = NORTH
			forced_diagonal_b = NORTHEAST
			lateral_heading_a = SOUTH
			lateral_heading_b = EAST
	var/vertical_heading = heading & (NORTH|SOUTH)
	var/horizontal_heading = heading & (EAST|WEST)

	if(path || aborted)
		return
	var/fast = scan_savings
	while(TRUE)
		lag_turf = current_turf
		current_turf = get_step(current_turf, heading)
		steps_taken++
		//стороны шага - это и середины диагонального ребра, и задние клетки проверки вынужденных соседей
		var/turf/side_a
		var/turf/side_b
		var/side_a_clear = FALSE
		var/side_b_clear = FALSE
		var/open_step = FALSE
		if(fast && JPS_CLEAR(current_turf) && JPS_CLEAR(lag_turf))
			side_a = get_step(current_turf, blocked_side_a)
			side_b = get_step(current_turf, blocked_side_b)
			side_a_clear = JPS_CLEAR(side_a)
			side_b_clear = JPS_CLEAR(side_b)
			open_step = side_a_clear || side_b_clear
		if(!open_step && !can_step(lag_turf, current_turf, heading))
			return

		var/steps_here = parent_node.number_tiles + steps_taken
		if(current_turf == end || (mintargetdist && (get_dist(current_turf, end) <= mintargetdist)))
			var/datum/jps_node/final_node = new(current_turf, parent_node, steps_taken)
			sources[current_turf] = steps_here
			found_goal(final_node)
			return
		var/known_steps = sources[current_turf]
		if(!isnull(known_steps) && (!shortest || known_steps <= steps_here)) //клетку уже прошёл скан не дальше от старта
			return
		sources[current_turf] = steps_here

		if(max_distance && parent_node.number_tiles + steps_taken > max_distance)
			return

		var/interesting
		if(side_a_clear && side_b_clear)
			var/turf/probe = get_step(current_turf, forced_diagonal_a)
			if(JPS_CLEAR(probe))
				probe = get_step(current_turf, forced_diagonal_b)
				if(JPS_CLEAR(probe))
					interesting = FALSE
		if(isnull(interesting))
			interesting = DIAGONAL_FORCED(lag_turf, current_turf, blocked_side_a, forced_diagonal_a, vertical_heading) || DIAGONAL_FORCED(lag_turf, current_turf, blocked_side_b, forced_diagonal_b, horizontal_heading)
		var/datum/jps_node/possible_child_node // otherwise, did one of our lateral subscans turn up something?
		if(!interesting)
			var/subscan_budget = (fast && max_distance) ? max_distance - parent_node.number_tiles - steps_taken : null
			possible_child_node = lateral_scan_spec(current_turf, lateral_heading_a, null, subscan_budget, steps_here) || lateral_scan_spec(current_turf, lateral_heading_b, null, subscan_budget, steps_here)
			if(aborted)
				return

		if(interesting || possible_child_node)
			var/datum/jps_node/newnode = new(current_turf, parent_node, steps_taken)
			open.insert(newnode)
			if(possible_child_node)
				possible_child_node.update_parent(newnode)
				open.insert(possible_child_node)
				if(possible_child_node.tile == end || (mintargetdist && (get_dist(possible_child_node.tile, end) <= mintargetdist)))
					found_goal(possible_child_node)
			return

		if(fast)
			JPS_BENCH_CHECKPOINT
			if(TICK_CHECK && slice_spent() && yield_search())
				return

/**
 * For seeing if we can actually move between 2 given turfs while accounting for our access and the caller's pass_flags
 *
 * Arguments:
 * * caller: The movable, if one exists, being used for mobility checks to see what tiles it can reach
 * * ID: An ID card that decides if we can gain access to doors that would otherwise block a turf
 * * check_environment: Whether simple-animal atmosphere and pressure-barrier safety gates apply.
 * * environment_policy_prechecked: Whether check_environment was resolved for this path owner already.
 */
/turf/proc/LinkBlockedWithAccess(turf/destination_turf, atom/movable/pathing_movable, ID, check_environment = TRUE, environment_policy_prechecked = FALSE)
	if(!destination_turf)
		return TRUE
	var/mob/living/simple_animal/pathing_animal = pathing_movable
	if(check_environment && !environment_policy_prechecked)
		check_environment = istype(pathing_animal) && pathing_animal.requires_safe_atmosphere()
	if(check_environment && !pathing_animal.can_safely_enter_turf(destination_turf, TRUE))
		return TRUE

	if(destination_turf.x != x && destination_turf.y != y) //diagonal
		var/in_dir = get_dir(destination_turf,src) // eg. northwest (1+8) = 9 (00001001)
		var/first_step_direction_a = in_dir & 3 // eg. north   (1+8)&3 (0000 0011) = 1 (0000 0001)
		var/first_step_direction_b = in_dir & 12 // eg. west   (1+8)&12 (0000 1100) = 8 (0000 1000)

		var/turf/midstep_turf = get_step(destination_turf, first_step_direction_a)
		if(!midstep_turf.density && !LinkBlockedWithAccess(midstep_turf, pathing_movable, ID, check_environment, TRUE) && !midstep_turf.LinkBlockedWithAccess(destination_turf, pathing_movable, ID, check_environment, TRUE))
			return FALSE
		midstep_turf = get_step(destination_turf, first_step_direction_b)
		if(!midstep_turf.density && !LinkBlockedWithAccess(midstep_turf, pathing_movable, ID, check_environment, TRUE) && !midstep_turf.LinkBlockedWithAccess(destination_turf, pathing_movable, ID, check_environment, TRUE))
			return FALSE
		return TRUE

	var/actual_dir = get_dir(src, destination_turf)

	var/static/list/directional_blocker_cache = typecacheof(list(
		/obj/structure/window,
		/obj/machinery/door/window,
		/obj/structure/railing,
		/obj/machinery/door/firedoor/border_only,
	))
	// Source border object checks. One contents walk is substantially cheaper
	// than four typed walks on every edge.
	for(var/obj/border in src)
		if(QDELETED(border))
			continue
		if(!border.density && border.can_astar_pass == CANASTARPASS_DENSITY)
			continue
		if(!directional_blocker_cache[border.type])
			continue
		if(check_environment && ai_pressure_barrier_blocks_step(border, src, destination_turf) && !pathing_animal.can_safely_open_pressure_barrier(border))
			return TRUE
		if(!border.CanAStarPass(ID, actual_dir))
			return TRUE

	// Destination blockers check
	var/reverse_dir = get_dir(destination_turf, src)
	for(var/obj/iter_object in destination_turf)
		if(QDELETED(iter_object))
			continue
		if(!iter_object.density && iter_object.can_astar_pass == CANASTARPASS_DENSITY)
			continue
		if(check_environment && ai_pressure_barrier_blocks_step(iter_object, src, destination_turf) && !pathing_animal.can_safely_open_pressure_barrier(iter_object))
			return TRUE
		if(!iter_object.CanAStarPass(ID, reverse_dir, pathing_movable))
			return TRUE

	return FALSE

#undef LATERAL_FORCED
#undef DIAGONAL_FORCED
#undef JPS_EDGE_PASS_SHIFT
#undef JPS_TURF_KNOWN
#undef JPS_TURF_NO_BLOCKERS
#undef JPS_TURF_SAFE
#undef JPS_TURF_CLEAR
#undef JPS_CLEAR
#undef JPS_YIELD_STEP_MASK
#undef JPS_MIN_SLICE_USAGE
#undef JPS_SCAN_SAVINGS
#undef JPS_SHORTEST
#undef JPS_BENCH_CHECKPOINT
