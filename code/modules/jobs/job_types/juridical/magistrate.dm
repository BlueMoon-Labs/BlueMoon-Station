/datum/job/ntr
	title = "NanoTrasen Representative"
	flag = NTR
	department_head = list("CentCom")
	department_flag = ENGSEC
	auto_deadmin_role_flags = DEADMIN_POSITION_HEAD|DEADMIN_POSITION_SECURITY
	head_announce = list(RADIO_CHANNEL_COMMAND)
	faction = "Station"
	total_positions = 1
	spawn_positions = 1
	minimal_player_age = 35
	supervisors = "Представители Центрального Командования и Космический Закон"
	selection_color = "#7e3d48"
	considered_combat_role = FALSE
	exp_requirements = 180
	exp_type = EXP_TYPE_COMMAND
	req_admin_notify = 1
	custom_spawn_text = "представитель NanoTrasen - должностное лицо, назначенное напрямую Центральным Командованием. Представитель контролирует соблюдение рабочих стандартов и космического закона во всех отделах на станции, консультирует и взаимодействует с главами отделов, а также следит за работой юристов (агентов внутренних дел), отдавая им напрямую приказы и исполняя их прошения. Авторизация увольнений глав, обеспечение связи с ЦК и организация судов аналогично входят в перечень его работ. Представитель ни в коем случае не должен выполнять работу СБ."
	alt_titles = list(
		"Syndicate Representative",
		"Judge",
		"Magistrate",
		"Prosecutor",
		"NanoTrasen Consultant",
		"Syndicate Advisor",
		"Netorare",
		"Commissar",
		"Political Officer",
		"NanoTrasen Slut",
		"Syndicate Slut",
		)

	outfit = /datum/outfit/job/ntr
	plasma_outfit = /datum/outfit/plasmaman/bar
	access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_RESEARCH,  ACCESS_COURT, ACCESS_MAINT_TUNNELS, ACCESS_MORGUE, ACCESS_MEDICAL, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_MINERAL_STOREROOM, ACCESS_CARGO, ACCESS_HEADS, ACCESS_MAILSORTING, ACCESS_ENGINE, ACCESS_HOS, ACCESS_CE, ACCESS_HOP, ACCESS_CMO, ACCESS_QM, ACCESS_RD, ACCESS_CAPTAIN, ACCESS_BLUESHIELD, ACCESS_LAWYER, ACCESS_BAR, ACCESS_JANITOR, ACCESS_KITCHEN, ACCESS_HYDROPONICS, ACCESS_KEYCARD_AUTH)
	minimal_access = list(ACCESS_SECURITY, ACCESS_SEC_DOORS, ACCESS_BRIG, ACCESS_RESEARCH,  ACCESS_COURT, ACCESS_MAINT_TUNNELS, ACCESS_MORGUE, ACCESS_MEDICAL, ACCESS_WEAPONS, ACCESS_ENTER_GENPOP, ACCESS_LEAVE_GENPOP, ACCESS_MINERAL_STOREROOM, ACCESS_CARGO, ACCESS_HEADS, ACCESS_MAILSORTING, ACCESS_ENGINE, ACCESS_HOS, ACCESS_CE, ACCESS_HOP, ACCESS_CMO, ACCESS_QM, ACCESS_RD, ACCESS_CAPTAIN, ACCESS_BLUESHIELD, ACCESS_LAWYER, ACCESS_BAR, ACCESS_JANITOR, ACCESS_KITCHEN, ACCESS_HYDROPONICS)
	paycheck = PAYCHECK_COMMAND
	paycheck_department = ACCOUNT_SEC

	mind_traits = list(TRAIT_LAW_ENFORCEMENT_METABOLISM, TRAIT_FENCER)

	blacklisted_quirks = list(/datum/quirk/mute, /datum/quirk/brainproblems, /datum/quirk/blindness, /datum/quirk/monophobia, /datum/quirk/illiterate, /datum/quirk/onelife)

	display_order = JOB_DISPLAY_ORDER_NTR
	departments = DEPARTMENT_BITFLAG_LAW
	threat = 2

	family_heirlooms = list(
		/obj/item/gavelhammer,
		/obj/item/book/manual/wiki/security_space_law
	)

/obj/item/pda/heads/ntr
	name = "NanoTrasen Representative PDA"
	default_cartridge = /obj/item/cartridge/hos
	icon_state = "pda-ntr"

/obj/item/clothing/suit/armor/ntr
	name = "NanoTrasen Officer Coat"
	desc = "A greatcoat enhanced with a special alloy for some extra protection and style for those with a commanding presence."
	icon_state = "ntr"
	item_state = "ntr"
	icon = 'modular_bluemoon/kovac_shitcode/icons/obj/clothing/suits.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/mob/clothing/suit.dmi'
	anthro_mob_worn_overlay = 'modular_bluemoon/kovac_shitcode/icons/mob/clothing/suit.dmi'
	unique_reskin = list(
		"Syndicate Officer Coat" = list("icon_state" = "str"),
		"Trenchcoat" = list("icon_state" = "detective"),
		"CentCom Officer Coat" = list("icon_state" = "centcom_coat"),
		"Red Coat" = list("icon_state" = "armadyne_trench")
	)

/obj/item/clothing/head/beret/sec/ntr
	name = "NanoTrasen Officer Cap"
	desc = "The standard-issue cap of the NanoTrasen Central Command. For showing the officers and HoS who's in charge."
	icon_state = "ntr"
	item_state = "ntr"
	icon = 'modular_bluemoon/kovac_shitcode/icons/obj/clothing/hats.dmi'
	mob_overlay_icon = 'modular_bluemoon/kovac_shitcode/icons/mob/clothing/head.dmi'

/obj/item/clothing/head/beret/sec/ntr_beret
	name = "NanoTrasen Representative Beret"
	desc = "The standard-issue beret of the NanoTrasen Central Command."
	icon_state = "ntrberet"
	item_state = "ntrberet"

/obj/item/clothing/head/beret/sec/ntr_hat
	name = "nanotrasen consultant's hat"
	desc = "A cap made from durathread, it has an insignia on the front denoting the rank of \"Nanotrasen Consultant\"."
	icon_state = "ntrhat"
	item_state = "ntrhat"

/obj/item/clothing/shoes/laceup/ntr // даем великому и ужасному судье раундстартом ноуслип туфли
	name = "distinguished laceup shoes"
	clothing_flags = NOSLIP

/datum/outfit/job/ntr
	name = "NanoTrasen Representative"
	jobtype = /datum/job/ntr

	belt = /obj/item/pda/heads/ntr
	id = /obj/item/card/id/silver
	ears = /obj/item/radio/headset/headset_cent/ntr
	gloves = /obj/item/clothing/gloves/color/black
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	uniform = /obj/item/clothing/under/rank/centcom/officer_alt
	suit = /obj/item/clothing/suit/armor/ntr
	head = /obj/item/clothing/head/beret/sec/ntr
	shoes = /obj/item/clothing/shoes/laceup/ntr
	r_pocket = /obj/item/pen/fourcolor/ntr

	backpack = /obj/item/storage/backpack/captain/ntr //BLUEMOON add
	satchel = /obj/item/storage/backpack/satchel/cap/ntr //BLUEMOON add
	duffelbag = /obj/item/storage/backpack/duffelbag/captain/ntr //BLUEMOON add

	chameleon_extras = /obj/item/stamp/law

	backpack_contents = list(/obj/item/gun/energy/e_gun=1, /obj/item/stamp/law=1)

	box = /obj/item/storage/box/survival/command

	implants = list(/obj/item/implant/mindshield)

	accessory = list(/obj/item/clothing/accessory/permit/special/representative, /obj/item/clothing/accessory/lawyers_badge)

/datum/outfit/job/ntr/syndicate
	name = "Syndicate Representative"
	jobtype = /datum/job/ntr

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_cent/ntr
	gloves = /obj/item/clothing/gloves/combat
	glasses = /obj/item/clothing/glasses/hud/security/sunglasses
	uniform = /obj/item/clothing/under/rank/centcom/officer_alt
	suit = /obj/item/clothing/suit/armor/ntr
	head = /obj/item/clothing/head/beret/sec/ntr
	shoes = /obj/item/clothing/shoes/laceup/ntr
	l_pocket = /obj/item/melee/classic_baton/telescopic

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	accessory = list(/obj/item/clothing/accessory/permit/special/representative)

	backpack_contents = list(/obj/item/gun/energy/e_gun=1, /obj/item/stamp/law=1, /obj/item/syndicate_uplink=1, /obj/item/pen/fourcolor/ntr)

/datum/outfit/job/ntr/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()

	H.typing_indicator_state = /obj/effect/overlay/typing_indicator/additional/law
