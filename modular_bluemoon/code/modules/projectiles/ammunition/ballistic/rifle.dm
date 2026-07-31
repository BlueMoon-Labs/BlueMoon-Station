// 5.8mm (ACR-5m30 Rifle)

/obj/item/ammo_casing/a58mm
	name = "5.8mm bullet casing"
	desc = "A 5.8mm bullet casing."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "5.8x40mm"
	caliber = "5.8x40mm"
	projectile_type = /obj/item/projectile/bullet/a58
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 400)

/obj/item/ammo_casing/a58mm/ap
	name = "5.8mm AP bullet casing"
	desc = "A 5.8mm bullet casing with white band."
	icon_state = "5.8x40mm_ap"
	projectile_type = /obj/item/projectile/bullet/a58/ap
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 400, /datum/material/titanium = 200)

/obj/item/ammo_casing/a58mm/hotshot
	name = "5.8mm HS bullet casing"
	desc = "A 5.8mm bullet casing with red band."
	icon_state = "5.8x40mm_hs"
	projectile_type = /obj/item/projectile/bullet/incendiary/a58
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 400, /datum/material/plasma = 200)

/obj/item/ammo_casing/a58mm/hollowpoint
	name = "5.8mm HP bullet casing"
	desc = "A 5.8mm bullet casing with \"cutted\" tip."
	icon_state = "5.8x40mm_hp"
	projectile_type = /obj/item/projectile/bullet/a58/hp
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 600)

// admin use only really
/obj/item/ammo_casing/a58mm/he
	name = "5.8mm HE bullet casing"
	desc = "A 5.8mm bullet casing with... Purple band."
	icon_state = "5.8x40mm_he"
	projectile_type = /obj/item/projectile/bullet/a58/he
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 4000, /datum/material/bananium = 1000) // пусть попробуют найти винтовку под этот калибр

////////////////////////////////////////////////////////////////////
// 5.56mm

/obj/item/ammo_casing/a556
	name = "5.56mm bullet casing"
	desc = "A 5.56mm bullet casing."
	caliber = "a556"
	projectile_type = /obj/item/projectile/bullet/a556
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 400)

/obj/item/ammo_casing/a556/rubber
	name = "5.56mm rubber bullet casing"
	desc = "A 5.56mm rubber bullet casing."
	projectile_type = /obj/item/projectile/bullet/a556_rubber
	can_be_printed = TRUE
	advanced_print_req = FALSE
	custom_materials = list(/datum/material/glass = 400)

/obj/item/ammo_casing/a556/hp
	name = "5.56mm hollow-point bullet casing"
	desc = "A 5.56mm hollow-point bullet casing."
	projectile_type = /obj/item/projectile/bullet/a556_hp
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800)


/obj/item/ammo_casing/a556/ap
	name = "5.56mm armor-piercing bullet casing"
	desc = "A 5.56mm armor-piercing bullet casing."
	projectile_type = /obj/item/projectile/bullet/a556_ap
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 400, /datum/material/titanium = 200)

////////////////////////////////////////////////////////////////////
// 7.62x39mm

/obj/item/ammo_casing/a762x39
	name = "7.62x39 bullet casing"
	desc = "A 7.62x39 bullet casing."
	icon_state = "762-casing"
	caliber = "a762x39"
	projectile_type = /obj/item/projectile/bullet/a762x39
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800)

/obj/item/ammo_casing/a762x39/rubber
	name = "7.62x39 rubber bullet casing"
	desc = "A 7.62x39 rubber bullet casing."
	projectile_type = /obj/item/projectile/bullet/a762x39_rubber
	can_be_printed = TRUE
	advanced_print_req = FALSE
	custom_materials = list(/datum/material/glass = 800)

/obj/item/ammo_casing/a762x39/hp
	name = "7.62x39 hollow-point bullet casing"
	desc = "A 7.62x39 hollow-point bullet casing."
	projectile_type = /obj/item/projectile/bullet/a762x39_hp
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 1200)

/obj/item/ammo_casing/a762x39/ap
	name = "7.62x39 armor-piercing bullet casing"
	desc = "A 7.62x39 armor-piercing bullet casing."
	projectile_type = /obj/item/projectile/bullet/a762x39_ap
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800, /datum/material/titanium = 400)
