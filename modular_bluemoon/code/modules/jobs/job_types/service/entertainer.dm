/datum/job/entertainer
	title = "Entertainer"
	flag = ENTERTAINER
	department_head = list("Head of Personnel")
	department_flag = CIVILIAN
	faction = "Station"
	total_positions = 5
	spawn_positions = 5
	supervisors = "the head of personnel"
	selection_color = "#bbe291"
	exp_type_department = EXP_TYPE_SERVICE // This is so the jobs menu can work properly

	outfit = /datum/outfit/job/entertainer
	plasma_outfit = /datum/outfit/plasmaman

	paycheck = PAYCHECK_EASY
	paycheck_department = ACCOUNT_SRV
	bounty_types = CIV_JOB_BASIC

	display_order = JOB_DISPLAY_ORDER_ENTERTAINER
	departments = DEPARTMENT_BITFLAG_SERVICE
	threat = 0.5

	access = list(ACCESS_MINERAL_STOREROOM, ACCESS_PRODUCTION_SERVICE)
	minimal_access = list(ACCESS_MINERAL_STOREROOM, ACCESS_PRODUCTION_SERVICE)

	custom_spawn_text = "вы — сотрудник сервисного отдела. У вас нет своего отдела или прямого начальника помимо Главы Персонала. \
	Коммуницируйте с остальным обслуживающим персоналом для достижения наилучшего эффекта. В конце концов, развлекайте туристов и тех, \
	кто обещает хорошие чаевые за ваш труд!"

	alt_titles = list(
		"Actor",
		"Barber",
		"Bard",
		"Beautician",
		"Belly Massager",
		"Cosmetologist",
		"Cosplayer",
		"Guide",
		"Dancer",
		"Entertainment Organizer",
		"Escort",
		"Fashion Officer",
		"Fitness Coach",
		"Fitness Instructor",
		"Fortuneteller",
		"Instructor",
		"Manual Laborer",
		"Massage therapist",
		"Masseur",
		"Musician",
		"Palmist",
		"Perfomer",
		"Performer",
		"Personal Physician",
		"Sex Educator",
		"Scene Performer",
		"Stripper",
		"Stylist",
		"Waiter",
		)

	family_heirlooms = list(
		/obj/item/storage/wallet,
		/obj/item/coin/silver,
		/obj/item/reagent_containers/rag/towel
	)

/obj/item/pda/entertainer
	name = "entertainer PDA"
	icon_state = "pda-bartender"
	//default_cartridge = /obj/item/cartridge/bartender
	inserted_item = /obj/item/pen/fountain

/datum/outfit/job/entertainer
	name = "Entertainer"
	jobtype = /datum/job/entertainer

	belt = /obj/item/pda/entertainer
	ears = /obj/item/radio/headset/headset_srv
	uniform = /obj/item/clothing/under/misc/assistantformal

/datum/outfit/job/entertainer/syndicate
	name = "Syndicate Entertainer"
	jobtype = /datum/job/entertainer

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_srv
	uniform = /obj/item/clothing/under/rank/civilian/util
	shoes = /obj/item/clothing/shoes/jackboots

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/syndicate_uplink=1)
