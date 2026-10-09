
//Here are the procs used to modify status effects of a mob.
//The effects include: stun, knockdown, unconscious, sleeping, resting, jitteriness, dizziness, ear damage,
// eye damage, eye_blind, eye_blurry, druggy, TRAIT_BLIND trait, and TRAIT_NEARSIGHT trait.

///Set the jitter of a mob
/mob/proc/Jitter(amount)
	jitteriness = max(jitteriness,amount,0)

/**
  * Set the dizzyness of a mob to a passed in amount
  *
  * Except if dizziness is already higher in which case it does nothing
  */
/mob/proc/Dizzy(amount)
	dizziness = max(dizziness,amount,0)

///FOrce set the dizzyness of a mob
/mob/proc/set_dizziness(amount)
	dizziness = max(amount, 0)

/**
  * Sets a mob's blindness to an amount if it was not above it already, similar to how status effects work
  */
/mob/proc/blind_eyes(amount)
	var/old_blind = eye_blind
	eye_blind = max((!eye_blind && stat == UNCONSCIOUS || HAS_TRAIT(src, TRAIT_BLIND)) ? 1 : eye_blind , amount)
	var/new_blind = eye_blind
	if(old_blind != new_blind)
		update_blindness()

/**
  * Adjust a mobs blindness by an amount
  *
  * Will apply the blind alerts if needed
  */
/mob/proc/adjust_blindness(amount)
	var/old_eye_blind = eye_blind
	eye_blind = max((stat == UNCONSCIOUS || HAS_TRAIT(src, TRAIT_BLIND)) ? 1 : 0, eye_blind + amount)
	if(!old_eye_blind || !eye_blind)
		update_blindness()
/**
  * Force set the blindness of a mob to some level
  */
/mob/proc/set_blindness(amount)
	var/old_eye_blind = eye_blind
	eye_blind = max(amount, (stat == UNCONSCIOUS || HAS_TRAIT(src, TRAIT_BLIND)) ? 1 : 0)
	if(!old_eye_blind || !eye_blind)
		update_blindness()

/// proc that adds and removes blindness overlays when necessary
/mob/proc/update_blindness()
	if(eye_blind) // UNCONSCIOUS or has blind trait, or has temporary blindness
		if(stat == CONSCIOUS || stat == SOFT_CRIT)
			throw_alert("blind", /atom/movable/screen/alert/blind)

		// Проверяем, надо ли накладывать Blindfold.
		if(HAS_TRAIT(src, TRAIT_BLINDFOLD_HARD))
			overlay_fullscreen("blind_blindfold_hard", /atom/movable/screen/fullscreen/scaled/blind_blindfold/hard)
			overlay_fullscreen("blind_frame", /atom/movable/screen/fullscreen/scaled/blind_frame)
		else if(HAS_TRAIT(src, TRAIT_BLINDFOLD))
			overlay_fullscreen("blind_blindfold", /atom/movable/screen/fullscreen/scaled/blind_blindfold)
			overlay_fullscreen("blind_frame", /atom/movable/screen/fullscreen/scaled/blind_frame)
		else
			clear_fullscreen("blind_blindfold_hard", 0)
			clear_fullscreen("blind_blindfold", 0)
			clear_fullscreen("blind_frame", 0)
			overlay_fullscreen("blind", /atom/movable/screen/fullscreen/scaled/blind)
		// You are blind why should you be able to make out details like color, only shapes near you
		// add_client_colour(/datum/client_colour/monochrome/blind)
	else // CONSCIOUS no blind trait, no blindness
		clear_fullscreen("blind_frame", 0) // Мгновенно убрать
		clear_alert("blind")
		clear_fullscreen("blind")
		clear_fullscreen("blind_blindfold_hard", 0) // Мгновенно убрать
		clear_fullscreen("blind_blindfold", 0) // Мгновенно убрать
		// remove_client_colour(/datum/client_colour/monochrome/blind)
	SEND_SIGNAL(src, COMSIG_MOB_BLINDNESS_CHANGED)
/**
  * Make the mobs vision blurry
  */
/mob/proc/blur_eyes(amount)
	if(amount>0)
		eye_blurry = max(amount, eye_blurry)
	update_eye_blur()

/**
  * Adjust the current blurriness of the mobs vision by amount
  */
/mob/proc/adjust_blurriness(amount)
	eye_blurry = max(eye_blurry+amount, 0)
	update_eye_blur()

///Set the mobs blurriness of vision to an amount
/mob/proc/set_blurriness(amount)
	eye_blurry = max(amount, 0)
	update_eye_blur()

/mob/proc/update_eye_blur()
	if(!hud_used)
		return
	var/atom/movable/plane_master_controller/game_plane_master_controller = hud_used.plane_master_controllers[PLANE_MASTERS_GAME]
	// Life зовёт это каждый тик, а смена фильтра пересобирает фильтры всех игровых плоскостей
	var/list/current_blur = LAZYACCESS(game_plane_master_controller.filter_data, "eye_blur")
	if(eye_blurry)
		var/blur_size = clamp(eye_blurry * 0.1, 0.6, 3)
		if(current_blur && current_blur["size"] == blur_size)
			return
		game_plane_master_controller.add_filter("eye_blur", 1, gauss_blur_filter(blur_size))
	else if(current_blur)
		game_plane_master_controller.remove_filter("eye_blur")

///Adjust the drugginess of a mob
/mob/proc/adjust_drugginess(amount)
	return

///Set the drugginess of a mob
/mob/proc/set_drugginess(amount)
	return

///Adjust the disgust level of a mob
/mob/proc/adjust_disgust(amount)
	return

///Set the disgust level of a mob
/mob/proc/set_disgust(amount)
	return

///Adjust the body temperature of a mob, with min/max settings
/mob/proc/adjust_bodytemperature(amount,min_temp=0,max_temp=INFINITY)
	if(bodytemperature >= min_temp && bodytemperature <= max_temp)
		bodytemperature = clamp(bodytemperature + amount,min_temp,max_temp)
