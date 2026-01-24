/mob/living/simple_animal/pet/dog/corgi/moth
	name = "Moth"
	real_name = "moth"
	desc = "Становится понятно, куда пропали шубы, перевозимые СССП."
	icon = 'icons/mob/animal.dmi'
	icon_state = "moth"
	icon_living = "moth"
	icon_dead = "moth_dead"
	turns_per_move = 1
	speak = list("Furrr.","Uhh.", "Hurrr.")
	emote_see = list("flutters")
	response_help_continuous = "shoos"
	response_disarm_continuous = "brushes aside"
	response_harm_continuous = "squashes"
	response_help_simple = "shoos"
	response_disarm_simple = "brushes aside"
	response_harm_simple = "squashes"
	speak_chance = 0
	maxHealth = 15
	health = 15
	see_in_dark = 100
	density = FALSE
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	mob_size = MOB_SIZE_TINY
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/xeno = 1)
	gold_core_spawnable = FRIENDLY_SPAWN

/mob/living/simple_animal/pet/dog/corgi/mothroach
	name = "Mothroach"
	real_name = "mothroach"
	desc = "Мотылёк. Обожает светочи."
	icon = 'icons/mob/pets.dmi'
	icon_state = "mothroach"
	icon_living = "mothroach"
	icon_dead = "mothroach_dead"
	speak = list("Furrr.","Uhh.", "Hurrr.")
	speak_chance = 0
	speak_emote = list("chitters")
	response_help_continuous = "pets"
	response_disarm_continuous = "bops"
	response_harm_continuous = "kicks"
	response_help_simple = "shoos"
	response_disarm_simple = "brushes aside"
	response_harm_simple = "squashes"
	faction = list("neutral")
	maxHealth = 15
	health = 15
	see_in_dark = 30
	turns_per_move = 10
	emote_see = list("flutters")
	density = FALSE
	gold_core_spawnable = FRIENDLY_SPAWN
	footstep_type = FOOTSTEP_MOB_BAREFOOT
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab/xeno = 1)
