/datum/bank_account
	var/pay_grade
	/// Надбавка главы, проценты от грейда
	var/wage_bonus = 0
	var/owed_wages = 0
	var/datum/weakref/owner_ref
	/// Разум владельца: по нему счёт находит новое тело после гиба или клонирования
	var/datum/weakref/owner_mind_ref
	/// world.time, с которого владелец без клиента или мёртв; 0 - в игре
	var/away_since = 0
	/// тикер -> число акций
	var/list/shares = list()
	/// тикер -> сколько уплачено за акции на руках, с комиссией
	var/list/cost_basis = list()
	var/realized_stock_profit = 0
	/// тикер -> world.time последней сделки
	var/list/trade_cooldowns = list()
	/// Общий служебный счёт команды (инспекция Sol): скиммер его не копирует, кража с него не засчитывается
	var/service_account = FALSE

/datum/bank_account/proc/set_job(datum/job/job)
	var/old_department = department_id
	account_job = job
	pay_grade = null
	department_id = null
	if(job?.paycheck > 0 && job.paycheck_department)
		department_id = job.paycheck_department
		pay_grade = econ_pay_grade(job.paycheck)
	if(department_id != old_department)
		owed_wages = 0
		wage_bonus = 0

/datum/bank_account/proc/bind_owner(mob/living/owner)
	owner_ref = WEAKREF(owner)
	owner_mind_ref = owner?.mind ? WEAKREF(owner.mind) : null
	away_since = 0

/datum/bank_account/proc/wage_amount()
	if(!pay_grade)
		return 0
	return round(SSeconomy.settings.wages[pay_grade] * (100 + wage_bonus) / 100)

/datum/bank_account/proc/update_dormancy()
	if(state == ACCOUNT_FROZEN || !owner_ref)
		return
	var/mob/living/owner = owner_ref.resolve()
	if(owner?.mind && !owner_mind_ref)
		owner_mind_ref = WEAKREF(owner.mind)
	var/datum/mind/owner_mind = owner_mind_ref?.resolve()
	var/mob/living/current_body = owner_mind?.current
	if(isliving(current_body) && current_body != owner)
		owner_ref = WEAKREF(current_body)
		owner = current_body
	if(!owner || owner.stat == DEAD || !GET_CLIENT(owner))
		if(!away_since)
			away_since = world.time
	else
		away_since = 0
	if(away_since && world.time - away_since > SSeconomy.settings.dormant_after_minutes MINUTES)
		state = ACCOUNT_DORMANT
	else if(!away_since && state == ACCOUNT_DORMANT)
		state = ACCOUNT_ACTIVE

/// Экипаж станции: NT платит ему минимум и без оклада или отдела, например после увольнения. Безбилетнику не платит.
/datum/bank_account/proc/nt_floor_crew()
	return !!owner_ref && !offstation && !istype(account_job, /datum/job/stowaway)

/datum/bank_account/proc/payday()
	if(state == ACCOUNT_DORMANT || (!pay_grade && !nt_floor_crew()))
		return 0
	var/wage = wage_amount()
	var/owed_cap = pay_grade ? SSeconomy.settings.wages[pay_grade] * SSeconomy.settings.owed_wages_cap_paychecks : 0
	if(state == ACCOUNT_FROZEN)
		owed_wages = min(owed_wages + wage, owed_cap)
		return 0
	var/datum/economy_department/department = pay_grade ? SSeconomy.get_department(department_id) : null
	var/due = wage + owed_wages
	var/paid = 0
	var/net = 0
	if(department)
		paid = min(due, max(department.account.account_balance, 0))
		if(paid && SSeconomy.move(department.account, src, paid, ECON_WAGE))
			net = SSeconomy.collect_tax(src, paid, ECON_WAGE)
		else
			paid = 0
	owed_wages = min(due - paid, owed_cap)
	var/floor = SSeconomy.settings.wage_floor
	if(paid < floor)
		net += SSeconomy.pay_personal(null, src, floor - paid, ECON_WAGE_FLOOR)
	bank_card_talk("Зарплата: [max(paid, floor)] кр. до налога, на руки [net] кр.[owed_wages ? " Отдел должен вам [owed_wages] кр." : ""]", FALSE, 'sound/economy/coin_soft.ogg', net ? "зарплата +[net] кр" : null)
	return max(paid, floor)

/// Владелец счёта - этот моб или его разум в другом теле.
/datum/bank_account/proc/owned_by(mob/user)
	if(!user)
		return FALSE
	if(owner_ref?.resolve() == user)
		return TRUE
	return !!user.mind && owner_mind_ref?.resolve() == user.mind

/// История операций для окон: time, label, amount, counterparty.
/datum/bank_account/proc/ui_history()
	. = list()
	for(var/datum/transaction/entry in transaction_history)
		. += list(list(
			"time" = entry.time,
			"label" = entry.purpose,
			"amount" = entry.amount,
			"counterparty" = entry.counterparty_number ? "[entry.target_name] (№[entry.counterparty_number])" : entry.target_name,
		))
