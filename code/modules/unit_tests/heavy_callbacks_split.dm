/// Тяжёлые колбеки таймеров, разбитые на куски: разрез кабельной сети, выброс мусоропровода, слаймовый измельчитель.

/// Отложенная проверка разрезов кабеля - колбек таймера на ближайший тик.
/datum/unit_test/proc/wait_cable_cuts()
	var/list/budget = new_wait_budget(2 SECONDS, "разбор разрезов кабеля")
	while(length(GLOB.cable_cut_ends))
		if(!wait_budget_tick(budget))
			return

/// Каждый кабель сети знает её, и сеть держит ровно эти кабели.
/datum/unit_test/proc/powernet_consistent(datum/powernet/net, list/cables)
	if(QDELETED(net) || length(net.cables) != length(cables))
		return FALSE
	for(var/obj/structure/cable/C as anything in cables)
		if(C.powernet != net || !(C in net.cables))
			return FALSE
	return TRUE

/// Отрезанный тупиковый кабель не пересобирает остальную сеть.
/datum/unit_test/powernet_cut_dead_end_keeps_net/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/list/chain = list()
	for(var/i in 0 to 3)
		chain += allocate(/obj/structure/cable, locate(start.x, start.y + i, start.z), null, NORTH, SOUTH)
	var/datum/powernet/net = new()
	propagate_network(chain[1], net)
	TEST_ASSERT(powernet_consistent(net, chain), "Сеть цепочки собрана неверно")

	var/obj/structure/cable/dead_end = chain[1]
	chain -= dead_end
	qdel(dead_end)
	wait_cable_cuts()

	var/obj/structure/cable/survivor = chain[1]
	TEST_ASSERT(powernet_consistent(net, chain), "Отрезанный конец пересобрал остаток в новую сеть: [survivor.powernet] вместо [net]")

/// Разрез кольца ничего не разделяет: сеть остаётся прежней.
/datum/unit_test/powernet_cut_loop_keeps_net/Run()
	var/turf/bottom_left = run_loc_floor_bottom_left
	var/turf/bottom_right = get_step(bottom_left, EAST)
	var/turf/top_left = get_step(bottom_left, NORTH)
	var/turf/top_right = get_step(top_left, EAST)
	var/list/ring = list(
		allocate(/obj/structure/cable, bottom_left, null, NORTH, EAST),
		allocate(/obj/structure/cable, bottom_right, null, NORTH, WEST),
		allocate(/obj/structure/cable, top_right, null, SOUTH, WEST),
		allocate(/obj/structure/cable, top_left, null, SOUTH, EAST),
	)
	var/datum/powernet/net = new()
	propagate_network(ring[1], net)
	TEST_ASSERT(powernet_consistent(net, ring), "Сеть кольца собрана неверно")

	var/obj/structure/cable/cut = ring[1]
	ring -= cut
	qdel(cut)
	wait_cable_cuts()

	TEST_ASSERT(powernet_consistent(net, ring), "Разрез кольца сменил сеть у связанного остатка")

/// Два разреза в одном тике делят линию на три сети; машина уходит вместе со своим куском.
/datum/unit_test/powernet_cut_splits_line/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/list/line = list()
	for(var/i in 0 to 4)
		line += allocate(/obj/structure/cable, locate(start.x + i, start.y, start.z), null, EAST, WEST)
	var/turf/east_end = locate(start.x + 4, start.y, start.z)
	var/obj/structure/cable/node = allocate(/obj/structure/cable, east_end, null, 0, WEST)
	var/obj/machinery/power/terminal/terminal = allocate(/obj/machinery/power/terminal, east_end)
	var/datum/powernet/net = new()
	propagate_network(line[1], net)
	TEST_ASSERT(terminal.connect_to_network(), "Терминал не подключился к сети")
	TEST_ASSERT_EQUAL(terminal.powernet, net, "Терминал не в сети линии")

	qdel(line[2])
	qdel(line[4])
	wait_cable_cuts()

	var/obj/structure/cable/west_end = line[1]
	var/obj/structure/cable/middle = line[3]
	var/obj/structure/cable/east_end_cable = line[5]
	var/datum/powernet/west_net = west_end.powernet
	var/datum/powernet/middle_net = middle.powernet
	var/datum/powernet/east_net = east_end_cable.powernet
	TEST_ASSERT(west_net && middle_net && east_net, "У куска линии не осталось сети")
	TEST_ASSERT(west_net != middle_net && middle_net != east_net && west_net != east_net, "Разделённые куски остались в одной сети")
	TEST_ASSERT(powernet_consistent(west_net, list(line[1])), "Западный кусок собран неверно")
	TEST_ASSERT(powernet_consistent(middle_net, list(line[3])), "Средний кусок собран неверно")
	TEST_ASSERT(powernet_consistent(east_net, list(line[5], node)), "Восточный кусок собран неверно")
	TEST_ASSERT_EQUAL(terminal.powernet, east_net, "Терминал не ушёл в сеть своего куска")
	TEST_ASSERT(terminal in east_net.nodes, "Сеть куска не знает свой терминал")

/// Взрыв режет линию с востока: западный кусок узнаёт о разрезе только от соседа, у которого восточный кабель уже ушёл.
/datum/unit_test/powernet_cut_run_from_far_end/Run()
	var/turf/start = run_loc_floor_bottom_left
	var/list/line = list()
	for(var/i in 0 to 5)
		line += allocate(/obj/structure/cable, locate(start.x + i, start.y, start.z), null, EAST, WEST)
	var/datum/powernet/net = new()
	propagate_network(line[1], net)
	TEST_ASSERT(powernet_consistent(net, line), "Сеть линии собрана неверно")

	for(var/i in 5 to 2 step -1)
		qdel(line[i])
	wait_cable_cuts()

	var/obj/structure/cable/west_end = line[1]
	var/obj/structure/cable/east_end = line[6]
	TEST_ASSERT(west_end.powernet && east_end.powernet, "У конца линии не осталось сети")
	TEST_ASSERT(west_end.powernet != east_end.powernet, "Линия, разрезанная с востока на запад, осталась одной сетью")
	TEST_ASSERT(powernet_consistent(west_end.powernet, list(west_end)), "Западный кусок собран неверно")
	TEST_ASSERT(powernet_consistent(east_end.powernet, list(east_end)), "Восточный кусок собран неверно")

/// Диагональный кабель держится за соседа через угол клетки: его разрез тоже делит сеть.
/datum/unit_test/powernet_cut_diagonal_bridge/Run()
	var/turf/origin = run_loc_floor_bottom_left
	var/obj/structure/cable/south_west = allocate(/obj/structure/cable, origin, null, 0, NORTHEAST)
	var/obj/structure/cable/bridge = allocate(/obj/structure/cable, locate(origin.x + 1, origin.y + 1, origin.z), null, NORTHEAST, SOUTHWEST)
	var/obj/structure/cable/north = allocate(/obj/structure/cable, locate(origin.x + 1, origin.y + 2, origin.z), null, 0, SOUTHEAST)
	var/datum/powernet/net = new()
	propagate_network(south_west, net)
	TEST_ASSERT(powernet_consistent(net, list(south_west, bridge, north)), "Сеть через диагональ собрана неверно")

	qdel(bridge)
	wait_cable_cuts()

	TEST_ASSERT(south_west.powernet && north.powernet, "У куска не осталось сети")
	TEST_ASSERT(south_west.powernet != north.powernet, "Разрез диагонального моста оставил куски одной сетью")

/// Сторона квадрата под сетку одного сида, в клетках.
#define POWERNET_PROPERTY_SPAN 14
#define POWERNET_PROPERTY_COLUMNS 4
#define POWERNET_PROPERTY_ROWS 3
#define POWERNET_PROPERTY_ROUNDS 3
#define POWERNET_PROPERTY_SEED 7301

/// Случайные связные сетки (петли, тупики, перекрёстки, диагонали, терминалы) режутся пачками по 1-8 кабелей в тик;
/// после колбека сети совпадают с компонентами связности, посчитанными обходом get_connections().
/datum/unit_test/powernet_cut_matches_components/Run()
	var/stride = POWERNET_PROPERTY_SPAN + 1
	var/datum/turf_reservation/arena = SSmapping.RequestBlockReservation(POWERNET_PROPERTY_COLUMNS * stride + 1, POWERNET_PROPERTY_ROWS * stride + 1, turf_type_override = /turf/open/floor/plating)
	TEST_ASSERT_NOTNULL(arena, "Не выделен участок под сетки")
	var/list/sites = list()
	var/site_count = POWERNET_PROPERTY_COLUMNS * POWERNET_PROPERTY_ROWS
	for(var/index in 1 to site_count)
		var/datum/powernet_property_site/site = new()
		site.seed = POWERNET_PROPERTY_SEED + index
		site.origin = locate(arena.bottom_left_coords[1] + 1 + ((index - 1) % POWERNET_PROPERTY_COLUMNS) * stride, arena.bottom_left_coords[2] + 1 + round((index - 1) / POWERNET_PROPERTY_COLUMNS) * stride, arena.bottom_left_coords[3])
		rand_seed(site.seed)
		site.lay(src, 6 + round((index - 1) * 110 / (site_count - 1)))
		sites += site

	for(var/datum/powernet_property_site/site as anything in sites)
		for(var/obj/structure/cable/cable as anything in site.cables)
			if(!cable.powernet)
				var/datum/powernet/net = new()
				net.add_cable(cable)
				propagate_network(cable, net)
		var/error = site.check()
		if(error)
			site.failed = TRUE
			TEST_FAIL("Сид [site.seed], сборка: [error]")

	for(var/round_index in 1 to POWERNET_PROPERTY_ROUNDS)
		for(var/datum/powernet_property_site/site as anything in sites)
			if(!site.failed)
				rand_seed(site.seed * 16 + round_index)
				site.last_cuts = site.cut_random(src)
		wait_cable_cuts()
		for(var/datum/powernet_property_site/site as anything in sites)
			if(site.failed)
				continue
			var/error = site.check()
			if(error)
				site.failed = TRUE
				TEST_FAIL("Сид [site.seed], разрез [round_index] ([site.last_cuts]): [error]")
	rand_seed(REALTIMEOFDAY)
	QDEL_LIST(sites)
	allocated += arena

/// Квадрат одного сида: кабели и терминалы на нём и сети, которые он уже видел.
/datum/powernet_property_site
	var/seed
	var/turf/origin
	var/list/cables = list()
	var/list/machines = list()
	var/list/known_nets = list()
	var/last_cuts
	var/failed = FALSE

/datum/powernet_property_site/Destroy()
	origin = null
	cables = null
	machines = null
	known_nets = null
	return ..()

/datum/powernet_property_site/proc/cell_turf(cell)
	return locate(origin.x + (cell - 1) % POWERNET_PROPERTY_SPAN, origin.y + round((cell - 1) / POWERNET_PROPERTY_SPAN), origin.z)

/datum/powernet_property_site/proc/neighbor_cell(cell, dir)
	var/x = (cell - 1) % POWERNET_PROPERTY_SPAN
	var/y = round((cell - 1) / POWERNET_PROPERTY_SPAN)
	if(dir & NORTH)
		y++
	if(dir & SOUTH)
		y--
	if(dir & EAST)
		x++
	if(dir & WEST)
		x--
	if(x < 0 || y < 0 || x >= POWERNET_PROPERTY_SPAN || y >= POWERNET_PROPERTY_SPAN)
		return 0
	return x + y * POWERNET_PROPERTY_SPAN + 1

/datum/powernet_property_site/proc/add_frontier(cell, list/in_tree, list/frontier)
	for(var/dir in GLOB.alldirs)
		var/other = neighbor_cell(cell, dir)
		if(!other || in_tree[other])
			continue
		if((dir in GLOB.diagonals) && prob(70))
			continue
		frontier += list(list(cell, dir))

/// Случайное остовное дерево из cells_wanted клеток и петли поверх. Клетка с двумя связями бывает сквозным кабелем,
/// с четырьмя прямыми - перекрёстком без контакта, иначе на ней узел на каждую связь и, бывает, терминал.
/datum/powernet_property_site/proc/lay(datum/unit_test/test, cells_wanted)
	var/cell_count = POWERNET_PROPERTY_SPAN * POWERNET_PROPERTY_SPAN
	var/list/links = new /list(cell_count)
	for(var/cell in 1 to cell_count)
		links[cell] = list()
	var/list/in_tree = new /list(cell_count)
	var/list/tree = list()
	var/list/frontier = list()
	var/first = rand(1, cell_count)
	in_tree[first] = TRUE
	tree += first
	add_frontier(first, in_tree, frontier)
	while(length(tree) < cells_wanted && length(frontier))
		var/list/edge = pick_n_take(frontier)
		var/other = neighbor_cell(edge[1], edge[2])
		if(in_tree[other])
			continue
		in_tree[other] = TRUE
		tree += other
		links[edge[1]] += edge[2]
		links[other] += turn(edge[2], 180)
		add_frontier(other, in_tree, frontier)

	var/list/spare = list()
	for(var/cell in tree)
		for(var/dir in list(NORTH, EAST, NORTHEAST, SOUTHEAST))
			var/other = neighbor_cell(cell, dir)
			if(other && in_tree[other] && !(dir in links[cell]))
				spare += list(list(cell, other, dir))
	for(var/i in 1 to rand(0, round(length(tree) / 4)))
		if(!length(spare))
			break
		var/list/edge = pick_n_take(spare)
		links[edge[1]] += edge[3]
		links[edge[2]] += turn(edge[3], 180)

	for(var/cell in tree)
		var/list/dirs = links[cell]
		var/turf/place = cell_turf(cell)
		if(length(dirs) == 2 && prob(50))
			cables += test.allocate(/obj/structure/cable, place, null, min(dirs[1], dirs[2]), max(dirs[1], dirs[2]))
			continue
		if(length(dirs) == 4 && (NORTH in dirs) && (SOUTH in dirs) && (EAST in dirs) && (WEST in dirs) && prob(50))
			cables += test.allocate(/obj/structure/cable, place, null, NORTH, SOUTH)
			cables += test.allocate(/obj/structure/cable, place, null, EAST, WEST)
			continue
		for(var/dir in dirs)
			cables += test.allocate(/obj/structure/cable, place, null, 0, dir)
		if(length(dirs) && prob(25))
			machines += test.allocate(/obj/machinery/power/terminal, place)

/// Режет 1-8 живых кабелей вразброс или кучно, как взрыв, в случайном порядке: половину взрывом, половину кусачками.
/datum/powernet_property_site/proc/cut_random(datum/unit_test/test)
	var/list/live = list()
	for(var/obj/structure/cable/cable as anything in cables)
		if(!QDELETED(cable))
			live += cable
	if(!length(live))
		return "резать нечего"
	var/count = min(rand(1, 8), length(live))
	var/list/doomed
	if(prob(50))
		doomed = list()
		var/list/pool = live.Copy()
		for(var/i in 1 to count)
			doomed += pick_n_take(pool)
	else
		var/list/cluster = list(pick(live))
		var/head = 1
		while(head <= length(cluster) && length(cluster) < count)
			var/obj/structure/cable/current = cluster[head]
			head++
			for(var/obj/structure/cable/next in current.get_connections())
				if(!(next in cluster))
					cluster += next
		doomed = cluster.Copy(1, min(count, length(cluster)) + 1)
		shuffle_inplace(doomed)
	var/list/report = list()
	for(var/obj/structure/cable/cable as anything in doomed)
		report += describe(cable)
		if(prob(50))
			cable.ex_act(EXPLODE_DEVASTATE)
		else
			test.allocated += cable.stored
			cable.deconstruct()
	return report.Join("; ")

/datum/powernet_property_site/proc/describe(atom/thing)
	var/obj/structure/cable/cable = thing
	if(istype(cable))
		return "([thing.x - origin.x],[thing.y - origin.y]) [cable.d1]-[cable.d2]"
	return "([thing.x - origin.x],[thing.y - origin.y]) [thing.name]"

/// Сверяет сети с компонентами связности живых кабелей. null - всё сходится.
/datum/powernet_property_site/proc/check()
	var/list/live = list()
	for(var/obj/structure/cable/cable as anything in cables)
		if(!QDELETED(cable))
			live += cable
	var/list/component = list()
	var/components = 0
	for(var/obj/structure/cable/cable as anything in live)
		if(component[cable])
			continue
		components++
		component[cable] = components
		var/list/queue = list(cable)
		var/head = 1
		while(head <= length(queue))
			var/obj/structure/cable/current = queue[head]
			head++
			for(var/obj/structure/cable/next in current.get_connections())
				if(!component[next])
					component[next] = components
					queue += next

	var/list/net_of_component = new /list(components)
	var/list/size_of_component = new /list(components)
	var/list/component_of_net = list()
	for(var/obj/structure/cable/cable as anything in live)
		var/datum/powernet/net = cable.powernet
		if(!net || QDELETED(net))
			return "кабель [describe(cable)] без сети"
		var/index = component[cable]
		size_of_component[index] += 1
		if(!net_of_component[index])
			net_of_component[index] = net
		else if(net_of_component[index] != net)
			return "связный кусок с кабелем [describe(cable)] разбит на несколько сетей"
		var/other = component_of_net[net]
		if(other && other != index)
			return "кабель [describe(cable)] в одной сети с несвязанным с ним куском"
		component_of_net[net] = index

	for(var/datum/powernet/net as anything in component_of_net)
		var/list/seen = list()
		for(var/obj/structure/cable/cable as anything in net.cables)
			if(QDELETED(cable) || cable.powernet != net || seen[cable])
				return "в списке сети удалённый, чужой или повторный кабель [describe(cable)]"
			seen[cable] = TRUE
		if(length(net.cables) != size_of_component[component_of_net[net]])
			return "сеть держит [length(net.cables)] кабелей, а в её куске [size_of_component[component_of_net[net]]]"
		for(var/obj/machinery/power/machine as anything in net.nodes)
			if(QDELETED(machine) || machine.powernet != net)
				return "в узлах сети чужая или удалённая машина [describe(machine)]"
	for(var/datum/powernet/net as anything in known_nets)
		if(!QDELETED(net) && !component_of_net[net])
			return "опустевшая сеть не удалена: кабелей [length(net.cables)], машин [length(net.nodes)]"
	known_nets = component_of_net.Copy()

	for(var/obj/machinery/power/machine as anything in machines)
		var/list/nets_here = list()
		for(var/obj/structure/cable/cable in machine.loc)
			if(cable.d1 == 0 && cable.powernet)
				nets_here += cable.powernet
		if(!length(nets_here))
			if(machine.powernet)
				return "терминал [describe(machine)] без узла под собой остался в сети"
			continue
		if(!(machine.powernet in nets_here))
			return "терминал [describe(machine)] не в сети узла под собой"
		if(!(machine in machine.powernet.nodes))
			return "сеть терминала [describe(machine)] его не знает"
	return null

#undef POWERNET_PROPERTY_SPAN
#undef POWERNET_PROPERTY_COLUMNS
#undef POWERNET_PROPERTY_ROWS
#undef POWERNET_PROPERTY_ROUNDS
#undef POWERNET_PROPERTY_SEED

/// Большая пачка из трубы выбрасывается кусками по тикам и вся доходит до турфа.
/datum/unit_test/disposal_outlet_expel_spreads_pile/Run()
	var/turf/T = run_loc_floor_bottom_left
	var/obj/structure/disposaloutlet/outlet = allocate(/obj/structure/disposaloutlet, T)
	var/obj/structure/disposalholder/holder = new(outlet)
	holder.gas = new /datum/gas_mixture()
	var/list/pile = list()
	for(var/i in 1 to 300)
		pile += allocate(/obj/item/crowbar, holder)

	// так колбек выброса зовёт SStimer
	INVOKE_ASYNC(outlet, TYPE_PROC_REF(/obj/structure/disposaloutlet, expel_holder), holder)
	TEST_ASSERT(!QDELETED(holder) && length(holder.contents), "Триста предметов выброшены одним куском, без уступки тика")

	var/waited = 0
	while(!QDELETED(holder) && waited < 100)
		sleep(1)
		waited++
	TEST_ASSERT(QDELETED(holder), "Холдер не удалён после выброса")
	for(var/obj/item/crowbar/thrown as anything in pile)
		TEST_ASSERT(isturf(thrown.loc), "Предмет [thrown] не долетел до турфа: [thrown.loc]")

/// Холдер, слитый с новым посреди выброса, не теряет и не дублирует остаток.
/datum/unit_test/disposal_outlet_expel_survives_merge/Run()
	var/turf/T = run_loc_floor_bottom_left
	var/obj/structure/disposaloutlet/outlet = allocate(/obj/structure/disposaloutlet, T)
	var/obj/structure/disposalholder/holder = new(outlet)
	holder.gas = new /datum/gas_mixture()
	var/list/pile = list()
	for(var/i in 1 to 300)
		pile += allocate(/obj/item/crowbar, holder)

	INVOKE_ASYNC(outlet, TYPE_PROC_REF(/obj/structure/disposaloutlet, expel_holder), holder)
	TEST_ASSERT(!QDELETED(holder) && length(holder.contents), "Выброс не уступил тик, слить посреди нечего")
	var/obj/structure/disposalholder/newcomer = allocate(/obj/structure/disposalholder, outlet)
	newcomer.merge(holder)
	var/left_over = length(newcomer.contents)
	TEST_ASSERT(left_over > 0, "Слияние не забрало остаток")

	sleep(10)
	TEST_ASSERT_EQUAL(length(newcomer.contents), left_over, "Выброс продолжил таскать предметы из чужого холдера")
	var/on_turf = 0
	for(var/obj/item/crowbar/thrown as anything in pile)
		if(isturf(thrown.loc))
			on_turf++
	TEST_ASSERT_EQUAL(on_turf + left_over, length(pile), "Часть пачки потерялась при слиянии")

/// Партия слаймов перерабатывается кусками по тикам, ядра выходят у всех.
/datum/unit_test/slime_processor_spreads_batch/Run()
	var/turf/T = run_loc_floor_bottom_left
	var/obj/machinery/processor/slime/processor = allocate(/obj/machinery/processor/slime, T)
	for(var/i in 1 to 40)
		var/mob/living/simple_animal/slime/slime = new(processor)
		slime.death()
	processor.processing = TRUE

	// так колбек переработки зовёт SStimer
	INVOKE_ASYNC(processor, TYPE_PROC_REF(/obj/machinery/processor, complete_processing))
	TEST_ASSERT(processor.processing, "Сорок слаймов переработаны одним куском, без уступки тика")

	var/waited = 0
	while(processor.processing && waited < 100)
		sleep(1)
		waited++
	TEST_ASSERT(!processor.processing, "Переработка не закончилась")
	TEST_ASSERT(!(locate(/mob/living/simple_animal/slime) in processor), "В измельчителе остались слаймы")
	var/cores = 0
	for(var/obj/item/slime_extract/core in T)
		cores++
		qdel(core)
	TEST_ASSERT(cores >= 40, "Ядер меньше, чем слаймов: [cores]")

/// Выращенный культом пол по-прежнему вспыхивает; без вспышки остаётся только пол с загрузки карты.
/datum/unit_test/cult_floor_flash_when_grown/Run()
	var/turf/T = run_loc_floor_bottom_left
	var/old_type = T.type
	T.ChangeTurf(/turf/open/floor/engine/cult)
	var/obj/effect/temp_visual/cult/turf/floor/flash = locate() in T
	T.ChangeTurf(old_type)
	TEST_ASSERT_NOTNULL(flash, "Выращенный культовый пол не вспыхнул")
