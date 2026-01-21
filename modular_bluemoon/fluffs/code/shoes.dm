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

/obj/item/clothing/shoes/jackboots/tall/mu88_boots
	name = "M.U. 88 New hope boots"
	desc = "Ботфорты, практически доходящие до бёдер своего носителя. Основной материал или сплав, из которых выполнен данных элемент одежды определить сложно, хоть и по прочности и класса брони напоминает соединение кевлара, лёгкого металла и карбона. Каркас подвижный, не стесняет движения своего носителя, самая подвижная часть расположена в месте колена. Не требует внешней зарядки, несмотря на установленную механическую часть. В незаметной части сапога имеется небольшой логотип в виде чёрной розы, а рядом надпись - Black Rose atelier."
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes_digi.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	icon_state = "mu88_boots"
	item_state = "mu88_boots"

///////////////////////////////////////////////

/obj/item/clothing/shoes/exo_legs
	name = "Exo-legs"
	desc = "Адаптирующие вес под собой, современные протезы для ходьбы"
	icon = 'modular_bluemoon/fluffs/icons/obj/clothing/shoes.dmi'
	mob_overlay_icon = 'modular_bluemoon/fluffs/icons/mob/clothing/shoes.dmi'
	lefthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_left.dmi'
	righthand_file = 'modular_bluemoon/fluffs/icons/mob/inhands/clothing_right.dmi'
	mutantrace_variation = STYLE_DIGITIGRADE | STYLE_NO_ANTHRO_ICON
	body_parts_covered = GROIN
	icon_state = "exo_legs"
	item_state = "exo_legs"
	var/list/poly_colors = list("#ffffff")

/obj/item/clothing/shoes/exo_legs/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/squeak, list('sound/effects/footstep/exo_footstep-1.ogg' = 1,'sound/effects/footstep/exo_footstep-2.ogg' = 1), 100)
	AddElement(/datum/element/polychromic, poly_colors, 1)
