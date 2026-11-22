/////////////////Brute///////////////
/mob/living/simple_animal/hostile/brute
	name = "Brute"
	real_name = "Brute"
	icon = 'modular_bluemoon/icons/mob/64x64necros.dmi'
	desc = "A massive, armored necromorph. Seems that he likes you."
	icon_state = "brute"
	icon_living = "brute"
	maxHealth = 500
	health = 500
	response_harm_continuous = "harmlessly punches"
	response_harm_simple = "harmlessly punch"
	harm_intent_damage = 0
	obj_damage = 60
	melee_damage_lower = 35
	melee_damage_upper = 40
	attack_verb_continuous = "smashes their armored gauntlet into"
	attack_verb_simple = "smash your armored gauntlet into"
	speed = 0.7
	environment_smash = ENVIRONMENT_SMASH_WALLS
	attack_sound = 'modular_bluemoon/sound/creatures/necros/brute_attack_3.ogg'
	status_flags = 0
	mob_size = MOB_SIZE_LARGE
	force_threshold = 10
	AIStatus = AI_ON
	loot = list(/obj/effect/gibspawner/xeno/bodypartless, /obj/effect/gibspawner/generic, /obj/effect/gibspawner/generic/animal, /obj/effect/gibspawner/human/bodypartless, /obj/effect/gibspawner/human)

/////////////////Leaper///////////////
/mob/living/simple_animal/hostile/brute/leaper
	name = "Leaper"
	real_name = "Leaper"
	icon = 'modular_bluemoon/icons/mob/64x64necros.dmi'
	desc = "Better run through the station."
	icon_state = "leaper"
	icon_living = "leaper"
	maxHealth = 100
	health = 100
	obj_damage = 10
	melee_damage_lower = 10
	melee_damage_upper = 18
	attack_verb_continuous = "smashes into"
	attack_verb_simple = "smash into"
	speed = 2.5
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_sound = 'modular_bluemoon/sound/creatures/necros/leaper_attack_5.ogg'
	mob_size = MOB_SIZE_HUMAN

/////////////////Ubermorph///////////////
/mob/living/simple_animal/hostile/brute/uber
	name = "Ubermorph"
	real_name = "Ubermorph"
	icon = 'modular_bluemoon/icons/mob/64x64necros.dmi'
	desc = "Tick-tick-tick."
	icon_state = "ubermorph"
	icon_living = "ubermorph"
	maxHealth = 250
	health = 250
	obj_damage = 30
	melee_damage_lower = 20
	melee_damage_upper = 30
	attack_verb_continuous = "smashes into"
	attack_verb_simple = "smash into"
	speed = 1.5
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_sound = 'modular_bluemoon/sound/creatures/necros/ubermorph_attack_1.ogg'

/////////////////Grunt///////////////
/mob/living/simple_animal/hostile/grunt
	name = "Necromorph"
	real_name = "Necromorph"
	icon = 'modular_bluemoon/icons/mob/necros.dmi'
	desc = "Hey down there, hugs!"
	icon_state = "alien_s"
	icon_living = "alien_s"
	maxHealth = 100
	health = 100
	response_harm_continuous = "harmlessly punches"
	response_harm_simple = "harmlessly punch"
	harm_intent_damage = 0
	obj_damage = 15
	melee_damage_lower = 15
	melee_damage_upper = 25
	attack_verb_continuous = "claws"
	attack_verb_simple = "claws"
	speed = 1
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_sound = 'modular_bluemoon/sound/creatures/necros/puker_attack_1.ogg'
	status_flags = 0
	mob_size = MOB_SIZE_HUMAN
	force_threshold = 10
	AIStatus = AI_ON
	loot = list(/obj/effect/gibspawner/xeno/bodypartless, /obj/effect/gibspawner/generic, /obj/effect/gibspawner/generic/animal, /obj/effect/gibspawner/human/bodypartless, /obj/effect/gibspawner/human)

/////////////////Spider///////////////
/mob/living/simple_animal/hostile/spider
	name = "Necromorph"
	real_name = "Necromorph"
	icon = 'modular_bluemoon/icons/mob/necros.dmi'
	desc = "Fear the arachnids"
	icon_state = "aliend_s"
	icon_living = "aliend_s"
	maxHealth = 40
	health = 40
	response_harm_continuous = "harmlessly punches"
	response_harm_simple = "harmlessly punch"
	harm_intent_damage = 0
	obj_damage = 10
	melee_damage_lower = 10
	melee_damage_upper = 15
	attack_verb_continuous = "claws"
	attack_verb_simple = "claws"
	speed = 1.8
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	attack_sound = 'modular_bluemoon/sound/creatures/necros/infector_attack_4.ogg'
	status_flags = 0
	mob_size = MOB_SIZE_SMALL
	force_threshold = 10
	AIStatus = AI_ON
	loot = list(/obj/effect/gibspawner/xeno/bodypartless, /obj/effect/gibspawner/generic, /obj/effect/gibspawner/generic/animal, /obj/effect/gibspawner/human/bodypartless, /obj/effect/gibspawner/human)

/proc/roll_necromorph_biomass(mob/living/simple_animal/hostile/source)
	var/common_chance = 30
	var/dense_chance = 0
	if(istype(source, /mob/living/simple_animal/hostile/brute))
		common_chance = 55
		dense_chance = 30
		if(istype(source, /mob/living/simple_animal/hostile/brute/leaper))
			common_chance = 45
			dense_chance = 15
		else if(istype(source, /mob/living/simple_animal/hostile/brute/uber))
			common_chance = 60
			dense_chance = 100
	if(prob(common_chance))
		new /obj/item/broken/necromorph_biomass(source.loc)
	if(prob(dense_chance))
		new /obj/item/broken/necromorph_biomass/dense(source.loc)

/mob/living/simple_animal/hostile/brute/drop_loot()
	. = ..()
	roll_necromorph_biomass(src)

/mob/living/simple_animal/hostile/grunt/drop_loot()
	. = ..()
	roll_necromorph_biomass(src)

/mob/living/simple_animal/hostile/spider/drop_loot()
	. = ..()
	roll_necromorph_biomass(src)
