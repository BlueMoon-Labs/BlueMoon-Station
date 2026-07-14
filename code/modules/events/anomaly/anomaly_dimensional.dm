/datum/round_event_control/anomaly/anomaly_dimensional
	name = "Anomaly: Dimensional"
	typepath = /datum/round_event/anomaly/anomaly_dimensional
	enabled = TRUE // база выключена, подтипы включаются явно
	max_occurrences = 5
	weight = 20
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "This anomaly replaces the materials of the surrounding area."
	admin_setup = list(/datum/event_admin_setup/set_location/anomaly, /datum/event_admin_setup/listed_options/anomaly_dimensional)

/datum/round_event/anomaly/anomaly_dimensional
	start_when = ANOMALY_START_MEDIUM_TIME
	announce_when = ANOMALY_ANNOUNCE_MEDIUM_TIME
	anomaly_path = /obj/effect/anomaly/dimensional
	/// What theme should the anomaly initially apply to the area?
	var/anomaly_theme

/datum/round_event/anomaly/anomaly_dimensional/apply_anomaly_properties(obj/effect/anomaly/dimensional/new_anomaly)
	if (!anomaly_theme)
		return
	new_anomaly.prepare_area(new_theme_path = anomaly_theme)

/datum/round_event/anomaly/anomaly_dimensional/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("Обнаружена вселенская нестабильность на [ANOMALY_ANNOUNCE_MEDIUM_TEXT] [impact_area.name].", "ВНИМАНИЕ: АНОМАЛИЯ", 'sound/announcer/classic/anomaly/anomaly_dimensional.ogg')

/datum/event_admin_setup/listed_options/anomaly_dimensional
	input_text = "Select a dimensional anomaly theme?"
	normal_run_option = "Random Theme"

/datum/event_admin_setup/listed_options/anomaly_dimensional/get_list()
	return subtypesof(/datum/dimension_theme)

/datum/event_admin_setup/listed_options/anomaly_dimensional/apply_to_event(datum/round_event/anomaly/anomaly_dimensional/event)
	event.anomaly_theme = chosen
