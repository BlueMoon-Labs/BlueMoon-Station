/datum/round_event_control/bruh_moment
	name = "Bruh Moment"
	typepath = /datum/round_event/bruh_moment
	weight = 10
	min_players = 1
	enabled = FALSE
	category = EVENT_CATEGORY_FRIENDLY
	severity = DIRECTOR_SEVERITY_MINOR

/datum/round_event/bruh_moment
	start_when = 8
	fakeable = FALSE

/datum/round_event/bruh_moment/start()
	for(var/mob/B in shuffle(GLOB.alive_mob_list))
		B.emote("bruh")
		sleep(0.2)

/datum/round_event/bruh_moment/announce()
	priority_announce("Central Command authorise Bruh Moment inbound. Please stand by.", "Bruhspace Anomaly")
