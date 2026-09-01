/obj/item/clothing/suit/bm
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	lefthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_lefthand.dmi'
	righthand_file = 'modular_bluemoon/icons/mob/inhands/clothing_righthand.dmi'

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

/obj/item/clothing/suit/hospitaller
	name = "hospitaller coat"
	desc = "Храни их жизни, Бог-Император!"
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "hospitaller"
	item_state = "hospitaller"
	blood_overlay_type = "coat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/toggle/male2
	name = "fancy t'au robe"
	desc = "Прекрасная одежда из Империи Тау."
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "male2"
	item_state = "male2"
	blood_overlay_type = "coat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/hooded/genetor
	name = "Adeptus Mechanicus fancy robe"
	desc = "Bless Omnissiah!"
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "genetor"
	item_state = "genetor"
	blood_overlay_type = "coat"
	no_t = TRUE
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	hoodtype = /obj/item/clothing/head/hooded/genetor_hood

/obj/item/clothing/suit/hooded/genetor_follower
	name = "Adeptus Mechanicus follower robe"
	desc = "Bless Omnissiah!"
	icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/suit.dmi'
	icon_state = "genetor"
	item_state = "genetor"
	no_t = TRUE
	blood_overlay_type = "coat"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
	hoodtype = /obj/item/clothing/head/hooded/genetor_follower_hood

/obj/item/clothing/head/hooded/genetor_hood
	name = "Adeptus Mechanicus Hood"
	desc = "Bless Omnissiah in my head."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "techpriestnew"  // или "genetor_hood" — какой спрайт есть
	body_parts_covered = HEAD
	flags_inv = HIDEHAIR|HIDEFACE|HIDEEARS

/obj/item/clothing/head/hooded/genetor_follower_hood
	name = "Adeptus Mechanicus Follower Hood"
	desc = "Bless Omnissiah in my head."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "genetor"  // или "genetor_follower_hood"
	body_parts_covered = HEAD
	flags_inv = HIDEHAIR|HIDEFACE|HIDEEARS

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

/obj/item/clothing/suit/bm/sergal_leather_cape
	name = "Sergal leather cape"
	icon_state = "leather_cape"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/bm/sergal_red_cape
	name = "Sergal red cape"
	icon_state = "red_cape"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/bm/sergal_red_armor
	name = "Sergal red armor"
	icon_state = "red_armor"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/bm/sergal_stylish_armor
	name = "Sergal stylish armor"
	icon_state = "stylish_armor"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/suit/bm/sergal_knight_armor
	name = "Sergal knight's armor"
	icon_state = "knight_armor"
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON
