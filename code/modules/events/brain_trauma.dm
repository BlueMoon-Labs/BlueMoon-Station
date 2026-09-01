/datum/round_event_control/brain_trauma
	name = "Spontaneous Brain Trauma"
	typepath = /datum/round_event/brain_trauma
	weight = 60
	min_players = 10
	category = EVENT_CATEGORY_HEALTH
	severity = DIRECTOR_SEVERITY_MINOR
	required_round_type = list(ROUNDTYPE_DYNAMIC_TEAMBASED, ROUNDTYPE_DYNAMIC_HARD, ROUNDTYPE_DYNAMIC_MEDIUM, ROUNDTYPE_DYNAMIC_LIGHT)

/datum/round_event_control/brain_trauma/can_fire(datum/director_signals/signals)
	. = ..()
	if(!.)
		return
	return director_has_living_role(list("Medical Doctor","Chief Medical Officer","Paramedic","Chemist","Virologist"))

/datum/round_event/brain_trauma
	fakeable = FALSE

/datum/round_event/brain_trauma/start()
	for(var/mob/living/carbon/human/H in shuffle(GLOB.alive_mob_list))
		if(!H.client)
			continue
		if(H.stat == DEAD) // What are you doing in this list
			continue
		if(!H.getorgan(/obj/item/organ/brain)) // If only I had a brain
			continue
		if(HAS_TRAIT(H,TRAIT_EXEMPT_HEALTH_EVENTS))
			continue
		if(!is_station_level(H.z))
			continue
		traumatize(H)
		announce_to_ghosts(H)
		break

/datum/round_event/brain_trauma/proc/traumatize(mob/living/carbon/human/H)
	var/resistance = pick(
		65;TRAUMA_RESILIENCE_BASIC,
		35;TRAUMA_RESILIENCE_SURGERY)

	var/trauma_type = pickweight(list(
		BRAIN_TRAUMA_MILD = 80,
		BRAIN_TRAUMA_SEVERE = 10,
		BRAIN_TRAUMA_SPECIAL = 10
	))

	H.gain_trauma_type(trauma_type, resistance)
	to_chat(H, span_userdanger(pick("ЧТО-ТО ДАВИТ НА МОЙ ЧЕРЕП!", "ГОЛОВА РАСКАЛЫВАЕТСЯ!", "ГОЛОВУ ЗАПОЛНЯЕТ БОЛЬ!")))
	H.DefaultCombatKnockdown(150)
	H.Stun(20)
	H.blind_eyes(10)
	H.dizziness += 50
	H.confused += 10
	H.stuttering += 15
