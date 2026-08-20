// 5.8x40mm boxes

/obj/item/ammo_box/a58mm
	name = "ammo box (5.8x40mm)"
	desc = "A box full of standart 5.8mm ammo."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "5.8x40mmbox"
	ammo_type = /obj/item/ammo_casing/a58mm
	max_ammo = 30

/obj/item/ammo_box/a58mm/update_icon_state()
	..()
	if(stored_ammo.len < 30)
		icon_state = "[initial(icon_state)]-used"
	if(stored_ammo.len == 0)
		icon_state = "[initial(icon_state)]-empty"

/obj/item/ammo_box/a58mm/ap
	name = "ammo box (Armor Piercing 5.8x40mm)"
	desc = "A box full of armor piercing 5.8mm ammo."
	icon_state = "5.8x40mmbox_ap"
	ammo_type = /obj/item/ammo_casing/a58mm/ap

/obj/item/ammo_box/a58mm/hs
	name = "ammo box (HOTSHOT 5.8x40mm)"
	desc = "A box full of incendiary 5.8mm ammo."
	icon_state = "5.8x40mmbox_hs"
	ammo_type = /obj/item/ammo_casing/a58mm/hotshot

/obj/item/ammo_box/a58mm/hp
	name = "ammo box (Hollow Point 5.8x40mm)"
	desc = "A box full of expansive hollow-pointed 5.8mm ammo."
	icon_state = "5.8x40mmbox_hp"
	ammo_type = /obj/item/ammo_casing/a58mm/hollowpoint

////////////////////////////////////////////////////////////////////
// 5.56mm boxes

/obj/item/ammo_box/a556
	name = "ammo box (5.56mm)"
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "5.56mmbox-l"
	ammo_type = /obj/item/ammo_casing/a556
	max_ammo = 30

/obj/item/ammo_box/a556/rubber
	name = "ammo box (5.56mm rubber)"
	icon_state = "5.56mmbox-rub"
	ammo_type = /obj/item/ammo_casing/a556/rubber
	max_ammo = 30

/obj/item/ammo_box/a556/hp
	name = "ammo box (5.56mm hollow-point)"
	icon_state = "5.56mmbox-l"
	ammo_type = /obj/item/ammo_casing/a556/hp
	max_ammo = 30

/obj/item/ammo_box/a556/ap
	name = "ammo box (5.56mm armor-piercing)"
	icon_state = "5.56mmbox-l"
	ammo_type = /obj/item/ammo_casing/a556/ap
	max_ammo = 30

////////////////////////////////////////////////////////////////////
// 7.62х39mm boxes

/obj/item/ammo_box/a762x39
	name = "ammo box (7.62x39)"
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "7.62x39mmbox-l"
	ammo_type = /obj/item/ammo_casing/a762x39
	max_ammo = 30

/obj/item/ammo_box/a762x39/rubber
	name = "ammo box (7.62x39 rubber)"
	icon_state = "7.62x39mmbox-R"
	ammo_type = /obj/item/ammo_casing/a762x39/rubber
	max_ammo = 30

/obj/item/ammo_box/a762x39/hp
	name = "ammo box (7.62x39 hollow-point)"
	icon_state = "7.62x39mmbox-l"
	ammo_type = /obj/item/ammo_casing/a762x39/hp
	max_ammo = 30

/obj/item/ammo_box/a762x39/ap
	name = "ammo box (7.62x39 armor-piercing)"
	icon_state = "7.62x39mmbox-l"
	ammo_type = /obj/item/ammo_casing/a762x39/ap
	max_ammo = 30

////////////////////////////////////////////////////////////////////
// 9mm boxes.

/obj/item/ammo_box/c9mm
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "9mmbox-l"

/obj/item/ammo_box/c9mm/rubber
	icon_state = "9mmbox-rub"

////////////////////////////////////////////////////////////////////
// 10mm boxes. Custom icon states mainly

/obj/item/ammo_box/c10mm
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "10mmbox"

/obj/item/ammo_box/c10mm/fire
	icon_state = "10mmbox"

/obj/item/ammo_box/c10mm/hp
	icon_state = "10mmbox-hp"

/obj/item/ammo_box/c10mm/ap
	icon_state = "10mmbox-ap"

/obj/item/ammo_box/c10mm/soporific
	icon_state = "10mmbox-softp"

////////////////////////////////////////////////////////////////////
// .45mm boxes

/obj/item/ammo_box/c45
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "45box-rub"

/obj/item/ammo_box/c45/trac
	icon_state = "45box-rub"

////////////////////////////////////////////////////////////////////
// .45mm long boxes

/obj/item/ammo_box/g45l
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "45lbox-r"

/obj/item/ammo_box/g45l/lethal
	icon_state = "45lbox"

////////////////////////////////////////////////////////////////////
// shotgun clips

/obj/item/ammo_box/shotgun/loaded/flechette
	ammo_type = /obj/item/ammo_casing/shotgun/flechette

/obj/item/ammo_box/shotgun/loaded/frangible
	ammo_type = /obj/item/ammo_casing/shotgun/frangible

////////////////////////////////////////////////////////////////////
