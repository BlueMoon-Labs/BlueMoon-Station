// BLUEMOON ADD
/datum/keybinding/mob/pixel_tilt
	hotkey_keys = list("N")
	name = "pixel_tilt"
	full_name = "Pixel Tilt"
	description = "Hold to rotate with movement keys."
	category = CATEGORY_MOVEMENT

/datum/keybinding/mob/pixel_tilt/down(client/user)
	var/mob/M = user.mob
	M.tilting = TRUE
	return TRUE

/datum/keybinding/mob/pixel_tilt/up(client/user)
	var/mob/M = user.mob
	M.tilting = FALSE
	return TRUE
