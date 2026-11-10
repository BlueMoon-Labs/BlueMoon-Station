/// Тяжёлые колбеки таймеров, разбитые на куски: разрез кабельной сети, выброс мусоропровода, слаймовый измельчитель.

/// Отложенная проверка разрезов кабеля - колбек таймера на ближайший тик.
/datum/unit_test/proc/wait_cable_cuts()
	sleep(5)

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
