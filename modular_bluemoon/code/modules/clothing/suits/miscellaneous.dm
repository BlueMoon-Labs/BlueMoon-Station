/obj/item/clothing/suit/toggle/uniform_parade
	name = "Officer's parade uniform"
	desc = "Glorious and shining uniform for honorable officers."
	icon = 'modular_bluemoon/icons/mob/clothing/uniforms.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/uniforms.dmi'
	icon_state = "uniform_parade"
	item_state = "uniform_parade"
	body_parts_covered = CHEST|ARMS
	togglename = "buttons"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/garland_suit
	name = "garlands"
	desc = "X-mas garlands"
	icon = 'modular_bluemoon/icons/obj/clothing/underwear.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/underwear.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "garland_shirt"
	item_state = "garland_shirt"

/obj/item/clothing/suit/bm/suit_corset
	name = "Corset"
	desc = "A support garment commonly worn to hold and train the torso into a desired shape, traditionally a smaller waist or larger bottom, for aesthetic or medical purposes, or support the breasts."
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	icon_state = "suit_corset"
	item_state = "suit_corset"

/obj/item/clothing/suit/jacket/paratrench
	name = "trenchcoat"
	desc = "A trenchcoat with a TailorCo brand on the tag. Looks expensive."
	icon_state = "paratrench"
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'

/obj/item/clothing/suit/jacket/paratrench/black
	icon_state = "paratrench_black"
	unique_reskin = list(
		"Adjusted coat" = list("icon_state" = "paratrench_black_d")
	)

/obj/item/clothing/suit/toggle/warm_poncho
	name = "warm rainbow poncho"
	desc = "Warm coarse knit wool poncho."
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_righthand.dmi'
	icon_state = "rainbow_warm_poncho"
	cold_protection = CHEST
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	togglename = "style"

/obj/item/clothing/suit/toggle/warm_poncho/green
	name = "warm green poncho"
	desc = "Warm coarse knit wool poncho."
	icon_state = "green_warm_poncho"

/obj/item/clothing/suit/toggle/warm_poncho/red
	name = "warm red poncho"
	desc = "Warm coarse knit wool poncho."
	icon_state = "red_warm_poncho"

/obj/item/clothing/suit/toggle/warm_poncho/blue
	name = "warm blue poncho"
	desc = "Warm coarse knit wool poncho."
	icon_state = "blue_warm_poncho"

/obj/item/clothing/suit/toggle/polysuitjacket
	name = "polychromic suit jacket"
	desc = "A snappy polychromic dress jacket."
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "polysuitjacket"
	item_state = "polysuitjacket"
	blood_overlay_type = "coat"
	body_parts_covered = CHEST|ARMS
	togglename = "buttons"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/polyrobes
	name = "polychromic robes"
	desc = "A magnificant robe."
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "polyrobes"
	item_state = "polyrobes"
	blood_overlay_type = "coat"
	body_parts_covered = CHEST|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/toggle/poly_labcoat
	name = "polychromic labcoat"
	desc = "A suit that protects against minor chemical spills."
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "poly_labcoat"
	item_state = "poly_labcoat"
	blood_overlay_type = "coat"
	body_parts_covered = CHEST|ARMS
	togglename = "buttons"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/commissar
	name = "commissar coat"
	desc = "A great way to cosplay the hero of the Imperium!"
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "commissar"
	item_state = "commissar"
	blood_overlay_type = "coat"
	body_parts_covered = CHEST|ARMS
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
