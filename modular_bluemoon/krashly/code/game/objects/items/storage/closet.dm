/obj/structure/closet/syndicate/inteq
	name = "armory closet"
	desc = "Why is this here?"
	icon_state = "inteq"

/obj/structure/closet/syndicate/inteq/vanguard
	icon_state = "inteq_boss"

/obj/structure/closet/syndicate/inteq/personal
	desc = "It's a personal storage unit for operative gear."

/obj/structure/closet/syndicate/inteq/personal/PopulateContents()
	..()
	new /obj/item/clothing/under/inteq(src)
	new /obj/item/clothing/under/inteq/skirt(src)
	new /obj/item/clothing/shoes/sneakers/black(src)
	new /obj/item/radio/headset/syndicate(src)
	new /obj/item/ammo_box/magazine/m10mm(src)
	new /obj/item/storage/belt/military/inteq(src)
	new /obj/item/crowbar/red(src)
	new /obj/item/clothing/glasses/night/syndicate(src)
	new /obj/item/clothing/glasses/hud/security/sunglasses/inteq(src)
	new /obj/item/clothing/under/inteq/maid

/obj/structure/closet/syndicate/inteq/personal_raider
	desc = "It's a personal storage unit for operative gear."

/obj/structure/closet/syndicate/inteq/personal_raider/PopulateContents()
	..()
	new /obj/item/clothing/under/inteq(src)
	new /obj/item/clothing/under/inteq/skirt(src)
	new /obj/item/clothing/shoes/sneakers/black(src)
	new /obj/item/radio/headset/syndicate(src)
	new /obj/item/clothing/glasses/hud/security/sunglasses/inteq(src)

/obj/machinery/suit_storage_unit/syndicate/inteq
	mod_type = /obj/item/mod/control/pre_equipped/inteq
	suit_type = /obj/item/clothing/suit/space/hardsuit/syndi/inteq
	mask_type = /obj/item/clothing/mask/gas/sechailer
	storage_type = /obj/item/tank/jetpack/oxygen/harness


/obj/machinery/suit_storage_unit/inteq_spacesuit
	suit_type = /obj/item/clothing/suit/space/syndicate/inteq
	mask_type = /obj/item/clothing/head/helmet/space/syndicate/inteq
	storage_type = /obj/item/tank/jetpack/oxygen/harness
