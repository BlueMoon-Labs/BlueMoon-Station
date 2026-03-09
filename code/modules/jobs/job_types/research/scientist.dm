/datum/job/scientist
	title = "Scientist"
	flag = SCIENTIST
	department_head = list("Research Director")
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 5
	spawn_positions = 3
	supervisors = "the research director"
	selection_color = "#9574cd"
	exp_requirements = 60
	exp_type = EXP_TYPE_CREW
	alt_titles = list(
		"Junior Researcher", //Стажер выше, для удобства
		"Cybersun Researcher", //Триглав выше, для удобства
		"Syndicate Researcher", //Синди выше, для удобства
		"Anomalist",
		"Chemical Researcher",
		"Circuitry Designer",
		"Lab Technician",
		"Nanite Programmer",
		"Ordnance Technician",
		"Plasma Researcher",
		"Programmer",
		"Pyrotechnician",
		"Rack Researcher",
		"Researcher",
		"Resonance Researcher",
		"Sex Researcher",
		"Theoretical Physicist",
		"Toxins Researcher",
		"Xenoarcheologist",
		"Xenobiologist"
		)

	outfit = /datum/outfit/job/scientist
	plasma_outfit = /datum/outfit/plasmaman/science

	access = list(ACCESS_ROBOTICS, ACCESS_TOX, ACCESS_TOX_STORAGE, ACCESS_RESEARCH, ACCESS_XENOBIOLOGY, ACCESS_MINERAL_STOREROOM, ACCESS_TECH_STORAGE, ACCESS_GENETICS)
	minimal_access = list(ACCESS_TOX, ACCESS_TOX_STORAGE, ACCESS_RESEARCH, ACCESS_XENOBIOLOGY, ACCESS_MINERAL_STOREROOM)
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_SCI
	bounty_types = CIV_JOB_SCI
	departments = DEPARTMENT_BITFLAG_SCIENCE
	starting_modifiers = list(/datum/skill_modifier/job/level/wiring/basic)
	display_order = JOB_DISPLAY_ORDER_SCIENTIST
	threat = 1.2

	family_heirlooms = list(
		/obj/item/toy/plush/slimeplushie
	)

	mail_goodies = list(
		/obj/item/raw_anomaly_core/random = 10,
//		/obj/item/disk/tech_disk/spaceloot = 2,
		/obj/item/camera_bug = 1
	)

/datum/outfit/job/scientist
	name = "Scientist"
	jobtype = /datum/job/scientist

	belt = /obj/item/pda/toxins
	ears = /obj/item/radio/headset/headset_sci
	uniform = /obj/item/clothing/under/rank/rnd/scientist
	shoes = /obj/item/clothing/shoes/sneakers/white
	suit = /obj/item/clothing/suit/toggle/labcoat/science

	backpack = /obj/item/storage/backpack/science
	satchel = /obj/item/storage/backpack/satchel/tox

/datum/outfit/job/scientist/syndicate
	name = "Syndicate Scientist"
	jobtype = /datum/job/scientist

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_sci
	uniform = /obj/item/clothing/under/rank/rnd/scientist/util
	shoes = /obj/item/clothing/shoes/sneakers/white
	suit = /obj/item/clothing/suit/toggle/labcoat/science

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/syndicate_uplink=1)

