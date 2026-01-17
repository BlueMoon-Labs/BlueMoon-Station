/datum/job/warden
	title = "Warden"
	flag = WARDEN
	auto_deadmin_role_flags = DEADMIN_POSITION_SECURITY
	department_head = list("Head of Security")
	department_flag = ENGSEC
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "the head of security"
	selection_color = "#c02f2f"
	minimal_player_age = 7
	exp_requirements = 3000
	exp_type = EXP_TYPE_SECURITY
	considered_combat_role = TRUE

	outfit = /datum/outfit/job/warden
	plasma_outfit = /datum/outfit/plasmaman/warden

	access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_COURT, ACCESS_MAINT_TUNNELS, ACCESS_MORGUE, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_FORENSICS_LOCKERS, ACCESS_MINERAL_STOREROOM, ACCESS_BRIGDOC)
	minimal_access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_COURT, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_MINERAL_STOREROOM, ACCESS_BRIGDOC) // See /datum/job/warden/get_access()

	paycheck = PAYCHECK_HARD
	paycheck_department = ACCOUNT_SEC
	bounty_types = CIV_JOB_SEC
	departments = DEPARTMENT_BITFLAG_SECURITY

	mind_traits = list(TRAIT_LAW_ENFORCEMENT_METABOLISM)

	display_order = JOB_DISPLAY_ORDER_WARDEN
	blacklisted_quirks = list(/datum/quirk/mute, /datum/quirk/brainproblems, /datum/quirk/nonviolent, /datum/quirk/blindness, /datum/quirk/monophobia, /datum/quirk/illiterate, /datum/quirk/onelife)
	threat = 2

	family_heirlooms = list(
		/obj/item/book/manual/wiki/security_space_law
	)

	mail_goodies = list(
		/obj/item/storage/fancy/cigarettes = 15,
		/obj/item/storage/box/handcuffs = 10,
		/obj/item/storage/box/teargas = 10,
		/obj/item/storage/box/flashbangs = 10,
		/obj/item/storage/box/rubbershot = 10,
		/obj/item/storage/box/lethalshot = 5
	)

/datum/job/warden/get_access()
	var/list/L = list()
	L = ..() | check_config_for_sec_maint()
	return L

/datum/outfit/job/warden
	name = "Warden"
	jobtype = /datum/job/warden

	belt = /obj/item/pda/warden
	ears = /obj/item/radio/headset/headset_sec/alt
	uniform = /obj/item/clothing/under/rank/security/warden
	shoes = /obj/item/clothing/shoes/jackboots/sec
	suit = /obj/item/clothing/suit/armor/vest/warden/alt
	gloves = /obj/item/clothing/gloves/color/black
	head = /obj/item/clothing/head/warden
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	l_pocket = /obj/item/storage/bag/security
	r_pocket = /obj/item/reagent_containers/peacehypo
	suit_store = /obj/item/gun/energy/pumpaction/defender
	backpack_contents = list(/obj/item/storage/box/sec_kit)

	backpack = /obj/item/storage/backpack/security
	satchel = /obj/item/storage/backpack/satchel/sec
	duffelbag = /obj/item/storage/backpack/duffelbag/sec
	box = /obj/item/storage/box/survival/security
	accessory = list(/obj/item/clothing/accessory/permit/special/security, /obj/item/clothing/accessory/badge)

	implants = list(/obj/item/implant/mindshield)

	chameleon_extras = /obj/item/gun/ballistic/shotgun/automatic/combat/warden

/datum/outfit/job/warden/syndicate
	name = "Syndicate Warden"
	jobtype = /datum/job/warden

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_sec/alt
	uniform = /obj/item/clothing/under/rank/security/officer/util
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	suit = /obj/item/clothing/suit/armor/vest/warden/alt
	gloves = /obj/item/clothing/gloves/combat
	head = /obj/item/clothing/head/warden
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	r_pocket = /obj/item/reagent_containers/peacehypo
	l_pocket = /obj/item/restraints/handcuffs
	suit_store = /obj/item/gun/energy/pumpaction/defender
	backpack_contents = list(/obj/item/syndicate_uplink_high=1)
	accessory = list(/obj/item/clothing/accessory/permit/special/security)

	backpack = /obj/item/storage/backpack/duffelbag/syndie/ammo
	satchel = /obj/item/storage/backpack/duffelbag/syndie/ammo
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/ammo
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
