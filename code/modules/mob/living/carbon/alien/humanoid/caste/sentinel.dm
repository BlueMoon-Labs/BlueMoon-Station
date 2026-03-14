/mob/living/carbon/alien/humanoid/sentinel
	name = "alien sentinel"
	caste = "s"
	maxHealth = 180
	health = 180
	icon_state = "aliens_s"
	meleeSlashHumanPower = 25

/mob/living/carbon/alien/humanoid/sentinel/Initialize(mapload)
	AddAbility(new /obj/effect/proc_holder/alien/sneak)
	. = ..()

/mob/living/carbon/alien/humanoid/sentinel/create_internal_organs()
	internal_organs += new /obj/item/organ/alien/plasmavessel
	internal_organs += new /obj/item/organ/alien/acid
	internal_organs += new /obj/item/organ/alien/neurotoxin
	..()
