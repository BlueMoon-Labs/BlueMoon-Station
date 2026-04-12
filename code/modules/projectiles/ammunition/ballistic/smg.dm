// 4.6x30mm (Autorifles)

/obj/item/ammo_casing/c46x30mm
	name = "4.6x30mm bullet casing"
	desc = "A 4.6x30mm bullet casing."
	caliber = "4.6x30mm"
	projectile_type = /obj/item/projectile/bullet/c46x30mm

/obj/item/ammo_casing/c46x30mm/ap
	name = "4.6x30mm armor-piercing bullet casing"
	desc = "A 4.6x30mm armor-piercing bullet casing."
	projectile_type = /obj/item/projectile/bullet/c46x30mm_ap

/obj/item/ammo_casing/c46x30mm/inc
	name = "4.6x30mm incendiary bullet casing"
	desc = "A 4.6x30mm incendiary bullet casing."
	projectile_type = /obj/item/projectile/bullet/incendiary/c46x30mm

// .45 (M1911 + C20r)

/obj/item/ammo_casing/c45
	name = ".45 bullet rubber casing" // BLUEMOON CHANGE adding "rubber" to name
	desc = "A .45 bullet casing."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi' // BLUEMOON ADD custom states
	icon_state = "casing-universal" // BLUEMOON ADD custom states
	caliber = ".45"
	projectile_type = /obj/item/projectile/bullet/c45

/obj/item/ammo_casing/c45/kitchengun
	desc = "A .45 bullet casing. It has a small sponge attached to it."
	projectile_type = /obj/item/projectile/bullet/c45_cleaning

/obj/item/ammo_casing/c45/kitchengun/inteq
	desc = "A .45 bullet casing. It has a small InteQ logo attached to it."
	projectile_type = /obj/item/projectile/bullet/c45_cleaning
