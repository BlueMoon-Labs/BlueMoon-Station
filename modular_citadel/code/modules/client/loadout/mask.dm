/datum/gear/mask
	category = LOADOUT_CATEGORY_MASK
	slot = ITEM_SLOT_MASK

/datum/gear/mask/balaclava
	name = "Balaclava"
	description = "КУЧА ДЕНЕГ!"
	path = /obj/item/clothing/mask/balaclava

/datum/gear/mask/moustache
	name = "Fake moustache"
	description = "Внимание: усы фальшивые."
	path = /obj/item/clothing/mask/fakemoustache

/datum/gear/mask/joy
	name = "Joy mask"
	description = "Вырази свою радость или скрой печаль с помощью этого модульного выреза."
	path = /obj/item/clothing/mask/joy
	cost = 3

/datum/gear/mask/kitsune
	name = "White Kitsune Mask"
	description = "Восточная фарфоровая маска."
	path = /obj/item/clothing/mask/kitsune
	loadout_initial_colors = list("#FFFFFF", "#CC0000", "#000000")
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	cost = 2

/datum/gear/mask/black_kitsune
	name = "Black Kitsune Mask"
	description = "Восточная фарфоровая маска."
	path = /obj/item/clothing/mask/kitsune/black
	loadout_initial_colors = list("#333333", "#CC9933", "#000000")
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	item_icon_state = "kitsune_black"
	cost = 2

/datum/gear/mask/gas
	name = "Gas Mask"
	description = "Маска, закрывающая лицо и подключаемая к источнику воздуха. Хороша для сокрытия личности, но плохо задерживает поток газа."
	path = /obj/item/clothing/mask/gas
	cost = 4
	//restricted_roles = list("Chief Engineer", "Atmospheric Technician", "Station Engineer") // BlueMoon edit. No restrictions

/datum/gear/mask/sterile
	name = "Aesthetic sterile mask"
	description = "Стерильная маска, помогающая предотвратить распространение болезней. Почему-то эта не кажется особенно полезной."
	path = /obj/item/clothing/mask/surgical/aesthetic
	cost = 2

/datum/gear/mask/paper
	name = "Paper mask"
	description = "Аккуратная круглая маска из бумаги."
	path = /obj/item/clothing/mask/paper
	cost = 2

/datum/gear/mask/polychromic_clown
	name = "polychromic clown wig and mask"
	description = "Настоящий наряд шутника. Клоун без парика и маски — не клоун."
	path = /obj/item/clothing/mask/gas/clown_hat_polychromic
	restricted_roles = list("Clown")
