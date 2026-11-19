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

/datum/economy_department/medical/situational_needs()
	. = list()
	var/injured = 0
	var/bloodless = 0
	var/dead = 0
	for(var/mob/living/carbon/human/patient as anything in econ_station_crew_bodies())
		if(patient.stat == DEAD)
			dead++
			continue
		if(patient.getBruteLoss() + patient.getFireLoss() >= ECON_NEEDS_INJURED_DAMAGE)
			injured++
		if(patient.get_blood_id() && patient.blood_volume < BLOOD_VOLUME_SAFE * patient.blood_ratio)
			bloodless++
	if(bloodless)
		.[/datum/supply_pack/medical/bloodpacks] = "Мало крови у [bloodless] чел. на станции"
	if(injured)
		.[/datum/supply_pack/medical/supplies] = "Раненых на станции: [injured]"
		.[/datum/supply_pack/medical/sprays] = "Ожоги и ушибы лечатся спреями быстрее"
	if(dead)
		.[/datum/supply_pack/medical/defibs] = "Погибших на станции: [dead], свежих поднимет дефибриллятор"
		.[/datum/supply_pack/medical/bodybags] = "Погибших на станции: [dead]"

/datum/economy_department/medical/everyday_needs()
	return list(
		/datum/supply_pack/medical/supplies = "Бинты и мази на смену",
		/datum/supply_pack/medical/bloodpacks = "Кровь для операций и раненых",
		/datum/supply_pack/medical/medipen_variety = "Медипены для выездов",
	)
