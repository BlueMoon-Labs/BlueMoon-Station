GLOBAL_LIST_INIT(econ_category_names, list(
	ECON_CAT_WAGE = "Зарплаты",
	ECON_CAT_WORK = "Оплата работы",
	ECON_CAT_GRANT = "Гранты и подъёмные",
	ECON_CAT_CONTRACT = "Контракты",
	ECON_CAT_TRADE = "Торговля",
	ECON_CAT_PURCHASE = "Покупки",
	ECON_CAT_TIP = "Чаевые",
	ECON_CAT_TAX = "Налог",
	ECON_CAT_TRANSFER = "Переводы",
	ECON_CAT_FINE = "Штрафы",
	ECON_CAT_STOCK = "Биржа",
	ECON_CAT_CASH = "Наличные",
	ECON_CAT_CRIME = "Преступления",
	ECON_CAT_ADMIN = "Администрация",
	ECON_CAT_EVENT = "События",
	ECON_CAT_MISC = "Прочее",
))

/// Ошибки последней перечитки economy.json из админ-панели, общие для всех админов
GLOBAL_LIST_EMPTY(economy_config_errors)
GLOBAL_VAR(economy_config_reloaded_at)

/client/proc/economy_panel()
	set category = "Admin.Events"
	set name = "Economy Panel"
	if(!check_rights(R_ADMIN))
		return
	var/datum/economy_panel/panel = new
	panel.ui_interact(mob)

/datum/economy_panel
	/// Файл, который перечитывает reload_config
	var/config_path = ECONOMY_CONFIG_PATH
	var/message = ""

/datum/economy_panel/ui_state(mob/user)
	return GLOB.admin_state

/datum/economy_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "EconomyAdmin")
		ui.open()

/datum/economy_panel/ui_close(mob/user)
	qdel(src)

/datum/economy_panel/ui_data(mob/user)
	return list(
		"message" = message,
		"tax_rate" = SSeconomy.tax_rate,
		"state" = SSeconomy.economy_state,
		"minted" = SSeconomy.ledger.minted,
		"burned" = SSeconomy.ledger.burned,
		"price_index" = round(SSeconomy.price_index(), 0.01),
	)

/datum/economy_panel/ui_static_data(mob/user)
	return panel_data()

/datum/economy_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	if(!panel_act(ui.user, action, params))
		return FALSE
	update_static_data(ui.user, ui)
	return TRUE

/datum/economy_panel/proc/panel_data()
	var/list/market = econ_cargo_market_data(TRUE)
	. = list(
		"ledger" = ledger_data(),
		"snapshots" = snapshots_data(),
		"departments" = departments_data(),
		"accounts" = accounts_data(),
		"flags" = flags_data(),
		"commodities" = market["commodities"],
		"partners" = econ_cargo_partners_data(TRUE),
		"companies" = companies_data(),
		"config_errors" = GLOB.economy_config_errors,
		"config_reloaded_at" = GLOB.economy_config_reloaded_at,
		"tax_max" = SSeconomy.settings.tax_max,
		"adjust_max" = ECON_ADMIN_ADJUST_MAX,
		"comment_max" = ECON_ADMIN_COMMENT_MAX,
		"freeze_reason_max" = AUDIT_REASON_MAX,
		"headline_max" = ECON_ADMIN_HEADLINE_MAX,
		"effect_min" = round(STOCK_EFFECT_MIN * 100),
		"effect_max" = round(STOCK_EFFECT_MAX * 100),
		"event_mult_max" = STOCK_EVENT_MULT_MAX,
		"price_max_ratio" = STOCK_PRICE_MAX_RATIO,
		"reset_phrase" = ECON_ADMIN_RESET_PHRASE,
		"persist_decay" = SSmarket.persist_decay,
		"station_event_cooldown" = STOCK_STATION_EVENT_COOLDOWN / (1 MINUTES),
		"snapshot_minutes" = SSeconomy.wait / (1 MINUTES),
	)

/datum/economy_panel/proc/ledger_data()
	var/datum/economy_ledger/ledger = SSeconomy.ledger
	var/list/categories = list()
	for(var/reason in ledger.by_reason)
		var/category = GLOB.econ_reason_category[reason] || ECON_CAT_MISC
		var/list/entry = categories[category]
		if(!entry)
			entry = list("id" = category, "name" = GLOB.econ_category_names[category] || category, "amount" = 0, "reasons" = list())
			categories[category] = entry
		entry["amount"] += ledger.by_reason[reason]
		var/list/reasons = entry["reasons"]
		reasons += list(list("id" = reason, "name" = econ_reason_name(reason), "amount" = ledger.by_reason[reason]))
	var/list/by_category = list()
	for(var/category in categories)
		by_category += list(categories[category])
	return list(
		"minted" = ledger.minted,
		"burned" = ledger.burned,
		"total" = SSeconomy.total_money(),
		"by_category" = by_category,
		"department_kept" = ledger.department_minted + ledger.department_received - ledger.department_paid_out,
		"department_burned" = ledger.department_burned,
		"department_sink" = round(ledger.department_sink_share() * 100),
		"department_sink_min" = SSeconomy.settings.department_sink_target_min,
		"department_sink_max" = SSeconomy.settings.department_sink_target_max,
		"department_sink_no_return" = round(ledger.department_share_of(FALSE, TRUE) * 100),
		"department_sink_no_command" = round(ledger.department_share_of(TRUE, FALSE) * 100),
		"department_sink_bare" = round(ledger.department_share_of(FALSE, FALSE) * 100),
		"tax_nt_burned" = ledger.by_reason[ECON_TAX_NT] || 0,
		"budget_returned" = ledger.by_reason[ECON_BUDGET_RETURN] || 0,
		"crew" = econ_crew_money_summary(),
	)

/datum/economy_panel/proc/snapshots_data()
	. = list()
	for(var/list/snapshot as anything in SSeconomy.ledger.snapshots)
		. += list(list(
			"minute" = round(snapshot["time"] / (1 MINUTES)),
			"minted" = snapshot["minted"],
			"burned" = snapshot["burned"],
			"in_accounts" = snapshot["in_accounts"],
			"cash" = snapshot["cash"],
		))

/datum/economy_panel/proc/departments_data()
	. = list()
	var/hours = max((world.time - SSticker.round_start_time) / (1 HOURS), 0.1)
	var/list/staff_stats = econ_staff_stats()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		var/list/flow = SSeconomy.ledger.department_flow(id)
		. += list(list(
			"id" = id,
			"name" = department.name,
			"number" = department.account?.account_id,
			"balance" = department.account?.account_balance,
			"owed" = department.owed,
			"staff" = department.staff_on_shift(staff_stats),
			"threshold" = department.budget_threshold(staff_stats),
			"return_due" = department.budget_return_due(staff_stats),
			"purchases" = flow["purchases"],
			"purchases_per_hour" = round(flow["purchases"] / hours, 0.1),
			"purchase_amount" = flow["purchase_amount"],
			"returned" = flow["returned"],
		))

/datum/economy_panel/proc/accounts_data()
	. = list()
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts)
		. += list(list(
			"number" = account.account_id,
			"holder" = account.account_holder,
			"budget" = FALSE,
			"department" = account.department_id,
			"balance" = account.account_balance,
			"state" = account.state,
			"frozen_by" = account.frozen_by,
			"freeze_reason" = account.freeze_reason,
		))
	for(var/datum/bank_account/account as anything in SSeconomy.generated_accounts)
		. += list(list(
			"number" = account.account_id,
			"holder" = account.account_holder,
			"budget" = TRUE,
			"department" = account.department_id,
			"balance" = account.account_balance,
			"state" = account.state,
		))

/datum/economy_panel/proc/flags_data()
	. = list()
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.audit_flags)
		. += list(list(
			"uid" = flag.uid,
			"time" = flag.time,
			"text" = flag.text,
			"amount" = flag.amount,
			"account" = flag.account_number,
			"counterparty" = flag.counterparty_number,
			"closed" = flag.closed,
			"refunded" = flag.refunded,
			"closed_by" = flag.closed_by,
		))

/datum/economy_panel/proc/companies_data()
	var/list/queued = list()
	for(var/datum/market_event/event as anything in SSmarket.scheduled_events)
		queued[event.company.ticker]++
	. = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		var/list/entry = company.ui_entry()
		entry["base_price"] = company.base_price
		entry["event_mult"] = round(company.event_mult, 0.01)
		entry["queued"] = queued[ticker] || 0
		. += list(entry)

/// Действие окна от имени user; права админа проверяются здесь, а не только в ui_state. FALSE - действие не принято.
/datum/economy_panel/proc/panel_act(mob/user, action, list/params)
	var/client/admin_client = user ? GET_CLIENT(user) : null
	if(!check_rights_for(admin_client, R_ADMIN))
		return FALSE
	if(!islist(params))
		params = list()
	if(action == "refresh")
		return TRUE
	var/comment = econ_ui_reason(params["comment"], ECON_ADMIN_COMMENT_MAX)
	if(action == "reload_config")
		reload_config(user, comment)
		return TRUE
	if(!(action in list("adjust", "freeze", "unfreeze", "reset_sector", "market_event", "set_tax")))
		return FALSE
	if(!length(comment))
		message = "Нужен комментарий: он уходит в админ-лог вместе с действием."
		return TRUE
	switch(action)
		if("adjust")
			adjust(user, params, comment)
		if("freeze", "unfreeze")
			set_frozen(user, params, comment, action == "freeze")
		if("reset_sector")
			reset_sector(user, params, comment)
		if("market_event")
			market_event(user, params, comment)
		if("set_tax")
			set_tax(user, params, comment)
	return TRUE

/datum/economy_panel/proc/log_action(mob/user, text, comment)
	var/tail = comment ? " Комментарий: [comment]" : ""
	log_admin("[key_name(user)] [text][tail]")
	message_admins("[key_name_admin(user)] [html_encode(text)][html_encode(tail)]")

/datum/economy_panel/proc/adjust(mob/user, list/params, comment)
	var/datum/bank_account/account = SSeconomy.find_account(econ_ui_number(params["number"]))
	if(!account || QDELETED(account) || !((account in SSeconomy.bank_accounts) || (account in SSeconomy.generated_accounts)))
		message = "Счёт не найден: корректируются личные счета и бюджеты."
		return
	var/amount = econ_ui_number(params["amount"])
	if(isnull(amount) || abs(amount) > ECON_ADMIN_ADJUST_MAX || !round(amount))
		message = "Сумма - целое число со знаком, по модулю от 1 до [ECON_ADMIN_ADJUST_MAX] кр."
		return
	amount = round(amount)
	var/done = amount > 0 ? account.credit(amount, ECON_ADMIN, user) : account.debit(-amount, ECON_ADMIN, user)
	if(!done)
		message = "Не списано: на счёте [account.account_balance] кр."
		return
	var/signed = "[amount > 0 ? "+" : ""][amount]"
	if(account in SSeconomy.bank_accounts)
		account.bank_card_talk("[econ_reason_name(ECON_ADMIN)]: [signed] кр.")
	message = "Счёт [account.account_holder] №[account.account_id]: [signed] кр., на счёте [account.account_balance] кр."
	log_action(user, "скорректировал счёт [account.account_holder] №[account.account_id] на [signed] кр.", comment)

/datum/economy_panel/proc/set_frozen(mob/user, list/params, comment, freeze)
	var/datum/bank_account/account = SSeconomy.find_account(econ_ui_number(params["number"]))
	if(!account || QDELETED(account) || !(account in SSeconomy.bank_accounts))
		message = "Замораживаются только личные счета."
		return
	if(freeze == (account.state == ACCOUNT_FROZEN))
		message = freeze ? "Счёт уже заморожен." : "Счёт не заморожен."
		return
	if(!freeze)
		SSeconomy.apply_unfreeze(account, ECON_ADMIN_FROZEN_BY)
		message = "Счёт [account.account_holder] №[account.account_id] разморожен."
		log_action(user, "разморозил счёт [account.account_holder] №[account.account_id].", comment)
		return
	var/reason = econ_ui_reason(params["reason"], AUDIT_REASON_MAX)
	if(!length(reason))
		message = "Нужна причина для владельца: она уходит на его карту."
		return
	SSeconomy.apply_freeze(account, ECON_ADMIN_FROZEN_BY, reason)
	message = "Счёт [account.account_holder] №[account.account_id] заморожен: [reason]."
	log_action(user, "заморозил счёт [account.account_holder] №[account.account_id], причина для владельца: [reason].", comment)

/datum/economy_panel/proc/set_tax(mob/user, list/params, comment)
	var/rate = econ_ui_number(params["rate"])
	if(isnull(rate))
		message = "Налог - число от 0 до [SSeconomy.settings.tax_max]%."
		return
	var/old_rate = SSeconomy.tax_rate
	SSeconomy.set_tax_rate(rate, user)
	message = "Налог: [SSeconomy.tax_rate]% (потолок из конфига [SSeconomy.settings.tax_max]%)."
	log_action(user, "изменил налог с [old_rate]% на [SSeconomy.tax_rate]%.", comment)

/datum/economy_panel/proc/reset_sector(mob/user, list/params, comment)
	var/confirm = params["confirm"]
	if(!istext(confirm) || trim(confirm) != ECON_ADMIN_RESET_PHRASE)
		message = "Сброс не подтверждён: введите «[ECON_ADMIN_RESET_PHRASE]» в поле подтверждения."
		return
	SSmarket.reset_sector()
	message = "Сектор сброшен к базе: товары, акции и партнёры. Файл состояния удалён, в конце раунда он запишется заново от сброшенного рынка."
	log_action(user, "сбросил состояние сектора к базе (рынок, акции, партнёры; файл [SSmarket.state_path] удалён до конца раунда).", comment)

/datum/economy_panel/proc/market_event(mob/user, list/params, comment)
	switch(params["kind"])
		if("shift")
			SSmarket.market_shift()
			message = "Рынок сдвинут, индекс цен [round(SSmarket.price_index, 0.01)]."
			log_action(user, "сдвинул рынок сектора.", comment)
		if("crash", "boom")
			var/key = params["kind"] == "crash" ? "market_crash" : "sector_boom"
			if(!length(SSmarket.station_events[key]))
				message = "Событие [key] не задано в конфиге."
				return
			var/ready_at = SSmarket.station_event_cooldowns[key]
			if(world.time < ready_at)
				message = "Событие [key] уже было недавно, повтор через [DisplayTimeText(ready_at - world.time, 1)]."
				return
			SSmarket.station_event(key)
			message = "Событие [key] применено к акциям."
			log_action(user, "вызвал событие биржи [key].", comment)
		if("company_event")
			company_event(user, params, comment)
		else
			message = "Неизвестное событие рынка."

/datum/economy_panel/proc/company_event(mob/user, list/params, comment)
	var/datum/stock_company/company = istext(params["ticker"]) ? SSmarket.get_company(params["ticker"]) : null
	if(!company)
		message = "Нет такой компании."
		return
	if(company.is_index)
		message = "Индекс сектора считается по другим компаниям, своих событий у него нет."
		return
	if(company.is_halted())
		message = "Торги [company.ticker] остановлены, событие не ставится."
		return
	var/percent = econ_ui_number(params["effect"])
	var/effect = isnull(percent) ? 0 : round(percent) / 100
	if(!effect || effect < STOCK_EFFECT_MIN || effect > STOCK_EFFECT_MAX)
		message = "Шок - целое число процентов от [round(STOCK_EFFECT_MIN * 100)] до [round(STOCK_EFFECT_MAX * 100)], не ноль."
		return
	var/headline = econ_ui_reason(params["headline"], ECON_ADMIN_HEADLINE_MAX)
	if(!length(headline))
		message = "Нужен заголовок: он выйдет в «[MARKET_NEWS_CHANNEL]»."
		return
	SSmarket.schedule_company_event(company, ECON_ADMIN_EVENT_KEY, headline, effect, 0)
	message = "Событие [company.ticker] ([round(percent)]%) выйдет на ближайшем тике биржи, до минуты."
	log_action(user, "поставил событие компании [company.ticker]: «[headline]», шок [round(percent)]%.", comment)

/datum/economy_panel/proc/reload_config(mob/user, comment)
	var/datum/economy_settings/fresh = new
	var/list/errors = fresh.load(config_path)
	GLOB.economy_config_reloaded_at = STATION_TIME_TIMESTAMP("hh:mm:ss", world.time)
	for(var/error in errors)
		log_config("economy.json: [error]")
	if(length(errors))
		GLOB.economy_config_errors = errors
		message = "Конфиг не применён, в economy.json ошибок: [length(errors)]."
		log_action(user, "перечитал economy.json: не применён, ошибок [length(errors)].", comment)
		return
	SSeconomy.settings = fresh
	if(SSeconomy.tax_rate > fresh.tax_max)
		SSeconomy.set_tax_rate(fresh.tax_max, user)
	var/list/market_errors = SSmarket.load_settings(fresh.raw?["market"])
	for(var/error in market_errors)
		log_config("economy.json: [error]")
	GLOB.economy_config_errors = market_errors
	message = length(market_errors) ? "Конфиг применён; в секции рынка ошибок: [length(market_errors)], там остались встроенные значения." : "Конфиг перечитан и применён."
	log_action(user, "перечитал economy.json[length(market_errors) ? ", ошибок рынка [length(market_errors)]" : ""], налог [SSeconomy.tax_rate]%.", comment)

/// Медианы личных денег и подъёмных экипажа на смене: рост личных денег для калибровки.
/proc/econ_crew_money_summary()
	var/list/balances = list()
	var/list/starts = list()
	var/list/growth = list()
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts)
		if(account.state == ACCOUNT_DORMANT || !account.department_id || account.offstation)
			continue
		balances += account.account_balance
		starts += account.starting_funds
		if(account.starting_funds > 0)
			growth += account.account_balance / account.starting_funds
	return list(
		"count" = length(balances),
		"median_balance" = econ_median(balances),
		"median_start" = econ_median(starts),
		"median_growth" = round(econ_median(growth), 0.01),
	)

/proc/econ_median(list/values)
	if(!length(values))
		return 0
	var/list/sorted = sortTim(values.Copy(), GLOBAL_PROC_REF(cmp_numeric_asc))
	return sorted[round((length(sorted) + 1) / 2)]
