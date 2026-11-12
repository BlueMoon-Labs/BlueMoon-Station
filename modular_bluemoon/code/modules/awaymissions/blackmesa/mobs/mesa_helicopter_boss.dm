// =============================================================================
// BLACK MESA - HELICOPTER BOSS (Gunship)
//
// Boss-aviation unit: hovers over the arena and runs a phase cycle of
// Hover -> Attack series -> Landmark jump, inspired by the Ash Drake.
// It never pathfinds tile-by-tile; it relocates between pre-placed
// /obj/effect/landmark/awaymission/blackmesa/helicopter_pad markers.
// =============================================================================

#define HELI_TICK_DS 10                  // main logic tick, deciseconds (1s)
#define HELI_ENGAGE_RANGE 30             // tiles, max target distance
#define HELI_OVERHEAT_DS 50              // 5 seconds of cooling after missile barrage
#define HELI_OVERHEAT_DAMAGE_MULT 1.5    // damage taken multiplier while overheated
#define HELI_STRAFE_WARN_DS 15           // 1.5s warning strip before strafing run
#define HELI_STRAFE_STEP_DS 2            // flight step during strafing run
#define HELI_STRAFE_MAX_LEN 20          // max tiles of a single strafing run window
#define HELI_LOCKON_DS 20                // 2s missile lock-on beeping
#define HELI_RELOCATE_WARN_DS 8          // quick reposition windup
#define HELI_ROTOR_RANGE 14              // tiles, rotor loop is re-sent to viewers inside this range

// =============================================================================
// LANDMARKS
// =============================================================================
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

// Landing site for the intro aircraft (Colin Grey transmission).
/obj/effect/landmark/awaymission/blackmesa/helicopter_cinematic_pad
	name = "Helicopter Landing Zone Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

// Pre-aimed strike point for the intro missile shot.
/obj/effect/landmark/awaymission/blackmesa/helicopter_target_pad
	name = "Helicopter Target Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

// Death rift: portal entrance spawns here when the gunship is destroyed.
/obj/effect/landmark/awaymission/blackmesa/helicopter_rift_in
	name = "Helicopter Rift Landmark (Entrance)"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

// Death rift: portal destination - players/hostiles step out here.
/obj/effect/landmark/awaymission/blackmesa/helicopter_rift_out
	name = "Helicopter Rift Landmark (Exit)"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

// Osprey transport hover point for troop-insertion runs.
/obj/effect/landmark/awaymission/blackmesa/osprey_pad
	name = "Osprey Pad Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

// Rope-drop zone: blackops operatives rappel down on this landmark.
/obj/effect/landmark/awaymission/blackmesa/osprey_drop
	name = "Osprey Drop Zone Landmark"
	invisibility = INVISIBILITY_ABSTRACT
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

// =============================================================================
// TEMP VISUALS (missile impact only - no targeting markers)
// =============================================================================
/obj/effect/temp_visual/helicopter_missile_boom
	name = "missile impact"
	icon = 'icons/effects/effects.dmi'
	icon_state = "explosion"
	layer = ABOVE_MOB_LAYER
	duration = 8
	randomdir = FALSE

// =============================================================================
// PROJECTILE - autocannon shell
// =============================================================================
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

// Unguided rocket fired from the gunship itself during the missile barrage.
// Child of the HE rocket so impacts detonate like the drone's salvo.
/obj/item/projectile/bullet/a84mm/helicopter_rocket
	name = "unguided rocket"
	icon_state = "missile"
	damage = 70
	pixels_per_second = TILES_TO_PIXELS(45)
	range = 45

// Apache rockets keep the parent's blast but must never flash-blind players.
/obj/item/projectile/bullet/a84mm/helicopter_rocket/do_boom(atom/target, random_crit_gib = FALSE)
	if(!isliving(target))
		explosion(target, heavy_impact_range = 1, light_impact_range = 2, flame_range = 3, flash_range = 0)
	else
		explosion(target, light_impact_range = 2, flame_range = 3, flash_range = 0)
		if(random_crit_gib)
			var/mob/living/gibbed_dude = target
			new /obj/effect/temp_visual/crit(get_turf(gibbed_dude))
			gibbed_dude.gib(FALSE, FALSE, FALSE)

// =============================================================================
// OSPREY - unkillable troop-transport helicopter for insertion runs.
// Hovers above the drop zone on ABOVE_ALL_MOB_LAYER with density off, so
// players can literally walk underneath it while it kicks out operatives.
// =============================================================================
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
	// shares FACTION_BLACKOPS so the gunship's own drop team doesn't
	// treat the transport as hostile (faction_check_mob => same side)
	faction = list("hostile", FACTION_XEN, FACTION_BLACKOPS)
	environment_smash = ENVIRONMENT_SMASH_NONE
	stat_attack = CONSCIOUS
	mob_biotypes = MOB_ROBOTIC|MOB_EPIC
	damage_coeff = list(BRUTE = 0, BURN = 0, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	weather_immunities = list(TRAIT_LAVA_IMMUNE, TRAIT_ASHSTORM_IMMUNE, TRAIT_TOXIMMUNE)
	ai_profile_type = null //no AI at all - it only hovers and leaves
	AIStatus = AI_OFF
	density = FALSE                    // players walk underneath
	layer = ABOVE_ALL_MOB_LAYER        // drawn above everything mob-side
	pixel_z = 80                       // hover height above head level

/mob/living/simple_animal/hostile/megafauna/osprey/Initialize(mapload)
	. = ..()
	if(mapload)
		// transport is spawned by the Apache's drop sequence only
		qdel(src)
		return

// Unkillable by design: every damage path funnels into adjustHealth.
/mob/living/simple_animal/hostile/megafauna/osprey/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	return FALSE

/mob/living/simple_animal/hostile/megafauna/osprey/handle_automated_movement()
	return FALSE

/mob/living/simple_animal/hostile/megafauna/osprey/handle_automated_action()
	return

// =============================================================================
// THE BOSS
// =============================================================================
/mob/living/simple_animal/hostile/megafauna/helicopter
	name = "Apache"
	desc = "An aviation unit circling the sector. Its autocannon and rocket pods do not forgive mistakes."
	icon = 'modular_bluemoon/icons/mob/helicopter.dmi'
	icon_state = "apache"
	pixel_x = -69
	pixel_y = -59
	maptext_height = 64
	maptext_width = 64
	health = 5000
	maxHealth = 5000
	// FACTION_BLACKOPS: the Apache and its blackops drop team are on the
	// same side - no targeting, no instant retaliation for stray splash
	faction = list("hostile", FACTION_XEN, FACTION_BLACKOPS)
	environment_smash = ENVIRONMENT_SMASH_NONE
	stat_attack = CONSCIOUS
	mob_biotypes = MOB_ROBOTIC|MOB_EPIC
	damage_coeff = list(BRUTE = 1, BURN = 1, TOX = 0, CLONE = 0, STAMINA = 0, OXY = 0)
	weather_immunities = list(TRAIT_LAVA_IMMUNE, TRAIT_ASHSTORM_IMMUNE, TRAIT_TOXIMMUNE)
	ai_profile_type = null //custom phase AI, no controller pathfinding
	AIStatus = AI_OFF
	projectiletype = /obj/item/projectile/bullet/helicopter_autocannon
	light_range = 4
	deathmessage = "crashes in a fireball, scattering burning debris across the sector."
	death_sound = 'sound/effects/Explosion2.ogg'

	// ---- runtime state ----
	var/heli_busy = FALSE                 // an attack/reposition sequence is running
	var/heli_tick_timer                   // stoppable logic loop
	var/heli_rotor_channel                // dedicated rotor loop channel
	var/list/heli_rotor_listeners = list() // mobs currently hearing the rotor loop
	var/list/heli_pads = list()           // landmark objs (pads)
	var/obj/effect/landmark/awaymission/blackmesa/helicopter_center/heli_center
	var/list/heli_bounds = null           // list(minx, maxx, miny, maxy, z)
	var/attacks_until_relocate = 3        // attacks left before next landmark jump
	var/overheated_until = 0              // world.time when cooling ends
	var/overheat_visual_active = FALSE
	var/list/heli_drop_thresholds = list(75, 50, 35, 10) // HP% that trigger an osprey insertion
	var/list/heli_drops_done = list()     // thresholds already fired
	var/heli_died = FALSE
	var/heli_cutscene = FALSE               // intro cinematic: invulnerable, weapons offline
	var/heli_airborne = FALSE               // flew off for an osprey insertion: no rotor loop
	var/heli_critical = FALSE               // <30% HP alarm state
	var/heli_crit_channel                  // dedicated critical-beep channel
	var/heli_crit_beep_next = 0            // world.time of next beep burst
	var/heli_theme_channel                  // boss theme sound channel
	var/list/heli_theme_listeners = list()

/mob/living/simple_animal/hostile/megafauna/helicopter/Initialize(mapload)
	. = ..()
	if(mapload)
		// The gunship must spawn via the Colin Grey radio sequence - a
		// map-placed copy has no intro and just attacks from round start.
		qdel(src)
		return
	ensure_landmarks()
	compute_bounds()
	attacks_until_relocate = rand(2, 3)
	heli_tick_timer = addtimer(CALLBACK(src, PROC_REF(heli_tick)), HELI_TICK_DS, TIMER_STOPPABLE | TIMER_LOOP)
	heli_theme_channel = SSsounds.reserve_sound_channel(src)
	heli_rotor_channel = SSsounds.reserve_sound_channel(src)
	heli_crit_channel = SSsounds.reserve_sound_channel(src)
	// The gunship is spawned by the Colin Grey radio after its transmission;
	// it is never placed on the map directly.
	heli_update_hull_icon()
	heli_update_rotor_sound()
	visible_message("<span class='boldannounce'>[src] enters the arena airspace!</span>")
	if(SSblackmesa_events)
		SSblackmesa_events.mesa_announce("Внимание! Вертолет Black Mesa вошел в зону операции. Держитесь подальше от точек сброса ракет!", "Airborne threat", 'sound/vehicles/high_eng.ogg')

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

// Hull damage icon states, same pattern as the combat drone:
// apache -> apachedam1 -> apachedam2, refreshed on every health change.
/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_update_hull_icon()
	var/hull_state = "apache"
	if(health <= maxHealth * 0.4)
		hull_state = "apachedam2"
	else if(health <= maxHealth * 0.75)
		hull_state = "apachedam1"
	if(icon_state != hull_state)
		icon_state = hull_state

/mob/living/simple_animal/hostile/megafauna/helicopter/visible_message(message, self_message, blind_message, vision_distance = DEFAULT_MESSAGE_RANGE, list/ignored_mobs, mob/target, target_message, omni = FALSE, runechat_popup, rune_msg, visible_message_flags = NONE, separation = " ")
	if(heli_cutscene) //suppress "got hit" spam while the landing cinematic plays
		return
	return ..()

/mob/living/simple_animal/hostile/megafauna/helicopter/death(gibbed, list/force_grant)
	if(health <= 0 && !heli_died)
		heli_died = TRUE
		stop_heli_sounds()
		new /datum/helicopter_death_fx(get_turf(src))
		heli_spawn_death_portal()
	. = ..(gibbed, force_grant)
	// The gunship always explodes into gibs, even on a plain killing blow.
	// If death() was reached through gib() itself (gibbed = TRUE) the outer
	// call already handles gibs and qdel - don't double it.
	if(!gibbed && !QDELETED(src) && stat == DEAD)
		gib()

// On death the wreck tears a rift between two dedicated landmarks:
// helicopter_rift_in (entrance) -> helicopter_rift_out (exit).
// Uses force_teleport so the NOTELEPORT area flag on the Black Mesa zone
// does not block it. Falls back to crash-site -> center pad if the rift
// landmarks are not mapped.
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
	// one-way rift: a single portal at A with a hard target at B - there is
	// deliberately no return portal.
	var/obj/effect/portal/mesa_rift/P = new(A)
	if(!istype(P))
		return
	P.hard_target = B
	P.hardlinked = FALSE

// Death cinematic runs on its own datum so it survives gibbing/qdel of the mob.
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

// =============================================================================
// LANDMARK MANAGEMENT
// =============================================================================
/mob/living/simple_animal/hostile/megafauna/helicopter/proc/ensure_landmarks()
	for(var/obj/effect/landmark/awaymission/blackmesa/helicopter_pad/P in GLOB.landmarks_list)
		heli_pads += P
	heli_center = locate(/obj/effect/landmark/awaymission/blackmesa/helicopter_center) in GLOB.landmarks_list
	if(heli_pads.len >= 2)
		return
	// No pads mapped: scatter fallback pads across the mission area once.
	var/list/mesa_areas = heli_mesa_areas()
	if(!mesa_areas)
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
		// fallback: box around the boss
		var/turf/ST = get_turf(src)
		if(!ST)
			return
		min_x = ST.x - 8; max_x = ST.x + 8
		min_y = ST.y - 8; max_y = ST.y + 8
	heli_bounds = list(min_x, max_x, min_y, max_y, bounds_z)

// =============================================================================
// TARGETING
// =============================================================================
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
		// skip players tucked inside containers/lockers
		if(!isturf(L.loc))
			continue
		// only engage targets inside the ihategordon gate area
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

// =============================================================================
// MAIN TICK / PHASE MACHINE
// =============================================================================
/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_tick()
	if(QDELETED(src))
		return
	heli_update_rotor_sound()
	heli_update_theme_sound()
	if(stat != CONSCIOUS || heli_busy || heli_cutscene)
		return
	// overheat state visuals
	var/overheated = world.time < overheated_until
	if(overheated != overheat_visual_active)
		overheat_visual_active = overheated
		if(overheated)
			visible_message("<span class='boldwarning'>[src]'s weapons are overheating - it is vulnerable!</span>")
	// critical hull state: alarm beep + one-time warning
	var/critical = health <= maxHealth * 0.3
	if(critical != heli_critical)
		heli_critical = critical
		if(critical)
			visible_message("<span class='boldwarning'>[src] is critically damaged - its systems are failing!</span>")
	// critical hull state: ~5s beep burst, then silence - no per-tick spam
	if(critical && world.time >= heli_crit_beep_next)
		heli_crit_beep_next = world.time + 100 // 5s beep + ~5s quiet cycle
		INVOKE_ASYNC(src, PROC_REF(heli_critical_beep_burst))
	if(overheated)
		return
	// troop insertion runs at fixed HP thresholds - each fires once,
	// queued naturally because heli_busy blocks the tick while one runs
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
	// strafing runs tilt the sprite sideways - level it back out on stop
	dir = SOUTH

// =============================================================================
// ATTACK 1 - AUTOCANNON BURST (5-8 heavy shots)
// =============================================================================
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
	var/obj/item/projectile/P = new /obj/item/projectile/bullet/helicopter_autocannon(startloc)
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/apache/apacheshot.ogg', 80, TRUE, -4)
	P.firer = src
	P.fired_from = src
	P.preparePixelProjectile(targeted_atom, src)
	P.fire()

// =============================================================================
// ATTACK 2 - STRAFING RUN
// =============================================================================
/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_plan_strafe()
	// returns list(horizontal, fixed_coord, start_coord, end_coord, step_dir, z) or null
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

// One strafing axis: a window of at most HELI_STRAFE_MAX_LEN tiles centered on
// the players (or the boss), flown along `fixed_coord`. Tries several lane
// offsets before giving up - a single wall used to kill the whole attack.
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
	// anchor the window on the players so the run actually crosses the fight
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
	// lane offset lives on the cross axis, so it clamps to the cross bounds
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
	// take the edge position
	var/turf/start_turf = horizontal ? locate(start_coord, fixed_coord, z) : locate(fixed_coord, start_coord, z)
	if(!start_turf)
		heli_attack_done()
		return
	forceMove(start_turf)
	setDir(horizontal ? (step_dir > 0 ? EAST : WEST) : (step_dir > 0 ? NORTH : SOUTH))
	// engine roar audio telegraph only - no ground markers
	playsound(src, 'sound/vehicles/high_eng.ogg', 85, TRUE, -4)
	playsound(src, 'sound/vehicles/rocketlaunch.ogg', 70, TRUE, -4)
	visible_message("<span class='boldwarning'>[src] begins a strafing run!</span>")
	sleep(HELI_STRAFE_WARN_DS)
	if(QDELETED(src) || stat != CONSCIOUS)
		heli_busy = FALSE
		return
	// fly across the arena, firing continuously
	while(TRUE)
		var/coord = horizontal ? x : y
		if(coord == end_coord)
			break
		// external displacement may have pushed us past the end tile -
		// without this the run would never terminate and cross the map
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

// =============================================================================
// ATTACK 3 - ROCKET VOLLEY + OVERHEAT WINDOW
// Detection whine -> 3s stall (the gunship cannot act, like the tank's
// recovery) -> volley of rockets fired from the gunship itself.
// =============================================================================
/mob/living/simple_animal/hostile/megafauna/helicopter/proc/start_missiles()
	heli_busy = TRUE
	INVOKE_ASYNC(src, PROC_REF(missiles_seq))

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/missiles_seq()
	if(!get_mesa_targets().len)
		heli_attack_done()
		return
	visible_message("<span class='boldwarning'>[src] is spooling its rocket pods - incoming fire!</span>")
	// detection beeping, then the 3s stall before the volley
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
	// overheat window
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

// =============================================================================
// ATTACK 4 - SCAN BURST
// Paints a target with a scanning marker for ~1.5s (drone-style telegraph),
// then puts a short autocannon burst into it.
// =============================================================================
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
	visible_message("<span class='boldwarning'>[src] is scanning [T] - weapons free!</span>")
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

// =============================================================================
// REPOSITION - landmark jump with rotor gust
// =============================================================================
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
	// ash drake style jump: climb + shrink/fade, blink to the landmark,
	// then descend back to full size - reads as a single hop, not a teleport
	playsound(src, 'sound/vehicles/high_eng.ogg', 85, TRUE, -4)
	animate(src, pixel_z = 160, transform = matrix()*0.7, alpha = 160, time = 6, easing = SINE_EASING)
	sleep(6)
	if(QDELETED(src) || stat != CONSCIOUS)
		if(!QDELETED(src))
			animate(src, pixel_z = 0, transform = matrix(), alpha = 255, time = 0, flags = ANIMATION_END_NOW)
		heli_busy = FALSE
		return
	if(!forceMove(dest))
		// pad turf got blocked between planning and landing - snap back
		animate(src, pixel_z = 0, transform = matrix(), alpha = 255, time = 0, flags = ANIMATION_END_NOW)
		heli_busy = FALSE
		return
	setDir(pick(GLOB.alldirs))
	animate(src, pixel_z = 0, transform = matrix(), alpha = 255, time = 8, easing = SINE_EASING)
	sleep(8)
	if(QDELETED(src) || stat == DEAD)
		return
	// rotor blast pushes everyone nearby away
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

// =============================================================================
// INTRO CINEMATIC - triggered by the Colin Grey radio
// Plane lands on helicopter_cinematic_pad, AI offline ~5s, then a single
// lock-on missile strikes helicopter_target_pad. Boss becomes damageable
// and starts attacking only after the strike.
// =============================================================================
/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_start_cinematic()
	if(heli_died || heli_cutscene || stat != CONSCIOUS)
		return
	heli_cutscene = TRUE
	INVOKE_ASYNC(src, PROC_REF(heli_cinematic_seq))

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_landmark_turf(type)
	// first mapped landmark of `type` on our z-level, or null
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
	// Inbound landing: the sprite starts high via pixel_z and descends
	// onto the pad - reads as a real touchdown, not a phase-in.
	// (turf.visible_message - the mob override mutes chat during cutscene)
	if(land_t)
		land_t.visible_message("<span class='boldwarning'>[src] is inbound on the LZ!</span>")
	playsound(src, 'sound/vehicles/high_eng.ogg', 85, TRUE, -3)
	pixel_z = 220
	animate(src, pixel_z = 0, time = 20, easing = SINE_EASING)
	sleep(20)
	if(QDELETED(src))
		return
	// touchdown: dust ring + heavy thud, then the AI-offline window
	if(land_t)
		heli_smoke(land_t, 6)
	playsound(src, 'sound/effects/meteorimpact.ogg', 90, TRUE, -4)
	playsound(src, 'sound/vehicles/norm_eng.ogg', 80, TRUE, -3)
	sleep(30) // ~3s settle / AI offline window
	if(QDELETED(src))
		return
	if(stat == CONSCIOUS && land_t)
		heli_smoke(land_t, 3)
		playsound(land_t, 'sound/effects/space_wind.ogg', 90, TRUE, -3)
	// AI offline window (~5s total), then 2s of inactivity
	sleep(20)
	sleep(20)
	// lock-on beeping, then a single rocket shot onto the second landmark
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
		land_t.visible_message("<span class='boldwarning'>[src]'s weapons are live - it opens fire!</span>")

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_cinematic_strike(turf/target_t)
	if(!istype(target_t))
		target_t = get_turf(src)
	if(!istype(target_t))
		return
	playsound(target_t, 'sound/weapons/rocketlaunch.ogg', 90, TRUE, -4)
	// one lock-on shot onto the landmark, same rocket as the combat barrage
	heli_fire_rocket(target_t, TRUE)

// =============================================================================
// TROOP INSERTION - osprey transport + rope drop at HP thresholds
// The Osprey hovers over osprey_pad (or the boss turf as fallback), three
// blackops rappel down at osprey_drop (or the mission centre pad), then it
// peels off and leaves. Unkillable - it is scenery, not a target.
// =============================================================================
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
	// Apache peels off for the whole insertion - it is "away" (invulnerable,
	// weapons offline, rotor loop cut) until the Osprey has left.
	heli_airborne = TRUE
	heli_cutscene = TRUE
	animate(src, pixel_z = 300, alpha = 0, time = 10, easing = SINE_EASING)
	playsound(O, 'sound/vehicles/high_eng.ogg', 85, TRUE, -3)
	playsound(O, 'sound/vehicles/norm_eng.ogg', 75, TRUE, -3)
	sleep(15) // ~1.5s hover-in before the drop
	if(QDELETED(src) || QDELETED(O) || stat != CONSCIOUS)
		if(!QDELETED(O))
			qdel(O)
		if(!QDELETED(src))
			heli_return_from_drop()
		return
	// three operatives fast-rope down at the drop landmark
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
		dt.visible_message("<span class='boldwarning'>[src] inserts a special ops team!</span>")
		if(SSblackmesa_events)
			SSblackmesa_events.mesa_announce("Зафиксирована тактическая высадка чёрных оперативников! Ожидайте пехотный десант!", "Troop deployment", 'sound/vehicles/rocketlaunch.ogg')
	// peel off and leave
	if(!QDELETED(O))
		animate(O, pixel_z = 300, alpha = 0, time = 15, easing = SINE_EASING)
		sleep(15)
		if(!QDELETED(O))
			qdel(O)
	if(QDELETED(src))
		return
	heli_return_from_drop()

// Apache flies back in after the Osprey is gone: restores its sprite,
// re-enables the fight and clears heli_busy once it has "landed".
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

// =============================================================================
// SMOKE HELPER
// =============================================================================
/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_smoke(turf/T, lifetime = 3)
	if(!istype(T) || !istype(T, /turf/open))
		return
	var/obj/effect/particle_effect/smoke/S = new(T)
	S.amount = 0
	S.lifetime = lifetime
	S.set_opacity(TRUE)

// =============================================================================
// NO-OP LEGACY AI HOOKS (paranoia: AIStatus is AI_OFF, but keep handlers inert)
// =============================================================================
/mob/living/simple_animal/hostile/megafauna/helicopter/handle_automated_movement()
	return FALSE

/mob/living/simple_animal/hostile/megafauna/helicopter/handle_automated_action()
	return

// =============================================================================
// ROTOR LOOP - one repeat sound on a reserved channel per listener, re-synced
// every tick. A looping_sound datum used to replay a ~20s file every few
// seconds and could not be cut on death; the channel stop is instant.
// =============================================================================
// Critical-hull alarm: loops the damage beep for ~5 seconds, then cuts it.
// Tracked per-listener so the loop cannot outlive its burst or follow
// players who left the area mid-beep.
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
	sleep(50) // ~5 seconds of warning beeps
	for(var/mob/listener in hearers)
		if(!QDELETED(listener))
			listener.stop_sound_channel(heli_crit_channel)

/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_update_rotor_sound()
	if(!heli_rotor_channel || heli_died || stat == DEAD)
		return
	if(heli_airborne)
		// Apache is away on an insertion run - cut the loop for everyone
		for(var/mob/listener in heli_rotor_listeners.Copy())
			if(!QDELETED(listener))
				listener.stop_sound_channel(heli_rotor_channel)
			heli_rotor_listeners -= listener
		return
	var/turf/ST = get_turf(src)
	if(!ST)
		return
	// one viewers() snapshot drives both removal and addition, so the two
	// sides can never disagree on range metrics and churn listeners
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

// =============================================================================
// BOSS THEME - same pattern as the infected tank's tanktheme.ogg
// =============================================================================
// Theme listeners are re-synced every tick: anyone who leaves the
// ihategordon area (or dies) loses the loop, and players inside the zone
// get it regardless of how far they are from the gunship - the track is
// zone ambience, not a positional sound.
/mob/living/simple_animal/hostile/megafauna/helicopter/proc/heli_update_theme_sound()
	if(!heli_theme_channel || heli_died || stat == DEAD)
		return
	for(var/mob/listener in heli_theme_listeners.Copy())
		if(QDELETED(listener) || listener.stat == DEAD || !istype(get_area(listener), /area/awaymission/ihategordon))
			stop_theme_listener_sound(listener)
			unregister_theme_listener(listener)
	// no new listeners while the intro cinematic or an osprey insertion
	// has the gunship "away" - same gate the old one-shot version had
	if(heli_cutscene || stat != CONSCIOUS)
		return
	for(var/mob/living/nearby_mob in GLOB.player_list)
		if(QDELETED(nearby_mob) || nearby_mob.stat == DEAD || nearby_mob in heli_theme_listeners)
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
	// idempotent: same stale-callback guard as the tank theme
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
	heli_theme_listeners.Cut()

// =============================================================================
// DEATH RIFT PORTAL - the gunship's wreck leaves a linked portal pair that
// ignores the Black Mesa NOTELEPORT area flag (force_teleport = TRUE).
// =============================================================================
/obj/effect/portal/mesa_rift
	name = "Black Mesa rift"
	desc = "A crackling tear in reality left behind by the destroyed gunship."
	force_teleport = TRUE
	mech_sized = TRUE
	anchored = TRUE

// =============================================================================
// COLIN GREY RADIO - plays the intro transmission, then triggers the
// helicopter landing cinematic. Place one inside the Black Mesa arena.
// =============================================================================
/obj/machinery/negotiations_radio/helicopter
	name = "distress radio"
	desc = "A crackling field radio. Someone is begging for help on the other end."
	icon_state = "radiohecu"
	detection_range = 12
	// Breakable field radio: keeps environmental immunity but loses
	// INDESTRUCTIBLE, so small arms/explosions can silence Colin for good.
	resistance_flags = LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF | FREEZE_PROOF
	max_integrity = 100
	// Sealed once Colin's transmission ends: every door/airlock whose id
	// matches blastdoor_id slams shut for the gunship fight.
	blastdoor_id = "helicopter"
	var/colin_sequence_active = FALSE
	var/colin_sequence_done = FALSE
	var/list/colin_lines = list(
		"ЭЙ!... Э-это К-колин Г-грэй! П-подойдите живо... Я в рубке!...",
		"П-пожалуйста! Ответьте живо!!!... Я в рубке!",
		"Я-... Я всё могу объяснить! ...НЕТ! НЕ МОГУ! К ВАМ ПРЯМО СЕЙЧАС ЛЕТИТ ВЕРТУШКА! У НИХ ПРИКАЗ ВАС УБИТЬ",
		"Я не могу... Боже... Мы обречены!!!"
	)

/obj/machinery/negotiations_radio/helicopter/Initialize(mapload)
	. = ..()
	next_detection_time = 0 //detect players immediately, no warmup cooldown

/obj/machinery/negotiations_radio/helicopter/process()
	// same as parent but without the random HECU chatter loop
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
	// The gunship may ONLY spawn after a player actually uses the radio.
	// Proximity detection (play_alert_phrase) must never start the sequence.
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
	// Just a proximity hint (icon + chime). The Colin Grey transmission -
	// and the helicopter spawn at its end - waits for attack_hand().
	if(colin_sequence_done || colin_sequence_active)
		return
	icon_state = "radiohecu_talking"
	playsound(src, 'sound/machines/chime.ogg', 70, FALSE, 7, 3)
	addtimer(CALLBACK(src, PROC_REF(reset_icon)), 3 SECONDS)

/obj/machinery/negotiations_radio/helicopter/proc/colin_sequence()
	icon_state = "radiohecu_talking"
	// say() with a language crashes inside lang_treat if the language subsystem
	// has not spawned the instance yet (e.g. triggered during map load).
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
	// hand off to the gunship: spawn it on the cinematic pad, it lands,
	// takes a missile shot at the target pad, then starts attacking
	spawn_helicopter_boss()
	close_blastdoors()

// ID-based lockdown: same matching rules as open_blastdoors() in
// mesanpc.dm (poddoor/brigdoor by .id, airlock by .id_tag) but closes.
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
		visible_message("<span class='boldwarning'>Blast doors seal the sector - there is no way out!</span>")

// Finds the first mapped landmark of `type` on the radio's z-level.
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
	// never drop the boss onto a blocked tile - step to a free neighbour
	if(is_blocked_turf(spawn_t, TRUE))
		for(var/dir in GLOB.alldirs)
			var/turf/N = get_step(spawn_t, dir)
			if(N && istype(N, /turf/open) && !is_blocked_turf(N, TRUE))
				spawn_t = N
				break
	var/mob/living/simple_animal/hostile/megafauna/helicopter/boss = new /mob/living/simple_animal/hostile/megafauna/helicopter(spawn_t)
	if(boss && !QDELETED(boss))
		boss.heli_start_cinematic()
