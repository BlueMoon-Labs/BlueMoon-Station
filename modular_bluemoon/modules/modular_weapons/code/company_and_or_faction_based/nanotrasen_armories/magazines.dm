/obj/item/ammo_box/magazine/katyusha/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]-[stored_ammo.len ? "full" : "empty"]"

/obj/item/ammo_box/magazine/katyusha/empty
	icon_state = "spikewall_mag-empty"
	start_empty = TRUE
	custom_materials = list(/datum/material/iron = SHEET_MATERIAL_AMOUNT * 2)

/obj/item/ammo_box/magazine/katyusha
	name = "\improper Katyusha Drum Magazine"
	desc = "A drum magazine of shotgun shells, suitable for the Katyusha combat shotgun."
	icon = 'modular_bluemoon/modules/modular_weapons/icons/obj/company_and_or_faction_based/nanotrasen_armories/magazines.dmi'
	icon_state = "spikewall_mag"
	base_icon_state = "spikewall_mag"
	ammo_type = /obj/item/ammo_casing/shotgun
	caliber = "shotgun"
	max_ammo = 10

/obj/item/ammo_box/magazine/katyusha/buckshot
	ammo_type = /obj/item/ammo_casing/shotgun/buckshot

/obj/item/ammo_box/magazine/jager/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]-[stored_ammo.len ? "full" : "empty"]"

/obj/item/ammo_box/magazine/jager/empty
	icon_state = "jager_mag-empty"
	start_empty = TRUE

/obj/item/ammo_box/magazine/jager
	name = "\improper jager Magazine"
	desc = "A magazine of shotgun shells, suitable for the 'jager' combat shotgun."
	icon = 'modular_bluemoon/modules/modular_weapons/icons/obj/company_and_or_faction_based/nanotrasen_armories/magazines.dmi'
	icon_state = "jager_mag"
	base_icon_state = "jager_mag"
	ammo_type = /obj/item/ammo_casing/shotgun
	caliber = "shotgun"
	max_ammo = 4

/obj/item/ammo_box/magazine/jager/rubbershot
	ammo_type = /obj/item/ammo_casing/shotgun/rubbershot

/* /obj/item/ammo_box/magazine/jager/large
	name = "large jager Magazine"
	desc = "A magazine of shotgun shells, suitable for the 'jager' combat shotgun."
	icon_state = "jager_mag_large"
	base_icon_state = "jager_mag_large"
	max_ammo = 7

/obj/item/ammo_box/magazine/jager/large/empty
	icon_state = "jager_mag_large-empty"
	start_empty = TRUE */ // станция пока не готова к расширенным магазинам на ягера
