/// Тип баунти -> отдел; подтип берёт отдел ближайшего предка из списка. Ключи без подтипов (напитки, особые заказы) только задают отдел.
GLOBAL_LIST_INIT(econ_bounty_department, list(
	/datum/bounty/item/medical = ACCOUNT_MED,
	/datum/bounty/virus = ACCOUNT_MED,
	/datum/bounty/reagent = ACCOUNT_MED,
	/datum/bounty/reagent/simple_drink = ACCOUNT_SRV,
	/datum/bounty/reagent/complex_drink = ACCOUNT_SRV,
	/datum/bounty/item/engineering = ACCOUNT_ENG,
	/datum/bounty/item/science = ACCOUNT_SCI,
	/datum/bounty/item/slime = ACCOUNT_SCI,
	/datum/bounty/item/mech = ACCOUNT_SCI,
	/datum/bounty/item/roboticist = ACCOUNT_SCI,
	/datum/bounty/item/cyborglimbs = ACCOUNT_SCI,
	/datum/bounty/item/bot = ACCOUNT_SCI,
	/datum/bounty/item/botany = ACCOUNT_SRV,
	/datum/bounty/item/chef = ACCOUNT_SRV,
	/datum/bounty/item/gardencook = ACCOUNT_SRV,
	/datum/bounty/item/mining = ACCOUNT_CAR,
	/datum/bounty/item/security = ACCOUNT_SEC,
	/datum/bounty/item/assistant = ACCOUNT_CIV,
	/datum/bounty/item/silly = ACCOUNT_CIV,
	/datum/bounty/item/alien_organs = ACCOUNT_SCI,
	/datum/bounty/item/syndicate_documents = ACCOUNT_SEC,
	/datum/bounty/item/adamantine = ACCOUNT_CAR,
))

GLOBAL_LIST_INIT(econ_activity_contracts, list(
	ACCOUNT_MED = list(/datum/econ_contract/activity/medical_discharges, /datum/econ_contract/activity/medical_surgeries),
	ACCOUNT_ENG = list(/datum/econ_contract/activity/engineering_export),
	ACCOUNT_SCI = list(/datum/econ_contract/activity/science_nodes),
	ACCOUNT_SRV = list(/datum/econ_contract/activity/service_dishes, /datum/econ_contract/activity/service_cleaning),
	ACCOUNT_SEC = list(/datum/econ_contract/activity/security_contraband),
	ACCOUNT_CAR = list(/datum/econ_contract/activity/cargo_ore),
))

/// Особые заказы ЦК на всю смену, выставляются при старте экономики.
GLOBAL_LIST_INIT(econ_roundstart_special_bounties, list(
	/datum/bounty/item/alien_organs,
	/datum/bounty/item/syndicate_documents,
	/datum/bounty/item/adamantine,
))

/proc/econ_bounty_department_of(bounty_type)
	for(var/current = bounty_type; current; current = type2parent(current))
		var/department_id = GLOB.econ_bounty_department[current]
		if(department_id)
			return department_id

/// Отдел -> типы баунти, из которых он получает контракты поставки.
/proc/econ_bounty_types_by_department()
	var/static/list/by_department
	if(by_department)
		return by_department
	by_department = list()
	for(var/base in GLOB.econ_bounty_department)
		for(var/bounty_type in subtypesof(base))
			var/department_id = econ_bounty_department_of(bounty_type)
			LAZYINITLIST(by_department[department_id])
			by_department[department_id] |= bounty_type
	return by_department

/datum/controller/subsystem/economy
	/// Контракты вне досок отделов: личные заказы и объявления экипажа
	var/list/loose_contracts = list()

/datum/controller/subsystem/economy/proc/all_contracts()
	. = list()
	for(var/id in departments)
		var/datum/economy_department/department = departments[id]
		. += department.contracts
	. += loose_contracts

/datum/controller/subsystem/economy/proc/contract_by_uid(uid)
	for(var/datum/econ_contract/contract as anything in all_contracts())
		if(contract.uid == uid)
			return contract

/datum/controller/subsystem/economy/proc/contracts_taken_by(datum/bank_account/account)
	. = list()
	if(!account)
		return
	for(var/datum/econ_contract/contract as anything in all_contracts())
		if(contract.taker == account && !contract.is_expired())
			. += contract

/datum/controller/subsystem/economy/proc/contract_rotation_age()
	return settings.contract_rotation_ticks * wait

/// Первая доска - на старте раунда, а не в лобби: сроки отсчитываются от раунда.
/datum/controller/subsystem/economy/proc/start_contracts()
	if(contracts_started)
		return
	contracts_started = TRUE
	refresh_contracts(force = TRUE)
	post_roundstart_specials()

/// force снимает все невзятые контракты без прогресса, иначе - только те, чей срок ротации вышел.
/datum/controller/subsystem/economy/proc/refresh_contracts(force = FALSE)
	for(var/id in departments)
		if(id == ACCOUNT_CMD)
			continue
		var/datum/economy_department/department = departments[id]
		for(var/datum/econ_contract/contract as anything in department.contracts.Copy())
			if(contract.is_expired())
				contract.expire()
			else if(contract_rotates(contract, force))
				qdel(contract)
		fill_department_contracts(department)
	for(var/datum/econ_contract/contract as anything in loose_contracts.Copy())
		if(contract.is_expired())
			contract.expire()
		else if(contract_rotates(contract, force))
			qdel(contract)

/// Добирает доску отдела до contracts_per_department обычных контрактов; заказы из avoid выдаются, только если других не осталось.
/datum/controller/subsystem/economy/proc/fill_department_contracts(datum/economy_department/department, list/avoid)
	var/regular = 0
	for(var/datum/econ_contract/contract as anything in department.contracts)
		if(!contract.pinned)
			regular++
	while(regular < settings.contracts_per_department)
		var/datum/econ_contract/fresh = generate_contract(department.id, avoid)
		if(!fresh && length(avoid))
			avoid = null
			continue
		if(!fresh)
			break
		department.contracts += fresh
		regular++

/datum/economy_department
	COOLDOWN_DECLARE(contract_reset_cooldown)

/// Почему user не может сбросить доску контрактов отдела, или null.
/datum/economy_department/proc/contract_reset_refusal(mob/living/user)
	if(id == ACCOUNT_CMD)
		return "У командования нет своей доски контрактов."
	if(!SSeconomy.contracts_started)
		return "Доска контрактов откроется с началом смены."
	if(!can_manage(user))
		return "Сбросить доску отдела может только его глава, ГП или капитан."
	if(!COOLDOWN_FINISHED(src, contract_reset_cooldown))
		return "Доску отдела \"[name]\" можно сбросить через [DisplayTimeText(COOLDOWN_TIMELEFT(src, contract_reset_cooldown), 1)]."

/// Взявший в игре: тело живо и с клиентом. Без него контракт только держит слот.
/datum/econ_contract/proc/taker_in_game()
	var/datum/mind/taker_mind = taker?.owner_mind_ref?.resolve()
	var/mob/living/body = isliving(taker_mind?.current) ? taker_mind.current : taker?.owner_ref?.resolve()
	return !!body && body.stat != DEAD && !!GET_CLIENT(body)

/// Снимет ли сброс доски главой user этот контракт: неначатый, не заказ ЦК, не свой контракт главы и не взятый игроком в игре меньше ECON_CONTRACT_BOARD_RESET_GRACE назад.
/datum/econ_contract/proc/board_reset_removes(datum/bank_account/head_account)
	if(pinned || completed || is_expired() || has_progress())
		return FALSE
	if(!taker)
		return TRUE
	if(taker == head_account)
		return FALSE
	return world.time - taken_at >= ECON_CONTRACT_BOARD_RESET_GRACE || !taker_in_game()

/// Контракты доски, которые сбросит user.
/datum/economy_department/proc/contracts_to_reset(mob/living/user)
	. = list()
	var/datum/bank_account/head_account = econ_account_of(user)
	for(var/datum/econ_contract/contract as anything in contracts)
		if(contract.board_reset_removes(head_account))
			. += contract

/// Глава снимает неначатые контракты отдела и выставляет новые; свой контракт и недавно взятые игроками в игре остаются. Взявшие не теряют репутацию и берут новый контракт сразу. Возвращает list(удалось ли, ответ игроку).
/datum/economy_department/proc/reset_contracts(mob/living/user)
	var/refusal = contract_reset_refusal(user)
	if(refusal)
		return list(FALSE, refusal)
	var/list/removed_types = list()
	var/freed = 0
	for(var/datum/econ_contract/contract as anything in contracts_to_reset(user))
		var/datum/econ_contract/delivery/delivery = contract
		removed_types += istype(delivery) ? delivery.bounty.type : contract.type
		if(contract.taker)
			freed++
			contract.taker.bank_card_talk("Глава отдела сбросил доску: контракт \"[contract.title]\" снят. Репутация не пострадала, новый контракт можно взять сразу.")
		qdel(contract)
	if(!length(removed_types))
		return list(FALSE, "На доске отдела \"[name]\" нечего сбрасывать: остались только начатые, заказы ЦК, ваш контракт и взятые меньше [DisplayTimeText(ECON_CONTRACT_BOARD_RESET_GRACE)] назад.")
	COOLDOWN_START(src, contract_reset_cooldown, ECON_CONTRACT_BOARD_RESET_COOLDOWN)
	SSeconomy.fill_department_contracts(src, removed_types)
	log_econ("[key_name(user)] сбросил доску контрактов отдела [id]: снято [length(removed_types)], из них взятых [freed]")
	return list(TRUE, "Доска отдела \"[name]\" сброшена: снято контрактов - [length(removed_types)][freed ? ", из них взятых - [freed]" : ""]. Начатые, заказы ЦК, ваш контракт и недавно взятые остались. Следующий сброс - через [DisplayTimeText(ECON_CONTRACT_BOARD_RESET_COOLDOWN)].")

/// Доски, которые user может сбросить (по умолчанию - всех отделов): id, имя, секунды до следующего сброса, минуты между сбросами и сколько контрактов (из них взятых) снимет сброс сейчас.
/proc/econ_contract_resets_ui(mob/user, list/departments)
	. = list()
	if(!isliving(user) || !SSeconomy.contracts_started)
		return
	if(!departments)
		departments = list()
		for(var/id in SSeconomy.departments)
			departments += SSeconomy.departments[id]
	for(var/datum/economy_department/department as anything in departments)
		if(department.id == ACCOUNT_CMD || !department.can_manage(user))
			continue
		var/list/removable = department.contracts_to_reset(user)
		var/removable_taken = 0
		for(var/datum/econ_contract/contract as anything in removable)
			if(contract.taker)
				removable_taken++
		. += list(list(
			"id" = department.id,
			"name" = department.name,
			"left" = CEILING(COOLDOWN_TIMELEFT(department, contract_reset_cooldown) / (1 SECONDS), 1),
			"minutes" = round(ECON_CONTRACT_BOARD_RESET_COOLDOWN / (1 MINUTES)),
			"grace_minutes" = round(ECON_CONTRACT_BOARD_RESET_GRACE / (1 MINUTES)),
			"remove" = length(removable),
			"remove_taken" = removable_taken,
		))

/proc/econ_contract_reset_act(mob/user, department_id)
	var/datum/economy_department/department = istext(department_id) ? SSeconomy.get_department(department_id) : null
	if(!department)
		return list(FALSE, "Нет такого отдела.")
	return department.reset_contracts(user)

/datum/controller/subsystem/economy/proc/contract_rotates(datum/econ_contract/contract, force)
	var/due = contract.rotation_due_at()
	if(isnull(due))
		return FALSE
	return world.time >= due || (force && !contract.has_progress())

/datum/controller/subsystem/economy/proc/generate_contract(department_id, list/avoid)
	var/datum/economy_department/department = get_department(department_id)
	var/list/present = LAZYCOPY(avoid)
	for(var/datum/econ_contract/existing as anything in department?.contracts)
		var/datum/econ_contract/delivery/delivery = existing
		present += istype(delivery) ? delivery.bounty.type : existing.type
	var/list/by_department = econ_bounty_types_by_department()
	var/list/activity_types = GLOB.econ_activity_contracts[department_id]
	var/list/bounty_types = by_department[department_id]
	activity_types = LAZYCOPY(activity_types) - present
	bounty_types = LAZYCOPY(bounty_types) - present
	var/datum/econ_contract/contract
	if(length(activity_types) && (!length(bounty_types) || prob(ECON_CONTRACT_ACTIVITY_CHANCE)))
		var/activity_type = pick(activity_types)
		contract = new activity_type(department_id)
	else
		var/datum/bounty/bounty = pick_bounty(bounty_types)
		if(bounty && prob(settings.contract_chain_chance))
			contract = generate_chain(department_id, bounty, bounty_types)
		else if(bounty)
			contract = new /datum/econ_contract/delivery(department_id, bounty)
	if(!contract)
		return null
	if(!istype(contract, /datum/econ_contract/delivery/chain) && prob(settings.contract_urgent_chance))
		contract.urgent = TRUE
		contract.set_deadline(world.time + settings.contract_urgent_minutes MINUTES)
	return contract

/// Новое баунти из списка типов, выбранный тип из списка убирается. Заказы, которые недавно сдавали, выпадают реже.
/datum/controller/subsystem/economy/proc/pick_bounty(list/bounty_types)
	while(length(bounty_types))
		var/list/weights = list()
		for(var/bounty_type in bounty_types)
			weights[bounty_type] = max(round(contract_demand_mult(bounty_type) * 10), 1)
		var/picked = pickweight(weights)
		bounty_types -= picked
		var/datum/bounty/bounty = new picked
		if(bounty.name && bounty.description)
			return bounty
		qdel(bounty)
	return null

/// Особый заказ ЦК: контракт поставки отдела по типу баунти (по умолчанию снабжения), без ротации и без исполнителя.
/datum/controller/subsystem/economy/proc/post_special_contract(datum/bounty/bounty)
	if(!bounty?.name || !bounty.description)
		return null
	for(var/datum/econ_contract/delivery/existing in all_contracts())
		if(!existing.bounty.compatible_with(bounty) || !bounty.compatible_with(existing.bounty))
			return null
	var/department_id = econ_bounty_department_of(bounty.type) || ACCOUNT_CAR
	var/datum/economy_department/department = get_department(department_id)
	if(!department)
		return null
	var/datum/econ_contract/delivery/contract = new(department_id, bounty)
	contract.pinned = TRUE
	contract.takeable = FALSE
	department.contracts += contract
	return contract

/datum/controller/subsystem/economy/proc/post_roundstart_specials()
	for(var/bounty_type in GLOB.econ_roundstart_special_bounties)
		var/datum/bounty/bounty = new bounty_type
		if(!post_special_contract(bounty))
			qdel(bounty)
