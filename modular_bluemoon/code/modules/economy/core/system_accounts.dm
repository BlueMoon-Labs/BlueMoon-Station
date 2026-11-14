/// Внутренний контрагент экономики (наличные, биржа): может уходить в минус, не входит в личные счета.
/datum/bank_account/system
	add_to_accounts = FALSE
	allow_debt = TRUE
	transferable = FALSE
