#define TREASURY_PRINT_COOLDOWN (5 SECONDS)

/// Казна станции: налог, бюджеты отделов, запросы глав, личные счета экипажа, прилавки и журнал денег NT. Управляют капитан и ГП.
/datum/computer_file/program/treasury
	filename = "treasury"
	filedesc = "Казна"
	category = PROGRAM_CATEGORY_CREW
	program_icon_state = "treasury"
	extended_desc = "Казна станции: налог, переводы в бюджеты отделов, запросы глав, личные счета экипажа и журнал денег NT. Управляют капитан и глава персонала."
	requires_ntnet = FALSE
	transfer_access = ACCESS_HOP
	usage_flags = PROGRAM_ALL
	size = 5
	tgui_id = "NtosTreasury"
	program_icon = "landmark"
	/// REF пользователя -> ответ на его последнее действие
	var/list/messages = list()
	/// REF пользователя -> номер счёта, открытого в окне
	var/list/selections = list()
	var/obj/machinery/computer/account_database/console
	COOLDOWN_DECLARE(print_cooldown)

/datum/computer_file/program/treasury/Destroy()
	console = null
	return ..()

/datum/computer_file/program/treasury/ui_static_data(mob/user)
	return treasury_static_data()

/datum/computer_file/program/treasury/ui_data(mob/user)
	return get_header_data() + treasury_data(user)

/datum/computer_file/program/treasury/ui_close(mob/user)
	. = ..()
	forget_user(user)

/datum/computer_file/program/treasury/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return treasury_act(usr, action, params)

/datum/computer_file/program/treasury/proc/forget_user(mob/user)
	messages -= REF(user)
	selections -= REF(user)

/datum/computer_file/program/treasury/proc/treasury_static_data()
	var/datum/economy_settings/settings = SSeconomy.settings
	var/list/grades = list()
	for(var/grade in GLOB.econ_pay_grade_names)
		grades += list(list("id" = grade, "name" = GLOB.econ_pay_grade_names[grade], "wage" = settings.wages[grade]))
	return list(
		"tax_max" = settings.tax_max,
		"grades" = grades,
		"holder_max" = MAX_NAME_LEN,
		"economy_minutes" = round(SSeconomy.wait / (1 MINUTES), 1),
		"wage_minutes" = round(settings.payroll_interval_ticks * SSeconomy.wait / (1 MINUTES), 1),
		"wage_floor" = settings.wage_floor,
		"owed_cap" = settings.owed_wages_cap_paychecks,
		"tax_nt_share" = settings.tax_nt_share,
		"cap_share" = settings.budget_cap_return_share,
		"grace_minutes" = settings.budget_cap_grace_ticks * round(SSeconomy.wait / (1 MINUTES), 1),
		"treasury_max" = settings.treasury_request_max,
		"treasury_pending_max" = settings.treasury_requests_pending_per_department,
		"unowned_max" = settings.treasury_unowned_accounts_max,
		"stall_fee" = settings.stall_rent_fee,
		"stall_minutes" = settings.stall_rent_minutes,
		"rich_per_capita" = settings.state_rich_per_capita,
		"poor_per_capita" = settings.state_poor_per_capita,
		"audit_rights" = SSeconomy.audit_rights_text(),
	)

/datum/computer_file/program/treasury/proc/user_can_manage(mob/living/user)
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	return !!command?.can_manage(user)

/// Пояснение к переводу в бюджет: сколько выше порога и что защищено от возврата NT. Перевод между отделами защиты не получает.
/proc/econ_shield_note(datum/economy_department/target, from_treasury = TRUE)
	if(!target)
		return ""
	var/list/staff_stats = econ_staff_stats()
	var/over = target.account.account_balance - target.budget_threshold(staff_stats) - target.owed_to_staff(staff_stats)
	if(over <= 0)
		return ""
	var/shielded = target.shielded()
	if(!from_treasury)
		return " Бюджет выше порога на [over] кр.: перевод между отделами от возврата NT не защищён[shielded ? ", защищены только [shielded] кр. прежних разовых поступлений ещё [target.shield_minutes()] мин." : ", излишек начнёт возвращаться на ближайшем тике."]"
	return " Бюджет выше порога на [over] кр.: разовые поступления вместе с этим переводом, [shielded] кр., защищены от возврата NT ещё [target.shield_minutes()] мин., потом излишек начнёт возвращаться."

/datum/computer_file/program/treasury/proc/treasury_data(mob/living/user)
	var/datum/economy_ledger/ledger = SSeconomy.ledger
	var/datum/bank_account/treasury = SSeconomy.treasury()
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	var/can_manage = user_can_manage(user)
	var/list/staff_stats = econ_staff_stats()
	var/list/money_history = list()
	for(var/list/snapshot as anything in ledger.snapshots)
		money_history += snapshot["in_accounts"]
	var/list/data = list(
		"message" = messages[REF(user)] || "",
		"can_manage" = can_manage,
		"treasury" = treasury?.account_balance || 0,
		"tax_rate" = SSeconomy.tax_rate,
		"treasury_grant" = command?.grant_amount(null, staff_stats),
		"treasury_cap" = command?.budget_threshold(staff_stats),
		"treasury_return_due" = command?.budget_return_due(staff_stats),
		"ledger" = list(
			"minted" = ledger.minted,
			"burned" = ledger.burned,
			"state" = SSeconomy.economy_state,
			"money_history" = money_history,
		),
	)
	var/list/departments = list()
	for(var/id in SSeconomy.departments)
		if(id == ACCOUNT_CMD)
			continue
		var/datum/economy_department/department = SSeconomy.departments[id]
		var/threshold = department.budget_threshold(staff_stats)
		departments += list(list(
			"id" = id,
			"name" = department.name,
			"balance" = department.account.account_balance,
			"owed" = department.owed,
			"owed_wages" = department.staff_stat(staff_stats, "owed_wages"),
			"staff_on_shift" = department.staff_on_shift(staff_stats),
			"threshold" = threshold,
			"headroom" = threshold - department.account.account_balance,
			"return_due" = department.budget_return_due(staff_stats),
		))
	data["departments"] = departments
	var/list/requests = list()
	for(var/datum/econ_request/treasury/request as anything in SSeconomy.treasury_requests)
		var/list/entry = request.ui_entry()
		var/datum/economy_department/department = SSeconomy.get_department(request.department_id)
		entry["department_name"] = department?.name || request.department_id
		requests += list(entry)
	data["requests"] = requests
	if(!can_manage)
		return data
	var/can_audit = SSeconomy.can_audit(user)
	var/list/flagged = list()
	if(can_audit)
		for(var/datum/econ_audit_flag/flag as anything in SSeconomy.audit_flags)
			if(flag.closed)
				continue
			for(var/number in flag.party_numbers())
				flagged["[number]"] = TRUE
	var/list/accounts = list()
	var/datum/bank_account/own
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts)
		if(!own && account.owned_by(user))
			own = account
		accounts += list(list(
			"number" = account.account_id,
			"holder" = account.account_holder,
			"grade" = account.pay_grade,
			"department" = account.department_id,
			"balance" = account.account_balance,
			"status" = account_status(account),
			"crew" = !!account.owner_ref && !account.offstation,
			"anonymous" = istype(account, /datum/bank_account/anonymous),
			"flagged" = !!flagged["[account.account_id]"],
		))
	data["my_account"] = own?.account_id
	data["can_audit"] = can_audit
	data["accounts"] = accounts
	data["account"] = account_details(crew_account(selections[REF(user)]), can_audit)
	data["stalls"] = stall_entries()
	return data

/datum/computer_file/program/treasury/proc/account_status(datum/bank_account/account)
	if(account.state == ACCOUNT_FROZEN)
		return "frozen"
	if(!account.transferable)
		return "blocked"
	if(account.state == ACCOUNT_DORMANT)
		return "dormant"
	return "active"

/datum/computer_file/program/treasury/proc/account_status_text(datum/bank_account/account)
	var/static/list/names = list(
		"frozen" = "заморожен аудитом",
		"blocked" = "заблокирован казной",
		"dormant" = "владелец не на смене",
		"active" = "активен",
	)
	return names[account_status(account)]

/datum/computer_file/program/treasury/proc/latest_case(datum/bank_account/account)
	var/datum/econ_audit_flag/latest
	for(var/datum/econ_audit_flag/flag as anything in SSeconomy.flags_for(account))
		if(!flag.closed && (!latest || flag.last_seen >= latest.last_seen))
			latest = flag
	return latest

/datum/computer_file/program/treasury/proc/account_details(datum/bank_account/account, can_audit)
	if(!account)
		return null
	var/datum/economy_department/department = SSeconomy.get_department(account.department_id)
	var/datum/econ_audit_flag/latest = can_audit ? latest_case(account) : null
	return list(
		"number" = account.account_id,
		"holder" = account.account_holder,
		"balance" = account.account_balance,
		"grade" = account.pay_grade ? GLOB.econ_pay_grade_names[account.pay_grade] : null,
		"department" = department?.name,
		"wage" = account.wage_amount(),
		"bonus" = account.wage_bonus,
		"owed" = account.owed_wages,
		"floor_only" = (!account.pay_grade || !department) && account.nt_floor_crew(),
		"status" = account_status(account),
		"frozen_by" = can_audit ? account.frozen_by : null,
		"freeze_reason" = can_audit ? account.freeze_reason : null,
		"case" = latest ? "Дело №[latest.uid]: [latest.text], [latest.amount] кр." : null,
		"history" = account.ui_history(),
	)

/datum/computer_file/program/treasury/proc/stall_entries()
	. = list()
	for(var/obj/machinery/vending/custom/stall as anything in GLOB.econ_rental_stalls)
		. += list(list(
			"name" = stall.name,
			"area" = get_area_name(stall, TRUE),
			"renter" = stall.linked_account?.account_holder,
			"until" = stall.linked_account ? stall.rent_end_text() : null,
			"active" = stall.rent_active(),
			"goods" = stall.loaded_items,
		))

/// Личный счёт по номеру из окна; бюджеты и системные счета сюда не попадают.
/datum/computer_file/program/treasury/proc/crew_account(number)
	var/datum/bank_account/account = SSeconomy.find_account(econ_ui_number(number))
	if(!account || QDELETED(account) || !(account in SSeconomy.bank_accounts))
		return null
	return account

/datum/computer_file/program/treasury/proc/budget_department(id)
	if(!istext(id) || id == ACCOUNT_CMD)
		return null
	return SSeconomy.get_department(id)

/datum/computer_file/program/treasury/proc/find_request(uid)
	uid = econ_ui_number(uid)
	if(isnull(uid))
		return null
	for(var/datum/econ_request/treasury/request as anything in SSeconomy.treasury_requests)
		if(request.uid == uid)
			return request

/// Почему казна не меняет этому счёту оклад или отдел; null - может.
/datum/computer_file/program/treasury/proc/payroll_problem(datum/bank_account/account, mob/living/user)
	if(!account)
		return "Счёт не найден."
	if(account.owned_by(user))
		return "Свой счёт так менять нельзя."
	if(account.offstation || !account.owner_ref)
		return "Оклад назначается только счёту члена экипажа."
	return null

/datum/computer_file/program/treasury/proc/treasury_act(mob/living/user, action, list/params)
	var/static/list/actions = list("set_tax", "fund", "move_budget", "resolve_request", "open_account", "select_account", "set_grade", "set_department", "toggle_block", "print_account", "print_summary")
	if(!isliving(user) || !islist(params) || !(action in actions))
		return FALSE
	var/user_ref = REF(user)
	if(!user_can_manage(user))
		messages[user_ref] = "Казной управляют только капитан и глава персонала."
		return TRUE
	switch(action)
		if("set_tax")
			var/rate = econ_ui_number(params["rate"])
			if(isnull(rate) || !SSeconomy.set_tax_rate(rate, user))
				messages[user_ref] = "Неверная ставка."
			else
				messages[user_ref] = "Налог: [SSeconomy.tax_rate]%."
		if("fund")
			var/datum/economy_department/target = budget_department(params["department"])
			var/amount = econ_ui_number(params["amount"])
			if(!target)
				messages[user_ref] = "Нет такого отдела."
			else if(isnull(amount) || !(amount >= 1))
				messages[user_ref] = "Неверная сумма."
			else if(SSeconomy.treasury_transfer(target, amount, user))
				messages[user_ref] = "В бюджет \"[target.name]\" переведено [round(amount)] кр.[econ_shield_note(target)]"
			else
				messages[user_ref] = "В казне не хватает денег."
		if("move_budget")
			var/datum/economy_department/source = budget_department(params["from"])
			var/datum/economy_department/target = budget_department(params["to"])
			var/amount = econ_ui_number(params["amount"])
			if(!source || !target || source == target)
				messages[user_ref] = "Выберите два разных отдела."
			else if(isnull(amount) || !(amount >= 1))
				messages[user_ref] = "Неверная сумма."
			else if(SSeconomy.department_transfer(source, target, amount, user))
				messages[user_ref] = "Из бюджета \"[source.name]\" в \"[target.name]\" переведено [round(amount)] кр.[econ_shield_note(target, FALSE)]"
			else
				messages[user_ref] = "В бюджете \"[source.name]\" не хватает денег."
		if("resolve_request")
			var/datum/econ_request/treasury/request = find_request(params["uid"])
			var/approve = econ_ui_number(params["approve"])
			if(!request || request.status != ECON_REQUEST_PENDING)
				messages[user_ref] = "Запрос не найден или уже решён."
			else if(isnull(approve))
				messages[user_ref] = "Неверное решение."
			else if(!SSeconomy.resolve_treasury_request(request.uid, !!approve, user))
				messages[user_ref] = "В казне не хватает денег: запрос №[request.uid] ждёт решения."
			else
				messages[user_ref] = approve ? "Запрос №[request.uid] одобрен: [request.amount] кр. ушли в бюджет отдела.[econ_shield_note(SSeconomy.get_department(request.department_id))]" : "Запрос №[request.uid] отклонён."
		if("open_account")
			messages[user_ref] = open_account(user, econ_ui_reason(params["holder"], MAX_NAME_LEN), econ_ui_number(params["funds"]))
		if("select_account")
			var/datum/bank_account/account = crew_account(params["number"])
			selections[user_ref] = account?.account_id
		if("set_grade")
			var/datum/bank_account/account = crew_account(params["number"])
			var/grade = params["grade"]
			var/problem = payroll_problem(account, user)
			if(problem)
				messages[user_ref] = problem
			else if(!istext(grade) || !(grade in GLOB.econ_pay_grade_names))
				messages[user_ref] = "Нет такого грейда."
			else
				account.pay_grade = grade
				var/grade_text = "[GLOB.econ_pay_grade_names[grade]], оклад [account.wage_amount()] кр."
				if(!SSeconomy.get_department(account.department_id))
					grade_text += ", но отдел не назначен: пока его нет, оклад не платится и NT платит только минимум [SSeconomy.settings.wage_floor] кр."
				log_econ("[key_name(user)] выставил грейд [grade] счёту [account.account_holder] №[account.account_id]")
				account.bank_card_talk("Казна изменила грейд вашего оклада: [grade_text]")
				messages[user_ref] = "Грейд [account.account_holder]: [grade_text]"
		if("set_department")
			var/datum/bank_account/account = crew_account(params["number"])
			var/datum/economy_department/department = budget_department(params["department"])
			var/problem = payroll_problem(account, user)
			if(problem)
				messages[user_ref] = problem
			else if(!department)
				messages[user_ref] = "Нет такого отдела."
			else if(account.department_id == department.id)
				messages[user_ref] = "[account.account_holder] уже получает зарплату из бюджета \"[department.name]\"."
			else
				account.department_id = department.id
				account.owed_wages = 0
				account.wage_bonus = 0
				log_econ("[key_name(user)] перевёл оклад счёта [account.account_holder] №[account.account_id] на бюджет [department.name]")
				var/no_grade = account.pay_grade ? "" : " Грейд не назначен: пока его нет, оклад не платится и NT платит только минимум [SSeconomy.settings.wage_floor] кр."
				account.bank_card_talk("Зарплату вам теперь платит бюджет отдела \"[department.name]\".[no_grade]")
				messages[user_ref] = "[account.account_holder] теперь получает зарплату из бюджета \"[department.name]\".[no_grade]"
		if("toggle_block")
			var/datum/bank_account/account = crew_account(params["number"])
			if(!account)
				messages[user_ref] = "Счёт не найден."
			else if(account.owned_by(user))
				messages[user_ref] = "Свой счёт так менять нельзя."
			else
				account.transferable = !account.transferable
				log_econ("[key_name(user)] [account.transferable ? "разблокировал" : "заблокировал"] счёт [account.account_holder] №[account.account_id]")
				account.bank_card_talk(account.transferable ? "Казна сняла блокировку с вашего счёта." : "Казна заблокировала ваш счёт: платить и получать личные деньги нельзя.", TRUE)
				messages[user_ref] = "Счёт [account.account_holder] [account.transferable ? "разблокирован" : "заблокирован"]."
		if("print_account")
			var/datum/bank_account/account = crew_account(params["number"])
			if(!account)
				messages[user_ref] = "Счёт не найден."
			else if(start_printing(user_ref))
				print_paper(user, "Выписка: [account.account_holder]", account_report(account, user))
				messages[user_ref] = "Выписка по счёту [account.account_holder] напечатана."
		if("print_summary")
			if(start_printing(user_ref))
				print_paper(user, "Сводный финансовый отчёт", summary_report(user))
				messages[user_ref] = "Сводный отчёт напечатан."
	return TRUE

/datum/computer_file/program/treasury/proc/open_account(mob/living/user, holder, funds)
	if(!length(holder))
		return "Укажите имя владельца."
	if(isnull(funds) || funds < 0)
		return "Неверная сумма."
	if(SSeconomy.unowned_treasury_accounts() >= SSeconomy.settings.treasury_unowned_accounts_max)
		return "Из казны уже открыто [SSeconomy.settings.treasury_unowned_accounts_max] счетов, не принадлежащих никому из экипажа: больше открыть нельзя."
	if(!start_printing(REF(user)))
		return messages[REF(user)]
	var/datum/bank_account/opened = SSeconomy.open_account(holder, funds, user)
	if(!opened)
		COOLDOWN_RESET(src, print_cooldown)
		return "В казне не хватает денег на начальный взнос."
	selections[REF(user)] = opened.account_id
	var/list/lines = list(
		"<h2>Новый банковский счёт</h2><hr>",
		"<p><b>Владелец:</b> [opened.account_holder]</p>",
		"<p><b>Номер счёта:</b> [opened.account_id]</p>",
		"<p><b>Начальный баланс:</b> [num2text(opened.account_balance, ECON_TEXT_DIGITS)] кр. из казны станции</p>",
		"<p><b>Открыт:</b> [STATION_TIME_TIMESTAMP("hh:mm", world.time)], [GLOB.current_date_string], [SSeconomy.auditor_name(user)]</p><hr>",
		"<p><i>Чтобы привязать счёт к ID-карте без счёта, Alt+клик по карте и введите номер.</i></p>",
	)
	print_paper(user, "Счёт: [opened.account_holder]", lines, TRUE)
	return "Открыт счёт №[opened.account_id] на имя [opened.account_holder], баланс [num2text(opened.account_balance, ECON_TEXT_DIGITS)] кр. Бумага с номером напечатана."

/datum/computer_file/program/treasury/proc/start_printing(user_ref)
	if(!COOLDOWN_FINISHED(src, print_cooldown))
		messages[user_ref] = "Принтер ещё печатает."
		return FALSE
	COOLDOWN_START(src, print_cooldown, TREASURY_PRINT_COOLDOWN)
	return TRUE

/datum/computer_file/program/treasury/proc/print_paper(mob/living/user, title, list/lines, stamped = FALSE)
	var/atom/printer = console || computer || user
	var/obj/item/paper/paper = new(printer.drop_location())
	paper.name = title
	paper.add_raw_text(jointext(lines, ""))
	if(stamped)
		var/datum/asset/spritesheet/sheet = get_asset_datum(/datum/asset/spritesheet/simple/paper)
		paper.add_stamp(sheet.icon_class_name("stamp-machine"), 400, 50, 0, "stamp-machine")
	paper.update_appearance()
	playsound(printer, 'sound/goonstation/machines/printer_thermal.ogg', 50, TRUE)
	user.put_in_hands(paper)
	return paper

/datum/computer_file/program/treasury/proc/account_report(datum/bank_account/account, mob/living/user)
	var/datum/economy_department/department = SSeconomy.get_department(account.department_id)
	. = list(
		"<h2>Выписка по счёту</h2><hr>",
		"<p><b>Владелец:</b> [account.account_holder]<br><b>Номер:</b> [account.account_id]<br><b>Баланс:</b> [num2text(account.account_balance, ECON_TEXT_DIGITS)] кр.<br><b>Состояние:</b> [account_status_text(account)]</p>",
		"<p><b>Оклад:</b> [account.pay_grade && department ? "[GLOB.econ_pay_grade_names[account.pay_grade]], [account.wage_amount()] кр. из бюджета \"[department.name]\"" : "не платится ([account.pay_grade ? "нет отдела" : "грейд не назначен"])[account.nt_floor_crew() ? ", NT платит минимум [SSeconomy.settings.wage_floor] кр." : ""]"]</p>",
		"<table width='100%'><tr><td><b>Время</b></td><td><b>Операция</b></td><td><b>Вторая сторона</b></td><td align='right'><b>Сумма</b></td></tr>",
	)
	for(var/datum/transaction/entry in account.transaction_history)
		. += "<tr><td>[entry.time]</td><td>[entry.purpose]</td><td>[entry.target_name]</td><td align='right'>[num2text(entry.amount, ECON_TEXT_DIGITS)]</td></tr>"
	. += "</table><hr><p><i>[GLOB.current_date_string], [SSeconomy.auditor_name(user)]</i></p>"

/datum/computer_file/program/treasury/proc/summary_report(mob/living/user)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	. = list("<h2>Сводный финансовый отчёт</h2><hr>", "<p><b>Казна:</b> [num2text(treasury?.account_balance || 0, ECON_TEXT_DIGITS)] кр., налог [SSeconomy.tax_rate]%</p><table width='100%'>")
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		if(id != ACCOUNT_CMD)
			. += "<tr><td>[department.name]</td><td align='right'>[num2text(department.account.account_balance, ECON_TEXT_DIGITS)] кр.</td></tr>"
	. += "</table><hr><table width='100%'><tr><td><b>Владелец</b></td><td><b>Номер</b></td><td align='right'><b>Баланс</b></td><td><b>Состояние</b></td></tr>"
	for(var/datum/bank_account/account as anything in SSeconomy.bank_accounts)
		. += "<tr><td>[account.account_holder]</td><td>[account.account_id]</td><td align='right'>[num2text(account.account_balance, ECON_TEXT_DIGITS)]</td><td>[account_status_text(account)]</td></tr>"
	. += "</table><hr><p><i>[GLOB.current_date_string], [SSeconomy.auditor_name(user)]</i></p>"

#undef TREASURY_PRINT_COOLDOWN
