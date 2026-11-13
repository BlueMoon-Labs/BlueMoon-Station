// =============================================================================
// BLACK MESA ZOMBIE HORDE SYSTEM
// AI Director controlled zombie waves for ihategordon mission
// =============================================================================

/datum/movespeed_modifier/status_effect/mesa_horde_slow
	multiplicative_slowdown = 1

/datum/status_effect/mesa_horde_slow
	id = "mesa_horde_slow"
	duration = 6
	status_type = STATUS_EFFECT_REFRESH
	alert_type = null

/datum/status_effect/mesa_horde_slow/on_apply()
	. = ..()
	if(.)
		owner.add_movespeed_modifier(/datum/movespeed_modifier/status_effect/mesa_horde_slow)

/datum/status_effect/mesa_horde_slow/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/mesa_horde_slow)
	return ..()

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
	// Start processing immediately and check for mobs already on the turf
	start_processing()
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
	burn_stuff()

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
		L.adjustFireLoss(damage_per_tick)
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
		L.adjustFireLoss(10)
		if(L.client)
			to_chat(L, span_warning("The acid burns your skin!"))

/obj/item/projectile/mesa_tank_rock
	name = "stone shard"
	icon = 'icons/obj/meteor.dmi'
	icon_state = "small1"
	damage = 20
	damage_type = BRUTE
	flag = BULLET
	hitsound = 'sound/effects/meteorimpact.ogg'
	hitsound_wall = 'sound/effects/meteorimpact.ogg'

/obj/item/projectile/mesa_tank_rock/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	if(isliving(target))
		var/mob/living/victim = target
		var/atom/throw_target = get_edge_target_turf(victim, get_dir(firer, victim))
		victim.throw_at(throw_target, 3, 1, firer)
		victim.Stun(3 SECONDS, ignore_canstun = TRUE)

/datum/ai_controller/hostile_adapter/mesa_tank
	ai_pack_role = AI_ROLE_TANK
	pursuit_leashed = FALSE
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm/mesa_tank,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/mesa_tank_rock_attack,
		/datum/ai_planning_subtree/tactical_approach,
		/datum/ai_planning_subtree/hostile_melee,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

/datum/ai_planning_subtree/hostile_fsm/mesa_tank/should_retreat(datum/ai_controller/controller)
	return FALSE

/datum/ai_planning_subtree/mesa_tank_rock_attack
	var/minimum_range = 3

/datum/ai_planning_subtree/mesa_tank_rock_attack/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/infected/tank/tank = controller.pawn
	if(!istype(tank))
		return
	if(tank.ranged_telegraph_timer_id)
		return SUBTREE_RETURN_FINISH_PLANNING
	var/atom/target = controller.blackboard[BB_AI_CURRENT_TARGET]
	if(QDELETED(target) || tank.ranged_cooldown > world.time)
		return
	var/distance = get_dist(tank, target)
	if(distance < minimum_range || distance > AI_RANGED_MAX_FIRE_RANGE || !can_see(tank, target, AI_RANGED_MAX_FIRE_RANGE))
		return
	//can_see смотрит только opacity, а Shoot() стреляет только по чистой
	//баллистической линии: без этой проверки танк вставал в телеграф сквозь
	//стол/труп в кресле и молча отменял бросок уже после остановки.
	if(tank.CheckRangedFireLane(target))
		return
	tank.target = target
	tank.telegraphed_open_fire(target)
	return SUBTREE_RETURN_FINISH_PLANNING

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
	maxHealth = 40
	health = 40
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
	sight = SEE_MOBS | SEE_TURFS // Битовая маска: видит мобов и турфы (дальность задаётся vision_range/aggro_vision_range)
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
		return TRUE
	. = ..()

/mob/living/simple_animal/hostile/infected/CanAttack(atom/the_target)
	if(!the_target)
		return FALSE
	if(istype(the_target, /obj/structure/urbanism_generator/fuel))
		// The fuel generator must never become a zombie target while players
		// feed it batteries - it would pull the whole horde off the players.
		return FALSE
	if(istype(the_target, /obj/structure/urbanism_generator))
		var/obj/structure/urbanism_generator/G = the_target
		if(!G || (!G.activating && !G.active && !G.waiting_for_fuel))
			return FALSE
	return ..()

/mob/living/simple_animal/hostile/infected/AttackingTarget()
	var/is_horde_mob = (type == /mob/living/simple_animal/hostile/infected) || istype(src, /mob/living/simple_animal/hostile/infected/runner) || istype(src, /mob/living/simple_animal/hostile/infected/bruiser)
	if(!is_horde_mob)
		return ..()
	if(!isliving(target))
		return ..()
	if(QDELETED(src) || QDELETED(target))
		return
	var/atom/attack_target = target
	if(SEND_SIGNAL(src, COMSIG_HOSTILE_ATTACKINGTARGET, attack_target) & COMPONENT_HOSTILE_NO_ATTACK)
		return
	if(QDELETED(src) || QDELETED(attack_target))
		return

	var/mob/living/victim = attack_target
	face_atom(victim)
	if(!CheckActionCooldown(CLICK_CD_MELEE))
		return
	DelayNextAction()
	if(HAS_TRAIT(src, TRAIT_PACIFISM))
		return FALSE

	in_melee = TRUE
	if(attack_sound)
		playsound(victim, attack_sound, 50, TRUE, 1)
	do_attack_animation(victim)
	visible_message(
		"<span class='danger'>\The [src] [attack_verb_continuous] [victim]!</span>",
		"<span class='userdanger'>\The [src] [attack_verb_continuous] you!</span>",
		target = victim,
		target_message = "<span class='danger'>\The [src] [attack_verb_continuous] you!</span>",
	)
	log_combat(src, victim, "attacked")
	// Regular infected and runners chip for 2 HP; bruisers always land a
	// guaranteed 3 BRUTE hit that ignores armor and stamina block.
	var/damage_amount = istype(src, /mob/living/simple_animal/hostile/infected/bruiser) ? 3 : 2
	victim.apply_damage(damage_amount, BRUTE, null, forced = TRUE)
	victim.apply_status_effect(/datum/status_effect/mesa_horde_slow)
	return TRUE

/mob/living/simple_animal/hostile/infected/death(gibbed)
	. = ..(gibbed)
	if(!ckey)
		toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/infected/Destroy()
	if(GLOB.zombie_director)
		var/datum/ai_director/zombie_mission/D = GLOB.zombie_director
		if(D && (src in D.active_zombies))
			D.active_zombies -= src
	return ..()

/mob/living/simple_animal/hostile/infected/Aggro()
	. = ..()
	if(speak && speak.len && prob(30))
		playsound(src, pick(speak), 70, TRUE)

// Shared fence movement logic for all infected types
/mob/living/simple_animal/hostile/infected/proc/handle_fence_movement(atom/newloc)
	if(newloc)
		for(var/obj/structure/fence/nocut/F in newloc)
			if(F && F.Adjacent(src))
				forceMove(newloc)
				return TRUE
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
	maxHealth = 51
	health = 51
	speed = 0
	melee_damage_lower = 8
	melee_damage_upper = 12
	sight = SEE_MOBS | SEE_TURFS
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
	maxHealth = 60
	health = 60
	speed = 2 // Slightly faster
	turns_per_move = 0 // Faster reaction
	melee_damage_lower = 15
	melee_damage_upper = 25
	sight = SEE_MOBS | SEE_TURFS // Битовая маска: видит мобов и турфы (дальность задаётся vision_range/aggro_vision_range)
	robust_searching = 1
	environment_smash = ENVIRONMENT_SMASH_NONE // Disable structure smashing to prevent attacking fences
	harm_intent_damage = 20
	obj_damage = 40
	// Disable fractures and dislocations completely
	wound_bonus = 0
	bare_wound_bonus = 0
	sharpness = SHARP_NONE // Prevent cutting wounds

/mob/living/simple_animal/hostile/infected/bruiser/Move(atom/newloc, dir, step_x, step_y)
	if(handle_fence_movement(newloc))
		return TRUE
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
	maxHealth = 70
	health = 70
	speed = 2
	turns_per_move = 0
	melee_damage_lower = 15
	melee_damage_upper = 25
	melee_damage_type = BURN
	sight = SEE_MOBS | SEE_TURFS
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

/mob/living/simple_animal/hostile/infected/acid_spitter/Move(atom/newloc, dir, step_x, step_y)
	if(handle_fence_movement(newloc))
		return TRUE
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
/datum/ai_controller/hostile_adapter/blackmesa_charger
	ai_pack_role = AI_ROLE_TANK
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/hostile_charge,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_break_away,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

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
	sight = SEE_MOBS | SEE_TURFS
	robust_searching = 1
	environment_smash = ENVIRONMENT_SMASH_NONE
	harm_intent_damage = 15
	obj_damage = 40
	wound_bonus = 0
	bare_wound_bonus = 0
	sharpness = SHARP_NONE
	// Use built-in charge system from hostile.dm
	charger = TRUE
	charge_distance = 25 // Long charge distance
	charge_frequency = 4 SECONDS // 4 seconds cooldown
	knockdown_time = 2 SECONDS // 2 seconds knockdown on hit
	minimum_distance = 3 // Allow getting closer before charging
	retreat_distance = 5
	ai_profile_type = /datum/ai_controller/hostile_adapter/blackmesa_charger
	speak = list('modular_bluemoon/sound/creatures/mesa/charger/alert_01.ogg', 'modular_bluemoon/sound/creatures/mesa/charger/alert_02.ogg')
	deathsound = 'modular_bluemoon/sound/creatures/mesa/charger/die_02.ogg'
	var/next_pain_sound_time = 0
	var/charge_damage = 40
	var/charge_stamina_damage = 60
	var/charge_hit_target = FALSE
	var/charge_recovery_time = 4 SECONDS
	var/charge_recovering = FALSE

/mob/living/simple_animal/hostile/infected/charger/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/swarming)
	wanted_objects = typecacheof(wanted_objects, TRUE)
	// Start with cooldown ready
	COOLDOWN_START(src, charge_cooldown, 0)

/mob/living/simple_animal/hostile/infected/charger/Move(atom/newloc, dir, step_x, step_y)
	if(handle_fence_movement(newloc))
		return TRUE
	if(charge_state)
		new /obj/effect/temp_visual/decoy/fading(loc, src)
		shake_camera(src, 1, 1)
	. = ..()

/mob/living/simple_animal/hostile/infected/charger/can_ai_controller_move()
	return !charge_state && !charge_windup_timer

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

	else if(hit_atom.density && !hit_atom.CanPass(src, get_turf(hit_atom)))
		visible_message("<span class='danger'>[src] crashes into [hit_atom]!</span>")
		playsound(get_turf(src), 'modular_bluemoon/sound/creatures/mesa/charger/attacksound.ogg', 100, TRUE)
		Stun(40) // 4 seconds stun on miss
	charge_end()

// Add a warning effect, then use the base charge windup and target validation.
/mob/living/simple_animal/hostile/infected/charger/enter_charge(var/atom/target)
	if(!target || QDELETED(target) || charge_recovering)
		return FALSE
	if(!target.has_gravity())
		return FALSE

	visible_message("<span class='danger'><b>[src]</b> braces for a charge!</span>")
	playsound(src, pick(list('modular_bluemoon/sound/creatures/mesa/charger/charge_01.ogg', 'modular_bluemoon/sound/creatures/mesa/charger/charge_02.ogg')), 100, TRUE)
	var/obj/effect/temp_visual/decoy/telegraph = new /obj/effect/temp_visual/decoy(loc, src)
	if(telegraph)
		animate(telegraph, alpha = 0, color = "#FF0000", transform = matrix() * 2, time = 15)
	return ..()

// Override charge_end for retreat logic after hit
/mob/living/simple_animal/hostile/infected/charger/charge_end()
	if(!charge_state)
		return
	. = ..()
	charge_hit_target = FALSE
	addtimer(CALLBACK(src, PROC_REF(start_retreat)), 1 SECONDS)

/mob/living/simple_animal/hostile/infected/charger/proc/start_retreat()
	if(!src || QDELETED(src))
		return
	charge_recovering = TRUE
	addtimer(CALLBACK(src, PROC_REF(stop_retreat)), charge_recovery_time)

/mob/living/simple_animal/hostile/infected/charger/proc/stop_retreat()
	if(!src || QDELETED(src))
		return
	charge_recovering = FALSE

/mob/living/simple_animal/hostile/infected/charger/AttackingTarget(atom/target)
	. = ..()
	// Disable normal melee attacks - charger should only use charge
	return

/mob/living/simple_animal/hostile/infected/charger/apply_damage(damage = 0, damagetype = BRUTE, def_zone = null, blocked = FALSE, forced = FALSE, spread_damage = FALSE, wound_bonus = 0, bare_wound_bonus = 0, sharpness = SHARP_NONE)
	. = ..(damage, damagetype, def_zone, blocked, forced, spread_damage, wound_bonus, bare_wound_bonus, sharpness)
	if(!. || stat == DEAD)
		return .
	if(world.time >= next_pain_sound_time && prob(20))
		next_pain_sound_time = world.time + 3 SECONDS
		playsound(src, 'modular_bluemoon/sound/creatures/mesa/charger/pain_03.ogg', 70, TRUE)
	return .

/mob/living/simple_animal/hostile/infected/charger/death(gibbed)
	. = ..(gibbed)
	charge_state = FALSE
	if(!ckey)
		toggle_ai(AI_OFF)

// =============================================================================
// TIER 4: HUNTER ZOMBIE
// Stealthy, high damage, isolates players, drags victims to darkness
// =============================================================================
/datum/ai_planning_subtree/ranged_skirmish/blackmesa_hunter
	max_range = 12

/datum/ai_controller/hostile_adapter/blackmesa_hunter
	ai_pack_role = AI_ROLE_HUNTER
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/maintain_distance,
		/datum/ai_planning_subtree/ranged_skirmish/blackmesa_hunter,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_break_away,
	)
	idle_behavior = /datum/idle_behavior/idle_random_walk/hostile_ambience

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
	speed = -1
	turns_per_move = 0 // instant reaction - hunters are fast
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
	vision_range = 40
	aggro_vision_range = 40
	pass_flags = PASSTABLE | PASSFENCE
	pass_flags_self = NONE
	sight = SEE_MOBS | SEE_TURFS
	move_on_shuttle = TRUE
	stop_automated_movement = 0
	wound_bonus = 0
	bare_wound_bonus = 0
	sharpness = SHARP_NONE
	// Hunter-specific variables
	var/is_stealthed = FALSE
	var/stealth_alpha = 60
	var/leap_damage = 35
	var/miss_stun_duration = 1.5 SECONDS
	var/last_light_check = 0
	var/light_check_interval = 20 // was 5 - locate() in range(10) scans 441 turfs
	// AI configuration - use ranged attack for leap (like headcrab)
	ranged = TRUE
	ai_profile_type = /datum/ai_controller/hostile_adapter/blackmesa_hunter
	ranged_message = "leaps"
	ranged_cooldown_time = 25 // 2.5 seconds in deciseconds
	var/jumpdistance = 12
	var/jumpspeed = 2
	var/is_leaping = FALSE
	var/leap_cooldown = 0
	var/next_vocalization = 0
	// Dodging configuration - higher dodge chance for evasive movement
	dodge_prob = 60
	// Distance keeping behavior
	retreat_distance = 5
	minimum_distance = 3

/mob/living/simple_animal/hostile/infected/hunter/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/swarming)
	wanted_objects = typecacheof(wanted_objects, TRUE)
	// Hunters spawn stealthed - the gate has no real darkness, so the stealth
	// only breaks under bright light (lamps, flashlights) or when it attacks.
	is_stealthed = TRUE
	animate(src, alpha = stealth_alpha, time = 0)

/mob/living/simple_animal/hostile/infected/hunter/Move(atom/newloc, dir, step_x, step_y)
	if(handle_fence_movement(newloc))
		return TRUE

	// Erratic movement when not in combat
	if(!target && !is_leaping && prob(15))
		// Occasionally move in a slightly random direction
		var/random_offset = pick(NORTH, SOUTH, EAST, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
		if(random_offset && random_offset != dir)
			var/turf/random_turf = get_step(src, random_offset)
			if(random_turf && !random_turf.density)
				. = ..(random_turf, random_offset, step_x, step_y)
				return

	. = ..()

/mob/living/simple_animal/hostile/infected/hunter/can_ai_controller_move()
	return !is_leaping

/mob/living/simple_animal/hostile/infected/hunter/Life()
	. = ..()
	if(speak && speak.len && prob(5) && world.time >= next_vocalization)
		playsound(get_turf(src), pick(speak), 70, FALSE)
		next_vocalization = world.time + 3 SECONDS
	handle_stealth()

/mob/living/simple_animal/hostile/infected/hunter/proc/exit_stealth()
	if(!is_stealthed)
		return
	is_stealthed = FALSE
	animate(src, alpha = 255, time = 3)

/mob/living/simple_animal/hostile/infected/hunter/proc/handle_stealth()
	// Once revealed the hunter stays visible - the gate has no dark corners
	// to fall back into, so there is nothing left to check.
	if(!is_stealthed)
		return
	if(world.time < last_light_check + light_check_interval)
		return
	last_light_check = world.time

	// Bright light sources - lit machinery and mobs carrying bright items
	// (flashlights etc.) - force the hunter out of stealth.
	for(var/obj/machinery/light/L in view(8, src))
		if(L && L.on)
			exit_stealth()
			return
	for(var/mob/living/carbon/C in view(6, src))
		if(C && C.luminosity > 3)
			exit_stealth()
			return

/mob/living/simple_animal/hostile/infected/hunter/CanAttack(atom/the_target)
	if(!the_target)
		return FALSE

	// Implement straggler targeting - prefer isolated targets
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(L)
			// Count nearby allies of the target
			var/ally_count = 0
			for(var/mob/living/M in view(7, L))
				if(M != L && M != src && faction_check_mob(L, M))
					ally_count++
			// If target has many allies nearby, avoid unless no other options
			if(ally_count >= 3 && prob(70))
				return FALSE

	return ..()

/mob/living/simple_animal/hostile/infected/hunter/AttackingTarget()
	var/atom/attack_target = target
	. = ..()
	if(!attack_target || QDELETED(attack_target))
		return
	if(isliving(attack_target))
		var/mob/living/L = attack_target
		if(L && L.client && L.stat != DEAD)
			// Apply screen shake to victim on melee hit
			shake_camera(L, 2, 2)

/mob/living/simple_animal/hostile/infected/hunter/OpenFire(atom/A)
	if(!A || QDELETED(A) || world.time < leap_cooldown || is_leaping)
		return
	if(check_friendly_fire)
		for(var/turf/T in getline(src,A))
			for(var/mob/living/L in T)
				if(L == src || L == A)
					continue
				if(faction_check_mob(L) && !attack_same)
					return

	// Only leap if target is at appropriate distance
	var/distance = get_dist(src, A)
	if(distance < 3 || distance > jumpdistance || !A.has_gravity())
		return

	exit_stealth()
	visible_message("<span class='danger'><b>[src]</b> [ranged_message] at [A]!</span>")
	playsound(get_turf(src), 'modular_bluemoon/sound/creatures/mesa/hunter/hscream.ogg', 90, FALSE)
	shake_camera(src, 2, 2)
	is_leaping = TRUE
	leap_cooldown = world.time + 5 SECONDS
	throw_at(A, jumpdistance, jumpspeed, spin = FALSE, diagonals_first = TRUE)
	ranged_cooldown = world.time + ranged_cooldown_time

/mob/living/simple_animal/hostile/infected/hunter/Bump(atom/A)
	if(!A)
		return
	if(is_leaping)
		return handle_leap_impact(A)
	return ..()

/mob/living/simple_animal/hostile/infected/hunter/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(!is_leaping)
		return ..()
	return handle_leap_impact(hit_atom)

/mob/living/simple_animal/hostile/infected/hunter/proc/handle_leap_impact(atom/hit_atom)
	if(!hit_atom)
		is_leaping = FALSE
		return
	is_leaping = FALSE
	if(isliving(hit_atom))
		var/mob/living/L = hit_atom
		if(!L || L.stat == DEAD)
			return
		L.apply_damage(leap_damage, BRUTE)
		L.Paralyze(20)
		shake_camera(L, 4, 3)
		shake_camera(src, 2, 3)
	else if(hit_atom.density && !hit_atom.CanPass(src, get_turf(hit_atom)))
		visible_message("<span class='danger'>[src] crashes into [hit_atom]!</span>")
		playsound(get_turf(src), 'modular_bluemoon/sound/creatures/mesa/hunter/punch2.ogg', 70, FALSE)
		Stun(miss_stun_duration * 10)

/mob/living/simple_animal/hostile/infected/hunter/death(gibbed)
	. = ..(gibbed)
	is_leaping = FALSE
	is_stealthed = FALSE
	animate(src, alpha = 255, time = 5)
	if(!ckey)
		toggle_ai(AI_OFF)

/mob/living/simple_animal/hostile/infected/hunter/Destroy()
	. = ..()

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
			// Add to active zombies list for tracking
			D.active_zombies += Z

// =============================================================================
// TIER 5: TANK
// Slow, durable infected that knocks targets back and pauses after each hit.
// =============================================================================
/mob/living/simple_animal/hostile/infected/tank
	name = "tank infected"
	desc = "A massive infected creature whose heavy blows send its victims flying."
	icon = 'modular_bluemoon/icons/mob/tank.dmi'
	icon_state = "tank"
	icon_living = "tank"
	icon_dead = "tankdead"
	maxHealth = 1000
	health = 1000
	speed = 1
	retreat_distance = null
	ai_profile_type = /datum/ai_controller/hostile_adapter/mesa_tank
	melee_damage_lower = 40
	melee_damage_upper = 40
	attack_verb_continuous = "smashes"
	attack_verb_simple = "smash"
	attack_sound = 'modular_bluemoon/sound/creatures/mesa/tank/tankhit.ogg'
	deathsound = 'modular_bluemoon/sound/creatures/mesa/tank/tankdead.ogg'
	speak = null
	footstep_type = FOOTSTEP_MOB_HEAVY
	var/list/tank_idle_sounds = list(
		'modular_bluemoon/sound/creatures/mesa/tank/tankidle.ogg',
		'modular_bluemoon/sound/creatures/mesa/tank/tankidle1.ogg',
	)
	var/list/tank_aggro_sounds = list(
		'modular_bluemoon/sound/creatures/mesa/tank/tankaggro.ogg',
		'modular_bluemoon/sound/creatures/mesa/tank/tankaggro2.ogg',
		'modular_bluemoon/sound/creatures/mesa/tank/tankaggro3.ogg',
		'modular_bluemoon/sound/creatures/mesa/tank/tankaggro4.ogg',
	)
	var/next_idle_sound = 0
	var/next_step_shake = 0
	var/attack_recovery_until = 0
	var/tank_theme_channel
	var/tank_idle_channel
	var/tank_theme_playing = FALSE
	var/list/tank_theme_listeners = list()
	ranged_message = "hurls a stone shard"
	ranged_cooldown_time = 5 SECONDS
	ranged_telegraph_duration = 2 SECONDS
	projectiletype = /obj/item/projectile/mesa_tank_rock
	projectilesound = 'sound/effects/meteorimpact.ogg'

/mob/living/simple_animal/hostile/infected/tank/Initialize(mapload)
	. = ..()
	tank_theme_channel = SSsounds.reserve_sound_channel(src)
	tank_idle_channel = SSsounds.reserve_sound_channel(src)

/mob/living/simple_animal/hostile/infected/tank/BiologicalLife(seconds, times_fired)
	if(!(. = ..()))
		return
	// Periodic theme maintenance: picks up players who entered the area after
	// aggro and covers target acquisition paths that skip Aggro().
	update_theme_listeners()
	if(target || stat == DEAD || world.time < next_idle_sound)
		return
	playsound(src, sound(pick(tank_idle_sounds), channel = tank_idle_channel), 65, TRUE, channel = tank_idle_channel)
	next_idle_sound = world.time + rand(80, 160)

/mob/living/simple_animal/hostile/infected/tank/Move(atom/newloc, dir, step_x, step_y)
	if(world.time < attack_recovery_until)
		return FALSE
	. = ..()
	if(. && world.time >= next_step_shake)
		next_step_shake = world.time + 10
		for(var/mob/living/nearby_mob in viewers(6, src))
			if(nearby_mob.client && istype(get_area(nearby_mob), /area/awaymission/ihategordon))
				shake_camera(nearby_mob, 1, 1)

/mob/living/simple_animal/hostile/infected/tank/can_ai_controller_move()
	return !ranged_telegraph_timer_id

/mob/living/simple_animal/hostile/infected/tank/AttackingTarget()
	if(world.time < attack_recovery_until)
		return FALSE
	if(!isliving(target))
		return ..()
	if(QDELETED(src) || QDELETED(target))
		return
	var/mob/living/victim = target
	if(SEND_SIGNAL(src, COMSIG_HOSTILE_ATTACKINGTARGET, victim) & COMPONENT_HOSTILE_NO_ATTACK)
		return
	if(QDELETED(src) || QDELETED(victim))
		return

	face_atom(victim)
	if(!CheckActionCooldown(CLICK_CD_MELEE))
		return
	DelayNextAction()
	if(HAS_TRAIT(src, TRAIT_PACIFISM))
		return FALSE

	in_melee = TRUE
	playsound(src, pick(tank_aggro_sounds), 80, TRUE)
	playsound(victim, attack_sound, 50, TRUE, 1)
	do_attack_animation(victim)
	visible_message(
		"<span class='danger'>\The [src] [attack_verb_continuous] [victim]!</span>",
		"<span class='userdanger'>\The [src] [attack_verb_continuous] you!</span>",
		target = victim,
		target_message = "<span class='danger'>\The [src] [attack_verb_continuous] you!</span>",
	)
	log_combat(src, victim, "attacked")
	victim.apply_damage(40, BRUTE, null, forced = TRUE)
	victim.Stun(2 SECONDS)
	var/throwtarget = get_edge_target_turf(src, get_dir(src, get_step_away(victim, src)))
	victim.throw_at(throwtarget, 3, 1, src)
	attack_recovery_until = world.time + (2 SECONDS)
	return TRUE

/mob/living/simple_animal/hostile/infected/tank/telegraphed_open_fire(atom/fire_target)
	if(QDELETED(fire_target) || stat == DEAD || ranged_telegraph_timer_id)
		return FALSE
	ranged_cooldown = world.time + ranged_cooldown_time + ranged_telegraph_duration
	if(isliving(fire_target))
		var/mob/living/victim = fire_target
		if(victim.client)
			to_chat(victim, span_userdanger("В вас целится [src] камнем!"))
	ranged_telegraph_timer_id = addtimer(CALLBACK(src, PROC_REF(finish_telegraphed_open_fire), fire_target), ranged_telegraph_duration, TIMER_STOPPABLE)
	playsound(src, pick(tank_aggro_sounds), 80, TRUE)
	return TRUE

/mob/living/simple_animal/hostile/infected/tank/Aggro()
	. = ..()
	playsound(src, pick(tank_aggro_sounds), 80, TRUE)
	update_theme_listeners()

/mob/living/simple_animal/hostile/infected/tank/proc/update_theme_listeners()
	if(stat == DEAD || QDELETED(src))
		return
	// The theme only makes sense while the tank has a living target - this also
	// covers aggro paths that bypass Aggro() (direct target assignment).
	if(!isliving(target))
		return
	if(!tank_theme_playing)
		tank_theme_playing = TRUE
	// Area-based like the helicopter theme: every player inside the gate hears
	// it, not just viewers() within 10 tiles at the moment of aggro.
	for(var/mob/living/player in GLOB.player_list)
		if(!player || QDELETED(player) || !player.client)
			continue
		if(player in tank_theme_listeners)
			continue
		if(!(player.client.prefs && (player.client.prefs.toggles & SOUND_AMBIENCE)))
			continue
		if(!istype(get_area(player), /area/awaymission/ihategordon))
			continue
		SEND_SOUND(player, sound('modular_bluemoon/sound/creatures/mesa/tank/tanktheme.ogg', repeat = TRUE, volume = 50, channel = tank_theme_channel))
		register_theme_listener(player)

/mob/living/simple_animal/hostile/infected/tank/proc/register_theme_listener(mob/listener)
	if(!listener || !istype(listener))
		return
	// Registration must be idempotent: tank_theme_listeners can lose track of a
	// listener while its signals stay registered (unregister_theme_listener
	// removes the list entry even when UnregisterSignal no-ops on a dropped
	// comp_lookup). Re-registering then hits "parent_qdeleting overridden"
	// warnings and leaks the stale callback, so clear it first.
	unregister_theme_listener(listener)
	tank_theme_listeners += listener
	RegisterSignal(listener, COMSIG_LIVING_DEATH, PROC_REF(on_theme_listener_death), override = TRUE)
	RegisterSignal(listener, COMSIG_MOB_GHOSTIZE, PROC_REF(on_theme_listener_ghostize), override = TRUE)
	RegisterSignal(listener, COMSIG_PARENT_QDELETING, PROC_REF(on_theme_listener_qdeleting), override = TRUE)
	if(listener.mind)
		RegisterSignal(listener.mind, COMSIG_MIND_TRANSFER, PROC_REF(on_theme_listener_mind_transfer), override = TRUE)

/mob/living/simple_animal/hostile/infected/tank/proc/unregister_theme_listener(mob/listener, datum/mind/mind)
	if(!listener)
		return
	var/datum/mind/listener_mind = mind
	if(!listener_mind && !QDELETED(listener))
		listener_mind = listener.mind
	UnregisterSignal(listener, list(COMSIG_LIVING_DEATH, COMSIG_MOB_GHOSTIZE, COMSIG_PARENT_QDELETING))
	if(listener_mind && !QDELETED(listener_mind))
		UnregisterSignal(listener_mind, COMSIG_MIND_TRANSFER)
	tank_theme_listeners -= listener

/mob/living/simple_animal/hostile/infected/tank/proc/stop_theme_listener_sound(mob/listener)
	if(!listener || QDELETED(listener) || !tank_theme_channel)
		return
	listener.stop_sound_channel(tank_theme_channel)

/mob/living/simple_animal/hostile/infected/tank/proc/on_theme_listener_death(mob/living/source, gibbed)
	SIGNAL_HANDLER
	stop_theme_listener_sound(source)
	unregister_theme_listener(source)

/mob/living/simple_animal/hostile/infected/tank/proc/on_theme_listener_ghostize(mob/source, can_reenter_corpse = FALSE, special = FALSE, penalize = FALSE, voluntary = FALSE)
	SIGNAL_HANDLER
	stop_theme_listener_sound(source)
	unregister_theme_listener(source)

/mob/living/simple_animal/hostile/infected/tank/proc/on_theme_listener_qdeleting(mob/source)
	SIGNAL_HANDLER
	unregister_theme_listener(source, source.mind)

/mob/living/simple_animal/hostile/infected/tank/proc/on_theme_listener_mind_transfer(datum/mind/source, mob/new_character, mob/old_character)
	SIGNAL_HANDLER
	if(!old_character || !(old_character in tank_theme_listeners))
		UnregisterSignal(source, COMSIG_MIND_TRANSFER)
		return
	stop_theme_listener_sound(new_character)
	stop_theme_listener_sound(old_character)
	unregister_theme_listener(old_character, source)

/mob/living/simple_animal/hostile/infected/tank/proc/stop_tank_sounds()
	tank_theme_playing = FALSE
	for(var/mob/listener in tank_theme_listeners.Copy())
		stop_theme_listener_sound(listener)
		unregister_theme_listener(listener)
	for(var/mob/listener in GLOB.player_list)
		if(QDELETED(listener))
			continue
		listener.stop_sound_channel(tank_theme_channel)
		listener.stop_sound_channel(tank_idle_channel)
	tank_theme_listeners.Cut()

/mob/living/simple_animal/hostile/infected/tank/death(gibbed)
	stop_tank_sounds()
	return ..(gibbed)

/mob/living/simple_animal/hostile/infected/tank/Destroy()
	stop_tank_sounds()
	SSsounds.free_datum_channels(src)
	return ..()
