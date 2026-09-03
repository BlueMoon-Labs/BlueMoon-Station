/// Блэкаут грав-генератора (порт с /tg/): станционный генератор мгновенно разряжается,
/// рубильник отщёлкивается. Гравитация не вернётся, пока кто-нибудь не дойдёт до генератора,
/// не включит рубильник обратно и не подождёт полной зарядки - готовая инженерная запарка
/// без единой сломанной детали.
/datum/round_event_control/gravity_generator_blackout
	name = "Gravity Generator Blackout"
	typepath = /datum/round_event/gravity_generator_blackout
	weight = 15
	max_occurrences = 1
	earliest_start = 20 MINUTES
	category = EVENT_CATEGORY_ENGINEERING
	// Невесомость - игрушечный хаос, а не блокирующая авария: чинится одним рубильником
	disruption = DIRECTOR_DISRUPTION_MILD
	// Без живой инженерии станция останется без гравитации до конца раунда
	min_staffing = list(DIRECTOR_DEPT_ENGINEERING = 1)
	description = "The gravity generator instantly discharges; someone has to walk over and restart it."

/datum/round_event_control/gravity_generator_blackout/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	for(var/z_key in GLOB.gravity_generators)
		for(var/obj/machinery/gravity_generator/main/generator in GLOB.gravity_generators[z_key])
			if(is_station_level(generator.z))
				return TRUE
	return FALSE

/datum/round_event/gravity_generator_blackout
	announce_when = 1
	// Втихую в трети случаев (как у tg): пусть иногда экипаж сам гадает, почему все взлетели
	announce_chance = 65
	fakeable = FALSE

/datum/round_event/gravity_generator_blackout/announce(fake)
	priority_announce("В вашем секторе зафиксированы грависферные возмущения. Ожидается сбой генераторов гравитации. Рекомендуем экипажу проверить состояние станционного генератора.", "Служба Контроля Гравитации")

/datum/round_event/gravity_generator_blackout/start()
	// GLOB.gravity_generators ключуется текстом z-уровня и содержит только включённые
	// генераторы (см. update_list). blackout() выключает генератор и тем самым выбрасывает
	// его из этого же списка, поэтому сначала собираем жертв, потом гасим.
	var/list/obj/machinery/gravity_generator/main/victims = list()
	for(var/z_key in GLOB.gravity_generators)
		for(var/obj/machinery/gravity_generator/main/generator in GLOB.gravity_generators[z_key])
			if(!is_station_level(generator.z))
				continue
			victims |= generator
	for(var/obj/machinery/gravity_generator/main/generator as anything in victims)
		generator.blackout()
		CHECK_TICK
