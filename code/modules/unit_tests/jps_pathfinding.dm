// ===== Поиск пути JPS: правильные пути и уступка тика внутри сканов =====

#define JPS_TEST_ARENA_SIZE 40
#define JPS_TEST_SEED 1114
///Предел тика ниже нуля: любая проверка тика в поиске уступает
#define JPS_TEST_FORCE_YIELD -1

///Зал-полигон для поиска пути: стены по краю, планировка по имени, путник-предмет без своего ИИ
/datum/unit_test/jps_arena
	var/datum/turf_reservation/arena
	var/arena_size = JPS_TEST_ARENA_SIZE
	var/list/clutter = list()

/datum/unit_test/jps_arena/Run()
	return

/datum/unit_test/jps_arena/Destroy()
	QDEL_LIST(clutter)
	QDEL_NULL(arena)
	return ..()

/datum/unit_test/jps_arena/proc/arena_turf(x, y)
	return locate(arena.bottom_left_coords[1] + x - 1, arena.bottom_left_coords[2] + y - 1, arena.bottom_left_coords[3])

///open - пустой зал, на каждой клетке предмет; station - сетка комнат 14x14 с проходами, столами, окнами и перилами
/datum/unit_test/jps_arena/proc/build_arena(layout)
	if(!arena)
		arena = SSmapping.RequestBlockReservation(arena_size, arena_size)
	QDEL_LIST(clutter)
	rand_seed(JPS_TEST_SEED)
	for(var/x in 1 to arena_size)
		for(var/y in 1 to arena_size)
			var/turf/tile = arena_turf(x, y)
			var/wall = x == 1 || y == 1 || x == arena_size || y == arena_size
			if(!wall && layout == "station")
				wall = (!(x % 15) && (y % 15) != 7 && (y % 15) != 8) || (!(y % 15) && (x % 15) != 7 && (x % 15) != 8)
			tile.ChangeTurf(wall ? /turf/closed/indestructible/wall : /turf/open/indestructible/boss/air)
			if(wall)
				continue
			clutter += new /obj/item/paper(tile)
			if(layout != "station" || !(x % 15) || !(y % 15))
				continue
			//сквозные дорожки через проходы остаются пустыми
			if(((x % 15) >= 6 && (x % 15) <= 9) || ((y % 15) >= 6 && (y % 15) <= 9))
				continue
			if(prob(8))
				clutter += new /obj/structure/table(tile)
			else if(prob(6))
				var/obj/structure/window/pane = new(tile)
				pane.setDir(pick(GLOB.cardinals))
				clutter += pane
			else if(prob(5))
				var/obj/structure/railing/rail = new(tile)
				rail.setDir(pick(GLOB.cardinals))
				clutter += rail
			else if(prob(4))
				clutter += new /obj/structure/chair(tile)

///Свободные клетки зала, кроме края
/datum/unit_test/jps_arena/proc/open_tiles()
	. = list()
	for(var/x in 2 to arena_size - 1)
		for(var/y in 2 to arena_size - 1)
			var/turf/tile = arena_turf(x, y)
			if(!tile.density && !(locate(/obj/structure) in tile))
				. += tile

///Кратчайшее число шагов поиском в ширину по тем же рёбрам, что видит JPS; null - не дойти за max_distance
/datum/unit_test/jps_arena/proc/reference_length(atom/movable/walker, turf/start, turf/goal, max_distance)
	var/datum/pathfind/edges = new(walker, start, goal, null, max_distance, 0, TRUE, null)
	var/alist/depth = alist()
	depth[start] = 0
	var/list/frontier = list(start)
	var/steps = 0
	while(length(frontier) && (!max_distance || steps < max_distance))
		steps++
		var/list/next_frontier = list()
		for(var/turf/from_turf as anything in frontier)
			for(var/direction in GLOB.alldirs)
				var/turf/to_turf = get_step(from_turf, direction)
				if(!to_turf || !isnull(depth[to_turf]) || !edges.can_step(from_turf, to_turf, direction))
					continue
				if(to_turf == goal)
					qdel(edges)
					return steps
				depth[to_turf] = steps
				next_frontier += to_turf
		frontier = next_frontier
	qdel(edges)
	return null

///Путь идёт по соседним клеткам через открытые рёбра от старта до цели
/datum/unit_test/jps_arena/proc/path_problem(atom/movable/walker, turf/start, turf/goal, list/path)
	var/datum/pathfind/edges = new(walker, start, goal, null, 0, 0, TRUE, null)
	if(path[1] != start)
		qdel(edges)
		return "путь начинается не со старта"
	var/turf/previous = start
	for(var/index in 2 to length(path))
		var/turf/step = path[index]
		var/direction = get_dir(previous, step)
		if(get_dist(previous, step) != 1 || !edges.can_step(previous, step, direction))
			qdel(edges)
			return "шаг [previous.x],[previous.y] -> [step.x],[step.y] не открыт"
		previous = step
	qdel(edges)
	if(previous != goal)
		return "путь кончился на [previous.x],[previous.y], а не в цели"

///На каждой паре клеток JPS находит путь тогда же, когда его находит поиск в ширину, и путь годный; длиннее кратчайшего он бывает лишь на пару шагов (JPS обрывается на первом найденном пути)
/datum/unit_test/jps_paths_match_reference
	parent_type = /datum/unit_test/jps_arena

/datum/unit_test/jps_paths_match_reference/Run()
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar)
	for(var/layout in list("open", "station"))
		build_arena(layout)
		var/list/tiles = open_tiles()
		rand_seed(JPS_TEST_SEED + 1)
		var/excess_total = 0
		for(var/pair in 1 to 40)
			var/turf/start = pick(tiles)
			var/turf/goal = pick(tiles)
			if(start == goal)
				continue
			var/max_distance = pair % 2 ? get_dist(start, goal) + AI_JPS_DETOUR_SLACK : 120
			walker.forceMove(start)
			//JPS дотягивается и на шаг сверх бюджета: такие пары ничего не доказывают
			var/shortest = reference_length(walker, start, goal, max_distance + 1)
			if(shortest == max_distance + 1)
				continue
			var/datum/pathfind/finder = new(walker, start, goal, null, max_distance, 0, TRUE, null)
			var/list/path = finder.search()
			qdel(finder)
			var/where = "[layout] [start.x],[start.y] -> [goal.x],[goal.y], бюджет [max_distance]"
			if(isnull(shortest))
				TEST_ASSERT(!length(path), "JPS нашёл путь там, где его нет: [where]")
				continue
			TEST_ASSERT(length(path), "JPS не нашёл путь длиной [shortest]: [where]")
			var/problem = path_problem(walker, start, goal, path)
			TEST_ASSERT(!problem, "Негодный путь, [problem]: [where]")
			//в пути есть и стартовая клетка
			var/steps = length(path) - 1
			TEST_ASSERT(steps <= shortest + 2, "Путь в [steps] шагов при кратчайшем [shortest]: [where]")
			excess_total += steps - shortest
		TEST_ASSERT(excess_total <= 10, "[layout]: пути JPS в сумме на [excess_total] шагов длиннее кратчайших")

///Длинный скан по пустому залу уступает тик, не дожидаясь конца раскрытия узла, и после сна продолжает ровно с того же места: путь тот же, что без сна
/datum/unit_test/jps_scan_yields_mid_expansion
	parent_type = /datum/unit_test/jps_arena
	var/list/async_result
	var/async_done = FALSE

/datum/unit_test/jps_scan_yields_mid_expansion/proc/run_search(datum/pathfind/finder)
	async_result = finder.search()
	async_done = TRUE

/datum/unit_test/jps_scan_yields_mid_expansion/Run()
	build_arena("open")
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar)
	var/turf/start = arena_turf(3, 3)
	var/turf/goal = arena_turf(arena_size - 6, arena_size - 2)
	walker.forceMove(start)
	var/datum/pathfind/finder = new(walker, start, goal, null, 0, 0, TRUE, null)
	var/previous_ticklimit = Master.current_ticklimit
	Master.current_ticklimit = JPS_TEST_FORCE_YIELD
	INVOKE_ASYNC(src, PROC_REF(run_search), finder)
	Master.current_ticklimit = previous_ticklimit
	TEST_ASSERT(!async_done && !finder.path, "Поиск дошёл до цели, ни разу не уступив тик внутри скана")
	TEST_ASSERT(length(finder.sources) < 100, "До первой уступки тика поиск обошёл [length(finder.sources)] клеток одним куском")
	var/waited = 0
	while(!async_done && waited < 30 SECONDS)
		sleep(1)
		waited++
	TEST_ASSERT(async_done, "Поиск не закончился после сна")
	qdel(finder)

	var/datum/pathfind/control = new(walker, start, goal, null, 0, 0, TRUE, null)
	var/list/control_path = control.search()
	qdel(control)
	TEST_ASSERT(length(control_path), "Sanity: в пустом зале путь есть")
	TEST_ASSERT_EQUAL(length(async_result), length(control_path), "Поиск со сном дал путь другой длины")
	for(var/index in 1 to length(control_path))
		TEST_ASSERT(async_result[index] == control_path[index], "Поиск со сном разошёлся с обычным на шаге [index]")

///Владелец поиска удалён, пока поиск спал посреди скана: поиск бросается без пути и не объявляет цель недостижимой (иначе ИИ полез бы ломать стены зря)
/datum/unit_test/jps_scan_cancelled_mid_expansion
	parent_type = /datum/unit_test/jps_scan_yields_mid_expansion

/datum/unit_test/jps_scan_cancelled_mid_expansion/Run()
	build_arena("open")
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar)
	var/obj/item/wrench/owner = allocate(/obj/item/wrench)
	var/turf/start = arena_turf(3, 3)
	var/turf/goal = arena_turf(arena_size - 6, arena_size - 2)
	walker.forceMove(start)
	var/datum/pathfind/finder = new(walker, start, goal, null, 0, 0, TRUE, null, owner)
	var/previous_ticklimit = Master.current_ticklimit
	Master.current_ticklimit = JPS_TEST_FORCE_YIELD
	INVOKE_ASYNC(src, TYPE_PROC_REF(/datum/unit_test/jps_scan_yields_mid_expansion, run_search), finder)
	Master.current_ticklimit = previous_ticklimit
	TEST_ASSERT(!async_done && !finder.path, "Поиск дошёл до цели, ни разу не уступив тик внутри скана")
	allocated -= owner
	qdel(owner)
	var/waited = 0
	while(!async_done && waited < 30 SECONDS)
		sleep(1)
		waited++
	TEST_ASSERT(async_done, "Отменённый поиск не вернулся")
	TEST_ASSERT(!length(async_result), "Отменённый поиск вернул путь")
	TEST_ASSERT(!finder.exhausted_search, "Отменённый поиск объявил цель недостижимой")
	qdel(finder)

#ifdef AI_HORDE_BENCH

GLOBAL_VAR_INIT(jps_scan_savings, TRUE)
GLOBAL_VAR_INIT(jps_bench_can_steps, 0)
GLOBAL_VAR_INIT(jps_bench_gap, 0)
GLOBAL_VAR_INIT(jps_bench_last_check, 0)

///Цена одного поиска со старыми и новыми сканами в одном мире: мс, вызовы can_step, самый длинный кусок без проверки тика, длина пути против кратчайшего
/datum/unit_test/jps_path_bench
	parent_type = /datum/unit_test/jps_arena
	priority = TEST_LONGER
	arena_size = 60

/datum/unit_test/jps_path_bench/Run()
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar)
	//open - зал орды; corridors - коридоры шириной 3 как в бенче драки; station - комнаты и долгие пути ботов
	for(var/layout in list("open", "corridors", "station"))
		build_bench_arena(layout)
		var/list/tiles = open_tiles()
		rand_seed(JPS_TEST_SEED + 2)
		var/list/pairs = list()
		while(length(pairs) < 60)
			var/turf/start = pick(tiles)
			var/turf/goal = pick(tiles)
			var/distance = get_dist(start, goal)
			if(layout == "station" ? distance < 30 : (distance < 4 || distance > 25))
				continue
			pairs += list(list(start, goal, layout == "station" ? 120 : distance + AI_JPS_DETOUR_SLACK))
		var/list/stats = list("old" = list(), "new" = list())
		for(var/index in 1 to length(pairs))
			var/list/pair = pairs[index]
			var/shortest = reference_length(walker, pair[1], pair[2], pair[3])
			//ABBA по парам гасит дрейф чужой нагрузки
			var/list/order = (index % 4 < 2) ? list("old", "new") : list("new", "old")
			for(var/mode in order)
				measure(walker, pair, shortest, stats[mode], mode == "new")
			if(!(index % 10))
				sleep(1)
		GLOB.jps_scan_savings = TRUE
		for(var/mode in stats)
			var/list/mode_stats = stats[mode]
			log_world("JPS BENCH [layout] [mode]: [length(pairs)] searches | ms avg [round(mode_stats["ms"] / length(pairs), 0.01)] max [round(mode_stats["ms_max"], 0.01)] | can_step avg [round(mode_stats["can_step"] / length(pairs))] | worst slice without tick check [round(mode_stats["gap_max"], 0.01)]ms | found [mode_stats["found"]]/[mode_stats["reachable"]] reachable, steps over shortest total [mode_stats["excess"]] max [mode_stats["excess_max"]]")
		profile_new_searches(walker, pairs, layout)

///Куда уходит время новых поисков: самые дорогие проки по собственному времени
/datum/unit_test/jps_path_bench/proc/profile_new_searches(atom/movable/walker, list/pairs, layout)
	GLOB.jps_scan_savings = TRUE
	world.Profile(PROFILE_CLEAR)
	world.Profile(PROFILE_START)
	for(var/list/pair as anything in pairs)
		var/datum/pathfind/finder = new(walker, pair[1], pair[2], null, pair[3], 0, TRUE, null)
		finder.search()
		qdel(finder)
	var/profile_data = world.Profile(PROFILE_REFRESH, format = "json")
	world.Profile(PROFILE_STOP)
	world.Profile(PROFILE_CLEAR)
	var/list/entries = json_decode(profile_data)
	var/list/parts = list()
	for(var/pick_index in 1 to 8)
		var/list/best
		for(var/list/entry as anything in entries)
			if(!best || entry["self"] > best["self"])
				best = entry
		if(!best)
			break
		entries -= list(best)
		parts += "[best["name"]] self [round(best["self"] * 1000 / length(pairs), 0.01)]ms calls [round(best["calls"] / length(pairs))]"
	log_world("JPS BENCH [layout] profile per search: [jointext(parts, " | ")]")

/datum/unit_test/jps_path_bench/proc/build_bench_arena(layout)
	if(layout != "corridors")
		build_arena(layout)
		return
	build_arena("open")
	for(var/x in 2 to arena_size - 1)
		for(var/y in 2 to arena_size - 1)
			if(((y - 2) % 12) < 3 || ((x - 2) % 20) < 3)
				continue
			var/turf/tile = arena_turf(x, y)
			for(var/obj/item/paper/sheet in tile)
				clutter -= sheet
				qdel(sheet)
			tile.ChangeTurf(/turf/closed/indestructible/wall)

/datum/unit_test/jps_path_bench/proc/measure(atom/movable/walker, list/pair, shortest, list/mode_stats, savings)
	GLOB.jps_scan_savings = savings
	walker.forceMove(pair[1])
	Master.current_ticklimit = 1000000
	GLOB.jps_bench_can_steps = 0
	GLOB.jps_bench_gap = 0
	var/started = TICK_USAGE_REAL
	GLOB.jps_bench_last_check = started
	var/datum/pathfind/finder = new(walker, pair[1], pair[2], null, pair[3], 0, TRUE, null)
	var/list/path = finder.search()
	qdel(finder)
	var/finished = TICK_USAGE_REAL
	var/gap = max(GLOB.jps_bench_gap, finished - GLOB.jps_bench_last_check)
	var/cost_ms = (finished - started) * world.tick_lag
	mode_stats["ms"] += cost_ms
	mode_stats["ms_max"] = max(mode_stats["ms_max"], cost_ms)
	mode_stats["can_step"] += GLOB.jps_bench_can_steps
	mode_stats["gap_max"] = max(mode_stats["gap_max"], gap * world.tick_lag)
	if(isnull(shortest))
		return
	mode_stats["reachable"] += 1
	if(!length(path))
		return
	mode_stats["found"] += 1
	var/excess = length(path) - 1 - shortest
	mode_stats["excess"] += excess
	mode_stats["excess_max"] = max(mode_stats["excess_max"], excess)

#endif

#undef JPS_TEST_ARENA_SIZE
#undef JPS_TEST_SEED
#undef JPS_TEST_FORCE_YIELD
