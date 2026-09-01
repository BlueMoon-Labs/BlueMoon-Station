/datum/round_event_control/anomaly/anomaly_pyro
	name = "Anomaly: Pyroclastic"
	typepath = /datum/round_event/anomaly/anomaly_pyro

	enabled = TRUE // база выключена, подтипы включаются явно
	max_occurrences = 5
	weight = 20
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "This anomaly sets things on fire, and creates a pyroclastic slime."

/datum/round_event/anomaly/anomaly_pyro
	start_when = ANOMALY_START_HARMFUL_TIME
	announce_when = ANOMALY_ANNOUNCE_HARMFUL_TIME
	anomaly_path = /obj/effect/anomaly/pyro

/datum/round_event/anomaly/anomaly_pyro/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("Пирокластическая аномалия обнаружена на [ANOMALY_ANNOUNCE_HARMFUL_TEXT] [impact_area.name].", "ВНИМАНИЕ: АНОМАЛИЯ", 'sound/announcer/classic/anomaly/anomaly_pyro.ogg')
