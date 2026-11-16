
/obj/item/clothing/head/fishing_hat
	name = "legendary fishing hat"
	desc = "Древняя реликвия времён щедрого улова и бесконечных рек. На белой вставке вышито: «Женщины боятся меня, рыбы боятся меня, мужчины отводят взгляд. Когда я иду, ни один зверь не смеет издать ни звука. Я один на этой пустой земле.»"
	icon = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_obj.dmi'
	icon_state = "fishing_hat"
	item_state = "fishing_hat"
	mob_overlay_icon = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_worn.dmi'
	lefthand_file = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_righthand.dmi'
	custom_price = PRICE_ALMOST_CHEAP

/obj/item/clothing/head/fishing_hat/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_HEAD)
		ADD_TRAIT(user, TRAIT_EXPERT_FISHER, REF(src))

/obj/item/clothing/head/fishing_hat/dropped(mob/user)
	. = ..()
	REMOVE_TRAIT(user, TRAIT_EXPERT_FISHER, REF(src))

/obj/item/clothing/head/fishing_hat/examine(mob/user)
	. = ..()
	. += span_notice("Пока шапка на голове, ловить рыбу заметно проще.")

/obj/item/clothing/suit/apron/waders
	name = "horticultural waders"
	desc = "Плотные кожаные заброды. Не боятся воды, грязи и шипов, а заодно спасают колени от рыбы, которая решила побороться."
	icon = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_obj.dmi'
	icon_state = "hort_waders"
	item_state = "hort_waders"
	mob_overlay_icon = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_worn.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_digi.dmi'
	body_parts_covered = CHEST|GROIN|LEGS
	mutantrace_variation = STYLE_DIGITIGRADE
	custom_price = PRICE_NORMAL

/obj/item/clothing/gloves/fishing
	name = "fishing gloves"
	desc = "Плотные перчатки с цепким хватом. Позволяют на ощупь оценить размер и вес пойманной рыбы."
	icon = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_obj.dmi'
	icon_state = "fishing_gloves"
	item_state = "fishing_gloves"
	mob_overlay_icon = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_worn.dmi'
	lefthand_file = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_lefthand.dmi'
	righthand_file = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_righthand.dmi'
	custom_price = PRICE_ALMOST_CHEAP

/obj/item/clothing/gloves/fishing/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_GLOVES)
		ADD_TRAIT(user, TRAIT_EXAMINE_FISH, REF(src))

/obj/item/clothing/gloves/fishing/dropped(mob/user)
	. = ..()
	REMOVE_TRAIT(user, TRAIT_EXAMINE_FISH, REF(src))

/obj/item/clothing/gloves/fishing/examine(mob/user)
	. = ..()
	. += span_notice("В этих перчатках при осмотре рыбы видно её размер и вес.")

/obj/item/clothing/neck/cloak/fishing
	name = "legendary fisher cloak"
	desc = "Плащ тех, кто познал все течения и освоил каждую наживку. Говорят, под ним рыба сама идёт на крючок."
	icon = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_obj.dmi'
	icon_state = "fishing_cloak"
	item_state = "fishing_cloak"
	mob_overlay_icon = 'modular_bluemoon/fishing/icons/clothing/fishing_clothing_worn.dmi'
	custom_price = PRICE_EXPENSIVE

/obj/item/clothing/neck/cloak/fishing/equipped(mob/user, slot)
	. = ..()
	if(slot == ITEM_SLOT_NECK)
		ADD_TRAIT(user, TRAIT_REVEAL_FISH, REF(src))

/obj/item/clothing/neck/cloak/fishing/dropped(mob/user)
	. = ..()
	REMOVE_TRAIT(user, TRAIT_REVEAL_FISH, REF(src))

/obj/item/clothing/neck/cloak/fishing/examine(mob/user)
	. = ..()
	. += span_notice("В этом плаще во время ловли видно, что именно клюнуло.")
