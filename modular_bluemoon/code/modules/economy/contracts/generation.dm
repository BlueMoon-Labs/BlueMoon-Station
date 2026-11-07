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

/datum/controller/subsystem/economy/proc/all_contracts()
	. = list()
	for(var/id in departments)
		var/datum/economy_department/department = departments[id]
		. += department.contracts

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
		var/regular = 0
		for(var/datum/econ_contract/contract as anything in department.contracts.Copy())
			if(contract.is_expired())
				contract.taker?.bank_card_talk("Срок контракта \"[contract.title]\" истёк, контракт снят.")
				qdel(contract)
			else if(contract_rotates(contract, force))
				qdel(contract)
			else if(!contract.pinned)
				regular++
		while(regular < settings.contracts_per_department)
			var/datum/econ_contract/fresh = generate_contract(id)
			if(!fresh)
				break
			department.contracts += fresh
			regular++

/datum/controller/subsystem/economy/proc/contract_rotates(datum/econ_contract/contract, force)
	var/due = contract.rotation_due_at()
	if(isnull(due))
		return FALSE
	return world.time >= due || (force && !contract.has_progress())

/datum/controller/subsystem/economy/proc/generate_contract(department_id)
	var/datum/economy_department/department = get_department(department_id)
	var/list/present = list()
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
		while(length(bounty_types) && !contract)
			var/bounty_type = pick_n_take(bounty_types)
			var/datum/bounty/bounty = new bounty_type
			if(bounty.name && bounty.description)
				contract = new /datum/econ_contract/delivery(department_id, bounty)
			else
				qdel(bounty)
	if(!contract)
		return null
	if(prob(settings.contract_urgent_chance))
		contract.urgent = TRUE
		contract.set_deadline(world.time + settings.contract_urgent_minutes MINUTES)
	return contract

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
