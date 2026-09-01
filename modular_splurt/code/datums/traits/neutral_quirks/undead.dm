//Zombies + Cumplus Fix\\

/datum/quirk/undead
	name = "Не-мёртвый"
	desc = "Ваше тело, будь то аномальное или просто отказывающееся умирать, действительно стало нежитью. Из-за этого вы испытываете сильный голод."
	value = 2
	mob_trait = TRAIT_UNDEAD
	processing_quirk = TRUE
	// Note: The Undead cannot take advantage of healing viruses and genetic mutations, since they have no DNA.
	var/list/zperks = list(
		TRAIT_STABLEHEART, TRAIT_EASYDISMEMBER,
		TRAIT_VIRUSIMMUNE, TRAIT_RADIMMUNE,
		TRAIT_FAKEDEATH, TRAIT_NOSOFTCRIT,
		TRAIT_NOPULSE, TRAIT_NOBREATH
		)

/datum/quirk/undead/add()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	if(H.mob_biotypes == MOB_ROBOTIC)
		return FALSE //Lol, lmao, even
	H.mob_biotypes |= MOB_UNDEAD
	for(var/A = 1, A <= zperks.len, A++)
		ADD_TRAIT(H, zperks[A], ROUNDSTART_TRAIT)
	if(H.physiology)
		H.physiology.hunger_mod *= 1.8
		H.physiology.thirst_mod *= 1.8

/datum/quirk/undead/remove()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	// BLUEMOON EDIT START - sanity check
	if(!H)
		return
	// BLUEMOON EDIT END
	H.mob_biotypes &= ~MOB_UNDEAD // Забытая тильда приведёт к тому, что игра инвертирует побитовую маску, сделав моба всеми биотипами, кроме undead
	for(var/A = 1, A <= zperks.len, A++)
		REMOVE_TRAIT(H, zperks[A], ROUNDSTART_TRAIT)
	if(H.physiology)
		H.physiology.hunger_mod /= 1.8
		H.physiology.thirst_mod /= 1.8

/datum/quirk/undead/on_process()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	if(!H)
		return
	H.set_screwyhud(SCREWYHUD_HEALTHY)
