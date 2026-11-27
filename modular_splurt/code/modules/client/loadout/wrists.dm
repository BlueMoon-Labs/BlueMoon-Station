/datum/gear/wrists
	category = LOADOUT_CATEGORY_WRISTS
	slot = ITEM_SLOT_WRISTS

/datum/gear/wrists/syntech/band
	name = "Normalizer Band"
	description = "Дорогой технологичный браслет в фиолетовых тонах SynTech с мерцающим золотом NanoTrasen. Пока надет, он «нормализует» размер владельца до заданного роста, одобренного для условий работы. На нём жужжит маленький экран с информацией."
	path = /obj/item/clothing/wrists/syntech

/datum/gear/wrists/armwarmer
	name = "Arm Warmers"
	description = "Пара нарукавников."
	path = /obj/item/clothing/wrists/armwarmer

/datum/gear/wrists/armwarmer/long
	name = "Long Arm Warmers"
	description = "Пара длинных нарукавников."
	path = /obj/item/clothing/wrists/armwarmer/long

/datum/gear/wrists/armwarmer_striped
	name = "Striped Arm Warmers"
	description = "Пара полосатых нарукавников."
	path = /obj/item/clothing/wrists/armwarmer_striped
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#FFFFFF", "#FFFFFF")

/datum/gear/wrists/armwarmer_striped/long
	name = "Long Striped Arm Warmers"
	description = "Пара длинных полосатых нарукавников."
	path = /obj/item/clothing/wrists/armwarmer_striped/long
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#FFFFFF", "#FFFFFF")

/datum/gear/wrists/talk_need_bracelet
	name = "Браслет - Давайте общаться"
	description = "Браслет с призывом «Давайте общаться». Относительно новая разработка для поддержки некоторых социальных слоёв существ."
	subcategory = LOADOUT_SUBCATEGORY_NONE
	path = /obj/item/clothing/wrists/helper_bracelet
	cost = 0

/datum/gear/wrists/love_need_bracelet
	name = "Браслет - Нахожусь в активном поиске любви"
	description = "Браслет с надписью «Нахожусь в активном поиске любви»."
	subcategory = LOADOUT_SUBCATEGORY_NONE
	path = /obj/item/clothing/wrists/helper_bracelet/love_need_bracelet
	cost = 0

/datum/gear/wrists/rape_need_bracelet
	name = "Браслет - Изнасилуйте меня"
	description = "Браслет с надписью «Изнасилуйте меня»."
	subcategory = LOADOUT_SUBCATEGORY_NONE
	path = /obj/item/clothing/wrists/helper_bracelet/rape_need_bracelet
	cost = 0

/datum/gear/wrists/fuckme_need_bracelet
	name = "Браслет - Трахните меня"
	description = "Браслет с надписью «Трахните меня»."
	subcategory = LOADOUT_SUBCATEGORY_NONE
	path = /obj/item/clothing/wrists/helper_bracelet/fuckme_need_bracelet
	cost = 0

/datum/gear/wrists/fuckyou_need_bracelet
	name = "Браслет - Хочу трахнуть кого-то"
	description = "Браслет с надписью «Хочу трахнуть кого-то»."
	subcategory = LOADOUT_SUBCATEGORY_NONE
	path = /obj/item/clothing/wrists/helper_bracelet/fuckyou_need_bracelet
	cost = 0
