/// Биржа сектора: котировки и торговля акциями с личного счёта, у капитана - и из казны.
/datum/computer_file/program/stock_exchange
	filename = "stocks"
	filedesc = "Биржа"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "stocks"
	extended_desc = "Котировки компаний сектора и торговля акциями с личного счёта; капитан может торговать и из казны станции."
	requires_ntnet = TRUE
	usage_flags = PROGRAM_ALL
	size = 5
	tgui_id = "NtosStockExchange"
	program_icon = "chart-line"
	/// REF пользователя -> ответ на его последнее действие; на терминале окно открывают разные люди
	var/list/messages = list()
	/// REF пользователей, включивших торговлю из казны; действует, только пока у пользователя есть право
	var/list/treasury_users = list()

/// Из казны торгует только капитан: доступ капитана на ID-карте, а не любое право управлять казной.
/proc/econ_can_trade_treasury(mob/living/user)
	if(!isliving(user))
		return FALSE
	var/obj/item/card/id/card = user.get_idcard(TRUE)
	return !!card && (ACCESS_CAPTAIN in card.GetAccess())

/datum/computer_file/program/stock_exchange/proc/trading_account(mob/living/user)
	if((REF(user) in treasury_users) && econ_can_trade_treasury(user))
		return SSeconomy.treasury()
	return econ_account_of(user)

/datum/computer_file/program/stock_exchange/proc/forget_user(mob/user)
	messages -= REF(user)
	treasury_users -= REF(user)

/datum/computer_file/program/stock_exchange/ui_static_data(mob/user)
	RegisterSignal(SSmarket, COMSIG_MARKET_STOCKS_TICKED, PROC_REF(on_stocks_ticked), override = TRUE)
	return stocks_static_data()

/// История котировок меняется только на тике биржи и уходит в окна статикой; без открытых окон программа отписывается.
/datum/computer_file/program/stock_exchange/proc/on_stocks_ticked(datum/source)
	SIGNAL_HANDLER
	if(!length(SStgui.open_uis_by_src[REF(src)]))
		UnregisterSignal(source, COMSIG_MARKET_STOCKS_TICKED)
		return
	INVOKE_ASYNC(src, TYPE_PROC_REF(/datum, update_static_data_for_all_viewers))

/datum/computer_file/program/stock_exchange/ui_data(mob/user)
	return get_header_data() + stocks_data(user)

/datum/computer_file/program/stock_exchange/ui_close(mob/user)
	. = ..()
	forget_user(user)

/datum/computer_file/program/stock_exchange/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return stocks_act(usr, action, params)

/// Правила биржи для справки окна и история котировок.
/datum/computer_file/program/stock_exchange/proc/stocks_static_data()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/list/histories = list()
	var/list/drivers = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		histories[ticker] = company.history
		drivers[ticker] = company.price_drivers()
	var/event_min = 0
	var/event_max = 0
	for(var/list/template as anything in SSmarket.company_event_templates)
		event_min = min(event_min, template["effect"])
		event_max = max(event_max, template["effect"])
	return list(
		"history" = histories,
		"drivers" = drivers,
		"common_drivers" = market_common_drivers(),
		"event_min" = round(event_min * 100, 0.1),
		"event_max" = round(event_max * 100, 0.1),
		"station_event_cooldown" = STOCK_STATION_EVENT_COOLDOWN / (1 MINUTES),
		"fee" = settings.stock_fee,
		"spread" = settings.stock_spread,
		"cooldown" = settings.stock_trade_cooldown_seconds,
		"personal_cap" = settings.stock_position_cap,
		"treasury_cap_mult" = settings.stock_treasury_cap_mult,
		"halt_ratio" = STOCK_BANKRUPT_RATIO * 100,
		"halt_minutes" = STOCK_HALT_TIME / (1 MINUTES),
		"relist_ratio" = STOCK_RELIST_RATIO * 100,
		"news_channel" = MARKET_NEWS_CHANNEL,
		"news_delay" = SSmarket.news_flash_minutes,
		"refute_minutes" = settings.press_release_refute_minutes,
		"persist_decay" = SSmarket.persist_decay,
		"dividend_share" = settings.stock_dividend_share,
		"payroll_minutes" = round(settings.payroll_interval_ticks * SSeconomy.wait / (1 MINUTES), 1),
		"orders_max" = STOCK_ORDERS_MAX,
	)

/datum/computer_file/program/stock_exchange/proc/stocks_data(mob/living/user)
	var/datum/bank_account/account = trading_account(user)
	var/is_treasury = !!account && account == SSeconomy.treasury()
	var/list/companies = list()
	var/list/cooldowns = list()
	var/list/last_trades = account ? account.trade_cooldowns : list()
	var/list/outstanding = SSmarket.outstanding_shares()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		var/list/entry = company.ui_entry()
		entry -= "history"
		entry["base_price"] = company.base_price
		entry["max_buy"] = SSmarket.max_buy_count(account, company)
		entry["index"] = company.is_index
		entry["dividend_pool"] = round(company.dividend_pool)
		entry["dividend_per_share"] = round(company.dividend_pool / max(outstanding[ticker], 1), 0.01)
		companies += list(entry)
		var/last_trade = last_trades[ticker]
		if(!isnull(last_trade))
			var/left = CEILING((last_trade + SSeconomy.settings.stock_trade_cooldown_seconds SECONDS - world.time) / (1 SECONDS), 1)
			if(left > 0)
				cooldowns[ticker] = left
	return list(
		"companies" = companies,
		"has_account" = !!account,
		"account_name" = is_treasury ? ACCOUNT_CMD_NAME : account?.account_holder,
		"holdings" = account ? account.shares.Copy() : list(),
		"cooldowns" = cooldowns,
		"balance" = account ? account.account_balance : 0,
		"portfolio" = account ? SSmarket.portfolio_value(account) : 0,
		"realized" = account ? account.realized_stock_profit : 0,
		"frozen" = account?.state == ACCOUNT_FROZEN,
		"can_treasury" = econ_can_trade_treasury(user),
		"using_treasury" = is_treasury,
		"message" = messages[REF(user)] || "",
		"position_cap" = account ? SSmarket.position_cap(account) : SSeconomy.settings.stock_position_cap,
		"orders" = account ? account.stock_orders.Copy() : list(),
	)

/datum/computer_file/program/stock_exchange/proc/stocks_act(mob/living/user, action, list/params)
	if(!isliving(user) || !islist(params))
		return FALSE
	var/user_ref = REF(user)
	switch(action)
		if("buy", "sell")
			var/ticker = params["ticker"]
			var/count = params["count"]
			if(istext(count) && count != "max")
				count = text2num(count)
			if(!istext(ticker) || !(isnum(count) || count == "max"))
				messages[user_ref] = "Неверная заявка."
				return TRUE
			var/datum/bank_account/account = trading_account(user)
			if(!account)
				messages[user_ref] = "Нет банковского счёта."
				return TRUE
			if(count == "max")
				count = action == "buy" ? SSmarket.max_buy_count(account, SSmarket.get_company(ticker)) : (account.shares[ticker] || 0)
				if(count < 1 && action == "buy")
					messages[user_ref] = "Купить нечего: позиция упёрлась в лимит или не хватает денег."
					return TRUE
			var/balance_before = account.account_balance
			var/is_buy = action == "buy"
			var/error = is_buy ? SSmarket.try_buy_shares(account, ticker, count, user) : SSmarket.try_sell_shares(account, ticker, count, user)
			if(error)
				messages[user_ref] = error
				return TRUE
			var/total = abs(account.account_balance - balance_before)
			messages[user_ref] = "[is_buy ? "Куплено" : "Продано"] [round(count)] [ticker] [is_buy ? "за" : "на"] [total] кр. с учётом спреда и комиссии."
			return TRUE
		if("add_order")
			var/datum/bank_account/account = trading_account(user)
			var/error = SSmarket.add_stock_order(account, params["ticker"], params["side"], params["count"], params["price"])
			if(error)
				messages[user_ref] = error
				return TRUE
			var/list/order = account.stock_orders[length(account.stock_orders)]
			messages[user_ref] = "Заявка принята: [econ_stock_order_text(order)]. Проверяется раз в минуту после смены цен."
			return TRUE
		if("cancel_order")
			var/datum/bank_account/account = trading_account(user)
			messages[user_ref] = SSmarket.cancel_stock_order(account, params["id"]) ? "Заявка снята." : "Такой заявки уже нет."
			return TRUE
		if("use_treasury")
			if(!econ_can_trade_treasury(user))
				treasury_users -= user_ref
				messages[user_ref] = "Из казны торгует только капитан."
				return TRUE
			if(params["value"])
				treasury_users |= user_ref
			else
				treasury_users -= user_ref
			messages -= user_ref
			return TRUE
	return FALSE
