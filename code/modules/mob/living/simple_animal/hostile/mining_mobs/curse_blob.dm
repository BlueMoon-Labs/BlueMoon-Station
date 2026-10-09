/mob/living/simple_animal/hostile/asteroid/curseblob
	name = "curse mass"
	desc = "A mass of purple... smoke?"
	icon = 'icons/mob/lavaland/lavaland_monsters.dmi'
	icon_state = "curseblob"
	icon_living = "curseblob"
	icon_aggro = "curseblob"
	mob_biotypes = MOB_SPIRIT
	movement_type = FLYING
	move_to_delay = 5
	vision_range = 20
	aggro_vision_range = 20
	maxHealth = 40 //easy to kill, but oh, will you be seeing a lot of them.
	health = 40
	del_on_death = TRUE
	melee_damage_lower = 10
	melee_damage_upper = 10
	melee_damage_type = BURN
	attack_verb_continuous = "slashes"
	attack_verb_simple = "slash"
	attack_sound = 'sound/effects/curseattack.ogg'
	throw_message = "passes through the smokey body of"
	obj_damage = 0
	environment_smash = ENVIRONMENT_SMASH_NONE
	sentience_type = SENTIENCE_BOSS
	layer = LARGE_MOB_LAYER
	blood_volume = 0
	var/mob/living/set_target
	var/timerid
	var/move_timer
	var/move_step_running = FALSE

/mob/living/simple_animal/hostile/asteroid/curseblob/Initialize(mapload)
	. = ..()
	timerid = QDEL_IN_STOPPABLE(src, 1 MINUTES)
	playsound(src, 'sound/effects/curse1.ogg', 100, 1, -1)

/mob/living/simple_animal/hostile/asteroid/curseblob/Destroy()
	new /obj/effect/temp_visual/dir_setting/curse/blob(loc, dir)
	deltimer(timerid)
	timerid = null
	deltimer(move_timer)
	move_timer = null
	set_target = null
	return ..()

/mob/living/simple_animal/hostile/asteroid/curseblob/proc/move_loop()
	if(move_timer || move_step_running)
		return
	pursue_target()

/mob/living/simple_animal/hostile/asteroid/curseblob/proc/pursue_target()
	move_timer = null
	if(QDELETED(src) || check_for_target() || !isturf(loc))
		return
	move_step_running = TRUE
	if(!incapacitated())
		var/step_turf = get_step(src, get_dir(src, set_target))
		if(step_turf && step_turf != get_turf(set_target))
			forceMove(step_turf)
	move_step_running = FALSE
	if(!QDELETED(src))
		move_timer = addtimer(CALLBACK(src, PROC_REF(pursue_target)), max(world.tick_lag, move_to_delay + movement_delay()), TIMER_STOPPABLE)

/mob/living/simple_animal/hostile/asteroid/curseblob/proc/check_for_target()
	if(QDELETED(set_target) || set_target.stat != CONSCIOUS || z != set_target.z)
		if(!QDELETED(src))
			qdel(src)
		return TRUE

/mob/living/simple_animal/hostile/asteroid/curseblob/GiveTarget(new_target)
	if(check_for_target())
		return
	new_target = set_target
	. = ..()
	if(!move_timer)
		move_loop()

/mob/living/simple_animal/hostile/asteroid/curseblob/LoseTarget() //we can't lose our target!
	if(check_for_target())
		return

/mob/living/simple_animal/hostile/asteroid/curseblob/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(mover == set_target)
		return FALSE
	if(istype(mover, /obj/item/projectile))
		return FALSE
