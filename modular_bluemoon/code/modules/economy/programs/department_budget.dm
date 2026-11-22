/// Отдел -> оплачиваемые виды его работы и за что платится единица
GLOBAL_LIST_INIT(econ_department_work, list(
	ACCOUNT_MED = list(
		WORK_MED_DISCHARGE_LIGHT = "за пациента",
		WORK_MED_DISCHARGE_HEAVY = "за пациента",
		WORK_MED_DISCHARGE_CRIT = "за пациента",
		WORK_MED_REVIVE = "за реанимацию",
		WORK_MED_SURGERY = "за операцию",
	),
	ACCOUNT_ENG = list(
		WORK_ENG_POWER_EXPORT = "за кредит экспорта энергии; чем больше станция продаёт, тем ниже цена, без продаж она восстанавливается",
		WORK_ENG_INTEGRITY = "за процент исправности станции, каждый цикл экономики",
	),
	ACCOUNT_SCI = list(
		WORK_SCI_NODE = "за каждые [ECON_NODE_POINTS_UNIT] очков изученного узла",
		WORK_SCI_SLIME_DISCOVERY = "за очко ценности нового цвета экстракта",
		WORK_SCI_ARTIFACT = "за очко ценности артефакта",
		WORK_SCI_MECH = "за первого за смену собранного на станции меха каждой модели",
	),
	ACCOUNT_CAR = list(
		WORK_MINING_ORE = "за очко руды в переработке",
	),
	ACCOUNT_SRV = list(
		WORK_SRV_DISH = "за блюдо, съеденное другим, больше за сложные",
		WORK_SRV_DRINK = "за коктейль, выпитый другим",
		WORK_SRV_NEW_PLANT = "за новый сорт урожая",
		WORK_SRV_CLEANING = "за отмытую от грязи плитку, с потолком на уборщика за цикл экономики",
	),
	ACCOUNT_SEC = list(
		WORK_SEC_CONTRABAND = "за кредит оценки изъятой контрабанды",
	),
))

/// Бюджет отдела: баланс, сотрудники, каталог и заявки, контракты, оплаченная работа; глава - заказы, премии, надбавки, касса и запросы в казну.
/datum/computer_file/program/department_budget
	filename = "deptbudget"
	filedesc = "Бюджет отдела"
	category = PROGRAM_CATEGORY_CREW
	program_icon_state = "deptbudget"
	extended_desc = "Бюджет своего отдела: что нужно отделу сейчас, заказы из каталога (недорогие и расходники - без одобрения), пачки скупки для отдела, контракты и оплаченная работа. Глава отдела одобряет заявки, выписывает премии и надбавки, просит деньги из казны; ИИ решает заявки сотрудников, кроме СБ."
	requires_ntnet = FALSE
	usage_flags = PROGRAM_ALL
	size = 4
	tgui_id = "NtosDepartmentBudget"
	program_icon = "money-check"
	/// REF пользователя -> ответ на его последнее действие
	var/list/messages = list()
	/// REF пользователя -> отдел, выбранный ГП или капитаном
	var/list/selections = list()
	/// Отдел консоли; без него - отдел по счёту пользователя
	var/fixed_department
	var/obj/machinery/computer/department_budget/console
	/// id отдела -> его паки каталога; собирается вместе со статическими данными окна
	var/list/catalog_cache = list()

/datum/computer_file/program/department_budget/Destroy()
	console = null
	return ..()

/datum/computer_file/program/department_budget/ui_static_data(mob/user)
	return budget_static_data(user)

/datum/computer_file/program/department_budget/ui_data(mob/user)
	return get_header_data() + budget_data(user)

/datum/computer_file/program/department_budget/ui_close(mob/user)
	. = ..()
	forget_user(user)

/datum/computer_file/program/department_budget/proc/forget_user(mob/user)
	messages -= REF(user)
	selections -= REF(user)

/datum/computer_file/program/department_budget/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return
	return budget_act(usr, action, params)

/// ГП, капитан и ИИ открывают бюджет любого отдела.
/datum/computer_file/program/department_budget/proc/can_switch(mob/living/user)
	var/datum/economy_department/command = SSeconomy.get_department(ACCOUNT_CMD)
	return !!command?.can_manage(user) || econ_ai_decider(user)

/// Казна командования - в окне казны; здесь только бюджеты отделов.
/datum/computer_file/program/department_budget/proc/current_department(mob/living/user)
	if(!isliving(user))
		return null
	var/selected = selections[REF(user)]
	var/department_id = fixed_department
	if(selected && can_switch(user))
		department_id = selected
	if(!department_id)
		var/datum/bank_account/account = econ_account_of(user)
		department_id = account?.department_id
	if(department_id == ACCOUNT_CMD)
		return null
	return SSeconomy.get_department(department_id)

/datum/computer_file/program/department_budget/proc/budget_static_data(mob/living/user)
	var/datum/economy_settings/settings = SSeconomy.settings
	var/list/departments = list()
	for(var/id in SSeconomy.departments)
		if(id == ACCOUNT_CMD)
			continue
		var/datum/economy_department/listed = SSeconomy.departments[id]
		departments += list(list("id" = id, "name" = listed.name))
	var/list/catalog = list()
	var/datum/economy_department/department = current_department(user)
	if(department)
		var/list/packs = department.catalog()
		catalog_cache[department.id] = packs
		for(var/datum/supply_pack/pack as anything in packs)
			catalog += list(list("type" = "[pack.type]", "name" = pack.name, "desc" = pack.desc || pack.name, "staple" = econ_pack_staple(pack)))
	var/list/goal_packs = istype(department, /datum/economy_department/cargo) ? econ_cargo_goal_packs(department) : list()
	return list(
		"goal_packs" = goal_packs,
		"goal_max" = econ_cargo_goal_max(),
		"departments" = departments,
		"catalog" = catalog,
		"advice" = department?.spending_advice() || list(),
		"reason_max" = ECON_REQUEST_REASON_MAX,
		"grant_base" = settings.grant_base,
		"grant_payroll_share" = settings.grant_payroll_share,
		"cap_paydays" = settings.budget_cap_paydays,
		"cap_share" = settings.budget_cap_return_share,
		"grace_minutes" = settings.budget_cap_grace_ticks * round(SSeconomy.wait / (1 MINUTES), 1),
		"goal_minutes" = settings.saving_goal_minutes,
		"goal_cooldown_minutes" = settings.saving_goal_cooldown_minutes,
		"goal_collect_minutes" = settings.saving_goal_collect_minutes,
		"economy_minutes" = round(SSeconomy.wait / (1 MINUTES), 1),
		"wage_minutes" = round(settings.payroll_interval_ticks * SSeconomy.wait / (1 MINUTES), 1),
		"owed_cap" = settings.owed_wages_cap_paychecks,
		"wage_floor" = settings.wage_floor,
		"dormant_minutes" = settings.dormant_after_minutes,
		"max_wage_bonus" = settings.max_wage_bonus,
		"express_markup" = settings.department_express_markup,
		"express_cooldown" = settings.department_express_cooldown_minutes,
		"bonus_cap_hour" = settings.bonus_cap_hour,
		"bonus_self_cap_hour" = settings.bonus_self_cap_hour,
		"treasury_max" = settings.treasury_request_max,
		"treasury_pending_max" = settings.treasury_requests_pending_per_department,
		"auto_approve_limit" = settings.auto_approve_limit,
		"auto_approve_cooldown" = settings.auto_approve_cooldown_minutes,
		"auto_approve_wait" = settings.auto_approve_wait_minutes,
		"staple_cap" = settings.staple_self_order_cap_hour,
		"handoff_minutes" = settings.request_handoff_minutes,
		"pending_per_requester" = settings.request_pending_per_requester,
		"handling_fee" = settings.cargo_handling_fee,
		"work_cap" = settings.work_personal_cap_hour,
		"performer_share" = settings.contract_performer_share,
		"contracts_help_topics" = econ_contracts_help_topics(),
		"audit_rights" = SSeconomy.audit_rights_text(),
		"audit_bonus_allowance" = SSeconomy.audit_bonus_allowance(),
		"audit_siphon_minutes" = settings.audit_siphon_minutes,
		"bundle_first" = round(BUNDLE_DEPARTMENT_FIRST / (1 MINUTES)),
		"grant_price" = settings.research_grant_price_per_point,
		"grant_cap" = settings.research_grant_cap_hour,
	)

/datum/computer_file/program/department_budget/proc/budget_data(mob/living/user)
	var/datum/economy_department/department = current_department(user)
	var/datum/bank_account/own = econ_account_of(user)
	var/datum/economy_department/manifest_department = econ_manifest_department_for(user)
	var/list/data = list(
		"message" = messages[REF(user)] || "",
		"can_switch" = can_switch(user),
		"has_department" = !!department,
		"my_account" = own?.account_id,
		"manifest_department" = manifest_department?.name,
		"tax_mood_note" = SSeconomy.tax_mood_note(),
	)
	if(!department)
		return data
	var/can_manage = department.can_manage(user)
	data["can_manage"] = can_manage
	data["is_staff"] = own?.department_id == department.id
	data["is_ai"] = econ_ai_decider(user)
	data["ai_decides"] = department.ai_decides()
	data["staple_left"] = own?.department_id == department.id ? department.staple_left(own.account_id) : null
	var/list/staff_stats = econ_staff_stats()
	var/on_shift = department.staff_on_shift(staff_stats)
	var/list/packs = catalog_cache[department.id]
	if(!packs)
		packs = department.catalog()
		catalog_cache[department.id] = packs
	data["department"] = list(
		"id" = department.id,
		"name" = department.name,
		"balance" = department.account.account_balance,
		"owed" = department.owed,
		"staff_on_shift" = on_shift,
		"grant" = department.grant_due(packs, staff_stats),
		"grant_max" = department.grant_amount(packs, staff_stats),
		"grant_level" = department.grant_level(staff_stats),
		"grant_has_base" = length(packs) && SSeconomy.settings.grant_base > 0,
		"threshold" = department.budget_threshold(staff_stats),
		"threshold_floor" = department.budget_floor(),
		"return_due" = department.budget_return_due(staff_stats),
		"reserve" = department.owed_to_staff(staff_stats),
		"return_in" = max(CEILING((SSeconomy.next_fire - world.time) / (1 MINUTES), 1), 1),
		"shielded" = department.shielded(),
		"goal_cooldown" = department.saving_goal_cooldown_minutes(),
		"express_ready_in" = CEILING(department.express_ready_in() / (1 SECONDS), 1),
		"goal" = econ_budget_goal_entry(department, packs),
		"emergency" = econ_emergency_active(),
	)
	var/list/prices = list()
	var/list/offers = SSmarket.best_offers(packs)
	for(var/datum/supply_pack/pack as anything in packs)
		var/list/row = econ_cargo_price_row(pack, offers[pack])
		prices["[pack.type]"] = list("price" = row["cost"], "available" = row["in_stock"])
	data["prices"] = prices
	data["needs"] = department.needs_ui()
	data["bundles"] = econ_bundles_ui_data(user, department.id)
	data["head_on_shift"] = department.has_approver_on_shift()
	data["work_share"] = SSeconomy.work_premium_share()
	var/list/work_prices = list()
	var/list/works = GLOB.econ_department_work[department.id]
	for(var/work_type in works)
		work_prices += list(list("name" = econ_work_name(work_type), "price" = round(SSeconomy.work_price(work_type), 0.01), "unit" = works[work_type]))
	data["work_prices"] = work_prices
	data["instant_approval"] = department.instant_approval()
	data["auto_ready_in"] = own?.department_id == department.id ? max(CEILING((department.auto_approve_after["[own.account_id]"] - world.time) / (1 MINUTES), 1), 0) : null
	if(istype(department, /datum/economy_department/cargo))
		var/list/goal_erts = list()
		for(var/ert_id in 1 to length(GLOB.payed_ert))
			var/list/ert = GLOB.payed_ert[ert_id]
			goal_erts += list(list("id" = ert_id, "name" = ert["name"], "price" = ert["price"], "available" = !!ert["available"]))
		data["goal_erts"] = goal_erts
	else
		data["goal_erts"] = null
	var/list/requests = list()
	for(var/datum/econ_request/request as anything in department.requests)
		requests += list(econ_budget_request_entry(department, request, user))
	data["requests"] = requests
	data["deciders"] = department.deciders_text()
	data["handoff_requests"] = istype(department, /datum/economy_department/cargo) && can_manage ? econ_handoff_requests_ui(user) : null
	var/list/treasury_requests = list()
	for(var/datum/econ_request/treasury/request as anything in SSeconomy.treasury_requests)
		if(request.department_id == department.id)
			treasury_requests += list(request.ui_entry())
	data["treasury_requests"] = treasury_requests
	var/list/contracts = list()
	for(var/datum/econ_contract/contract as anything in department.contracts)
		contracts += list(contract.ui_entry())
	data["contracts"] = contracts
	data["board_resets"] = econ_contract_resets_ui(user, list(department))
	data["work_log"] = department.work_log
	data["register_share"] = department.register_cashier_share
	var/owed_total = 0
	var/list/staff = list()
	for(var/datum/bank_account/member as anything in department.staff_accounts())
		owed_total += member.owed_wages
		if(!can_manage)
			continue
		staff += list(list(
			"number" = member.account_id,
			"holder" = member.account_holder,
			"wage" = member.wage_amount(),
			"bonus" = member.wage_bonus,
			"bonus_left" = member.bonus_left(econ_own_account(member, user)),
			"owed" = member.owed_wages,
			"frozen" = member.state == ACCOUNT_FROZEN,
			"away" = member.state == ACCOUNT_DORMANT,
		))
	data["staff"] = staff
	data["owed_wages"] = owed_total
	var/datum/economy_department/science/science = department
	data["is_science"] = istype(science)
	if(istype(science))
		var/window_over = world.time - science.grant_window_start >= 1 HOURS
		data["grant_left"] = SSeconomy.settings.research_grant_cap_hour - (window_over ? 0 : science.grant_points_in_window)
		data["grant_resets_in"] = window_over ? 0 : CEILING((science.grant_window_start + 1 HOURS - world.time) / (1 MINUTES), 1)
	return data

/proc/econ_ui_number(value)
	if(istext(value))
		value = text2num(value)
	return isnum(value) ? value : null

/// Свободный текст из окна: без разметки и переносов, не длиннее max_length символов.
/proc/econ_ui_reason(value, max_length = ECON_REQUEST_REASON_MAX)
	if(!istext(value))
		return ""
	value = strip_html_simple(strip_html_tags(copytext_char(value, 1, max_length + 1)))
	return trim(sanitize_simple(value, list("\n" = " ", "\t" = " ")))

/datum/computer_file/program/department_budget/proc/catalog_pack(datum/economy_department/department, pack_text)
	if(!istext(pack_text))
		return null
	var/pack_path = text2path(pack_text)
	if(!ispath(pack_path, /datum/supply_pack))
		return null
	var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_path]
	if(!pack || !(pack in department.catalog()))
		return null
	return pack

/// Цель накопления отдела для окна: сколько набрать, сколько осталось на сбор и на заказ; null - цели нет.
/proc/econ_budget_goal_entry(datum/economy_department/department, list/packs)
	var/amount = department.saving_goal_amount()
	if(!amount)
		return null
	var/until = department.saving_goal_until
	return list(
		"id" = department.saving_goal_ert ? "ert:[department.saving_goal_ert]" : "[department.saving_goal.type]",
		"name" = department.saving_goal_name(),
		"amount" = amount,
		"is_ert" = !!department.saving_goal_ert,
		"off_catalog" = !department.saving_goal_ert && !(department.saving_goal in packs),
		"minutes_left" = until ? CEILING((until - world.time) / (1 MINUTES), 1) : null,
		"collect_minutes_left" = until ? null : max(CEILING((department.saving_goal_collect_deadline() - world.time) / (1 MINUTES), 1), 0),
	)

/// Пак, на который отдел может копить: из каталога, а у снабжения - и заказываемый за его бюджет.
/datum/computer_file/program/department_budget/proc/goal_pack(datum/economy_department/department, pack_text)
	if(!istext(pack_text))
		return null
	var/pack_path = text2path(pack_text)
	if(!ispath(pack_path, /datum/supply_pack))
		return null
	var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_path]
	return department.can_save_for(pack) ? pack : null

/// Паки снабжения вне его каталога, на которые оно может копить, с ценой из общей таблицы окон снабжения.
/proc/econ_cargo_goal_packs(datum/economy_department/cargo/cargo)
	. = list()
	GLOB.econ_cargo_prices.refresh()
	var/list/own = cargo.catalog()
	var/goal_max = econ_cargo_goal_max()
	for(var/pack_type in SSshuttle.supply_packs)
		var/datum/supply_pack/pack = SSshuttle.supply_packs[pack_type]
		if((pack in own) || !econ_cargo_budget_pack(pack))
			continue
		var/list/row = GLOB.econ_cargo_prices.table[pack_type]
		var/price = round(row ? row["cost"] : econ_pack_price(pack))
		if(price > goal_max)
			continue
		. += list(list("type" = "[pack_type]", "name" = pack.name, "group" = pack.group, "price" = price, "available" = row ? !!row["in_stock"] : !econ_pack_unavailable(pack)))

/// Заявка отдела для окна: что с ней дальше и может ли зритель её решить.
/proc/econ_budget_request_entry(datum/economy_department/department, datum/econ_request/request, mob/living/user)
	var/list/entry = request.ui_entry()
	entry["outlook"] = department.request_outlook(request)
	entry["can_decide"] = request.status == ECON_REQUEST_PENDING && department.can_decide(request, user)
	entry["department"] = department.name
	entry["department_id"] = department.id
	return entry

/// Заявки других отделов, переданные снабжению и ждущие решения: начальнику снабжения в его бюджете.
/proc/econ_handoff_requests_ui(mob/living/user)
	. = list()
	for(var/id in SSeconomy.departments)
		var/datum/economy_department/department = SSeconomy.departments[id]
		if(id == ACCOUNT_CAR)
			continue
		for(var/datum/econ_request/request as anything in department.requests)
			if(request.status == ECON_REQUEST_PENDING && request.handed_off)
				var/list/entry = econ_budget_request_entry(department, request, user)
				entry["balance"] = department.account.account_balance
				. += list(entry)

/datum/computer_file/program/department_budget/proc/find_request(datum/economy_department/department, uid)
	uid = econ_ui_number(uid)
	if(isnull(uid))
		return null
	for(var/datum/econ_request/request as anything in department.requests)
		if(request.uid == uid)
			return request

/datum/computer_file/program/department_budget/proc/staff_member(datum/economy_department/department, number)
	var/datum/bank_account/member = SSeconomy.find_account(econ_ui_number(number))
	return department.is_staff_account(member) ? member : null

/datum/computer_file/program/department_budget/proc/budget_act(mob/living/user, action, list/params)
	if(!isliving(user) || !islist(params))
		return FALSE
	var/user_ref = REF(user)
	if(action == "select_department")
		messages[user_ref] = select_department(user, params["id"])
		return TRUE
	var/datum/economy_department/department = current_department(user)
	if(!department)
		messages[user_ref] = "Отдел не определён: нужен счёт сотрудника отдела."
		return TRUE
	var/static/manage_refusal = "Это может только глава отдела, ГП или капитан."
	var/can_manage = department.can_manage(user)
	switch(action)
		if("request")
			var/datum/supply_pack/pack = catalog_pack(department, params["pack"])
			if(!pack)
				messages[user_ref] = "Этого нет в каталоге отдела."
				return TRUE
			var/datum/econ_request/repeat = department.instant_repeat(pack, user)
			if(repeat)
				messages[user_ref] = econ_repeat_refusal(repeat)
				return TRUE
			var/datum/econ_request/request = department.submit_request(pack, user, econ_ui_reason(params["reason"]))
			if(!request)
				messages[user_ref] = "Заявку не приняли: подают сотрудники отдела, у одного сотрудника ждут решения не больше [SSeconomy.settings.request_pending_per_requester] заявок."
			else if(request.status == ECON_REQUEST_APPROVED)
				messages[user_ref] = "Заявка №[request.uid] одобрена, заказ ушёл в снабжение."
			else
				var/list/parts = list(econ_sentence("Заявка №[request.uid] подана и [department.pending_text(pack, user, 1)]"))
				var/money = department.money_note(pack)
				if(money)
					parts += money
				var/datum/bank_account/requester_account = econ_account_of(user)
				var/cooldown = department.cooldown_note(pack, requester_account?.account_id)
				if(cooldown)
					parts += cooldown
				messages[user_ref] = jointext(parts, " ")
		if("approve", "deny")
			var/datum/economy_department/owner = department
			if(istext(params["department"]) && params["department"] != department.id)
				owner = SSeconomy.get_department(params["department"])
			var/datum/econ_request/request = owner && find_request(owner, params["uid"])
			if(!request || request.status != ECON_REQUEST_PENDING)
				messages[user_ref] = "Заявка не найдена или уже решена."
			else if(!owner.can_decide(request, user))
				messages[user_ref] = owner == department ? "Это может только глава отдела, ГП, капитан[owner.ai_decides() ? ", ИИ" : ""] или, если заявку передали снабжению, его начальник." : "Эту заявку снабжению не передавали."
			else if(action == "deny")
				messages[user_ref] = owner.deny(request, user) ? "Заявка №[request.uid] отклонена." : "Заявка не отклонена."
			else
				messages[user_ref] = owner.approve(request, user) ? "Заявка №[request.uid] одобрена, заказ ушёл в снабжение[owner == department ? "" : " за бюджет отдела \"[owner.name]\""][request.cargo_topup ? ", недостающие [request.cargo_topup] кр. доплатил бюджет снабжения" : ""]." : owner.order_refusal(request.pack, request, user)
		if("set_goal", "clear_goal")
			var/datum/supply_pack/pack = goal_pack(department, params["pack"])
			var/datum/economy_department/cargo/cargo = department
			var/ert_id = istype(cargo) && !isnull(params["ert"]) ? econ_ui_number(params["ert"]) : null
			if(!can_manage)
				messages[user_ref] = manage_refusal
			else if(action == "clear_goal")
				department.clear_saving_goal(user)
				messages[user_ref] = "Цель накопления снята. Новую можно поставить через [SSeconomy.settings.saving_goal_cooldown_minutes] мин."
			else if(ert_id ? cargo.set_saving_goal_ert(ert_id, user) : department.set_saving_goal(pack, user))
				messages[user_ref] = "Цель накопления: \"[department.saving_goal_name()]\". Пока бюджет не наберёт её цену, NT не забирает излишек и доливает на неё излишки других отделов (при красном коде - нет; долитое без заказа цели NT заберёт обратно); набрать её нужно за [SSeconomy.settings.saving_goal_collect_minutes] мин., иначе цель снимется. Набрали - [department.saving_goal_order_hint(SSeconomy.settings.saving_goal_minutes)]"
			else if(department.saving_goal_amount())
				messages[user_ref] = "Цель уже выбрана: \"[department.saving_goal_name()]\". Снимите её, чтобы выбрать другую."
			else if(department.saving_goal_cooldown_minutes())
				messages[user_ref] = "Новую цель можно поставить через [department.saving_goal_cooldown_minutes()] мин."
			else if(ert_id)
				messages[user_ref] = "Этот отряд сейчас не вызвать."
			else
				messages[user_ref] = istype(cargo) ? "Копить можно на пак каталога, пак, который снабжение заказывает за свой бюджет, не дороже [econ_cargo_goal_max()] кр., или на отряд ОБР." : "Этого нет в каталоге отдела."
		if("express")
			var/datum/supply_pack/pack = catalog_pack(department, params["pack"])
			if(!pack)
				messages[user_ref] = "Этого нет в каталоге отдела."
			else if(!can_manage)
				messages[user_ref] = manage_refusal
			else
				var/price = department.express_price(pack)
				var/refusal = department.express_pack(pack, user)
				messages[user_ref] = refusal || "Капсула с \"[pack.name]\" вылетела: [price] кр. списано из бюджета, сядет рядом с вами."
		if("order")
			var/datum/supply_pack/pack = catalog_pack(department, params["pack"])
			if(!pack)
				messages[user_ref] = "Этого нет в каталоге отдела."
			else if(!can_manage)
				messages[user_ref] = manage_refusal
			else
				messages[user_ref] = department.order_pack(pack, user, "Заказ главы: [department.name]") ? "\"[pack.name]\" заказан, деньги списаны из бюджета." : department.order_refusal(pack)
		if("buy_bundle")
			var/datum/supply_pack/bundle/bundle = SSmarket.bundle_by_uid(econ_ui_number(params["uid"]))
			if(!bundle || bundle.department_id != department.id)
				messages[user_ref] = "Этой пачки для отдела в скупке уже нет."
			else
				var/list/result = econ_bundle_buy_for_department(user, bundle)
				messages[user_ref] = result[2]
		if("bonus")
			var/datum/bank_account/member = staff_member(department, params["number"])
			var/amount = econ_ui_number(params["amount"])
			if(!can_manage)
				messages[user_ref] = manage_refusal
			else if(!member)
				messages[user_ref] = "Сотрудник не найден в отделе."
			else if(member.state == ACCOUNT_FROZEN)
				messages[user_ref] = "Счёт [member.account_holder] заморожен аудитом: премии на него закрыты."
			else if(isnull(amount) || !(amount >= 1))
				messages[user_ref] = "Неверная сумма."
			else if(department.account.account_balance < round(amount))
				messages[user_ref] = "В бюджете не хватает денег."
			else if(round(amount) > member.bonus_left(econ_own_account(member, user)))
				messages[user_ref] = econ_own_account(member, user) ? "Себе можно выписать ещё [member.bonus_left(TRUE)] кр. в этом часе." : "[member.account_holder] может получить ещё [member.bonus_left()] кр. премий в этом часе."
			else
				messages[user_ref] = department.pay_bonus(member, amount, user) ? "Премия [round(amount)] кр. выписана: [member.account_holder]." : "Премия не выписана."
		if("wage_bonus")
			var/datum/bank_account/member = staff_member(department, params["number"])
			var/percent = econ_ui_number(params["percent"])
			if(!can_manage)
				messages[user_ref] = manage_refusal
			else if(!member || isnull(percent))
				messages[user_ref] = "Сотрудник не найден в отделе."
			else if(econ_own_account(member, user))
				messages[user_ref] = "Свой счёт так менять нельзя."
			else
				messages[user_ref] = department.set_wage_bonus(member, percent, user) ? "Надбавка [member.account_holder]: [member.wage_bonus]%." : "Надбавка не изменена."
		if("treasury_request")
			var/amount = econ_ui_number(params["amount"])
			if(!can_manage)
				messages[user_ref] = manage_refusal
			else
				var/datum/econ_request/treasury/request = isnull(amount) ? null : department.request_treasury(amount, econ_ui_reason(params["reason"]), user)
				messages[user_ref] = request ? "Запрос №[request.uid] на [request.amount] кр. [request.notified ? "отправлен капитану и ГП" : "ждёт в программе \"Казна\": капитана и ГП на смене нет, им сообщат, когда выйдут"]." : "Запрос не отправлен: от 1 до [SSeconomy.settings.treasury_request_max] кр., у отдела ждут решения не больше [SSeconomy.settings.treasury_requests_pending_per_department] запросов."
		if("print_manifest")
			if(!econ_manifest_department_for(user))
				messages[user_ref] = "Экспортные накладные выдаются сотрудникам отделов станции, кроме снабжения."
			else
				messages[user_ref] = econ_print_manifest(user, console || ui_host()) ? "Накладная напечатана." : "Накладную можно печатать не чаще раза в [DisplayTimeText(ECON_MANIFEST_PRINT_COOLDOWN)]."
		if("register_share")
			var/percent = econ_ui_number(params["percent"])
			if(!can_manage)
				messages[user_ref] = manage_refusal
			else
				messages[user_ref] = !isnull(percent) && department.set_register_share(percent, user) ? "Доля кассира на кассах отдела: [department.register_cashier_share]%." : "Неверная доля."
		if("research_grant")
			var/datum/economy_department/science/science = department
			var/points = econ_ui_number(params["points"])
			if(!istype(science))
				messages[user_ref] = "Грант на исследования покупает только наука."
			else if(!can_manage)
				messages[user_ref] = manage_refusal
			else if(isnull(points) || !(points >= 1))
				messages[user_ref] = "Неверное число очков."
			else if(science.buy_research_grant(points, user))
				messages[user_ref] = "Грант куплен: [round(points)] очков исследований."
			else
				messages[user_ref] = "Грант не куплен: не хватает денег в бюджете или исчерпан часовой лимит."
		if("take")
			var/list/result = econ_try_take_contract(user, params["uid"])
			messages[user_ref] = result[2]
		if("drop")
			var/list/result = econ_try_drop_contract(user, params["uid"])
			messages[user_ref] = result[2]
		if("board_reset")
			var/list/result = department.reset_contracts(user)
			messages[user_ref] = result[2]
		else
			return FALSE
	return TRUE

/datum/computer_file/program/department_budget/proc/select_department(mob/living/user, id)
	if(!can_switch(user))
		return "Переключать отделы могут только ГП и капитан."
	if(!istext(id) || id == ACCOUNT_CMD || !SSeconomy.get_department(id))
		return "Нет такого отдела."
	selections[REF(user)] = id
	var/datum/static_host = console || src
	static_host.update_static_data(user)
	var/datum/economy_department/department = SSeconomy.get_department(id)
	return "Открыт бюджет отдела \"[department.name]\"."
