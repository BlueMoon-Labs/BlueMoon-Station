/mob/living/simple_animal/hostile/blackmesa
	var/list/alert_sounds
	var/alert_cooldown = 3 SECONDS
	var/alert_cooldown_time

/mob/living/simple_animal/hostile/blackmesa/xen
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500

/mob/living/simple_animal/hostile/blackmesa/Aggro()
	if(alert_sounds)
		if(!(world.time <= alert_cooldown_time))
			playsound(src, pick(alert_sounds), 70)
			alert_cooldown_time = world.time + alert_cooldown

// Bullsquid

/mob/living/simple_animal/hostile/blackmesa/xen/bullsquid
	name = "bullsquid"
	desc = "Противное инопланетное существо прямиком из другого измерения. Его глаза уже сверлят вас."
	icon = 'modular_bluemoon/icons/mob/bullsquidnew.dmi'
	icon_state = "bullsquid1"
	icon_living = "bullsquid1"
	icon_dead = "bullsquid1dead"
	icon_gib = null
	mob_biotypes = list(MOB_ORGANIC, MOB_BEAST)
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	faction = list(FACTION_XEN)
	speak_chance = 50
	speak_emote = list("growls")
	emote_taunt = list("growls", "snarls", "grumbles")
	taunt_chance = 100
	turns_per_move = 7
	maxHealth = 110
	health = 110
	obj_damage = 50
	harm_intent_damage = 15
	melee_damage_lower = 15
	melee_damage_upper = 15
	ranged = TRUE
	retreat_distance = 4
	minimum_distance = 4
	dodging = TRUE
	projectilesound = 'modular_bluemoon/sound/creatures/mesa/bullsquid/goo_attack3.ogg'
	melee_damage_upper = 18
	attack_sound = 'modular_bluemoon/sound/creatures/mesa/bullsquid/attack1.ogg'
	gold_core_spawnable = HOSTILE_SPAWN
	alert_sounds = list('modular_bluemoon/sound/creatures/mesa/bullsquid/detect1.ogg','modular_bluemoon/sound/creatures/mesa/bullsquid/detect2.ogg','modular_bluemoon/sound/creatures/mesa/bullsquid/detect3.ogg')
	projectiletype = /obj/item/projectile/neurotox/bullsquid

/mob/living/simple_animal/hostile/blackmesa/xen/bullsquid/alt1
	icon_state = "bullsquid2"
	icon_living = "bullsquid2"
	icon_dead = "bullsquid2dead"
	maxHealth = 90
	health = 90

/mob/living/simple_animal/hostile/blackmesa/xen/bullsquid/alt2
	icon_state = "bullsquid3"
	icon_living = "bullsquid3"
	icon_dead = "bullsquid3dead"
	maxHealth = 100
	health = 100

/obj/item/projectile/neurotox/bullsquid
	name = "nasty ball of ooze"
	icon_state = "declone"
	damage = 5
	damage_type = BURN
	knockdown = 20
	impact_effect_type = /obj/effect/temp_visual/impact_effect/neurotoxin
	hitsound = 'modular_bluemoon/sound/creatures/mesa/bullsquid/splat1.ogg'
	hitsound_wall = 'modular_bluemoon/sound/creatures/mesa/bullsquid/splat1.ogg'

/obj/effect/temp_visual/impact_effect/neurotoxin
	icon_state = "greenglow"
	color = "#5BDD04"
	icon = 'icons/effects/effects.dmi'
	layer = ABOVE_ALL_MOB_LAYER
	duration = 3

/obj/effect/temp_visual/impact_effect/neurotoxin/Initialize(mapload)
	. = ..()
	new /obj/effect/decal/cleanable/bullsquid_ooze(get_turf(src))


/obj/effect/decal/cleanable/bullsquid_ooze
	name = "Nasty ooze"
	desc = "Отвратительная смесь феромонов и других токсичных реагентов"
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenglow"

/obj/item/projectile/neurotox/bullsquid/on_hit(atom/target, blocked = FALSE)
	..()
	if(iscarbon(target))
		var/mob/living/carbon/C = target
		C.reagents.add_reagent(/datum/reagent/toxin/leaper_venom, 5)
		return
	if(isanimal(target))
		var/mob/living/simple_animal/L = target
		L.adjustHealth(25)


/obj/item/projectile/neurotox/bullsquid/on_range()
	var/turf/T = get_turf(src)
	..()
	new /obj/structure/bullsquidshot(T)


/obj/structure/bullsquidshot
	name = "Ball of ooze"
	desc = "A floating bubble containing leaper venom. The contents are under a surprising amount of pressure."
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "declone"
	max_integrity = 10
	density = FALSE

/obj/structure/bullsquidshot/Initialize(mapload)
	. = ..()
	INVOKE_ASYNC(src, TYPE_PROC_REF(/atom/movable, float), TRUE)
	QDEL_IN(src, 100)

/obj/structure/bullsquidshot/Destroy()
	new /obj/effect/temp_visual/impact_effect/neurotoxin(get_turf(src))
	playsound(src,'modular_bluemoon/sound/creatures/mesa/bullsquid/splat1.ogg',50, 1, -1)
	return ..()

/obj/structure/bullsquidshot/Crossed(atom/movable/AM)
	if(isliving(AM))
		var/mob/living/L = AM
		if(!istype(L, /mob/living/simple_animal/hostile/jungle/leaper))
			playsound(src,'modular_bluemoon/sound/creatures/mesa/bullsquid/splat1.ogg',50, 1, -1)
			L.DefaultCombatKnockdown(50)
			if(iscarbon(L))
				var/mob/living/carbon/C = L
				C.reagents.add_reagent(/datum/reagent/toxin/leaper_venom, 5)
			if(isanimal(L))
				var/mob/living/simple_animal/A = L
				A.adjustHealth(25)
			qdel(src)
	return ..()

// Gonome

/mob/living/simple_animal/hostile/blackmesa/xen/gonome
	name = "Gonome"
	desc = "Довольно опасная мутация обычного зомби! Вам точно стоило тратить время на его рассмотрение?"
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "gonome"
	icon_living = "gonome"
	icon_dead = "zombie_dead"
	icon_gib = "syndicate_gib"
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	faction = list(FACTION_XEN)
	speak_chance = 50
	speak_emote = list("Рычит")
	speed = 1
	emote_taunt = list("Рычит", "Орёт", "Кряхтит")
	taunt_chance = 100
	turns_per_move = 40
	projectiletype = /obj/item/projectile/neurotox
	maxHealth = 3000
	health = 3000
	stat_attack = UNCONSCIOUS
	obj_damage = 70
	harm_intent_damage = 25
	melee_damage_lower = 30
	melee_damage_upper = 30
	attack_sound = 'modular_bluemoon/sound/creatures/mesa/bullsquid/attack1.ogg'
	minbodytemp = 0
	maxbodytemp = 1500
	alert_sounds = list ('modular_bluemoon/sound/creatures/mesa/gonome/gonomealert1.ogg','modular_bluemoon/sound/creatures/mesa/gonome/gonomealert3.ogg','modular_bluemoon/sound/creatures/mesa/gonome/gonomealert2.ogg','modular_bluemoon/sound/creatures/mesa/gonome/gonomealert4.ogg')
	loot = list(/obj/effect/gibspawner/human, /obj/item/wrench/shepard)

// Mesa Headcrab

/mob/living/simple_animal/hostile/headcrab/mesa
	faction = list(FACTION_XEN)
/mob/living/simple_animal/hostile/headcrab/mesa/death(gibbed)
	. = ..()
	playsound(src, pick(list(
		'modular_bluemoon/sound/creatures/mesa/headcrab/die1.ogg',
		'modular_bluemoon/sound/creatures/mesa/headcrab/die2.ogg'
	)), 100)

// Houndeye

/mob/living/simple_animal/hostile/blackmesa/xen/houndeye
	name = "houndeye"
	desc = "Инопланетное существо, отдалённо напоминающее собаку. Очень жаль, что его рвение подбежать к вам приведёт к довольно плачевным последствиям."
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "houndeye"
	icon_living = "houndeye"
	icon_dead = "houndeye_dead"
	icon_gib = null
	mob_biotypes = list(MOB_ORGANIC, MOB_BEAST)
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	faction = list(FACTION_XEN)
	speak_chance = 50
	speak_emote = list("growls")
	speed = 1
	emote_taunt = list("growls", "snarls", "grumbles")
	taunt_chance = 100
	turns_per_move = 7
	maxHealth = 100
	health = 100
	obj_damage = 50
	harm_intent_damage = 10
	melee_damage_lower = 20
	melee_damage_upper = 20
	attack_sound = 'sound/weapons/bite.ogg'
	gold_core_spawnable = HOSTILE_SPAWN
	//Since those can survive on Xen, I'm pretty sure they can thrive on any atmosphere

	minbodytemp = 0
	maxbodytemp = 1500
	alert_sounds = list ('modular_bluemoon/sound/creatures/mesa/houndeye/he_alert1.ogg','modular_bluemoon/sound/creatures/mesa/houndeye/he_alert2.ogg','modular_bluemoon/sound/creatures/mesa/houndeye/he_alert3.ogg','modular_bluemoon/sound/creatures/mesa/houndeye/he_alert4.ogg','modular_bluemoon/sound/creatures/mesa/houndeye/he_alert5.ogg')

// Xen Shark

/mob/living/simple_animal/hostile/blackmesa/xen/snark
	name = "Snark"
	desc = "Snarks are small, beetle-like xenian creatures with one beady green eye, an extendable beak, antennae, four legs, and a dark red thick segmented shell"
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "snark"
	icon_living = "snark"
	icon_gib = null
	faction = list(FACTION_XEN)
	mob_biotypes = MOB_ORGANIC|MOB_BUG
	mob_size = MOB_SIZE_TINY
	pass_flags = PASSTABLE | PASSGRILLE | PASSMOB
	speed = 1
	ranged = 1
	ranged_message = "leaps"
	ranged_cooldown_time = 30
	taunt_chance = 100
	turns_per_move = 20
	maxHealth = 50
	del_on_death = 1
	health = 40
	var/jumpdistance = 4
	var/jumpspeed = 1
	attack_verb_continuous = "bites"
	attack_verb_simple = "bites"
	robust_searching = 1
	speed = 3
	dodging = TRUE
	obj_damage = 5
	harm_intent_damage = 15
	melee_damage_lower = 10
	melee_damage_upper = 10
	loot = list(/obj/effect/decal/cleanable/insectguts)
	attack_sound = 'modular_bluemoon/sound/creatures/mesa/snark/snark4.ogg'
	alert_sounds = list('modular_bluemoon/sound/creatures/mesa/snark/snark1.ogg','modular_bluemoon/sound/creatures/mesa/snark/snark2.ogg','modular_bluemoon/sound/creatures/mesa/snark/snark3.ogg')
	footstep_type = FOOTSTEP_MOB_CLAW

/mob/living/simple_animal/hostile/blackmesa/xen/snark/OpenFire(atom/A)
	if(check_friendly_fire)
		for(var/turf/T in getline(src,A)) // Not 100% reliable but this is faster than simulating actual trajectory
			for(var/mob/living/L in T)
				if(L == src || L == A)
					continue
				if(faction_check_mob(L) && !attack_same)
					return
	visible_message("<span class='danger'><b>[src]</b> [ranged_message] at [A]!</span>")
	throw_at(A, jumpdistance, jumpspeed, spin = FALSE, diagonals_first = TRUE)
	ranged_cooldown = world.time + ranged_cooldown_time


/mob/living/simple_animal/hostile/blackmesa/xen/snark/friendly
	name = "Snark with damaged beak"
	desc = "Snark, which beak has been damaged, now they're cant hurt you (but still tries to bite your fingers)"
	gold_core_spawnable = FRIENDLY_SPAWN
	faction = list("neutral")

/mob/living/simple_animal/hostile/blackmesa/xen/snark/friendly/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/wuv, "Shakes violently and tries to bite your fingers!")
	AddElement(/datum/element/strippable, GLOB.strippable_corgi_items)
	AddElement(/datum/element/mob_holder)

// Vortigaunt

/mob/living/simple_animal/hostile/blackmesa/xen/vortigaunt
	name = "vortigaunt"
	desc = "There is no distance between us. No false veils of time or space may intervene."
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "vortigaunt"
	icon_living = "vortigaunt"
	icon_dead = "vortigaunt_dead"
	icon_gib = null
	gender = MALE
	faction = list(FACTION_XEN)
	mob_biotypes = list(MOB_ORGANIC, MOB_BEAST)
	speak_chance = 1
	speak_emote = list("galungs")
	speed = 1
	emote_taunt = list("galalungas", "galungas", "gungs")
	projectiletype = /obj/item/projectile/beam/emitter/hitscan
	projectilesound = 'modular_bluemoon/sound/creatures/mesa/vortigaunt/attack_shoot4.ogg'
	ranged_cooldown_time = 5 SECONDS
	ranged_message = "fires"
	taunt_chance = 100
	turns_per_move = 7
	maxHealth = 130
	health = 130
	speed = 3
	ranged = TRUE
	dodging = TRUE
	harm_intent_damage = 15
	melee_damage_lower = 10
	melee_damage_upper = 10
	retreat_distance = 5
	minimum_distance = 5
	attack_sound = 'sound/weapons/bite.ogg'
	loot = list(/obj/item/stack/sheet/bone)
	alert_sounds = list(
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/alert01.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/alert01b.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/alert02.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/alert03.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/alert04.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/alert05.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/alert06.ogg',
	)
	/// SOunds we play when asked to follow/unfollow.
	var/list/follow_sounds = list(
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/village_argue01.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/village_argue02.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/village_argue03.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/village_argue04.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/village_argue05.ogg',
		'modular_bluemoon/sound/creatures/mesa/vortigaunt/village_argue05a.ogg',
	)
	var/follow_speed = 1
	var/follow_distance = 2

/mob/living/simple_animal/hostile/blackmesa/xen/vortigaunt/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/follow, follow_sounds, follow_sounds, follow_distance, follow_speed)

/mob/living/simple_animal/hostile/blackmesa/xen/vortigaunt/slave
	name = "slave vortigaunt"
	desc = "Bound by the shackles of a sinister force. He does not want to hurt you."
	icon_state = "vortigaunt_slave"
