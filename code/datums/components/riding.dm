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

/datum/component/riding/proc/vehicle_mob_unbuckle(datum/source, mob/living/M, force = FALSE)
	var/atom/movable/AM = parent
	restore_position(M)
	unequip_buckle_inhands(M)
	if(del_on_unbuckle_all && !AM.has_buckled_mobs())
		qdel(src)

/datum/component/riding/proc/vehicle_mob_buckle(datum/source, mob/living/M, force)
	handle_vehicle_offsets(M.buckled?.dir)
	handle_vehicle_layer(M.buckled?.dir)

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
	if (isnull(dir))
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

/datum/component/riding/proc/force_dismount(mob/living/M)
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
			var/list/offsets = get_offsets(passindex)
			var/rider_dir = get_rider_dir(passindex)
			buckled_mob.setDir(rider_dir)
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
	if(buckled_mob)
		buckled_mob.pixel_x = 0
		buckled_mob.pixel_y = 0
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

/datum/component/riding/human/Initialize()
	. = ..()
	directional_vehicle_layers = list(TEXT_NORTH = MOB_LOWER_LAYER, TEXT_SOUTH = MOB_UPPER_LAYER, TEXT_EAST = MOB_UPPER_LAYER, TEXT_WEST = MOB_UPPER_LAYER)
	RegisterSignal(parent, COMSIG_HUMAN_MELEE_UNARMED_ATTACK, PROC_REF(on_host_unarmed_melee))

/datum/component/riding/human/vehicle_mob_unbuckle(datum/source, mob/living/M, force = FALSE)
	var/mob/living/carbon/human/H = parent
	if(!length(H.buckled_mobs))
		H.remove_movespeed_modifier(/datum/movespeed_modifier/human_carry)
	if(!buckle_type == RIDING_FIREMAN)
		M.Daze(25)
	if(buckle_type == RIDING_PRINCESS)
		M.update_pixel_shifting(TRUE)
	REMOVE_TRAIT(M, TRAIT_MOBILITY_NOUSE, src)
	REMOVE_TRAIT(M, TRAIT_BEING_CARRIED, src)
	return ..()

/datum/component/riding/human/vehicle_mob_buckle(datum/source, mob/living/M, force = FALSE)
	. = ..()
	var/mob/living/carbon/human/H = parent
	if(length(H.buckled_mobs))
		H.add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/human_carry, TRUE, buckle_type == RIDING_FIREMAN? FIREMAN_CARRY_SLOWDOWN : PIGGYBACK_CARRY_SLOWDOWN)
		RegisterSignal(H.buckled_mobs[1], COMSIG_MOVABLE_MOVED, PROC_REF(set_rider_dir)) // works fine while all humans has max_buckled_mobs = 1
	if(buckle_type == RIDING_FIREMAN)
		ADD_TRAIT(M, TRAIT_MOBILITY_NOUSE, src)
	ADD_TRAIT(M, TRAIT_BEING_CARRIED, src)

/datum/component/riding/human/handle_vehicle_offsets(dir)
	. = ..()
	set_rider_dir()

/datum/component/riding/human/proc/set_rider_dir()
	SIGNAL_HANDLER
	var/mob/living/carbon/human/H = parent
	if(H.has_buckled_mobs())
		for(var/mob/living/L in H.buckled_mobs)
			if(buckle_type == RIDING_FACE_TO_FACE)
				L.setDir(turn(L.dir, 180))
			else if(buckle_type == RIDING_PRINCESS)
				switch(H.dir)
					if(EAST, NORTH)
						H.buckle_lying = 90
						L.lying = 90
						L.update_transform(FALSE)
						L.lying_prev = L.lying
						L.setDir(WEST)
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
						L.setDir(EAST)
						L.update_pixel_shifting(TRUE)
						while(L.is_tilted < 20)
							if(L.tilt_right() == FALSE)
								break
						L.pixel_x -= 4

/datum/component/riding/human/proc/on_host_unarmed_melee(atom/target)
	var/mob/living/carbon/human/H = parent
	if(H.a_intent == INTENT_DISARM && (target in H.buckled_mobs))
		force_dismount(target)

/datum/component/riding/human/handle_vehicle_layer()
	. = ..()
	var/atom/movable/AM = parent
	if(AM.buckled_mobs && AM.buckled_mobs.len)
		for(var/mob/M in AM.buckled_mobs) //ensure proper layering of piggyback and carry, sometimes weird offsets get applied
			M.layer = MOB_LAYER
		// NORTH | SOUTH | EAST | WEST
		// ABOVE_MOB_LAYER = A, OBJ_LAYER = O
		if(buckle_type == RIDING_FACE_TO_FACE || buckle_type == RIDING_PRINCESS) // A|O|O|O
			if(AM.dir == NORTH)
				AM.layer = ABOVE_MOB_LAYER
			else
				AM.layer = OBJ_LAYER
		// else if(buckle_type == RIDING_PRINCESS) // A|O|A|A
		// 	if(AM.dir == SOUTH)
		// 		AM.layer = OBJ_LAYER
		// 	else
		// 		AM.layer = ABOVE_MOB_LAYER
		else if(!AM.buckle_lying) // O|A|O|O - piggyback_carrying
			if(AM.dir == SOUTH)
				AM.layer = ABOVE_MOB_LAYER
			else
				AM.layer = OBJ_LAYER
		else // O|A|A|A - RIDING_FIREMAN
			if(AM.dir == NORTH)
				AM.layer = OBJ_LAYER
			else
				AM.layer = ABOVE_MOB_LAYER
	else
		AM.layer = MOB_LAYER

/datum/component/riding/human/get_offsets(pass_index)
	var/mob/living/carbon/human/H = parent
	var/size_modifier = get_size(H)
	if(buckle_type == RIDING_FACE_TO_FACE)
		. = list(TEXT_NORTH = list(0, 4), TEXT_SOUTH = list(0, 4), TEXT_EAST = list(8, 4), TEXT_WEST = list(-8, 4))
	else if(buckle_type == RIDING_PRINCESS)
		. = list(TEXT_NORTH = list(0, 0), TEXT_SOUTH = list(0, 0), TEXT_EAST = list(0, 0), TEXT_WEST = list(0, 0))
	else if(H.buckle_lying)
		. = list(TEXT_NORTH = list(0, 6), TEXT_SOUTH = list(0, 6), TEXT_EAST = list(0, 6), TEXT_WEST = list(0, 6))
	else
		. = list(TEXT_NORTH = list(0, 6), TEXT_SOUTH = list(0, 6), TEXT_EAST = list(-6, 6), TEXT_WEST = list( 6, 6))
	for(var/d in .)
		if(.[d][1] > 0)
			.[d][1] += (size_modifier-1)*2
		else if(.[d][1] < 0)
			.[d][1] -= (size_modifier-1)*2
		.[d][2] += (size_modifier-1)*16

/datum/component/riding/human/additional_offset_checks()
	var/mob/living/carbon/human/H = parent
	return !H.buckled

/datum/component/riding/human/force_dismount(mob/living/user)
	var/atom/movable/AM = parent
	AM.unbuckle_mob(user)
	user.DefaultCombatKnockdown(60)
	user.Daze(50)
	user.visible_message("<span class='warning'>[AM] pushes [user] off of [AM.ru_na()]!</span>")

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

/datum/component/riding/cyborg/force_dismount(mob/living/M)
	var/atom/movable/AM = parent
	AM.unbuckle_mob(M)
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
