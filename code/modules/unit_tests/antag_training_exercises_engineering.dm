/// Переносит участника в сектор через пульт и запускает там упражнение тоже через пульт.
/datum/unit_test/proc/antag_training_systems_start(datum/antag_training_session/session, datum/tgui/ui, sector_id, exercise_id)
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors[sector_id]
	var/mob/living/carbon/human/body = session.current_body
	body.a_intent = INTENT_HELP
	antag_training_console_act(session, ui, "sector_enter", list("id" = sector_id))
	var/list/budget = new_wait_budget(30 SECONDS, "участник в секторе [sector_id]")
	while(!(sector.state == ANTAG_TRAINING_SECTOR_READY && arena.inside_bounds(get_turf(session.current_body), sector.bounds)) && wait_budget_tick(budget))
		continue
	antag_training_console_act(session, ui, "exercise_start", list("id" = exercise_id))
	var/datum/antag_training_exercise_run/run = session.exercise_run
	return run?.exercise.id == exercise_id ? run : null

/datum/unit_test/proc/antag_training_hold(mob/living/carbon/human/user, obj/item/tool)
	user.drop_all_held_items()
	user.put_in_active_hand(tool)
	return tool

/datum/unit_test/proc/antag_training_machine_act(mob/living/user, datum/machine, interface, action, list/params = list())
	var/datum/tgui/ui = allocate(/datum/tgui, user, machine, interface)
	ui.status = UI_INTERACTIVE
	usr = user
	. = machine.ui_act(action, params, ui)
	usr = null

/datum/unit_test/proc/antag_training_wait_step(datum/antag_training_exercise_run/run, step_index, max_wait = 5 SECONDS)
	var/list/budget = new_wait_budget(max_wait, "шаг [step_index] упражнения [run.exercise.id]")
	while(!QDELETED(run) && !run.ended && run.step_index < step_index && wait_budget_tick(budget))
		continue
	return !QDELETED(run) && (run.step_index >= step_index || run.ended)

/// «Запусти генератор»: плазма в P.A.C.M.A.N., включение из его окна, SMES начинает принимать заряд; сброс глушит генератор.
/datum/unit_test/antag_training_exercise_generator/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = antag_training_systems_start(session, ui, "engineering", "engineering_generator")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в инженерном секторе.")
	var/datum/antag_training_sector/sector = session.arena.sectors["engineering"]
	var/area/sector_area = sector.sector_area
	var/obj/machinery/power/port_gen/pacman/generator = locate() in sector_area
	var/obj/machinery/power/smes/storage = locate() in sector_area
	TEST_ASSERT(!generator.active && !generator.sheets && storage.input_attempt, "Подготовка глушит и опустошает генератор, вход SMES включён.")
	var/obj/item/stack/sheet/mineral/plasma/fuel
	for(var/turf/near as anything in RANGE_TURFS(1, generator))
		fuel = fuel || (locate(/obj/item/stack/sheet/mineral/plasma) in near)
	TEST_ASSERT_NOTNULL(fuel, "Рядом с генератором лежит плазма.")
	var/mob/living/carbon/human/user = session.current_body
	user.forceMove(get_turf(fuel))
	antag_training_hold(user, fuel)
	fuel.melee_attack_chain(user, generator)
	TEST_ASSERT(generator.sheets > 0, "Плазма загружена в генератор.")
	TEST_ASSERT(antag_training_wait_step(run, 2), "Заправка засчитана.")
	antag_training_machine_act(user, generator, "PortableGenerator", "toggle_power")
	TEST_ASSERT(generator.active, "Генератор запускается из своего окна.")
	TEST_ASSERT(antag_training_wait_step(run, 3), "Запуск засчитан.")
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 30 SECONDS), "Упражнение завершается, когда SMES принимает заряд.")
	TEST_ASSERT(run.success && storage.inputting && storage.input_available > 0, "SMES принимает заряд от генератора: [run.result_text]")
	antag_training_console_act(session, ui, "exercise_stop", list())
	TEST_ASSERT(!generator.active, "Сброс упражнения глушит генератор.")

/// «Проложи питание»: кабель от конца под дверью до терминала щитка комнаты, лампы комнаты загораются; подготовка снимает кабель и разряжает щиток.
/datum/unit_test/antag_training_exercise_cable/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = antag_training_systems_start(session, ui, "engineering", "engineering_cable")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в инженерном секторе.")
	var/datum/antag_training_sector/engineering/sector = session.arena.sectors["engineering"]
	var/area/antag_training/room_area = sector.cable_room
	TEST_ASSERT(istype(room_area, /area/antag_training/sector/engineering/cable_room) && room_area.arena == session.arena, "Комната под прокладку - своя область полигона.")
	var/obj/machinery/power/apc/room_apc = locate() in room_area
	TEST_ASSERT(room_apc?.terminal && !room_apc.terminal.powernet, "Щиток комнаты не подключён к сети.")
	TEST_ASSERT_EQUAL(room_apc.cell.charge, 0, "Батарея щитка разряжена.")
	TEST_ASSERT(!(locate(/obj/structure/cable) in room_area), "В комнате нет кабеля.")
	var/list/budget = new_wait_budget(10 SECONDS, "комната без питания темнеет")
	while(room_area.powered(LIGHT) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!room_area.powered(LIGHT), "Без кабеля в комнате нет света.")

	var/turf/live_end
	for(var/obj/structure/cable/wire in sector.sector_area)
		for(var/direction in GLOB.cardinals)
			var/turf/next = get_step(wire, direction)
			if(next?.loc == room_area)
				live_end = get_turf(wire)
	TEST_ASSERT_NOTNULL(live_end, "Конец кабеля лежит у двери комнаты.")
	var/list/turf/path = antag_training_cable_path(live_end, get_turf(room_apc), room_area)
	TEST_ASSERT(length(path) > 2, "От конца кабеля до щитка есть путь по комнате.")
	var/mob/living/carbon/human/user = session.current_body
	user.equip_to_slot_or_del(new /obj/item/clothing/gloves/color/yellow(user), ITEM_SLOT_GLOVES)
	var/obj/item/stack/cable_coil/coil = antag_training_hold(user, new /obj/item/stack/cable_coil(user, 30))
	for(var/index in 1 to length(path) - 1)
		var/turf/here = path[index]
		var/turf/next = path[index + 1]
		user.forceMove(here)
		user.setDir(get_dir(here, next))
		coil.melee_attack_chain(user, here)
		coil.melee_attack_chain(user, next)
	TEST_ASSERT(room_apc.terminal.powernet, "Кабель подключил терминал щитка.")
	TEST_ASSERT(antag_training_wait_step(run, 2), "Прокладка засчитана.")
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 90 SECONDS), "Щиток заряжается и включает свет.")
	TEST_ASSERT(run.success, "Упражнение выполнено: [run.result_text]")
	var/lit = FALSE
	for(var/obj/machinery/light/lamp in room_area)
		lit ||= lamp.status == LIGHT_OK && lamp.on
	TEST_ASSERT(lit, "Лампа комнаты горит.")

	antag_training_console_act(session, ui, "exercise_start", list("id" = "engineering_cable"))
	TEST_ASSERT(!(locate(/obj/structure/cable) in room_area) && !room_apc.cell.charge, "Повтор снимает проложенный кабель и разряжает щиток.")

/datum/unit_test/proc/antag_training_cable_path(turf/start, turf/goal, area/room_area)
	var/list/came_from = list()
	came_from[start] = start
	var/list/turf/queue = list(start)
	for(var/index = 1; index <= length(queue); index++)
		var/turf/here = queue[index]
		if(here == goal)
			break
		for(var/direction in GLOB.cardinals)
			var/turf/open/next = get_step(here, direction)
			if(istype(next) && next.loc == room_area && !came_from[next])
				came_from[next] = here
				queue += next
	if(!came_from[goal])
		return null
	var/list/turf/path = list(goal)
	while(path[1] != start)
		path.Insert(1, came_from[path[1]])
	return path

/// «Взломай шлюз»: панель отвёрткой, болты импульсом, проверка ID кусачками, открытие импульсом, а не ломом; болты, поднятые раньше своего шага, засчитываются; сброс чинит провода и снимает болты.
/datum/unit_test/antag_training_exercise_hack/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	var/datum/antag_training_exercise_run/run = antag_training_systems_start(session, ui, "engineering", "engineering_hack")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в инженерном секторе.")
	var/datum/antag_training_exercise/systems/hack/hack = run.exercise
	var/obj/machinery/door/airlock/door = hack.target(session.arena.sectors["engineering"])
	TEST_ASSERT_NOTNULL(door, "Шлюз под доступ найден.")
	TEST_ASSERT(door.locked && door.density && !door.panel_open && door.requiresID(), "Подготовка запирает шлюз на болты.")
	var/mob/living/carbon/human/user = session.current_body
	TEST_ASSERT(!door.allowed(user), "Участник без карты не проходит.")
	user.equip_to_slot_or_del(new /obj/item/clothing/gloves/color/yellow(user), ITEM_SLOT_GLOVES)
	for(var/direction in GLOB.cardinals)
		var/turf/open/side = get_step(door, direction)
		if(istype(side) && !side.is_blocked_turf())
			user.forceMove(side)
			break
	var/obj/item/screwdriver/screwdriver = antag_training_hold(user, new /obj/item/screwdriver(get_turf(user)))
	screwdriver.melee_attack_chain(user, door)
	TEST_ASSERT(door.panel_open, "Отвёртка снимает панель.")
	var/datum/wires/wires = door.wires
	antag_training_hold(user, new /obj/item/multitool(get_turf(user)))
	antag_training_machine_act(user, wires, "Wires", "pulse", list("wire" = wires.get_color_of_wire(WIRE_BOLTS)))
	TEST_ASSERT(!door.locked, "Импульс по проводу болтов поднимает их.")
	TEST_ASSERT(run.step_index == 1, "Болты подняты, пока шаг панели ещё не засчитан.")
	TEST_ASSERT(antag_training_wait_step(run, 3), "Болты, поднятые раньше своего шага, засчитываются при его подключении.")
	antag_training_hold(user, new /obj/item/wirecutters(get_turf(user)))
	antag_training_machine_act(user, wires, "Wires", "cut", list("wire" = wires.get_color_of_wire(WIRE_IDSCAN)))
	TEST_ASSERT(!door.requiresID(), "Перерезанный провод отключает проверку ID.")
	TEST_ASSERT(antag_training_wait_step(run, 4), "Проверка ID засчитана.")
	var/obj/item/multitool/multitool = locate() in get_turf(user)
	antag_training_hold(user, multitool)
	antag_training_machine_act(user, wires, "Wires", "pulse", list("wire" = wires.get_color_of_wire(WIRE_POWER1)))
	TEST_ASSERT(!door.hasPower(), "Импульс по проводу питания обесточивает шлюз.")
	var/list/pause = new_wait_budget(2 SECONDS, "участник берёт лом")
	while(wait_budget_tick(pause))
		continue
	var/obj/item/crowbar/crowbar = antag_training_hold(user, new /obj/item/crowbar(get_turf(user)))
	crowbar.melee_attack_chain(user, door)
	TEST_ASSERT(wait_for_var(door, "density", FALSE, 5 SECONDS), "Обесточенный шлюз открывается ломом.")
	var/list/budget = new_wait_budget(2 SECONDS, "открытие ломом не засчитывается")
	while(wait_budget_tick(budget))
		continue
	TEST_ASSERT(run.step_index == 4 && !run.ended, "Шлюз, открытый ломом, не засчитан.")
	budget = new_wait_budget(30 SECONDS, "питание шлюза возвращается")
	while(!door.hasPower() && wait_budget_tick(budget))
		continue
	antag_training_hold(user, multitool)
	antag_training_machine_act(user, wires, "Wires", "pulse", list("wire" = wires.get_color_of_wire(WIRE_OPEN)))
	TEST_ASSERT(wait_for_var(door, "density", TRUE, 5 SECONDS), "Импульс по проводу открытия закрывает открытый шлюз.")
	TEST_ASSERT(wait_for_var(door, "operating", FALSE, 5 SECONDS), "Шлюз закрылся до конца.")
	TEST_ASSERT(!run.ended, "Закрытие импульсом не засчитано.")
	antag_training_machine_act(user, wires, "Wires", "pulse", list("wire" = wires.get_color_of_wire(WIRE_OPEN)))
	TEST_ASSERT(wait_for_var(door, "density", FALSE, 5 SECONDS), "Импульс по проводу открытия открывает шлюз.")
	TEST_ASSERT(wait_for_var(run, "ended", TRUE, 5 SECONDS) && run.success, "Упражнение выполнено: [run.result_text]")

	antag_training_console_act(session, ui, "exercise_stop", list())
	TEST_ASSERT(!door.locked && !door.panel_open && door.requiresID(), "Сброс снимает болты, чинит провода и закрывает панель.")
	TEST_ASSERT(wait_for_var(door, "density", TRUE, 5 SECONDS), "Сброс закрывает шлюз.")

/// «Отключи щитовую и верни свет»: рубильник APC гасит свет сектора и возвращает его, шаги засчитываются по смене питания области; второе упражнение в секторе не начинается.
/datum/unit_test/antag_training_exercise_blackout/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	var/datum/antag_training_sector/sector = session.arena.sectors["engineering"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/obj/machinery/power/apc/switchboard = locate() in sector.sector_area
	switchboard.operating = FALSE
	switchboard.update()
	var/datum/antag_training_exercise_run/run = antag_training_systems_start(session, ui, "engineering", "engineering_blackout")
	TEST_ASSERT_NOTNULL(run, "Упражнение стартует в инженерном секторе.")
	TEST_ASSERT(switchboard.operating && sector.sector_area.powered(LIGHT), "Подготовка включает свет сектора.")
	var/datum/antag_training_session/other = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(other.prepare(session.arena), "Второй участник входит на тот же полигон.")
	var/datum/tgui/other_ui = allocate(/datum/tgui, other.current_body, other, "AntagTraining")
	TEST_ASSERT_NULL(antag_training_systems_start(other, other_ui, "engineering", "engineering_hack"), "Второй участник не начинает другое упражнение того же сектора.")
	TEST_ASSERT(findtext(other.last_feedback, "другого участника"), "Пульт объясняет отказ: [other.last_feedback]")
	TEST_ASSERT(!run.ended && switchboard.operating, "Отказ второму участнику не трогает чужой прогон.")
	var/mob/living/user = session.current_body
	user.forceMove(get_turf(switchboard))
	antag_training_machine_act(user, switchboard, "Apc", "breaker")
	TEST_ASSERT(!sector.sector_area.powered(LIGHT), "Рубильник гасит свет.")
	TEST_ASSERT_EQUAL(run.step_index, 2, "Обесточивание засчитано по смене питания области.")
	antag_training_machine_act(user, switchboard, "Apc", "breaker")
	TEST_ASSERT(sector.sector_area.powered(LIGHT), "Рубильник возвращает свет.")
	TEST_ASSERT(run.ended && run.success, "Упражнение выполнено: [run.result_text]")
