//IMPORTANT: Multiple animate() calls do not stack well, so try to do them all at once if you can.
/mob/living/update_transform(do_animate = TRUE)
//BLUEMOOB ADD START - FUZZY
	appearance_flags |= PIXEL_SCALE
	if(fuzzy)
		appearance_flags &= ~PIXEL_SCALE
//BLUEMOON ADD END - FUZZY
	var/matrix/ntransform = matrix(transform) //aka transform.Copy()
	if(gravity_inverted)
		ntransform.Scale(1, -1)
	var/final_pixel_y = pixel_y
	var/changed = 0
	if(lying != lying_prev && rotate_on_lying)
		changed++
		ntransform.TurnTo(lying_prev,lying)
		if(lying == 0) //Lying to standing
			final_pixel_y = get_standard_pixel_y_offset()
		else //if(lying != 0)
			if(lying_prev == 0) //Standing to lying
				pixel_y = get_standard_pixel_y_offset()
				final_pixel_y = get_standard_pixel_y_offset(lying)
				if(dir & (EAST|WEST)) //Facing east or west
					setDir(pick(NORTH, SOUTH)) //So you fall on your side rather than your face or ass

	if(resize != RESIZE_DEFAULT_SIZE)
		changed++
		ntransform.Scale(resize)
		if(lying && rotate_on_lying)
			ntransform.Translate(lying == 90 ? 16*(resize-1) : -(16*(resize-1)), 0) //Makes sure you stand on the tile no matter the size - sand
		else
			ntransform.Translate(0, 16*(resize-1)) //Makes sure you stand on the tile no matter the size - sand
		resize = RESIZE_DEFAULT_SIZE

	if(gravity_inverted)
		ntransform.Scale(1, -1)
	if(changed)
		if(do_animate)
			animate(src, transform = ntransform, time = 2, pixel_y = final_pixel_y, easing = EASE_IN|EASE_OUT, flags = ANIMATION_PARALLEL)
		else
			transform = ntransform
			pixel_y = final_pixel_y

	update_small_sprite()

/mob/living/proc/update_gravity_inversion(gravity)
	var/inverted = gravity <= NEGATIVE_GRAVITY
	if(gravity_inverted == inverted)
		return
	gravity_inverted = inverted
	var/matrix/flipped = matrix(transform)
	if(is_tilted)
		flipped.Turn(-is_tilted)
		is_tilted = 0
	flipped.Scale(1, -1)
	animate(src, transform = flipped, time = GRAVITY_INVERSION_TIME, easing = SINE_EASING|EASE_OUT, flags = ANIMATION_PARALLEL)
	update_small_sprite()

/mob/living
	var/datum/action/sizecode_smallsprite/small_sprite

/mob/living/proc/update_small_sprite()
	var/datum/atom_hud/alternate_appearance/basic/small_sprite/smallsprite = small_sprite?.smallsprite_WR?.resolve()
	smallsprite?.update_appearance()
