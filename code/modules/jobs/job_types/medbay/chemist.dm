/datum/job/chemist
	title = "Chemist"
	flag = CHEMIST
	department_head = list("Chief Medical Officer")
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "the chief medical officer"
	selection_color = "#74b5e0"
	exp_type = EXP_TYPE_CREW
	exp_requirements = 60
	alt_titles = list(
		"Chemist Intern", //Стажер выше, для удобства
		"Alchemist",
		"Apothecarist",
		"Chemi-Slut",
		"Chemical Specialist",
		"Chemical Technician",
		"Chemical Plumber",
		"Hexocrocin Therapist",
		"Organomegaly Healer",
		"Pharmacist",
		"Pharmacologist",
		)

	outfit = /datum/outfit/job/chemist
	plasma_outfit = /datum/outfit/plasmaman/chemist

	access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_SURGERY, ACCESS_CHEMISTRY, ACCESS_VIROLOGY, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_CHEMISTRY, ACCESS_MINERAL_STOREROOM)
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED
	bounty_types = CIV_JOB_CHEM
	departments = DEPARTMENT_BITFLAG_MEDICAL

	mind_traits = list(TRAIT_REAGENT_EXPERT) //BLUEMOON ADD use TRAIT system for jobs

	display_order = JOB_DISPLAY_ORDER_CHEMIST
	threat = 1.5

	starting_modifiers = list(/datum/skill_modifier/job/surgery, /datum/skill_modifier/job/affinity/surgery)
	blacklisted_quirks = list(/datum/quirk/nonviolent)

	family_heirlooms = list(
		/obj/item/book/manual/wiki/chemistry,
		/obj/item/fermichem/pHbooklet
	)

	mail_goodies = list(
		/datum/reagent/flash_powder = 15,
//		/datum/reagent/exotic_stabilizer = 5,
		/datum/reagent/toxin/leadacetate = 5,
		/obj/item/paper/secretrecipe = 1
	)

/datum/outfit/job/chemist
	name = "Chemist"
	jobtype = /datum/job/chemist

	glasses = /obj/item/clothing/glasses/science
	belt = /obj/item/pda/chemist
	ears = /obj/item/radio/headset/headset_med
	uniform = /obj/item/clothing/under/rank/medical/chemist
	shoes = /obj/item/clothing/shoes/sneakers/white
	suit =  /obj/item/clothing/suit/toggle/labcoat/chemist
	backpack = /obj/item/storage/backpack/chemistry
	satchel = /obj/item/storage/backpack/satchel/chem
	duffelbag = /obj/item/storage/backpack/duffelbag/med

	backpack_contents = list(/obj/item/storage/hypospraykit/regular)

	chameleon_extras = /obj/item/gun/syringe

/datum/outfit/job/chemist/syndicate
	name = "Syndicate Chemist"
	jobtype = /datum/job/chemist

	//belt = /obj/item/pda/syndicate/no_deto

	glasses = /obj/item/clothing/glasses/science
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	ears = /obj/item/radio/headset/headset_med
	uniform = /obj/item/clothing/under/rank/medical/doctor/util
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	suit =  /obj/item/clothing/suit/toggle/labcoat/chemist

	backpack = /obj/item/storage/backpack/duffelbag/syndie/med
	satchel = /obj/item/storage/backpack/duffelbag/syndie/med
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/med
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/storage/hypospraykit/regular, /obj/item/syndicate_uplink=1)

