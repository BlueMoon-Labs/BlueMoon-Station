/mob/living/carbon/alien/humanoid/sentinel
	name = "alien sentinel"
	caste = "s"
	maxHealth = 180
	health = 180
	icon = 'icons/Xeno/castes/sentinel.dmi'
	icon_state = "Sentinel Walking"
	meleeSlashHumanPower = 25
	pixel_x = -11

/datum/movespeed_modifier/alien_sentinel_speed
	multiplicative_slowdown = 0.2

/mob/living/carbon/alien/humanoid/sentinel/Initialize(mapload)
	AddAbility(new /obj/effect/proc_holder/alien/sneak)
	. = ..()
	add_movespeed_modifier(/datum/movespeed_modifier/alien_sentinel_speed)

/mob/living/carbon/alien/humanoid/sentinel/create_internal_organs()
	internal_organs += new /obj/item/organ/alien/plasmavessel
	internal_organs += new /obj/item/organ/alien/acid
	internal_organs += new /obj/item/organ/alien/neurotoxin
	..()
