/datum/economy_ledger
	var/minted = 0
	var/burned = 0
	/// reason -> сумма за раунд
	var/list/by_reason = list()
	/// Последние ECON_SNAPSHOT_MAX снимков: time, minted, burned, in_accounts, cash
	var/list/snapshots = list()
	var/last_minted = 0
	var/last_burned = 0
	/// Деньги бюджетов станционных отделов: эмиссия в бюджеты, сожжённое из них, ушедшее из них на счета и пришедшее со счетов
	var/department_minted = 0
	var/department_burned = 0
	var/department_paid_out = 0
	var/department_received = 0
	/// id отдела -> list("kept", "burned", "returned", "purchases", "purchase_amount") для панели калибровки
	var/list/department_flows = list()

/datum/bank_account
	/// Подъёмные смены: от них панель считает рост личных денег
	var/starting_funds = 0

/datum/bank_account/department
	/// Части защиты, ушедшие последним расходом бюджета: list(сумма, тик истечения)
	var/list/department_shield_spent = list()

/datum/supply_order
	/// Части защиты, потраченные предоплатой: отмена заказа возвращает их с прежними сроками
	var/list/shield_entries = list()

/datum/economy_ledger/proc/record(datum/bank_account/source, datum/bank_account/target, amount, reason)
	by_reason[reason] += amount
	if(!source)
		minted += amount
	if(!target)
		burned += amount
	if(reason == ECON_STARTING_FUNDS && target)
		target.starting_funds += amount
	var/from_budget = econ_is_station_budget(source)
	var/to_budget = econ_is_station_budget(target)
	var/datum/bank_account/department/payer_budget = from_budget ? source : null
	var/datum/bank_account/department/payee_budget = to_budget ? target : null
	if(payer_budget && reason != ECON_BUDGET_RETURN)
		payer_budget.department_shield_spent = payer_budget.department.consume_shield(amount)
	if(payee_budget && (reason in GLOB.econ_cap_shielded_reasons) && (!payer_budget || payer_budget.department_id == ACCOUNT_CMD))
		payee_budget.department.add_shield(amount)
	if(from_budget && to_budget)
		department_flow(payer_budget.department_id)["kept"] -= amount
		department_flow(payee_budget.department_id)["kept"] += amount
		return
	if(!from_budget && !to_budget)
		return
	if(to_budget && !source && reason == ECON_REFUND)
		department_flow(payee_budget.department_id)["burned"] -= amount
		department_burned -= amount
		return
	var/datum/bank_account/department/station_budget = to_budget ? target : source
	var/list/flow = department_flow(station_budget.department_id)
	if(to_budget)
		flow["kept"] += amount
		if(source)
			department_received += amount
		else
			department_minted += amount
		return
	if(target)
		flow["kept"] -= amount
		department_paid_out += amount
		return
	department_burned += amount
	flow["burned"] += amount
	if(reason == ECON_BUDGET_RETURN)
		flow["returned"] += amount
	if(reason == ECON_IMPORT)
		flow["purchases"] += 1
		flow["purchase_amount"] += amount

/datum/economy_ledger/proc/department_flow(id)
	var/list/flow = department_flows[id]
	if(!flow)
		flow = list("kept" = 0, "burned" = 0, "returned" = 0, "purchases" = 0, "purchase_amount" = 0)
		department_flows[id] = flow
	return flow

/// Доля стоков отделов; без with_return возврат излишка не входит ни в стоки, ни в оставшиеся деньги, без with_command казна не считается.
/datum/economy_ledger/proc/department_share_of(with_return = TRUE, with_command = TRUE)
	var/kept = 0
	var/burned_sum = 0
	for(var/id in department_flows)
		if(!with_command && id == ACCOUNT_CMD)
			continue
		var/list/flow = department_flows[id]
		kept += flow["kept"]
		burned_sum += flow["burned"]
		if(!with_return)
			kept -= flow["returned"]
			burned_sum -= flow["returned"]
	return kept > 0 ? burned_sum / kept : 0

/// Доля сожжённого из денег, оставшихся у отделов: (эмиссия в бюджеты + пришедшее со счетов - выплаченное на счета). Цель - department_sink_target_min..max из настроек.
/datum/economy_ledger/proc/department_sink_share()
	var/kept = department_minted + department_received - department_paid_out
	return kept > 0 ? department_burned / kept : 0

/proc/econ_is_station_budget(datum/bank_account/account)
	var/datum/bank_account/department/budget = account
	return istype(budget) && !!budget.department

/datum/economy_ledger/proc/snapshot()
	var/cash = SSeconomy.cash_account?.account_balance || 0
	snapshots += list(list(
		"time" = world.time,
		"minted" = minted - last_minted,
		"burned" = burned - last_burned,
		"in_accounts" = SSeconomy.total_money() - cash,
		"cash" = cash,
	))
	last_minted = minted
	last_burned = burned
	if(length(snapshots) > ECON_SNAPSHOT_MAX)
		snapshots.Cut(1, 2)

/datum/controller/subsystem/economy/proc/move(datum/bank_account/source, datum/bank_account/target, amount, reason, mob/actor, memo)
	if(!isnum(amount) || amount <= 0)
		return FALSE
	amount = round(amount)
	if(!amount || source == target || (!source && !target))
		return FALSE
	if(!istext(reason) || !GLOB.econ_reason_category[reason])
		stack_trace("SSeconomy.move: неизвестная причина [reason]")
		return FALSE
	if(source)
		if(source.state == ACCOUNT_FROZEN && !(reason in GLOB.econ_reasons_ignore_freeze))
			return FALSE
		if(source.account_balance < amount && !source.allow_debt)
			return FALSE
		source.account_balance -= amount
	if(target)
		target.account_balance += amount
	record_move(source, target, amount, reason, actor, memo)
	return TRUE

/// Учёт уже совершённого движения: журнал, истории счетов, сигнал и лог. log_tag - пометка только для лога.
/datum/controller/subsystem/economy/proc/record_move(datum/bank_account/source, datum/bank_account/target, amount, reason, mob/actor, memo, log_tag)
	ledger.record(source, target, amount, reason)
	var/label = memo || econ_reason_name(reason)
	source?.add_log_to_history(-amount, label, target ? target.account_holder : "Nanotrasen", reason, target?.account_id)
	target?.add_log_to_history(amount, label, source ? source.account_holder : "Nanotrasen", reason, source?.account_id)
	audit_move(source, target, amount, reason, actor)
	SEND_SIGNAL(src, COMSIG_ECONOMY_MOVED, source, target, amount, reason, actor)
	log_econ("[amount] кр.: [source ? source.account_holder : "эмиссия"] -> [target ? target.account_holder : "сток"] ([reason][log_tag ? ", [log_tag]" : ""])[actor ? " by [key_name(actor)]" : ""]")

/datum/controller/subsystem/economy/proc/find_account(number)
	return accounts_by_number["[number]"]

/datum/controller/subsystem/economy/proc/total_money()
	. = 0
	for(var/number in accounts_by_number)
		var/datum/bank_account/account = accounts_by_number[number]
		. += account.account_balance

/datum/controller/subsystem/economy/proc/register_account(datum/bank_account/account)
	if(account.account_id && !accounts_by_number["[account.account_id]"])
		accounts_by_number["[account.account_id]"] = account
		return
	for(var/attempt in 1 to 1000)
		var/number = rand(111111, 999999)
		if(accounts_by_number["[number]"])
			continue
		account.account_id = number
		accounts_by_number["[number]"] = account
		return
	CRASH("SSeconomy: не нашлось свободного номера счёта")

/datum/controller/subsystem/economy/proc/unregister_account(datum/bank_account/account, number)
	if(isnull(number))
		number = account.account_id
	if(accounts_by_number["[number]"] == account)
		accounts_by_number -= "[number]"

/datum/bank_account/proc/credit(amount, reason, mob/actor, memo)
	return SSeconomy.move(null, src, amount, reason, actor, memo)

/datum/bank_account/proc/debit(amount, reason, mob/actor, memo)
	return SSeconomy.move(src, null, amount, reason, actor, memo)
