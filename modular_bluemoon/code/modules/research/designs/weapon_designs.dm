//////////////////
//Bulldog design//
//////////////////

/obj/item/disk/design_disk/adv/ammo/bulldog
	name = "Bulldog ammo desine disk"
	desc = "Вставьте в автолат, что бы изготовить магазины для вашего оружия"

/obj/item/disk/design_disk/adv/ammo/bulldog/Initialize(mapload)
	. = ..()
	var/datum/design/ammo_bulldog/B = new
	var/datum/design/ammo_bulldog_slug/S = new
	blueprints[1] = B
	blueprints[2] = S

/datum/design/ammo_bulldog
	name = "shotgun magazine (12g buckshot)"
	desc = "A drum magazine."
	id = "ammo_bulldog"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 20000)
	build_path = /obj/item/ammo_box/magazine/m12g
	category = list("Imported")

/datum/design/ammo_bulldog_slug
	name = "shotgun magazine (12g slugs)"
	desc = "A drum magazine. Now with slug shots"
	id = "ammo_bulldog_slug"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 25000)
	build_path = /obj/item/ammo_box/magazine/m12g/slug
	category = list("Imported")

//////////////////
// M90GL design	//
//////////////////

/obj/item/disk/design_disk/ammo/m90
	name = "M90GL ammo desine disk"
	desc = "Вставьте в автолат, что бы изготовить магазины для вашего оружия"

/obj/item/disk/design_disk/ammo/m90/Initialize(mapload)
	. = ..()
	var/datum/design/ammo_m90/M = new
	blueprints[1] = M

/datum/design/ammo_m90
	name = "toploader magazine (5.56mm)"
	desc = "A toploader magazine containing 30 shots of 5.56 ammo."
	id = "ammo_m90"
	build_type = AUTOLATHE
	materials = list(/datum/material/iron = 25000)
	build_path = /obj/item/ammo_box/magazine/m556
	category = list("Imported")
/*
//////////////////
//ACR5m30 design//
//////////////////

/datum/design/mag_acr5
	name = "ACR-5 Rifle Magazine (5.8mm)"
	desc = "A standart 26 shot magazine for 5.8 mm ACR-5m30 rifle, loaded."
	id = "mag_acr5"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 20000, /datum/material/titanium = 500)
	build_path = /obj/item/ammo_box/magazine/acr5m30
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_RED

/datum/design/mag_acr5/empty
	name = "ACR-5 Rifle Magazine (Empty)"
	desc = "A standart 26 shot magazine for 5.8 mm ACR-5m30 rifle."
	id = "mag_acr5_empty"
	materials = list(/datum/material/iron = 6500)
	build_path = /obj/item/ammo_box/magazine/acr5m30/empty

////////////////// BOXES //////////////////

/datum/design/box_acr5/ap
	name = "Ammo Box (5.8x40mm Armour Piercing)"
	desc = "A box of 5.8x40 mm  armour piercing titanium bullets. 30 cartridges total."
	id = "box_acr5_ap"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 35000, /datum/material/titanium = 1750, /datum/material/silver = 500)
	build_path = /obj/item/ammo_box/a58mm/ap
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/box_acr5/hp
	name = "Ammo Box (5.8x40mm Hollow Pointed)"
	desc = "A box of 5.8x40 mm expancive hollow pointed ammo. 30 cartridges total."
	id = "box_acr5_hp"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 24000, /datum/material/silver = 1500)
	build_path = /obj/item/ammo_box/a58mm/hp
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/box_acr5/hs
	name = "Ammo Box (5.8x40mm HOTSHOT)"
	desc = "A box of 5.8x40 mm incendiary plasma-phosphorus ammo. 30 cartridges total."
	id = "box_acr5_hs"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 20000, /datum/material/plasma = 1500)
	build_path = /obj/item/ammo_box/a58mm/hs
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
*/

////////////////////////
//Enforcer ext design///
////////////////////////

/datum/design/e45_extended
	name = "Extended Enforcer magazine (.45 Rubber)"
	id = "c45_ext"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 17000)
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_GREEN

/datum/design/e45_extended/empty
	name = "Extended Enforcer magazine (Empty)"
	id = "c45_ext_empty"
	materials = list(/datum/material/iron = 1200)
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended/empty

/datum/design/e45_extended/taser
	name = "Extended Enforcer magazine (.45 Taser)"
	id = "c45_ext_taser"
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended/taser

/datum/design/e45_extended/stun
	name = "Extended Enforcer magazine (.45 Stun)"
	id = "c45_ext_stun"
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended/stun
	materials = list(/datum/material/iron = 17000, /datum/material/uranium = 800)

/datum/design/e45_extended/ion
	name = "Extended Enforcer magazine (.45 Ion)"
	id = "c45_ext_ion"
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended/ion
	materials = list(/datum/material/iron = 17000, /datum/material/uranium = 800)

/datum/design/e45_extended/tracking
	name = "Extended Enforcer magazine (.45 Tracking)"
	id = "c45_ext_tracking"
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended/trac
	min_security_level = SEC_LEVEL_BLUE

/datum/design/e45_extended/lethal
	name = "Extended Enforcer magazine (.45 Lethal)"
	id = "c45_ext_lethal"
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended/lethal
	min_security_level = SEC_LEVEL_BLUE

/datum/design/e45_extended/lethal/hotshot
	name = "Extended Enforcer magazine (.45 Hotshot)"
	id = "c45_ext_hotshot"
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended/hotshot

/datum/design/e45_extended/lethal/hydra
	name = "Extended Enforcer magazine (.45 Hydra)"
	id = "c45_ext_hydra"
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended/hydra

/datum/design/e45_extended/lethal/laser
	name = "Extended Enforcer magazine (.45 Laser)"
	id = "c45_ext_laser"
	build_path = /obj/item/ammo_box/magazine/e45/e45_extended/laser
	materials = list(/datum/material/iron = 17000, /datum/material/uranium = 800)

////////////////////////
//Enforcer drum design//
////////////////////////

/datum/design/e45_drum
	name = "Drum Enforcer magazine (.45 Rubber)"
	desc = "A drum mag of .45 rubber for the Mk. 58 Enforcer"
	id = "e45_drum"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 35000)
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum
	category = list("Ammo")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_BLUE

/datum/design/e45_drum/empty
	name = "Drum Enforcer magazine (Empty)"
	desc = "A drum Mk. 58 magazine, mostly known for it jams."
	id = "e45_drum_empty"
	materials = list(/datum/material/iron = 20000)
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum/empty

/datum/design/e45_drum/lethal
	name = "Drum Enforcer magazine (.45 Lethal)"
	desc = "A drum mag of .45 Lethal for the Mk. 58 Enforcer"
	id = "e45_drum_lethal"
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum/lethal

/datum/design/e45_drum/taser
	name = "Drum Enforcer magazine (.45 Taser)"
	desc = "A drum mag of .45 Taser for the Mk. 58 Enforcer"
	id = "e45_drum_taser"
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum/taser

/datum/design/e45_drum/trac
	name = "Drum Enforcer magazine (.45 Tracking)"
	desc = "A drum mag of .45 Tracking for the Mk. 58 Enforcer"
	id = "e45_drum_trac"
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum/trac

/datum/design/e45_drum/hotshot
	name = "Drum Enforcer magazine (.45 Hotshot)"
	desc = "A drum mag of .45 Hotshot for the Mk. 58 Enforcer"
	id = "e45_drum_hot"
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum/hotshot

/datum/design/e45_drum/hydra
	name = "Drum Enforcer magazine (.45 Hydra)"
	desc = "A drum mag of .45 Hydra-Shock for the Mk. 58 Enforcer"
	id = "e45_drum_hydra"
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum/hydra

/datum/design/e45_drum/ion
	name = "Drum Enforcer magazine (.45 Ion)"
	desc = "A drum mag of .45 Ion for the Mk. 58 Enforcer"
	id = "e45_drum_ion"
	materials = list(/datum/material/iron = 35000, /datum/material/uranium = 1650)
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum/ion

/datum/design/e45_drum/e45stun
	name = "Drum Enforcer magazine (.45 Stun)"
	desc = "A drum mag of .45 Stun for the Mk. 58 Enforcer"
	id = "e45_drum_stun"
	materials = list(/datum/material/iron = 35000, /datum/material/uranium = 1650)
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum/stun

/datum/design/e45_drum/laser
	name = "Drum Enforcer magazine (.45 Laser)"
	desc = "A drum mag of .45 Laser for the Mk. 58 Enforcer"
	id = "e45_drum_laser"
	materials = list(/datum/material/iron = 35000, /datum/material/uranium = 1650)
	build_path = /obj/item/ammo_box/magazine/e45/e45_drum/laser

/////////////////////////////
//Enforcer MK59-MK62 design//
/////////////////////////////

// /datum/design/mk59
//	name = "Enfrocer MK59 upgrade kit"
//	desc = "A set of spare parts for upgrading the enforcer pistol to the MK59 version. Can be used only on empty gun"
//	id = "mk59"
//	build_type = PROTOLATHE
//	materials = list(/datum/material/iron = 5000, /datum/material/plastic = 1500)
//	build_path = /obj/item/weaponcrafting/gunkit/mk59
//	category = list("Weapons")
//	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
//	min_security_level = SEC_LEVEL_BLUE

/datum/design/mk60
	name = "Enfrocer MK60 upgrade kit"
	desc = "A set of spare parts for upgrading the enforcer pistol to the MK60 version. Can be used only on empty gun"
	id = "mk60"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 7500, /datum/material/uranium = 2500, /datum/material/plastic = 1500)
	build_path = /obj/item/weaponcrafting/gunkit/mk60
	category = list("Weapons")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_BLUE

/datum/design/mk62
	name = "Enfrocer MK62 upgrade kit"
	desc = "A set of spare parts for upgrading the MK60 pistol to the MK62 version. Can be used only on empty gun"
	id = "mk62"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 7500, /datum/material/gold = 1500, /datum/material/titanium = 1000 )
	build_path = /obj/item/weaponcrafting/gunkit/mk62
	category = list("Weapons")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_BLUE

/datum/design/vector

	name = "Vector SMG convetion kit"
	desc = "A set of spare parts for upgrading the MK60 pistol to the Vector SMG. Can be used only on empty gun"
	id = "vector"
	build_type = PROTOLATHE
	materials = list(/datum/material/iron = 7500, /datum/material/silver = 3500, /datum/material/titanium = 2000 )
	build_path = /obj/item/weaponcrafting/gunkit/vector
	category = list("Weapons")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY
	min_security_level = SEC_LEVEL_AMBER
