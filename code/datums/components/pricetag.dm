/datum/component/pricetag
	///Payee gets 100% of the value if no ratio has been set.
	var/default_profit_ratio = 1
	///List of bank accounts this pricetag pays out to. Format is payees[bank_account] = profit_ratio.
	var/list/payees = list()


/datum/component/pricetag/Initialize(_owner,_profit_ratio)
	if(!isobj(parent))	//Has to account for both objects and sellable structures like crates.
		return COMPONENT_INCOMPATIBLE
	if(_profit_ratio)
		payees[_owner] = _profit_ratio
	else
		payees[_owner] = default_profit_ratio
	RegisterSignal(parent, COMSIG_ITEM_SOLD, PROC_REF(split_profit))
	RegisterSignal(parent, COMSIG_STRUCTURE_UNWRAPPED, PROC_REF(Unwrapped))
	RegisterSignal(parent, COMSIG_ITEM_UNWRAPPED, PROC_REF(Unwrapped))
	RegisterSignal(parent, COMSIG_ITEM_SPLIT_PROFIT, PROC_REF(return_ratio))

/datum/component/pricetag/proc/Unwrapped()
	qdel(src) //Once it leaves it's wrapped container, the object in question should lose it's pricetag component.

/datum/component/pricetag/proc/split_profit(var/item_value)
	var/price = item_value
	if(price)
		for(var/datum/bank_account/payee in payees)
			var/profit_ratio = payees[payee]
			var/adjusted_value = round(price * profit_ratio)
			var/datum/bank_account/bank_account = payee
			if(!bank_account.credit(adjusted_value, ECON_EXPORT, memo = "Продажа: [parent]"))
				continue
			bank_account.bank_card_talk("Продажа [parent] по штрихкоду: на счёт зачислено [adjusted_value] кр.")
		return TRUE

/datum/component/pricetag/proc/return_ratio()
// BLUEMOON CHANGE реальный срез профита выгодаполучателям за отсканирование товаров
	var/profit_loss = 0
	for(var/datum/bank_account/payee in payees)
		profit_loss += payees[payee]
	return min(profit_loss * 100 , 100)
// BLUEMOON CHANGE END
