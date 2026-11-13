// Personal CLIP loadout.
// Пояса (разгрузки) в лодаут не входят.
// Одежда идёт напрямую (без статов), а скафандры, шлемы, био-костюмы, броня riot и меха
// выдаются только через коробку улучшалок CLIP kit.

/datum/gear/donator/bm/clip
	ckeywhitelist = list("tech_grid", "dagran")

/datum/gear/donator/bm/clip/deck_uniform
	name = "CLIP deck uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/clip

/datum/gear/donator/bm/clip/minuteman_uniform
	name = "CLIP minuteman uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/clip/minuteman

/datum/gear/donator/bm/clip/formal_uniform
	name = "CLIP formal uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/clip/formal

/datum/gear/donator/bm/clip/formal_skirt
	name = "CLIP formal skirt"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/clip/formal_skirt

/datum/gear/donator/bm/clip/medic_uniform
	name = "CLIP medical uniform"
	slot = ITEM_SLOT_ICLOTHING
	path = /obj/item/clothing/under/clip/medic

/datum/gear/donator/bm/clip/general_coat
	name = "CLIP general's coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/jacket/clip_general

/datum/gear/donator/bm/clip/admiral_coat
	name = "CLIP admiral's coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/jacket/clip_admiral

/datum/gear/donator/bm/clip/captain_coat
	name = "CLIP captain's coat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/jacket/clip_captaincoat

/datum/gear/donator/bm/clip/trenchcoat
	name = "CLIP trenchcoat"
	slot = ITEM_SLOT_OCLOTHING
	path = /obj/item/clothing/suit/jacket/clip_trenchcoat

/datum/gear/donator/bm/clip/goggles
	name = "CLIP ballistic goggles"
	slot = ITEM_SLOT_EYES
	path = /obj/item/clothing/glasses/sunglasses/clip_goggles

/datum/gear/donator/bm/clip/gloves
	name = "CLIP combat gloves"
	slot = ITEM_SLOT_GLOVES
	path = /obj/item/clothing/gloves/color/black/clip_combat

/datum/gear/donator/bm/clip/gasmask
	name = "CLIP gas mask"
	slot = ITEM_SLOT_MASK
	path = /obj/item/clothing/mask/gas/clip

/datum/gear/donator/bm/clip/kit
	name = "CLIP kit"
	slot = ITEM_SLOT_BACKPACK
	path = /obj/item/storage/box/clip_kit
