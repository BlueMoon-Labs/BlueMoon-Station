/datum/job/janitor
	title = "Janitor"
	flag = JANITOR
	department_head = list("Head of Personnel")
	department_flag = CIVILIAN
	faction = "Station"
	total_positions = 2
	spawn_positions = 2
	supervisors = "the head of personnel"
	selection_color = "#bbe291"

	outfit = /datum/outfit/job/janitor
	plasma_outfit = /datum/outfit/plasmaman/janitor

	access = list(ACCESS_JANITOR, ACCESS_MAINT_TUNNELS, ACCESS_MINERAL_STOREROOM)
	minimal_access = list(ACCESS_JANITOR, ACCESS_MAINT_TUNNELS, ACCESS_MINERAL_STOREROOM)
	paycheck = PAYCHECK_EASY
	paycheck_department = ACCOUNT_SRV

	display_order = JOB_DISPLAY_ORDER_JANITOR
	departments = DEPARTMENT_BITFLAG_SERVICE
	threat = 0.2

	family_heirlooms = list(
		/obj/item/mop,
		/obj/item/clothing/suit/caution,
		/obj/item/reagent_containers/glass/bucket,
		/obj/item/soap
	)

	mail_goodies = list(
		/obj/item/grenade/chem_grenade/cleaner = 30,
		/obj/item/storage/box/lights/mixed = 20,
		/obj/item/lightreplacer = 10
	)

/datum/outfit/job/janitor
	name = "Janitor"
	jobtype = /datum/job/janitor

	belt = /obj/item/pda/janitor
	ears = /obj/item/radio/headset/headset_srv
	uniform = /obj/item/clothing/under/rank/civilian/janitor
	backpack_contents = list(/obj/item/modular_computer/tablet/preset/advanced=1, /obj/item/access_key)

/datum/outfit/job/janitor/syndicate
	name = "Syndicate Janitor"
	jobtype = /datum/job/janitor

	//belt = /obj/item/pda/syndicate/no_deto

	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	ears = /obj/item/radio/headset/headset_srv
	uniform = /obj/item/clothing/under/rank/civilian/util

	backpack = /obj/item/storage/backpack/duffelbag/syndie
	satchel = /obj/item/storage/backpack/duffelbag/syndie
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT
	backpack_contents = list(/obj/item/modular_computer/tablet/preset/advanced=1, /obj/item/syndicate_uplink=1)

// BLUEMOON ADD уборщики не оставляют при своём хождении грязь
/datum/outfit/job/janitor/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()
	if(!visualsOnly)
		H.dirtyness_maker = FALSE
// BLUEMOON ADD END
