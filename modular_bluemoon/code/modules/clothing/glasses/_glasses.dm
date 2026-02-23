/obj/item/clothing/glasses/geist_gazers
	name = "geist gazers"
	icon = 'modular_bluemoon/icons/obj/clothing/glasses.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/eyes.dmi'
	icon_state = "geist_gazers"
	item_state = "geist_gazers"
	glass_colour_type = /datum/client_colour/glass_colour/green
	flags_cover = GLASSESCOVERSEYES

/obj/item/clothing/gloves/poly_evening
	name = "polychromic evening gloves"
	desc = "Thin, pretty polychromic gloves intended for use in regal feminine attire."
	icon = 'modular_bluemoon/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hands.dmi'
	icon_state = "poly_evening"
	item_state = "poly_evening"
	transfer_prints = TRUE
	cold_protection = HANDS
	min_cold_protection_temperature = GLOVES_MIN_TEMP_PROTECT
	heat_protection = HANDS
	max_heat_protection_temperature = COAT_MAX_TEMP_PROTECT
	strip_mod = 0.9

/obj/item/clothing/gloves/poly_evening/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/polychromic, list("#FEFEFE"), 1)

/obj/item/clothing/gloves/transparent
	name = "transparent bracers"
	desc = "A pair of transparent bracers, they look fancy."
	icon = 'modular_bluemoon/icons/obj/clothing/gloves.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hands.dmi'
	icon_state = "transparent_bracers"
	item_state = "transparent_bracers"
	transfer_prints = TRUE
