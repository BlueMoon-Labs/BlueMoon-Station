// =============================================================================
// BLACK MESA ZOMBIE HORDE SYSTEM
// AI Director controlled zombie waves for ihategordon mission
// =============================================================================

// Hunter infected stealth ability
#define HUNTER_STEALTH "hunter_stealth"

// =============================================================================
// ACID OOZE POOL
// =============================================================================

/obj/effect/decal/cleanable/acid_ooze
	name = "acid ooze"
	desc = "A bubbling pool of acidic sludge that burns on contact."
	icon = 'icons/effects/effects.dmi'
	icon_state = "greenglow"
	color = "#32CD32"
	layer = ABOVE_NORMAL_TURF_LAYER
	anchored = TRUE
	density = FALSE
	var/damage_per_tick = 5
	var/duration = 100 // 10 seconds (100 deciseconds)
	var/processing = FALSE

/obj/effect/decal/cleanable/acid_ooze/Initialize(mapload)
	. = ..()
	QDEL_IN(src, duration)

/obj/effect/decal/cleanable/acid_ooze/Entered(atom/movable/AM)
	. = ..()
	if(!AM)
		return
	if(can_burn(AM))
		start_processing()

/obj/effect/decal/cleanable/acid_ooze/proc/start_processing()
	if(!processing)
		processing = TRUE
		START_PROCESSING(SSobj, src)

/obj/effect/decal/cleanable/acid_ooze/process()
	if(!burn_stuff())
		STOP_PROCESSING(SSobj, src)
		processing = FALSE

/obj/effect/decal/cleanable/acid_ooze/proc/can_burn(atom/movable/target)
	if(!target)
		return FALSE
	if(isobj(target))
		var/obj/O = target
		if(O.resistance_flags & ACID_PROOF)
			return FALSE
	if(isliving(target))
		var/mob/living/L = target
		if(L.stat == DEAD)
			return FALSE
		if(istype(L, /mob/living/simple_animal/hostile/infected))
			return FALSE // Infected are immune
	return TRUE

/obj/effect/decal/cleanable/acid_ooze/proc/burn_stuff()
	var/something_burning = FALSE
	for(var/atom/movable/AM in get_turf(src))
		if(!can_burn(AM))
			continue
		do_burn(AM)
		something_burning = TRUE
	return something_burning

/obj/effect/decal/cleanable/acid_ooze/proc/do_burn(atom/movable/target)
	if(QDELETED(target))
		return
	if(isobj(target))
		return // Don't damage objects, only living mobs
	else if(isliving(target))
		var/mob/living/L = target
		// Direct damage without causing nausea
		L.health -= damage_per_tick
		L.updatehealth()
		if(L.client)
			to_chat(L, span_warning("The acid ooze burns you!"))

// =============================================================================
// ACID SPIT PROJECTILE
// =============================================================================

/obj/item/projectile/neurotox/acid_spit
	name = "acid spit"
	icon_state = "declone"
	damage = 15
	damage_type = BURN
	nodamage = FALSE
	flag = "acid"
	impact_effect_type = /obj/effect/temp_visual/impact_effect/acid_spit
	hitsound = 'modular_bluemoon/sound/creatures/mesa/bullsquid/splat1.ogg'
	hitsound_wall = 'modular_bluemoon/sound/creatures/mesa/bullsquid/splat1.ogg'

/obj/effect/temp_visual/impact_effect/acid_spit
	icon_state = "greenglow"
	color = "#32CD32"
	icon = 'icons/effects/effects.dmi'
	layer = ABOVE_ALL_MOB_LAYER
	duration = 3

/obj/effect/temp_visual/impact_effect/acid_spit/Initialize(mapload)
	. = ..()
	var/turf/T = get_turf(src)
	if(!T)
		return
	for(var/x_offset = -1 to 1)
		for(var/y_offset = -1 to 1)
			var/turf/pool_turf = locate(T.x + x_offset, T.y + y_offset, T.z)
			if(pool_turf && !pool_turf.density)
				new /obj/effect/decal/cleanable/acid_ooze(pool_turf)

/obj/item/projectile/neurotox/acid_spit/on_hit(atom/target, blocked = FALSE)
	. = ..()
	if(!target)
		return
	if(isliving(target))
		var/mob/living/L = target
		if(!L)
			return
		L.adjustToxLoss(10)
		if(L.client)
			to_chat(L, span_warning("The acid burns your skin!"))

// Move speed modifier for infected slow effect
/datum/movespeed_modifier/infected_slow
	id = MOVESPEED_ID_INFECTED_SLOW
	multiplicative_slowdown = 15.0
	blacklisted_movetypes = FLOATING

// Move speed modifier for bruiser slow effect (stronger)
/datum/movespeed_modifier/bruiser_slow
	id = MOVESPEED_ID_BRUISER_SLOW
	multiplicative_slowdown = 20.0
	blacklisted_movetypes = FLOATING

// Move speed modifier for infected damage slow (when hit)
/datum/movespeed_modifier/infected_damage_slow
	id = MOVESPEED_ID_INFECTED_DAMAGE_SLOW
	multiplicative_slowdown = 3.0
	blacklisted_movetypes = FLOATING

// Parent infected mob type
/mob/living/simple_animal/hostile/infected
	name = "infected"
	desc = "A horrific creature that was once human."
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "scientist_zombie"
	icon_living = "scientist_zombie"
	icon_dead = "zombie_dead"
	mob_biotypes = list(MOB_ORGANIC, MOB_HUMANOID)
	faction = list(FACTION_XEN)
	turns_per_move = 0 // Instant reaction time
	maxHealth = 100
	health = 100
	speed = 0 // Instant movement
	melee_damage_lower = 10
	melee_damage_upper = 15
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/creatures/zombie_attack.ogg'
	speak = list('sound/creatures/zombie_idle1.ogg', 'sound/creatures/zombie_idle2.ogg', 'sound/creatures/zombie_idle3.ogg')
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	robust_searching = 1
	search_objects = 1
	wanted_objects = list(/obj/structure/urbanism_generator)
	environment_smash = ENVIRONMENT_SMASH_NONE // Disable structure smashing to prevent attacking fences
	gold_core_spawnable = NO_SPAWN
	density = TRUE
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	vision_range = 25 // Increased pursuit distance
	aggro_vision_range = 30 // Increased aggro range when attacked
	var/is_runner = FALSE
	// Allow zombies to climb tables and pass through fences
	pass_flags = PASSTABLE | PASSFENCE
	pass_flags_self = NONE
	sight = 20 // High sight range to detect players from far away
	move_on_shuttle = TRUE // Allow movement during shuttle transit (helps with pathfinding)
	stop_automated_movement = 0 // Don't stop automated movement
	// Disable fractures and dislocations completely
	wound_bonus = 0
	bare_wound_bonus = 0
	sharpness = SHARP_NONE // Prevent cutting wounds

/mob/living/simple_animal/hostile/infected/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/swarming)
	// Initialize wanted_objects typecache at runtime to avoid constant-expression compile errors
	wanted_objects = typecacheof(wanted_objects, TRUE)

/mob/living/simple_animal/hostile/infected/Move(atom/newloc, dir, step_x, step_y)
	if(handle_fence_movement(newloc))
		return
	. = ..()

/mob/living/simple_animal/hostile/infected/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	if(amount < 0 && !stat)
		add_movespeed_modifier(/datum/movespeed_modifier/infected_damage_slow, TRUE)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/infected_damage_slow), 1 SECONDS)

/mob/living/simple_animal/hostile/infected/CanAttack(atom/the_target)
	if(!the_target)
		return FALSE
	if(istype(the_target, /obj/structure/urbanism_generator))
		var/obj/structure/urbanism_generator/G = the_target
		if(!G || !G.activating)
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/infected/death(gibbed)
	. = ..(gibbed)
	if(!ckey)
		toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/infected/Aggro()
	. = ..()
	if(speak && speak.len && prob(30))
		playsound(src, pick(speak), 70, TRUE)

/mob/living/simple_animal/hostile/infected/AttackingTarget(atom/target)
	. = ..()
	if(!target)
		return
	if(isliving(target))
		var/mob/living/L = target
		if(L && L.client && L.stat != DEAD)
			L.add_movespeed_modifier(/datum/movespeed_modifier/infected_slow, TRUE)
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/infected_slow), 5 SECONDS)
			to_chat(L, span_warning("Вас замедлил заражённый!"))

// Shared fence movement logic for all infected types
/mob/living/simple_animal/hostile/infected/proc/handle_fence_movement(atom/newloc)
	if(newloc)
		for(var/obj/structure/fence/nocut/F in newloc)
			if(F && F.Adjacent(src))
				return forceMove(newloc)
	return FALSE

// =============================================================================
// TIER 1: RUNNER ZOMBIE (DEPRECATED - No longer spawned)
// Fast, low HP, high sight, dense-stacking, can climb fences
// =============================================================================
/mob/living/simple_animal/hostile/infected/runner
	name = "runner infected"
	desc = "A fast-moving infected creature. It moves with terrifying speed."
	icon = 'modular_bluemoon/icons/mob/mesa_mobs.dmi'
	icon_state = "hecu_zombie"
	icon_living = "hecu_zombie"
	maxHealth = 60
	health = 60
	speed = 0
	melee_damage_lower = 8
	melee_damage_upper = 12
	sight = 20
	robust_searching = 1
	is_runner = TRUE

// =============================================================================
// TIER 2: BRUISER ZOMBIE
// Slower, high HP, standard sight, normal movement
// =============================================================================
/mob/living/simple_animal/hostile/infected/bruiser
	name = "bruiser infected"
	desc = "A heavily built infected creature with thick muscle mass. It can take a lot of punishment."
	icon = 'modular_bluemoon/icons/mob/gonome.dmi'
	icon_state = "former_gonome"
	icon_living = "former_gonome"
	icon_dead = "former_dead"
	maxHealth = 100
	health = 100
	speed = 2 // Slightly faster
	turns_per_move = 0 // Faster reaction
	melee_damage_lower = 15
	melee_damage_upper = 25
	sight = 20 // High sight range to detect players from far away
	robust_searching = 1
	environment_smash = ENVIRONMENT_SMASH_NONE // Disable structure smashing to prevent attacking fences
	harm_intent_damage = 20
	obj_damage = 40
	// Disable fractures and dislocations completely
	wound_bonus = 0
	bare_wound_bonus = 0
	sharpness = SHARP_NONE // Prevent cutting wounds

/mob/living/simple_animal/hostile/infected/bruiser/AttackingTarget(atom/target)
	. = ..()
	if(!target)
		return
	if(isliving(target))
		var/mob/living/L = target
		if(L && L.client && L.stat != DEAD)
			L.add_movespeed_modifier(/datum/movespeed_modifier/bruiser_slow, TRUE)
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/bruiser_slow), 6 SECONDS)
			to_chat(L, span_warning("Вас сильно замедлил bruiser!"))

/mob/living/simple_animal/hostile/infected/bruiser/Move(atom/newloc, dir, step_x, step_y)
	if(handle_fence_movement(newloc))
		return
	. = ..()

/mob/living/simple_animal/hostile/infected/bruiser/Aggro()
	. = ..()
	if(speak && speak.len && prob(40))
		playsound(src, pick(speak), 80, TRUE)

/mob/living/simple_animal/hostile/infected/bruiser/alt
	icon_state = "former_gonome_alt"
	icon_living = "former_gonome_alt"

// =============================================================================
// TIER 3: ACID SPITTER ZOMBIE
// Bruiser HP, acid spit attack, explodes into acid pool on death
// Only spawns after trigger4 (difficulty level 4+)
// =============================================================================
/mob/living/simple_animal/hostile/infected/acid_spitter
	name = "acid spitter infected"
	desc = "A heavily built infected creature with swollen acid glands. It can spit corrosive acid and explodes into a toxic pool when killed."
	icon = 'modular_bluemoon/icons/mob/gonome.dmi'
	icon_state = "boomer"
	icon_living = "boomer"
	icon_dead = "former_dead"
	maxHealth = 100
	health = 100
	speed = 2
	turns_per_move = 0
	melee_damage_lower = 15
	melee_damage_upper = 25
	sight = 20
	robust_searching = 1
	environment_smash = ENVIRONMENT_SMASH_NONE
	harm_intent_damage = 20
	obj_damage = 40
	// Ranged attack settings
	ranged = TRUE
	ranged_cooldown_time = 40 // 4 seconds between acid spits
	retreat_distance = 4
	minimum_distance = 3
	projectiletype = /obj/item/projectile/neurotox/acid_spit
	projectilesound = 'sound/effects/blobattack.ogg'
	// Disable fractures and dislocations completely
	wound_bonus = 0
	bare_wound_bonus = 0
	sharpness = SHARP_NONE

/mob/living/simple_animal/hostile/infected/acid_spitter/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/swarming)
	wanted_objects = typecacheof(wanted_objects, TRUE)

/mob/living/simple_animal/hostile/infected/acid_spitter/AttackingTarget(atom/target)
	. = ..()
	if(!target)
		return
	if(isliving(target))
		var/mob/living/L = target
		if(L && L.client && L.stat != DEAD)
			L.add_movespeed_modifier(/datum/movespeed_modifier/bruiser_slow, TRUE)
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/bruiser_slow), 6 SECONDS)
			to_chat(L, span_warning("Вас сильно замедлил acid spitter!"))

/mob/living/simple_animal/hostile/infected/acid_spitter/Move(atom/newloc, dir, step_x, step_y)
	if(handle_fence_movement(newloc))
		return
	. = ..()

/mob/living/simple_animal/hostile/infected/acid_spitter/Aggro()
	. = ..()
	if(speak && speak.len && prob(40))
		playsound(src, pick(speak), 80, TRUE)

/mob/living/simple_animal/hostile/infected/acid_spitter/death(gibbed)
	. = ..(gibbed)
	var/turf/death_turf = get_turf(src)
	if(!death_turf)
		return
	for(var/x_offset = -1 to 1)
		for(var/y_offset = -1 to 1)
			var/turf/pool_turf = locate(death_turf.x + x_offset, death_turf.y + y_offset, death_turf.z)
			if(pool_turf && !pool_turf.density)
				new /obj/effect/decal/cleanable/acid_ooze(pool_turf)
	playsound(death_turf, 'sound/effects/splat.ogg', 100, TRUE)
	if(!ckey)
		toggle_ai(AI_OFF)

// =============================================================================
// TIER 4: CHARGER ZOMBIE
// Charge attack mechanic based on bubblegum/guardian charger
// Maintains distance, then charges. If hits player - drags to wall. If misses - stuns.
// Only spawns after trigger4 (difficulty level 4+)
// =============================================================================
/mob/living/simple_animal/hostile/infected/charger
	name = "charger infected"
	desc = "A muscular infected creature built for speed. It charges at high velocity to slam into targets."
	icon = 'modular_bluemoon/icons/mob/gonome.dmi'
	icon_state = "charger"
	icon_living = "charger"
	icon_dead = "former_dead"
	maxHealth = 100
	health = 100
	speed = 2
	turns_per_move = 0
	melee_damage_lower = 10
	melee_damage_upper = 15
	sight = 20
	robust_searching = 1
	environment_smash = ENVIRONMENT_SMASH_NONE
	harm_intent_damage = 15
	obj_damage = 40
	wound_bonus = 0
	bare_wound_bonus = 0
	sharpness = SHARP_NONE
	// Use built-in charge system from hostile.dm
	charger = TRUE
	charge_distance = 15 // Long charge distance
	charge_frequency = 4 SECONDS // 4 seconds cooldown
	knockdown_time = 2 SECONDS // 2 seconds knockdown on hit
	minimum_distance = 1 // Get close to target by default
	retreat_distance = null // Don't retreat by default
	var/charge_damage = 40
	var/charge_stamina_damage = 60
	var/charge_hit_target = FALSE

/mob/living/simple_animal/hostile/infected/charger/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/swarming)
	wanted_objects = typecacheof(wanted_objects, TRUE)
	// Start with cooldown ready
	COOLDOWN_START(src, charge_cooldown, 0)

/mob/living/simple_animal/hostile/infected/charger/AttackingTarget(atom/target)
	. = ..()
	if(!target)
		return
	if(isliving(target))
		var/mob/living/L = target
		if(L && L.client && L.stat != DEAD)
			L.add_movespeed_modifier(/datum/movespeed_modifier/bruiser_slow, TRUE)
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/bruiser_slow), 6 SECONDS)
			to_chat(L, span_warning("Вас сильно замедлил charger!"))

/mob/living/simple_animal/hostile/infected/charger/Move(atom/newloc, dir, step_x, step_y)
	if(handle_fence_movement(newloc))
		return
	if(charge_state)
		new /obj/effect/temp_visual/decoy/fading(loc, src)
		shake_camera(src, 1, 1)
	. = ..()

/mob/living/simple_animal/hostile/infected/charger/Aggro()
	. = ..()
	if(speak && speak.len && prob(40))
		playsound(src, pick(speak), 80, TRUE)

// Override throw_impact for custom charge logic
/mob/living/simple_animal/hostile/infected/charger/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!charge_state)
		return ..()

	if(isliving(hit_atom))
		var/mob/living/L = hit_atom
		if(!L)
			return

		charge_hit_target = TRUE
		L.visible_message("<span class='danger'>[src] slams into [L]!</span>", "<span class='userdanger'>[src] slams into you!</span>")
		playsound(get_turf(L), 'modular_bluemoon/sound/creatures/mesa/charger/attacksound.ogg', 100, TRUE)

		L.apply_damage(charge_damage, BRUTE)
		L.adjustStaminaLoss(charge_stamina_damage)
		if(L.client)
			to_chat(L, span_userdanger("You're slammed by the charger!"))

		shake_camera(L, 4, 3)
		shake_camera(src, 2, 3)

		var/throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(L, src)))
		L.throw_at(throwtarget, 5)

	else if(hit_atom.density && !hit_atom.CanPass(src))
		visible_message("<span class='danger'>[src] crashes into [hit_atom]!</span>")
		playsound(get_turf(src), 'modular_bluemoon/sound/creatures/mesa/charger/attacksound.ogg', 100, TRUE)
		Stun(40) // 4 seconds stun on miss

// Override to play charge start sound and skip windup
/mob/living/simple_animal/hostile/infected/charger/enter_charge(var/atom/target)
	if((mobility_flags & (MOBILITY_MOVE | MOBILITY_STAND)) != (MOBILITY_MOVE | MOBILITY_STAND) || charge_state || charge_windup_timer)
		return FALSE

	if(!(COOLDOWN_FINISHED(src, charge_cooldown)) || !has_gravity() || !target.has_gravity())
		return FALSE

	COOLDOWN_START(src, charge_cooldown, charge_frequency)
	visible_message("<span class='danger'><b>[src]</b> charges!</span>")
	playsound(src, 'modular_bluemoon/sound/creatures/mesa/charger/charge_02.ogg', 100, TRUE)

	// Temporarily disable retreat to allow charge
	var/old_retreat = retreat_distance
	var/old_minimum = minimum_distance
	retreat_distance = null
	minimum_distance = 1

	// Skip windup, charge immediately
	charge_state = TRUE
	throw_at(target, charge_distance, 1, src, FALSE, TRUE, callback = CALLBACK(src, PROC_REF(charge_end)))

	// Restore retreat settings after charge starts
	addtimer(CALLBACK(src, PROC_REF(restore_retreat_settings), old_retreat, old_minimum), 0.1 SECONDS)
	return TRUE

/mob/living/simple_animal/hostile/infected/charger/proc/restore_retreat_settings(old_retreat, old_minimum)
	retreat_distance = old_retreat
	minimum_distance = old_minimum

// Override charge_end for retreat logic after hit
/mob/living/simple_animal/hostile/infected/charger/charge_end()
	. = ..()
	if(charge_hit_target)
		// Start retreat after 1 second delay
		charge_hit_target = FALSE
		addtimer(CALLBACK(src, PROC_REF(start_retreat)), 1 SECONDS)

/mob/living/simple_animal/hostile/infected/charger/proc/start_retreat()
	retreat_distance = 6
	minimum_distance = 5
	// Stop retreat after 2 seconds
	addtimer(CALLBACK(src, PROC_REF(stop_retreat)), 2 SECONDS)

/mob/living/simple_animal/hostile/infected/charger/proc/stop_retreat()
	retreat_distance = null
	minimum_distance = 1

/mob/living/simple_animal/hostile/infected/charger/AttackingTarget(atom/target)
	. = ..()
	// Disable normal melee attacks - charger should only use charge
	return

/mob/living/simple_animal/hostile/infected/charger/death(gibbed)
	. = ..(gibbed)
	charge_state = FALSE
	if(!ckey)
		toggle_ai(AI_OFF)

// =============================================================================
// TIER 4: HUNTER ZOMBIE
// Stealthy, high damage, isolates players, drags victims to darkness
// =============================================================================
/mob/living/simple_animal/hostile/infected/hunter
	name = "hunter infected"
	desc = "A terrifying creature that moves silently through darkness, hunting isolated prey with deadly leaps."
	icon = 'modular_bluemoon/icons/mob/gonome.dmi'
	icon_state = "gonome_fast"
	icon_living = "gonome_fast"
	icon_dead = "former_dead"
	mob_biotypes = list(MOB_ORGANIC, MOB_HUMANOID)
	faction = list(FACTION_XEN)
	maxHealth = 70
	health = 70
	speed = 0
	melee_damage_lower = 25
	melee_damage_upper = 35
	attack_verb_continuous = "mauls"
	attack_verb_simple = "maul"
	attack_sound = 'modular_bluemoon/sound/creatures/mesa/hunter/punch2.ogg'
	speak = list('modular_bluemoon/sound/creatures/mesa/hunter/hunter1.ogg', 'modular_bluemoon/sound/creatures/mesa/hunter/hunter2.ogg')
	deathsound = 'modular_bluemoon/sound/creatures/mesa/hunter/death.ogg'
	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0
	maxbodytemp = 1500
	robust_searching = 1
	search_objects = 1
	wanted_objects = list(/obj/structure/urbanism_generator)
	environment_smash = ENVIRONMENT_SMASH_NONE
	gold_core_spawnable = NO_SPAWN
	density = TRUE
	mouse_opacity = MOUSE_OPACITY_OPAQUE
	vision_range = 25
	aggro_vision_range = 30
	pass_flags = PASSTABLE | PASSFENCE
	pass_flags_self = NONE
	sight = 20
	move_on_shuttle = TRUE
	stop_automated_movement = 0
	wound_bonus = 0
	bare_wound_bonus = 0
	sharpness = SHARP_NONE
	// Hunter-specific variables
	var/is_stealthed = FALSE
	var/mob/living/dragging_target = null
	var/mob/living/ignored_target = null
	var/stealth_alpha = 30
	var/light_threshold = SHADOW_SPECIES_LIGHT_THRESHOLD
	var/leap_range = 6
	var/leap_cooldown_time = 2.5 SECONDS
	var/leap_damage = 35
	var/miss_stun_duration = 1.5 SECONDS
	var/last_light_check = 0
	var/light_check_interval = 5
	// AI configuration - use ranged attack for leap (like headcrab)
	ranged = TRUE
	ranged_message = "leaps"
	ranged_cooldown_time = 25 // 2.5 seconds in deciseconds
	var/jumpdistance = 6
	var/jumpspeed = 1
	var/is_leaping = FALSE
	var/is_dragging = FALSE
	var/drag_distance = 0
	var/drag_target_distance = 15
	var/drag_direction = null
	// Dodging configuration - higher dodge chance for evasive movement
	dodge_prob = 60

/mob/living/simple_animal/hostile/infected/hunter/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/swarming)
	wanted_objects = typecacheof(wanted_objects, TRUE)

/mob/living/simple_animal/hostile/infected/hunter/Move(atom/newloc, dir, step_x, step_y)
	if(handle_fence_movement(newloc))
		return
	. = ..()

/mob/living/simple_animal/hostile/infected/hunter/Life()
	. = ..()
	if(speak && speak.len && prob(5))
		playsound(get_turf(src), pick(speak), 100, TRUE, FALSE, 100)
	handle_stealth()

/mob/living/simple_animal/hostile/infected/hunter/proc/handle_stealth()
	if(!src)
		return
	if(world.time < last_light_check + light_check_interval)
		return
	last_light_check = world.time

	var/turf/T = get_turf(src)
	if(!T)
		return

	// Calculate light excluding background floodlights
	var/light_amount = T.get_lumcount()

	// Check for background floodlights nearby and reduce their light contribution
	var/turf/nearby_turf = locate(/obj/machinery/power/floodlight) in range(10, src)
	if(nearby_turf)
		light_amount *= 0.3 // Reduce effect of background floodlights by 70%

	if(light_amount < light_threshold)
		if(!is_stealthed)
			is_stealthed = TRUE
			animate(src, alpha = stealth_alpha, time = 10)
			ADD_TRAIT(src, TRAIT_STRONG_INVISIBILITY, HUNTER_STEALTH)
			var/mutable_appearance/eyes = mutable_appearance(icon, "hunter_eyes")
			eyes.layer = ABOVE_MOB_LAYER
			add_overlay(eyes)
	else
		if(is_stealthed)
			is_stealthed = FALSE
			animate(src, alpha = 255, time = 5)
			REMOVE_TRAIT(src, TRAIT_STRONG_INVISIBILITY, HUNTER_STEALTH)
			cut_overlay("hunter_eyes")

/mob/living/simple_animal/hostile/infected/hunter/Aggro()
	. = ..()
	if(speak && speak.len && prob(60))
		playsound(get_turf(src), 'modular_bluemoon/sound/creatures/mesa/hunter/greetings.ogg', 100, TRUE, FALSE, 100)

/mob/living/simple_animal/hostile/infected/hunter/CanAttack(atom/the_target)
	if(!the_target)
		return FALSE
	if(ignored_target && the_target == ignored_target)
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/infected/hunter/OpenFire(atom/A)
	if(check_friendly_fire)
		for(var/turf/T in getline(src,A))
			for(var/mob/living/L in T)
				if(L == src || L == A)
					continue
				if(faction_check_mob(L) && !attack_same)
					return

	visible_message("<span class='danger'><b>[src]</b> [ranged_message] at [A]!</span>")
	playsound(get_turf(src), 'modular_bluemoon/sound/creatures/mesa/hunter/hscream.ogg', 80, TRUE, FALSE, 100)
	shake_camera(src, 2, 2)
	is_leaping = TRUE
	throw_at(A, jumpdistance, jumpspeed, spin = FALSE, diagonals_first = TRUE)
	ranged_cooldown = world.time + ranged_cooldown_time

/mob/living/simple_animal/hostile/infected/hunter/Bump(atom/A)
	if(!A)
		return
	if(is_leaping)
		is_leaping = FALSE
	if(isliving(A))
		var/mob/living/L = A
		if(L && L.stat != DEAD)
			L.apply_damage(leap_damage, BRUTE)
			L.Paralyze(20)
			shake_camera(L, 4, 3)
			shake_camera(src, 2, 3)

		// Start dragging victim manually
		if(!is_dragging)
			start_dragging(L)
		else if(A.density && !A.CanPass(src))
			visible_message("<span class='danger'>[src] crashes into [A]!</span>")
			playsound(get_turf(src), 'modular_bluemoon/sound/creatures/mesa/hunter/punch2.ogg', 80, TRUE, FALSE, 100)
			Stun(miss_stun_duration * 10)

/mob/living/simple_animal/hostile/infected/hunter/proc/crit_and_ignore(mob/living/victim)
	if(!victim || QDELETED(victim))
		return
	if(victim.stat == DEAD)
		return

	// Leave victim in critical condition
	victim.health = -victim.maxHealth * 0.5
	victim.updatehealth()
	if(victim.client)
		to_chat(victim, span_userdanger("Вас оставили в критическом состоянии!"))

	// Add to ignore list so hunter won't target them again
	ignored_target = victim

/mob/living/simple_animal/hostile/infected/hunter/death(gibbed)
	. = ..(gibbed)
	is_leaping = FALSE
	dragging_target = null
	stop_pulling()
	is_stealthed = FALSE
	animate(src, alpha = 255, time = 5)
	REMOVE_TRAIT(src, TRAIT_STRONG_INVISIBILITY, HUNTER_STEALTH)
	if(!ckey)
		toggle_ai(AI_OFF)

// =============================================================================
// ZOMBIE SPAWN LANDMARK
// Invisible landmark that randomly spawns infected or bruiser zombies
// =============================================================================
/obj/effect/landmark/zombie_spawn
	name = "zombie spawn"
	icon_state = "x"
	invisibility = INVISIBILITY_ABSTRACT // Completely invisible
	anchored = TRUE
	layer = MID_LANDMARK_LAYER

	var/spawn_chance = 30 // 30% chance to spawn on round start
	var/spawn_mob_types = list(
		/mob/living/simple_animal/hostile/infected = 70,
		/mob/living/simple_animal/hostile/infected/bruiser = 30
	)
	var/spawn_mob_types_diff4 = list(
		/mob/living/simple_animal/hostile/infected = 40,
		/mob/living/simple_animal/hostile/infected/bruiser = 25,
		/mob/living/simple_animal/hostile/infected/acid_spitter = 20,
		/mob/living/simple_animal/hostile/infected/charger = 15
	)
	var/spawn_mob_types_diff5 = list(
		/mob/living/simple_animal/hostile/infected = 55,
		/mob/living/simple_animal/hostile/infected/bruiser = 20,
		/mob/living/simple_animal/hostile/infected/bruiser/alt = 10,
		/mob/living/simple_animal/hostile/infected/acid_spitter = 5,
		/mob/living/simple_animal/hostile/infected/charger = 7,
		/mob/living/simple_animal/hostile/infected/hunter = 3
	)

/obj/effect/landmark/zombie_spawn/Initialize(mapload)
	. = ..()
	if(mapload && prob(spawn_chance))
		spawn_zombie()
	return INITIALIZE_HINT_QDEL

/obj/effect/landmark/zombie_spawn/proc/spawn_zombie()
	var/turf/spawn_turf = get_turf(src)
	if(!spawn_turf)
		return

	// Check if spawn location is valid (not blocked)
	if(spawn_turf.density)
		return

	for(var/atom/movable/A in spawn_turf)
		if(A.density)
			return

	// Choose mob type based on weights and difficulty level
	var/list/current_spawn_types = spawn_mob_types
	if(GLOB.zombie_director)
		var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
		if(D && D.difficulty_level >= 5)
			current_spawn_types = spawn_mob_types_diff5
		else if(D && D.difficulty_level >= 4)
			current_spawn_types = spawn_mob_types_diff4

	var/mob_type = pickweight(current_spawn_types)
	if(!mob_type)
		return

	var/mob/living/simple_animal/hostile/infected/Z = new mob_type(spawn_turf)
	if(Z)
		// Apply HP multiplier from zombie director if available
		if(GLOB.zombie_director)
			var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
			if(D && D.zombie_hp_multiplier > 1.0)
				Z.maxHealth = round(Z.maxHealth * D.zombie_hp_multiplier)
				Z.health = Z.maxHealth
/mob/living/simple_animal/hostile/infected/hunter/Bump(atom/A)
	if(!A)
		return
	if(is_leaping)
		is_leaping = FALSE
	if(isliving(A))
		var/mob/living/L = A
		if(L && L.stat != DEAD)
			L.apply_damage(leap_damage, BRUTE)
			L.Paralyze(20)
			shake_camera(L, 4, 3)
			shake_camera(src, 2, 3)

			// Start dragging victim manually
			if(!is_dragging)
				start_dragging(L)

	else if(A.density && !A.CanPass(src))
		visible_message("<span class='danger'>[src] crashes into [A]!</span>")
		playsound(get_turf(src), 'modular_bluemoon/sound/creatures/mesa/hunter/punch2.ogg', 80, TRUE, FALSE, 100)
		Stun(miss_stun_duration * 10)

/mob/living/simple_animal/hostile/infected/hunter/proc/start_dragging(mob/living/victim)
	if(!victim || QDELETED(victim))
		return
	if(is_dragging)
		return

	is_dragging = TRUE
	dragging_target = victim
	drag_distance = 0

	// Find available direction for dragging
	var/list/available_dirs = list()
	for(var/d in list(NORTH, SOUTH, EAST, WEST))
		var/turf/T = get_step(src, d)
		if(T && !T.density)
			var/blocked = FALSE
			for(var/obj/structure/fence/nocut/F in T)
				if(F && F.Adjacent(src))
					blocked = TRUE
					break
			if(!blocked)
				available_dirs += d

	if(available_dirs.len)
		drag_direction = pick(available_dirs)
		// Set strong grab
		start_pulling(victim, supress_message = TRUE)
		setGrabState(GRAB_NECK)
		// Start dragging process
		drag_tick()

/mob/living/simple_animal/hostile/infected/hunter/proc/drag_tick()
	if(!is_dragging || !dragging_target || QDELETED(dragging_target))
		end_dragging()
		return

	if(drag_distance >= drag_target_distance)
		end_dragging()
		// Put victim in critical condition
		crit_and_ignore(dragging_target)
		return

	// Try to move in drag direction
	var/turf/next_turf = get_step(src, drag_direction)
	if(!next_turf || next_turf.density)
		end_dragging()
		crit_and_ignore(dragging_target)
		return

	// Check for fences
	var/fence_blocked = FALSE
	for(var/obj/structure/fence/nocut/F in next_turf)
		if(F && F.Adjacent(src))
			fence_blocked = TRUE
			break

	if(fence_blocked)
		end_dragging()
		crit_and_ignore(dragging_target)
		return

	// Move hunter and pull victim
	Move(next_turf, drag_direction)
	drag_distance++

	// Continue dragging
	addtimer(CALLBACK(src, PROC_REF(drag_tick)), 0.1 SECONDS)

/mob/living/simple_animal/hostile/infected/hunter/proc/end_dragging()
	is_dragging = FALSE
	dragging_target = null
	drag_distance = 0
	drag_direction = null
	stop_pulling()
