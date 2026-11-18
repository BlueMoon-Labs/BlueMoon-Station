/datum/job/bitrunner
	title = "Bitrunner"
	flag = CARGOTECH
	department_head = list("Quartermaster")
	department_flag = CIVILIAN
	faction = "Station"
	total_positions = 3
	spawn_positions = 3
	supervisors = "the quartermaster"
	selection_color = "#ca8f55"

	alt_titles = list(
		"Domain Runner",
		"Netrunner",
		"Quantum Runner",
	)

	outfit = /datum/outfit/job/bitrunner
	plasma_outfit = /datum/outfit/plasmaman/bitrunner

	access = list(
		ACCESS_BIT_DEN,
		ACCESS_CARGO,
		ACCESS_MAINT_TUNNELS,
		ACCESS_MINERAL_STOREROOM,
		ACCESS_MINING,
		ACCESS_MINING_STATION,
		ACCESS_QM,
	)
	minimal_access = list(
		ACCESS_BIT_DEN,
		ACCESS_CARGO,
		ACCESS_MAINT_TUNNELS,
		ACCESS_MINERAL_STOREROOM,
		ACCESS_MINING,
		ACCESS_MINING_STATION,
		ACCESS_QM,
	)

	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_CAR
	display_order = JOB_DISPLAY_ORDER_BITRUNNER
	bounty_types = CIV_JOB_BITRUN
	departments = DEPARTMENT_BITFLAG_SUPPLY
	threat = 0.5

	family_heirlooms = list(/obj/item/reagent_containers/food/drinks/soda_cans/space_mountain_wind)

	mail_goodies = list(
		/obj/item/reagent_containers/food/snacks/cornchips = 1,
		/obj/item/reagent_containers/food/drinks/soda_cans/space_mountain_wind = 1,
	)

/datum/outfit/job/bitrunner
	name = "Bitrunner"
	jobtype = /datum/job/bitrunner

	uniform = /obj/item/clothing/under/rank/cargo/bitrunner
	belt = /obj/item/modular_computer/pda/bitrunner
	ears = /obj/item/radio/headset/headset_cargo
	shoes = /obj/item/clothing/shoes/sneakers/black
	r_pocket = /obj/item/disk/bitrunning/prefs

/datum/outfit/plasmaman/bitrunner
	name = "Bitrunner Plasmaman"

	uniform = /obj/item/clothing/under/plasmaman/bitrunner
	head = /obj/item/clothing/head/helmet/space/plasmaman/bitrunner
	gloves = /obj/item/clothing/gloves/color/black
