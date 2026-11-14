/// Таможня, Вольные торговцы и чёрный рынок на изолированной копии рынка; настройки таможни, бюджет и долг снабжения возвращаются.
/datum/unit_test/economy_contraband
	abstract_type = /datum/unit_test/economy_contraband
	var/list/saved_market
	var/list/stashed_contracts
	var/list/saved_settings = list()
	var/saved_centcom_message
	var/saved_export_categories
	var/datum/economy_department/cargo
	var/saved_cargo_balance
	var/saved_cargo_owed
	var/datum/economy_department/medical
	var/saved_medical_balance
	var/saved_medical_owed
	var/list/saved_exported_by

/datum/unit_test/economy_contraband/New()
	..()
	saved_market = econ_test_swap_market()
	SSmarket.next_shift = world.time + 1 HOURS
	SSmarket.next_restock = world.time + 1 HOURS
	SSmarket.next_offers = world.time + 1 HOURS
	stashed_contracts = econ_test_stash_contracts()
	for(var/key in list("customs_chance", "customs_chance_inspection", "customs_chance_alert", "customs_fine_share"))
		saved_settings[key] = SSeconomy.settings.vars[key]
	SSeconomy.settings.customs_chance_inspection = 0
	SSeconomy.settings.customs_chance_alert = 0
	saved_centcom_message = SSshuttle.centcom_message
	saved_export_categories = SSshuttle.supply.export_categories
	cargo = SSeconomy.get_department(ACCOUNT_CAR)
	saved_cargo_balance = cargo.account.account_balance
	saved_cargo_owed = cargo.owed
	medical = SSeconomy.get_department(ACCOUNT_MED)
	saved_medical_balance = medical.account.account_balance
	saved_medical_owed = medical.owed
	saved_exported_by = SSmarket.contraband_exported_by.Copy()
	econ_test_set_balance(cargo.account, 100000)

/datum/unit_test/economy_contraband/Destroy()
	for(var/key in saved_settings)
		SSeconomy.settings.vars[key] = saved_settings[key]
	SSshuttle.centcom_message = saved_centcom_message
	SSshuttle.supply.export_categories = saved_export_categories
	econ_test_restore_contracts(stashed_contracts)
	econ_test_set_balance(cargo.account, saved_cargo_balance)
	cargo.owed = saved_cargo_owed
	cargo = null
	econ_test_set_balance(medical.account, saved_medical_balance)
	medical.owed = saved_medical_owed
	medical = null
	SSmarket.contraband_exported_by = saved_exported_by
	econ_test_restore_market(saved_market)
	return ..()

/datum/unit_test/economy_contraband/proc/shuttle_crate()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/turf/open/floor in shuttle_area)
			if(!floor.is_blocked_turf())
				return allocate(/obj/structure/closet/crate, floor)
	TEST_FAIL("Нет пола шаттла снабжения")

/// Цена ящика со стопками металла так, как его продаст шаттл сейчас; crate_type = FALSE - сумма цен стопок без ящика.
/datum/unit_test/economy_contraband/proc/metal_crate_value(list/stacks, crate_type = /obj/structure/closet/crate)
	var/atom/movable/holder = crate_type ? allocate(crate_type) : null
	var/list/sold = list()
	for(var/amount in stacks)
		sold += new /obj/item/stack/sheet/metal(holder || run_loc_floor_bottom_left, amount)
	if(holder)
		sold = list(holder)
	. = 0
	for(var/atom/movable/thing as anything in sold)
		. += econ_export_report_value(export_item_and_contents(thing, SSshuttle.supply.export_categories, delete_unsold = FALSE, dry_run = TRUE))
		qdel(thing)

/datum/unit_test/economy_contraband/proc/set_commodity(datum/commodity/commodity, trend)
	commodity.trend = trend
	commodity.noise = 0
	commodity.recompute()

/// Таможня изымает контрабанду из отгрузки шаттлом, честный груз из контрабандного ящика продаётся, снабжение платит штраф и видит его в сообщении ЦК; ящик без контрабанды не штрафуется.
/datum/unit_test/economy_contraband/customs/Run()
	econ_test_contraband_ready()
	SSeconomy.settings.customs_chance = 100
	SSshuttle.supply.export_categories = EXPORT_CARGO | EXPORT_CONTRABAND
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	var/honest_value = metal_crate_value(list(10, 10))
	TEST_ASSERT(honest_value > 0, "Металл продаётся")
	var/obj/structure/closet/crate/crate = shuttle_crate()
	var/obj/item/card/id/syndicate/agent_card = new(crate)
	var/obj/item/storage/toolbox/syndicate/toolbox = new(crate)
	for(var/obj/item/preloaded in toolbox.contents)
		qdel(preloaded)
	new /obj/item/stack/sheet/metal(crate, 10)
	new /obj/item/stack/sheet/metal(toolbox, 10)
	var/seized_value = econ_contraband_value(agent_card) + econ_contraband_value(toolbox)
	TEST_ASSERT(seized_value > 0, "Контрабанда оценена")
	var/fine = round(seized_value * SSeconomy.settings.customs_fine_share / 100)
	var/trend_before = contraband.trend
	var/balance_before = cargo.account.account_balance
	var/owed_before = cargo.owed
	SSshuttle.supply.sell()
	var/delta = cargo.account.account_balance - balance_before
	TEST_ASSERT(QDELETED(agent_card) && QDELETED(toolbox), "Контрабанда не изъята")
	TEST_ASSERT_EQUAL(delta, honest_value - fine, "Снабжение получило не выручку за честный груз за вычетом штрафа")
	TEST_ASSERT_EQUAL(cargo.owed, owed_before, "Штраф ушёл в долг при полном бюджете")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "Таможня NT изъяла контрабанду: 2 шт. на [seized_value] кр., штраф: [cargo.name] - [fine] кр."), "Сообщение ЦК о таможне")
	TEST_ASSERT(contraband.trend > trend_before, "Изъятие таможней не подняло тренд контрабанды")

	honest_value = metal_crate_value(list(20))
	var/obj/structure/closet/crate/honest_crate = shuttle_crate()
	new /obj/item/stack/sheet/metal(honest_crate, 20)
	balance_before = cargo.account.account_balance
	SSshuttle.supply.sell()
	delta = cargo.account.account_balance - balance_before
	TEST_ASSERT_EQUAL(delta, honest_value, "Честный ящик принёс не свою цену")
	TEST_ASSERT_EQUAL(cargo.owed, owed_before, "Честный ящик оштрафован")
	TEST_ASSERT(!findtext(SSshuttle.centcom_message, "Таможня"), "Таможня в сообщении о честном грузе")

/// Контрабандный контейнер без ящика изымается, а его честное содержимое продаётся в той же отгрузке.
/datum/unit_test/economy_contraband/customs_loose_container/Run()
	econ_test_contraband_ready()
	SSeconomy.settings.customs_chance = 100
	SSshuttle.supply.export_categories = EXPORT_CARGO
	var/metal_value = metal_crate_value(list(10), FALSE)
	TEST_ASSERT(metal_value > 0, "Металл продаётся")
	var/obj/structure/closet/crate/marker = shuttle_crate()
	var/obj/item/storage/toolbox/syndicate/toolbox = new(marker.loc)
	qdel(marker)
	for(var/obj/item/preloaded in toolbox.contents)
		qdel(preloaded)
	var/obj/item/stack/sheet/metal/metal = new(toolbox, 10)
	var/fine = round(econ_contraband_value(toolbox) * SSeconomy.settings.customs_fine_share / 100)
	var/balance_before = cargo.account.account_balance
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(toolbox), "Ящик Синдиката не изъят")
	TEST_ASSERT(QDELETED(metal), "Высыпанный металл не продан и уедет обратно")
	TEST_ASSERT_EQUAL(cargo.account.account_balance - balance_before, metal_value - fine, "Снабжение получило не цену металла за вычетом штрафа")

/// Штраф таможни платит отдел, чья накладная лежит в ящике; нехватка уходит в долг этого отдела, сообщение ЦК его называет.
/datum/unit_test/economy_contraband/customs_manifest_payer/Run()
	econ_test_contraband_ready()
	SSeconomy.settings.customs_chance = 100
	SSshuttle.supply.export_categories = EXPORT_CARGO
	var/obj/structure/closet/crate/reference = allocate(/obj/structure/closet/crate)
	medical.print_manifest(reference)
	var/crate_value = econ_export_report_value(export_item_and_contents(reference, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE))
	qdel(reference)
	var/share = crate_value - round(crate_value * SSeconomy.settings.cargo_handling_fee / 100)
	var/obj/structure/closet/crate/crate = shuttle_crate()
	medical.print_manifest(crate)
	var/obj/item/card/id/syndicate/agent_card = new(crate)
	var/had_market_price = (/obj/item/card/id/syndicate in GLOB.econ_contraband_market_price)
	var/saved_market_price = GLOB.econ_contraband_market_price[/obj/item/card/id/syndicate]
	GLOB.econ_contraband_market_price[/obj/item/card/id/syndicate] = 100
	var/fine = round(econ_contraband_value(agent_card) * SSeconomy.settings.customs_fine_share / 100)
	econ_test_set_balance(medical.account, 0)
	var/medical_owed = medical.owed
	var/cargo_owed = cargo.owed
	var/saved_work_price = SSeconomy.settings.work_prices[WORK_SEC_CONTRABAND]
	SSeconomy.settings.work_prices[WORK_SEC_CONTRABAND] = 2
	SSshuttle.supply.sell()
	SSeconomy.settings.work_prices[WORK_SEC_CONTRABAND] = saved_work_price
	if(had_market_price)
		GLOB.econ_contraband_market_price[/obj/item/card/id/syndicate] = saved_market_price
	else
		GLOB.econ_contraband_market_price -= /obj/item/card/id/syndicate
	TEST_ASSERT(fine > 0, "Штраф за карту есть")
	TEST_ASSERT(QDELETED(agent_card), "Карта не изъята")
	TEST_ASSERT_EQUAL(medical.owed - medical_owed, fine, "Штраф не ушёл в долг отдела накладной")
	TEST_ASSERT_EQUAL(medical.account.account_balance, share, "Отдел накладной получил не свою долю за ящик")
	TEST_ASSERT_EQUAL(cargo.owed, cargo_owed, "Штраф выставлен снабжению")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "штраф: [medical.name] - [fine] кр."), "Сообщение ЦК не называет отдел")

/// Шанс досмотра - из настроек, выше при красном коде и во время инспекции Sol на станции; без контрабанды досмотр ничего не изымает.
/datum/unit_test/economy_contraband/customs_chance/Run()
	econ_test_contraband_ready()
	var/datum/economy_settings/settings = SSeconomy.settings
	settings.customs_chance = 15
	settings.customs_chance_alert = 10
	settings.customs_chance_inspection = 20
	var/saved_level = GLOB.security_level
	GLOB.security_level = SEC_LEVEL_GREEN
	var/green_chance = econ_customs_chance()
	GLOB.security_level = SEC_LEVEL_RED
	var/red_chance = econ_customs_chance()
	GLOB.security_level = saved_level
	var/datum/team/sol_inspection/inspection = new
	QDEL_NULL(inspection.account)
	var/en_route_chance = econ_customs_chance()
	inspection.visited_station = TRUE
	var/inspecting_chance = econ_customs_chance()
	inspection.returned_home = TRUE
	var/returned_chance = econ_customs_chance()
	qdel(inspection)
	TEST_ASSERT_EQUAL(green_chance, 15, "Шанс без тревоги")
	TEST_ASSERT_EQUAL(red_chance, 25, "Шанс при красном коде")
	TEST_ASSERT_EQUAL(en_route_chance, 15, "Надбавка до прибытия инспекции")
	TEST_ASSERT_EQUAL(inspecting_chance, 35, "Шанс во время инспекции")
	TEST_ASSERT_EQUAL(returned_chance, 15, "Надбавка после отлёта инспекции")
	settings.customs_chance = 0
	var/obj/structure/closet/crate/crate = allocate(/obj/structure/closet/crate)
	var/obj/item/card/id/syndicate/agent_card = new(crate)
	TEST_ASSERT_EQUAL(econ_customs_scan(crate), 0, "При шансе 0 изъято")
	TEST_ASSERT(!QDELETED(agent_card), "При шансе 0 карта удалена")

/// Емаг консоли снабжения тихо открывает Вольных торговцев, не ломая её контрабандные паки; контрабанду они покупают только с допуском контрабанды, иначе она возвращается; продажа записывается на последнего касавшегося.
/datum/unit_test/economy_contraband/free_traders/Run()
	econ_test_contraband_ready()
	SSeconomy.settings.customs_chance = 0
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	TEST_ASSERT(traders && !traders.unlocked, "Вольные торговцы закрыты на свежем рынке")
	SSshuttle.supply.export_categories = EXPORT_CARGO | EXPORT_CONTRABAND
	var/obj/item/card/id/syndicate/locked_card = new(shuttle_crate())
	SSshuttle.supply.sell()
	TEST_ASSERT(!QDELETED(locked_card) && isturf(locked_card.loc), "Контрабанда без открытых торговцев не вернулась")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "Не нашлось покупателя: 1 шт. возвращено."), "Сообщение ЦК о возврате")

	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/obj/machinery/computer/cargo/request/request_console = allocate(/obj/machinery/computer/cargo/request)
	var/datum/news/feed_channel/channel = SSmarket.news_channel()
	var/messages_before = length(channel.messages)
	var/pending_before = length(SSmarket.pending_news)
	var/mob/living/carbon/human/hacker = allocate(/mob/living/carbon/human)
	var/obj/item/card/emag/emag = allocate(/obj/item/card/emag)
	hacker.put_in_active_hand(emag)
	emag.melee_attack_chain(hacker, request_console)
	TEST_ASSERT(request_console.obj_flags & EMAGGED, "Консоль запросов не взломана")
	TEST_ASSERT(!traders.unlocked, "Консоль запросов открыла Вольных торговцев")
	emag.melee_attack_chain(hacker, console)
	TEST_ASSERT(traders.unlocked, "Емаг не открыл Вольных торговцев")
	TEST_ASSERT((console.obj_flags & EMAGGED) && console.contraband, "Емаг больше не открывает контрабандные паки")
	var/obj/item/circuitboard/computer/cargo/board = console.circuit
	TEST_ASSERT(board.contraband && (board.obj_flags & EMAGGED), "Плата не запомнила взлом")
	TEST_ASSERT_EQUAL(length(channel.messages), messages_before, "Открытие Вольных торговцев попало в новости")
	TEST_ASSERT_EQUAL(length(SSmarket.pending_news), pending_before, "Открытие Вольных торговцев ждёт в очереди новостей")

	SSshuttle.supply.export_categories = EXPORT_CARGO
	locked_card.forceMove(shuttle_crate())
	SSshuttle.supply.sell()
	TEST_ASSERT(!QDELETED(locked_card) && isturf(locked_card.loc), "Контрабанда продана с шаттла без допуска контрабанды")
	qdel(locked_card)

	SSshuttle.supply.export_categories = console.get_export_categories()
	var/obj/structure/closet/crate/crate = shuttle_crate()
	var/obj/item/card/id/syndicate/agent_card = new(crate)
	agent_card.fingerprintslast = "econtestsmuggler"
	var/expected = econ_export_report_value(export_item_and_contents(agent_card, SSshuttle.supply.export_categories, delete_unsold = FALSE, dry_run = TRUE))
	TEST_ASSERT(expected > 0, "Вольные торговцы не оценили карту")
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(agent_card), "Карта не продана")
	TEST_ASSERT_EQUAL(SSmarket.contraband_exported_by["econtestsmuggler"], expected, "Продажа контрабанды не записана на касавшегося")
	TEST_ASSERT(findtext(econ_cargo_message("", TRUE), "[traders.name] - [expected] кр."), "Взломанная консоль не видит сделку с Вольными торговцами")
	var/public_message = econ_cargo_message("", FALSE)
	TEST_ASSERT(!findtext(public_message, traders.name) && !findtext(public_message, "free traders"), "Сделка с Вольными торговцами в общем сообщении ЦК: [public_message]")

/datum/unit_test/economy_contraband/blackmarket_purchase
	var/saved_cash_balance
	var/saved_minted
	var/saved_burned
	var/list/saved_by_reason

/datum/unit_test/economy_contraband/blackmarket_purchase/New()
	..()
	saved_cash_balance = SSeconomy.cash_account.account_balance
	saved_minted = SSeconomy.ledger.minted
	saved_burned = SSeconomy.ledger.burned
	saved_by_reason = SSeconomy.ledger.by_reason.Copy()

/datum/unit_test/economy_contraband/blackmarket_purchase/Destroy()
	econ_test_set_balance(SSeconomy.cash_account, saved_cash_balance)
	SSeconomy.ledger.minted = saved_minted
	SSeconomy.ledger.burned = saved_burned
	SSeconomy.ledger.by_reason = saved_by_reason
	return ..()

/// Наличные в аплинке сжигаются, цена лота идёт за рынком контрабанды, а купленное на дне рынка помечено, и его выкуп на пике не окупает покупку.
/datum/unit_test/economy_contraband/blackmarket_purchase/Run()
	econ_test_contraband_ready()
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	set_commodity(contraband, MARKET_PRICE_MIN)
	var/datum/blackmarket_market/market = SSblackmarket.markets[/datum/blackmarket_market/blackmarket]
	var/test_category = "econ test wares"
	var/datum/blackmarket_item/listing = new
	listing.name = "econ test emag"
	listing.category = test_category
	listing.item = /obj/item/card/emag
	listing.price = 1000
	listing.stock = 1
	market.available_items[test_category] = list(listing)
	var/obj/item/blackmarket_uplink/uplink = allocate(/obj/item/blackmarket_uplink)
	uplink.viewing_market = /datum/blackmarket_market/blackmarket
	uplink.viewing_category = test_category
	var/obj/machinery/ltsrbt/pad = allocate(/obj/machinery/ltsrbt)
	var/mob/living/carbon/human/buyer = allocate(/mob/living/carbon/human)
	var/obj/item/holochip/chip = new(buyer.loc, 2000)
	buyer.put_in_active_hand(chip)
	var/cash_before = SSeconomy.cash_account.account_balance
	var/burned_before = SSeconomy.ledger.burned
	chip.melee_attack_chain(buyer, uplink)
	TEST_ASSERT(QDELETED(chip) && uplink.money == 2000, "Голочип не вставлен: [uplink.money]")
	TEST_ASSERT_EQUAL(SSeconomy.cash_account.account_balance, cash_before - 2000, "Наличные не ушли из оборота")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, 2000, "Наличные в аплинке не сожжены")

	var/list/data = uplink.ui_data(buyer)
	var/shown_cost
	for(var/list/entry as anything in data["items"])
		if(entry["name"] == listing.name)
			shown_cost = entry["cost"]
	TEST_ASSERT_EQUAL(shown_cost, round(1000 * MARKET_PRICE_MIN), "Аплинк показывает цену не по рынку")
	var/datum/tgui/window = allocate(/datum/tgui, buyer, uplink, "BlackMarketUplink")
	window.status = UI_INTERACTIVE
	usr = buyer
	uplink.ui_act("select", list("item" = "[listing.type]"), window)
	uplink.ui_act("buy", list("method" = SHIPPING_METHOD_LTSRBT), window)
	usr = null
	var/paid = shown_cost + market.shipping[SHIPPING_METHOD_LTSRBT]
	TEST_ASSERT_EQUAL(uplink.money, 2000 - paid, "Списано не по цене рынка")

	SSblackmarket.fire()
	pad.set_machine_stat(pad.machine_stat & ~NOPOWER)
	pad.recharge_cooldown = 0
	pad.process()
	pad.process()
	var/datum/blackmarket_purchase/purchase = pad.transmitting
	var/obj/item/card/emag/bought = purchase?.item
	pad.transmitting = null
	qdel(purchase)
	market.available_items -= test_category
	qdel(listing)
	TEST_ASSERT(istype(bought), "Телепад не выдал покупку")
	allocated += bought
	TEST_ASSERT(bought.econ_imported, "Покупка не помечена купленной")

	econ_test_partner_extremes()
	set_commodity(contraband, MARKET_PRICE_MAX)
	contraband.hot_mult = MARKET_HOT_MULT_MAX
	contraband.demand = 1
	var/export_value = econ_export_report_value(export_item_and_contents(bought, EXPORT_CARGO | EXPORT_CONTRABAND | EXPORT_EMAG, delete_unsold = FALSE, dry_run = TRUE))
	TEST_ASSERT(export_value > 0 && export_value <= paid, "Выкуп на пике [export_value] при покупке за [paid]")
	var/seizure_total = econ_contraband_value(bought) * (100 + SSeconomy.settings.work_personal_share) / 100
	TEST_ASSERT(seizure_total <= paid, "Изъятие с премией [seizure_total] при покупке за [paid]")

/// Ни один лот чёрного рынка, купленный на дне рынка контрабанды, не окупается выкупом NT или Вольных торговцев на пике рынка при всех открытых партнёрах, ни сдачей в хранилище улик.
/datum/unit_test/economy_contraband/blackmarket_scan/Run()
	econ_test_contraband_ready()
	var/datum/commodity/contraband = SSmarket.get_commodity(COMMODITY_CONTRABAND)
	set_commodity(contraband, MARKET_PRICE_MIN)
	var/datum/blackmarket_market/market = SSblackmarket.markets[/datum/blackmarket_market/blackmarket]
	var/cheapest_shipping
	for(var/method in market.shipping)
		cheapest_shipping = isnull(cheapest_shipping) ? market.shipping[method] : min(cheapest_shipping, market.shipping[method])
	var/list/purchases = list()
	for(var/datum/blackmarket_item/listing_type as anything in subtypesof(/datum/blackmarket_item))
		if(!ispath(initial(listing_type.item), /atom/movable))
			continue
		var/datum/blackmarket_item/listing = new listing_type
		var/datum/blackmarket_purchase/purchase = new(listing, null, SHIPPING_METHOD_LAUNCH)
		purchase.paid = econ_blackmarket_price(listing.price) + cheapest_shipping
		purchases += purchase
	econ_test_partner_extremes()
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		set_commodity(commodity, MARKET_PRICE_MAX)
		commodity.hot_mult = MARKET_HOT_MULT_MAX
		commodity.demand = 1
	var/share = SSeconomy.settings.work_personal_share
	var/list/offenders = list()
	var/contraband_lots = 0
	for(var/datum/blackmarket_purchase/purchase as anything in purchases)
		var/atom/movable/product = purchase.deliver(run_loc_floor_bottom_left)
		var/value = econ_export_report_value(export_item_and_contents(product, EXPORT_CARGO | EXPORT_CONTRABAND | EXPORT_EMAG, delete_unsold = FALSE, dry_run = TRUE))
		if(value > purchase.paid)
			offenders += "[purchase.entry.type]: выкуп [value] при цене [purchase.paid]"
		var/seized = 0
		for(var/obj/item/thing in product.GetAllContents())
			seized += econ_contraband_value(thing)
		if(seized)
			contraband_lots++
		if(seized * (100 + share) / 100 > purchase.paid)
			offenders += "[purchase.entry.type]: изъятие [seized] при цене [purchase.paid]"
		var/datum/blackmarket_item/listing = purchase.entry
		qdel(purchase)
		qdel(listing)
		econ_test_clear_turf(run_loc_floor_bottom_left)
	TEST_ASSERT(contraband_lots, "Среди лотов чёрного рынка нет контрабанды")
	TEST_ASSERT(!length(offenders), "Покупка на чёрном рынке окупается: [jointext(offenders, "; ")]")

/// Контрабанда с реагентами на шаттле без допуска возвращается вместе с реагентами: шаттл и сканер не оценивают её реагенты.
/datum/unit_test/economy_contraband/reagents_returned/Run()
	econ_test_contraband_ready()
	SSeconomy.settings.customs_chance = 0
	SSshuttle.supply.export_categories = EXPORT_CARGO
	var/obj/structure/closet/crate/crate = shuttle_crate()
	var/obj/item/reagent_containers/spray/chemsprayer/bioterror/sprayer = new(crate)
	allocated += sprayer
	TEST_ASSERT(econ_is_contraband(sprayer), "Химраспылитель Синдиката не контрабанда")
	var/valued_reagents = FALSE
	for(var/datum/reagent/reagent as anything in sprayer.reagents.reagent_list)
		if(reagent.value)
			valued_reagents = TRUE
	TEST_ASSERT(valued_reagents && sprayer.reagents.value_multiplier, "В распылителе нет реагентов с ценой")
	var/datum/export_report/preview = export_item_and_contents(sprayer, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE)
	TEST_ASSERT(!length(preview.reagents_value), "Сканер оценил реагенты контрабанды")
	var/volume = sprayer.reagents.total_volume
	var/obj/structure/closet/crate/empty = allocate(/obj/structure/closet/crate)
	var/crate_value = econ_export_report_value(export_item_and_contents(empty, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE))
	var/before = cargo.account.account_balance
	SSshuttle.supply.sell()
	TEST_ASSERT(!QDELETED(sprayer) && isturf(sprayer.loc), "Контрабанда не вернулась шаттлом")
	TEST_ASSERT(abs(sprayer.reagents.total_volume - volume) < 0.1, "Реагенты контрабанды ушли с шаттла")
	TEST_ASSERT_EQUAL(cargo.account.account_balance - before, crate_value, "Снабжение получило за реагенты контрабанды")

/// Открытые Вольные торговцы покупают груз, в том числе ходовой товар контрабанды, только с шаттла с допуском контрабанды; спецзаказ контрабандного партнёра проваливается мимо общего сообщения ЦК.
/datum/unit_test/economy_contraband/free_traders_need_permit/Run()
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	TEST_ASSERT(SSmarket.open_contraband_partners(), "Вольные торговцы не открылись")
	var/obj/item/reagent_containers/crack/crack = allocate(/obj/item/reagent_containers/crack)
	TEST_ASSERT(!econ_is_contraband(crack), "Крэк считается контрабандой Синдиката")
	var/plain = econ_export_report_value(export_item_and_contents(crack, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE))
	var/permitted = econ_export_report_value(export_item_and_contents(crack, EXPORT_CARGO | EXPORT_CONTRABAND, delete_unsold = FALSE, dry_run = TRUE))
	TEST_ASSERT(plain > 0, "Крэк не продаётся NT")
	TEST_ASSERT(plain < permitted, "Вольные торговцы платят за крэк без допуска контрабанды: [plain] против [permitted]")
	TEST_ASSERT(SSmarket.best_buyer(COMMODITY_CONTRABAND) != traders, "Вольные торговцы - покупатель без допуска")

	var/datum/market_offer/offer = new("free_traders", /obj/item/reagent_containers/crack, "крэк", 3, 2, 100)
	traders.offers += offer
	offer.accept()
	SSshuttle.centcom_message = ""
	SSmarket.contraband_message = ""
	offer.fail()
	TEST_ASSERT(!findtext(econ_cargo_message("", FALSE), traders.name), "Провал спецзаказа Вольных торговцев в общем сообщении ЦК")
	TEST_ASSERT(findtext(econ_cargo_message("", TRUE), traders.name), "Взломанная консоль не видит провал спецзаказа Вольных торговцев")

/// Консоль с широким приёмником платы, без взлома, отгружает с допуском контрабанды: её справка, сканер и сообщение ЦК говорят о Вольных торговцах, которые покупают её груз.
/datum/unit_test/economy_contraband/permit_console/Run()
	econ_test_contraband_ready()
	SSeconomy.settings.customs_chance = 0
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	var/mob/living/carbon/human/technician = allocate(/mob/living/carbon/human)
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/obj/item/circuitboard/computer/cargo/board = console.circuit
	board.multitool_act(technician, allocate(/obj/item/multitool))
	console.on_construction()
	TEST_ASSERT(console.contraband && !(console.obj_flags & EMAGGED), "Плата не перевела консоль на широкий приёмник")
	TEST_ASSERT(SSmarket.open_contraband_partners(), "Вольные торговцы не открылись")
	TEST_ASSERT(findtext(console.ui_static_data(technician)["market_help"], "Вольные торговцы"), "Справка консоли с допуском контрабанды не называет Вольных торговцев")
	var/obj/item/export_scanner/scanner = allocate(/obj/item/export_scanner)
	scanner.afterattack(console, technician, TRUE)
	TEST_ASSERT(scanner.cargo_console == console, "Сканер не привязан к консоли")
	TEST_ASSERT(findtext(scanner.contraband_warning(), "купят Вольные торговцы"), "Сканер обещает вернуть контрабанду, которую купят: [scanner.contraband_warning()]")
	SSshuttle.supply.export_categories = console.get_export_categories()
	var/obj/item/card/id/syndicate/agent_card = new(shuttle_crate())
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(agent_card), "Карта не продана с шаттла с допуском")
	var/message = console.ui_data(technician)["message"]
	TEST_ASSERT(findtext(message, traders.name), "Консоль с допуском контрабанды не видит свою сделку с Вольными торговцами: [message]")
