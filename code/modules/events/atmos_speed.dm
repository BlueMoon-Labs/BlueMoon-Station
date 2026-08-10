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
	/// Тик события - это проход SSdirector, то есть DIRECTOR_WAIT = 2 секунды
	/// (см. комментарий к activeFor в _event.dm). 600 тиков - это двадцать минут
	/// учетверённого SSair, а не заявленная в description минута: в раунде 9872
	/// событие подняло стоимость фазы турфов с 55.7 до 205.6 мс и держало её до
	/// конца смены, потому что раунд кончился раньше события.
	end_when = 30
	/// Speed the operator configured, handed back when the flux passes.
	var/original_speed = 1
	/// Decided in start(), so the station-wide announcement cannot describe a
	/// direction the subsystem did not take.
	var/speeding_up = TRUE

/datum/round_event/atmos_flux/announce(fake)
	priority_announce("Обнаружен аномальный атмосферный поток в вашем секторе. Датчики показывают, что воздух может перемещаться [speeding_up ? "быстрее" : "медленней"], чем обычно.", "Атмосферная Тревога")

/datum/round_event/atmos_flux/start()
	original_speed = SSair.atmos_speed
	speeding_up = !prob(20)
	SSair.set_atmos_speed(speeding_up ? (original_speed * rand(2, 4)) : (original_speed * 0.5))

/datum/round_event/atmos_flux/end()
	SSair.set_atmos_speed(original_speed)
