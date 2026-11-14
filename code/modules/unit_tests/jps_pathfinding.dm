// ===== Поиск пути JPS: правильные пути и уступка тика внутри сканов =====

#define JPS_TEST_ARENA_SIZE 40
#define JPS_TEST_SEED 1114
///Сколько пар клеток сверяется с поиском в ширину на каждой планировке
#define JPS_TEST_PAIRS 100
///Предел тика ниже нуля: любая проверка тика в поиске уступает
#define JPS_TEST_FORCE_YIELD -1
///Срок, после которого пасфайндер отбирает у поиска слот
#define JPS_TEST_SLOT_TIME (15 SECONDS)
///Сколько тиков тест ждёт поиск при выбранном бюджете и сколько ему можно идти
#define JPS_TEST_SPENT_BUDGET_WAIT 400
#define JPS_TEST_SPENT_BUDGET_TICKS 60
///Сколько тиков бенч ждёт один поиск
#define JPS_BENCH_CONTENDED_CAP 400

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

///Координаты клетки внутри зала: по ним пару можно повторить на любом месте резервации
/datum/unit_test/jps_arena/proc/arena_coords(turf/tile)
	return "[tile.x - arena.bottom_left_coords[1] + 1],[tile.y - arena.bottom_left_coords[2] + 1]"

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

///Кратчайшее число шагов поиском в ширину по тем же рёбрам, что видит JPS, до клетки не дальше mintargetdist от цели; null - не дойти за max_distance
/datum/unit_test/jps_arena/proc/reference_length(atom/movable/walker, turf/start, turf/goal, max_distance, mintargetdist = 0)
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
				if(get_dist(to_turf, goal) <= mintargetdist)
					qdel(edges)
					return steps
				depth[to_turf] = steps
				next_frontier += to_turf
		frontier = next_frontier
	qdel(edges)
	return null

///Путь идёт по соседним клеткам через открытые рёбра от старта до цели
/datum/unit_test/jps_arena/proc/path_problem(atom/movable/walker, turf/start, turf/goal, list/path, mintargetdist = 0)
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
	if(get_dist(previous, goal) > mintargetdist)
		return "путь кончился на [previous.x],[previous.y], а не в цели"

///На каждой паре клеток JPS находит путь тогда же, когда его находит поиск в ширину, и путь кратчайший. Пары выбраны до первого поиска: поиск уступает тик, и чужие проки за это время тратят общий генератор случайных чисел
/datum/unit_test/jps_paths_match_reference
	parent_type = /datum/unit_test/jps_arena

/datum/unit_test/jps_paths_match_reference/Run()
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar)
	for(var/layout in list("open", "station"))
		build_arena(layout)
		var/list/tiles = open_tiles()
		rand_seed(JPS_TEST_SEED + 1)
		var/list/pairs = list()
		for(var/index in 1 to JPS_TEST_PAIRS)
			pairs += list(list(pick(tiles), pick(tiles), index % 2, index % 3))
		//здесь первый найденный путь был длиннее кратчайшего на 4-6 шагов
		if(layout == "station")
			pairs += list(list(arena_turf(29, 12), arena_turf(11, 36), TRUE, 0), list(arena_turf(37, 5), arena_turf(13, 33), TRUE, 0), list(arena_turf(38, 28), arena_turf(27, 12), TRUE, 0))
		for(var/list/pair as anything in pairs)
			var/turf/start = pair[1]
			var/turf/goal = pair[2]
			if(start == goal)
				continue
			var/max_distance = pair[3] ? get_dist(start, goal) + AI_JPS_DETOUR_SLACK : 120
			var/zone = pair[4]
			walker.forceMove(start)
			//JPS дотягивается и на шаг сверх бюджета: такие пары ничего не доказывают
			var/shortest = reference_length(walker, start, goal, max_distance + 1, zone)
			if(shortest == max_distance + 1)
				continue
			var/datum/pathfind/finder = new(walker, start, goal, null, max_distance, zone, TRUE, null)
			var/list/path = finder.search()
			qdel(finder)
			var/where = "[layout] [arena_coords(start)] -> [arena_coords(goal)], бюджет [max_distance], зона цели [zone]"
			if(isnull(shortest))
				TEST_ASSERT(!length(path), "JPS нашёл путь там, где его нет: [where]")
				continue
			TEST_ASSERT(length(path), "JPS не нашёл путь длиной [shortest]: [where]")
			var/problem = path_problem(walker, start, goal, path, zone)
			TEST_ASSERT(!problem, "Негодный путь, [problem]: [where]")
			//в пути есть и стартовая клетка
			TEST_ASSERT_EQUAL(length(path) - 1, shortest, "Путь JPS длиннее кратчайшего: [where]")

///Обезьяна вплотную к цели с mintargetdist 1: путь в один шаг отдаётся сразу, без сканов во все стороны зала
/datum/unit_test/jps_adjacent_goal_zone
	parent_type = /datum/unit_test/jps_arena
	var/sources_after_first_node

/datum/unit_test/jps_adjacent_goal_zone/proc/on_first_node(atom/movable/walker, datum/pathfind/search)
	SIGNAL_HANDLER
	sources_after_first_node = length(search.sources)

/datum/unit_test/jps_adjacent_goal_zone/Run()
	build_arena("open")
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar)
	var/turf/start = arena_turf(20, 20)
	var/turf/goal = arena_turf(21, 20)
	walker.forceMove(start)
	RegisterSignal(walker, COMSIG_TEST_PATHFIND_AFTER_FIRST_TICK, PROC_REF(on_first_node))
	var/datum/pathfind/finder = new(walker, start, goal, null, 250, 1, TRUE, null)
	var/list/path = finder.search()
	qdel(finder)
	UnregisterSignal(walker, COMSIG_TEST_PATHFIND_AFTER_FIRST_TICK)
	TEST_ASSERT_EQUAL(length(path), 2, "Путь к соседней цели не из одного шага")
	TEST_ASSERT(sources_after_first_node && sources_after_first_node < 10, "Поиск к соседней цели обошёл [sources_after_first_node] клеток")

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
	finder.min_slice_usage = 0
	var/previous_ticklimit = Master.current_ticklimit
	Master.current_ticklimit = JPS_TEST_FORCE_YIELD
	INVOKE_ASYNC(src, TYPE_PROC_REF(/datum/unit_test/jps_scan_yields_mid_expansion, run_search), finder)
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
	finder.min_slice_usage = 0
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

///Пока running, в каждом тике выбирает бюджет вне МК раньше уснувшего поиска: так тик видит поиск на занятом сервере
/datum/jps_budget_burner
	var/running = TRUE

/datum/jps_budget_burner/proc/burn()
	set waitfor = FALSE
	while(running)
		while(!TICK_CHECK && TICK_USAGE_REAL < TICK_LIMIT_TO_RUN)
			continue
		sleep(world.tick_lag)

///Клетка зала, обнесённая стенами: пути к ней нет, поиск обходит всё, до чего дотянется
/datum/unit_test/jps_arena/proc/sealed_goal(x, y)
	var/turf/goal = arena_turf(x, y)
	for(var/direction in GLOB.alldirs)
		var/turf/ring = get_step(goal, direction)
		for(var/obj/item/paper/sheet in ring)
			clutter -= sheet
			qdel(sheet)
		ring.ChangeTurf(/turf/closed/indestructible/wall)
	return goal

/datum/unit_test/jps_scan_yields_mid_expansion/proc/run_path_to(atom/movable/walker, turf/goal, list/search_status)
	async_result = get_path_to(walker, goal, 0, 0, null, TRUE, null, TRUE, null, search_status)
	async_done = TRUE

///Поиск, который просыпается в тик с уже выбранным бюджетом вне МК, всё равно делает за пробуждение кусок работы и обходит зал задолго до того, как у него отберут слот; счётчики пасфайндера видят уступки и длительность
/datum/unit_test/jps_search_progresses_on_spent_budget
	parent_type = /datum/unit_test/jps_scan_yields_mid_expansion

/datum/unit_test/jps_search_progresses_on_spent_budget/Run()
	build_arena("open")
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar)
	var/turf/start = arena_turf(3, 3)
	var/turf/goal = sealed_goal(arena_size - 5, arena_size - 5)
	walker.forceMove(start)
	allocate(/datum/outside_mc_probe_guard)
	Master.outside_tick_limit = TICK_LIMIT_OUTSIDE_MC_DEFAULT
	Master.pacing_forced = TRUE
	var/list/metrics_before = GLOB.ai_metrics.snapshot()
	var/datum/jps_budget_burner/burner = new
	burner.burn()
	var/list/search_status = list()
	var/started_at = world.time
	INVOKE_ASYNC(src, TYPE_PROC_REF(/datum/unit_test/jps_scan_yields_mid_expansion, run_path_to), walker, goal, search_status)
	var/waited = 0
	while(!async_done && waited < JPS_TEST_SPENT_BUDGET_WAIT)
		sleep(world.tick_lag)
		waited++
	burner.running = FALSE
	var/ticks = round((world.time - started_at) / world.tick_lag)
	var/list/metrics = GLOB.ai_metrics.delta_since(metrics_before)
	log_test("\tПоиск по залу [arena_size]x[arena_size] до замкнутой клетки при выбранном бюджете: [ticks] тиков, уступок [metrics["jps_yields"]]")
	TEST_ASSERT(async_done, "Поиск не закончился за [JPS_TEST_SPENT_BUDGET_WAIT] тиков при выбранном бюджете вне МК")
	TEST_ASSERT(search_status[JPS_SEARCH_EXHAUSTED], "Поиск до замкнутой клетки не доказал, что пути нет")
	TEST_ASSERT(ticks <= JPS_TEST_SPENT_BUDGET_TICKS, "Поиск по залу шёл [ticks] тиков: пробуждение при выбранном бюджете делает слишком мало")
	TEST_ASSERT_EQUAL(metrics["jps_searches"], 1, "Счётчик поисков пути не учёл поиск")
	TEST_ASSERT(metrics["jps_yields"] >= 1, "Счётчик уступок не учёл уступки поиска")
	TEST_ASSERT(metrics["jps_search_ticks"] >= 1, "Счётчик тиков поиска не учёл уснувший поиск")
	TEST_ASSERT(GLOB.ai_metrics.jps_search_ticks_max >= metrics["jps_search_ticks"], "Максимум тиков поиска меньше длительности этого поиска")

///Строка о слишком долгом поиске называет радиус и число уступок
/datum/unit_test/jps_toolong_message/Run()
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar, run_loc_floor_bottom_left)
	var/datum/pathfind/finder = new(walker, run_loc_floor_bottom_left, run_loc_floor_top_right, null, 77, 0, TRUE, null)
	finder.yields = 13
	var/datum/pathfinder_lease/lease = new
	lease.owner = walker
	lease.search = finder
	var/message = SSpathfinder.mobs.toolong_message(lease)
	qdel(lease)
	qdel(finder)
	TEST_ASSERT(findtext(message, "radius 77"), "В строке нет радиуса поиска: [message]")
	TEST_ASSERT(findtext(message, "yields 13"), "В строке нет числа уступок: [message]")

///Обезьяна не начинает второй поиск пути, пока идёт первый: handle_combat зовёт поиск асинхронно каждый Life
/datum/unit_test/monkey_single_path_search/Run()
	var/mob/living/carbon/monkey/walker = allocate(/mob/living/carbon/monkey, run_loc_floor_bottom_left)
	var/datum/flowcache/cache = SSpathfinder.mobs
	var/saved_run = cache.run
	var/requests_before = GLOB.ai_metrics.jps_requests
	cache.run = cache.lcount
	INVOKE_ASYNC(walker, TYPE_PROC_REF(/mob/living/carbon/monkey, walk2derpless), run_loc_floor_top_right)
	INVOKE_ASYNC(walker, TYPE_PROC_REF(/mob/living/carbon/monkey, walk2derpless), run_loc_floor_top_right)
	var/requests = GLOB.ai_metrics.jps_requests - requests_before
	cache.run = saved_run
	var/waited = 0
	while(walker.path_search_until && waited < 5 SECONDS)
		sleep(world.tick_lag)
		waited += world.tick_lag
	walk(walker, 0)
	TEST_ASSERT_EQUAL(requests, 1, "Пока поиск пути обезьяны ждёт слот, второй вызов начал ещё один поиск")
	TEST_ASSERT(!walker.path_search_until, "Поиск пути обезьяны не закончился и не снял отметку")

///Поиск, переживший свою отметку, не снимает отметку следующего поиска
/datum/unit_test/monkey_stale_path_search_keeps_newer_mark/Run()
	var/mob/living/carbon/monkey/walker = allocate(/mob/living/carbon/monkey, run_loc_floor_bottom_left)
	var/datum/flowcache/cache = SSpathfinder.mobs
	var/saved_run = cache.run
	var/searches_before = GLOB.ai_metrics.jps_searches
	cache.run = cache.lcount
	INVOKE_ASYNC(walker, TYPE_PROC_REF(/mob/living/carbon/monkey, walk2derpless), run_loc_floor_top_right)
	cache.run = saved_run
	TEST_ASSERT(walker.path_search_until, "Sanity: поиск обезьяны начался и поставил отметку")
	var/newer_mark = walker.path_search_until + 1
	walker.path_search_until = newer_mark
	var/waited = 0
	while(GLOB.ai_metrics.jps_searches == searches_before && waited < 5 SECONDS)
		sleep(world.tick_lag)
		waited += world.tick_lag
	sleep(world.tick_lag)
	walk(walker, 0)
	TEST_ASSERT(GLOB.ai_metrics.jps_searches > searches_before, "Sanity: старый поиск обезьяны закончился")
	TEST_ASSERT_EQUAL(walker.path_search_until, newer_mark, "Закончившийся старый поиск снял отметку идущего нового")

///Бот ищет путь к призыву один раз, пока поиск ждёт слот, а результат сброшенного призыва отбрасывает
/datum/unit_test/bot_single_summon_path_search/Run()
	var/mob/living/simple_animal/bot/cleanbot/bot = allocate(/mob/living/simple_animal/bot/cleanbot, run_loc_floor_bottom_left)
	bot.toggle_ai(AI_OFF)
	bot.auto_patrol = FALSE
	bot.summon_target = run_loc_floor_top_right
	bot.mode = BOT_SUMMON
	var/datum/flowcache/cache = SSpathfinder.mobs
	var/saved_run = cache.run
	var/requests_before = GLOB.ai_metrics.jps_requests
	cache.run = cache.lcount
	bot.calc_summon_path()
	bot.calc_summon_path()
	var/requests = GLOB.ai_metrics.jps_requests - requests_before
	cache.run = saved_run
	var/waited = 0
	while(bot.summon_path_search_until && waited < 5 SECONDS)
		sleep(world.tick_lag)
		waited += world.tick_lag
	TEST_ASSERT_EQUAL(requests, 1, "Пока поиск пути к призыву ждёт слот, второй вызов начал ещё один поиск")
	TEST_ASSERT(!bot.summon_path_search_until, "Поиск пути к призыву не закончился и не снял отметку")
	TEST_ASSERT(length(bot.path), "Бот нашёл путь к месту призыва")

	bot.set_path(null)
	cache.run = cache.lcount
	bot.calc_summon_path()
	cache.run = saved_run
	bot.bot_reset()
	waited = 0
	while(bot.summon_path_search_until && waited < 5 SECONDS)
		sleep(world.tick_lag)
		waited += world.tick_lag
	TEST_ASSERT(!length(bot.path), "Сброшенный во время поиска бот взял путь к старому призыву")

#ifdef AI_HORDE_BENCH
GLOBAL_VAR_INIT(jps_bench_slice_max, 0)

///Долгие поиски ботов и обезьян (радиус 120-250) при бюджете вне МК, выбранном к их пробуждению: тики до ответа с уступкой на узел, по восьми клеткам и по куску времени (first - с первым найденным путём, slice - с кратчайшим)
/datum/unit_test/jps_contended_bench
	parent_type = /datum/unit_test/jps_scan_yields_mid_expansion
	priority = TEST_LONGER
	arena_size = 150

/datum/unit_test/jps_contended_bench/Run()
	build_arena("station")
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar)
	var/list/searches = list()
	var/turf/sealed_near = sealed_goal(arena_size - 40, arena_size - 40)
	var/turf/sealed_far = sealed_goal(arena_size - 20, arena_size - 25)
	var/list/tiles = open_tiles()
	rand_seed(JPS_TEST_SEED + 3)
	var/list/radii = list(120, 150, 200, 250)
	while(length(searches) < length(radii))
		var/turf/start = pick(tiles)
		var/turf/goal = pick(tiles)
		var/distance = get_dist(start, goal)
		if(distance >= 60 && distance <= 110)
			searches += list(list(start, goal, radii[length(searches) + 1]))
	searches += list(list(arena_turf(4, 4), sealed_near, 120))
	searches += list(list(arena_turf(4, 4), sealed_far, 250))

	allocate(/datum/outside_mc_probe_guard)
	Master.outside_tick_limit = TICK_LIMIT_OUTSIDE_MC_DEFAULT
	Master.pacing_forced = TRUE
	var/datum/jps_budget_burner/burner = new
	burner.burn()
	for(var/mode in list("node", "steps", "first", "slice"))
		var/list/parts = list()
		var/total_ticks = 0
		var/max_ticks = 0
		var/over_slot = 0
		for(var/list/search as anything in searches)
			walker.forceMove(search[1])
			GLOB.jps_shortest = mode == "slice"
			var/datum/pathfind/finder = new(walker, search[1], search[2], null, search[3], 0, TRUE, null)
			finder.scan_savings = mode != "node"
			if(mode == "node" || mode == "steps")
				finder.min_slice_usage = 0
			async_done = FALSE
			async_result = null
			GLOB.jps_bench_slice_max = 0
			var/started_at = world.time
			INVOKE_ASYNC(src, TYPE_PROC_REF(/datum/unit_test/jps_scan_yields_mid_expansion, run_search), finder)
			var/waited = 0
			while(!async_done && waited < JPS_BENCH_CONTENDED_CAP)
				sleep(world.tick_lag)
				waited++
			var/ticks = round((world.time - started_at) / world.tick_lag)
			var/finished = async_done
			if(!finished)
				finder.aborted = TRUE
				while(!async_done)
					sleep(world.tick_lag)
			total_ticks += ticks
			max_ticks = max(max_ticks, ticks)
			if(ticks * world.tick_lag > JPS_TEST_SLOT_TIME)
				over_slot++
			parts += "r[search[3]] [ticks]т[finished ? "" : " (не дошёл)"] уст [finder.yields] кусок макс [round(TICK_DELTA_TO_MS(GLOB.jps_bench_slice_max), 0.01)]мс [length(async_result) ? "путь" : "нет пути"]"
			qdel(finder)
		log_world("JPS CONTENDED [mode]: тиков ср [round(total_ticks / length(searches), 0.1)] макс [max_ticks], дольше слота [over_slot]/[length(searches)] | [jointext(parts, " | ")]")
	burner.running = FALSE
	GLOB.jps_shortest = TRUE
#endif

#ifdef AI_HORDE_BENCH

GLOBAL_VAR_INIT(jps_scan_savings, TRUE)
GLOBAL_VAR_INIT(jps_shortest, TRUE)
GLOBAL_VAR_INIT(jps_bench_can_steps, 0)
GLOBAL_VAR_INIT(jps_bench_gap, 0)
GLOBAL_VAR_INIT(jps_bench_last_check, 0)

///Цена одного поиска со старыми сканами, с первым найденным путём и с кратчайшим в одном мире: мс, вызовы can_step, самый длинный кусок без проверки тика, длина пути против кратчайшего
/datum/unit_test/jps_path_bench
	parent_type = /datum/unit_test/jps_arena
	priority = TEST_LONGER
	arena_size = 60

/datum/unit_test/jps_path_bench/Run()
	var/obj/item/crowbar/walker = allocate(/obj/item/crowbar)
	//open - зал орды; corridors - коридоры шириной 3 как в бенче драки; station - комнаты и долгие пути ботов; sealed - те же комнаты и замурованная цель: поиск обходит весь радиус
	for(var/layout in list("open", "corridors", "station", "sealed"))
		build_bench_arena(layout)
		var/turf/sealed = layout == "sealed" ? sealed_goal(22, 22) : null
		var/list/tiles = open_tiles()
		rand_seed(JPS_TEST_SEED + 2)
		var/list/pairs = list()
		while(length(pairs) < (sealed ? 30 : 100))
			var/turf/start = pick(tiles)
			var/turf/goal = sealed || pick(tiles)
			var/distance = get_dist(start, goal)
			if(layout == "open" || layout == "corridors" ? (distance < 4 || distance > 25) : distance < 30)
				continue
			pairs += list(list(start, goal, layout == "open" || layout == "corridors" ? distance + AI_JPS_DETOUR_SLACK : 120))
		var/list/stats = list("old" = list(), "first" = list(), "new" = list())
		for(var/index in 1 to length(pairs))
			var/list/pair = pairs[index]
			var/shortest = reference_length(walker, pair[1], pair[2], pair[3])
			//порядок режимов меняется от пары к паре и гасит дрейф чужой нагрузки
			var/list/order = list("old", "first", "new")
			for(var/turn in 1 to (index % 3))
				order.Add(order[1])
				order.Cut(1, 2)
			if(index % 2)
				reverseRange(order)
			for(var/mode in order)
				GLOB.jps_shortest = mode == "new"
				measure(walker, pair, shortest, stats[mode], mode != "old")
			if(!(index % 10))
				sleep(1)
		GLOB.jps_scan_savings = TRUE
		GLOB.jps_shortest = TRUE
		for(var/mode in stats)
			var/list/mode_stats = stats[mode]
			log_world("JPS BENCH [layout] [mode]: [length(pairs)] searches | ms avg [round(mode_stats["ms"] / length(pairs), 0.01)] max [round(mode_stats["ms_max"], 0.01)] | can_step avg [round(mode_stats["can_step"] / length(pairs))] | worst slice without tick check [round(mode_stats["gap_max"], 0.01)]ms | found [mode_stats["found"]]/[mode_stats["reachable"]] reachable, steps over shortest total [mode_stats["excess"]] max [mode_stats["excess_max"]]")
		profile_new_searches(walker, pairs, layout)

///Куда уходит время новых поисков: самые дорогие проки по собственному времени
/datum/unit_test/jps_path_bench/proc/profile_new_searches(atom/movable/walker, list/pairs, layout)
	GLOB.jps_scan_savings = TRUE
	GLOB.jps_shortest = TRUE
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
		build_arena(layout == "sealed" ? "station" : layout)
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
#undef JPS_TEST_PAIRS
#undef JPS_TEST_FORCE_YIELD
#undef JPS_TEST_SLOT_TIME
#undef JPS_TEST_SPENT_BUDGET_WAIT
#undef JPS_TEST_SPENT_BUDGET_TICKS
#undef JPS_BENCH_CONTENDED_CAP
