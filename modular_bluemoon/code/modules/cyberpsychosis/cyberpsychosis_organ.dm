
/obj/item/organ/cyberimp
	var/cyber_load = 1

/obj/item/organ/cyberimp/brain/ai_link
	cyber_load = 5 //ты буквально с ИИ сооеденяешся, почти ряхнулся, чумба?

/obj/item/organ/cyberimp/brain/anti_drop
	cyber_load = 3

/obj/item/organ/cyberimp/brain/anti_stun
	cyber_load = 3

/obj/item/organ/cyberimp/arm/clockwork/claw
	cyber_load = 1 //всё же культовский имплант

/obj/item/organ/cyberimp/arm/medibeam
	cyber_load = 2

/obj/item/organ/cyberimp/arm/toolset
	cyber_load = 1

/obj/item/organ/cyberimp/arm/surgery
	cyber_load = 1

/obj/item/organ/cyberimp/arm/janitor
	cyber_load = 1

/obj/item/organ/cyberimp/arm/service
	cyber_load = 1

/obj/item/organ/cyberimp/arm/flash
	cyber_load = 2

/obj/item/organ/cyberimp/arm/baton
	cyber_load = 2

/obj/item/organ/cyberimp/arm/power_cord
	cyber_load = 0

/obj/item/organ/cyberimp/arm/claws
	cyber_load = 0

/obj/item/organ/cyberimp/arm/razor_claws
	cyber_load = 1

/obj/item/organ/cyberimp/chest/reviver
	cyber_load = 2

/obj/item/organ/cyberimp/chest/healer
	cyber_load = 2

/obj/item/organ/cyberimp/chest/thrusters
	cyber_load = 2

/obj/item/organ/cyberimp/chest/nutriment/plus
	cyber_load = 1

/obj/item/organ/cyberimp/arm/gun
	cyber_load = 3

/obj/item/organ/cyberimp/arm/combat
	cyber_load = 3

/obj/item/organ/cyberimp/arm/esword
	cyber_load = 3

/obj/item/organ/cyberimp/arm/shield
	cyber_load = 2

/obj/item/organ/cyberimp/arm/mantis_blade
	cyber_load = 3

/obj/item/organ/cyberimp/chest/chem_implant
	cyber_load = 3

/obj/item/organ/cyberimp/brain/nif
	cyber_load = 3


/obj/item/organ/Insert(mob/living/carbon/M, special = 0, drop_if_replaced = TRUE)
	. = ..()
	if(. && ishuman(M))
		var/mob/living/carbon/human/H = M
		H.update_cyberpsychosis(TRUE)

/obj/item/organ/Remove(special = FALSE)
	var/mob/living/carbon/saved_owner = owner
	. = ..()
	if(saved_owner && ishuman(saved_owner))
		var/mob/living/carbon/human/H = saved_owner
		H.update_cyberpsychosis(FALSE)

/mob/living/carbon/human
	var/datum/cyberpsychosis/cyberpsychosis

/mob/living/carbon/human/proc/update_cyberpsychosis(alert = TRUE)
	if(QDELETED(src))
		return
	var/load = 0
	for(var/obj/item/organ/cyberimp/CO in internal_organs)
		if(CO.status == ORGAN_ROBOTIC)
			load += CO.cyber_load
	if(!cyberpsychosis)
		if(load <= 0)
			return
		cyberpsychosis = new /datum/cyberpsychosis(src)
	if(QDELETED(cyberpsychosis))
		cyberpsychosis = null
		return
	cyberpsychosis.update_stage(alert, load)
	if(cyberpsychosis.stage != CYBERPSYCHOSIS_TIER_NONE)
		START_PROCESSING(SSobj, cyberpsychosis)
