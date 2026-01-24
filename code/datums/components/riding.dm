/datum/component/riding
	var/last_vehicle_move = 0 //used for move delays
	var/last_move_diagonal = FALSE
	var/vehicle_move_delay = 2 //tick delay between movements, lower = faster, higher = slower
	var/keytype

	var/slowed = FALSE
	var/slowvalue = 1

	var/list/riding_offsets = list()	//position_of_user = list(dir = list(px, py)), or RIDING_OFFSET_ALL for a generic one.
	var/list/directional_vehicle_layers = list()	//["[DIRECTION]"] = layer. Don't set it for a direction for default, set a direction to null for no change.
	var/list/directional_vehicle_offsets = list()	//same as above but instead of layer you have a list(px, py)
	var/list/allowed_turf_typecache
	var/list/forbid_turf_typecache					//allow typecache for only certain turfs, forbid to allow all but those. allow only certain turfs will take precedence.
	var/allow_one_away_from_valid_turf = TRUE		//allow moving one tile away from a valid turf but not more.
	var/override_allow_spacemove = FALSE
	var/drive_verb = "drive"
	var/ride_check_rider_incapacitated = FALSE
	var/ride_check_rider_restrained = FALSE
	var/ride_check_ridden_incapacitated = FALSE
	var/list/offhands = list() // keyed list containing all the current riding offsets associated by mob

	var/del_on_unbuckle_all = FALSE

/datum/component/riding/Initialize()
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	RegisterSignal(parent, COMSIG_MOVABLE_BUCKLE, PROC_REF(vehicle_mob_buckle))
	RegisterSignal(parent, COMSIG_MOVABLE_UNBUCKLE, PROC_REF(vehicle_mob_unbuckle))
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(vehicle_moved))
	RegisterSignal(parent, COMSIG_ATOM_DIR_AFTER_CHANGE, PROC_REF(update_dir))

/datum/component/riding/proc/vehicle_mob_unbuckle(datum/source, mob/living/M, force = FALSE)
	SIGNAL_HANDLER

	var/atom/movable/AM = parent
	restore_position(M)
	unequip_buckle_inhands(M)
	if(del_on_unbuckle_all && !AM.has_buckled_mobs())
		qdel(src)

/datum/component/riding/proc/vehicle_mob_buckle(datum/source, mob/living/M, force)
	SIGNAL_HANDLER

	handle_vehicle_offsets(M.buckled?.dir)
	handle_vehicle_layer(M.buckled?.dir)

/datum/component/riding/proc/update_dir(mob/source, dir, newdir)
	SIGNAL_HANDLER

	handle_vehicle_offsets(newdir)
	handle_vehicle_layer(newdir)

/datum/component/riding/proc/handle_vehicle_layer(dir)
	var/atom/movable/AM = parent
	var/static/list/defaults = list(TEXT_NORTH = OBJ_LAYER, TEXT_SOUTH = ABOVE_MOB_LAYER, TEXT_EAST = ABOVE_MOB_LAYER, TEXT_WEST = ABOVE_MOB_LAYER)
	. = defaults["[dir]"]
	if(directional_vehicle_layers["[dir]"])
		. = directional_vehicle_layers["[dir]"]
	if(isnull(.))	//you can set it to null to not change it.
		. = AM.layer
	AM.layer = .

/datum/component/riding/proc/set_vehicle_dir_layer(dir, layer)
	directional_vehicle_layers["[dir]"] = layer

/datum/component/riding/proc/vehicle_moved(datum/source, oldLoc, dir)
	SIGNAL_HANDLER

	var/atom/movable/AM = parent
	if(isnull(dir))
		dir = AM.dir
	AM.set_glide_size(DELAY_TO_GLIDE_SIZE(vehicle_move_delay), FALSE)
	for(var/i in AM.buckled_mobs)
		ride_check(i)
	handle_vehicle_offsets(dir)
	handle_vehicle_layer(dir)

/datum/component/riding/proc/ride_check(mob/living/M)
	var/atom/movable/AM = parent
	var/mob/AMM = AM
	if((ride_check_rider_restrained && M.restrained(TRUE)) || (ride_check_rider_incapacitated && M.incapacitated(FALSE, TRUE)) || (ride_check_ridden_incapacitated && istype(AMM) && AMM.incapacitated(FALSE, TRUE)))
		AM.visible_message("<span class='warning'>[M] falls off of [AM]!</span>")
		AM.unbuckle_mob(M)
	return TRUE

/datum/component/riding/proc/force_dismount_all()
	var/atom/movable/AM = parent
	for(var/i in AM.buckled_mobs)
		force_dismount(i)

/datum/component/riding/proc/force_dismount(mob/living/M, from_mob = FALSE)
	var/atom/movable/AM = parent
	AM.unbuckle_mob(M)

/datum/component/riding/proc/additional_offset_checks()
	return TRUE

/datum/component/riding/proc/handle_vehicle_offsets(dir)
	var/atom/movable/AM = parent
	var/AM_dir = "[dir]"
	var/passindex = 0
	if(AM.has_buckled_mobs())
		for(var/m in AM.buckled_mobs)
			passindex++
			var/mob/living/buckled_mob = m
			var/rider_dir = get_rider_dir(passindex)
			buckled_mob.setDir(rider_dir)
			var/list/offsets = get_offsets(passindex)
			for(var/offsetdir in offsets)
				if(offsetdir == AM_dir)
					var/list/diroffsets = offsets[offsetdir]
					buckled_mob.pixel_x = diroffsets[1]
					if(diroffsets.len >= 2)
						buckled_mob.pixel_y = diroffsets[2]
					if(diroffsets.len == 3)
						buckled_mob.layer = diroffsets[3]
					break
	if (!additional_offset_checks())
		return
	var/list/static/default_vehicle_pixel_offsets = list(TEXT_NORTH = list(0, 0), TEXT_SOUTH = list(0, 0), TEXT_EAST = list(0, 0), TEXT_WEST = list(0, 0))
	var/px = default_vehicle_pixel_offsets[AM_dir]
	var/py = default_vehicle_pixel_offsets[AM_dir]
	if(directional_vehicle_offsets[AM_dir])
		if(isnull(directional_vehicle_offsets[AM_dir]))
			px = AM.pixel_x
			py = AM.pixel_y
		else
			px = directional_vehicle_offsets[AM_dir][1]
			py = directional_vehicle_offsets[AM_dir][2]
	AM.pixel_x = px
	AM.pixel_y = py

/datum/component/riding/proc/set_vehicle_dir_offsets(dir, x, y)
	directional_vehicle_offsets["[dir]"] = list(x, y)

//Override this to set your vehicle's various pixel offsets
/datum/component/riding/proc/get_offsets(pass_index) // list(dir = x, y, layer)
	. = list(TEXT_NORTH = list(0, 0), TEXT_SOUTH = list(0, 0), TEXT_EAST = list(0, 0), TEXT_WEST = list(0, 0))
	if(riding_offsets["[pass_index]"])
		. = riding_offsets["[pass_index]"]
	else if(riding_offsets["[RIDING_OFFSET_ALL]"])
		. = riding_offsets["[RIDING_OFFSET_ALL]"]

/datum/component/riding/proc/set_riding_offsets(index, list/offsets)
	if(!islist(offsets))
		return FALSE
	riding_offsets["[index]"] = offsets

//Override this to set the passengers/riders dir based on which passenger they are.
//ie: rider facing the vehicle's dir, but passenger 2 facing backwards, etc.
/datum/component/riding/proc/get_rider_dir(pass_index)
	var/atom/movable/AM = parent
	return AM.dir

//KEYS
/datum/component/riding/proc/keycheck(mob/user)
	return !keytype || user?.is_holding_item_of_type(keytype)

//BUCKLE HOOKS
/datum/component/riding/proc/restore_position(mob/living/buckled_mob)
	if(isliving(parent))
		var/mob/living/M = parent
		if(M.lying)
			M.layer = LYING_MOB_LAYER
		else
			M.layer = initial(M.layer)

	if(buckled_mob)
		buckled_mob.pixel_x = 0
		buckled_mob.pixel_y = 0

		if(buckled_mob.lying)
			buckled_mob.layer = LYING_MOB_LAYER
			buckled_mob.lying = buckled_mob.lying >= 180 ? 270 : 90
			buckled_mob.update_transform(FALSE)
			buckled_mob.lying_prev = buckled_mob.lying
		else
			buckled_mob.layer = initial(buckled_mob.layer)

		if(buckled_mob.client)
			buckled_mob.client.view_size.resetToDefault()

//MOVEMENT
/datum/component/riding/proc/turf_check(turf/next, turf/current)
	if(allowed_turf_typecache && !allowed_turf_typecache[next.type])
		return (allow_one_away_from_valid_turf && allowed_turf_typecache[current.type])
	else if(forbid_turf_typecache && forbid_turf_typecache[next.type])
		return (allow_one_away_from_valid_turf && !forbid_turf_typecache[current.type])
	return TRUE

/datum/component/riding/proc/handle_ride(mob/user, direction)
	var/atom/movable/AM = parent
	if(user && user.incapacitated())
		Unbuckle(user)
		return
	if(world.time < last_vehicle_move + ((last_move_diagonal? 2 : 1) * vehicle_move_delay))
		return
	last_vehicle_move = world.time

	if(keycheck(user))
		var/turf/next = get_step(AM, direction)
		var/turf/current = get_turf(AM)
		if(!istype(next) || !istype(current))
			return	//not happening.
		if(!turf_check(next, current))
			to_chat(user, "Your \the [AM] can not go onto [next]!")
			return
		if(!Process_Spacemove(direction) || !isturf(AM.loc))
			return
		step(AM, direction)

		if((direction & (direction - 1)) && (AM.loc == next))		//moved diagonally
			last_move_diagonal = TRUE
		else
			last_move_diagonal = FALSE

		handle_vehicle_offsets(direction)
		handle_vehicle_layer(direction)
	else
		to_chat(user, "<span class='notice'>You'll need the keys in one of your hands to [drive_verb] [AM].</span>")

/datum/component/riding/proc/Unbuckle(atom/movable/M)
	addtimer(CALLBACK(parent, TYPE_PROC_REF(/atom/movable, unbuckle_mob), M), 0, TIMER_UNIQUE)

/datum/component/riding/proc/Process_Spacemove(direction)
	var/atom/movable/AM = parent
	return override_allow_spacemove || AM.has_gravity()

/datum/component/riding/proc/account_limbs(mob/living/M)
	if(M.get_num_legs() < 2 && !slowed)
		vehicle_move_delay = vehicle_move_delay + slowvalue
		slowed = TRUE
	else if(slowed)
		vehicle_move_delay = vehicle_move_delay - slowvalue
		slowed = FALSE

///////Yes, I said humans. No, this won't end well...//////////
/datum/component/riding/human
	del_on_unbuckle_all = TRUE
	var/buckle_type = RIDING_PIGGYBACK
	var/rider_dir = 0
	var/obj/item/storage/belt/belly_riding/belly_harness
	var/true_belly_riding = FALSE
	var/datum/interaction/true_belly_riding_interaction
	var/true_belly_riding_cooldown = 0

/datum/component/riding/human/Initialize()
	. = ..()
	directional_vehicle_layers = list(TEXT_NORTH = MOB_LOWER_LAYER, TEXT_SOUTH = MOB_UPPER_LAYER, TEXT_EAST = MOB_UPPER_LAYER, TEXT_WEST = MOB_UPPER_LAYER)

/datum/component/riding/human/vehicle_mob_unbuckle(datum/source, mob/living/M, force = FALSE)
	var/mob/living/carbon/human/H = parent

	// belly riding
	off_true_belly_riding()

	if(!length(H.buckled_mobs))
		H.remove_movespeed_modifier(/datum/movespeed_modifier/human_carry)

		// belly riding
		H.clear_alert(RIDING_ALERT_CATEGORY)
		if(belly_harness)
			REMOVE_TRAIT(belly_harness, TRAIT_NODROP, RIDING_TRAIT)
		var/datum/action/cooldown/true_belly_riding/belly_riding_action = locate() in H.actions
		if(belly_riding_action)
			belly_riding_action.Remove(H)

	if(!buckle_type == RIDING_FIREMAN)
		M.Daze(25)
	if(buckle_type == RIDING_PRINCESS || buckle_type == RIDING_BELLY)
		M.update_pixel_shifting(TRUE)
	REMOVE_TRAIT(M, TRAIT_MOBILITY_NOUSE, src)
	REMOVE_TRAIT(M, TRAIT_BEING_CARRIED, src)
	return ..()

/datum/component/riding/human/vehicle_mob_buckle(datum/source, mob/living/M, force = FALSE)
	. = ..()
	var/mob/living/carbon/human/H = parent
	if(length(H.buckled_mobs))
		H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/human_carry, TRUE, buckle_type == RIDING_FIREMAN? FIREMAN_CARRY_SLOWDOWN : PIGGYBACK_CARRY_SLOWDOWN)
		RegisterSignal(H.buckled_mobs[1], COMSIG_MOVABLE_MOVED, PROC_REF(rider_moved)) // works fine while all humans has max_buckled_mobs = 1
	if(buckle_type == RIDING_FIREMAN)
		ADD_TRAIT(M, TRAIT_MOBILITY_NOUSE, src)
	ADD_TRAIT(M, TRAIT_BEING_CARRIED, src)

	if(istype(belly_harness) && RIDING_IS_BELLY(buckle_type))
		RegisterSignal(parent, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(belly_harness_unequipped))
		ADD_TRAIT(belly_harness, TRAIT_NODROP, RIDING_TRAIT)
		H.throw_alert(RIDING_ALERT_CATEGORY, /atom/movable/screen/alert/belly_riding)
		if((H?.client?.prefs.toggles & VERB_CONSENT) && H?.client?.prefs.erppref == "Yes" || H.has_penis() || H.has_strapon())
			var/datum/action/cooldown/true_belly_riding/belly_riding_action = new
			belly_riding_action.Grant(H)

/datum/component/riding/human/handle_vehicle_offsets(dir)
	set_rider_dir() // первым, т.к. update_transform сбрасывает позицию x, y
	. = ..()

/datum/component/riding/human/get_rider_dir(pass_index)
	return rider_dir || ..()

/datum/component/riding/human/vehicle_moved(datum/source, oldLoc, dir)
	. = ..()
	INVOKE_ASYNC(src, PROC_REF(do_true_belly_riding))

/datum/component/riding/human/proc/do_true_belly_riding()
	var/mob/living/carbon/human/H = parent
	// true belly riding
	if(!true_belly_riding || !true_belly_riding_interaction || !length(H.buckled_mobs))
		off_true_belly_riding()
		return

	if(true_belly_riding_cooldown > world.time)
		return

	true_belly_riding_cooldown = world.time + 0.5 SECONDS
	if(!true_belly_riding_interaction.do_action(H, H.buckled_mobs[1], FALSE))
		off_true_belly_riding()
		return

/datum/component/riding/human/proc/off_true_belly_riding()
	true_belly_riding = FALSE
	true_belly_riding_interaction = null
	true_belly_riding_cooldown = 0
	var/mob/living/carbon/human/H = parent
	var/datum/action/cooldown/true_belly_riding/belly_riding_action = locate() in H.actions
	if(belly_riding_action)
		belly_riding_action.UpdateButtons()

/datum/component/riding/human/proc/belly_harness_unequipped(mob/source, obj/item)
	SIGNAL_HANDLER

	if(item != belly_harness || !RIDING_IS_BELLY(buckle_type))
		return
	if(!QDELETED(belly_harness))
		REMOVE_TRAIT(belly_harness, TRAIT_NODROP, RIDING_TRAIT)
	belly_harness = null

	force_dismount_all()

/datum/component/riding/human/proc/rider_moved(datum/source, oldLoc, dir)
	SIGNAL_HANDLER

	vehicle_moved() // Да, сюда НЕ нужно передавать параметры

/datum/component/riding/human/proc/set_rider_dir()
	var/mob/living/carbon/human/H = parent
	if(H.has_buckled_mobs())
		for(var/mob/living/L in H.buckled_mobs)
			if(buckle_type == RIDING_FACE_TO_FACE)
				rider_dir = turn(H.dir, 180)
			else if(buckle_type == RIDING_PRINCESS)
				switch(H.dir)
					if(EAST, NORTH)
						H.buckle_lying = 90
						L.lying = 90
						L.update_transform(FALSE)
						L.lying_prev = L.lying
						rider_dir = WEST
						L.update_pixel_shifting(TRUE)
						while(L.is_tilted > -20)
							if(L.tilt_left() == FALSE)
								break
						L.pixel_x += 4
					if(WEST, SOUTH)
						H.buckle_lying = 270
						L.lying = 270
						L.update_transform(FALSE)
						L.lying_prev = L.lying
						rider_dir = EAST
						L.update_pixel_shifting(TRUE)
						while(L.is_tilted < 20)
							if(L.tilt_right() == FALSE)
								break
						L.pixel_x -= 4
			else if(buckle_type == RIDING_BELLY)
				rider_dir = turn(H.dir, 180)
				var/degree = (H.dir in list(NORTH, SOUTH)) ? 0 : (H.dir == EAST) ? 20 : 340
				H.buckle_lying = degree
				L.lying = degree
				L.update_transform(FALSE)
				L.lying_prev = L.lying
			else if(buckle_type == RIDING_BELLY_TAUR)
				var/degree = (H.dir in list(NORTH, SOUTH)) ? 360 : (H.dir == EAST) ? 70 : 290
				rider_dir = turn(H.dir, 180)
				H.buckle_lying = degree
				L.lying = degree
				L.update_transform(FALSE)
				L.lying_prev = L.lying

/datum/component/riding/human/handle_vehicle_layer()
	. = ..()
	var/atom/movable/AM = parent
	if(AM.buckled_mobs && AM.buckled_mobs.len)
		for(var/mob/M in AM.buckled_mobs) //ensure proper layering of piggyback and carry, sometimes weird offsets get applied
			M.layer = MOB_LAYER

		// NORTH | SOUTH | EAST | WEST
		// ABOVE_MOB_LAYER = A, BELOW_MOB_LAYER = B

		// A|B|B|B
		if(buckle_type == RIDING_PRINCESS || buckle_type == RIDING_BELLY)
			if(AM.dir == NORTH)
				AM.layer = ABOVE_MOB_LAYER
			else
				AM.layer = BELOW_MOB_LAYER
		// A|B|A|A
		else if(buckle_type == RIDING_FACE_TO_FACE)
			if(AM.dir == SOUTH)
				AM.layer = BELOW_MOB_LAYER
			else
				AM.layer = ABOVE_MOB_LAYER
		// A|A|B|B
		else if(buckle_type == RIDING_BELLY_TAUR)
			if(AM.dir == NORTH)
				AM.layer = ABOVE_MOB_LAYER
			else
				AM.layer = BELOW_MOB_LAYER
		// B|A|B|B - piggyback_carrying
		else if(!AM.buckle_lying)
			if(AM.dir == SOUTH)
				AM.layer = ABOVE_MOB_LAYER
			else
				AM.layer = BELOW_MOB_LAYER

		// A|B|B|B - RIDING_FIREMAN
		else
			if(AM.dir == NORTH)
				AM.layer = BELOW_MOB_LAYER
			else
				AM.layer = ABOVE_MOB_LAYER
	else
		AM.layer = initial(AM.layer)

/datum/component/riding/human/get_offsets(pass_index)
	var/static/list/offsets_by_type = list(
		RIDING_FACE_TO_FACE	= list(TEXT_NORTH = list(0, 4), TEXT_SOUTH = list(0, 4), TEXT_EAST = list(8, 4), TEXT_WEST = list(-8, 4)),
		RIDING_PRINCESS		= list(TEXT_NORTH = list(6, 0), TEXT_SOUTH = list(-6, 0), TEXT_EAST = list(6, 0), TEXT_WEST = list(-6, 0)),
		RIDING_BELLY 		= list(TEXT_NORTH = list(0, 2), TEXT_SOUTH = list(0, 2), TEXT_EAST = list(10, 0), TEXT_WEST = list(-10, 0)),
		RIDING_BELLY_TAUR 	= list(TEXT_NORTH = list(0, -7), TEXT_SOUTH = list(0, -7), TEXT_EAST = list(-3, -12), TEXT_WEST = list(3, -12)),
		"lying" 			= list(TEXT_NORTH = list(0, 6), TEXT_SOUTH = list(0, 6), TEXT_EAST = list(0, 6), TEXT_WEST = list(0, 6)),
		"else" 				= list(TEXT_NORTH = list(0, 6), TEXT_SOUTH = list(0, 6), TEXT_EAST = list(-6, 6), TEXT_WEST = list(6, 6)),
	)
	var/key_name = buckle_type
	var/list/result = offsets_by_type[key_name]

	var/mob/living/carbon/human/H = parent
	if(!result)
		key_name = H.buckle_lying ? "lying" : "else"
		result = offsets_by_type[key_name]
	. = deepCopyList(result)

	var/x_change = 2
	var/y_change = 16
	switch(key_name)
		if(RIDING_BELLY)
			y_change = 8
		if(RIDING_BELLY_TAUR)
			x_change = 7
			y_change = 2

	var/vehicle_size = get_size(H) || 1
	if(vehicle_size != 1 && (x_change || y_change))
		vehicle_size -= 1
		for(var/d in .)
			if(.[d][1] > 0)
				.[d][1] += vehicle_size * x_change
			else if(.[d][1] < 0)
				.[d][1] -= vehicle_size * x_change
			.[d][2] += vehicle_size * y_change


	var/rider_size = get_size(H.buckled_mobs[pass_index]) || 1
	x_change = 0
	y_change = 0
	switch(key_name)
		if(RIDING_BELLY)
			y_change = -8
		if(RIDING_BELLY_TAUR)
			x_change = 7
			y_change = -2

	if(rider_size != 1 && (x_change || y_change))
		rider_size -= 1
		for(var/d in .)
			if(.[d][1] > 0)
				.[d][1] += rider_size * x_change
			else if(.[d][1] < 0)
				.[d][1] -= rider_size * x_change
			.[d][2] += rider_size * y_change

/datum/component/riding/human/additional_offset_checks()
	var/mob/living/carbon/human/H = parent
	return !H.buckled

/datum/component/riding/human/force_dismount(mob/living/M, from_mob = FALSE)
	if(isliving(parent) && RIDING_IS_BELLY(buckle_type) && (belly_harness && !QDELETED(belly_harness)))
		var/mob/living/sender = from_mob ? M : parent
		var/mob/living/target = from_mob ? parent : M
		if(INTERACTING_WITH(sender, target) || !do_after(sender, RIDING_CARRYDELAY_BELLY, target))
			return
	return ..()

/datum/component/riding/cyborg
	del_on_unbuckle_all = TRUE

/datum/component/riding/cyborg/Initialize()
	. = ..()
	directional_vehicle_layers = list(TEXT_NORTH = MOB_LOWER_LAYER, TEXT_SOUTH = MOB_UPPER_LAYER, TEXT_EAST = MOB_UPPER_LAYER, TEXT_WEST = MOB_UPPER_LAYER)

/datum/component/riding/cyborg/ride_check(mob/user)
	var/atom/movable/AM = parent
	if(user.incapacitated())
		var/kick = TRUE
		if(iscyborg(AM))
			var/mob/living/silicon/robot/R = AM
			if(R.module && R.module.ride_allow_incapacitated)
				kick = FALSE
		if(kick)
			to_chat(user, "<span class='userdanger'>You fall off of [AM]!</span>")
			Unbuckle(user)
			return
	if(iscarbon(user))
		var/mob/living/carbon/carbonuser = user
		if(!carbonuser.get_num_arms())
			Unbuckle(user)
			to_chat(user, "<span class='userdanger'>You can't grab onto [AM] with no hands!</span>")
			return

/datum/component/riding/cyborg/handle_vehicle_layer()
	var/atom/movable/AM = parent
	if(AM.buckled_mobs && AM.buckled_mobs.len)
		if(AM.dir == SOUTH)
			AM.layer = ABOVE_MOB_LAYER
		else
			AM.layer = OBJ_LAYER
	else
		AM.layer = MOB_LAYER

/datum/component/riding/cyborg/get_offsets(pass_index) // list(dir = x, y, layer)
	return list(TEXT_NORTH = list(0, 4), TEXT_SOUTH = list(0, 4), TEXT_EAST = list(-6, 3), TEXT_WEST = list( 6, 3))

/datum/component/riding/cyborg/handle_vehicle_offsets()
	var/atom/movable/AM = parent
	if(AM.has_buckled_mobs())
		for(var/mob/living/M in AM.buckled_mobs)
			M.setDir(AM.dir)
			if(iscyborg(AM))
				var/mob/living/silicon/robot/R = AM
				if(istype(R.module))
					M.pixel_x = R.module.ride_offset_x[dir2text(AM.dir)]
					M.pixel_y = R.module.ride_offset_y[dir2text(AM.dir)]
			else
				..()

/datum/component/riding/cyborg/force_dismount(mob/living/M, from_mob = FALSE)
	. = ..()
	var/atom/movable/AM = parent
	var/turf/target = get_edge_target_turf(AM, AM.dir)
	var/turf/targetm = get_step(get_turf(AM), AM.dir)
	M.Move(targetm)
	M.visible_message("<span class='warning'>[M] is thrown clear of [AM]!</span>")
	M.throw_at(target, 14, 5, AM)
	M.DefaultCombatKnockdown(60)

/datum/component/riding/proc/equip_buckle_inhands(mob/living/carbon/human/user, amount_required = 1, mob/living/riding_target_override)
	var/list/equipped
	var/mob/living/L = riding_target_override ? riding_target_override : user
	for(var/amount_needed = amount_required, amount_needed > 0, amount_needed--)
		var/obj/item/riding_offhand/inhand = new
		inhand.rider = L
		inhand.parent = parent
		if(!user.put_in_hands(inhand, TRUE))
			qdel(inhand) // it isn't going to be added to offhands anyway
			break
		LAZYADD(equipped, inhand)
	var/amount_equipped = LAZYLEN(equipped)
	if(amount_equipped)
		LAZYADD(offhands[L], equipped)
	if(amount_equipped >= amount_required)
		return TRUE
	unequip_buckle_inhands(L)
	return FALSE

/datum/component/riding/proc/unequip_buckle_inhands(mob/living/carbon/user)
	for(var/a in offhands[user])
		LAZYREMOVE(offhands[user], a)
		if(a) //edge cases null entries
			var/obj/item/riding_offhand/O = a
			if(O.parent != parent)
				CRASH("RIDING OFFHAND ON WRONG MOB")
			else if(!O.selfdeleting)
				qdel(O)
	return TRUE

/obj/item/riding_offhand
	name = "offhand"
	icon = 'icons/obj/items_and_weapons.dmi'
	icon_state = "offhand"
	w_class = WEIGHT_CLASS_HUGE
	item_flags = ABSTRACT | DROPDEL | NOBLUDGEON
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF
	var/mob/living/carbon/rider
	var/mob/living/parent
	var/selfdeleting = FALSE

/obj/item/riding_offhand/dropped(mob/user)
	selfdeleting = TRUE
	. = ..()

/obj/item/riding_offhand/equipped()
	if(loc != rider && loc != parent)
		selfdeleting = TRUE
		qdel(src)
	. = ..()

/obj/item/riding_offhand/Destroy()
	var/atom/movable/AM = parent
	if(selfdeleting)
		if(rider in AM.buckled_mobs)
			AM.unbuckle_mob(rider)
	. = ..()

/obj/item/riding_offhand/on_thrown(mob/living/carbon/user, atom/target)
	if(rider == user)
		return //Piggyback user.
	user.unbuckle_mob(rider)
	if(HAS_TRAIT(user, TRAIT_PACIFISM))
		to_chat(user, span_notice("Вы аккуратно отпускаете [rider]."))
		return
	return rider

/datum/action/cooldown/true_belly_riding
	name = "True Belly Riding"
	desc = "Позвозяет насадить переносимого на свой член или дилдо."
	icon_icon = 'modular_splurt/icons/mob/actions/lewd_actions/lewd_icons.dmi'
	button_icon_state = "arousal_small"

/datum/action/cooldown/true_belly_riding/Activate()
	if(!ishuman(owner))
		Remove(owner)
		return

	var/mob/living/carbon/human/action_owner = owner
	var/datum/component/riding/human/riding_comp = action_owner.GetComponent(/datum/component/riding/human)
	if(!RIDING_IS_BELLY(riding_comp?.buckle_type))
		Remove(action_owner)
		return
	if(!length(action_owner.buckled_mobs))
		riding_comp.off_true_belly_riding()
		Remove(action_owner)
		return
	if(!action_owner.has_penis() && !action_owner.has_strapon())
		riding_comp.off_true_belly_riding()
		return
	var/mob/living/target = action_owner.buckled_mobs[1]
	var/t_has_vagina = target.has_vagina()
	var/t_has_anus = target.has_anus()
	if(!t_has_anus && !t_has_vagina)
		riding_comp.off_true_belly_riding()
		to_chat(action_owner, span_warning("К сожалению, у [target] отсутствуют подходящие места."))
		return
	// Если выключено, даем выбор интеракции
	if(!riding_comp.true_belly_riding)
		if(!(target?.client?.prefs.toggles & VERB_CONSENT) || !target?.client?.prefs.erppref)
			to_chat(src, span_warning("[target] не желает такой поездки."))
			return
		var/list/interactions_list = list()
		if(t_has_vagina)
			interactions_list[CUM_TARGET_VAGINA] = "/datum/interaction/lewd/belly_riding/vagina"
		if(t_has_anus)
			interactions_list[CUM_TARGET_ANUS] = "/datum/interaction/lewd/belly_riding/anal"
		if(!interactions_list.len)
			to_chat(action_owner, span_warning("К сожалению, у [target] отсутствуют подходящие места."))
			return
		var/choise = interactions_list.len == 1 ? interactions_list[1] : tgui_input_list(action_owner, "Чем вы хотите насадить переносимого?", name, interactions_list)
		if(!choise)
			return
		riding_comp.true_belly_riding_interaction = SSinteractions.interactions[interactions_list[choise]]
		if(!riding_comp.true_belly_riding_interaction)
			return
		else
			var/penis_desc = action_owner.has_strapon() ? "дилдо" : "член"
			to_chat(action_owner, span_userlove("Вы насаживаете [target] на свой [penis_desc]!"))
			to_chat(target, span_userlove("[action_owner] насаживает вас на свой [penis_desc]!"))

	riding_comp.true_belly_riding = !riding_comp.true_belly_riding
	if(!riding_comp.true_belly_riding)
		riding_comp.off_true_belly_riding()
	else
		riding_comp.do_true_belly_riding()

	UpdateButtons()

/datum/action/cooldown/true_belly_riding/UpdateButton(atom/movable/screen/movable/action_button/button, status_only, force)
	if(!ishuman(owner))
		Remove(owner)
		return
	var/mob/living/carbon/human/action_owner = owner
	var/datum/component/riding/human/riding_comp = action_owner.GetComponent(/datum/component/riding/human)
	if(!RIDING_IS_BELLY(riding_comp?.buckle_type))
		Remove(action_owner)
		return
	button_icon_state = riding_comp.true_belly_riding ? "arousal_max" : "arousal_small"
	return ..()
