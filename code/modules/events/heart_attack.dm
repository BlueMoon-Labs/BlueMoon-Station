/datum/round_event_control/heart_attack
	name = "Random Heart Attack"
	typepath = /datum/round_event/heart_attack
	weight = 50
	max_occurrences = 5
	min_players = 35 // To avoid shafting lowpop
	category = EVENT_CATEGORY_HEALTH
	severity = DIRECTOR_SEVERITY_MODERATE
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT)

/datum/round_event_control/heart_attack/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	return director_has_living_role(list("Medical Doctor","Chief Medical Officer","Paramedic"))

/datum/round_event/heart_attack/start()
	var/list/heart_attack_contestants = list()
	for(var/mob/living/carbon/human/H in shuffle(GLOB.player_list))
		if(!H.client || H.stat == DEAD || H.InCritical() || !H.can_heartattack() || H.has_status_effect(STATUS_EFFECT_EXERCISED) || (/datum/disease/heart_failure in H.diseases) || H.undergoing_cardiac_arrest() || HAS_TRAIT(H,TRAIT_EXEMPT_HEALTH_EVENTS) || !is_station_level(H.z))
			continue
		if(H.satiety <= -60) //Multiple junk food items recently
			heart_attack_contestants[H] = 3
		else
			heart_attack_contestants[H] = 1

	if(LAZYLEN(heart_attack_contestants))
		var/mob/living/carbon/human/winner = pickweight(heart_attack_contestants)
		var/datum/disease/D = new /datum/disease/heart_failure()
		winner.ForceContractDisease(D, FALSE, TRUE)
		announce_to_ghosts(winner)
