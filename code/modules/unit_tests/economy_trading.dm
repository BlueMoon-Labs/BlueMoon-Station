/// Сделки на копии биржи из конфига со своим системным счётом биржи; рынок, счёт биржи и казна восстанавливаются.
/datum/unit_test/economy_trading
	abstract_type = /datum/unit_test/economy_trading
	var/list/saved_market
	var/datum/bank_account/system/saved_market_account
	var/datum/stock_company/company
	var/list/traders = list()
	var/list/trades = list()
	var/datum/bank_account/treasury
	var/list/saved_treasury

/datum/unit_test/economy_trading/New()
	..()
	saved_market = econ_test_swap_market()
	SSmarket.company_event_chance = 0
	saved_market_account = SSeconomy.market_account
	SSeconomy.market_account = new /datum/bank_account/system("econ_test_market")
	company = SSmarket.get_company("AGRO")
	company.volatility = 0
	RegisterSignal(SSmarket, COMSIG_MARKET_STOCK_TRADE, PROC_REF(on_trade))

/datum/unit_test/economy_trading/Destroy()
	UnregisterSignal(SSmarket, COMSIG_MARKET_STOCK_TRADE)
	QDEL_LIST(traders)
	if(treasury)
		var/delta = treasury.account_balance - saved_treasury["balance"]
		if(delta > 0)
			treasury.debit(delta, ECON_ADMIN)
		else if(delta < 0)
			treasury.credit(-delta, ECON_ADMIN)
		treasury.shares = saved_treasury["shares"]
		treasury.cost_basis = saved_treasury["cost_basis"]
		treasury.trade_cooldowns = saved_treasury["trade_cooldowns"]
		treasury.realized_stock_profit = saved_treasury["realized"]
		treasury = null
	qdel(SSeconomy.market_account)
	SSeconomy.market_account = saved_market_account
	saved_market_account = null
	company = null
	econ_test_restore_market(saved_market)
	return ..()

/datum/unit_test/economy_trading/proc/on_trade(datum/source, datum/bank_account/account, ticker, count, price, is_buy)
	SIGNAL_HANDLER
	trades += "[ticker]:[count]:[price]:[is_buy]"

/datum/unit_test/economy_trading/proc/new_trader(money)
	var/datum/bank_account/trader = new("econ_test_trader_[length(traders) + 1]")
	traders += trader
	if(money)
		trader.credit(money, ECON_ADMIN)
	return trader

/// Казна станции на время теста, с запасом денег; баланс и акции возвращаются в Destroy().
/datum/unit_test/economy_trading/proc/use_treasury(money)
	treasury = SSeconomy.treasury()
	saved_treasury = list(
		"balance" = treasury.account_balance,
		"shares" = treasury.shares.Copy(),
		"cost_basis" = treasury.cost_basis.Copy(),
		"trade_cooldowns" = treasury.trade_cooldowns.Copy(),
		"realized" = treasury.realized_stock_profit,
	)
	treasury.credit(money, ECON_ADMIN)
	return treasury

/datum/unit_test/economy_trading/proc/expire_cooldown(datum/bank_account/account, ticker)
	account.trade_cooldowns[ticker] -= SSeconomy.settings.stock_trade_cooldown_seconds SECONDS

/// Во сколько раз должна вырасти цена, чтобы круг «купил-продал» окупил спред и обе комиссии.
/datum/unit_test/economy_trading/proc/breakeven()
	var/spread = SSeconomy.settings.stock_spread
	var/fee = SSeconomy.settings.stock_fee
	return (100 + spread) * (100 + fee) / ((100 - spread) * (100 - fee))

/datum/unit_test/economy_trading/proc/reset_company(datum/stock_company/target)
	target.price = target.base_price
	target.event_mult = 1
	target.trade_volume = 0
	target.halted_until = 0
	target.history.Cut()

/// Наибольший рост цены от тика покупки к любому более позднему тику продажи.
/datum/unit_test/economy_trading/proc/best_ratio(list/prices)
	. = 0
	var/lowest = prices[1]
	for(var/index in 2 to length(prices))
		. = max(., prices[index] / lowest)
		lowest = min(lowest, prices[index])

/// Покупка списывает цену со спредом и комиссию, продажа зачисляет цену за вычетом спреда и комиссии; деньги сделки идут через счёт биржи, комиссия - в сток.
/datum/unit_test/economy_trading/buy_sell/Run()
	var/datum/bank_account/trader = new_trader(10000)
	company.price = 50
	var/burned_before = SSeconomy.ledger.burned
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(trader, "AGRO", 10), "Покупка")
	var/cost = CEILING(50 * 10 * (100 + SSeconomy.settings.stock_spread) / 100, 1)
	var/buy_fee = CEILING(cost * SSeconomy.settings.stock_fee / 100, 1)
	TEST_ASSERT_EQUAL(trader.shares["AGRO"], 10, "Десять акций")
	TEST_ASSERT_EQUAL(trader.account_balance, 10000 - cost - buy_fee, "Списана цена со спредом и комиссия")
	TEST_ASSERT_EQUAL(SSeconomy.market_account.account_balance, cost, "Биржа получила цену со спредом")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, buy_fee, "Комиссия покупки ушла в сток")
	TEST_ASSERT_EQUAL(trader.cost_basis["AGRO"], cost + buy_fee, "Уплаченное за позицию")
	TEST_ASSERT_EQUAL(SSmarket.portfolio_value(trader), 500, "Стоимость портфеля по текущей цене")
	company.price = 100
	expire_cooldown(trader, "AGRO")
	burned_before = SSeconomy.ledger.burned
	TEST_ASSERT_NULL(SSmarket.try_sell_shares(trader, "AGRO", 10), "Продажа")
	var/proceeds = round(100 * 10 * (100 - SSeconomy.settings.stock_spread) / 100)
	var/sell_fee = CEILING(proceeds * SSeconomy.settings.stock_fee / 100, 1)
	TEST_ASSERT(!("AGRO" in trader.shares) && !("AGRO" in trader.cost_basis), "Пустая позиция осталась в списках")
	TEST_ASSERT_EQUAL(trader.account_balance, 10000 - cost - buy_fee + proceeds - sell_fee, "Зачислена выручка за вычетом комиссии")
	TEST_ASSERT_EQUAL(trader.realized_stock_profit, proceeds - sell_fee - cost - buy_fee, "Прибыль учтена")
	TEST_ASSERT_EQUAL(SSeconomy.market_account.account_balance, cost - proceeds, "Выручку выплатила биржа")
	TEST_ASSERT_EQUAL(SSeconomy.ledger.burned - burned_before, sell_fee, "Комиссия продажи ушла в сток")
	TEST_ASSERT_EQUAL(jointext(trades, ","), "AGRO:10:50:1,AGRO:10:100:0", "Сигналы сделок")

/// Купить и продать по неизменной цене всегда убыточно при любой цене и объёме; потерянное трейдером ушло бирже и в сток.
/datum/unit_test/economy_trading/round_trip/Run()
	var/datum/bank_account/trader = new_trader(100000)
	for(var/price in list(2.37, 13.3, 45, 99.99, 224.5))
		for(var/count in list(1, 3, round(SSeconomy.settings.stock_position_cap / max(price, company.base_price))))
			company.price = price
			var/balance_before = trader.account_balance
			var/profit_before = trader.realized_stock_profit
			var/market_before = SSeconomy.market_account.account_balance
			var/burned_before = SSeconomy.ledger.burned
			TEST_ASSERT_NULL(SSmarket.try_buy_shares(trader, "AGRO", count), "Покупка [count] по [price]")
			expire_cooldown(trader, "AGRO")
			TEST_ASSERT_NULL(SSmarket.try_sell_shares(trader, "AGRO", count), "Продажа [count] по [price]")
			expire_cooldown(trader, "AGRO")
			var/loss = balance_before - trader.account_balance
			TEST_ASSERT(loss > 0, "Круг [count] по [price] не убыточен: [loss]")
			TEST_ASSERT_EQUAL(profit_before - trader.realized_stock_profit, loss, "Прибыль круга [count] по [price]")
			TEST_ASSERT_EQUAL(SSeconomy.market_account.account_balance - market_before + SSeconomy.ledger.burned - burned_before, loss, "Деньги круга [count] по [price] не сошлись")

/// Сговор ста полных личных счетов и казны: даже первый в очереди, купивший раньше всех и продавший первым, остаётся в убытке.
/datum/unit_test/economy_trading/self_impact/Run()
	var/cap = SSeconomy.settings.stock_position_cap
	reset_company(company)
	var/list/pumpers = list(new_trader(cap * 2), use_treasury(cap * SSeconomy.settings.stock_treasury_cap_mult * 2))
	for(var/i in 1 to 99)
		pumpers += new_trader(cap * 2)
	var/start_price = company.price
	var/list/balances = list()
	var/list/counts = list()
	for(var/datum/bank_account/account as anything in pumpers)
		balances[account] = account.account_balance
		counts[account] = round(SSmarket.position_cap(account) / max(company.price, company.base_price))
		TEST_ASSERT_NULL(SSmarket.try_buy_shares(account, "AGRO", counts[account]), "Покупка на лимит [account.account_holder]")
	TEST_ASSERT(company.price > start_price, "Покупки не двинули цену")
	TEST_ASSERT(company.price / start_price < breakeven(), "Сговор поднял цену на [company.price / start_price], порог [breakeven()]")
	for(var/datum/bank_account/account as anything in pumpers)
		expire_cooldown(account, "AGRO")
		TEST_ASSERT_NULL(SSmarket.try_sell_shares(account, "AGRO", counts[account]), "Продажа [account.account_holder]")
		TEST_ASSERT(account.account_balance < balances[account], "[account.account_holder] заработал на сговоре: [account.account_balance - balances[account]]")

/// Отказы не двигают деньги и не ставят кулдаун: лимит позиции, неверное количество, нет компании, кулдаун по компании, остановленные торги, нет денег, заморозка, продажа сверх позиции, чужие бюджеты.
/datum/unit_test/economy_trading/limits/Run()
	var/datum/bank_account/trader = new_trader(100000)
	company.price = 50
	var/fitting = round(SSeconomy.settings.stock_position_cap / company.price)
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(trader, "AGRO", fitting + 1), "Лимит позиции")
	for(var/bad_count in list(0, -3, 0.5, "10", null))
		TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(trader, "AGRO", bad_count), "Количество [isnull(bad_count) ? "null" : bad_count]")
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(trader, "ZZZZ", 1), "Нет такой компании")
	TEST_ASSERT_EQUAL(trader.account_balance, 100000, "Отказ списал деньги")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(trader, "AGRO", fitting), "Позиция ровно на лимит")
	expire_cooldown(trader, "AGRO")
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(trader, "AGRO", 1), "Сверх лимита после покупки")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(trader, "PRSP", 1), "Другая компания без кулдауна")
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(trader, "PRSP", 1), "Кулдаун")
	TEST_ASSERT_NOTNULL(SSmarket.try_sell_shares(trader, "PRSP", 1), "Кулдаун продажи")
	expire_cooldown(trader, "PRSP")
	TEST_ASSERT_NOTNULL(SSmarket.try_sell_shares(trader, "PRSP", 2), "Продажа сверх позиции")
	TEST_ASSERT_NOTNULL(SSmarket.try_sell_shares(trader, "VYMD", 1), "Продажа без акций")
	var/datum/stock_company/prospectors = SSmarket.get_company("PRSP")
	prospectors.halted_until = world.time + 1 MINUTES
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(trader, "PRSP", 1), "Покупка при остановленных торгах")
	TEST_ASSERT_NOTNULL(SSmarket.try_sell_shares(trader, "PRSP", 1), "Продажа при остановленных торгах")
	prospectors.halted_until = 0
	trader.state = ACCOUNT_FROZEN
	TEST_ASSERT_NOTNULL(SSmarket.try_sell_shares(trader, "PRSP", 1), "Продажа с замороженного счёта")
	trader.state = ACCOUNT_ACTIVE
	TEST_ASSERT_NULL(SSmarket.try_sell_shares(trader, "PRSP", 1), "Продажа после кулдауна")
	var/datum/bank_account/poor = new_trader(0)
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(poor, "AGRO", 1), "Нет денег")
	TEST_ASSERT(!length(poor.shares) && !poor.account_balance, "Покупка без денег")
	var/datum/bank_account/cargo = SSeconomy.get_dep_account(ACCOUNT_CAR)
	TEST_ASSERT_NOTNULL(cargo, "Бюджет снабжения")
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(cargo, "AGRO", 1), "Бюджет отдела торгует")
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(SSeconomy.cash_account, "AGRO", 1), "Системный счёт торгует")
	TEST_ASSERT(!length(cargo.shares) && !length(SSeconomy.cash_account.shares), "Акции у бюджета")

/// Казна торгует с лимитом позиции в stock_treasury_cap_mult раз выше личного.
/datum/unit_test/economy_trading/treasury_cap/Run()
	var/cap = SSeconomy.settings.stock_position_cap * SSeconomy.settings.stock_treasury_cap_mult
	use_treasury(cap * 2)
	company.price = 50
	var/fitting = round(cap / company.price)
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(treasury, "AGRO", fitting + 1), "Сверх лимита казны")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(treasury, "AGRO", fitting), "Казна на свой лимит")
	TEST_ASSERT_EQUAL(treasury.shares["AGRO"], fitting, "Акции казны")

/// Итоги раунда называют трейдера с наибольшей реализованной прибылью, убыточного - нет.
/datum/unit_test/economy_trading/report/Run()
	var/datum/bank_account/winner = new_trader(10000)
	var/datum/bank_account/loser = new_trader(10000)
	company.price = 50
	SSmarket.try_buy_shares(winner, "AGRO", 20)
	SSmarket.try_buy_shares(loser, "AGRO", 20)
	expire_cooldown(winner, "AGRO")
	expire_cooldown(loser, "AGRO")
	company.price = 40
	SSmarket.try_sell_shares(loser, "AGRO", 20)
	company.price = 80
	SSmarket.try_sell_shares(winner, "AGRO", 20)
	TEST_ASSERT(winner.realized_stock_profit > 0 && loser.realized_stock_profit < 0, "Прибыль [winner.realized_stock_profit], убыток [loser.realized_stock_profit]")
	var/report = jointext(econ_market_report(), "\n")
	TEST_ASSERT(findtext(report, "Лучший трейдер смены: <b>[winner.account_holder]</b>, прибыль [winner.realized_stock_profit] кр."), "Нет трейдера в итогах: [report]")
	TEST_ASSERT(!findtext(report, loser.account_holder), "Убыточный трейдер в итогах")

/// Лимит позиции считается по цене не ниже базовой: после обвала и усреднением вниз позиция не растёт сверх лимита по базе.
/datum/unit_test/economy_trading/crash_cap/Run()
	var/datum/bank_account/trader = new_trader(100000)
	company.price = company.base_price * STOCK_RELIST_RATIO
	var/fitting = round(SSeconomy.settings.stock_position_cap / company.base_price)
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(trader, "AGRO", fitting + 1), "После обвала куплено сверх лимита по базе")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(trader, "AGRO", fitting), "Лимит по базе")
	expire_cooldown(trader, "AGRO")
	company.price /= 2
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(trader, "AGRO", 1), "Усреднение вниз сверх лимита")
	TEST_ASSERT_EQUAL(SSmarket.try_buy_shares(null, "AGRO", 1), "Нет такого счёта.", "Отказ без счёта")

/// Повторный листинг консолидирует акции держателей: стоимость позиции по цене остановки не растёт.
/datum/unit_test/economy_trading/relist_consolidation/Run()
	var/datum/bank_account/trader = new_trader(100000)
	reset_company(company)
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(trader, "AGRO", 100), "Покупка")
	var/datum/bank_account/small = new_trader(10000)
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(small, "AGRO", 1), "Покупка одной акции")
	var/small_basis = small.cost_basis["AGRO"]
	company.price = company.base_price * STOCK_BANKRUPT_RATIO / 2
	SSmarket.tick_stocks()
	var/halted_price = company.price
	TEST_ASSERT(company.is_halted(), "Банкротство не остановило торги")
	company.halted_until = world.time
	SSmarket.tick_stocks()
	TEST_ASSERT(abs(company.price - company.base_price * STOCK_RELIST_RATIO) < 0.01, "Цена повторного листинга: [company.price]")
	TEST_ASSERT_EQUAL(trader.shares["AGRO"], round(100 * halted_price / company.price), "Акции не консолидированы")
	TEST_ASSERT(trader.shares["AGRO"] * company.price <= 100 * halted_price, "Позиция подорожала при листинге")
	TEST_ASSERT(!("AGRO" in small.shares) && !("AGRO" in small.cost_basis), "Дробный остаток не списан")
	TEST_ASSERT_EQUAL(small.realized_stock_profit, -small_basis, "Списанная позиция не учтена убытком")

/// Без шума после видимого события компании (и фейка), события станции (метеоры и вспышка - через announce() и start()), релиста и торгового объёма ни одна пара тиков покупки и продажи не даёт роста цены.
/datum/unit_test/economy_trading/visible_events/Run()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/each = SSmarket.companies[ticker]
		each.volatility = 0
	for(var/list/template as anything in SSmarket.company_event_templates)
		for(var/fake in list(FALSE, TRUE))
			reset_company(company)
			SSmarket.schedule_company_event(company, template["key"], template["headline"], template["effect"], 0, fake)
			SSmarket.run_due_events()
			check_paths(list(company), "[template["key"]][fake ? ", фейк" : ""]")
	for(var/key in SSmarket.station_events)
		var/list/hit = reset_hit(key)
		SSmarket.station_event(key)
		check_paths(hit, key)
	var/datum/round_event/meteor_wave/wave = new(FALSE)
	var/list/meteor_hit = reset_hit("meteors")
	wave.announce(FALSE)
	check_paths(meteor_hit, "объявление метеоров", wave)
	wave.kill()
	qdel(wave)
	var/datum/round_event/disease_outbreak/outbreak = new(FALSE)
	var/list/disease_hit = reset_hit("disease_outbreak")
	outbreak.announce(FALSE)
	check_paths(disease_hit, "объявление вспышки")
	outbreak.kill()
	qdel(outbreak)
	reset_company(company)
	company.price = company.base_price * STOCK_BANKRUPT_RATIO / 2
	SSmarket.tick_stocks()
	TEST_ASSERT(company.is_halted(), "Банкротство не остановило торги")
	company.halted_until = world.time
	SSmarket.tick_stocks()
	TEST_ASSERT(!company.is_halted(), "Повторный листинг")
	check_paths(list(company), "релист")
	var/datum/trade_partner/prospectors = SSmarket.get_partner("prospectors")
	var/datum/stock_company/prospectors_company = SSmarket.get_company(prospectors.company)
	reset_company(prospectors_company)
	prospectors.note_sale(STOCK_TRADE_SCALE * 10)
	check_paths(list(prospectors_company), "торговый объём")

/// Сбрасывает все компании и кулдауны событий станции, возвращает компании, которые задевает событие key.
/datum/unit_test/economy_trading/visible_events/proc/reset_hit(key)
	. = list()
	var/list/effects = SSmarket.station_events[key]
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/each = SSmarket.companies[ticker]
		reset_company(each)
		if(!isnull(effects[ticker]) || !isnull(effects[STOCK_ALL_COMPANIES]))
			. += each
	SSmarket.station_event_cooldowns.Cut()

/datum/unit_test/economy_trading/visible_events/proc/check_paths(list/watched, label, datum/round_event/started)
	TEST_ASSERT(length(watched), "[label]: нет задетых компаний")
	var/list/paths = list()
	for(var/datum/stock_company/each as anything in watched)
		paths[each] = list(each.price)
	for(var/tick_index in 1 to 30)
		SSmarket.tick_stocks()
		if(tick_index == 1 && started)
			started.start()
		for(var/datum/stock_company/each as anything in watched)
			var/list/path = paths[each]
			path += each.price
	for(var/datum/stock_company/each as anything in watched)
		var/ratio = best_ratio(paths[each])
		TEST_ASSERT(ratio <= 1.0001, "[label], [each.ticker]: цена растёт после видимого события ([ratio])")
		TEST_ASSERT(ratio < breakeven(), "[label], [each.ticker]: сделка окупается ([ratio], порог [breakeven()])")

/// Монте-Карло на волатильности из конфига: средний рост «купил в видимом состоянии - держал N тиков» не выше 1 с запасом в четыре стандартные ошибки и ниже порога окупаемости.
/datum/unit_test/economy_trading/monte_carlo/Run()
	rand_seed(4242)
	var/samples = 300
	var/list/holds = list(1, 10, 30)
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/each = SSmarket.companies[ticker]
		if(each.is_index)
			continue
		var/configured_volatility = each.volatility
		for(var/state in list("обычное", "после роста", "после падения", "после релиста"))
			var/list/sums = list()
			var/list/squares = list()
			for(var/sample in 1 to samples)
				reset_company(each)
				each.volatility = configured_volatility
				switch(state)
					if("после роста")
						each.apply_shock(0.25)
					if("после падения")
						each.apply_shock(-0.2)
					if("после релиста")
						each.price = each.base_price * STOCK_BANKRUPT_RATIO / 2
						each.tick()
						each.halted_until = world.time
						each.tick()
				var/start = each.price
				for(var/tick_index in 1 to 30)
					each.tick()
					if(tick_index in holds)
						var/ratio = each.price / start
						sums["[tick_index]"] += ratio
						squares["[tick_index]"] += ratio * ratio
			for(var/hold in holds)
				var/mean = sums["[hold]"] / samples
				var/stderr = sqrt(max(squares["[hold]"] / samples - mean * mean, 0) / samples)
				TEST_ASSERT(mean <= 1 + 4 * stderr && mean < breakeven(), "[ticker] [state], [hold] тиков: средний рост [mean] (ошибка [stderr])")
	rand_seed(world.realtime + world.timeofday)

/// Кулдаун сделок может быть нулевым, отрицательный, спред выше 100% и нулевой лимит позиции отвергаются.
/datum/unit_test/economy_trading_settings/Run()
	var/path = "data/unit_test_economy_stock.json"
	fdel(path)
	text2file("{\"settings\": {\"stock_trade_cooldown_seconds\": -5, \"stock_spread\": 101, \"stock_position_cap\": 0}}", path)
	var/datum/economy_settings/settings = new
	var/list/errors = settings.load(path)
	fdel(path)
	TEST_ASSERT_EQUAL(length(errors), 3, "Ошибки: кулдаун, спред, лимит ([jointext(errors, "; ")])")
	TEST_ASSERT_EQUAL(settings.stock_trade_cooldown_seconds, initial(settings.stock_trade_cooldown_seconds), "Отрицательный кулдаун принят")
	text2file("{\"settings\": {\"stock_trade_cooldown_seconds\": 0}}", path)
	errors = settings.load(path)
	fdel(path)
	TEST_ASSERT(!length(errors), "Нулевой кулдаун отвергнут: [jointext(errors, "; ")]")
	TEST_ASSERT_EQUAL(settings.stock_trade_cooldown_seconds, 0, "Нулевой кулдаун не применился")

/// Счёт трейдера, который запоминает сообщения на карту.
/datum/unit_test/economy_trading/proc/new_spy(money)
	var/datum/bank_account/econ_test_spy/trader = new("econ_test_spy_[length(traders) + 1]")
	traders += trader
	if(money)
		trader.credit(money, ECON_ADMIN)
	return trader

/// 100 × средняя доля базовой цены всех компаний, кроме индекса.
/datum/unit_test/economy_trading/proc/index_formula()
	var/total = 0
	var/count = 0
	for(var/ticker in SSmarket.companies)
		if(ticker == STOCK_INDEX_TICKER)
			continue
		var/datum/stock_company/each = SSmarket.companies[ticker]
		total += each.price / each.base_price
		count++
	return 100 * total / count

/datum/unit_test/economy_trading/proc/any_pack()
	for(var/pack_id in SSshuttle.supply_packs)
		return SSshuttle.supply_packs[pack_id]

/// Закупки станции у партнёра копят фонд дивидендов его компании, продажи - нет; выплата с зарплатой делит фонд по акциям целыми кредитами, остаток остаётся в фонде, деньги выпускаются причиной ECON_DIVIDEND; остановка и релист фонд не трогают.
/datum/unit_test/economy_trading/dividends/Run()
	var/datum/trade_partner/partner = SSmarket.get_partner(company.partner_id)
	TEST_ASSERT_NOTNULL(partner, "У AGRO нет партнёра")
	var/datum/supply_pack/pack = any_pack()
	partner.note_sale(1000)
	TEST_ASSERT_EQUAL(company.dividend_pool, 0, "Продажа партнёру пополнила фонд дивидендов")
	partner.note_purchase(pack, 1000)
	var/share = SSeconomy.settings.stock_dividend_share
	TEST_ASSERT(abs(company.dividend_pool - 1000 * share / 100) < 0.01, "Фонд после закупки на 1000 кр.: [company.dividend_pool]")
	company.dividend_pool = 50
	var/datum/bank_account/econ_test_spy/big = new_spy(10000)
	var/datum/bank_account/econ_test_spy/small = new_spy(10000)
	var/datum/bank_account/econ_test_spy/outsider = new_spy(10000)
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(big, "AGRO", 2), "Покупка двух акций")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(small, "AGRO", 1), "Покупка одной акции")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(outsider, "PRSP", 1), "Акция другой компании")
	var/list/outstanding = SSmarket.outstanding_shares()
	TEST_ASSERT_EQUAL(outstanding["AGRO"], 3, "Чужие акции AGRO на счетах мира")
	var/big_before = big.account_balance
	var/small_before = small.account_balance
	var/outsider_before = outsider.account_balance
	var/minted_before = SSeconomy.ledger.by_reason[ECON_DIVIDEND] || 0
	SSeconomy.run_payroll()
	TEST_ASSERT_EQUAL(big.account_balance - big_before, 33, "Две акции из трёх: 2/3 от 50 кр. вниз")
	TEST_ASSERT_EQUAL(small.account_balance - small_before, 16, "Одна акция из трёх: 1/3 от 50 кр. вниз")
	TEST_ASSERT_EQUAL(outsider.account_balance, outsider_before, "Держатель другой компании получил дивиденды AGRO")
	TEST_ASSERT(abs(company.dividend_pool - 1) < 0.01, "Остаток не остался в фонде: [company.dividend_pool]")
	TEST_ASSERT_EQUAL((SSeconomy.ledger.by_reason[ECON_DIVIDEND] || 0) - minted_before, 49, "Выплата не по причине дивидендов")
	var/datum/transaction/last = big.transaction_history[length(big.transaction_history)]
	TEST_ASSERT(last.reason == ECON_DIVIDEND && !last.counterparty_number, "Дивиденды не выпущены, а переведены: [last.reason], [last.counterparty_number]")
	TEST_ASSERT_EQUAL(big.card_messages[length(big.card_messages)], "Дивиденды [company.name] (AGRO): +33 кр. за 2 акции.", "Сообщение на карту")
	TEST_ASSERT_EQUAL(small.card_messages[length(small.card_messages)], "Дивиденды [company.name] (AGRO): +16 кр. за 1 акцию.", "Сообщение на карту одной акции")
	SSeconomy.run_payroll()
	TEST_ASSERT_EQUAL(big.account_balance - big_before, 33, "Остаток меньше кредита на держателя выплачен")
	TEST_ASSERT(abs(company.dividend_pool - 1) < 0.01, "Остаток фонда пропал: [company.dividend_pool]")
	company.halted_until = world.time + STOCK_HALT_TIME
	partner.note_purchase(pack, 1000)
	TEST_ASSERT(abs(company.dividend_pool - 1 - 1000 * share / 100) < 0.01, "Остановленная компания не копит фонд: [company.dividend_pool]")
	var/kept = company.dividend_pool
	company.halted_until = world.time
	SSmarket.tick_stocks()
	TEST_ASSERT(!company.is_halted(), "Повторный листинг")
	TEST_ASSERT(abs(company.dividend_pool - kept) < 0.01, "Релист сбросил фонд: [company.dividend_pool]")

/// Индекс сектора стоит 100 × среднюю долю базовой цены остальных компаний и следует за ними; события компании и станции, сорванные спецзаказы, продажи партнёрам, его собственные сделки и остановки его не двигают сверх формулы; событий ему не планируют.
/datum/unit_test/economy_trading/index_fund/Run()
	var/datum/stock_company/fund = SSmarket.get_company(STOCK_INDEX_TICKER)
	TEST_ASSERT(fund?.is_index, "Нет индекса сектора")
	TEST_ASSERT_EQUAL(fund.name, "Индекс сектора", "Название индекса")
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/each = SSmarket.companies[ticker]
		each.volatility = 0
	TEST_ASSERT(abs(fund.price - 100) < 0.01, "Все по базе, индекс [fund.price]")
	var/datum/stock_company/nt = SSmarket.get_company("NTRN")
	nt.set_price(nt.base_price * 3)
	company.set_price(company.base_price / 2)
	TEST_ASSERT(abs(fund.price - index_formula()) < 0.01, "Индекс [fund.price] после сдвига компаний, формула [index_formula()]")
	SSmarket.tick_stocks()
	TEST_ASSERT(abs(fund.history[length(fund.history)] - index_formula()) < 0.01, "Тик не записал индекс в историю")
	SSmarket.station_event_cooldowns.Cut()
	TEST_ASSERT(SSmarket.station_event("sector_boom"), "Бум не прошёл")
	TEST_ASSERT(abs(fund.price - index_formula()) < 0.01, "Индекс [fund.price] после бума, формула [index_formula()]")
	TEST_ASSERT_EQUAL(fund.event_mult, 1, "Шок события станции у индекса")
	var/before_event = fund.price
	SSmarket.schedule_company_event(fund, "merger", "тест", 0.5, 0)
	SSmarket.run_due_events()
	TEST_ASSERT(abs(fund.price - before_event) < 0.01, "Событие компании сдвинуло индекс: [before_event] -> [fund.price]")
	var/datum/trade_partner/partner = SSmarket.get_partner(company.partner_id)
	partner.note_sale(STOCK_TRADE_SCALE * 10)
	TEST_ASSERT(abs(fund.price - index_formula()) < 0.01, "Продажа партнёру: индекс [fund.price], формула [index_formula()]")
	SSmarket.company_event_chance = 100
	SSmarket.maybe_schedule_events()
	for(var/datum/market_event/event as anything in SSmarket.scheduled_events)
		TEST_ASSERT(event.company != fund, "Событие индексу в очереди")
	QDEL_LIST(SSmarket.scheduled_events)
	SSmarket.company_event_chance = 0
	var/datum/bank_account/trader = new_trader(10000)
	var/price = fund.price
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(trader, STOCK_INDEX_TICKER, 10), "Покупка индекса")
	var/cost = CEILING(price * 10 * (100 + SSeconomy.settings.stock_spread) / 100, 1)
	TEST_ASSERT_EQUAL(trader.account_balance, 10000 - cost - CEILING(cost * SSeconomy.settings.stock_fee / 100, 1), "Индекс покупается со спредом и комиссией")
	TEST_ASSERT(abs(fund.price - price) < 0.0001, "Своя сделка сдвинула индекс")
	TEST_ASSERT_NOTNULL(SSmarket.try_buy_shares(trader, STOCK_INDEX_TICKER, 1), "Кулдаун сделок по индексу")
	fund.halted_until = world.time + STOCK_HALT_TIME
	fund.price = STOCK_PRICE_MIN
	SSmarket.tick_stocks()
	TEST_ASSERT(!fund.is_halted() && abs(fund.price - index_formula()) < 0.01, "Индекс остановился или ушёл с формулы: [fund.price]")
	var/problem = SSmarket.press_release_problem(fund, TRUE)
	TEST_ASSERT(findtext(problem, "Индекс сектора"), "Фальшивый релиз об индексе: [problem]")

/// Заявки срабатывают на тике биржи ровно на пороге: покупка и стоп при цене не выше, фиксация - не ниже; исполняются обычной сделкой и снимаются с сообщением на карту. Кулдаун и остановленные торги держат заявку, отказ сделки снимает её с причиной.
/datum/unit_test/economy_trading/stock_orders/Run()
	var/datum/bank_account/econ_test_spy/trader = new_spy(10000)
	var/spread = SSeconomy.settings.stock_spread
	var/fee = SSeconomy.settings.stock_fee
	company.price = 50
	TEST_ASSERT_NULL(SSmarket.add_stock_order(trader, "AGRO", STOCK_ORDER_BUY_BELOW, 10, 40), "Заявка на покупку")
	SSmarket.tick_stocks()
	TEST_ASSERT(!trader.shares["AGRO"] && length(trader.stock_orders) == 1, "Покупка сработала выше порога")
	company.price = 40.01
	SSmarket.tick_stocks()
	TEST_ASSERT(!trader.shares["AGRO"], "Покупка сработала выше порога на копейку")
	company.price = 40
	SSmarket.tick_stocks()
	TEST_ASSERT_EQUAL(trader.shares["AGRO"], 10, "Покупка на пороге")
	TEST_ASSERT(!length(trader.stock_orders), "Исполненная заявка осталась")
	var/cost = CEILING(40 * 10 * (100 + spread) / 100, 1)
	TEST_ASSERT_EQUAL(trader.account_balance, 10000 - cost - CEILING(cost * fee / 100, 1), "Заявка купила по обычным правилам")
	TEST_ASSERT(findtext(trader.card_messages[length(trader.card_messages)], "куплено 10 шт. AGRO по 40 кр."), "Сообщение о покупке: [trader.card_messages[length(trader.card_messages)]]")

	TEST_ASSERT_NULL(SSmarket.add_stock_order(trader, "AGRO", STOCK_ORDER_SELL_BELOW, 10, 35), "Стоп")
	company.price = 35
	SSmarket.tick_stocks()
	TEST_ASSERT(trader.shares["AGRO"] == 10 && length(trader.stock_orders) == 1, "Кулдаун по компании снял или исполнил стоп")
	expire_cooldown(trader, "AGRO")
	company.halted_until = world.time + STOCK_HALT_TIME
	SSmarket.tick_stocks()
	TEST_ASSERT(trader.shares["AGRO"] == 10 && length(trader.stock_orders) == 1, "Остановленные торги сняли или исполнили стоп")
	company.halted_until = 0
	SSmarket.tick_stocks()
	TEST_ASSERT(!trader.shares["AGRO"] && !length(trader.stock_orders), "Стоп не продал на пороге")
	TEST_ASSERT(findtext(trader.card_messages[length(trader.card_messages)], "продано 10 шт. AGRO"), "Сообщение о продаже: [trader.card_messages[length(trader.card_messages)]]")

	expire_cooldown(trader, "AGRO")
	TEST_ASSERT_NULL(SSmarket.try_buy_shares(trader, "AGRO", 5), "Покупка под фиксацию")
	TEST_ASSERT_NULL(SSmarket.add_stock_order(trader, "AGRO", STOCK_ORDER_SELL_ABOVE, 5, 60), "Фиксация")
	expire_cooldown(trader, "AGRO")
	company.price = 59.99
	SSmarket.tick_stocks()
	TEST_ASSERT_EQUAL(trader.shares["AGRO"], 5, "Фиксация сработала ниже порога")
	company.price = 60
	SSmarket.tick_stocks()
	TEST_ASSERT(!trader.shares["AGRO"] && !length(trader.stock_orders), "Фиксация не продала на пороге")

	var/datum/bank_account/econ_test_spy/poor = new_spy(10)
	TEST_ASSERT_NULL(SSmarket.add_stock_order(poor, "AGRO", STOCK_ORDER_BUY_BELOW, 10, 40), "Заявка без денег ставится")
	company.price = 40
	SSmarket.tick_stocks()
	TEST_ASSERT(!length(poor.stock_orders) && !poor.shares["AGRO"], "Неисполнимая заявка осталась")
	TEST_ASSERT_EQUAL(poor.card_messages[length(poor.card_messages)], "Биржа: заявка «купить 10 шт. AGRO, если цена ≤ 40» снята. Недостаточно средств.", "Причина отказа на карту")

/// Ввод заявки проверяется: тикер, вид, целое количество, цена в коридоре компании, акции для продажи, лимит позиции, счёт и не больше STOCK_ORDERS_MAX заявок.
/datum/unit_test/economy_trading/stock_order_input/Run()
	var/datum/bank_account/trader = new_trader(10000)
	var/cap_count = round(SSeconomy.settings.stock_position_cap / company.base_price)
	for(var/list/bad as anything in list(
		list("ZZZZ", STOCK_ORDER_BUY_BELOW, 1, 40),
		list(null, STOCK_ORDER_BUY_BELOW, 1, 40),
		list("AGRO", "buy_now", 1, 40),
		list("AGRO", STOCK_ORDER_BUY_BELOW, 0, 40),
		list("AGRO", STOCK_ORDER_BUY_BELOW, 1.5, 40),
		list("AGRO", STOCK_ORDER_BUY_BELOW, -2, 40),
		list("AGRO", STOCK_ORDER_BUY_BELOW, "много", 40),
		list("AGRO", STOCK_ORDER_BUY_BELOW, cap_count + 1, 40),
		list("AGRO", STOCK_ORDER_BUY_BELOW, 1, 0),
		list("AGRO", STOCK_ORDER_BUY_BELOW, 1, -5),
		list("AGRO", STOCK_ORDER_BUY_BELOW, 1, company.base_price * STOCK_PRICE_MAX_RATIO + 1),
		list("AGRO", STOCK_ORDER_BUY_BELOW, 1, "дёшево"),
		list("AGRO", STOCK_ORDER_SELL_BELOW, 1, 40),
		list("AGRO", STOCK_ORDER_SELL_ABOVE, 1, 40),
	))
		TEST_ASSERT_NOTNULL(SSmarket.add_stock_order(trader, bad[1], bad[2], bad[3], bad[4]), "Принята заявка [json_encode(bad)]")
	TEST_ASSERT(!length(trader.stock_orders), "Отказ оставил заявку")
	TEST_ASSERT_NULL(SSmarket.add_stock_order(trader, "AGRO", STOCK_ORDER_BUY_BELOW, cap_count, 40), "Заявка ровно на лимит позиции")
	TEST_ASSERT_NULL(SSmarket.add_stock_order(trader, STOCK_INDEX_TICKER, STOCK_ORDER_BUY_BELOW, 1, "95.555"), "Заявка на индекс с ценой текстом")
	var/list/index_order = trader.stock_orders[2]
	TEST_ASSERT(abs(index_order["price"] - 95.56) < 0.001, "Цена заявки не округлена до сотых: [index_order["price"]]")
	for(var/i in 1 to STOCK_ORDERS_MAX - 2)
		TEST_ASSERT_NULL(SSmarket.add_stock_order(trader, "PRSP", STOCK_ORDER_BUY_BELOW, 1, 10), "Заявка [i + 2]")
	TEST_ASSERT_NOTNULL(SSmarket.add_stock_order(trader, "PRSP", STOCK_ORDER_BUY_BELOW, 1, 10), "Заявка сверх [STOCK_ORDERS_MAX]")
	TEST_ASSERT_EQUAL(length(trader.stock_orders), STOCK_ORDERS_MAX, "Число заявок")
	var/list/first = trader.stock_orders[1]
	TEST_ASSERT(SSmarket.cancel_stock_order(trader, first["id"]), "Снятие заявки")
	TEST_ASSERT(!SSmarket.cancel_stock_order(trader, first["id"]), "Повторное снятие")
	TEST_ASSERT_EQUAL(length(trader.stock_orders), STOCK_ORDERS_MAX - 1, "Снятая заявка осталась")
	var/datum/bank_account/frozen = new_trader(10000)
	frozen.state = ACCOUNT_FROZEN
	TEST_ASSERT_NOTNULL(SSmarket.add_stock_order(frozen, "AGRO", STOCK_ORDER_BUY_BELOW, 1, 40), "Заявка с замороженного счёта")
	TEST_ASSERT_NOTNULL(SSmarket.add_stock_order(SSeconomy.get_dep_account(ACCOUNT_CAR), "AGRO", STOCK_ORDER_BUY_BELOW, 1, 40), "Заявка из бюджета отдела")
	TEST_ASSERT_NOTNULL(SSmarket.add_stock_order(SSeconomy.cash_account, "AGRO", STOCK_ORDER_BUY_BELOW, 1, 40), "Заявка с системного счёта")
	TEST_ASSERT_NOTNULL(SSmarket.add_stock_order(null, "AGRO", STOCK_ORDER_BUY_BELOW, 1, 40), "Заявка без счёта")
