/obj/item/ammo_box/magazine/toy
	name = "foam force META magazine"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart
	caliber = "foam_force"

/obj/item/ammo_box/magazine/toy/sniper_rounds
	name = "donksoft Sniper magazine"
	icon_state = ".50mag"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/sniper/riot
	max_ammo = 6
	caliber = "foam_force_sniper"

/obj/item/ammo_box/magazine/toy/smg
	name = "foam force SMG magazine"
	icon_state = "smg9mm-42"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart
	max_ammo = 20

/obj/item/ammo_box/magazine/toy/smg/update_icon()
	..()
	if(ammo_count())
		icon_state = "smg9mm-42"
	else
		icon_state = "smg9mm-0"

/obj/item/ammo_box/magazine/toy/smg/riot
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/riot

/obj/item/ammo_box/magazine/toy/pistol
	name = "foam force pistol magazine"
	icon_state = "9x19p"
	max_ammo = 8
	multiple_sprites = 2

/obj/item/ammo_box/magazine/toy/pistol/update_icon_state()
	. = ..()
	icon_state = "[initial(icon_state)]-[stored_ammo.len ? "16" : "0"]"

/obj/item/ammo_box/magazine/toy/pistol/riot
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/riot

/obj/item/ammo_box/magazine/toy/enforcer
	name = "foam enforcer magazine"
	icon_state = "enforcer"
	max_ammo = 8
	multiple_sprites = 1
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/riot

/obj/item/ammo_box/magazine/toy/enforcer/update_icon()
	..()
	overlays.Cut()

	var/ammo = ammo_count()
	if(ammo && is_riot())
		overlays += image('icons/obj/guns/ammo.dmi', icon_state = "enforcer-rd")
	else if(ammo)
		overlays += image('icons/obj/guns/ammo.dmi', icon_state = "enforcer-bd")

/obj/item/ammo_box/magazine/toy/enforcer/proc/is_riot()//if the topmost bullet is a riot dart
	var/ammo = ammo_count()
	if(!ammo)
		return 0
	if(istype(contents[contents.len], /obj/item/ammo_casing/caseless/foam_dart/riot))
		return 1
	return 0

/obj/item/ammo_box/magazine/toy/smgm45
	name = "donksoft SMG magazine"
	icon_state = "c20r45-toy"
	caliber = "foam_force"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart
	max_ammo = 20

/obj/item/ammo_box/magazine/toy/smgm45/update_icon()
	..()
	icon_state = "c20r45-[round(ammo_count(),2)]"

/obj/item/ammo_box/magazine/toy/smgm45/riot
	icon_state = "c20r45-riot"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/riot

/obj/item/ammo_box/magazine/toy/m762
	name = "donksoft box magazine"
	icon_state = "a762-toy"
	caliber = "foam_force"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart
	max_ammo = 50

/obj/item/ammo_box/magazine/toy/m762/update_icon()
	..()
	icon_state = "a762-[round(ammo_count(),10)]"

/obj/item/ammo_box/magazine/toy/m762/riot
	icon_state = "a762-riot"
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/riot

/obj/item/ammo_box/magazine/toy/foamag
	name = "foam force magrifle magazine"
	icon_state = "foamagmag"
	max_ammo = 24
	multiple_sprites = 2
	ammo_type = /obj/item/ammo_casing/caseless/foam_dart/mag
	custom_materials = list(/datum/material/iron = 200)
