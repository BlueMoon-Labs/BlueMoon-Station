// ============================================
// Ваучеры снаряжения
// ============================================

/obj/item/vanguard_voucher_class
	name = "specialization voucher"
	desc = "Ваучер для получения комплекта снаряжения. Видно этикетку \"BountyVend\"."
	icon = 'icons/obj/vending.dmi'
	icon_state = "syndie-voucher"
	w_class = WEIGHT_CLASS_TINY

/obj/item/vanguard_voucher_class/examine(mob/user)
	. = ..()
	. += span_notice("Кажется, можно осмотреть получше...")

/obj/item/vanguard_voucher_class/examine_more(mob/user)
	. = ..()
	. += span_boldnotice("<hr><center>Выберите себе набор снаряжения!</center>")
	. += "<div style='margin-top:4px;'>• <b>[span_yellowteamradio("Гренадёр")]</b> – эксперт по проникновению поможет эскадрону инженерный набором и сумкой с термитными зарядами. \
	Вооружён лаз-пистолетом на сменных и перезаряжаемых батареях.</div>"
	. += "<div style='margin-top:4px;'>• <b>[span_green("Фельдшер")]</b> – полевой врач и передовой ресурс с ценными медикаментами, вооружённый спектром оружия ближнего боя \
	и хирургическими инструментами.</div>"
	. += "<div style='margin-top:4px;'>• <b>[span_red("Штурмовик")]</b> – специалист по убийству всего что движется с двумя пистолетами, откалиброванных под огонь \
	по-македонски, набором метательных ножей и подсумком с медикаментами.</div>"

/obj/item/vanguard_voucher_suit
	name = "vanguard suit voucher"
	desc = "Ваучер для получения комплекта одежды. Видно этикетку \"BountyVend\"."
	icon = 'icons/obj/vending.dmi'
	icon_state = "syndie-voucher"
	w_class = WEIGHT_CLASS_TINY

/obj/item/vanguard_voucher_suit/examine(mob/user)
	. = ..()
	. += span_notice("Кажется, можно осмотреть получше...")

/obj/item/vanguard_voucher_suit/examine_more(mob/user)
	. = ..()
	. += span_boldnotice("<hr><center>Выберите себе набор защиты!</center>")
	. += "<div style='margin-top:4px;'>• <b>[span_notice("EVA")]</b> – бронированная EVA, способная защитить не только от космоса, но и его угроз!</div>"
	. += "<div style='margin-top:4px;'>• <b>[span_notice("Комбинезон")]</b> – бронированный шлем и бронежилет с покрытием всего тела для надёжной защиты!</div>"

// ============================================
// BOUNTY VEND
// ============================================
/obj/machinery/equipment_vendor/vanguard
	name = "\improper BountyVend"
	desc = "Бронированный автомат выдачи специализированного, порой контрабандного, снаряжения за очки награды."
	icon = 'icons/obj/vending.dmi'
	icon_state = "syndicate-marine"
	icon_deny = "syndicate-marine-deny"
	panel_open_icon = "syndicate-marine-off"
	density = TRUE
	anchored = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	active_power_usage = 100
	circuit = /obj/item/circuitboard/machine/bountyvend
	point_type = "contraband_points"
	point_label = "Очки награды"
	metadollar_job = /datum/job/expeditor
	metadollar_activity = "экспедиторскую деятельность"
	undiscounted_items = list(/obj/item/stack/metadollar)
	category_order = list("Ranged", "Melee", "Armor", "Elite", "Ammo", "Medical", "Tools", "Recreation", "Misc")

	prize_list = list(
				// ============ ОРУЖИЕ ДАЛЬНЕГО БОЯ ============
		new /datum/data/mining_equipment("Supressor",               	/obj/item/suppressor,                                   			500, 	"Ranged"),
		new /datum/data/mining_equipment("Spare P320",					/obj/item/gun/ballistic/automatic/pistol/sigsauer,					1000,	"Ranged"),
		new /datum/data/mining_equipment("Spare Laspistol",				/obj/item/gun/ballistic/automatic/laser/vanguard,					1000,	"Ranged"),
		new /datum/data/mining_equipment("Premium KA",					/obj/item/gun/energy/kinetic_accelerator/premiumka,					1250,	"Ranged"),
		new /datum/data/mining_equipment("Vanguard Service revolver",	/obj/item/gun/ballistic/revolver/r45l/vanguard,						5000,	"Ranged"),

		// ============ АМУНИЦИЯ И БОЕПРИПАСЫ ============
		new /datum/data/mining_equipment("Spare P320 standart mag",		/obj/item/ammo_box/magazine/sig,									250,	"Ammo"),
		new /datum/data/mining_equipment("Sig Suaer extended mag",		/obj/item/ammo_box/magazine/sig/sig_ext,							500,	"Ammo"),
		new /datum/data/mining_equipment(".45 long lethal box",			/obj/item/ammo_box/g45l/lethal,										500,	"Ammo"),
		new /datum/data/mining_equipment("Spare lasbattery",			/obj/item/ammo_box/magazine/recharge/vanguard,						500,	"Ammo"),
		new /datum/data/mining_equipment("Empty marksman pouch",		/obj/item/storage/bag/marksman/empty,								750,	"Ammo"),
		new /datum/data/mining_equipment("Empty combatant pouch",		/obj/item/storage/bag/medpen/combatant/empty,						750,	"Ammo"),
		new /datum/data/mining_equipment("Ammunitions datadisk",      	/obj/item/disk/ammo_workbench/advanced,                     		1000, 	"Ammo"),
		new /datum/data/mining_equipment("Empty Vanguard belt",			/obj/item/storage/belt/avangard_belt/empty,							1500,	"Ammo"),
		new /datum/data/mining_equipment("Military belt",				/obj/item/storage/belt/military/green,								2500,	"Ammo"),

		// ============ ОРУЖИЕ БЛИЖНЕГО БОЯ ============
		new /datum/data/mining_equipment("Combat knife",				/obj/item/kitchen/knife/combat,					        			100,	"Melee"),
		new /datum/data/mining_equipment("Throwing knife",				/obj/item/kitchen/knife/combat/marksman,							250,	"Melee"),
		new /datum/data/mining_equipment("Spare Tomahawk",				/obj/item/melee/tomahawk,											1000,	"Melee"),
		new /datum/data/mining_equipment("Spare Shield",				/obj/item/shield/riot/pointman,										4500,	"Melee"),
		new /datum/data/mining_equipment("Spare Proton cutter",			/obj/item/melee/sabre/proton_cutter,								5000,	"Melee"),

		// ============ БРОНЯ, СКАФАНДРЫ, ЗАЩИТНОЕ СНАРЯЖЕНИЕ ============
		new /datum/data/mining_equipment("Combined armor kit",				/obj/item/armorkit/vanguard/vest,								750,	"Armor"),
		new /datum/data/mining_equipment("Combined headgear kit",			/obj/item/armorkit/vanguard/helmet,								750,	"Armor"),
		new /datum/data/mining_equipment("Jetpack upgrade",					/obj/item/tank/jetpack/suit,									1000,	"Armor"),
		new /datum/data/mining_equipment("Jump boots",						/obj/item/clothing/shoes/bhop,									1250,	"Armor"),
		new /datum/data/mining_equipment("Vanguard armor voucher",			/obj/item/vanguard_voucher_suit,								1500,	"Armor"),
		new /datum/data/mining_equipment("Jet harness",						/obj/item/tank/jetpack/oxygen/harness,							1500,	"Armor"),
		new /datum/data/mining_equipment("Ranger hardsuit",					/obj/item/clothing/suit/space/hardsuit/exploration,				2500,	"Armor"),
		new /datum/data/mining_equipment("Tactical Oxygen tank",			/obj/item/tank/internals/tactical,								2500,	"Armor"),
		new /datum/data/mining_equipment("Guerrilla Gloves",				/obj/item/clothing/gloves/tackler/combat/insulated,				3000,	"Armor"),
		new /datum/data/mining_equipment("Vanguard modsuit",				/obj/item/mod/control/pre_equipped/expeditor,					5000,	"Armor"),

		// ============ МЕДИКАМЕНТЫ ============
		new /datum/data/mining_equipment("First-Aid Kit",					/obj/item/storage/firstaid/regular,								100,	"Medical"),
		new /datum/data/mining_equipment("Brute First-Aid Kit",				/obj/item/storage/firstaid/brute,								250,	"Medical"),
		new /datum/data/mining_equipment("Burn First-Aid Kit",				/obj/item/storage/firstaid/fire,								250,	"Medical"),
		new /datum/data/mining_equipment("Toxin treatment kit",				/obj/item/storage/firstaid/toxin,								350,	"Medical"),
		new /datum/data/mining_equipment("Survival Medipen",				/obj/item/reagent_containers/hypospray/medipen/survival,		500,	"Medical"),
		new /datum/data/mining_equipment("Ferrocortex Medipen",				/obj/item/reagent_containers/hypospray/medipen/ferrocortex,		500,	"Medical"),
		new /datum/data/mining_equipment("CMS",								/obj/item/stack/medical/fracture_kit/cms,						750,	"Medical"),
		new /datum/data/mining_equipment("Surv12",							/obj/item/stack/medical/fracture_kit/surv12,					1500,	"Medical"),
		new /datum/data/mining_equipment("Psicodine pill bottle",			/obj/item/storage/pill_bottle/psicodine,						2500,	"Medical"),
		new /datum/data/mining_equipment("Hapiness pill bottle",			/obj/item/storage/pill_bottle/happinesspsych,					5000,	"Medical"),

		// ============ ИНСТРУМЕНТЫ ============
		new /datum/data/mining_equipment("Vanguard points transfer card",	/obj/item/card/contraband_point_card,							100,	"Tools"),
		new /datum/data/mining_equipment("Fulton beacon",					/obj/item/fulton_core,											200,	"Tools"),
		new /datum/data/mining_equipment("Spare detonation device",			/obj/item/exploration_detonator,								200,	"Tools"),
		new /datum/data/mining_equipment("Spare breaching charge",			/obj/item/grenade/exploration,									300,	"Tools"),
		new /datum/data/mining_equipment("Lazarus injector",				/obj/item/lazarus_injector,										500,	"Tools"),
		new /datum/data/mining_equipment("Fulton pack",						/obj/item/extraction_pack,										500,	"Tools"),
		new /datum/data/mining_equipment("Auto surgeon",					/obj/item/autosurgeon/vanguard,									750,	"Tools"),
		new /datum/data/mining_equipment("B&R kit",							/obj/item/storage/box/demolition,								1200,	"Tools"),
		new /datum/data/mining_equipment("Vanguard basic kit",				/obj/item/storage/backpack/duffelbag/vanguard/conscript,		1500,	"Tools"),
		new /datum/data/mining_equipment("Vanguard objective pinpointer",	/obj/item/pinpointer/objective,									10000,	"Tools"),

		// ============ РЕКРЕАЦИЯ ============
		new /datum/data/mining_equipment("Whiskey",							/obj/item/reagent_containers/food/drinks/bottle/whiskey,		50,		"Recreation"),
		new /datum/data/mining_equipment("Cigar",							/obj/item/clothing/mask/cigarette/cigar/havana,					75,		"Recreation"),
		new /datum/data/mining_equipment("High quality Soap",				/obj/item/soap/syndie,											150,	"Recreation"),
		new /datum/data/mining_equipment("MRE pack",						/obj/item/storage/box/mre/menu2,								300,	"Recreation"),
		new /datum/data/mining_equipment("MRE-4",							/obj/item/storage/mre,											500,	"Recreation"),
		new /datum/data/mining_equipment("MRE-6 Veg.",						/obj/item/storage/mre/vegan,									500,	"Recreation"),
		new /datum/data/mining_equipment("MRE-47 Meat",						/obj/item/storage/mre/protein,									500,	"Recreation"),

		// ============ ПРОЧЕЕ ============
		new /datum/data/mining_equipment("BEPIS technology disk",			/obj/item/disk/tech_disk/major,									1000,	"Misc"),
		new /datum/data/mining_equipment("space cash",						/obj/item/stack/spacecash/c1000,								1500,	"Misc"),
		new /datum/data/mining_equipment("Strange object",					/obj/item/relic,												2500,	"Misc"),
		new /datum/data/mining_equipment("Vanguard specialization voucher",	/obj/item/vanguard_voucher_class,								7500,	"Misc"),
		new /datum/data/mining_equipment("1 Metadollar",            		/obj/item/stack/metadollar, 									100000, "Misc"),
		new /datum/data/mining_equipment("Illegal technology disk",			/obj/item/disk/tech_disk/illegal,								100000,	"Misc"),

		// ============ ЭЛИТНОЕ СНАРЯЖЕНИЕ =========
		new /datum/data/mining_equipment("ACR-5m26 spare mag (empty)",		/obj/item/ammo_box/magazine/acr5m30/empty,						2500,		"Elite"),
		new /datum/data/mining_equipment("С-02 Permit",						/obj/item/clothing/accessory/permit/special/c_02,				5000,		"Elite"),
		new /datum/data/mining_equipment("Budget tactical first aid",		/obj/item/storage/firstaid/tactical/vanguard,					10000,		"Elite"),
		new /datum/data/mining_equipment("ACR-5m26",						/obj/item/gun/ballistic/automatic/acr5m30/pinvanguard,			20000,		"Elite"),
		new /datum/data/mining_equipment("Department Prototlathe beacon",	/obj/item/choice_beacon/departmental_protholate,				20000,		"Elite"),
		new /datum/data/mining_equipment("Hoshi modular laser",				/obj/item/gun/energy/modular_laser_rifle/carbine/pinvanguard,	25000,		"Elite"),
		new /datum/data/mining_equipment("Civillian Syndicate ID card",		/obj/item/card/id/syndicate/one_access_copy,					25000,		"Elite"),
//		new /datum/data/mining_equipment("ERT MOD Suit",					/obj/item/mod/control/pre_equipped/responsory,					50000,		"Elite"),
		new /datum/data/mining_equipment("Medbeam Gun",						/obj/item/gun/medbeam,											60000,		"Elite"),
		new /datum/data/mining_equipment("Syndicate Baloon",				/obj/item/toy/syndicateballoon,									1000000,	"Elite"),

	)

/obj/machinery/equipment_vendor/vanguard/can_purchase(mob/user, datum/data/mining_equipment/prize)
	if(!..())
		return FALSE
	if(ispath(prize.equipment_path, /obj/item/disk/tech_disk/major) && !length(SSresearch.techweb_nodes_experimental))
		to_chat(user, span_alert("Ошибка: не осталось экспериментальных технологий для записи на [prize.equipment_name]!"))
		return FALSE
	return TRUE

/obj/machinery/equipment_vendor/vanguard/record_purchase(datum/data/mining_equipment/prize)
	return

/obj/machinery/equipment_vendor/vanguard/redeem_voucher(obj/item/voucher, mob/user)
	if(istype(voucher, /obj/item/vanguard_voucher_class))
		RedeemVoucher(voucher, user)
		return TRUE
	if(istype(voucher, /obj/item/vanguard_voucher_suit))
		RedeemSVoucher(voucher, user)
		return TRUE
	return FALSE

/obj/machinery/equipment_vendor/vanguard/RedeemVoucher(obj/item/vanguard_voucher_class/voucher, mob/redeemer)
	var/items = list(
		"Гренадёр" = image(icon = 'modular_bluemoon/icons/obj/guns/energy.dmi', icon_state = "flashgun"),
		"Фельдшер" = image(icon = 'icons/obj/stack_objects.dmi', icon_state = "cms"),
		"Штурмовик" = image(icon = 'modular_bluemoon/icons/obj/guns/projectile.dmi', icon_state = "sauer")
	)
	var/selection = show_radial_menu(redeemer, src, items, require_near = TRUE, tooltips = TRUE)
	if(!selection || !Adjacent(redeemer) || QDELETED(voucher) || voucher.loc != redeemer)
		return
	var/drop_location = drop_location()
	switch(selection)
		if("Гренадёр")
			new /obj/item/storage/secure/briefcase/vanguard/lasgun(drop_location)
			new /obj/item/storage/belt/military/assault/demolition(drop_location)
			new /obj/item/extinguisher/mini(drop_location)
			new /obj/item/storage/box/demolition(drop_location)
			new /obj/item/clothing/glasses/meson(drop_location)
			new /obj/item/clothing/gloves/combat(drop_location)
		if("Фельдшер")
			new /obj/item/stack/medical/fracture_kit/cms(drop_location)
			new /obj/item/storage/firstaid/frontier(drop_location)
			new /obj/item/storage/belt/avangard_belt(drop_location)
			new /obj/item/storage/firstaid/vanguard(drop_location)
			new /obj/item/shield/riot/pointman(drop_location)
			new /obj/item/defibrillator/compact/loaded(drop_location)
			new /obj/item/clothing/glasses/hud/health(drop_location)
			new /obj/item/clothing/gloves/color/latex/nitrile(drop_location)
		if("Штурмовик")
			new /obj/item/storage/secure/briefcase/vanguard/p320(drop_location)
			new /obj/item/storage/belt/military/assault(drop_location)
			new /obj/item/storage/bag/medpen/combatant(drop_location)
			new /obj/item/storage/bag/marksman(drop_location)
			new /obj/item/clothing/glasses/night(drop_location)
			new /obj/item/clothing/gloves/color/black(drop_location)
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	SSblackbox.record_feedback("tally", "vanguard_voucher_redeemed", 1, selection)
	qdel(voucher)

/obj/machinery/equipment_vendor/vanguard/RedeemSVoucher(obj/item/vanguard_voucher_suit/voucher, mob/redeemer)
	var/items = list(
		"EVA" = image(icon = 'modular_bluemoon/Ren/Icons/Obj/cloth.dmi', icon_state = "hardsuit0-explorer"),
		"Комбинезон" = image(icon = 'modular_bluemoon/icons/obj/clothing/suit.dmi', icon_state = "combined")
	)
	var/selection = show_radial_menu(redeemer, src, items, require_near = TRUE, tooltips = TRUE)
	if(!selection || !Adjacent(redeemer) || QDELETED(voucher) || voucher.loc != redeemer)
		return
	var/drop_location = drop_location()
	switch(selection)
		if("EVA")
			new /obj/item/clothing/suit/space/vanguard(drop_location)
			new /obj/item/clothing/head/helmet/space/vanguard(drop_location)
		if("Комбинезон")
			new /obj/item/clothing/suit/armor/vanguard(drop_location)
			new /obj/item/clothing/head/helmet/vanguard(drop_location)
	playsound(src, 'sound/machines/machine_vend.ogg', 50, TRUE, extrarange = -3)
	SSblackbox.record_feedback("tally", "suit_voucher_redeemed", 1, selection)
	qdel(voucher)


// ============================================
// ДОПОЛНИТЕЛЬНЫЕ ПРЕДМЕТЫ (Basic kit)
// ============================================

/obj/item/card/vanguard_access_card
	name = "vanguard access card"
	desc = "Небольшая карта с магнитным покрытием. ID-карты могут перенять от неё доступы оперативников Авангарда."
	icon_state = "data_1"

/obj/item/card/vanguard_access_card/afterattack(atom/movable/AM, mob/user, proximity)
	. = ..()
	if(istype(AM, /obj/item/card/id) && proximity)
		var/obj/item/card/id/I = AM
		I.access |=	ACCESS_RESEARCH
		I.access |= ACCESS_GATEWAY
		I.access |= ACCESS_PRODUCTION_SCIENCE
		to_chat(user, "Вы добавляете доступы Авангарда к данным [I].")
		qdel(src)

/obj/item/storage/backpack/duffelbag/vanguard/conscript
	name = "Vanguard basic kit"
	desc = "Какая-то устаревшая экипировка для новых членов вылетных эскадронов. На этикетке пишется: \"Экспедиторское снаряжение\"."

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



