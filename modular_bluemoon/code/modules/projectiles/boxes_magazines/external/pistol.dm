// Pistol Magazines

/obj/item/ammo_box/magazine/e45/e45_extended
	name = "Extended Enforcer magazine"
	icon = 'modular_splurt/icons/obj/ammo.dmi'
	icon_state = "enforcer-ext"
	ammo_type = /obj/item/ammo_casing/c45
	caliber = ".45"
	desc = "An extended Mk. 58 magazine."
	max_ammo = 12
	w_class = WEIGHT_CLASS_SMALL

/obj/item/ammo_box/magazine/e45/e45_extended/update_icon()
	..()
	icon_state = "enforcer-ext-[round(ammo_count())]"

/obj/item/ammo_box/magazine/e45/e45_extended/empty
	name = "Extended Enforcer magazine"
	desc = "An extended Mk. 58 magazine."
	start_empty = 1

/obj/item/ammo_box/magazine/e45/e45_drum
	name = "Drum Enforcer magazine (.45 Rubber)"
	icon = 'modular_splurt/icons/obj/ammo.dmi'
	icon_state = "enforcer-drum"
	ammo_type = /obj/item/ammo_casing/c45
	caliber = ".45"
	desc = "A drum Mk. 58 magazine, mostly known for it jams."
	max_ammo = 28
	w_class = WEIGHT_CLASS_NORMAL

/obj/item/ammo_box/magazine/e45/e45_drum/update_icon()
	..()
	icon_state = "enforcer-drum-[round(ammo_count())]"

/obj/item/ammo_box/magazine/e45/e45_drum/empty
	name = "Drum Enforcer magazine"
	desc = "A drum Mk. 58 magazine, mostly known for it jams."
	start_empty = 1

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
