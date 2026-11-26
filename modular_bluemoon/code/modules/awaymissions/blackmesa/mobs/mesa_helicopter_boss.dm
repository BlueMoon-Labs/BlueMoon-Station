#define HELI_TICK_DS 10
#define HELI_ENGAGE_RANGE 30
#define HELI_OVERHEAT_DS 50
#define HELI_OVERHEAT_DAMAGE_MULT 1.5
#define HELI_STRAFE_WARN_DS 15
#define HELI_STRAFE_STEP_DS 2
#define HELI_STRAFE_MAX_LEN 20
#define HELI_LOCKON_DS 20
#define HELI_RELOCATE_WARN_DS 8
#define HELI_ROTOR_RANGE 14

/obj/effect/landmark/awaymission/blackmesa/helicopter_pad
	name = "Helicopter Pad Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/landmark/awaymission/blackmesa/helicopter_center
	name = "Helicopter Command Pad Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/landmark/awaymission/blackmesa/helicopter_cinematic_pad
	name = "Helicopter Landing Zone Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/landmark/awaymission/blackmesa/helicopter_target_pad
	name = "Helicopter Target Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/landmark/awaymission/blackmesa/helicopter_rift_in
	name = "Helicopter Rift Landmark (Entrance)"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/landmark/awaymission/blackmesa/helicopter_rift_out
	name = "Helicopter Rift Landmark (Exit)"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/landmark/awaymission/blackmesa/mesa_rift
	name = "Mesa Rift Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/landmark/awaymission/blackmesa/osprey_pad
	name = "Osprey Pad Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/landmark/awaymission/blackmesa/osprey_drop
	name = "Osprey Drop Zone Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

/obj/effect/temp_visual/helicopter_missile_boom
	name = "missile impact"
	icon = 'icons/effects/effects.dmi'
	icon_state = "explosion"
	layer = ABOVE_MOB_LAYER
	duration = 8
	randomdir = FALSE

/obj/item/projectile/bullet/helicopter_autocannon
	name = "autocannon shell"
	icon = 'icons/obj/projectiles.dmi'
	icon_state = "bullet"
	damage = 20
	damage_type = BRUTE
	armour_penetration = BULLET_BR10
	pixels_per_second = TILES_TO_PIXELS(60)
	range = 32
	knockdown = 0
	dismemberment = 15
	flag = BULLET
	hitsound_wall = "ricochet"

/obj/item/projectile/bullet/a84mm/helicopter_rocket
	name = "unguided rocket"
	icon_state = "missile"
	damage = 20
	pixels_per_second = TILES_TO_PIXELS(45)
	range = 45
	allow_crit_gib = FALSE

/obj/item/projectile/bullet/a84mm/helicopter_rocket/do_boom(atom/target, random_crit_gib = FALSE)
	if(isliving(target))
		var/turf/T = get_turf(target)
		if(T)
			T.visible_message(span_bolddanger("[target] накрывает взрывом apache-ракеты!"), span_bolddanger("По вам попала ракета!"))
	if(!isliving(target))
		explosion(target, heavy_impact_range = 1, light_impact_range = 2, flame_range = 2, flash_range = 0)
	else
		explosion(target, light_impact_range = 1, flame_range = 2, flash_range = 0)
		if(random_crit_gib)
			var/mob/living/gibbed_dude = target
			new /obj/effect/temp_visual/crit(get_turf(gibbed_dude))
			gibbed_dude.gib(FALSE, FALSE, FALSE)

/mob/living/simple_animal/hostile/megafauna/osprey
	name = "Osprey"
	desc = "An armored transport helicopter on a troop-insertion run. Small arms cannot scratch it."
	icon = 'modular_bluemoon/icons/mob/ospreylive.dmi'
	icon_state = "osprey"
	pixel_x = -272
	pixel_y = -154
	maptext_height = 64
	maptext_width = 64
	health = 50000
	maxHealth = 50000

	faction = list("hostile", FACTION_XEN, FACTION_BLACKOPS)
	environment_smash = ENVIRONMENT_SMASH_NONE
	stat_attack = CONSCIOUS
	mob_biotypes = MOB_ROBOTIC|MOB_EPIC
	damage_coeff = list(BRUTE = 0, BURN = 0, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	weather_immunities = list(TRAIT_LAVA_IMMUNE, TRAIT_ASHSTORM_IMMUNE, TRAIT_TOXIMMUNE)
	ai_profile_type = null
	AIStatus = AI_OFF
	density = FALSE
	layer = ABOVE_ALL_MOB_LAYER
	pixel_z = 80

/mob/living/simple_animal/hostile/megafauna/osprey/Initialize(mapload)
	. = ..()
	if(mapload)

		qdel(src)
		return

/mob/living/simple_animal/hostile/megafauna/osprey/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	return FALSE

/mob/living/simple_animal/hostile/megafauna/osprey/handle_automated_movement()
	return FALSE

/mob/living/simple_animal/hostile/megafauna/osprey/handle_automated_action()
	return

/mob/living/simple_animal/hostile/megafauna/helicopter
	name = "Apache"
	desc = "An aviation unit circling the sector. Its autocannon and rocket pods do not forgive mistakes."
	icon = 'modular_bluemoon/icons/mob/helicopter.dmi'
	icon_state = "apache"
	pixel_x = -69
	pixel_y = -59
	// 3x3 hitbox: tile under the mob is the bottom-middle tile of the box
	// (bounds cover x-1..x+1, y-2..y relative to the mob's turf).
	bound_x = -32
	bound_y = 0
	bound_width = 96
	bound_height = 96
	maptext_height = 64
	maptext_width = 64
	health = 7000
	maxHealth = 7000

	faction = list("hostile", FACTION_XEN, FACTION_BLACKOPS)
	environment_smash = ENVIRONMENT_SMASH_NONE
	stat_attack = CONSCIOUS
	mob_biotypes = MOB_ROBOTIC|MOB_EPIC
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	weather_immunities = list(TRAIT_LAVA_IMMUNE, TRAIT_ASHSTORM_IMMUNE, TRAIT_TOXIMMUNE)
	ai_profile_type = null
	AIStatus = AI_OFF
	projectiletype = /obj/item/projectile/bullet/helicopter_autocannon
	light_range = 4
	deathmessage = "crashes in a fireball, scattering burning debris across the sector."
	death_sound = 'sound/effects/Explosion2.ogg'

	var/heli_busy = FALSE
	var/heli_tick_timer
	var/heli_rotor_channel
	var/list/heli_rotor_listeners = list()
	var/list/heli_pads = list()
	var/obj/effect/landmark/awaymission/blackmesa/helicopter_center/heli_center
	var/list/heli_bounds = null
	var/attacks_until_relocate = 3
	var/overheated_until = 0
	var/last_fire_warning = 0
	var/overheat_visual_active = FALSE
	var/list/heli_drop_thresholds = list(75, 50, 35, 10)
	var/list/heli_drops_done = list()
	var/heli_died = FALSE
	var/heli_cutscene = FALSE
	var/heli_airborne = FALSE
	var/heli_critical = FALSE
	var/heli_crit_channel
	var/heli_crit_beep_next = 0
	var/heli_theme_channel
	var/list/heli_theme_listeners = list()

/mob/living/simple_animal/hostile/megafauna/helicopter/Initialize(mapload)
	. = ..()
	if(mapload)

		qdel(src)
		return
	ensure_landmarks()
	compute_bounds()
	attacks_until_relocate = rand(2, 3)
	heli_tick_timer = addtimer(CALLBACK(src, PROC_REF(heli_tick)), HELI_TICK_DS, TIMER_STOPPABLE | TIMER_LOOP)
	heli_theme_channel = SSsounds.reserve_sound_channel(src)
	heli_rotor_channel = SSsounds.reserve_sound_channel(src)
	heli_crit_channel = SSsounds.reserve_sound_channel(src)

	heli_update_hull_icon()
	heli_update_rotor_sound()
	visible_message("<span class='boldannounce'>[src] enters the arena airspace!</span>")
	if(SSblackmesa_events)
		SSblackmesa_events.mesa_announce("Внимание! Боевой вертолёт \"Apache\" вошёл в зону операции. Держитесь подальше от точек сброса ракет!", "Airborne threat", 'sound/vehicles/high_eng.ogg')

/mob/living/simple_animal/hostile/megafauna/helicopter/Destroy()
	stop_heli_sounds()
	deltimer(heli_tick_timer)
	heli_tick_timer = null
	SSsounds.free_datum_channels(src)
	heli_pads = null
	heli_center = null
	heli_bounds = null
	. = ..()

/mob/living/simple_animal/hostile/megafauna/helicopter/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	if(heli_cutscene && !forced)
		return FALSE
	if(amount > 0 && world.time < overheated_until)
		amount *= HELI_OVERHEAT_DAMAGE_MULT
	. = ..()
	heli_update_hull_icon()
	return .

/mob/living/simple_animal/hostile/megafauna/helicopter/bullet_act(obj/item/projectile/Proj, def_zone, piercing_hit = FALSE)
	if(!Proj)
		return
	SEND_SIGNAL(src, COMSIG_ATOM_BULLET_ACT, Proj, def_zone)
	var/blocked = piercing_hit
	if(simple_mob_flags & SIMPLE_MOB_PROJECTILE_ARMOR)
		blocked = max(blocked, run_armor_check(def_zone, Proj.flag, armour_penetration = Proj.armour_penetration, silent = TRUE))
	apply_damage(Proj.damage, Proj.damage_type, 0, blocked)
	Proj.on_hit(src)
	return BULLET_ACT_HIT

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_update_hull_icon()
	var/hull_state = "apache"
	if(health <= maxHealth * 0.4)
		hull_state = "apachedam2"
	else if(health <= maxHealth * 0.75)
		hull_state = "apachedam1"
	if(icon_state != hull_state)
		icon_state = hull_state

/mob/living/simple_animal/hostile/megafauna/helicopter/visible_message(message, self_message, blind_message, vision_distance = DEFAULT_MESSAGE_RANGE, list/ignored_mobs, mob/target, target_message, omni = FALSE, runechat_popup, rune_msg, visible_message_flags = NONE, separation = " ")
	if(heli_cutscene)
		return
	return ..()

/mob/living/simple_animal/hostile/megafauna/helicopter/death(gibbed, list/force_grant)
	if(health <= 0 && !heli_died)
		heli_died = TRUE
		mesa_boss_zone_reward(src)
		stop_heli_sounds()
		new /datum/helicopter_death_fx(get_turf(src))
		heli_spawn_death_portal()
	. = ..(gibbed, force_grant)

	if(!gibbed && !QDELETED(src) && stat == DEAD)
		gib()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_spawn_death_portal()
	var/turf/A = null
	var/turf/B = null
	var/obj/effect/landmark/awaymission/blackmesa/helicopter_rift_in/RIN = locate(/obj/effect/landmark/awaymission/blackmesa/helicopter_rift_in) in GLOB.landmarks_list
	if(RIN)
		A = get_turf(RIN)
	if(!istype(A))
		A = get_turf(src)
	if(!istype(A))
		return
	var/obj/effect/landmark/awaymission/blackmesa/helicopter_rift_out/ROUT = locate(/obj/effect/landmark/awaymission/blackmesa/helicopter_rift_out) in GLOB.landmarks_list
	if(ROUT)
		B = get_turf(ROUT)
	if(!istype(B) || B.z != A.z || B == A)
		B = null
	if(!B)
		if(heli_center)
			B = get_turf(heli_center)
	if(!istype(B) || B.z != A.z || B == A)
		B = null
	if(!B)
		for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in heli_pads)
			var/turf/PT = get_turf(P)
			if(istype(PT) && PT.z == A.z && PT != A)
				B = PT
				break
	if(!istype(B))
		return

	var/obj/effect/portal/mesa_rift/P = new(A)
	if(!istype(P))
		return
	P.hard_target = B
	P.hardlinked = FALSE

/datum/helicopter_death_fx
	var/turf/T

/datum/helicopter_death_fx/New(turf/death_turf)
	T = death_turf
	INVOKE_ASYNC(src, PROC_REF(run_effects))

/datum/helicopter_death_fx/proc/run_effects()
	if(!istype(T))
		qdel(src)
		return
	playsound(T, 'sound/effects/space_wind.ogg', 90, TRUE, -4)
	sleep(4)
	if(!istype(T))
		qdel(src)
		return
	playsound(T, 'sound/effects/Explosion1.ogg', 100, TRUE, -2)
	playsound(T, 'sound/effects/Explosion2.ogg', 90, TRUE, -2)
	new /obj/effect/temp_visual/helicopter_missile_boom(T)
	var/turf/adjacent_t = get_step(T, pick(GLOB.alldirs))
	if(adjacent_t)
		new /obj/effect/temp_visual/helicopter_missile_boom(adjacent_t)
	for(var/mob/living/L in range(6, T))
		if(QDELETED(L) || L.stat == DEAD)
			continue
		L.adjustBruteLoss(120)
		shake_camera(L, 8, 1)
	qdel(src)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/ensure_landmarks()
	for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in GLOB.landmarks_list)
		heli_pads += P
	heli_center = locate(/obj/effect/landmark/awaymission/blackmesa/helicopter_center) in GLOB.landmarks_list
	if(heli_pads.len >= 2)
		return

	var/list/mesa_areas = heli_mesa_areas()
	if(!mesa_areas || !mesa_areas.len)
		return
	var/attempts = 0
	while(heli_pads.len < 6 && attempts < 60)
		attempts++
		var/turf/T = heli_random_mesa_turf(mesa_areas)
		if(!T)
			continue
		var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P = new(T)
		heli_pads += P
	if(!heli_center)
		var/turf/CT = heli_random_mesa_turf(mesa_areas)
		if(CT)
			heli_center = new /obj/effect/landmark/awaymission/blackmesa/helicopter_center(CT)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_mesa_areas()
	var/list/areas = null
	if(SSblackmesa_events)
		areas = SSblackmesa_events.cached_mission_areas
	if(!areas || !areas.len)
		areas = get_areas(/area/awaymission/ihategordon, TRUE)
	return areas

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_random_mesa_turf(list/mesa_areas)
	if(!mesa_areas || !mesa_areas.len)
		return null
	for(var/i in 1 to 10)
		var/area/A = pick(mesa_areas)
		var/list/turfs = get_area_turfs(A)
		if(!turfs.len)
			continue
		for(var/j in 1 to 10)
			var/turf/T = pick(turfs)
			if(T && istype(T, /turf/open) && !is_blocked_turf(T, TRUE))
				return T
	return null

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/compute_bounds()
	heli_bounds = null
	var/min_x = INFINITY
	var/max_x = -INFINITY
	var/min_y = INFINITY
	var/max_y = -INFINITY
	var/bounds_z = z
	for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in heli_pads)
		var/turf/PT = get_turf(P)
		if(!PT || PT.z != bounds_z)
			continue
		if(PT.x < min_x) min_x = PT.x
		if(PT.x > max_x) max_x = PT.x
		if(PT.y < min_y) min_y = PT.y
		if(PT.y > max_y) max_y = PT.y
	if(min_x == INFINITY)

		var/turf/ST = get_turf(src)
		if(!ST)
			return
		min_x = ST.x - 8; max_x = ST.x + 8
		min_y = ST.y - 8; max_y = ST.y + 8
	heli_bounds = list(min_x, max_x, min_y, max_y, bounds_z)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/get_mesa_targets() as list
	. = list()
	var/turf/ST = get_turf(src)
	if(!ST || stat == DEAD)
		return .
	for(var/mob/living/L in GLOB.player_list)
		if(QDELETED(L) || L.stat == DEAD)
			continue
		var/turf/LT = get_turf(L)
		if(!LT || LT.z != ST.z)
			continue
		if(get_dist(ST, LT) > HELI_ENGAGE_RANGE)
			continue

		if(!isturf(L.loc))
			continue

		if(!istype(get_area(L), /area/awaymission/ihategordon))
			continue
		. += L
	return .

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/nearest_target(list/targets)
	. = null
	var/best_dist = INFINITY
	var/turf/ST = get_turf(src)
	for(var/atom/A as anything in targets)
		if(QDELETED(A))
			continue
		if(isliving(A))
			var/mob/living/L = A
			if(L.stat == DEAD)
				continue
		var/turf/AT = get_turf(A)
		if(!AT || AT.z != ST.z)
			continue
		var/d = get_dist(ST, AT)
		if(d < best_dist)
			best_dist = d
			. = A
	return .

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_tick()
	if(QDELETED(src))
		return
	heli_update_rotor_sound()
	heli_update_theme_sound()
	if(stat != CONSCIOUS || heli_busy || heli_cutscene)
		return

	var/overheated = world.time < overheated_until
	if(overheated != overheat_visual_active)
		overheat_visual_active = overheated
		if(overheated)
			visible_message("<span class='bolddanger'>[src]'s weapons are overheating - it is vulnerable!</span>")

	var/critical = health <= maxHealth * 0.3
	if(critical != heli_critical)
		heli_critical = critical
		if(critical)
			visible_message("<span class='bolddanger'>[src] is critically damaged - its systems are failing!</span>")

	if(critical && world.time >= heli_crit_beep_next)
		heli_crit_beep_next = world.time + 100
		INVOKE_ASYNC(src, PROC_REF(heli_critical_beep_burst))
	if(overheated)
		return

	var/hp_percent = round((health / maxHealth) * 100)
	for(var/threshold in heli_drop_thresholds)
		if(hp_percent <= threshold && !(threshold in heli_drops_done))
			heli_drops_done += threshold
			start_osprey_drop()
			return
	var/list/targets = get_mesa_targets()
	if(!targets.len)
		return
	if(attacks_until_relocate <= 0)
		if(heli_pads.len >= 2)
			start_relocate()
		else
			attacks_until_relocate = rand(2, 3)
		return
	var/roll = rand(100)
	if(roll < 40)
		start_autocannon()
	else if(roll < 62)
		if(heli_plan_strafe())
			start_strafe()
		else
			start_autocannon()
	else if(roll < 80)
		start_scan_burst()
	else
		start_missiles()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_attack_done()
	if(QDELETED(src))
		return
	attacks_until_relocate--
	heli_busy = FALSE

	dir = SOUTH

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/start_autocannon()
	heli_busy = TRUE
	INVOKE_ASYNC(src, PROC_REF(autocannon_seq))

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/autocannon_seq()
	var/shots = rand(5, 8)
	var/list/targets = get_mesa_targets()
	if(!targets.len)
		heli_attack_done()
		return
	visible_message("<span class='danger'><b>[src]</b> opens up with its autocannon!</span>")
	for(var/i in 1 to shots)
		if(QDELETED(src) || stat != CONSCIOUS)
			heli_busy = FALSE
			return
		if(i == 1 || i % 3 == 0)
			targets = get_mesa_targets()
		if(!targets.len)
			break
		var/atom/T = nearest_target(targets)
		if(!T)
			T = pick(targets)
		if(T)
			heli_fire(T)
		sleep(4)
	heli_attack_done()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_fire(atom/targeted_atom)
	if(QDELETED(src) || QDELETED(targeted_atom) || heli_cutscene)
		return
	var/turf/startloc = get_turf(src)
	var/turf/target_turf = get_turf(targeted_atom)
	if(!startloc || !target_turf || target_turf.z != startloc.z)
		return
	if(isliving(targeted_atom) && world.time >= last_fire_warning)
		last_fire_warning = world.time + 20
		var/mob/living/L = targeted_atom
		L.visible_message(span_bolddanger("[src] ведёт по вам огонь!"), span_bolddanger("Apache стреляет по вам!"))
	var/obj/item/projectile/P = new /obj/item/projectile/bullet/helicopter_autocannon(startloc)
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/apache/apacheshot.ogg', 80, TRUE, -4)
	P.firer = src
	P.fired_from = src
	P.preparePixelProjectile(targeted_atom, src)
	P.fire()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_plan_strafe()

	. = null
	if(!heli_bounds)
		return .
	var/turf/ST = get_turf(src)
	if(!ST)
		return .
	var/horizontal = (heli_bounds[2] - heli_bounds[1]) >= (heli_bounds[4] - heli_bounds[3])
	var/plan = heli_strafe_lane(horizontal, ST)
	if(!plan && (heli_bounds[2] - heli_bounds[1]) != (heli_bounds[4] - heli_bounds[3]))
		plan = heli_strafe_lane(!horizontal, ST)
	. = plan
	return .

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_strafe_lane(horizontal, turf/ST)
	var/min_x = heli_bounds[1]
	var/max_x = heli_bounds[2]
	var/min_y = heli_bounds[3]
	var/max_y = heli_bounds[4]
	var/z = heli_bounds[5]
	if(ST.z != z)
		return null
	var/low = horizontal ? min_x : min_y
	var/high = horizontal ? max_x : max_y
	var/span = high - low
	if(span < 4)
		return null
	var/win_len = min(span, HELI_STRAFE_MAX_LEN)

	var/anchor = horizontal ? ST.x : ST.y
	var/cross_anchor = horizontal ? ST.y : ST.x
	var/list/targets = get_mesa_targets()
	if(targets.len)
		var/sum = 0
		var/csum = 0
		var/n = 0
		for(var/atom/A in targets)
			var/turf/AT = get_turf(A)
			if(!AT || AT.z != z)
				continue
			sum += horizontal ? AT.x : AT.y
			csum += horizontal ? AT.y : AT.x
			n++
		if(n)
			anchor = round(sum / n)
			cross_anchor = round(csum / n)
	var/win_start = clamp(anchor - round(win_len / 2), low, high - win_len)
	var/win_end = win_start + win_len

	var/cross_low = horizontal ? min_y : min_x
	var/cross_high = horizontal ? max_y : max_x
	var/list/candidates = list(
		clamp(horizontal ? ST.y : ST.x, cross_low + 1, cross_high - 1),
		clamp(cross_anchor, cross_low + 1, cross_high - 1),
		clamp(round((cross_low + cross_high) / 2), cross_low + 1, cross_high - 1)
	)
	var/seen = list()
	for(var/fc in candidates)
		if(fc in seen)
			continue
		seen += fc
		var/step_dir = pick(-1, 1)
		var/start_coord = step_dir > 0 ? win_start : win_end
		var/end_coord = step_dir > 0 ? win_end : win_start
		var/c = start_coord
		var/clear = TRUE
		while(c != end_coord)
			var/turf/T = horizontal ? locate(c, fc, z) : locate(fc, c, z)
			if(!T || !istype(T, /turf/open) || is_blocked_turf(T, TRUE))
				clear = FALSE
				break
			c += step_dir
		if(!clear)
			continue
		var/turf/END_T = horizontal ? locate(end_coord, fc, z) : locate(fc, end_coord, z)
		if(!END_T || !istype(END_T, /turf/open) || is_blocked_turf(END_T, TRUE))
			continue
		return list(horizontal, fc, start_coord, end_coord, step_dir, z)
	return null

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/start_strafe()
	heli_busy = TRUE
	INVOKE_ASYNC(src, PROC_REF(strafe_seq))

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/strafe_seq()
	var/plan = heli_plan_strafe()
	if(!plan)
		heli_attack_done()
		return
	var/horizontal = plan[1]
	var/fixed_coord = plan[2]
	var/start_coord = plan[3]
	var/end_coord = plan[4]
	var/step_dir = plan[5]
	var/z = plan[6]

	var/turf/start_turf = horizontal ? locate(start_coord, fixed_coord, z) : locate(fixed_coord, start_coord, z)
	if(!start_turf)
		heli_attack_done()
		return
	forceMove(start_turf)
	setDir(horizontal ? (step_dir > 0 ? EAST : WEST) : (step_dir > 0 ? NORTH : SOUTH))

	playsound(src, 'sound/vehicles/high_eng.ogg', 85, TRUE, -4)
	playsound(src, 'sound/vehicles/rocketlaunch.ogg', 70, TRUE, -4)
	visible_message("<span class='bolddanger'>[src] begins a strafing run!</span>")
	sleep(HELI_STRAFE_WARN_DS)
	if(QDELETED(src) || stat != CONSCIOUS)
		heli_busy = FALSE
		return

	while(TRUE)
		var/coord = horizontal ? x : y
		if(coord == end_coord)
			break

		if((coord - end_coord) * step_dir > 0)
			break
		if(QDELETED(src) || stat != CONSCIOUS)
			heli_busy = FALSE
			return
		var/turf/next_turf = horizontal ? locate(x + step_dir, y, z) : locate(x, y + step_dir, z)
		if(!next_turf || !istype(next_turf, /turf/open) || !forceMove(next_turf))
			break
		setDir(horizontal ? (step_dir > 0 ? EAST : WEST) : (step_dir > 0 ? NORTH : SOUTH))
		var/list/targets = get_mesa_targets()
		if(targets.len)
			var/atom/T = nearest_target(targets)
			if(T)
				heli_fire(T)
		sleep(HELI_STRAFE_STEP_DS)
	heli_attack_done()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/start_missiles()
	heli_busy = TRUE
	INVOKE_ASYNC(src, PROC_REF(missiles_seq))

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/missiles_seq()
	if(!get_mesa_targets().len)
		heli_attack_done()
		return
	visible_message("<span class='bolddanger'>[src] is spooling its rocket pods - incoming fire!</span>")
	for(var/atom/T in get_mesa_targets())
		if(isliving(T))
			var/mob/living/L = T
			L.visible_message("<span class='danger big'><b>[src] берёт [L] на ракетный прицел!</b></span>", "<span class='danger big'><b>Apache берёт вас на ракетный прицел!</b></span>")

	for(var/i in 1 to 3)
		if(QDELETED(src) || stat != CONSCIOUS)
			heli_busy = FALSE
			return
		playsound(src, 'modular_bluemoon/sound/creatures/mesa/apache/rocketwarning.ogg', 100, TRUE, 12)
		sleep(10)
	var/wanted = rand(2, 3)
	for(var/i in 1 to wanted)
		if(QDELETED(src) || stat != CONSCIOUS)
			heli_busy = FALSE
			return
		var/list/targets = get_mesa_targets()
		if(!targets.len)
			break
		heli_fire_rocket(pick(targets))
		sleep(rand(2, 4))

	overheated_until = world.time + HELI_OVERHEAT_DS
	heli_attack_done()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_fire_rocket(atom/targeted_atom, allow_cutscene = FALSE)
	if(QDELETED(src) || QDELETED(targeted_atom) || (heli_cutscene && !allow_cutscene))
		return
	var/turf/startloc = get_turf(src)
	var/turf/target_turf = get_turf(targeted_atom)
	if(!startloc || !target_turf || target_turf.z != startloc.z)
		return
	var/obj/item/projectile/P = new /obj/item/projectile/bullet/a84mm/helicopter_rocket(startloc)
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/apache/apacheshot.ogg', 70, TRUE, -4)
	P.firer = src
	P.fired_from = src
	P.preparePixelProjectile(targeted_atom, src)
	P.fire()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/start_scan_burst()
	heli_busy = TRUE
	INVOKE_ASYNC(src, PROC_REF(scan_burst_seq))

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/scan_burst_seq()
	var/list/targets = get_mesa_targets()
	if(!targets.len)
		heli_attack_done()
		return
	var/atom/T = nearest_target(targets)
	if(!T)
		T = pick(targets)
	if(!T)
		heli_attack_done()
		return
	var/turf/TT = get_turf(T)
	if(!istype(TT))
		heli_attack_done()
		return
	visible_message("<span class='bolddanger'>[src] is scanning [T] - weapons free!</span>")
	sleep(HELI_STRAFE_WARN_DS)
	if(QDELETED(src) || stat != CONSCIOUS)
		heli_busy = FALSE
		return
	for(var/i in 1 to 4)
		if(QDELETED(src) || stat != CONSCIOUS)
			heli_busy = FALSE
			return
		var/mob/living/L = istype(T, /mob/living) ? T : null
		if(QDELETED(T) || (L && L.stat == DEAD))
			targets = get_mesa_targets()
			T = targets.len ? pick(targets) : null
			if(!T)
				break
		heli_fire(T)
		sleep(4)
	heli_attack_done()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/start_relocate()
	heli_busy = TRUE
	INVOKE_ASYNC(src, PROC_REF(relocate_seq))

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/relocate_seq()
	var/list/candidates = list()
	var/turf/ST = get_turf(src)
	for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in heli_pads)
		var/turf/PT = get_turf(P)
		if(PT && PT != ST && PT.z == ST.z && istype(PT, /turf/open) && !is_blocked_turf(PT, TRUE))
			candidates += PT
	if(!candidates.len)
		attacks_until_relocate = rand(2, 3)
		heli_busy = FALSE
		return
	var/turf/dest = pick(candidates)
	if(!dest)
		attacks_until_relocate = rand(2, 3)
		heli_busy = FALSE
		return
	playsound(src, 'sound/vehicles/high_eng.ogg', 80, TRUE, -4)
	sleep(HELI_RELOCATE_WARN_DS)
	if(QDELETED(src) || stat != CONSCIOUS)
		heli_busy = FALSE
		return

	playsound(src, 'sound/vehicles/high_eng.ogg', 85, TRUE, -4)
	animate(src, pixel_z = 160, transform = matrix()*0.7, alpha = 160, time = 6, easing = SINE_EASING)
	sleep(6)
	if(QDELETED(src) || stat != CONSCIOUS)
		if(!QDELETED(src))
			animate(src, pixel_z = 0, transform = matrix(), alpha = 255, time = 0, flags = ANIMATION_END_NOW)
		heli_busy = FALSE
		return
	if(!forceMove(dest))

		animate(src, pixel_z = 0, transform = matrix(), alpha = 255, time = 0, flags = ANIMATION_END_NOW)
		heli_busy = FALSE
		return
	setDir(pick(GLOB.alldirs))
	animate(src, pixel_z = 0, transform = matrix(), alpha = 255, time = 8, easing = SINE_EASING)
	sleep(8)
	if(QDELETED(src) || stat == DEAD)
		return

	playsound(src, 'sound/effects/space_wind.ogg', 95, TRUE, -3)
	playsound(src, 'sound/vehicles/norm_eng.ogg', 80, TRUE, -3)
	heli_rotor_push(2)
	heli_smoke(dest, 1)
	attacks_until_relocate = rand(2, 3)
	heli_busy = FALSE

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_rotor_push(radius)
	var/turf/ST = get_turf(src)
	if(!ST)
		return
	for(var/mob/living/L in range(radius, ST))
		if(L == src || L.stat == DEAD)
			continue
		heli_knockback(L, ST, radius + 1)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_knockback(atom/movable/L, turf/center, dist)
	if(QDELETED(L) || !istype(center))
		return
	var/turf/LT = get_turf(L)
	if(!LT || LT.z != center.z)
		return
	var/dir = get_dir(center, LT)
	if(!dir)
		dir = pick(GLOB.alldirs)
	var/turf/throw_target = get_step(LT, dir)
	for(var/i in 2 to dist)
		var/turf/next_t = get_step(throw_target, dir)
		if(!next_t || !istype(next_t, /turf/open))
			break
		throw_target = next_t
	L.throw_at(throw_target, dist, 4, src)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_start_cinematic()
	if(heli_died || heli_cutscene || stat != CONSCIOUS)
		return
	heli_cutscene = TRUE
	INVOKE_ASYNC(src, PROC_REF(heli_cinematic_seq))

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_landmark_turf(type)

	for(var/obj/effect/landmark/awaymission/blackmesa/L in GLOB.landmarks_list)
		if(!istype(L, type))
			continue
		var/turf/T = get_turf(L)
		if(T && T.z == z)
			return T
	return null

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_cinematic_pad_turf()
	var/turf/T = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/helicopter_cinematic_pad)
	if(T)
		return T
	T = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/helicopter_center)
	if(T)
		return T
	if(heli_pads.len)
		for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in heli_pads)
			T = get_turf(P)
			if(T && T.z == z)
				return T
	return get_turf(src)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_target_pad_turf()
	var/turf/T = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/helicopter_target_pad)
	if(T)
		return T
	if(heli_pads.len)
		var/list/valid = list()
		for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in heli_pads)
			T = get_turf(P)
			if(T && T.z == z)
				valid += T
		if(valid.len)
			return pick(valid)
	return heli_cinematic_pad_turf()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_cinematic_seq()
	var/turf/land_t = heli_cinematic_pad_turf()
	var/turf/target_t = heli_target_pad_turf()

	if(land_t)
		land_t.visible_message("<span class='bolddanger'>[src] is inbound on the LZ!</span>")
	playsound(src, 'sound/vehicles/high_eng.ogg', 85, TRUE, -3)
	pixel_z = 220
	animate(src, pixel_z = 0, time = 20, easing = SINE_EASING)
	sleep(20)
	if(QDELETED(src))
		return

	if(land_t)
		heli_smoke(land_t, 6)
	playsound(src, 'sound/effects/meteorimpact.ogg', 90, TRUE, -4)
	playsound(src, 'sound/vehicles/norm_eng.ogg', 80, TRUE, -3)
	sleep(30)
	if(QDELETED(src))
		return
	if(stat == CONSCIOUS && land_t)
		heli_smoke(land_t, 3)
		playsound(land_t, 'sound/effects/space_wind.ogg', 90, TRUE, -3)

	sleep(20)
	sleep(20)

	for(var/i in 1 to 2)
		if(QDELETED(src))
			return
		if(stat != CONSCIOUS)
			pixel_z = 0
			heli_cutscene = FALSE
			return
		playsound(src, 'modular_bluemoon/sound/creatures/mesa/apache/rocketwarning.ogg', 100, TRUE, 12)
		sleep(10)
	if(QDELETED(src))
		return
	if(stat != CONSCIOUS)
		pixel_z = 0
		heli_cutscene = FALSE
		return
	heli_cinematic_strike(target_t)
	if(QDELETED(src))
		return
	heli_cutscene = FALSE
	if(land_t)
		land_t.visible_message("<span class='bolddanger'>[src]'s weapons are live - it opens fire!</span>")

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_cinematic_strike(turf/target_t)
	if(!istype(target_t))
		target_t = get_turf(src)
	if(!istype(target_t))
		return
	playsound(target_t, 'sound/weapons/rocketlaunch.ogg', 90, TRUE, -4)

	heli_fire_rocket(target_t, TRUE)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/start_osprey_drop()
	heli_busy = TRUE
	INVOKE_ASYNC(src, PROC_REF(osprey_drop_seq))

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/osprey_drop_seq()
	var/turf/ST = get_turf(src)
	if(!ST)
		heli_attack_done()
		return
	var/turf/op_t = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/osprey_pad)
	if(!op_t)
		op_t = ST
	var/turf/dt = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/osprey_drop)
	if(!dt || dt.z != ST.z)
		dt = heli_nearest_pad_to_center()
	if(!dt || dt.z != ST.z)
		dt = ST
	var/mob/living/simple_animal/hostile/megafauna/osprey/O = new /mob/living/simple_animal/hostile/megafauna/osprey(op_t)
	if(!O || QDELETED(O))
		heli_attack_done()
		return

	heli_airborne = TRUE
	heli_cutscene = TRUE
	animate(src, pixel_z = 300, alpha = 0, time = 10, easing = SINE_EASING)
	playsound(O, 'sound/vehicles/high_eng.ogg', 85, TRUE, -3)
	playsound(O, 'sound/vehicles/norm_eng.ogg', 75, TRUE, -3)
	sleep(15)
	if(QDELETED(src) || QDELETED(O) || stat != CONSCIOUS)
		if(!QDELETED(O))
			qdel(O)
		if(!QDELETED(src))
			heli_return_from_drop()
		return

	var/dropped = 0
	for(var/i in 1 to 3)
		var/turf/drop_t = heli_spawn_turf_near(dt, 2)
		if(!drop_t)
			break
		var/mob/living/simple_animal/hostile/blackmesa/blackops/ranged/M = new(drop_t)
		if(M)
			M.pixel_z = 120
			animate(M, pixel_z = 0, time = 12, easing = SINE_EASING)
			dropped++
		sleep(3)
	if(dropped)
		dt.visible_message("<span class='bolddanger'>[src] inserts a special ops team!</span>")
		if(SSblackmesa_events)
			SSblackmesa_events.mesa_announce("Зафиксирована тактическая высадка чёрных оперативников! Ожидайте пехотный десант!", "Troop deployment", 'sound/vehicles/rocketlaunch.ogg')

	if(!QDELETED(O))
		animate(O, pixel_z = 300, alpha = 0, time = 15, easing = SINE_EASING)
		sleep(15)
		if(!QDELETED(O))
			qdel(O)
	if(QDELETED(src))
		return
	heli_return_from_drop()

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_return_from_drop()
	if(QDELETED(src))
		return
	heli_airborne = FALSE
	heli_cutscene = FALSE
	playsound(src, 'sound/vehicles/high_eng.ogg', 85, TRUE, -3)
	animate(src, pixel_z = 0, alpha = 255, time = 10, easing = SINE_EASING)
	sleep(10)
	if(QDELETED(src))
		return
	attacks_until_relocate = rand(2, 3)
	heli_busy = FALSE

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_nearest_pad_to_center()
	. = null
	if(!heli_pads.len)
		return .
	var/turf/ST = get_turf(src)
	if(!ST)
		return .
	var/center_x = 0
	var/center_y = 0
	var/count = 0
	for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in heli_pads)
		var/turf/PT = get_turf(P)
		if(PT && PT.z == ST.z)
			center_x += PT.x
			center_y += PT.y
			count++
	if(!count)
		return .
	center_x = round(center_x / count)
	center_y = round(center_y / count)
	var/best = INFINITY
	var/turf/center_t = locate(center_x, center_y, ST.z)
	if(!center_t)
		return .
	for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in heli_pads)
		var/turf/PT = get_turf(P)
		if(!PT || PT.z != ST.z)
			continue
		var/d = get_dist(PT, center_t)
		if(d < best)
			best = d
			. = PT
	return .

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_spawn_turf_near(turf/center, radius)
	for(var/i in 1 to 15)
		var/turf/T = locate(center.x + rand(-radius, radius), center.y + rand(-radius, radius), center.z)
		if(!T || !istype(T, /turf/open) || is_blocked_turf(T, TRUE))
			continue
		if(!(locate(/mob/living) in T))
			. = T
			return .
	return .

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_smoke(turf/T, lifetime = 3)
	if(!istype(T) || !istype(T, /turf/open))
		return
	var/obj/effect/particle_effect/smoke/S = new(T)
	S.amount = 0
	S.lifetime = lifetime
	S.set_opacity(TRUE)

/mob/living/simple_animal/hostile/megafauna/helicopter/handle_automated_movement()
	return FALSE

/mob/living/simple_animal/hostile/megafauna/helicopter/handle_automated_action()
	return

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_critical_beep_burst()
	if(QDELETED(src) || stat == DEAD || heli_died || !heli_crit_channel || heli_airborne)
		return
	var/sound/beep = sound('modular_bluemoon/sound/creatures/mesa/apache/damagedapachebeep.ogg', repeat = TRUE, volume = 75, channel = heli_crit_channel)
	var/list/hearers = list()
	for(var/atom/A in viewers(20, src))
		if(!isliving(A))
			continue
		var/mob/living/L = A
		if(QDELETED(L) || L.client == null || L.stat == DEAD)
			continue
		SEND_SOUND(L, beep)
		hearers += L
	if(!hearers.len)
		return
	sleep(50)
	for(var/mob/listener in hearers)
		if(QDELETED(listener))
			continue
		listener.stop_sound_channel(heli_crit_channel)
		// Если слушатель за 50 дс умер/загостился, стоп на старый моб не
		// доезжает до клиента - шлём ещё и на текущий контролируемый моб.
		var/mob/current = listener.mind ? listener.mind.current : null
		if(current && current != listener)
			current.stop_sound_channel(heli_crit_channel)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_update_rotor_sound()
	if(!heli_rotor_channel || heli_died || stat == DEAD)
		return
	if(heli_airborne)

		for(var/mob/listener in heli_rotor_listeners.Copy())
			if(!QDELETED(listener))
				listener.stop_sound_channel(heli_rotor_channel)
			heli_rotor_listeners -= listener
		return
	var/turf/ST = get_turf(src)
	if(!ST)
		return

	var/list/viewers_list = viewers(HELI_ROTOR_RANGE, src)
	for(var/mob/listener in heli_rotor_listeners.Copy())
		var/turf/LT = QDELETED(listener) ? null : get_turf(listener)
		if(QDELETED(listener) || listener.stat == DEAD || !LT || LT.z != ST.z || !(listener in viewers_list))
			if(!QDELETED(listener))
				listener.stop_sound_channel(heli_rotor_channel)
			heli_rotor_listeners -= listener
	for(var/atom/A in viewers_list)
		if(!isliving(A) || (A in heli_rotor_listeners))
			continue
		var/mob/living/L = A
		if(QDELETED(L) || L.stat == DEAD || !L.client)
			continue
		var/turf/LT = get_turf(L)
		if(!LT || LT.z != ST.z)
			continue
		SEND_SOUND(L, sound('modular_bluemoon/sound/creatures/mesa/apache/apacheflyloop.ogg', repeat = TRUE, volume = 65, channel = heli_rotor_channel))
		heli_rotor_listeners += L

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_update_theme_sound()
	if(!heli_theme_channel || heli_died || stat == DEAD)
		return
	for(var/mob/listener in heli_theme_listeners.Copy())
		if(QDELETED(listener) || listener.stat == DEAD || !listener.client || !listener.client.prefs || !(listener.client.prefs.toggles & SOUND_AMBIENCE) || !istype(get_area(listener), /area/awaymission/ihategordon))
			stop_theme_listener_sound(listener)
			unregister_theme_listener(listener)

	if(heli_cutscene || stat != CONSCIOUS)
		return
	for(var/mob/living/nearby_mob in GLOB.player_list)
		if(QDELETED(nearby_mob) || nearby_mob.stat == DEAD || (nearby_mob in heli_theme_listeners))
			continue
		if(!nearby_mob.client || !nearby_mob.client.prefs || !(nearby_mob.client.prefs.toggles & SOUND_AMBIENCE))
			continue
		if(!istype(get_area(nearby_mob), /area/awaymission/ihategordon))
			continue
		SEND_SOUND(nearby_mob, sound('modular_bluemoon/sound/creatures/mesa/apache/yourfuneral.ogg', repeat = TRUE, volume = 50, channel = heli_theme_channel))
		register_theme_listener(nearby_mob)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/register_theme_listener(mob/listener)
	if(!listener || !istype(listener))
		return

	unregister_theme_listener(listener)
	heli_theme_listeners += listener
	RegisterSignal(listener, COMSIG_LIVING_DEATH, PROC_REF(on_theme_listener_death), override = TRUE)
	RegisterSignal(listener, COMSIG_MOB_GHOSTIZE, PROC_REF(on_theme_listener_ghostize), override = TRUE)
	RegisterSignal(listener, COMSIG_PARENT_QDELETING, PROC_REF(on_theme_listener_qdeleting), override = TRUE)
	if(listener.mind)
		RegisterSignal(listener.mind, COMSIG_MIND_TRANSFER, PROC_REF(on_theme_listener_mind_transfer), override = TRUE)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/unregister_theme_listener(mob/listener, datum/mind/mind)
	if(!listener)
		return
	var/datum/mind/listener_mind = mind
	if(!listener_mind && !QDELETED(listener))
		listener_mind = listener.mind
	UnregisterSignal(listener, list(COMSIG_LIVING_DEATH, COMSIG_MOB_GHOSTIZE, COMSIG_PARENT_QDELETING))
	if(listener_mind && !QDELETED(listener_mind))
		UnregisterSignal(listener_mind, COMSIG_MIND_TRANSFER)
	heli_theme_listeners -= listener

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/stop_theme_listener_sound(mob/listener)
	if(!listener || QDELETED(listener) || !heli_theme_channel)
		return
	listener.stop_sound_channel(heli_theme_channel)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/on_theme_listener_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	stop_theme_listener_sound(source)
	unregister_theme_listener(source)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/on_theme_listener_ghostize(mob/source, can_reenter_corpse = FALSE, special = FALSE, penalize = FALSE, voluntary = FALSE)
	SIGNAL_HANDLER
	stop_theme_listener_sound(source)
	unregister_theme_listener(source)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/on_theme_listener_qdeleting(mob/source)
	SIGNAL_HANDLER
	// Без стопа repeat-трек оставался крутиться на клиенте навсегда.
	stop_theme_listener_sound(source)
	unregister_theme_listener(source, source.mind)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/on_theme_listener_mind_transfer(datum/mind/source, mob/new_character, mob/old_character)
	SIGNAL_HANDLER
	if(!old_character || !(old_character in heli_theme_listeners))
		UnregisterSignal(source, COMSIG_MIND_TRANSFER)
		return
	stop_theme_listener_sound(new_character)
	stop_theme_listener_sound(old_character)
	unregister_theme_listener(old_character, source)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/stop_heli_sounds()
	for(var/mob/listener in heli_theme_listeners.Copy())
		stop_theme_listener_sound(listener)
		unregister_theme_listener(listener)
	for(var/mob/listener in heli_rotor_listeners.Copy())
		if(!QDELETED(listener))
			listener.stop_sound_channel(heli_rotor_channel)
	heli_rotor_listeners.Cut()
	for(var/mob/listener in GLOB.player_list)
		if(QDELETED(listener))
			continue
		listener.stop_sound_channel(heli_theme_channel)
		listener.stop_sound_channel(heli_rotor_channel)
		listener.stop_sound_channel(heli_crit_channel)
	heli_theme_listeners.Cut()

/obj/effect/portal/mesa_rift
	name = "Black Mesa rift"
	desc = "A crackling tear in reality left behind by the destroyed gunship."
	force_teleport = TRUE
	mech_sized = TRUE
	anchored = TRUE

/obj/machinery/negotiations_radio/helicopter
	name = "distress radio"
	desc = "A crackling field radio. Someone is begging for help on the other end."
	icon_state = "radiohecu"
	detection_range = 12

	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	max_integrity = 100

	blastdoor_id = "helicopter"
	var/colin_sequence_active = FALSE
	var/colin_sequence_done = FALSE
	can_skip_dialogue = FALSE
	var/list/colin_lines = list(
		"ЭЙ!... Э-это К-колин Г-грэй! П-подойдите живо... Я в рубке!...",
		"П-пожалуйста! Ответьте живо!!!... Я в рубке!",
		"Я-... Я всё могу объяснить! ...НЕТ! НЕ МОГУ! К ВАМ ПРЯМО СЕЙЧАС ЛЕТИТ ВЕРТУШКА! У НИХ ПРИКАЗ ВАС УБИТЬ",
		"Я не могу... Боже... Мы обречены!!!"
	)

/obj/machinery/negotiations_radio/helicopter/Initialize(mapload)
	. = ..()
	next_detection_time = 0

/obj/machinery/negotiations_radio/helicopter/process()

	if(dialogue_active && dialogue_should_end())
		end_dialogue()
	if(dialogue_active || dialogue_completed)
		return
	if(world.time >= next_detection_time)
		detect_players()

/obj/machinery/negotiations_radio/helicopter/Destroy()
	return ..()

/obj/machinery/negotiations_radio/helicopter/proc/start_colin_sequence()
	if(!src || colin_sequence_active || colin_sequence_done)
		return
	colin_sequence_active = TRUE
	INVOKE_ASYNC(src, PROC_REF(colin_sequence))

/obj/machinery/negotiations_radio/helicopter/attack_hand(mob/user)

	if(!user || !src)
		return
	if(colin_sequence_done)
		to_chat(user, span_warning("Радио больше не отвечает."))
		return
	if(colin_sequence_active)
		to_chat(user, span_warning("Радио ещё передаёт сообщение..."))
		return
	start_colin_sequence()

/obj/machinery/negotiations_radio/helicopter/play_alert_phrase()

	if(colin_sequence_done || colin_sequence_active)
		return
	icon_state = "radiohecu_talking"
	playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
	addtimer(CALLBACK(src, PROC_REF(reset_icon)), 3 SECONDS)

/obj/machinery/negotiations_radio/helicopter/proc/colin_sequence()
	icon_state = "radiohecu_talking"

	var/datum/language/lang = null
	if(/datum/language/modular_sand/solcommon in GLOB.language_datum_instances)
		lang = /datum/language/modular_sand/solcommon
	for(var/i in 1 to colin_lines.len)
		if(QDELETED(src))
			return
		say(colin_lines[i], language = lang)
		playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
		sleep(i == colin_lines.len ? 50 : 40)
	if(QDELETED(src))
		return
	colin_sequence_active = FALSE
	colin_sequence_done = TRUE
	addtimer(CALLBACK(src, PROC_REF(reset_icon)), 10)

	spawn_helicopter_boss()
	close_blastdoors()
	activate_mesa_rift()

/obj/machinery/negotiations_radio/helicopter/proc/close_blastdoors()
	if(!src || !blastdoor_id)
		return
	var/doors_closed = 0
	for(var/obj/machinery/door/poddoor/D in GLOB.machines)
		if(D && D.id == blastdoor_id)
			D.close()
			doors_closed++
	for(var/obj/machinery/door/window/brigdoor/W in GLOB.machines)
		if(W && W.id == blastdoor_id)
			W.close()
			doors_closed++
	for(var/obj/machinery/door/airlock/A in GLOB.airlocks)
		if(A && A.id_tag == blastdoor_id)
			A.close()
			doors_closed++
	if(doors_closed)
		visible_message("<span class='bolddanger'>Blast doors seal the sector - there is no way out!</span>")

/obj/machinery/negotiations_radio/helicopter/proc/activate_mesa_rift()
	if(!src)
		return
	var/turf/A = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/mesa_rift)
	if(!istype(A))
		return
	var/turf/B = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/helicopter_center)
	if(!istype(B) || B.z != A.z || B == A)
		B = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/helicopter_rift_in)
	if(!istype(B) || B.z != A.z || B == A)
		B = get_turf(src)
	if(!istype(B) || B.z != A.z || B == A)
		return
	var/obj/effect/portal/mesa_rift/P = new(A)
	if(!istype(P))
		return
	P.hard_target = B
	P.hardlinked = FALSE
	playsound(A, 'sound/effects/space_wind.ogg', 90, TRUE, -4)
	visible_message("<span class='bolddanger'>A rift tears open by the sealed gates - the boss arena is reachable through it!</span>")

/obj/machinery/negotiations_radio/helicopter/proc/heli_landmark_turf(type)
	var/turf/my_t = get_turf(src)
	if(!my_t)
		return null
	for(var/obj/effect/landmark/awaymission/blackmesa/L in GLOB.landmarks_list)
		if(!istype(L, type))
			continue
		var/turf/T = get_turf(L)
		if(T && T.z == my_t.z)
			return T
	return null

/obj/machinery/negotiations_radio/helicopter/proc/spawn_helicopter_boss()
	if(QDELETED(src))
		return
	var/turf/spawn_t = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/helicopter_cinematic_pad)
	if(!spawn_t)
		spawn_t = heli_landmark_turf(/obj/effect/landmark/awaymission/blackmesa/helicopter_center)
	if(!spawn_t)
		for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in GLOB.landmarks_list)
			var/turf/PT = get_turf(P)
			var/turf/my_t = get_turf(src)
			if(PT && my_t && PT.z == my_t.z)
				spawn_t = PT
				break
	if(!spawn_t)
		spawn_t = get_turf(src)
	if(!istype(spawn_t))
		return

	if(is_blocked_turf(spawn_t, TRUE))
		for(var/dir in GLOB.alldirs)
			var/turf/N = get_step(spawn_t, dir)
			if(N && istype(N, /turf/open) && !is_blocked_turf(N, TRUE))
				spawn_t = N
				break
	var/mob/living/simple_animal/hostile/megafauna/helicopter/boss = new /mob/living/simple_animal/hostile/megafauna/helicopter(spawn_t)
	if(boss && !QDELETED(boss))
		boss.heli_start_cinematic()
