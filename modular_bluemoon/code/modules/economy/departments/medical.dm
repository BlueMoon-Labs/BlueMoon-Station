/datum/economy_department/medical
	id = ACCOUNT_MED
	name = "Медицина"
	budget_name = "бюджет медицины"
	head_access = list(ACCESS_CMO)

/datum/economy_department/medical/spending_advice()
	return list(
		"Кровь, бинты и мази кончаются первыми: держите запас до того, как привезут раненых.",
		"Хирургия и реанимация оплачиваются отделу, им нужны инструменты и дефибрилляторы.",
	)

/// Только то, что видно на мониторе экипажа: смерть - датчиками от SENSOR_LIVING, раны и кровь - от SENSOR_VITALS.
/datum/economy_department/medical/situational_needs()
	. = list()
	var/injured = 0
	var/bloodless = 0
	var/revivable = 0
	var/loose_bodies = 0
	var/obj/item/shockpaddles/paddles = /obj/item/shockpaddles
	var/defib_limit = initial(paddles.tlimit)
	for(var/mob/living/carbon/human/patient as anything in econ_station_crew_bodies())
		var/sensors = econ_sensor_level(patient)
		if(sensors < SENSOR_LIVING)
			continue
		if(patient.stat == DEAD)
			if(world.time - patient.timeofdeath <= defib_limit)
				revivable++
			if(!econ_body_stored(patient))
				loose_bodies++
			continue
		if(sensors < SENSOR_VITALS)
			continue
		if(patient.getBruteLoss() + patient.getFireLoss() >= ECON_NEEDS_INJURED_DAMAGE)
			injured++
		if(patient.get_blood_id() && patient.blood_volume < BLOOD_VOLUME_SAFE * patient.blood_ratio)
			bloodless++
	if(bloodless)
		.[/datum/supply_pack/medical/bloodpacks] = "Мало крови у [bloodless] чел. по датчикам костюмов"
	if(injured)
		.[/datum/supply_pack/medical/supplies] = "Раненых на станции: [injured]"
		.[/datum/supply_pack/medical/sprays] = "Ожоги и ушибы лечатся спреями быстрее"
	if(revivable)
		.[/datum/supply_pack/medical/defibs] = "Погибших недавно: [revivable], дефибриллятор ещё может их поднять"
	if(loose_bodies)
		.[/datum/supply_pack/medical/bodybags] = "Тел вне морга и мешков: [loose_bodies]"

/datum/economy_department/medical/sensor_needs()
	return situational_needs()

/// Тело уже убрано: в мешке, в ячейке морга или в самом морге.
/proc/econ_body_stored(mob/living/body)
	return istype(body.loc, /obj/structure/closet/body_bag) || istype(body.loc, /obj/structure/bodycontainer) || istype(get_area(body), /area/medical/morgue)

/datum/economy_department/medical/everyday_needs()
	return list(
		/datum/supply_pack/medical/supplies = "Бинты и мази на смену",
		/datum/supply_pack/medical/bloodpacks = "Кровь для операций и раненых",
		/datum/supply_pack/medical/medipen_variety = "Медипены для выездов",
	)
