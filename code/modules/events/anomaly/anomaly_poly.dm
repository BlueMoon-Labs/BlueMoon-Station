/datum/round_event_control/anomaly/anomaly_poly
	name = "Anomaly: Polymorph"
	typepath = /datum/round_event/anomaly/anomaly_poly

	max_occurrences = 10
	weight = 25
	description = "This anomaly transforms the appearance of creatures nearby."

/datum/round_event/anomaly/anomaly_poly
	start_when = ANOMALY_START_HARMFUL_TIME
	announce_when = ANOMALY_ANNOUNCE_HARMFUL_TIME
	anomaly_path = /obj/effect/anomaly/poly

/datum/round_event/anomaly/anomaly_poly/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("Аномалия полиморфизма обнаружена на [ANOMALY_ANNOUNCE_HARMFUL_TEXT] [impact_area.name].", "ВНИМАНИЕ: АНОМАЛИЯ", 'sound/announcer/classic/anomaly/anomaly_dimensional.ogg')
