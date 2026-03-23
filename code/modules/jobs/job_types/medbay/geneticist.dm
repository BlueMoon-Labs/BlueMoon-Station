/datum/job/geneticist
	title = "Geneticist"
	flag = GENETICIST
	department_head = list("Chief Medical Officer", "Research Director")
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "the chief medical officer and research director"
	selection_color = "#74b5e0"
	exp_type = EXP_TYPE_CREW
	exp_requirements = 60
	alt_titles = list(
		"Genetist Intern", //Стажер выше, для удобства
		"Syndicate Genetist",
		"Bioengineer",
		"Gene Tailor",
		"Gene Therapist",
		"Gene-Slut",
		"Gene-Stud",
		"Genemancer",
		"Genetics Researcher"
		)

	outfit = /datum/outfit/job/geneticist
	departments = DEPARTMENT_BITFLAG_MEDICAL
	plasma_outfit = /datum/outfit/plasmaman/genetics

	access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_CHEMISTRY, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_RESEARCH, ACCESS_XENOBIOLOGY, ACCESS_ROBOTICS, ACCESS_MINERAL_STOREROOM, ACCESS_TECH_STORAGE)
	minimal_access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_RESEARCH, ACCESS_MINERAL_STOREROOM)
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED
	bounty_types = CIV_JOB_SCI

	display_order = JOB_DISPLAY_ORDER_GENETICIST
	threat = 1.5

	starting_modifiers = list(/datum/skill_modifier/job/surgery, /datum/skill_modifier/job/affinity/surgery)

	family_heirlooms = list(
		/obj/item/clothing/under/shorts/purple
	)

	mail_goodies = list(
		/obj/item/storage/box/monkeycubes = 10
	)

/datum/outfit/job/geneticist
	name = "Geneticist"
	jobtype = /datum/job/geneticist

	belt = /obj/item/pda/geneticist
	ears = /obj/item/radio/headset/headset_medsci
	uniform = /obj/item/clothing/under/rank/medical/geneticist
	shoes = /obj/item/clothing/shoes/sneakers/white
	suit =  /obj/item/clothing/suit/toggle/labcoat/genetics
	suit_store =  /obj/item/flashlight/pen

	backpack = /obj/item/storage/backpack/genetics
	satchel = /obj/item/storage/backpack/satchel/gen
	duffelbag = /obj/item/storage/backpack/duffelbag/med
	l_pocket = /obj/item/sequence_scanner

/datum/outfit/job/geneticist/syndicate
	name = "Syndicate Geneticist"
	jobtype = /datum/job/geneticist

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_medsci
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	uniform = /obj/item/clothing/under/rank/medical/doctor/util
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	suit =  /obj/item/clothing/suit/toggle/labcoat/genetics
	suit_store =  /obj/item/flashlight/pen
	l_pocket = /obj/item/sequence_scanner

	backpack = /obj/item/storage/backpack/duffelbag/syndie/med
	satchel = /obj/item/storage/backpack/duffelbag/syndie/med
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/med
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/syndicate_uplink=1)


