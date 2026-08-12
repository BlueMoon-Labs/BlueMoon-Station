/datum/round_event_control/anomaly/anomaly_bluespace
	name = "Anomaly: Bluespace"
	typepath = /datum/round_event/anomaly/anomaly_bluespace
	enabled = TRUE // база выключена, подтипы включаются явно
	weight = 15
	max_occurrences = 1
	earliest_start = 20 MINUTES
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "This anomaly randomly teleports all items and mobs in a large area."

/datum/round_event/anomaly/anomaly_bluespace
	start_when = ANOMALY_START_MEDIUM_TIME
	announce_when = ANOMALY_ANNOUNCE_MEDIUM_TIME
	anomaly_path = /obj/effect/anomaly/bluespace

/datum/round_event/anomaly/anomaly_bluespace/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("Нестабильная блюспейс аномалия обнаружена на [ANOMALY_ANNOUNCE_MEDIUM_TEXT] [impact_area.name].", "ВНИМАНИЕ: АНОМАЛИЯ", 'sound/announcer/classic/anomaly/anomaly_bluespace.ogg')
