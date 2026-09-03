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
		// ============ WEAPONRY ============
		new /datum/data/bounty_equipment("Premium KA",					/obj/item/gun/energy/kinetic_accelerator/premiumka,				1250,	"Weaponry"),
		new /datum/data/bounty_equipment("Combat knife",				/obj/item/kitchen/knife/combat,					        		100,	"Weaponry"),
		new /datum/data/bounty_equipment("Electronic Firing Pin",		/obj/item/firing_pin,											500,	"Weaponry"),
		new /datum/data/bounty_equipment("Supressor",               	/obj/item/suppressor,                                   		500, 	"Weaponry"),
		new /datum/data/bounty_equipment("Munitions datadisk",      	/obj/item/disk/ammo_workbench/advanced,                     	1000, 	"Weaponry"),
		new /datum/data/bounty_equipment("Vanguard specialization",		/obj/item/vanguard_voucher_class,								2000,	"Weaponry"),
		new /datum/data/bounty_equipment("Sig Suaer extended mag",		/obj/item/ammo_box/magazine/sig/sig_ext,						500,	"Weaponry"),

		// ============ ARMOR ============
		new /datum/data/bounty_equipment("Vanguard armor",					/obj/item/vanguard_voucher_suit,								1500,	"Armor"),
		new /datum/data/bounty_equipment("Ranger hardsuit",					/obj/item/clothing/suit/space/hardsuit/exploration,				2500,	"Armor"),
		new /datum/data/bounty_equipment("Combined armor kit",				/obj/item/armorkit/vanguard/vest,								750,	"Armor"),
		new /datum/data/bounty_equipment("Combined headgear kit",			/obj/item/armorkit/vanguard/helmet,								750,	"Armor"),
		new /datum/data/bounty_equipment("Jet harness",						/obj/item/tank/jetpack/oxygen/harness,							1500,	"Armor"),
		new /datum/data/bounty_equipment("Jetpack upgrade",					/obj/item/tank/jetpack/suit,									1000,	"Armor"),
		new /datum/data/bounty_equipment("Vanguard modsuit",				/obj/item/mod/control/pre_equipped/expeditor,					5000,	"Armor"),
		new /datum/data/bounty_equipment("Jump boots",						/obj/item/clothing/shoes/bhop,									1250,	"Armor"),

		// ============ MEDICAL ============
		new /datum/data/bounty_equipment("First-Aid Kit",					/obj/item/storage/firstaid/regular,								25,		"Medical"),
		new /datum/data/bounty_equipment("Brute First-Aid Kit",				/obj/item/storage/firstaid/brute,								50,		"Medical"),
		new /datum/data/bounty_equipment("Burn First-Aid Kit",				/obj/item/storage/firstaid/fire,								50,		"Medical"),
		new /datum/data/bounty_equipment("Survival Medipen",				/obj/item/reagent_containers/hypospray/medipen/survival,		100,	"Medical"),
		new /datum/data/bounty_equipment("CMS",								/obj/item/stack/medical/fracture_kit/cms,						150,	"Medical"),
		new /datum/data/bounty_equipment("Surv12",							/obj/item/stack/medical/fracture_kit/surv12,					250,	"Medical"),

		// ============ TOOLS ============
		new /datum/data/bounty_equipment("Lazarus injector",				/obj/item/lazarus_injector,										500,	"Tools"),
		new /datum/data/bounty_equipment("Fulton pack",						/obj/item/extraction_pack,										500,	"Tools"),
		new /datum/data/bounty_equipment("Auto surgeon",					/obj/item/autosurgeon,											750,	"Tools"),
		new /datum/data/bounty_equipment("Illegal technology disk",			/obj/item/disk/tech_disk/illegal,								5000,	"Tools"),
		new /datum/data/bounty_equipment("Fulton beacon",					/obj/item/fulton_core,											200,	"Tools"),
		new /datum/data/bounty_equipment("BEPIS technology disk",			/obj/item/disk/tech_disk/major,									1000,	"Tools"),
		new /datum/data/bounty_equipment("Vanguard basic kit",				/obj/item/storage/backpack/duffelbag/vanguard/conscript,		1500,	"Tools"),
		new /datum/data/bounty_equipment("Vanguard points transfer card",	/obj/item/card/contraband_point_card,							100,	"Tools"),

		// ============ RECREATIONAL ============
		new /datum/data/bounty_equipment("Whiskey",							/obj/item/reagent_containers/food/drinks/bottle/whiskey,		50,		"Recreational"),
		new /datum/data/bounty_equipment("Cigar",							/obj/item/clothing/mask/cigarette/cigar/havana,					75,		"Recreational"),
		new /datum/data/bounty_equipment("High quality Soap",				/obj/item/soap/syndie,											150,	"Recreational"),
		new /datum/data/bounty_equipment("MRE pack",						/obj/item/storage/box/mre/menu2,								300,	"Recreational"),

		// ============ ELITE EQUIPMENT =========
		new /datum/data/bounty_equipment("ACR-5m26",						/obj/item/gun/ballistic/automatic/acr5m30,						20000,	"Elite Equipment"),
		new /datum/data/bounty_equipment("Budget tactical first aid",		/obj/item/storage/firstaid/tactical/vanguard,					5000,	"Elite Equipment"),
		new /datum/data/bounty_equipment("ACR-5m26 spare mag (empty)",		/obj/item/ammo_box/magazine/acr5m30/empty,						2500,	"Elite Equipment"),
		new /datum/data/bounty_equipment("Hoshi modular laser",				/obj/item/gun/energy/modular_laser_rifle/carbine,				25000,	"Elite Equipment"),
		new /datum/data/bounty_equipment("Advanced ion jetpack",			/obj/item/mod/module/jetpack/advanced,							5000,	"Elite Equipment"),
		new /datum/data/bounty_equipment("С-02 Permit",						/obj/item/clothing/accessory/permit/special/c_02,				10000,	"Elite Equipment"),
		new /datum/data/bounty_equipment("Nanotrasen & Syndicate Uplink",	/obj/item/syndicate_uplink/station,								75000,	"Elite Equipment"),
		new /datum/data/bounty_equipment("Department Prototlathe beacon",	/obj/item/choice_beacon/departmental_protholate,								20000,	"Elite Equipment"),
	)

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
	.["categories"] = list("Weaponry", "Armor", "Medical", "Tools", "Recreational", "Miscellaneous", "Elite Equipment")
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
			if(ispath(prize.equipment_path, /obj/item/stack/metadollar) && !bm_bounty_vendor_can_buy_metadollar(usr))
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
			new /obj/item/storage/box/demolition(drop_location)
		if("Field Surgeon")
			new /obj/item/stack/medical/fracture_kit/cms(drop_location)
			new /obj/item/storage/firstaid/frontier(drop_location)
			new /obj/item/melee/tomahawk(drop_location)
			new /obj/item/storage/firstaid/vanguard(drop_location)
			new /obj/item/shield/riot/pointman(drop_location)
			new /obj/item/defibrillator/compact/loaded(drop_location)
		if("Combatant")
			new /obj/item/storage/secure/briefcase/vanguard/p320(drop_location)
			new /obj/item/storage/belt/military/assault(drop_location)
			new /obj/item/storage/bag/medpen/combatant(drop_location)
			new /obj/item/storage/bag/marksman(drop_location)
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


// ============================================
// ДОПОЛНИТЕЛЬНЫЕ ПРЕДМЕТЫ (Basic kit)
// ============================================

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


// Потому что нехорошие люди абьюзят метадолоровку - оставляю их только в специальном вендомате станции

/obj/machinery/bountyvend/plus
	name = "BountyVend Expert"
	circuit = /obj/item/circuitboard/machine/bountyvend/plus

/obj/machinery/bountyvend/plus/Initialize(mapload)
	. = ..()
	desc += "\nIt seems a few selections have been added."
	prize_list += list(
		// ============ MISCELLANEOUS ============
		new /datum/data/bounty_equipment("1 Metadollar",            		/obj/item/stack/metadollar, 									25000, 	"Miscellaneous"),
		new /datum/data/bounty_equipment("space cash",						/obj/item/stack/spacecash/c1000,								1500,	"Miscellaneous")
		)
	build_inventory()

// и дабл чек что бы могли покупать только авангардцы
/proc/bm_bounty_vendor_can_buy_metadollar(mob/user)
	if(!ishuman(user))
		to_chat(user, span_warning("Нужна гуманоидная форма."))
		return FALSE
	var/mob/living/carbon/human/H = user
	if(!H.mind?.assigned_role)
		to_chat(H, span_warning("Нужна зарегистрированная профессия."))
		return FALSE
	var/datum/job/J = SSjob.GetJob(H.mind.assigned_role)
	if(!istype(J, /datum/job/expeditor))
		to_chat(H, span_warning("Попридержи коней, приятель. Эта награда тебе не по зубам, доступна только настоящим оперативникам."))
		return FALSE
	return TRUE
