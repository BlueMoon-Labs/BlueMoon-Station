// Shadow wood walls use legacy icon smoothing — no bitmask sprites exist for them.

/turf/closed/wall/mineral/wood/shadow
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE
	icon = 'modular_splurt/icons/turf/walls/wall_shadow.dmi'
	icon_state = "shadow"
	canSmoothWith = list(/turf/closed/wall/mineral/wood/shadow, /obj/structure/falsewall/wood/shadow)

/turf/closed/wall/mineral/wood/shadow/nonmetal
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE
	canSmoothWith = list(/turf/closed/wall/mineral/wood/shadow, /obj/structure/falsewall/wood/shadow)

/obj/structure/falsewall/wood/shadow
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE
	icon = 'modular_splurt/icons/turf/walls/wall_shadow.dmi'
	icon_state = "shadow"
	base_icon_state = "shadow"
	fake_icon = 'modular_splurt/icons/turf/walls/wall_shadow.dmi'
	canSmoothWith = list(/turf/closed/wall/mineral/wood/shadow, /obj/structure/falsewall/wood/shadow)

/obj/structure/falsewall/wood/shadow/update_icon_state()
	if(opening)
		icon = initial(icon)
		icon_state = "[base_icon_state]-[density ? "opening" : "closing"]"
		return ..()
	if(density)
		icon = fake_icon
		icon_state = "shadow"
	else
		icon = initial(icon)
		icon_state = "[initial(base_icon_state)]-open"
	return ..()
