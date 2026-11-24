/datum/objective/economy
	name = "economy"
	/// "номер счёта" -> засчитанное с него и ещё не вернувшееся
	var/list/taken_from = list()
	/// Номера счетов, куда пришли засчитанные деньги: возврат с них аудитом отнимает засчитанное
	var/list/recipient_ids = list()
	/// Что кладётся в рюкзак к заданию; неиспользованное уходит вместе с заданием
	var/tool_type
	var/datum/weakref/tool_ref
	var/tool_name
	/// Владелец уже узнал, что набрал нужное: второй раз не сообщаем
	var/threshold_noted = FALSE

/datum/objective/economy/New(text)
	. = ..()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_AUDIT_REFUNDED, PROC_REF(on_audit_refund))

/datum/objective/economy/Destroy(force, ...)
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_AUDIT_REFUNDED)
	drop_unused_tool()
	return ..()

/datum/objective/economy/proc/forge()
	update_explanation_text()
	return TRUE

/datum/objective/economy/admin_edit(mob/admin)
	if(forge())
		give_tool()
		return
	to_chat(admin, span_warning("Задание «[name]» сейчас выдать нельзя: нет подходящей цели. Задание не выдано."))
	qdel(src)

/// Кладёт владельцу инструмент к заданию, один на задание.
/datum/objective/economy/proc/give_tool()
	if(!tool_type || tool_ref)
		return null
	var/list/given = give_special_equipment(list(tool_type))
	var/obj/item/tool = length(given) ? given[1] : null
	if(!tool)
		return null
	tool_ref = WEAKREF(tool)
	tool_name = tool.name
	log_game("[key_name(owner)] получил [tool.name] к экономическому заданию предателя ([name]).")
	return tool

/datum/objective/economy/proc/tool_unused(obj/item/tool)
	var/obj/item/anon_account_card/card = tool
	if(istype(card))
		return !card.account || (card.account.account_balance <= 0 && !length(card.account.shares) && !card.account.realized_stock_profit && length(card.account.bank_cards) <= 1)
	var/obj/item/card_skimmer/skimmer = tool
	if(istype(skimmer))
		return !length(skimmer.stolen)
	return TRUE

/// Инструмент, которым не пользовались и который никому не отдали, уходит вместе с заданием: замена не даёт лишний предмет.
/datum/objective/economy/proc/drop_unused_tool()
	var/obj/item/tool = tool_ref?.resolve()
	tool_ref = null
	if(QDELETED(tool))
		return FALSE
	var/mob/holder = get(tool, /mob)
	if(holder && !(holder.mind in get_owners()))
		return FALSE
	if(!tool_unused(tool))
		return FALSE
	var/obj/item/anon_account_card/card = tool
	var/datum/bank_account/empty_account = istype(card) ? card.account : null
	qdel(tool)
	qdel(empty_account)
	return TRUE

/// Подсказка в окне агента и строка о выданном инструменте.
/datum/objective/economy/proc/full_hint()
	. = how_to_text()
	if(tool_name)
		. += " К заданию вам выдали: [tool_name]."

/// Нужное набрано; дальше достаточно удержать до конца смены.
/datum/objective/economy/proc/threshold_reached()
	return is_done()

/datum/objective/economy/proc/threshold_text()
	return "Экономическое задание выполнено."

/// Один раз сообщает живому владельцу у экрана, что нужное набрано; возврат аудитом сообщение не повторяет.
/datum/objective/economy/proc/note_threshold()
	if(threshold_noted || !threshold_reached())
		return FALSE
	for(var/datum/mind/mind as anything in get_owners())
		var/mob/living/body = mind.current
		if(!isliving(body) || body.stat == DEAD || !GET_CLIENT(body))
			continue
		threshold_noted = TRUE
		to_chat(body, span_notice(threshold_text()))
		for(var/datum/antagonist/antag as anything in mind.antag_datums)
			if(src in antag.objectives)
				antag.update_static_data_for_all_viewers()
	return threshold_noted

/datum/objective/economy/proc/goal_text()
	return ""

/datum/objective/economy/proc/progress_text()
	return ""

/// Подсказка «Как выполнить» под заданием в окне агента: чем, что засчитывается и что нет.
/datum/objective/economy/proc/how_to_text()
	return ""

/datum/objective/economy/proc/is_done()
	return FALSE

/// Чужой счёт, перевод с которого засчитывает эта цель: другие цели того же владельца его не берут.
/datum/objective/economy/proc/claimed_account()
	return null

/datum/objective/economy/update_explanation_text()
	explanation_text = goal_text()

/datum/objective/economy/proc/refresh_progress()
	explanation_text = "[goal_text()] Сейчас: [progress_text()]"

/datum/objective/economy/check_completion()
	. = is_done()
	refresh_progress()

/datum/objective/economy/current_explanation()
	refresh_progress()
	return explanation_text

/datum/objective/economy/proc/is_owner(mob/actor)
	return actor?.mind && (actor.mind in get_owners())

/// Цель ещё числится за живым владельцем-антагонистом.
/datum/objective/economy/proc/is_active()
	for(var/datum/mind/mind as anything in get_owners())
		if(isliving(mind.current) && mind.current.stat != DEAD && (src in mind.get_all_objectives()))
			return TRUE
	return FALSE

/// Засчитывает amount, ушедшие с source на payee; возвращает amount.
/datum/objective/economy/proc/count_taken(datum/bank_account/source, datum/bank_account/payee, amount)
	taken_from["[source.account_id]"] += amount
	if(payee && payee != SSeconomy.cash_account)
		recipient_ids |= "[payee.account_id]"
	return amount

/// Деньги вернулись на source: вычитает не больше засчитанного с него и возвращает вычтенное.
/datum/objective/economy/proc/count_returned(datum/bank_account/source, amount)
	var/key = "[source?.account_id]"
	var/counted = taken_from[key]
	if(!counted)
		return 0
	. = min(amount, counted)
	taken_from[key] = counted - .

/// Владелец цели сам вернул деньги на счёт, с которого они засчитаны: внёс наличные или перевёл со своего или любого анонимного счёта. Покупки и оплата работы не в счёт.
/datum/objective/economy/proc/note_put_back(datum/bank_account/payer, datum/bank_account/payee, amount, reason, mob/actor)
	var/static/list/put_back_reasons = list(ECON_CASH_IN, ECON_TRANSFER, ECON_BUDGET_TRANSFER)
	if(!payee || !payer || !(reason in put_back_reasons) || !is_owner(actor))
		return FALSE
	if(payer != SSeconomy.cash_account && !(payer in owner_accounts()) && !istype(payer, /datum/bank_account/anonymous))
		return FALSE
	var/returned = count_returned(payee, amount)
	if(!returned)
		return FALSE
	lose_progress(returned)
	return TRUE

/datum/objective/economy/proc/on_audit_refund(datum/source, datum/bank_account/from_account, datum/bank_account/to_account, amount)
	SIGNAL_HANDLER
	if("[from_account.account_id]" in recipient_ids)
		lose_progress(count_returned(to_account, amount))

/// Засчитанное уменьшилось на amount: деньги вернулись туда, откуда ушли.
/datum/objective/economy/proc/lose_progress(amount)
	return

/// Личный счёт владельца и счета анонимных карт при нём.
/datum/objective/economy/proc/owner_accounts()
	. = list()
	for(var/datum/mind/mind as anything in get_owners())
		var/mob/living/body = mind.current
		if(!isliving(body))
			continue
		var/datum/bank_account/own = econ_account_of(body)
		if(own)
			. |= own
		for(var/obj/item/anon_account_card/card in body.GetAllContents())
			if(card.account)
				. |= card.account

/datum/objective/economy/proc/owner_cash()
	. = 0
	for(var/datum/mind/mind as anything in get_owners())
		var/mob/living/body = mind.current
		if(!isliving(body))
			continue
		for(var/obj/item/money in body.GetAllContents())
			if(istype(money, /obj/item/holochip) || istype(money, /obj/item/stack/spacecash))
				. += money.get_item_credit_value()

/// Экономические цели, где среди владельцев есть кто-то из minds.
/datum/objective/economy/proc/sibling_objectives()
	. = list()
	var/list/owners = get_owners()
	for(var/datum/objective/economy/other in GLOB.objectives)
		if(other != src && length(other.get_owners() & owners))
			. += other

/datum/objective/economy/embezzle
	name = "embezzle"
	var/target_department
	var/moved = 0

/datum/objective/economy/embezzle/New(text)
	. = ..()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_move))

/datum/objective/economy/embezzle/Destroy(force, ...)
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	return ..()

/datum/objective/economy/embezzle/lose_progress(amount)
	moved = max(moved - amount, 0)

/datum/objective/economy/embezzle/forge()
	var/list/departments = list(ACCOUNT_ENG, ACCOUNT_MED, ACCOUNT_SCI, ACCOUNT_SRV, ACCOUNT_CAR)
	for(var/id in departments)
		if(!SSeconomy.get_dep_account(id))
			departments -= id
	if(!length(departments))
		return FALSE
	target_department = pick(departments)
	var/share = rand(ECON_OBJECTIVE_EMBEZZLE_MIN, ECON_OBJECTIVE_EMBEZZLE_MAX)
	target_amount = max(round(SSeconomy.settings.department_start_budget * share / 100, ECON_OBJECTIVE_STEP), ECON_OBJECTIVE_STEP)
	return ..()

/datum/objective/economy/embezzle/claimed_account()
	return SSeconomy.get_dep_account(target_department)

/datum/objective/economy/embezzle/proc/on_move(datum/source, datum/bank_account/payer, datum/bank_account/payee, amount, reason, mob/actor)
	SIGNAL_HANDLER
	var/datum/bank_account/budget = SSeconomy.get_dep_account(target_department)
	if(!budget || note_put_back(payer, payee, amount, reason, actor))
		return
	if(payer != budget || !is_owner(actor))
		return
	if(payee == SSeconomy.cash_account || (payee in owner_accounts()))
		moved += count_taken(budget, payee, amount)
		note_threshold()

/datum/objective/economy/embezzle/goal_text()
	var/datum/economy_department/department = SSeconomy.get_department(target_department)
	return "Выведите [target_amount] кр. из бюджета отдела «[department?.name]» себе: на свой счёт, анонимную карту или наличными."

/datum/objective/economy/embezzle/how_to_text()
	return "Проще всего - Alt-клик по карте бюджета этого отдела: агенту она выдаёт наличные. Или премия себе в приложении «Бюджет отдела» на любом КПК: нужна ID-карта с доступом главы этого отдела, а премию можно выписать только его сотруднику. Считается то, что вы провели сами: на свой счёт, анонимную карту при себе или наличными. Возвращённое аудитом или внесённое вами обратно вычитается. Без вреда экипажу."

/datum/objective/economy/embezzle/threshold_text()
	return "Растрата набрана: выведено [moved] кр. из бюджета, задание выполнено."

/datum/objective/economy/embezzle/progress_text()
	return "выведено [moved] из [target_amount] кр."

/datum/objective/economy/embezzle/is_done()
	return moved >= target_amount

/datum/objective/economy/drain_head
	name = "drain head"
	required_opt_in_level = ANTAG_OPT_IN_TEMPORARY
	tool_type = /obj/item/card_skimmer
	var/target_account_id
	var/drained = 0

/datum/objective/economy/drain_head/New(text)
	. = ..()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_move))

/datum/objective/economy/drain_head/Destroy(force, ...)
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	return ..()

/datum/objective/economy/drain_head/forge()
	target_amount = SSeconomy.settings.wages[PAY_GRADE_COMMAND] * SSeconomy.settings.starting_paychecks
	return !!find_target()

/// Глава со своим счётом, согласный быть целью без убийства, не антагонист; без цели подписка снимается.
/datum/objective/economy/drain_head/find_target(dupe_search_range, blacklist)
	var/list/owners = get_owners()
	var/list/possible = list()
	for(var/datum/mind/candidate as anything in get_crewmember_minds())
		if((candidate in owners) || (candidate in blacklist) || !(candidate.assigned_role in GLOB.command_positions))
			continue
		if(!ishuman(candidate.current) || candidate.current.stat == DEAD || candidate.is_ghost_role() || brother_mind_is_antagonist(candidate))
			continue
		if(!opt_in_valid(candidate) || !is_unique_objective(candidate) || !econ_account_of(candidate.current))
			continue
		possible += candidate
	target = length(possible) ? pick(possible) : null
	var/datum/bank_account/account = target ? econ_account_of(target.current) : null
	target_account_id = account?.account_id
	drained = 0
	threshold_noted = FALSE
	if(target)
		RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_move), override = TRUE)
	else
		UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	update_explanation_text()
	return target

/datum/objective/economy/drain_head/claimed_account()
	return SSeconomy.find_account(target_account_id)

/datum/objective/economy/drain_head/lose_progress(amount)
	drained = max(drained - amount, 0)

/datum/objective/economy/drain_head/proc/on_move(datum/source, datum/bank_account/payer, datum/bank_account/payee, amount, reason, mob/actor)
	SIGNAL_HANDLER
	if(!target || !target_account_id || note_put_back(payer, payee, amount, reason, actor))
		return
	if(reason == ECON_AUCTION_REFUND && payee?.account_id == target_account_id)
		if(is_owner(actor))
			lose_progress(count_returned(payee, amount))
		return
	if(reason == ECON_REGISTER)
		return
	if(payer && payer.account_id == target_account_id && is_owner(actor))
		drained += count_taken(payer, payee, amount)
		note_threshold()

/datum/objective/economy/drain_head/threshold_reached()
	return drained >= target_amount

/datum/objective/economy/drain_head/threshold_text()
	return "Выкачано достаточно: [drained] кр. Теперь к концу смены на счёте [target?.name] должно остаться не больше [ECON_OBJECTIVE_DRAIN_LEFT] кр., а зарплата его пополняет."

/datum/objective/economy/drain_head/goal_text()
	return "Выкачайте [target_amount] кр. с личного счёта [target?.name] ([target?.assigned_role]) и оставьте на нём к концу смены не больше [ECON_OBJECTIVE_DRAIN_LEFT] кр."

/datum/objective/economy/drain_head/how_to_text()
	return "Подойдут скиммер, украденная ID-карта или снятие наличных с неё. Зарплата пополняет счёт каждые [DisplayTimeText(SSeconomy.wait * SSeconomy.settings.payroll_interval_ticks)], так что последнюю перекачку делайте ближе к концу смены. Деньги за его акции, которые биржа продаст в конце смены, в остаток не идут. Траты самого владельца, оплата на кассе и то, что вы вернёте на счёт, не засчитываются."

/// Остаток на счёте главы без денег, зачисленных продажей его акций в конце смены.
/datum/objective/economy/drain_head/proc/left_on_account()
	var/datum/bank_account/account = SSeconomy.find_account(target_account_id)
	return account ? account.account_balance - account.stock_autosold_credited : 0

/datum/objective/economy/drain_head/progress_text()
	return "выкачано [drained] из [target_amount] кр., на счёте [max(left_on_account(), 0)] кр."

/datum/objective/economy/drain_head/is_done()
	return SSeconomy.find_account(target_account_id) && drained >= target_amount && left_on_account() <= ECON_OBJECTIVE_DRAIN_LEFT

/datum/objective/economy/hoard
	name = "hoard"
	tool_type = /obj/item/anon_account_card
	var/stolen = 0
	/// В Лайте и Эксте кражей считаются только чужие личные счета
	var/allow_budgets = TRUE

/datum/objective/economy/hoard/New(text)
	. = ..()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED, PROC_REF(on_move))

/datum/objective/economy/hoard/Destroy(force, ...)
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_MOVED)
	return ..()

/datum/objective/economy/hoard/forge()
	allow_budgets = econ_harmful_objectives_allowed()
	target_amount = SSeconomy.settings.wages[PAY_GRADE_MEDIUM] * rand(ECON_OBJECTIVE_HOARD_MIN, ECON_OBJECTIVE_HOARD_MAX)
	target_amount = max(round(target_amount, ECON_OBJECTIVE_STEP), ECON_OBJECTIVE_STEP)
	return ..()

/datum/objective/economy/hoard/lose_progress(amount)
	stolen = max(stolen - amount, 0)

/// Кража - перевод, который владелец цели сам провёл с чужого счёта или бюджета себе или в наличные; возврат аудитом и положенное обратно её отнимают.
/datum/objective/economy/hoard/proc/on_move(datum/source, datum/bank_account/payer, datum/bank_account/payee, amount, reason, mob/actor)
	SIGNAL_HANDLER
	if(!payer || reason == ECON_REFUND || reason == ECON_REGISTER || !is_owner(actor) || note_put_back(payer, payee, amount, reason, actor))
		return
	var/list/mine = owner_accounts()
	if(payee != SSeconomy.cash_account && !(payee in mine))
		return
	if((payer in mine) || istype(payer, /datum/bank_account/anonymous) || payer.service_account)
		return
	var/datum/bank_account/department/budget = payer
	if(!SSeconomy.is_personal_account(payer) && !(allow_budgets && istype(budget) && budget.department))
		return
	for(var/datum/objective/economy/other as anything in sibling_objectives())
		if(other.claimed_account() == payer)
			return
	stolen += count_taken(payer, payee, amount)
	note_threshold()

/datum/objective/economy/hoard/threshold_reached()
	return stolen >= target_amount

/datum/objective/economy/hoard/threshold_text()
	return "Украдено достаточно: держите не меньше [target_amount] кр. у себя до конца смены - на своём счёте, анонимных картах или наличными."

/datum/objective/economy/hoard/proc/holdings()
	. = owner_cash()
	for(var/datum/bank_account/account as anything in owner_accounts())
		. += max(account.account_balance, 0)

/datum/objective/economy/hoard/goal_text()
	return "Украдите [target_amount] кр. с чужих личных счетов[allow_budgets ? " или бюджетов отделов" : ""] и держите к концу смены не меньше [target_amount] кр. у себя."

/datum/objective/economy/hoard/how_to_text()
	return "Кража - перевод или снятие наличных, которое вы сами сделали с чужого счёта: скиммером или украденной картой. Оплата на кассе - это продажа, а не кража. «У себя» - это ваш счёт, анонимные карты и наличные при вас. Зарплата, подарки и деньги с анонимных и служебных счетов не считаются; возвращённое аудитом и то, что вы сами вернёте, вычитается."

/datum/objective/economy/hoard/progress_text()
	return "украдено [stolen] из [target_amount] кр., у себя [holdings()] кр."

/datum/objective/economy/hoard/is_done()
	return stolen >= target_amount && holdings() >= target_amount

/datum/objective/economy/stock_profit
	name = "stock profit"
	tool_type = /obj/item/anon_account_card
	/// "номер счёта" -> прибыль на бирже, с которой счёт попал в учёт; счёт остаётся в учёте насовсем
	var/list/profit_baseline = list()
	/// "номер счёта" -> результат счёта на последней сделке: на случай, если счёт исчезнет
	var/list/profit_last = list()

/datum/objective/economy/stock_profit/New(text)
	. = ..()
	RegisterSignal(SSmarket, COMSIG_MARKET_STOCK_TRADE, PROC_REF(on_trade))

/datum/objective/economy/stock_profit/Destroy(force, ...)
	UnregisterSignal(SSmarket, COMSIG_MARKET_STOCK_TRADE)
	return ..()

/datum/objective/economy/stock_profit/forge()
	var/share = rand(ECON_OBJECTIVE_STOCK_MIN, ECON_OBJECTIVE_STOCK_MAX)
	target_amount = max(round(SSeconomy.settings.audit_insider_threshold * share / 100, ECON_OBJECTIVE_STEP), ECON_OBJECTIVE_STEP)
	for(var/datum/bank_account/account as anything in owner_accounts())
		profit_baseline["[account.account_id]"] = account.traded_stock_profit()
	return ..()

/datum/objective/economy/stock_profit/proc/on_trade(datum/source, datum/bank_account/account, ticker, count, price, is_buy, realized, mob/user)
	SIGNAL_HANDLER
	var/key = "[account.account_id]"
	if(isnull(profit_baseline[key]))
		if(!is_owner(user) && !(account in owner_accounts()))
			return
		profit_baseline[key] = account.traded_stock_profit() - realized
	profit_last[key] = account.traded_stock_profit() - profit_baseline[key]
	note_threshold()

/datum/objective/economy/stock_profit/threshold_text()
	return "Прибыль на бирже набрана: [profit()] кр. Не уходите в убыток до конца смены."

/datum/objective/economy/stock_profit/proc/profit()
	. = 0
	for(var/key in profit_baseline)
		var/datum/bank_account/account = SSeconomy.find_account(key)
		. += account ? account.traded_stock_profit() - profit_baseline[key] : profit_last[key]

/datum/objective/economy/stock_profit/goal_text()
	return "Заработайте на бирже [target_amount] кр. чистой прибыли."

/datum/objective/economy/stock_profit/how_to_text()
	return "Биржа - приложение «Биржа» на КПК: купите акции дешевле и продайте дороже. Считается прибыль с продаж после получения задания, со своего счёта и анонимных карт; убытки тоже считаются, даже если карта ушла из рук. Продажа непроданных акций в конце смены не считается. Пейджер инсайдера из аплинка заранее показывает настоящие новости компаний."

/datum/objective/economy/stock_profit/progress_text()
	return "прибыль [profit()] из [target_amount] кр."

/datum/objective/economy/stock_profit/is_done()
	return profit() >= target_amount

/datum/objective/economy/crash_stock
	name = "crash stock"
	var/company_ticker
	var/percent
	var/start_price
	/// Самая низкая цена, пока действовала своя плохая фальшивка о компании
	var/lowest_price
	var/fake_until = 0

/datum/objective/economy/crash_stock/New(text)
	. = ..()
	RegisterSignal(SSmarket, COMSIG_MARKET_STOCKS_TICKED, PROC_REF(on_tick))
	RegisterSignal(SSmarket, COMSIG_MARKET_COMPANY_EVENT, PROC_REF(on_company_event))

/datum/objective/economy/crash_stock/Destroy(force, ...)
	UnregisterSignal(SSmarket, list(COMSIG_MARKET_STOCKS_TICKED, COMSIG_MARKET_COMPANY_EVENT))
	return ..()

/// Компания, о которой фальшивка ещё не выходила и которую не роняет другая такая цель.
/datum/objective/economy/crash_stock/forge()
	var/list/tickers = list()
	for(var/ticker in SSmarket.companies)
		var/datum/stock_company/company = SSmarket.companies[ticker]
		if(company.is_index || company.is_halted() || (ticker in SSmarket.press_released) || company.price <= STOCK_PRICE_MIN + STOCK_PRICE_EPSILON)
			continue
		tickers += ticker
	for(var/datum/objective/economy/crash_stock/other in GLOB.objectives)
		if(other.is_active())
			tickers -= other.company_ticker
	if(!length(tickers))
		return FALSE
	return setup(pick(tickers), rand(ECON_OBJECTIVE_CRASH_MIN, ECON_OBJECTIVE_CRASH_MAX))

/datum/objective/economy/crash_stock/proc/setup(ticker, new_percent)
	var/datum/stock_company/company = SSmarket.get_company(ticker)
	if(!company)
		return FALSE
	company_ticker = ticker
	percent = new_percent
	start_price = company.price_without_work()
	lowest_price = null
	fake_until = 0
	update_explanation_text()
	return TRUE

/// Компания держится за целью, пока она не выполнена и числится за живым владельцем.
/datum/objective/economy/crash_stock/proc/reserves(datum/stock_company/company)
	return company?.ticker == company_ticker && !is_done() && is_active()

/// Обвал меряется ценой без сдвига от работы отделов: работа станции его не делает и не отменяет.
/datum/objective/economy/crash_stock/proc/note_price()
	var/datum/stock_company/company = SSmarket.get_company(company_ticker)
	if(company)
		var/clean_price = company.price_without_work()
		lowest_price = min(isnull(lowest_price) ? clean_price : lowest_price, clean_price)
		note_threshold()

/datum/objective/economy/crash_stock/threshold_text()
	return "Акции [company_ticker] обрушены: задание выполнено."

/datum/objective/economy/crash_stock/proc/on_tick(datum/source)
	SIGNAL_HANDLER
	if(world.time <= fake_until)
		note_price()

/datum/objective/economy/crash_stock/proc/on_company_event(datum/source, datum/market_event/event)
	SIGNAL_HANDLER
	if(event.company?.ticker != company_ticker)
		return
	if(event.refutes)
		fake_until = 0
		return
	if(!event.press_release || event.effect >= 0)
		return
	var/datum/mind/author = event.press_release_author?.resolve()
	if(!author || !(author in get_owners()))
		return
	fake_until = world.time + SSeconomy.settings.press_release_refute_minutes MINUTES
	note_price()

/datum/objective/economy/crash_stock/proc/target_price()
	return round(start_price * (100 - percent) / 100, 0.01)

/datum/objective/economy/crash_stock/goal_text()
	var/datum/stock_company/company = SSmarket.get_company(company_ticker)
	return "Обрушьте акции [company?.name] ([company_ticker]) на [percent]%: с [round(start_price, 0.01)] до [target_price()] кр. или ниже, пока ваш фальшивый пресс-релиз о компании не опровергли."

/datum/objective/economy/crash_stock/how_to_text()
	return "Фальшивый пресс-релиз продаёт аплинк, его же выпускает ньюскастер, взломанный емагом (Alt-клик). Выберите плохую новость о компании. Через [SSeconomy.settings.press_release_refute_minutes] мин. NT опровергнет релиз, и падение после этого уже не считается. О компании выходит одна фальшивка за смену, а в секторе - не чаще раза в [SSmarket.press_release_cooldown()] мин., поэтому выпускайте, когда акции уже слабы. Цена считается без сдвига от работы отделов. Без вреда станции."

/datum/objective/economy/crash_stock/progress_text()
	if(isnull(lowest_price))
		return "вашей плохой фальшивки о [company_ticker] ещё не было."
	return "самая низкая цена при вашей фальшивке [round(lowest_price, 0.01)] из нужных [target_price()] кр., без сдвига от работы станции."

/datum/objective/economy/crash_stock/is_done()
	return !isnull(lowest_price) && lowest_price <= start_price * (100 - percent) / 100

/// Фальшивый релиз о компании, которую держит чужое задание на обвал, не выйдет.
/proc/econ_press_release_reserved(datum/stock_company/company, datum/mind/author)
	for(var/datum/objective/economy/crash_stock/objective in GLOB.objectives)
		if((!author || !(author in objective.get_owners())) && objective.reserves(company))
			return TRUE
	return FALSE

/datum/objective/economy/smuggle
	name = "smuggle"
	/// ckey -> продано контрабанды при выдаче цели
	var/list/sold_baseline = list()

/datum/objective/economy/smuggle/forge()
	target_amount = SSeconomy.settings.contraband_value_per_tc * rand(ECON_OBJECTIVE_SMUGGLE_MIN, ECON_OBJECTIVE_SMUGGLE_MAX)
	target_amount = max(round(target_amount, ECON_OBJECTIVE_STEP), ECON_OBJECTIVE_STEP)
	for(var/datum/mind/mind as anything in get_owners())
		var/key = ckey(mind.key)
		if(key)
			sold_baseline[key] = SSmarket.contraband_exported_by[key] || 0
	return ..()

/datum/objective/economy/smuggle/proc/sold()
	. = 0
	for(var/datum/mind/mind as anything in get_owners())
		var/key = ckey(mind.key)
		if(key)
			. += (SSmarket.contraband_exported_by[key] || 0) - (sold_baseline[key] || 0)

/datum/objective/economy/smuggle/goal_text()
	return "Продайте Вольным торговцам контрабанды на [target_amount] кр. через шаттл снабжения."

/datum/objective/economy/smuggle/how_to_text()
	return "Торговцев открывает консоль снабжения, взломанная емагом. Контрабанда - предметы из аплинка, последними на товаре должны остаться ваши отпечатки. Таможня NT может досмотреть ящик и изъять груз."

/datum/objective/economy/smuggle/progress_text()
	return "продано [sold()] из [target_amount] кр."

/datum/objective/economy/smuggle/is_done()
	return sold() >= target_amount

/// В Лайте и Эксте - только цели без побочного вреда станции и экипажу.
/proc/econ_harmful_objectives_allowed()
	return GLOB.round_type != ROUNDTYPE_DYNAMIC_LIGHT && GLOB.round_type != ROUNDTYPE_EXTENDED

/// Контрабанды тут нет: продавать пришлось бы своё снаряжение из аплинка. Её выдаёт админ в панели целей.
/proc/econ_objective_types()
	. = list(/datum/objective/economy/hoard, /datum/objective/economy/stock_profit)
	if(econ_harmful_objectives_allowed())
		. += list(/datum/objective/economy/embezzle, /datum/objective/economy/drain_head, /datum/objective/economy/crash_stock)

/// Случайная экономическая цель, какой у владельца ещё нет; кража не выдаётся вместе с растратой и опустошением счёта главы. null - выдать нечего.
/proc/econ_random_objective(datum/mind/owner)
	var/list/candidates = econ_objective_types()
	var/list/owned = list()
	for(var/datum/objective/existing as anything in owner?.get_all_objectives())
		owned |= existing.type
	for(var/datum/objective/economy/existing in GLOB.objectives)
		if(owner && (owner in existing.get_owners()))
			owned |= existing.type
	candidates -= owned
	if((/datum/objective/economy/embezzle in owned) || (/datum/objective/economy/drain_head in owned))
		candidates -= /datum/objective/economy/hoard
	if(/datum/objective/economy/hoard in owned)
		candidates -= list(/datum/objective/economy/embezzle, /datum/objective/economy/drain_head)
	while(length(candidates))
		var/objective_type = pick_n_take(candidates)
		var/datum/objective/economy/objective = new objective_type
		objective.owner = owner
		if(objective.forge())
			return objective
		qdel(objective)
	return null

/// Шанс экономического задания: снабжению, сервису и командованию деньги ближе, остальным - дальше.
/proc/econ_objective_chance(datum/mind/owner)
	var/chance = SSeconomy.settings.traitor_econ_objective_chance
	var/role = owner?.assigned_role
	var/datum/job/job = role ? SSjob.GetJob(role) : null
	if((role in GLOB.command_positions) || (role in GLOB.supply_positions) || job?.paycheck_department == ACCOUNT_SRV)
		return min(chance * ECON_OBJECTIVE_CHANCE_MONEY_JOB, 100)
	return chance * ECON_OBJECTIVE_CHANCE_OTHER_JOB

/datum/traitor_class/human/proc/try_forge_economy_objective(datum/antagonist/traitor/T)
	if(T.economy_swap_used || !prob(econ_objective_chance(T.owner)))
		return FALSE
	var/datum/objective/economy/objective = econ_random_objective(T.owner)
	if(!objective)
		return FALSE
	T.add_objective(objective)
	objective.give_tool()
	return TRUE

/// Что агент узнаёт об экономических заданиях; null - таких заданий нет.
/datum/antagonist/traitor/proc/economy_objectives_note()
	if(!(locate(/datum/objective/economy) in objectives))
		return null
	var/kinds = econ_harmful_objectives_allowed() ? "кража со счетов, растрата бюджета, биржа" : "кража со счетов и биржа"
	. = "Экономические задания - про деньги станции: [kinds]. Под каждым в окне агента написано, как его выполнить."
	if(!economy_swap_used)
		. += " Если такое задание не по душе, одно можно один раз заменить на обычное кнопкой «Заменить», пока не вызван эвакуационный шаттл. Новое задание выпадет случайно, вернуть прежнее нельзя."

/// Почему это экономическое задание сейчас нельзя заменить; null - можно.
/datum/antagonist/traitor/proc/economy_swap_refusal(datum/objective/economy/objective, mob/user)
	if(economy_swap_used)
		return "Замена уже использована."
	if(!give_objectives || !istype(objective) || !(objective in objectives) || !istype(traitor_kind, /datum/traitor_class/human))
		return "Это задание не заменить."
	if(objective.team || length(objective.get_owners()) > 1)
		return "Общее задание не заменить."
	if(SSticker.current_state >= GAME_STATE_FINISHED)
		return "Смена уже закончилась."
	if(SSmarket.evac_underway())
		return ECON_OBJECTIVE_SWAP_EVAC_REFUSAL
	var/mob/living/body = owner?.current
	if(!user || user != body || !isliving(body) || body.stat == DEAD)
		return "Заменить задание может только живой агент."
	if(objective.check_completion())
		return "Задание уже выполнено."
	return null

/// Разовая бесплатная замена экономического задания на обычное задание своего класса, на то же место в списке.
/datum/antagonist/traitor/proc/swap_economy_objective(datum/objective/economy/old, mob/user)
	var/refusal = economy_swap_refusal(old, user)
	if(refusal)
		to_chat(user, span_warning(refusal))
		update_static_data(user)
		return FALSE
	economy_swap_used = TRUE
	var/datum/traitor_class/human/class = traitor_kind
	var/list/before = objectives.Copy()
	var/datum/objective/replacement
	for(var/attempt in 1 to ECON_OBJECTIVE_SWAP_ATTEMPTS)
		class.forge_single_objective(src)
		var/list/added = objectives - before
		if(length(added))
			replacement = added[1]
			break
	if(!replacement)
		economy_swap_used = FALSE
		to_chat(user, span_warning("Обычного задания для замены сейчас нет, попробуйте позже."))
		update_static_data(user)
		return FALSE
	objectives -= replacement
	objectives.Insert(objectives.Find(old), replacement)
	objectives -= old
	log_game("[key_name(user)] заменил экономическое задание предателя \"[old.explanation_text]\" на \"[replacement.explanation_text]\".")
	message_admins("[ADMIN_LOOKUPFLW(user)] заменил экономическое задание предателя ([old.name]) на: [replacement.explanation_text]")
	qdel(old)
	to_chat(user, span_notice("Экономическое задание заменено. Новое задание: [replacement.explanation_text]"))
	update_static_data_for_all_viewers()
	return TRUE
