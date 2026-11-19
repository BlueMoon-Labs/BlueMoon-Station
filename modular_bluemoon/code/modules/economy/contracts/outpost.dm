/// Заказы ЦК, которые экипаж аванпоста делает своими руками: id бюджета -> базовые типы баунти вместе с подтипами. На обоих аванпостах есть гидропоника, кухня и химия; бар и пустоши Лаваленда - только у Deep Space.
GLOBAL_LIST_INIT(econ_outpost_bounty_bases, list(
	ACCOUNT_TAR = list(
		/datum/bounty/item/botany,
		/datum/bounty/item/chef,
		/datum/bounty/item/gardencook,
		/datum/bounty/reagent/chemical,
	),
	ACCOUNT_DS = list(
		/datum/bounty/item/botany,
		/datum/bounty/item/chef,
		/datum/bounty/item/gardencook,
		/datum/bounty/reagent/chemical,
		/datum/bounty/reagent/simple_drink,
		/datum/bounty/reagent/complex_drink,
		/datum/bounty/item/mining,
	),
))

/proc/econ_outpost_bounty_types(id)
	var/static/list/by_outpost = list()
	if(by_outpost[id])
		return by_outpost[id]
	var/list/found = list()
	for(var/base in GLOB.econ_outpost_bounty_bases[id])
		for(var/bounty_type in typesof(base))
			if(!GLOB.econ_bounty_unobtainable[bounty_type])
				found |= bounty_type
	by_outpost[id] = found
	return found

/// Заказ аванпоста: награда - бюджету аванпоста, доля участника - сдавшим сканером продажи. Станционные доски и пады его не видят, а станционный спрос он не трогает.
/datum/econ_contract/delivery/outpost
	takeable = FALSE

/datum/econ_contract/delivery/outpost/Destroy()
	var/list/board = SSeconomy.outpost_contracts[department_id]
	if(board)
		board -= src
	return ..()

/datum/econ_contract/delivery/outpost/performer_share()
	return SSeconomy.settings.contract_team_share

/datum/econ_contract/delivery/outpost/kind()
	return "outpost"

/datum/econ_contract/delivery/outpost/visible_to(datum/bank_account/account)
	return FALSE

/datum/econ_contract/delivery/outpost/take_refusal(datum/bank_account/account)
	return "Заказ аванпоста не берут: его сдают сканером продажи аванпоста."

/datum/econ_contract/delivery/outpost/counts_demand()
	return FALSE

/datum/econ_contract/delivery/outpost/note_contribution(mob/performer, units = 1)
	var/datum/bank_account/account = econ_account_of(performer)
	if(!account || units <= 0 || istype(account, /datum/bank_account/department))
		return
	LAZYINITLIST(contributions)
	contributions["[account.account_id]"] += units

/datum/econ_contract/delivery/outpost/pay_reward(total, mob/performer)
	. = 0
	var/datum/bank_account/budget = SSeconomy.get_dep_account(department_id)
	var/memo = "Заказ аванпоста: [title]"
	if(!budget?.credit(total, ECON_CONTRACT, performer, memo))
		return
	var/list/shares = reward_shares(total)
	for(var/datum/bank_account/account as anything in shares)
		var/net = SSeconomy.pay_personal(budget, account, shares[account], ECON_CONTRACT, performer, memo)
		if(!net)
			continue
		. += net
		account.bank_card_talk("Заказ аванпоста \"[title]\" выполнен: вам [net] кр.", balloon = "заказ +[net] кр")

/datum/econ_contract/delivery/outpost/ui_entry()
	. = ..()
	.["department_name"] = econ_budget_name(SSeconomy.get_dep_account(department_id))

/datum/controller/subsystem/economy
	/// id бюджета аванпоста -> его заказы
	var/list/outpost_contracts = list()
	/// id бюджета аванпоста -> когда доска доберёт заказы взамен выполненных и снятых
	var/list/outpost_refill_at = list()

/datum/controller/subsystem/economy/proc/outpost_board(id)
	var/list/board = outpost_contracts[id]
	if(!board)
		board = list()
		outpost_contracts[id] = board
	return board

/datum/controller/subsystem/economy/proc/add_outpost_contract(id, datum/bounty/bounty)
	var/datum/econ_contract/delivery/outpost/contract = new(id, bounty)
	var/list/board = outpost_board(id)
	board += contract
	return contract

/// Снимает залежавшиеся заказы аванпостов и раз в возраст ротации добирает доски: за ротацию аванпост получает не больше ECON_OUTPOST_CONTRACTS новых заказов, сколько бы ни выполнил.
/datum/controller/subsystem/economy/proc/refresh_outpost_contracts(force = FALSE)
	for(var/id in GLOB.econ_outpost_bounty_bases)
		var/list/board = outpost_board(id)
		for(var/datum/econ_contract/contract as anything in board.Copy())
			if(contract.is_expired())
				contract.expire()
			else if(contract_rotates(contract, force))
				qdel(contract)
		if(!force && world.time < outpost_refill_at[id])
			continue
		outpost_refill_at[id] = world.time + contract_rotation_age()
		var/list/bounty_types = econ_outpost_bounty_types(id)
		bounty_types = bounty_types.Copy()
		for(var/datum/econ_contract/delivery/existing as anything in board)
			bounty_types -= existing.bounty.type
		while(length(board) < ECON_OUTPOST_CONTRACTS)
			var/datum/bounty/bounty = pick_bounty(bounty_types)
			if(!bounty)
				break
			add_outpost_contract(id, bounty)

/// Засчитывает предмет и его содержимое по заказам аванпоста id и удаляет засчитанное. Возвращает число засчитанных вещей.
/proc/econ_outpost_contracts_ship(atom/movable/thing, mob/shipper, id)
	. = 0
	var/list/board = SSeconomy.outpost_contracts[id]
	if(!length(board))
		return
	for(var/atom/movable/item as anything in econ_contract_candidates(thing))
		for(var/datum/econ_contract/delivery/outpost/contract as anything in board.Copy())
			if(QDELETED(contract) || !contract.wants(item))
				continue
			contract.ship(item, shipper)
			.++
			if(!QDELETED(item))
				qdel(item)
			break

/// Заказы аванпоста id и открытые спецзаказы партнёров для окна экспресс-консоли аванпоста.
/proc/econ_outpost_earnings_ui(id)
	var/list/contracts = list()
	for(var/datum/econ_contract/contract as anything in SSeconomy.outpost_contracts[id])
		contracts += list(contract.ui_entry())
	var/datum/bank_account/budget = SSeconomy.get_dep_account(id)
	return list(
		"contracts" = contracts,
		"offers" = econ_pad_offers_ui(),
		"team_share" = SSeconomy.settings.contract_team_share,
		"refill_in" = max(round((SSeconomy.outpost_refill_at[id] - world.time) / (1 SECONDS)), 0),
		"budget_name" = econ_budget_name(budget),
	)

/// Строки осмотра сканера аванпоста о его заказах.
/proc/econ_outpost_contracts_examine(id)
	. = list()
	for(var/datum/econ_contract/delivery/outpost/contract as anything in SSeconomy.outpost_contracts[id])
		. += "[contract.title]: сдано [contract.progress_text()], [contract.payout()] кр. при выполнении."
