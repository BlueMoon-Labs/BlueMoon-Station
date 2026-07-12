/datum/round_event_control/space_cleaner_spill
	name = "Scrubber overflow: space cleaner"
	typepath = /datum/round_event/space_cleaner_spill
	// Часть семейства труб: общий фолл-офф и пауза с остальными переливами (см. scrubber_overflow).
	// Метка mild, а не disruptive: мыло станцию моет, а не пачкает, и по договорённости с прода
	// должно выпадать заметно чаще кам-ивентов (примерно два космочиста на один кам).
	// Один раз за раунд: даже мягкая мойка всей станции надоедает при повторе (жалоба прода).
	weight = 25
	max_occurrences = 1
	min_players = 5
	category = EVENT_CATEGORY_JANITORIAL
	family = "scrubbers"
	disruption = DIRECTOR_DISRUPTION_MILD
	description = "Scrubbers and vents spill space cleaner foam."

/datum/round_event/space_cleaner_spill
	announce_when = 1
	start_when = 5
	/// Количество реагента из каждой точки (больше = дальше распространение пены)
	var/reagents_amount = 220
	/// Список скрубберов и вентилей, из которых польётся пена
	var/list/atmos_devices = list()

/datum/round_event/space_cleaner_spill/announce(fake)
	priority_announce("Запущена аварийная очистка космической станции. Из части скрубберов и вентиляций будет подана моющая пена.", "ВНИМАНИЕ: АТМОСФЕРА", 'sound/announcer/classic/ventclog.ogg')

/datum/round_event/space_cleaner_spill/setup()
	// Собираем скрубберы
	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/temp_vent in GLOB.machines)
		var/turf/vent_turf = get_turf(temp_vent)
		if(!vent_turf)
			continue
		if(!is_station_level(vent_turf.z))
			continue
		if(temp_vent.welded)
			continue
		atmos_devices += temp_vent

	// Собираем вентили (vent_pump)
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in GLOB.machines)
		var/turf/vent_turf = get_turf(temp_vent)
		if(!vent_turf)
			continue
		if(!is_station_level(vent_turf.z))
			continue
		if(temp_vent.welded)
			continue
		atmos_devices += temp_vent

	if(!atmos_devices.len)
		return kill()

/datum/round_event_control/space_cleaner_spill/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	for(var/obj/machinery/atmospherics/components/unary/vent_scrubber/temp_vent in GLOB.machines)
		var/turf/vent_turf = get_turf(temp_vent)
		if(!vent_turf || !is_station_level(vent_turf.z) || temp_vent.welded)
			continue
		return TRUE
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in GLOB.machines)
		var/turf/vent_turf = get_turf(temp_vent)
		if(!vent_turf || !is_station_level(vent_turf.z) || temp_vent.welded)
			continue
		return TRUE
	return FALSE

/datum/round_event/space_cleaner_spill/start()
	for(var/obj/machinery/atmospherics/components/unary/vent as anything in atmos_devices)
		if(!vent.loc)
			continue

		var/datum/reagents/dispensed_reagent = new /datum/reagents(reagents_amount)
		dispensed_reagent.my_atom = vent
		// Мягкий очиститель: смывает грязь и кровь, но не рисунки крайонов и не покраску
		// спрейканами - ивент не должен уничтожать оформление, сделанное игроками (жалоба прода).
		dispensed_reagent.add_reagent(/datum/reagent/space_cleaner/gentle, reagents_amount)
		dispensed_reagent.create_foam(/datum/effect_system/foam_spread/short, reagents_amount)

		CHECK_TICK
