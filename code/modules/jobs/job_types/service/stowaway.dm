GLOBAL_LIST_EMPTY(roundstart_stowaway)

/datum/job/stowaway
	title = "Stowaway"
	flag = STOWAWAY
	department_head = NONE
	department_flag = NONE
	paycheck = 0
	paycheck_department = null
	faction = "Station"
	total_positions = 3
	spawn_positions = 3
	threat = 0.5
	supervisors = "no one"
	minimal_player_age = 3
	exp_requirements = 100
	exp_type = EXP_TYPE_CREW
	considered_combat_role = FALSE
	custom_spawn_text = "вы - <b>безбилетный</b> пассажир. Вы НЕ должны начинать драки или пытаться бороться с охраной по какой-либо причине. В лучшем случае вы должны активно убегать от них, поскольку находитесь на станции нелегально."
	outfit = /datum/outfit/job/stowaway
	plasma_outfit = /datum/outfit/plasmaman/stowaway
	display_order = JOB_DISPLAY_ORDER_STOWAWAY
	alt_titles = list(
		"Escapist",
		"Fraudster",
		"Hobo",
		"Jigolo",
		"Migrant",
		"Proshmandovka",
		"Refugee",
		"Tunnel Warrior",
		"Savage",
		"Outcast",
		)

/datum/job/stowaway/get_roundstart_spawn_point()
	return get_latejoin_spawn_point()

/datum/outfit/job/stowaway/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()
	var/suited = !preference_source || preference_source.prefs.jumpsuit_style == PREF_SUIT
	uniform = suited ? /obj/item/clothing/under/color/random : /obj/item/clothing/under/color/jumpskirt/random

/obj/item/card/id/stowaway_stolen
	name = "Unknown ID Card"
	desc = "An strange-looking old ID card."
	icon_state = "data_1"
	uses_overlays = FALSE
	registered_name = null
	assignment = null
	access = list(ACCESS_MAINT_TUNNELS)
	bank_support = ID_NO_BANK_ACCOUNT

/datum/outfit/job/stowaway
	name = "Stowaway"
	jobtype = /datum/job/stowaway

	uniform = /obj/item/clothing/under/color/random
	shoes = /obj/item/clothing/shoes/sneakers/black
	id = /obj/item/card/id/stowaway_stolen
	ears = null
	belt = /obj/item/storage/belt/utility/atmostech
	gloves = /obj/item/clothing/gloves/color/yellow
	r_pocket = /obj/item/radio
	l_pocket = /obj/item/flashlight

/datum/outfit/job/stowaway/syndicate
	name = "Syndicate Stowaway"
	jobtype = /datum/job/stowaway

	id = /obj/item/card/id/stowaway_stolen

	uniform = /obj/item/clothing/under/syndicate/combat
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	ears = null
	belt = /obj/item/storage/belt/utility/atmostech
	gloves = /obj/item/clothing/gloves/color/yellow
	r_pocket = /obj/item/radio
	l_pocket = /obj/item/flashlight

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie

/datum/outfit/plasmaman/stowaway
	name = "Stowaway Plasmaman"
	shoes = /obj/item/clothing/shoes/sneakers/black
	id = /obj/item/card/id/stowaway_stolen
	ears = null
	belt = /obj/item/storage/belt/utility/full
	gloves = /obj/item/clothing/gloves/color/yellow
	r_pocket = /obj/item/radio
	l_pocket = /obj/item/flashlight

