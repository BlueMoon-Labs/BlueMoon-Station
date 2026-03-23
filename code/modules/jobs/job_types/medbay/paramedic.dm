/datum/job/paramedic
	title = "Paramedic"
	flag = PARAMEDIC
	department_head = list("Chief Medical Officer")
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "the chief medical officer"
	selection_color = "#74b5e0"
	alt_titles = list(
		"Interdyne Field Medic", //Триглав выше, для удобства
		"Syndicate Field Medic", //Синди выше, для удобства
		"Crocin Deliverer",
		"Emergency Condom Team",
		"Emergency Cum Receiver",
		"Emergency Horny Technical",
		"Emergency Medical Doctor",
		"Emergency Medical Technician",
		"Emergency Physician",
		"Field Physician",
		"Field Surgeon",
		"Para-Slut",
		"Para-Stud",
		"Searh and Rescue Technician",
		"Trauma Team",
		"Trauma Team",
		"Trauma Team Responder"
		)

	outfit = /datum/outfit/job/paramedic

	access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_SURGERY, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_MINERAL_STOREROOM, ACCESS_MAINT_TUNNELS, ACCESS_CARGO, ACCESS_MAILSORTING, ACCESS_MINING, ACCESS_MINING_STATION, ACCESS_EXTERNAL_AIRLOCKS, ACCESS_CONSTRUCTION, ACCESS_RESEARCH, ACCESS_EVA,)

	minimal_access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_CLONING, ACCESS_MINERAL_STOREROOM, ACCESS_MAINT_TUNNELS, ACCESS_CARGO, ACCESS_MAILSORTING, ACCESS_MINING, ACCESS_MINING_STATION, ACCESS_EXTERNAL_AIRLOCKS, ACCESS_CONSTRUCTION, ACCESS_RESEARCH,)
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED
	bounty_types = CIV_JOB_MED
	departments = DEPARTMENT_BITFLAG_MEDICAL

	mind_traits = list(TRAIT_QUICK_CARRY) //BLUEMOON ADD use TRAIT system for jobs

	display_order = JOB_DISPLAY_ORDER_PARAMEDIC

	threat = 0.5

	starting_modifiers = list(/datum/skill_modifier/job/surgery, /datum/skill_modifier/job/affinity/surgery)

	family_heirlooms = list(
		/obj/item/storage/firstaid/ancient/heirloom
	)

	mail_goodies = list(
		/obj/item/reagent_containers/hypospray/medipen = 20,
		/obj/item/reagent_containers/hypospray/medipen/oxandrolone = 10,
		/obj/item/reagent_containers/hypospray/medipen/salacid = 10,
		/obj/item/reagent_containers/hypospray/medipen/salbutamol = 10,
		/obj/item/reagent_containers/hypospray/medipen/penacid = 10,
		/obj/item/reagent_containers/hypospray/medipen/survival = 5 // survival/luxury
	)

/datum/outfit/job/paramedic
	name = "Paramedic"
	jobtype = /datum/job/paramedic

	ears = /obj/item/radio/headset/headset_med
	gloves = /obj/item/clothing/gloves/color/latex/nitrile
	uniform = /obj/item/clothing/under/rank/medical/paramedic
	mask = /obj/item/clothing/mask/surgical
	shoes = /obj/item/clothing/shoes/jackboots
	head = /obj/item/clothing/head/soft/emt
	suit =  /obj/item/clothing/suit/toggle/labcoat/paramedic
	belt = /obj/item/storage/belt/medical
	l_hand = /obj/item/storage/firstaid/regular
	suit_store = /obj/item/flashlight/pen/paramedic
	id = /obj/item/card/id
	r_pocket = /obj/item/pinpointer/crew
	l_pocket = /obj/item/pda/medical
	backpack_contents = list(/obj/item/roller=1, /obj/item/storage/hypospraykit/regular=1)
	pda_slot = ITEM_SLOT_LPOCKET

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med

	chameleon_extras = /obj/item/gun/syringe

/datum/outfit/job/paramedic/syndicate
	name = "Syndicate Paramedic"
	jobtype = /datum/job/paramedic

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_med
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	uniform = /obj/item/clothing/under/rank/medical/doctor/util
	mask = /obj/item/clothing/mask/surgical
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	head = /obj/item/clothing/head/soft/emt
	suit =  /obj/item/clothing/suit/toggle/labcoat/paramedic
	l_hand = /obj/item/storage/firstaid/regular
	suit_store = /obj/item/flashlight/pen/paramedic

	r_pocket = /obj/item/pinpointer/crew

	backpack = /obj/item/storage/backpack/duffelbag/syndie/med
	satchel = /obj/item/storage/backpack/duffelbag/syndie/med
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/med
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/roller=1, /obj/item/syndicate_uplink=1)
