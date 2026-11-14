/datum/blackmarket_item/syndi/clothing/ds_hardsuit
	price = 0
	stock = 0
	availability_prob = 0	//Zeroing this out so it can't be used at all
//normal

/datum/blackmarket_item/clothing/stalker
	name = "S.T.A.L.K.E.R. mask"
	desc = "Smells like reactor four."
	item = /obj/item/clothing/mask/gas/stalker
	price_min = 400
	price_max = 800
	stock_min = 1
	stock_max = 3
	availability_prob = 80

/datum/blackmarket_item/clothing/military
	name = "Military Gas Mask"
	desc = "A rare PMC gas mask, one of the very expensive kinds. The inside looks comfortable to wear for a while. The blood red eyes however seem to stare back at you. Creepy."
	item = /obj/item/clothing/mask/gas/military
	price_min = 400
	price_max = 800
	stock_min = 1
	stock_max = 3
	availability_prob = 80

//syndis

/datum/blackmarket_item/syndi/clothing/tactical
	name = "Tactical turtleneck"
	desc = "A non-descript and slightly suspicious looking turtleneck with digital camouflage cargo pants."
	item = /obj/item/clothing/under/syndicate
	price = 500000
	stock_min = 1
	stock_max = 10
	availability_prob = 75

/datum/blackmarket_item/syndi/clothing/tacticalskirt
	name = "Tactical skirtleneck"
	desc = "A non-descript and slightly suspicious looking skirtleneck."
	item = /obj/item/clothing/under/syndicate/tacticool
	price = 500000
	stock_min = 1
	stock_max = 10
	availability_prob = 75

/datum/blackmarket_item/syndi/clothing/tacticalskirt
	name = "Combat uniform"
	desc = "With a suit lined with this many pockets, you are ready to operate."
	item = /obj/item/clothing/under/syndicate/combat
	price = 500000
	stock_min = 1
	stock_max = 10
	availability_prob = 50

/datum/blackmarket_item/syndi/clothing/fullred_spacesuit_set
	name = "Red Spacesuit Box"
	desc = "A boxed Syndicate space suit"
	item = /obj/item/storage/box
	price = 750000
	stock_min = 1
	stock_max = 2
	availability_prob = 30


/datum/blackmarket_item/syndi/clothing/fullred_spacesuit_set/spawn_item(loc)
	var/obj/item/storage/box/B = ..()
	B.name = "Spacesuit Box"
	B.desc = "It has a NT logo crossed with marker on it."
	new /obj/item/clothing/head/helmet/space/syndicate(B)
	new /obj/item/clothing/suit/space/syndicate(B)
	return B

/datum/blackmarket_item/syndi/clothing/fullgreen_spacesuit_set
	name = "Green Spacesuit Box"
	desc = "A boxed Syndicate space suit"
	item = /obj/item/storage/box
	price = 750000
	stock_min = 1
	stock_max = 2
	availability_prob = 30

/datum/blackmarket_item/syndi/clothing/fullgreen_spacesuit_set/spawn_item(loc)
	var/obj/item/storage/box/B = ..()
	B.name = "Spacesuit Box"
	B.desc = "It has a NT logo crossed with marker on it."
	new /obj/item/clothing/head/helmet/space/syndicate/green(B)
	new /obj/item/clothing/suit/space/syndicate/green(B)
	return B

/datum/blackmarket_item/syndi/clothing/fullgreen_spacesuit_set
	name = "Dark Green Spacesuit Box"
	desc = "A boxed Syndicate space suit"
	item = /obj/item/storage/box
	price = 750000
	stock_min = 1
	stock_max = 2
	availability_prob = 30

/datum/blackmarket_item/syndi/clothing/fullgreen_spacesuit_set/spawn_item(loc)
	var/obj/item/storage/box/B = ..()
	B.name = "Spacesuit Box"
	B.desc = "It has a NT logo crossed with marker on it."
	new /obj/item/clothing/head/helmet/space/syndicate/green/dark(B)
	new /obj/item/clothing/suit/space/syndicate/green/dark(B)
	return B
