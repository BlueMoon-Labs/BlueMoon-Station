/// Нарушитель парковки (порт идеи goonstation "Parking Incident"): где-то в техтоннелях
/// обнаруживается брошенный транспорт со штрафным талоном ЦентКома под "дворником".
/// Без анонса - пасхалка для тех, кто шарится по техам. Гости станции паркуются как попало.
/datum/round_event_control/parking_incident
	name = "Parking Incident"
	typepath = /datum/round_event/parking_incident
	weight = 15
	max_occurrences = 1
	earliest_start = 10 MINUTES
	category = EVENT_CATEGORY_FRIENDLY
	disruption = DIRECTOR_DISRUPTION_AMBIENT
	description = "An abandoned vehicle with a parking ticket appears somewhere in maintenance."

/datum/round_event/parking_incident
	fakeable = FALSE
	/// Пул транспорта: вес - шанс выбора. ATV дополнительно получает ключ рядом.
	var/static/list/vehicle_pool = list(
		/obj/vehicle/ridden/scooter = 25,
		/obj/vehicle/ridden/scooter/skateboard = 20,
		/obj/vehicle/ridden/wheelchair = 20,
		/obj/vehicle/ridden/bicycle = 15,
		/obj/vehicle/ridden/secway = 10,
		/obj/vehicle/ridden/atv = 10,
	)

/datum/round_event/parking_incident/start()
	var/list/turf/candidates = list()
	for(var/area/maintenance_area in GLOB.sortedAreas)
		if(!istype(maintenance_area, /area/maintenance))
			continue
		for(var/turf/open/candidate in maintenance_area)
			if(candidate.density || !is_station_level(candidate.z))
				continue
			var/blocked = FALSE
			for(var/obj/blocker in candidate)
				if(blocker.density)
					blocked = TRUE
					break
			if(!blocked)
				candidates += candidate
			CHECK_TICK

	if(!length(candidates))
		return kill()

	var/turf/parking_spot = pick(candidates)
	var/vehicle_type = pickweight(vehicle_pool.Copy())
	var/obj/vehicle/ridden/abandoned = new vehicle_type(parking_spot)
	if(vehicle_type == /obj/vehicle/ridden/atv)
		new /obj/item/key(parking_spot)

	var/obj/item/paper/ticket = new(parking_spot)
	ticket.name = "штрафной талон"
	ticket.add_raw_text("<b>УВЕДОМЛЕНИЕ О НАРУШЕНИИ ПРАВИЛ ПАРКОВКИ</b><br><br>Транспортное средство размещено в зоне, не предназначенной для стоянки. Владелец задержан патрульной службой Центрального Командования и препровождён для дачи объяснений.<br><br>Транспортное средство подлежит конфискации в пользу нашедшего.<br><br><i>Патрульная служба ЦК, форма 27-П</i>")
	ticket.update_appearance()

	announce_to_ghosts(abandoned)
