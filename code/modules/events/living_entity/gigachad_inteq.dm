/datum/round_event_control/gigachad_inteq
	name = "InteQ Sledgehammer Mutant"
	typepath = /datum/round_event/gigachad_inteq
	max_occurrences = 2
	weight = 15
	category = EVENT_CATEGORY_ENTITIES

/datum/round_event/gigachad_inteq/announce(fake)
	send_fax_to_area(new /obj/item/paper/fax_CC_message/escapee/gigachad_inteq_announce, /area/security, "Психиатрический Отдел Nanotrasen", FALSE)
	// priority_announce("Один из наших... кхм... особых заключённых сбежал. Так получилось, что его последнее известное местонахождение до того, как их маячок заглох, - это ваша станция, так что будьте осторожней и остерегайтесь Технических Тоннелей. И еще... что это за стуки металла?",
	// sender_override = "Психиатрический Отдел Nanotrasen", has_important_message = TRUE)

/datum/round_event/gigachad_inteq/start()
	var/list/spawn_locs = list()
	var/list/unsafe_spawn_locs = list()
	for(var/X in GLOB.xeno_spawn)
		if(!isfloorturf(X))
			unsafe_spawn_locs += X
			continue
		var/turf/open/floor/F = X
		var/datum/gas_mixture/A = F.air
		var/oxy_moles = A.get_moles(GAS_O2)
		if((oxy_moles < 16 || oxy_moles > 50) || A.get_moles(GAS_PLASMA) || A.get_moles(GAS_CO2) >= 10)
			unsafe_spawn_locs += F
			continue
		if((A.return_temperature() <= 270) || (A.return_temperature() >= 360))
			unsafe_spawn_locs += F
			continue
		var/pressure = A.return_pressure()
		if((pressure <= 20) || (pressure >= 550))
			unsafe_spawn_locs += F
			continue
		spawn_locs += F

	if(!spawn_locs.len)
		spawn_locs += unsafe_spawn_locs

	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR

	var/turf/T = get_turf(pick(spawn_locs))
	var/mob/living/simple_animal/hostile/gigachad_inteq/S = new(T)
	playsound(S, 'modular_bluemoon/kovac_shitcode/sound/weapons/sledge.ogg', 75, 1, 1000)
	message_admins("An InteQ mutant has been spawned at [COORD(T)][ADMIN_JMP(T)]")
	log_game("An InteQ mutant has been spawned at [COORD(T)]")
	return SUCCESSFUL_SPAWN

/////////////////Simple mob himself///////////////
/mob/living/simple_animal/hostile/gigachad_inteq
	name = "InteQ Agent"
	real_name = "InteQ Agent"
	icon = 'modular_bluemoon/kovac_shitcode/icons/gigachad_inteq.dmi'
	desc = "An experiment had gone out of control.."
	icon_state = "gigachad_inteq"
	icon_living = "gigachad_inteq"
	icon_dead = "syndicate_dead"
	icon_gib = "syndicate_gib"
	maxHealth = 1200
	health = 1200
	response_harm_continuous = "harmlessly punches"
	response_harm_simple = "harmlessly punch"
	harm_intent_damage = 0
	obj_damage = 100
	melee_damage_lower = 50
	melee_damage_upper = 60
	attack_verb_continuous = "smashes his sledgehammer into"
	attack_verb_simple = "smashes sledgehammer into"
	speed = 0.8
	environment_smash = ENVIRONMENT_SMASH_WALLS
	attack_sound = 'modular_bluemoon/kovac_shitcode/sound/weapons/sledge.ogg'
	status_flags = 0
	mob_size = MOB_SIZE_LARGE
	del_on_death = TRUE
	force_threshold = 10
	speak_chance = 90
	AIStatus = AI_ON
	speak = list("БЕГАЮЩИЕ ГВОЗДИ!!!", "БЕГИ, СУКА, БЕГИ!!!", "КАК ОРЕХ ЩА РАСКОЛЮ!!!")
	loot = list(/obj/item/storage/belt/military/inteq, /obj/item/clothing/head/helmet/swat/inteq, /obj/item/clothing/shoes/combat/coldres, /obj/effect/gibspawner/generic, /obj/effect/gibspawner/generic/animal, /obj/effect/gibspawner/human/bodypartless, /obj/effect/gibspawner/human)

/mob/living/simple_animal/hostile/gigachad_inteq/space
	name = "InteQ Space Agent"
	maxHealth = 1400
	health = 1400
	melee_damage_lower = 30
	melee_damage_upper = 20
	attack_verb_continuous = "smashes his hands into"
	attack_verb_simple = "smashes hands into"
	icon_state = "gigachad_inteq_space"
	icon_living = "gigachad_inteq_space"
	attack_sound = 'sound/weapons/smash.ogg'
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	spacewalk = TRUE
	faction = list(ROLE_INTEQ)

/mob/living/simple_animal/hostile/gigachad_inteq/shooter
	name = "InteQ Machinegunner"
	icon_state = "gigachad_machinegun"
	icon_living = "gigachad_machinegun"
	maxHealth = 600
	health = 600
	ranged = 1
	rapid = 5
	projectilesound = 'sound/weapons/shot.ogg'
	speak = list("БЕГАЮЩАЯ МИШЕНЬ И БЕСПЛАТНО!!!", "БЕГИ, СУКА, БЕГИ!!!", "КАК АРБУЗ МАГНУМОМ ЛОПНУ!!!")
	casingtype = /obj/item/ammo_casing/n762
	retreat_distance = 5
	minimum_distance = 5
	faction = list(ROLE_INTEQ)

/mob/living/simple_animal/hostile/gigachad_inteq/shooter/sniper
	name = "InteQ Buffed sniper"
	icon_state = "gigachad_sniper"
	icon_living = "gigachad_sniper"
	casingtype = /obj/item/ammo_casing/p50/inteqsniper
	rapid = 1
	maxHealth = 350
	health = 350
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
	projectilesound = "sound/weapons/noscope.ogg"
	ranged_cooldown = 150
	check_friendly_fire = 1
	speak = list("ДА ЁБ ТВОЮ МАТЬ! ОПЯТЬ КЛИН!!!", "А ЭТО ЧЁ? ПРОБИВНЫЕ? ЭТО НАМ НАДО!!!", "МАГАЗИН ГДЕ? БЛЯ! ГДЕ МАГАЗИН МОЙ!!!")

/obj/item/ammo_casing/p50/inteqsniper
	name = "cheap .50 bullet casing"
	desc = "A cheap .50 bullet casing."
	projectile_type = /obj/item/projectile/bullet/p50/inteqsniper

/obj/item/projectile/bullet/p50/inteqsniper
	name ="cheap .50 bullet"
	damage = 40
	knockdown = 80
	dismemberment = 40
	armour_penetration = 30
	zone_accuracy_factor = 70
	wound_bonus = 10
	bare_wound_bonus = 5

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/datum/round_event_control/space_mosquito
	name = "Space Mosquito"
	typepath = /datum/round_event/space_mosquito
	max_occurrences = 2
	weight = 30
	category = EVENT_CATEGORY_ENTITIES

/datum/round_event/space_mosquito/announce(fake)
	send_fax_to_area(new /obj/item/paper/fax_CC_message/escapee/mosquito_announce, /area/security, "Психиатрический Отдел Nanotrasen", FALSE)
	// priority_announce("Один из наших... кхм... особых заключённых сбежал. Так получилось, что его последнее известное местонахождение до того, как их маячок заглох, - это ваша станция, так что будьте осторожней и остерегайтесь Технических Тоннелей. И еще... это что, выкрики на нео-русском?",
	// sender_override = "Психиатрический Отдел Nanotrasen", has_important_message = TRUE)

/datum/round_event/space_mosquito/start()
	var/list/spawn_locs = list()
	var/list/unsafe_spawn_locs = list()
	for(var/X in GLOB.xeno_spawn)
		if(!isfloorturf(X))
			unsafe_spawn_locs += X
			continue
		var/turf/open/floor/F = X
		var/datum/gas_mixture/A = F.air
		var/oxy_moles = A.get_moles(GAS_O2)
		if((oxy_moles < 16 || oxy_moles > 50) || A.get_moles(GAS_PLASMA) || A.get_moles(GAS_CO2) >= 10)
			unsafe_spawn_locs += F
			continue
		if((A.return_temperature() <= 270) || (A.return_temperature() >= 360))
			unsafe_spawn_locs += F
			continue
		var/pressure = A.return_pressure()
		if((pressure <= 20) || (pressure >= 550))
			unsafe_spawn_locs += F
			continue
		spawn_locs += F

	if(!spawn_locs.len)
		spawn_locs += unsafe_spawn_locs

	if(!spawn_locs.len)
		message_admins("No valid spawn locations found, aborting...")
		return MAP_ERROR

	var/turf/T = get_turf(pick(spawn_locs))
	var/mob/living/simple_animal/hostile/space_mosquito/S = new(T)
	playsound(S, 'modular_bluemoon/kovac_shitcode/sound/komar_spawn.ogg', 75, 1, 1000)
	message_admins("A Space Mosquito has been spawned at [COORD(T)][ADMIN_JMP(T)]")
	log_game("A Space Mosquito has been spawned at [COORD(T)]")
	return SUCCESSFUL_SPAWN

/////////////////Simple mob himself///////////////
/mob/living/simple_animal/hostile/space_mosquito
	name = "Space Mosquito"
	real_name = "Space Mosquito"
	icon = 'modular_bluemoon/kovac_shitcode/icons/animals.dmi'
	desc = "An expert of battle and survival in extremal environment."
	icon_state = "komar"
	icon_living = "komar"
	icon_dead = "syndicate_dead"
	icon_gib = "syndicate_gib"
	maxHealth = 250
	health = 250
	response_harm_continuous = "harmlessly punches"
	response_harm_simple = "harmlessly punch"
	harm_intent_damage = 0
	obj_damage = 100
	melee_damage_lower = 250
	melee_damage_upper = 300
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slashes"
	speed = -10
	environment_smash = ENVIRONMENT_SMASH_WALLS
	attack_sound = 'modular_bluemoon/kovac_shitcode/sound/komar.ogg'
	status_flags = 0
	mob_size = MOB_SIZE_HUMAN
	del_on_death = TRUE
	force_threshold = 10
	move_to_delay = 1 // ГОТТА ФАСТ БОЙЙЙ
	speak_chance = 0
	AIStatus = AI_ON
	loot = list(/obj/effect/gibspawner/human)

/mob/living/simple_animal/hostile/space_mosquito/AttackingTarget()
	. = ..()
	if(. && isliving(target))
		var/mob/living/L = target
		L.adjustBruteLoss(110)
		qdel(src)
	return
/mob/living/simple_animal/hostile/malf_drone/experimental
	name = "Experimental drone"
	desc = "You see an unusual drone, primed but not painted.The front part is dotted with sensors, and a large-caliber machine gun and a rocket launcher mouth are visible under the bottom."
	projectiletype = /obj/item/projectile/bullet/a308
	projectilesound = 'modular_bluemoon/sound/weapons/carcannon1.ogg'
	var/alt_projectilesound = 'modular_bluemoon/sound/weapons/rocketlaunch.ogg'
	var/alternative_fire = /obj/item/projectile/bullet/a84mm_he
	var/list_sound = list('modular_bluemoon/sound/creatures/drone_speech.ogg', 'modular_bluemoon/sound/creatures/drone_target_search.ogg','modular_bluemoon/sound/creatures/drone_up.ogg','modular_bluemoon/sound/creatures/drone_up2.ogg')
	icon = 'modular_bluemoon/icons/mob/dron.dmi'
	icon_dead = "crash"
	del_on_death = FALSE
	speak_chance = 50
	turns_per_move = 1
	rapid = 2
	speed = 14

/mob/living/simple_animal/hostile/malf_drone/experimental/proc/changeFireMode()
	var/mob/living/simple_animal/hostile/malf_drone/experimental/D = src
	if(D.projectiletype != D.alternative_fire & D.stat == CONSCIOUS)
		D.projectiletype = D.alternative_fire
		D.projectilesound = D.alt_projectilesound
		D.rapid = 1
		playsound(src, 'modular_bluemoon/sound/creatures/drone_target_search.ogg', 50)
	else
		D.projectiletype = /obj/item/projectile/bullet/a308
		D.rapid = 3
		D.projectilesound = 'modular_bluemoon/sound/weapons/carcannon1.ogg'

/mob/living/simple_animal/hostile/malf_drone/experimental/update_icons()
	if(src.stat == UNCONSCIOUS)
		src.overlays = null
	return

/mob/living/simple_animal/hostile/malf_drone/experimental/OpenFire(atom/A)
	. = ..()
	if(src.projectiletype == src.alternative_fire)
		new /obj/effect/temp_visual/drone_radar(A.loc)

/mob/living/simple_animal/hostile/malf_drone/experimental/BiologicalLife()
	. = ..()
	var/mob/living/simple_animal/hostile/malf_drone/experimental/E = src
	if(prob(20))
		E.changeFireMode()
	else
		if(E.stat == CONSCIOUS)
			src.add_overlay(/obj/effect/temp_visual/drone_scan)
			var/sound = pick(E.list_sound)
			playsound(src, sound, 50)

/mob/living/simple_animal/hostile/malf_drone/experimental/emp_act(severity)
	. = ..()
	adjustHealth(200 / severity)
	src.AIStatus = AI_OFF
	playsound(src, 'sound/machines/terminal_alert.ogg', 50, 0)
	addtimer(CALLBACK(src, PROC_REF(switch_AIStatus_on)), 2 SECONDS)

/mob/living/simple_animal/hostile/malf_drone/experimental/proc/switch_AIStatus_on()
	AIStatus = AI_ON

/obj/effect/temp_visual/drone_scan
	icon = 'modular_bluemoon/icons/mob/dron.dmi'
	icon_state = "scan"
	anchored = TRUE
	duration = 15

/obj/effect/temp_visual/drone_radar
	icon = 'modular_bluemoon/icons/mob/radar.dmi'
	icon_state = "radar"
	anchored = TRUE
	duration = 30

/obj/effect/temp_visual/drone_target_pointer
	icon = 'icons/effects/mouse_pointers/weapon_pointer.dmi'
	icon_state = "all"
	anchored = TRUE
	duration = 10

/mob/living/simple_animal/hostile/malf_drone/experimental/drop_loot()
	. = ..()
	var/turf/T = get_turf(src)
	new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack(T)
	new /obj/item/robot_module/syndicate/inteq(T)

/mob/living/simple_animal/hostile/alien/queen/king
	icon = 'modular_bluemoon/icons/mob/king.dmi'
	name = "King"
	desc = "It has a massive body with a characteristic head crest divided into two horns, between which there is a third, shorter protrusion. The king lacks the pair of pectoral limbs typical of the queen, but has a massive tail and dorsal breathing tubes resembling small tails."
	icon_state = "Normal King Walking"
	icon_living = "Normal King Walking"
	icon_dead = "Normal King Dead"
	health = 800
	maxHealth = 800
	melee_damage_lower = 40
	melee_damage_upper = 70
	armour_penetration = 20
	minimum_distance = 1
	retreat_distance = 1
	ranged = FALSE
	loot = list(/obj/effect/mob_spawn/alien/corpse/humanoid/queen/king)

/mob/living/simple_animal/hostile/alien/queen/king/SpreadPlants()
	return FALSE //Кинг не королева, чтобы создавать яйца

/obj/effect/mob_spawn/alien/corpse/humanoid/queen/king
	name = "king corpse"
	mob_type = /mob/living/carbon/alien/humanoid/royal/queen/king

/mob/living/carbon/alien/humanoid/royal/queen/king
	icon = 'modular_bluemoon/icons/mob/king.dmi'
	icon_state = "Normal King Dead"
	stat = DEAD
