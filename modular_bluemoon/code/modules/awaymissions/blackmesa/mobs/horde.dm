// =============================================================================
// BLACK MESA ZOMBIE HORDE SYSTEM
// AI Director controlled zombie waves for ihategordon mission
// =============================================================================

// Move speed modifier for infected slow effect
/datum/movespeed_modifier/infected_slow
	id = MOVESPEED_ID_INFECTED_SLOW
	multiplicative_slowdown = 8.0
	blacklisted_movetypes = FLOATING

// Move speed modifier for bruiser slow effect (stronger)
/datum/movespeed_modifier/bruiser_slow
	id = MOVESPEED_ID_BRUISER_SLOW
	multiplicative_slowdown = 10.0
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
	environment_smash = ENVIRONMENT_SMASH_STRUCTURES
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

/mob/living/simple_animal/hostile/infected/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/swarming)
	// Initialize wanted_objects typecache at runtime to avoid constant-expression compile errors
	wanted_objects = typecacheof(wanted_objects, TRUE)

/mob/living/simple_animal/hostile/infected/adjustHealth(amount, updating_health = TRUE, forced = FALSE)
	. = ..()
	// Apply slowdown when taking damage
	if(amount < 0 && !stat)
		// Only slow if taking damage (negative amount)
		add_movespeed_modifier(/datum/movespeed_modifier/infected_damage_slow, TRUE)
		addtimer(CALLBACK(src, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/infected_damage_slow), 1 SECONDS)

/mob/living/simple_animal/hostile/infected/Found(atom/A)
	// Prioritize activating generators above all other targets
	if(istype(A, /obj/structure/urbanism_generator))
		var/obj/structure/urbanism_generator/G = A
		if(G && G.activating)
			return A
	return ..()

/mob/living/simple_animal/hostile/infected/CanAttack(atom/the_target)
	if(!the_target)
		return FALSE
	if(istype(the_target, /obj/structure/urbanism_generator))
		var/obj/structure/urbanism_generator/G = the_target
		if(!G)
			return FALSE
		if(!G.activating)
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
	// Crutch method: if attacking a fence, teleport to the fence tile
	if(istype(target, /obj/structure/fence))
		var/obj/structure/fence/F = target
		if(!F || !F.density)
			return
		if(!stat)
			var/turf/fence_turf = get_turf(F)
			if(fence_turf)
				forceMove(fence_turf)
				return
	. = ..()
	if(!target)
		return
	// Apply slow effect to living targets (players)
	if(isliving(target))
		var/mob/living/L = target
		if(!L)
			return
		if(L.client && L.stat != DEAD)
			// Apply temporary slow (5 seconds)
			L.add_movespeed_modifier(/datum/movespeed_modifier/infected_slow, TRUE)
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/infected_slow), 5 SECONDS)
			to_chat(L, span_warning("Вас замедлил заражённый!"))

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
	environment_smash = ENVIRONMENT_SMASH_WALLS
	harm_intent_damage = 20
	obj_damage = 40

/mob/living/simple_animal/hostile/infected/bruiser/AttackingTarget(atom/target)
	// Crutch method: if attacking a fence, teleport to the fence tile
	if(istype(target, /obj/structure/fence))
		var/obj/structure/fence/F = target
		if(!F || !F.density)
			return
		if(!stat)
			var/turf/fence_turf = get_turf(F)
			if(fence_turf)
				forceMove(fence_turf)
				return
	. = ..()
	if(!target)
		return
	// Apply strong slow effect to living targets (players)
	if(isliving(target))
		var/mob/living/L = target
		if(!L)
			return
		if(L.client && L.stat != DEAD)
			// Apply temporary strong slow (6 seconds)
			L.add_movespeed_modifier(/datum/movespeed_modifier/bruiser_slow, TRUE)
			addtimer(CALLBACK(L, TYPE_PROC_REF(/mob, remove_movespeed_modifier), /datum/movespeed_modifier/bruiser_slow), 6 SECONDS)
			to_chat(L, span_warning("Вас сильно замедлил бруiser!"))

/mob/living/simple_animal/hostile/infected/bruiser/Aggro()
	. = ..()
	if(speak && speak.len && prob(40))
		playsound(src, pick(speak), 80, TRUE)

/mob/living/simple_animal/hostile/infected/bruiser/alt
	icon_state = "former_gonome_alt"
	icon_living = "former_gonome_alt"

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

	// Choose mob type based on weights
	var/mob_type = pickweight(spawn_mob_types)
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
