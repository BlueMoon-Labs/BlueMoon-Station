/obj/item/armorkit/blueshield
	name = "aegis armor kit"
	desc = "A nanotrasen armoring kit with armored plates and some nanoglue, for reinforcing outerwear."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	icon_state = "blueshield_armor_kit" // I'm so sorry I butchered the sprite, Toriate.
	parent_armor_type = /obj/item/clothing/suit/armor/vest/blueshield
	kit_slot_flag = ITEM_SLOT_OCLOTHING
	kit_prefix = "aegis"


/obj/item/armorkit/blueshield/helmet
	name = "aegis headgear kit"
	desc = "A nanotrasen armoring kit with armored plates and some nanoglue, for reinforcing hats or other headgear."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	icon_state = "blueshield_helmet_kit" // I'm so sorry I butchered the sprite, Toriate. (x2)
	parent_armor_type = /obj/item/clothing/head/helmet/sec/blueshield
	kit_slot_flag = ITEM_SLOT_HEAD
	kit_prefix = "aegis"

/obj/item/armorkit/security
	name = "rampart armor kit"
	desc = "A security armoring kit with flexible armored sheets and some nanoglue, for reinforcing outerwear."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	icon_state = "sec_armor_kit" // I'm so sorry I butchered the sprite, Toriate. (x3)
	parent_armor_type = /obj/item/clothing/suit/armor/vest
	kit_slot_flag = ITEM_SLOT_OCLOTHING
	kit_prefix = "rampart"

/obj/item/armorkit/security/helmet
	name = "rampart headgear kit"
	desc = "A security armoring kit with flexible armored sheets and some nanoglue, for reinforcing hats or other headgear."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	icon_state = "sec_helmet_kit" // I'm so sorry I butchered the sprite, Toriate. (x4)
	parent_armor_type = /obj/item/clothing/head/helmet/sec
	kit_slot_flag = ITEM_SLOT_HEAD
	kit_prefix = "rampart"

/obj/item/armorkit/syndicate
	name = "SynTech armor kit"
	desc = "Набор гибких армированных пластин которые будут совершенно незаметно сидеть под твоей толстовкой, с которой ты так не захотел расставаться, хиккан."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	icon_state = "syn_armor_kit"
	parent_armor_type = /obj/item/clothing/suit/armor/vest/blueshield
	kit_slot_flag = ITEM_SLOT_OCLOTHING
	kit_prefix = "rogue"

//Голова
/obj/item/armorkit/helmet/syndicate
	name = "SynTech helmet kit"
	desc = "Набор гибких армированных пластин которые будут совершенно незаметно сидеть под твоей кепкой, с которой ты так не захотел расставаться, хиккан."
	icon = 'modular_splurt/icons/obj/clothing/reinforcekits.dmi'
	icon_state = "syn_helmet_kit"
	parent_armor_type = /obj/item/clothing/head/helmet/sec/blueshield
	kit_slot_flag = ITEM_SLOT_HEAD
	kit_prefix = "rogue"
