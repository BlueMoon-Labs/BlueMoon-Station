/// Инженерный сектор питается по-настоящему: SMES кормит APC, рубильник APC гасит лампы, консоль видит солнечные панели.
/datum/unit_test/antag_training_sector_engineering/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["engineering"]
	TEST_ASSERT_NOTNULL(sector, "Арена знает инженерный сектор.")
	var/datum/tgui/console_ui = allocate(/datum/tgui, session.current_body, session, "AntagTraining")
	antag_training_console_act(session, console_ui, "sector_enter", list("id" = "engineering"))
	var/list/budget = new_wait_budget(30 SECONDS, "участник в инженерном секторе")
	while(!(sector.bounds && arena.inside_bounds(get_turf(session.current_body), sector.bounds)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(sector.bounds && arena.inside_bounds(get_turf(session.current_body), sector.bounds), "Пульт переносит участника в инженерный сектор.")
	var/area/sector_area = sector.sector_area
	TEST_ASSERT(sector_area.requires_power, "Сектор требует питания.")
	var/turf/spawn_tile = sector.spawn_turf()
	TEST_ASSERT(IS_DYNAMIC_LIGHTING(sector_area) && spawn_tile.lighting_object, "В секторе работает динамический свет, а не полная яркость.")

	var/obj/machinery/power/apc/apc
	var/obj/machinery/power/smes/smes
	var/obj/machinery/power/port_gen/pacman/pacman
	var/obj/machinery/power/solar_control/solar_console
	var/list/obj/machinery/power/solar/panels = list()
	var/list/obj/machinery/light/lamps = list()
	for(var/obj/machinery/machine in sector_area)
		if(istype(machine, /obj/machinery/power/apc))
			apc = machine
		else if(istype(machine, /obj/machinery/power/smes))
			smes = machine
		else if(istype(machine, /obj/machinery/power/port_gen/pacman))
			pacman = machine
		else if(istype(machine, /obj/machinery/power/solar_control))
			solar_console = machine
		else if(istype(machine, /obj/machinery/power/solar))
			panels += machine
		else if(istype(machine, /obj/machinery/light))
			lamps += machine
	TEST_ASSERT_NOTNULL(apc, "В секторе есть APC.")
	TEST_ASSERT(!apc.locked, "APC открыт для участника без карты.")
	TEST_ASSERT_EQUAL(apc.cell?.type, /obj/item/stock_parts/cell/high, "В APC батарея высокой ёмкости.")
	TEST_ASSERT(apc.terminal?.powernet, "APC подключён к сети.")
	TEST_ASSERT(smes?.terminal?.powernet && smes.powernet, "SMES с терминалом в сети.")
	TEST_ASSERT_EQUAL(apc.terminal.powernet, smes.powernet, "APC питается от выхода SMES.")
	var/datum/powernet/input_net = smes.terminal.powernet
	TEST_ASSERT_NOTEQUAL(input_net, smes.powernet, "Вход и выход SMES - разные сети.")
	TEST_ASSERT(pacman?.anchored && pacman.powernet == input_net, "P.A.C.M.A.N. закреплён и подключён ко входу SMES.")
	var/fuel = 0
	for(var/turf/near as anything in RANGE_TURFS(1, pacman))
		for(var/obj/item/stack/sheet/mineral/plasma/sheets in near)
			fuel += sheets.amount
	TEST_ASSERT_EQUAL(fuel, 20, "Рядом с генератором лежат 20 листов плазмы.")
	TEST_ASSERT_EQUAL(length(panels), 8, "В галерее 8 солнечных панелей.")
	TEST_ASSERT(solar_console?.powernet == input_net, "Консоль солнечных панелей на входе SMES.")
	TEST_ASSERT_EQUAL(length(solar_console.connected_panels), length(panels), "Консоль видит все панели после загрузки.")
	TEST_ASSERT_NOTNULL(solar_console.connected_tracker, "Консоль видит трекер после загрузки.")

	budget = new_wait_budget(10 SECONDS, "питание инженерного сектора")
	while(!(sector_area.powered(LIGHT) && apc.terminal.avail() > 0) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(sector_area.powered(LIGHT), "Свет сектора запитан.")
	TEST_ASSERT(apc.terminal.avail() > 0, "SMES отдаёт мощность в сеть APC.")
	var/list/working_lamps = list()
	for(var/obj/machinery/light/lamp as anything in lamps)
		if(lamp.status == LIGHT_OK)
			working_lamps += lamp
	TEST_ASSERT(length(working_lamps), "В секторе есть целые лампы.")
	for(var/obj/machinery/light/lamp as anything in working_lamps)
		TEST_ASSERT(lamp.on && lamp.light_range > 0, "Лампа [AREACOORD(lamp)] светит при питании.")

	var/mob/living/trainee = session.current_body
	var/locked_airlocks = 0
	for(var/obj/machinery/door/airlock/airlock in sector_area)
		if(airlock.allowed(trainee))
			continue
		locked_airlocks++
		TEST_ASSERT(airlock.hasPower(), "Шлюз [AREACOORD(airlock)] под питанием.")
	TEST_ASSERT_EQUAL(locked_airlocks, 2, "Два шлюза инженерного доступа закрыты для участника без карты.")
	trainee.forceMove(get_turf(apc))
	var/datum/tgui/ui = allocate(/datum/tgui, trainee, apc, "Apc")
	ui.status = UI_INTERACTIVE
	usr = trainee
	apc.ui_act("breaker", list(), ui)
	usr = null
	TEST_ASSERT(!apc.operating, "Рубильник APC выключается из интерфейса.")
	TEST_ASSERT(!sector_area.powered(LIGHT), "Рубильник APC обесточивает свет сектора.")
	budget = new_wait_budget(2 SECONDS, "лампы инженерного сектора гаснут")
	var/lit = TRUE
	while(lit)
		lit = FALSE
		for(var/obj/machinery/light/lamp as anything in working_lamps)
			lit ||= lamp.on
		if(lit && !wait_budget_tick(budget))
			break
	TEST_ASSERT(!lit, "Без питания лампы сектора гаснут.")

	usr = trainee
	apc.ui_act("breaker", list(), ui)
	usr = null
	TEST_ASSERT(apc.operating && sector_area.powered(LIGHT), "Рубильник возвращает питание.")
	for(var/obj/machinery/light/lamp as anything in working_lamps)
		if(lamp.status == LIGHT_OK)
			TEST_ASSERT(lamp.on, "Лампа [AREACOORD(lamp)] снова светит.")

/// Выключатель и пожарная тревога прошлой загрузки не переживают выгрузку: следующая загрузка сектора светлая.
/datum/unit_test/antag_training_sector_area_reset/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["engineering"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/area/sector_area = sector.sector_area
	var/obj/machinery/light_switch/light_switch = locate() in sector_area
	TEST_ASSERT_NOTNULL(light_switch, "В секторе есть выключатель.")
	var/mob/living/trainee = session.current_body
	trainee.forceMove(get_turf(light_switch))
	light_switch.attack_hand(trainee)
	TEST_ASSERT(!sector_area.lightswitch, "Выключатель гасит свет сектора.")
	sector_area.firealert(light_switch)
	TEST_ASSERT(sector_area.fire, "Пожарная тревога сектора поднята.")
	sector.unload()
	TEST_ASSERT(sector.load(), "Сектор загружается повторно.")
	TEST_ASSERT(sector_area.lightswitch, "Новая загрузка начинается с включённым выключателем.")
	TEST_ASSERT(!sector_area.fire && !(sector_area.datum_flags & DF_ISPROCESSING), "Новая загрузка начинается без пожарной тревоги.")
	var/list/budget = new_wait_budget(10 SECONDS, "лампы сектора после повторной загрузки")
	var/working = 0
	var/lit = 0
	while(TRUE)
		working = 0
		lit = 0
		for(var/obj/machinery/light/lamp in sector_area)
			if(lamp.status != LIGHT_OK)
				continue
			working++
			if(lamp.on)
				lit++
		if((working && lit == working) || !wait_budget_tick(budget))
			break
	TEST_ASSERT(working, "В секторе есть целые лампы.")
	TEST_ASSERT_EQUAL(lit, working, "После повторной загрузки горят все целые лампы.")

/// Шлюзы, собранные на полигоне, в том числе с раскладкой по отделу, получают свою раскладку проводов, а вне полигона - раскладку раунда.
/datum/unit_test/antag_training_built_airlock_wiring/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["engineering"]
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/obj/machinery/door/airlock/built = new(sector.target_turf())
	for(var/wire_key in GLOB.wire_color_directory)
		TEST_ASSERT(built.wires.colors != GLOB.wire_color_directory[wire_key], "Шлюз полигона получил раскладку раунда [wire_key].")
	TEST_ASSERT_EQUAL(length(built.wires.colors), length(built.wires.wires), "У шлюза полигона раскладка всех проводов.")
	var/datum/wires/airlock/engineering/engineering_wires = /datum/wires/airlock/engineering
	var/wiretype = initial(engineering_wires.wiretype)
	var/had_engineering_layout = !!GLOB.wire_color_directory[wiretype]
	var/obj/machinery/door/airlock/engineering/built_engineering = new(get_step(sector.target_turf(), WEST))
	for(var/wire_key in GLOB.wire_color_directory)
		TEST_ASSERT(built_engineering.wires.colors != GLOB.wire_color_directory[wire_key], "Инженерный шлюз полигона получил раскладку раунда [wire_key].")
	TEST_ASSERT_EQUAL(!!GLOB.wire_color_directory[wiretype], had_engineering_layout, "Инженерный шлюз полигона не задаёт раскладку раунда.")
	var/obj/machinery/door/airlock/station_airlock = allocate(/obj/machinery/door/airlock)
	TEST_ASSERT_EQUAL(station_airlock.wires.colors, GLOB.wire_color_directory[/obj/machinery/door/airlock], "Шлюз вне полигона - с раскладкой раунда.")
	var/obj/machinery/door/airlock/engineering/station_engineering = allocate(/obj/machinery/door/airlock/engineering)
	TEST_ASSERT_EQUAL(station_engineering.wires.colors, GLOB.wire_color_directory[wiretype], "Инженерный шлюз вне полигона - с раскладкой раунда.")
