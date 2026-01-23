/obj/structure/closet
	name = "closet"
	desc = "It's a basic storage unit."
	icon = 'icons/obj/closet.dmi'
	icon_state = "generic"
	density = TRUE
	max_integrity = 200
	integrity_failure = 0.25
	armor = list(MELEE = 20, BULLET = 10, LASER = 10, ENERGY = 0, BOMB = 10, BIO = 0, RAD = 0, FIRE = 70, ACID = 60)

	/// The overlay for the closet's door
	var/obj/effect/overlay/closet_door/door_obj
	/// Whether or not this door is being animated
	var/is_animating_door = FALSE
	/// Vertical squish of the door
	var/door_anim_squish = 0.12
	/// The maximum angle the door will be drawn at
	var/door_anim_angle = 136
	/// X position of the closet door hinge
	var/door_hinge_x = -6.5
	/// Amount of time it takes for the door animation to play
	var/door_anim_time = 1.5 // set to 0 to make the door not animate at all

	var/icon_door = null
	var/has_door_icon = TRUE // Set to false to skip trying to draw a door icon.
	var/secure = FALSE //secure locker or not, also used if overriding a non-secure locker with a secure door overlay to add fancy lights
	var/opened = FALSE
	var/welded = FALSE
	var/locked = FALSE
	var/large = TRUE
	var/wall_mounted = 0 //never solid (You can always pass over it)
	var/breakout_time = 1200

	/// How many pixels the closet can shift on the x axis when shaking
	var/x_shake_pixel_shift = 2
	/// How many pixels the closet can shift on the y axes when shaking
	var/y_shake_pixel_shift = 1

	var/message_cooldown
	var/can_weld_shut = TRUE
	var/horizontal = FALSE
	var/allow_objects = FALSE
	var/allow_dense = FALSE
	var/dense_when_open = FALSE //if it's dense when open or not
	var/max_mob_size = MOB_SIZE_HUMAN //Biggest mob_size accepted by the container
	var/mob_storage_capacity = 3 // how many human sized mob/living can fit together inside a closet.
	var/storage_capacity = 30 //This is so that someone can't pack hundreds of items in a locker/crate then open it in a populated area to crash clients.
	var/cutting_tool = TOOL_WELDER
	var/open_sound = 'sound/machines/closet_open.ogg'
	var/close_sound = 'sound/machines/closet_close.ogg'
	var/material_drop = /obj/item/stack/sheet/metal
	var/material_drop_amount = 2
	var/delivery_icon = "deliverycloset" //which icon to use when packagewrapped. null to be unwrappable.
	var/anchorable = TRUE
	var/icon_welded = "welded"
	var/obj/item/electronics/airlock/lockerelectronics //Installed electronics
	var/lock_in_use = FALSE //Someone is doing some stuff with the lock here, better not proceed further
	var/eigen_teleport = FALSE //If the closet leads to Mr Tumnus.
	var/obj/structure/closet/eigen_target //Where you go to.
	var/should_populate_contents = TRUE

/obj/structure/closet/Initialize(mapload)
	if(mapload && !opened) // if closed, any item at the crate's loc is put in the contents
		addtimer(CALLBACK(src, PROC_REF(take_contents)), 0)
	. = ..()
	update_icon()
	if(should_populate_contents)
		PopulateContents()
	if(secure)
		lockerelectronics = new(src)
		lockerelectronics.accesses = req_access

//USE THIS TO FILL IT, NOT INITIALIZE OR NEW
/obj/structure/closet/proc/PopulateContents()
	return

/obj/structure/closet/Destroy()
	dump_contents(override = FALSE)
	QDEL_NULL(door_obj)
	return ..()

/obj/structure/closet/update_icon()
	. = ..()
	if(istype(src, /obj/structure/closet/supplypod))
		return

	layer = opened ? BELOW_OBJ_LAYER : OBJ_LAYER

/obj/structure/closet/update_overlays()
	. = ..()
	closet_update_overlays(.)

/obj/structure/closet/proc/closet_update_overlays(list/new_overlays)
	. = new_overlays
	if(!is_animating_door)
		if(opened)
			. += "[icon_state]_open"
			return

		if(has_door_icon)
			. += "[icon_door || icon_state]_door"

		if(welded)
			. += icon_welded

		if(!secure)
			return
		if(broken)
			. += "off"
			. += "sparking"
		//Overlay is similar enough for both that we can use the same mask for both
		. += emissive_appearance(icon, "locked", alpha = src.alpha)
		. += locked ? "locked" : "unlocked"

/// Animates the closet door opening and closing
/obj/structure/closet/proc/animate_door(closing = FALSE)
	if(!door_anim_time)
		return
	if(!door_obj)
		door_obj = new
	var/default_door_icon = "[icon_door || icon_state]_door"
	vis_contents += door_obj
	door_obj.icon = icon
	door_obj.icon_state = default_door_icon
	is_animating_door = TRUE
	var/num_steps = door_anim_time / world.tick_lag

	for(var/step in 0 to num_steps)
		var/angle = door_anim_angle * (closing ? 1 - (step/num_steps) : (step/num_steps))
		var/matrix/door_transform = get_door_transform(angle)
		var/door_state
		var/door_layer

		if (angle >= 90)
			door_state = "[icon_state]_back"
			door_layer = FLOAT_LAYER
		else
			door_state = default_door_icon
			door_layer = ABOVE_MOB_LAYER

		if(step == 0)
			door_obj.transform = door_transform
			door_obj.icon_state = door_state
			door_obj.layer = door_layer
		else if(step == 1)
			animate(door_obj, transform = door_transform, icon_state = door_state, layer = door_layer, time = world.tick_lag, flags = ANIMATION_END_NOW)
		else
			animate(transform = door_transform, icon_state = door_state, layer = door_layer, time = world.tick_lag)
	addtimer(CALLBACK(src, PROC_REF(end_door_animation)), door_anim_time, TIMER_UNIQUE|TIMER_OVERRIDE|TIMER_CLIENT_TIME)

/// Ends the door animation and removes the animated overlay
/obj/structure/closet/proc/end_door_animation()
	is_animating_door = FALSE
	vis_contents -= door_obj
	update_icon()

/// Calculates the matrix to be applied to the animated door overlay
/obj/structure/closet/proc/get_door_transform(angle)
	var/matrix/door_matrix = matrix()
	door_matrix.Translate(-door_hinge_x, 0)
	door_matrix.Multiply(matrix(cos(angle), 0, 0, -sin(angle) * door_anim_squish, 1, 0))
	door_matrix.Translate(door_hinge_x, 0)
	return door_matrix

/obj/structure/closet/examine(mob/user)
	. = ..()
	if(welded)
		. += span_notice("Шкафчик заварен.")
	if(anchored)
		. += span_notice("Шкафчик <b>прикручен</b> к полу.")
	if(opened)
		switch(cutting_tool)
			if(TOOL_WELDER)
				. += span_notice("Части [src] <b>сварены</b> инструментом.")
			if(TOOL_WIRECUTTER)
				. += span_notice("Части [src] можно <b>перекусить</b> инструментом.")
			if(TOOL_CROWBAR)
				. += span_notice("Части [src] можно <b>вскрыть</b> инструментом.")
			if(TOOL_WRENCH)
				. += span_notice("Части [src] можно <b>раскрутить</b> инструментом.")
			if(TOOL_SCREWDRIVER)
				. += span_notice("Части [src] можно <b>развинтить</b> инструментом.")
			else
				. += span_notice("Части [src] можно <b>разобрать</b> инструментом.")
	else if(secure && !opened)
		. += span_notice("Alt-click, чтобы [locked ? "открыть" : "закрыть"].")
	else if(broken)
		. += span_notice("Замок <b>вкручен</b> внутрь.")

	if(isobserver(user))
		. += span_info("Внутри находится: [english_list(contents)].")
		investigate_log("had its contents examined by [user] as a ghost.", INVESTIGATE_GHOST)

	if(HAS_TRAIT(user, TRAIT_SKITTISH))
		. += span_notice("If you bump into [p_them()] while running, you will jump inside.")

/obj/structure/closet/CanAllowThrough(atom/movable/mover, turf/target)
	. = ..()
	if(wall_mounted)
		return TRUE

/obj/structure/closet/proc/can_open(mob/living/user, force = FALSE)
	if(force)
		return TRUE
	if(welded || locked)
		return FALSE
	var/turf/T = get_turf(src)
	for(var/mob/living/L in T)
		if(L.anchored || L.move_resist >= MOVE_FORCE_VERY_STRONG || (horizontal && L.mob_size > MOB_SIZE_TINY && L.density))
			if(user)
				to_chat(user, span_danger("Что-то большое поверх [src] мешает открыть шкафчик."))
			return FALSE
	return TRUE

/obj/structure/closet/proc/can_close(mob/living/user)
	var/turf/T = get_turf(src)
	for(var/obj/structure/closet/closet in T)
		if(closet != src && !closet.wall_mounted)
			return FALSE
	for(var/mob/living/L in T)
		if(L.anchored || L.move_resist >= MOVE_FORCE_VERY_STRONG || (horizontal && L.mob_size > MOB_SIZE_TINY && L.density))
			if(user)
				to_chat(user, span_danger("Что-то слишком большое внутри [src] мешает закрыть шкафчик."))
			return FALSE
	// BLUEMOON ADD START - крутое ЕРТ кропило против сатанистов
	for(var/obj/item/aspergillum/ert/holy_thing)
		if(iscultist(user) || is_servant_of_ratvar(user) || isclockmob(user) || isconstruct(user) || isvampire(user))
			to_chat(user, span_cultbold("Священная энергия [holy_thing] не позволяет [src] закрыться!"))
			return FALSE
		else
			break
	// BLUEMOON ADD END
	return TRUE

/obj/structure/closet/proc/dump_contents(override = TRUE) //Override is for not revealing the locker electronics when you open the locker, for example
	var/atom/L = drop_location()
	for(var/atom/movable/AM in src)
		if(AM == lockerelectronics && override) // this stops the electronics from being dumped out? huh
			continue
		AM.forceMove(L)
		if(throwing) // you keep some momentum when getting out of a thrown closet
			step(AM, dir)
	if(throwing)
		throwing.finalize(FALSE)

/obj/structure/closet/proc/take_contents()
	var/atom/L = drop_location()
	for(var/atom/movable/AM in L)
		if(AM != src && insert(AM) == -1) // limit reached
			break
	// todo: this should be unnecessary, storage should auto close on move wtf
	for(var/i in reverseRange(L.GetAllContents()))
		var/atom/movable/thing = i
		SEND_SIGNAL(thing, COMSIG_TRY_STORAGE_HIDE_ALL)

/obj/structure/closet/proc/open(mob/living/user, force = FALSE)
	if(!can_open(user, force))
		return
	if(opened)
		return
	welded = FALSE
	locked = FALSE // if you manage to open it, then its not welded/locked, hello?!
	playsound(loc, open_sound, 15, TRUE, -3)
	opened = TRUE
	if(!dense_when_open)
		density = FALSE
	climb_time *= 0.5 //it's faster to climb onto an open thing
	dump_contents()
	animate_door(FALSE)
	update_icon()
	after_open(user, force)
	return TRUE

///Proc to override for effects after opening a door
/obj/structure/closet/proc/after_open(mob/living/user, force = FALSE)
	return

/obj/structure/closet/proc/insert(atom/movable/AM)
	if(contents.len >= storage_capacity)
		return -1
	if(insertion_allowed(AM))
		if(eigen_teleport) // For teleporting people with linked lockers.
			do_teleport(AM, get_turf(eigen_target), 0)
			if(eigen_target.opened == FALSE)
				eigen_target.bust_open()
			return TRUE

		AM.forceMove(src)
		return TRUE
	else
		return FALSE

/obj/structure/closet/proc/insertion_allowed(atom/movable/AM)
	if(ismob(AM))
		if(!isliving(AM)) //let's not put ghosts or camera mobs inside closets...
			return FALSE
		var/mob/living/L = AM
		if(L.anchored || L.move_resist >= MOVE_FORCE_VERY_STRONG || L.buckled || L.incorporeal_move || L.has_buckled_mobs())
			return FALSE
		if(L.mob_size > MOB_SIZE_TINY) // Tiny mobs are treated as items.
			if(horizontal && L.density)
				return FALSE
			if(L.mob_size > max_mob_size)
				return FALSE
			// BLUEMOOB ADDITION AHEAD - убираем много головной боли с абузами ящиков на больших персонажей, запретив помещать их внутрь
			if(L.mob_weight > MOB_WEIGHT_NORMAL)
				return FALSE
			// BLUEMOOB ADDITION END
			var/mobs_stored = 0
			for(var/mob/living/M in contents)
				if(++mobs_stored >= mob_storage_capacity)
					return FALSE
		L.stop_pulling()

	else if(istype(AM, /obj/structure/closet))
		return FALSE

	else if(iseffect(AM)) // todo: move to atom/movable
		return FALSE

	else if(isobj(AM))
		if((!allow_dense && AM.density) || AM.anchored || AM.has_buckled_mobs())
			return FALSE
		else if(isitem(AM) && !HAS_TRAIT(AM, TRAIT_NODROP))
			return TRUE
		else if(!allow_objects && !istype(AM, /obj/effect/dummy/chameleon))
			return FALSE
	else
		return FALSE

	return TRUE

/obj/structure/closet/proc/close(mob/living/user)
	if(!opened || !can_close(user))
		return FALSE
	take_contents()
	playsound(loc, close_sound, 15, TRUE, -3)
	opened = FALSE
	density = TRUE
	animate_door(TRUE)
	update_icon()
	after_close(user)
	return TRUE

///Proc to override for effects after closing a door
/obj/structure/closet/proc/after_close(mob/living/user)
	return


/obj/structure/closet/proc/toggle(mob/living/user)
	if(opened)
		return close(user)
	else
		return open(user)


/obj/structure/closet/deconstruct(disassembled = TRUE)
	if(ispath(material_drop) && material_drop_amount && !(flags_1 & NODECONSTRUCT_1))
		new material_drop(loc, material_drop_amount)
	qdel(src)

/obj/structure/closet/obj_break(damage_flag)
	if(!broken && !(flags_1 & NODECONSTRUCT_1))
		bust_open()

/obj/structure/closet/attackby(obj/item/W, mob/user, params)
	if(user in src)
		return
	if(src.tool_interact(W,user))
		return TRUE // No afterattack
	else
		return ..()

/obj/structure/closet/proc/tool_interact(obj/item/W, mob/living/user)//returns TRUE if attackBy call shouldn't be continued (because tool was used/closet was of wrong type), FALSE if otherwise
	. = TRUE
	if(opened)
		if(W.tool_behaviour == cutting_tool)
			// eigen check
			if(eigen_teleport)
				to_chat(user, span_notice("The unstable nature of \the [src] makes it impossible to deconstruct!"))
				return

			if(W.tool_behaviour == TOOL_WELDER)
				if(!W.tool_start_check(user, amount=0))
					return
				to_chat(user, span_notice("You begin cutting \the [src] apart..."))
				if(W.use_tool(src, user, 40, volume=50))
					if(!opened)
						return
					user.visible_message(span_notice("[user] slices apart \the [src]."),
									span_notice("You cut \the [src] apart with \the [W]."),
									span_hear("You hear welding."))
					deconstruct(TRUE)
				return
			else if(W.tool_behaviour == TOOL_WIRECUTTER)
				W.use_tool(src, user, 40, volume=50)
				user.visible_message(span_notice("[user] cut apart \the [src]."), \
									span_notice("You cut \the [src] apart with \the [W]."))
				deconstruct(TRUE)
				return
			W.use_tool(src, user, 40, volume=50)
			user.visible_message(span_notice("[user] deconstructed \the [src]."), \
									span_notice("You deconstructed \the [src] with \the [W]."))
			deconstruct(TRUE) //Honestly by this point, if all checks were right and this is the cutting tool, just cut it
			return
		if(user.transferItemToLoc(W, drop_location())) // so we put in unlit welder too
			return
	else if(!opened && user.a_intent == INTENT_HELP)
		var/item_is_id = W.GetID()
		if(!item_is_id)
			if(!open(user))
				togglelock(user)
				return
			return
		if(item_is_id || !toggle(user))
			togglelock(user)
			return
	else if(W.tool_behaviour == TOOL_WELDER && can_weld_shut)
		// eigen check
		if(eigen_teleport)
			to_chat(user, span_notice("The unstable nature of \the [src] makes it impossible to deconstruct!"))
			return
		if(!W.tool_start_check(user, amount=0))
			return

		to_chat(user, span_notice("You begin [welded ? "unwelding":"welding"] \the [src]..."))
		if(W.use_tool(src, user, 40, volume=50))
			if(opened)
				return
			welded = !welded
			after_weld(welded)
			user.visible_message(span_notice("[user] [welded ? "welds shut" : "unwelded"] \the [src]."),
							span_notice("You [welded ? "weld" : "unwelded"] \the [src] with \the [W]."),
							span_hear("You hear welding."))
			log_game("[key_name(user)] [welded ? "welded":"unwelded"] closet [src] with [W] at [AREACOORD(src)]")
			update_icon()
	else if(W.tool_behaviour == TOOL_WRENCH && anchorable)
		if(isinspace() && !anchored)
			return
		set_anchored(!anchored)
		W.play_tool_sound(src, 75)
		user.visible_message(span_notice("[user] [anchored ? "anchored" : "unanchored"] \the [src] [anchored ? "to" : "from"] the ground."), \
						span_notice("You [anchored ? "anchored" : "unanchored"] \the [src] [anchored ? "to" : "from"] the ground."), \
						span_hear("You hear a ratchet."))
	// cit addons
	else if(istype(W, /obj/item/electronics/airlock))
		handle_lock_addition(user, W)
	else if(W.tool_behaviour == TOOL_SCREWDRIVER)
		handle_lock_removal(user, W)

	else
		return FALSE

/obj/structure/closet/proc/after_weld(weld_state)
	return

/obj/structure/closet/MouseDrop_T(atom/movable/O, mob/living/user)
	if(!istype(O) || O.anchored || istype(O, /atom/movable/screen))
		return
	if(!istype(user) || user.incapacitated() || user.lying)
		return
	if(!Adjacent(user) || !user.Adjacent(O))
		return
	if(user == O) //try to climb onto it
		return ..()
	if(!opened)
		return
	if(!isturf(O.loc))
		return

	var/actuallyismob = 0
	if(isliving(O))
		actuallyismob = 1
	else if(!isitem(O))
		return
	var/turf/T = get_turf(src)
//	var/list/targets = list(O, src) / BLUEMOON REMOVAL - CLOSET DROP RUNTIME FIX
	add_fingerprint(user)
	user.visible_message(span_warning("[user] [actuallyismob ? "tries to ":""]stuff [O] into [src]."), \
		span_warning("You [actuallyismob ? "try to ":""]stuff [O] into [src]."), \
		span_hear("You hear clanging."))
	if(actuallyismob)
		var/is_bodybag = istype(src, /obj/structure/closet/body_bag) // BLUEMOON ADD
		if(is_bodybag || do_after(user, 3 SECONDS, O)) // BLUEMOON EDIT - CLOSET DROP RUNTIME FIX - WAS if(!do_after(user, 3 SECONDS, target = targets, timed_action_flags = (IGNORE_HELD_ITEM | IGNORE_INCAPACITATED), extra_checks = CALLBACK(user, TYPE_PROC_REF(/mob/living/carbon, cuff_resist_check))))
			user.visible_message(span_notice("[user] stuffs [O] into [src]."), \
				span_notice("You stuff [O] into [src]."), \
				is_bodybag ? span_hear("You hear a loud metal bang.") : null)
			var/mob/living/L = O
			if(!is_bodybag && !issilicon(L))
				L.DefaultCombatKnockdown(40)
			if(istype(src, /obj/structure/closet/supplypod/extractionpod))
				O.forceMove(src)
			else
				O.forceMove(T)
				if(!is_bodybag)
					close()
			log_combat(user, O, "stuffed", addition = "inside of [src]") // BLUEMOON ADD - CLOSET DROP RUNTIME FIX
	else
		O.forceMove(T)

/obj/structure/closet/relaymove(mob/living/user, direction)
	if(user.stat || !isturf(loc))
		return
	if(locked)
		if(message_cooldown <= world.time)
			message_cooldown = world.time + 50
			to_chat(user, span_warning("[src]'s door won't budge!"))
		return
	container_resist(user)

/obj/structure/closet/on_attack_hand(mob/user)
	if(user.lying && get_dist(src, user) > 0)
		return

	if(!toggle(user))
		togglelock(user)


/obj/structure/closet/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/closet/attack_robot(mob/user)
	if(user.Adjacent(src))
		return attack_hand(user)

// tk grab then use on self
/obj/structure/closet/attack_self_tk(mob/user)
	return attack_hand(user)

/obj/structure/closet/verb/verb_toggleopen()
	set src in view(1)
	set category = "Object"
	set name = "Toggle Open"

	if(!usr.canUseTopic(src, BE_CLOSE) || !isturf(loc))
		return

	if(iscarbon(usr) || issilicon(usr) || isdrone(usr))
		return toggle(usr)
	else
		to_chat(usr, span_warning("This mob type can't use this verb."))

// Objects that try to exit a locker by stepping were doing so successfully,
// and due to an oversight in turf/Enter() were going through walls.  That
// should be independently resolved, but this is also an interesting twist.
/obj/structure/closet/Exit(atom/movable/AM)
	open()
	if(AM.loc == src)
		return FALSE
	return TRUE

/obj/structure/closet/container_resist(mob/living/user)
	if(isstructure(loc))
		relay_container_resist(user, loc)
	if(opened)
		return
	if(ismovable(loc))
		user.changeNext_move(CLICK_CD_BREAKOUT)
		user.last_special = world.time + CLICK_CD_BREAKOUT
		var/atom/movable/AM = loc
		AM.relay_container_resist(user, src)
		return
	if(!welded && !locked)
		open()
		return
	//okay, so the closet is either welded or locked... resist!!!
	user.changeNext_move(CLICK_CD_BREAKOUT)
	user.last_special = world.time + CLICK_CD_BREAKOUT
	user.visible_message(span_warning("[src] begins to shake violently!"), \
		span_notice("You lean on the back of [src] and start pushing the door open... (this will take about [DisplayTimeText(breakout_time)].)"), \
		span_hear("You hear banging from [src]."))

	addtimer(CALLBACK(src, PROC_REF(check_if_shake)), 1 SECONDS)

	if(do_after(user,(breakout_time), target = src))
		if(!user || user.stat != CONSCIOUS || user.loc != src || opened || (!locked && !welded) )
			return
		//we check after a while whether there is a point of resisting anymore and whether the user is capable of resisting
		user.visible_message(span_danger("[user] successfully broke out of [src]!"),
							span_notice("You successfully break out of [src]!"))
		bust_open()
	else
		if(user.loc == src) //so we don't get the message if we resisted multiple times and succeeded.
			to_chat(user, span_warning("You fail to break out of [src]!"))

/obj/structure/closet/proc/bust_open()
	welded = FALSE //applies to all lockers
	locked = FALSE //applies to critter crates and secure lockers only
	broken = TRUE //applies to secure lockers only
	open()

/// Check if someone is still resisting inside, and choose to either keep shaking or stop shaking the closet
/obj/structure/closet/proc/check_if_shake()
	// Assuming we decide to shake again, how long until we check to shake again
	var/next_check_time = 1 SECONDS

	// How long we shake between different calls of Shake(), so that it starts shaking and stops, instead of a steady shake
	var/shake_duration =  0.3 SECONDS

	for(var/mob/living/mob in contents)
		if(DOING_INTERACTION_WITH_TARGET(mob, src))
			// Shake and queue another check_if_shake
			Shake(x_shake_pixel_shift, y_shake_pixel_shift, shake_duration)
			addtimer(CALLBACK(src, PROC_REF(check_if_shake)), next_check_time)
			return TRUE

	// If we reach here, nobody is resisting, so dont shake
	return FALSE

/obj/structure/closet/relay_container_resist(mob/living/user, obj/container)
	container.container_resist()

/obj/structure/closet/AltClick(mob/user)
	..()
	if(!user.canUseTopic(src, BE_CLOSE) || !isturf(loc))
		return
	if(opened || !secure)
		return
	else
		togglelock(user)

/obj/structure/closet/proc/togglelock(mob/living/user, silent)
	if(secure && !broken)
		if(allowed(user))
			if(iscarbon(user))
				add_fingerprint(user)
			locked = !locked
			user.visible_message(span_notice("[user] [locked ? null : "un"]locks [src]."),
							span_notice("You [locked ? null : "un"]lock [src]."))
			update_icon()
		else if(!silent)
			to_chat(user, span_alert("Access Denied."))
	else if(secure && broken)
		to_chat(user, span_warning("\The [src] is broken!"))

/obj/structure/closet/CtrlShiftClick(mob/living/user)
	if(!HAS_TRAIT(user, TRAIT_SKITTISH))
		return ..()
	if(!user.canUseTopic(src) || !isturf(user.loc) || !user.Adjacent(src) || !user.CanReach(src))
		return
	dive_into(user)

/obj/structure/closet/emag_act(mob/user)
	. = ..()
	if(!secure || broken)
		return
	if(user)
		user.visible_message(span_warning("Sparks fly from [src]!"),
						span_warning("You scramble [src]'s lock, breaking it open!"),
						span_hear("You hear a faint electrical spark."))
	log_admin("[key_name(usr)] emagged [src] at [AREACOORD(src)]")
	playsound(src, "sparks", 50, TRUE, SHORT_RANGE_SOUND_EXTRARANGE)
	broken = TRUE
	locked = FALSE
	if(!QDELETED(lockerelectronics))
		QDEL_NULL(lockerelectronics)
	update_icon()

/obj/structure/closet/get_remote_view_fullscreens(mob/user)
	if(user.stat == DEAD || !(user.sight & (SEEOBJS|SEEMOBS)))
		user.overlay_fullscreen("remote_view", /atom/movable/screen/fullscreen/scaled/impaired, 1)

/obj/structure/closet/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if (!(. & EMP_PROTECT_CONTENTS))
		for(var/obj/O in src)
			O.emp_act(severity)
	if(!secure || broken)
		return
	if(prob(severity/2))
		locked = !locked
		update_icon()
	if(prob(severity/5) && !opened)
		if(!locked)
			open()
		else
			req_access = list()
			req_access += pick(get_all_accesses())
			if(!QDELETED(lockerelectronics))
				lockerelectronics.accesses = req_access

/obj/structure/closet/contents_explosion(severity, target, origin)
	for(var/atom/A in contents)
		A.ex_act(severity, target, origin)
		CHECK_TICK

/obj/structure/closet/singularity_act()
	dump_contents()
	..()

/obj/structure/closet/AllowDrop()
	return TRUE


/obj/structure/closet/return_temperature()
	return

/obj/structure/closet/proc/dive_into(mob/living/user)
	var/turf/T1 = get_turf(user)
	var/turf/T2 = get_turf(src)
	if(!opened)
		if(locked)
			togglelock(user, TRUE)
		if(!open(user))
			to_chat(user, span_warning("It won't budge!"))
			return
	step_towards(user, T2)
	T1 = get_turf(user)
	if(T1 == T2)
		user.set_resting(TRUE, TRUE)
		if(!close(user))
			to_chat(user, span_warning("You can't get [src] to close!"))
			user.set_resting(FALSE, TRUE)
			return
		user.set_resting(FALSE, TRUE)
		togglelock(user)
		T1.visible_message(span_warning("[user] dives into [src]!"))

/obj/structure/closet/canReachInto(atom/user, atom/target, list/next, view_only, obj/item/tool)
	return (user in src)

/// cit specific ///

/obj/structure/closet/proc/handle_lock_addition(mob/user, obj/item/electronics/airlock/E)
	add_fingerprint(user)
	if(lock_in_use)
		to_chat(user, span_notice("Wait for work on [src] to be done first!"))
		return
	if(secure)
		to_chat(user, span_notice("This locker already has a lock!"))
		return
	if(broken)
		to_chat(user, span_notice("<b>Unscrew</b> the broken lock first!"))
		return
	if(!istype(E))
		return
	user.visible_message(span_notice("[user] begins installing a lock on [src]..."),span_notice("You begin installing a lock on [src]..."))
	lock_in_use = TRUE
	playsound(loc, 'sound/items/screwdriver.ogg', 50, 1)
	if(!do_after(user, 60, target = src))
		lock_in_use = FALSE
		return
	lock_in_use = FALSE
	to_chat(user, span_notice("You finish the lock on [src]!"))
	E.forceMove(src)
	lockerelectronics = E
	req_access = E.accesses
	secure = TRUE
	update_icon()
	return TRUE

/obj/structure/closet/proc/handle_lock_removal(mob/user, obj/item/S)
	if(!S.tool_behaviour == TOOL_SCREWDRIVER)
		return
	if(lock_in_use)
		to_chat(user, span_notice("Wait for work on [src] to be done first!"))
		return
	if(locked)
		to_chat(user, span_notice("Unlock it first!"))
		return
	if(!secure)
		to_chat(user, span_notice("[src] doesn't have a lock that you can remove!"))
		return
	if(!istype(S))
		return
	var/brokenword = broken ? "broken " : null
	user.visible_message(span_notice("[user] begins removing the [brokenword]lock on [src]..."),span_notice("You begin removing the [brokenword]lock on [src]..."))
	playsound(loc, S.usesound, 50, 1)
	lock_in_use = TRUE
	if(!do_after(user, 100 * S.toolspeed, target = src))
		lock_in_use = FALSE
		return
	to_chat(user, span_notice("You remove the [brokenword]lock from [src]!"))
	if(!QDELETED(lockerelectronics))
		lockerelectronics.add_fingerprint(user)
		lockerelectronics.forceMove(user.loc)
	lockerelectronics = null
	req_access = null
	secure = FALSE
	broken = FALSE
	locked = FALSE
	lock_in_use = FALSE
	update_icon()
	return TRUE

/obj/structure/closet/proc/can_lock(mob/living/user, var/check_access = TRUE) //set check_access to FALSE if you only need to check if a locker has a functional lock rather than access
	if(!secure)
		return FALSE
	if(broken)
		to_chat(user, span_notice("[src] is broken!"))
		return FALSE
	if(QDELETED(lockerelectronics) && !locked) //We want to be able to unlock it regardless of electronics, but only lockable with electronics
		to_chat(user, span_notice("[src] is missing locker electronics!"))
		return FALSE
	if(!check_access)
		return TRUE
	if(allowed(user))
		return TRUE
	to_chat(user, span_notice("Access denied."))

/obj/structure/closet/on_object_saved(depth)
	if(depth >= 10)
		return ""
	var/dat = ""
	for(var/obj/item in contents)
		var/metadata = generate_tgm_metadata(item)
		dat += "[dat ? ",\n" : ""][item.type][metadata]"
		//Save the contents of things inside the things inside us, EG saving the contents of bags inside lockers
		var/custom_data = item.on_object_saved(depth++)
		dat += "[custom_data ? ",\n[custom_data]" : ""]"
	return dat
