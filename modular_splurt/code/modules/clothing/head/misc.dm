// This icon fixes blue-ish tint on the helmet
/obj/item/clothing/head/assu_helmet
	icon = 'modular_splurt/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'

/obj/item/clothing/head/jester
	unique_reskin = list(
		"Original" = list(
			"icon_state" = "jester_hat",
			"icon" = 'icons/obj/clothing/hats.dmi',
			"mob_overlay_icon" = null,
		),
		"Stripped" = list(
			"icon_state" = "striped_jester_hat",
			"icon" = 'modular_splurt/icons/obj/clothing/head.dmi',
			"mob_overlay_icon" = 'modular_splurt/icons/mob/clothing/head.dmi',
		)
	)

/obj/item/clothing/head/bridgeofficer
	name = "bridge officer cap"
	desc = "A generic blue cap for the back ground officer"
	icon_state = "bridgeseccap"
	item_state = "bridgeseccap"
	icon = 'modular_splurt/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0, "energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 0, "acid" = 0)
	strip_delay = 25
	dynamic_hair_suffix = ""
	dog_fashion = null

/obj/item/clothing/head/bridgeofficer/beret
	name = "bridge officer beret"
	desc = "A generic blue beret for the back ground officer"
	icon_state = "beret_bridgesec"
	item_state = "beret_bridgesec"
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'

/obj/item/clothing/head/press_helmet
	name = "press helmet"
	icon_state = "press_helmet"
	item_state = "press_helmet"
	desc = "A lightweight helmet for reporting on security. You swear up and down it is made of Kevlar and not old cloth and plastic."
	icon = 'modular_splurt/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	flags_inv = HIDEHAIR
	armor = list(MELEE = 40, BULLET = 30, LASER = 30,ENERGY = 10, BOMB = 25, BIO = 0, RAD = 0, FIRE = 50, ACID = 50)

//CBRN/MOPP helmets

/obj/item/clothing/head/helmet/cbrn
	name = "CBRN hood Civilian"
	desc = "Chemical, Biological, Radiological and Nuclear. A hood design for harsh environmental conditions short of no atmosphere"
	icon_state = "cbrnhoodciv"
	item_state = "cbrnhoodciv"
	icon = 'modular_splurt/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	armor = list("melee" = 5, "bullet" = 0, "laser" = 5,"energy" = 5, "bomb" = 0, "bio" = 100, "rad" = 100, "fire" = 40, "acid" = 100)
	w_class = WEIGHT_CLASS_NORMAL
	gas_transfer_coefficient = 0.5
	permeability_coefficient = 0.5
	strip_delay = 60
	equip_delay_other = 60
	body_parts_covered = HEAD
	clothing_flags = THICKMATERIAL
	flags_inv = HIDEHAIR|HIDEEARS
	resistance_flags = ACID_PROOF
	rad_flags = RAD_PROTECT_CONTENTS | RAD_NO_CONTAMINATE
	is_edible = 0

/obj/item/clothing/head/helmet/cbrn/serv
	name = "CBRN hood Service"
	icon_state = "cbrnhoodserv"
	item_state = "cbrnhoodserv"

/obj/item/clothing/head/helmet/cbrn/eng
	name = "CBRN hood Engineer"
	icon_state = "cbrnhoodeng"
	item_state = "cbrnhoodeng"
	max_heat_protection_temperature = FIRE_SUIT_MAX_TEMP_PROTECT
	resistance_flags = FIRE_PROOF
	armor = list("melee" = 5, "bullet" = 0, "laser" = 5,"energy" = 5, "bomb" = 0, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 100)
	desc = "Chemical, Biological, Radiological and Nuclear. A hood design for harsh environmental conditions short of no atmosphere and for engineer squads fireproof."

/obj/item/clothing/head/helmet/cbrn/sec
	name = "CBRN hood Security"
	icon_state = "cbrnhoodsec"
	item_state = "cbrnhoodsec"
	armor = list("melee" = 20, "bullet" = 20, "laser" = 20,"energy" = 10, "bomb" = 0, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 100)
	desc = "Chemical, Biological, Radiological and Nuclear. A hood design for harsh environmental conditions short of no atmosphere and for security squads was armor padded."

/obj/item/clothing/head/helmet/cbrn/med
	name = "CBRN hood Medical"
	icon_state = "cbrnhoodmed"
	item_state = "cbrnhoodmed"

/obj/item/clothing/head/helmet/cbrn/sci
	name = "CBRN hood Science"
	icon_state = "cbrnhoodsci"
	item_state = "cbrnhoodsci"
	armor = list("melee" = 5, "bullet" = 0, "laser" = 5,"energy" = 5, "bomb" = 20, "bio" = 100, "rad" = 100, "fire" = 40, "acid" = 100)

/obj/item/clothing/head/helmet/cbrn/cargo
	name = "CBRN hood Cargo"
	icon_state = "cbrnhoodcargo"
	item_state = "cbrnhoodcargo"
	armor = list("melee" = 5, "bullet" = 5, "laser" = 5,"energy" = 5, "bomb" = 10, "bio" = 100, "rad" = 100, "fire" = 100, "acid" = 100)
	desc = "Chemical, Biological, Radiological and Nuclear. A hood design for harsh environmental conditions short of no atmosphere and for cargo some a bit defend from attacks."


/obj/item/clothing/head/helmet/cbrn/mopp
	name = "MOPP hood"
	desc = "Mission Oriented Protective Posture. A hood design for harsh combat conditions short of no atmosphere. This one has a helmet towed onto the hood for added protection."
	icon_state = "mopphood"
	item_state = "mopphood"
	can_flashlight = 1
	anthro_mob_worn_overlay = 'modular_splurt/icons/mob/clothing/head_muzzled.dmi'
	armor = list("melee" = 35, "bullet" = 40, "laser" = 35,"energy" = 40, "bomb" = 25, "bio" = 100, "rad" = 100, "fire" = 40, "acid" = 100)
	is_edible = 0
	clothing_flags = STOPSPRESSUREDAMAGE | THICKMATERIAL
	max_heat_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	cold_protection = HEAD
	min_cold_protection_temperature = FIRE_SUIT_MIN_TEMP_PROTECT
	unique_reskin = list(
		"Monolith" = list("icon_state" = "mopphoodaltm"),
		"Duty" = list("icon_state" = "mopphoodaltd"),
		"Volya" = list("icon_state" = "mopphoodaltv")
	)

/obj/item/clothing/head/helmet/cbrn/mopp/update_icon_state()
	var/base = current_skin ? unique_reskin[current_skin]["icon_state"] : initial(icon_state)
	if(attached_light)
		if(attached_light.on)
			icon_state = base + "-flight-on"
		else
			icon_state = base + "-flight"
	else
		icon_state = base

/obj/item/clothing/head/helmet/cbrn/mopp/advance
	name = "advance MOPP hood"
	desc = "Mission Oriented Protective Posture. A hood design for harsh combat conditions short of no atmosphere. This is an advance versoin for ERT units and Central Command Staff."
	can_flashlight = 1
	armor = list("melee" = 50, "bullet" = 40, "laser" = 40,"energy" = 40, "bomb" = 35, "bio" = 110, "rad" = 110, "fire" = 50, "acid" = 110)
// 	clothing_flags = NONE // BLUEMOON COMMENTED OUT led to loss of parental clothing flags = no space protection
	is_edible = 0


// research nods
/datum/design/cbrn/cbrnhood
	name = "CBRN Hood Civilian"
	desc = "A CBRN hood."
	id = "cbrn_hood"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 200, /datum/material/uranium = 50, /datum/material/iron = 200)
	build_path = /obj/item/clothing/head/helmet/cbrn
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY | DEPARTMENTAL_FLAG_ENGINEERING | DEPARTMENTAL_FLAG_SERVICE | DEPARTMENTAL_FLAG_CARGO | DEPARTMENTAL_FLAG_SCIENCE | DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cbrn/cbrnhood/serv
	name = "CBRN Hood Service"
	desc = "A CBRN hood."
	id = "cbrn_hood_serv"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 200, /datum/material/uranium = 50, /datum/material/iron = 200)
	build_path = /obj/item/clothing/head/helmet/cbrn/serv
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SERVICE

/datum/design/cbrn/cbrnhood/sec
	name = "CBRN Hood Security"
	desc = "A CBRN hood."
	id = "cbrn_hood_sec"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 1000, /datum/material/uranium = 100, /datum/material/iron = 500)
	build_path = /obj/item/clothing/head/helmet/cbrn/sec
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/datum/design/cbrn/cbrnhood/med
	name = "CBRN Hood Medical"
	desc = "A CBRN hood."
	id = "cbrn_hood_med"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 200, /datum/material/uranium = 50, /datum/material/iron = 200)
	build_path = /obj/item/clothing/head/helmet/cbrn/med
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_MEDICAL

/datum/design/cbrn/cbrnhood/sci
	name = "CBRN Hood"
	desc = "A CBRN hood."
	id = "cbrn_hood_sci"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 200, /datum/material/uranium = 50, /datum/material/iron = 200)
	build_path = /obj/item/clothing/head/helmet/cbrn/sci
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SCIENCE

/datum/design/cbrn/cbrnhood/cargo
	name = "CBRN Hood Cargo"
	desc = "A CBRN hood."
	id = "cbrn_hood_cargo"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 200, /datum/material/uranium = 50, /datum/material/iron = 200)
	build_path = /obj/item/clothing/head/helmet/cbrn/cargo
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_CARGO

/datum/design/cbrn/cbrnhood/eng
	name = "CBRN Hood Engineer"
	desc = "A CBRN hood."
	id = "cbrn_hood_eng"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 1000, /datum/material/uranium = 1000, /datum/material/iron = 1000, /datum/material/titanium = 400)
	build_path = /obj/item/clothing/head/helmet/cbrn/eng
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_ENGINEERING

/datum/design/cbrn/mopphood
	name = "MOPP Hood"
	desc = "A MOPP hood with an integrated helmet"
	id = "mopp_hood"
	build_type = PROTOLATHE
	materials = list(/datum/material/plastic = 2000, /datum/material/uranium = 500, /datum/material/iron = 2000)
	build_path = /obj/item/clothing/head/helmet/cbrn/mopp
	category = list("Equipment")
	departmental_flags = DEPARTMENTAL_FLAG_SECURITY

/obj/item/clothing/head/invisihat
	name = "invisifiber hat"
	desc = "A hat made of transparent fibers, often used with reinforcement kits."
	icon = 'modular_splurt/icons/obj/clothing/head.dmi'
	// No overlay, because they're invisible!
	icon_state = "hat_transparent"
	// Makes the invisible hat not screw up hair.
	dynamic_hair_suffix = ""

/obj/item/clothing/head/clussy_wig
	name = "Clussy wig"
	desc = "Wearing this will certainly make your pussy honk..."
	icon = 'modular_splurt/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	icon_state = "clussy_wig"
	item_state = "clussy_wig"
	flags_inv = HIDEHAIR

/obj/item/clothing/head/hoodcowl
	name = "Hood cowl"
	desc = "A dirty, worn-down rag with crudely cut-out eyeholes that barely qualifies as clothing."
	icon = 'modular_splurt/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	icon_state = "hoodcowl"
	item_state = "hoodcowl"
	flags_inv = HIDEHAIR
	dynamic_hair_suffix = ""
