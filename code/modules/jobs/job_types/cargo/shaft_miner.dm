/datum/job/mining
	title = "Shaft Miner"
	flag = MINER
	department_head = list("Quartermaster")
	department_flag = CIVILIAN
	faction = "Station"
	total_positions = 6
	spawn_positions = 6
	supervisors = "the quartermaster"
	selection_color = "#ca8f55"
	custom_spawn_text = "не забывайте, что вы шахтёр, а не охотник. Ваша главная цель - поставлять ресурсы станции."
	alt_titles = list(
		"Trainee Miner", //Стажер выше, для удобства
		"Shaft Syndi-Miner", //Синди выше, для удобства
		"Ashwalker Breeder",
		"Ashwalker Sex Slave",
		"Digger",
		"Dredger",
		"Drill Technician",
		"Excavator",
		"Exotic Ore Miner",
		"Fauna Hunter",
		"Hunter",
		"Prospector",
		"Slayer",
		"Spelunker",
		"Miner"
		)

	outfit = /datum/outfit/job/miner
	plasma_outfit = /datum/outfit/plasmaman/mining

	access = list(ACCESS_MAINT_TUNNELS, ACCESS_MAILSORTING, ACCESS_CARGO, ACCESS_CARGO_BOT, ACCESS_MINING,
				ACCESS_MINING_STATION, ACCESS_MINERAL_STOREROOM, ACCESS_PRODUCTION_CARGO)
	minimal_access = list(ACCESS_MINING, ACCESS_MINING_STATION, ACCESS_MAILSORTING, ACCESS_MINERAL_STOREROOM, ACCESS_PRODUCTION_CARGO)
	paycheck = PAYCHECK_EASY ///Not necessarily easy itself, but it can be trivial to make lot of cash on this job.
	paycheck_department = ACCOUNT_CAR
	bounty_types = CIV_JOB_MINE
	departments = DEPARTMENT_BITFLAG_SUPPLY

	display_order = JOB_DISPLAY_ORDER_SHAFT_MINER

	threat = 1.5

	family_heirlooms = list(
		/obj/item/pickaxe/mini,
		/obj/item/shovel
	)

/datum/outfit/job/miner
	name = "Shaft Miner (Lavaland)"
	jobtype = /datum/job/mining

	belt = /obj/item/pda/shaftminer
	ears = /obj/item/radio/headset/headset_cargo/mining
	shoes = /obj/item/clothing/shoes/workboots/mining
	gloves = /obj/item/clothing/gloves/color/black
	uniform = /obj/item/clothing/under/rank/cargo/miner/lavaland
	l_pocket = /obj/item/reagent_containers/hypospray/medipen/survival
	r_pocket = /obj/item/storage/bag/ore	//causes issues if spawned in backpack
	backpack_contents = list(
		/obj/item/flashlight/seclite=1,\
		/obj/item/kitchen/knife/combat/survival=1,\
		/obj/item/mining_voucher=1,\
		/obj/item/suit_voucher=1,\
		/obj/item/stack/marker_beacon/ten=1)

	backpack = /obj/item/storage/backpack/explorer
	satchel = /obj/item/storage/backpack/satchel/explorer
	duffelbag = /obj/item/storage/backpack/duffelbag
	box = /obj/item/storage/box/survival/mining

	chameleon_extras = /obj/item/gun/energy/kinetic_accelerator

// BLUEMOON ADD START - шахтёрским синтетикам с начала их смены выдаётся заряженная шахтёрская ПОУ
/datum/outfit/job/miner/pre_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	if(HAS_TRAIT(H, TRAIT_ROBOTIC_ORGANISM))
		l_pocket = belt
		belt = /obj/item/device/cooler/lavaland/charged
	. = ..()
// BLUEMOON ADD END

/datum/outfit/job/miner/syndicate
	name = "Syndicate Shaft Miner"
	jobtype = /datum/job/mining

	//belt = /obj/item/pda/syndicate/no_deto

	ears = /obj/item/radio/headset/headset_cargo/mining
	shoes = /obj/item/clothing/shoes/jackboots/tall_default
	gloves = /obj/item/clothing/gloves/combat
	uniform = /obj/item/clothing/under/rank/cargo/util
	l_pocket = /obj/item/reagent_containers/hypospray/medipen/survival
	r_pocket = /obj/item/storage/bag/ore/holding	//causes issues if spawned in backpack
	backpack_contents = list(
		/obj/item/flashlight/seclite=1,\
		/obj/item/kitchen/knife/combat/survival=1,\
		/obj/item/mining_voucher=1,\
		/obj/item/suit_voucher=1,\
		/obj/item/stack/marker_beacon/ten=1,\
		/obj/item/syndicate_uplink=1)

	backpack = /obj/item/storage/backpack/duffelbag/syndie/ammo
	satchel = /obj/item/storage/backpack/duffelbag/syndie/ammo
	duffelbag = /obj/item/storage/backpack/duffelbag/syndie/ammo
	box = /obj/item/storage/box/survival/syndie
	pda_slot = ITEM_SLOT_BELT

/datum/outfit/job/miner/asteroid
	name = "Shaft Miner (Asteroid)"
	uniform = /obj/item/clothing/under/rank/cargo/miner
	shoes = /obj/item/clothing/shoes/workboots

/datum/outfit/job/miner/equipped/hardsuit
	name = "Shaft Miner (Lavaland + Equipment)"
	suit = /obj/item/clothing/suit/hooded/explorer/standard
	mask = /obj/item/clothing/mask/gas/explorer
	glasses = /obj/item/clothing/glasses/meson
	suit_store = /obj/item/tank/internals/oxygen/yellow
	internals_slot = ITEM_SLOT_SUITSTORE
	backpack_contents = list(
		/obj/item/flashlight/seclite=1,\
		/obj/item/kitchen/knife/combat/survival=1,
		/obj/item/mining_voucher=1,
		/obj/item/t_scanner/adv_mining_scanner/lesser=1,
		/obj/item/gun/energy/kinetic_accelerator=1,\
		/obj/item/stack/marker_beacon/ten=1)

/datum/outfit/job/miner/equipped/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE, client/preference_source)
	..()
	if(visualsOnly)
		return
	if(istype(H.wear_suit, /obj/item/clothing/suit/hooded))
		var/obj/item/clothing/suit/hooded/S = H.wear_suit
		S.ToggleHood()

/datum/outfit/job/miner/equipped/hardsuit
	name = "Shaft Miner (Equipment + Hardsuit)"
	suit = /obj/item/clothing/suit/space/hardsuit/mining
	mask = /obj/item/clothing/mask/breath
