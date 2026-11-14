#define ANTAG_TRAINING_ATMOS_SEAL_FIRES 5
#define ANTAG_TRAINING_ATMOS_PRESSURE_DRIFT 1

/// Открытая канистра плазмы меняет воздух сектора, но не ядра, не пишет администраторам, а сброс сектора возвращает воздух и гасит тревогу.
/datum/unit_test/antag_training_sector_atmos/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_arena/arena = session.arena
	var/datum/antag_training_sector/sector = arena.sectors["atmos"]
	TEST_ASSERT_NOTNULL(sector, "Арена знает атмос-сектор.")
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/obj/machinery/portable_atmospherics/canister/toxins/canister = locate() in sector.sector_area
	TEST_ASSERT_NOTNULL(canister, "В секторе есть канистра плазмы.")
	var/turf/open/hub_floor = arena.entry_turf
	var/hub_plasma = hub_floor.air.get_moles(GAS_PLASMA)
	var/admin_entries = length(GLOB.admin_log_entries)
	session.current_body.forceMove(get_turf(canister))
	var/datum/tgui/ui = allocate(/datum/tgui, session.current_body, canister, "Canister")
	ui.status = UI_INTERACTIVE
	canister.ui_act("pressure", list("pressure" = "max"), ui)
	canister.ui_act("valve", list(), ui)
	TEST_ASSERT(canister.valve_open, "Клапан открывается из окна канистры.")
	var/turf/open/canister_floor = get_turf(canister)
	var/list/budget = new_wait_budget(10 SECONDS, "плазма в воздухе сектора")
	while(canister_floor.air.get_moles(GAS_PLASMA) <= 0 && wait_budget_tick(budget))
		continue
	TEST_ASSERT(canister_floor.air.get_moles(GAS_PLASMA) > 0, "Плазма вышла в воздух сектора.")
	TEST_ASSERT_EQUAL(hub_floor.air.get_moles(GAS_PLASMA), hub_plasma, "Воздух ядра не меняется.")
	TEST_ASSERT_EQUAL(length(GLOB.admin_log_entries), admin_entries, "Учебная канистра не докладывает администраторам о выпуске плазмы.")

	var/obj/machinery/portable_atmospherics/canister/toxins/station_canister = allocate(/obj/machinery/portable_atmospherics/canister/toxins, run_loc_floor_bottom_left)
	var/datum/tgui/station_ui = allocate(/datum/tgui, session.current_body, station_canister, "Canister")
	station_ui.status = UI_INTERACTIVE
	station_canister.ui_act("valve", list(), station_ui)
	station_canister.ui_act("valve", list(), station_ui)
	TEST_ASSERT(length(GLOB.admin_log_entries) > admin_entries, "Станционная канистра тем же путём докладывает администраторам.")

	var/obj/machinery/firealarm/alarm = locate() in sector.sector_area
	TEST_ASSERT_NOTNULL(alarm, "В секторе есть пожарная тревога.")
	session.current_body.forceMove(get_turf(alarm))
	alarm.attack_hand(session.current_body)
	TEST_ASSERT(sector.sector_area.fire, "Пожарная тревога включается.")
	var/list/canister_coords = list(canister_floor.x, canister_floor.y, canister_floor.z)
	TEST_ASSERT(arena.request_reset(session, "atmos"), "Сброс сектора запрашивается.")
	budget = new_wait_budget(1 MINUTES, "сектор перезагружен")
	while((arena.resetting || sector.state != ANTAG_TRAINING_SECTOR_READY || !QDELETED(canister)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(!arena.resetting && sector.state == ANTAG_TRAINING_SECTOR_READY && QDELETED(canister), "Сектор перезагружается.")
	var/turf/open/reloaded_floor = locate(canister_coords[1], canister_coords[2], canister_coords[3])
	var/datum/gas_mixture/air = reloaded_floor.return_air()
	var/pressure = air.return_pressure()
	TEST_ASSERT_EQUAL(air.get_moles(GAS_PLASMA), 0, "После сброса плазмы в воздухе нет.")
	TEST_ASSERT(pressure > WARNING_LOW_PRESSURE && pressure < WARNING_HIGH_PRESSURE, "После сброса нормальное давление, а не [pressure] кПа.")
	TEST_ASSERT(!sector.sector_area.fire, "Сброс сектора снимает пожарную тревогу.")
	TEST_ASSERT(!(sector.sector_area.datum_flags & DF_ISPROCESSING), "Область сектора не обрабатывается после сброса тревоги.")

/// Воздух не выходит за стены сектора, а стекло и шлюз вакуумной камеры держат давление зала.
/datum/unit_test/antag_training_sector_atmos_sealed/Run()
	var/datum/antag_training_session/session = allocate_training_session(/datum/antag_training_program/free)
	TEST_ASSERT(session.prepare(), "Полигон должен подготовиться.")
	var/datum/antag_training_sector/sector = session.arena.sectors["atmos"]
	TEST_ASSERT_NOTNULL(sector, "Арена знает атмос-сектор.")
	TEST_ASSERT(sector.load(), "Сектор загружается.")
	var/list/inside = list()
	for(var/turf/tile as anything in sector.turfs)
		inside[tile] = TRUE
	var/list/turf/open/chamber = list()
	for(var/turf/open/floor/engine/vacuum/vacuum_floor in sector.turfs)
		chamber[vacuum_floor] = TRUE
	TEST_ASSERT(length(chamber), "В секторе есть вакуумная камера.")
	var/list/filled = filled_tiles(chamber)
	TEST_ASSERT(!length(filled), "Вакуумная камера загружается с воздухом: [filled.Join("; ")].")
	var/obj/machinery/door/airlock/external/hatch = locate() in sector.sector_area
	TEST_ASSERT_NOTNULL(hatch, "У камеры есть шлюз.")
	var/turf/open/front
	for(var/direction in GLOB.cardinals)
		var/turf/open/side = get_step(hatch, direction)
		if(istype(side) && !chamber[side] && !(locate(/obj/structure/window) in side))
			front = side
	TEST_ASSERT_NOTNULL(front, "Перед шлюзом есть пол зала.")
	var/start_pressure = front.air.return_pressure()
	var/target_fire = SSair.times_fired + ANTAG_TRAINING_ATMOS_SEAL_FIRES
	var/list/budget = new_wait_budget(30 SECONDS, "несколько тиков SSair и пересчёт смежности")
	while((SSair.times_fired < target_fire || adjacency_pending(sector.turfs)) && wait_budget_tick(budget))
		continue
	TEST_ASSERT(SSair.times_fired >= target_fire && !adjacency_pending(sector.turfs), "SSair отработал [ANTAG_TRAINING_ATMOS_SEAL_FIRES] тиков, смежность пересчитана.")
	filled = filled_tiles(chamber)
	TEST_ASSERT(!length(filled), "В вакуумной камере появился воздух: [filled.Join("; ")].")
	var/end_pressure = front.air.return_pressure()
	TEST_ASSERT(abs(end_pressure - start_pressure) < ANTAG_TRAINING_ATMOS_PRESSURE_DRIFT && end_pressure > WARNING_LOW_PRESSURE, "Давление у шлюза держится: было [start_pressure], стало [end_pressure] кПа.")
	var/list/outward = list()
	var/list/breached = list()
	for(var/turf/open/floor in sector.turfs)
		for(var/turf/neighbor as anything in floor.atmos_adjacent_turfs)
			if(!inside[neighbor])
				outward |= "[floor.x],[floor.y] -> [neighbor.x],[neighbor.y]"
			if(chamber[floor] != chamber[neighbor])
				breached |= "[floor.x],[floor.y] -> [neighbor.x],[neighbor.y] [neighbor.type]"
	TEST_ASSERT(!length(outward), "Воздух сектора граничит с клетками снаружи: [outward.Join("; ")].")
	TEST_ASSERT(!length(breached), "Вакуумная камера сообщается с залом: [breached.Join("; ")].")

/datum/unit_test/antag_training_sector_atmos_sealed/proc/filled_tiles(list/turf/open/chamber)
	. = list()
	for(var/turf/open/vacuum_floor as anything in chamber)
		if(vacuum_floor.air.total_moles())
			. += "[vacuum_floor.x],[vacuum_floor.y]"

/datum/unit_test/antag_training_sector_atmos_sealed/proc/adjacency_pending(list/turf/turfs)
	for(var/turf/tile as anything in turfs)
		if(SSadjacent_air.queue[tile])
			return TRUE
	return FALSE

#undef ANTAG_TRAINING_ATMOS_SEAL_FIRES
#undef ANTAG_TRAINING_ATMOS_PRESSURE_DRIFT
