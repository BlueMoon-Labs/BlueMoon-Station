/obj/item/clothing/head/npc_questhuh_hat
	name = "NPC Hat"
	desc = "The hat that looks like a big question..."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/large-worn-icons/32x48/head.dmi'
	icon_state = "huh"
	item_state = "huh"

/obj/item/clothing/head/npc_questhey_hat
	name = "NPC Hat"
	desc = "The hat that looks like a big exclamation mark..."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/large-worn-icons/32x48/head.dmi'
	icon_state = "hey"
	item_state = "hey"

/obj/item/clothing/head/hcaberet
	name = "HCA beret"
	desc = "A black beret with a silver sun, around which rays spread. The symbol of the Triad of the Sun - the main idea of the political party Human Commonwealth. Glory to Humanity!"
	icon_state = "hcaberetitem"
	item_state = "hcaberetitem"
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	strip_delay = 60
	dog_fashion = null

/obj/item/clothing/head/beret/chronos
	name = "new mecca beret"
	desc = "But burning those villages, watching those naked peasants cry..."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "torch_beret"

/obj/item/clothing/head/turban
	name = "Polychromic Turban"
	desc = "Идёт караван из Ирана.."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "turban_he"
	item_state = "turban"
	var/list/poly_colors = list("#ffffff")

/obj/item/clothing/head/turban/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/polychromic, poly_colors, 1)

/obj/item/clothing/head/cracked_pot
	name = "Cracked pot"
	desc = "It looks extremely stupid, but for some reason wearing it makes you feel proud."
	flags_inv = HIDEHAIR|HIDEFACIALHAIR|HIDEEARS|HIDESNOUT
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "cracked_pot"

////////////////////////////////////////////
/obj/item/clothing/head/helmet/cbrn/mopp
	mutantrace_variation = STYLE_MUZZLE
	anthro_mob_worn_overlay = 'modular_bluemoon/icons/mob/clothing/head_muzzled.dmi'

////////////////////////////////////////////

/obj/item/clothing/head/fez
	name = "fez"
	desc = "Put it on your monkey, make lots of cash money."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "fez"
	item_state = "fez"

/obj/item/clothing/head/flower_crown
	name = "flower crown"
	desc = "A colorful flower crown made out of lilies, sunflowers and poppies."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "flower_crown"
	item_state = "flower_crown"

/obj/item/clothing/head/sunflower_crown
	name = "sunflower crown"
	desc = "A bright flower crown made out sunflowers that is sure to brighten up anyone's day!"
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "sunflower_crown"
	item_state = "sunflower_crown"

/obj/item/clothing/head/poppy_crown
	name = "poppy crown"
	desc = "A flower crown made out of a string of bright red poppies."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "poppy_crown"
	item_state = "poppy_crown"

/obj/item/clothing/head/lily_crown
	name = "lily crown"
	desc = "A leafy flower crown with a cluster of large white lilies at the front."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "lily_crown"
	item_state = "lily_crown"

/obj/item/clothing/head/geranium_crown
	name = "geranium crown"
	desc = "A flower crown made out of an array of rich purple geraniums."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "geranium_crown"
	item_state = "geranium_crown"

/obj/item/clothing/head/laurel_crown
	name = "Golden laurel wreath"
	desc = "A wreath of bay leaves made of gold."
	icon = 'modular_bluemoon/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/icons/mob/clothing/hats.dmi'
	icon_state = "laurel_crown"
	item_state = "laurel_crown"
