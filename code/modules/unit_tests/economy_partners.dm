/// Тесты на свежих партнёрах из конфига репозитория; рынок, корзина снабжения и бюджет карго возвращаются.
/datum/unit_test/economy_partners
	abstract_type = /datum/unit_test/economy_partners
	var/list/saved_market
	var/list/saved_shoppinglist
	var/list/stashed_contracts
	var/saved_centcom_message
	var/datum/bank_account/department/cargo
	var/saved_cargo
	var/list/unlocked_signals = list()
	var/list/trade_signals = list()

/datum/unit_test/economy_partners/New()
	..()
	saved_market = econ_test_swap_market()
	SSmarket.next_shift = world.time + 1 HOURS
	stashed_contracts = econ_test_stash_contracts()
	saved_shoppinglist = SSshuttle.shoppinglist.Copy()
	SSshuttle.shoppinglist.Cut()
	saved_centcom_message = SSshuttle.centcom_message
	cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	saved_cargo = cargo.account_balance
	RegisterSignal(SSmarket, COMSIG_MARKET_PARTNER_UNLOCKED, PROC_REF(on_unlocked))
	RegisterSignal(SSmarket, COMSIG_MARKET_TRADE, PROC_REF(on_trade))

/datum/unit_test/economy_partners/Destroy()
	UnregisterSignal(SSmarket, list(COMSIG_MARKET_PARTNER_UNLOCKED, COMSIG_MARKET_TRADE))
	QDEL_LIST(SSshuttle.shoppinglist)
	SSshuttle.shoppinglist += saved_shoppinglist
	SSshuttle.centcom_message = saved_centcom_message
	econ_test_restore_contracts(stashed_contracts)
	econ_test_set_balance(cargo, saved_cargo)
	cargo = null
	econ_test_restore_market(saved_market)
	return ..()

/datum/unit_test/economy_partners/proc/on_unlocked(datum/source, datum/trade_partner/partner)
	SIGNAL_HANDLER
	unlocked_signals += partner

/datum/unit_test/economy_partners/proc/on_trade(datum/source, datum/trade_partner/partner, value, is_sale)
	SIGNAL_HANDLER
	trade_signals += list(list(partner, value, is_sale))

/// Пак, который партнёр продаёт в обычном ящике.
/datum/unit_test/economy_partners/proc/crate_pack_of(datum/trade_partner/partner)
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(partner.sells_pack(pack) && pack.goody == PACK_GOODY_NONE && !ispath(pack.crate_type, /obj/structure/closet/secure_closet/cargo) && !econ_test_explodes_on_delete(pack))
			return pack

/datum/unit_test/economy_partners/proc/shuttle_crates()
	. = list()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/obj/structure/closet/crate/crate in shuttle_area)
			. += crate

/datum/unit_test/economy_partners/proc/shuttle_floor()
	for(var/area/shuttle/shuttle_area as anything in SSshuttle.supply.shuttle_areas)
		for(var/turf/open/floor in shuttle_area)
			if(!floor.is_blocked_turf())
				return floor

/datum/unit_test/economy_partners/proc/sell(atom/movable/thing, dry_run = FALSE)
	return econ_export_report_value(export_item_and_contents(thing, EXPORT_CARGO, delete_unsold = FALSE, dry_run = dry_run))

/// С начала раунда открыты три партнёра, остальные закрыты; закрытый партнёр ничего не покупает.
/datum/unit_test/economy_partners/initial/Run()
	for(var/id in list("nt_logistics", "prospectors", "vey_med"))
		var/datum/trade_partner/partner = SSmarket.get_partner(id)
		TEST_ASSERT(partner?.unlocked, "[id] открыт")
	for(var/id in list("nakamura", "agrarian", "sol_federation", "free_traders"))
		var/datum/trade_partner/partner = SSmarket.get_partner(id)
		TEST_ASSERT(partner && !partner.unlocked, "[id] закрыт")
	TEST_ASSERT(SSmarket.best_buyer(COMMODITY_METALS) == SSmarket.get_partner("prospectors"), "Гильдия платит за металл больше всех")
	TEST_ASSERT(SSmarket.best_buyer(COMMODITY_ENERGY) == SSmarket.get_partner("nt_logistics"), "Закрытая Накамура купила энергию")

/// Репутация от торговли открывает дерево партнёров: Накамуру, Аграрный союз, Солнечную Федерацию по двум ступеням, Вольных торговцев.
/datum/unit_test/economy_partners/unlock_tree/Run()
	var/datum/trade_partner/nt = SSmarket.get_partner("nt_logistics")
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/trade_partner/nakamura = SSmarket.get_partner("nakamura")
	var/datum/trade_partner/agrarian = SSmarket.get_partner("agrarian")
	var/datum/trade_partner/sol = SSmarket.get_partner("sol_federation")
	var/datum/trade_partner/free_traders = SSmarket.get_partner("free_traders")
	var/credits_per_tier = PARTNER_TIER_STEP / SSmarket.reputation_per_credit
	TEST_ASSERT(SSmarket.best_buyer(COMMODITY_CONSTRUCTION) == nt, "Стекло покупает НТ")
	var/obj/item/stack/sheet/glass/fifty/glass = allocate(/obj/item/stack/sheet/glass/fifty, run_loc_floor_bottom_left)
	var/preview = sell(glass, dry_run = TRUE)
	TEST_ASSERT(preview > 0, "Стекло продаётся")
	nt.reputation = PARTNER_TIER_STEP * 2 - preview * SSmarket.reputation_per_credit / 2
	TEST_ASSERT_EQUAL(nt.tier(), 1, "Чуть меньше второй ступени")
	TEST_ASSERT(!nakamura.unlocked, "Накамура открылась раньше второй ступени")
	sell(glass)
	TEST_ASSERT_EQUAL(nt.tier(), 2, "Продажа стекла не подняла НТ до второй ступени")
	TEST_ASSERT(nakamura.unlocked && (nakamura in unlocked_signals), "Накамура открылась с сигналом")
	TEST_ASSERT(!sol.unlocked, "Федерация открылась по одному партнёру")
	vey.note_sale(credits_per_tier)
	TEST_ASSERT(agrarian.unlocked, "Аграрный союз открылся от первой ступени Вей-Мед")
	TEST_ASSERT(!sol.unlocked, "Федерация открылась по партнёру первой ступени")
	vey.note_sale(credits_per_tier)
	TEST_ASSERT(sol.unlocked, "Федерация открылась по двум партнёрам второй ступени")
	prospectors.note_sale(credits_per_tier * 3)
	TEST_ASSERT(!free_traders.unlocked, "Репутация Гильдии открыла Вольных торговцев")
	prospectors.note_sale(credits_per_tier * 100)
	TEST_ASSERT_EQUAL(prospectors.reputation, PARTNER_REPUTATION_MAX, "Репутация упёрлась в потолок")
	TEST_ASSERT_EQUAL(prospectors.tier(), PARTNER_TIER_MAX, "Высшая ступень")
	TEST_ASSERT(abs(prospectors.discount() - PARTNER_DISCOUNT_MAX) < 0.001, "Скидка высшей ступени")

/// Шаттл покупает пак у самого дешёвого партнёра: списан его запас, вырос капитал и репутация; проданное обратно репутации не даёт; пустой склад уходит НТ, пополнение тратит капитал.
/datum/unit_test/economy_partners/stock/Run()
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	var/datum/trade_partner/nt = SSmarket.get_partner("nt_logistics")
	var/datum/supply_pack/pack = crate_pack_of(vey)
	TEST_ASSERT_NOTNULL(pack, "Вей-Мед продаёт пак в ящике")
	var/vey_price = vey.pack_price(pack)
	var/nt_price = nt.pack_price(pack)
	TEST_ASSERT(vey_price < nt_price, "Вей-Мед дешевле НТ: [vey_price] против [nt_price]")
	TEST_ASSERT_EQUAL(pack.get_cost(), vey_price, "Цена пака - у самого дешёвого поставщика")
	econ_test_set_balance(cargo, nt_price * 10)
	var/wealth_before = vey.wealth
	var/reputation_before = vey.reputation
	var/list/crates_before = shuttle_crates()
	var/datum/supply_order/order = new(pack, "Тест", "Тест", null, "Тест")
	SSshuttle.shoppinglist += order
	var/balance_before = cargo.account_balance
	SSshuttle.supply.buy()
	SSshuttle.orderhistory -= order
	TEST_ASSERT(!(order in SSshuttle.shoppinglist), "Заказ отгружен")
	qdel(order)
	var/list/delivered = shuttle_crates() - crates_before
	TEST_ASSERT_EQUAL(length(delivered), 1, "Ящик на шаттле")
	var/obj/structure/closet/crate/crate = delivered[1]
	allocated += crate.GetAllContents()
	TEST_ASSERT_EQUAL(balance_before - cargo.account_balance, vey_price, "Карго заплатило цену Вей-Мед")
	TEST_ASSERT_EQUAL(vey.stock[pack.type], SSmarket.partner_stock_default - 1, "Запас уменьшился")
	TEST_ASSERT(abs(vey.wealth - (wealth_before + vey_price)) < 0.1, "Капитал вырос на цену: [vey.wealth]")
	TEST_ASSERT(abs(vey.reputation - (reputation_before + vey_price * SSmarket.reputation_per_credit / 2)) < 0.01, "Репутация за закупку: [vey.reputation]")
	TEST_ASSERT(length(trade_signals) && trade_signals[1][1] == vey && !trade_signals[1][3], "Сигнал закупки у Вей-Мед")
	reputation_before = vey.reputation
	TEST_ASSERT(sell(crate) > 0, "Купленное продаётся")
	TEST_ASSERT(abs(vey.reputation - reputation_before) < 0.001, "Проданное обратно купленное дало репутацию: [vey.reputation - reputation_before]")
	vey.stock[pack.type] = 0
	TEST_ASSERT(SSmarket.supplier_for(pack) == nt, "Без запаса пак везёт НТ")
	TEST_ASSERT_EQUAL(pack.get_cost(), nt_price, "Без запаса цена НТ")
	var/unit_cost = max(round(pack.market_cost() * PARTNER_PRODUCTION_SHARE), 1)
	wealth_before = vey.wealth
	SSmarket.next_restock = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(vey.stock[pack.type], SSmarket.partner_stock_default, "Пополнено")
	TEST_ASSERT(abs(vey.wealth - (wealth_before + vey.base_income - unit_cost * SSmarket.partner_stock_default)) < 0.1, "Пополнение стоило [unit_cost] за штуку: [vey.wealth]")
	TEST_ASSERT(SSmarket.next_restock > world.time, "Следующее пополнение назначено")
	vey.stock[pack.type] = 0
	vey.wealth = 0
	vey.base_income = unit_cost
	SSmarket.next_restock = world.time
	SSmarket.fire()
	TEST_ASSERT_EQUAL(vey.stock[pack.type], 1, "Бедный партнёр пополнился на один пак")

/// Скидка ступени и наценка касаются только содержимого и не опускают его ниже дна рынка; пак каталога отдела идёт мимо партнёров.
/datum/unit_test/economy_partners/prices/Run()
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	var/datum/trade_partner/nt = SSmarket.get_partner("nt_logistics")
	var/datum/supply_pack/pack = crate_pack_of(vey)
	var/total = pack.cost * SSeconomy.pack_price_modifier
	var/packaging = econ_packaging_value(pack.packaging_type())
	TEST_ASSERT(packaging > 0 && packaging < total, "Ящик пака стоит [packaging] при цене [total]")
	TEST_ASSERT(abs(vey.pack_price(pack) - (packaging + (total - packaging) * vey.markup)) <= 1, "Наценка без скидки")
	vey.reputation = PARTNER_REPUTATION_MAX
	TEST_ASSERT(abs(vey.pack_price(pack) - (packaging + (total - packaging) * vey.markup * (1 - PARTNER_DISCOUNT_MAX))) <= 1, "Скидка высшей ступени: [vey.pack_price(pack)]")
	var/datum/commodity/medicine = SSmarket.get_commodity(COMMODITY_MEDICINE)
	medicine.price_factor = MARKET_PRICE_MIN
	TEST_ASSERT(abs(vey.pack_price(pack) - (packaging + (total - packaging) * MARKET_PRICE_MIN)) <= 1, "Скидка опустила цену ниже дна рынка: [vey.pack_price(pack)]")
	TEST_ASSERT(abs(nt.pack_price(pack) - (packaging + (total - packaging) * MARKET_PRICE_MIN * nt.markup)) <= 1, "Наценка на дне рынка: [nt.pack_price(pack)]")
	var/datum/supply_pack/exclusive = SSshuttle.supply_packs[/datum/supply_pack/department/engineering_export_node]
	TEST_ASSERT_NULL(econ_pack_supplier(exclusive), "Эксклюзив отдела везёт партнёр")
	TEST_ASSERT_EQUAL(econ_pack_price(exclusive), exclusive.market_cost(), "Эксклюзив отдела с наценкой")
	var/help = econ_cargo_market_help()
	TEST_ASSERT(findtext(help, "каждые [PARTNER_TIER_STEP] очков") && findtext(help, "раз в [SSmarket.partner_restock_minutes] мин."), "Справка карго не описывает партнёров")

/// Груз покупает лучший открытый покупатель, ему репутация по выручке; купленное через снабжение - по потолку выкупа и без репутации; сообщение ЦК называет покупателя.
/datum/unit_test/economy_partners/sale/Run()
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/obj/item/stack/sheet/metal/local = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 10)
	var/base = econ_export_report_value(export_item_and_contents(local, EXPORT_CARGO, apply_elastic = FALSE, delete_unsold = FALSE, dry_run = TRUE))
	TEST_ASSERT(base > 0, "Металл продаётся")
	var/reputation_before = prospectors.reputation
	var/sold = sell(local)
	TEST_ASSERT(abs(sold - base * prospectors.buy_multiplier(COMMODITY_METALS)) <= 1, "Металл продан Гильдии за [sold] при базе [base]")
	TEST_ASSERT(abs(prospectors.reputation - (reputation_before + sold * SSmarket.reputation_per_credit)) < 0.01, "Репутация Гильдии за продажу: [prospectors.reputation]")
	var/obj/structure/closet/crate/import_crate = allocate(/obj/structure/closet/crate, run_loc_floor_bottom_left)
	var/obj/item/stack/sheet/metal/imported = new(import_crate, 10)
	econ_mark_imported(import_crate)
	imported.forceMove(run_loc_floor_bottom_left)
	reputation_before = prospectors.reputation
	sold = sell(imported)
	TEST_ASSERT(sold > 0 && sold <= round(base * econ_import_resale_factor()) + 1, "Купленный металл продан за [sold] при потолке [base * econ_import_resale_factor()]")
	TEST_ASSERT(abs(prospectors.reputation - reputation_before) < 0.001, "Купленный металл дал репутацию")
	var/turf/open/floor = shuttle_floor()
	TEST_ASSERT_NOTNULL(floor, "Есть пол шаттла снабжения")
	var/obj/structure/closet/crate/shipment = allocate(/obj/structure/closet/crate, floor)
	new /obj/item/stack/sheet/metal/fifty(shipment)
	SSshuttle.supply.sell()
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "Груз купили партнёры: [prospectors.name] - "), "Сообщение ЦК не называет покупателя: [SSshuttle.centcom_message]")

/// Без открытого покупателя товар не продаётся: шаттл возвращает его, ящик-залог продаётся, сообщение ЦК называет возвращённое.
/datum/unit_test/economy_partners/embargo/Run()
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		partner.buys -= COMMODITY_METALS
		partner.buys -= PARTNER_ANY
	TEST_ASSERT_NULL(SSmarket.best_buyer(COMMODITY_METALS), "Металл кто-то покупает")
	var/obj/item/stack/sheet/metal/sheets = allocate(/obj/item/stack/sheet/metal, run_loc_floor_bottom_left, 10)
	var/datum/export_report/report = export_item_and_contents(sheets, EXPORT_CARGO, delete_unsold = FALSE, dry_run = TRUE)
	TEST_ASSERT_EQUAL(econ_export_report_value(report), 0, "Металл продан без покупателя")
	TEST_ASSERT(!length(report.total_amount), "Металл засчитан проданным")
	var/turf/open/floor = shuttle_floor()
	TEST_ASSERT_NOTNULL(floor, "Есть пол шаттла снабжения")
	var/obj/structure/closet/crate/shipment = allocate(/obj/structure/closet/crate, floor)
	var/obj/item/stack/sheet/metal/fifty/cargo_metal = new(shipment)
	allocated += cargo_metal
	SSshuttle.supply.sell()
	TEST_ASSERT(QDELETED(shipment), "Ящик-залог не продан")
	TEST_ASSERT(!QDELETED(cargo_metal) && get_turf(cargo_metal) == floor, "Металл без покупателя уничтожен или не остался на шаттле")
	TEST_ASSERT(findtext(SSshuttle.centcom_message, "Не нашлось покупателя: 1 шт. возвращено."), "Сообщение ЦК не называет возвращённое: [SSshuttle.centcom_message]")

/// Ни у кого нет пака - консоль его не заказывает, а уже стоящий заказ ждёт и не списывает деньги.
/datum/unit_test/economy_partners/out_of_stock/Run()
	var/datum/trade_partner/vey = SSmarket.get_partner("vey_med")
	var/datum/supply_pack/pack = crate_pack_of(vey)
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/cargo_tech = allocate(/mob/living/carbon/human)
	var/obj/item/card/id/card = allocate(/obj/item/card/id)
	card.access = list(ACCESS_CARGO)
	cargo_tech.put_in_hands(card)
	var/datum/tgui/window = allocate(/datum/tgui, cargo_tech, console, "Cargo")
	window.status = UI_INTERACTIVE
	usr = cargo_tech
	console.ui_act("add", list("id" = "[pack.type]"), window)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Консоль заказывает пак в наличии")
	QDEL_LIST(SSshuttle.shoppinglist)
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		partner.unlocked = FALSE
	TEST_ASSERT(econ_pack_unavailable(pack), "Пак доступен без партнёров")
	console.ui_act("add", list("id" = "[pack.type]"), window)
	usr = null
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Консоль заказала пак, которого нет")
	econ_test_set_balance(cargo, pack.get_cost() * 10)
	var/datum/supply_order/order = new(pack, "Тест", "Тест", null, "Тест")
	SSshuttle.shoppinglist += order
	var/balance_before = cargo.account_balance
	SSshuttle.supply.buy()
	TEST_ASSERT(order in SSshuttle.shoppinglist, "Заказ без поставщика отгружен")
	TEST_ASSERT_EQUAL(cargo.account_balance, balance_before, "Заказ без поставщика списал деньги")
	QDEL_LIST(SSshuttle.shoppinglist)

/// Вольные торговцы дешевле всех, но обычная консоль заказывает и шаттл везёт у видимого партнёра; без него - «нет в наличии»; у торговцев покупает только взломанная консоль.
/datum/unit_test/economy_partners/hidden_supplier/Run()
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/trade_partner/traders = SSmarket.get_partner("free_traders")
	var/datum/trade_partner/logistics = SSmarket.get_partner(PARTNER_UNIVERSAL_ID)
	var/datum/supply_pack/pack = crate_pack_of(prospectors)
	TEST_ASSERT_NOTNULL(pack, "Гильдия продаёт пак в ящике")
	logistics.unlocked = FALSE
	traders.unlocked = TRUE
	traders.markup = PARTNER_MARKUP_MIN
	traders.sells_groups = list(pack.group)
	TEST_ASSERT(traders.pack_price(pack) < prospectors.pack_price(pack), "Торговцы дешевле Гильдии")
	var/obj/machinery/computer/cargo/console = allocate(/obj/machinery/computer/cargo)
	var/mob/living/carbon/human/cargo_tech = allocate(/mob/living/carbon/human)
	var/datum/tgui/window = allocate(/datum/tgui, cargo_tech, console, "Cargo")
	window.status = UI_INTERACTIVE
	usr = cargo_tech
	console.ui_act("add", list("id" = "[pack.type]"), window)
	usr = null
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Обычная консоль заказала пак")
	var/datum/supply_order/order = SSshuttle.shoppinglist[1]
	var/prospectors_price = prospectors.pack_price(pack)
	econ_test_set_balance(cargo, prospectors_price * 10)
	var/balance_before = cargo.account_balance
	var/list/crates_before = shuttle_crates()
	SSshuttle.supply.buy()
	SSshuttle.orderhistory -= order
	for(var/obj/structure/closet/crate/crate as anything in shuttle_crates() - crates_before)
		allocated += crate.GetAllContents()
	TEST_ASSERT(!(order in SSshuttle.shoppinglist), "Заказ отгружен")
	qdel(order)
	TEST_ASSERT_EQUAL(balance_before - cargo.account_balance, prospectors_price, "Снабжение заплатило цену Гильдии")
	TEST_ASSERT_EQUAL(prospectors.stock[pack.type], SSmarket.partner_stock_default - 1, "Пак взят со склада Гильдии")
	TEST_ASSERT(isnull(traders.stock[pack.type]) || traders.stock[pack.type] == SSmarket.partner_stock_default, "Торговцы поставили обычный заказ")
	prospectors.stock[pack.type] = 0
	TEST_ASSERT(econ_pack_unavailable(pack), "Без видимого поставщика пака нет в наличии")
	usr = cargo_tech
	console.ui_act("add", list("id" = "[pack.type]"), window)
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 0, "Обычная консоль заказала у торговцев")
	var/obj/machinery/computer/cargo/hacked = allocate(/obj/machinery/computer/cargo)
	hacked.emag_act(cargo_tech)
	var/datum/tgui/hacked_window = allocate(/datum/tgui, cargo_tech, hacked, "Cargo")
	hacked_window.status = UI_INTERACTIVE
	hacked.ui_act("add", list("id" = "[pack.type]"), hacked_window)
	usr = null
	TEST_ASSERT_EQUAL(length(SSshuttle.shoppinglist), 1, "Взломанная консоль заказала у торговцев")
	order = SSshuttle.shoppinglist[1]
	crates_before = shuttle_crates()
	SSshuttle.supply.buy()
	SSshuttle.orderhistory -= order
	for(var/obj/structure/closet/crate/crate as anything in shuttle_crates() - crates_before)
		allocated += crate.GetAllContents()
	qdel(order)
	TEST_ASSERT_EQUAL(traders.stock[pack.type], SSmarket.partner_stock_default - 1, "Заказ взломанной консоли везут торговцы")
	for(var/obj/item/paper/requisition in get_turf(console))
		qdel(requisition)

/// Секция партнёров из economy.json грузится без ошибок и совпадает со встроенной; битые записи пишут ошибки и не ломают партнёров; перечитывание сохраняет репутацию.
/datum/unit_test/economy_partners/config/Run()
	var/list/errors = SSmarket.load_settings(SSeconomy.settings.raw?["market"])
	TEST_ASSERT(!length(errors), "economy.json market: [jointext(errors, "; ")]")
	var/list/configured = snapshot_partners()
	SSmarket.load_settings(list())
	var/list/builtin = snapshot_partners()
	TEST_ASSERT_EQUAL(length(builtin), length(configured), "Число параметров")
	for(var/key in configured)
		TEST_ASSERT_EQUAL(builtin[key], configured[key], "Встроенное [key] расходится с economy.json")
	var/list/config_partners = SSeconomy.settings.raw["market"]["partners"]
	for(var/id in GLOB.market_default_partners)
		TEST_ASSERT_EQUAL(GLOB.market_default_partners[id]["wealth"], config_partners[id]["wealth"], "Встроенный капитал [id] расходится с economy.json")
	var/datum/trade_partner/nt = SSmarket.get_partner("nt_logistics")
	var/default_markup = nt.markup
	nt.reputation = PARTNER_TIER_STEP
	var/list/bad = list(
		"partner_restock_minutes" = 0,
		"partner_stock_default" = 1.5,
		"reputation_per_credit" = -1,
		"commodities" = SSeconomy.settings.raw["market"]["commodities"],
		"partners" = list(
			"nt_logistics" = list("markup" = 100, "buys" = list("unobtainium" = 1, PARTNER_ANY = 1), "unlock" = list("partner" = "nobody", "tier" = 2)),
			"prospectors" = "плохо",
			"acme" = list("name" = "Акме"),
		),
	)
	errors = SSmarket.load_settings(bad)
	TEST_ASSERT_EQUAL(length(errors), 8, "Ошибки: пополнение, запас, репутация, наценка, товар, открытие, не объект, неизвестный партнёр ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(SSmarket.partner_restock_minutes, initial(SSmarket.partner_restock_minutes), "Нулевой интервал пополнения принят")
	TEST_ASSERT_EQUAL(nt.markup, default_markup, "Неверная наценка принята")
	TEST_ASSERT_EQUAL(length(SSmarket.partners), length(GLOB.market_default_partners), "Неизвестный партнёр добавлен")
	TEST_ASSERT(SSmarket.get_partner("nt_logistics") == nt, "Перечитывание заменило партнёра")
	TEST_ASSERT_EQUAL(nt.reputation, PARTNER_TIER_STEP, "Перечитывание сбросило репутацию")
	errors = SSmarket.load_settings("мусор")
	TEST_ASSERT(length(errors), "Секция не объект - ошибка")
	TEST_ASSERT_EQUAL(length(SSmarket.partners), length(GLOB.market_default_partners), "Встроенные партнёры при битой секции")
	TEST_ASSERT(nt.unlocked, "НТ закрыта при битой секции")
	var/list/market_section = SSeconomy.settings.raw["market"]
	var/list/no_universal = market_section.Copy()
	var/list/partner_entries = no_universal["partners"]
	partner_entries = partner_entries.Copy()
	partner_entries["nt_logistics"] = list("sells_groups" = list("Medical"))
	no_universal["partners"] = partner_entries
	errors = SSmarket.load_settings(no_universal)
	TEST_ASSERT_EQUAL(length(errors), 1, "Без партнёра, который продаёт и покупает всё, - ошибка ([jointext(errors, "; ")])")
	TEST_ASSERT((PARTNER_ANY in nt.sells_groups) && nt.unlocked, "НТ Логистика не вернулась встроенной")
	var/datum/trade_partner/nakamura = SSmarket.get_partner("nakamura")
	nakamura.unlocked = FALSE
	nt.reputation = PARTNER_TIER_STEP * 2
	SSmarket.load_settings(SSeconomy.settings.raw?["market"])
	TEST_ASSERT(nakamura.unlocked, "Перечитывание не проверило открытие партнёров")

/datum/unit_test/economy_partners/config/proc/snapshot_partners()
	. = list("restock" = "[SSmarket.partner_restock_minutes]", "stock" = "[SSmarket.partner_stock_default]", "reputation" = "[SSmarket.reputation_per_credit]")
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		var/list/buy_texts = list()
		for(var/commodity_id in partner.buys)
			buy_texts += "[commodity_id]=[partner.buys[commodity_id]]"
		var/list/unlock_texts = list()
		for(var/key in partner.unlock)
			unlock_texts += "[key]=[partner.unlock[key]]"
		.[id] = "[partner.name]|[partner.desc]|[jointext(buy_texts, ",")]|[jointext(partner.sells_groups, ",")]|[partner.markup]|[partner.base_income]|[partner.start_unlocked]|[jointext(unlock_texts, ",")]|[partner.company]|[partner.contraband]"
