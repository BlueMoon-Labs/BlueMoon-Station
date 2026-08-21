// ============================================
// DATUM ДЛЯ ТОВАРОВ
// ============================================
/datum/data/bounty_equipment
	var/equipment_name = "generic"
	var/equipment_path = null
	var/cost = 0
	var/category = ""
	var/base_cost = 0

/datum/data/bounty_equipment/New(name, path, cost, category)
	src.equipment_name = name
	src.equipment_path = path
	src.cost = cost
	src.category = category
	src.base_cost = cost

// ============================================
// BOUNTY VEND
// ============================================
/obj/machinery/bountyvend
	name = "\improper BountyVend"
	desc = "A secure terminal for requisitioning specialized contraband equipment using bounty points. Can be upgraded with matter bins to reduce prices."
	icon = 'icons/obj/vending.dmi'
	icon_state = "syndicate-marine"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 100
	circuit = /obj/item/circuitboard/machine/bountyvend
	var/icon_deny = "syndicate-marine-deny"

	var/list/prize_list = list(
		// Melee Weaponry
		new /datum/data/bounty_equipment("Baton",					/obj/item/melee/baton,										30,		"Melee Weaponry"),
		new /datum/data/bounty_equipment("Survival Knife",			/obj/item/kitchen/knife/combat/survival,					80,		"Melee Weaponry"),
		// Armor
		new /datum/data/bounty_equipment("Armor Vest",				/obj/item/clothing/suit/armor/vest,						50,		"Armor"),
		new /datum/data/bounty_equipment("Ballistic Helmet",		/obj/item/clothing/head/helmet,							40,		"Armor"),
		// Medical
		new /datum/data/bounty_equipment("First-Aid Kit",			/obj/item/storage/firstaid/regular,						25,		"Medical"),
		new /datum/data/bounty_equipment("Brute First-Aid Kit",		/obj/item/storage/firstaid/brute,							40,		"Medical"),
		new /datum/data/bounty_equipment("Burn First-Aid Kit",		/obj/item/storage/firstaid/fire,							40,		"Medical"),
		new /datum/data/bounty_equipment("Survival Medipen",		/obj/item/reagent_containers/hypospray/medipen/survival,	60,	"Medical"),
		new /datum/data/bounty_equipment("CMS",						/obj/item/stack/medical/fracture_kit/cms,	150,	"Medical"),
		new /datum/data/bounty_equipment("Surv12",					/obj/item/stack/medical/fracture_kit/surv12,	250,	"Medical"),
		// Tools
		new /datum/data/bounty_equipment("Multitool",				/obj/item/multitool,										40,		"Tools"),
		new /datum/data/bounty_equipment("Welder",					/obj/item/weldingtool,									30,		"Tools"),
		new /datum/data/bounty_equipment("Crowbar",					/obj/item/crowbar,										20,		"Tools"),
		// Recreational
		new /datum/data/bounty_equipment("Whiskey",					/obj/item/reagent_containers/food/drinks/bottle/whiskey,	40,		"Recreational"),
		new /datum/data/bounty_equipment("Cigar",					/obj/item/clothing/mask/cigarette/cigar/havana,			60,		"Recreational"),
	)

// ============================================
// ИНИЦИАЛИЗАЦИЯ
// ============================================

/obj/machinery/bountyvend/Initialize(mapload)
	. = ..()
	build_inventory()

/obj/machinery/bountyvend/proc/build_inventory()
	for(var/p in prize_list)
		var/datum/data/bounty_equipment/M = p
		GLOB.vending_products[M.equipment_path] = 1

/obj/machinery/bountyvend/update_icon_state()
	if(powered())
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]-off"

// ============================================
// СИСТЕМА СКИДОК (как в mining vendor)
// ============================================

/obj/machinery/bountyvend/RefreshParts()
	var/discount_rate = 0.0
	// По 2.5% за каждый тир matter bin ВЫШЕ первого
	// T1 = 0%, T2 = 2.5%, T3 = 5%, T4 = 7.5%
	// 3× T4 = 22.5% скидки
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		discount_rate += 0.025 * (bin.rating - 1)

	for(var/datum/data/bounty_equipment/prize in prize_list)
		prize.cost = max(1, round(prize.base_cost * (1 - discount_rate)))

	update_static_data_for_all_viewers()

/obj/machinery/bountyvend/proc/get_discount()
	var/discount_rate = 0.0
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		discount_rate += 0.025 * (bin.rating - 1)
	return discount_rate

// ============================================
// ОСМОТР
// ============================================

/obj/machinery/bountyvend/examine(mob/user)
	. = ..()
	. += "\nDisplay shows you current discount of the vending machine: [span_green("[get_discount() * 100]%")]"

// ============================================
// TGUI
// ============================================

/obj/machinery/bountyvend/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/vending),
	)

/obj/machinery/bountyvend/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BountyVend", name)
		ui.open()

/obj/machinery/bountyvend/ui_static_data(mob/user)
	. = list()
	.["product_records"] = list()
	for(var/datum/data/bounty_equipment/prize in prize_list)
		if(!prize.category || prize.category == "")
			prize.category = "Miscellaneous"

		// Генерируем HTML с иконкой предмета
		var/obj/item/temp = new prize.equipment_path()
		var/icon_html = icon2html(temp, user)
		qdel(temp)

		var/list/product_data = list(
			path = replacetext(replacetext("[prize.equipment_path]", "/obj/item/", ""), "/", "-"),
			name = prize.equipment_name,
			price = prize.cost,
			category = prize.category,
			ref = REF(prize),
			icon = icon_html
		)
		.["product_records"] += list(product_data)

	.["categories"] = list(
		"Melee Weaponry",
		"Armor",
		"Medical",
		"Tools",
		"Recreational",
		"Miscellaneous"
	)
	.["discount"] = get_discount()

/obj/machinery/bountyvend/ui_data(mob/user)
	. = list()
	var/mob/living/L = user
	var/obj/item/card/id/C = L?.get_idcard(TRUE)
	if(C)
		.["user"] = list()
		.["user"]["points"] = C.contraband_points
		if(C.registered_account)
			.["user"]["name"] = C.registered_account.account_holder
			if(C.registered_account.account_job)
				.["user"]["job"] = C.registered_account.account_job.title
			else
				.["user"]["job"] = "No Job"

/obj/machinery/bountyvend/ui_act(action, params)
	if(..())
		return

	switch(action)
		if("purchase")
			var/mob/M = usr
			var/obj/item/card/id/I = M.get_idcard(TRUE)
			if(!istype(I))
				to_chat(usr, "<span class='alert'>Error: An ID is required!</span>")
				flick(icon_deny, src)
				return
			var/datum/data/bounty_equipment/prize = locate(params["ref"]) in prize_list
			if(!prize || !(prize in prize_list))
				to_chat(usr, "<span class='alert'>Error: Invalid choice!</span>")
				flick(icon_deny, src)
				return
			if(prize.cost > I.contraband_points)
				to_chat(usr, "<span class='alert'>Error: Insufficient points for [prize.equipment_name] on [I]!</span>")
				flick(icon_deny, src)
				return
			I.contraband_points -= prize.cost
			to_chat(usr, "<span class='notice'>[src] clanks to life briefly before vending [prize.equipment_name]!</span>")
			playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
			new prize.equipment_path(loc)
			return TRUE

/obj/machinery/bountyvend/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/vanguard_voucher_class))
		RedeemVoucher(I, user)
		return
	if(istype(I, /obj/item/vanguard_voucher_suit))
		RedeemSVoucher(I, user)
		return
	if(default_deconstruction_screwdriver(user, "syndicate-marine-off", "syndicate-marine", I))
		return
	if(default_deconstruction_crowbar(I))
		return
	return ..()

/obj/machinery/bountyvend/proc/RedeemVoucher(obj/item/vanguard_voucher_class/voucher, mob/redeemer)
	var/items = list(	"Demolition Expert" = image(icon = 'modular_bluemoon/icons/obj/guns/energy.dmi', icon_state = "flashgun"),
						"Field Surgeon" = image(icon = 'icons/obj/mining.dmi', icon_state = "resonator"),
						"Combatant" = image(icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi', icon_state = "sauer"))

	var/selection = show_radial_menu(redeemer, src, items, require_near = TRUE, tooltips = TRUE)
	if(!selection || !Adjacent(redeemer) || QDELETED(voucher) || voucher.loc != redeemer)
		return
	var/drop_location = drop_location()
	switch(selection)
		if("Demolition Expert")
			new /obj/item/storage/belt/mining/vendor(drop_location)
		if("Field Surgeon")
			new /obj/item/extinguisher/mini(drop_location)
			new /obj/item/resonator(drop_location)
		if("Combatant")
			new /mob/living/simple_animal/hostile/mining_drone(drop_location)
			new /obj/item/weldingtool/hugetank(drop_location)
			new /obj/item/clothing/head/welding(drop_location)
			new /obj/item/borg/upgrade/modkit/minebot_passthrough(drop_location)
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	SSblackbox.record_feedback("tally", "mining_voucher_redeemed", 1, selection)
	qdel(voucher)

/obj/machinery/bountyvend/proc/RedeemSVoucher(/obj/item/vanguard_voucher_suit, mob/redeemer)
	var/items = list(	"Exo-suit" = image(icon = 'icons/obj/clothing/suits.dmi', icon_state = "exo"),
						"HEVA suit" = image(icon = 'icons/obj/clothing/suits.dmi', icon_state = "heva"))

// ============================================
// Ваучеры снаряжения
// ============================================

/obj/item/vanguard_voucher_class
	name = "specialization voucher"
	desc = "A token to redeem a piece of equipment. Use it on a mining equipment vendor."
	icon = 'icons/obj/vending.dmi'
	icon_state = "syndie-voucher"
	w_class = WEIGHT_CLASS_TINY

/obj/item/vanguard_voucher_suit
	name = "vanguard suit voucher"
	desc = "A token to redeem a new suit. Use it on a mining equipment vendor."
	icon = 'icons/obj/vending.dmi'
	icon_state = "syndie-voucher"
	w_class = WEIGHT_CLASS_TINY
