/datum/ert/erp
	roles = list(/datum/antagonist/ert/security/party, /datum/antagonist/ert/clown/party, /datum/antagonist/ert/engineer/party, /datum/antagonist/ert/janitor/party)
	leader_role = /datum/antagonist/ert/commander/party
	opendoors = FALSE
	rename_team = "Emergency Response Party"
	mission = "Create entertainment for the crew."
	polldesc = "a Code Rainbow Nanotrasen Emergency Response Party"
	code = "Rainbow"

/datum/antagonist/ert/clown
	role = "Клоун"
	outfit = /datum/outfit/ert/clown

/datum/antagonist/ert/clown/New()
	. = ..()
	name_source = GLOB.clown_names

/datum/antagonist/ert/janitor/party
	role = "Пати-Уборщик"
	outfit = /datum/outfit/ert/janitor/party

/datum/antagonist/ert/security/party
	role = "Пати-Bышибала"
	outfit = /datum/outfit/ert/security/party

/datum/antagonist/ert/engineer/party
	role = "Пати-Инженер"
	outfit = /datum/outfit/ert/engineer/party

/datum/antagonist/ert/clown/party
	role = "Пати-Комедиант"
	outfit = /datum/outfit/ert/clown/party

/datum/antagonist/ert/commander/party
	role = "Пати-Организатор"
	outfit = /datum/outfit/ert/commander/party

/datum/outfit/ert/janitor/party
	name = "ERP Cleaning Service"

	uniform = /obj/item/clothing/under/misc/overalls
	suit = /obj/item/clothing/suit/apron
	suit_store = null
	back = /obj/item/storage/backpack/captain
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom=1,
		/obj/item/mop/advanced = 1,
		/obj/item/reagent_containers/glass/bucket = 1,
		/obj/item/storage/box/lights/mixed = 1,
	)
	belt = /obj/item/storage/belt/janitor/ert_maid
	glasses = /obj/item/clothing/glasses/meson
	mask = /obj/item/clothing/mask/gas/sechailer/syndicate
	l_pocket = /obj/item/grenade/chem_grenade/cleaner
	r_pocket = /obj/item/grenade/chem_grenade/cleaner
	l_hand = /obj/item/storage/bag/trash

/datum/outfit/ert/security/party
	name = "ERP Bouncer"

	uniform = /obj/item/clothing/under/rank/security/officer/util
	suit = /obj/item/clothing/suit/armor/vest
	back = /obj/item/storage/backpack/captain
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom=1,
		/obj/item/clothing/head/helmet/police = 1,
		/obj/item/storage/box/handcuffs = 1,
	)
	belt = /obj/item/melee/classic_baton/telescopic
	l_pocket = /obj/item/assembly/flash
	r_pocket = /obj/item/storage/wallet

/datum/outfit/ert/engineer/party
	name = "ERP Constructor"

	uniform = /obj/item/clothing/under/rank/engineering/engineer/hazard
	suit = /obj/item/clothing/suit/hazardvest
	suit_store = null
	back = /obj/item/storage/backpack/captain
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom=1,
		/obj/item/construction/rcd/loaded = 1,
		/obj/item/stack/light_w = 30,
		/obj/item/stack/sheet/glass/fifty = 1,
		/obj/item/stack/sheet/metal/fifty = 1,
		/obj/item/stack/sheet/plasteel/twenty = 1,
	)
	head = /obj/item/clothing/head/welding
	mask = /obj/item/clothing/mask/gas/atmos
	l_hand = /obj/item/areaeditor/blueprints

/datum/outfit/ert/clown/party
	name = "ERP Comedian"

	uniform = /obj/item/clothing/under/rank/civilian/clown
	suit = /obj/item/clothing/suit/chameleon
	suit_store = null
	back = /obj/item/storage/backpack/captain
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom=1,
		/obj/item/instrument/piano_synth = 1,
		/obj/item/shield/energy/bananium = 1,
	)
	glasses = /obj/item/clothing/glasses/chameleon
	head = /obj/item/clothing/head/chameleon

/datum/outfit/ert/commander/party
	name = "ERP Coordinator"

	uniform = /obj/item/clothing/under/rank/captain/parade
	suit = /obj/item/clothing/suit/toggle/captains_parade
	suit_store = null
	back = /obj/item/storage/backpack/captain
	backpack_contents = list(
		/obj/item/storage/box/survival/centcom=1,
		/obj/item/reagent_containers/food/snacks/store/cake/birthday = 1,
		/obj/item/storage/box/fireworks = 3,
	)
	belt = /obj/item/storage/belt/sabre
	head = /obj/item/clothing/head/caphat/parade
	l_pocket = /obj/item/kitchen/knife
	l_hand = /obj/item/toy/balloon
