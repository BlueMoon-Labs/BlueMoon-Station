// ACR-5Mm30
/obj/item/gun/ballistic/automatic/acr5m30
	name = "ACR-5m30"
	desc = "A military bullpup rifle, outdated by modern standarts. It is still robust enough to deal with assigned combat tasks."
	icon_state = "acr5"
	item_state = "acr5"
	icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/weapons/guns_righthand.dmi'
	mag_type = /obj/item/ammo_box/magazine/acr5m30
	pin = /obj/item/firing_pin/implant/mindshield
	can_suppress = FALSE
	slot_flags = ITEM_SLOT_BACK
	weapon_weight = WEAPON_HEAVY
	w_class = WEIGHT_CLASS_BULKY
	burst_size = 2
	burst_shot_delay = 1
	fire_delay = 2
	fire_sound = "modular_bluemoon/sound/weapons/acr_fire.ogg"

/obj/item/gun/ballistic/automatic/acr5m30/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/gun/ballistic/automatic/acr5m30/update_icon_state()
	..()
	icon_state = "acr5[magazine ? "-[CEILING(((get_ammo(FALSE) / magazine.max_ammo) * 30) /5, 1)*5]" : ""]"
	item_state = "acr5[magazine ? "" : "e"]"

////////////////////////////////////////////////////////////////////
// M16A4 and variations
/obj/item/gun/ballistic/automatic/m16a4
	name = "\improper M16A4 rifle"
	desc = "A Solar Federation automatic rifle chambered for the 5.56 round, designed for use by SWAT."
	icon = 'modular_bluemoon/phenyamomota/icon/obj/guns/rifles.dmi'
	icon_state = "m16"
	lefthand_file = 'modular_bluemoon/phenyamomota/icon/mob/inhand/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/phenyamomota/icon/mob/inhand/guns_righthand.dmi'
	mob_overlay_icon = 'modular_bluemoon/phenyamomota/icon/mob/rifles_back.dmi'
	item_state = "m16"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	mag_type = /obj/item/ammo_box/magazine/m16
	can_suppress = FALSE
	weapon_weight = WEAPON_HEAVY
	burst_size = 3
	fire_delay = 2
	fire_sound = 'modular_bluemoon/phenyamomota/sound/guns/m16_fire.ogg'

/obj/item/gun/ballistic/automatic/m16a4/update_icon_state()
	if(magazine)
		icon_state = "m16"
	else
		icon_state = "m16-e"

///
/obj/item/gun/ballistic/automatic/m16a4/tactical
	name = "\improper tactical M16A4 rifle"
	desc = "A Solar Federation automatic rifle chambered for the 5.56 round, designed for use by Special Ops."
	icon_state = "m16_tactical"
	burst_size = 3 // EDIT - was "burst_size = 5"
	fire_delay = 2 // EDIT - was "fire_delay = 3"

/obj/item/gun/ballistic/automatic/m16a4/tactical/update_icon_state()
	if(magazine)
		icon_state = "m16_tactical"
	else
		icon_state = "m16_tactical-e"

///
/obj/item/gun/ballistic/automatic/m16a4/stock
	name = "\improper stock M16A4 rifle"
	desc = "A Solar Federation automatic rifle chambered for the 5.56 round, just bought from nearest gun-shop."
	icon_state = "m16_stock"
	burst_size = 3
	fire_delay = 4

/obj/item/gun/ballistic/automatic/m16a4/stock/update_icon_state()
	if(magazine)
		icon_state = "m16_stock"
	else
		icon_state = "m16_stock-e"

////////////////////////////////////////////////////////////////////
// AK-47 and variations
/obj/item/gun/ballistic/automatic/ak47
	name = "\improper AK-47 rifle"
	desc = "A timeless human design of a carbine chambered for the 7.62 ammo. A weapon so simple that even a child could use it - and they often did. Respected by illegal mercenaries."
	icon = 'modular_bluemoon/phenyamomota/icon/obj/guns/rifles.dmi'
	icon_state = "ak47"
	lefthand_file = 'modular_bluemoon/phenyamomota/icon/mob/inhand/guns_lefthand.dmi'
	righthand_file = 'modular_bluemoon/phenyamomota/icon/mob/inhand/guns_righthand.dmi'
	mob_overlay_icon = 'modular_bluemoon/phenyamomota/icon/mob/rifles_back.dmi'
	item_state = "ak47"
	slot_flags = ITEM_SLOT_BELT | ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_BULKY
	mag_type = /obj/item/ammo_box/magazine/ak47
	can_suppress = FALSE
	weapon_weight = WEAPON_HEAVY
	burst_size = 3
	fire_delay = 2
	fire_sound = 'modular_bluemoon/phenyamomota/sound/guns/ak47_fire.ogg'

/obj/item/gun/ballistic/automatic/ak47/update_icon_state()
	if(magazine)
		icon_state = "ak47"
	else
		icon_state = "ak47-e"

/obj/item/gun/ballistic/automatic/ak47/pindicate
	pin = /obj/item/firing_pin/implant/pindicate

///
/obj/item/gun/ballistic/automatic/ak47/akm
	name = "\improper AKM rifle"
	desc = "A timeless human design of a carbine chambered for the 7.62 ammo. Imported from far-far-away frontier spaces."
	icon_state = "akm"

/obj/item/gun/ballistic/automatic/ak47/akm/update_icon_state()
	if(magazine)
		icon_state = "akm"
	else
		icon_state = "akm-e"

///
/obj/item/gun/ballistic/automatic/ak47/homemade
	name = "\improper HomeMade AK-47 rifle"
	desc = "Kalak-12 with zatvornaya zaderjka like M16. Karch not included."
	icon_state = "ak47_hm"
	burst_size = 3
	fire_delay = 5

/obj/item/gun/ballistic/automatic/ak47/homemade/update_icon_state()
	if(magazine)
		icon_state = "ak47_hm"
	else
		icon_state = "ak47_hm-e"

/obj/item/gun/ballistic/automatic/ak47/homemade/pindicate
	pin = /obj/item/firing_pin/implant/pindicate

////////////////////////////////////////////////////////////////////
