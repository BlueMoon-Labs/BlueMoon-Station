/datum/supply_pack
	/// id партнёра, который один везёт этот пак, и только со ступени репутации exclusive_tier
	var/partner_exclusive
	var/exclusive_tier = 2

/datum/supply_pack/medical/veymed_surgery
	name = "Хирургический набор Вей-Мед"
	desc = "Улучшенные скальпель, расширитель и дрель, стерильные простыни. Только у Вей-Мед со 2-й ступени репутации."
	cost = 4500
	partner_exclusive = "vey_med"
	contains = list(
		/obj/item/scalpel/advanced,
		/obj/item/retractor/advanced,
		/obj/item/surgicaldrill/advanced,
		/obj/item/surgical_drapes,
	)
	crate_name = "хирургический ящик Вей-Мед"

/datum/supply_pack/medical/veymed_hypospray
	name = "Гипоспреи Вей-Мед"
	desc = "Два гипоспрея MkII для быстрых инъекций. Только у Вей-Мед со 2-й ступени репутации."
	cost = 3000
	partner_exclusive = "vey_med"
	contains = list(
		/obj/item/hypospray/mkii,
		/obj/item/hypospray/mkii,
	)
	crate_name = "ящик гипоспреев Вей-Мед"

/datum/supply_pack/materials/prospectors_drill
	name = "Буровой комплект старателей"
	desc = "Отбойный бур и улучшенный шахтёрский сканер. Только у Гильдии старателей со 2-й ступени репутации."
	cost = 3500
	partner_exclusive = "prospectors"
	contains = list(
		/obj/item/pickaxe/drill/jackhammer,
		/obj/item/t_scanner/adv_mining_scanner,
	)
	crate_name = "буровой ящик старателей"

/datum/supply_pack/materials/prospectors_explorer
	name = "Снаряжение старателя"
	desc = "Костюм исследователя, противогаз, шахтёрский пояс и GPS. Только у Гильдии старателей со 2-й ступени репутации."
	cost = 2500
	partner_exclusive = "prospectors"
	contains = list(
		/obj/item/clothing/suit/hooded/explorer,
		/obj/item/clothing/mask/gas/explorer,
		/obj/item/storage/belt/mining,
		/obj/item/gps/mining,
	)
	crate_name = "ящик снаряжения старателя"

/datum/supply_pack/engineering/nakamura_parts
	name = "Улучшенные детали Накамуры"
	desc = "По две детали третьего поколения каждого вида для апгрейда машин. Только у Накамуры со 2-й ступени репутации."
	cost = 4000
	partner_exclusive = "nakamura"
	contains = list(
		/obj/item/stock_parts/capacitor/super,
		/obj/item/stock_parts/capacitor/super,
		/obj/item/stock_parts/scanning_module/phasic,
		/obj/item/stock_parts/scanning_module/phasic,
		/obj/item/stock_parts/manipulator/pico,
		/obj/item/stock_parts/manipulator/pico,
		/obj/item/stock_parts/micro_laser/ultra,
		/obj/item/stock_parts/micro_laser/ultra,
		/obj/item/stock_parts/matter_bin/super,
		/obj/item/stock_parts/matter_bin/super,
	)
	crate_name = "ящик деталей Накамуры"

/datum/supply_pack/engineering/nakamura_cells
	name = "Батареи Накамуры"
	desc = "Две гиперъёмкие и одна блюспейс-батарея. Только у Накамуры со 2-й ступени репутации."
	cost = 3500
	partner_exclusive = "nakamura"
	contains = list(
		/obj/item/stock_parts/cell/hyper,
		/obj/item/stock_parts/cell/hyper,
		/obj/item/stock_parts/cell/bluespace,
	)
	crate_name = "ящик батарей Накамуры"

/datum/supply_pack/organic/agrarian_seeds
	name = "Редкие семена аграриев"
	desc = "Амброзия гайя, блюспейс-томаты и золотые яблоки. Только у Аграрного союза со 2-й ступени репутации."
	cost = 2500
	partner_exclusive = "agrarian"
	commodity = COMMODITY_SEEDS
	contains = list(
		/obj/item/seeds/ambrosia/gaia,
		/obj/item/seeds/ambrosia/gaia,
		/obj/item/seeds/tomato/blue/bluespace,
		/obj/item/seeds/tomato/blue/bluespace,
		/obj/item/seeds/apple/gold,
		/obj/item/seeds/apple/gold,
	)
	crate_name = "ящик семян аграриев"

/datum/supply_pack/organic/agrarian_feast
	name = "Праздничный стол аграриев"
	desc = "Пиццы, салаты и бутылка шампанского к празднику. Только у Аграрного союза со 2-й ступени репутации."
	cost = 1800
	partner_exclusive = "agrarian"
	contains = list(
		/obj/item/reagent_containers/food/snacks/pizza/margherita,
		/obj/item/reagent_containers/food/snacks/pizza/margherita,
		/obj/item/reagent_containers/food/snacks/salad/validsalad,
		/obj/item/reagent_containers/food/snacks/salad/validsalad,
		/obj/item/reagent_containers/food/drinks/bottle/champagne,
	)
	crate_name = "праздничный ящик аграриев"

/datum/supply_pack/service/sol_luxury
	name = "Роскошь Солнечной Федерации"
	desc = "Гаванские сигары и шампанское для особых гостей. Только у Солнечной Федерации со 2-й ступени репутации."
	cost = 2500
	partner_exclusive = "sol_federation"
	contains = list(
		/obj/item/storage/fancy/cigarettes/cigars/havana,
		/obj/item/storage/fancy/cigarettes/cigars/havana,
		/obj/item/reagent_containers/food/drinks/bottle/champagne,
		/obj/item/reagent_containers/food/drinks/bottle/champagne,
	)
	crate_name = "ящик Солнечной Федерации"

/datum/supply_pack/service/sol_instruments
	name = "Инструменты Солнечной Федерации"
	desc = "Скрипка, аккордеон и труба для бара и сцены. Только у Солнечной Федерации со 2-й ступени репутации."
	cost = 2000
	partner_exclusive = "sol_federation"
	contains = list(
		/obj/item/instrument/violin,
		/obj/item/instrument/accordion,
		/obj/item/instrument/trumpet,
	)
	crate_name = "ящик инструментов Солнечной Федерации"

/// Эксклюзивный пак везёт только свой партнёр и только со ступени exclusive_tier; обычный - любой.
/proc/econ_exclusive_ok(datum/trade_partner/partner, datum/supply_pack/pack)
	if(!pack.partner_exclusive)
		return TRUE
	return partner?.id == pack.partner_exclusive && partner.tier() >= pack.exclusive_tier

/// Партнёр сейчас может везти пак: открыт, не под эмбарго, продаёт группу, пак на складе; контрабандный - только с допуском.
/proc/econ_partner_supplies(datum/trade_partner/partner, datum/supply_pack/pack, allow_contraband = FALSE)
	if(!partner || !pack || !partner.unlocked || partner.embargoed() || (partner.contraband && !allow_contraband) || !econ_pack_traded(pack))
		return FALSE
	return econ_exclusive_ok(partner, pack) && partner.sells_group(pack.group) && partner.in_stock(pack)

/// Поставщик заказа: выбранный при заказе партнёр, если он ещё может везти, иначе самый дешёвый.
/proc/econ_order_supplier(datum/supply_order/order)
	if(istype(order.pack, /datum/supply_pack/bundle))
		var/datum/supply_pack/bundle/bundle = order.pack
		return SSmarket.get_partner(bundle.seller_id)
	var/datum/trade_partner/chosen = order.partner_id ? SSmarket.get_partner(order.partner_id) : null
	if(econ_partner_supplies(chosen, order.pack, order.contraband_supply))
		return chosen
	return econ_pack_supplier(order.pack, order.paying_account, order.contraband_supply)

/// Цена заказа у его поставщика.
/proc/econ_order_cost(datum/supply_order/order)
	var/datum/trade_partner/supplier = econ_order_supplier(order)
	return supplier ? supplier.pack_price(order.pack, order.paying_account) : order.pack.get_cost(order.paying_account, order.contraband_supply)

/// Партнёр из окна для нового заказа: только тот, кто сейчас может его везти; иначе null - поставщика выберет цена.
/proc/econ_requested_partner(list/params, datum/supply_pack/pack, allow_contraband)
	var/id = params["partner"]
	if(!istext(id))
		return null
	var/datum/trade_partner/partner = SSmarket.get_partner(id)
	return econ_partner_supplies(partner, pack, allow_contraband) ? partner : null
