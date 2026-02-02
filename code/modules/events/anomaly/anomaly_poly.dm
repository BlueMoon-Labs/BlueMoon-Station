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
