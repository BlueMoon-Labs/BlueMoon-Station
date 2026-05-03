/datum/job/doctor
	title = "Medical Doctor"
	flag = DOCTOR
	department_head = list("Chief Medical Officer")
	department_flag = MEDSCI
	faction = "Station"
	total_positions = 5
	spawn_positions = 3
	supervisors = "the chief medical officer"
	selection_color = "#74b5e0"
	alt_titles = list(
		"Medical Intern", //Стажер выше, для удобства
		"Interdyne Specialist", //Триглав выше, для удобства
		"Coroner",
		"Healing Fleshlight",
		"Medi-Slut",
		"Medi-Stud",
		"Medical Examiner",
		"Medical Secretary",
		"Medical Resident",
		"Medical Technician",
		"Medtech",
		"Nurse",
		"Oral Doctor",
		"Pathologist",
		"Physician",
		"Psychiatrist",
		"Surgeon",
		"Field Surgeon",
		"Therapist",
		"Trophologist",
		"Xenosurgeon",
		)

	outfit = /datum/outfit/job/doctor
	departments = DEPARTMENT_BITFLAG_MEDICAL
	plasma_outfit = /datum/outfit/plasmaman/medical

	access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_SURGERY, ACCESS_CHEMISTRY, ACCESS_GENETICS, ACCESS_CLONING, ACCESS_VIROLOGY, ACCESS_MINERAL_STOREROOM, ACCESS_PRODUCTION_MEDICAL)
	minimal_access = list(ACCESS_MEDICAL, ACCESS_MORGUE, ACCESS_SURGERY, ACCESS_CLONING, ACCESS_MINERAL_STOREROOM, ACCESS_PRODUCTION_MEDICAL)
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_MED
	bounty_types = CIV_JOB_MED

	mind_traits = list(TRAIT_KNOW_MED_SURGERY_T2) //BLUEMOON ADD use TRAIT system for jobs

	display_order = JOB_DISPLAY_ORDER_MEDICAL_DOCTOR
	threat = 0.5

	starting_modifiers = list(/datum/skill_modifier/job/surgery, /datum/skill_modifier/job/affinity/surgery)

	family_heirlooms = list(
		/obj/item/storage/firstaid/ancient/heirloom,
		/obj/item/scalpel,
		/obj/item/hemostat,
		/obj/item/circular_saw,
		/obj/item/retractor,
		/obj/item/cautery
	)

	mail_goodies = list(
		/obj/item/healthanalyzer/advanced = 15,
		/obj/item/scalpel/advanced = 6,
		/obj/item/retractor/advanced = 6,
		/obj/item/surgicaldrill/advanced = 6,
		/datum/reagent/toxin/formaldehyde = 6,
		/obj/effect/spawner/lootdrop/organ_spawner = 5,
//		/obj/effect/spawner/lootdrop/memeorgans = 1
	)

/datum/outfit/job/doctor
	name = "Medical Doctor"
	jobtype = /datum/job/doctor

	belt = /obj/item/pda/medical
	ears = /obj/item/radio/headset/headset_med
	uniform = /obj/item/clothing/under/rank/medical/doctor
	shoes = /obj/item/clothing/shoes/sneakers/white
	suit =  /obj/item/clothing/suit/toggle/labcoat
	l_hand = /obj/item/storage/firstaid/regular
	suit_store = /obj/item/flashlight/pen

	backpack = /obj/item/storage/backpack/medic
	satchel = /obj/item/storage/backpack/satchel/med
	duffelbag = /obj/item/storage/backpack/duffelbag/med

	backpack_contents = list(/obj/item/storage/hypospraykit/regular)

	chameleon_extras = /obj/item/gun/syringe

/datum/outfit/job/doctor/syndicate
	name = "Syndicate Medical Doctor"
	jobtype = /datum/job/doctor

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_med
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	uniform = /obj/item/clothing/under/rank/medical/doctor/util
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	suit =  /obj/item/clothing/suit/toggle/labcoat
	l_hand = /obj/item/storage/firstaid/regular
	suit_store = /obj/item/flashlight/pen

	backpack = /obj/item/storage/backpack/duffelbag/syndie/med
	satchel = /obj/item/storage/backpack/duffelbag/syndie/med
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/med
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/syndicate_uplink=1)
