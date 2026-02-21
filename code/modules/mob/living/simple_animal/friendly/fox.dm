//Foxxy
/mob/living/simple_animal/pet/fox
	name = "fox"
	desc = "It's a fox."
	icon = 'icons/mob/pets.dmi'
	icon_state = "fox"
	icon_living = "fox"
	icon_dead = "fox_dead"
	speak = list("Ack-Ack","Ack-Ack-Ack-Ackawoooo","Geckers","Awoo","Tchoff")
	speak_emote = list("geckers", "barks")
	emote_hear = list("howls.","barks.")
	emote_see = list("shakes its head.", "shivers.")
	speak_chance = 1
	turns_per_move = 5
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 3)
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	gold_core_spawnable = FRIENDLY_SPAWN
	footstep_type = FOOTSTEP_MOB_CLAW
	var/held_icon = "fox"

	vocal_bark_id = "bullet"
	vocal_speed = 2
	vocal_pitch = 1.6
	vocal_pitch_range = 0.4

/mob/living/simple_animal/pet/fox/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/mob_holder, held_icon)

//Captain fox
/mob/living/simple_animal/pet/fox/Renault
	name = "Renault"
	desc = "Renault, the Captain's trustworthy fox."
	gender = FEMALE
	gold_core_spawnable = NO_SPAWN
	unique_pet = TRUE

/mob/living/simple_animal/pet/syndifox
	name = "Syndi-Fox"
	real_name = "Syndi-Fox" // Intended to hold the name without altering it.
	gender = NEUTER
	mob_biotypes = MOB_ROBOTIC
	blood_volume = 0
	desc = "It's a Cybersun MiniVix robotic model wearing a microsized syndicate MODsuit and a cute little cap. Quite pretty."
	icon = 'modular_bluemoon/icons/mob/smiley_pets.dmi'
	icon_state = "syndifox"
	icon_living = "syndifox"
	icon_dead = "syndifox_dead"
	speak_emote = list("geckers", "barks")
	see_in_dark = 6
	butcher_results = list(/obj/item/reagent_containers/food/snacks/meat/slab = 6)
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'
	melee_damage_lower = 20 //same damage as a carp would make - reference to Paradise Station's Syndifox
	melee_damage_upper = 20
	maxHealth = 100
	health = 100
	response_help_continuous = "pets"
	response_help_simple = "pet"
	response_disarm_continuous = "gently pushes aside"
	response_disarm_simple = "gently push aside"
	response_harm_continuous = "kicks"
	response_harm_simple = "kick"
	faction = list(ROLE_SYNDICATE)
	gold_core_spawnable = FRIENDLY_SPAWN

/mob/living/simple_animal/hostile/tegu
	name = "tegu"
	desc = "That's a tegu."
	icon = 'modular_bluemoon/icons/mob/smiley_pets.dmi'
	icon_state = "tegu"
	icon_living = "tegu"
	icon_dead ="tegu_dead"
	speak_emote = list("hisses")
	emote_see = list("hisses.", "flicks its tongue.")
	health = 20
	maxHealth = 20
	faction = list("Lizard")
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'
	footstep_type = FOOTSTEP_MOB_CLAW
	melee_damage_lower = 16 //They do have a nasty bite
	melee_damage_upper = 16
	response_help_continuous = "pets the"
	response_help_simple = "pet"
	response_disarm_continuous = "rolls over the"
	response_disarm_simple = "roll over"
	response_harm_continuous = "stomps on"
	response_harm_simple = "stomp on"
	pass_flags = PASSTABLE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST|MOB_REPTILE
	gold_core_spawnable = FRIENDLY_SPAWN
	turns_per_move = 10
	stop_automated_movement = TRUE

/mob/living/simple_animal/tegu/entertains_the_hostages //not a hostile, harmless
	name = "Entertains-The-Hostages"
	desc = "Безобидная ящерка синдиката, позволяющая одиноким заключенным не сойти с ума"
	icon = 'modular_bluemoon/icons/mob/smiley_pets.dmi'
	icon_state = "tegu"
	icon_living = "tegu"
	icon_dead ="tegu_dead"
	speak_emote = list("hisses")
	emote_see = list("hisses.", "flicks its tongue.")
	health = 20
	maxHealth = 20
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/weapons/bite.ogg'
	footstep_type = FOOTSTEP_MOB_CLAW
	response_help_continuous = "pets the"
	response_help_simple = "pet"
	response_disarm_continuous = "rolls over the"
	response_disarm_simple = "roll over"
	response_harm_continuous = "stomps on"
	response_harm_simple = "stomp on"
	pass_flags = PASSTABLE
	mob_biotypes = MOB_ORGANIC|MOB_BEAST|MOB_REPTILE
	turns_per_move = 10

/mob/living/simple_animal/pet/fox/fennec
	name = "Red"
	desc = "It's a fennec!"
	icon_state = "fennec"
	icon_living = "fennec"
	icon_dead = "fennec_dead"
	held_icon = "fennec"
	see_in_dark = 10
	vocal_bark_id = "weh"
	vocal_speed = 1.5
	speak_chance = 15
	maxHealth = 50
	health = 50
	gender = MALE
