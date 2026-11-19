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

/// Заказы, которые аванпосту не из чего сделать: корги на аванпостах нет.
GLOBAL_LIST_INIT(econ_outpost_bounty_excluded, list(
	/datum/bounty/item/chef/corgifarming = TRUE,
))

/proc/econ_outpost_bounty_types(id)
	var/static/list/by_outpost = list()
	if(by_outpost[id])
		return by_outpost[id]
	var/list/found = list()
	for(var/base in GLOB.econ_outpost_bounty_bases[id])
		for(var/bounty_type in typesof(base))
			if(!GLOB.econ_bounty_unobtainable[bounty_type] && !GLOB.econ_outpost_bounty_excluded[bounty_type] && econ_bounty_fits_scanner(bounty_type))
				found |= bounty_type
	by_outpost[id] = found
	return found

/// Сканер продажи берёт только предметы: заказ на костёр или лодку им не сдать.
/proc/econ_bounty_fits_scanner(bounty_type)
	if(!ispath(bounty_type, /datum/bounty/item))
		return TRUE
	var/datum/bounty/item/bounty = new bounty_type
	. = TRUE
	for(var/wanted in bounty.wanted_types)
		if(!ispath(wanted, /obj/item))
			. = FALSE
			break
	qdel(bounty)

/// Заказ аванпоста: награда - бюджету аванпоста, доля участника - сдавшим сканером продажи. Станционные доски и пады его не видят, а станционный спрос он не трогает.
/datum/econ_contract/delivery/outpost
	takeable = FALSE
	/// Сколько награды осталось бюджету аванпоста после долей сдавших, для сообщений о выполнении
	var/budget_net = 0

/datum/econ_contract/delivery/outpost/set_bounty(datum/bounty/new_bounty)
	..()
	desc = "Покупатель на рынке сектора ищет такой товар. Сдайте его сканером продажи."

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
	SSeconomy.ledger.note_outpost_income(department_id, "contracts", total)
	budget_net = total
	var/list/shares = reward_shares(total)
	for(var/datum/bank_account/account as anything in shares)
		var/share = shares[account]
		var/net = SSeconomy.pay_personal(budget, account, share, ECON_CONTRACT, performer, memo)
		if(!net)
			continue
		. += net
		budget_net -= share
		account.bank_card_talk(net == share ? "Заказ аванпоста \"[title]\" выполнен: вам [net] кр." : "Заказ аванпоста \"[title]\" выполнен: [share] кр. до налога, на руки [net] кр.", balloon = "заказ +[net] кр")
	econ_outpost_say(department_id, "Заказ [title] выполнен, +[budget_net] кр. в бюджет.")

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
		var/list/added = list()
		while(length(board) < ECON_OUTPOST_CONTRACTS)
			var/datum/bounty/bounty = pick_bounty(bounty_types)
			if(!bounty)
				break
			var/datum/econ_contract/contract = add_outpost_contract(id, bounty)
			added += contract.title
		if(length(added))
			econ_outpost_say(id, "Новые заказы: [jointext(added, ", ")].")

/// Экспресс-консоли аванпоста id говорят вслух: слышат те, кто рядом, без радио.
/proc/econ_outpost_say(id, message)
	for(var/obj/machinery/computer/cargo/express/console in GLOB.machines)
		if(console.department_account == id && !(console.machine_stat & (NOPOWER|BROKEN)))
			console.say(message)

/// Засчитывает предмет и его содержимое по заказам аванпоста id и удаляет засчитанное. Возвращает строки о тронутых заказах: сколько сдано или что выполнен.
/proc/econ_outpost_contracts_ship(atom/movable/thing, mob/shipper, id)
	. = list()
	var/list/board = SSeconomy.outpost_contracts[id]
	if(!length(board))
		return
	var/list/shipped = list()
	for(var/atom/movable/item as anything in econ_contract_candidates(thing))
		for(var/datum/econ_contract/delivery/outpost/contract as anything in board.Copy())
			if(QDELETED(contract) || !contract.wants(item))
				continue
			shipped |= contract
			contract.ship(item, shipper)
			if(!QDELETED(item))
				qdel(item)
			break
	for(var/datum/econ_contract/delivery/outpost/contract as anything in shipped)
		. += QDELETED(contract) ? "[contract.title]: выполнен, +[contract.budget_net] кр. в бюджет" : "[contract.title]: сдано [contract.progress_text()]"

/// Куда сканер аванпоста id отправит вещь, в том же порядке, что и сдача: для подсказки до телепортации.
/proc/econ_outpost_scan_destination(atom/movable/thing, id)
	var/list/candidates = econ_contract_candidates(thing)
	for(var/datum/market_offer/offer as anything in SSmarket.all_offers())
		if(!offer.pad_open())
			continue
		for(var/atom/movable/item as anything in candidates)
			if(offer.matches(item))
				return "под спецзаказ"
	for(var/datum/econ_contract/delivery/outpost/contract as anything in SSeconomy.outpost_contracts[id])
		for(var/atom/movable/item as anything in candidates)
			if(contract.wants(item))
				return "под заказ: [contract.title]"
	return "на рынок"

/datum/economy_ledger
	/// id аванпоста -> откуда пришли деньги в его бюджет: заказы, спецзаказы, рынок
	var/list/outpost_income = list()

/datum/economy_ledger/proc/note_outpost_income(id, source, amount)
	if(amount <= 0)
		return
	var/list/income = outpost_income[id]
	if(!income)
		income = list("contracts" = 0, "offers" = 0, "market" = 0)
		outpost_income[id] = income
	income[source] += amount

/// Строки итогов раунда о заработке аванпостов: только тех, кому что-то пришло.
/proc/econ_outpost_income_report()
	var/static/list/names = list(ACCOUNT_TAR = "Тарков", ACCOUNT_DS = "Deep Space")
	var/static/list/source_names = list("contracts" = "заказы", "offers" = "спецзаказы", "market" = "рынок")
	. = list()
	for(var/id in GLOB.econ_outpost_bounty_bases)
		var/list/income = SSeconomy.ledger.outpost_income[id]
		var/total = 0
		var/list/parts = list()
		for(var/source in source_names)
			if(income?[source] > 0)
				total += income[source]
				parts += "[source_names[source]] [num2text(income[source], ECON_TEXT_DIGITS)] кр."
		if(total > 0)
			. += "[names[id]] заработал [num2text(total, ECON_TEXT_DIGITS)] кр.: [jointext(parts, ", ")]"

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
