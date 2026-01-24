/// Is `observed_atom` in a mob's field of view? This takes blindness, nearsightness and FOV into consideration
/mob/living/proc/in_fov(atom/observed_atom, ignore_self = FALSE)
	if(ignore_self && observed_atom == src)
		return TRUE
	if(is_blind())
		return FALSE
	. = FALSE
	var/turf/my_turf = get_turf(src) //Because being inside contents of something will cause our x,y to not be updated
	// If turf doesn't exist, then we wouldn't get a fov check called by `play_fov_effect` or presumably other new stuff that might check this.
	//  ^ If that case has changed and you need that check, add it.
	var/rel_x = observed_atom.x - my_turf.x
	var/rel_y = observed_atom.y - my_turf.y
	if(fov_view)
		if(rel_x >= -1 && rel_x <= 1 && rel_y >= -1 && rel_y <= 1) //Cheap way to check inside that 3x3 box around you
			return TRUE //Also checks if both are 0 to stop division by zero

		var/vector_len = sqrt(rel_x ** 2 + rel_y ** 2)

		var/dir_x
		var/dir_y
		switch(dir)
			if(SOUTH)
				dir_x = 0
				dir_y = -vector_len
			if(NORTH)
				dir_x = 0
				dir_y = vector_len
			if(EAST)
				dir_x = vector_len
				dir_y = 0
			if(WEST)
				dir_x = -vector_len
				dir_y = 0

		///Calculate angle
		var/angle = arccos((dir_x * rel_x + dir_y * rel_y) / (sqrt(dir_x**2 + dir_y**2) * sqrt(rel_x**2 + rel_y**2)))

		/// Calculate vision angle and compare
		var/vision_angle = (360 - fov_view) / 2
		if(angle < vision_angle)
			. = TRUE
	else
		. = TRUE

	// Handling nearsightnedness
	if(. && is_nearsighted())
		if((rel_x >= NEARSIGHTNESS_FOV_BLINDNESS || rel_x <= -NEARSIGHTNESS_FOV_BLINDNESS) || (rel_y >= NEARSIGHTNESS_FOV_BLINDNESS || rel_y <= -NEARSIGHTNESS_FOV_BLINDNESS))
			return FALSE


/mob/living/proc/update_fov()
	var/highest_fov
	for(var/T in fov_traits)
		var/V = fov_traits[T]
		if(V > highest_fov)
			highest_fov = V

	fov_view = highest_fov
	update_fov_client()


/mob/living/proc/update_fov_client()
	if(!client)
		return

	var/datum/component/fov_handler/C = GetComponent(/datum/component/fov_handler)
	if(fov_view)
		if(!C)
			AddComponent(/datum/component/fov_handler, fov_view)
		else
			C.set_fov_angle(fov_view)
	else if(C)
		qdel(C)


/image/fov_image
	icon = 'icons/effects/fov/fov_effects.dmi'
	plane = FOV_VISUAL_PLANE
	layer = FOV_VISUAL_LAYER
	appearance_flags = RESET_COLOR | RESET_TRANSFORM


/proc/remove_image_from_clients(image/I, list/clients)
	if(!I || !clients)
		return
	for(var/client/C in clients)
		C.images -= I
	qdel(I)


/proc/play_fov_effect(atom/center, range, icon_state, dir = SOUTH, ignore_self = FALSE, angle = 0, time = 1.5 SECONDS, list/override_list)
	var/turf/anchor_point = get_turf(center)
	var/image/fov_image/I
	var/list/clients_shown

	for(var/mob/living/M in (override_list || get_hearers_in_view(range, center)))
		if(!M.client)
			continue
		if(HAS_TRAIT(M, TRAIT_DEAF))
			continue
		if(M.in_fov(center, ignore_self))
			continue

		if(!I)
			I = new
			I.loc = anchor_point
			I.icon_state = icon_state
			I.dir = dir

			if(angle)
				var/matrix/MX = new
				MX.Turn(angle)
				I.transform = MX

			I.mouse_opacity = MOUSE_OPACITY_TRANSPARENT

		LAZYADD(clients_shown, M.client)
		M.client.images += I

	if(clients_shown)
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(remove_image_from_clients), I, clients_shown), time)

/atom/movable/screen/fov_blocker
	icon = 'icons/effects/fov/field_of_view.dmi'
	icon_state = "90"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = FIELD_OF_VISION_BLOCKER_PLANE
	screen_loc = "BOTTOM,LEFT"

/atom/movable/screen/fov_shadow
	icon = 'icons/effects/fov/field_of_view.dmi'
	icon_state = "90_v"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	plane = ABOVE_LIGHTING_PLANE
	screen_loc = "BOTTOM,LEFT"
