/datum/job/hydro
	title = "Botanist"
	flag = BOTANIST
	department_head = list("Head of Personnel")
	department_flag = CIVILIAN
	faction = "Station"
	total_positions = 3
	spawn_positions = 2
	supervisors = "the head of personnel"
	selection_color = "#bbe291"
	alt_titles = list(
		"Junior Botanist", //Стажер выше, для удобства
		"Apiarist",
		"Apiculturist",
		"Beekeeper",
		"Botanical Researcher",
		"Druid",
		"Farmer",
		"Florist",
		"Gardener",
		"Herbalist",
		"Hydroponicist",
		"Mycologist",
		"Plants Breeder",
		"Soiler",
		"Vintner",
		"Xenobotanist"
		)

	outfit = /datum/outfit/job/botanist
	plasma_outfit = /datum/outfit/plasmaman/botany

	access = list(ACCESS_HYDROPONICS, ACCESS_BAR, ACCESS_KITCHEN, ACCESS_MORGUE, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_HYDROPONICS, ACCESS_MORGUE, ACCESS_MINERAL_STOREROOM)
	paycheck = PAYCHECK_EASY
	paycheck_department = ACCOUNT_SRV
	bounty_types = CIV_JOB_GROW
	departments = DEPARTMENT_BITFLAG_SERVICE
	display_order = JOB_DISPLAY_ORDER_BOTANIST
	threat = 1.5 // lol powergame

	family_heirlooms = list(
		/obj/item/cultivator,
		/obj/item/reagent_containers/glass/bucket, // Watering cans don't exist yet
		/obj/item/toy/plush/beeplushie,
	)

	mail_goodies = list(
		/datum/reagent/toxin/mutagen = 20,
		/datum/reagent/saltpetre = 20,
		/datum/reagent/diethylamine = 20,
		/obj/item/gun/energy/floragun = 10,
		/obj/effect/spawner/lootdrop/seed_vault = 5,// These are strong, rare seeds, so use sparingly.
		/obj/item/reagent_containers/food/snacks/cube/bee = 2
	)

/datum/outfit/job/botanist
	name = "Botanist"
	jobtype = /datum/job/hydro

	belt = /obj/item/pda/botanist
	ears = /obj/item/radio/headset/headset_srv
	uniform = /obj/item/clothing/under/rank/civilian/hydroponics
	suit = /obj/item/clothing/suit/apron
	gloves  =/obj/item/clothing/gloves/botanic_leather
	suit_store = /obj/item/plant_analyzer

	backpack = /obj/item/storage/backpack/botany
	satchel = /obj/item/storage/backpack/satchel/hyd

/datum/outfit/job/botanist/syndicate
	name = "Syndicate Botanist"
	jobtype = /datum/job/hydro

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_srv
	uniform = /obj/item/clothing/under/rank/civilian/util
	suit = /obj/item/clothing/suit/apron
	gloves = /obj/item/clothing/gloves/botanic_leather
	suit_store = /obj/item/plant_analyzer
	shoes = /obj/item/clothing/shoes/jackboots/tall_default

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	backpack_contents = list(/obj/item/syndicate_uplink=1)
	pda_slot = ITEM_SLOT_BELT
