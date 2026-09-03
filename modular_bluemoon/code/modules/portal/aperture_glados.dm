/mob/living/silicon/ai/proc/deferred_aperture_glados_theme()
	if(QDELETED(src) || !HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE))
		return
	apply_glados_theme(src)

/mob/living/silicon/ai/update_icon_state()
	if(HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE))
		icon = APERTURE_GLADOS_ICON
		icon_state = get_glados_core_icon_state(src)
		return
	return ..()

/mob/living/silicon/ai/set_core_display_icon(input, client/C)
	if(HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE))
		update_glados_core_icon(src)
		return
	return ..()

/mob/living/silicon/ai/view_core()
	. = ..()
	if(HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE))
		update_glados_core_icon(src)

/mob/living/silicon/ai/reset_perspective(atom/A)
	. = ..()
	if(HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE))
		update_glados_core_icon(src)

/mob/camera/aiEye/setLoc(T, force_update = FALSE, dir)
	var/turf/old_turf = get_turf(src)
	. = ..()
	if(!ai || !HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE))
		return
	var/turf/new_turf = get_turf(src)
	if(!force_update && new_turf == old_turf)
		return
	update_glados_core_icon(ai)
