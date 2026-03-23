/obj/item/gun/ballistic/automatic/pistol/m1911
	icon = 'modular_splurt/icons/obj/guns/projectile.dmi'
	can_flashlight = 1
	flight_x_offset = 19
	flight_y_offset = 15

/obj/item/gun/ballistic/automatic/pistol/m1911/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"


/obj/item/gun/ballistic/automatic/pistol/enforcer
	name = "\improper Mk. 58 Enforcer (.45)"
	desc = "A polymer frame pistol made by Nanotreason. Won't show up on Space port X-rays and cost more then you make in a month."
	icon = 'modular_splurt/icons/obj/guns/projectile.dmi'
	icon_state = "enforcer_black"
	w_class = WEIGHT_CLASS_NORMAL
	mag_type = /obj/item/ammo_box/magazine/e45
	can_suppress = TRUE
	can_flashlight = 1
	flight_x_offset = 17
	flight_y_offset = 17
	obj_flags = UNIQUE_RENAME
	unique_reskin = list(
		"Default" = list("icon_state" = "enforcer_black"),
		"VP78 Enforcer" = list("icon_state" = "vp78"),
		"USP Enforcer" = list("icon_state" = "usp-m")
	)

/obj/item/gun/ballistic/automatic/pistol/enforcer/update_icon_state() //BLUEMOOD EDIT: Визуально добавлены статусы оружия при наличии глушителя и расширенного магазина
	if(current_skin)
		icon_state = "[unique_reskin[current_skin]["icon_state"]][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"
	else
		icon_state = "[initial(icon_state)][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"

/obj/item/gun/ballistic/automatic/pistol/enforcer/nomag
	pin = /obj/item/firing_pin/alert_level/blue
	spawnwithmagazine = FALSE

/obj/item/gun/ballistic/automatic/pistol/enforcerred
	name = "\improper Blueshield Mk. 58 Enforcer (.45)"
	desc = "A polymer frame pistol made by Nanotreason. Won't show up on Space port X-rays and cost more then you make in a month. Respect mah Authorita!"
	icon = 'modular_splurt/icons/obj/guns/projectile.dmi'
	icon_state = "enforcer_blue"
	w_class = WEIGHT_CLASS_NORMAL
	mag_type = /obj/item/ammo_box/magazine/e45
	can_suppress = TRUE
	burst_shot_delay = 2
	burst_size = 2
	fire_delay = 2.5
	fire_select_modes = list(SELECT_SEMI_AUTOMATIC, SELECT_BURST_SHOT, SELECT_FULLY_AUTOMATIC)
	automatic_burst_overlay = TRUE
	can_flashlight = 1
	flight_x_offset = 16
	flight_y_offset = 17
	unique_reskin = list(
		"Blue Shield" = list("icon_state" = "enforcer_blue"),
		"Red Shield" = list("icon_state" = "enforcer_red")
	)
	pin = /obj/item/firing_pin/alert_level/blue

/obj/item/gun/ballistic/automatic/pistol/enforcerred/update_icon_state() //BLUEMOOD EDIT: Визуально добавлены статусы оружия при наличии глушителя и расширенного магазина
	if(current_skin)
		icon_state = "[unique_reskin[current_skin]["icon_state"]][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"
	else
		icon_state = "[initial(icon_state)][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"


/obj/item/gun/ballistic/automatic/pistol/enforcergold
	name = "\improper Gold Mk. 58 Enforcer (.45)"
	desc = "A titianium gold plated Enforcer. A vulger display of power. A show of force in a public execution."
	icon = 'modular_splurt/icons/obj/guns/projectile.dmi'
	icon_state = "enforcer_gold"
	w_class = WEIGHT_CLASS_NORMAL
	mag_type = /obj/item/ammo_box/magazine/e45
	can_suppress = TRUE
	can_flashlight = 1
	flight_x_offset = 17
	flight_y_offset = 17

/obj/item/gun/ballistic/automatic/pistol/enforcergold/update_icon_state() //BLUEMOOD EDIT: Визуально добавлены статусы оружия при наличии глушителя и расширенного магазина
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"][suppressed ? "-suppressed" : "" ][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_extended) ? "-expended" : ""][magazine && istype(magazine, /obj/item/ammo_box/magazine/e45/e45_drum) ? "-drum" : ""]"

/obj/item/gun/ballistic/automatic/pistol/m9mmpistol
	name = "\improper Cheap 9mm Handgun"
	desc = "An extremly cheap 9mm handgun produced by M&A Firearms."
	icon = 'modular_splurt/icons/obj/guns/projectile.dmi'
	icon_state = "ninemil"
	w_class = WEIGHT_CLASS_NORMAL
	mag_type = /obj/item/ammo_box/magazine/m9
	can_suppress = FALSE
	obj_flags = UNIQUE_RENAME
	unique_reskin = list(
		"Default" = list("icon_state" = "ninemil"),
		"Maria" = list("icon_state" = "maria")
	)

/obj/item/gun/ballistic/automatic/pistol/m9mmpistol/update_icon_state()
	if(current_skin)
		icon_state = "[unique_reskin[current_skin]["icon_state"]][chambered ? "" : "-e"]"
	else
		icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"

/obj/item/gun/ballistic/automatic/pistol/m9mmpistol/nomag
	spawnwithmagazine = FALSE

/obj/item/gun/ballistic/automatic/pistol/m22pistol
	name = "\improper Cheap .22 Handgun"
	desc = "An extremly cheap .22 handgun produced by a Martain weapons maker. Great for mouse hunting, not much else."
	icon = 'modular_splurt/icons/obj/guns/projectile.dmi'
	icon_state = "silenced22"
	w_class = WEIGHT_CLASS_NORMAL
	mag_type = /obj/item/ammo_box/magazine/m22
	can_suppress = FALSE

/obj/item/gun/ballistic/automatic/pistol/m22pistol/update_icon_state()
	icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"


/obj/item/gun/ballistic/automatic/pistol/deagle
	name = "\improper Desert Eagle (.50 AE)"


/obj/item/gun/ballistic/automatic/pistol/deagle2
	name = "\improper Desert Eagle (.357)"
	desc = "A robust .357 Magnum handgun."
	icon_state = "deagle"
	force = 14
	mag_type = /obj/item/ammo_box/magazine/m357
	can_suppress = FALSE
	automatic_burst_overlay = FALSE
	fire_sound = 'modular_bluemoon/kovac_shitcode/sound/weapons/deagle.ogg'
	obj_flags = UNIQUE_RENAME
	unique_reskin = list(
		"Default" = list("icon_state" = "deagle"),
		"Desert Eagle Gold" = list("icon_state" = "deagleg"),
		"Desert Eagle Camo" = list("icon_state" = "deaglecamo")
	)

/obj/item/gun/ballistic/automatic/pistol/deagle2/update_overlays()
	. = ..()
	if(magazine)
		. += "deagle_magazine"

/obj/item/gun/ballistic/automatic/pistol/deagle2/update_icon_state()
	if(current_skin)
		icon_state = "[unique_reskin[current_skin]["icon_state"]][chambered ? "" : "-e"]"
	else
		icon_state = "[initial(icon_state)][chambered ? "" : "-e"]"

/obj/item/gun/ballistic/automatic/pistol/deagle2/nomag
	spawnwithmagazine = FALSE

/obj/item/gun/ballistic/automatic/pistol/luger/mag
	spawnwithmagazine = TRUE

//gun parts

/obj/item/gunpart //the parent
	name = "generic gun part"
	icon_state = "shotstock"
	icon = 'modular_splurt/icons/obj/items_and_weapons.dmi'
	item_state = "assembly"
	lefthand_file = 'icons/mob/inhands/weapons/swords_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/weapons/swords_righthand.dmi'
	desc = "generic gun part is generic."
	force = 3
	w_class = WEIGHT_CLASS_NORMAL
	throwforce = 5
	throw_speed = 3
	throw_range = 6
	hitsound = 'sound/weapons/genhit.ogg'
	attack_verb = list("stubbed", "poked")
	resistance_flags = NONE

/obj/item/gunpart/pistol22frame
	name = ".22 pistol frame"
	desc = "a .22 pistol frame"
	icon_state = "silenced22frame"

/obj/item/gunpart/pistol22barrel
	name = ".22 pistol barrel"
	desc = "a .22 pistol barrel"
	icon_state = "silenced22barrel"

/obj/item/gunpart/pistol22bolt
	name = ".22 pistol bolt"
	desc = "a .22 pistol bolt"
	icon_state = "silenced22bolt"

/obj/item/gunpart/pistol9frame
	name = "9mm pistol frame"
	desc = "a 9mm pistol frame"
	icon_state = "ninemilframe"

/obj/item/gunpart/pistol9slide
	name = "9mm pistol slide"
	desc = "a 9mm pistol slide and barrel"
	icon_state = "ninemilslide"

/datum/crafting_recipe/pistol22assemble
	name = "Assemble .22 Pistol"
	result = /obj/item/gun/ballistic/automatic/pistol/m22pistol
	reqs = list(/obj/item/gunpart/pistol22frame = 1,
				/obj/item/gunpart/pistol22barrel = 1,
				/obj/item/gunpart/pistol22bolt = 1)
	tools = list(TOOL_SCREWDRIVER)
	time = 50
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON

/datum/crafting_recipe/pistol9assemble
	name = "Assemble 9mm Pistol"
	result = /obj/item/gun/ballistic/automatic/pistol/m9mmpistol/nomag
	reqs = list(/obj/item/gunpart/pistol9frame = 1,
				/obj/item/gunpart/pistol9slide = 1)
	tools = list(TOOL_SCREWDRIVER)
	time = 50
	category = CAT_WEAPONRY
	subcategory = CAT_WEAPON
