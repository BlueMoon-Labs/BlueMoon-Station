/datum/job/chief_engineer
	title = "Chief Engineer"
	flag = CHIEF
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD
	department_head = list("Captain")
	department_flag = ENGSEC
	head_announce = list(RADIO_CHANNEL_ENGINEERING)
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	supervisors = "the captain"
	selection_color = "#ee7400"
	req_admin_notify = 1
	minimal_player_age = 35
	exp_requirements = 180
	exp_type = EXP_TYPE_CREW
	exp_type_department = EXP_TYPE_ENGINEERING
	considered_combat_role = TRUE

	outfit = /datum/outfit/job/ce
	departments = DEPARTMENT_BITFLAG_ENGINEERING | DEPARTMENT_BITFLAG_COMMAND
	plasma_outfit = /datum/outfit/plasmaman/ce

	access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_TECH_STORAGE, ACCESS_MAINT_TUNNELS,
						ACCESS_EXTERNAL_AIRLOCKS, ACCESS_ATMOSPHERICS, ACCESS_EVA,
						ACCESS_HEADS, ACCESS_CONSTRUCTION, ACCESS_SEC_DOORS, ACCESS_MINISAT,
						ACCESS_CE, ACCESS_RC_ANNOUNCE, ACCESS_KEYCARD_AUTH, ACCESS_TCOMSAT, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_ENGINE, ACCESS_ENGINE_EQUIP, ACCESS_TECH_STORAGE, ACCESS_MAINT_TUNNELS,
						ACCESS_EXTERNAL_AIRLOCKS, ACCESS_ATMOSPHERICS, ACCESS_EVA,
						ACCESS_HEADS, ACCESS_CONSTRUCTION, ACCESS_SEC_DOORS, ACCESS_MINISAT,
						ACCESS_CE, ACCESS_RC_ANNOUNCE, ACCESS_KEYCARD_AUTH, ACCESS_TCOMSAT, ACCESS_MINERAL_STOREROOM)
	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_ENG
	bounty_types = CIV_JOB_ENG

	starting_modifiers = list(/datum/skill_modifier/job/level/wiring/master, /datum/skill_modifier/job/affinity/wiring) //BLUEMOON CHANGE job/level to master

	mind_traits = list(TRAIT_KNOW_ENGI_WIRES) //BLUEMOON ADD use #define TRAIT system

	display_order = JOB_DISPLAY_ORDER_CHIEF_ENGINEER
	blacklisted_quirks = list(/datum/quirk/mute, /datum/quirk/brainproblems, /datum/quirk/insanity, /datum/quirk/illiterate)
	threat = 2

	family_heirlooms = list(
		/obj/item/clothing/head/hardhat,
		/obj/item/screwdriver/brass/family,
		/obj/item/wrench/brass/family,
		/obj/item/weldingtool/mini, // No brass family variant
		/obj/item/crowbar/brass/family,
		/obj/item/wirecutters/brass/family
	)

	mail_goodies = list(
		/obj/item/reagent_containers/food/snacks/cracker = 25, //you know. for poly
		/obj/item/stack/sheet/mineral/diamond = 15,
		/obj/item/stack/sheet/mineral/uranium/five = 15,
		/obj/item/stack/sheet/mineral/plasma/five = 15,
		/obj/item/stack/sheet/mineral/gold = 15,
		/obj/effect/spawner/lootdrop/space/fancytool/engineonly = 3
	)

/datum/outfit/job/ce
	name = "Chief Engineer"
	jobtype = /datum/job/chief_engineer

	id = /obj/item/card/id/silver
	belt = /obj/item/storage/belt/utility/chief/full
	l_pocket = /obj/item/pda/heads/ce
	ears = /obj/item/radio/headset/heads/ce
	uniform = /obj/item/clothing/under/rank/engineering/chief_engineer
	shoes = /obj/item/clothing/shoes/sneakers/brown
	head = /obj/item/clothing/head/hardhat/white
	gloves = /obj/item/clothing/gloves/color/black
	backpack_contents = list(/obj/item/modular_computer/tablet/preset/advanced=1)
	accessory = list(/obj/item/clothing/accessory/permit/special/chief_engineer)

	backpack = /obj/item/storage/backpack/industrial
	satchel = /obj/item/storage/backpack/satchel/eng
	duffelbag = /obj/item/storage/backpack/duffelbag/engineering
	box = /obj/item/storage/box/survival/command
	pda_slot = ITEM_SLOT_LPOCKET
	chameleon_extras = /obj/item/stamp/ce

/datum/outfit/job/ce/syndicate
	name = "Syndicate Chief Engineer"
	jobtype = /datum/job/chief_engineer

	//l_pocket = /obj/item/pda/syndicate/no_deto

	belt = /obj/item/storage/belt/utility/chief/full
	ears = /obj/item/radio/headset/heads/ce
	uniform = /obj/item/clothing/under/rank/captain/util
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	head = /obj/item/clothing/head/hardhat/red/upgraded
	gloves = /obj/item/clothing/gloves/combat
	neck = /obj/item/clothing/neck/cloak/syndiecap
	backpack_contents = list(/obj/item/melee/classic_baton/telescopic=1, /obj/item/modular_computer/tablet/preset/advanced=1, /obj/item/syndicate_uplink_high=1)
	accessory = list(/obj/item/clothing/accessory/permit/special/chief_engineer)

	backpack = /obj/item/storage/backpack/duffelbag/syndie/ammo
	satchel = /obj/item/storage/backpack/duffelbag/syndie/ammo
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/ammo
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_LPOCKET
	chameleon_extras = /obj/item/stamp/ce

/datum/outfit/job/ce/rig
	name = "Chief Engineer (Hardsuit)"

	mask = /obj/item/clothing/mask/breath
	suit = /obj/item/clothing/suit/space/hardsuit/engine/elite
	shoes = /obj/item/clothing/shoes/magboots/advance
	suit_store = /obj/item/tank/internals/oxygen
	glasses = /obj/item/clothing/glasses/meson/engine
	gloves = /obj/item/clothing/gloves/color/yellow
	head = null
	internals_slot = ITEM_SLOT_SUITSTORE
