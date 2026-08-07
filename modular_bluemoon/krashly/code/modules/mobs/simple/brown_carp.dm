/mob/living/simple_animal/hostile/carp/brown
	name = "brown space carp"
	desc = "A ferocious, fang-bearing creature that resembles a fish."
	icon = 'modular_bluemoon/krashly/icons/mob/simple_mob/brown_carp.dmi'
	faction = list("carp", "InteQ")

/mob/living/simple_animal/hostile/carp/brown/beret
	name = "brown space carp with beret"
	icon = 'modular_bluemoon/krashly/icons/mob/simple_mob/brown_carp_beret.dmi'

/mob/living/simple_animal/hostile/carp/brown/beret/ComponentInitialize()
	. = ..()
	// Лут смерти декларативно через элемент вместо оверрайда drop_loot()
	AddElement(/datum/element/death_drops, list(
		/obj/item/clothing/suit/armor/inteq/vanguard,
		/obj/item/clothing/head/HoS/inteq_vanguard,
	))
