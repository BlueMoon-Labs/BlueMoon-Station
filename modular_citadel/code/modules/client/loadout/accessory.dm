/datum/gear/accessory
	category = LOADOUT_CATEGORY_ACCESSORY
	slot = ITEM_SLOT_ACCESSORY
	handle_post_equip = TRUE

/datum/gear/accessory/necklace
	name = "A renameable necklace"
	description = "Ожерелье."
	path = /obj/item/clothing/accessory/necklace

/datum/gear/accessory/polymaidapron
	name = "Polychromic maid apron"
	description = "Лучшая часть костюма горничной."
	path = /obj/item/clothing/accessory/maidapron/polychromic
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	loadout_initial_colors = list("#333333", "#FFFFFF")

/datum/gear/accessory/pridepin
	name = "Pride pin"
	description = "Голографическая заколка от Центра разнообразия и инклюзивности NanoTrasen — покажите свою гордость сексуальностью или гендерной идентичностью и напомните экипажу о их непоколебимой приверженности равенству, разнообразию и инклюзивности!"
	path = /obj/item/clothing/accessory/pride
	cost = 0
