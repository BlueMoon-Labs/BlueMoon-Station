

/mob/living/simple_animal/friendly/gaslamp
	name = "gaslamp"
	desc = "Some sort of floaty alien with a warm glow. This creature is endemic to Virgo-3B."

	icon_state = "gaslamp"
	icon_living = "gaslamp"
	icon_dead = "gaslamp_dead"
	icon = 'modular_bluemoon/icons/mob/gaslamp.dmi'

	maxHealth = 100
	health = 100


	melee_damage_lower = 15
	melee_damage_upper = 15

	response_help_simple = "brushes"
	response_disarm_simple = "pushes"
	response_harm_simple   = "swats"

	minbodytemp = 0
	maxbodytemp = 350

/mob/living/simple_animal/friendly/gaslamp/update_mobility()
	. = ..()
	if(client && stat != DEAD)
		if(!CHECK_MOBILITY(src, MOBILITY_STAND))
			icon_state = "[icon_living]_rest"
		else
			icon_state = "[icon_living]"
	regenerate_icons()

/mob/living/simple_animal/friendly/gaslamp/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/mob_holder, worn_state = icon_state, inv_slots = mob_size <= MOB_SIZE_SMALL ? (ITEM_SLOT_HEAD | ITEM_SLOT_NECK) : NONE)
