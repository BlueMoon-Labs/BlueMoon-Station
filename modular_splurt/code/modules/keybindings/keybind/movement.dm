/datum/keybinding/mob/tilt_right
	hotkey_keys = list("AltCtrlEast", "AltCtrlD")
	name = "pixel_tilt_east"
	full_name = "Pixel Tilt Right"
	description = ""
	category = CATEGORY_MOVEMENT

/datum/keybinding/mob/tilt_right/down(client/user)
	var/mob/M = user.mob
	M.tilt_right()
	return TRUE

/datum/keybinding/mob/tilt_left
	hotkey_keys = list("AltCtrlWest", "AltCtrlA")
	name = "pixel_tilt_west"
	full_name = "Pixel Tilt Left"
	description = ""
	category = CATEGORY_MOVEMENT

/datum/keybinding/mob/tilt_left/down(client/user)
	var/mob/M = user.mob
	M.tilt_left()
	return TRUE

// BLUEMOON ADD
/datum/keybinding/mob/pixel_tilt
	hotkey_keys = list("J")
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

//////////////////// Shifting Layer ////////////////////
/datum/keybinding/mob/layershift_up
	name = "layershift_up"
	full_name = "Shift Layer Upwards"
	hotkey_keys = list("Add", "=")
	category = CATEGORY_MOVEMENT

/datum/keybinding/mob/layershift_up/down(client/user)
	var/mob/living/M = user.mob
	if(!istype(M))
		return
	M.layershift_up()
	return TRUE

/datum/keybinding/mob/layershift_down
	name = "layershift_down"
	full_name = "Shift Layer Downwards"
	hotkey_keys = list("Subtract", "-")
	category = CATEGORY_MOVEMENT

/datum/keybinding/mob/layershift_down/down(client/user)
	var/mob/living/M = user.mob
	if(!istype(M))
		return
	M.layershift_down()
	return TRUE

/datum/keybinding/mob/layershift_reset
	name = "layershift_reset"
	full_name = "Reset Layer Priority"
	hotkey_keys = list("Multiply", "0")
	category = CATEGORY_MOVEMENT

/datum/keybinding/mob/layershift_reset/down(client/user)
	var/mob/living/M = user.mob
	if(!istype(M))
		return
	M.layershift_reset()
	return TRUE
