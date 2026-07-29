// A mob which only moves when it isn't being watched by living beings.

/mob/living/simple_animal/hostile/statue
	name = "statue" // matches the name of the statue with the flesh-to-stone spell
	desc = "An incredibly lifelike marble carving. Its eyes seem to follow you.." // same as an ordinary statue with the added "eye following you" description
	icon = 'icons/obj/statue.dmi'
	icon_state = "human_male"
	icon_living = "human_male"
	icon_dead = "human_male"
	gender = NEUTER
	a_intent = INTENT_HARM
	mob_biotypes = MOB_HUMANOID
	response_help_continuous = "touches"
	response_help_simple = "touch"
	response_disarm_continuous = "pushes"
	response_disarm_simple = "push"
	speed = -1
	maxHealth = 50000
	health = 50000
	healable = 0
	blood_volume = 0

	harm_intent_damage = 10
	obj_damage = 100
	melee_damage_lower = 68
	melee_damage_upper = 83
	attack_verb_continuous = "claws"
	attack_verb_simple = "claw"
	attack_sound = 'sound/hallucinations/growl1.ogg'

	atmos_requirements = list("min_oxy" = 0, "max_oxy" = 0, "min_tox" = 0, "max_tox" = 0, "min_co2" = 0, "max_co2" = 0, "min_n2" = 0, "max_n2" = 0)
	minbodytemp = 0

	faction = list("statue")
	move_to_delay = 0 // Very fast

	animate_movement = NO_STEPS // Do not animate movement, you jump around as you're a scary statue.
	hud_possible = list(ANTAG_HUD)

	see_in_dark = 13
	lighting_alpha = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
	vision_range = 12
	aggro_vision_range = 12

	search_objects = 1 // So that it can see through walls

	sight = SEE_SELF|SEE_MOBS|SEE_OBJS|SEE_TURFS

	move_force = MOVE_FORCE_EXTREMELY_STRONG
	move_resist = MOVE_FORCE_EXTREMELY_STRONG
	pull_force = MOVE_FORCE_EXTREMELY_STRONG

	var/cannot_be_seen = 1
	var/mob/living/creator = null

	///Скорость атак 1:1 - фишка ангела: ровно легаси-каденс NPC-пула,
	///без компромиссного ускорения адаптера
	ai_melee_cadence_scale = 1
	///Молниеносный рывок в слепой момент - designed-фишка ужаса, а не фауна из
	///жалоб на скорость: ангел отписан от пола скорости AI-погони, как боссы
	ai_pursuit_speed_capped = FALSE



// No movement while seen code.

/mob/living/simple_animal/hostile/statue/Initialize(mapload, var/mob/living/creator)
	. = ..()
	// Give spells
	mob_spell_list += new /obj/effect/proc_holder/spell/aoe_turf/flicker_lights(src)
	mob_spell_list += new /obj/effect/proc_holder/spell/aoe_turf/blindness(src)
	mob_spell_list += new /obj/effect/proc_holder/spell/targeted/night_vision(src)

	// Set creator
	if(creator)
		src.creator = creator

/mob/living/simple_animal/hostile/statue/med_hud_set_health()
	return //we're a statue we're invincible

/mob/living/simple_animal/hostile/statue/med_hud_set_status()
	return //we're a statue we're invincible

/mob/living/simple_animal/hostile/statue/Move(turf/NewLoc)
	if(can_be_seen(NewLoc))
		if(client)
			to_chat(src, "<span class='warning'>You cannot move, there are eyes on you!</span>")
		return FALSE
	return ..()

/mob/living/simple_animal/hostile/statue/BiologicalLife(delta_time, times_fired)
	if(!(. = ..()))
		return
	if(!client && target) // If we have a target and we're AI controlled
		var/mob/watching = can_be_seen()
		// If they're not our target
		if(watching && watching != target)
			// This one is closer.
			if(get_dist(watching, src) > get_dist(target, src))
				LoseTarget()
				GiveTarget(watching)

/mob/living/simple_animal/hostile/statue/AttackingTarget()
	if(can_be_seen(get_turf(loc)))
		if(client)
			to_chat(src, "<span class='warning'>You cannot attack, there are eyes on you!</span>")
		return FALSE
	else
		return ..()

/mob/living/simple_animal/hostile/statue/DestroyPathToTarget()
	if(!can_be_seen(get_turf(loc)))
		..()

/mob/living/simple_animal/hostile/statue/face_atom()
	if(!can_be_seen(get_turf(loc)))
		..()

/mob/living/simple_animal/hostile/statue/proc/can_be_seen(turf/destination)
	if(!cannot_be_seen)
		return null
	// Check for darkness
	var/turf/T = get_turf(loc)
	if(T && destination && T.lighting_object)
		if(T.get_lumcount()<0.1 && destination.get_lumcount()<0.1) // No one can see us in the darkness, right?
			return null
		if(T == destination)
			destination = null

	// We aren't in darkness, loop for viewers.
	var/list/check_list = list(src)
	if(destination)
		check_list += destination

	// This loop will, at most, loop twice.
	for(var/atom/check in check_list)
		for(var/mob/living/M in fov_viewers(world.view + 1, check) - src)
			if(M.client && CanAttack(M) && !M.silicon_privileges)
				if(!M.eye_blind)
					return M
	return null

// Cannot talk

/mob/living/simple_animal/hostile/statue/say(message, bubble_type, var/list/spans = list(), sanitize = TRUE, datum/language/language = null, ignore_spam = FALSE, forced = null)
	return FALSE

// Turn to dust when gibbed

/mob/living/simple_animal/hostile/statue/gib()
	dust()


// Stop attacking clientless mobs

/mob/living/simple_animal/hostile/statue/CanAttack(atom/the_target)
	if(isliving(the_target))
		var/mob/living/L = the_target
		if(!L.client && !L.ckey)
			return FALSE
	return ..()

// Don't attack your creator if there is one: стратегия hostile_legacy/statue

// Statue powers

// Flicker lights
/obj/effect/proc_holder/spell/aoe_turf/flicker_lights
	name = "Flicker Lights"
	desc = "You will trigger a large amount of lights around you to flicker."

	charge_max = 300
	clothes_req = NONE
	range = 14

/obj/effect/proc_holder/spell/aoe_turf/flicker_lights/cast(list/targets,mob/user = usr)
	for(var/turf/T in targets)
		for(var/obj/machinery/light/L in T)
			L.flicker()
	return

//Blind AOE
/obj/effect/proc_holder/spell/aoe_turf/blindness
	name = "Blindness"
	desc = "Your prey will be momentarily blind for you to advance on them."

	message = "<span class='notice'>You glare your eyes.</span>"
	charge_max = 600
	clothes_req = NONE
	range = 10

/obj/effect/proc_holder/spell/aoe_turf/blindness/cast(list/targets,mob/user = usr)
	for(var/mob/living/L in GLOB.alive_mob_list)
		var/turf/T = get_turf(L.loc)
		if(T && (T in targets))
			L.blind_eyes(4)
	return

//Toggle Night Vision
/obj/effect/proc_holder/spell/targeted/night_vision
	name = "Toggle Nightvision \[ON\]"
	desc = "Toggle your nightvision mode."

	charge_max = 10
	clothes_req = NONE

	message = "<span class='notice'>You toggle your night vision!</span>"
	range = -1
	include_user = 1

/obj/effect/proc_holder/spell/targeted/night_vision/cast(list/targets, mob/user = usr)
    for(var/mob/living/target in targets)
        toggle_nightvision(target)

/obj/effect/proc_holder/spell/targeted/night_vision/proc/toggle_nightvision(mob/living/target)
	var/original_darksight = initial(target.see_in_dark)
	var/turfs_value = target.lighting_alpha
	var/cutoff_value = target.lighting_cutoff
	var/list/color_cutoffs_value = target.lighting_color_cutoffs
	var/darksight
	switch(turfs_value)
		if(LIGHTING_PLANE_ALPHA_VISIBLE)
			turfs_value = LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE
			cutoff_value = LIGHTING_CUTOFF_MEDIUM
			color_cutoffs_value = list(15, 15, 15)
			darksight = min(original_darksight, NIGHT_VISION_DARKSIGHT_RANGE)
			name = "Toggle Nightvision \[More]"
		if(LIGHTING_PLANE_ALPHA_MOSTLY_VISIBLE)
			turfs_value = LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE
			cutoff_value = LIGHTING_CUTOFF_HIGH
			color_cutoffs_value = list(25, 25, 25)
			darksight = max(original_darksight, NIGHT_VISION_DARKSIGHT_RANGE)
			name = "Toggle Nightvision \[Full]"
		if(LIGHTING_PLANE_ALPHA_MOSTLY_INVISIBLE)
			turfs_value = LIGHTING_PLANE_ALPHA_INVISIBLE
			cutoff_value = LIGHTING_CUTOFF_FULLBRIGHT
			color_cutoffs_value = list(40, 40, 40)
			darksight = original_darksight
			name = "Toggle Nightvision \[OFF]"
		else
			turfs_value = LIGHTING_PLANE_ALPHA_VISIBLE
			cutoff_value = LIGHTING_CUTOFF_VISIBLE
			color_cutoffs_value = null
			darksight = max(original_darksight, NIGHT_VISION_DARKSIGHT_RANGE)
			name = "Toggle Nightvision \[ON]"
	target.lighting_alpha = turfs_value
	target.lighting_cutoff = cutoff_value
	target.lighting_color_cutoffs = color_cutoffs_value
	target.see_in_dark = darksight
	target.update_sight(forced = FALSE)

/mob/living/simple_animal/hostile/statue/sentience_act()
	faction -= "neutral"

/mob/living/simple_animal/hostile/statue/restrained(ignore_grab)
	. = ..()
	if(can_be_seen(loc))
		return TRUE

// ===== Адаптер-профиль =====
// Плачущий ангел: восприятие и цели - штатной машиной (рентген-стратегия
// hostile_legacy/statue воспроизводит легаси search_objects=1 + SEE_MOBS
// "видит сквозь стены"), а фишка "замри, пока смотрят" остаётся в легаси-гейтах
// can_be_seen(): Move()/AttackingTarget()/face_atom() работают через делегацию,
// сабтри statue_freeze_when_watched обрывает боевой план под взглядом, а
// can_ai_controller_move() глушит мувер контроллера без черна failed-moves/JPS.
// Ретаргет на более близкого наблюдателя остаётся в легаси BiologicalLife:
// его GiveTarget/LoseTarget зеркалируются в блэкборд штатным мостом.

///Хук мувера: под взглядом контроллер даже не пытается шагать; точный гейт
///по турфу назначения остаётся в легаси Move()
/mob/living/simple_animal/hostile/statue/can_ai_controller_move()
	return !can_be_seen(get_turf(loc))

///Профиль ангела: обычная милишная погоня, замирающая под взглядами
/datum/ai_controller/hostile_adapter/melee_chaser/statue
	planning_subtrees = list(
		/datum/ai_planning_subtree/find_hostile_targets,
		/datum/ai_planning_subtree/statue_freeze_when_watched,
		/datum/ai_planning_subtree/hostile_fsm,
		/datum/ai_planning_subtree/attack_obstacle_in_path,
		/datum/ai_planning_subtree/hostile_melee,
	)

/datum/ai_controller/hostile_adapter/melee_chaser/statue/TryPossessPawn(atom/new_pawn)
	. = ..()
	if(.)
		return
	//рентген-приобретение: легаси-статуя брала цели сквозь стены
	blackboard[BB_AI_TARGETING_STRATEGY] = /datum/targeting_strategy/hostile_legacy/statue

///Под взглядом статуя не делает НИЧЕГО: ни милишки, ни сноса препятствий,
///ни FSM-переходов. Восприятие (find_hostile_targets выше) остаётся живым -
///как легаси FindTarget, который работал и под взглядом.
/datum/ai_planning_subtree/statue_freeze_when_watched

/datum/ai_planning_subtree/statue_freeze_when_watched/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/simple_animal/hostile/statue/angel = controller.pawn
	if(!istype(angel))
		return
	if(angel.can_be_seen(get_turf(angel)))
		return SUBTREE_RETURN_FINISH_PLANNING
