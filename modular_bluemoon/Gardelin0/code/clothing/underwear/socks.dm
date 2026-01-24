/obj/item/clothing/underwear/socks/thigh/stockings/poly_fishnet
	name = "polychromic fishnet stockings"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polyfishnet"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/thigh/stockings/poly_fishnet/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/full_pantyhose
	name = "full body pantyhose"
	desc = "Full Body Pantyhose."
	body_parts_covered = FEET | LEGS | GROIN
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "pantyhose_full"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/full_pantyhose/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_pantyhose
	name = "polychromic pantyhose"
	desc = "Pantyhose."
	body_parts_covered = FEET | LEGS | GROIN
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polypantyhose"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_pantyhose_thick
	name = "thick polychromic pantyhose"
	desc = "Thick Pantyhose."
	body_parts_covered = FEET | LEGS | GROIN
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polypantyhose_thick"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose_thick/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_knee
	name = "thin polychromic knee socks"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polythin_knee"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_knee/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/thigh/stockings/poly_thigh_thin
	name = "polychromic thin thigh high"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polythin_thigh"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/thigh/stockings/poly_thigh_thin/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/thigh/stockings/poly_garter_thin
	name = "polychromic thin garters"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polythin_garter"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/thigh/stockings/poly_garter_thin/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_pantyhose_plaid
	name = "plaid polychromic pantyhose"
	desc = "Plaid Pantyhose."
	body_parts_covered = FEET | LEGS | GROIN
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polypantyhose_plaid"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose_plaid/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/thigh/stockings/poly_thigh_plaid
	name = "plaid polychromic thigh high"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polyplaidthin_thigh"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/thigh/stockings/poly_thigh_plaid/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/thigh/stockings/poly_garter_plaid
	name = "plaid polychromic garters"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polyplaidthin_garter"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/thigh/stockings/poly_garter_plaid/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_pantyhose_dotted
	name = "dotted polychromic pantyhose"
	desc = "Dotted Pantyhose."
	body_parts_covered = FEET | LEGS | GROIN
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polypantyhose_dotted"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose_dotted/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/thigh/stockings/poly_thigh_dotted
	name = "dotted polychromic thigh high"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polydottedthin_thigh"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/thigh/stockings/poly_thigh_dotted/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/thigh/stockings/poly_garter_dotted
	name = "dotted polychromic garters"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polydottedthin_garter"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/thigh/stockings/poly_garter_dotted/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/poly_pantyhose_faux
	name = "faux polychromic pantyhose"
	desc = "Faux Pantyhose."
	body_parts_covered = FEET | LEGS | GROIN
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polypantyhose_faux"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/poly_pantyhose_faux/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/thigh/stockings/poly_thigh_faux
	name = "faux polychromic thigh high"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polyfauxthin_thigh"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/thigh/stockings/poly_thigh_faux/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)

/obj/item/clothing/underwear/socks/thigh/stockings/poly_garter_faux
	name = "faux polychromic garters"
	icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/Gardelin0/icons/clothing/worn/underwear_digi.dmi'
	icon_state = "polyfauxthin_garter"
	var/polychromic = TRUE

/obj/item/clothing/underwear/socks/thigh/stockings/poly_garter_faux/ComponentInitialize()
	. = ..()
	if(polychromic)
		AddElement(/datum/element/polychromic, list("#ffffff"), 1)
