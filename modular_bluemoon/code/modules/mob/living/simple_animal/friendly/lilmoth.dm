/mob/living/simple_animal/pet/dog/corgi/mothroach/lilmoth
	name = "\improper Lil moth"
	real_name = "Saimon"
	desc = "It's a pretty little moth."
	icon = 'modular_bluemoon/icons/mob/caimon.dmi'
	icon_state = "nude"
	icon_living = "nude"
	icon_dead = "krit"
	held_icon = "caimon"
	maxHealth = 30
	health = 30
	emote_see = list("flutters", "mothes")
	speak = list("*chitter", "*chitter2", "*spin", "*flap", "*flip")
	emote_hear = list( "жужжит!", "хлопает крыльями.")
	unique_pet = TRUE
	gender = FEMALE
	vocal_bark_id = "moff"
	speak_chance = 20
	gold_core_spawnable = null
	loot = list(/obj/effect/gibspawner/generic/animal/lilmoth)

/obj/effect/gibspawner/generic/animal/lilmoth
	gibtypes = list(/obj/effect/decal/cleanable/blood/gibs/lilmoth)

/obj/effect/decal/cleanable/blood/gibs/lilmoth
	icon = 'modular_bluemoon/icons/mob/caimon.dmi'
	icon_state = "dead"

/mob/living/simple_animal/pet/dog/corgi/mothroach/lilmoth/dressed
	icon_state = "weared"
	icon_living = "weared"
	icon_dead = "weared_krit"
	desc = "It's a pretty little moth with a funny hat."
	held_icon = "dressed_caimon"

/mob/living/simple_animal/pet/dog/corgi/mothroach/lilmoth/ComponentInitialize()
	. = ..()
	RemoveElement(/datum/element/wuv, "yaps happily!", EMOTE_AUDIBLE, /datum/mood_event/pet_animal, "growls!", EMOTE_AUDIBLE)
	RemoveElement(/datum/element/strippable, GLOB.strippable_corgi_items)
	RemoveElement(/datum/element/mob_holder, held_icon)
	AddElement(/datum/element/wuv, "mothin'!", EMOTE_AUDIBLE, /datum/mood_event/pet_animal, "buzzes!", EMOTE_AUDIBLE)
	AddElement(/datum/element/mob_holder, held_icon, inv_slots = ITEM_SLOT_HEAD)
