/datum/job/cargo_tech
	title = "Cargo Technician"
	flag = CARGOTECH
	department_head = list("Quartermaster")
	department_flag = CIVILIAN
	faction = "Station"
	total_positions = 3
	spawn_positions = 2
	supervisors = "the quartermaster"
	selection_color = "#ca8f55"
	alt_titles = list(
		"Trainee Cargo Technician", //Стажер выше, для удобства
		"Donk Co. Specialist", //Триглав выше, для удобства
		"Syndicate Smuggler", //Синди выше, для удобства
		"Cock Packager",
		"Commodities Trader",
		"Cryptocurrency Technician",
		"Deck Worker",
		"Deliveries Officer",
		"Delivery Manager",
		"Disposal Technician",
		"Horny Mailer",
		"Inventory Associate",
		"Logistics Technician",
		"Mail Carrier",
		"Mailman",
		"Mailroom Technician",
		"Merchant",
		"Package Handler",
		"Pleasures Deliverer",
		"Postman",
		"Receiving Clerk",
		"Scavenger",
		"Scrap Recycler",
		"Shipping Specialist",
		"Smuggler",
		"Supplier",
		"Supply Specialist",
		"Supply Technician"
		)

	outfit = /datum/outfit/job/cargo_tech
	plasma_outfit = /datum/outfit/plasmaman/cargo

	access = list(ACCESS_MAINT_TUNNELS, ACCESS_MAILSORTING, ACCESS_CARGO, ACCESS_CARGO_BOT, ACCESS_MINING,
				ACCESS_MINING_STATION, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_MAINT_TUNNELS, ACCESS_CARGO, ACCESS_MAILSORTING, ACCESS_MINERAL_STOREROOM)
	paycheck = PAYCHECK_EASY
	paycheck_department = ACCOUNT_CAR

	display_order = JOB_DISPLAY_ORDER_CARGO_TECHNICIAN
	bounty_types = CIV_JOB_RANDOM
	departments = DEPARTMENT_BITFLAG_SUPPLY
	threat = 0.2

	family_heirlooms = list(
		/obj/item/clipboard
	)

	mail_goodies = list(
		/obj/item/pizzabox = 10,
		/obj/item/stack/sheet/mineral/gold = 5,
		/obj/item/stack/sheet/mineral/uranium = 4,
		/obj/item/stack/sheet/mineral/diamond = 3,
		/obj/item/gun/ballistic/shotgun/boltaction = 1
	)
/datum/outfit/job/cargo_tech
	name = "Cargo Technician"
	jobtype = /datum/job/cargo_tech

	belt = /obj/item/pda/cargo
	ears = /obj/item/radio/headset/headset_cargo
	uniform = /obj/item/clothing/under/rank/cargo/tech
	l_hand = /obj/item/export_scanner

/datum/outfit/job/cargo_tech/syndicate
	name = "Syndicate Cargo Technician"
	jobtype = /datum/job/cargo_tech

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_cargo
	uniform = /obj/item/clothing/under/rank/cargo/util
	l_hand = /obj/item/export_scanner
	shoes = /obj/item/clothing/shoes/jackboots/tall_default

	backpack = /obj/item/storage/backpack/duffelbag/syndie/ammo
	satchel = /obj/item/storage/backpack/duffelbag/syndie/ammo
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/ammo
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/syndicate_uplink=1)
