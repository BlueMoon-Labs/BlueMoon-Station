/datum/job/lawyer
	title = "Internal Affairs Agent"
	flag = LAWYER
	department_head = list("NanoTrasen Representative")
	department_flag = ENGSEC
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "the Corporation Representative"
	selection_color = "#7e3d48"
	considered_combat_role = TRUE
	exp_requirements = 100
	exp_type = EXP_TYPE_SECURITY

	outfit = /datum/outfit/job/lawyer
	plasma_outfit = /datum/outfit/plasmaman/bar //yes, this is correct, there's no 'lawyer' plasmeme outfit

	access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_COURT, ACCESS_MAINT_TUNNELS, ACCESS_MORGUE, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_FORENSICS_LOCKERS, ACCESS_MINERAL_STOREROOM, ACCESS_MAILSORTING, ACCESS_LAWYER, ACCESS_MEDICAL, ACCESS_RESEARCH, ACCESS_CARGO, ACCESS_ENGINE, ACCESS_HEADS)
	minimal_access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_COURT, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_MINERAL_STOREROOM, ACCESS_MAILSORTING, ACCESS_LAWYER, ACCESS_MEDICAL, ACCESS_RESEARCH, ACCESS_CARGO, ACCESS_ENGINE, ACCESS_HEADS)

	paycheck = PAYCHECK_HARD
	paycheck_department = ACCOUNT_SEC

	mind_traits = list(TRAIT_LAW_ENFORCEMENT_METABOLISM)

	blacklisted_quirks = list(/datum/quirk/mute, /datum/quirk/brainproblems, /datum/quirk/blindness, /datum/quirk/monophobia, /datum/quirk/illiterate)

	display_order = JOB_DISPLAY_ORDER_LAWYER
	departments = DEPARTMENT_BITFLAG_LAW
	threat = 0.3

	family_heirlooms = list(
		/obj/item/gavelhammer,
		/obj/item/storage/briefcase/lawyer/family,
		/obj/item/book/manual/wiki/security_space_law
	)

/datum/outfit/job/lawyer
	name = "Internal Affairs Agent"
	jobtype = /datum/job/lawyer

	belt = /obj/item/pda/lawyer
	ears = /obj/item/radio/headset/headset_law
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	uniform = /obj/item/clothing/under/rank/civilian/lawyer/really_black
	//suit = /obj/item/clothing/suit/toggle/lawyer/black
	shoes = /obj/item/clothing/shoes/laceup
	l_pocket = /obj/item/laser_pointer
	r_pocket = /obj/item/modular_computer/tablet/preset/advanced

	backpack = /obj/item/storage/backpack/security
	satchel = /obj/item/storage/backpack/satchel/sec
	duffelbag = /obj/item/storage/backpack/duffelbag/sec

	chameleon_extras = /obj/item/stamp/law

	backpack_contents = list(/obj/item/stamp/law=1, /obj/item/gun/energy/civilian=1)

	box = /obj/item/storage/box/survival/command
	accessory = list(/obj/item/clothing/accessory/permit/special/lawyer, /obj/item/clothing/accessory/lawyers_badge)

	implants = list(/obj/item/implant/mindshield)

/datum/outfit/job/lawyer/syndicate
	name = "Syndicate Internal Affairs Agent"
	jobtype = /datum/job/lawyer

	//belt = /obj/item/pda/syndicate/no_deto

	belt = /obj/item/pda/lawyer
	ears = /obj/item/radio/headset/headset_law
	gloves = /obj/item/clothing/gloves/combat
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	uniform = /obj/item/clothing/under/rank/civilian/lawyer/really_black
	//suit = /obj/item/clothing/suit/toggle/lawyer/black
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	l_pocket = /obj/item/laser_pointer
	r_pocket = /obj/item/syndicate_uplink

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	accessory = list(/obj/item/clothing/accessory/permit/special/lawyer, /obj/item/clothing/accessory/lawyers_badge)

	backpack_contents = list(/obj/item/gun/energy/e_gun=1, /obj/item/stamp/law=1)

/datum/outfit/job/lawyer/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	H.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/law
