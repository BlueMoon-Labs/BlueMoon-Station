/datum/weather/ash_storm/mesa_sandstorm
	parent_type = /datum/weather/particle
	name = "sandstorm"
	desc = "A localized sandstorm is kicking up dust across the surface."

	particle_type = /particles/weather/ash_storm
	emissive_type = /particles/weather/ash_storm/embers
	min_severity = 60
	optimal_severity = 80
	wind_sign = -1

	telegraph_message = "<span class='boldwarning'>Ветер усиливается, поднимая тучи песка с поверхности.</span>"
	telegraph_duration = 300

	weather_message = "<span class='userdanger'><i>Песчаная буря охватила сектор!</i></span>"

	end_message = "<span class='boldannounce'>Ветер стихает, и песок оседает на землю.</span>"
	end_duration = 300

	aesthetic = TRUE
	probability = 0

	weather_duration_lower = 1800
	weather_duration_upper = 3600

	area_type = /area/awaymission/ihategordon/outsideofmesa
	protect_indoors = TRUE
	protected_areas = list(/area/awaymission/ihategordon/rocks, /area/awaymission/ihategordon/outsideofmesa/restricted_zone)

/datum/weather/ash_storm/mesa_sandstorm/start()
	. = ..()
	if(SSblackmesa_events)
		SSblackmesa_events.mesa_announce("Внимание! В Секторе H началась интенсивная песчаная буря. Рекомендуется укрыться в помещениях!", "Sandstorm Warning", 'modular_bluemoon/sound/ambience/mesa/BMAS2.ogg')
