/mob/living/simple_animal/pet/dog/corgi/pig
	name = "Pig"
	real_name = "Pig"
	desc = "Хрюкает."
	icon = 'icons/mob/animal.dmi'
	icon_state = "pig"
	icon_living = "pig"
	icon_dead = "pig_dead"
	speak = list("ХРЮ!","УИИИИ!","ХРЮ?")
	speak_emote = list("хрюкает")
	emote_hear = list("хрюкает.")
	emote_see = list("хрюкает.")
	speak_chance = 5
	turns_per_move = 1
	see_in_dark = 3
	maxHealth = 50
	health = 50
	damaged_sound = list('modular_bluemoon/sound/creatures/pig/oink.ogg')
	deathsound = 'modular_bluemoon/sound/creatures/pig/death.ogg'
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/pig = 6)
	density = TRUE
	mob_size = MOB_SIZE_LARGE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST
	gold_core_spawnable = FRIENDLY_SPAWN
	held_icon = "pig"
	faction = list("neutral")
	talk_sound = list('modular_bluemoon/sound/creatures/pig/hru.ogg', 'modular_bluemoon/sound/creatures/pig/oink.ogg', 'modular_bluemoon/sound/creatures/pig/squeak.ogg')
	damaged_sound = list('modular_bluemoon/sound/creatures/pig/hru.ogg', 'modular_bluemoon/sound/creatures/pig/oink.ogg', 'modular_bluemoon/sound/creatures/pig/squeak.ogg')

/mob/living/simple_animal/pet/dog/corgi/pig/Initialize(mapload)
	. = ..()
	if(prob(1))
		name = "Randy Sandy"
		desc = "<big>Самый жирный боров.</big>"
		maxHealth = 500
		health = 500

/mob/living/simple_animal/pet/dog/corgi/pig/Life()
	..()
	if(stat)
		return
	if(prob(25))
		var/chosen_sound = pick('modular_bluemoon/sound/creatures/pig/hru.ogg', 'modular_bluemoon/sound/creatures/pig/oink.ogg', 'modular_bluemoon/sound/creatures/pig/squeak.ogg')
		playsound(src, chosen_sound, 50, TRUE)

/mob/living/simple_animal/pet/dog/corgi/pig/update_corgi_fluff()
	name = real_name
	desc = initial(desc)
	speak = list("ХРЮ!","УИИИИ!","ХРЮ?")
	speak_emote = list("хрюкает")
	emote_hear = list("хрюкает!")
	emote_see = list("хрюкает гениально")
	set_light(0)

	if(inventory_head?.dog_fashion)
		var/datum/dog_fashion/DF = new inventory_head.dog_fashion(src)
		DF.apply(src)

	if(inventory_back?.dog_fashion)
		var/datum/dog_fashion/DF = new inventory_back.dog_fashion(src)
		DF.apply(src)

/obj/item/reagent_containers/food/snacks/meat/slab/pig
	name = "Сало"
	icon_state = "salo"
	cooked_type = /obj/item/reagent_containers/food/snacks/meat/steak/plain/pig
	slice_path = /obj/item/reagent_containers/food/snacks/meat/rawcutlet/plain/salo
	tastes = list("pig meat" = 1)
	foodtype = MEAT

/obj/item/reagent_containers/food/snacks/meat/slab/pig/On_Consume(mob/living/carbon/human/eater)
	. = ..()
	eater.add_quirk(/datum/quirk/ukraine)

/obj/item/reagent_containers/food/snacks/meat/rawcutlet/plain/salo
	name = "Кусочек Сала"
	icon_state = "salo_slice"

/obj/item/reagent_containers/food/snacks/meat/rawcutlet/plain/salo/On_Consume(mob/living/carbon/human/eater)
	. = ..()
	eater.add_quirk(/datum/quirk/ukraine)

/obj/item/reagent_containers/food/snacks/meat/steak/plain/pig/On_Consume(mob/living/carbon/human/eater)
	. = ..()
	eater.add_quirk(/datum/quirk/ukraine)
