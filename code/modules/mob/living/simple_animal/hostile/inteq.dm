/*
	CONTENTS
	LINE 10  - BASE MOB
	LINE 52  - MELEE
	LINE 164 - GUNS
	LINE 267 - MISC
*/


///////////////Base mob////////////

/mob/living/simple_animal/hostile/inteq
	name = "InteQ Operative"
	desc = "Смерть Nanotrasen и Синдикату!"
	icon = 'icons/mob/simple_human.dmi'
	icon_state = "syndicate"
	icon_living = "syndicate"
	icon_dead = "syndicate_dead"
	icon_gib = "syndicate_gib"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	speak_chance = 0
	turns_per_move = 5
	speed = 0
	stat_attack = UNCONSCIOUS
	robust_searching = 1
	maxHealth = 150
	health = 150
	harm_intent_damage = 5
	melee_damage_lower = 10
	melee_damage_upper = 10
	vision_range = 15
	aggro_vision_range = 15
	attack_verb_continuous = "punches"
	attack_verb_simple = "punch"
	attack_sound = 'sound/weapons/punch1.ogg'
	a_intent = INTENT_HARM
	loot = list(/obj/effect/mob_spawn/human/corpse/inteq_dead)
	// Новая переменная для случайного лута (ассоциативный список: предмет -> вес)
	var/list/random_loot = null
	atmos_requirements = list("min_oxy" = 5, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 1, "min_co2" = 0, "max_co2" = 5, "min_n2" = 0, "max_n2" = 0)
	unsuitable_atmos_damage = 15
	faction = list(ROLE_INTEQ)
	check_friendly_fire = 1
	status_flags = CANPUSH
	del_on_death = 1
	dodging = TRUE
	rapid_melee = 2

	footstep_type = FOOTSTEP_MOB_SHOE

/mob/living/simple_animal/hostile/inteq/Initialize(mapload)
	. = ..()
	if(random_loot && length(random_loot))
		AddComponent(/datum/component/random_loot, random_loot)

///////////////Melee////////////

/mob/living/simple_animal/hostile/inteq/space
	icon_state = "syndicate_space"
	icon_living = "syndicate_space"
	name = "InteQ Commando"
	maxHealth = 170
	health = 170
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	speed = 1
	spacewalk = TRUE

/mob/living/simple_animal/hostile/inteq/space/Initialize(mapload)
	. = ..()
	set_light(4)

/mob/living/simple_animal/hostile/inteq/space/stormtrooper
	icon_state = "syndicate_stormtrooper"
	icon_living = "syndicate_stormtrooper"
	name = "InteQ Stormtrooper"
	maxHealth = 250
	health = 250

/mob/living/simple_animal/hostile/inteq/melee
	melee_damage_lower = 15
	melee_damage_upper = 15
	wound_bonus = 10
	bare_wound_bonus = 10
	sharpness = SHARP_EDGED
	icon_state = "syndicate_knife"
	icon_living = "syndicate_knife"
	loot = list(/obj/effect/gibspawner/human)
	random_loot = list(
		/obj/item/inteq_sledgehammer = 5,
		/obj/item/broken/inteq_sledgehammer = 40,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/suit/armor/inteq = 5,
		/obj/item/clothing/head/helmet/swat/inteq = 5,
		null = 40   // ничего не выпадает
	)
	attack_verb_continuous = "smashes"
	attack_verb_simple = "smash"
	attack_sound = 'modular_bluemoon/kovac_shitcode/sound/weapons/sledge.ogg'
	status_flags = 0

/mob/living/simple_animal/hostile/inteq/melee/space
	icon_state = "syndicate_space_knife"
	icon_living = "syndicate_space_knife"
	name = "InteQ Commando"
	maxHealth = 170
	health = 170
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	speed = 1
	spacewalk = TRUE
	random_loot = list(
		/obj/item/inteq_sledgehammer = 5,
		/obj/item/broken/inteq_sledgehammer = 40,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/head/helmet/space/syndicate/inteq = 5,
		/obj/item/clothing/suit/space/syndicate/inteq = 5,
		null = 40   // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/melee/space/Initialize(mapload)
	. = ..()
	set_light(4)

/mob/living/simple_animal/hostile/inteq/melee/space/stormtrooper
	icon_state = "syndicate_stormtrooper_knife"
	icon_living = "syndicate_stormtrooper_knife"
	name = "InteQ Stormtrooper"
	maxHealth = 250
	health = 250
	random_loot = list(
		/obj/item/inteq_sledgehammer = 5,
		/obj/item/broken/inteq_sledgehammer = 40,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq = 5,
		/obj/item/broken/inteq_elite = 35,
		null = 10   // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/melee/sword
	melee_damage_lower = 30
	melee_damage_upper = 30
	icon_state = "syndicate_sword"
	icon_living = "syndicate_sword"
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/weapons/blade1.ogg'
	armour_penetration = 35
	light_color = LIGHT_COLOR_RED
	status_flags = 0
	var/obj/effect/light_emitter/red_energy_sword/sord
	random_loot = list(
		/obj/item/dualsaber = 1,
		/obj/item/broken/dualsaber = 15,
		/obj/item/melee/transforming/energy/sword = 5,
		/obj/item/broken/energy_sword = 40,
		/obj/item/clothing/under/inteq = 5,
		/obj/item/clothing/mask/gas/inteq = 5,
		/obj/item/clothing/suit/armor/inteq = 5,
		/obj/item/clothing/head/helmet/swat/inteq = 5,
		null = 19   // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/melee/sword/Initialize(mapload)
	. = ..()
	set_light(2)

/mob/living/simple_animal/hostile/inteq/melee/sword/Destroy()
	QDEL_NULL(sord)
	return ..()

/mob/living/simple_animal/hostile/inteq/melee/sword/bullet_act(obj/item/projectile/Proj)
	if(prob(50))
		visible_message("<span class='danger'>[src] blocks [Proj] with its sword!</span>")
		return BULLET_ACT_BLOCK
	return ..()

/mob/living/simple_animal/hostile/inteq/melee/sword/space
	icon_state = "syndicate_space_sword"
	icon_living = "syndicate_space_sword"
	name = "InteQ Commando"
	maxHealth = 170
	health = 170
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	speed = 1
	spacewalk = TRUE
	random_loot = list(
		/obj/item/dualsaber = 1,
		/obj/item/broken/dualsaber = 15,
		/obj/item/melee/transforming/energy/sword = 5,
		/obj/item/broken/energy_sword = 40,
		/obj/item/clothing/under/inteq = 5,
		/obj/item/clothing/mask/gas/inteq = 5,
		/obj/item/clothing/head/helmet/space/syndicate/inteq = 5,
		/obj/item/clothing/suit/space/syndicate/inteq = 5,
		null = 19   // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/melee/sword/space/Initialize(mapload)
	. = ..()
	sord = new(src)
	set_light(4)

/mob/living/simple_animal/hostile/inteq/melee/sword/space/Destroy()
	QDEL_NULL(sord)
	return ..()

/mob/living/simple_animal/hostile/inteq/melee/sword/space/stormtrooper
	icon_state = "syndicate_stormtrooper_sword"
	icon_living = "syndicate_stormtrooper_sword"
	name = "InteQ Stormtrooper"
	maxHealth = 250
	health = 250
	random_loot = list(
		/obj/item/dualsaber = 1,
		/obj/item/broken/dualsaber = 15,
		/obj/item/melee/transforming/energy/sword = 5,
		/obj/item/broken/energy_sword = 20,
		/obj/item/clothing/under/inteq = 5,
		/obj/item/clothing/mask/gas/inteq = 5,
		/obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq = 5,
		/obj/item/broken/inteq_elite = 35,
		null = 9   // ничего не выпадает
	)

///////////////Guns////////////

/mob/living/simple_animal/hostile/inteq/ranged
	ranged = 1
	retreat_distance = 5
	minimum_distance = 5
	icon_state = "syndicate_pistol"
	icon_living = "syndicate_pistol"
	casingtype = /obj/item/ammo_casing/c10mm
	projectilesound = 'sound/weapons/gunshot.ogg'
	loot = list(/obj/effect/gibspawner/human)
	dodging = FALSE
	rapid_melee = 1
	random_loot = list(
		/obj/item/gun/ballistic/automatic/pistol = 5,
		/obj/item/broken/makarov = 30,
		/obj/item/ammo_box/magazine/m10mm = 10,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/suit/armor/inteq = 5,
		/obj/item/clothing/head/helmet/swat/inteq = 5,
		null = 30 // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/ranged/infiltrator //shuttle loan event / GateInteQ
	projectilesound = 'sound/weapons/gunshot_silenced.ogg'
	loot = list(/obj/effect/mob_spawn/human/corpse/inteq_dead)

/mob/living/simple_animal/hostile/inteq/ranged/space
	icon_state = "syndicate_space_pistol"
	icon_living = "syndicate_space_pistol"
	name = "InteQ Commando"
	maxHealth = 170
	health = 170
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	speed = 1
	spacewalk = TRUE
	random_loot = list(
		/obj/item/gun/ballistic/automatic/pistol = 5,
		/obj/item/broken/makarov = 30,
		/obj/item/ammo_box/magazine/m10mm = 10,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/head/helmet/space/syndicate/inteq = 5,
		/obj/item/clothing/suit/space/syndicate/inteq = 5,
		null = 30 // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/ranged/space/Initialize(mapload)
	. = ..()
	set_light(4)

/mob/living/simple_animal/hostile/inteq/ranged/space/stormtrooper
	icon_state = "syndicate_stormtrooper_pistol"
	icon_living = "syndicate_stormtrooper_pistol"
	name = "InteQ Stormtrooper"
	maxHealth = 250
	health = 250
	random_loot = list(
		/obj/item/gun/ballistic/automatic/pistol = 5,
		/obj/item/broken/makarov = 10,
		/obj/item/ammo_box/magazine/m10mm = 10,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq = 5,
		/obj/item/broken/inteq_elite = 35,
		null = 10 // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/ranged/smg
	rapid = 2
	icon_state = "syndicate_smg"
	icon_living = "syndicate_smg"
	casingtype = /obj/item/ammo_casing/c45/lethal
	projectilesound = 'sound/weapons/gunshot_smg.ogg'
	random_loot = list(
		/obj/item/gun/ballistic/automatic/c20r = 5,
		/obj/item/broken/c20r = 30,
		/obj/item/ammo_box/magazine/smgm45 = 10,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/suit/armor/inteq = 5,
		/obj/item/clothing/head/helmet/swat/inteq = 5,
		null = 20 // ничего не выпадает
	)


/mob/living/simple_animal/hostile/inteq/ranged/smg/pilot
	name = "InteQ Salvage Pilot"
	loot = list(/obj/effect/mob_spawn/human/corpse/inteq_dead)

/mob/living/simple_animal/hostile/inteq/ranged/smg/space
	icon_state = "syndicate_space_smg"
	icon_living = "syndicate_space_smg"
	name = "InteQ Commando"
	maxHealth = 170
	health = 170
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	speed = 1
	spacewalk = TRUE
	random_loot = list(
		/obj/item/gun/ballistic/automatic/c20r = 5,
		/obj/item/broken/c20r = 30,
		/obj/item/ammo_box/magazine/smgm45 = 10,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/head/helmet/space/syndicate/inteq = 5,
		/obj/item/clothing/suit/space/syndicate/inteq = 5,
		null = 20 // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/ranged/smg/space/Initialize(mapload)
	. = ..()
	set_light(4)

/mob/living/simple_animal/hostile/inteq/ranged/smg/space/stormtrooper
	icon_state = "syndicate_stormtrooper_smg"
	icon_living = "syndicate_stormtrooper_smg"
	name = "InteQ Stormtrooper"
	maxHealth = 250
	health = 250
	random_loot = list(
		/obj/item/gun/ballistic/automatic/c20r = 5,
		/obj/item/broken/c20r = 10,
		/obj/item/ammo_box/magazine/smgm45 = 10,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq = 5,
		/obj/item/broken/inteq_elite = 35,
		null = 10 // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/ranged/shotgun
	rapid = 2
	rapid_fire_delay = 6
	minimum_distance = 3
	icon_state = "syndicate_shotgun"
	icon_living = "syndicate_shotgun"
	casingtype = /obj/item/ammo_casing/shotgun/buckshot //buckshot (up to 72.5 brute) fired in a two-round burst
	random_loot = list(
		/obj/item/gun/ballistic/automatic/shotgun/bulldog = 5,
		/obj/item/broken/bulldog = 30,
		/obj/item/ammo_box/magazine/m12g = 10,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/suit/armor/inteq = 5,
		/obj/item/clothing/head/helmet/swat/inteq = 5,
		null = 20 // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/ranged/shotgun/space
	icon_state = "syndicate_space_shotgun"
	icon_living = "syndicate_space_shotgun"
	name = "InteQ Commando"
	maxHealth = 170
	health = 170
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	speed = 1
	spacewalk = TRUE
	random_loot = list(
		/obj/item/gun/ballistic/automatic/shotgun/bulldog = 5,
		/obj/item/broken/bulldog = 30,
		/obj/item/ammo_box/magazine/m12g = 10,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/head/helmet/space/syndicate/inteq = 5,
		/obj/item/clothing/suit/space/syndicate/inteq = 5,
		null = 20 // ничего не выпадает
	)

/mob/living/simple_animal/hostile/inteq/ranged/shotgun/space/Initialize(mapload)
	. = ..()
	set_light(4)

/mob/living/simple_animal/hostile/inteq/ranged/shotgun/space/stormtrooper
	icon_state = "syndicate_stormtrooper_shotgun"
	icon_living = "syndicate_stormtrooper_shotgun"
	name = "InteQ Stormtrooper"
	maxHealth = 250
	health = 250
	random_loot = list(
		/obj/item/gun/ballistic/automatic/shotgun/bulldog = 5,
		/obj/item/broken/bulldog = 10,
		/obj/item/ammo_box/magazine/m12g = 10,
		/obj/item/clothing/under/inteq = 15,
		/obj/item/clothing/mask/gas/inteq = 10,
		/obj/item/clothing/suit/space/hardsuit/syndi/elite/inteq = 5,
		/obj/item/broken/inteq_elite = 35,
		null = 10 // ничего не выпадает
	)

///////////////Misc////////////

/mob/living/simple_animal/hostile/inteq/civilian
	minimum_distance = 10
	retreat_distance = 10
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	var/next_guard_call = 0
	var/guard_call_cooldown = 30 SECONDS

/mob/living/simple_animal/hostile/inteq/civilian/Aggro()
	..()
	if(world.time < next_guard_call)
		return
	next_guard_call = world.time + guard_call_cooldown
	summon_backup(15)
	say("GUARDS!!")
