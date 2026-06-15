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
	. = ..()
	if(ai && HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE))
		update_glados_core_icon(ai)

/mob/living/silicon/ai/Login()
	. = ..()
	if(HAS_TRAIT(SSstation, STATION_TRAIT_APERTURE_SCIENCE))
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(apply_glados_theme), src), 1)
