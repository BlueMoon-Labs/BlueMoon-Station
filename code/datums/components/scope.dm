/datum/component/scope
	var/range_modifier = 1
	var/category = "scope"
	var/severity = 1
	var/mob/owner
	var/atom/movable/screen/fullscreen/scaled/scope/tracker
	var/given_x = 0
	var/given_y = 0
	var/last_x
	var/last_y
	var/first_pan = TRUE
	var/activation_mouse_params

/datum/component/scope/Initialize(range_modifier = 1, category = "scope", severity = 1)
	if(!isitem(parent))
		return COMPONENT_INCOMPATIBLE
	src.range_modifier = range_modifier
	src.category = category
	src.severity = severity
	RegisterSignal(parent, COMSIG_MOVABLE_MOVED, PROC_REF(on_parent_moved))

/datum/component/scope/UnregisterFromParent()
	stop_zooming()
	UnregisterSignal(parent, COMSIG_MOVABLE_MOVED)
	return ..()

/datum/component/scope/Destroy(force)
	stop_zooming()
	return ..()

/datum/component/scope/proc/on_parent_moved(datum/source)
	SIGNAL_HANDLER
	stop_zooming()

/datum/component/scope/proc/on_user_logout(datum/source)
	SIGNAL_HANDLER
	stop_zooming()

/datum/component/scope/proc/on_user_death(datum/source)
	SIGNAL_HANDLER
	stop_zooming()

/datum/component/scope/proc/on_user_swap_hands(datum/source)
	SIGNAL_HANDLER
	if(owner && !(parent in owner.held_items))
		stop_zooming()

/datum/component/scope/proc/on_user_entered(datum/source, atom/destination, atom/old_loc, list/atom/old_locs)
	SIGNAL_HANDLER
	if(!isturf(destination))
		stop_zooming()

/datum/component/scope/proc/zoom(mob/user)
	if(!user?.client || tracker)
		return FALSE
	var/area/user_area = get_area(user)
	if(user_area && is_hilbert_hotel_area(user_area))
		to_chat(user, span_warning("Отель Гилберта, запрещает смотреть за свои границы."))
		return FALSE
	tracker = user.overlay_fullscreen(category, /atom/movable/screen/fullscreen/scaled/scope, severity)
	if(!tracker)
		return FALSE
	owner = user
	RegisterSignal(user, COMSIG_MOB_CLIENT_LOGOUT, PROC_REF(on_user_logout))
	RegisterSignal(user, COMSIG_LIVING_DEATH, PROC_REF(on_user_death))
	RegisterSignal(user, COMSIG_MOB_SWAP_HANDS, PROC_REF(on_user_swap_hands))
	RegisterSignal(user, COMSIG_ATOM_ENTERING, PROC_REF(on_user_entered))
	START_PROCESSING(SSprojectiles, src)
	first_pan = TRUE
	activation_mouse_params = user.client.mouseParams
	process()
	return TRUE

/datum/component/scope/proc/stop_zooming(mob/user = owner)
	if(!tracker)
		return FALSE
	STOP_PROCESSING(SSprojectiles, src)
	if(owner)
		UnregisterSignal(owner, list(COMSIG_MOB_CLIENT_LOGOUT, COMSIG_LIVING_DEATH, COMSIG_MOB_SWAP_HANDS, COMSIG_ATOM_ENTERING))
		if(owner.client)
			animate(owner.client, 0.2 SECONDS, pixel_x = 0, pixel_y = 0)
		if(owner.fullscreens[category] == tracker)
			owner.clear_fullscreen(category, 0)
	tracker = null
	owner = null
	last_x = null
	last_y = null
	first_pan = TRUE
	activation_mouse_params = null
	if(isgun(parent))
		var/obj/item/gun/gun = parent
		gun.zoomed = FALSE
	return TRUE

/datum/component/scope/process()
	if(!owner?.client || QDELETED(tracker))
		stop_zooming()
		return
	var/area/user_area = get_area(owner)
	if(user_area && is_hilbert_hotel_area(user_area))
		stop_zooming()
		return
	if(tracker.view_current != owner.client.view)
		tracker.SetView(owner.client.view)
	if(first_pan)
		if(owner.client.mouseParams == activation_mouse_params)
			return
		activation_mouse_params = null
	var/list/modifiers = params2list(owner.client.mouseParams)
	var/screen_loc = modifiers["screen-loc"]
	if(!screen_loc)
		return
	var/list/split = splittext(screen_loc, ",")
	if(length(split) < 2)
		return
	var/list/screen_x_list = splittext(split[1], ":")
	var/list/screen_y_list = splittext(split[2], ":")
	if(length(screen_x_list) < 2 || length(screen_y_list) < 2)
		return
	var/screen_x = (text2num(screen_x_list[1]) - 1) * world.icon_size + text2num(screen_x_list[2])
	var/screen_y = (text2num(screen_y_list[1]) - 1) * world.icon_size + text2num(screen_y_list[2])
	if(isnull(screen_x) || isnull(screen_y))
		return
	var/list/view_size = getviewsize(owner.client.view)
	var/view_x = view_size[1] * world.icon_size
	var/view_y = view_size[2] * world.icon_size
	var/x_cap = range_modifier * view_x / 2
	var/y_cap = range_modifier * view_y / 2
	given_x = clamp(round((screen_x - view_x / 2) * range_modifier), -x_cap, x_cap)
	given_y = clamp(round((screen_y - view_y / 2) * range_modifier), -y_cap, y_cap)
	if(given_x == last_x && given_y == last_y)
		return
	last_x = given_x
	last_y = given_y
	if(first_pan)
		first_pan = FALSE
		animate(owner.client, 0.25 SECONDS, pixel_x = given_x, pixel_y = given_y, easing = SINE_EASING | EASE_OUT)
	else
		animate(owner.client, world.tick_lag, pixel_x = given_x, pixel_y = given_y)

/datum/component/scope/proc/get_target_turf()
	if(!owner || !isturf(owner.loc))
		return
	var/pixel_x = owner.client ? owner.client.pixel_x : given_x
	var/pixel_y = owner.client ? owner.client.pixel_y : given_y
	return locate(owner.x + round(pixel_x / world.icon_size, 1), owner.y + round(pixel_y / world.icon_size, 1), owner.z)

/datum/component/scope/proc/get_target(turf/target_turf)
	if(!owner)
		return target_turf
	var/list/object_targets = list()
	var/list/non_dense_targets = list()
	for(var/atom/movable/possible_target in target_turf)
		if(possible_target.layer <= PROJECTILE_HIT_THRESHHOLD_LAYER)
			continue
		if(possible_target.invisibility > owner.see_invisible)
			continue
		if(!possible_target.mouse_opacity)
			continue
		if(iseffect(possible_target))
			continue
		if(ismob(possible_target))
			if(possible_target == owner)
				continue
			return possible_target
		if(!possible_target.density)
			non_dense_targets += possible_target
			continue
		object_targets += possible_target
	for(var/obj/important_object as anything in object_targets)
		return important_object
	for(var/obj/unimportant_object as anything in non_dense_targets)
		return unimportant_object
	return target_turf
