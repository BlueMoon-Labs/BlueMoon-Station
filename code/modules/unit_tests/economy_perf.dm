/// Поштучный перебор партнёров с прежней формулой цены, без процов подбора и цены: эталон для SSmarket.best_offers().
/proc/econ_test_reference_offer(datum/supply_pack/pack, datum/bank_account/paying_account, allow_contraband)
	var/datum/commodity/market_commodity = econ_pack_commodity(pack)
	if(!market_commodity || pack.department_catalog || pack.special || pack.hidden || pack.admin_spawned || pack.contraband)
		return null
	var/total = pack.cost * SSeconomy.pack_price_modifier
	var/packaging = min(econ_packaging_value(pack.packaging_type(paying_account)), total)
	var/datum/trade_partner/best
	var/best_price
	for(var/id in SSmarket.partners)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		if((partner.contraband && !allow_contraband) || !partner.unlocked || partner.embargo_until > world.time)
			continue
		if(!((PARTNER_ANY in partner.sells_groups) || (pack.group in partner.sells_groups)) || !partner.in_stock(pack))
			continue
		var/factor = max(market_commodity.price_factor * partner.markup * (1 - partner.discount()), MARKET_PRICE_MIN)
		var/price = round(packaging + (total - packaging) * factor)
		if(!best || price < best_price)
			best = partner
			best_price = price
	return best ? list(best, best_price) : null

/// Пакетный подбор поставщиков, таблица цен снабжения и цены окна бюджета совпадают с поштучным перебором партнёров на разных состояниях рынка: эмбарго, пустые склады, репутация, сдвиг цен товаров, равные цены, контрабанда дешевле открытых партнёров.
/datum/unit_test/economy_best_offers_match
	var/list/saved_market
	var/saved_modifier

/datum/unit_test/economy_best_offers_match/Run()
	saved_market = econ_test_swap_market()
	saved_modifier = SSeconomy.pack_price_modifier
	var/datum/bank_account/account = new("econ_test_offers")
	allocated += account
	var/list/packs = list()
	for(var/pack_type in SSshuttle.supply_packs)
		packs += SSshuttle.supply_packs[pack_type]
	var/list/partner_ids = list()
	for(var/id in SSmarket.partners)
		partner_ids += id
	TEST_ASSERT(length(partner_ids) >= 3, "Партнёров меньше трёх")
	compare_all(packs, account, "конфиг")

	var/index = 0
	for(var/id in partner_ids)
		index++
		var/datum/trade_partner/partner = SSmarket.partners[id]
		partner.unlocked = TRUE
		partner.reputation = index * PARTNER_TIER_STEP
	var/datum/trade_partner/embargoed = SSmarket.partners[partner_ids[1]]
	embargoed.embargo_until = world.time + 10 MINUTES
	var/datum/trade_partner/empty = SSmarket.partners[partner_ids[2]]
	for(var/i in 1 to length(packs))
		if(i % 3 == 0)
			var/datum/supply_pack/pack = packs[i]
			empty.stock[pack.type] = 0
	var/shift = 0
	for(var/id in SSmarket.commodities)
		var/datum/commodity/commodity = SSmarket.commodities[id]
		commodity.price_factor = 0.55 + 0.15 * (shift++ % 8)
	SSeconomy.pack_price_modifier = 1.3
	compare_all(packs, account, "открытые партнёры")

	for(var/id in partner_ids)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		partner.markup = 1
		partner.reputation = 0
		partner.embargo_until = 0
	compare_all(packs, account, "равные цены")

	var/datum/trade_partner/smuggler
	for(var/id in partner_ids)
		var/datum/trade_partner/partner = SSmarket.partners[id]
		if(partner.contraband)
			smuggler = partner
			break
	TEST_ASSERT_NOTNULL(smuggler, "Нет контрабандного партнёра")
	smuggler.markup = 0.5
	var/undercut = 0
	for(var/datum/supply_pack/pack as anything in packs)
		var/list/cheapest = econ_test_reference_offer(pack, null, TRUE)
		if(cheapest && cheapest[1] == smuggler && econ_test_reference_offer(pack, null, FALSE))
			undercut++
	TEST_ASSERT(undercut, "Контрабанда нигде не дешевле открытого партнёра: ветка таблицы без контрабанды не проверена")
	compare_all(packs, account, "контрабанда дешевле")

	var/obj/machinery/computer/department_budget/console = allocate(/obj/machinery/computer/department_budget)
	var/mob/living/carbon/human/head = allocate(/mob/living/carbon/human)
	econ_test_badge(head, list(ACCESS_CAPTAIN))
	for(var/id in SSeconomy.departments)
		if(id == ACCOUNT_CMD)
			continue
		var/datum/economy_department/department = SSeconomy.departments[id]
		console.program.selections[REF(head)] = id
		var/list/data = console.program.budget_data(head)
		var/list/prices = data["prices"]
		for(var/datum/supply_pack/pack as anything in department.catalog())
			var/list/offer = econ_test_reference_offer(pack, null, FALSE)
			var/list/shown = prices["[pack.type]"]
			TEST_ASSERT_EQUAL(shown["price"], offer ? offer[2] : pack.market_cost(), "Бюджет [id]: цена [pack.type]")
			TEST_ASSERT_EQUAL(shown["available"], !!offer || !econ_pack_traded(pack), "Бюджет [id]: наличие [pack.type]")

/datum/unit_test/economy_best_offers_match/proc/compare_all(list/packs, datum/bank_account/account, stage)
	var/list/batch = SSmarket.best_offers(packs, account)
	var/list/batch_contraband = SSmarket.best_offers(packs, null, TRUE)
	GLOB.econ_cargo_prices.refresh(TRUE)
	for(var/datum/supply_pack/pack as anything in packs)
		check_offer(batch[pack], econ_test_reference_offer(pack, account, FALSE), "[stage], [pack.type] со счётом")
		var/list/expected_all = econ_test_reference_offer(pack, null, TRUE)
		check_offer(batch_contraband[pack], expected_all, "[stage], [pack.type] с контрабандой")
		check_row(GLOB.econ_cargo_prices.table[pack.type], pack, econ_test_reference_offer(pack, null, FALSE), "[stage], таблица [pack.type]")
		check_row(GLOB.econ_cargo_prices.table_all[pack.type], pack, expected_all, "[stage], таблица с контрабандой [pack.type]")

/datum/unit_test/economy_best_offers_match/proc/check_offer(list/actual, list/expected, label)
	if(!expected)
		TEST_ASSERT_NULL(actual, "[label]: лишний поставщик")
		return
	TEST_ASSERT_NOTNULL(actual, "[label]: нет поставщика")
	TEST_ASSERT(actual[1] == expected[1], "[label]: другой поставщик")
	TEST_ASSERT_EQUAL(actual[2], expected[2], "[label]: цена")

/datum/unit_test/economy_best_offers_match/proc/check_row(list/row, datum/supply_pack/pack, list/expected, label)
	var/datum/trade_partner/supplier = expected ? expected[1] : null
	TEST_ASSERT_EQUAL(row["cost"], expected ? expected[2] : pack.market_cost(), "[label]: цена")
	TEST_ASSERT_EQUAL(row["supplier"], supplier?.id, "[label]: поставщик")
	TEST_ASSERT_EQUAL(row["in_stock"], !!expected || !econ_pack_traded(pack), "[label]: наличие")

/datum/unit_test/economy_best_offers_match/Destroy()
	SSeconomy.pack_price_modifier = saved_modifier
	econ_test_restore_market(saved_market)
	GLOB.econ_cargo_prices.refresh(TRUE)
	return ..()

/datum/computer_file/program/stock_exchange/econ_test_spy
	var/pushes = 0

/datum/computer_file/program/stock_exchange/econ_test_spy/update_static_data_for_all_viewers(force, ignore_cooldown)
	pushes++

/obj/machinery/computer/stock_terminal/econ_test_spy
	var/pushes = 0

/obj/machinery/computer/stock_terminal/econ_test_spy/update_static_data_for_all_viewers(force, ignore_cooldown)
	pushes++

/// Котировки уходят в окна биржи статикой, а не с каждым обновлением: тик биржи пересылает её открытым окнам программы и терминала, программа без окон отписывается.
/datum/unit_test/economy_stock_history_static
	var/list/saved_market

/datum/unit_test/economy_stock_history_static/Run()
	saved_market = econ_test_swap_market()
	var/mob/living/carbon/human/trader = allocate(/mob/living/carbon/human)
	var/datum/computer_file/program/stock_exchange/econ_test_spy/program = new
	allocated += program
	var/obj/machinery/computer/stock_terminal/econ_test_spy/terminal = allocate(/obj/machinery/computer/stock_terminal/econ_test_spy)
	var/list/static_data = program.ui_static_data(trader)
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		TEST_ASSERT(static_data["history"][ticker] ~= company.history, "История [ticker] в статике окна")
	var/list/data = program.stocks_data(trader)
	for(var/list/entry as anything in data["companies"])
		TEST_ASSERT(!("history" in entry), "История [entry["ticker"]] не уходит с каждым обновлением")

	var/datum/tgui/program_window = allocate(/datum/tgui, trader, program, "NtosStockExchange")
	var/datum/tgui/terminal_window = allocate(/datum/tgui, trader, terminal, "StockTerminal")
	SStgui.open_uis_by_src[REF(program)] = list(program_window)
	SStgui.open_uis_by_src[REF(terminal)] = list(terminal_window)
	SSmarket.tick_stocks()
	SStgui.open_uis_by_src -= REF(program)
	SStgui.open_uis_by_src -= REF(terminal)
	TEST_ASSERT_EQUAL(program.pushes, 1, "Тик переслал статику окну программы")
	TEST_ASSERT_EQUAL(terminal.pushes, 1, "Тик переслал статику окну терминала")

	SSmarket.tick_stocks()
	TEST_ASSERT_EQUAL(program.pushes, 1, "Без окон статика не пересылается")
	TEST_ASSERT_EQUAL(terminal.pushes, 1, "Терминал без окон статику не пересылает")
	var/list/subscriptions = LAZYACCESS(program.signal_procs, SSmarket)
	TEST_ASSERT(!subscriptions || !subscriptions[COMSIG_MARKET_STOCKS_TICKED], "Программа без окон отписалась от тика биржи")

/datum/unit_test/economy_stock_history_static/Destroy()
	econ_test_restore_market(saved_market)
	return ..()

/// Прежний catalog(): проход по всем пакам снабжения.
/proc/econ_test_reference_catalog(department_id)
	. = list()
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.hidden || pack.contraband || pack.admin_spawned || pack.DropPodOnly || pack.goody != PACK_GOODY_NONE || pack.exclusive_consoles)
			continue
		if(pack.special && !pack.special_enabled)
			continue
		if(econ_pack_department(pack) == department_id)
			. += pack

/// Каталог отдела совпадает с проходом по всем пакам и следует за флагами паков и за новым паком в SSshuttle.supply_packs.
/datum/unit_test/economy_department_catalog_index
	var/datum/supply_pack/hidden_pack
	var/datum/supply_pack/special_pack
	var/datum/supply_pack/extra_pack

/datum/unit_test/economy_department_catalog_index/Run()
	check_all("старт")
	var/datum/economy_department/security = SSeconomy.get_department(ACCOUNT_SEC)
	var/list/before = security.catalog()
	hidden_pack = before[1]
	hidden_pack.hidden = TRUE
	for(var/pack_id in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_id]
		if(pack.special && !pack.special_enabled && econ_pack_department(pack) && !pack.hidden && !pack.contraband && !pack.admin_spawned && !pack.DropPodOnly && pack.goody == PACK_GOODY_NONE && !pack.exclusive_consoles)
			special_pack = pack
			break
	TEST_ASSERT_NOTNULL(special_pack, "Нет особого пака отдела")
	special_pack.special_enabled = TRUE
	TEST_ASSERT(!(hidden_pack in security.catalog()), "Скрытый пак ушёл из каталога")
	var/datum/economy_department/special_owner = SSeconomy.get_department(econ_pack_department(special_pack))
	TEST_ASSERT(special_pack in special_owner.catalog(), "Включённый особый пак в каталоге")
	check_all("флаги")
	extra_pack = new /datum/supply_pack/security/ammo
	SSshuttle.supply_packs["econ_test_extra"] = extra_pack
	TEST_ASSERT(extra_pack in security.catalog(), "Новый пак снабжения попал в каталог отдела")
	check_all("новый пак")

/datum/unit_test/economy_department_catalog_index/proc/check_all(stage)
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		TEST_ASSERT(department.catalog() ~= econ_test_reference_catalog(id), "[stage]: каталог [id] разошёлся с проходом по всем пакам")

/datum/unit_test/economy_department_catalog_index/Destroy()
	if(hidden_pack)
		hidden_pack.hidden = FALSE
	if(special_pack)
		special_pack.special_enabled = FALSE
	if(extra_pack)
		SSshuttle.supply_packs -= "econ_test_extra"
		econ_department_packs(ACCOUNT_SEC)
		qdel(extra_pack)
		extra_pack = null
	return ..()

/// Сводка сотрудников за один проход совпадает с прежними поотдельными проходами, со счётом без отдела и бюджетом в списке счетов: на смене, оклады, долг и следующая зарплата, долг без внестанционных; цель накопления - с поштучной ценой паков.
/datum/unit_test/economy_staff_stats_match
	var/list/saved_accounts

/datum/unit_test/economy_staff_stats_match/Run()
	saved_accounts = SSeconomy.bank_accounts
	SSeconomy.bank_accounts = list()
	var/list/departments = list(ACCOUNT_SEC, ACCOUNT_MED, ACCOUNT_ENG, ACCOUNT_SRV)
	var/list/grades = list(PAY_GRADE_EASY, PAY_GRADE_MEDIUM, null)
	var/list/states = list(ACCOUNT_ACTIVE, ACCOUNT_DORMANT, ACCOUNT_FROZEN)
	for(var/i in 1 to 24)
		var/datum/bank_account/member = new("econ_test_staff_[i]")
		allocated += member
		member.department_id = departments[(i % length(departments)) + 1]
		member.pay_grade = grades[(i % length(grades)) + 1]
		member.state = states[(i % length(states)) + 1]
		member.owed_wages = i * 7
		member.wage_bonus = (i % 4) * 5
		member.offstation = !(i % 5)
	var/datum/bank_account/unassigned = new("econ_test_staff_none")
	allocated += unassigned
	unassigned.pay_grade = PAY_GRADE_EASY
	unassigned.owed_wages = 50
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	SSeconomy.bank_accounts += medical.account
	var/list/stats = econ_staff_stats()
	for(var/key in stats)
		TEST_ASSERT(key, "Счёт без отдела попал в сводку")
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		var/on_shift = 0
		var/payroll = 0
		var/owed_to_staff = 0
		var/owed_wages = 0
		for(var/datum/bank_account/member as anything in SSeconomy.bank_accounts)
			if(member.department_id != id)
				continue
			if(member.state == ACCOUNT_ACTIVE)
				on_shift++
			if(member.state != ACCOUNT_DORMANT && member.pay_grade)
				payroll += SSeconomy.settings.wages[member.pay_grade] || 0
			owed_to_staff += member.owed_wages
			if(member.state != ACCOUNT_DORMANT)
				owed_to_staff += member.wage_amount()
		for(var/datum/bank_account/member as anything in department.staff_accounts())
			owed_wages += member.owed_wages
		TEST_ASSERT_EQUAL(department.staff_on_shift(stats), on_shift, "[id]: на смене")
		TEST_ASSERT_EQUAL(department.base_payroll(stats), payroll, "[id]: оклады")
		TEST_ASSERT_EQUAL(department.owed_to_staff(stats), owed_to_staff, "[id]: долг и следующая зарплата")
		TEST_ASSERT_EQUAL(department.staff_stat(stats, "owed_wages"), owed_wages, "[id]: долг без внестанционных")
		TEST_ASSERT_EQUAL(department.owed_to_staff(), owed_to_staff, "[id]: без готовой сводки")
		var/list/own_stats = econ_staff_stats(id)
		TEST_ASSERT(length(own_stats) <= 1, "[id]: сводка одного отдела собрала другие отделы")
		TEST_ASSERT_EQUAL(department.budget_return_due(), department.budget_return_due(stats), "[id]: возврат без сводки и по общей сводке")

	var/datum/economy_department/security = SSeconomy.get_department(ACCOUNT_SEC)
	var/list/catalog = security.catalog()
	security.saving_goal = catalog[1]
	security.saving_goal_until = world.time + 1 HOURS
	security.saving_goal_cache = null
	var/top = 0
	for(var/datum/supply_pack/pack as anything in catalog)
		if(!econ_pack_unavailable(pack))
			top = max(top, round(econ_pack_price(pack)))
	TEST_ASSERT_EQUAL(security.saving_goal_amount(), min(round(econ_pack_price(security.saving_goal)), top), "Цель накопления по поштучной цене паков")
	security.clear_saving_goal(ordered = TRUE)

/datum/unit_test/economy_staff_stats_match/Destroy()
	var/datum/economy_department/medical = SSeconomy.get_department(ACCOUNT_MED)
	SSeconomy.bank_accounts -= medical.account
	SSeconomy.bank_accounts = saved_accounts
	return ..()
