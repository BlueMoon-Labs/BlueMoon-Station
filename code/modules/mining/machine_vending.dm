/**********************Mining Equipment Vendor**************************/

/obj/machinery/equipment_vendor
	name = "mining equipment vendor"
	desc = "Автомат снаряжения для шахтёров; очки, полученные из рудоплавильной печи, могут быть потрачены тут."
	icon = 'icons/obj/machines/mining_machines.dmi'
	icon_state = "mining"
	density = TRUE
	circuit = /obj/item/circuitboard/machine/mining_equipment_vendor
	init_process = FALSE
	var/icon_deny = "mining-deny"
	// Группируйте товары по категории и цене; используйте табуляцию.
	var/list/prize_list = list(
		new /datum/data/mining_equipment("1 Marker Beacon",				/obj/item/stack/marker_beacon,										10),
		new /datum/data/mining_equipment("10 Marker Beacons",			/obj/item/stack/marker_beacon/ten,									100),
		new /datum/data/mining_equipment("30 Marker Beacons",			/obj/item/stack/marker_beacon/thirty,								300),
		new /datum/data/mining_equipment("Laser Pointer",				/obj/item/laser_pointer,											300),
		new /datum/data/mining_equipment("Alien Toy",					/obj/item/clothing/mask/facehugger/toy,								300),
		new /datum/data/mining_equipment("Mini Extinguisher",			/obj/item/extinguisher/mini,										1000),
		new /datum/data/mining_equipment("Jetpack Upgrade",				/obj/item/tank/jetpack/suit,										2000),
		new /datum/data/mining_equipment("Illegal technology disk",		/obj/item/disk/tech_disk/illegal,									100000),

		new /datum/data/mining_equipment("Explorer Stripper Outfit", 	/obj/item/clothing/under/rank/cargo/miner/lavaland/stripper, 		50,				"Equipment"),
		new /datum/data/mining_equipment("GAR Meson Scanners",			/obj/item/clothing/glasses/meson/gar,								500,			"Equipment"),
		new /datum/data/mining_equipment("Explorer's Webbing",			/obj/item/storage/belt/mining,										500,			"Equipment"),
		new /datum/data/mining_equipment("Larger Ore Bag",				/obj/item/storage/bag/ore/large,									500,			"Equipment"),
		new /datum/data/mining_equipment("Mining Conscription Kit",		/obj/item/storage/backpack/duffelbag/mining/conscript,				1000,			"Equipment"),
		new /datum/data/mining_equipment("Spare Suit Voucher",			/obj/item/suit_voucher,												2000,			"Equipment"),
		new /datum/data/mining_equipment("Mining Hardsuit",				/obj/item/clothing/suit/space/hardsuit/mining,						2000,			"Equipment"),
		new /datum/data/mining_equipment("Jump Boots",					/obj/item/clothing/shoes/bhop,										2500,			"Equipment"),
		new /datum/data/mining_equipment("Ice hiking boots",            /obj/item/clothing/shoes/winterboots/ice_boots,				        2500,			"Equipment"),
		new /datum/data/mining_equipment("Miner Full Replacement",		/obj/item/storage/backpack/duffelbag/mining/cloned,					3000,			"Equipment"),
		new /datum/data/mining_equipment("Improved Miner Suit",			/obj/item/clothing/suit/hooded/explorer/standard/improved,			15000,			"Equipment"),

		new /datum/data/mining_equipment("Advanced Scanner",			/obj/item/t_scanner/adv_mining_scanner,								800,			"Tools"),
		new /datum/data/mining_equipment("Resonator",					/obj/item/resonator,												800,			"Tools"),
		new /datum/data/mining_equipment("Silver Pickaxe",				/obj/item/pickaxe/silver,											1000,			"Tools"),
		new /datum/data/mining_equipment("Diamond Pickaxe",				/obj/item/pickaxe/diamond,											2000,			"Tools"),
		new /datum/data/mining_equipment("Super Resonator",				/obj/item/resonator/upgraded,										2500,			"Tools"),
		new /datum/data/mining_equipment("Sonic Jackhammer",			/obj/item/pickaxe/drill/jackhammer,									4000,			"Tools"),

		new /datum/data/mining_equipment("Survival Knife",				/obj/item/kitchen/knife/combat/survival,							450,			"Melee"),
		new /datum/data/mining_equipment("Survival Dagger",				/obj/item/kitchen/knife/combat/survival/knuckledagger,				550,			"Melee"),
		new /datum/data/mining_equipment("Kinetic Crusher",				/obj/item/kinetic_crusher,											750,			"Melee"),
		new /datum/data/mining_equipment("Premium Kinetic Melee Kit",	/obj/item/storage/backpack/duffelbag/mining/glaivekit,				2250,			"Melee"),
		new /datum/data/mining_equipment("Kinetic Destroyer",			/obj/item/kinetic_crusher/premiumcrusher,							12000,			"Melee"), //boop

		new /datum/data/mining_equipment("Kinetic Accelerator",			/obj/item/gun/energy/kinetic_accelerator,							750,			"Accelerators"),
		new /datum/data/mining_equipment("Premium Accelerator",			/obj/item/gun/energy/kinetic_accelerator/premiumka,					8000,			"Accelerators"),
		new /datum/data/mining_equipment("Precise Accelerator",			/obj/item/gun/energy/kinetic_accelerator/premiumka/precise,			10000,			"Accelerators"),
		new /datum/data/mining_equipment("Rapid Accelerator",			/obj/item/gun/energy/kinetic_accelerator/premiumka/rapid,			10000,			"Accelerators"),
		new /datum/data/mining_equipment("Heavy Accelerator",			/obj/item/gun/energy/kinetic_accelerator/premiumka/heavy,			10000,			"Accelerators"),
		new /datum/data/mining_equipment("Modular Accelerator",			/obj/item/gun/energy/kinetic_accelerator/premiumka/modular,			15000,			"Accelerators"),
		new /datum/data/mining_equipment("Build-your-own-KA kit",		/obj/item/gun/energy/kinetic_accelerator/premiumka/byoka,			30000,			"Accelerators"),

		new /datum/data/mining_equipment("KA Minebot Passthrough",		/obj/item/borg/upgrade/modkit/minebot_passthrough,					100,			"Upgrades"),
		new /datum/data/mining_equipment("KA White Tracer Rounds",		/obj/item/borg/upgrade/modkit/tracer,								100,			"Upgrades"),
		new /datum/data/mining_equipment("KA Adjustable Tracer Rounds",	/obj/item/borg/upgrade/modkit/tracer/adjustable,					150,			"Upgrades"),
		new /datum/data/mining_equipment("KA Super Chassis",			/obj/item/borg/upgrade/modkit/chassis_mod,							250,			"Upgrades"),
		new /datum/data/mining_equipment("KA Hyper Chassis",			/obj/item/borg/upgrade/modkit/chassis_mod/orange,					300,			"Upgrades"),
		new /datum/data/mining_equipment("KA Range Increase",			/obj/item/borg/upgrade/modkit/range,								1000,			"Upgrades"),
		new /datum/data/mining_equipment("KA Damage Increase",			/obj/item/borg/upgrade/modkit/damage,								1000,			"Upgrades"),
		new /datum/data/mining_equipment("KA Cooldown Decrease",		/obj/item/borg/upgrade/modkit/cooldown,								1000,			"Upgrades"),
		new /datum/data/mining_equipment("KA AoE Damage",				/obj/item/borg/upgrade/modkit/aoe/mobs,								2000,			"Upgrades"),
		new /datum/data/mining_equipment("Premium KA borg Upgrade",		/obj/item/borg/upgrade/premiumka,									8000,			"Upgrades"),

		new /datum/data/mining_equipment("Stabilizing Serum",			/obj/item/hivelordstabilizer,										400,			"Medical"),
		new /datum/data/mining_equipment("Fulton Beacon",				/obj/item/fulton_core,												400,			"Medical"),
		new /datum/data/mining_equipment("Tracking Implant Kit", 		/obj/item/storage/box/minertracker,									600,			"Medical"),
		new /datum/data/mining_equipment("Jaunter",						/obj/item/wormhole_jaunter,											750,			"Medical"),
		new /datum/data/mining_equipment("Survival Medipen",			/obj/item/reagent_containers/hypospray/medipen/survival,			750,			"Medical"),
		new /datum/data/mining_equipment("Brute First-Aid Kit",			/obj/item/storage/firstaid/brute,									800,			"Medical"),
		new /datum/data/mining_equipment("Burn First-Aid Kit",			/obj/item/storage/firstaid/fire,									800,			"Medical"),
		new /datum/data/mining_equipment("First-Aid Kit",				/obj/item/storage/firstaid/regular,									800,			"Medical"),
		new /datum/data/mining_equipment("Fulton Pack",					/obj/item/extraction_pack,											1000,			"Medical"),
		new /datum/data/mining_equipment("Lazarus Injector",			/obj/item/lazarus_injector,											1000,			"Medical"),

		new /datum/data/mining_equipment("Nanotrasen Minebot",			/mob/living/simple_animal/hostile/mining_drone,						800,			"Minebot"),
		new /datum/data/mining_equipment("Minebot Melee Upgrade",		/obj/item/mine_bot_upgrade,											400,			"Minebot"),
		new /datum/data/mining_equipment("Minebot Armor Upgrade",		/obj/item/mine_bot_upgrade/health,									400,			"Minebot"),
		new /datum/data/mining_equipment("Minebot Cooldown Upgrade",	/obj/item/borg/upgrade/modkit/cooldown/minebot,						600,			"Minebot"),
		new /datum/data/mining_equipment("Minebot AI Upgrade",			/obj/item/slimepotion/slime/sentience/mining,						1000,			"Minebot"),

		new /datum/data/mining_equipment("Shelter Capsule",				/obj/item/survivalcapsule,											400,	 		"Capsules"),
		new /datum/data/mining_equipment("Pill Shelter",				/obj/item/survivalcapsule/luxury/pill,								400, 			"Capsules"), //The smallest of them all! Same as usual capsule to prevent abusing them
		new /datum/data/mining_equipment("Luxury Shelter Capsule",		/obj/item/survivalcapsule/luxury,									3000,			"Capsules"),
		new /datum/data/mining_equipment("Empty Capsule",				/obj/item/survivalcapsule/luxury/empty,								5000,			"Capsules"),
		new /datum/data/mining_equipment("Penthouse Capsule",			/obj/item/survivalcapsule/luxury/penthouse,							7500,			"Capsules"),
		new /datum/data/mining_equipment("Garden & Kitchen Capsule",	/obj/item/survivalcapsule/luxury/garden,							7500,			"Capsules"),
		new /datum/data/mining_equipment("Arena Shelter",				/obj/item/survivalcapsule/luxury/arena,								10000,			"Capsules"), //What do you expect in the first place?
		new /datum/data/mining_equipment("Luxury Bar Capsule",			/obj/item/survivalcapsule/luxury/elitebar,							10000,			"Capsules"),
		new /datum/data/mining_equipment("Luxurious Penthouse Capsule",	/obj/item/survivalcapsule/luxury/elutepenthouse,					15000,			"Capsules"),  //BLUEMOON CHANGE: New, robust version of Penthouse capsule.
		new /datum/data/mining_equipment("Supreme Shelter",				/obj/item/survivalcapsule/luxury/greatest,							100000,			"Capsules"), //https://youtu.be/97lKspTB3u0?si=bsdh-3VRzvV7wkIG | Yes it will cost a lot, but look at the design!(it sucks lmao)

		new /datum/data/mining_equipment("50 Point Transfer Card",		/obj/item/card/mining_point_card/fifty,								50,				"Earnings"),
		new /datum/data/mining_equipment("500 Point Transfer Card", 	/obj/item/card/mining_point_card,									500,			"Earnings"),
		new /datum/data/mining_equipment("Space Cash",					/obj/item/stack/spacecash/c1000,									2000,			"Earnings"),
		new /datum/data/mining_equipment("5000 Point Transfer Card",	/obj/item/card/mining_point_card/fivethousand,						5000,			"Earnings"),
		new /datum/data/mining_equipment("1 Metadollar",				/obj/item/stack/metadollar,											50000,			"Earnings"),

		new /datum/data/mining_equipment("Whiskey",						/obj/item/reagent_containers/food/drinks/bottle/whiskey,			100,			"Recreation"),
		new /datum/data/mining_equipment("Absinthe",					/obj/item/reagent_containers/food/drinks/bottle/absinthe/premium,	100,			"Recreation"),
		new /datum/data/mining_equipment("Cigar",						/obj/item/clothing/mask/cigarette/cigar/havana,						150,			"Recreation"),
		new /datum/data/mining_equipment("Soap",						/obj/item/soap/nanotrasen,											200,			"Recreation"),
		new /datum/data/mining_equipment("NT MRE Ration Kit Menu 1",	/obj/item/storage/box/mre/menu1,									999,			"Recreation"), //On other forks miners at least can buy themselves some food, at affordable price.
		new /datum/data/mining_equipment("NT MRE Ration Kit Menu 2",	/obj/item/storage/box/mre/menu2,									999,			"Recreation"),
		new /datum/data/mining_equipment("NT MRE Ration Kit Menu 3",	/obj/item/storage/box/mre/menu3,									999,			"Recreation"),
		new /datum/data/mining_equipment("NT MRE Ration Kit Menu 4",	/obj/item/storage/box/mre/menu4,									999,			"Recreation"),
		new /datum/data/mining_equipment("KinkMate Refill Stock",		/obj/item/vending_refill/kink,										1200,			"Recreation"), //Kinkmate restock for ghostroles/lone miners. Circuit can be found in circuit printer.
		)

	// Имя поля баланса на ID-карте; подтипы выбирают свою валюту.
	var/point_type = "mining_points"
	var/point_label = "Шахтёрские очки"
	var/metadollar_job = /datum/job/mining
	var/metadollar_activity = "шахтёрскую деятельность"
	var/panel_open_icon = "mining-open"
	var/list/undiscounted_items = list(/obj/item/card/mining_point_card, /obj/item/stack/metadollar)
	var/list/category_order = list("Equipment", "Tools", "Melee", "Accelerators", "Upgrades", "Medical", "Capsules", "Recreation", "Earnings", "Minebot", "Liberator", "Misc")
	var/static/list/category_labels = list(
		"Equipment" = list("ru" = "Снаряжение", "icon" = "hard-hat"),
		"Tools" = list("ru" = "Инструменты", "icon" = "tools"),
		"Melee" = list("ru" = "Ближний", "icon" = "fist-raised"),
		"Accelerators" = list("ru" = "Ускорители", "icon" = "crosshairs"),
		"Upgrades" = list("ru" = "Улучшения", "icon" = "cogs"),
		"Medical" = list("ru" = "Медицина", "icon" = "medkit"),
		"Capsules" = list("ru" = "Капсулы", "icon" = "campground"),
		"Recreation" = list("ru" = "Отдых", "icon" = "cocktail"),
		"Earnings" = list("ru" = "Заработок", "icon" = "coins"),
		"Minebot" = list("ru" = "Шахтобот", "icon" = "robot"),
		"Liberator" = list("ru" = "Либератор", "icon" = "gem"),
		"Misc" = list("ru" = "Прочее", "icon" = "box-open"),
		"Ranged" = list("ru" = "Дальний", "icon" = "crosshairs"),
		"Ammo" = list("ru" = "Боеприпасы", "icon" = "bullseye"),
		"Armor" = list("ru" = "Броня", "icon" = "shield-alt"),
		"Elite" = list("ru" = "Элитное", "icon" = "star"),
	)

/datum/data/mining_equipment
	var/equipment_name = "generic"
	var/equipment_path = null
	var/cost = 0
	var/category = ""
	var/base_cost = 0

/datum/data/mining_equipment/New(name, path, cost, category)
	src.equipment_name = name
	src.equipment_path = path
	src.cost = cost
	src.category = category
	src.base_cost = cost

/obj/machinery/equipment_vendor/Initialize(mapload)
	// Цены и ссылки принадлежат экземпляру, а не общему списку типа.
	var/list/initial_prizes = prize_list
	prize_list = list()
	for(var/datum/data/mining_equipment/prize as anything in initial_prizes)
		prize_list += new /datum/data/mining_equipment(prize.equipment_name, prize.equipment_path, prize.base_cost, prize.category)
	. = ..()
	build_inventory()

/obj/machinery/equipment_vendor/Destroy()
	QDEL_LIST(prize_list)
	return ..()

/obj/machinery/equipment_vendor/proc/build_inventory()
	for(var/datum/data/mining_equipment/prize as anything in prize_list)
		GLOB.vending_products[prize.equipment_path] = TRUE

/obj/machinery/equipment_vendor/update_icon_state()
	icon_state = powered() ? initial(icon_state) : "[initial(icon_state)]-off"

/obj/machinery/equipment_vendor/RefreshParts()
	var/discount_rate = get_discount()
	for(var/datum/data/mining_equipment/prize as anything in prize_list)
		if(ispath_in_list(prize.equipment_path, undiscounted_items))
			continue
		prize.cost = max(1, round(prize.base_cost * (1 - discount_rate)))
	update_static_data_for_all_viewers()

/obj/machinery/equipment_vendor/proc/get_discount()
	var/discount_rate = 0
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		discount_rate += 0.025 * (bin.rating - 1)
	return discount_rate

/obj/machinery/equipment_vendor/examine_display_content(mob/user)
	. = ..()
	. += "– Текущая скидка на товары: [span_green("[get_discount() * 100]%")]"

/obj/machinery/equipment_vendor/ui_assets(mob/user)
	return list(get_asset_datum(/datum/asset/spritesheet_batched/vending))

/obj/machinery/equipment_vendor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Vending", name)
		ui.open()

/obj/machinery/equipment_vendor/ui_static_data(mob/user)
	. = list()
	.["point_vendor"] = TRUE
	.["point_label"] = point_label
	.["onstation"] = TRUE
	.["discount"] = get_discount()
	.["product_records"] = list()
	for(var/datum/data/mining_equipment/prize as anything in prize_list)
		.["product_records"] += list(list(
			"path" = replacetext(replacetext("[prize.equipment_path]", "/obj/item/", ""), "/", "-"),
			"name" = prize.equipment_name,
			"price" = prize.cost,
			"category" = prize.category || "Misc",
			"ref" = REF(prize),
		))
	var/datum/preferences/lang_prefs = user?.client?.prefs
	var/is_russian = lang_prefs?.use_modern_translations && lang_prefs?.modern_ui_language == 1
	.["categories"] = list()
	for(var/category in category_order)
		var/list/labels = category_labels[category]
		.["categories"][category] = list("name" = is_russian ? labels["ru"] : category, "icon" = labels["icon"])

/obj/machinery/equipment_vendor/ui_data(mob/user)
	. = list("user" = null)
	.["vending_layout"] = user?.client?.prefs?.get_vending_layout(type) || "grid"
	var/obj/item/card/id/card = user?.get_idcard(TRUE)
	if(card)
		.["user"] = list(
			"cash" = card.vars[point_type],
			"name" = card.registered_account?.account_holder || "Неизвестный пользователь",
			"job" = card.registered_account?.account_job?.title || "БЕЗ РАБОТЫ",
		)

/obj/machinery/equipment_vendor/ui_act(action, params)
	if(..())
		return TRUE
	if(action == "set_vending_layout")
		usr.client?.prefs?.set_vending_layout(type, params["layout"])
		return TRUE
	if(action != "purchase")
		return FALSE
	var/mob/user = usr
	var/obj/item/card/id/card = user.get_idcard(TRUE)
	if(!card)
		to_chat(user, span_alert("Ошибка: требуется ID-карта!"))
		flick(icon_deny, src)
		return TRUE
	var/datum/data/mining_equipment/prize = locate(params["ref"]) in prize_list
	if(!prize)
		to_chat(user, span_alert("Ошибка: неверный выбор!"))
		flick(icon_deny, src)
		return TRUE
	if(!can_purchase(user, prize))
		flick(icon_deny, src)
		return TRUE
	if(prize.cost > card.vars[point_type])
		to_chat(user, span_alert("Ошибка: недостаточно очков для покупки [prize.equipment_name] на счёте [card]!"))
		flick(icon_deny, src)
		return TRUE
	card.vars[point_type] -= prize.cost
	to_chat(user, span_notice("[src] стучит и выдаёт [prize.equipment_name]!"))
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	new prize.equipment_path(loc)
	record_purchase(prize)
	return TRUE

/obj/machinery/equipment_vendor/proc/can_purchase(mob/user, datum/data/mining_equipment/prize)
	if(ispath(prize.equipment_path, /obj/item/stack/metadollar))
		return vendor_can_buy_metadollar(user, metadollar_job, metadollar_activity)
	return TRUE

/obj/machinery/equipment_vendor/proc/record_purchase(datum/data/mining_equipment/prize)
	SSblackbox.record_feedback("nested tally", "mining_equipment_bought", 1, list("[type]", "[prize.equipment_path]"))

/obj/machinery/equipment_vendor/attackby(obj/item/item, mob/user, params)
	if(redeem_voucher(item, user))
		return
	if(default_deconstruction_screwdriver(user, panel_open_icon, initial(icon_state), item))
		return
	if(default_deconstruction_crowbar(item))
		return
	return ..()

/obj/machinery/equipment_vendor/proc/redeem_voucher(obj/item/voucher, mob/user)
	if(istype(voucher, /obj/item/mining_voucher))
		RedeemVoucher(voucher, user)
		return TRUE
	if(istype(voucher, /obj/item/suit_voucher))
		RedeemSVoucher(voucher, user)
		return TRUE
	if(istype(voucher, /obj/item/premium_crusher_voucher))
		RedeemPCVoucher(voucher, user)
		return TRUE
	return FALSE

/obj/machinery/equipment_vendor/proc/RedeemVoucher(obj/item/mining_voucher/voucher, mob/redeemer)
	var/items = list(	"Survival Capsule and Explorer's Webbing" = image(icon = 'icons/obj/storage.dmi', icon_state = "explorerpack"),
						"Resonator Kit" = image(icon = 'icons/obj/mining.dmi', icon_state = "resonator"),
						"Minebot Kit" = image(icon = 'icons/mob/aibots.dmi', icon_state = "mining_drone"),
						"Extraction and Rescue Kit" = image(icon = 'icons/obj/fulton.dmi', icon_state = "extraction_pack"),
						"Crusher Kit" = image(icon = 'icons/obj/mining.dmi', icon_state = "crusher"),
						"Mining Conscription Kit" = image(icon = 'icons/obj/storage.dmi', icon_state = "duffel"))

	var/selection = show_radial_menu(redeemer, src, items, require_near = TRUE, tooltips = TRUE)
	if(!selection || !Adjacent(redeemer) || QDELETED(voucher) || voucher.loc != redeemer)
		return
	var/drop_location = drop_location()
	switch(selection)
		if("Survival Capsule and Explorer's Webbing")
			new /obj/item/storage/belt/mining/vendor(drop_location)
		if("Resonator Kit")
			new /obj/item/extinguisher/mini(drop_location)
			new /obj/item/resonator(drop_location)
		if("Minebot Kit")
			new /mob/living/simple_animal/hostile/mining_drone(drop_location)
			new /obj/item/weldingtool/hugetank(drop_location)
			new /obj/item/clothing/head/welding(drop_location)
			new /obj/item/borg/upgrade/modkit/minebot_passthrough(drop_location)
		if("Extraction and Rescue Kit")
			new /obj/item/extraction_pack(drop_location)
			new /obj/item/fulton_core(drop_location)
			new /obj/item/stack/marker_beacon/thirty(drop_location)
		if("Crusher Kit")
			new /obj/item/extinguisher/mini(drop_location)
			new /obj/item/kinetic_crusher(drop_location)
		if("Mining Conscription Kit")
			new /obj/item/storage/backpack/duffelbag/mining/conscript(drop_location)
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	SSblackbox.record_feedback("tally", "mining_voucher_redeemed", 1, selection)
	qdel(voucher)

/obj/machinery/equipment_vendor/proc/RedeemSVoucher(obj/item/suit_voucher/voucher, mob/redeemer)
	var/items = list(	"Exo-suit" = image(icon = 'icons/obj/clothing/suits.dmi', icon_state = "exo"),
						"HEVA suit" = image(icon = 'icons/obj/clothing/suits.dmi', icon_state = "heva"))

	var/selection = show_radial_menu(redeemer, src, items, require_near = TRUE, tooltips = TRUE)
	if(!selection || !Adjacent(redeemer) || QDELETED(voucher) || voucher.loc != redeemer)
		return
	var/drop_location = drop_location()
	switch(selection)
		if("Exo-suit")
			new /obj/item/clothing/suit/hooded/explorer/exo(drop_location)
			new /obj/item/clothing/mask/gas/exo(drop_location)
		if("HEVA suit")
			new /obj/item/clothing/suit/hooded/explorer/heva(drop_location)
			new /obj/item/clothing/mask/gas/heva(drop_location)
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	SSblackbox.record_feedback("tally", "suit_voucher_redeemed", 1, selection)
	qdel(voucher)

/obj/machinery/equipment_vendor/proc/RedeemPCVoucher(obj/item/premium_crusher_voucher/voucher, mob/redeemer) // someone should REALLY just refactor this
	var/items = list("Kinetic Glaive" = image(icon = 'icons/obj/mining.dmi', icon_state = "crusher-glaive"),
					"Kinetic Gauntlets" = image(icon = 'icons/obj/mining.dmi', icon_state = "crusher-hands"))

	var/selection = show_radial_menu(redeemer, src, items, require_near = TRUE, tooltips = TRUE)
	if(!selection || !Adjacent(redeemer) || QDELETED(voucher) || voucher.loc != redeemer)
		return
	var/drop_location = drop_location()
	switch(selection)
		if("Kinetic Glaive")
			new /obj/item/kinetic_crusher/glaive(drop_location)
		if("Kinetic Gauntlets")
			new /obj/item/kinetic_crusher/glaive/gauntlets(drop_location)
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	SSblackbox.record_feedback("tally", "crusher_voucher_redeemed", 1, selection)
	qdel(voucher)

/obj/machinery/equipment_vendor/ex_act(severity, target, origin)
	do_sparks(5, TRUE, src)
	if(prob(50 / severity) && severity < 3)
		qdel(src)

/****************Golem Point Vendor**************************/

/obj/machinery/equipment_vendor/golem
	name = "golem ship equipment vendor"
	circuit = /obj/item/circuitboard/machine/mining_equipment_vendor/golem

/obj/machinery/equipment_vendor/golem/Initialize(mapload)
	. = ..()
	desc += "\nIt seems a few selections have been added."
	prize_list += list(
		new /datum/data/mining_equipment("Extra ID",       				/obj/item/card/id/mining, 				                   		250, 	"Liberator"),
		new /datum/data/mining_equipment("Science Goggles",       		/obj/item/clothing/glasses/science,								250,	"Liberator"),
		new /datum/data/mining_equipment("Monkey Cube",					/obj/item/reagent_containers/food/snacks/cube/monkey,        	300,	"Liberator"),
		new /datum/data/mining_equipment("Toolbelt",					/obj/item/storage/belt/utility,	    							350,	"Liberator"),
		new /datum/data/mining_equipment("Royal Cape of the Либератор", /obj/item/bedsheet/rd/royal_cape, 								500,	"Liberator"),
		new /datum/data/mining_equipment("Grey Slime Extract",			/obj/item/slime_extract/grey,									1000,	"Liberator"),
		new /datum/data/mining_equipment("Modification Kit",    		/obj/item/borg/upgrade/modkit/trigger_guard,					1700,	"Liberator"),
		new /datum/data/mining_equipment("The Либератор's Legacy",  	/obj/item/storage/box/rndboards,								2000,	"Liberator")
		)
	build_inventory() // Фикс нужен для корректного отображения иконок

/**********************Mining Equipment Vendor Items**************************/

/**********************Mining Equipment Voucher**********************/

/obj/item/mining_voucher
	name = "mining voucher"
	desc = "A token to redeem a piece of equipment. Use it on a mining equipment vendor."
	icon = 'icons/obj/mining.dmi'
	icon_state = "mining_voucher"
	w_class = WEIGHT_CLASS_TINY

/obj/item/suit_voucher
	name = "suit voucher"
	desc = "A token to redeem a new suit. Use it on a mining equipment vendor."
	icon = 'icons/obj/mining.dmi'
	icon_state = "mining_voucher"
	w_class = WEIGHT_CLASS_TINY

/obj/item/premium_crusher_voucher
	name = "premium crusher voucher"
	desc = "A token to redeem for a premium proto-kinetic melee weapon. Use it on a mining equipment vendor."
	icon = 'icons/obj/mining.dmi'
	icon_state = "mining_voucher"
	w_class = WEIGHT_CLASS_TINY

/**********************Mining Point Card**********************/
//mp = Miner Pointers
//c  =  Cash
//TODO add in cr = Credits for cargo
/obj/item/card/mining_point_card
	name = "mining points card"
	desc = "A small card for transferring mining points. Swipe your ID card over it to start the process."
	icon_state = "data_1"
	var/points = 500

/obj/item/card/mining_point_card/fifty
	points = 50

/obj/item/card/mining_point_card/fivethousand
	points = 5000

/obj/item/card/mining_point_card/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/card/id))
		var/obj/item/card/id/id = I
		to_chat(user, span_info("You swipe [id] on [src] and start the transfer process."))
		var/choice = alert(user, "Do you want to transfer points to or from the point card's storage?", "Mining Points Transfer", "From Point Card/Storage", "To Point Card/Storage", "Cancel")
		if(choice != "Cancel")
			var/amount = input(user, "How much do you want to transfer? ID Balance: [id.mining_points], Transfer Card Balance: [points]", "Transfer Points") as num|null
			if(!amount || amount <= 0)
				return
			amount = round(amount, 1)
			if(choice == "To Point Card/Storage")
				if(amount && amount <= id.mining_points)
					id.mining_points -= amount
					points += amount
					to_chat(user, span_info("You transfer [amount] points to [src] from [id]."))
			else if(choice == "From Point Card/Storage")
				if(amount && amount <= points)
					id.mining_points += amount
					points -= amount
					to_chat(user, span_info("You transfer [amount] points to [id] from [src]."))
	/*
		if(points)
			var/obj/item/card/id/C = I
			C.mining_points += points
			to_chat(user, "<span class='info'>You transfer [points] points to [C].</span>")
			points = 0
		else
			to_chat(user, "<span class='info'>There's no points left on [src].</span>")
	*/
	..()

/obj/item/card/mining_point_card/examine(mob/user)
	. = ..()
	. += "There's [points] point\s on the card."

///Conscript kit
/obj/item/card/mining_access_card
	name = "mining access card"
	desc = "A small card, that when used on any ID, will add mining access."
	icon_state = "data_1"

/obj/item/card/mining_access_card/afterattack(atom/movable/AM, mob/user, proximity)
	. = ..()
	if(istype(AM, /obj/item/card/id) && proximity)
		var/obj/item/card/id/I = AM
		I.access |=	ACCESS_MINING
		I.access |= ACCESS_MINING_STATION
		I.access |= ACCESS_MINERAL_STOREROOM
		I.access |= ACCESS_CARGO
		I.access |= ACCESS_PRODUCTION_CARGO
		to_chat(user, "You upgrade [I] with mining access.")
		qdel(src)

/obj/item/storage/backpack/duffelbag/mining/conscript
	name = "mining conscription kit"
	desc = "A kit containing everything a crewmember needs to support a shaft miner in the field."

/obj/item/storage/backpack/duffelbag/mining/conscript/PopulateContents()
	new /obj/item/pickaxe/mini(src)
	new /obj/item/clothing/glasses/meson(src)
	new /obj/item/t_scanner/adv_mining_scanner/lesser(src)
	new /obj/item/storage/bag/ore(src)
	new /obj/item/clothing/suit/hooded/explorer/standard(src)
	new /obj/item/encryptionkey/headset_cargo(src)
	new /obj/item/clothing/mask/gas/explorer(src)
	new /obj/item/card/mining_access_card(src)
	new /obj/item/gun/energy/kinetic_accelerator(src)
	new /obj/item/kitchen/knife/combat/survival(src)
	new /obj/item/flashlight/seclite(src)

	//CITADEL ADDITIONS BELOW

/obj/item/storage/backpack/duffelbag/mining/cloned
	name = "mining replacement kit"
	desc = "A large bag that has advanced tools and a spare jumpsuit, boots, and gloves for a newly cloned miner to get back in the field. Even has a new ID!"

/obj/item/storage/backpack/duffelbag/mining/cloned/PopulateContents()
	new /obj/item/pickaxe/mini(src)
	new /obj/item/clothing/under/rank/cargo/miner/lavaland(src)
	new /obj/item/clothing/shoes/workboots/mining(src)
	new /obj/item/clothing/gloves/color/black(src)
	new /obj/item/implanter/tracking/gps(src)
	new /obj/item/gun/energy/kinetic_accelerator(src)
	new /obj/item/kitchen/knife/combat/survival(src)
	new /obj/item/storage/firstaid/regular(src)
	new /obj/item/reagent_containers/hypospray/medipen/survival(src)
	new /obj/item/t_scanner/adv_mining_scanner(src)
	new /obj/item/clothing/suit/hooded/explorer/standard(src)
	new /obj/item/encryptionkey/headset_cargo(src)
	new /obj/item/clothing/mask/gas/explorer(src)
	new /obj/item/card/id/mining(src)
	new /obj/item/storage/bag/ore(src)
	new /obj/item/clothing/glasses/meson/prescription(src)

/obj/item/storage/backpack/duffelbag/mining/glaivekit

/obj/item/storage/backpack/duffelbag/mining/glaivekit/PopulateContents()
	new /obj/item/kitchen/knife/combat/survival/knuckledagger(src)
	new /obj/item/premium_crusher_voucher(src)
