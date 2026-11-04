/datum/controller/subsystem/economy/proc/treasury()
	var/datum/economy_department/command = departments[ACCOUNT_CMD]
	return command?.account

/datum/controller/subsystem/economy/proc/pay_personal(datum/bank_account/source, datum/bank_account/target, amount, reason, mob/actor, memo)
	if(!move(source, target, amount, reason, actor, memo))
		return 0
	return collect_tax(target, round(amount), reason, actor)

/// Удерживает налог с уже зачисленного дохода, возвращает остаток после налога.
/datum/controller/subsystem/economy/proc/collect_tax(datum/bank_account/target, amount, reason, mob/actor)
	if(!tax_rate || reason == ECON_WAGE_FLOOR || istype(target, /datum/bank_account/department) || !(GLOB.econ_reason_category[reason] in GLOB.econ_taxable_categories))
		return amount
	var/tax = round(amount * tax_rate / 100)
	if(tax <= 0)
		return amount
	var/nt_part = round(tax * settings.tax_nt_share / 100)
	if(nt_part > 0 && !move(target, null, nt_part, ECON_TAX_NT, actor, "Налог [tax_rate]%: доля NT"))
		return amount
	if(tax - nt_part > 0 && !move(target, treasury(), tax - nt_part, ECON_TAX, actor, "Налог [tax_rate]%: в казну"))
		return amount - nt_part
	return amount - tax

/datum/controller/subsystem/economy/proc/set_tax_rate(rate, mob/user)
	if(!isnum(rate))
		return FALSE
	tax_rate = clamp(round(rate), 0, settings.tax_max)
	log_econ("Налог установлен в [tax_rate]%[user ? " ([key_name(user)])" : ""]")
	return TRUE

/datum/controller/subsystem/economy/proc/treasury_transfer(datum/economy_department/target, amount, mob/user)
	if(!target || target.id == ACCOUNT_CMD)
		return FALSE
	return move(treasury(), target.account, amount, ECON_BUDGET_TRANSFER, user, "Из казны: [target.name]")

/datum/controller/subsystem/economy/proc/department_transfer(datum/economy_department/source, datum/economy_department/target, amount, mob/user)
	if(!source || !target || source == target)
		return FALSE
	return move(source.account, target.account, amount, ECON_BUDGET_TRANSFER, user, "[source.name] -> [target.name]")

/datum/bank_account
	/// Открыт из казны: пока у счёта нет owner_ref, он в лимите treasury_unowned_accounts_max; привязка к карте Alt-кликом owner_ref не ставит, так что лимит фактически на смену
	var/opened_by_treasury = FALSE

/datum/controller/subsystem/economy/proc/unowned_treasury_accounts()
	. = 0
	for(var/datum/bank_account/account as anything in bank_accounts)
		if(account.opened_by_treasury && !account.owner_ref)
			.++

/datum/controller/subsystem/economy/proc/open_account(holder, starting_funds, mob/user)
	if(!istext(holder) || !length(holder) || !isnum(starting_funds) || starting_funds < 0)
		return null
	if(unowned_treasury_accounts() >= settings.treasury_unowned_accounts_max)
		return null
	starting_funds = round(starting_funds)
	var/datum/bank_account/department/treasury = treasury()
	if(starting_funds && !treasury?.has_money(starting_funds))
		return null
	var/datum/bank_account/opened = new(holder)
	opened.opened_by_treasury = TRUE
	if(starting_funds && !move(treasury, opened, starting_funds, ECON_BUDGET_TRANSFER, user, "Открытие счёта"))
		qdel(opened)
		return null
	log_econ("Открыт счёт [holder] №[opened.account_id] с [starting_funds] кр.[user ? " ([key_name(user)])" : ""]")
	return opened
