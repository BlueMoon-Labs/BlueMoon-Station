#define STOCK_MARKET_CLOSED_TEXT "Смена закончилась: биржа закрыта."

/// Текст отказа или null, если счёт может торговать акциями компании прямо сейчас.
/datum/controller/subsystem/market/proc/trade_guard(datum/bank_account/account, datum/stock_company/company)
	if(!account)
		return "Нет такого счёта."
	if(!company)
		return "Нет такой компании."
	if(SSeconomy.round_over())
		return STOCK_MARKET_CLOSED_TEXT
	if(!can_hold_stocks(account))
		return "С этого счёта нельзя торговать акциями."
	if(company.is_halted())
		return "Торги [company.ticker] остановлены."
	if(account.state == ACCOUNT_FROZEN)
		return "Счёт заморожен."
	if(trade_cooling_down(account, company.ticker))
		return "Слишком частые сделки по [company.ticker]."
	return null

/// Акциями торгуют личные счета и казна, но не бюджеты отделов и не системные счета.
/datum/controller/subsystem/market/proc/can_hold_stocks(datum/bank_account/account)
	return !istype(account, /datum/bank_account/system) && (!istype(account, /datum/bank_account/department) || account == SSeconomy.treasury())

/datum/controller/subsystem/market/proc/trade_cooling_down(datum/bank_account/account, ticker)
	var/last_trade = account.trade_cooldowns[ticker]
	return !isnull(last_trade) && world.time - last_trade < SSeconomy.settings.stock_trade_cooldown_seconds SECONDS

/datum/controller/subsystem/market/proc/position_cap(datum/bank_account/account)
	. = SSeconomy.settings.stock_position_cap
	if(account == SSeconomy.treasury())
		. *= SSeconomy.settings.stock_treasury_cap_mult

/// Сделка на value кр. сразу сдвигает цену в свою сторону.
/datum/controller/subsystem/market/proc/apply_trade_impact(datum/stock_company/company, value, is_buy)
	company.set_price(company.price * (1 + value / STOCK_TRADE_IMPACT_DEPTH * (is_buy ? 1 : -1)))

/// Обмен акций держателей при скачке цены вне торгов (листинг, сброс сектора): ratio - доля новой цены, которую стоила акция до скачка.
/datum/controller/subsystem/market/proc/consolidate_shares(datum/stock_company/company, ratio, reason = "Повторный листинг")
	var/ticker = company.ticker
	if(!ticker)
		return
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		var/held = account.shares[ticker]
		if(!held)
			continue
		var/kept = round(held * ratio)
		if(kept)
			account.shares[ticker] = kept
			account.bank_card_talk("[reason] [ticker]: ваши [held] акций обменяны на [kept] по новой цене.")
			continue
		var/lost = account.cost_basis[ticker]
		account.realized_stock_profit -= lost
		account.shares -= ticker
		account.cost_basis -= ticker
		account.bank_card_talk("[reason] [ticker]: ваши [held] акций стоили меньше одной новой и списаны, убыток [lost] кр.")

/datum/controller/subsystem/market/proc/try_buy_shares(datum/bank_account/account, ticker, count, mob/user)
	var/datum/stock_company/company = companies[ticker]
	. = trade_guard(account, company)
	if(.)
		return
	if(!isnum(count) || !(count >= 1))
		return "Неверное количество."
	count = round(count)
	var/cap = position_cap(account)
	if(((account.shares[ticker] || 0) + count) * max(company.price, company.base_price) > cap)
		return "Позиция превысит лимит [cap] кр.: акции считаются по цене не ниже базовой, [company.base_price] кр."
	var/cost = CEILING(company.price * count * (100 + SSeconomy.settings.stock_spread) / 100, 1)
	var/fee = CEILING(cost * SSeconomy.settings.stock_fee / 100, 1)
	if(!account.has_money(cost + fee))
		return "Недостаточно средств."
	if(!SSeconomy.move(account, SSeconomy.market_account, cost, ECON_STOCK_BUY, user, "Покупка [count] [ticker]"))
		return "Сделка не прошла."
	if(fee)
		account.debit(fee, ECON_STOCK_FEE, user, "Комиссия биржи")
	account.shares[ticker] = (account.shares[ticker] || 0) + count
	account.cost_basis[ticker] = (account.cost_basis[ticker] || 0) + cost + fee
	account.trade_cooldowns[ticker] = world.time
	var/price = company.price
	apply_trade_impact(company, cost, TRUE)
	SEND_SIGNAL(src, COMSIG_MARKET_STOCK_TRADE, account, ticker, count, price, TRUE, 0, user)
	return null

/// Держателям акций - сообщение на карту о скачке цены от STOCK_HOLDER_ALERT_MIN; заголовок новости не раскрывается, он выходит позже. Возвращает число уведомлённых счетов.
/datum/controller/subsystem/market/proc/alert_holders(datum/stock_company/company, price_before)
	. = 0
	if(!company || !(price_before > 0))
		return
	var/change = company.price / price_before - 1
	if(abs(change) < STOCK_HOLDER_ALERT_MIN)
		return
	var/percent = round(abs(change) * 100)
	var/signed = "[change > 0 ? "+" : "-"][percent]%"
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		var/held = account.shares[company.ticker]
		if(!held)
			continue
		account.bank_card_talk("Биржа: акции \"[company.name]\" [change > 0 ? "выросли" : "упали"] на [percent]%. Ваши [held] шт. стоят [round(company.price * held)] кр.", balloon = "[company.ticker] [signed]")
		.++

/// Держателям - почему торги компании встали и что будет с их акциями.
/datum/controller/subsystem/market/proc/alert_holders_halted(datum/stock_company/company)
	. = 0
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		var/held = account.shares[company.ticker]
		if(!held)
			continue
		account.bank_card_talk("Биржа: торги \"[company.name]\" остановлены на [STOCK_HALT_TIME / (1 MINUTES)] мин. - цена упала ниже [STOCK_BANKRUPT_RATIO * 100]% базовой. Потом компания вернётся на биржу по [STOCK_RELIST_RATIO * 100]% базовой, а ваши [held] шт. обменяют на меньшее число новых по цене остановки.", balloon = "[company.ticker] торги встали")
		.++

/datum/controller/subsystem/market
	/// Номер эвакуации за смену: растёт, когда шаттл снова вызывают после отзыва
	var/evac_wave = 0
	/// На прошлой проверке эвакуация уже шла
	var/evac_was_underway = FALSE

/datum/bank_account
	/// Номер эвакуации, о которой держатель акций уже знает с карты
	var/stock_evac_wave = 0
	/// Часть realized_stock_profit от продажи по рынку в конце смены: её не засчитывают цели предателя
	var/stock_autosold_profit = 0
	/// Сколько зачислено продажей по рынку в конце смены: выкачка счёта главы его не считает
	var/stock_autosold_credited = 0

/// Прибыль на бирже от своих сделок, без продажи по рынку в конце смены.
/datum/bank_account/proc/traded_stock_profit()
	return realized_stock_profit - stock_autosold_profit

/// Эвакуация идёт: шаттл вызван, стоит у станции или улетает; продать акции ещё можно.
/datum/controller/subsystem/market/proc/evac_underway(mode = SSshuttle.emergency?.mode)
	var/static/list/evac_modes = list(SHUTTLE_CALL, SHUTTLE_DOCKED, SHUTTLE_IGNITING, SHUTTLE_STRANDED, SHUTTLE_ESCAPE)
	return !SSeconomy.round_over() && (mode in evac_modes)

/// Сообщение карты дойдёт до holder: он жив, слышит и не выключил сообщения карты.
/datum/bank_account/proc/card_reaches_holder(mob/holder)
	return ismob(holder) && holder.stat != DEAD && holder.can_hear() && card_talk_reaches(holder)

/// Карту счёта держит живой, кто услышит её сообщение.
/datum/bank_account/proc/card_holder_listening()
	for(var/obj/card in bank_cards)
		if(card_reaches_holder(recursive_loc_check(card, /mob)))
			return TRUE
	return FALSE

/// Пока идёт эвакуация, держатель акций один раз за каждый вызов шаттла узнаёт с карты, что в конце смены акции продадутся по рынку; кто сейчас не услышит, узнает позже. За казну узнают капитаны. Возвращает число предупреждённых.
/datum/controller/subsystem/market/proc/warn_holders_before_evac(mode = SSshuttle.emergency?.mode)
	. = 0
	var/underway = evac_underway(mode)
	if(underway && !evac_was_underway)
		evac_wave++
	evac_was_underway = underway
	if(!underway)
		return
	var/datum/bank_account/treasury = SSeconomy.treasury()
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		if(account == treasury || account.stock_evac_wave == evac_wave || !length(account.shares) || !account.card_holder_listening())
			continue
		account.stock_evac_wave = evac_wave
		account.bank_card_talk(evac_warning_text(account, "ваши непроданные акции"), balloon = "акции: эвакуация")
		.++
	if(treasury && treasury.stock_evac_wave != evac_wave && length(treasury.shares))
		var/text = evac_warning_text(treasury, "непроданные акции казны")
		for(var/mob/living/holder as anything in GLOB.alive_mob_list)
			if(!isliving(holder) || !econ_can_trade_treasury(holder))
				continue
			var/obj/item/card/id/card = holder.get_idcard(TRUE)
			var/datum/bank_account/personal = card.registered_account
			if(!personal || !personal.card_reaches_holder(holder))
				continue
			treasury.stock_evac_wave = evac_wave
			personal.bank_card_talk(text, balloon = "акции казны: эвакуация")
			.++
	if(.)
		log_econ("Эвакуация [evac_wave]: [.] держателям акций напомнили, что в конце смены акции продадутся по рынку")

/// Предупреждение об эвакуации: сколько стоят акции счёта и что даст их продажа сейчас.
/datum/controller/subsystem/market/proc/evac_warning_text(datum/bank_account/account, subject)
	var/list/quote = sell_off_quote(account)
	var/result = quote[1] - quote[2]
	var/outcome = result > 0 ? "+[result] кр. прибыли" : (result < 0 ? "[-result] кр. убытка" : "ни прибыли, ни убытка")
	. = "Биржа: идёт эвакуация. В конце смены [subject] продадутся по рыночной цене. Сейчас они стоят [portfolio_value(account)] кр., продав сейчас, вы зафиксируете [outcome]. Хотите выбрать момент сами - продайте раньше."
	if(quote[3])
		. += " Акции остановленных компаний не продаются."

/// Что даст продажа count акций сейчас: list(выручка после спреда, комиссия).
/datum/controller/subsystem/market/proc/sale_amounts(datum/stock_company/company, count)
	var/proceeds = round(company.price * count * (100 - SSeconomy.settings.stock_spread) / 100)
	return list(proceeds, CEILING(proceeds * SSeconomy.settings.stock_fee / 100, 1))

/// Продажа всех акций счёта сейчас: list(выручка за вычетом комиссии, потрачено на эти акции, сколько позиций на остановленных торгах).
/datum/controller/subsystem/market/proc/sell_off_quote(datum/bank_account/account)
	var/net = 0
	var/basis = 0
	var/halted = 0
	for(var/ticker in account.shares)
		var/datum/stock_company/company = companies[ticker]
		if(!company || company.is_halted())
			halted++
			continue
		var/list/amounts = sale_amounts(company, account.shares[ticker])
		net += amounts[1] - amounts[2]
		basis += account.cost_basis[ticker]
	return list(net, basis, halted)

/// Колбэк конца раунда через глобальный proc: после Recover() он попадает в новый экземпляр SSmarket.
/proc/market_sell_off_shares()
	SSmarket.sell_off_shares()

/// Конец смены: непроданные акции продаются по рыночной цене со спредом и комиссией, как обычная продажа, но без сдвига цены и без засчёта в цели предателя. Остановленные торги и замороженные счета пропускаются. Возвращает число счетов, у которых что-то продано.
/datum/controller/subsystem/market/proc/sell_off_shares()
	. = 0
	var/total = 0
	var/total_profit = 0
	var/skipped = 0
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		if(!length(account.shares) || !can_hold_stocks(account))
			continue
		if(account.state == ACCOUNT_FROZEN)
			skipped += length(account.shares)
			continue
		account.stock_orders.Cut()
		var/list/sold = list()
		var/credited = 0
		for(var/ticker in account.shares.Copy())
			var/datum/stock_company/company = companies[ticker]
			if(!company || company.is_halted())
				skipped++
				continue
			var/held = account.shares[ticker]
			var/list/amounts = sale_amounts(company, held)
			if(amounts[1] && !SSeconomy.move(SSeconomy.market_account, account, amounts[1], ECON_STOCK_SELL, null, "Конец смены: продажа [held] [ticker]"))
				skipped++
				continue
			if(amounts[2])
				account.debit(amounts[2], ECON_STOCK_FEE, null, "Комиссия биржи")
			var/realized = amounts[1] - amounts[2] - account.cost_basis[ticker]
			account.realized_stock_profit += realized
			account.stock_autosold_profit += realized
			account.shares -= ticker
			account.cost_basis -= ticker
			credited += amounts[1] - amounts[2]
			account.stock_autosold_credited += amounts[1] - amounts[2]
			total_profit += realized
			sold += "[held] [ticker]"
		if(!length(sold))
			continue
		total += credited
		.++
		account.bank_card_talk("Биржа: смена закончилась, непроданные акции проданы по рыночной цене: [jointext(sold, ", ")], зачислено [credited] кр.", balloon = "акции проданы")
	if(. || skipped)
		log_econ("Конец смены: непроданные акции [.] счетов проданы по рынку на [total] кр., итог держателей [total_profit > 0 ? "+" : ""][total_profit] кр.; не продано позиций (остановленные торги, замороженные счета): [skipped]")

/// Продать всё с одного счёта обычными сделками; остановленные торги и кулдаун пропускаются с объяснением. Текст ответа окну.
/datum/controller/subsystem/market/proc/sell_all_shares(datum/bank_account/account, mob/user)
	if(!account)
		return "Нет банковского счёта."
	if(SSeconomy.round_over())
		return STOCK_MARKET_CLOSED_TEXT
	if(account.state == ACCOUNT_FROZEN)
		return "Счёт заморожен: продать нельзя."
	if(!length(account.shares))
		return "Продавать нечего: акций на счёте нет."
	var/balance_before = account.account_balance
	var/list/sold = list()
	var/list/skipped = list()
	for(var/ticker in account.shares.Copy())
		var/held = account.shares[ticker]
		var/error = try_sell_shares(account, ticker, held, user)
		if(error)
			skipped += error
		else
			sold += "[held] [ticker]"
	. = list()
	if(length(sold))
		. += "Продано [jointext(sold, ", ")] на [account.account_balance - balance_before] кр. с учётом спреда и комиссии."
	if(length(skipped))
		. += "Не продано: [jointext(skipped, " ")]"
	return jointext(., " ")

/// Сколько акций можно купить одной сделкой: в пределах лимита позиции и денег на счёте со спредом и комиссией.
/datum/controller/subsystem/market/proc/max_buy_count(datum/bank_account/account, datum/stock_company/company)
	if(!account || !company || company.is_halted())
		return 0
	var/spread = SSeconomy.settings.stock_spread
	var/fee_percent = SSeconomy.settings.stock_fee
	var/by_cap = round(position_cap(account) / max(company.price, company.base_price)) - (account.shares[company.ticker] || 0)
	var/by_money = round(account.account_balance / (company.price * (100 + spread) / 100 * (100 + fee_percent) / 100))
	. = max(0, min(by_cap, by_money))
	// Цена и комиссия округляются вверх: число из деления может оказаться на пару акций дороже счёта
	while(. > 0)
		var/cost = CEILING(company.price * . * (100 + spread) / 100, 1)
		if(cost + CEILING(cost * fee_percent / 100, 1) <= account.account_balance)
			break
		.--

/datum/controller/subsystem/market/proc/try_sell_shares(datum/bank_account/account, ticker, count, mob/user)
	var/datum/stock_company/company = companies[ticker]
	. = trade_guard(account, company)
	if(.)
		return
	var/held = account.shares[ticker] || 0
	if(!isnum(count) || !(count >= 1) || round(count) > held)
		return "Неверное количество."
	count = round(count)
	var/list/amounts = sale_amounts(company, count)
	var/proceeds = amounts[1]
	var/fee = amounts[2]
	if(proceeds && !SSeconomy.move(SSeconomy.market_account, account, proceeds, ECON_STOCK_SELL, user, "Продажа [count] [ticker]"))
		return "Сделка не прошла."
	if(fee)
		account.debit(fee, ECON_STOCK_FEE, user, "Комиссия биржи")
	var/basis_part = count == held ? account.cost_basis[ticker] : round(account.cost_basis[ticker] * count / held)
	var/realized = proceeds - fee - basis_part
	account.realized_stock_profit += realized
	if(count == held)
		account.shares -= ticker
		account.cost_basis -= ticker
	else
		account.shares[ticker] = held - count
		account.cost_basis[ticker] -= basis_part
	account.trade_cooldowns[ticker] = world.time
	var/price = company.price
	apply_trade_impact(company, proceeds, FALSE)
	SEND_SIGNAL(src, COMSIG_MARKET_STOCK_TRADE, account, ticker, count, price, FALSE, realized, user)
	return null

/datum/controller/subsystem/market/proc/portfolio_value(datum/bank_account/account)
	. = 0
	for(var/ticker in account.shares)
		var/datum/stock_company/company = companies[ticker]
		if(company)
			. += round(company.price * account.shares[ticker])

/// тикер -> сколько акций на всех счетах.
/datum/controller/subsystem/market/proc/outstanding_shares()
	. = list()
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		for(var/ticker in account.shares)
			.[ticker] += account.shares[ticker]

/// Фонд дивидендов каждой компании делится между держателями по числу акций, целыми кредитами; остаток копится дальше. Деньги закупки импорт уже сжёг, выплата - эмиссия.
/datum/controller/subsystem/market/proc/pay_dividends()
	var/list/outstanding = outstanding_shares()
	for(var/ticker in companies)
		var/datum/stock_company/company = companies[ticker]
		var/total = outstanding[ticker]
		if(company.dividend_pool < 1 || !total)
			continue
		var/pool = company.dividend_pool
		var/paid = 0
		var/holders = 0
		for(var/number in SSeconomy.accounts_by_number)
			var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
			var/held = account.shares[ticker]
			if(!(held > 0))
				continue
			var/amount = round(pool * held / total)
			if(amount < 1 || !SSeconomy.move(null, account, amount, ECON_DIVIDEND, null, "Дивиденды [ticker]"))
				continue
			paid += amount
			holders++
			account.bank_card_talk("Дивиденды [company.name] ([ticker]): +[amount] кр. за [held] [ru_plural(held, "акцию", "акции", "акций")].", quiet = TRUE)
		company.dividend_pool -= paid
		if(paid)
			log_econ("Дивиденды [ticker]: [paid] кр. [holders] держателям, в фонде осталось [round(company.dividend_pool, 0.01)] кр.")

/// Ставит заявку на счёт; текст отказа или null.
/datum/controller/subsystem/market/proc/add_stock_order(datum/bank_account/account, ticker, side, count, trigger)
	if(!account)
		return "Нет банковского счёта."
	if(SSeconomy.round_over())
		return STOCK_MARKET_CLOSED_TEXT
	if(!can_hold_stocks(account))
		return "С этого счёта нельзя торговать акциями."
	if(account.state == ACCOUNT_FROZEN)
		return "Счёт заморожен."
	if(length(account.stock_orders) >= STOCK_ORDERS_MAX)
		return "Заявок не больше [STOCK_ORDERS_MAX] на счёт: снимите одну из старых."
	var/datum/stock_company/company = istext(ticker) ? companies[ticker] : null
	if(!company)
		return "Нет такой компании."
	if(!(side in list(STOCK_ORDER_BUY_BELOW, STOCK_ORDER_SELL_BELOW, STOCK_ORDER_SELL_ABOVE)))
		return "Неверный вид заявки."
	if(istext(count))
		count = text2num(count)
	if(!isnum(count) || !(count >= 1) || round(count) != count)
		return "Количество - целое число от 1."
	var/held = account.shares[ticker] || 0
	if(side == STOCK_ORDER_BUY_BELOW)
		var/fits = round(position_cap(account) / company.base_price) - held
		if(count > fits)
			return fits > 0 ? "В лимит позиции поместится не больше [fits] шт. [ticker]." : "Позиция [ticker] уже на лимите."
	else if(count > held)
		return held ? "На счёте только [held] шт. [ticker]." : "Акций [ticker] на счёте нет."
	if(istext(trigger))
		trigger = text2num(trigger)
	var/price_max = round(company.base_price * STOCK_PRICE_MAX_RATIO, 0.01)
	if(!isnum(trigger) || !(trigger >= STOCK_PRICE_MIN) || trigger > price_max)
		return "Цена срабатывания - от [STOCK_PRICE_MIN] до [price_max] кр."
	account.stock_order_serial++
	account.stock_orders += list(list("id" = account.stock_order_serial, "ticker" = ticker, "side" = side, "count" = count, "price" = round(trigger, 0.01)))
	return null

/datum/controller/subsystem/market/proc/cancel_stock_order(datum/bank_account/account, id)
	if(!account)
		return FALSE
	if(istext(id))
		id = text2num(id)
	for(var/list/order as anything in account.stock_orders)
		if(order["id"] == id)
			account.stock_orders -= list(order)
			return TRUE
	return FALSE

/datum/controller/subsystem/market/proc/stock_order_due(list/order, price)
	switch(order["side"])
		if(STOCK_ORDER_BUY_BELOW, STOCK_ORDER_SELL_BELOW)
			return price <= order["price"] + STOCK_PRICE_EPSILON
		if(STOCK_ORDER_SELL_ABOVE)
			return price >= order["price"] - STOCK_PRICE_EPSILON
	return FALSE

/// Заявки после смены цен: сработавшая исполняется обычной сделкой и снимается, отказ снимает её с объяснением на карту; кулдаун по компании и остановленные торги ждут следующего тика.
/datum/controller/subsystem/market/proc/run_stock_orders()
	if(SSeconomy.round_over())
		return
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		if(!length(account.stock_orders))
			continue
		for(var/list/order as anything in account.stock_orders.Copy())
			run_stock_order(account, order)

/datum/controller/subsystem/market/proc/run_stock_order(datum/bank_account/account, list/order)
	var/ticker = order["ticker"]
	var/datum/stock_company/company = companies[ticker]
	if(!company)
		account.stock_orders -= list(order)
		account.bank_card_talk("Биржа: заявка \"[econ_stock_order_text(order)]\" снята. Компании больше нет на бирже.")
		return
	if(company.is_halted() || trade_cooling_down(account, ticker) || !stock_order_due(order, company.price))
		return
	var/is_buy = order["side"] == STOCK_ORDER_BUY_BELOW
	var/count = is_buy ? order["count"] : min(order["count"], account.shares[ticker] || 0)
	var/price = company.price
	var/balance_before = account.account_balance
	var/error = "Акций [ticker] на счёте больше нет."
	if(count >= 1)
		error = is_buy ? try_buy_shares(account, ticker, count) : try_sell_shares(account, ticker, count)
	account.stock_orders -= list(order)
	if(error)
		account.bank_card_talk("Биржа: заявка \"[econ_stock_order_text(order)]\" снята. [error]", balloon = "заявка [ticker] снята")
		return
	var/total = abs(account.account_balance - balance_before)
	account.bank_card_talk("Биржа: заявка исполнена, [is_buy ? "куплено" : "продано"] [count] шт. [ticker] по [round(price, 0.01)] кр., [is_buy ? "списано" : "зачислено"] [total] кр. с учётом спреда и комиссии.", balloon = "[ticker] [is_buy ? "куплено" : "продано"] [count] шт.")

/proc/econ_stock_order_text(list/order)
	switch(order["side"])
		if(STOCK_ORDER_BUY_BELOW)
			return "купить [order["count"]] шт. [order["ticker"]], если цена ≤ [order["price"]]"
		if(STOCK_ORDER_SELL_BELOW)
			return "продать [order["count"]] шт. [order["ticker"]], если цена ≤ [order["price"]]"
	return "продать [order["count"]] шт. [order["ticker"]], если цена ≥ [order["price"]]"

/// Строки экономики для итогов раунда.
/proc/econ_market_report()
	var/datum/bank_account/best
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts)
		if(account.realized_stock_profit > (best ? best.realized_stock_profit : 0))
			best = account
	. = list("<span class='header'>Экономика смены</span>")
	. += "NT выпустило в оборот [num2text(SSeconomy.ledger.minted, ECON_TEXT_DIGITS)] кр., из оборота ушло [num2text(SSeconomy.ledger.burned, ECON_TEXT_DIGITS)] кр."
	. += econ_outpost_income_report()
	if(best)
		. += "Лучший трейдер смены: <b>[best.account_holder]</b>, прибыль [num2text(best.realized_stock_profit, ECON_TEXT_DIGITS)] кр."
	var/list/worked = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		if(abs(company.work_boost) >= STOCK_MOVE_MIN)
			worked += "[company.name] [SSmarket.signed_percent(round(company.work_boost * 100, 0.1))]"
	if(length(worked))
		. += "Работа отделов сдвинула акции: [jointext(worked, ", ")]."

#undef STOCK_MARKET_CLOSED_TEXT
