/datum/round_event_control/anomaly/anomaly_flux
	name = "Anomaly: Hyper-Energetic Flux"
	typepath = /datum/round_event/anomaly/anomaly_flux

	enabled = TRUE // база выключена, подтипы включаются явно
	min_players = 10
	max_occurrences = 5
	weight = 20
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "This anomaly shocks and explodes."

/datum/round_event/anomaly/anomaly_flux
	start_when = ANOMALY_START_DANGEROUS_TIME
	announce_when = ANOMALY_ANNOUNCE_DANGEROUS_TIME
	anomaly_path = /obj/effect/anomaly/flux

/datum/round_event/anomaly/anomaly_flux/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("Обнаружен гипер-энергетический поток на [ANOMALY_ANNOUNCE_DANGEROUS_TEXT] [impact_area.name].", "ВНИМАНИЕ: АНОМАЛИЯ", 'sound/announcer/classic/anomaly/anomaly_flux.ogg')
