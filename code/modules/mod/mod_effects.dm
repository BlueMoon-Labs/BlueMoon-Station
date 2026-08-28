/datum/overlay_effect
	var/name = "Generic effect"
	var/icon = 'modular_bluemoon/icons/mob/human/MOD_mask.dmi'
	var/icon_state = ""
	var/color = rgb(248, 248, 248, 255)
	var/need_use_color = FALSE
	var/icon/pre_build_icon

/datum/overlay_effect/proc/apply_color(new_color)
	color = new_color
	if(!need_use_color)
		need_use_color = TRUE
	// if(pre_build_icon)
	// 	pre_build_icon.ColorTone(color)

/datum/overlay_effect/New()
	. = ..()
	pre_build_icon = icon(icon, icon_state)

/datum/overlay_effect/mod_effect
	name = "Base MOD effect"
	icon_state = "modify_tg"

/datum/overlay_effect/mod_effect/white_noize
	name = "White Noize effect"
	icon_state = "static_base"
	color = null //изначально просто эффект.
