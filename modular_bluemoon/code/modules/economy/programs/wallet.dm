/// Личный счёт в КПК: баланс, история, переводы, чаевые, контракты, акции и метадоллары.
/datum/computer_file/program/wallet
	filename = "wallet"
	filedesc = "Кошелёк"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "wallet"
	extended_desc = "Личный счёт: баланс, история операций, переводы, чаевые, контракты NT, акции, лотерея сектора и метадоллары."
	requires_ntnet = FALSE
	usage_flags = PROGRAM_ON_TABLETS
	size = 4
	tgui_id = "NtosWallet"
	program_icon = "wallet"
	/// Ответ на последнее действие для окна
	var/message = ""
	/// Счёт, к которому относится message: при смене карты ответ стирается
	var/datum/weakref/message_account

/// Счёт ID-карты в устройстве, без карты - собственный счёт пользователя.
/datum/computer_file/program/wallet/proc/wallet_account(mob/user)
	var/obj/item/card/id/card = computer?.GetID()
	if(istype(card) && card.registered_account)
		return card.registered_account
	return econ_account_of(user)

/datum/computer_file/program/wallet/ui_interact(mob/user, datum/tgui/ui)
	if(!SStgui.get_open_ui(user, src))
		message = ""
	return ..()

/datum/computer_file/program/wallet/ui_static_data(mob/user)
	return wallet_static_data()

/datum/computer_file/program/wallet/ui_data(mob/user)
	return get_header_data() + wallet_data(user)

/datum/computer_file/program/wallet/proc/wallet_static_data()
	var/datum/economy_settings/settings = SSeconomy.settings
	return list(
		"transfer_max" = settings.transfer_max,
		"transfer_cooldown" = settings.transfer_cooldown_seconds,
		"memo_max" = ECON_TRANSFER_MEMO_MAX,
		"name_max" = MAX_NAME_LEN,
		"audit_rights" = SSeconomy.audit_rights_text(),
		"owed_cap" = settings.owed_wages_cap_paychecks,
		"wage_floor" = settings.wage_floor,
		"tax_nt_share" = settings.tax_nt_share,
		"wage_interval" = round(settings.payroll_interval_ticks * SSeconomy.wait / (1 MINUTES), 1),
		"dormant_minutes" = settings.dormant_after_minutes,
		"performer_share" = settings.contract_performer_share,
		"contracts_help" = econ_contracts_help(),
		"crew" = wallet_crew_names(),
	)

/datum/computer_file/program/wallet/proc/wallet_data(mob/user)
	var/static/list/state_names = list("active", "frozen", "dormant")
	var/datum/economy_settings/settings = SSeconomy.settings
	var/datum/bank_account/account = wallet_account(user)
	if(message && message_account?.resolve() != account)
		message = ""
	var/list/data = list(
		"message" = message,
		"metadollars_available" = !!user?.client?.ckey,
		"metadollars" = user?.client?.ckey ? SSmetadollars.get_metadollars(user.client.ckey) : 0,
		"has_account" = !!account,
		"lottery" = SSeconomy.lottery?.ui_entry(account),
	)
	if(!account)
		return data
	var/obj/item/card/id/card = computer?.GetID()
	data["from_card"] = istype(card) && card.registered_account == account
	data["holder"] = account.account_holder
	data["number"] = account.account_id
	data["balance"] = account.account_balance
	data["state"] = state_names[account.state + 1]
	data["blocked"] = !account.transferable
	data["anonymous"] = istype(account, /datum/bank_account/anonymous)
	data["personal"] = SSeconomy.is_personal_account(account)
	data["frozen_by"] = account.frozen_by
	data["freeze_source"] = account.state == ACCOUNT_FROZEN ? SSeconomy.freeze_source(account.frozen_by) : null
	data["freeze_reason"] = account.freeze_reason
	data["cooldown_left"] = CEILING(COOLDOWN_TIMELEFT(account, personal_payment_cooldown) / (1 SECONDS), 1)
	var/datum/economy_department/department = SSeconomy.get_department(account.department_id)
	data["wage"] = list(
		"grade" = account.pay_grade ? wallet_grade_name(account.pay_grade) : null,
		"department" = department?.name,
		"base" = account.pay_grade ? settings.wages[account.pay_grade] : 0,
		"bonus" = account.wage_bonus,
		"amount" = account.wage_amount(),
		"floor_only" = (!account.pay_grade || !department) && account.nt_floor_crew(),
		"tax_rate" = SSeconomy.tax_rate,
		"owed" = account.owed_wages,
	)
	data["history"] = account.ui_history()
	var/list/contracts = list()
	for(var/datum/econ_contract/contract as anything in SSeconomy.all_contracts())
		contracts += list(contract.ui_entry())
	data["contracts"] = contracts
	data["my_account"] = account.account_id
	var/list/shares = list()
	for(var/ticker in account.shares)
		var/datum/stock_company/company = SSmarket.get_company(ticker)
		shares += list(list(
			"ticker" = ticker,
			"name" = company?.name || ticker,
			"count" = account.shares[ticker],
			"value" = company ? round(company.price * account.shares[ticker]) : 0,
		))
	data["shares"] = shares
	data["portfolio"] = SSmarket.portfolio_value(account)
	return data

/datum/computer_file/program/wallet/proc/wallet_crew_names()
	. = list()
	for(var/datum/data/record/record in GLOB.data_core.general)
		var/name = record.fields["name"]
		if(istext(name) && length(name))
			. |= name

/datum/computer_file/program/wallet/proc/wallet_grade_name(grade)
	return GLOB.econ_pay_grade_names[grade] || grade

/datum/computer_file/program/wallet/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return wallet_act(usr, action, params)

/datum/computer_file/program/wallet/proc/wallet_act(mob/living/user, action, list/params)
	if(!isliving(user) || !islist(params))
		return FALSE
	message_account = WEAKREF(wallet_account(user))
	switch(action)
		if("transfer", "tip")
			return wallet_payment(user, action, params)
		if("take")
			return wallet_take(user, params["uid"])
		if("lottery_buy")
			return wallet_lottery(user, params["count"])
		if("md_withdraw", "md_deposit")
			return metadollar_act(user, action, params)
	return FALSE

/datum/computer_file/program/wallet/proc/wallet_payment(mob/living/user, action, list/params)
	var/datum/bank_account/account = wallet_account(user)
	if(!account)
		message = "Нет банковского счёта."
		return TRUE
	var/amount = params["amount"]
	if(istext(amount))
		amount = text2num(amount)
	if(!isnum(amount) || !(amount >= 1))
		message = "Неверная сумма."
		return TRUE
	var/target_text = params["target"]
	if(isnum(target_text))
		target_text = "[target_text]"
	if(!istext(target_text))
		message = "Укажите получателя."
		return TRUE
	target_text = trim(copytext_char(target_text, 1, MAX_NAME_LEN + 1))
	var/datum/bank_account/target = SSeconomy.find_account(text2num(target_text)) || SSeconomy.find_account_by_name(target_text)
	if(!target)
		var/list/namesakes = SSeconomy.find_accounts_by_name(target_text)
		message = length(namesakes) > 1 ? "На имя «[target_text]» несколько счетов - укажите номер." : "Счёт «[target_text]» не найден."
		return TRUE
	var/error
	if(action == "tip")
		error = SSeconomy.send_tip(account, target, amount, user)
	else
		error = SSeconomy.send_transfer(account, target, amount, user, params["memo"])
	if(error)
		message = error
		return TRUE
	message = "[action == "tip" ? "Чаевые" : "Перевод"] [round(amount)] кр. → [target.account_holder] (№[target.account_id])."
	return TRUE

/datum/computer_file/program/wallet/proc/wallet_lottery(mob/living/user, count)
	if(!SSeconomy.lottery)
		message = "Лотерея сейчас не проводится."
		return TRUE
	if(istext(count))
		count = text2num(count)
	var/error = SSeconomy.lottery.buy(wallet_account(user), count, user)
	message = error || "Куплено билетов: [round(count)]."
	return TRUE

/datum/computer_file/program/wallet/proc/wallet_take(mob/living/user, uid)
	var/list/result = econ_try_take_contract(user, uid, wallet_account(user))
	message = result[2]
	return TRUE

/// Метадоллары: постоянный счёт игрока, с кредитами станции не связан.
/datum/computer_file/program/wallet/proc/metadollar_act(mob/living/user, action, list/params)
	var/client/user_client = user.client
	if(!user_client?.ckey)
		message = "Нет связи с вашим счётом метадолларов."
		return TRUE
	switch(action)
		if("md_withdraw")
			var/amount = params["amount"]
			if(istext(amount))
				amount = text2num(amount)
			if(!isnum(amount) || !(amount >= 1))
				message = "Неверная сумма."
				return TRUE
			amount = round(amount)
			var/balance = SSmetadollars.get_metadollars(user_client.ckey)
			if(balance < amount)
				message = "Недостаточно метадолларов: на счёте [balance] M$."
				return TRUE
			SSmetadollars.metadollar_adjust(-amount, user_client.ckey, user_client.key)
			var/obj/item/stack/metadollar/notes = new(user.drop_location(), amount)
			user.put_in_hands(notes)
			log_admin("METADOLLAR: [user.real_name] ([user_client.ckey]) withdrew [amount] M$ via PDA. Balance: [SSmetadollars.get_metadollars(user_client.ckey)] M$.")
			message = "Снято [amount] M$."
			return TRUE
		if("md_deposit")
			var/obj/item/stack/metadollar/notes = user.get_active_held_item()
			if(!istype(notes))
				message = "Возьмите стопку метадолларов в активную руку."
				return TRUE
			var/amount = notes.amount
			if(amount <= 0)
				message = "В стопке нет метадолларов."
				return TRUE
			SSmetadollars.metadollar_adjust(amount, user_client.ckey, user_client.key)
			log_admin("METADOLLAR: [user.real_name] ([user_client.ckey]) deposited [amount] M$ via PDA. Balance: [SSmetadollars.get_metadollars(user_client.ckey)] M$.")
			qdel(notes)
			message = "Зачислено [amount] M$."
			return TRUE
