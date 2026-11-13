/// Окна снабжения на свежем рынке из конфига; рынок, корзина и заявки снабжения возвращаются.
/datum/unit_test/economy_ui_cargo
	abstract_type = /datum/unit_test/economy_ui_cargo
	var/list/saved_market
	var/list/saved_shoppinglist
	var/list/saved_requestlist
	var/saved_shuttle_loan

/// Аренда шаттла без события: только отмечает, что её приняли.
/datum/econ_test_shuttle_loan
	var/dispatched = FALSE
	var/loaned = FALSE

/datum/econ_test_shuttle_loan/proc/loan_shuttle()
	loaned = TRUE

/datum/unit_test/economy_ui_cargo/New()
	. = ..()
	saved_market = econ_test_swap_market()
	SSmarket.next_shift = world.time + 1 HOURS
	SSmarket.next_restock = world.time + 1 HOURS
	SSmarket.next_offers = world.time + 1 HOURS
	saved_shoppinglist = SSshuttle.shoppinglist.Copy()
	SSshuttle.shoppinglist.Cut()
	saved_requestlist = SSshuttle.requestlist.Copy()
	SSshuttle.requestlist.Cut()
	saved_shuttle_loan = SSshuttle.shuttle_loan
	GLOB.econ_cargo_prices.refresh(TRUE)

/datum/unit_test/economy_ui_cargo/Destroy()
	SSshuttle.shuttle_loan = saved_shuttle_loan
	QDEL_LIST(SSshuttle.shoppinglist)
	SSshuttle.shoppinglist += saved_shoppinglist
	QDEL_LIST(SSshuttle.requestlist)
	SSshuttle.requestlist += saved_requestlist
	econ_test_restore_market(saved_market)
	GLOB.econ_cargo_prices.refresh(TRUE)
	return ..()

/datum/unit_test/economy_ui_cargo/proc/make_staff(department_id, list/access, turf/where)
	var/mob/living/carbon/human/staff = allocate(/mob/living/carbon/human, where || run_loc_floor_bottom_left)
	var/datum/bank_account/account = new("econ_test_cargo_[department_id]")
	account.department_id = department_id
	staff.account_id = account.account_id
	allocated += account
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = access || list()
	staff.put_in_hands(card)
	return staff

/datum/unit_test/economy_ui_cargo/proc/press(mob/living/user, datum/host, action, list/params = list())
	var/datum/tgui/window = allocate(/datum/tgui, user, host, "Cargo")
	window.status = UI_INTERACTIVE
	usr = user
	. = host.ui_act(action, params, window)
	usr = null

/datum/unit_test/economy_ui_cargo/proc/find_entry(list/entries, key, value)
	for(var/list/entry as anything in entries)
		if(entry[key] == value)
			return entry

/datum/unit_test/economy_ui_cargo/proc/catalog_entry(list/supplies, datum/supply_pack/pack)
	var/list/group = supplies[pack.group]
	return group ? find_entry(group["packs"], "id", pack.type) : null

/// Данные окна, как их видит клиент: статика, поверх неё обновление.
/datum/unit_test/economy_ui_cargo/proc/client_view(datum/host, mob/user)
	. = host.ui_static_data(user)
	var/list/data = host.ui_data(user)
	for(var/key in data)
		.[key] = data[key]

/// Строка каталога окна с ценой из таблицы цен: cost, supplier, in_stock, commodity.
/datum/unit_test/economy_ui_cargo/proc/priced_entry(datum/host, mob/user, datum/supply_pack/pack)
	var/list/view = client_view(host, user)
	var/list/entry = catalog_entry(view["supplies"], pack)
	var/list/price = view["prices"][pack.type]
	if(!entry || !price)
		return null
	var/datum/trade_partner/supplier = SSmarket.get_partner(price[2])
	return list("cost" = price[1], "supplier" = supplier?.name, "in_stock" = price[3], "commodity" = entry["commodity"])

/datum/unit_test/economy_ui_cargo/proc/supply_app(mob/living/carbon/human/owner, pda_type)
	var/obj/item/modular_computer/pda/pda = allocate(pda_type)
	owner.put_in_hands(pda)
	return locate(/datum/computer_file/program/cargo_orders) in pda.get_all_files()

/// Станционная консоль снабжения показывает спецзаказ, берёт его и печатает к нему накладную.
/datum/unit_test/economy_ui_cargo/console_offer/Run()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo, station_turf)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO), station_turf)
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/market_offer/offer = new("prospectors", /obj/item/stack/sheet/mineral/gold, "слитки золота", 10, 2, 60)
	prospectors.offers += offer
	var/list/data = console.ui_data(technician)
	TEST_ASSERT(data["can_take_offers"], "Станционная консоль берёт спецзаказы")
	TEST_ASSERT_NOTNULL(find_entry(data["special_offers"], "uid", offer.uid), "Спецзаказ в окне консоли")
	press(technician, console, "accept_offer", list("uid" = "[offer.uid]"))
	TEST_ASSERT(offer.accepted, "Спецзаказ взят")
	press(technician, console, "print_offer_manifest", list("uid" = offer.uid))
	var/obj/item/export_manifest/manifest = locate() in technician.held_items
	TEST_ASSERT_NOTNULL(manifest, "Накладная спецзаказа напечатана")
	TEST_ASSERT_EQUAL(manifest.special_offer_id, offer.uid, "Накладная привязана к спецзаказу")
	qdel(manifest)
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	traders.unlocked = TRUE
	var/datum/market_offer/smuggling = new("free_traders", /obj/item/reagent_containers/crack, "крэк", 3, 2, 100)
	traders.offers += smuggling
	press(technician, console, "accept_offer", list("uid" = "[smuggling.uid]"))
	TEST_ASSERT(!smuggling.accepted, "Обычная консоль взяла спецзаказ скрытых Вольных торговцев по uid")
	smuggling.accept()
	press(technician, console, "print_offer_manifest", list("uid" = "[smuggling.uid]"))
	TEST_ASSERT_NULL(locate(/obj/item/export_manifest) in technician.held_items, "Обычная консоль напечатала накладную скрытого партнёра")

/// Окно консоли объясняет рынок, партнёров и заявки отделов; Вольные торговцы видны только на взломанной консоли.
/datum/unit_test/economy_ui_cargo/console_data/Run()
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	metals.hot_mult = 2
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	traders.unlocked = TRUE
	var/datum/market_offer/smuggling = new("free_traders", /obj/item/reagent_containers/crack, "крэк", 3, 2, 100)
	traders.offers += smuggling
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	var/datum/supply_order/prepaid = new(pack, "Тест", "Инженер", null, "Ремонт")
	prepaid.prepaid = 500
	prepaid.department_id = ACCOUNT_ENG
	SSshuttle.shoppinglist += prepaid
	GLOB.econ_cargo_prices.refresh(TRUE)
	var/normal_help = console.ui_static_data(technician)["market_help"]
	TEST_ASSERT(!findtext(normal_help, "Вольные торговцы") && !findtext(normal_help, "контрабандн"), "Справка обычной консоли называет Вольных торговцев или контрабандного партнёра")
	var/list/data = client_view(console, technician)
	var/list/hot = find_entry(data["market"]["commodities"], "id", COMMODITY_METALS)
	TEST_ASSERT_EQUAL(hot["hot"], 2, "Горячий товар помечен множителем")
	TEST_ASSERT_NULL(find_entry(data["market"]["commodities"], "id", COMMODITY_CONTRABAND), "Контрабанда на рынке обычной консоли")
	var/list/nakamura = find_entry(data["partners"], "id", "nakamura")
	TEST_ASSERT(!nakamura["unlocked"], "Накамура закрыт")
	TEST_ASSERT(findtext(nakamura["next_unlock"], "НТ Логистика") && findtext(nakamura["next_unlock"], "ступени 2"), "Условие открытия: [nakamura["next_unlock"]]")
	TEST_ASSERT_NULL(find_entry(data["partners"], "id", "free_traders"), "Вольные торговцы видны на обычной консоли")
	TEST_ASSERT_NULL(find_entry(data["special_offers"], "uid", smuggling.uid), "Спецзаказ Вольных торговцев на обычной консоли")
	var/list/request = find_entry(data["department_requests"], "id", prepaid.id)
	TEST_ASSERT_NOTNULL(request, "Оплаченная заявка отдела в окне")
	TEST_ASSERT_EQUAL(request["prepaid"], 500, "Оплата отдела показана")
	TEST_ASSERT(islist(data["contracts"]), "Контракты отделов в окне")
	console.emag_act(technician)
	TEST_ASSERT(findtext(console.ui_static_data(technician)["market_help"], "Вольные торговцы"), "Справка взломанной консоли молчит о Вольных торговцах")
	data = client_view(console, technician)
	TEST_ASSERT_NOTNULL(find_entry(data["partners"], "id", "free_traders"), "Взломанная консоль видит Вольных торговцев")
	TEST_ASSERT_NOTNULL(find_entry(data["special_offers"], "uid", smuggling.uid), "Взломанная консоль видит их спецзаказ")

/// Цены, поставщик и наличие в каталоге консоли и экспресс-консоли идут за рынком без переоткрытия окна.
/datum/unit_test/economy_ui_cargo/catalog_prices/Run()
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/obj/machinery/computer/cargo/express/express = allocate(/obj/machinery/computer/cargo/express)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	var/list/entry = priced_entry(console, technician, pack)
	TEST_ASSERT_NOTNULL(entry, "Пак в каталоге консоли")
	var/old_cost = entry["cost"]
	TEST_ASSERT_EQUAL(old_cost, round(econ_pack_price(pack)), "Цена каталога")
	TEST_ASSERT_NOTNULL(entry["supplier"], "Поставщик в каталоге")
	TEST_ASSERT(entry["in_stock"], "Пак в наличии")
	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	TEST_ASSERT_EQUAL(entry["commodity"], metals.name, "Товар рынка пака")
	metals.trend = 2
	metals.noise = 0
	metals.recompute()
	var/version = console.prices_seen[1]
	console.ui_data(technician)
	TEST_ASSERT_EQUAL(console.prices_seen[1], version, "Окно узнаёт о ценах не из ui_data")
	GLOB.econ_cargo_prices.tick()
	TEST_ASSERT_NOTEQUAL(console.prices_seen[1], version, "Подписанная консоль узнала о новых ценах")
	TEST_ASSERT_EQUAL(console.prices_seen[1], GLOB.econ_cargo_prices.version, "Версия каталога консоли")
	entry = priced_entry(console, technician, pack)
	TEST_ASSERT(entry["cost"] > old_cost, "Цена каталога выросла за рынком")
	TEST_ASSERT_EQUAL(entry["cost"], round(econ_pack_price(pack)), "Цена каталога после сдвига рынка")
	var/list/express_data = express.ui_data(technician)
	TEST_ASSERT(!("supplies" in express_data), "Экспресс-консоль шлёт каталог с каждым обновлением")
	var/list/express_static = express.ui_static_data(technician)
	var/list/express_entry = catalog_entry(express_static["supplies"], pack)
	TEST_ASSERT_EQUAL(express_entry["cost"], entry["cost"], "Экспресс-консоль показывает новую цену")
	TEST_ASSERT(express_static["supplies"] == express.meme_pack_data, "Экспресс-консоль шлёт свой каталог, а не каталог станционной консоли")
	var/list/express_topics = express_static["help_topics"]
	TEST_ASSERT(length(express_topics), "У экспресс-консоли нет справки")
	for(var/list/topic as anything in express_topics)
		TEST_ASSERT(!findtext(jointext(topic["lines"], " "), "Вольные торговцы"), "Справка экспресс-консоли без Вольных торговцев")
	var/obj/machinery/computer/cargo/express/ds/ds_express = allocate(/obj/machinery/computer/cargo/express/ds)
	var/list/ds_static = ds_express.ui_static_data(technician)
	TEST_ASSERT(!ds_static["help_topics"], "Экспресс-консоль DS без справки станции")
	var/datum/trade_partner/logistics = SSmarket.get_partner(PARTNER_UNIVERSAL_ID)
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	logistics.unlocked = FALSE
	prospectors.stock[pack.type] = 0
	GLOB.econ_cargo_prices.refresh(TRUE)
	entry = priced_entry(console, technician, pack)
	TEST_ASSERT(!entry["in_stock"], "Пака нет в наличии")
	TEST_ASSERT_NULL(entry["supplier"], "Без поставщика")
	press(technician, console, "add", list("id" = "[pack.type]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Пак без поставщика не заказан")
	logistics.unlocked = TRUE
	press(technician, console, "add", list("id" = "[pack.type]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Консоль заказывает пак прежним действием add")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	press(technician, console, "remove", list("id" = "[order.id]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Консоль снимает заказ прежним действием remove")
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	var/datum/supply_pack/armory_pack
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/candidate = SSshuttle.supply_packs[pack_type]
		if(!candidate.exclusive_consoles && !candidate.DropPodOnly && candidate.goody == PACK_GOODY_NONE && (candidate.group in traders.sells_groups) && econ_pack_traded(candidate))
			armory_pack = candidate
			break
	TEST_ASSERT_NOTNULL(armory_pack, "Есть пак, который возят Вольные торговцы")
	logistics.unlocked = FALSE
	traders.unlocked = TRUE
	GLOB.econ_cargo_prices.refresh(TRUE)
	var/obj/machinery/computer/cargo/hacked = allocate(/obj/machinery/computer/cargo)
	hacked.emag_act(technician)
	var/list/hacked_entry = priced_entry(hacked, technician, armory_pack)
	TEST_ASSERT_EQUAL(hacked_entry["supplier"], traders.name, "Взломанная консоль видит поставщика Вольных торговцев")
	entry = priced_entry(console, technician, armory_pack)
	TEST_ASSERT(!entry["in_stock"], "Пак только у скрытого партнёра не в наличии на обычной консоли")
	TEST_ASSERT_NULL(entry["supplier"], "Скрытый поставщик не назван")
	TEST_ASSERT_EQUAL(entry["cost"], round(armory_pack.market_cost()), "Цена скрытого поставщика не показана")
	press(technician, console, "add", list("id" = "[armory_pack.type]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Обычная консоль заказала у скрытого партнёра")
	for(var/obj/item/paper/requisition in get_turf(console))
		qdel(requisition)

/// Консоль запросов кладёт заявку с причиной из окна в очередь заявок.
/datum/unit_test/economy_ui_cargo/request_console/Run()
	var/obj/machinery/computer/cargo/request/console = allocate(/obj/machinery/computer/cargo/request)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED, list(ACCESS_MEDICAL))
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	press(doctor, console, "add", list("id" = "[pack.type]", "reason" = "Ремонт <b>палаты</b>"))
	TEST_ASSERT_EQUAL(length(SSshuttle.requestlist), 1, "Заявка в очереди")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Консоль запросов не кладёт в корзину")
	var/datum/supply_order/request = SSshuttle.requestlist[1]
	TEST_ASSERT_EQUAL(request.reason, "Ремонт палаты", "Причина из окна без разметки")
	press(doctor, console, "approve", list("id" = "[request.id]"))
	TEST_ASSERT(request in SSshuttle.requestlist, "Консоль запросов одобрила заявку")
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	traders.unlocked = TRUE
	console.emag_act(doctor)
	GLOB.econ_cargo_prices.refresh(TRUE)
	TEST_ASSERT_NULL(find_entry(client_view(console, doctor)["partners"], "id", "free_traders"), "Взломанная консоль запросов видит Вольных торговцев")
	TEST_ASSERT(!findtext(console.ui_static_data(doctor)["market_help"], "Вольные торговцы"), "Справка взломанной консоли запросов называет Вольных торговцев")
	for(var/obj/item/paper/requisition in get_turf(console))
		qdel(requisition)

/// Приложение снабжения на КПК: грузчик заказывает за бюджет карго и решает заявки, чужой - нет; шаттл, спецзаказы и Вольные торговцы - только на консоли.
/datum/unit_test/economy_ui_cargo/ntos_rights/Run()
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/mob/living/carbon/human/stranger = make_staff(ACCOUNT_MED, list(ACCESS_MEDICAL))
	var/datum/computer_file/program/cargo_orders/app = supply_app(technician, /obj/item/modular_computer/pda/cargo)
	TEST_ASSERT_NOTNULL(app, "Приложение на КПК грузчика")
	var/mob/living/carbon/human/quartermaster = make_staff(ACCOUNT_CAR, list(ACCESS_QM))
	var/datum/computer_file/program/cargo_orders/quartermaster_app = supply_app(quartermaster, /obj/item/modular_computer/pda/heads/quartermaster)
	TEST_ASSERT_NOTNULL(quartermaster_app, "Приложение на КПК квартирмейстера")
	TEST_ASSERT_NOTNULL(locate(/datum/computer_file/program/department_budget) in quartermaster_app.computer.get_all_files(), "Бюджет отдела остался на КПК квартирмейстера")
	var/datum/computer_file/program/cargo_orders/stranger_app = supply_app(stranger, /obj/item/modular_computer/pda/cargo)
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	press(technician, app, "add", list("id" = "[pack.type]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Грузчик заказал с КПК")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	TEST_ASSERT_NULL(order.paying_account, "Заказ за бюджет снабжения")
	var/datum/supply_order/request = new(pack, "Тест", "Врач", null, "Нужно")
	SSshuttle.requestlist += request
	press(stranger, stranger_app, "approve", list("id" = "[request.id]"))
	TEST_ASSERT(request in SSshuttle.requestlist, "Чужой одобрил заявку")
	press(stranger, stranger_app, "clear")
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Чужой очистил корзину")
	TEST_ASSERT(stranger_app.ui_data(stranger)["requestonly"], "Чужой только подаёт заявки")
	press(technician, app, "approve", list("id" = "[request.id]"))
	TEST_ASSERT(request in SSshuttle.shoppinglist, "Грузчик одобрил заявку с КПК")
	press(technician, app, "remove", list("id" = "[order.id]"))
	TEST_ASSERT(!(order in SSshuttle.shoppinglist), "Грузчик снял заказ с КПК")
	var/datum/market_offer/offer = new("prospectors", /obj/item/stack/sheet/mineral/gold, "слитки золота", 10, 2, 60)
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	prospectors.offers += offer
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	traders.unlocked = TRUE
	var/list/data = client_view(app, technician)
	TEST_ASSERT(!data["requestonly"], "Грузчик заказывает")
	TEST_ASSERT(!data["can_take_offers"] && !data["can_send"], "КПК не берёт спецзаказы и не шлёт шаттл")
	TEST_ASSERT_NOTNULL(find_entry(data["special_offers"], "uid", offer.uid), "Спецзаказ виден на КПК")
	TEST_ASSERT_NULL(find_entry(data["partners"], "id", "free_traders"), "Вольные торговцы видны на КПК")
	press(technician, app, "accept_offer", list("uid" = "[offer.uid]"))
	TEST_ASSERT(!offer.accepted, "КПК взял спецзаказ")
	TEST_ASSERT_NOTNULL(catalog_entry(app.ui_static_data(technician)["supplies"], pack), "Каталог на КПК")
	TEST_ASSERT_EQUAL(data["message"], econ_cargo_message("Bluespace instability detected. Shuttle movement impossible."), "Сообщение ЦК на КПК как на консоли")
	TEST_ASSERT(length(data["message"]), "Сообщение на КПК не пустое")
	var/datum/econ_test_shuttle_loan/loan = new
	SSshuttle.shuttle_loan = loan
	TEST_ASSERT_EQUAL(SSshuttle.supply.getDockedId(), "supply_away", "Шаттл снабжения у ЦК")
	press(technician, app, "loan")
	TEST_ASSERT(!loan.loaned, "КПК сдал шаттл в аренду")
	var/obj/item/modular_computer/pda/pda = app.computer
	pda.enabled = TRUE
	pda.emag_act(technician)
	var/datum/supply_pack/contraband_pack = SSshuttle.supply_packs[/datum/supply_pack/costumes_toys/randomised/contraband]
	TEST_ASSERT_NULL(catalog_entry(app.ui_static_data(technician)["supplies"], contraband_pack), "Взломанный КПК показывает контрабанду")
	var/cart_before = length(SSshuttle.shoppinglist)
	press(technician, app, "add", list("id" = "[contraband_pack.type]"))
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), cart_before, "Взломанный КПК заказал контрабанду")
	var/requests_before = length(SSshuttle.requestlist)
	press(stranger, stranger_app, "add", list("id" = "[pack.type]", "reason" = "Для медбея"))
	TEST_ASSERT_EQUAL(length(SSshuttle.requestlist), requests_before + 1, "Чужой подал заявку с КПК")
	TEST_ASSERT_NOTNULL(stranger_app.radio, "Заявка с КПК оповестила канал снабжения")
	TEST_ASSERT_NULL(stranger_app.radio.loc, "Радио приложения не осталось в КПК")
	TEST_ASSERT(stranger_app.message_cooldown > world.time, "Оповещение с откатом")

/datum/tgui/econ_test_spy
	var/list/sent = list()

/datum/tgui/econ_test_spy/send_update(custom_data, force)
	sent += list(custom_data)

/obj/machinery/computer/cargo/econ_test_spy
	var/full_updates = 0

/obj/machinery/computer/cargo/econ_test_spy/update_static_data_for_all_viewers(force, ignore_cooldown)
	full_updates++

/// Каталог уходит статикой без цен, цены, рынок и партнёры - не с каждым обновлением; пересчёт шлёт открытым окнам частичное обновление, смена состава каталога - всю статику, без перемен - ничего.
/datum/unit_test/economy_ui_cargo/live_push
	var/datum/supply_pack/special_pack

/datum/unit_test/economy_ui_cargo/live_push/Run()
	var/obj/machinery/computer/cargo/econ_test_spy/console = allocate(/obj/machinery/computer/cargo/econ_test_spy)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	var/list/static_data = console.ui_static_data(technician)
	var/list/entry = catalog_entry(static_data["supplies"], pack)
	TEST_ASSERT(entry && !("cost" in entry) && !("supplier" in entry) && !("in_stock" in entry), "Строка каталога без цены")
	var/list/prices = static_data["prices"]
	TEST_ASSERT_EQUAL(prices[pack.type][1], round(econ_pack_price(pack)), "Цена пака в таблице статики")
	TEST_ASSERT(static_data["market"] && static_data["partners"], "Рынок и партнёры в статике")
	var/list/data = console.ui_data(technician)
	TEST_ASSERT(!("prices" in data) && !("market" in data) && !("partners" in data), "Цены, рынок и партнёры уходят с каждым обновлением")

	var/datum/tgui/econ_test_spy/window = allocate(/datum/tgui/econ_test_spy, technician, console, "Cargo")
	SStgui.open_uis_by_src[REF(console)] = list(window)
	GLOB.econ_cargo_prices.tick()
	TEST_ASSERT_EQUAL(length(window.sent), 0, "Без перемен окну ничего не ушло")

	var/datum/commodity/metals = SSmarket.get_commodity(COMMODITY_METALS)
	metals.trend = 2
	metals.noise = 0
	metals.recompute()
	GLOB.econ_cargo_prices.tick()
	TEST_ASSERT_EQUAL(length(window.sent), 1, "Новые цены ушли частичным обновлением")
	var/list/update = length(window.sent) ? window.sent[1] : list()
	TEST_ASSERT(update["prices"] && update["market"] && update["partners"] && !update["supplies"], "В обновлении цены, рынок и партнёры без каталога")
	var/list/new_prices = update["prices"]
	TEST_ASSERT_EQUAL(new_prices[pack.type][1], round(econ_pack_price(pack)), "Новая цена пака")

	var/datum/trade_partner/logistics = SSmarket.get_partner(PARTNER_UNIVERSAL_ID)
	logistics.wealth += 1000
	GLOB.econ_cargo_prices.tick()
	TEST_ASSERT_EQUAL(length(window.sent), 2, "Перемена у партнёра ушла частичным обновлением")
	TEST_ASSERT_EQUAL(console.full_updates, 0, "Цены и рынок не пересылают весь каталог")

	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/candidate = SSshuttle.supply_packs[pack_type]
		if(candidate.special && !candidate.special_enabled && !candidate.department_catalog && !candidate.DropPodOnly && !candidate.exclusive_consoles)
			special_pack = candidate
			break
	TEST_ASSERT_NOTNULL(special_pack, "Есть выключенный особый пак")
	special_pack.special_enabled = TRUE
	GLOB.econ_cargo_prices.tick()
	TEST_ASSERT_EQUAL(console.full_updates, 1, "Новый пак в каталоге - вся статика")
	TEST_ASSERT_EQUAL(length(window.sent), 2, "Смена состава каталога не уходит частичным обновлением")

	SStgui.open_uis_by_src -= REF(console)
	GLOB.econ_cargo_prices.tick()
	var/list/subscriptions = LAZYACCESS(console.signal_procs, GLOB.econ_cargo_prices)
	TEST_ASSERT(!subscriptions || !subscriptions[COMSIG_ECON_CARGO_PRICES_TICK], "Консоль без окон отписалась от пересчёта")

/datum/unit_test/economy_ui_cargo/live_push/Destroy()
	if(special_pack)
		special_pack.special_enabled = FALSE
	return ..()

/datum/unit_test/economy_ui_cargo/proc/find_pack(contraband, hidden, special_disabled, exclusive)
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if(pack.department_catalog || pack.DropPodOnly)
			continue
		if(!!pack.contraband != contraband || !!pack.hidden != hidden || (pack.special && !pack.special_enabled) != special_disabled || !!pack.exclusive_consoles != exclusive)
			continue
		return pack

/// Таблица цен окна - ровно паки его каталога.
/datum/unit_test/economy_ui_cargo/proc/prices_match_catalog(list/static_data, label)
	var/list/listed = econ_cargo_supply_ids(static_data["supplies"])
	var/list/prices = static_data["prices"]
	for(var/pack_type in prices)
		TEST_ASSERT(listed[pack_type], "[label]: цена пака [pack_type] вне каталога окна")
	for(var/pack_type in listed)
		TEST_ASSERT(prices[pack_type], "[label]: нет цены пака [pack_type] из каталога")

/// Окну уходят цены только его каталога: обычная консоль и КПК не получают строк контрабанды, скрытых, выключенных особых паков и эксклюзивов; консоль с платой контрабанды и взломанная консоль заявок получают строки того, что показывают.
/datum/unit_test/economy_ui_cargo/window_prices_visibility/Run()
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/supply_pack/contraband_pack = find_pack(TRUE, FALSE, FALSE, FALSE)
	var/datum/supply_pack/hidden_pack = find_pack(FALSE, TRUE, FALSE, FALSE)
	var/datum/supply_pack/special_pack = find_pack(FALSE, FALSE, TRUE, FALSE)
	var/datum/supply_pack/exclusive_pack = find_pack(FALSE, FALSE, FALSE, TRUE)
	var/datum/supply_pack/metal = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	TEST_ASSERT(contraband_pack && hidden_pack && special_pack && exclusive_pack, "Есть контрабандный, скрытый, выключенный особый и эксклюзивный пак")
	var/list/unlisted = list(contraband_pack, hidden_pack, special_pack, exclusive_pack)
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/list/static_data = console.ui_static_data(technician)
	prices_match_catalog(static_data, "обычная консоль")
	var/list/prices = static_data["prices"]
	TEST_ASSERT(prices[metal.type], "Цена обычного пака на обычной консоли")
	for(var/datum/supply_pack/pack as anything in unlisted)
		TEST_ASSERT(!prices[pack.type], "Обычная консоль получила цену [pack.type]")
	var/datum/computer_file/program/cargo_orders/app = supply_app(technician, /obj/item/modular_computer/pda/cargo)
	static_data = app.ui_static_data(technician)
	prices_match_catalog(static_data, "КПК")
	prices = static_data["prices"]
	for(var/datum/supply_pack/pack as anything in unlisted)
		TEST_ASSERT(!prices[pack.type], "КПК получил цену [pack.type]")
	var/obj/machinery/computer/cargo/smuggling_console = allocate(/obj/machinery/computer/cargo)
	smuggling_console.contraband = TRUE
	static_data = smuggling_console.ui_static_data(technician)
	prices_match_catalog(static_data, "консоль с платой контрабанды")
	prices = static_data["prices"]
	TEST_ASSERT(prices[contraband_pack.type], "Консоль с платой контрабанды не получила цену контрабанды")
	TEST_ASSERT(!prices[hidden_pack.type], "Консоль с платой контрабанды получила цену скрытого пака")
	var/obj/machinery/computer/cargo/request/hacked_request = allocate(/obj/machinery/computer/cargo/request)
	hacked_request.emag_act(technician)
	static_data = hacked_request.ui_static_data(technician)
	prices_match_catalog(static_data, "взломанная консоль заявок")
	prices = static_data["prices"]
	TEST_ASSERT(prices[contraband_pack.type] && prices[hidden_pack.type], "Взломанная консоль заявок не получила цен контрабанды и скрытого пака")
	TEST_ASSERT(!prices[special_pack.type] && !prices[exclusive_pack.type], "Взломанная консоль заявок получила цену выключенного особого пака или эксклюзива")

/obj/machinery/computer/cargo/express/econ_test_spy
	var/full_updates = 0

/obj/machinery/computer/cargo/express/econ_test_spy/update_static_data_for_all_viewers(force, ignore_cooldown)
	full_updates++

/// Взлом экспресс-консоли пересылает открытым окнам каталог, в котором уже есть контрабанда.
/datum/unit_test/economy_ui_cargo/express_emag/Run()
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/supply_pack/contraband_pack = find_pack(TRUE, FALSE, FALSE, FALSE)
	var/obj/machinery/computer/cargo/express/econ_test_spy/express = allocate(/obj/machinery/computer/cargo/express/econ_test_spy)
	TEST_ASSERT_NULL(catalog_entry(express.ui_static_data(technician)["supplies"], contraband_pack), "Контрабанда в каталоге экспресс-консоли до взлома")
	express.emag_act(technician)
	TEST_ASSERT_EQUAL(express.full_updates, 1, "Взлом не переслал статику окнам экспресс-консоли")
	TEST_ASSERT_NOTNULL(catalog_entry(express.ui_static_data(technician)["supplies"], contraband_pack), "Контрабанды нет в каталоге взломанной экспресс-консоли")

/// Экспресс-консоль, в том числе Deep Space вне станции, не шлёт шаттл, не правит корзину и заявки снабжения и не печатает накладные.
/datum/unit_test/economy_ui_cargo/express_station_actions/Run()
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO, ACCESS_QM, ACCESS_SYNDICATE_LEADER))
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	var/datum/supply_order/cart_order = new(pack, "Тест", "Грузчик", null, "")
	SSshuttle.shoppinglist += cart_order
	var/datum/supply_order/request = new(pack, "Тест", "Инженер", null, "Ремонт")
	SSshuttle.requestlist += request
	var/supply_mode = SSshuttle.supply.mode
	var/supply_dock = SSshuttle.supply.getDockedId()
	var/obj/machinery/computer/cargo/express/ds/ds_express = allocate(/obj/machinery/computer/cargo/express/ds)
	ds_express.locked = FALSE
	press(technician, ds_express, "send")
	press(technician, ds_express, "remove", list("id" = "[cart_order.id]"))
	press(technician, ds_express, "approve", list("id" = "[request.id]"))
	press(technician, ds_express, "deny", list("id" = "[request.id]"))
	press(technician, ds_express, "denyall")
	press(technician, ds_express, "clear")
	press(technician, ds_express, "print_manifest")
	TEST_ASSERT(cart_order in SSshuttle.shoppinglist, "Экспресс-консоль убрала заказ из корзины снабжения")
	TEST_ASSERT((request in SSshuttle.requestlist) && !(request in SSshuttle.shoppinglist), "Экспресс-консоль решила заявку снабжения")
	TEST_ASSERT(SSshuttle.supply.mode == supply_mode && SSshuttle.supply.getDockedId() == supply_dock, "Экспресс-консоль отправила шаттл снабжения")
	TEST_ASSERT_NULL(locate(/obj/item/export_manifest) in technician.held_items, "Экспресс-консоль напечатала накладную")

/// Экспресс-консоль, которая во взломе бросает капсулы в зону теста, а не на станцию.
/obj/machinery/computer/cargo/express/econ_test_landing
	var/area/test_landing_area

/obj/machinery/computer/cargo/express/econ_test_landing/emag_landing_area()
	return test_landing_area

/// Экспресс-заказ с бюджета снабжения: открытая консоль заказывает пак своего каталога по его цене, запертая ничего не заказывает, скрытый пак не заказывается; взломанная берёт ящик-залог без скидки и пять паков только со склада, где их пять.
/datum/unit_test/economy_ui_cargo/express_orders
	var/datum/bank_account/cargo_budget
	var/saved_cargo_balance

/datum/unit_test/economy_ui_cargo/express_orders/Destroy()
	if(cargo_budget)
		econ_test_set_balance(cargo_budget, saved_cargo_balance)
	return ..()

/datum/unit_test/economy_ui_cargo/express_orders/Run()
	var/turf/station_turf = find_walkable_station_turf()
	TEST_ASSERT_NOTNULL(station_turf, "Есть станционный турф")
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO, ACCESS_QM), station_turf)
	cargo_budget = SSeconomy.get_dep_account(ACCOUNT_CAR)
	saved_cargo_balance = cargo_budget.account_balance
	econ_test_set_balance(cargo_budget, 100000)
	var/datum/supply_pack/metal = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	var/datum/supply_pack/hidden_pack = find_pack(FALSE, TRUE, FALSE, FALSE)
	TEST_ASSERT_NOTNULL(hidden_pack, "Есть скрытый пак")
	var/obj/machinery/computer/cargo/express/econ_test_landing/express = allocate(/obj/machinery/computer/cargo/express/econ_test_landing, station_turf)
	express.test_landing_area = get_area(run_loc_floor_bottom_left)
	var/obj/item/supplypod_beacon/beacon = allocate(/obj/item/supplypod_beacon, run_loc_floor_bottom_left)
	beacon.link_console(express, technician)
	press(technician, express, "add", list("id" = "[metal.type]"))
	TEST_ASSERT_EQUAL(cargo_budget.account_balance, 100000, "Запертая экспресс-консоль приняла заказ")
	express.locked = FALSE
	press(technician, express, "add", list("id" = "[hidden_pack.type]"))
	TEST_ASSERT_EQUAL(cargo_budget.account_balance, 100000, "Экспресс-консоль заказала скрытый пак")
	press(technician, express, "LZBeacon")
	var/metal_cost = metal.get_cost()
	press(technician, express, "add", list("id" = "[metal.type]"))
	TEST_ASSERT_EQUAL(cargo_budget.account_balance, 100000 - metal_cost, "Открытая экспресс-консоль не заказала пак своего каталога по его цене")
	TIMER_COOLDOWN_END(express, COOLDOWN_EXPRESSPOD_CONSOLE)

	express.emag_act(technician)
	var/datum/supply_pack/cheap
	var/packaging
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/candidate = SSshuttle.supply_packs[pack_type]
		if(!express.offers_pack(candidate) || candidate.goody != PACK_GOODY_NONE || econ_pack_unavailable(candidate))
			continue
		var/candidate_cost = candidate.get_cost()
		var/candidate_packaging = min(candidate.market_packaging(null, candidate.market_total()), candidate_cost)
		if(candidate_cost * EMAG_ROCKETS_DISCOUNT * MAX_EMAG_ROCKETS <= MAX_EMAG_ROCKETS * candidate_packaging - 1)
			cheap = candidate
			packaging = candidate_packaging
			break
	TEST_ASSERT_NOTNULL(cheap, "Нет пака, который со скидкой взлома дешевле своих ящиков-залогов")
	econ_test_set_balance(cargo_budget, MAX_EMAG_ROCKETS * packaging - 1)
	press(technician, express, "add", list("id" = "[cheap.type]"))
	TEST_ASSERT_EQUAL(cargo_budget.account_balance, MAX_EMAG_ROCKETS * packaging - 1, "Пять ящиков-залогов куплены дешевле, чем NT их выкупит")
	var/bulk_cost = MAX_EMAG_ROCKETS * (packaging + express.emag_contents_price(cheap, null))
	econ_test_set_balance(cargo_budget, bulk_cost)
	press(technician, express, "add", list("id" = "[cheap.type]"))
	TEST_ASSERT_EQUAL(cargo_budget.account_balance, 0, "Взломанная консоль не продала пять паков по цене залога и содержимого со скидкой")
	TIMER_COOLDOWN_END(express, COOLDOWN_EXPRESSPOD_CONSOLE)

	var/datum/trade_partner/supplier = econ_pack_supplier(metal, null)
	TEST_ASSERT(supplier && !(PARTNER_ANY in supplier.sells_groups), "Металл везёт партнёр со складом")
	supplier.stock[metal.type] = MAX_EMAG_ROCKETS - 1
	econ_test_set_balance(cargo_budget, 100000)
	press(technician, express, "add", list("id" = "[metal.type]"))
	TEST_ASSERT_EQUAL(cargo_budget.account_balance, 100000, "Взломанная консоль купила пять паков со склада, где их меньше")
	TEST_ASSERT_EQUAL(supplier.stock[metal.type], MAX_EMAG_ROCKETS - 1, "Склад партнёра ушёл в минус")

/// Консоль снабжения, собранная из взломанной платы, ловит Вольных торговцев так же, как взломанная емагом.
/datum/unit_test/economy_ui_cargo/emagged_board_console/Run()
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	TEST_ASSERT(!traders.unlocked, "Вольные торговцы закрыты на свежем рынке")
	var/obj/item/circuitboard/computer/cargo/board = allocate(/obj/item/circuitboard/computer/cargo)
	board.emag_act(technician)
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	qdel(console.circuit)
	console.circuit = board
	board.forceMove(console)
	console.on_construction()
	TEST_ASSERT(console.shows_contraband(), "Консоль из взломанной платы не взломана")
	TEST_ASSERT(traders.unlocked, "Консоль из взломанной платы не открыла Вольных торговцев")
	TEST_ASSERT_NOTNULL(find_entry(client_view(console, technician)["partners"], "id", "free_traders"), "Консоль из взломанной платы не видит Вольных торговцев")

/// Справка консоли снабжения разбита на темы и вся входит в строку market_help; без допуска контрабанды Вольных торговцев в темах нет.
/datum/unit_test/economy_ui_cargo/help_topics/Run()
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/list/static_data = console.ui_static_data(technician)
	var/list/topics = static_data["help_topics"]
	TEST_ASSERT(length(topics) >= 5, "Тем справки: [length(topics)]")
	var/help = static_data["market_help"]
	for(var/list/topic as anything in topics)
		TEST_ASSERT(length(topic["title"]) && length(topic["icon"]) && length(topic["lines"]), "Тема без заголовка, значка или пунктов: [json_encode(topic)]")
		for(var/line in topic["lines"])
			TEST_ASSERT(findtext(help, line), "Пункт темы \"[topic["title"]]\" не попал в строку справки: [line]")
			TEST_ASSERT(!findtext(line, "Вольные торговцы"), "Обычная консоль называет Вольных торговцев: [line]")
	TEST_ASSERT_EQUAL(static_data["add_max"], ECON_CARGO_ADD_MAX, "Окно знает предел количества")

/// Опись пака складывает одинаковые предметы; заказ нескольких штук создаёт столько заказов, сколько просили, в пределах ECON_CARGO_ADD_MAX.
/datum/unit_test/economy_ui_cargo/order_amount/Run()
	var/datum/supply_pack/fake = new
	fake.contains = list(/obj/item/crowbar, /obj/item/crowbar, /obj/item/wrench)
	var/list/contents = econ_pack_contents(fake)
	var/obj/item/crowbar/crowbar_type = /obj/item/crowbar
	var/obj/item/wrench/wrench_type = /obj/item/wrench
	TEST_ASSERT_EQUAL(jointext(contents, ";"), "[initial(crowbar_type.name)] ×2;[initial(wrench_type.name)]", "Опись пака")
	qdel(fake)
	TEST_ASSERT_EQUAL(econ_cargo_add_amount(list()), 1, "Без количества - один")
	TEST_ASSERT_EQUAL(econ_cargo_add_amount(list("amount" = "мусор")), 1, "Мусор вместо количества - один")
	TEST_ASSERT_EQUAL(econ_cargo_add_amount(list("amount" = 500)), ECON_CARGO_ADD_MAX, "Количество ограничено")
	TEST_ASSERT_EQUAL(econ_cargo_add_amount(list("amount" = -3)), 1, "Отрицательное количество - один")

	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	TEST_ASSERT(!econ_pack_unavailable(pack), "Металл есть у партнёров")
	press(technician, console, "add", list("id" = "[pack.type]", "amount" = 3))
	var/added = 0
	for(var/datum/supply_order/order as anything in SSshuttle.shoppinglist)
		if(order.pack == pack)
			added++
	TEST_ASSERT_EQUAL(added, 3, "Три пака одним нажатием")
	var/datum/supply_order/first = SSshuttle.shoppinglist[1]
	var/list/entry = first.cart_entry()
	TEST_ASSERT_EQUAL(entry["pack"], "[pack.type]", "Строка корзины знает пак для группировки")
	TEST_ASSERT(isnull(entry["department"]), "Заказ снабжения без отдела")

	var/list/data = console.ui_data(technician)
	var/list/shuttle = data["shuttle"]
	var/static/list/states = list("station", "centcom", "to_station", "to_centcom", "recharging", "loaned", "away")
	TEST_ASSERT(shuttle["state"] in states, "Состояние шаттла: [shuttle["state"]]")
	TEST_ASSERT(isnum(shuttle["eta"]) && shuttle["eta"] >= 0, "Время до прибытия: [shuttle["eta"]]")

/// Выбранный в окне партнёр везёт заказ и берёт свою цену; не может везти - везёт самый дешёвый; чужой или скрытый партнёр не принимается.
/datum/unit_test/economy_ui_cargo/supplier_choice/Run()
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	var/datum/trade_partner/nt = SSmarket.get_partner("nt_logistics")
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	TEST_ASSERT(nt.markup > 1, "НТ Логистика с логистической наценкой: [nt.markup]")
	var/list/offer = SSmarket.best_offer(pack)
	TEST_ASSERT_EQUAL(offer[1], prospectors, "Металл дешевле у старателей")
	var/list/choices = offer[3]
	TEST_ASSERT_EQUAL(length(choices), 2, "Окно видит обоих поставщиков металла")
	press(technician, console, "add", list("id" = "[pack.type]", "partner" = "nt_logistics"))
	var/datum/supply_order/order = SSshuttle.shoppinglist[length(SSshuttle.shoppinglist)]
	TEST_ASSERT_EQUAL(order.partner_id, "nt_logistics", "Заказ запомнил выбранного партнёра")
	TEST_ASSERT_EQUAL(econ_order_supplier(order), nt, "Везёт выбранный")
	TEST_ASSERT_EQUAL(econ_order_cost(order), nt.pack_price(pack), "Цена выбранного партнёра")
	TEST_ASSERT(econ_order_cost(order) > prospectors.pack_price(pack), "НТ дороже профильного партнёра")
	nt.embargo_until = world.time + 10 MINUTES
	TEST_ASSERT_EQUAL(econ_order_supplier(order), prospectors, "Под эмбарго везёт самый дешёвый")
	nt.embargo_until = 0
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	traders.unlocked = TRUE
	press(technician, console, "add", list("id" = "[pack.type]", "partner" = "free_traders"))
	order = SSshuttle.shoppinglist[length(SSshuttle.shoppinglist)]
	TEST_ASSERT_NULL(order.partner_id, "Скрытый контрабандный партнёр не принят")
	press(technician, console, "add", list("id" = "[pack.type]", "partner" = "nakamura"))
	order = SSshuttle.shoppinglist[length(SSshuttle.shoppinglist)]
	TEST_ASSERT_NULL(order.partner_id, "Партнёр без металла не принят")

/// Эксклюзив партнёра закрыт до его 2-й ступени, везёт его только он, НТ Логистика - никогда; окно знает, у кого и с какой ступени.
/datum/unit_test/economy_ui_cargo/exclusive_packs/Run()
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/medical/veymed_surgery]
	TEST_ASSERT_NOTNULL(pack, "Пак Вей-Мед зарегистрирован")
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	TEST_ASSERT(vey.unlocked, "Вей-Мед открыт со старта")
	vey.reputation = 0
	TEST_ASSERT(econ_pack_unavailable(pack), "До 2-й ступени эксклюзив не купить")
	vey.reputation = PARTNER_TIER_STEP * 2
	TEST_ASSERT_EQUAL(vey.tier(), 2, "Вторая ступень")
	var/list/offer = SSmarket.best_offer(pack)
	TEST_ASSERT_EQUAL(offer[1], vey, "Везёт только Вей-Мед")
	TEST_ASSERT_NULL(offer[3], "Другого поставщика у эксклюзива нет")
	TEST_ASSERT(!econ_partner_supplies(SSmarket.get_partner("nt_logistics"), pack), "НТ Логистика эксклюзив не везёт")
	var/list/entry = econ_cargo_static_entry(pack)
	TEST_ASSERT_EQUAL(entry["exclusive"][1], vey.name, "Окно знает партнёра эксклюзива")
	TEST_ASSERT_EQUAL(entry["exclusive"][2], 2, "И ступень")
	for(var/pack_type in subtypesof(/datum/supply_pack))
		var/datum/supply_pack/each = SSshuttle.supply_packs[pack_type]
		if(!each?.partner_exclusive)
			continue
		var/datum/trade_partner/owner = SSmarket.get_partner(each.partner_exclusive)
		TEST_ASSERT_NOTNULL(owner, "[pack_type]: нет партнёра [each.partner_exclusive]")
		TEST_ASSERT(owner.sells_group(each.group), "[pack_type]: [owner.name] не продаёт группу [each.group]")
		TEST_ASSERT(econ_pack_traded(each), "[pack_type]: пак не идёт через партнёров")

/// Аукцион: ставка замораживается и возвращается, когда перебили; соперник не выходит за свой потолок; ставка в последнюю минуту продлевает торги; победа станции сжигает ставку и привозит лот с меткой импорта.
/datum/unit_test/economy_ui_cargo/auction/Run()
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/bidder = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/bank_account/account = econ_account_of(bidder)
	account.credit(5000, ECON_ADMIN)
	var/datum/bank_account/escrow = SSeconomy.market_account
	var/escrow_before = escrow.account_balance
	var/datum/auction_lot/lot = SSmarket.start_auction(list("path" = /obj/item/toy/plush/carpplushie, "name" = "тестовый карп", "value" = 1000))
	TEST_ASSERT_NOTNULL(lot, "Лот выставлен")
	lot.rivals = list("станция \"Тест\"" = 600)
	TEST_ASSERT_EQUAL(lot.min_bid(), 400, "Старт - 40% оценки")
	TEST_ASSERT(SSmarket.place_auction_bid(account, 399, bidder, lot.uid), "Ставка ниже минимума отвергнута")
	TEST_ASSERT(SSmarket.place_auction_bid(account, 500, bidder, lot.uid + 1), "Ставка на чужой лот отвергнута")
	press(bidder, console, "auction_bid", list("uid" = "[lot.uid]", "amount" = "400"))
	TEST_ASSERT_EQUAL(lot.bidder_account, account, "Станция ведёт")
	TEST_ASSERT_EQUAL(account.account_balance, 4600, "Ставка заморожена")
	TEST_ASSERT_EQUAL(escrow.account_balance - escrow_before, 400, "Деньги на счёте биржи")
	TEST_ASSERT_EQUAL(SSmarket.rival_bid(lot, TRUE), "станция \"Тест\"", "Соперник перебил")
	TEST_ASSERT(lot.bid >= 420 && lot.bid <= 600, "Ставка соперника в своём потолке: [lot.bid]")
	TEST_ASSERT_EQUAL(account.account_balance, 5000, "Перебитая ставка вернулась целиком")
	TEST_ASSERT_EQUAL(escrow.account_balance, escrow_before, "Счёт биржи пуст")
	lot.ends_at = world.time + 5 SECONDS
	TEST_ASSERT_NULL(SSmarket.place_auction_bid(account, 650, bidder, lot.uid), "Ставка выше соперника прошла")
	TEST_ASSERT(lot.ends_at >= world.time + AUCTION_SNIPE_WINDOW, "Ставка в последнюю минуту продлила торги")
	TEST_ASSERT_NULL(SSmarket.rival_bid(lot, TRUE), "Соперник не перебивает выше своего потолка")
	TEST_ASSERT_NULL(SSmarket.place_auction_bid(account, 700, bidder, lot.uid), "Поднять свою ставку можно")
	TEST_ASSERT_EQUAL(account.account_balance, 4300, "Доплачена только разница")
	var/list/data = console.ui_data(bidder)
	TEST_ASSERT(data["auction"]["mine"], "Окно знает, что ведёт пользователь")
	SSmarket.auction_drop_turf = run_loc_floor_bottom_left
	var/burned_before = SSeconomy.ledger.burned
	SSmarket.finish_auction()
	TEST_ASSERT_NULL(SSmarket.auction, "Торги закрыты")
	var/obj/item/storage/lockbox/order/parcel = locate() in run_loc_floor_bottom_left
	TEST_ASSERT(parcel?.buyer_account == account, "Лот приехал запертой посылкой на счёт победителя")
	var/obj/item/toy/plush/carpplushie/prize = locate() in parcel
	TEST_ASSERT_NOTNULL(prize, "Лот доставлен")
	TEST_ASSERT(prize.econ_imported, "Лот помечен как импорт")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, 700, "Выигравшая ставка сгорела")
	TEST_ASSERT_EQUAL(escrow.account_balance, escrow_before, "На счёте биржи ничего не осталось")
	TEST_ASSERT(SSmarket.auction_results[1][4], "Итог - наша станция")
	qdel(parcel)

	lot = SSmarket.start_auction(list("path" = /obj/item/toy/plush/carpplushie, "name" = "второй карп", "value" = 1000))
	lot.rivals = list("станция \"Тест\"" = 900)
	SSmarket.place_auction_bid(account, 400, bidder, lot.uid)
	SSmarket.rival_bid(lot, TRUE)
	SSmarket.finish_auction()
	TEST_ASSERT_NULL(locate(/obj/item/storage/lockbox/order) in run_loc_floor_bottom_left, "Проигранный лот не приехал")
	TEST_ASSERT_EQUAL(account.account_balance, 4300, "Проигравшему ставка вернулась")
	TEST_ASSERT_EQUAL(SSmarket.auction_results[1][2], "станция \"Тест\"", "Итог - соперник")
	TEST_ASSERT(SSmarket.next_auction_at > world.time, "Следующий лот запланирован")

/// Коллекционеры: открыты, ничего не покупают и не продают, спецзаказ просят на одну-несколько редких вещей дороже обычного.
/datum/unit_test/economy_ui_cargo/collectors/Run()
	var/datum/trade_partner/collectors = SSmarket.get_partner("collectors")
	TEST_ASSERT_NOTNULL(collectors, "Коллекционеры есть")
	TEST_ASSERT(collectors.unlocked, "Открыты со старта")
	TEST_ASSERT(!length(collectors.sells_groups) && !collectors.buy_multiplier(COMMODITY_LUXURY), "Не торгуют паками и грузом")
	var/datum/market_offer/offer = collectors.new_offer()
	TEST_ASSERT_NOTNULL(offer, "Запрос коллекционеров выставлен")
	TEST_ASSERT(offer.unit_price * offer.multiplier >= 200, "Запрос платит много: [offer.unit_price] x [offer.multiplier]")
	TEST_ASSERT(offer.quantity <= 5, "Просят мало штук: [offer.quantity]")

/// Скупка: пачка из разных предметов партнёра дешевле суммы по отдельности, берётся только целиком, уходит в корзину по своей цене у своего партнёра и пропадает из скупки; просроченная снимается.
/datum/unit_test/economy_ui_cargo/bundles/Run()
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	var/datum/supply_pack/bundle/bundle = SSmarket.generate_bundle(vey)
	TEST_ASSERT_NOTNULL(bundle, "У Вей-Мед есть что сложить в пачку")
	var/count = length(bundle.contains)
	TEST_ASSERT(count >= BUNDLE_ITEMS_MIN && count <= BUNDLE_ITEMS_MAX, "Предметов в пачке: [count]")
	TEST_ASSERT_EQUAL(length(uniqueList(bundle.contains)), count, "Предметы в пачке разные")
	TEST_ASSERT(bundle.price < bundle.full_value, "Пачка дешевле суммы: [bundle.price] против [bundle.full_value]")
	TEST_ASSERT(bundle.discount >= BUNDLE_DISCOUNT_MIN && bundle.discount <= BUNDLE_DISCOUNT_MAX, "Скидка [bundle.discount]%")
	TEST_ASSERT(bundle.price >= bundle.full_value * MARKET_PRICE_MIN, "Пачка не дешевле выкупа NT: перепродажа не окупится")
	var/list/data = console.ui_data(technician)
	TEST_ASSERT_EQUAL(length(data["bundles"]), 1, "Окно видит пачку")
	var/datum/supply_pack/bundle/other = SSmarket.generate_bundle(vey)
	press(technician, console, "buy_bundle", list("uid" = "[bundle.uid]"))
	TEST_ASSERT(!(bundle in SSmarket.bundles), "Взятая пачка пропала из скупки")
	var/datum/supply_order/order = SSshuttle.shoppinglist[length(SSshuttle.shoppinglist)]
	TEST_ASSERT_EQUAL(order.pack, bundle, "В корзине та самая пачка")
	TEST_ASSERT_EQUAL(econ_order_supplier(order), vey, "Везёт партнёр пачки")
	TEST_ASSERT_EQUAL(econ_order_cost(order), bundle.price, "Цена пачки, а не рынка")
	press(technician, console, "buy_bundle", list("uid" = "[bundle.uid]"))
	TEST_ASSERT_EQUAL(SSshuttle.shoppinglist[length(SSshuttle.shoppinglist)], order, "Вторая покупка той же пачки не прошла")
	var/obj/machinery/computer/cargo/request/request_console = allocate(/obj/machinery/computer/cargo/request)
	var/mob/living/carbon/human/doctor = make_staff(ACCOUNT_MED, list(ACCESS_MEDICAL))
	press(doctor, request_console, "buy_bundle", list("uid" = "[other.uid]"))
	TEST_ASSERT(other in SSmarket.bundles, "Заявкой скупку за бюджет снабжения не взять")
	other.expires_at = world.time - 1
	SSmarket.tick_bundles()
	TEST_ASSERT(!(other in SSmarket.bundles), "Просроченная пачка снята")
	TEST_ASSERT(!SSshuttle.supply_packs[/datum/supply_pack/bundle], "Тип пачки не попал в каталог")

/// Непринятое предложение аренды шаттла снимается с концом события: по нему не сдать шаттл и консоль не застревает на «передан ЦК».
/datum/unit_test/economy_ui_cargo/shuttle_loan_expires/Run()
	var/datum/round_event/shuttle_loan/older = new(FALSE)
	var/datum/round_event/shuttle_loan/newer = new(FALSE)
	SSdirector.running -= older
	SSdirector.running -= newer
	SSshuttle.shuttle_loan = newer
	older.end()
	TEST_ASSERT_EQUAL(SSshuttle.shuttle_loan, newer, "Конец старого события снял чужое предложение")
	newer.end()
	TEST_ASSERT_NULL(SSshuttle.shuttle_loan, "Предложение аренды осталось после конца события")
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	press(technician, console, "loan")
	TEST_ASSERT(!newer.dispatched, "Шаттл сдан по истёкшему предложению")
	TEST_ASSERT_NOTEQUAL(econ_cargo_shuttle_data()["state"], "loaned", "Консоль показывает шаттл в аренде")
	qdel(older)
	qdel(newer)

/// Каталог не шлёт описания и описи статикой: карточку пака и поиск по описанию и описи окно запрашивает у сервера, скрытые паки не раскрываются.
/datum/unit_test/economy_ui_cargo/lazy_pack_info/Run()
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/obj/machinery/computer/cargo/express/express = allocate(/obj/machinery/computer/cargo/express)
	var/mob/living/carbon/human/technician = make_staff(ACCOUNT_CAR, list(ACCESS_CARGO))
	var/datum/supply_pack/pack = SSshuttle.supply_packs[/datum/supply_pack/materials/metal50]
	var/list/view = client_view(console, technician)
	var/list/entry = catalog_entry(view["supplies"], pack)
	TEST_ASSERT_NOTNULL(entry, "Пак в каталоге")
	TEST_ASSERT(isnull(entry["desc"]) && isnull(entry["contents"]), "Описание и опись не уходят статикой")
	TEST_ASSERT_NULL(view["pack_info"], "Карточка без запроса")
	press(technician, console, "pack_info", list("id" = "[pack.type]"))
	var/list/info = console.ui_data(technician)["pack_info"]
	TEST_ASSERT_NOTNULL(info, "Карточка пришла по запросу")
	TEST_ASSERT_EQUAL(info["id"], "[pack.type]", "Карточка того пака")
	TEST_ASSERT_EQUAL(info["desc"], pack.desc || pack.name, "Описание пака")
	TEST_ASSERT_EQUAL(length(info["contents"]), length(econ_pack_contents(pack)), "Опись пака")
	var/datum/supply_pack/hidden = find_pack(FALSE, TRUE, FALSE, FALSE)
	TEST_ASSERT_NOTNULL(hidden, "Есть скрытый пак")
	press(technician, console, "pack_info", list("id" = "[hidden.type]"))
	TEST_ASSERT_NULL(console.ui_data(technician)["pack_info"], "Скрытый пак раскрылся на обычной консоли")
	var/old_desc = pack.desc
	pack.desc = "Листы ЭКОНТЕСТЪЯЖ для поиска"
	GLOB.econ_cargo_search_text -= pack.type
	press(technician, console, "search", list("text" = " эконтестъяж "))
	var/list/data = console.ui_data(technician)
	press(technician, express, "search", list("text" = "эконтестъяж"))
	var/list/express_data = express.ui_data(technician)
	pack.desc = old_desc
	GLOB.econ_cargo_search_text -= pack.type
	TEST_ASSERT_EQUAL(data["search"], "эконтестъяж", "Строка поиска без пробелов по краям")
	var/list/hits = data["search_hits"]
	TEST_ASSERT_EQUAL(length(hits), 1, "Поиск по описанию без учёта регистра нашёл [length(hits)] паков")
	TEST_ASSERT_EQUAL(hits[1], "[pack.type]", "Найден тот пак")
	TEST_ASSERT_EQUAL(data["search_total"], 1, "Найден один пак")
	var/list/express_hits = express_data["search_hits"]
	TEST_ASSERT(length(express_hits) == 1 && express_hits[1] == "[pack.type]", "Экспресс-консоль ищет так же")
	press(technician, console, "search", list("text" = "x"))
	TEST_ASSERT_EQUAL(length(console.ui_data(technician)["search_hits"]), 0, "Строка короче минимума не ищет")
	GLOB.econ_cargo_viewers -= REF(technician)
