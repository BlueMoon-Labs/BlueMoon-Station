/datum/round_event_control/anomaly/anomaly_grav
	name = "Anomaly: Gravitational"
	typepath = /datum/round_event/anomaly/anomaly_grav

	enabled = TRUE // база выключена, подтипы включаются явно
	max_occurrences = 5
	weight = 25
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "This anomaly throws things around."

/datum/round_event/anomaly/anomaly_grav
	start_when = ANOMALY_START_HARMFUL_TIME
	announce_when = ANOMALY_ANNOUNCE_HARMFUL_TIME
	anomaly_path = /obj/effect/anomaly/grav

/datum/round_event_control/anomaly/anomaly_grav/high
	name = "Anomaly: Gravitational (High Intensity)"
	typepath = /datum/round_event/anomaly/anomaly_grav/high
	enabled = TRUE // база выключена, подтипы включаются явно
	weight = 15
	max_occurrences = 1
	earliest_start = 20 MINUTES
	description = "This anomaly has an intense gravitational field, and can disable the gravity generator."

/datum/round_event/anomaly/anomaly_grav/high
	start_when = ANOMALY_START_HARMFUL_TIME
	announce_when = ANOMALY_ANNOUNCE_HARMFUL_TIME
	anomaly_path = /obj/effect/anomaly/grav/high

/datum/round_event/anomaly/anomaly_grav/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("Гравитационная аномалия обнаружена на [ANOMALY_ANNOUNCE_HARMFUL_TEXT] [impact_area.name].", "ВНИМАНИЕ: АНОМАЛИЯ", 'sound/announcer/classic/anomaly/anomaly_grav.ogg')
