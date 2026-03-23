/*
Assistant
*/
/datum/job/assistant
	title = "Assistant"
	flag = ASSISTANT
	department_flag = CIVILIAN
	faction = "Station"
	total_positions = 50
	spawn_positions = 50
	supervisors = "absolutely everyone"
	selection_color = "#dddddd"
	access = list()			//See /datum/job/assistant/get_access()
	minimal_access = list()	//See /datum/job/assistant/get_access()
	outfit = /datum/outfit/job/assistant
	antag_rep = 7
	paycheck = PAYCHECK_ASSISTANT // Get a job. Job reassignment changes your paycheck now. Get over it.
	paycheck_department = ACCOUNT_CIV
	departments = DEPARTMENT_BITFLAG_SERVICE
	display_order = JOB_DISPLAY_ORDER_ASSISTANT
	always_can_respawn_as = TRUE
	threat = 0.2
	alt_titles = list(
		"Syndicate Specialist", //Синди выше, для удобства
		"Acolyte",
		"All-purpose Dildo",
		"All-purpose Fleshlight",
		"Ambassador",
		"Bitch",
		"Blacksmith",
		"Businessman",
		"Businesswoman",
		"Butler",
		"Civilian",
		"Clerk",
		"Colonist",
		"Contractor",
		"Crewmate",
		"Cumdump",
		"Diplomat",
		"Freelancer",
		"Freeloader",
		"Greytider",
		"Hobbyist",
		"Off-Duty",
		"Off-Duty Civilian",
		"Off-Duty Crew",
		"Off-Duty Staff",
		"Pet",
		"Service Bottom",
		"Service Pred",
		"Service Prey",
		"Service Top",
		"Slave",
		"Slut",
		"Snack",
		"Station Pet",
		"Stress Relief",
		"Tourist",
		"Trader",
		"Visitor",
		"Volunteer"
		)

	family_heirlooms = list(
		/obj/item/storage/toolbox/mechanical/old/heirloom,
		/obj/item/clothing/gloves/cut/family,
		/obj/item/lighter,
		/obj/item/lighter/greyscale
	)

	mail_goodies = list(
		/obj/item/storage/box/donkpockets = 10,
		/obj/item/clothing/mask/gas = 10,
		/obj/item/clothing/gloves/color/fyellow = 7,
		/obj/item/choice_beacon/music = 5,
		/obj/item/toy/sprayoncan = 3,
		/obj/item/crowbar/large = 1
	)

/datum/job/assistant/get_access()
	if(CONFIG_GET(flag/assistants_have_maint_access) || !CONFIG_GET(flag/jobs_have_minimal_access)) //Config has assistant maint access set
		. = ..()
		. |= list(ACCESS_MAINT_TUNNELS)
	else
		return ..()

/datum/job/assistant/after_spawn(mob/living/spawned, client/player_client, latejoin)
	. = ..()
	if(player_client && player_client.prefs && player_client.prefs.alt_titles_preferences[title] == "Blacksmith")
		var/datum/skill/level/S = GLOB.skill_datums[/datum/skill/level/dwarfy/blacksmithing]
		spawned.mind?.set_skill_value(S.type, S.get_skill_level_value(ROUND_UP(S.max_levels/5)))

/datum/outfit/job/assistant
	name = "Assistant"
	jobtype = /datum/job/assistant

/datum/outfit/job/assistant/syndicate
	name = "Syndicate Assistant"
	jobtype = /datum/job/assistant

	uniform = /obj/item/clothing/under/rank/civilian/util

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/syndicate_uplink=1)

/datum/outfit/job/assistant/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()
	var/suited = !preference_source || preference_source.prefs.jumpsuit_style == PREF_SUIT
	if (CONFIG_GET(flag/grey_assistants))
		uniform = suited ? /obj/item/clothing/under/color/grey : /obj/item/clothing/under/color/jumpskirt/grey
	else
		if(SSevents.holidays && SSevents.holidays[PRIDE_MONTH])
			uniform = suited ? /obj/item/clothing/under/color/rainbow : /obj/item/clothing/under/color/jumpskirt/rainbow
		else
			uniform = suited ? /obj/item/clothing/under/color/random : /obj/item/clothing/under/color/jumpskirt/random
