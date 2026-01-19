/datum/job/brigdoc
	title = "Brig Physician"
	flag = BRIGDOC
//	auto_deadmin_role_flags = DEADMIN_POSITION_SECURITY
	department_head = list("Head of Security")
	department_flag = ENGSEC
	faction = "Station"
	total_positions = 2 //Handled in /datum/controller/occupations/proc/setup_officer_positions()
	spawn_positions = 2 //Handled in /datum/controller/occupations/proc/setup_officer_positions()
	supervisors = "the head of security, and the head of your assigned department (if applicable)"
	selection_color = "#c02f2f"
	minimal_player_age = 7
	exp_requirements = 3000
	exp_type = EXP_TYPE_MEDICAL
	considered_combat_role = TRUE
	exp_type_department = EXP_TYPE_MEDICAL
	alt_titles = list("NT Safeguard Physician", "Syndicate Field Medic", "Security Doctor", "Security Medic", "Brig Doctor", "Brig EMT", "Security Physician", "Security EMT", "Slutcurity Nurse", "Fucking Slave", "Well-Trained Girl", "Well-Trained Boy", "Trauma Team", "Security Corpsman", "AC Combat Medic", "Field Medic of Interdyne", "Syndicate Corpsman", "SAARE Corpsman")


	outfit = /datum/outfit/job/brigdoc
	plasma_outfit = /datum/outfit/plasmaman/brigdoc

	access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_COURT, ACCESS_MAINT_TUNNELS, ACCESS_MORGUE, ACCESS_MEDICAL, ACCESS_SURGERY, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_FORENSICS_LOCKERS, ACCESS_MINERAL_STOREROOM, ACCESS_BRIGDOC)
	minimal_access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_COURT, ACCESS_MAINT_TUNNELS, ACCESS_MORGUE, ACCESS_MEDICAL, ACCESS_SURGERY, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_FORENSICS_LOCKERS, ACCESS_MINERAL_STOREROOM, ACCESS_BRIGDOC)
	paycheck = PAYCHECK_MEDIUM
	paycheck_department = ACCOUNT_SEC
	bounty_types = CIV_JOB_MED

	mind_traits = list(TRAIT_LAW_ENFORCEMENT_METABOLISM, TRAIT_KNOW_MED_SURGERY_T2) //BLUEMOON EDIT added surgery trait

	display_order = JOB_DISPLAY_ORDER_BRIG_PHYSICIAN
	blacklisted_quirks = list(/datum/quirk/mute, /datum/quirk/brainproblems, /datum/quirk/blindness, /datum/quirk/monophobia, /datum/quirk/onelife)
	threat = 2

/datum/outfit/job/brigdoc
	name = "Brig Physician"
	jobtype = /datum/job/brigdoc

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/headset_brigdoc/alt
	uniform = /obj/item/clothing/under/syndicate/brigdoc
	gloves = /obj/item/clothing/gloves/color/latex
	glasses = /obj/item/clothing/glasses/hud/health/sunglasses
	suit = /obj/item/clothing/suit/armor/brigdoc
	shoes = /obj/item/clothing/shoes/jackboots
	backpack_contents = list(
		/obj/item/storage/hypospraykit/regular,
		/obj/item/storage/firstaid/regular,
		/obj/item/sensor_device_security,
		/obj/item/melee/classic_baton/telescopic,
		/obj/item/choice_beacon/copgun
		)

	backpack = /obj/item/storage/backpack/security
	satchel = /obj/item/storage/backpack/satchel/sec
	duffelbag = /obj/item/storage/backpack/duffelbag/sec
	box = /obj/item/storage/box/survival/security

	implants = list(/obj/item/implant/mindshield)

	accessory = list(/obj/item/clothing/accessory/permit/special/security)

	chameleon_extras = list(/obj/item/storage/firstaid/regular)

/datum/outfit/job/brigdoc/syndicate
	name = "Syndicate Brig Physician"
	jobtype = /datum/job/brigdoc

	//belt = /obj/item/pda/syndicate/no_deto

	uniform = /obj/item/clothing/under/rank/security/officer/util
	gloves = /obj/item/clothing/gloves/color/latex/nitrile/hsc
	glasses = /obj/item/clothing/glasses/hud/health/sunglasses
	suit = /obj/item/clothing/suit/armor/brigdoc
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	l_pocket = /obj/item/reagent_containers/spray/pepper
	r_pocket = /obj/item/assembly/flash/handheld
	backpack_contents = list(/obj/item/storage/hypospraykit/regular,
							/obj/item/storage/firstaid/regular,
							/obj/item/melee/classic_baton/telescopic,
							/obj/item/sensor_device_security,
							/obj/item/choice_beacon/copgun,
							/obj/item/syndicate_uplink_high=1
							)
	backpack = /obj/item/storage/backpack/duffelbag/syndie/med
	satchel = /obj/item/storage/backpack/duffelbag/syndie/med
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/med
	box = /obj/item/storage/box/survival/syndie
	accessory = list(/obj/item/clothing/accessory/permit/special/security)
	pda_slot = ITEM_SLOT_BELT

/datum/outfit/plasmaman/brigdoc
	name = "Brig Physician"

	head = /obj/item/clothing/head/helmet/space/plasmaman/medical
	uniform = /obj/item/clothing/under/plasmaman/medical
	ears = /obj/item/radio/headset/headset_brigdoc

/obj/item/radio/headset/headset_brigdoc
	name = "brig physician  radio headset"
	desc = "This is used by your elite security force's brig physician."
	icon_state = "sec_headset"
	keyslot = new /obj/item/encryptionkey/headset_brigdoc

/obj/item/radio/headset/headset_brigdoc/alt
	name = "brig physician bowman headset"
	desc = "This is used by your elite security force's brig physician. Protects ears from flashbangs."
	icon_state = "sec_headset_alt"
	item_state = "sec_headset_alt"
	bowman = TRUE

/obj/item/encryptionkey/headset_brigdoc
	name = "brig physician radio encryption key"
	icon_state = "sec_cypherkey"
	channels = list(RADIO_CHANNEL_SECURITY = 1, RADIO_CHANNEL_MEDICAL = 1)

/obj/effect/landmark/start/brigdoc
	name = "Brig Physician"
	icon_state = "Security Officer"
