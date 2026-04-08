/datum/job/roboticist
	title = "Roboticist"
	flag = ROBOTICIST
	department_head = list("Research Director")
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "the research director"
	selection_color = "#9574cd"
	exp_requirements = 60
	exp_type = EXP_TYPE_CREW
	alt_titles = list(
		"Junior Roboticist", //Стажер выше, для удобства
		"Cybersun Specialist", //Триглав выше, для удобства
		"Biomechanical Engineer",
		"Borgs Raper",
		"Borgs Slut",
		"Cyberneticist",
		"Droid Mechanic",
		"Machinist",
		"Mechanic",
		"Mechatronic Engineer",
		"MOD Mechanic",
		"Ripperdoc",
		"Robo-Slut",
		"Robotics Operator",
		"Synth Technician",
		"Techpriest Biologis"
		)

	outfit = /datum/outfit/job/roboticist
	departments = DEPARTMENT_BITFLAG_SCIENCE
	plasma_outfit = /datum/outfit/plasmaman/robotics

	access = list(ACCESS_ROBOTICS, ACCESS_TOX, ACCESS_TOX_STORAGE, ACCESS_TECH_STORAGE, ACCESS_MORGUE, ACCESS_RESEARCH, ACCESS_MINERAL_STOREROOM, ACCESS_XENOBIOLOGY, ACCESS_GENETICS, ACCESS_PRODUCTION_SCIENCE)
	minimal_access = list(ACCESS_ROBOTICS, ACCESS_TECH_STORAGE, ACCESS_MORGUE, ACCESS_RESEARCH, ACCESS_MINERAL_STOREROOM, ACCESS_PRODUCTION_SCIENCE)
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_SCI
	bounty_types = CIV_JOB_ROBO

	starting_modifiers = list(/datum/skill_modifier/job/level/wiring/basic, /datum/skill_modifier/job/affinity/wiring) //BLUEMOON CHANGE job/level to basic

	mind_traits = list(TRAIT_KNOW_CYBORG_WIRES, TRAIT_MECHA_EXPERT) //BLUEMOON ADD use #define TRAIT system

	display_order = JOB_DISPLAY_ORDER_ROBOTICIST
	threat = 1

	family_heirlooms = list(
		/obj/item/toy/figure/borg,
	)

	mail_goodies = list(
		/obj/item/storage/box/flashes = 20,
		/obj/item/stack/sheet/metal/twenty = 15,
		/obj/item/modular_computer/tablet/preset/advanced = 5
	)

/datum/job/roboticist/New()
	. = ..()
	family_heirlooms += subtypesof(/obj/item/toy/mecha)

/datum/outfit/job/roboticist
	name = "Roboticist"
	jobtype = /datum/job/roboticist

	belt = /obj/item/storage/belt/utility/full
	l_pocket = /obj/item/pda/roboticist
	ears = /obj/item/radio/headset/headset_sci
	uniform = /obj/item/clothing/under/rank/rnd/roboticist
	suit = /obj/item/clothing/suit/toggle/labcoat/roboticist

	backpack = /obj/item/storage/backpack/science
	satchel = /obj/item/storage/backpack/satchel/tox

	pda_slot = ITEM_SLOT_LPOCKET

/datum/outfit/job/roboticist/syndicate
	name = "Syndicate Roboticist"
	jobtype = /datum/job/roboticist

	//belt = /obj/item/pda/syndicate/no_deto

	l_pocket = /obj/item/pda/roboticist
	ears = /obj/item/radio/headset/headset_sci
	uniform = /obj/item/clothing/under/rank/rnd/scientist/util
	suit = /obj/item/clothing/suit/toggle/labcoat/roboticist

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/syndicate_uplink=1)
