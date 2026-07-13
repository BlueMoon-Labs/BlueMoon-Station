// Shadow/mushroom wood uses legacy icon smoothing — no bitmask sprites exist for them.

/turf/closed/wall/mineral/wood/shadow
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE
	smoothing_groups = NONE
	icon = 'modular_splurt/icons/turf/walls/wall_shadow.dmi'
	icon_state = "shadow"
	canSmoothWith = list(/turf/closed/wall/mineral/wood/shadow, /obj/structure/falsewall/wood/shadow)

/turf/closed/wall/mineral/wood/shadow/nonmetal
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE
	smoothing_groups = NONE
	canSmoothWith = list(/turf/closed/wall/mineral/wood/shadow, /obj/structure/falsewall/wood/shadow)

/turf/closed/wall/mineral/wood/mushroom
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE
	smoothing_groups = NONE
	icon = 'modular_splurt/icons/turf/walls/wall_mushwood.dmi'
	icon_state = "mushwood"
	canSmoothWith = list(/turf/closed/wall/mineral/wood/mushroom, /obj/structure/falsewall/wood/mushroom)

/turf/closed/wall/mineral/wood/mushroom/nonmetal
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE
	smoothing_groups = NONE
	canSmoothWith = list(/turf/closed/wall/mineral/wood/mushroom, /obj/structure/falsewall/wood/mushroom)

/obj/structure/falsewall/wood/shadow
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE
	icon = 'modular_splurt/icons/turf/walls/wall_shadow.dmi'
	icon_state = "shadow"
	base_icon_state = "shadow"
	fake_icon = 'modular_splurt/icons/turf/walls/wall_shadow.dmi'
	canSmoothWith = list(/turf/closed/wall/mineral/wood/shadow, /obj/structure/falsewall/wood/shadow)

/obj/structure/falsewall/wood/mushroom
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE
	icon = 'modular_splurt/icons/turf/walls/wall_mushwood.dmi'
	icon_state = "mushwood"
	base_icon_state = "mushwood"
	fake_icon = 'modular_splurt/icons/turf/walls/wall_mushwood.dmi'
	canSmoothWith = list(/turf/closed/wall/mineral/wood/mushroom, /obj/structure/falsewall/wood/mushroom)

/obj/structure/table/wood/shadow
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE

/obj/structure/table/wood/mushroom
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE

/obj/structure/table/wood/poker/shadow
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE

/obj/structure/table/wood/poker/mushroom
	smooth = SMOOTH_TRUE
	smoothing_flags = NONE

/obj/structure/falsewall/wood/shadow/update_icon_state()
	if(opening)
		icon = initial(icon)
		icon_state = "[base_icon_state]-[density ? "opening" : "closing"]"
		return ..()
	if(density)
		icon = fake_icon
		icon_state = base_icon_state
	else
		icon = initial(icon)
		icon_state = "[initial(base_icon_state)]-open"
	return ..()

/obj/structure/falsewall/wood/mushroom/update_icon_state()
	if(opening)
		icon = initial(icon)
		icon_state = "[base_icon_state]-[density ? "opening" : "closing"]"
		return ..()
	if(density)
		icon = fake_icon
		icon_state = base_icon_state
	else
		icon = initial(icon)
		icon_state = "[initial(base_icon_state)]-open"
	return ..()
