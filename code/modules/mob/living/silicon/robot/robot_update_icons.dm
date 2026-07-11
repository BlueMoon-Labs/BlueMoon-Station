/mob/living/silicon/robot/update_icons()
	cut_overlays()
	if(!module)
		return

	update_base_icon()
	update_equipment_overlays()
	update_sleeper_overlays()
	update_cover_overlay()
	update_rest_icon()
	// Applied after update_rest_icon() so the resting lamp overlay survives its cut_overlays().
	update_eye_lights()
	update_hat_overlay()
	update_fire()

	SEND_SIGNAL(src, COMSIG_ROBOT_UPDATE_ICONS)

/// Sets the base icon file, icon_state and any module-defined transform.
/mob/living/silicon/robot/proc/update_base_icon()
	icon_state = module.cyborg_base_icon
	// Citadel: modules may override the icon file and apply a pixel offset.
	icon = module.cyborg_icon_override || initial(icon)

	if(stat == DEAD && module.has_snowflake_deadsprite)
		icon_state = "[module.cyborg_base_icon]-wreck"

	if(module.cyborg_pixel_offset)
		var/matrix/M = transform
		M.c = module.cyborg_pixel_offset
		transform = M

	if(module.cyborg_base_icon == "robot")
		icon = 'icons/mob/robots.dmi'
		var/matrix/M = transform
		M.c = 0 // Cyborg's initial x offset is very likely to be 0
		transform = M

/// Overlays for equipped module weapons. See borg/inventory.dm.
/mob/living/silicon/robot/proc/update_equipment_overlays()
	if(laser)
		add_overlay("laser")
	if(disabler)
		add_overlay("disabler")

/// Overlays for a fitted sleeper module, with optional night-vision variant.
/mob/living/silicon/robot/proc/update_sleeper_overlays()
	if(!module.sleeper_overlay)
		return
	var/nv_suffix = sleeper_nv ? "_nv" : ""
	if(sleeper_g)
		add_overlay("[module.sleeper_overlay]_g[nv_suffix]")
	if(sleeper_r)
		add_overlay("[module.sleeper_overlay]_r[nv_suffix]")

/// Glowing eyes / headlamp overlay, differing between resting and standing.
/mob/living/silicon/robot/proc/update_eye_lights()
	if(stat == DEAD || IsUnconscious() || low_power_mode)
		return

	var/light_key = module.special_light_key || module.cyborg_base_icon
	var/glowing = lamp_enabled || lamp_doom

	if(resting)
		if(!(glowing && module.sit_lamp_has_state))
			return
		if(!eye_lights)
			eye_lights = new()
		eye_lights.icon_state = "[light_key]_l_[resting_state]"
		eye_lights.color = lamp_doom ? COLOR_RED : lamp_color
		eye_lights.plane = 19 // glowy eyes
	else
		if(IsStun() || IsParalyzed())
			return
		if(!eye_lights)
			eye_lights = new()
		if(glowing)
			eye_lights.icon_state = "[light_key]_l"
			eye_lights.color = lamp_doom ? COLOR_RED : lamp_color
			eye_lights.plane = 19 // glowy eyes
		else
			eye_lights.icon_state = "[light_key]_e[is_servant_of_ratvar(src) ? "_r" : ""]"
			eye_lights.color = COLOR_WHITE
			eye_lights.plane = -1

	eye_lights.icon = icon
	add_overlay(eye_lights)

/// Overlay shown when the maintenance panel is open.
/mob/living/silicon/robot/proc/update_cover_overlay()
	if(!opened)
		return
	if(wiresexposed)
		add_overlay("ov-opencover +w")
	else if(cell)
		add_overlay("ov-opencover +c")
	else
		add_overlay("ov-opencover -c")

/// Dogborg / rest-capable modules swap to a dedicated resting sprite,
/// dropping the standard overlays while resting.
/mob/living/silicon/robot/proc/update_rest_icon()
	if(!(client && stat != DEAD && (module.dogborg || module.hasrest)))
		return
	if(resting)
		icon_state = "[module.cyborg_base_icon]-[resting_state]"
		cut_overlays()
	else
		icon_state = module.cyborg_base_icon

/// Rebuilds (or clears) the worn hat overlay.
/mob/living/silicon/robot/proc/update_hat_overlay()
	if(hat)
		hat_overlay = hat.build_worn_icon(20, default_icon_file = 'icons/mob/clothing/head.dmi', override_state = hat.icon_state)
		update_worn_icons()
	else if(hat_overlay)
		QDEL_NULL(hat_overlay)

/mob/living/silicon/robot/proc/update_worn_icons()
	if(!hat_overlay)
		return
	cut_overlay(hat_overlay)

	if(islist(hat_offset))
		var/alist/offset_state
		if(resting && module.hasrest)
			offset_state = hat_offset["hat_offset_[resting_state]"] || hat_offset[HAT_REST_OFFSET]
		else
			offset_state = hat_offset[HAT_STAND_OFFSET]

		if(offset_state == HAT_NO_RENDER)
			return
		var/list/offset = offset_state[ISDIAGONALDIR(dir) ? dir2text(dir & (WEST|EAST)) : dir2text(dir)]
		if(offset)
			hat_overlay.pixel_x = offset[1]
			hat_overlay.pixel_y = offset[2]
	else if(isnum(hat_offset)) // legacy compatibility pixel_y
		hat_overlay.pixel_y = hat_offset

	add_overlay(hat_overlay)

/mob/living/silicon/robot/setDir(newdir, ismousemovement)
	var/old_dir = dir
	. = ..()
	if(. != old_dir)
		update_worn_icons()
