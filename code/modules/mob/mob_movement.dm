//DO NOT USE THIS UNLESS YOU ABSOLUTELY HAVE TO. THIS IS BEING PHASED OUT FOR THE MOVESPEED MODIFICATION SYSTEM.
//See mob_movespeed.dm
/mob/proc/movement_delay()	//update /living/movement_delay() if you change this
	return cached_multiplicative_slowdown

/client/verb/drop_item()
	set hidden = 1
	if(!iscyborg(mob) && mob.stat == CONSCIOUS)
		mob.dropItemToGround(mob.get_active_held_item())
	return

/client/proc/Move_object(direction)
	if(mob && mob.control_object)
		if(mob.control_object.density)
			step(mob.control_object,direction)
			if(!mob.control_object)
				return
			mob.control_object.setDir(direction)
		else
			mob.control_object.forceMove(get_step(mob.control_object,direction))

#define MOVEMENT_DELAY_BUFFER 0.75
#define MOVEMENT_DELAY_BUFFER_DELTA 1.25

/client/Move(n, direction)
	if(world.time < move_delay) //do not move anything ahead of this check please
		return FALSE
	else
		next_move_dir_add = next_move_dir_sub = NONE
	var/old_move_delay = move_delay
	move_delay = world.time + world.tick_lag //this is here because Move() can now be called mutiple times per tick
	if(!n || !direction || !mob?.loc)
		return FALSE
	//GET RID OF THIS SOON AS MOBILITY FLAGS IS DONE
	if(mob.mob_transforming)
		return FALSE

	if(mob.control_object)
		return Move_object(direction)
	if(!isliving(mob))
		return mob.Move(n, direction)
	if(mob.stat == DEAD)
		mob.ghostize()
		return FALSE
	if(mob.force_moving)
		return FALSE

	// Sandstorm Edit
	if(mob.shifting || mob.tilting)
		mob.pixel_shift(direction)
		return FALSE
	else if(mob.is_shifted)
		mob.unpixel_shift()
	//

	var/mob/living/L = mob  //Already checked for isliving earlier
	if(L.incorporeal_move)	//Move though walls
		Process_Incorpmove(direction)
		return FALSE

	if(mob.remote_control)					//we're controlling something, our movement is relayed to it
		return mob.remote_control.relaymove(mob, direction)

	if(isAI(mob))
		return AIMove(n,direction,mob)

	if(Process_Grab()) //are we restrained by someone's grip?
		return

	if(mob.buckled)							//if we're buckled to something, tell it we moved.
		return mob.buckled.relaymove(mob, direction)

	if(!CHECK_MOBILITY(L, MOBILITY_MOVE))
		return FALSE

	if(isobj(mob.loc) || ismob(mob.loc))	//Inside an object, tell it we moved
		var/atom/O = mob.loc
		return O.relaymove(mob, direction)

	if(!mob.Process_Spacemove(direction))
		return FALSE
	//We are now going to move
	var/add_delay = mob.movement_delay()
	mob.set_glide_size(DELAY_TO_GLIDE_SIZE(add_delay * ( (NSCOMPONENT(direction) && EWCOMPONENT(direction)) ? 2 : 1 ) ), FALSE) // set it now in case of pulled objects
	if(old_move_delay + (add_delay*MOVEMENT_DELAY_BUFFER_DELTA) + MOVEMENT_DELAY_BUFFER > world.time)
		move_delay = old_move_delay
	else
		move_delay = world.time
	var/oldloc = mob.loc

	var/confusion_level = L.get_confusion_movement_level()
	if(confusion_level)
		var/newdir = NONE
		if((confusion_level > 50) && prob(min(confusion_level * 0.5, 50)))
			newdir = pick(GLOB.alldirs)
		else if(prob(confusion_level))
			newdir = angle2dir(dir2angle(direction) + pick(90, -90))
		else if(prob(confusion_level * 2))
			newdir = angle2dir(dir2angle(direction) + pick(45, -45))
		if(newdir)
			direction = newdir
			n = get_step(L, direction)

	. = ..()

	if((direction & (direction - 1)) && mob.loc == n) //moved diagonally successfully
		add_delay *= SQRT_2
	mob.set_glide_size(DELAY_TO_GLIDE_SIZE(add_delay), FALSE)
	move_delay += add_delay
	if(.) // If mob is null here, we deserve the runtime
		if(mob.throwing)
			mob.throwing.finalize(FALSE)

	var/atom/movable/AM = L.pulling
	if(AM && AM.density && !SEND_SIGNAL(L, COMSIG_COMBAT_MODE_CHECK, COMBAT_MODE_ACTIVE) && !ismob(AM))
		L.setDir(turn(L.dir, 180))

	last_move = world.time

	SEND_SIGNAL(mob, COMSIG_MOB_CLIENT_MOVE, src, direction, n, oldloc, add_delay)


/// Process_Grab(): checks for grab, attempts to break if so. Return TRUE to prevent movement.
/client/proc/Process_Grab()
	if(mob.pulledby)
		if((mob.pulledby == mob.pulling) && (mob.pulledby.grab_state == GRAB_PASSIVE))			//Don't autoresist passive grabs if we're grabbing them too.
			return
		if(mob.incapacitated(ignore_restraints = 1))
			move_delay = world.time + 10
			return TRUE
		else if(mob.restrained(ignore_grab = 1))
			move_delay = world.time + 10
			to_chat(src, "<span class='warning'>You're restrained! You can't move!</span>")
			return TRUE
		else
			return !mob.attempt_resist_grab(TRUE)

///Process_Incorpmove
///Called by client/Move()
///Allows mobs to run though walls
/client/proc/Process_Incorpmove(direction)
	var/turf/mobloc = get_turf(mob)
	if(!isliving(mob))
		return
	var/mob/living/L = mob
	switch(L.incorporeal_move)
		if(INCORPOREAL_MOVE_BASIC)
			var/T = get_step(L,direction)
			if(T)
				L.forceMove(T)
			L.setDir(direction)
		if(INCORPOREAL_MOVE_SHADOW)
			if(prob(50))
				var/locx
				var/locy
				switch(direction)
					if(NORTH)
						locx = mobloc.x
						locy = (mobloc.y+2)
						if(locy>world.maxy)
							return
					if(SOUTH)
						locx = mobloc.x
						locy = (mobloc.y-2)
						if(locy<1)
							return
					if(EAST)
						locy = mobloc.y
						locx = (mobloc.x+2)
						if(locx>world.maxx)
							return
					if(WEST)
						locy = mobloc.y
						locx = (mobloc.x-2)
						if(locx<1)
							return
					else
						return
				var/target = locate(locx,locy,mobloc.z)
				if(target)
					L.forceMove(target)
					var/limit = 2//For only two trailing shadows.
					for(var/turf/T in getline(mobloc, L.loc))
						new /obj/effect/temp_visual/dir_setting/ninja/shadow(T, L.dir)
						limit--
						if(limit<=0)
							break
			else
				new /obj/effect/temp_visual/dir_setting/ninja/shadow(mobloc, L.dir)
				var/T = get_step(L,direction)
				if(T)
					L.forceMove(T)
			L.setDir(direction)
		if(INCORPOREAL_MOVE_JAUNT) //Incorporeal move, but blocked by holy-watered tiles and salt piles.
			var/turf/open/floor/stepTurf = get_step(L, direction)
			if(stepTurf)
				for(var/obj/effect/decal/cleanable/salt/S in stepTurf)
					to_chat(L, "<span class='warning'>[S] bars your passage!</span>")
					if(isrevenant(L) || isqareen(L))
						var/mob/living/simple_animal/revenant/R = L
						R.reveal(20)
						R.stun(20)
					return
				if(stepTurf.flags_1 & NOJAUNT_1)
					to_chat(L, "<span class='warning'>Some strange aura is blocking the way.</span>")
					return
				if (locate(/obj/effect/blessing, stepTurf))
					to_chat(L, "<span class='warning'>Holy energies block your path!</span>")
					return

				L.forceMove(stepTurf)
			L.setDir(direction)
	return TRUE


///Process_Spacemove
///Called by /client/Move()
///For moving in space.
/// return TRUE to allow voluntary movement / bracing; FALSE when nothing to push off and you should keep drifting
/mob/Process_Spacemove(movement_dir = 0, continuous_move = FALSE)
	. = ..(movement_dir, continuous_move)
	if(. || HAS_TRAIT(src, TRAIT_SPACEWALK) || spacewalk)
		return TRUE
	if(buckled)
		return TRUE
	if((movement_type & FLYING) || HAS_TRAIT(src, TRAIT_FREE_FLOAT_MOVEMENT))
		return TRUE
	var/atom/movable/backup = get_spacemove_backup(movement_dir, continuous_move)
	if(!backup)
		return FALSE
	if(drift_handler?.attempt_halt(movement_dir, continuous_move, backup))
		return FALSE
	if(continuous_move || !ismovable(backup) || !movement_dir || backup.anchored)
		return TRUE
	last_pushoff = world.time
	if(backup.newtonian_move(REVERSE_DIR(movement_dir), instant = TRUE))
		backup.last_pushoff = world.time
		to_chat(src, "<span class='info'>You push off of [backup] to propel yourself.</span>")
	return TRUE

/// Finds mass to push off within range 1 (floor, wall, anchored or dense movables)
/mob/get_spacemove_backup(moving_direction, continuous_move, include_floors = FALSE)
	var/atom/secondary_backup
	var/list/priority_dirs = (moving_direction in GLOB.cardinals) ? GLOB.cardinals : GLOB.diagonals
	for(var/atom/pushover as anything in range(1, get_turf(src)))
		if(pushover == src)
			continue
		if(isarea(pushover))
			continue
		var/is_priority = pushover.loc == loc || (get_dir(src, pushover) in priority_dirs)
		if(isturf(pushover))
			var/turf/turf = pushover
			if(isspaceturf(turf))
				continue
			if(!turf.density && !mob_negates_gravity())
				if(!include_floors || !has_gravity(turf))
					continue
			if(is_priority)
				return pushover
			secondary_backup = pushover
			continue
		var/atom/movable/rebound = pushover
		if(rebound == buckled)
			continue
		if(ismob(rebound))
			var/mob/lover = rebound
			if(lover.buckled)
				continue
		var/pass_allowed = rebound.CanPass(src, get_turf(src))
		if(!rebound.density && pass_allowed && !istype(rebound, /obj/structure/lattice))
			continue
		if(rebound.last_pushoff == world.time)
			continue
		if(continuous_move && !pass_allowed)
			var/datum/move_loop/smooth_move/rebound_engine = SSmove_manager.processing_on(rebound, SSnewtonian_movement)
			if(moving_direction == get_dir(src, pushover) && rebound_engine && moving_direction == angle2dir(rebound_engine.angle))
				continue
		else if(!pass_allowed)
			if(moving_direction == get_dir(src, pushover))
				continue
		if(rebound.anchored)
			if(is_priority)
				return rebound
			secondary_backup = rebound
			continue
		if(pulling == rebound)
			continue
		if(is_priority)
			return rebound
		secondary_backup = rebound
	return secondary_backup

/mob/proc/mob_has_gravity()
	return has_gravity()

/mob/proc/mob_negates_gravity()
	return FALSE


/mob/proc/slip(s_amount, w_amount, obj/O, lube)
	return

/mob/proc/update_gravity(has_gravity, override=FALSE)
	var/speed_change = max(0, has_gravity - STANDARD_GRAVITY)
	if(!speed_change)
		remove_movespeed_modifier(/datum/movespeed_modifier/gravity)
	else
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/gravity, multiplicative_slowdown = speed_change)

//bodypart selection - Cyberboss
//8 toggles through head - eyes - mouth
//4: r-arm 5: chest 6: l-arm
//1: r-leg 2: groin 3: l-leg

/client/proc/check_has_body_select()
	return mob && mob.hud_used && mob.hud_used.zone_select && istype(mob.hud_used.zone_select, /atom/movable/screen/zone_sel)

/client/verb/body_toggle_head()
	set name = "body-toggle-head"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/next_in_line
	switch(mob.zone_selected)
		if(BODY_ZONE_HEAD)
			next_in_line = BODY_ZONE_PRECISE_EYES
		if(BODY_ZONE_PRECISE_EYES)
			next_in_line = BODY_ZONE_PRECISE_MOUTH
		else
			next_in_line = BODY_ZONE_HEAD

	var/atom/movable/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone(next_in_line, mob)

/client/verb/body_r_arm()
	set name = "body-r-arm"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/atom/movable/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone(BODY_ZONE_R_ARM, mob)

/client/verb/body_chest()
	set name = "body-chest"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/atom/movable/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone(BODY_ZONE_CHEST, mob)

/client/verb/body_l_arm()
	set name = "body-l-arm"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/atom/movable/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone(BODY_ZONE_L_ARM, mob)

/client/verb/body_r_leg()
	set name = "body-r-leg"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/atom/movable/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone(BODY_ZONE_R_LEG, mob)

/client/verb/body_groin()
	set name = "body-groin"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/atom/movable/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone(BODY_ZONE_PRECISE_GROIN, mob)

/client/verb/body_l_leg()
	set name = "body-l-leg"
	set hidden = 1

	if(!check_has_body_select())
		return

	var/atom/movable/screen/zone_sel/selector = mob.hud_used.zone_select
	selector.set_selected_zone(BODY_ZONE_L_LEG, mob)

/client/verb/toggle_walk_run()
	set name = "toggle-walk-run"
	set hidden = TRUE
	set instant = TRUE
	if(mob)
		mob.toggle_move_intent(usr)

/mob/proc/toggle_move_intent(mob/user)
	if(m_intent == MOVE_INTENT_RUN)
		m_intent = MOVE_INTENT_WALK
	else
		if (HAS_TRAIT(src,TRAIT_NORUNNING))
			to_chat(src, "You find yourself unable to run.")
			return FALSE
		m_intent = MOVE_INTENT_RUN
	if(hud_used && hud_used.static_inventory)
		for(var/atom/movable/screen/mov_intent/selector in hud_used.static_inventory)
			selector.update_icon()

/mob/verb/up()
	set name = "Move Upwards"
	set category = "IC.Z Layer Move"

	if(zMove(UP, TRUE))
		to_chat(src, "<span class='notice'>You move upwards.</span>")

/mob/verb/down()
	set name = "Move Down"
	set category = "IC.Z Layer Move"

	if(zMove(DOWN, TRUE))
		to_chat(src, "<span class='notice'>You move down.</span>")

/mob/proc/zMove(dir, feedback = FALSE)
	if(dir != UP && dir != DOWN)
		return FALSE
	var/turf/target = get_step_multiz(src, dir)
	if(!target)
		if(feedback)
			to_chat(src, "<span class='warning'>There's nothing in that direction!</span>")
		return FALSE
	if(!canZMove(dir, target))
		if(feedback)
			to_chat(src, "<span class='warning'>You couldn't move there!</span>")
		return FALSE
	forceMove(target)
	return TRUE

/mob/proc/canZMove(direction, turf/target)
	return FALSE

/mob/Moved(atom/old_loc, Dir, Forced = FALSE)
	. = ..()
	if(!client)
		return
	if(client.parallax_holder)
		var/anim_time = world.tick_lag
		if(isliving(src) && glide_size > 0)
			anim_time = world.icon_size / glide_size * world.tick_lag
		client.parallax_holder.Update(anim_time = anim_time)

/mob/onTransitZ(old_z, new_z)
	. = ..()
	if(old_z != new_z)
		client?.parallax_holder?.Reset()
