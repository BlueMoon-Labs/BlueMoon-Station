/datum/job/hos
	title = "Head of Security"
	flag = HOS
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD|DEADMIN_POSITION_SECURITY
	department_head = list("Captain")
	department_flag = ENGSEC
	head_announce = list(RADIO_CHANNEL_SECURITY)
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "the captain"
	selection_color = "#b90000"
	req_admin_notify = 1
	minimal_player_age = 35
	exp_requirements = 5000
	exp_type = EXP_TYPE_CREW
	considered_combat_role = TRUE
	exp_type_department = EXP_TYPE_SECURITY

	outfit = /datum/outfit/job/hos
	departments = DEPARTMENT_BITFLAG_SECURITY | DEPARTMENT_BITFLAG_COMMAND
	plasma_outfit = /datum/outfit/plasmaman/hos

	mind_traits = list(TRAIT_LAW_ENFORCEMENT_METABOLISM)

	access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_COURT, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP,
						ACCESS_FORENSICS_LOCKERS, ACCESS_MORGUE, ACCESS_MAINT_TUNNELS, ACCESS_ALL_PERSONAL_LOCKERS,
						ACCESS_RESEARCH, ACCESS_ENGINE, ACCESS_MINING, ACCESS_MEDICAL, ACCESS_CONSTRUCTION, ACCESS_MAILSORTING,
						ACCESS_HEADS, ACCESS_HOS, ACCESS_RC_ANNOUNCE, ACCESS_KEYCARD_AUTH, ACCESS_GATEWAY, ACCESS_MAINT_TUNNELS, ACCESS_MINERAL_STOREROOM, ACCESS_BRIGDOC)
	minimal_access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_ARMORY, ACCESS_COURT, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP,
						ACCESS_FORENSICS_LOCKERS, ACCESS_MORGUE, ACCESS_MAINT_TUNNELS, ACCESS_ALL_PERSONAL_LOCKERS,
						ACCESS_RESEARCH, ACCESS_ENGINE, ACCESS_MINING, ACCESS_MEDICAL, ACCESS_CONSTRUCTION, ACCESS_MAILSORTING,
						ACCESS_HEADS, ACCESS_HOS, ACCESS_RC_ANNOUNCE, ACCESS_KEYCARD_AUTH, ACCESS_GATEWAY, ACCESS_MAINT_TUNNELS, ACCESS_MINERAL_STOREROOM, ACCESS_BRIGDOC)
	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_SEC
	bounty_types = CIV_JOB_SEC


	display_order = JOB_DISPLAY_ORDER_HEAD_OF_SECURITY
	blacklisted_quirks = list(/datum/quirk/mute, /datum/quirk/brainproblems, /datum/quirk/nonviolent, /datum/quirk/blindness, /datum/quirk/monophobia, /datum/quirk/insanity, /datum/quirk/illiterate, /datum/quirk/onelife)
	threat = 3

	family_heirlooms = list(
		/obj/item/book/manual/wiki/security_space_law
	)

/datum/outfit/job/hos
	name = "Head of Security"
	jobtype = /datum/job/hos

	id = /obj/item/card/id/silver
	belt = /obj/item/pda/heads/hos
	ears = /obj/item/radio/headset/heads/hos/alt
	uniform = /obj/item/clothing/under/rank/security/head_of_security
	shoes = /obj/item/clothing/shoes/jackboots/sec
	suit = /obj/item/clothing/suit/armor/hos/trenchcoat
	gloves = /obj/item/clothing/gloves/combat
	head = /obj/item/clothing/head/HoS/beret
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	//suit_store = /obj/item/gun/energy/e_gun
	l_pocket = /obj/item/storage/bag/security
	r_pocket = /obj/item/modular_computer/tablet/preset/advanced
	backpack_contents = list(/obj/item/storage/box/sec_kit, /obj/item/choice_beacon/hos_new_weapon = 1)
	box = /obj/item/storage/box/survival/command
	accessory = list(/obj/item/clothing/accessory/permit/special/head_of_sec, /obj/item/clothing/accessory/badge)

	satchel = /obj/item/storage/backpack/satchel/sec
	duffelbag = /obj/item/storage/backpack/duffelbag/sec
	box = /obj/item/storage/box/survival/command

	implants = list(/obj/item/implant/mindshield)

	chameleon_extras = list(/obj/item/gun/energy/e_gun/hos, /obj/item/stamp/hos)

/datum/outfit/job/hos/syndicate
	name = "Syndicate Head of Security"
	jobtype = /datum/job/hos

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/heads/hos/alt
	uniform = /obj/item/clothing/under/rank/captain/util
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	suit = /obj/item/clothing/suit/armor/hos/trenchcoat
	gloves = /obj/item/clothing/gloves/combat
	head = /obj/item/clothing/head/HoS/beret
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	neck = /obj/item/clothing/neck/cloak/syndiecap
	r_pocket = /obj/item/assembly/flash/handheld
	l_pocket = /obj/item/restraints/handcuffs

	backpack = /obj/item/storage/backpack/duffelbag/syndie/ammo
	satchel = /obj/item/storage/backpack/duffelbag/syndie/ammo
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/ammo
	box = /obj/item/storage/box/survival/syndie
	accessory = list(/obj/item/clothing/accessory/permit/special/head_of_sec)
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/syndicate_uplink_high=1)

/datum/outfit/job/hos/hardsuit
	name = "Head of Security (Hardsuit)"

	mask = /obj/item/clothing/mask/gas/sechailer
	suit = /obj/item/clothing/suit/space/hardsuit/security/hos
	suit_store = /obj/item/tank/internals/oxygen
	backpack_contents = list(/obj/item/melee/baton/loaded=1)

/datum/outfit/job/hos/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	H.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/law

// BLUEMOON ADD START - командная коробочка для командира
/datum/outfit/job/hos/pre_equip(mob/living/carbon/human/H, visualsOnly, client/preference_source)
	. = ..()
	var/list/extra_backpack_items = list(
		/obj/item/storage/box/pinpointer_squad
	)
	LAZYADD(backpack_contents, extra_backpack_items)
// BLUEMOON ADD END
