/datum/round_event_control/anomaly/anomaly_vortex
	name = "Anomaly: Vortex"
	typepath = /datum/round_event/anomaly/anomaly_vortex

	enabled = TRUE // база выключена, подтипы включаются явно
	min_players = 20
	max_occurrences = 2
	weight = 10
	// Дефолт категории ANOMALIES - MAJOR (cost 20): вихрь злее собратьев, но это всё та же
	// одиночная локальная аномалия с громким анонсом - цена среднего, как у пирокластики.
	severity = DIRECTOR_SEVERITY_MODERATE
	description = "This anomaly sucks in and detonates items."

/datum/round_event/anomaly/anomaly_vortex
	start_when = ANOMALY_START_DANGEROUS_TIME
	announce_when = ANOMALY_ANNOUNCE_DANGEROUS_TIME
	anomaly_path = /obj/effect/anomaly/bhole

/datum/round_event/anomaly/anomaly_vortex/announce(fake)
	if(isnull(impact_area))
		impact_area = placer.findValidArea()
	priority_announce("Обнаружена высокоинтенсивная вихревая аномалия на [ANOMALY_ANNOUNCE_DANGEROUS_TEXT] [impact_area.name]", "ВНИМАНИЕ: АНОМАЛИЯ", 'sound/announcer/classic/anomaly/anomaly_vortex.ogg')
