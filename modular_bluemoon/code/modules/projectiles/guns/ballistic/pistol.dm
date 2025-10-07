///obj/item/gun/ballistic/automatic/mk59
//	name = "\improper Mk. 59 Enforcer (.45)"
//	desc = "The mk59 version enforcer is equipped with a wire buttstock, which increases stabilization at the cost of weapon size."
//	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
//	icon_state = "mk59"
//	w_class = WEIGHT_CLASS_BULKY
//	weapon_weight = WEAPON_LIGHT
//	spread = 1
//	mag_type = /obj/item/ammo_box/magazine/e45
//	can_suppress = TRUE
//	can_flashlight = 1
//	flight_x_offset = 31
//	flight_y_offset = 17
//	obj_flags = UNIQUE_RENAME
//	fire_delay = 0
//	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
//	burst_size = 1
//	automatic_burst_overlay = FALSE
//
///obj/item/gun/ballistic/automatic/mk59/update_icon_state()
//	icon_state = "[initial(icon_state)][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"

///obj/item/gun/ballistic/automatic/mk59/nomag
//	spawnwithmagazine = FALSE

/obj/item/gun/ballistic/automatic/mk60
	name = "\improper Mk. 60 Enforcer (.45)"
	desc = "The Mk60 version adds a pre-installed collimator sight to the Mk59 version, which helps with quick aiming, as well as an easier trigger mechanism."
	icon = 'modular_bluemoon/icons/obj/guns/projectile48x32.dmi'
	icon_state = "mk60"
	w_class = WEIGHT_CLASS_BULKY
	weapon_weight = WEAPON_LIGHT
	spread = 0.5
	fire_delay = 0
	mag_type = /obj/item/ammo_box/magazine/e45
	can_suppress = TRUE
	can_flashlight = 1
	flight_x_offset = 31
	flight_y_offset = 17
	obj_flags = UNIQUE_RENAME
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC)
	burst_size = 1
	automatic_burst_overlay = FALSE

/obj/item/gun/ballistic/automatic/mk60/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"

/obj/item/gun/ballistic/automatic/mk60/nomag
	spawnwithmagazine = FALSE

/obj/item/gun/ballistic/automatic/mk60/mk62
	name = "\improper Mk. 62 Enforcer (.45)"
	desc = "The MK62 version was designed for mecha pilots as a last-ditch weapon. Equipped with a stock, red-dot sight and in-built sec-light, this litll devil is perfect for one-two hand shooting."
	icon_state = "mk62"
	mag_type = /obj/item/ammo_box/magazine/e45
	can_flashlight = 0
	obj_flags = UNIQUE_RENAME
	gunlight_state = "mini-light"

/obj/item/gun/ballistic/automatic/mk60/mk62/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"

/obj/item/gun/ballistic/automatic/mk60/mk62/nomag
	spawnwithmagazine = FALSE

/obj/item/gun/ballistic/automatic/mk60/mk62/Initialize(mapload)
	gun_light = new /obj/item/flashlight/seclite(src)
	return ..()

/obj/item/gun/ballistic/automatic/mk60/vector
	name = "\improper Vector (.45)"
	desc = "Never mass produced, forever remembered. Vector fromb L.G.B.T.- Tactical Arms is one of the most iconic weapons ever created, spending your lead faster that you understand it."
	burst_shot_delay = 1.5
	burst_size = 3
	fire_delay = 2
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	can_flashlight = 1
	weapon_weight = WEAPON_HEAVY
	icon_state = "vector"
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	item_state = "vector"


/obj/item/gun/ballistic/automatic/mk60/vector
	projectile_damage_multiplier = 0.75
