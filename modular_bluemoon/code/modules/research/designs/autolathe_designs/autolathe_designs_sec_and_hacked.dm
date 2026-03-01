///////////////////////////////////
//////////Autolathe Designs ///////
///////////////////////////////////

/////////////
////Secgear//
/////////////

/datum/design/a556_rubber
	name = "Ammo Box (5.56mm rubber)"
	id = "a556_rubber"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 30000)
	build_path = /obj/item/ammo_box/a556/rubber
	category = list("initial", "Security")

/datum/design/a762x39_rubber
	name = "Ammo Box (7.62x39 rubber)"
	id = "a762x39_rubber"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 30000)
	build_path = /obj/item/ammo_box/a762x39/rubber
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
	name = "Ammo Box (5.56mm)"
	id = "a556"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE
	materials = list(/datum/material/iron = 50000)
	build_path = /obj/item/ammo_box/a556
	category = list("hacked", "Security")

/datum/design/a762x39
	name = "Ammo Box (7.62x39)"
	id = "a762x39"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE
	materials = list(/datum/material/iron = 50000)
	build_path = /obj/item/ammo_box/a762x39
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

///////////////// Enforcer /////////////////

/datum/design/e45/empty
	name = "Empty Enforcer magazine"
	id = "c45_empy"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE
	materials = list(/datum/material/iron = 600)
	build_path = /obj/item/ammo_box/magazine/e45/empty
	category = list("hacked", "Security")

///////////////// 5.8x40 mm ammo /////////////////

/datum/design/box_acr5/lethal
	name = "Ammo Box (5.8x40mm)"
	id = "box_acr5"
	build_type = AUTOLATHE | NO_PUBLIC_LATHE
	materials = list(/datum/material/iron = 35000, /datum/material/titanium = 1000)
	build_path = /obj/item/ammo_box/a58mm
	category = list("hacked", "Security")
