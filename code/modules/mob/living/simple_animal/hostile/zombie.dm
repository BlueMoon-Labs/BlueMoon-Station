/mob/living/simple_animal/hostile/zombie
	name = "Shambling Corpse"
	desc = "When there is no more room in hell, the dead will walk in outer space."
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "zombie"
	icon_living = "zombie"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	speak_chance = 0
	stat_attack = UNCONSCIOUS //braains
	maxHealth = 100
	health = 100
	harm_intent_damage = 5
	melee_damage_lower = 21
	melee_damage_upper = 21
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/hallucinations/growl1.ogg'
	a_intent = INTENT_HARM
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	spacewalk = FALSE
	status_flags = CANPUSH
	del_on_death = 1
	var/zombiejob = "Medical Doctor"
	var/infection_chance = 0
	var/obj/effect/mob_spawn/human/corpse/delayed/corpse
	///Собирать ли внешность из аутфита профессии. Подтипу со своим спрайтом это
	///только мешает: get_flat_human_icon затирает объявленную им иконку.
	var/generate_appearance = TRUE
	///Оставлять ли после себя труп человека. Подтип со своим loot обходится без него.
	var/no_corpse = FALSE

/mob/living/simple_animal/hostile/zombie/Initialize(mapload)
	. = ..()
	setup_visuals()

/mob/living/simple_animal/hostile/zombie/Destroy()
	if(!QDELETED(corpse))
		QDEL_NULL(corpse)
	. = ..()

/mob/living/simple_animal/hostile/zombie/proc/setup_visuals()
	set waitfor = FALSE
	if(!generate_appearance && no_corpse)
		return //ни рисовать, ни хоронить нечего - подтип обходится своими силами
	var/datum/preferences/dummy_prefs = new
	dummy_prefs.pref_species = new /datum/species/zombie
	dummy_prefs.be_random_body = TRUE
	var/datum/job/J = SSjob.GetJob(zombiejob)
	var/datum/outfit/O
	if(J.outfit)
		O = new J.outfit
		//They have claws now.
		O.r_hand = null
		O.l_hand = null

	if(generate_appearance)
		icon = get_flat_human_icon("zombie_[zombiejob]", J , dummy_prefs, "zombie", outfit_override = O)
	if(no_corpse)
		return
	corpse = new(src)
	corpse.outfit = O
	corpse.mob_species = /datum/species/zombie
	corpse.mob_name = name

/mob/living/simple_animal/hostile/zombie/AttackingTarget()
	. = ..()
	if(. && ishuman(target) && prob(infection_chance))
		try_to_zombie_infect(target)

/mob/living/simple_animal/hostile/zombie/drop_loot()
	. = ..()
	if(QDELETED(corpse))
		return
	corpse.forceMove(drop_location())
	corpse.create()
	corpse = null

/mob/living/simple_animal/hostile/unemployedclone
	name = "Failed clone"
	desc = "Somebody failed chemistry."
	icon = 'icons/mob/human.dmi'
	icon_state = "husk"
	icon_living = "husk"
	icon_dead = "husk"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	speak_chance = 0
	stat_attack = UNCONSCIOUS //braains
	maxHealth = 100
	health = 100
	harm_intent_damage = 5
	melee_damage_lower = 21
	melee_damage_upper = 21
	attack_verb_continuous = "bites"
	attack_verb_simple = "bite"
	attack_sound = 'sound/hallucinations/growl1.ogg'
	a_intent = INTENT_HARM
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	spacewalk = FALSE
	status_flags = CANPUSH
	del_on_death = 0
