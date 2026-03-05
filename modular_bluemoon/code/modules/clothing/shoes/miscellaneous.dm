/obj/item/clothing/shoes/legwrap // Ported from Fluffy Frontier
	name = "Leg wrap"
	desc = "A roll of treated canvas used for wrapping claws or paws."
	icon = 'modular_bluemoon/icons/obj/clothing/shoes.dmi'
	icon_state = "legwrap"
	item_state = "legwrap"
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/shoes_digi.dmi'

/obj/item/clothing/shoes/jackboots/cbrn/mopp
	icon = 'modular_bluemoon/icons/obj/clothing/shoes.dmi'
	icon_state = "moppboots"
	item_state = "moppboots"
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/shoes_digi.dmi'

/obj/item/clothing/shoes/polyflats
	name = "Polychromic flat shoes"
	desc = "Flats."
	icon = 'modular_bluemoon/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/shoes_digi.dmi'
	icon_state = "flatswhite"

/obj/item/clothing/shoes/polywhitedress
	name = "Polychromic dress shoes"
	desc = "Shiny dress shoes."
	icon = 'modular_bluemoon/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/shoes_digi.dmi'
	icon_state = "whitedress"

/obj/item/clothing/shoes/polyheels
	name = "Polychromic high heels"
	desc = "Shoes with high heels."
	icon = 'modular_bluemoon/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/shoes_digi.dmi'
	icon_state = "heels"

/obj/item/clothing/shoes/polyheels/Initialize()
	. = ..()
	AddComponent(/datum/component/squeak, list('modular_splurt/sound/lewd/highheel1.ogg' = 1,'modular_splurt/sound/lewd/highheel2.ogg' = 1), 70)

/obj/item/clothing/shoes/polyheels_boots
	name = "Polychromic high heeled boots"
	desc = "Boots with high heels."
	name = "High heeled boots"
	icon = 'modular_bluemoon/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/shoes_digi.dmi'
	icon_state = "boots"

/obj/item/clothing/shoes/polyheels_boots/Initialize()
	. = ..()
	AddComponent(/datum/component/squeak, list('modular_splurt/sound/lewd/highheel1.ogg' = 1,'modular_splurt/sound/lewd/highheel2.ogg' = 1), 70)


/obj/item/clothing/shoes/polyheels_boots_high
	name = "Polychromic high heeled high boots"
	desc = "High boots with high heels."
	icon = 'modular_bluemoon/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/shoes_digi.dmi'
	icon_state = "boots_high"

/obj/item/clothing/shoes/polyheels_boots_high/Initialize()
	. = ..()
	AddComponent(/datum/component/squeak, list('modular_splurt/sound/lewd/highheel1.ogg' = 1,'modular_splurt/sound/lewd/highheel2.ogg' = 1), 70)

/obj/item/clothing/shoes/sandals_fancy
	name = "Fancy sandals"
	desc = "A pair of fancy wooden sandals."
	icon = 'modular_bluemoon/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/shoes_digi.dmi'
	icon_state = "sandals_fancy"
