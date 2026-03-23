/mob
	/// If we are in the shifting setting.
	var/shifting = FALSE

	/// Any atoms moving into this atom's tile will be allowed pass through (exception: thrown atoms and projectiles)
	var/passthroughable = FALSE

/datum/keybinding/mob/pixel_shift
	hotkey_keys = list("B")
	name = "pixel_shift"
	full_name = "Pixel Shift"
	description = "Shift your characters offset."
	category = CATEGORY_MOVEMENT
	keybind_signal = COMSIG_KB_MOB_PIXELSHIFT

/datum/keybinding/mob/pixel_shift/down(client/user)
	. = ..()
	if(.)
		return
	var/mob/M = user.mob
	M.shifting = TRUE
	return TRUE

/datum/keybinding/mob/pixel_shift/up(client/user)
	. = ..()
	if(.)
		return
	var/mob/M = user.mob
	M.shifting = FALSE
	return TRUE

/mob/proc/unpixel_shift()
	return

/mob/living/unpixel_shift()
	. = ..()
	passthroughable = FALSE
	if(is_shifted)
		is_shifted = FALSE
		pixel_x = get_standard_pixel_x_offset() + base_pixel_x
		client?.pixel_x = 0
		pixel_y = get_standard_pixel_y_offset() + base_pixel_y
		client?.pixel_y = 0
	// BLUEMOON ADD
	if(is_tilted)
		transform = transform.Turn(-is_tilted)
		is_tilted = 0
	// BLUEMOON ADD END

/mob/proc/pixel_shift(direction)
	return

/mob/living/set_pull_offsets(mob/living/pull_target, grab_state)
	pull_target.unpixel_shift()
	return ..()

/mob/living/reset_pull_offsets(mob/living/pull_target, override)
	pull_target.unpixel_shift()
	return ..()

/mob/living/pixel_shift(direction)
	passthroughable = FALSE

	// BLUEMOON ADD
	if(tilting)
		if(CHECK_BITFIELD(direction, EAST))
			if(is_tilted < 45)
				transform = transform.Turn(1)
				is_tilted++
				is_shifted = TRUE
		else if(CHECK_BITFIELD(direction, WEST))
			if(is_tilted > -45)
				transform = transform.Turn(-1)
				is_tilted--
				is_shifted = TRUE
		return
	// BLUEMOON ADD END

	// Y-axis
	if(CHECK_BITFIELD(direction, NORTH))
		if(pixel_y < PIXEL_SHIFT_MAXIMUM + base_pixel_y)
			pixel_y++
			if(client && client.prefs.view_pixelshift && client.pixel_y < PIXEL_SHIFT_MAXIMUM) //SPLURT Edit
				client.pixel_y++
			is_shifted = TRUE
	else if(CHECK_BITFIELD(direction, SOUTH))
		if(pixel_y > -PIXEL_SHIFT_MAXIMUM + base_pixel_y)
			pixel_y--
			if(client && client.prefs.view_pixelshift && client.pixel_y > -PIXEL_SHIFT_MAXIMUM) //SPLURT Edit
				client.pixel_y--
			is_shifted = TRUE

	// X-axis
	if(CHECK_BITFIELD(direction, EAST))
		if(pixel_x < PIXEL_SHIFT_MAXIMUM + base_pixel_x)
			pixel_x++
			if(client && client.prefs.view_pixelshift && client.pixel_x < PIXEL_SHIFT_MAXIMUM) //SPLURT Edit
				client.pixel_x++
			is_shifted = TRUE
	else if(CHECK_BITFIELD(direction, WEST))
		if(pixel_x > -PIXEL_SHIFT_MAXIMUM + base_pixel_x)
			pixel_x--
			if(client && client.prefs.view_pixelshift && client.pixel_x > -PIXEL_SHIFT_MAXIMUM) //SPLURT Edit
				client.pixel_x--
			is_shifted = TRUE

	if(abs(pixel_y - base_pixel_y) >= PIXEL_SHIFT_PASSABLE_THRESHOLD || abs(pixel_x - base_pixel_x) >= PIXEL_SHIFT_PASSABLE_THRESHOLD)
		passthroughable = TRUE

/mob/living/Login()
	. = ..()
	if(is_shifted && client?.prefs.view_pixelshift) //SPLURT Edit
		client?.pixel_x = pixel_x - base_pixel_x
		client?.pixel_y = pixel_y - base_pixel_y

/mob/living/CanAllowThrough(atom/movable/mover, turf/target)
	// Make sure to not allow projectiles of any kind past where they normally wouldn't.
	if(!istype(mover, /obj/item/projectile) && !mover.throwing && passthroughable)
		return TRUE
	return ..()
