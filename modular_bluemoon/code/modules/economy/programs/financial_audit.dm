#define AUDIT_SEARCH_MAX 20

/// Финансовый аудит: дела, поиск счетов, след денег, заморозка, возврат и закрытие дел. Работают только те, у кого есть права аудита.
/datum/computer_file/program/financial_audit
	filename = "finaudit"
	filedesc = "Финансовый аудит"
	category = PROGRAM_CATEGORY_SECURITY
	program_icon_state = "finaudit"
	extended_desc = "Дела финансового аудита, поиск счетов, след денег, заморозка счетов и возврат украденного по делу."
	requires_ntnet = FALSE
	transfer_access = ACCESS_SECURITY
	usage_flags = PROGRAM_ALL
	size = 4
	tgui_id = "NtosFinancialAudit"
	program_icon = "search-dollar"
	/// REF пользователя -> ответ на его последнее действие
	var/list/messages = list()
	/// REF пользователя -> list(запрос, номера найденных счетов)
	var/list/searches = list()
	/// REF пользователя -> номер открытого счёта
	var/list/selections = list()
	/// REF пользователя -> снимок следа денег: номер, владелец, время, дерево
	var/list/traces = list()

/datum/computer_file/program/financial_audit/ui_data(mob/user)
	return get_header_data() + audit_data(user)

/datum/computer_file/program/financial_audit/ui_close(mob/user)
	. = ..()
	forget_user(user)

/datum/computer_file/program/financial_audit/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return audit_act(usr, action, params)

/datum/computer_file/program/financial_audit/proc/forget_user(mob/user)
	var/user_ref = REF(user)
	messages -= user_ref
	searches -= user_ref
	selections -= user_ref
	traces -= user_ref

/datum/computer_file/program/financial_audit/proc/audit_data(mob/living/user)
	var/user_ref = REF(user)
	var/can_audit = SSeconomy.can_audit(user)
	var/list/data = list(
		"message" = messages[user_ref] || "",
		"can_audit" = can_audit,
		"audit_rights" = SSeconomy.audit_rights_text(),
	)
	if(!can_audit)
		return data
	var/datum/economy_settings/settings = SSeconomy.settings
	data["rules"] = list(
		"siphon_threshold" = settings.audit_bonus_threshold,
		"siphon_minutes" = settings.audit_siphon_minutes,
		"structuring_count" = settings.audit_structuring_count,
		"structuring_minutes" = settings.audit_structuring_minutes,
		"insider_threshold" = settings.audit_insider_threshold,
		"insider_minutes" = settings.audit_insider_window_minutes,
		"event_eta_min" = STOCK_EVENT_ETA_MIN / (1 MINUTES),
		"event_eta_max" = STOCK_EVENT_ETA_MAX / (1 MINUTES),
		"refute_minutes" = settings.press_release_refute_minutes,
		"trace_minutes" = settings.audit_trace_minutes,
		"trace_depth" = settings.audit_trace_depth,
		"fee_percent" = settings.audit_case_fee_percent,
		"owed_cap" = settings.owed_wages_cap_paychecks,
		"reason_max" = AUDIT_REASON_MAX,
		"search_max" = AUDIT_SEARCH_MAX,
	)
	var/datum/bank_account/own = econ_account_of(user)
	data["my_account"] = own?.account_id
	var/list/cases = list()
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.audit_flags)
		cases += list(case_entry(flag, user))
	data["cases"] = cases
	var/list/search = searches[user_ref]
	var/list/results = list()
	if(search)
		for(var/number in search[2])
			var/datum/bank_account/found = SSeconomy.find_account(number)
			if(found && !QDELETED(found))
				results += list(account_row(found))
	data["query"] = search ? search[1] : ""
	data["results"] = results
	data["selected"] = account_card(SSeconomy.find_account(selections[user_ref]))
	data["trace"] = traces[user_ref]
	return data

/datum/computer_file/program/financial_audit/proc/case_entry(datum/econ_audit_flag/flag, mob/living/user)
	var/datum/bank_account/source = SSeconomy.find_account(flag.account_number)
	var/datum/bank_account/recipient = flag.counterparty_number ? SSeconomy.find_account(flag.counterparty_number) : null
	return list(
		"uid" = flag.uid,
		"kind" = flag.kind,
		"text" = flag.text,
		"amount" = flag.amount,
		"time" = flag.time,
		"source" = flag.account_number,
		"source_holder" = source ? source.account_holder : "Счёт закрыт",
		"recipient" = flag.counterparty_number,
		"recipient_holder" = flag.counterparty_number ? (recipient ? recipient.account_holder : "Счёт закрыт") : null,
		"recipient_frozen" = recipient?.state == ACCOUNT_FROZEN,
		"recipient_balance" = recipient ? recipient.account_balance : 0,
		"pooled" = flag.pooled,
		"mine" = flag.concerns(user),
		"recipients" = pooled_recipients(flag),
		"closed" = flag.closed,
		"closed_by" = flag.closed_by,
		"close_reason" = flag.close_reason,
		"refunded" = flag.refunded,
	)

/// Получатели объединённого дела: сколько ушло каждому и сколько с него ещё можно вернуть.
/datum/computer_file/program/financial_audit/proc/pooled_recipients(datum/econ_audit_flag/flag)
	. = list()
	if(!flag.pooled)
		return
	for(var/number in flag.recipients)
		var/datum/bank_account/recipient = SSeconomy.find_account(number)
		. += list(list(
			"number" = text2num(number),
			"holder" = recipient ? recipient.account_holder : "Счёт закрыт",
			"amount" = flag.recipients[number],
			"left" = flag.refundable_from(text2num(number)),
			"frozen" = recipient?.state == ACCOUNT_FROZEN,
			"balance" = recipient ? recipient.account_balance : 0,
		))

/datum/computer_file/program/financial_audit/proc/account_kind(datum/bank_account/account)
	if(istype(account, /datum/bank_account/anonymous))
		return "anonymous"
	if(istype(account, /datum/bank_account/department))
		return "budget"
	if(account.add_to_accounts)
		return "personal"
	return "system"

/datum/computer_file/program/financial_audit/proc/account_status(datum/bank_account/account)
	if(account.state == ACCOUNT_FROZEN)
		return "frozen"
	if(!account.transferable && account.add_to_accounts)
		return "blocked"
	if(account.state == ACCOUNT_DORMANT)
		return "dormant"
	return "active"

/datum/computer_file/program/financial_audit/proc/account_row(datum/bank_account/account)
	return list(
		"number" = account.account_id,
		"holder" = account.account_holder,
		"balance" = account.account_balance,
		"kind" = account_kind(account),
		"status" = account_status(account),
	)

/datum/computer_file/program/financial_audit/proc/account_card(datum/bank_account/account)
	if(!account || QDELETED(account))
		return null
	var/list/card = account_row(account)
	var/list/case_ids = list()
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.flags_for(account))
		case_ids += flag.uid
	card["frozen_by"] = account.frozen_by
	card["freeze_reason"] = account.freeze_reason
	card["freeze_locked"] = (account.state == ACCOUNT_FROZEN && account.frozen_by == ECON_ADMIN_FROZEN_BY) ? ECON_ADMIN_FREEZE_LOCKED : null
	card["cases"] = case_ids
	card["history"] = account.ui_history()
	return card

/// Точный номер любого счёта и подстрока имени без учёта регистра среди личных счетов; не больше AUDIT_SEARCH_MAX.
/datum/computer_file/program/financial_audit/proc/search_accounts(query)
	. = list()
	var/datum/bank_account/exact = SSeconomy.find_account(text2num(query))
	if(exact)
		. += exact.account_id
	query = lowertext(query)
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts)
		if(length(.) >= AUDIT_SEARCH_MAX)
			return
		if(account != exact && findtextEx(lowertext(account.account_holder), query))
			. += account.account_id

/datum/computer_file/program/financial_audit/proc/target_account(list/params)
	var/number = econ_ui_number(params["number"])
	if(isnull(number))
		return null
	var/datum/bank_account/account = SSeconomy.find_account(number)
	return QDELETED(account) ? null : account

/datum/computer_file/program/financial_audit/proc/audit_act(mob/living/user, action, list/params)
	var/static/list/actions = list("search", "select", "trace", "freeze", "unfreeze", "refund", "close_case")
	if(!isliving(user) || !islist(params) || !(action in actions))
		return FALSE
	var/user_ref = REF(user)
	if(!SSeconomy.can_audit(user))
		messages[user_ref] = "Нужны права финансового аудита: [SSeconomy.audit_rights_text()]."
		return TRUE
	switch(action)
		if("search")
			var/query = econ_ui_reason(params["query"], MAX_NAME_LEN)
			if(!length(query))
				searches -= user_ref
				messages[user_ref] = "Введите имя владельца или номер счёта."
				return TRUE
			var/list/found = search_accounts(query)
			searches[user_ref] = list(query, found)
			messages[user_ref] = length(found) ? "Найдено счетов: [length(found)][length(found) >= AUDIT_SEARCH_MAX ? " (показаны первые [AUDIT_SEARCH_MAX], уточните запрос)" : ""]." : "По запросу «[query]» счетов нет."
		if("select")
			var/datum/bank_account/account = target_account(params)
			if(account)
				selections[user_ref] = account.account_id
			else
				selections -= user_ref
		if("trace")
			var/datum/bank_account/account = target_account(params)
			if(!account)
				messages[user_ref] = "Счёт не найден."
				return TRUE
			var/list/tree = SSeconomy.trace_money(account, SSeconomy.settings.audit_trace_depth)
			traces[user_ref] = list(
				"number" = account.account_id,
				"holder" = account.account_holder,
				"time" = STATION_TIME_TIMESTAMP("hh:mm", world.time),
				"tree" = tree,
			)
			messages[user_ref] = length(tree) ? "След денег со счёта №[account.account_id] построен." : "За последние [SSeconomy.settings.audit_trace_minutes] мин. со счёта №[account.account_id] деньги никуда не уходили."
		if("freeze")
			var/datum/bank_account/account = target_account(params)
			var/reason = econ_ui_reason(params["reason"], AUDIT_REASON_MAX)
			var/problem = SSeconomy.freeze_problem(account, user, TRUE)
			if(problem)
				messages[user_ref] = problem
			else if(!length(reason))
				messages[user_ref] = "Укажите причину заморозки: владелец увидит её на карте."
			else if(SSeconomy.freeze_account(account, user, reason))
				messages[user_ref] = "Счёт №[account.account_id] ([account.account_holder]) заморожен: [account.freeze_reason]."
		if("unfreeze")
			var/datum/bank_account/account = target_account(params)
			var/problem = SSeconomy.freeze_problem(account, user, FALSE)
			if(problem)
				messages[user_ref] = problem
			else if(SSeconomy.unfreeze_account(account, user))
				messages[user_ref] = "Счёт №[account.account_id] ([account.account_holder]) разморожен."
		if("refund")
			var/datum/econ_audit_flag/flag = SSeconomy.find_audit_flag(econ_ui_number(params["uid"]))
			var/amount = econ_ui_number(params["amount"])
			var/recipient_number = flag?.pooled ? econ_ui_number(params["recipient"]) : flag?.counterparty_number
			var/datum/bank_account/from_account = recipient_number ? SSeconomy.find_account(recipient_number) : null
			var/datum/bank_account/to_account = flag ? SSeconomy.find_account(flag.account_number) : null
			var/problem = SSeconomy.refund_problem(from_account, to_account, amount, user, flag?.uid)
			var/list/result = problem ? null : SSeconomy.refund(from_account, to_account, amount, user, flag.uid)
			if(problem)
				messages[user_ref] = problem
			else if(islist(result))
				var/fee_text = "пострадавшему возвращено [result["returned"]] кр., сбор отдела безопасности [result["fee"]] кр."
				messages[user_ref] = flag.closed ? "Дело №[flag.uid] закрыто: [fee_text]" : "По делу №[flag.uid] со счёта №[from_account.account_id] [fee_text] Дело открыто, [flag.remaining_text(from_account.account_id)]"
		if("close_case")
			var/uid = econ_ui_number(params["uid"])
			var/reason = econ_ui_reason(params["reason"], AUDIT_REASON_MAX)
			var/problem = SSeconomy.close_case_problem(uid, user)
			if(problem)
				messages[user_ref] = problem
			else if(!length(reason))
				messages[user_ref] = "Укажите причину закрытия: её увидят владельцы обоих счетов."
			else if(SSeconomy.close_case(uid, user, reason))
				messages[user_ref] = "Дело №[uid] закрыто без возврата: [reason]."
	return TRUE

#undef AUDIT_SEARCH_MAX
