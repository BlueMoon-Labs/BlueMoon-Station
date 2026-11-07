/// Текст отказа или null, если счёт может торговать акциями компании прямо сейчас.
/datum/controller/subsystem/market/proc/trade_guard(datum/bank_account/account, datum/stock_company/company)
	if(!account)
		return "Нет такого счёта."
	if(!company)
		return "Нет такой компании."
	if(istype(account, /datum/bank_account/system) || (istype(account, /datum/bank_account/department) && account != SSeconomy.treasury()))
		return "С этого счёта нельзя торговать акциями."
	if(company.is_halted())
		return "Торги [company.ticker] остановлены."
	if(account.state == ACCOUNT_FROZEN)
		return "Счёт заморожен."
	var/last_trade = account.trade_cooldowns[company.ticker]
	if(!isnull(last_trade) && world.time - last_trade < SSeconomy.settings.stock_trade_cooldown_seconds SECONDS)
		return "Слишком частые сделки по [company.ticker]."
	return null

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
		account.bank_card_talk("Биржа: акции «[company.name]» [change > 0 ? "выросли" : "упали"] на [percent]%. Ваши [held] шт. стоят [round(company.price * held)] кр.", balloon = "[company.ticker] [signed]")
		.++

/// Держателям - почему торги компании встали и что будет с их акциями.
/datum/controller/subsystem/market/proc/alert_holders_halted(datum/stock_company/company)
	. = 0
	for(var/number in SSeconomy.accounts_by_number)
		var/datum/bank_account/account = SSeconomy.accounts_by_number[number]
		var/held = account.shares[company.ticker]
		if(!held)
			continue
		account.bank_card_talk("Биржа: торги «[company.name]» остановлены на [STOCK_HALT_TIME / (1 MINUTES)] мин. - цена упала ниже [STOCK_BANKRUPT_RATIO * 100]% базовой. Потом компания вернётся на биржу по [STOCK_RELIST_RATIO * 100]% базовой, а ваши [held] шт. обменяют на меньшее число новых по цене остановки.", balloon = "[company.ticker] торги встали")
		.++

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
	var/proceeds = round(company.price * count * (100 - SSeconomy.settings.stock_spread) / 100)
	var/fee = CEILING(proceeds * SSeconomy.settings.stock_fee / 100, 1)
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

/// Строки экономики для итогов раунда.
/proc/econ_market_report()
	var/datum/bank_account/best
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts)
		if(account.realized_stock_profit > (best ? best.realized_stock_profit : 0))
			best = account
	. = list("<span class='header'>Экономика смены</span>")
	. += "NT выпустило в оборот [num2text(SSeconomy.ledger.minted, ECON_TEXT_DIGITS)] кр., из оборота ушло [num2text(SSeconomy.ledger.burned, ECON_TEXT_DIGITS)] кр."
	if(best)
		. += "Лучший трейдер смены: <b>[best.account_holder]</b>, прибыль [num2text(best.realized_stock_profit, ECON_TEXT_DIGITS)] кр."
