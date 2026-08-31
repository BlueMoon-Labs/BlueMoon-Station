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

	var/list/prize_config = list(
		list("name" = "Premium KA", "path" = /obj/item/gun/energy/kinetic_accelerator/premiumka, "cost" = 1250, "category" = "Weaponry"),
		list("name" = "Combat knife", "path" = /obj/item/kitchen/knife/combat, "cost" = 100, "category" = "Weaponry"),
		list("name" = "Electronic Firing Pin", "path" = /obj/item/firing_pin, "cost" = 500, "category" = "Weaponry"),
		list("name" = "Supressor", "path" = /obj/item/suppressor, "cost" = 500, "category" = "Weaponry"),
		list("name" = "Munitions datadisk", "path" = /obj/item/disk/ammo_workbench/advanced, "cost" = 1000, "category" = "Weaponry"),
		list("name" = "Vanguard specialization", "path" = /obj/item/vanguard_voucher_class, "cost" = 2000, "category" = "Weaponry"),
		list("name" = "Sig Suaer extended mag", "path" = /obj/item/ammo_box/magazine/sig/sig_ext, "cost" = 500, "category" = "Weaponry"),
		list("name" = "Vanguard armor", "path" = /obj/item/vanguard_voucher_suit, "cost" = 1500, "category" = "Armor"),
		list("name" = "Ranger hardsuit", "path" = /obj/item/clothing/suit/space/hardsuit/exploration, "cost" = 2500, "category" = "Armor"),
		list("name" = "Combined armor kit", "path" = /obj/item/armorkit/vanguard/vest, "cost" = 750, "category" = "Armor"),
		list("name" = "Combined headgear kit", "path" = /obj/item/armorkit/vanguard/helmet, "cost" = 750, "category" = "Armor"),
		list("name" = "Jet harness", "path" = /obj/item/tank/jetpack/oxygen/harness, "cost" = 1500, "category" = "Armor"),
		list("name" = "Jetpack upgrade", "path" = /obj/item/tank/jetpack/suit, "cost" = 1000, "category" = "Armor"),
		list("name" = "Vanguard modsuit", "path" = /obj/item/mod/control/pre_equipped/expeditor, "cost" = 5000, "category" = "Armor"),
		list("name" = "Jump boots", "path" = /obj/item/clothing/shoes/bhop, "cost" = 1250, "category" = "Armor"),
		list("name" = "First-Aid Kit", "path" = /obj/item/storage/firstaid/regular, "cost" = 25, "category" = "Medical"),
		list("name" = "Brute First-Aid Kit", "path" = /obj/item/storage/firstaid/brute, "cost" = 50, "category" = "Medical"),
		list("name" = "Burn First-Aid Kit", "path" = /obj/item/storage/firstaid/fire, "cost" = 50, "category" = "Medical"),
		list("name" = "Survival Medipen", "path" = /obj/item/reagent_containers/hypospray/medipen/survival, "cost" = 100, "category" = "Medical"),
		list("name" = "CMS", "path" = /obj/item/stack/medical/fracture_kit/cms, "cost" = 150, "category" = "Medical"),
		list("name" = "Budget tactical first aid", "path" = /obj/item/storage/firstaid/tactical/vanguard, "cost" = 5000, "category" = "Medical"),
		list("name" = "Surv12", "path" = /obj/item/stack/medical/fracture_kit/surv12, "cost" = 250, "category" = "Medical"),
		list("name" = "Lazarus injector", "path" = /obj/item/lazarus_injector, "cost" = 500, "category" = "Tools"),
		list("name" = "Fulton pack", "path" = /obj/item/extraction_pack, "cost" = 500, "category" = "Tools"),
		list("name" = "Auto surgeon", "path" = /obj/item/autosurgeon, "cost" = 750, "category" = "Tools"),
		list("name" = "Illegal technology disk", "path" = /obj/item/disk/tech_disk/illegal, "cost" = 5000, "category" = "Tools"),
		list("name" = "Fulton beacon", "path" = /obj/item/fulton_core, "cost" = 200, "category" = "Tools"),
		list("name" = "BEPIS technology disk", "path" = /obj/item/disk/tech_disk/major, "cost" = 1000, "category" = "Tools"),
		list("name" = "Vanguard basic kit", "path" = /obj/item/storage/backpack/duffelbag/vanguard/conscript, "cost" = 1500, "category" = "Tools"),
		list("name" = "Vanguard points transfer card", "path" = /obj/item/card/contraband_point_card, "cost" = 100, "category" = "Tools"),
		list("name" = "Whiskey", "path" = /obj/item/reagent_containers/food/drinks/bottle/whiskey, "cost" = 50, "category" = "Recreational"),
		list("name" = "Cigar", "path" = /obj/item/clothing/mask/cigarette/cigar/havana, "cost" = 75, "category" = "Recreational"),
		list("name" = "High quality Soap", "path" = /obj/item/soap/syndie, "cost" = 150, "category" = "Recreational"),
		list("name" = "MRE pack", "path" = /obj/item/storage/box/mre/menu2, "cost" = 300, "category" = "Recreational"),
		list("name" = "1 Metadollar", "path" = /obj/item/stack/metadollar, "cost" = 25000, "category" = "Miscellaneous"),
		list("name" = "space cash", "path" = /obj/item/stack/spacecash/c1000, "cost" = 1500, "category" = "Miscellaneous"),
	)

	var/list/prize_list = list()

/obj/machinery/bountyvend/Initialize(mapload)
	. = ..()
	for(var/list/config in prize_config)
		var/datum/data/bounty_equipment/prize = new(config["name"], config["path"], config["cost"], config["category"])
		prize_list += prize

/obj/machinery/bountyvend/update_icon_state()
	if(powered())
		icon_state = initial(icon_state)
	else
		icon_state = "[initial(icon_state)]-off"

/obj/machinery/bountyvend/RefreshParts()
	var/discount_rate = 0.0
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		discount_rate += 0.025 * (bin.rating - 1)
	for (var/datum/data/bounty_equipment/prize in prize_list)
		if(ispath(prize.equipment_path, /obj/item/stack/metadollar))
			continue
		prize.cost = max(1, round(prize.base_cost * (1 - discount_rate)))
	update_static_data_for_all_viewers()

/obj/machinery/bountyvend/proc/get_discount()
	var/discount_rate = 0.0
	for(var/obj/item/stock_parts/matter_bin/bin in component_parts)
		discount_rate += 0.025 * (bin.rating - 1)
	return discount_rate

/obj/machinery/bountyvend/examine(mob/user)
	. = ..()
	. += "\nDisplay shows you current discount of the vending machine: [span_green("[get_discount() * 100]%")]"

/obj/machinery/bountyvend/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet_batched/vending),
	)

/obj/machinery/bountyvend/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "BountyVend", name)
		ui.open()

/obj/machinery/bountyvend/ui_static_data(mob/user)
	. = list()
	var/list/records = list()
	for(var/datum/data/bounty_equipment/prize in prize_list)
		if(!prize.category || prize.category == "")
			prize.category = "Miscellaneous"
		var/list/product_data = list(
			"path" = replacetext(replacetext("[prize.equipment_path]", "/obj/item/", ""), "/", "-"),
			"name" = prize.equipment_name,
			"price" = prize.cost,
			"category" = prize.category,
			"ref" = REF(prize)
		)
		records += list(product_data)
	.["product_records"] = records
	.["categories"] = list("Weaponry", "Armor", "Medical", "Tools", "Recreational", "Miscellaneous")
	.["discount"] = get_discount()

/obj/machinery/bountyvend/ui_data(mob/user)
	. = list()
	var/obj/item/card/id/C = user?.get_idcard(TRUE)
	if(C)
		.["user"] = list()
		.["user"]["points"] = C.contraband_points
		if(C.registered_account)
			.["user"]["name"] = C.registered_account.account_holder || "Unknown"
			.["user"]["job"] = C.registered_account.account_job?.title || "No Job"
		else
			.["user"]["name"] = "Unknown"
			.["user"]["job"] = "No ID"

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
	var/items = list(
		"Demolition Expert" = image(icon = 'modular_bluemoon/icons/obj/guns/energy.dmi', icon_state = "flashgun"),
		"Field Surgeon" = image(icon = 'icons/obj/stack_objects.dmi', icon_state = "cms"),
		"Combatant" = image(icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi', icon_state = "sauer")
	)
	var/selection = show_radial_menu(redeemer, src, items, require_near = TRUE, tooltips = TRUE)
	if(!selection || !Adjacent(redeemer) || QDELETED(voucher) || voucher.loc != redeemer)
		return
	var/drop_location = drop_location()
	switch(selection)
		if("Demolition Expert")
			new /obj/item/storage/secure/briefcase/vanguard/lasgun(drop_location)
			new /obj/item/storage/belt/military/assault/demolition(drop_location)
			new /obj/item/extinguisher/mini(drop_location)
			new /obj/item/storage/box/red/demolition(drop_location)
		if("Field Surgeon")
			new /obj/item/stack/medical/fracture_kit/cms(drop_location)
			new /obj/item/storage/belt/military/assault/surgeon(drop_location)
			new /obj/item/melee/tomahawk(drop_location)
			new /obj/item/storage/box/blue/surgeon(drop_location)
			new /obj/item/shield/riot/pointman(drop_location)
		if("Combatant")
			new /obj/item/storage/secure/briefcase/vanguard/p320(drop_location)
			new /obj/item/storage/belt/military/assault(drop_location)
			new /obj/item/storage/box/orange/combatant(drop_location)
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	SSblackbox.record_feedback("tally", "vanguard_voucher_redeemed", 1, selection)
	qdel(voucher)

/obj/machinery/bountyvend/proc/RedeemSVoucher(obj/item/vanguard_voucher_suit/voucher, mob/redeemer)
	var/items = list(
		"EVA" = image(icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi', icon_state = "hardsuit0-explorer"),
		"Combined suit" = image(icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi', icon_state = "combined")
	)
	var/selection = show_radial_menu(redeemer, src, items, require_near = TRUE, tooltips = TRUE)
	if(!selection || !Adjacent(redeemer) || QDELETED(voucher) || voucher.loc != redeemer)
		return
	var/drop_location = drop_location()
	switch(selection)
		if("EVA")
			new /obj/item/clothing/suit/space/vanguard(drop_location)
			new /obj/item/clothing/head/helmet/space/vanguard(drop_location)
		if("Combined suit")
			new /obj/item/clothing/suit/armor/vanguard(drop_location)
			new /obj/item/clothing/head/helmet/vanguard(drop_location)
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	SSblackbox.record_feedback("tally", "suit_voucher_redeemed", 1, selection)
	qdel(voucher)

///Basic kit
/obj/item/card/vanguard_access_card
	name = "mining access card"
	desc = "A small card, that when used on any ID, will add Vanguard operative access."
	icon_state = "data_1"

/obj/item/card/vanguard_access_card/afterattack(atom/movable/AM, mob/user, proximity)
	. = ..()
	if(istype(AM, /obj/item/card/id) && proximity)
		var/obj/item/card/id/I = AM
		I.access |=	ACCESS_RESEARCH
		I.access |= ACCESS_GATEWAY
		I.access |= ACCESS_PRODUCTION_SCIENCE
		to_chat(user, "You upgrade [I] with Vanguard operative access.")
		qdel(src)

/obj/item/storage/backpack/duffelbag/vanguard/conscript
	name = "Vanguard basic kit"
	desc = "Some outdated vanguard equipment for new members of squadrons"

/obj/item/storage/backpack/duffelbag/vanguard/conscript/PopulateContents()
	. = ..()
	new /obj/item/gun/energy/e_gun/mini/expeditor(src)
	new /obj/item/clothing/head/helmet/exp(src)
	new /obj/item/clothing/suit/armor/vest/exp(src)
	new /obj/item/tank/internals/emergency_oxygen/engi(src)
	new /obj/item/card/vanguard_access_card(src)
	new /obj/item/kitchen/knife/combat(src)
	new /obj/item/radio/headset/headset_exp(src)
	new /obj/item/clothing/glasses/sunglasses(src)
