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
	armor_type = /datum/armor/none
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
	armor_type = /datum/armor/armored_headgear

//CBRN/MOPP helmets

/obj/item/clothing/head/helmet/cbrn
	name = "CBRN hood Civilian"
	desc = "Chemical, Biological, Radiological and Nuclear. A hood design for harsh environmental conditions short of no atmosphere"
	icon_state = "cbrnhoodciv"
	item_state = "cbrnhoodciv"
	icon = 'modular_splurt/icons/obj/clothing/head.dmi'
	mob_overlay_icon = 'modular_splurt/icons/mob/clothing/head.dmi'
	armor_type = /datum/armor/cbrn
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
	armor_type = /datum/armor/cbrn_engineering
	desc = "Chemical, Biological, Radiological and Nuclear. A hood design for harsh environmental conditions short of no atmosphere and for engineer squads fireproof."

/obj/item/clothing/head/helmet/cbrn/sec
	name = "CBRN hood Security"
	icon_state = "cbrnhoodsec"
	item_state = "cbrnhoodsec"
	armor_type = /datum/armor/cbrn_head_sec
	desc = "Chemical, Biological, Radiological and Nuclear. A hood design for harsh environmental conditions short of no atmosphere and for security squads was armor padded."

/obj/item/clothing/head/helmet/cbrn/med
	name = "CBRN hood Medical"
	icon_state = "cbrnhoodmed"
	item_state = "cbrnhoodmed"

/obj/item/clothing/head/helmet/cbrn/sci
	name = "CBRN hood Science"
	icon_state = "cbrnhoodsci"
	item_state = "cbrnhoodsci"
	armor_type = /datum/armor/science

/obj/item/clothing/head/helmet/cbrn/cargo
	name = "CBRN hood Cargo"
	icon_state = "cbrnhoodcargo"
	item_state = "cbrnhoodcargo"
	armor_type = /datum/armor/cargo
	desc = "Chemical, Biological, Radiological and Nuclear. A hood design for harsh environmental conditions short of no atmosphere and for cargo some a bit defend from attacks."


/obj/item/clothing/head/helmet/cbrn/mopp
	name = "MOPP hood"
	desc = "Mission Oriented Protective Posture. A hood design for harsh combat conditions short of no atmosphere. This one has a helmet towed onto the hood for added protection."
	icon_state = "mopphood"
	item_state = "mopphood"
	can_flashlight = 1
	mutantrace_variation = STYLE_MUZZLE
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/head_muzzled.dmi'
	armor_type = /datum/armor/head_mopp
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
	armor_type = /datum/armor/head_advance
// 	clothing_flags = NONE // BLUEMOON COMMENTED OUT led to loss of parental clothing flags = no space protection
	is_edible = 0

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
