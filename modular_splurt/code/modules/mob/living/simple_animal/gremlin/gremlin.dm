/mob/living/simple_animal/hostile/gremlin
	icon = 'modular_splurt/icons/mob/gremlin.dmi'

	var/body_color

/mob/living/simple_animal/hostile/gremlin/Initialize(mapload)
	. = ..()
	if(!body_color)
		body_color = pick(list("orange","blue","purple", "green", "crystal"))
	AddElement(/datum/element/mob_holder, "gremlin_[body_color]", alt_worn = icon, inv_slots = mob_size <= MOB_SIZE_SMALL ? (ITEM_SLOT_HEAD | ITEM_SLOT_NECK) : NONE)
	icon_state = "gremlin_[body_color]"
	icon_living = "gremlin_[body_color]"
	icon_dead = "gremlin_[body_color]_dead"
