/obj/item/clothing/shoes/archangel_boots
	name = "Archangel Group boots"
	desc = "A pair of fancy boots of Archangel Group."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes.dmi'
	icon_state = "archangel_boots"

/obj/item/clothing/shoes/jackboots/sec/white
	name = "white jackboots"
	desc = "Security jackboots in white colors."
	icon_state = "jackboots_sec_white"
	item_state = "jackboots_sec_white"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE|STYLE_NO_ANTHRO_ICON

/obj/item/clothing/shoes/breadboots
	name = "Breadshoe"
	desc = "Эти ботинки выглядят настолько съедобно, что даже хочется попробовать их на вкус. Правда, компания UniShoesInc не несёт ответственности за попытки поедания реплики булочного изделия."
	icon_state = "breadshoe"
	item_state = "breadshoe"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes_digi.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE

/obj/item/clothing/shoes/breadboots/Initialize()
	. = ..()
	AddComponent(/datum/component/squeak, list('modular_bluemoon/sound/items/bread_step.ogg' = 1), 75)

/obj/item/clothing/shoes/breadboots/baguette
	name = "Baguetteshoe"
	icon_state = "baguetteshoe"
	item_state = "baguetteshoe"

/obj/item/clothing/shoes/jackboots/tall/soviet_jackboots
	name = "Soviet Black Jackboots"
	desc = "High-quality clothes made of a mixture of fleece and cotton. The logo in the form of an eagle and the caption of the Strategic Assault Tactical Team are visible on the tag. If you inhale the smell, you can smell the slices of a war crime."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes_digi.dmi'
	icon_state = "sovietblackboots"
	item_state = "jackboots"
