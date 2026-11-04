/datum/objective/economy
	name = "economy"
	/// "номер счёта" -> засчитанное с него и ещё не вернувшееся
	var/list/taken_from = list()
	/// Номера счетов, куда пришли засчитанные деньги: возврат с них аудитом отнимает засчитанное
	var/list/recipient_ids = list()

/datum/objective/economy/New(text)
	. = ..()
	RegisterSignal(SSeconomy, COMSIG_ECONOMY_AUDIT_REFUNDED, PROC_REF(on_audit_refund))

/datum/objective/economy/Destroy(force, ...)
	UnregisterSignal(SSeconomy, COMSIG_ECONOMY_AUDIT_REFUNDED)
	return ..()

/datum/objective/economy/proc/forge()
	update_explanation_text()
	return TRUE

/datum/objective/economy/proc/goal_text()
	return ""

/datum/objective/economy/proc/progress_text()
	return ""

/datum/objective/economy/proc/is_done()
	return FALSE

/// Чужой счёт, перевод с которого засчитывает эта цель: другие цели того же владельца его не берут.
/datum/objective/economy/proc/claimed_account()
	return null

/datum/objective/economy/update_explanation_text()
	explanation_text = goal_text()

/datum/objective/economy/proc/refresh_progress()
	explanation_text = "[goal_text()] Сейчас: [progress_text()]."

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

/datum/objective/economy/embezzle/goal_text()
	var/datum/economy_department/department = SSeconomy.get_department(target_department)
	return "Выведите из бюджета отдела «[department?.name]» не меньше [target_amount] кр.: на свой счёт или анонимную карту при себе либо наличными с карты бюджета. Деньги, которые финансовый аудит вернёт отделу или вы сами внесёте обратно наличными или переводом, не засчитываются. Без вреда экипажу."

/datum/objective/economy/embezzle/progress_text()
	return "выведено [moved] из [target_amount] кр."

/datum/objective/economy/embezzle/is_done()
	return moved >= target_amount

/datum/objective/economy/drain_head
	name = "drain head"
	required_opt_in_level = ANTAG_OPT_IN_TEMPORARY
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
	if(payer && payer.account_id == target_account_id && is_owner(actor))
		drained += count_taken(payer, payee, amount)

/datum/objective/economy/drain_head/goal_text()
	return "Выкачайте с личного счёта [target?.name] ([target?.assigned_role]) не меньше [target_amount] кр. - скиммером, украденной картой или снятием наличных с неё - и оставьте на счёте к концу смены не больше [ECON_OBJECTIVE_DRAIN_LEFT] кр. Зарплата пополняет счёт каждые [DisplayTimeText(SSeconomy.wait * SSeconomy.settings.payroll_interval_ticks)], так что последнюю перекачку делайте ближе к концу смены. Траты самого владельца и то, что вы внесёте обратно наличными или переводом, не засчитываются."

/datum/objective/economy/drain_head/progress_text()
	var/datum/bank_account/account = SSeconomy.find_account(target_account_id)
	return "выкачано [drained] из [target_amount] кр., на счёте [account ? account.account_balance : 0] кр."

/datum/objective/economy/drain_head/is_done()
	var/datum/bank_account/account = SSeconomy.find_account(target_account_id)
	return account && drained >= target_amount && account.account_balance <= ECON_OBJECTIVE_DRAIN_LEFT

/datum/objective/economy/hoard
	name = "hoard"
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
	if(!payer || reason == ECON_REFUND || !is_owner(actor) || note_put_back(payer, payee, amount, reason, actor))
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

/datum/objective/economy/hoard/proc/holdings()
	. = owner_cash()
	for(var/datum/bank_account/account as anything in owner_accounts())
		. += max(account.account_balance, 0)

/datum/objective/economy/hoard/goal_text()
	return "Украдите не меньше [target_amount] кр. с чужих личных счетов[allow_budgets ? " и бюджетов отделов" : ""] - скиммером, украденной картой, снятием наличных с неё - и сохраните к концу смены не меньше [target_amount] кр. на своём счёте, анонимных картах при себе и наличными при себе. Честный заработок, чужие подарки и деньги с анонимных и служебных счетов кражей не считаются; возвращённое аудитом и внесённое вами обратно наличными или переводом вычитается."

/datum/objective/economy/hoard/progress_text()
	return "украдено [stolen] кр., при себе [holdings()] кр."

/datum/objective/economy/hoard/is_done()
	return stolen >= target_amount && holdings() >= target_amount

/datum/objective/economy/stock_profit
	name = "stock profit"
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
		profit_baseline["[account.account_id]"] = account.realized_stock_profit
	return ..()

/datum/objective/economy/stock_profit/proc/on_trade(datum/source, datum/bank_account/account, ticker, count, price, is_buy, realized, mob/user)
	SIGNAL_HANDLER
	var/key = "[account.account_id]"
	if(isnull(profit_baseline[key]))
		if(!is_owner(user) && !(account in owner_accounts()))
			return
		profit_baseline[key] = account.realized_stock_profit - realized
	profit_last[key] = account.realized_stock_profit - profit_baseline[key]

/datum/objective/economy/stock_profit/proc/profit()
	. = 0
	for(var/key in profit_baseline)
		var/datum/bank_account/account = SSeconomy.find_account(key)
		. += account ? account.realized_stock_profit - profit_baseline[key] : profit_last[key]

/datum/objective/economy/stock_profit/goal_text()
	return "Заработайте на бирже сектора не меньше [target_amount] кр. чистой прибыли с продаж акций, считая с получения задания: со своего счёта и анонимных карт. Убытки счёта, с которого вы торговали, считаются и после того, как карта ушла из рук."

/datum/objective/economy/stock_profit/progress_text()
	return "прибыль [profit()] кр."

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
		if(company.is_halted() || (ticker in SSmarket.press_released) || company.price <= STOCK_PRICE_MIN + STOCK_PRICE_EPSILON)
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
	start_price = company.price
	lowest_price = null
	fake_until = 0
	update_explanation_text()
	return TRUE

/// Компания держится за целью, пока она не выполнена и числится за живым владельцем.
/datum/objective/economy/crash_stock/proc/reserves(datum/stock_company/company)
	return company?.ticker == company_ticker && !is_done() && is_active()

/datum/objective/economy/crash_stock/proc/note_price()
	var/datum/stock_company/company = SSmarket.get_company(company_ticker)
	if(company)
		lowest_price = min(isnull(lowest_price) ? company.price : lowest_price, company.price)

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
	return "Обрушьте акции [company?.name] ([company_ticker]) хотя бы на [percent]% от цены при получении задания, [round(start_price, 0.01)] кр.: пока ваш плохой фальшивый пресс-релиз о компании не опровергнут, цена должна опуститься до [target_price()] кр. или ниже. Фальшивку дают аплинк и взломанный ньюскастер; о компании она выходит одна за смену, чужих о ней не пропустят, пока задание не выполнено, а в секторе фальшивки выходят не чаще раза в [SSmarket.press_release_cooldown()] мин. Выпускайте, когда акции уже слабы. Без вреда станции."

/datum/objective/economy/crash_stock/progress_text()
	if(isnull(lowest_price))
		return "вашей плохой фальшивки о [company_ticker] ещё не было"
	return "самая низкая цена при вашей фальшивке [round(lowest_price, 0.01)] кр."

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
	return "Продайте Вольным торговцам через шаттл снабжения контрабанды не меньше чем на [target_amount] кр. Торговцев открывает взлом консоли снабжения, последними на товаре должны остаться ваши отпечатки, а таможня NT может досмотреть ящик и изъять груз."

/datum/objective/economy/smuggle/progress_text()
	return "продано на [sold()] кр."

/datum/objective/economy/smuggle/is_done()
	return sold() >= target_amount

/// В Лайте и Эксте - только цели без побочного вреда станции и экипажу.
/proc/econ_harmful_objectives_allowed()
	return GLOB.round_type != ROUNDTYPE_DYNAMIC_LIGHT && GLOB.round_type != ROUNDTYPE_EXTENDED

/proc/econ_objective_types()
	. = list(/datum/objective/economy/hoard, /datum/objective/economy/stock_profit)
	if(econ_harmful_objectives_allowed())
		. += list(/datum/objective/economy/embezzle, /datum/objective/economy/drain_head, /datum/objective/economy/crash_stock, /datum/objective/economy/smuggle)

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

/datum/traitor_class/human/proc/try_forge_economy_objective(datum/antagonist/traitor/T)
	if(!prob(SSeconomy.settings.traitor_econ_objective_chance))
		return FALSE
	var/datum/objective/economy/objective = econ_random_objective(T.owner)
	if(!objective)
		return FALSE
	T.add_objective(objective)
	return TRUE
