// Pistol Magazines

/obj/item/ammo_box/magazine/e45/e45_extended
	name = "Extended Enforcer magazine (.45 Rubber)"
	desc = "An extended Mk. 58 magazine."
	icon = 'modular_splurt/icons/obj/ammo.dmi'
	icon_state = "enforcer-ext"
	ammo_type = /obj/item/ammo_casing/c45
	caliber = ".45"
	max_ammo = 12
	w_class = WEIGHT_CLASS_SMALL
	custom_materials = list(/datum/material/iron = 12000)

/obj/item/ammo_box/magazine/e45/e45_extended/update_icon()
	..()
	icon_state = "enforcer-ext-[round(ammo_count())]"

/obj/item/ammo_box/magazine/e45/e45_extended/empty
	name = "Extended Enforcer magazine"
	desc = "An extended Mk. 58 magazine."
	start_empty = 1
	custom_materials = list(/datum/material/iron = 1200)

/obj/item/ammo_box/magazine/e45/e45_extended/lethal
	name = "Extended Enforcer magazine (.45 Lethal)"
	desc = "An extended Mk. 58 magazine. Loaded with lethal rounds."
	ammo_type = /obj/item/ammo_casing/c45/lethal

/obj/item/ammo_box/magazine/e45/e45_extended/hydra
	name = "Extended Enforcer magazine (.45 Hydra)"
	desc = "An extended Mk. 58 magazine. Loaded with Hydra-shock."
	ammo_type = /obj/item/ammo_casing/c45/hydra

/obj/item/ammo_box/magazine/e45/e45_extended/taser
	name = "Extended Enforcer magazine (.45 Taser)"
	desc = "An extended Mk. 58 magazine. Loaded with taser rounds."
	ammo_type = /obj/item/ammo_casing/c45/taser

/obj/item/ammo_box/magazine/e45/e45_extended/trac
	name = "Extended Enforcer magazine (.45 Tracking)"
	desc = "An extended Mk. 58 magazine. Loaded with trac rounds."
	ammo_type = /obj/item/ammo_casing/c45/trac

/obj/item/ammo_box/magazine/e45/e45_extended/hotshot
	name = "Extended Enforcer magazine (.45 Hotshot)"
	desc = "An extended Mk. 58 magazine. Loaded with Hotshot rounds."
	ammo_type = /obj/item/ammo_casing/c45/hotshot

/obj/item/ammo_box/magazine/e45/e45_extended/ion
	name = "Extended Enforcer magazine (.45 Ion)"
	desc = "An extended Mk. 58 magazine. Loaded with Ion rounds."
	ammo_type = /obj/item/ammo_casing/c45/ion

/obj/item/ammo_box/magazine/e45/e45_extended/laser
	name = "Extended Enforcer magazine (.45 Laser)"
	desc = "An extended Mk. 58 magazine. Loaded with Laser rounds."
	ammo_type = /obj/item/ammo_casing/c45/laser

/obj/item/ammo_box/magazine/e45/e45_extended/stun
	name = "Extended Enforcer magazine (.45 Stun)"
	desc = "An extended Mk. 58 magazine. Loaded with Stun rounds."
	ammo_type = /obj/item/ammo_casing/c45/stun

///////////////////// DRUM /////////////////////

/obj/item/ammo_box/magazine/e45/e45_drum
	name = "Drum Enforcer magazine (.45 Rubber)"
	icon = 'modular_splurt/icons/obj/ammo.dmi'
	icon_state = "enforcer-drum"
	ammo_type = /obj/item/ammo_casing/c45
	caliber = ".45"
	desc = "A drum Mk. 58 magazine, mostly known for it jams."
	max_ammo = 28
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/iron = 30000)

/obj/item/ammo_box/magazine/e45/e45_drum/update_icon()
	..()
	icon_state = "enforcer-drum-[round(ammo_count())]"

/obj/item/ammo_box/magazine/e45/e45_drum/empty
	name = "Drum Enforcer magazine"
	desc = "A drum Mk. 58 magazine, mostly known for it jams."
	start_empty = 1
	custom_materials = list(/datum/material/iron = 17000)

/obj/item/ammo_box/magazine/e45/e45_drum/lethal
	name = "Enforcer drum (.45 Lethal)"
	desc = "A Mk. 58 drum. Loaded with lethal rounds."
	ammo_type = /obj/item/ammo_casing/c45/lethal

/obj/item/ammo_box/magazine/e45/e45_drum/hydra
	name = "Enforcer drum (.45 Hydra)"
	desc = "A Mk. 58 drum. Loaded with Hydra-shock."
	ammo_type = /obj/item/ammo_casing/c45/hydra

/obj/item/ammo_box/magazine/e45/e45_drum/taser
	name = "Enforcer drum (.45 Taser)"
	desc = "A Mk. 58 drum. Loaded with taser rounds."
	ammo_type = /obj/item/ammo_casing/c45/taser

/obj/item/ammo_box/magazine/e45/e45_drum/trac
	name = "Enforcer drum (.45 Tracking)"
	desc = "A Mk. 58 drum. Loaded with trac rounds."
	ammo_type = /obj/item/ammo_casing/c45/trac

/obj/item/ammo_box/magazine/e45/e45_drum/hotshot
	name = "Enforcer drum (.45 Hotshot)"
	desc = "A Mk. 58 drum. Loaded with Hotshot rounds."
	ammo_type = /obj/item/ammo_casing/c45/hotshot

/obj/item/ammo_box/magazine/e45/e45_drum/ion
	name = "Enforcer drum (.45 Ion)"
	desc = "A Mk. 58 drum. Loaded with Ion rounds."
	ammo_type = /obj/item/ammo_casing/c45/ion

/obj/item/ammo_box/magazine/e45/e45_drum/laser
	name = "Enforcer drum (.45 Laser)"
	desc = "A Mk. 58 drum. Loaded with Laser rounds."
	ammo_type = /obj/item/ammo_casing/c45/laser

/obj/item/ammo_box/magazine/e45/e45_drum/stun
	name = "Enforcer drum (.45 Stun)"
	desc = "A Mk. 58 drum. Loaded with Stun rounds."
	ammo_type = /obj/item/ammo_casing/c45/stun

///////////////////// DATUM DESIGN /////////////////////

/datum/design/c9mm_box
	name = "Ammo Box (9mm)"
	desc = "A box of ammo containing 30 rounds of nine mil' caliber."
	id = "c9mm_box"
	build_type =  PROTOLATHE
	materials = list(/datum/material/iron = 30000)
	build_path = /obj/item/ammo_box/c9mm
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY | DEPARTMENTAL_FLAG_SCIENCE
