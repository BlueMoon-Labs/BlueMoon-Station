/datum/gear/mask
	category = LOADOUT_CATEGORY_MASK
	slot = ITEM_SLOT_MASK

/datum/gear/mask/balaclava
	name = "Balaclava"
	path = /obj/item/clothing/mask/balaclava

/datum/gear/mask/moustache
	name = "Fake moustache"
	path = /obj/item/clothing/mask/fakemoustache

/datum/gear/mask/joy
	name = "Joy mask"
	path = /obj/item/clothing/mask/joy
	cost = 3

/datum/gear/mask/kitsune
	name = "White Kitsune Mask"
	path = /obj/item/clothing/mask/kitsune
	loadout_initial_colors = list("#FFFFFF", "#CC0000", "#000000")
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	cost = 2

/datum/gear/mask/black_kitsune
	name = "Black Kitsune Mask"
	path = /obj/item/clothing/mask/kitsune/black
	loadout_initial_colors = list("#333333", "#CC9933", "#000000")
	loadout_flags = LOADOUT_CAN_NAME_DESC_POLY
	item_icon_state = "kitsune_black"
	cost = 2

/datum/gear/mask/gas
	name = "Gas Mask"
	path = /obj/item/clothing/mask/gas
	cost = 4
	//restricted_roles = list("Chief Engineer", "Atmospheric Technician", "Station Engineer") // BlueMoon edit. No restrictions

/datum/gear/mask/sterile
	name = "Aesthetic sterile mask"
	path = /obj/item/clothing/mask/surgical/aesthetic
	cost = 2

/datum/gear/mask/paper
	name = "Paper mask"
	path = /obj/item/clothing/mask/paper
	cost = 2

/datum/gear/mask/polychromic_clown
	name = "polychromic clown wig and mask"
	path = /obj/item/clothing/mask/gas/clown_hat_polychromic
	restricted_roles = list("Clown")
