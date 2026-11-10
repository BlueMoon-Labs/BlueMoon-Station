/// Ранги подрядчика по возрастанию репутации: сколько контрактов держит одновременно и надбавка NT к его доле награды, проценты.
GLOBAL_LIST_INIT(econ_contract_ranks, list(
	list("rep" = 0, "name" = "Новичок", "slots" = 1, "bonus" = 0),
	list("rep" = 3, "name" = "Подрядчик", "slots" = 2, "bonus" = 0),
	list("rep" = 8, "name" = "Надёжный подрядчик", "slots" = 2, "bonus" = 10),
	list("rep" = 15, "name" = "Доверенный поставщик", "slots" = 3, "bonus" = 20),
))

/datum/bank_account
	/// Репутация подрядчика за смену
	var/contract_rep = 0
	var/contracts_done = 0
	COOLDOWN_DECLARE(contract_reroll_cooldown)

/datum/bank_account/proc/contract_rank()
	for(var/list/rank as anything in GLOB.econ_contract_ranks)
		if(contract_rep >= rank["rep"])
			. = rank

/datum/bank_account/proc/contract_slots()
	var/list/rank = contract_rank()
	return rank["slots"]

/datum/bank_account/proc/contract_rank_bonus()
	var/list/rank = contract_rank()
	return rank["bonus"]

/datum/bank_account/proc/adjust_contract_rep(delta)
	var/list/before = contract_rank()
	contract_rep = max(contract_rep + delta, 0)
	var/list/after = contract_rank()
	if(after == before)
		return
	if(after["rep"] > before["rep"])
		bank_card_talk("Репутация подрядчика выросла: теперь вы [after["name"]]. Контрактов одновременно: [after["slots"]][after["bonus"] ? ", надбавка NT к вашей доле: [after["bonus"]]%" : ""].")
	else
		bank_card_talk("Репутация подрядчика упала: теперь вы [after["name"]].")

/datum/bank_account/proc/contract_done(rep)
	contracts_done++
	adjust_contract_rep(rep)

/datum/bank_account/proc/contract_rank_data()
	var/list/rank = contract_rank()
	var/list/next_rank
	for(var/list/candidate as anything in GLOB.econ_contract_ranks)
		if(candidate["rep"] > contract_rep)
			next_rank = candidate
			break
	return list(
		"name" = rank["name"],
		"rep" = contract_rep,
		"done" = contracts_done,
		"slots" = rank["slots"],
		"used" = length(SSeconomy.contracts_taken_by(src)),
		"bonus" = rank["bonus"],
		"next_name" = next_rank?["name"],
		"next_rep" = next_rank?["rep"],
	)

/// "Подрядчик (от 3) - 2 контракта сразу; ..." для справки.
/proc/econ_contract_ranks_text()
	var/list/parts = list()
	for(var/list/rank as anything in GLOB.econ_contract_ranks)
		if(!rank["rep"])
			continue
		parts += "[rank["name"]] (от [rank["rep"]]) - контрактов сразу: [rank["slots"]][rank["bonus"] ? ", надбавка к доле [rank["bonus"]]%" : ""]"
	return parts.Join("; ")
