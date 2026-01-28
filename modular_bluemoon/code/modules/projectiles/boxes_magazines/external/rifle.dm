// ACR-5m30 magazines
/obj/item/ammo_box/magazine/acr5m30
	name = "ACR-5 magazine (5.8x40mm)"
	desc = "A standart magazine for ACR rifle."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = "acr58mm"
	ammo_type = /obj/item/ammo_casing/a58mm
	caliber = "5.8x40mm"
	max_ammo = 26

/obj/item/ammo_box/magazine/acr5m30/update_icon_state()
	..()
	icon_state = "[initial(icon_state)]-[ammo_count() ? "30" : "0"]"

/obj/item/ammo_box/magazine/acr5m30/empty
	start_empty = TRUE

/obj/item/ammo_box/magazine/acr5m30/ap
	name = "ACR-5 magazine (AP 5.8x40mm)"
	desc = "A magazine for ACR rifle with armor piercing bullets."
	icon_state = "acr58mm_ap"
	ammo_type = /obj/item/ammo_casing/a58mm/ap

/obj/item/ammo_box/magazine/acr5m30/hp
	name = "ACR-5 magazine (HP 5.8x40mm)"
	desc = "A magazine for ACR rifle with expansive bullets."
	icon_state = "acr58mm_hp"
	ammo_type = /obj/item/ammo_casing/a58mm/hollowpoint

// Admin abuse ammo
/obj/item/ammo_box/magazine/acr5m30/he
	name = "ACR-5 magazine (HE 5.8x40mm)"
	desc = "A magazine for ACR rifle with explosive bullets."
	icon_state = "acr58mm_he"
	ammo_type = /obj/item/ammo_casing/a58mm/he

////////////////////////////////////////////////////////////////////
// M16A4 magazines
/obj/item/ammo_box/magazine/m16
	name = "\improper M16A4 magazine"
	desc = "A double-stack translucent polymer magazine for use with the M16A4 rifles. Holds 30 rounds of 5.56."
	icon = 'modular_bluemoon/phenyamomota/icon/obj/guns/ammo.dmi'
	icon_state = "m16e"
	ammo_type = /obj/item/ammo_casing/a556
	caliber = "a556"
	max_ammo = 30
	multiple_sprites = 2

/obj/item/ammo_box/magazine/m16/ap
	name = "\improper M16A4 armor-piercing magazine"
	desc = "A double-stack translucent polymer magazine for use with the M16A4 rifles. Holds 30 rounds of armor-piercing 5.56."
	ammo_type = /obj/item/ammo_casing/a556/ap

/obj/item/ammo_box/magazine/m16/hp
	name = "\improper M16A4 hollow-point magazine"
	desc = "A double-stack translucent polymer magazine for use with the M16A4 rifles. Holds 30 rounds of hollow-point 5.56."
	ammo_type = /obj/item/ammo_casing/a556/hp

/obj/item/ammo_box/magazine/m16/rubber
	name = "\improper M16A4 rubber magazine"
	desc = "A double-stack translucent polymer magazine for use with the M16A4 rifles. Holds 30 rounds of rubber 5.56."
	ammo_type = /obj/item/ammo_casing/a556/rubber

////////////////////////////////////////////////////////////////////
// AK-47 magazines
/obj/item/ammo_box/magazine/ak47
	name = "\improper AK-47 magazine"
	desc = "a banana-shaped double-stack magazine able to hold 30 rounds of 7.62 ammo."
	icon = 'modular_bluemoon/phenyamomota/icon/obj/guns/ammo.dmi'
	icon_state = "ak47"
	ammo_type = /obj/item/ammo_casing/a762x39
	caliber = "a762x39"
	max_ammo = 30
	multiple_sprites = 2

/obj/item/ammo_box/magazine/ak47/ap
	name = "\improper AK-47 armor-piercing magazine"
	desc = "a banana-shaped double-stack magazine able to hold 30 rounds of armor-piercing 7.62 ammo."
	ammo_type = /obj/item/ammo_casing/a762x39/ap

/obj/item/ammo_box/magazine/ak47/hp
	name = "\improper AK-47 hollow-point magazine"
	desc = "a banana-shaped double-stack magazine able to hold 30 rounds of hollow-point 7.62 ammo."
	ammo_type = /obj/item/ammo_casing/a762x39/hp

/obj/item/ammo_box/magazine/ak47/rubber
	name = "\improper AK-47 rubber magazine"
	desc = "a banana-shaped double-stack magazine able to hold 30 rounds of rubber 7.62 ammo."
	ammo_type = /obj/item/ammo_casing/a762x39/rubber

////////////////////////////////////////////////////////////////////
// .50 sniper magazines

/obj/item/ammo_box/magazine/sniper_rounds/soporific/lewd
	name = "sniper rounds (crocin)"
	desc = "Магазин кроциновых патрон, метрический калибр 12.7 мм. Идеально подходит для тихой и спокойной охоты на сексуальную дичь..."
	icon = 'modular_bluemoon/icons/obj/ammo.dmi'
	icon_state = ".50lewd"
	ammo_type = /obj/item/ammo_casing/p50/lewd
	max_ammo = 3
	caliber = ".50"

////////////////////////////////////////////////////////////////////
