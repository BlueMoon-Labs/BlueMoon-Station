// 7.62x38mmR (Nagant Revolver)

/obj/item/projectile/bullet/n762
	name = "7.62x38mmR bullet"
	damage = 60
	armour_penetration = BULLET_BR6
	wound_bonus = 10
	bare_wound_bonus = 4

// .50AE — BR4 (крупный пистолетный, Desert Eagle)
/obj/item/projectile/bullet/a50AE
	name = ".50AE bullet"
	damage = 60
	armour_penetration = BULLET_BR4
	wound_bonus = 15
	bare_wound_bonus = 5

// .38 — BR2 (Detective's Gun)
/obj/item/projectile/bullet/c38
	name = ".38 bullet"
	damage = 30
	armour_penetration = BULLET_BR2
	ricochets_max = 2
	ricochet_chance = 100
	ricochet_auto_aim_angle = 30
	ricochet_auto_aim_range = 6
	wound_bonus = 5
	bare_wound_bonus = 8
	embedding = list(embed_chance=15, fall_chance=2, jostle_chance=2, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=3, jostle_pain_mult=5, rip_time=10)

/obj/item/projectile/bullet/c38/match
	name = ".38 Match bullet"
	ricochets_max = 4
	ricochet_chance = 100
	ricochet_auto_aim_angle = 45
	ricochet_auto_aim_range = 8
	ricochet_incidence_leeway = 50
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1
	wound_bonus = 7
	armour_penetration = BULLET_BR2

/obj/item/projectile/bullet/c38/match/bouncy
	name = ".38 Bouncy bullet" // уточняем название, чтобы не путули с резиной
	damage = 10
	stamina = 30
	armour_penetration = -30
	ricochets_max = 6
	ricochet_incidence_leeway = 70
	ricochet_chance = 130
	ricochet_decay_damage = 0.8
	shrapnel_type = NONE
	armour_penetration = BULLET_BR0
	sharpness = SHARP_NONE
	embedding = null

// premium .38 ammo from cargo, weak against armor, lower base damage, but excellent at embedding and causing slice wounds at close range
/obj/item/projectile/bullet/c38/dumdum

	name = ".38 DumDum bullet"
	damage = 15
	armour_penetration = BULLET_BR0 - 30
	ricochets_max = 0
	sharpness = SHARP_EDGED
	wound_bonus = 20
	bare_wound_bonus = 20
	embedding = list(embed_chance=75, fall_chance=3, jostle_chance=4, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=5, jostle_pain_mult=6, rip_time=10)
	wound_falloff_tile = -5
	embed_falloff_tile = -15


/obj/item/projectile/bullet/c38/rubber
	name = ".38 Rubber bullet"
	damage = 2
	stamina = 50
	shrapnel_type = NONE
	sharpness = SHARP_NONE
	embedding = null
	armour_penetration = BULLET_BR0 //а вот тут почему то блять никто не написал про БР0 и то что это резина

/obj/item/projectile/bullet/c38/trac
	name = ".38 TRAC bullet"
	armour_penetration = BULLET_BR0
	damage = 5
	ricochets_max = 0

/obj/item/projectile/bullet/c38/trac/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!iscarbon(target))
		return

	var/mob/living/carbon/C = target
	if(locate(/obj/item/gps/embed_gps) in C)
		return

	var/obj/item/gps/embed_gps/gps = new(target)
	gps.tryEmbed(C, forced = TRUE, silent = TRUE)

	// var/obj/item/implant/tracking/c38/imp
	// for(var/obj/item/implant/tracking/c38/TI in M.implants) //checks if the target already contains a tracking implant
	// 	imp = TI
	// 	return
	// if(!imp)
	// 	imp = new /obj/item/implant/tracking/c38(M)
	// 	imp.implant(M)

/obj/item/projectile/bullet/c38/hotshot //similar to incendiary bullets, but do not leave a flaming trail
	name = ".38 Hot Shot bullet"
	armour_penetration = BULLET_BR3
	damage = 30
	ricochets_max = 0

/obj/item/projectile/bullet/c38/hotshot/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.adjust_fire_stacks(6)
		M.IgniteMob()

/obj/item/projectile/bullet/c38/iceblox //see /obj/item/projectile/temp for the original code
	name = ".38 Iceblox bullet"
	armour_penetration = BULLET_BR3
	damage = 20
	var/temperature = 100
	ricochets_max = 0

/obj/item/projectile/bullet/c38/iceblox/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(isliving(target))
		var/mob/living/M = target
		M.adjust_bodytemperature(((100-blocked)/100)*(temperature - M.bodytemperature))


// .357 (Syndie Revolver)

// .357 — BR4 (мощный револьверный)
/obj/item/projectile/bullet/a357
	name = ".357 bullet"
	damage = 65
	armour_penetration = BULLET_BR7
	wound_bonus = 25
	ricochets_max = 2
	ricochet_chance = 100

/obj/item/projectile/bullet/a357/ap
	name = ".357 armor-piercing bullet"
	damage = 50
	armour_penetration = BULLET_BR13

// admin only really, for ocelot memes
/obj/item/projectile/bullet/a357/match
	name = ".357 match bullet"
	ricochets_max = 5
	ricochet_chance = 140
	ricochet_auto_aim_angle = 50
	ricochet_auto_aim_range = 6
	ricochet_incidence_leeway = 80
	ricochet_decay_chance = 1

/obj/item/projectile/bullet/a357/dumdum
	name = ".357 DumDum bullet"
	damage = 85
	armour_penetration = BULLET_BR0 - 20
	wound_bonus = 45
	bare_wound_bonus = 45
	sharpness = SHARP_EDGED
	embedding = list(embed_chance=90, fall_chance=2, jostle_chance=5, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=5, jostle_pain_mult=6, rip_time=10)
	wound_falloff_tile = -1
	embed_falloff_tile = -5

/// 12.7x55mm — The Central Requiem: тяжёлый урон, тупой удар (blunt) с сильным бонусом к ранам
/obj/item/projectile/bullet/a357/requiem
	name = "12.7x55mm bullet"
	damage = 80
	armour_penetration = BULLET_BR12  // Камон - какие 20 бронепробития для ЕРТ гана красного кода
	sharpness = SHARP_NONE
	wound_bonus = 70
	bare_wound_bonus = 80
	wound_falloff_tile = -0.5

//.45-70 GOVT (Gunslinger's Derringer)
//0bserver here. For all that is holy, do me a flavor, and do NOT allow people easy access to this ammo. This is meant for extremely lucky traitors, and nuclear operatives.

// .45-70 Govt — BR7 (крупный охотничий калибр)
/obj/item/projectile/bullet/g4570
	name = ".45-70 Govt bullet"
	damage = 60
	armour_penetration = BULLET_BR8
	wound_bonus = 10

//.41 cal сб ревик

/obj/item/ammo_casing/cal41/rubber
	name= ".41 rubber bullet casing"
	desc = "An .41 rubber casing."
	caliber = ".41cal"
	projectile_type = /obj/item/projectile/bullet/cal41/rubber
	can_be_printed = TRUE
	custom_materials = list(/datum/material/glass = 800)

/obj/item/projectile/bullet/cal41/rubber
	name = ".41 rubber bullet"
	damage = 2
	stamina = 50
	shrapnel_type = NONE
	sharpness = SHARP_NONE
	embedding = null
	armour_penetration = BULLET_BR0

/obj/item/ammo_casing/cal41/lethal
	name= ".41 bullet casing"
	desc = "An .41 casing."
	caliber = ".41cal"
	projectile_type = /obj/item/projectile/bullet/cal41/lethal
	can_be_printed = TRUE
	custom_materials = list(/datum/material/iron = 800)

/obj/item/projectile/bullet/cal41/lethal
	name = ".41 bullet"
	damage = 33
	shrapnel_type = NONE
	sharpness = SHARP_NONE
	embedding = null
	armour_penetration = BULLET_BR2

/obj/item/ammo_casing/cal41/incendiary
	name= ".41 bullet casing"
	desc = "An .41 casing."
	caliber = ".41cal"
	projectile_type = /obj/item/projectile/bullet/cal41/incendiary
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/glass = 800)

/obj/item/projectile/bullet/cal41/incendiary
	name = ".41 bullet"
	damage = 30
	shrapnel_type = NONE
	sharpness = SHARP_NONE
	embedding = null
	armour_penetration = BULLET_BR1
	

/obj/item/projectile/bullet/cal41/incendiary/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(iscarbon(target))
		var/mob/living/carbon/M = target
		M.adjust_fire_stacks(6)
		M.IgniteMob()

/obj/item/ammo_casing/cal41/dumdum
	name= ".41 incendiary dumdum casing"
	desc = "An .41 dumdum casing."
	caliber = ".41cal"
	projectile_type = /obj/item/projectile/bullet/cal41/dumdum
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800, /datum/material/plastic = 200)

/obj/item/projectile/bullet/cal41/dumdum
	name = ".38 DumDum bullet"
	damage = 20
	armour_penetration = BULLET_BR0 - 30
	ricochets_max = 0
	sharpness = SHARP_EDGED
	wound_bonus = 20
	bare_wound_bonus = 20
	embedding = list(embed_chance=75, fall_chance=3, jostle_chance=4, ignore_throwspeed_threshold=TRUE, pain_stam_pct=0.4, pain_mult=5, jostle_pain_mult=6, rip_time=10)
	wound_falloff_tile = -5
	embed_falloff_tile = -15

/obj/item/ammo_casing/cal41/magnum
	name= ".41 Remington Magnum casing"
	desc = "An .41 Remington Magnum"
	caliber = ".41cal"
	projectile_type = /obj/item/projectile/bullet/cal41/magnum
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800, /datum/material/plastic = 200)

/obj/item/projectile/bullet/cal41/magnum
	name = ".41 Remington Magnum bullet"
	damage = 40
	shrapnel_type = NONE
	sharpness = SHARP_NONE
	embedding = null
	armour_penetration = BULLET_BR4
	wound_bonus = 3

/obj/item/ammo_casing/cal41/fmj
	name= ".41 FMJ casing"
	desc = "An .41 FMJ bullet"
	caliber = ".41cal"
	projectile_type = /obj/item/projectile/bullet/cal41/fmj
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800, /datum/material/plastic = 200)

/obj/item/projectile/bullet/cal41/fmj
	name = ".41 Remington fmj bullet"
	damage = 30
	shrapnel_type = NONE
	sharpness = SHARP_NONE
	embedding = null
	armour_penetration = BULLET_BR5

//410 револьвер дробовик

/obj/item/ammo_casing/cal410
	name= ".410 rubber shot"
	desc = "An .410 rubber shot."
	caliber = ".410cal"
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "410rubber"
	pellets = 6
	variance = 50
	projectile_type = /obj/item/projectile/bullet/pellet/exorcist_rubber
	can_be_printed = TRUE
	custom_materials = list(/datum/material/glass = 800)

/obj/item/projectile/bullet/pellet/exorcist_rubber
	name = "rubbershot pellet"
	icon_state = "pellet"
	damage = 1
	stamina = 4
	armour_penetration = BULLET_BR0
	sharpness = SHARP_NONE
	embedding = null
	ricochets_max = 4
	ricochet_chance = 50
	ricochet_auto_aim_angle = 45
	ricochet_auto_aim_range = 8
	ricochet_incidence_leeway = 50
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1

/obj/item/ammo_casing/cal410/lethal
	name= ".410 snakeshot"
	desc = "An .410 snakeshot."
	caliber = ".410cal"
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "410snakeshot"
	pellets = 6
	variance = 50
	projectile_type = /obj/item/projectile/bullet/pellet/exorcist_snakeshot
	can_be_printed = TRUE
	custom_materials = list(/datum/material/iron = 800)

/obj/item/projectile/bullet/pellet/exorcist_snakeshot
	name = "snakeshot pellet"
	icon_state = "pellet"
	armour_penetration = BULLET_BR1
	damage = 6
	tile_dropoff_ap = 6
	wound_bonus = 1
	bare_wound_bonus = 5
	wound_falloff_tile = -2.5

//взрывной револьвер/кинетик

/obj/item/ammo_casing/magnum44
	name = ".44 Magnum glycerine rounds"
	desc = "Особый патрон. Пуля наносит легкий урон и вживляет дистанционную взрывчатку под кожу."
	caliber = ".44 magnum"
	projectile_type = /obj/item/projectile/bullet/judgement_beacon

/obj/item/ammo_casing/magnum44_kinetic
	name = ".44 magnum kinetic rounds"
	caliber = ".44 magnum"
	desc = "Особый патрон. Пуля наносит огромный урон, отскакивает от стен и откидывает цели назад."
	projectile_type = /obj/item/projectile/bullet/judgement_kinetic_ricochet

// Маячок (10 урона + МНОЖЕСТВЕННОЕ вживление имплантов)
/obj/item/projectile/bullet/judgement_beacon
	name = ".44 Magnum glycerine rounds"
	damage = 10 

/obj/item/projectile/bullet/judgement_beacon/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!iscarbon(target))
		return

	var/mob/living/carbon/C = target
	
	if(!firer || !istype(firer.get_active_held_item(), /obj/item/gun/ballistic/revolver/judgement))
		return

	var/obj/item/gun/ballistic/revolver/judgement/J = firer.get_active_held_item()

	var/obj/item/gps/embed_gps/judgement_beacon_bomb/bomb = new(target)
	bomb.my_gun = J
	bomb.my_target = C
	bomb.tryEmbed(C, forced = TRUE, silent = TRUE)
	
	J.active_beacons.Add(C)
	
	to_chat(firer, "<span class='notice'>Револьвер издает писк</span>")

/obj/effect/temp_visual/judgement_kinetic_blast
	name = "кинетическая вспышка"
	desc = "Визуальный эффект кинетического удара."
	icon = 'modular_bluemoon/icons/obj/effect/projectiles/generic.dmi' 
	icon_state = "fire" 
	duration = 5 // Длительность анимации в тиках (0.5 секунды), после чего игра сама удалит эффект

/obj/item/projectile/bullet/judgement_kinetic_ricochet
	name = ".44 Magnum round"
	damage = 70
	ricochets_max = 4
	ricochet_chance = 100
	ricochet_auto_aim_angle = 90
	ricochet_auto_aim_range = 10
	ricochet_incidence_leeway = 50
	ricochet_decay_chance = 1
	ricochet_decay_damage = 1

/obj/item/projectile/bullet/judgement_kinetic_ricochet/on_hit(atom/target, blocked = 0)
	. = ..()
	
	var/turf/hit_turf = get_turf(target)
	if(hit_turf)
		new /obj/effect/temp_visual/judgement_kinetic_blast(hit_turf)
		playsound(hit_turf, 'sound/weapons/genhit2.ogg', 40, 1)

	// КРИВО СПИЗДИЛ КОД С ПАУВЕР ФИСТА
	if(isliving(target))
		var/mob/living/L = target
		
		if(hasvar(L, "move_resist") && L.vars["move_resist"] >= INFINITY)
			return

		var/atom/throw_target = get_edge_target_turf(L, get_dir(src, get_step_away(L, starting)))
		
		if(throw_target)
			L.throw_at(throw_target, 2, 1)
			to_chat(L, "<span class='userdanger'>Тяжелый кинетический импульс пули сбивает вас с ног и отбрасывает назад!</span>")

/obj/item/gps/embed_gps/judgement_beacon_bomb
	name = "Маячок-детонатор"
	desc = "Миниатюрный скрытый заряд, внедренный под кожу. Дистанционно взрывается по радиосигналу револьвера или автоматически через 2 минуты."
	icon = 'modular_bluemoon/icons/obj/guns/revolvers.dmi'
	icon_state = "bomb_beacon" 
	
	var/obj/item/gun/ballistic/revolver/judgement/my_gun 
	var/mob/living/carbon/my_target 

/obj/item/gps/embed_gps/judgement_beacon_bomb/Initialize(mapload)
	. = ..()
	src.lifespan = 2 MINUTES 
	addtimer(CALLBACK(src, PROC_REF(auto_detonate)), src.lifespan)

/obj/item/gps/embed_gps/judgement_beacon_bomb/proc/auto_detonate()
	if(QDELETED(src))
		return

	if(my_target && !QDELETED(my_target))
		to_chat(my_target, "<span class='userdanger'>Вживленный внутри вас маячок издает критический писк и детонирует!</span>")
		
		var/turf/T = get_turf(my_target)
		if(T)
			new /obj/effect/temp_visual/kinetic_blast(T)
			playsound(T, 'sound/weapons/resonator_blast.ogg', 50, 1)
		
		my_target.ex_act(EXPLODE_LIGHT)
		
		if(my_gun && !QDELETED(my_gun))
			my_gun.active_beacons -= my_target
	else
		var/turf/T = get_turf(src)
		if(T)
			new /obj/effect/particle_effect/smoke(T)
	
	qdel(src)
