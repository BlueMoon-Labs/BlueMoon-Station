/datum/job/blueshield
	title = "Blueshield"
	flag = BLUESHIELD
	department_head = list("CentCom")
	department_flag = ENGSEC
	faction = "Station"
	head_announce = list(RADIO_CHANNEL_COMMAND)
	supervisors = "Центрального Командования"
	total_positions = 2
	spawn_positions = 2
	selection_color = "#aac1ee"
	minimal_player_age = 7
	exp_requirements = 1500
	exp_type = EXP_TYPE_SECURITY
	considered_combat_role = TRUE //Brigger then shit yes it is
	exp_type_department = EXP_TYPE_SECURITY
	alt_titles = list("NT Management Defender", "Syndicate Prime-Defender", "Command Security", "Command Guard", "Command Bodyguard", "Sweet Boy", "Sweet Girl", "Combat Maid", "Syndicate Combat Maid", "Penis Case", "Blueguard", "Blueshit", "Captain Mattress", "Blueslut", "Red Shield")
	custom_spawn_text = "офицер Синего Щита является представителем сторон отдела по защите Главенствующего Персонала в соответствии приоритету - от <b>секретаря мостика</b> до <b>капитана</b>. Офицер Синего Щита подчиняется <b>ВрИО капитана</b>, <b>капитану</b> и Центральному Командованию."

	outfit = /datum/outfit/job/blueshield
	plasma_outfit = /datum/outfit/plasmaman/blueshield

	access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_RESEARCH,  ACCESS_COURT, ACCESS_MAINT_TUNNELS, ACCESS_MORGUE, ACCESS_MEDICAL, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_MINERAL_STOREROOM, ACCESS_CARGO, ACCESS_HEADS, ACCESS_MAILSORTING, ACCESS_ENGINE, ACCESS_HOS, ACCESS_CE, ACCESS_CMO, ACCESS_QM, ACCESS_RD, ACCESS_BLUESHIELD)
	minimal_access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_RESEARCH,  ACCESS_COURT, ACCESS_MAINT_TUNNELS, ACCESS_MORGUE, ACCESS_MEDICAL, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_MINERAL_STOREROOM, ACCESS_CARGO, ACCESS_HEADS, ACCESS_MAILSORTING, ACCESS_ENGINE, ACCESS_HOS, ACCESS_CE, ACCESS_CMO, ACCESS_QM, ACCESS_RD, ACCESS_BLUESHIELD)
	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_SEC

	mind_traits = list(TRAIT_LAW_ENFORCEMENT_METABOLISM)

	display_order = JOB_DISPLAY_ORDER_BLUESHIELD
	departments = DEPARTMENT_BITFLAG_COMMAND
	blacklisted_quirks = list(/datum/quirk/mute, /datum/quirk/brainproblems, /datum/quirk/nonviolent, /datum/quirk/blindness, /datum/quirk/monophobia, /datum/quirk/insanity, /datum/quirk/onelife)
	threat = 3


/datum/outfit/job/blueshield
	name = "Blueshield"
	jobtype = /datum/job/blueshield

	belt = /obj/item/pda/security
	ears = /obj/item/radio/headset/headset_blueshield
	uniform = /obj/item/clothing/under/rank/blueshield
	head = /obj/item/clothing/head/helmet/sec/blueshield
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	glasses = /obj/item/clothing/glasses/hud/blueshield
	suit = /obj/item/clothing/suit/armor/vest/bluesheid
	shoes = /obj/item/clothing/shoes/jackboots
	suit_store = /obj/item/kitchen/knife/combat
	r_pocket = /obj/item/sensor_device_command
	backpack_contents = list(/obj/item/storage/firstaid/regular, /obj/item/storage/box/death_alert, /obj/item/storage/box/blue_shield_hs, /obj/item/storage/box/sec_kit,  /obj/item/choice_beacon/hosgun, /obj/item/choice_beacon/bsbaton)
	accessory = list(/obj/item/clothing/accessory/permit/special/blueshield, /obj/item/clothing/accessory/badge/holo)

	backpack = /obj/item/storage/backpack/blueshield
	satchel = /obj/item/storage/backpack/satchel/blueshield
	duffelbag = /obj/item/storage/backpack/duffelbag/blueshield
	box = /obj/item/storage/box/survival/security/radio

	implants = list(/obj/item/implant/mindshield)

	chameleon_extras = list(/obj/item/storage/firstaid/regular, /obj/item/kitchen/knife/combat)

/datum/outfit/job/blueshield/syndicate
	name = "Syndicate Blueshield"
	jobtype = /datum/job/blueshield

	//belt = /obj/item/pda/syndicate/no_deto
	ears = /obj/item/radio/headset/headset_blueshield
	uniform = /obj/item/clothing/under/rank/blueshield
	head = /obj/item/clothing/head/helmet/sec/blueshield
	gloves = /obj/item/clothing/gloves/tackler/combat/insulated
	glasses = /obj/item/clothing/glasses/hud/blueshield
	suit = /obj/item/clothing/suit/armor/vest/bluesheid
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	suit_store = /obj/item/kitchen/knife/combat
	l_pocket = /obj/item/sensor_device_command
	backpack_contents = list(/obj/item/storage/firstaid/regular, /obj/item/storage/box/death_alert, /obj/item/storage/box/blue_shield_hs, /obj/item/storage/box/sec_kit,  /obj/item/choice_beacon/hosgun, /obj/item/choice_beacon/bsbaton, /obj/item/syndicate_uplink_high)
	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	accessory = list(/obj/item/clothing/accessory/permit/special/blueshield, /obj/item/clothing/accessory/badge/holo)
	pda_slot = ITEM_SLOT_BELT

/datum/outfit/plasmaman/blueshield
	name = "Blueshield"

	head = /obj/item/clothing/head/helmet/space/plasmaman/security/blueshield //Ported the ones from fucking Skyrat
	uniform = /obj/item/clothing/under/plasmaman/security/blueshield
	ears = /obj/item/radio/headset/headset_blueshield
	accessory = list(/obj/item/clothing/accessory/permit/special/blueshield, /obj/item/clothing/accessory/badge/holo)

/obj/item/radio/headset/headset_blueshield
	name = "blueshield bowman headset"
	desc = "This is used by the blueshield. It protects from flashbangs"
	icon_state = "com_headset_alt"
	item_state = "com_headset_alt"
	keyslot = new /obj/item/encryptionkey/headset_blueshield
	bowman = TRUE
	command = TRUE


/obj/item/encryptionkey/headset_blueshield
	name = "blueshield radio encryption key"
	icon_state = "com_cypherkey"
	channels = list(RADIO_CHANNEL_COMMAND = 1, RADIO_CHANNEL_SECURITY = 1, RADIO_CHANNEL_MEDICAL = 1)

/obj/effect/landmark/start/blueshield
	name = "Blueshield"
	icon_state = "Security Officer"

/area/command/blueshieldoffice
	name = "Blueshield's Office"
	icon_state = "bridge"

/area/command/blueshielquarters
	name = "Blueshield's Quarters"
	icon_state = "bridge"

/area/command/blueshielquarters2
	name = "Blueshield's Quarters"
	icon_state = "bridge"

/area/command/blueshielquarters3
	name = "Blueshield's Quarters"
	icon_state = "bridge"

//BLUEMOON CHANGE однородность для cqc с ограниченой зоной использования
///Subtype of CQC. Only used for the Blueshield.
/datum/martial_art/cqc/restricted/blueshield
	name = "Close Quarters Combat, Blueshield Edition"
	valid_areas = list(/area/command, /area/command/bridge, /area/command/meeting_room, /area/command/meeting_room/council,
								/area/command/heads_quarters/captain, /area/command/heads_quarters/ce, /area/command/heads_quarters/ce/private,
								/area/command/heads_quarters/cmo, /area/command/heads_quarters/cmo/private, /area/command/heads_quarters/hop,
								/area/command/heads_quarters/hop/private, /area/command/heads_quarters/hos, /area/command/heads_quarters/hos/private,
								/area/command/heads_quarters/rd, /area/command/heads_quarters/rd/private, /area/command/teleporter, /area/command/gateway,
								/area/command/corporate_showroom)

/datum/outfit/job/blueshield/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()
	if(visualsOnly)
		return
	var/datum/martial_art/cqc/restricted/blueshield/justablue = new
	justablue.teach(H)
//BLUEMOON CHANGE END
