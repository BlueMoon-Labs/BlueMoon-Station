///////////////////////////////////
//////////Autolathe Designs ///////
///////////////////////////////////

/////////////
////Secgear//
/////////////

/datum/design/a556_rubber
	name = "Rifle Bullet (5.56mm rubber)"
	id = "a556_rubber"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 1200)
	build_path = /obj/item/ammo_casing/a556/rubber
	category = list("initial", "Security")

/datum/design/a762x39_rubber
	name = "Rifle Bullet (7.62x39 rubber)"
	id = "a762x39_rubber"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 1200)
	build_path = /obj/item/ammo_casing/a762x39/rubber
	category = list("initial", "Security")

/////////////////
///Hacked Gear //
/////////////////

/datum/design/random_contraband
	name = "Contraband Poster"
	id = "random_contraband"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE
	materials = list(/datum/material/iron = 2000, /datum/material/glass = 2000)
	build_path = /obj/item/poster/random_contraband
	category = list("hacked", "Misc")

/////////////////
//   Bullets   //
/////////////////

/datum/design/a556
	name = "Rifle Bullet (5.56mm)"
	id = "a556"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE
	materials = list(/datum/material/iron = 1500)
	build_path = /obj/item/ammo_casing/a556
	category = list("hacked", "Security")

/datum/design/a762x39
	name = "Rifle Bullet (7.62x39)"
	id = "a762x39"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE
	materials = list(/datum/material/iron = 1500)
	build_path = /obj/item/ammo_casing/a762x39
	category = list("hacked", "Security")

/datum/design/a762x38
	name = "Revolver Bullet (7.62x38R)"
	id = "a762x38R"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE
	materials = list(/datum/material/iron = 4000)
	build_path = /obj/item/ammo_casing/n762
	category = list("hacked", "Security")

/datum/design/a762x38
	name = "Revolver Bullet (7.62x38R)"
	id = "a762x38R"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE
	materials = list(/datum/material/iron = 4000)
	build_path = /obj/item/ammo_casing/n762
	category = list("hacked", "Security")

/datum/design/a127x55
	name = "Heavy revolver round (12.7x55mm)"
	id = "a127x55"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE | PROTOLATHE
	materials = list(/datum/material/iron = 4500)
	build_path = /obj/item/ammo_casing/a357/requiem
	category = list("hacked", "Security")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/a127x55_speedloader
	name = "Speed loader (12.7x55mm)"
	id = "a127x55_speedloader"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE | PROTOLATHE
	materials = list(/datum/material/iron = 26000)
	build_path = /obj/item/ammo_box/a357/requiem
	category = list("hacked", "Security")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
