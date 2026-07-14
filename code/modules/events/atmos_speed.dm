/datum/round_event_control/atmos_flux
	name = "Atmospheric Flux"
	typepath = /datum/round_event/atmos_flux
	max_occurrences = 5
	weight = 10
	category = EVENT_CATEGORY_ENGINEERING
	min_staffing = list(DIRECTOR_DEPT_ENGINEERING = 1)
	description = "Modifies the speed of the SSair randomly, ends after one minute."

/datum/round_event/atmos_flux
	announce_when = 1
	end_when = 600
	var/original_speed

/datum/round_event/atmos_flux/announce(fake)
	priority_announce("Обнаружен аномальный атмосферный поток в вашем секторе. Датчики показывают, что воздух может перемещаться [(SSair.share_max_steps_target > original_speed) ? "быстрее" : "медленней"], чем обычно.", "Атмосферная Тревога")

/datum/round_event/atmos_flux/start()
	original_speed = SSair.share_max_steps_target
	if(prob(20))
		SSair.share_max_steps_target = max(1, original_speed - rand(1,original_speed-1))
	else
		SSair.share_max_steps_target += rand(2,10)

/datum/round_event/atmos_flux/end()
	SSair.share_max_steps_target = original_speed
