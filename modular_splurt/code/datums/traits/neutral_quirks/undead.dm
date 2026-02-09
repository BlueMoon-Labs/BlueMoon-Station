//Zombies + Cumplus Fix\\

/datum/quirk/undead
	name = "Не-мёртвый"
	desc = "Ваше тело, будь то аномальное или просто отказывающееся умирать, действительно стало нежитью. Из-за этого вы испытываете сильный голод."
	value = 2
	mob_trait = TRAIT_UNDEAD
	processing_quirk = TRUE
	// Note: The Undead cannot take advantage of healing viruses and genetic mutations, since they have no DNA.
	var/list/zperks = list(TRAIT_STABLEHEART,TRAIT_EASYDISMEMBER,TRAIT_VIRUSIMMUNE,TRAIT_RADIMMUNE,TRAIT_FAKEDEATH,TRAIT_NOSOFTCRIT, TRAIT_NOPULSE)

/datum/quirk/undead/add()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	if(H.mob_biotypes == MOB_ROBOTIC)
		return FALSE //Lol, lmao, even
	H.mob_biotypes |= MOB_UNDEAD
	for(var/A = 1, A <= zperks.len, A++)
		ADD_TRAIT(H,zperks[A],ROUNDSTART_TRAIT)

/datum/quirk/undead/remove()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	// BLUEMOON EDIT START - sanity check
	if(!H)
		return
	// BLUEMOON EDIT END
	H.mob_biotypes &= MOB_UNDEAD
	for(var/A = 1, A <= zperks.len, A++)
		REMOVE_TRAIT(H,zperks[A], ROUNDSTART_TRAIT)

/datum/quirk/undead/on_process()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	H.adjust_nutrition(-0.025)
	H.adjust_thirst(-0.025)
	H.set_screwyhud(SCREWYHUD_HEALTHY)
	H.adjustOxyLoss(-3) //Stops a defibrilator bug. Note to future self: Fix defib bug.
