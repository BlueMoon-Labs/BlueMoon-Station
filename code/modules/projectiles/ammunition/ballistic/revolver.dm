// .357 (Syndie Revolver)

/obj/item/ammo_casing/a357
	name = ".357 bullet casing"
	desc = "A .357 bullet casing."
	caliber = "357"
	projectile_type = /obj/item/projectile/bullet/a357
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 1200)

/obj/item/ammo_casing/a357/ap
	name = ".357 armor-piercing bullet casing"
	desc = "A .357 armor-piercing bullet casing."
	projectile_type = /obj/item/projectile/bullet/a357/ap
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 1200, /datum/material/titanium = 600)

/obj/item/ammo_casing/a357/match
	name = ".357 match bullet casing"
	desc = "A .357 bullet casing, manufactured to exceedingly high standards."
	projectile_type = /obj/item/projectile/bullet/a357/match
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 1200, /datum/material/plastic = 600)

/obj/item/ammo_casing/a357/dumdum
	name = ".357 DumDum bullet casing"
	desc = "A .357 bullet casing. Usage of this ammunition will constitute a war crime in your area."
	projectile_type = /obj/item/projectile/bullet/a357/dumdum
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 2400)

/// 12.7x55mm (The Central Requiem) — отдельный калибр, не .357
/obj/item/ammo_casing/a357/requiem
	name = "12.7x55mm bullet casing"
	desc = "A 12.7x55mm heavy revolver cartridge casing, issued for the Requiem."
	caliber = "12.7x55mm"
	projectile_type = /obj/item/projectile/bullet/a357/requiem
	can_be_printed = FALSE

// 7.62x38mmR (Nagant Revolver)

/obj/item/ammo_casing/n762
	name = "7.62x38mmR bullet casing"
	desc = "A 7.62x38mmR bullet casing."
	caliber = "n762"
	projectile_type = /obj/item/projectile/bullet/n762
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 1200)

// .38 (Detective's Gun)

/obj/item/ammo_casing/c38
	name = ".38 rubber bullet casing"
	desc = "A .38 rubber bullet casing."
	caliber = "38"
	projectile_type = /obj/item/projectile/bullet/c38/rubber
	can_be_printed = TRUE
	custom_materials = list(/datum/material/glass = 800)

/obj/item/ammo_casing/c38/lethal
	name = ".38 bullet casing"
	desc = "A .38 bullet casing."
	projectile_type = /obj/item/projectile/bullet/c38
	can_be_printed = TRUE
	custom_materials = list(/datum/material/iron = 800)

/obj/item/ammo_casing/c38/trac
	name = ".38 TRAC bullet casing"
	desc = "A .38 \"TRAC\" bullet casing."
	projectile_type = /obj/item/projectile/bullet/c38/trac
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800, /datum/material/uranium = 200)

/obj/item/ammo_casing/c38/hotshot
	name = ".38 Hot Shot bullet casing"
	desc = "A .38 Hot Shot bullet casing."
	caliber = "38"
	projectile_type = /obj/item/projectile/bullet/c38/hotshot
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800, /datum/material/plasma = 200)

/obj/item/ammo_casing/c38/iceblox
	name = ".38 Iceblox bullet casing"
	desc = "A .38 Iceblox bullet casing."
	caliber = "38"
	projectile_type = /obj/item/projectile/bullet/c38/iceblox
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/glass = 800, /datum/material/plasma = 200)

/obj/item/ammo_casing/c38/match
	name = ".38 Match bullet casing"
	desc = "A .38 bullet casing, manufactured to exceedingly high standards."
	projectile_type = /obj/item/projectile/bullet/c38/match
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800, /datum/material/plastic = 200)

/obj/item/ammo_casing/c38/match/bouncy
	name = ".38 Rubber bullet casing"
	desc = "A .38 rubber bullet casing, manufactured to exceedingly high standards."
	projectile_type = /obj/item/projectile/bullet/c38/match/bouncy
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 800, /datum/material/plastic = 600)

/obj/item/ammo_casing/c38/dumdum
	name = ".38 DumDum bullet casing"
	desc = "A .38 DumDum bullet casing."
	projectile_type = /obj/item/projectile/bullet/c38/dumdum
	can_be_printed = TRUE
	advanced_print_req = TRUE
	custom_materials = list(/datum/material/iron = 1600)

//.45-70 GOVT (Gunslinger's Derringer)

/obj/item/ammo_casing/g4570
	name= ".45-70 Govt bullet casing"
	desc = "An exceedingly rare .45-70 Govt bullet casing."
	caliber = "45-70g"
	projectile_type = /obj/item/projectile/bullet/g4570
	can_be_printed = FALSE
