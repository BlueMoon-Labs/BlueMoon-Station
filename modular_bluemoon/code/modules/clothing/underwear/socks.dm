/obj/item/clothing/underwear/socks/poly_pantyhose_crotchless
	name = "bottomless polychromic pantyhose"
	desc = "Pantyhose with an open bottom."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/underwear_digi.dmi'
	icon_state = "polypantyhose"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose_crotchless/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_pantyhose_thick_crotchless
	name = "bottomless thick polychromic pantyhose"
	desc = "Thick Pantyhose with an open bottom."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/underwear_digi.dmi'
	icon_state = "polypantyhose_thick"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose_thick_crotchless/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_pantyhose_plaid_crotchless
	name = "bottomless plaid polychromic pantyhose"
	desc = "Plaid Pantyhose with an open bottom."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/underwear_digi.dmi'
	icon_state = "polypantyhose_plaid"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose_plaid_crotchless/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_pantyhose_dotted_crotchless
	name = "bottomless dotted polychromic pantyhose"
	desc = "Dotted Pantyhose with an open bottom."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/underwear_digi.dmi'
	icon_state = "polypantyhose_dotted"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose_dotted_crotchless/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_pantyhose_faux_crotchless
	name = "bottomless faux polychromic pantyhose"
	desc = "Faux Pantyhose with an open bottom."
	icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/underwear_digi.dmi'
	icon_state = "polypantyhose_faux"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose_faux_crotchless/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)
