/datum/round_event_control
	/// ECON_STATE_* -> множитель веса у директора; состояния без записи - 1
	var/list/econ_state_weights

/datum/round_event_control/get_weight(datum/director_signals/signals)
	return ..() * econ_weight_mult()

/datum/round_event_control/proc/econ_weight_mult()
	if(!length(econ_state_weights))
		return 1
	var/mult = econ_state_weights[SSeconomy.economy_state]
	return isnum(mult) ? mult : 1

/// Выкуп налётчиков: не меньше minimum и share процентов казны, с округлением вниз до тысяч.
/proc/econ_ransom_demand(minimum, share)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	return max(minimum, FLOOR((treasury ? treasury.account_balance : 0) * share / 100, 1000))

/// Платит выкуп из казны; если в ней не хватает денег, не списывает ничего.
/proc/pirates_pay_ransom(amount, payee)
	var/datum/bank_account/treasury = SSeconomy.treasury()
	return !!treasury?.debit(amount, ECON_EVENT_RANSOM, memo = "Выкуп: [payee]")
